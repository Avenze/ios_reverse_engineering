local DoubleRewardUI = GameTableDefine.DoubleRewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function DoubleRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.DOUBLE_REWARD_UI, self.m_view, require("GamePlay.Common.UI.DoubleRewardUIView"), self, self.CloseView)
    return self.m_view
end

function DoubleRewardUI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.DOUBLE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function DoubleRewardUI:Show(func, allReward)
    self:GetView():Invoke("Show", func, allReward)
end