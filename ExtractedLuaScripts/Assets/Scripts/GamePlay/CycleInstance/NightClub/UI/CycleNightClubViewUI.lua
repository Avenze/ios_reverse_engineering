
---@class CycleNightClubViewUI
local CycleNightClubViewUI = GameTableDefine.CycleNightClubViewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleNightClubViewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_VIEW_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubViewUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubViewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_VIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleNightClubViewUI:OpenView()
    self:GetView():Invoke("InitView")
end
