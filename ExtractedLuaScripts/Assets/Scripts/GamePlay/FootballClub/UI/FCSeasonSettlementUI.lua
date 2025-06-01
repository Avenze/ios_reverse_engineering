local FCSeasonSettlementUI = GameTableDefine.FCSeasonSettlementUI
local GameUIManager = GameTableDefine.GameUIManager


function FCSeasonSettlementUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FOOTBALL_CLUB_SEASON_SETTLEMENT_UI, self.m_view, require("GamePlay.FootballClub.UI.FCSeasonSettlementUIView"), self, self.CloseView)
    return self.m_view
end

function FCSeasonSettlementUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FOOTBALL_CLUB_SEASON_SETTLEMENT_UI)
    self.m_view = nil
    collectgarbage("collect")
end