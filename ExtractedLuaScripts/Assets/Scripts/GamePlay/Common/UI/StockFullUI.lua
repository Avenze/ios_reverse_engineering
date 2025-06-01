local StockFullUI = GameTableDefine.StockFullUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function StockFullUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.STOCK_FULL_UI, self.m_view, require("GamePlay.Common.UI.StockFullUIView"), self, self.CloseView)
    return self.m_view
end

function StockFullUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.STOCK_FULL_UI)
    self.m_view = nil
    collectgarbage("collect")
end