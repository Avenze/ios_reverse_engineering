local Class = require("Framework.Lua.Class");
---@class BaseScene
local BaseScene = Class("BaseScene");
local GameResMgr = require("GameUtils.GameResManager");
local EventManager = require("Framework.Event.Manager")
local UIView = require("Framework.UI.View")

local SoundEngine = GameTableDefine.SoundEngine

local Mathf = CS.UnityEngine.Mathf
local EventTriggerListener = CS.Common.Utils.EventTriggerListener
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local GameObject = CS.UnityEngine.GameObject
local GameUIManager = GameTableDefine.GameUIManager
local FlyIconsUI = GameTableDefine.FlyIconsUI
local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3
local DotweenUtil = CS.Common.Utils.DotweenUtil
local UnityTime = CS.UnityEngine.Time

function BaseScene:ctor()
    self.__listeners = self.__listeners or {};
    self.__listeners[self] = {};                -- 设置的监听要在界面关闭时消除;
    self.__timers = self.__timers or {}
    self.__timers[self] = nil
end

function BaseScene:SetSceneType(sceneType)
    self.m_sceneType = sceneType
end

function BaseScene:GetSceneType()
    return self.m_sceneType
end

function BaseScene:SetSceneRootGo(rootGo)
    self.m_rootGo = rootGo;
end

function BaseScene:GetSceneRootGo()
    return self.m_rootGo
end

function BaseScene:OnEnter()
    print("BaseScene:OnEnter");
    self.cameraGO = GameObject.Find("Main Camera").gameObject
    self.capsuleGO = GameObject.Find("Capsule").gameObject
    self.camera = self.cameraGO:GetComponent("Camera")
    self.cameraMove = self.cameraGO:GetComponent("CameraMove")
end

function BaseScene:OnUpdate(scene)
    if scene.__currentFollowGo and not scene.__currentFollowGo:IsNull() then
        scene:LocatePosition(scene.__currentFollowGo.transform.position, true)
    end
end

function BaseScene:OnPause()
    print("BaseScene:OnPause");
end

function BaseScene:OnResume()
    print("BaseScene:OnResume");
end

function BaseScene:OnExit(scene)
    GameTimer:StopTimer(self.m_focusAndScaleTimerId)
    GameTimer:StopTimer(self.m_focusTimerId)
    self:StopTimerByScene(scene)
    self.m_focusAndScaleTimerId = nil
    self.m_focusTimerId = nil

    for go, t in pairs(self.__listeners[scene] or {}) do
        if not go:IsNull() then
            print("Remove EventHandle", go.name, EventType.PointerClick);
            EventTriggerListener.Get(go):SetEventHandle(EventType.PointerClick, nil);
        end
    end
    self.__listeners[scene] = nil
    self.__cameraLocateRecordData = nil
    self.__currentFollowGo = nil
    if self.cameraMove then
        self.cameraMove.Follower = nil
    end

    self.cameraGO = nil
    self.capsuleGO = nil
    self.camera = nil
    self.cameraMove = nil
    GameResMgr:Unload(self)
    GameResMgr:Unload(scene)
end

function BaseScene:SetButtonClickHandler(go, handler, sfxURL)
    local cb = handler
    if not handler then
        EventTriggerListener.Get(go):SetEventHandle(EventType.PointerClick, nil)
        return
    end

    if sfxURL ~= "" then
        sfxURL = sfxURL or SoundEngine.BUTTON_CLICK_SFX
        cb = function( ... )
            SoundEngine:PlaySFX(sfxURL)
            handler(...)
        end
    end

    EventTriggerListener.Get(go):SetEventHandle(EventType.PointerClick, cb)
    self.__listeners = self.__listeners or {};
    self.__listeners[self] = self.__listeners[self] or {};
    self.__listeners[self][go] = cb;
end

function BaseScene:CreateTimer(intervalInMilliSec, func, isLoop, execImmediately)
    self:StopTimer()
    self.__timers[self] = GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, isLoop, execImmediately)
end

function BaseScene:StopTimerByScene(scene)
    if self.__timers[scene] then
        GameTimer:StopTimer(self.__timers[scene])
        self.__timers[scene] = nil
    end
end

function BaseScene:StopTimer()
    if self.__timers[self] then
        GameTimer:StopTimer(self.__timers[self])
        self.__timers[self] = nil
    end
end

function BaseScene:GetGo(go, child)
    return UIView:GetGo(go, child)
end

