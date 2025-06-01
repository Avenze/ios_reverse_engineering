local FCSettlementUI = GameTableDefine.FCSettlementUI
local GameUIManager = GameTableDefine.GameUIManager
local leagueDataManager = GameTableDefine.FootballClubLeagueRankDataManager
local FootballClubModel = GameTableDefine.FootballClubModel
local FootballClubController = GameTableDefine.FootballClubController
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local FCLeagueRankUI = GameTableDefine.FCLeagueRankUI

FCSettlementUI.leagueResult = {
    --可晋级
    promotable = 1,
    --不可晋级
    noPromotable = 2,
    --达到最高等级
    maxLevel = 3
}

function FCSettlementUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_SETTLEMENT_UI, self.m_view, require("GamePlay.FootballClub.UI.FCSettlementUIView"), self, self.CloseView)
    return self.m_view
end

function FCSettlementUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_SETTLEMENT_UI)
    self.m_Model= nil
    self.m_view = nil
    collectgarbage("collect")
end

function FCSettlementUI:GetUIModel()
    if not self.m_Model then
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)    
        local LeagueData = FootballClubModel:GetLeagueData()
        local ranking = leagueDataManager:GetLeagueRanking()
        local price = leagueDataManager:GetCurrentLeaguePrize()
        local nextLeagueCfg = ConfigMgr.config_league[FootballClubModel.m_cfg.id][LeagueData.leagueLV]
        local advanceState = self:GetLeagueAdvanceState()
        self.m_Model = 
        {
            ranking = ranking,
            leagueCfg = ConfigMgr.config_league[FootballClubModel.m_cfg.id][LeagueData.currLeagueLV],
            price = price,
            palyerTeamCfg = ConfigMgr.config_team_pool[FootballClubModel.m_cfg.id][0],
            advanceState = advanceState
        }

    end
    return self.m_Model
end

function FCSettlementUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end

function FCSettlementUI:GetLeagueAdvanceState()
    local IsMaxLeagueLevel = leagueDataManager:IsMaxLeagueLevel()
    local IsMaxLeagueLevelUnlocked = leagueDataManager:IsMaxLeagueLevelUnlocked()
    local ranking = leagueDataManager:GetLeagueRanking()
    if IsMaxLeagueLevel then
        return FCSettlementUI.leagueResult.maxLevel
    elseif IsMaxLeagueLevelUnlocked and ranking <= 2 then
        return FCSettlementUI.leagueResult.promotable
    else
        return FCSettlementUI.leagueResult.noPromotable
    end

end

function FCSettlementUI:FinishSeason(rank)
    --得钱
    ResourceManger:AddLocalMoney(self.m_Model.price, nil, function() end, nil, true, true)
    GameSDKs:TrackForeign("cash_event", {type_new = 2, change_new = 0, amount_new = tonumber(self.m_Model.price) or 0, position = "俱乐部赛季奖励"})
    --修改存档
    FootballClubModel:FinishSeason(rank)
    --跳转页面
    if self.m_Model.ranking <= 2 then
        --跳转到联赛列表页面
        FCLeagueRankUI:ShowLeagueList()
    else
        --跳转到续约页面
        FootballClubController:ClickClubCenter(FootballClubController.sceneGo["ClubCenter"].root,10001)
    end  
    self:CloseView()

end