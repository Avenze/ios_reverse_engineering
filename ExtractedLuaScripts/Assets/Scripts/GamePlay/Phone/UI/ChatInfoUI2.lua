local ChatInfoUI2 = GameTableDefine.ChatInfoUI2

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ChatUI = GameTableDefine.ChatUI
local EventManager = require("Framework.Event.Manager")

function ChatInfoUI2:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.APP_CHAT_INFO_UI2, self.m_view, require("GamePlay.Phone.UI.ChatInfoUI2View"), self, self.CloseView)
    return self.m_view
end

function ChatInfoUI2:Refresh(chatId, data)
    self:GetView():Invoke("Refresh", chatId, data)
end

function ChatInfoUI2:CloseView()
    ChatUI:Refresh()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_CHAT_INFO_UI2)
    self.m_view = nil
    collectgarbage("collect")
end