local TipsUI = GameTableDefine.TipsUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function TipsUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.TIPS_UI, self.m_view, require("GamePlay.Common.UI.TipsUIView"), self, self.CloseView)
    return self.m_view
end

function TipsUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.TIPS_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function TipsUI:Init()
    EventManager:RegEvent("UI_NOTE", function(message)
        TipsUI:GetView():Invoke("Show", message)
    end);
end