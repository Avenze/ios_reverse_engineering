
local UIDemo = GameTableDefine.UIDemo

local GameUIManager = GameTableDefine.GameUIManager;
local EventManager = require("Framework.Event.Manager")

function UIDemo:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.UI_DEMO, self.m_view, require("GamePlay.City.UI.UIDemoView"), self, self.CloseView)
    return self.m_view
end

function UIDemo:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.UI_DEMO)
    self.m_view = nil
    collectgarbage("collect")
end