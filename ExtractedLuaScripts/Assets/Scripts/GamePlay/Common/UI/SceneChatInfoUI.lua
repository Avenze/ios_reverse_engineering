local SceneChatInfoUI = GameTableDefine.SceneChatInfoUI
local ChatEventManager = GameTableDefine.ChatEventManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function SceneChatInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.SCENE_CHAT_INFO_UI, self.m_view, require("GamePlay.Common.UI.SceneChatInfoUIView"), self, self.CloseView)
    return self.m_view
end

function SceneChatInfoUI:Refresh(conditionId, data)
    local saveData = ChatEventManager:UpdateSceneChat()
    self:GetView():Invoke("Refresh", conditionId, {steps = saveData})
end

function SceneChatInfoUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.SCENE_CHAT_INFO_UI)
    self.m_view = nil
    collectgarbage("collect")
end