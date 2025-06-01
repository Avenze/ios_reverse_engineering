local AdFreeUI = GameTableDefine.AdFreeUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function AdFreeUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.AD_FREE_UI, self.m_view, require("GamePlay.Shop.AdFreeUIView"), self, self.CloseView)
    return self.m_view
end

function AdFreeUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.AD_FREE_UI)
    self.m_view = nil
    collectgarbage("collect")
end