local OrderFinishUI = GameTableDefine.OrderFinishUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function OrderFinishUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ORDER_FINISH_UI, self.m_view, require("GamePlay.Common.UI.OrderFinishUIView"), self, self.CloseView)
    return self.m_view
end

function OrderFinishUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ORDER_FINISH_UI)
    self.m_view = nil
    collectgarbage("collect")
end