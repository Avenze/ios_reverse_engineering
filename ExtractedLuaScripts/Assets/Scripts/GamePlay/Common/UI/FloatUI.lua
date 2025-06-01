---@class FloatUI
local FloatUI = GameTableDefine.FloatUI
local GameUIManager = GameTableDefine.GameUIManager
local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper
local FloatUIPrefabPath = "Assets/Res/UI/DisplayInSceneUI.prefab"
local GameResMgr = require("GameUtils.GameResManager")

local UIView = require "Framework.UI.View"
local FloatUIView = require("GamePlay.Common.UI.FloatUIViewNew")
local UIViews = {}

local LoadedPrefabs = false
--local FloatUIPrefab = nil
local FloatUIPrefabs = nil

---@private 加载FloatUI的Prefab
function FloatUI:LoadFloatUIPrefabs()
    if FloatUIPrefabs then
        return
    end
    FloatUIPrefabs = {}
    GameResMgr:ALoadAsync(FloatUIPrefabPath,self,function(h)
        local FloatUIPrefab = h.Result ---@type UnityEngine.GameObject
        local trans = FloatUIPrefab.transform
        local childCount = FloatUIPrefab.transform.childCount
        for i = 0, childCount - 1 do
            local childGO = trans:GetChild(i).gameObject
            FloatUIPrefabs[childGO.name] = childGO
        end
        LoadedPrefabs = true
    end)
end

---加载FloatUI的child
function FloatUI:LoadContentToFloatUIView(view,path)
    if LoadedPrefabs then
        local prefab = FloatUIPrefabs[path]
        if prefab then
            local go = GameObject.Instantiate(prefab)
            go.name = prefab.name
            UnityHelper.AddChildToParent(view.m_uiObj.transform,go.transform,false)
            go.transform.localScale = prefab.transform.localScale
            return go
        end
    else
        return nil
    end
end

function FloatUI:LoadFloatUIView(hander, go)
    if hander.view then
        return hander.guid, hander.view
    end

    local viewData = self:GetFreeFloatView(hander)
    if not viewData then
        local view = FloatUIView.new()
        local guid = GameUIManager:OpenFloatUI(ENUM_GAME_UITYPE.FLOAT_UI, view)
        UIViews[guid] = {guid = guid, view = view, hander = hander}
        UIViews[guid].m_type = hander.m_type or "others"
        hander.view = view
        hander.guid = guid
    else
        hander.view = viewData.view
        hander.guid = viewData.guid
        hander.view:SetStatus(3) -- ENUM_STATUS.OPENED = 3
    end
    hander.view:Invoke("SetEntity", go, hander)

    return hander.guid, hander.view
end

function FloatUI:FreeFloatUIView(hander, isOutOfScreen)
    if hander.view then
        hander.view:SetStatus(4) -- ENUM_STATUS.CLOSED = 4
        hander.view:Invoke("Init", isOutOfScreen)
        hander.view:StopTimer()
        UIViews[hander.guid].hander = nil
        hander.guid = nil
        hander.view = nil
    end
end

---引用这个FloatUI的物体被删除时，中断这个FloatUI的所有加载和执行
function FloatUI:BreakFloatUIView(handler)

    if handler.objectCrossCamera then
        for k,v in ipairs(handler.objectCrossCamera or {}) do
            if v ~= nil then
                v:SetOnBecameFunc(nil)
            end
        end
        handler.objectCrossCamera = nil
    end

    if handler.view then
        handler.view:SetStatus(4) -- ENUM_STATUS.CLOSED = 4
        handler.view:StopTimer()
        UIViews[handler.guid].hander = nil
        handler.guid = nil
        handler.view = nil
    end
end

function FloatUI:GetFreeFloatView(hander)
    for guid, viewData in pairs(UIViews) do
        if not viewData.hander and viewData.view:CheckViewFree() then
            local type = hander.m_type or "others"
            if type == viewData.m_type then
                viewData.hander = hander
                return viewData
            end
        end
    end
end

function FloatUI:DestroyAllFloatUIView()
    if true then
        return
    end
    for k,v in pairs(UIViews) do
        self:DestroyFloatUIView(k)
    end
end

function FloatUI:DestroyFloatUIView(guid)
    local destroyFunc = function(guid)
        GameUIManager:CloseFloatUI(ENUM_GAME_UITYPE.FLOAT_UI, guid)
        if UIViews[guid].hander then
            --2023年5月22日17:40:25 gxy 卸载floatUI时也把绑定在脚本上的事件卸载掉
            -- if UIViews[guid].hander.objectCrossCamera then
            --     local hander = UIViews[guid].hander
            --     for k,v in ipairs(hander.objectCrossCamera or {}) do
            --         v:SetOnBecameFunc(function(inScreen, isFocuse)
            --             self:OnBecameFunc(hander, nil, nil, hander.m_go, k, inScreen, isFocuse)
            --         end, true)
            --     end

            -- end
   
            UIViews[guid].hander.guid = nil
            UIViews[guid].hander.view = nil
        end
        UIViews[guid] = nil
    end

    if guid then
        destroyFunc(guid)
        return
    end
    for guid, viewData in pairs(UIViews) do
        destroyFunc(guid)
    end
    UIViews = {}
end

