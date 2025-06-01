--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 10:39:49
]]
---@class InstanceRewardUI
local InstanceRewardUI = GameTableDefine.InstanceRewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager

---@return InstanceRewardUIView
function InstanceRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_REWARD_UI, self.m_view, require("GamePlay.Instance.UI.InstanceRewardUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceRewardUI:GetUIModel()
    local reallyRewards = InstanceDataManager:GetCurAllRewardData()
    self.m_uiModel = {
        reallyRewards = reallyRewards,
        rewardTypeConfig = InstanceDataManager.config_rewardType_instance,
        rewardIDConfig = InstanceDataManager.config_rewardID_instance,
        shopConfig = ConfigMgr.config_shop,

    }

    return self.m_uiModel
end

function InstanceRewardUI:Show(closeCallback)
    self.m_closeCallback = closeCallback
    self:GetView()
end

function InstanceRewardUI:CloseView()
    if self.m_closeCallback then
        self.m_closeCallback()
        self.m_closeCallback = nil
    end
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end