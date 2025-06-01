local ChatEventUI = GameTableDefine.ChatEventUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function ChatEventUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CHAT_EVENT_UI, self.m_view, require("GamePlay.Common.UI.ChatEventUIView"), self, self.CloseView)
    return self.m_view
end

function ChatEventUI:Refresh(eventId, cost, acceptCb, rejectCb, considerCb)
    self:GetView():Invoke("Refresh", eventId, cost, acceptCb, rejectCb, considerCb)
end

function ChatEventUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CHAT_EVENT_UI)
    self.m_view = nil
    collectgarbage("collect")
end