function BaseScene:GetGoOrNul(go, child)
    return UIView:GetGoOrNil(go, child)
end

function BaseScene:GetComp(go, child, uiType)
    return UIView:GetComp(go, child, uiType)
end

function BaseScene:GetTrans(go, child)
    return UIView:GetTrans(go, child)
end

function BaseScene:CameraFollow()
    local cameraFollow = self.cameraGO:GetComponent("CameraFollow")
    return cameraFollow
end

function BaseScene:CameraMove()
    return self.cameraMove
end

function BaseScene:SetCameraLocateRecordData(go3d, start2DPositon)
    if self.__cameraLocateRecordData then
        return
    end

    local cameraFollow = self.cameraGO:GetComponent("CameraFollow")
    self.__cameraLocateRecordData = {}
    self.__cameraLocateRecordData.offset = cameraFollow.Offset.magnitude - cameraFollow.OrthOffset
    self.__cameraLocateRecordData.go3d = go3d
    self.__cameraLocateRecordData.offset2dPosition = start2DPositon
end
function BaseScene:GetSetCameraLocateRecordData()
    return self.__cameraLocateRecordData
end

function BaseScene:InitSceneCameraScale(data, callback)
    local go = self.capsuleGO
    local size = data.m_cameraSize
    local speed = data.m_cameraMoveSpeed
    --local target2DPosition = data.position
    local cb = function()
        self.__cameraLocateRecordData = nil
        if callback then callback() end
    end
    self:Locate3DPositionByScreenPosition(go, nil, size, speed, cb)
end

function BaseScene:Locate3DPositionByScreenPosition(startGo, end2dPosition, endScale, speed, endCallBack, updateCallback)
    local cameraFollow = self.cameraGO:GetComponent("CameraFollow")
    local normalized = cameraFollow.Offset.normalized
    local OrthOffset = cameraFollow.OrthOffset
    local data = self:GetSetCameraLocateRecordData() or {}
    local isBack = data.isBack
    endScale = math.min(cameraFollow.scaleMaxLimit,math.max(cameraFollow.scaleMinLimit,endScale))
    local finalOffset = normalized * (endScale + OrthOffset)
    if self.m_focusAndScaleTimerId then
        GameTimer:StopTimer(self.m_focusAndScaleTimerId)
        self.m_focusAndScaleTimerId = nil
    end

    local object3dPosition = nil
    local objectGroundPosition = nil
    local current2dPosition = nil

    if end2dPosition then
        object3dPosition = startGo.transform.position
        local object2dPosition = self:Position3dTo2d(object3dPosition)
        local success, posGround = self:GetSceneGroundPosition(object2dPosition)
        if success then
            current2dPosition = self:Position3dTo2d(posGround)
            objectGroundPosition = posGround
        else
            current2dPosition = object2dPosition
            objectGroundPosition = object3dPosition
        end
        self:SetCameraLocateRecordData(startGo, current2dPosition)
        --printError("start2dPosition = ".. current2dPosition.x..",".. current2dPosition.y..",".. current2dPosition.z)
    end
    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.ROOM_BUILDING_UI) and not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INSTANCE_BUILDING_UI) then
        GameUIManager:SetEnableTouch(false,"相机移动")
    end
    self.m_cameraMoveFrame = 0
    self.m_focusAndScaleTimerId = GameTimer:CreateNewMilliSecTimer(1, function()
        self.m_cameraMoveFrame = self.m_cameraMoveFrame + 1
        local movePro = nil
        local deltaTimeSpeed = speed * math.min(1,UnityTime.deltaTime * 40)
        cameraFollow:SetOffsetAndUpdatePosition(Vector3.Lerp(cameraFollow.Offset, finalOffset, deltaTimeSpeed))
        --printError("deltaTimeSpeed = "..deltaTimeSpeed)
        if end2dPosition then
            current2dPosition = Vector3.Lerp(current2dPosition, end2dPosition, deltaTimeSpeed)
            local succ, currentGroundPos = self:GetSceneGroundPosition(current2dPosition)
            if succ then
                self:LocatePosition(self.capsuleGO.transform.position + (objectGroundPosition - currentGroundPos))
            end
            movePro = math.abs(end2dPosition.magnitude - current2dPosition.magnitude)
        end

        local scalePro = math.abs(cameraFollow.Offset.magnitude - endScale - OrthOffset)
        local needStopMove = scalePro < 0.2 and (not end2dPosition or movePro < 1)
        if not needStopMove then
            --摄像机移动异常，可能因某种原因卡住了 强行停止移动
            if self.m_cameraMoveFrame > 100 then
                needStopMove = true
                printError("摄像机移动异常，耗时超过100次update，可能因某种原因卡住了，强行停止移动")
            end
        else
            --因为GameTimer不能本帧停止，所以摄像机移动也不准在开始的帧里面停止
            if self.m_cameraMoveFrame == 1 then
                needStopMove = false
            end
        end
        if needStopMove then -- and movePro < 20
            --FlyIconsUI:SetSceneSwitchMask(movePro/moveProgress, 1)
            --应用最终缩放
            cameraFollow:SetOffsetAndUpdatePosition( finalOffset)
            if end2dPosition then
                if isBack and math.abs((data.offset or -100000000) - endScale) < 1 then
                    self.__cameraLocateRecordData = nil
                end
                --应用最终位置
                local succ, currentGroundPos = self:GetSceneGroundPosition(end2dPosition)
                if succ then
                    self:LocatePosition(self.capsuleGO.transform.position + (objectGroundPosition - currentGroundPos))
                end
                --do
                --    local final2dPosition = self:Position3dTo2d(objectGroundPosition)
                --    printError("final2dPosition = ".. final2dPosition.x..",".. final2dPosition.y..",".. final2dPosition.z)
                --end
            end

            GameTimer:StopTimer(self.m_focusAndScaleTimerId)
            self.m_focusAndScaleTimerId = nil
            GameUIManager:SetEnableTouch(true,"相机移动")
            if endCallBack then  endCallBack(true) end
        else
            --FlyIconsUI:SetSceneSwitchMask(movePro/moveProgress, 0)
        end
    end,true)
