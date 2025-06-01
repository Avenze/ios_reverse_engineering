local RewardUI = GameTableDefine.RewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function RewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.REWARD_UI, self.m_view, require("GamePlay.Common.UI.RewardUIView"), self, self.CloseView)
    return self.m_view
end

function RewardUI:Refresh(mainType, typeId, NumOrId, cb)
    self:GetView():Invoke("Refresh", mainType, typeId, NumOrId, cb)
end

function RewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end