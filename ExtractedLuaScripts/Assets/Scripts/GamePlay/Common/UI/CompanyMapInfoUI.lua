local CompanyMapInfoUI = GameTableDefine.CompanyMapInfoUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function CompanyMapInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.COMPANY_MAP_INFO_UI, self.m_view, require("GamePlay.Common.UI.CompanyMapInfoUIView"), self, self.CloseView)
    return self.m_view
end

function CompanyMapInfoUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.COMPANY_MAP_INFO_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CompanyMapInfoUI:Refresh(data, cfg)
    self:GetView():Invoke("Refresh", data, cfg)
end