end

function BaseScene:LocatePosition(targetPosition, showMoving, callBack)
    local focusGO = self.capsuleGO
    if focusGO and targetPosition then
        --停止摄像机因触控操作产生的移动
        if self.cameraMove and self.cameraMove.StopMove then
            self.cameraMove:StopMove()
        end
        if showMoving then
            local maxSpeed = 300
            local minSpeed = 20
            local velocity = Vector3()
            if self.m_focusTimerId then
                GameTimer:StopTimer(self.m_focusTimerId)
                self.m_focusTimerId = nil
            end

            --printf("LocatePosition targetPosition = "..tostring(targetPosition))

            self.m_focusTimerId =
            GameTimer:CreateNewMilliSecTimer(
                    1,
                    function()
                        local currentPos = focusGO.transform.position
                        --printf("focusGO.transform.position = "..tostring(currentPos))
                        if not focusGO or not focusGO.transform or focusGO:IsNull() or focusGO.transform:IsNull() then
                            GameTimer:StopTimer(self.m_focusTimerId)
                            self.m_focusTimerId = nil
                            if callBack then callBack(true) end
                            return
                        end
                        targetPosition.y = currentPos.y
                        currentPos, velocity = Vector3.SmoothDamp(currentPos,targetPosition, velocity,0.2, maxSpeed)
                        local curSpeed = velocity.magnitude
                        if curSpeed<minSpeed and curSpeed>0 then
                            velocity = velocity.normalized * minSpeed
                        end
                        --printf("velocity = "..tostring(velocity).."\n currentPos = "..tostring(currentPos).."\n targetPosition = "..tostring(targetPosition))
                        --local x,z
                        --x,vec3.x = Mathf.SmoothDamp(focusGO.transform.position.x, targetPosition.x, vec3.x,0.2, speed)
                        --z,vec3.z = Mathf.SmoothDamp(focusGO.transform.position.z, targetPosition.z, vec3.z,0.2, speed)
                        --focusGO.transform.position = {
                        --    x = x,
                        --    y = focusGO.transform.position.y,
                        --    z = z
                        --}
                        focusGO.transform.position = currentPos
                        if math.abs(focusGO.transform.position.x - targetPosition.x) < 0.1 and math.abs(focusGO.transform.position.z - targetPosition.z) < 0.1 then
                            GameTimer:StopTimer(self.m_focusTimerId)
                            self.m_focusTimerId = nil
                            if callBack then callBack(true) end
                        end
                    end,
                    true,
                    true
            )
        else
            focusGO.transform.position = {
                x = targetPosition.x,
                y = focusGO.transform.position.y,
                z = targetPosition.z
            }
            if callBack then callBack(true) end--大多情况直接移动不需要使用回调
        end
    end
