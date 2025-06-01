--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-24 10:06:24
]]

local InstanceOfflineRewardUI = GameTableDefine.InstanceOfflineRewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceDataManager = GameTableDefine.InstanceDataManager

function InstanceOfflineRewardUI:GetView()
    local rewardData = InstanceDataManager:GetCurInstanceOfflineRewardData()
    -- local rewardData = InstanceDataManager:GetGMCurInstanceOfflineRewardData()
    if not rewardData or Tools:GetTableSize(rewardData) <= 0 then
        return
    end

    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_OFFLINE_REWARD_UI, self.m_view, require("GamePlay.Instance.UI.InstanceOfflineRewardUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceOfflineRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_OFFLINE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end