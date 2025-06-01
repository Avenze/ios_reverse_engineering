
---@class CycleCastleViewUI
local CycleCastleViewUI = GameTableDefine.CycleCastleViewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleCastleViewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_VIEW_UI, self.m_view, require("GamePlay.CycleInstance.Castle.UI.CycleCastleViewUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleViewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_VIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
    GameTableDefine.UIPopupManager:DequeuePopView(self)
end

function CycleCastleViewUI:OpenView()
    self:GetView():Invoke("InitView")
end
