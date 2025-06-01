--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 17:16:10
]]

local Actor = require "GamePlay.Floors.Actors.Actor"
local ActorDefine = require "CodeRefactoring.Actor.ActorDefine"
local InstanceWorker = require "GamePlay.Instance.InstanceWorker"
local EventInstance = require("CodeRefactoring.Actor.Actors.EventInstanceNew")
local InteractionsManager = require "CodeRefactoring.Interactions.InteractionsManager"
local InstanceWorkerSM = require("CodeRefactoring.AI.StateMachines.InstanceWorkerSM")
local ActorTypeEnum = require("CodeRefactoring.Actor.ActorTypeEnum")
local AIStateEnum = require("CodeRefactoring.AI.AIStateEnum")
local GameResMgr = require("GameUtils.GameResManager")
local instanceRoom =  require("GamePlay.Instance.InstanceRoom")

local EventManager = require("Framework.Event.Manager")
local Class = require("Framework.Lua.Class");
local BaseScene = require("Framework.Scene.BaseScene")
---@class InstanceScene:BaseScene
local InstanceScene = Class("InstanceScene", BaseScene)

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local Transform = CS.UnityEngine.Transform
local MeshRenderer = CS.UnityEngine.MeshRenderer

local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel
local InstanceBuildingUI = GameTableDefine.InstanceBuildingUI
local InstanceUnlockUI = GameTableDefine.InstanceUnlockUI
local FloatUI = GameTableDefine.FloatUI
local InstanceBuildingUI = GameTableDefine.InstanceBuildingUI
local TimerMgr = GameTimeManager
local InstanceDataManager = GameTableDefine.InstanceDataManager
local LightManager = GameTableDefine.LightManager
local SoundEngine = GameTableDefine.SoundEngine
local InstanceShopUI = GameTableDefine.InstanceShopUI
local GuideManager = GameTableDefine.GuideManager


local Landmark --场景特殊物品
local selectFurniture   --被选中的家具
local lastSelectIsPrebuy   --上个被选择的家具是将要买的
local spacialGOPopIsShow = false    --正在显示特殊物品点击气泡
local preBuyMatPath = "Assets/Res/Materials/FX_Materials/PreBuy.mat"

local glintingInterval = 100 -- 家具闪烁变化间隔(ms)
local maxFlash = 0.5 -- 材质flash参数最大值
local deltaV = 0.1 -- 材质参数变化速度
--[[
    @desc: 声明所有变量
    author:{author}
    time:2023-03-31 11:36:28
    @return:
]]
function InstanceScene:DeclareVariable()
    self.roomsConfig = InstanceModel.roomsConfig    --房间配置数据
    self.roomsData = InstanceModel.roomsData   --所有房间存档数据
    self.personList = {}  --所有员工实例列表
    self.Rooms = {}     --房间表
    self.m_personRoot = GameObject.Find("NPC").gameObject   --NPC根节点
    self.floatUI = {}   --气泡所需结构
    self.m_nightGos = nil
    self.m_dayGos = nil
    self.m_landmarkFeel = nil -- 地标动画
    self.m_glinting = {} -- 家具闪烁数据
end

function InstanceScene:OnEnter()
    self.super:OnEnter()
    self:PlayBGM()
    self:InitEventActor()

end

function InstanceScene:OnResume()
end

function InstanceScene:Update(dt)
    self.super:OnUpdate(self)
    local timeType = InstanceModel.timeType
    if self.currTime ~= timeType then
        self.currTime = timeType

        local eatingEntities = InteractionsManager:GetEntities(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_EATING)
        if eatingEntities then
            for k, v in pairs(eatingEntities) do
                v.m_personQueue = {}
            end
        end
        local sleepingEntities = InteractionsManager:GetEntities(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_SLEEPING)
        if sleepingEntities then
            for k, v in pairs(sleepingEntities) do
                v.m_personQueue = {}
            end
        end
    end
    Actor:UpdateActorList(dt)
    self:RefreshLight()
end

function InstanceScene:OnPouse()
end

function InstanceScene:OnExit()
    self.eventInstance:Destroy()
    self:UnloadWorker()
    self:StopBGM()
    self.m_nightGos = nil
    self.m_dayGos = nil
    selectFurniture = nil
end

function InstanceScene:InitScene()
    Landmark = GameObject.Find("Landmark")
    GameTableDefine.InstanceAIBlackBoard:ClearSeat()

    self:DeclareVariable()
    self:InitSceneLight()
    self:InitSceneVFX()
    self:InitRooms()
    self:InitSpecialGameObject()
    self:InitWheel()

    --引导
    local guideID = InstanceDataManager:GetGuideID()
    if not guideID then
        local instanceBind = InstanceDataManager:GetInstanceBind()
        GuideManager.currStep = instanceBind.guideID
        GuideManager:ConditionToStart()
    end 
