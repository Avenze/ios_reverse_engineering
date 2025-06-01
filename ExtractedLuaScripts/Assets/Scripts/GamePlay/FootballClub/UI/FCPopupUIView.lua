local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FCPopupUI= GameTableDefine.FCPopupUI

local FootballClubModel = GameTableDefine.FootballClubModel
local ResMgr = GameTableDefine.ResourceManger
local CountryMode = GameTableDefine.CountryMode
local ConfigMgr = GameTableDefine.ConfigMgr

local FCPopupUIView = Class("FCPopupUIView", UIView)
function FCPopupUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCPopupUIView:OnEnter()
    -- self:SetButtonClickHandler(self:GetComp(".....buttonPath...","Button"), function()
    --     self:DestroyModeUIObject()
    -- end)
    self:GetGo("TrainningReward"):SetActive(false)
    self:GetGo("Settlement"):SetActive(false)
    self:GetGo("Levelup"):SetActive(false)
        
end

--升级UI
function FCPopupUIView:EnterLevelupUI()
    self.m_data = FCPopupUI:GetLevelupModel()
    self:GetGo("Levelup"):SetActive(true)
    self:SetButtonClickHandler(self:GetComp("Levelup/btn","Button"), function()
        self:DestroyModeUIObject()
        FootballClubModel:UpgradeClubLevel(function(success)
            if success then
                local countryId = CountryMode:GetCurrCountry() or 1
                local resourceId = ConfigMgr.config_money[countryId].resourceId
                ResMgr:AddLocalMoney(self.m_data.cashAward, nil, function()
                    EventManager:DispatchEvent("FLY_ICON", nil, resourceId, nil)
                end, nil, true)
            end        
        end)        
    end)
    self:SetText("Levelup/level/bg/num", self.m_data.LV)
    self:SetText("Levelup/reward/reward/num", self.m_data.cashAward)
    local imageSilder = self:GetComp("Levelup/level/prog_lv", "Image")
    imageSilder.fillAmount = self.m_data.curEXP / self.m_data.ExpUpperLimit 
end

--训练结果UI
function FCPopupUIView:EnterTrainningRewardUI()
    self.m_data = FCPopupUI:GetTrainningRewardModel()
    self:GetGo("Settlement"):SetActive(true)
    self:SetButtonClickHandler(self:GetComp("Settlement/btn","Button"), function()
        self:DestroyModeUIObject()
        local countryId = CountryMode:GetCurrCountry() or 1
        local resourceId = ConfigMgr.config_money[countryId].resourceId
        ResMgr:AddLocalMoney(self.m_data.cashAward, nil, function()
            EventManager:DispatchEvent("FLY_ICON", nil, resourceId, nil)
        end, nil, true)                            
    end)
    self:SetText("Settlement/level/bg/num", self.m_data.LV)
    self:SetText("Settlement/require/rank/num", self.m_data.name)
    self:SetText("Settlement/info/name", self.m_data.rank)
    self:SetText("Settlement/rankreward/reward/num", self.m_data.cashAward)
    self:SetText("Settlement/leaguelv/txt", self.m_data.leaguelv)
end

--赛季结算UI
function FCPopupUIView:EnterSettlementUI()
    self.m_data = FCPopupUI:GetSettlementModel()
    self:GetGo("Settlement"):SetActive(true)
    self:SetButtonClickHandler(self:GetComp("Settlement/btn","Button"), function()
        self:DestroyModeUIObject()
        local countryId = CountryMode:GetCurrCountry() or 1
        local resourceId = ConfigMgr.config_money[countryId].resourceId
        ResMgr:AddLocalMoney(self.m_data.cashAward, nil, function()
            EventManager:DispatchEvent("FLY_ICON", nil, resourceId, nil)
        end, nil, true)                            
    end)
    self:SetText("Settlement/level/bg/num", self.m_data.LV)
    self:SetText("Settlement/require/rank/num", self.m_data.name)
    self:SetText("Settlement/info/name", self.m_data.rank)
    self:SetText("Settlement/rankreward/reward/num", self.m_data.cashAward)
    self:SetText("Settlement/leaguelv/txt", self.m_data.leaguelv)

end


function FCPopupUIView:OnExit()
    self.super:OnExit(self)
    self.m_data = nil
end

return FCPopupUIView
