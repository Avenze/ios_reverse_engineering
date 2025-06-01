--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 10:39:49
]]

---@class CycleNightClubRankRewardUI
local CycleNightClubRankRewardUI = GameTableDefine.CycleNightClubRankRewardUI

local CycleNightClubRankManager = GameTableDefine.CycleNightClubRankManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local EventManager = require("Framework.Event.Manager")

function CycleNightClubRankRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_RANK_REAWARD_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubRankRewardUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubRankRewardUI:GetUIModel()
    local eggs = CycleNightClubRankManager:GetRankReward()
    self.m_uiModel = {
        eggs = eggs,
        reallyRewards = CycleNightClubRankManager:GetRankRewardDetail(),
        rewardTypeConfig = eggs,
        rewardIDConfig = {},
        shopConfig = ConfigMgr.config_shop,
    }
    
    return self.m_uiModel
end

function CycleNightClubRankRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_RANK_REAWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end