end
function InstanceScene:InitRooms()
    local Environment = GameObject.Find("Environment")
    local clickArg = {} --点击房间对应的参数表

    for k, v in pairs(self.roomsConfig) do
        local newRoom = instanceRoom:new()
        local roomGO = self:GetGo(Environment, v.object_name)
        local roomData = self.roomsData[v.id]
        self.Rooms[v.id] = newRoom
        newRoom:Init(v.room_category, roomData, v, roomGO, function(GO, roomID, index, isBuy)
            if not self.Rooms[v.id].existence then
                GameTimer:CreateNewTimer(1, function()
                    self:InitInteractionRoomData(v.id)
                end)
            else
                if self.Rooms[v.id].reTimer then
                    GameTimer:StopTimer(self.Rooms[v.id].reTimer)
                    self.Rooms[v.id].reTimer = nil
                end
                self.Rooms[v.id].reTimer = GameTimer:CreateNewTimer(1, function()
                    self.Rooms[v.id].reTimer = nil
                    self:RefreshInteractionRoomData(v.id)
                end)
            end
            self.Rooms[v.id].existence = true
            local levelID = roomData.furList[tostring(index)].id
            if not newRoom.workers[index] and newRoom.furLevelConfig[levelID].isPresonFurniture then
                --是工人家具
                if not self.personList[roomID] then
                    self.personList[roomID] = {}
                end
                self.personList[roomID][index] = self:NewCreateWorker(GO, roomGO, index, isBuy, v.id)

            else
                --不是工人家具
                if newRoom.furLevelConfig[levelID].shipCD > 0 then   -- 船
                    local trans = GO:GetComponentsInChildren(typeof(Transform))
                    for i=0,trans.Length-1 do
                        if trans[i].gameObject.tag == "TAG_DAY_OBJ" then
                            self.m_dayGos[#self.m_dayGos + 1] = trans[i].gameObject
                        elseif trans[i].gameObject.tag == "TAG_NIGHT_OBJ" then
                            self.m_nightGos[#self.m_dayGos + 1] = trans[i].gameObject
                        end
                    end
                end
            end
        end)
        newRoom:OnEnter()
        --绑定房间点击事件
        local roomBox = self:GetGo(Environment, v.object_name .. "/roombox")
        local tempArg = { [1] = v.id, [2] = roomBox }
        table.insert(clickArg, tempArg)
        self:SetButtonClickHandler(roomBox, function()
            local arg = nil
            for k, v in pairs(clickArg) do
                if v[2] == roomBox then
                    arg = v
                    break
                end
            end
            local curRoomData = self.roomsData[arg[1]]
            local curRoomCfg = self.roomsConfig[arg[1]]
            if curRoomData.state == 0 then
                --未解锁,点击显示解锁界面
                InstanceUnlockUI:ShowUI(arg[1])
            elseif curRoomData.state == 1 then
                --在解锁中,显示悬浮进度

            elseif curRoomData.state == 2 then
                --已解锁,点击显示RoomUI
                if curRoomCfg.room_category == 1 then
                    InstanceBuildingUI:ShowFactoryUI(arg[1])
                elseif curRoomCfg.room_category == 2 or curRoomCfg.room_category == 3 then
                    InstanceBuildingUI:ShowSupplyBuildingUI(arg[1])
                else
                    InstanceBuildingUI:ShowWharfUI(arg[1])
                end
            end
        end)
        self:RefreshRoom(v.id)
    end


end

--[[
    @desc: 初始化场景中的特殊物品
    author:{author}
    time:2023-04-03 15:08:38
    @return:
]]
function InstanceScene:InitSpecialGameObject()
    self:ShowSpecialGameObject(not InstanceModel:GetLandMarkCanPurchas())

    --绑定场景特殊物品点击事件

    local specialGOBox = GameObject.Find("Miscellaneous/Environment/Landmark/roombox")
    self.floatUI.Landmark = { ["go"] = Landmark }
    FloatUI:SetObjectCrossCamera(self.floatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowInstanceSpacialGOPop", false)
        end
    end, nil, "roombox")

    self:SetButtonClickHandler(specialGOBox, function()
        if not InstanceModel:GetLandMarkCanPurchas() then --买了1.5
            if not spacialGOPopIsShow then
                if self.floatUI.Landmark.view then
                    self.floatUI.Landmark.view:ShowInstanceSpacialGOPop(true)
                end

                spacialGOPopIsShow = true

                GameTimer:CreateNewTimer(3, function()
                    spacialGOPopIsShow = false
                    if self.floatUI.Landmark.view then
                        self.floatUI.Landmark.view:ShowInstanceSpacialGOPop(false)
                    end
                    --FloatUI:DestroyFloatUIView(self.floatUI.Landmark.guid)
                end)
            end
            if not self.m_landmarkFeel then
                self.m_landmarkFeel = self:GetComp(Landmark, "bought/Statue/clickFB", "MMFeedbacks")
            end
            if not self.m_landmarkFeel then
                return
            end
            self.m_landmarkFeel:PlayFeedbacks()
        else
            local landMarkShopID = InstanceDataManager:GetInstanceBind().landmark_id
            InstanceShopUI:OpenAndTurnPage(landMarkShopID,true)
        end
    end)
end

--[[
    @desc: 显示场景特殊物品
    author:{author}
    time:2023-05-08 14:44:34
    @return:
]]
function InstanceScene:ShowSpecialGameObject(active)
    if active then
        self:GetGo(Landmark, "bought"):SetActive(true)
        self:GetGo(Landmark, "broken"):SetActive(false)
    else
        self:GetGo(Landmark, "bought"):SetActive(false)
        self:GetGo(Landmark, "broken"):SetActive(true)
    end

end

--[[
    @desc: 初始化转盘
    author:{author}
    time:2023-04-03 15:08:58
    @return:
]]
function InstanceScene:InitWheel()
end

--[[
    @desc: 初始化时间演员
    author:{author}
    time:2023-09-08 14:32:05
    @return:
]]
function InstanceScene:InitEventActor()
    local IAA = GameObject.Find("IAA")
    local go = self:GetGo(IAA,"AdNPC").gameObject
    local start = GameObject.Find("IAA/StartPos")
    local dstPos = GameObject.Find("IAA/DstPos")
    local facePos = GameObject.Find("IAA/DstPos/face")
    self.eventInstance = EventInstance:CreateActor() ---@type EventInstanceNew
    self.eventInstance.m_tempGo = go
    --self.eventInstance.m_rootGo = go.transform.parent.gameObject
    --self.eventInstance:CreateGo()
    -- local trempGo = GameObject.Instantiate(go)
    self.eventInstance:Init(IAA,go,start.transform.position, dstPos.transform.position,facePos.transform.position, 101)

end

function InstanceScene:InitSceneVFX()
    self.m_nightGos = UnityHelper.GetGameObjectsByTagToLuaTable("TAG_NIGHT_OBJ")
    self.m_dayGos = UnityHelper.GetGameObjectsByTagToLuaTable("TAG_DAY_OBJ")
    self:SceneSwtichDayOrLight(LightManager.isDay)
end

--[[
    @desc: 事件角色切换到返回状态
    author:{author}
    time:2023-09-12 13:52:38
    --@state: 
    @return:
]]
function InstanceScene:EventInstanceBack()
    if self.eventInstance then
        self.eventInstance.m_stateMachine:ChangeState(ActorDefine.State.EventInstanceLeaving)
    end
end

--[[
    @desc: 初始化场景光照
    author:{author}
    time:2023-04-03 15:09:08
    @return:
]]
function InstanceScene:InitSceneLight()
    LightManager:Init()
end

function InstanceScene:PlayBGM()
    local instanceBind = InstanceDataManager:GetInstanceBind()
    local bgm = instanceBind.bgm
    local bgmPlay = SoundEngine[bgm]
    SoundEngine:PlayBackgroundMusic(bgmPlay, true)
end

function InstanceScene:StopBGM()
    SoundEngine:StopBackgroundMusic(true)
end

--[[
    @desc: 创建工人物体
    author:{author}
    time:2023-04-06 20:14:43
    @return:
]]
function InstanceScene:CreateWorker(furnitureGo, roomGo, index, isBuy, roomId)
    local needWalk = false
    local worker = InstanceWorker:CreateActor()
    if not worker then
        return
    end
    local spawnPosTr = self:GetTrans(roomGo, "spawnPos")  -- 出生点

    local workPosTr = self:GetTrans(furnitureGo, "workPos") --工位点

    local facePosTr = self:GetTrans(furnitureGo, "face") --工位点朝向

    local actionPosTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index) or workPosTr --工作点

    local faceTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index .. "/face") or self:GetTrans(furnitureGo, "face")

    local timeType = InstanceDataManager:GetCurInstanceTimeType()

    if isBuy then
        worker:AddFlag(Actor.FLAG_INSTANCEWORKER_ON_WORKSIT)
    elseif timeType == InstanceDataManager.timeType.work then
        worker:AddFlag(Actor.FLAG_INSTANCEWORKER_ON_WORKING)
    elseif timeType == InstanceDataManager.timeType.eat then
        worker:AddFlag(Actor.FLAG_INSTANCEWORKER_ON_EATING)
    elseif timeType == InstanceDataManager.timeType.sleep then
        worker:AddFlag(Actor.FLAG_INSTANCEWORKER_ON_SLEEPING)
    end
    local ChoiceSpawnPos = function()
        if isBuy then
            return spawnPosTr.position
        elseif timeType == InstanceDataManager.timeType.work then
            return actionPosTr.position
        elseif timeType == InstanceDataManager.timeType.eat then
            --需要根据房间情况选择
            return workPosTr.position
        elseif timeType == InstanceDataManager.timeType.sleep then
            --需要根据房间情况选择
            return workPosTr.position
        end
    end
    local pfbName = ConfigMgr.config_character[tonumber(self.roomsData[roomId].furList[tostring(index)].worker.prefab)].prefab
    local roomData = {
        roomId = roomId,
        index = index
    }
    local prefab = "Assets/Res/Prefabs/character/Instance/" .. pfbName .. ".prefab"
    local spawnPos = ChoiceSpawnPos()
    local targetPos = workPosTr.position
    local targetRotation = faceTr.position
    local dismissPositon = nil
    local personID = 0
    local rootGo = nil

    rootGo = self.m_personRoot
    if worker then
        worker:Init(rootGo, prefab, spawnPos, targetPos, targetRotation, roomData, personID, actionPosTr.position)
    end

    return worker

