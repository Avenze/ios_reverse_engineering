local FCLeagueUpUI = GameTableDefine.FCLeagueUpUI
local GameUIManager = GameTableDefine.GameUIManager
local dataManager = GameTableDefine.FootballClubLeagueRankDataManager
local FootballClubModel = GameTableDefine.FootballClubModel
local rankDataManager = GameTableDefine.FootballClubLeagueRankDataManager
local ConfigMgr = GameTableDefine.ConfigMgr

function FCLeagueUpUI:GetView()
    --刷新一次数据
    dataManager:InitFootballClubLeagueData()
    self:RefreshModel()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_LEAGUE_UP_UI, self.m_view, require("GamePlay.FootballClub.UI.FCLeagueUpUIView"), self, self.CloseView)
    return self.m_view
end

function FCLeagueUpUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_LEAGUE_UP_UI)
    self.m_view = nil
    self.m_Model = nil
    collectgarbage("collect")
end


function FCLeagueUpUI:GetUIModel()
    if not self.m_Model then
        local leagueList = dataManager.leagueListCfg
        local leagueDate = FootballClubModel:GetLeagueData()
        local PlayerTeamData = FootballClubModel:GetPlayerTeamData()
        self.m_Model = {
            leagueList = leagueList,
            curLeagueLevel = leagueDate.currLeagueLV,
            lastleagueLevel = leagueDate.currLeagueLV -1 ,
            curLeagueCfg = rankDataManager:GetFootballLeagueDataByLevel(leagueDate.currLeagueLV),
            lastleagueCfg = rankDataManager:GetFootballLeagueDataByLevel(leagueDate.currLeagueLV -1),
            teamCfg = PlayerTeamData or ConfigMgr.config_team_pool[FootballClubModel.m_cfg.id][0],

        }
    end

    return self.m_Model
end

function FCLeagueUpUI:RefreshModel()
    self.m_Model = nil 
    self.m_Model = self:GetUIModel()
end
