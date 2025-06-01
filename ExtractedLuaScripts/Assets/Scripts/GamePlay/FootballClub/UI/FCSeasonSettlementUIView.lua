local Class = require("Framework.Lua.Class")
local UIViwe = require("Framework.UI.View")
local leagueDataManager = GameTableDefine.FootballClubLeagueRankDataManager

local FCSeasonSettlementUIView = Class("FCSeasonSettlementUIView", UIViwe)

function FCSeasonSettlementUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCSeasonSettlementUIView:OnEnter()
    self:InitView()
end

function FCSeasonSettlementUIView:OnExit()
    self.super:OnExit(self)
end

function FCSeasonSettlementUIView:InitView()
    local playerTeamArchive = leagueDataManager:GetPlayerTeamArchiveData()
    --联赛排名
    local leagueRanking = leagueDataManager:GetLeagueRanking()
    self:SetText("RootPanel/require/rank/num", leagueRanking)

    --球队等级
    local teamLevel = playerTeamArchive.level
    self:SetText("RootPanel/require/clublv/num", teamLevel)

    --球队头像
    local headImage = self:GetComp("RootPanel/info/icon", "Image")
    -- local icon = playerTeamArchive.icon
    -- self:SetSprite(headImage,"UI_Common",icon)

    --球队名称
    local teamName = playerTeamArchive.name
    self:SetText("RootPanel/info/name", teamName)

    --当前联赛等级图标
    local leagueLevelImage = self:GetComp("RootPanel/leaguelv/icon", "Image")
    --local leagueLevelIcon = DataManager:GetPlayerLeagueArchive().icon
    -- self:SetSprite(headImage,"UI_Common",icon)

    --排名收入
    local prize = leagueDataManager:GetCurrentLeaguePrize()
    self:SetText("RootPanel/rankreward/reward/num", "+" .. prize)

    --"确认"按钮
    local promotable = leagueDataManager:GetPlayerLeagueArchive()
    local currentLeagueLevel = promotable.level
    local teamRanking = leagueDataManager:GetLeagueRanking()
    local isMaxLeagueLevel = leagueDataManager:IsMaxLeagueLevel()
    if isMaxLeagueLevel then --达到最大联赛等级,确认
        return
    end
    if teamRanking > 2 then --排名>2,不可晋级
    else
        if true then    --队伍等级满足,可晋级

        else    --队伍等级不足,查看

        end
    end
end

return FCSeasonSettlementUIView
