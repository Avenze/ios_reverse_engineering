local FCLeagueRankUI = GameTableDefine.FCLeagueRankUI
local GameUIManager = GameTableDefine.GameUIManager
local dataManager = GameTableDefine.FootballClubLeagueRankDataManager
local FootballClubModel = GameTableDefine.FootballClubModel
local ConfigMgr = GameTableDefine.ConfigMgr
local FCStadiumUI = GameTableDefine.FCStadiumUI

function FCLeagueRankUI:GetView()
    --刷新一次数据
    dataManager:InitFootballClubLeagueData()
    self:RefreshModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_LENAGUE_RANK_UI, self.m_view, require("GamePlay.FootballClub.UI.FCLeagueRankUIView"), self, self.CloseView)
    return self.m_view
end

function FCLeagueRankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_LENAGUE_RANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end


function FCLeagueRankUI:GetUIModel()
    if not self.m_Model then
        local matchData = FootballClubModel:GetMatchData()
        local leagueList = dataManager.leagueListCfg
        local leagueDate = FootballClubModel:GetLeagueData()
        local teamData = FootballClubModel:GetPlayerTeamData()
        local teamList = FCStadiumUI:CreateTeamList()
        self.m_Model = {
            rank = dataManager:GetLeagueRanking(),
            leagueList = leagueList,
            curLeagueLevel = leagueDate.currLeagueLV,
            leagueLevel = leagueDate.leagueLV,
            leagueCfg = ConfigMgr.config_league[FootballClubModel.m_cfg.id][leagueDate.currLeagueLV],
            unlockable = leagueDate.unlockable,
            teamData = teamData or ConfigMgr.config_team_pool[FootballClubModel.m_cfg.id][0],
            --比赛次数
            frequency = matchData.frequency,
            --总比赛次数
            totalFrequency = (#teamList - 1) * 2,
        }
    end

    return self.m_Model
end

function FCLeagueRankUI:RefreshModel()
    self.m_Model = nil 
    self.m_Model = self:GetUIModel()
end

function FCLeagueRankUI:ShowLeagueList()
    self:GetView():Invoke("ShowLeagueList")
end

function FCLeagueRankUI:ShowRankList()
    self:GetView():Invoke("ShowRankList")
end