end

function InstanceScene:NewCreateWorker(furnitureGo, roomGo, index, isBuy, roomId)

    local spawnPosTr = self:GetTrans(roomGo, "spawnPos")  -- 出生点

    local workPosTr = self:GetTrans(furnitureGo, "workPos") --工位点

    local facePosTr = self:GetTrans(furnitureGo, "face") --工位点朝向

    local actionPosTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index) or workPosTr --工作点

    local faceTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index .. "/face") or self:GetTrans(furnitureGo, "face")

    local timeType = InstanceDataManager:GetCurInstanceTimeType()

    local ChoiceSpawnPos = function()
        if isBuy then
            return spawnPosTr.position
        elseif timeType == InstanceDataManager.timeType.work then
            return actionPosTr.position
        elseif timeType == InstanceDataManager.timeType.eat then
            --需要根据房间情况选择
            return workPosTr.position
        elseif timeType == InstanceDataManager.timeType.sleep then
            --需要根据房间情况选择
            return workPosTr.position
        end
    end

    local pfbName = ConfigMgr.config_character[tonumber(self.roomsData[roomId].furList[tostring(index)].worker.prefab)].prefab
    local roomData = {
        roomId = roomId,
        index = index
    }
    local spawnPos = ChoiceSpawnPos()
    local targetPos = workPosTr.position
    local targetRotation = faceTr.position
    local dismissPositon = nil
    local personID = 0
    local rootGo = self.m_personRoot

    --重构测试调用
    local ActorManager = GameTableDefine.ActorManager

    local furData = self.roomsData[roomId].furList[tostring(index)]
    local data = {
        buildID = "instance", --所属建筑ID,这里把副本场景也看成一个building
        roomID = roomId, --所属房间ID
        furnitureID = furData.id, --所属家具ID
        furnitureIndex = index --所属家具位置索引
    }
    local prefabPath = "Assets/Res/Prefabs/character/Instance/" .. pfbName .. ".prefab"

    local worker = ActorManager:CreateActorSync("InstanceWorker",data)  ---@type InstanceWorkerClass
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, worker, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        worker:Init(worker.instanceID,go,{
            roomId = roomId,
            furIndex = index,
            workPosTr = workPosTr,
            workFaceTr =  facePosTr,
            actPosTr = actionPosTr,
            actFaceTr = faceTr,
            roomGO = roomGo,
            furGo = furnitureGo,
            spawnPos = spawnPos,
        },spawnPosTr.position,spawnPosTr.rotation,isBuy)
    end)
    
    return instanceWorker
