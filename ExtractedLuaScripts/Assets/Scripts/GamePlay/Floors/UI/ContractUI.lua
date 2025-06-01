local ContractUI = GameTableDefine.ContractUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function ContractUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CONTRACT_UI, self.m_view, require("GamePlay.Floors.UI.ContractUIView"), self, self.CloseView)
    return self.m_view
end

function ContractUI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CONTRACT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function ContractUI:Refresh(data)
    self:GetView():Invoke("Show", data)
end