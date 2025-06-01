local GuideUI = GameTableDefine.GuideUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function GuideUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.GUIDE_UI, self.m_view, require("GamePlay.Common.UI.GuideUIView"), self, self.CloseView)
    return self.m_view
end

function GuideUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.GUIDE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function GuideUI:StepDataBy(step)
end

function GuideUI:Show(data)
    self:GetView():Invoke("Refresh", data)
end

function GuideUI:ResetView()
    self:GetView():Invoke("ResetView")
end