function FloatUI:SetObjectCrossCamera(hander, inCallback , outCallback, dis, shadowOff)
    if nil == shadowOff then
        shadowOff = true
    end

    local go = hander.m_go or hander.go or hander.gameObject
    if not go or go == -1 or go:IsNull() then
        return
    end
    
    if hander.objectCrossCamera then
        for k,v in ipairs(hander.objectCrossCamera) do
            v:SetOnBecameFunc(function(inScreen, isFocuse)
                self:OnBecameFunc(hander, inCallback, outCallback, go, k, inScreen, isFocuse)
            end, shadowOff)
        end
        if hander.objectCrossCamera then
            hander.objectCrossCamera[1]:Refresh(true)
        end
        return
    end

    hander.crosseCount = 0
    local groundTrans = UIView:GetTrans(go, type(dis) == 'string' and dis or "struct/DiTan")
    if groundTrans then
        local crossCamera = groundTrans.gameObject:GetComponent("ObjectCrossCamera")
        if not crossCamera then
            crossCamera = groundTrans.gameObject:AddComponent(typeof(CS.UnityEngine.UI.ObjectCrossCamera))
        end
        hander.objectCrossCamera = {crossCamera}

        local renderer = groundTrans:GetComponent("MeshRenderer")
        if renderer and not renderer:IsNull() then
            if renderer.enabled == false then
                renderer.enabled = true
                UnityHelper.ClearMaterials(renderer)
            end
            if renderer.renderingLayerMask == 0 then
                hander.objectCrossCamera[1]:HostIgnoreRenderer(true)
                renderer.enabled = false
            end
        end
    else
        hander.objectCrossCamera = UIView:GetComp(go, "UIPosition", "ObjectCrossCamera"):Clone(dis or 8)
    end
    for k,v in ipairs(hander.objectCrossCamera or {}) do
        v:SetOnBecameFunc(function(inScreen, isFocuse)
            self:OnBecameFunc(hander, inCallback, outCallback, go, k, inScreen, isFocuse)
        end, shadowOff)
    end
end

function FloatUI:OnBecameFunc(hander, inCallback, outCallback, go, flag, inScreen, isFocuse)
    if isFocuse then
        if inScreen then
            if inCallback then inCallback(hander.view) end
        elseif not inScreen then
            self:FreeFloatUIView(hander, true)
            if outCallback then outCallback() end
        end
        return
    end

    if inScreen then
        if hander.crosseCount > 0 then
            hander.crosseCount = UnityHelper.AddFlag(hander.crosseCount, 1 << flag)
            return
        end
        hander.crosseCount = UnityHelper.AddFlag(hander.crosseCount, 1 << flag)
    else
        hander.crosseCount = UnityHelper.RemoveFlag(hander.crosseCount, 1 << flag)
        if hander.crosseCount > 0 then
            return
        end
    end
    if hander.crosseCount ~= 0 then
        local guid, view = self:LoadFloatUIView(hander, go)
        if inCallback then inCallback(view) end
    else
        if outCallback then outCallback() end
        self:FreeFloatUIView(hander, true)
    end
end

function FloatUI:RemoveObjectCrossCamera(hander)
    if hander.objectCrossCamera then
        for k,v in ipairs(hander.objectCrossCamera or {}) do
            if v ~= nil then
                v:SetOnBecameFunc(nil)
            end
        end
        hander.objectCrossCamera = nil
    end
    self:FreeFloatUIView(hander)
end

--[[
    @desc: 直接绑定一个gameobject显示UI
    author:{author}
    time:2023-09-04 11:47:26
    --@go:
	--@callback:
	--@shadowOff: 
    @return:
]]
function FloatUI:BindGoToDisplay(go, callback, shadowOff)
    local objectCrossCamera = UIView:GetComp(go, "UIPosition", "ObjectCrossCamera"):Clone(8)
    local isDisplay = false
    if objectCrossCamera then
        for k, v in ipairs(objectCrossCamera) do
            if not isDisplay then
                v:SetOnBecameFunc(function(inScreen, isFocuse)
                    if inScreen then
                        local view = FloatUIView.new()
                        local guid = GameUIManager:OpenFloatUI(ENUM_GAME_UITYPE.FLOAT_UI, view)
                        UIViews[guid] = {guid = guid, view = view, objectCrossCamera = objectCrossCamera}
                        view:Invoke("SetEntity", go, nil)
                        if callback then
                            callback(view, guid)
                        end
                        isDisplay = true
                    end
                end)
            end
        end
        
    end
    
end
--[[
    @desc: 解绑一个gameobjec上的UI
    author:{author}
    time:2023-09-04 11:47:57
    --@view: 
    @return:
]]
function FloatUI:FreeBindFromDisplay(guid)
    local closeData = UIViews[guid]
    if not closeData then
        return
    end
    if closeData.objectCrossCamera then
        for k, v in ipairs(closeData.objectCrossCamera) do
            if v ~= nil then
                v:SetOnBecameFunc(nil)
            end
        end
        closeData.objectCrossCamera = nil
    end
    if closeData.view and closeData.view:GetUIObj() then
        closeData.view:Invoke("Init", true)
        closeData.view:StopTimer()
        closeData.view = nil
    end
    UIViews[guid] = nil
end

FloatUI:LoadFloatUIPrefabs()

return FloatUI
