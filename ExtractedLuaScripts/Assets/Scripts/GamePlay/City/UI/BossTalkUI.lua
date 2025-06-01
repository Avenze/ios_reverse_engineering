
local BossTalkUI = GameTableDefine.BossTalkUI
local GameUIManager = GameTableDefine.GameUIManager
local EventManager = require("Framework.Event.Manager")

function BossTalkUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.BOSS_TALK_UI, self.m_view, require("GamePlay.City.UI.BossTalkUIView"), self, self.CloseView)
    return self.m_view
end

function BossTalkUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.BOSS_TALK_UI)
    self.m_view = nil
    collectgarbage("collect")
end