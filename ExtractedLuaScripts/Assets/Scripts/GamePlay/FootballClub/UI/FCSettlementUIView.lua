local Class = require("Framework.Lua.Class")
local DataManager = GameTableDefine.FootballClubLeagueRankDataManager
local UIViwe = require("Framework.UI.View")
local leagueDataManager = GameTableDefine.FootballClubLeagueRankDataManager
local UI = GameTableDefine.FCSettlementUI
local UnityHelper = CS.Common.Utils.UnityHelper
local FootballClubModel = GameTableDefine.FootballClubModel
local FootballClubController = GameTableDefine.FootballClubController
local ResourceManger = GameTableDefine.ResourceManger

local FCSettlementUIView = Class("FCSettlementUIView", UIViwe)

function FCSettlementUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCSettlementUIView:OnEnter()
    self:InitView()
end

function FCSettlementUIView:OnExit()
    self.super:OnExit(self)
end

function FCSettlementUIView:InitView()
    local model = UI:GetUIModel()
    self:SetButtonClickHandler(self:GetComp("RootPanel/btn","Button"),function()
        UI:FinishSeason(model.ranking)
    end)
    if model.ranking <= 2 then
        self:SetText("RootPanel/title/txt",GameTextLoader:ReadText("TXT_FBCLUB_DESC_1"))
    else
        self:SetText("RootPanel/title/txt",GameTextLoader:ReadText("TXT_LEAGUE_DESC_10"))
    end
    self:SetImageSprite("RootPanel/title/bg",model.palyerTeamCfg.icon_bg)
    self:SetImageSprite("RootPanel/title/bg/icon",model.palyerTeamCfg.icon)
    self:SetImageSprite("RootPanel/info_area/league/leaguelv/icon",model.leagueCfg.icon)
    self:SetText("RootPanel/info_area/league/leaguelv/txt",GameTextLoader:ReadText(model.leagueCfg.name))
    self:SetText("RootPanel/info_area/league/rank/num",model.ranking)
    self:SetText("RootPanel/info_area/rankreward/reward/num",Tools:SeparateNumberWithComma(model.price))
    self:GetGo("RootPanel/info_area/tip/up"):SetActive(model.advanceState == UI.leagueResult.promotable)
    self:GetGo("RootPanel/info_area/tip/fail"):SetActive(model.advanceState == UI.leagueResult.noPromotable)
    self:GetGo("RootPanel/info_area/tip/max"):SetActive(model.advanceState == UI.leagueResult.maxLevel)
end

return FCSettlementUIView
