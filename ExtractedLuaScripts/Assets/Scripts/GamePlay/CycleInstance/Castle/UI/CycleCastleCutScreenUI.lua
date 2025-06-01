---@class CycleCastleCutScreenUI
local CycleCastleCutScreenUI = GameTableDefine.CycleCastleCutScreenUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleCastleCutScreenUI:GetView()
    if LocalDataManager:IsNewPlayerRecord() then
        return
    end
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_CUT_SCREEN_UI, self.m_view, require("GamePlay.CycleInstance.Castle.UI.CycleCastleCutScreenUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleCutScreenUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_CUT_SCREEN_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleCastleCutScreenUI:Play(spend, cb)
    self:GetView():Invoke("Play", cb, spend)
end