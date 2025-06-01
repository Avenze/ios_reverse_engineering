local CutScreenUI = GameTableDefine.CutScreenUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CutScreenUI:GetView()
    if LocalDataManager:IsNewPlayerRecord() then
        return
    end
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CUT_SCREEN_UI, self.m_view, require("GamePlay.Common.UI.CutScreenUIView"), self, self.CloseView)
    return self.m_view
end

function CutScreenUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CUT_SCREEN_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CutScreenUI:Play(spend, cb)
    self:GetView():Invoke("Play", cb, spend)
end