end


--[[
    @desc: 切换相机lookat目标
    author:{author}
    time:2023-04-03 15:11:13
    @return:
]]
function InstanceScene:LookAtSceneGO(roomID, furIndex, cameraFocus, isBack,callback)
    if not furIndex then
        local roomGO = self:GetRoomGameObjectByID(roomID)
        self:LocatePosition(roomGO.transform.position, true,callback)
    elseif not cameraFocus then
        local furGO = self:GetSceneRoomFurnitureGo(roomID, furIndex)
        self:LocatePosition(furGO.transform.position, true,callback)
    else
        local furGO = self:GetSceneRoomFurnitureGo(roomID, furIndex)
        local size = cameraFocus.m_cameraSize
        local speed = cameraFocus.m_cameraMoveSpeed
        local target2DPosition = cameraFocus.transform.position
        local cb = nil
        if isBack then
            local data = self:GetSetCameraLocateRecordData() or {}
            data.isBack = true
            size = data.offset or size
            target2DPosition = data.offset2dPosition
            furGO = data.go3d
            cb = callback
        elseif not self:GetSetCameraLocateRecordData() then
            cb = function()
                -- local roomCfg = ConfigMgr.config_rooms[self.m_curRoomId]
                -- SoundEngine:PlaySFX(SoundEngine.ROOM_SFX[roomCfg.category[2]])
                if callback then
                    callback()
                end
            end
        end
        if not furGO or furGO:IsNull() then
            return
        end
        self:Locate3DPositionByScreenPosition(furGO, target2DPosition, size, speed, cb)
    end
