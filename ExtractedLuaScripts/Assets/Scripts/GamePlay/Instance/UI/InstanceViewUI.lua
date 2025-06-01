
local InstanceViewUI = GameTableDefine.InstanceViewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function InstanceViewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_VIEW_UI, self.m_view, require("GamePlay.Instance.UI.InstanceViewUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceViewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_VIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function InstanceViewUI:OpenInstanceViewUI()
    self:GetView():Invoke("InitView")
end
