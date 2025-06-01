
---@class CycleIslandViewUI
local CycleIslandViewUI = GameTableDefine.CycleIslandViewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CycleIslandViewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_VIEW_UI, self.m_view, require("GamePlay.CycleInstance.Island.UI.CycleIslandViewUIView"), self, self.CloseView)
    return self.m_view
end

function CycleIslandViewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_VIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleIslandViewUI:OpenView()
    self:GetView():Invoke("InitView")
end
