
---@class CycleToyOfflineRewardUI
local CycleToyOfflineRewardUI = GameTableDefine.CycleToyOfflineRewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr

function CycleToyOfflineRewardUI:GetView()
    local currentModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
    local rewardData = currentModel:GetCurInstanceOfflineRewardData()
    -- local rewardData = InstanceDataManager:GetGMCurInstanceOfflineRewardData()
    if not rewardData or Tools:GetTableSize(rewardData) <= 0 then
        return
    end

    self.timer = GameTimer:CreateNewTimer(1, function()
        if GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_TOY_MAIN_VIEW_UI, true, {
            ENUM_GAME_UITYPE.INTRODUCE_UI,
            ENUM_GAME_UITYPE.BENAME_UI,
            ENUM_GAME_UITYPE.OFFLINE_REWARD_UI,
            ENUM_GAME_UITYPE.INSTANCE_OFFLINE_REWARD_UI,
            ENUM_GAME_UITYPE.FLY_ICONS_UI,
            ENUM_GAME_UITYPE.LAUNCH,
            ENUM_GAME_UITYPE.AD_TICKET_CHOOSE_UI,
            ENUM_GAME_UITYPE.CHOOSE_UI,
            ENUM_GAME_UITYPE.CUT_SCREEN_UI,
            ENUM_GAME_UITYPE.BOARD_UI,
            ENUM_GAME_UITYPE.TIPS_UI,
            ENUM_GAME_UITYPE.CYCLE_TOY_CUT_SCREEN_UI,
        }) then
            self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_OFFLINE_REWARD_UI, self.m_view, require("GamePlay/CycleInstance/Toy/UI/CycleToyOfflineRewardUIView"), self, self.CloseView)
            GameTimer:StopTimer(self.timer)
            self.timer = nil
        end
    end, true, false)
    
    return self.m_view
end

function CycleToyOfflineRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_OFFLINE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

