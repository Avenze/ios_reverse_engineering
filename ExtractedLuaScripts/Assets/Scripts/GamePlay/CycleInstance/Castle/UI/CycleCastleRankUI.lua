---@class CycleCastleRankUI

local CycleCastleRankUI = GameTableDefine.CycleCastleRankUI
local GameUIManager = GameTableDefine.GameUIManager
local CityMode = GameTableDefine.CityMode

function CycleCastleRankUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_RANK_UI, self.m_view, require("GamePlay.CycleInstance.Castle.UI.CycleCastleRankUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleRankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_RANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end



