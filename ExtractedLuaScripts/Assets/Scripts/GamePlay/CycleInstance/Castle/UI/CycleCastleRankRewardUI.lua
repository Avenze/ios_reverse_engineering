--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 10:39:49
]]

---@class CycleCastleRankRewardUI
local CycleCastleRankRewardUI = GameTableDefine.CycleCastleRankRewardUI

local CycleCastleRankManager = GameTableDefine.CycleCastleRankManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local EventManager = require("Framework.Event.Manager")

function CycleCastleRankRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_RANK_REAWARD_UI, self.m_view, require("GamePlay.CycleInstance.Castle.UI.CycleCastleRankRewardUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleRankRewardUI:GetUIModel()
    local eggs = CycleCastleRankManager:GetRankReward()
    self.m_uiModel = {
        eggs = eggs,
        reallyRewards = CycleCastleRankManager:GetRankRewardDetail(),
        rewardTypeConfig = eggs,
        rewardIDConfig = {},
        shopConfig = ConfigMgr.config_shop,
    }
    
    return self.m_uiModel
end

function CycleCastleRankRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_RANK_REAWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end