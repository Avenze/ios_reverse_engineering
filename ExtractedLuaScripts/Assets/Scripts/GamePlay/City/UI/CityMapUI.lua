
local CityMapUI = GameTableDefine.CityMapUI

local CountryMode = GameTableDefine.CountryMode
local FlyIconsUI = GameTableDefine.FlyIconsUI
local MainUI = GameTableDefine.MainUI
local GameUIManager = GameTableDefine.GameUIManager
local CityMode = GameTableDefine.CityMode
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local SoundEngine = GameTableDefine.SoundEngine
local CompanyMode = GameTableDefine.CompanyMode

--先是cityMapUI,后来加了伟大工程
--因为之前的难以复用,所以就照着别人已经写了的代码复制了一份xxxGreate,之类的代码
function CityMapUI:GetView()
    self.path = "CITY_MAP"
    local currcountry = CountryMode:GetCurrCountry()

    for k,v in pairs(ConfigMgr.config_country) do
        if currcountry == v.id then
            self.path = v.ui
        end
    end
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE[self.path], self.m_view, require("GamePlay.City.UI.CityMapUIView"), self, self.CloseView)
    return self.m_view
end

function CityMapUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE[self.path])
    self.m_view = nil
    collectgarbage("collect")
end

function CityMapUI:ShowMap()
    if self.m_view ~= nil then
        self:CloseView()
    end
    self:GetView()
    local musicClio = SoundEngine["Citymap_BGM"]
    SoundEngine:PlayBackgroundMusic(musicClio, true)
end

function CityMapUI:SetDistrictData(data)
    self:GetView():Invoke("SetDistrictData", data)
end

function CityMapUI:ShowBuildingHint(id, buildingName, districtId, name, icon, state, buildingClass)
    if CityMode:IsDistrictUnlock(districtId) or (CityMode:IsTypeGreatBuilding(id) and state == 0)then
        local target = "MapRect/Viewport/Map/district_"..districtId.."/unlock/" .. buildingName
        local cameraPos = "MapRect/Viewport/Map/district_"..districtId.."/CameraPos"
        self:GetView():Invoke("ShowBuildingHint", id, target, name, icon, state, cameraPos, buildingClass)
    end
end

function  CityMapUI:UpdateBuildingDetails(districtId,  buildingName, buildingClass)
    if CityMode:IsDistrictUnlock(districtId) then
        local target = "MapRect/Viewport/Map/district_"..districtId.."/unlock/" .. buildingName
        self:GetView():Invoke("UpdateBuildingDetails", target, buildingClass)
    end
end

function CityMapUI:ShowBuildingDetails(class, logo, unlockCash, ownCash, starNeed, moneyEnhance, state, buildingGo, hintGo)
    self:GetView():Invoke("ShowBuildingDetails", class, logo, unlockCash, ownCash, starNeed, moneyEnhance, state, buildingGo, hintGo)
end

function CityMapUI:ShowGreateDetail(buildingGo, hintGo, class)
    self:GetView():Invoke("ShowGreateDetail", buildingGo, hintGo, class)
end

function CityMapUI:LookAtBuilding(buildingId)
    local cfg = ConfigMgr.config_buildings[buildingId]
    local buildingName = cfg.mode_name
    local districtId = cfg.district
    local target = "MapRect/Viewport/Map/district_"..districtId.."/unlock/" .. buildingName
    self:GetView():Invoke("LookAt", target)
end

function CityMapUI:LookAt(target)
    self:GetView():Invoke("LookAt", target)    
end

--切换国家地图
function CityMapUI:ToggleCountryMap(cb)                               
    CityMode:OnExit()
    
    --MainUI:SetPowerBtnState(false)

    --CityMode:EnterDefaultBuiding()--进入默认的场景
    FlyIconsUI:SetScenceSwitchEffect(1,function()
        GameStateManager.m_currentGameState = 3
        GameStateManager:SetCurrentGameState(GameStateManager.GAME_STATE_CITY)--修改游戏状态为大地图状态用于进入大地图

        MainUI:RefreshCashEarn()
        MainUI:PlayUIAnimation(false)
        EventManager:DispatchEvent(GameEventDefine.ReCalculatePowerUsed)
        EventManager:DispatchEvent(GameEventDefine.ReCalculateTotalPower)
        MainUI:UpdateResourceUI() 
    end)
                                                 
end

--是否处于打开的状态
function CityMapUI:isInCity()
    for k,v in pairs(ConfigMgr.config_country) do
        if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE[v.ui]) then
            
            return true
        end
    end    
    return false
end