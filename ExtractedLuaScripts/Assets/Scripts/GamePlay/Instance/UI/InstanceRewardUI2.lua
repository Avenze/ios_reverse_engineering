--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 10:39:49
]]

local InstanceRewardUI2 = GameTableDefine.InstanceRewardUI2

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local EventManager = require("Framework.Event.Manager")

function InstanceRewardUI2:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_REWARD_UI_2, self.m_view, require("GamePlay.Instance.UI.InstanceRewardUIView2"), self, self.CloseView)
    return self.m_view
end

function InstanceRewardUI2:GetUIModel()
    local achievementLevel = InstanceDataManager:GetCurInstanceKSLevel()
    local eggs = InstanceModel:GetLevelReward(achievementLevel)
    self.m_uiModel = {
        eggs = eggs,
        reallyRewards = InstanceDataManager:GetCurAllRewardData(),
        rewardTypeConfig = InstanceDataManager.config_rewardType_instance,
        rewardIDConfig = InstanceDataManager.config_rewardID_instance,
        shopConfig = ConfigMgr.config_shop,

    }

    return self.m_uiModel
end

function InstanceRewardUI2:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_REWARD_UI_2)
    self.m_view = nil
    collectgarbage("collect")
end