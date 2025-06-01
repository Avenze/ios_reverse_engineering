---@class CycleNightClubRankUI

local CycleNightClubRankUI = GameTableDefine.CycleNightClubRankUI
local GameUIManager = GameTableDefine.GameUIManager
local CityMode = GameTableDefine.CityMode

function CycleNightClubRankUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_RANK_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubRankUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubRankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_RANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end



