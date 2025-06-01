--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-05-25 13:48:15
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local FootballClubModel = GameTableDefine.FootballClubModel
local FootballClubController = GameTableDefine.FootballClubController
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI

local FCRoomUnlockUIView = Class("FCRoomUnlockUIView", UIView)

function FCRoomUnlockUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

local button = nil
local buldingGO = nil
local buildID = 0

function FCRoomUnlockUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)

    button = self:GetComp("RootPanel/SelectPanel/ClaimBtn","Button")
    self:SetButtonClickHandler(button,function()
        local buildData = FootballClubModel:GetRoomDataById(buildID)
        buildData.startTime = GameTimeManager:GetCurrentServerTime(true)
        buildData.state = 1
        LocalDataManager:WriteToFile()
        
        local buildCfg = ConfigMgr.config_football_club[FootballClubModel.m_cfg.id][buildID]
        -- local waitTime = buildCfg.unlockTime + buildData.startTime
        -- FootballClubController:CreateFloatUI(buildID,buldingGO,"ShowFootballBuildingUnlockButton",buildCfg,waitTime)  
        FootballClubController:ShowFootballClubBuildings()
        
        --花钱
        ResourceManger:SpendEuro(buildCfg.unlockRequire,nil,function()
            MainUI:RefreshCashEarn()
            GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 1, amount_new = tonumber(buildCfg.unlockRequire) or 0, position = "["..tostring(buildID).."]号俱乐部建筑解锁"})
        end)

        self:DestroyModeUIObject()

    end)
end

function FCRoomUnlockUIView:OnExit() 
	self.super:OnExit(self)
end

function FCRoomUnlockUIView:Show(id,go)
    buildID = id
    buldingGO = go
    --data
    local footballClubConfig =  ConfigMgr.config_football_club[FootballClubModel.m_cfg.id]
    local buildCfg = footballClubConfig[buildID]

    --view
    local image = self:GetComp("RootPanel/MidPanel/icon","Image")
    self:SetSprite(image,"UI_Common",buildCfg.icon)

    self:SetText("RootPanel/MidPanel/info/room_name",GameTextLoader:ReadText(buildCfg.name))

    self:SetText("RootPanel/MidPanel/info/desc",GameTextLoader:ReadText(buildCfg.desc))

    local time = buildCfg.unlockTime
    self:SetText("RootPanel/MidPanel/requirement/time/num", GameTimeManager:FormatTimeLength(time))

    button.interactable = ResourceManger:CheckEuro(buildCfg.unlockRequire)
    self:SetText("RootPanel/SelectPanel/ClaimBtn/cash/num",Tools:SeparateNumberWithComma(buildCfg.unlockRequire))

end

return FCRoomUnlockUIView