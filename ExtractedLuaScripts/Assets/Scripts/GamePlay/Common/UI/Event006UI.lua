local Event006UI = GameTableDefine.Event006UI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function Event006UI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EVENT006_UI, self.m_view, require("GamePlay.Common.UI.Event006UIView"), self, self.CloseView)
    return self.m_view
end

function Event006UI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EVENT006_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function Event006UI:ShowPanel()
    self:GetView():Invoke("ShowPanel")
end