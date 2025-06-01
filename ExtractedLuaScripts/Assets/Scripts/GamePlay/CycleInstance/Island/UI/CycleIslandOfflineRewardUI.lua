
---@class CycleIslandOfflineRewardUI
local CycleIslandOfflineRewardUI = GameTableDefine.CycleIslandOfflineRewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

function CycleIslandOfflineRewardUI:GetView()
    local rewardData = CycleInstanceDataManager:GetCurrentModel():GetCurInstanceOfflineRewardData()
    -- local rewardData = InstanceDataManager:GetGMCurInstanceOfflineRewardData()
    if not rewardData or Tools:GetTableSize(rewardData) <= 0 then
        return
    end

    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_OFFLINE_REWARD_UI, self.m_view, require("GamePlay/CycleInstance/Island/UI/CycleIslandOfflineRewardUIView"), self, self.CloseView)
    return self.m_view
end

function CycleIslandOfflineRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_OFFLINE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

