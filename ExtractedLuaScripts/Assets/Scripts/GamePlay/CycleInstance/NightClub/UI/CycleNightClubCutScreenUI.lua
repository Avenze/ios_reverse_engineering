---@class CycleNightClubCutScreenUI
local CycleNightClubCutScreenUI = GameTableDefine.CycleNightClubCutScreenUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleNightClubCutScreenUI:GetView()
    if LocalDataManager:IsNewPlayerRecord() then
        return
    end
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_CUT_SCREEN_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubCutScreenUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubCutScreenUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_CUT_SCREEN_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleNightClubCutScreenUI:Play(spend, cb)
    self:GetView():Invoke("Play", cb, spend)
end