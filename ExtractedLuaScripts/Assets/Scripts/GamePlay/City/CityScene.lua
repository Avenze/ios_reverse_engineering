local Class = require("Framework.Lua.Class");
local BaseScene = require("Framework.Scene.BaseScene")
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local CityMode = GameTableDefine.CityMode
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local GameUIManager = GameTableDefine.GameUIManager
local CityMapUI = GameTableDefine.CityMapUI

local GameObject = CS.UnityEngine.GameObject
local Mathf = CS.UnityEngine.Mathf
local UnityHelper = CS.Common.Utils.UnityHelper

local CityScene = {} --Class("CityScene", BaseScene)

local buildingsGo = {}
local currBuidlingId = nil
local currBuidlingGo = nil

-- function CityScene:ctor()
--     self.super:ctor()
-- end


function CityScene:OnEnter()
    -- self.super:OnEnter()
    --self.buildingsGO = GameObject.Find("Buildings").gameObject
    self:InitDistricts()
    self:InitBuildings()
    -- MainUI:InitCameraScale("OutdoorScale", function()
    -- end, true)
end

-- function CityScene:OnPause()
-- end

-- function CityScene:OnResume()
-- end

function CityScene:OnExit()
    -- self.super:OnExit(self)
    buildingsGo = {}
    currBuidlingId = nil
    -- GameTableDefine.FloatUI:DestroyFloatUIView()
end

function CityScene:Update(dt)
    
end

function CityScene:InitDistricts()
    self.m_districtData = {}
    local districtData = CityMode:GetDistrictLocalData()
    local districtCfg = CityMode:GetCurrDistrictCfg()
    for i,v in ipairs(districtCfg or {}) do
        self.m_districtData[v.id].name = v.go_name
        if districtData.currId <= v.id then
            self.m_districtData[v.id].state = 1 --  1 解锁
        elseif v.id == districtData.unlockingId then
            self.m_districtData[v.id].state = districtData.unlockingTime
        else
            self.m_districtData[v.id].state = 0 -- 0 未解锁
            self.m_districtData[v.id].hint = StarMode:GetStar() >= v.star_need and "UnlockDistrictHint" or nil
        end
    end
    CityMapUI:SetDistrictData(self.m_districtData)
end

function CityScene:InitBuildingsGo()
    currBuidlingId = CityMode:GetCurrentBuilding()
    -- for k,v in pairs(self.buildingsGO.transform or {}) do
    --     buildingsGo[v.name] = v.gameObject
    -- end

    -- for i,v in pairs(ConfigMgr.config_buildings or {}) do
    --     if buildingsGo[v.mode_name] then
    --         local go = buildingsGo[v.mode_name]
    --         buildingsGo[i] = {name = v.mode_name, go = go, id = i}
    --         buildingsGo[v.mode_name] = nil
    --         if i == currBuidlingId then
    --             currBuidlingGo = buildingsGo[i].go
    --             currBuidlingGo:SetActive(true)
    --         end
    --         CityMode:CreateBuildingClass(i, go)
    --     end
    -- end
end


function CityScene:GetCurrBuidlingId()
    return currBuidlingId
end

function CityScene:LocateConstructionPosition(posID, showMovingAnimation)
    local modelGO = self:GetPosModelGO(posID)
    -- self:LocatePosition(modelGO.transform.position, showMovingAnimation)
end

function CityScene:InitSceneCameraScale(data, callback, isBack)
    local buildingId = CityMode:GetCurrentBuilding()
    local buildingsClass = CityMode:GetBuildingClass(buildingId)

    if isBack then
        local cameraFollow = self.cameraGO:GetComponent("CameraFollow")
        cameraFollow.Offset = cameraFollow.Offset.normalized * data.m_oldCameraSize
        self.super.InitSceneCameraScale(self, data, callback, isBack)
        return
    end
    
    local cb = function()
        self.__cameraLocateRecordData = nil
        if callback then callback() end
    end
    if buildingsClass then
        buildingsClass:SetBuildingOnCenter(data, nil, cb)
    else
        cb()
    end
end

function CityScene:ShowUnlockBuildingEffect()
    local unlockId, unlockCountDown = CityMode:GetUnlockingBuidlingInfo()
    if not unlockId then
        return
    end
    -- if self.m_playableDirector and not self.m_playableDirector:IsNull() then
    --     self.m_playableDirector:Play()
    --     return
    -- end
    -- GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/Prefabs/Timeline/TruckAnimation_" .. unlockId .. ".prefab", self, function(childGo)
    --     UnityHelper.AddChildToParent(GameObject.Find("TruckEvent").transform, childGo.transform)
    --     self.m_playableDirector = childGo:GetComponent("PlayableDirector")
    --     if self.m_playableDirector then
    --         self.storyCamera = UnityHelper.GetTheChildComponent(childGo, "CameraCG", "Camera");
    --         UnityHelper.SetCameraRenderType(self.storyCamera, 1);
    --         UnityHelper.AddCameraToCameraStack(GameUIManager:GetSceneCamera(), self.storyCamera, 0)
    --         self.m_playableDirector:Play()
    --     end
    -- end)
end

-- EventManager:RegEvent("EVENT_TRUCK_ARRIVED", function()
--     -- if CityMode:GetScene().m_playableDirector then
--     --     CityMode:GetScene().m_playableDirector:Pause()
--     -- end
-- end)
-- EventManager:RegEvent("EVENT_TRUCK_LEFT", function()
--     UnityHelper.RemoveCameraFromCameraStack(GameUIManager:GetSceneCamera(), GameStateManager:GetCurrScene().storyCamera)
-- 	UnityHelper.DestroyGameObject(GameStateManager:GetCurrScene().m_playableDirector.gameObject)
-- end)

return CityScene