--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-01 12:18:23
]]
local CycleInstanceRewardUI = GameTableDefine.CycleInstanceRewardUI
local GameUIManager = GameTableDefine.GameUIManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

function CycleInstanceRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_INSTANCE_REWARD_UI, self.m_view, require("GamePlay.CycleInstance.Island.UI.CycleInstanceRewardUIView"), self, self.CloseView)
    return self.m_view
end

function CycleInstanceRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_INSTANCE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--[[
    @desc:里程碑界面获取单个里程碑奖励发放 
    author:{author}
    time:2024-07-02 12:22:13
    --@rewards: 
    @return:
]]
function CycleInstanceRewardUI:ShowGetReward(rewards,isShopUIRequire, scrollIndex)
    self:GetView():Invoke("ShowGetReward", rewards,isShopUIRequire, scrollIndex)
end

--[[
    @desc:获取所有当前没有领取的里程碑奖励内容 
    author:{author}
    time:2024-07-02 12:22:43
    @return:
]]
function CycleInstanceRewardUI:ShowAllNotClaimRewardsGet()

    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local allRewards = currentModel:GetAllSKRewardNotClaim()

    --实际发放奖励
    for k, v in pairs(allRewards) do
        currentModel:RealGetRewardByLevel(v.level)
    end
    if Tools:GetTableSize(allRewards) > 0 then
        self:GetView():Invoke("ShowAllNotClaimRewardsGet", allRewards)
    end
end

--[[
    @desc: 增加使用礼包码补单也用这个奖励界面进行显示
    author:{author}
    time:2024-08-09 17:04:34
    --@rewards: 
    @return:
]]
function CycleInstanceRewardUI:ShowGiftCodeGetRewards(rewards, isUIShow)
    if Tools:GetTableSize(rewards) > 0 then
        self:GetView():Invoke("ShowGiftCodeGetRewards", rewards, isUIShow)
    end
end