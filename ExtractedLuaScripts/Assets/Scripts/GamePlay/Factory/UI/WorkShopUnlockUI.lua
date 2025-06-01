local WorkShopUnlockUI = GameTableDefine.WorkShopUnlockUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function WorkShopUnlockUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.WORK_SHOP_UNLOCK_UI, self.m_view, require("GamePlay.Factory.UI.WorkShopUnlockUIView"), self, self.CloseView)
    return self.m_view
end

function WorkShopUnlockUI: DisplayInformation(workShopid)
    
    self:GetView():Invoke("Refresh",workShopid)
end


function WorkShopUnlockUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.WORK_SHOP_UNLOCK_UI)
    self.m_view = nil
    collectgarbage("collect")
end