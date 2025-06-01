local FCLevelupUI= GameTableDefine.FCLevelupUI
local GameUIManager = GameTableDefine.GameUIManager
local FootballClubModel = GameTableDefine.FootballClubModel
local CfgMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
function FCLevelupUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_LEVEL_UP_UI , self.m_view, require("GamePlay.FootballClub.UI.FCLevelupUIView"), self, self.CloseView)
    return self.m_view
end
function FCLevelupUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_LEVEL_UP_UI)
    self.m_view = nil
    self.m_Model = nil
    collectgarbage("collect")
end


-------------model-------------
function FCLevelupUI:GetUIModel()
    if not self.m_Model then
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        local clubCfg = CfgMgr.config_club_data[FootballClubModel.m_cfg.id][FCData.LV]
        self.m_Model = 
        {
            LV = FCData.LV,
            cashAward = clubCfg.reward,
            curEXP = FCData.curEXP,
            ExpUpperLimit = clubCfg.exp,
        }
    end
    return self.m_Model
end