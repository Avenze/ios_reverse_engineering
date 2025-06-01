local ConformUI = GameTableDefine.ConformUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr

function ConformUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CONFORM_UI, self.m_view, require("GamePlay.Common.UI.ConformUIView"), self, self.CloseView)
    return self.m_view
end

function ConformUI:OpenFirstResetAccount()
    self:GetView():Invoke("OpenFirstResetAccount")
end

function ConformUI:OpenThirdAccountReset()
    self:GetView():Invoke("OpenThirdAccountReset")
end

function ConformUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CONFORM_UI)
    self.m_view = nil
    collectgarbage("collect")
end
