

local HUD = GameTableDefine.HUD
local GameUIManager = GameTableDefine.GameUIManager;
local EventManager = require("Framework.Event.Manager")

function HUD:GetView()
    self.m_mainView = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.HUD, self.m_mainView, require("GamePlay.Floors.UI.HUDView"), self, self.CloseView)
    return self.m_mainView
end

function HUD:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.HUD)
    self.m_mainView = nil
    collectgarbage("collect")
end