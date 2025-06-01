local TalkUI = GameTableDefine.TalkUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function TalkUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.TALK_UI, self.m_view, require("GamePlay.Common.UI.TalkUIView"), self, self.CloseView)
    return self.m_view
end

function TalkUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.TALK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function TalkUI:OpenTalk(id, setting, TLGo, final_cb, begin_cb)
    self:GetView():Invoke("OpenTalk", id, setting, TLGo, final_cb, begin_cb)
end