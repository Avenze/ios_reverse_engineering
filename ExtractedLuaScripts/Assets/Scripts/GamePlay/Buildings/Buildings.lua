local Class = require("Framework.Lua.Class")
local Building = Class("Building")

local EventTriggerListener = CS.Common.Utils.EventTriggerListener
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local UnityHelper = CS.Common.Utils.UnityHelper

local GameUIManager = GameTableDefine.GameUIManager
local CityMode = GameTableDefine.CityMode
local BuildingPop = GameTableDefine.BuildingPop
local UIDemo = GameTableDefine.UIDemo
local ConfigMgr = GameTableDefine.ConfigMgr
local SceneUnlockUI = GameTableDefine.SceneUnlockUI
local FloatUI = GameTableDefine.FloatUI
local ResMgr = GameTableDefine.ResourceManger
local CityMapUI = GameTableDefine.CityMapUI
local HouseMode = GameTableDefine.HouseMode
local StoryLineManager = GameTableDefine.StoryLineManager
local popButtonUIView = nil

--主要用于CityMapUIView的图标,地图信息
--存一些本地数据,然后点击调用的时候显示

function Building:ctor()
    -- self.buildingGo = nil
    -- self.buildingConfig = nil
    -- self.buidlingLocalData = nil
end

function Building:Init(id, config, localData)
    self.m_id = id
    self.m_config = config
    self.m_localData = localData
    -- self:SetBuildingClickHandler()
    self:GetBuildingGoUIView()
end

function Building:Update(dt)
end

function Building:Destroy()
    -- EventTriggerListener.Get(self.m_go):SetEventHandle(EventType.PointerClick, nil)
    popButtonUIView = {}
    -- BuildingPop:CloseOpPopView()
    -- FloatUI:RemoveObjectCrossCamera(self)
    self.m_id = nil
    self.m_config = nil
    self.m_localData = nil
end

-- function Building:SetBuildingClickHandler()
--     local data = ConfigMgr.config_buildings
--     local curBuildingId = CityMode:GetCurrentBuilding()
--     local currShowId = curBuildingId
--     local nextShowId = 9999

--     for k,v in pairs(data) do
--         if not curBuildingId then
--             currShowId = currShowId and math.min(k, currShowId) or k
--         end
--         if curBuildingId and k > currShowId and k < nextShowId then
--             nextShowId = k
--         end
--     end

--     local scene = CityMode:GetScene():SetButtonClickHandler(self.m_go, function()
--         if self.m_id ~= currShowId and self.m_id ~= nextShowId then
--             return
--         end
--         -- if self.m_id < (CityMode:GetCurrenBuildingId() or 0) then
--         --     return
--         -- end
--         self:ShowBuildingOperationPanel()
--     end)
-- end

function Building:GetBuildingInfo()
    local state = 0
    local name = GameTextLoader:ReadText("TXT_BUILDING_B" .. self.m_id .. "_NAME")
    --local icon = ConfigMgr.config_buildings[self.m_id]
    if self.m_config.company_qualities then -- 表示办公楼--0不显示 1解锁了 2待解锁
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            local unlockId, unlockCountDown = CityMode:GetUnlockingBuidlingInfo()
            local curr = CityMode:GetCurrentBuilding()
            local next = curr and ConfigMgr.config_buildings[curr].next_bid or 0
            if curr == self.m_id then
                state = 1
            elseif unlockId == self.m_id then
                state = 2 -- unlockCountDown
            elseif next == self.m_id then
                state = 2
            elseif curr == nil and CityMode:GetCurrMinId() == self.m_config.district then
                state = 2
            end
        end
    elseif self.m_config.building_type == 4 then --伟大工程
        --可能的状态包括 未解锁 解锁中 可升级 已满级...
        --经过分析,实际状态未 不显示0 要显示1.以及 解锁中的时间信息和 解锁后的等级信息
        --if not CityMode:CheckBuildingSatisfy(self.m_config.unlock_building) then
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            state = 1
        end
    elseif self.m_config.building_type == 3 then --买车
        -- 0不显示
        -- 1表示已经购买了 
        -- 2表示没有购买
        --if not CityMode:CheckBuildingSatisfy(self.m_config.unlock_building) then
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            state = self.m_config.starNeed <= GameTableDefine.StarMode:GetStar() and 1 or 2
        end
    elseif self.m_config.building_type == 5 then --工厂
        -- 0不显示
        -- 1表示已经购买了 
        -- 2表示没有购买
        --if not CityMode:CheckBuildingSatisfy(self.m_config.unlock_building) then
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            local data = LocalDataManager:GetCurrentRecord()
            if data["factory"] and data["factory"][self.m_config.mode_name] then
                state = 1
            else
                state = 2
            end
        end
    elseif self.m_config.building_type == 6 then --足球俱乐部
        -- 0表示未解锁前置建筑
        -- 1表示已经购买了 
        -- 2表示没有购买
        local data = LocalDataManager:GetCurrentRecord()
        local key = self.m_config.mode_name
        local buildName = "football" .. GameTableDefine.CountryMode.SAVE_KEY[self.m_config.country]
        --if not CityMode:CheckBuildingSatisfy(self.m_config.unlock_building) then
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            if data[buildName] and data[buildName][key] then
                state = 1
            else
                state = 2
            end
        end

    elseif self.m_config.building_type == 2 then --买房子
        -- 0不显示
        -- 1表示已经购买了 
        -- 2表示没有购买 但是 星星够了
        -- 3表示没有购买 同时 星星也不够
        --if not CityMode:CheckBuildingSatisfy(self.m_config.unlock_building) then
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            if HouseMode:GetLocalData(self.m_id) then
                state = 1
            elseif self.m_config.starNeed <= GameTableDefine.StarMode:GetStar() then
                state = 2
            else
                state = 3
            end
        end
    else --其他的东西(基本没了)
        -- 1表示已经购买了 
        -- 2表示没有购买
        --if not CityMode:CheckBuildingSatisfy(self.m_config.unlock_building) then
        if not StoryLineManager:IsCompleteStage(self.m_config.unlock_stage) then
            state = 0
        else
            state = HouseMode:GetLocalData(self.m_id) and 1 or 2
        end
    end
    self.m_constructState = state
    return name, nil, state
