local BuyCarInfoUI = GameTableDefine.BuyCarInfoUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function BuyCarInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.APP_CAR_INFO_UI, self.m_view, require("GamePlay.Phone.UI.BuyCarInfoUIView"), self, self.CloseView)
    return self.m_view
end

function BuyCarInfoUI:Refresh(carId)
    self:GetView():Invoke("Refresh", carId)
end

function BuyCarInfoUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_CAR_INFO_UI)
    self.m_view = nil
    collectgarbage("collect")
end