end

--[[
    @desc: 显示所选的家具
    author:{author}
    time:2023-05-05 19:06:56
    --@furGO:
	--@preBuy: 
    @return:
]]
function InstanceScene:ShowSelectFurniture(furGO, preBuy)
    -- 先还原上次操作的对象
    if selectFurniture then
        if lastSelectIsPrebuy then
            -- 将材质还原
            self:RevertMeshRendererMaterial()
            selectFurniture:SetActive(false)
        else
            self:StopFurnitureGlinting(selectFurniture)
        end
    end
    if not furGO then
        return
    end
    local blink = self:GetGo(furGO,"blink")
    local skin = self:GetGo(furGO,"skin")
    
    lastSelectIsPrebuy = preBuy
    selectFurniture = furGO
    furGO:SetActive(true)
    if preBuy then   
        -- 替换Prebuy材质
        skin:SetActive(false)
        blink:SetActive(true)
        local meshRenderers = blink.gameObject:GetComponentsInChildren(typeof(MeshRenderer))
        local count = meshRenderers.Length
        for i=0,count-1 do
            local go = meshRenderers[i].gameObject
            if go.name ~= "shadow" then
                self:AddMeshRendererMaterial(go, preBuyMatPath)
            end
        end
    
    else
        self:StartFurnitureGlinting(furGO)
        return
    end

end

function InstanceScene:StopFurnitureGlinting(furnitureGo)
    if self.m_glinting and self.m_glinting.meshRenderers then
        GameTimer:StopTimer(self.m_glinting.timer)
        for i=1,#self.m_glinting.materials do
            local mat = self.m_glinting.materials[i]
            --if mat:HasProperty("flash") then
            --    mat:SetFloat("flash", 0);
            --end
            if mat:HasProperty("DoFlash") then
                mat:SetFloat("DoFlash", 0);
            end
        end
        local blink = self:GetGo(furnitureGo,"blink")
        local skin = self:GetGo(furnitureGo,"skin")
        
        blink:SetActive(false)
        skin:SetActive(true)
        
        -- MaterialPropertyBlock 方案因在手机上有功能异常所以弃用
        --for i=0,self.m_glinting.meshRenderers.Length -1  do
        --    UnityHelper.SetBlockToMaterial(self.m_glinting.meshRenderers[i],false)
        --end
        self.m_glinting = nil
    end
end

