

local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local MainUI = GameTableDefine.MainUI
local StarMode = GameTableDefine.StarMode

function DiamondRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.DIAMOND_REWARD_UI, self.m_view, require("GamePlay.Common.UI.DiamondRewardUIView"), self, self.CloseView)
    return self.m_view
end

function DiamondRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.DIAMOND_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

-- function DiamondRewardUI:Init()
--     self:UpdateResourceUI()
--     self:GetView():Invoke("SetUIStatus", GameStateManager:IsInFloor())
-- end

function DiamondRewardUI:ShowRewardPanel()
    -- type 1 头  4 尾 2 不带奖励 3 带奖励
    -- diamond 奖励数量
    -- status 1 已经完成待领取 2 已经领取 3未完成

    --这些都是过去时了...现在只管
    local data = {}

    -- local cfg_reward = ConfigMgr.config_global.diamond_layout_reward
    -- local cfg_star = ConfigMgr.config_global.diamond_layout_star
    local cfg = ConfigMgr.config_total_ad_reward

    local currStar = StarMode:GetStar()
    local currLevel = 1
    for k,v in ipairs(cfg) do
        if currStar <= v.star then
            break
        end
        currLevel = currLevel + 1
    end
    currLevel = currLevel > #cfg and #cfg or currLevel--免得修改超过999了

    local cfg = cfg[currLevel]

    local localData = DiamondRewardUI:GetLocalData()
    for i, v in ipairs(cfg.ad_times or {}) do
        local status = 3
        if localData.current_level >= v then--满足条件
            status = 2
            if localData.current_reward_level < i then--已经领取过
                status = 1
            end
        end
        --table.insert(data, {type = v[1], diamond = v[2] or 0, status = status})
        table.insert(data, {adTimes = v, reward = cfg.reward[i], status = status})
    end
    self:GetView():Invoke("SetRewardStatus", data)
end

function DiamondRewardUI:GetDate()
    local offset = (ConfigMgr.config_global.reset_time or 5) * 60 * 60
    return tonumber(os.date("%Y%m%d", GameTimeManager:GetCurrentServerTime() - offset))
end

function DiamondRewardUI:GetLocalData()
    local data = LocalDataManager:GetDataByKey("ad_diamond_reward")
    local curDate = self:GetDate()
    if Tools:GetTableSize(data) == 0 or data.date ~= curDate then
        data.date = curDate
        data.current_level = 0
        data.current_reward_level = 0
        LocalDataManager:WriteToFile()
    end

    data.current_level = LocalDataManager:GetDataByKey("ad_data").todayAdTime
    return data
end

function DiamondRewardUI:IsNewDay()--每天5点可以领取一次,是否为可领取日
    local lcoalData = self:GetLocalData()
    local curData = self:GetDate()
    return lcoalData.free_reward_date ~= curData
end

function DiamondRewardUI:ClamADRewards(check)
    --local cfg = ConfigMgr.config_global.diamond_layout

    local cfg = ConfigMgr.config_total_ad_reward

    -- local cfg_reward = ConfigMgr.config_global.diamond_layout_reward
    -- local cfg_star = ConfigMgr.config_global.diamond_layout_star

    local currStar = StarMode:GetStar()
    local currLevel = 1
    for k,v in ipairs(cfg) do
        if currStar <= v.star then
            break
        end
        currLevel = currLevel + 1
    end
    currLevel = currLevel > #cfg and #cfg or currLevel--免得修改超过999了

    local cfg = cfg[currLevel]

    local localData = DiamondRewardUI:GetLocalData()
    local currLv = localData.current_level or 0
    local level = 0
    local rewards = {}
    local rewardAble = false
    for i, v in ipairs(cfg.ad_times or {}) do
        if currLv >= v and (localData.current_reward_level < i) then
            table.insert(rewards, cfg.reward[i])
            level = i
            rewardAble = true
        end
    end

    if check then return rewardAble, rewards end
    
    if rewardAble and level ~= localData.current_reward_level then
        -- ResMgr:AddDiamond(count, ResMgr.EVENT_COLLECTION_DAILY_LEVEL_REWARDS, function(success)
        --     if not success then
        --         return
        --     end
        --     MainUI:RefreshDiamondShop()
        --     localData.current_reward_level = level
        --     self:ShowRewardPanel()
        -- end, true)
        for k,v in ipairs(rewards) do
            ResMgr:Add(v[1], v[2], ResMgr.EVENT_COLLECTION_DAILY_LEVEL_REWARDS, function(success)
                if v[1] == 3 then
                    -- GameSDKs:Track("get_diamond", {get = v[2], left = ResMgr:GetDiamond(), get_way = "累计广告奖励"})
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "累计广告奖励", behaviour = 1, num_new = tonumber(v[2])})
                end

                if not success then
                    return
                end

                if k ~= #rewards then
                    return
                end

                localData.current_reward_level = level
                MainUI:RefreshDiamondHint()
                self:ShowRewardPanel()
            end, true)
        end
    end
end

-- function DiamondRewardUI:AddADRewardsLevel()
--     local cfg = ConfigMgr.config_global.diamond_layout
--     local localData = DiamondRewardUI:GetLocalData()
--     localData.current_level = math.max(localData.current_level + 1, #cfg)
--     LocalDataManager:WriteToFile()
-- end
