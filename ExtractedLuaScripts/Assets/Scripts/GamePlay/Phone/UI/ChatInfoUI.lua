local ChatInfoUI = GameTableDefine.ChatInfoUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ChatUI = GameTableDefine.ChatUI
local EventManager = require("Framework.Event.Manager")

function ChatInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.APP_CHAT_INFO_UI, self.m_view, require("GamePlay.Phone.UI.ChatInfoUIView"), self, self.CloseView)
    return self.m_view
end

function ChatInfoUI:Refresh(chatId, data)
    self:GetView():Invoke("Refresh", chatId, data)
end

function ChatInfoUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_CHAT_INFO_UI)
    self.m_view = nil
    collectgarbage("collect")
end