end

function Building:GetBuildingGoUIView()
    -- local data = ConfigMgr.config_buildings
    -- local curBuildingId = CityMode:GetCurrentBuilding()
    -- local currShowId = curBuildingId
    -- local nextShowId = 9999

    -- for k,v in pairs(data) do
    --     if not curBuildingId then
    --         currShowId = currShowId and math.min(k, currShowId) or k
    --     end
    --     if curBuildingId and k > currShowId and k < nextShowId then
    --         nextShowId = k
    --     end
    -- end
    -- if self.m_id ~= currShowId and self.m_id ~= nextShowId then
    --     FloatUI:RemoveObjectCrossCamera(self)
    --     return
    -- end
    -- FloatUI:SetObjectCrossCamera(self, function(view)
    --     if view then
    --         local info, icon, state = self:GetBuildingInfo()
    --         view:Invoke("ShowBuilingBumble", state, info, icon, self.m_go, self.m_id)
    --     end
    -- end)
    local name, icon, state = self:GetBuildingInfo()
    CityMapUI:ShowBuildingHint(self.m_id, self.m_config.mode_name, self.m_config.district, name, icon, state, self)

end

function Building:UpdateBuildingDetails()
    CityMapUI:UpdateBuildingDetails(self.m_config.district, self.m_config.mode_name, self)
end

function Building:ShowGreateDetail(buildingGo, hintGo)
    CityMapUI:ShowGreateDetail(buildingGo, hintGo, self)
end

function Building:ShowUnlockBuildingDetails(buildingGo, hintGo)
    local data = self.m_config
    local ownCash = ResMgr:GetLocalMoney()
    CityMapUI:ShowBuildingDetails(self, data.building_icon, data.unlock_require, ownCash, data.starNeed, data.money_enhance, self.m_constructState, buildingGo, hintGo)
end

function Building:GenerateOperationButtonsString(functionArray)
    local buttonNumber = 0
    local buttonName = {}
    local buttonValue = {}
    local buttonHint = {}
    for k, v in pairs(functionArray) do
        buttonNumber = buttonNumber + 1
        local value = "0"
        local hint = "0"
        table.insert(buttonValue, value)
        table.insert(buttonHint, hint)
        table.insert(buttonName, v)
    end
    return buttonNumber, buttonName, buttonValue, buttonHint
end

function Building:ShowBuildingOperationPanel()
    local buttonArray = {"BUILDING_DETAIL", "UPGRADE_BUILDING"}
    if CityMode:GetCurrentBuilding() == self.m_id then
        buttonArray = {"UPGRADE_BUILDING"}
    else
        buttonArray = {"UNLOCK_BUILDING"}
    end

    local buttonNumber, buttonName, buttonValue, buttonHint = self:GenerateOperationButtonsString(buttonArray)

    if buttonNumber == 1 then
        GameUIManager:SetEnableTouch(false)
        self:ClickeOperationButtonByName(buttonName[1])
    else
        --SoundEngine:playEffect(SoundConst.SFX_CLICK_TOTAL)
        -- if self.m_go then
        --     BuildingPop:ShowOpPop(self.m_go, self.m_id, self.m_level, self.m_name, buttonNumber, buttonName, buttonName, buttonValue, buttonHint)
        --     local view = self:GetBuildingGoUIView()
        --     if view then
        --         view:Invoke("Hide")
        --     end
        -- end
    end
end

function Building:ClickeOperationButtonByName(functionName)
    if functionName == "BUILDING_DETAIL" then
        UIDemo:GetView()
    elseif functionName == "UNLOCK_BUILDING" then
        SceneUnlockUI:ShowUnlockPanel(self.m_id)
    elseif functionName == "UPGRADE_BUILDING" then
        CityMode:EnterDefaultBuiding()
    end
    BuildingPop:HideOpPopView()
end

function Building:SetBuildingOnCenter(cameraFocus, isBack, cb)
    -- local scene = CityMode:GetScene()
    -- local target2DPosition = cameraFocus.position
    -- local size = cameraFocus.m_cameraSize
    -- if isBack then
    --     local data = scene:GetSetCameraLocateRecordData() or {}
    --     data.isBack = true
    --     size = data.offset or size
    --     target2DPosition = data.offset2dPosition or target2DPosition
    -- end
    -- scene:Locate3DPositionByScreenPosition(self.m_go, target2DPosition, size, cameraFocus.m_cameraMoveSpeed, cb)
end

return Building