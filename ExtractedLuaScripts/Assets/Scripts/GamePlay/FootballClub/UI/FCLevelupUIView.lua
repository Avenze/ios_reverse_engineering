local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FootballClubModel = GameTableDefine.FootballClubModel
local CountryMode = GameTableDefine.CountryMode
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local ConfigMgr = GameTableDefine.ConfigMgr
local FCLevelupUI= GameTableDefine.FCLevelupUI
local ResMgr = GameTableDefine.ResourceManger

local FCLevelupUIView = Class("FCLevelupUIView", UIView)
function FCLevelupUIView:ctor()
  self.super:ctor()
  self.m_data = FCLevelupUI:GetUIModel()
end
function FCLevelupUIView:OnEnter()
    local cash = 0
    self:SetButtonClickHandler(self:GetComp("RootPanel/btn","Button"), function()
        self:DestroyModeUIObject()
        FootballClubModel:UpgradeClubLevel(function(success)
            if success then
                local countryId = CountryMode:GetCurrCountry() or 1
                local resourceId = ConfigMgr.config_money[countryId].resourceId
                ResMgr:AddLocalMoney(cash, nil, function()
                    EventManager:DispatchEvent("FLY_ICON", nil, resourceId, nil)
                    --2024-10-23添加俱乐部升级获得奖励
                    local type = CountryMode:GetCurrCountry()
                    local amount = cash
                    local change = 0
                    local position = "俱乐部等级提升"
                    GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
                end, nil, true, true)
            end        
        end)        
    end)
    local curCfg = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][self.m_data.LV ]
    self:SetText("RootPanel/icon/icon/num", self.m_data.LV + 1)
    cash = math.floor( curCfg.reward * FootballClubModel:GetTeamDataByID().synthesize )
    self:SetText("RootPanel/info_area/cash/num", Tools:SeparateNumberWithComma(cash))
    local imageSilder = self:GetComp("RootPanel/icon/prog_lv", "Image")
    imageSilder.fillAmount = self.m_data.curEXP / self.m_data.ExpUpperLimit    
    
    if self.m_data.LV < Tools:GetTableSize(ConfigMgr.config_club_data[FootballClubModel.m_cfg.id]) then
        local nextCfg = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][self.m_data.LV + 1]
        self:SetText("RootPanel/info_area/limit/atk/num/num",nextCfg.qualityLimit - curCfg.qualityLimit)
        self:SetText("RootPanel/info_area/limit/def/num/num",nextCfg.qualityLimit - curCfg.qualityLimit)
        self:SetText("RootPanel/info_area/limit/orz/num/num",nextCfg.qualityLimit - curCfg.qualityLimit)
        self:SetText("RootPanel/info_area/limit/str/num/num",nextCfg.strengthLimit - curCfg.strengthLimit)
    end

    local anim = UnityHelper.GetTheChildComponent(self.m_uiObj, "RootPanel/icon", "Animation")
    AnimationUtil.Play(anim, "UI_club_levelup", function()
        anim:Stop()
    end)
    
end

function FCLevelupUIView:OnExit()
    self.super:OnExit(self)
end

return FCLevelupUIView
