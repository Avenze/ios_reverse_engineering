local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FCTrainningRewardUI = GameTableDefine.FCTrainningRewardUI
local ResourceManger = GameTableDefine.ResourceManger
local FootballClubModel = GameTableDefine.FootballClubModel
local FootballClubController = GameTableDefine.FootballClubController


local FCTrainningRewardUIView = Class("FCTrainningRewardUIView", UIView)
function FCTrainningRewardUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    
end
function FCTrainningRewardUIView:OnEnter()    
    self.m_Model = FCTrainningRewardUI:GetUIModel()
    self:Init()
    self:Refresh()    
end

function FCTrainningRewardUIView:Init()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ConfirmBtn","Button"), function()
        FCTrainningRewardUI:TrainingReward()
        self:DestroyModeUIObject()

    end)

    self:SetImageSprite("RootPanel/MidPanel/bg/icon",self.m_Model.trainingCfg.icon)
    self:SetText("RootPanel/MidPanel/bg/abvalue/num",math.floor(self.m_Model.synthesize))
    self:SetText("RootPanel/MidPanel/bg/info/area/time/num/num",self.m_Model.trainingDuration)
    self:SetText("RootPanel/MidPanel/bg/info/area/strength/num",self.m_Model.strengthCost)

    self:SetText("RootPanel/MidPanel/bg/rewards/str/prog/value/now",math.floor(self.m_Model.SP))
    self:SetText("RootPanel/MidPanel/bg/rewards/str/prog/value/num",self.m_Model.SPlimit)
    self:SetText("RootPanel/MidPanel/bg/rewards/str/prog/value/up","+"..(Tools:SeparateNumberWithComma(self.m_Model.SPlimitAdd)))
    self:GetGo("RootPanel/MidPanel/bg/rewards/str/prog/value/up"):SetActive(self.m_Model.SPlimitAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/str/prog/up"):SetActive(self.m_Model.SPlimitAdd > 0)
    self:GetComp("RootPanel/MidPanel/bg/rewards/str/prog","Slider").value = self.m_Model.SP / self.m_Model.SPlimit

    --进攻
    self:GetComp("RootPanel/MidPanel/bg/rewards/value/offense/bg/line","Image").fillAmount = self.m_Model.atk / self.m_Model.qualityLimit
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/offense/value/num"):SetActive(self.m_Model.atkAdd > 0)
    self:SetText("RootPanel/MidPanel/bg/rewards/value/offense/value/num",math.floor(self.m_Model.atk))
    self:SetText("RootPanel/MidPanel/bg/rewards/value/offense/value/up","+"..self.m_Model.atkAdd)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/offense/value/up"):SetActive(self.m_Model.atkAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/offense/up"):SetActive(self.m_Model.atkAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/offense/value/max"):SetActive(self.m_Model.atkAdd <= 0)
    --防御
    self:GetComp("RootPanel/MidPanel/bg/rewards/value/defense/bg/line","Image").fillAmount = self.m_Model.def / self.m_Model.qualityLimit
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/defense/value/num"):SetActive(self.m_Model.atkAdd > 0)
    self:SetText("RootPanel/MidPanel/bg/rewards/value/defense/value/num",math.floor(self.m_Model.def))
    self:SetText("RootPanel/MidPanel/bg/rewards/value/defense/value/up","+"..self.m_Model.defAdd)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/defense/value/up"):SetActive(self.m_Model.defAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/defense/up"):SetActive(self.m_Model.defAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/defense/value/max"):SetActive(self.m_Model.atkAdd <= 0)
    --组织
    self:GetComp("RootPanel/MidPanel/bg/rewards/value/organizational/bg/line","Image").fillAmount = self.m_Model.org / self.m_Model.qualityLimit
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/organizational/value/num"):SetActive(self.m_Model.atkAdd > 0)
    self:SetText("RootPanel/MidPanel/bg/rewards/value/organizational/value/num",math.floor(self.m_Model.org))
    self:SetText("RootPanel/MidPanel/bg/rewards/value/organizational/value/up","+"..self.m_Model.orgAdd)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/organizational/value/up"):SetActive(self.m_Model.orgAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/organizational/up"):SetActive(self.m_Model.orgAdd > 0)
    self:GetGo("RootPanel/MidPanel/bg/rewards/value/organizational/value/max"):SetActive(self.m_Model.atkAdd <= 0)
end


function FCTrainningRewardUIView:Refresh()
    self.m_Model = FCTrainningRewardUI:GetUIModel()    
end

function FCTrainningRewardUIView:OnExit()    
    self.m_Model = nil
    self.super:OnExit(self)
    FootballClubController:ShowFootballClubBuildings()
end


return FCTrainningRewardUIView
