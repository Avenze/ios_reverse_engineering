---@class CycleNightClubPiggyBankUI

local CycleNightClubPiggyBankUI = GameTableDefine.CycleNightClubPiggyBankUI
local GameUIManager = GameTableDefine.GameUIManager

function CycleNightClubPiggyBankUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_PIGGY_BANK_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubPiggyBankUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubPiggyBankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_PIGGY_BANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end



