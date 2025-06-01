local RenewUI = GameTableDefine.RenewUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function RenewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.RENEW_UI, self.m_view, require("GamePlay.Floors.UI.RenewUIView"), self, self.CloseView)
    return self.m_view
end

function RenewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.RENEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function RenewUI:Refresh(companyId, roomIndex, roomId)
    self:GetView():Invoke("Refresh", companyId, roomIndex, roomId)
end