function InstanceScene:StartFurnitureGlinting(furnitureGo)
    if not furnitureGo then
        return
    end
    --self:StopFurnitureGlinting()

    local blink = self:GetGo(furnitureGo,"blink")
    local skin = self:GetGo(furnitureGo,"skin")
    blink:SetActive(true)
    skin:SetActive(false)
    local meshRenderers = blink:GetComponentsInChildren(typeof(MeshRenderer))
    local MaterialPropertyBlock = nil
    for i=0,meshRenderers.Length -1  do
        MaterialPropertyBlock = UnityHelper.SetBlockToMaterial(meshRenderers[i],true)
    end
    local materials = {}
     for i=0,meshRenderers.Length -1  do
         local meshRenderer = meshRenderers[i]
         for k=0,meshRenderer.materials.Length-1 do
             materials[#materials + 1] = meshRenderer.materials[k]
         end
     end
    
    
    local count = #materials
   
    self.m_glinting = {
        ["materials"] = materials,
        ["meshRenderers"] = meshRenderers,
        --["MaterialPropertyBlock"] = MaterialPropertyBlock,
        ["timer"] = nil,
        ["time"] = 0,
        ["deltaV"] = deltaV
    }

    for i=1,count do
        local mat = materials[i]
        if mat:HasProperty("DoFlash") then
            mat:SetFloat("DoFlash", 1);
        end
    end
    --local timer = GameTimer:CreateNewMilliSecTimer(glintingInterval, function()
    --
    --    local count = count
    --    local materials = materials
    --    self.m_glinting.time = self.m_glinting.time + self.m_glinting.deltaV
    --    if self.m_glinting.time > maxFlash then
    --        self.m_glinting.time = maxFlash
    --        self.m_glinting.deltaV = -self.m_glinting.deltaV
    --    end
    --    if self.m_glinting.time < 0 then
    --        self.m_glinting.time = 0
    --        self.m_glinting.deltaV = -self.m_glinting.deltaV
    --    end
    --     for i=1,count do
    --         local mat = materials[i]
    --         if mat:HasProperty("flash") then
    --             mat:SetFloat("flash", self.m_glinting.time);
    --         end
    --     end
    --    
    --    -- MaterialPropertyBlock 方案因在手机上有功能异常所以弃用
    --    --self.m_glinting.MaterialPropertyBlock:SetFloat("flash", self.m_glinting.time)
    --    --for i=0,self.m_glinting.meshRenderers.Length -1  do
    --    --    UnityHelper.SetBlockToMaterial(self.m_glinting.meshRenderers[i],true)
    --    --end
    --end, true, true)
    --self.m_glinting.timer = timer
end

function InstanceScene:AddMeshRendererMaterial(go, address, index)
    if not go then
        return
    end
    if not self.revertMaterialData then
        self.revertMaterialData = {}
    end

    local meshRenderer = go:GetComponent("MeshRenderer")
    if meshRenderer then
        local materials = meshRenderer.materials
        if not index then
            for i = 1, materials.Length do
                self:AddMeshRendererMaterial(go, address, i)
            end
            return
        end

        local index = materials.Length - index
        if index < 0 then
            return
        end
        local material = self:LoadMaterials(address)
        if not material then
            return
        end
        if not self.revertMaterialData[meshRenderer] then
            self.revertMaterialData[meshRenderer] = {}
        end
        table.insert(self.revertMaterialData[meshRenderer], { index = index, oldMaterial = materials[index] })
        UnityHelper.SetMeshRendererMaterial(meshRenderer, material, index)
        
        -- MaterialPropertyBlock 方案因在手机上有功能异常所以弃用
        -- materials[index] = material
        -- meshRenderer.materials = materials
    end
end


function InstanceScene:RevertMeshRendererMaterial()
    for meshRenderer,v in pairs(self.revertMaterialData or {}) do
        -- local materials = meshRenderer.materials
        -- materials[v.index] = v.oldMaterial
        -- meshRenderer.materials = materials
        for k,data in pairs(v) do
            UnityHelper.SetMeshRendererMaterial(meshRenderer, data.oldMaterial, data.index)
        end
        local SkodeGlinting = meshRenderer.gameObject:GetComponent("Skode_Glinting")
        if SkodeGlinting then
            SkodeGlinting:ResetMaterials()
        end
    end
    self.revertMaterialData = {}
end


--[[
    @desc: 刷新副本房间
    author:{author}
    time:2023-05-06 18:07:47
    --@roomID: 
    @return:
]]
function InstanceScene:RefreshScene(roomID)
    for k, v in pairs(self.roomsData) do
        self:RefreshRoom(v.roomID)
    end
end

--[[
    @desc: 刷新房子的相关表现
    author:{author}
    time:2023-04-03 15:12:03
    @return:
]]
function InstanceScene:RefreshRoom(roomID, index,isBuy)
    local roomData = self.roomsData[roomID]
    if roomData.state == 1 then
        --如果是修建状态,判断当前是否修建完成,如果完成则刷新显示并修改存档
        local currentTP = TimerMgr:GetCurrentServerTime(true)
        if currentTP >= InstanceModel:GetRoomUnlockTime(roomID) then
            InstanceDataManager:SetRoomData(roomID, roomData.buildTimePoint, 2)
            self.Rooms[roomID]:HideBubble()
        else
            --显示房屋悬浮图标
            self.Rooms[roomID]:ShowBubble()
        end
    end
    self.Rooms[roomID]:ShowRoom()
    if index then
        self.Rooms[roomID]:ShowFurniture(index, isBuy)
    else
        self.Rooms[roomID]:ShowFurniture(nil, isBuy)
    end
end

--[[
    @desc: 卸载场景中的所有员工
    author:{author}
    time:2023-04-03 15:12:23
    @return:
]]
function InstanceScene:UnloadWorker()
    Actor:DestroyAllActor()
end

--[[
    @desc: 获取某个房间的根节点
    author:{author}
    time:2023-04-27 10:26:06
    --@roomID: 
    @return:
]]
function InstanceScene:GetRoomGameObjectByID(roomID)
    return self.Rooms[roomID].GORoot
end

--[[
    @desc: 获取某个房间的InstanceRoom实例
    author:{author}
    time:2023-04-27 10:28:13
    --@roomID: 
    @return:
]]
function InstanceScene:GetSceneRoomItems(roomID)
    return self.Rooms[roomID]
end

--[[
    @desc: 获取家具GameObject
    author:{author}
    time:2023-04-27 10:25:34
    --@roomID:
	--@furnitureIndex: 
    @return:
]]
function InstanceScene:GetSceneRoomFurnitureGo(roomID, furnitureIndex, index)
    if not self.Rooms[roomID] then
        return nil
    end
    if index then
        return self.Rooms[roomID]:GetSubFurnitureGoByIndex(index)
    end

    return self.Rooms[roomID]:GetFurnitureGoByIndex(furnitureIndex)
end


--[[
    @desc: 初始化功能房间的相关数据，宿舍和食堂
    author:{author}
    time:2023-04-15 14:55:47
    --@roomID: 
    @return:
]]
function InstanceScene:InitInteractionRoomData(roomID)
    local roomConfig = GameTableDefine.InstanceModel:GetRoomConfigByID(roomID)
    local localData = {
        unlock = true,
        furnitures = {},
    }
    local roomData = {
        go = self:GetRoomGameObjectByID(roomID),
        config = roomConfig,
        employee = {},

        furnituresGo = {},
        drakFlag = {},
    }
    for k, v in pairs(self.Rooms[roomID].roomGO.furList) do
        local go
        -- for i,o in pairs(v.transform) do
        --     go = o.gameObject
        --     break
        -- end
        local workPos1 = self:GetGoOrNul(v, "workPos" .. "_" .. 1)
        if workPos1 then
            roomData.furnituresGo[k] = workPos1.transform.parent.gameObject
        end
    end
    for k, v in pairs(roomData.furnituresGo) do
        local state = self.roomsData[roomID].furList[tostring(k)].state
        if not localData.furnitures[k] then
            localData.furnitures[k] = {}
        end
        localData.furnitures[k].level = state
    end
    local SetData = function(interactions)
        if interactions then
            interactions:SetData(roomConfig, localData, roomData)
        end
    end
    if not self.Rooms[roomID].interactionsRoomData then
        self.Rooms[roomID].interactionsRoomData = roomData
    end
    --餐厅    
    if roomConfig.room_category == 3 then
        SetData(InteractionsManager:GetEntity(Actor.FLAG_INSTANCEWORKER_ON_EATING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
    --宿舍
    if roomConfig.room_category == 2 then
        SetData(InteractionsManager:GetEntity(Actor.FLAG_INSTANCEWORKER_ON_SLEEPING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
end

--刷新互动的物体的数据状态
function InstanceScene:RefreshInteractionRoomData(roomID)
    local roomConfig = GameTableDefine.InstanceModel:GetRoomConfigByID(roomID)
    local localData = {
        unlock = true,
        furnitures = {},
    }
    local roomData = {
        go = self:GetRoomGameObjectByID(roomID),
        config = roomConfig,
        employee = {},
        furnituresGo = {},
        drakFlag = {},
    }
    for k, v in pairs(self.Rooms[roomID].roomGO.furList) do
        local go
        -- for i,o in pairs(v.transform) do
        --     go = o.gameObject
        --     break
        -- end
        local workPos1 = self:GetGoOrNul(v, "workPos" .. "_" .. 1)
        if workPos1 then
            roomData.furnituresGo[k] = workPos1.transform.parent.gameObject
        end
    end
    for k, v in pairs(roomData.furnituresGo) do
        local state = self.roomsData[roomID].furList[tostring(k)].state
        if not localData.furnitures[k] then
            localData.furnitures[k] = {}
        end
        localData.furnitures[k].level = state
    end
    local RefreshData = function(interactions)
        if interactions then
            interactions.m_localData = localData
            interactions.m_sceneProcessData = roomData
            interactions.m_furnitureChanged = 1
        end
    end
    --餐厅    
    if roomConfig.room_category == 3 then
        RefreshData(InteractionsManager:GetEntity(Actor.FLAG_INSTANCEWORKER_ON_EATING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
    --宿舍
    if roomConfig.room_category == 2 then
        RefreshData(InteractionsManager:GetEntity(Actor.FLAG_INSTANCEWORKER_ON_SLEEPING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
end

--向角色发送ACTION事件标签
function InstanceScene:CallWorkerAct(roomId, index, msg)
    if not self.personList[roomId] or not self.personList[roomId][index] then
        return
    end
    local person = self.personList[roomId][index]
    local params = nil
    local msg = msg or person.EVENT_INSTANCE_WORKER_GOTO_ACTION
    person:Event(msg)
end

--标记人物可以成功执行接下来的任务
function InstanceScene:TagPeopleCanDo(roomId, index, interactionRoomId)
    if not self.personList[roomId] or not self.personList[roomId][index] then
        return
    end
    local person = self.personList[roomId][index]
    person.canSuccessDo = InstanceDataManager:GetCurInstanceTimeType()
    person.interactionRoomId = interactionRoomId
    print(Tools:ChangeTextColor("roomId:" .. roomId .. ",index:" .. index .. ",interactionRoomId:" .. interactionRoomId .. ",TYPE:" .. person.canSuccessDo, "00ff00"))
end

--[[s
    @desc: 刷新场景光照
    author:{author}
    time:2023-04-21 10:07:37
    @return:
]]
function InstanceScene:RefreshLight()
    local curInstanceTime = InstanceDataManager:GetCurInstanceTime()
    if curInstanceTime.Hour ~= InstanceModel.lastTime.Hour then
        if curInstanceTime.Hour == tonumber(InstanceDataManager.config_global.timeNode[1]) then
            EventManager:DispatchEvent("DAY_COME")
        elseif tonumber(curInstanceTime.Hour) == tonumber(InstanceDataManager.config_global.timeNode[2]) then
            EventManager:DispatchEvent("NIGHT_COME")
        end
    end
    self.lastTime = curInstanceTime
end

--[[
    @desc: 播放船的动画
    author:{author}
    time:2023-04-27 10:09:57
    @return:
]]
function InstanceScene:PlayShipAnim(shipFurIndex, isGO)
    for k, v in pairs(self.roomsData) do
        local roomID = v.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 4 and v.state == 2 then
            for furIndex, furData in pairs(v.furList) do
                if shipFurIndex == furData.index and furData.state == 1 then
                    local shipParent = self:GetSceneRoomFurnitureGo(roomID, furData.index)
                    local shipGO = shipParent.transform:GetChild(0).gameObject
                    local startPos = self:GetGo(shipParent, "startPos")
                    local middlePos = self:GetGo(shipParent, "middlePos")
                    local endPos = self:GetGo(shipParent, "endPos")
                    if isGO then
                        --print(string.format("船[%d]离港", shipFurIndex-6))
                        local goFeed = self:GetComp(shipGO, "goFB", "MMFeedbacks")
                        -- goFeed.Feedbacks[0].InitialPositionTransform = startPos.transform
                        -- goFeed.Feedbacks[0].DestinationPositionTransform = middlePos.transform
                        -- goFeed.Feedbacks[6].InitialPositionTransform = middlePos.transform
                        -- goFeed.Feedbacks[6].DestinationPositionTransform = endPos.transform
                        goFeed:PlayFeedbacks()
                    else
                        --print(string.format("船[%d]靠港", shipFurIndex-6))
                        local backFB = self:GetComp(shipGO, "backFB", "MMFeedbacks")
                        -- backFB.Feedbacks[1].InitialPositionTransform = endPos.transform
                        -- backFB.Feedbacks[1].DestinationPositionTransform = startPos.transform
                        backFB:PlayFeedbacks()
                    end
                end
            end
        end
    end
end

--设置船的气泡的状态
function InstanceScene:SetShipBubbles(shipFurIndex, isLeave, isOpen)
    if not self.shipHanders then
        self.shipHanders = {}
    end
    local loadtime = ConfigMgr.config_global.instance_ship_loadtime

    if not self.shipHanders[shipFurIndex] then
        self.shipHanders[shipFurIndex] = {
            loadValue = 0,
            loadtime = loadtime,
            iconId = 1
        }
    end
    self.shipHanders[shipFurIndex].isLeave = isLeave
    self.shipHanders[shipFurIndex].isOpen = isOpen
    if isLeave then
        self.shipHanders[shipFurIndex].loadValue = 0
    end
    for k, v in pairs(self.roomsData) do
        local roomID = v.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 4 and v.state == 2 then
            for furIndex, furData in pairs(v.furList) do
                if shipFurIndex == furData.index and furData.state == 1 then
                    self.shipHanders[shipFurIndex].iconId = ConfigMgr.config_furniture_level_instance[furData.id].resource_type or 1
                    if not self.shipHanders[shipFurIndex].go then
                        local shipParent = self:GetSceneRoomFurnitureGo(roomID, furData.index)
                        self.shipHanders[shipFurIndex].go = shipParent
                    end
                    FloatUI:SetObjectCrossCamera(self.shipHanders[shipFurIndex], function(view)
                        self.shipHanders[shipFurIndex].view:Invoke("RefreshShipBubbles", self.shipHanders[shipFurIndex].loadValue, self.shipHanders[shipFurIndex].isLeave, self.shipHanders[shipFurIndex].isOpen, self.shipHanders[shipFurIndex].iconId)
                    end, function()
                        if not self.shipHanders[shipFurIndex].view then
                            return
                        end
                        self.shipHanders[shipFurIndex].view:Invoke("RefreshShipBubbles", 0, true)
                    end, 0)
                end
            end
        end
    end
end


function InstanceScene:SceneSwtichDayOrLight(isDay)
    for name, go in pairs(self.m_nightGos or {}) do
        go:SetActive(not isDay)
    end
    for name, go in pairs(self.m_dayGos or {}) do
        go:SetActive(isDay)
    end

end

return InstanceScene