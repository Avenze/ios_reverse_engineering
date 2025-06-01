local BuyCarUI = GameTableDefine.BuyCarUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function BuyCarUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.APP_CAR_UI, self.m_view, require("GamePlay.Phone.UI.BuyCarUIView"), self, self.CloseView)
    return self.m_view
end

function BuyCarUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_CAR_UI)
    self.m_view = nil
    collectgarbage("collect")
end