local FCPopupUI= GameTableDefine.FCPopupUI
local GameUIManager = GameTableDefine.GameUIManager
local EventManager = require("Framework.Event.Manager")
local FootballClubModel = GameTableDefine.FootballClubModel
local CfgMgr = GameTableDefine.ConfigMgr

function FCPopupUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_POPUP_UI, self.m_view, require("GamePlay.FootballClub.UI.FCPopupUIView"), self, self.CloseView)
    return self.m_view
end

function FCPopupUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_POPUP_UI)
    self.m_view = nil
    self.m_LevelupModel = nil
    collectgarbage("collect")
end

----------------------------LevelupUI------------------------------
function FCPopupUI:GetLevelupModel()
    if not self.m_LevelupModel then
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        local clubCfg = CfgMgr.config_club_data[FootballClubModel.m_cfg.id][FCData.LV]
        self.m_LevelupModel = 
        {
            LV = FCData.LV,
            cashAward = clubCfg.reward,
            curEXP = FCData.curEXP,
            ExpUpperLimit = clubCfg.comment,
        }
    end
    return self.m_LevelupModel
end

function FCPopupUI:GetLevelupUI()
    self:GetView():Invoke("EnterLevelupUI")
end
----------------------------------------------------------------

-----------------------TrainningReward--------------------------
function FCPopupUI:GetTrainningRewardModel()
    if not self.m_TrainningRewardModel then
        self.TrainningRewardModel = 
        {
            trainningName = "ds",
            time = 1,
            spenf = 1555,
            dsf = {}
        }
    end
    return self.TrainningRewardModel
end

function FCPopupUI:GetTrainningRewardUI()
    self:GetView():Invoke("EnterTrainningRewardUI")
end


----------------------------------------------------------------


-------------------------Settlement-----------------------------
function FCPopupUI:GetSettlementModel()
    if not self.m_SettlementModel then
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        self.m_SettlementModel = 
        {
            LV = FCData.LV,
            rank = 1,
            name = "ds",
            leaguelv = "",
            cashAward = 4155
        }
    end
    return self.m_SettlementModel
end

function FCPopupUI:GetSettlementUI()
    self:GetView():Invoke("EnterSettlementUI")
end
----------------------------------------------------------------
