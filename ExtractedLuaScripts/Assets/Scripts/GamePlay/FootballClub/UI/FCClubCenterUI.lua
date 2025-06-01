local FCClubCenterUI= GameTableDefine.FCClubCenterUI
local GameUIManager = GameTableDefine.GameUIManager
local FootballClubModel = GameTableDefine.FootballClubModel
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local FCHealthCenterUI = GameTableDefine.FCHealthCenterUI

FCClubCenterUI.ROOM_NUM = 10001

function FCClubCenterUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FC_CLUB_CENTER_UI, self.m_view, require("GamePlay.FootballClub.UI.FCClubCenterUIView"), self, self.CloseView)
    return self.m_view
end
function FCClubCenterUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FC_CLUB_CENTER_UI)
    self.m_view = nil
    self.m_Model= nil
    collectgarbage("collect")
end

-------------model-------------
function FCClubCenterUI:GetUIModel()
    if not self.m_Model then
        local playerTeam = FootballClubModel:GetTeamDataByID()
        local clubCenterData = FootballClubModel:GetRoomDataById(self.ROOM_NUM)
        --local healthCenterUIModel = FCHealthCenterUI:GetUIModel()
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        local clubCfg = ConfigMgr.config_club_data[FootballClubModel.m_cfg.id][FCData.LV]
        local playerTeamData = FootballClubModel:GetPlayerTeamData()
        local healthCenterData = FootballClubModel:GetRoomDataById(10005)
        local healthConterCfg = ConfigMgr.config_health_center[FootballClubModel.m_cfg.id][healthCenterData.LV]

        local strengthRevert = healthConterCfg.strength
        if healthCenterData.state ~= 2 then
            strengthRevert = 0
        end
        self.m_Model = 
        {
            LV = FCData.LV,
            SPlimit = FCData.SPlimit,
            SP = FootballClubModel:GetSP(),
            --SP = FCData.SP,
            name = playerTeamData.name,
            --head = playerTeamData.head,
            renewal = clubCfg.renewal,
            salary = clubCfg.salary,            
            synthesize = playerTeam.synthesize,
            atk = playerTeam.atk,
            def = playerTeam.def,
            ogz = playerTeam.ogz,
            limit = clubCfg.qualityLimit,
            SPRevert = strengthRevert,
        }
    end
    return self.m_Model
end

function FCClubCenterUI:RefreshUIModel()
    self.m_Model = nil
    self:GetUIModel()
end

