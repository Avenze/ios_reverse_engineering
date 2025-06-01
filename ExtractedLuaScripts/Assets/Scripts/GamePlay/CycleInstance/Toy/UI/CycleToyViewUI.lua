
---@class CycleToyViewUI
local CycleToyViewUI = GameTableDefine.CycleToyViewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleToyViewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_VIEW_UI, self.m_view, require("GamePlay.CycleInstance.Toy.UI.CycleToyViewUIView"), self, self.CloseView)
    return self.m_view
end

function CycleToyViewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_VIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
    GameTableDefine.UIPopupManager:DequeuePopView(self)
end

function CycleToyViewUI:OpenView()
    self:GetView():Invoke("InitView")
end