end

function BaseScene:LoadMaterials(address)
    local handler = GameResMgr:LoadMaterialSyncFree(address, self)
    return handler.Result
end

function BaseScene:IsGoOutsideScreen(go, extraMargin)
    if go and not go:IsNull() and self.cameraGO and not self.cameraGO:IsNull() then
        local camera = self.cameraGO:GetComponent("Camera")
        if camera and not camera:IsNull() then
            local viewportPoint = camera:WorldToViewportPoint(go.transform.position)
            return not self:IsValidViewportPoint(viewportPoint, extraMargin)
        end
    end
    return true
end

function BaseScene:IsValidViewportPoint(viewportPoint, extraMargin)
    local extraMargin = extraMargin or 0
    if viewportPoint.x < 0 - extraMargin or viewportPoint.x > 1 + extraMargin or viewportPoint.y < 0 - extraMargin or viewportPoint.y > 1 + extraMargin then
        return false
    else
        return true
    end
end


function BaseScene:CheckPositionChange()
    if self.capsuleGO and not self.capsuleGO:IsNull() then
        local threshold = 2.0
        local pos = self.capsuleGO.transform.position
        if not self.preFocusPosition then
            self.preFocusPosition = pos
            return true
        end

        if math.abs(pos.x - self.preFocusPosition.x) > threshold or math.abs(pos.z - self.preFocusPosition.z) > threshold then
            self.preFocusPosition = pos
            return true
        end
    end
    return false
end

function BaseScene:GetSceneGroundPosition(target2DPosition)
    if not self.camera or self.camera:IsNull() then
        return false, nil
    end
    local viewPort = GameUIManager.m_uiCamera:WorldToViewportPoint(target2DPosition)
    local succ, position = UnityHelper.GetPositionbyViewportPosition(self.camera, viewPort, 500)
    return succ, position
end

function BaseScene:Position3dTo2d(position)
    local positon2d = self.camera:WorldToViewportPoint(position)
    positon2d = GameUIManager.m_uiCamera:ViewportToWorldPoint(positon2d)
    return positon2d
end

function BaseScene:SetCameraFollowGo(go)
    if self.cameraMove then
        local trans = nil
        if go and not go:IsNull() then
            trans = go.transform
        end
        self.cameraMove.Follower = trans
    else
        if go and go:IsNull() then
            go = nil
        end
        self.__currentFollowGo = go
    end
end

function BaseScene:SetCameraLimitBounds(bc)
    if not bc or bc:IsNull() then
        return false
    end
    self.cameraMove:SetMoveBoxCollider(bc)
    return true
end

function BaseScene:SetCameraCapsule(pos, cb, bc)
    if not self.capsuleGO or self.capsuleGO:IsNull() or not pos then
        return
    end

    local isTransfer = bc and not bc:IsNull() -- self:SetCameraLimitBounds(bc)
    local capsulePos = self.capsuleGO.transform.position
    if isTransfer then
        capsulePos = pos
    else
        capsulePos.y = pos.y
    end
    GameUIManager:SetEnableTouch(false)
    -- DotweenUtil.DOTweenMove(self.capsuleGO, capsulePos, 0.5, function()
    --     GameUIManager:SetEnableTouch(true)
    --     if cb then cb() end
    -- end)
    local cmd = "SET_CAM_CAP_END_" ..self.capsuleGO:GetInstanceID()
    EventManager:RegEvent(cmd, function(go)
        self:SetCameraLimitBounds(bc)
        EventManager:RegEvent(cmd, nil)
        GameUIManager:SetEnableTouch(true)
        if cb then cb() end
    end)
    DotweenUtil.DOTweenMove(self.capsuleGO, capsulePos, isTransfer and 0.05 or 0.5, cmd)
end

--function BaseScene:RefreshAStarBlock(rootGo)
--    if not rootGo or rootGo:IsNull() then
--        return
--    end
--
--    local trans = self:GetTrans(rootGo, "block")
--    if not trans or trans:IsNull() then
--        return
--    end
--    GameTimer:CreateNewMilliSecTimer(100, function () --需要等待 childGo 初始化完毕，所以延迟100毫秒刷新地图
--        local boxs = trans.gameObject:GetComponents(typeof(CS.UnityEngine.BoxCollider))
--        for i = 0, boxs.Length - 1 do
--            UnityHelper.RefreshAStarMap(boxs[i].bounds)
--        end
--    end)
--end

return BaseScene