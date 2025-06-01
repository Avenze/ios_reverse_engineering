local FootballClubManagerInfoUI = GameTableDefine.FootballClubManagerInfoUI
local GameUIManager = GameTableDefine.GameUIManager


function FootballClubManagerInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FOOTBALL_CLUB_MANAGER_INFO_UI, self.m_view, require("GamePlay.FootballClub.UI.FootballClubManagerInfoUIView"), self, self.CloseView)
    return self.m_view
end

function FootballClubManagerInfoUI:CloseView()

end