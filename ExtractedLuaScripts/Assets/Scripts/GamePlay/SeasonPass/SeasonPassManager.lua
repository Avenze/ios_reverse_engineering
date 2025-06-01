---@class SeasonPassManager
local SeasonPassManager = GameTableDefine.SeasonPassManager
local PASS_DATA_KEY = "SeasonPass"
local GameTimeManager = GameTimeManager
local EventDispatcher = require("Framework.Event.EventDispatcher")
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local CommonRewardUI = GameTableDefine.CommonRewardUI
local LocalDataManager = LocalDataManager
local Shop = GameTableDefine.Shop
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager

SeasonPassManager.PREMIUM_SHOP_ID = 1611
SeasonPassManager.LUXURY_SHOP_ID = 1612

---@class SeasonPassManagerSaveData
---@field currentPassType string
---@field nextPassType string
---@field passDatas table<string,SeasonPassSaveData>
local SeasonPassManagerSaveData = {}

---@class SeasonPassSaveData
---@field starTime number
---@field endTime number
---@field passType string 游戏类型
---@field theme string 主题类型
---@field gotAdditionalCount number 已领取的额外奖励数量
---@field level number 当前经验等级
---@field isBuyPremium boolean 是否购买高级通行证
---@field isBuyLuxury boolean 是否购买豪华通行证
---@field gotRewardInfo table<number,number[]>  是否领取(普通,高级,高级)奖励
---@field lastUnlockIndex number
local SeasonPassSaveData = {}

---@class SeasonPassRewardConfig
---@field id number
---@field passType_id string
---@field level number
---@field exp number
---@field normal_rewards number[]
---@field premium_rewards number[]
---@field luxury_rewards number[]
---@field grand_point boolean
local SeasonPassRewardConfig = {}

local TOTAL_ADDITIONAL_REWARD = 30

SeasonPassManager.RewardType = {
    Normal = "N",
    Premium = "P",
    Luxury = "L",
}

SeasonPassManager.MiniGameType = {
    tuibiji = "tuibiji",
    fruitji = "fruitji"
}

SeasonPassManager.Theme = {
    ["normal"] = "normal",
    ["stpatrick"] = "stpatrick",
}

function SeasonPassManager:ctor()
    self.m_initialized = false
    self.m_currentGameManager = nil
    self.m_rewardConfigList = nil ---@type SeasonPassRewardConfig[]
    self.m_currentPassData = nil ---@type SeasonPassSaveData
    self.m_saveData = nil ---@type SeasonPassManagerSaveData
    self.m_rewardConfigCount = 0

    self.m_buyLevelDiamond = 100 ---购买1级通行证等级所需钻石数
    self.m_additionalRewardExp = 100 ---额外宝箱需求经验
    self.m_additionalRewardCfg = {1599, 1} ---额外宝箱内容(商品id,数量)
    self.m_additionalRewardCount = 30 ---额外宝箱领取数量限制
end

function SeasonPassManager:GetCurrentPassData()
    if self.m_currentPassData then
        return self.m_currentPassData
    end
    if not self.m_saveData then
        self.m_saveData = LocalDataManager:GetDataByKey(PASS_DATA_KEY)
    end
    if self.m_saveData.currentPassType and self.m_saveData.passDatas then
        local currentPassData = self.m_saveData.passDatas[self.m_saveData.currentPassType]
        if currentPassData then
            --不论是否结束都要返回本赛季的数据
            --if currentPassData.endTime > GameTimeManager:GetTheoryTime() then
            --    self.m_currentPassData = currentPassData
            --    return currentPassData
            --end
            self.m_currentPassData = currentPassData
            return currentPassData
        end
    end
    return nil
end

---返回下个赛季的存档数据
function SeasonPassManager:GetNextPassData()
    self:Init()
    if self.m_nextPassData then
        return self.m_nextPassData
    end
    if self.m_saveData and self.m_saveData.nextPassType and self.m_saveData.passDatas then
        local nextPassData = self.m_saveData.passDatas[self.m_saveData.nextPassType]
        if nextPassData then
            if nextPassData.endTime > GameTimeManager:GetTheoryTime() then
                self.m_nextPassData = nextPassData
                return nextPassData
            end
        end
    end
    return nil
end

---是否需要拉去下赛季的活动，不存在下赛季内容时拉去活动
function SeasonPassManager:NeedRequestActivity()
    if not self.m_saveData then
        self.m_saveData = LocalDataManager:GetDataByKey(PASS_DATA_KEY)
    end
    --首先尝试切换，顺便清空本赛季和下赛季数据
    self:CheckChangeToNextPassData()
    if not self.m_saveData.nextPassType then
        return true
    else
        return false
    end
end

function SeasonPassManager:GetCurrentRewardConfigs()
    return self.m_rewardConfigList
end

---检查是否需要切换到下个赛季的存档数据 赛季之间可能有空档，并且在上赛季界面停留时不能开启下赛季.
function SeasonPassManager:CheckChangeToNextPassData()
    local now = GameTimeManager:GetCurrentServerTime()
    --本赛季type置空
    if self.m_saveData.currentPassType then
        local curPassData = self.m_saveData.passDatas[self.m_saveData.currentPassType]
        if curPassData then
            --本赛季未结束，不切换
            if curPassData.endTime > now then
                return
            end
            self.m_saveData.currentPassType = nil
            self.m_currentPassData = nil
        end
    end
    --开启下赛季,
    if self.m_saveData.nextPassType then
        local nextPassData = self.m_saveData.passDatas[self.m_saveData.nextPassType]
        if nextPassData then
            if nextPassData.endTime > now and nextPassData.starTime <= now then
                self.m_saveData.currentPassType = self.m_saveData.nextPassType
                self.m_saveData.nextPassType = nil
                --2024-12-30增加一个是否第一次进入该通行证的埋点
                self.m_saveData.isFirstEnter = 1
                self.m_nextPassData = nil
                self.m_initialized = false
                GameTableDefine.SeasonPassTaskManager:Reset()
                GameTableDefine.SeasonPassTaskManager:Init(1, self.m_saveData.currentPassType)
                LocalDataManager:WriteToFile()
                self:Init()
            end
        end
    end
end

---返回当前通行证类型
function SeasonPassManager:GetCurrentType()
    local currentData = self:GetCurrentPassData()
    return currentData and currentData.passType or "tuibiji"
end

function SeasonPassManager:GetTheme()
    local currentData = self:GetCurrentPassData()
    return currentData and currentData.theme or "normal"
end

---返回当前通行证已领取的额外奖励数量和最大数量,当前可以获取的数量
---@return number,number,number 已获取数量,最大数量,当前可以获取的数量
function SeasonPassManager:GetAdditionalRewardInfo()
    local currentData = self:GetCurrentPassData()
    local curGetCount = currentData.gotAdditionalCount or 0
    local curLevel,maxLevel = self:GetLevelInfo(true)
    curLevel = math.min(curLevel,maxLevel)
    local canGetRewardCount = math.max(0,curLevel-self.m_rewardConfigCount - curGetCount)
    return curGetCount,TOTAL_ADDITIONAL_REWARD,canGetRewardCount
end

function SeasonPassManager:ProcessSDKCallbackData(sdkData)
    if not sdkData then return end
    if tonumber(sdkData.activityType) ~= TimeLimitedActivitiesManager.SeasonPass then
        return
    end

    local startTime = tonumber(sdkData.startTime)
    local endTime = tonumber(sdkData.endTime)

    if not startTime or not endTime then
        return
    end

    local now = GameTimeManager:GetCurrentServerTime()
    if endTime <= now or startTime >= endTime then
        return
    end

    local passType = sdkData.season_pass_type or SeasonPassManager.MiniGameType.tuibiji

    self.m_saveData = LocalDataManager:GetDataByKey(PASS_DATA_KEY)

    local passDatas = self.m_saveData.passDatas
    if passDatas then
        local prePassData = passDatas[passType]
        if prePassData then
            ---上个同类型通行证活动还未结束,数据不能被替换
            if prePassData.endTime > now and passType == self.m_saveData.currentPassType then
                return
            end
        end
    else
        passDatas = {}
        self.m_saveData.passDatas = passDatas
    end
    local newSeasonData = {} ---@type SeasonPassSaveData
    passDatas[passType] = newSeasonData
    newSeasonData.passType = passType
    newSeasonData.starTime = startTime
    newSeasonData.endTime = endTime
    newSeasonData.theme = sdkData.season_pass_theme

    self.m_saveData.nextPassType = passType
    self:CheckChangeToNextPassData()
    GameTableDefine.MainUI:RefreshSeasonPassBtn()

end

function SeasonPassManager:GMOpenActivity(passType, theme, durationTime)
    passType = tostring(passType)
    self.m_saveData = LocalDataManager:GetDataByKey(PASS_DATA_KEY)
    local newSeasonData = {}
    if not self.m_saveData.passDatas then
        self.m_saveData.passDatas = {}
    end
    self.m_saveData.passDatas[passType] = newSeasonData
    newSeasonData.passType = passType
    newSeasonData.theme = theme
    local now = GameTimeManager:GetTheoryTime()
    newSeasonData.starTime = now
    newSeasonData.endTime = now + durationTime * 60
    self.m_saveData.currentPassType = passType
    self.m_saveData.isFirstEnter = 1
    --fy添加初始化任务数据
    --TODO:seasonID可能埋点需要
    local seasonID = 1
    GameTableDefine.SeasonPassTaskManager:Reset()
    GameTableDefine.SeasonPassTaskManager:Init(seasonID, passType)
    LocalDataManager:WriteToFile()

    --重置数据
    self.m_initialized = false
    self:Init()
    EventDispatcher:TriggerEvent(GameEventDefine.SeasonPassStateChange)
end

function SeasonPassManager:GetActivityIsOpen()
    self:Init()
    local currentPass = self:GetCurrentPassData()
    if currentPass and currentPass.endTime > GameTimeManager:GetTheoryTime() then
        return true
    end
    return false
end

---获取活动的开始时间,返回当前类型的开始时间或下一个类型的开始时间
function SeasonPassManager:GetStartTime()
    local currentData = self:GetCurrentPassData()
    if currentData then
        return currentData.starTime
    else
        return 0
    end
end

---获取活动的结束时间
function SeasonPassManager:GetEndTime()
    local currentData = self:GetCurrentPassData()
    return currentData and currentData.endTime or 0
end

---获取剩余时间
function SeasonPassManager:GetActivityLeftTime()
    local endTime = self:GetEndTime()
    local limitTime = math.max(0,endTime - GameTimeManager:GetCurrentServerTime())
    return limitTime
end

function SeasonPassManager:GetEnterDay()
    local currentData = self:GetCurrentPassData()
    if currentData then
        return currentData.enterDay
    end
end

function SeasonPassManager:SetEnterDay()
    local currentData = self:GetCurrentPassData()
    if currentData then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local day = GameTimeManager:FormatTimeToD(now)
        currentData.enterDay = day
    end
end

function SeasonPassManager:Init()
    if self.m_initialized then
        return
    end

    self.m_currentPassData = nil
    local currentPass = self:GetCurrentPassData()
    if not currentPass then
        --没有开启活动

    else
        local seasonID = 1
        if currentPass.passType == SeasonPassManager.MiniGameType.tuibiji then
            self.m_currentGameManager = GameTableDefine.CoinPusherManager
            self.m_currentGameManager:Init()
        end
        --2025-12-30fy添加，用于初始化当次的通信证活动
        if not currentPass.isFirstEnter then
            currentPass.isFirstEnter = 1
        end
        GameTableDefine.SeasonPassTaskManager:Init(seasonID, currentPass.passType or SeasonPassManager.MiniGameType.tuibiji)
        self.m_rewardConfigList = ConfigMgr.config_pass_rewards[currentPass.passType]
        self.m_rewardConfigCount = #self.m_rewardConfigList

        self.m_buyLevelDiamond = ConfigMgr.config_global.pass_rewards_levelUpBuy
        self.m_additionalRewardExp = ConfigMgr.config_global.pass_rewards_exChestNeeds
        self.m_additionalRewardCfg = Tools:SplitString(ConfigMgr.config_global.pass_rewards_exChest,",",true)
        self.m_additionalRewardCount = ConfigMgr.config_global.pass_rewards_exChestLimit
        TOTAL_ADDITIONAL_REWARD = ConfigMgr.config_global.pass_rewards_exChestLimit
        SeasonPassManager.PREMIUM_SHOP_ID = ConfigMgr.config_global.pass_cnYear_advancedPass
        SeasonPassManager.LUXURY_SHOP_ID = ConfigMgr.config_global.pass_cnYear_ultimatePass
    end
    self.m_initialized = true
end

function SeasonPassManager:GetCurGameManager()
    return self.m_currentGameManager
end

---发放额外等级的奖励
function SeasonPassManager:DistributeAdditionalReward()
    local curGotCount,maxGotCount, canGetCount = self:GetAdditionalRewardInfo()
    if canGetCount >0 then
        local rewardID,rewardCount = self.m_additionalRewardCfg[1],self.m_additionalRewardCfg[2]
        rewardCount = rewardCount* canGetCount

        ShopManager:Buy_LimitPackReward(rewardID,nil,function()
            local showValue,showIcon = CommonRewardUI:GetShowValueString(rewardID,rewardCount)
            local rewardData = {icon = showIcon,num = showValue}
            CommonRewardUI:ShowRewardsOneByOne({rewardData})
            --通行证小游戏票数量变化埋点
            local shopCfg = ShopManager:GetCfg(rewardID)
            if shopCfg and shopCfg.type == 37 then
                local leftTicket = self.m_currentGameManager:GetTicketNum()
                GameSDKs:TrackForeign("pass_ticket", {behavior = 1,num = shopCfg.amount * rewardCount,left = leftTicket,source = 2})
            end
            --2025-1-7 fy  通行证奖励获取钻石埋点 
            if shopCfg and shopCfg.type == 3 then
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "通行证奖励", behaviour = 1, num_new = tonumber(shopCfg.amount * rewardCount)})
            end
            LocalDataManager:WriteToFile()
        end,false,rewardCount)

        local currentData = self:GetCurrentPassData()
        currentData.gotAdditionalCount = curGotCount + canGetCount
        LocalDataManager:WriteToFile()
    end
end

---@return number,number 当前等级,总等级(默认不包括额外奖励)
function SeasonPassManager:GetLevelInfo(includeAdditional)
    self:Init()
    if self.m_currentPassData then
        if not self.m_currentPassData.level then
            self.m_currentPassData.level = 1
        end
        if includeAdditional then
            return self.m_currentPassData.level,self.m_rewardConfigCount + self.m_additionalRewardCount
        else
            return self.m_currentPassData.level,self.m_rewardConfigCount
        end
    end
    return 0,30
end

function SeasonPassManager:AddExp(exp, taskID)
    self:Init()
    if self.m_currentPassData then
        if not self.m_currentPassData.exp then
            self.m_currentPassData.exp = 0
        end
        if not self.m_currentPassData.totalExp then
            self.m_currentPassData.totalExp = exp
        else
            self.m_currentPassData.totalExp = self.m_currentPassData.totalExp + exp
        end
        local remainExp = exp + self.m_currentPassData.exp
        self.m_currentPassData.exp = 0
        while(true) do
            local curExp,nextLevelNeedExp = self:GetExpInfo()
            if remainExp >= nextLevelNeedExp then
                local curLevel,maxLevel = self:GetLevelInfo()
                self.m_currentPassData.level = curLevel + 1
                remainExp = remainExp - nextLevelNeedExp
                EventDispatcher:TriggerEvent(GameEventDefine.SeasonPassLevelUp)
            else
                self.m_currentPassData.exp = remainExp
                break
            end
        end
        --2024-12-30添加任务领取增长等级埋点
        GameSDKs:TrackForeign("pass_level", {source = taskID or 0})
        return true
    end
    return false
end

--[[
    @desc: fy获取总的经验值
    author:{author}
    time:2024-12-31 11:18:25
    @return:
]]
function SeasonPassManager:GetTotalExp()
    if not self.m_currentPassData or not self.m_currentPassData.totalExp then
        return 0
    end
    return self.m_currentPassData.totalExp
end

function SeasonPassManager:BuyLevel(resultCB)
    local curLevel,maxLevel = self:GetLevelInfo()
    local canBuyLevel = false
    if curLevel<maxLevel then
        --没满级
        canBuyLevel = true
    else
        --额外奖励等级
        if curLevel < maxLevel + self.m_additionalRewardCount then
            canBuyLevel = true
        end
    end
    if canBuyLevel or true then
        local needDiamond = self.m_buyLevelDiamond
        ResourceManger:SpendDiamond(needDiamond,ResourceManger.EVENT_BUY_PASS_LEVEL,function(success)
            if success then
                local curExp,needExp = self:GetExpInfo()
                --2024-12-30fy根据埋点要求，钻石购买的等级需要传任务id为999
                self:AddExp(needExp, 999)
                if resultCB then
                    resultCB(true)
                end
                --2025-1-7fy 花费钻石埋点
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "通行证等级购买", behaviour = 2, num_new = tonumber(needDiamond)})
            else
                if resultCB then
                    resultCB(false)
                end
            end
        end)
    end
end

function SeasonPassManager:GetExpInfo()
    self:Init()

    if self.m_currentPassData then
        if not self.m_currentPassData.exp then
            self.m_currentPassData.exp = 0
        end
        --超过奖励等级就是额外等级，每级100经验
        local nextLevelNeedExp = 100
        local curLevel,maxLevel = self:GetLevelInfo()
        if curLevel<maxLevel then
            nextLevelNeedExp = self.m_rewardConfigList[curLevel+1].exp
        else
            nextLevelNeedExp = self.m_additionalRewardExp
        end
        return self.m_currentPassData.exp,nextLevelNeedExp
    end
    return 0,100
end

---@return SeasonPassRewardConfig
function SeasonPassManager:GetConfigByLevel(level)
    self:Init()

    if self.m_rewardConfigList then
        if level <= self.m_rewardConfigCount then
            return self.m_rewardConfigList[level]
        else
            return nil
        end
    end
    return nil
end

---@return boolean 是否购买高级通行证
function SeasonPassManager:IsBuyPremium()
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        return currentPass.isBuyPremium and true or false
    else
        return false
    end
end

---@return boolean 是否购买豪华通行证
function SeasonPassManager:IsBuyLuxury()
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        return currentPass.isBuyLuxury and true or false
    else
        return false
    end
end

---拉起高级通行证订单
function SeasonPassManager:BuyPremiumPass()
    Shop:CreateShopItemOrder(SeasonPassManager.PREMIUM_SHOP_ID)
end

---拉起豪华通行证订单
function SeasonPassManager:BuyLuxuryPass()
    Shop:CreateShopItemOrder(SeasonPassManager.LUXURY_SHOP_ID)
end

---将高级通行证订单设为已购买
function SeasonPassManager:SetIsBuyPremiumPass()
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        currentPass.isBuyPremium = true
    end
end

---将豪华通行证订单设为已购买
function SeasonPassManager:SetIsBuyLuxuryPass()
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        currentPass.isBuyLuxury = true
    end
end

function SeasonPassManager:IsGotReward(level,rewardType)
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        local gotRewardInfo = currentPass.gotRewardInfo
        level = tostring(level)
        if not gotRewardInfo or not gotRewardInfo[level] then
            return false
        else
            return gotRewardInfo[level][rewardType] and true or false
        end
    else
        return false
    end
end

function SeasonPassManager:CanGetReward(level,rewardType)
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        if rewardType == SeasonPassManager.RewardType.Premium then
            if not self:IsBuyPremium() then
                return false
            end
        elseif rewardType == SeasonPassManager.RewardType.Luxury then
            if not self:IsBuyLuxury() then
                return false
            end
        end
        local curLevel,maxLevel = self:GetLevelInfo()
        if level > curLevel then
            return false
        end
        return not self:IsGotReward(level,rewardType)
    else
        return false
    end
end

---是否有任何奖励可以领取
---@param needCount number 至少多少个
function SeasonPassManager:CanClaimAnyReward(includeAdditional,needCount)
    local curLevel,maxLevel = self:GetLevelInfo()
    local canClaimCount = 0
    needCount = needCount or 1
    curLevel = math.min(curLevel,self.m_rewardConfigCount)
    if curLevel > 0 then
        for i = 1, curLevel do
            if self:CanGetReward(i,SeasonPassManager.RewardType.Normal) then
                canClaimCount = canClaimCount + 1
            end
            if self:CanGetReward(i,SeasonPassManager.RewardType.Premium) then
                canClaimCount = canClaimCount + 1
            end
            if self:CanGetReward(i,SeasonPassManager.RewardType.Luxury) then
                canClaimCount = canClaimCount + 1
            end
            if canClaimCount >= needCount then
                return true
            end
        end
    end
    if includeAdditional then
        local curGotCount,maxGotCount,canGetCount self:GetAdditionalRewardInfo()
        if canGetCount > 0 then
            return true
        end
    end
    return false
end

---可以领取的奖励数量
function SeasonPassManager:GetCanClaimRewardCount(includeAdditional)
    local curLevel,maxLevel = self:GetLevelInfo()
    local canClaimCount = 0
    curLevel = math.min(curLevel,self.m_rewardConfigCount)
    if curLevel > 0 then
        for i = 1, curLevel do
            if self:CanGetReward(i,SeasonPassManager.RewardType.Normal) then
                canClaimCount = canClaimCount + 1
            end
            if self:CanGetReward(i,SeasonPassManager.RewardType.Premium) then
                canClaimCount = canClaimCount + 1
            end
            if self:CanGetReward(i,SeasonPassManager.RewardType.Luxury) then
                canClaimCount = canClaimCount + 1
            end
        end
    end
    if includeAdditional and self:IsBuyLuxury() then
        local curGotCount,maxGotCount,canGetCount self:GetAdditionalRewardInfo()
        canClaimCount = canClaimCount + canGetCount
    end
    return canClaimCount
end

---获取对应等级和类型的奖励信息
---@return number,number shopID,数量
function SeasonPassManager:GetRewardInfoByLevelType(level,rewardType)
    local passConfig = self:GetConfigByLevel(level)
    local rewardID,rewardCount
    if rewardType == SeasonPassManager.RewardType.Normal then
        rewardID,rewardCount = passConfig.normal_rewards
    elseif rewardType == SeasonPassManager.RewardType.Premium then
        rewardID,rewardCount = passConfig.premium_rewards
    elseif rewardType == SeasonPassManager.RewardType.Luxury then
        rewardID,rewardCount = passConfig.luxury_rewards
    end
    return rewardID,rewardCount
end

---发放奖励给玩家
function SeasonPassManager:DistributeReward(level,rewardType)
    if self:CanGetReward(level,rewardType) then
        local passConfig = self:GetConfigByLevel(level)
        local rewardID,rewardCount
        if rewardType == SeasonPassManager.RewardType.Normal then
            rewardID,rewardCount = passConfig.normal_rewards[1],passConfig.normal_rewards[2]
        elseif rewardType == SeasonPassManager.RewardType.Premium then
            rewardID,rewardCount = passConfig.premium_rewards[1],passConfig.premium_rewards[2]
        elseif rewardType == SeasonPassManager.RewardType.Luxury then
            rewardID,rewardCount = passConfig.luxury_rewards[1],passConfig.luxury_rewards[2]
        end
        if rewardID then
            rewardCount = rewardCount or 1
            ShopManager:Buy_LimitPackReward(rewardID,nil,function()
                local showValue,showIcon = CommonRewardUI:GetShowValueString(rewardID,rewardCount)
                local rewardData = {icon = showIcon,num = showValue}
                local needBackDiamond, backDiamond, isAD = ShopManager:CheckIfBackDiamond(rewardID)
                if needBackDiamond then
                    backDiamond = backDiamond * rewardCount
                    rewardData.backDiamond = backDiamond
                    if not isAD then
                        ResourceManger:AddDiamond(backDiamond, nil, nil, true)
                    end
                    rewardData = {icon = "icon_shop_diamond_1", num = backDiamond}
                end
                CommonRewardUI:ShowRewardsOneByOne({rewardData},function()
                    GameTableDefine.MainUI:UpdateResourceUI()
                end)
                local shopCfg = ShopManager:GetCfg(rewardID)
                if shopCfg and shopCfg.type == 37 then
                    local leftTicket = self.m_currentGameManager:GetTicketNum()
                    GameSDKs:TrackForeign("pass_ticket", {behavior = 1,num = shopCfg.amount * rewardCount,left = leftTicket,source = 1})
                end
                --2025-1-7 fy  通行证奖励获取钻石埋点 
                if shopCfg and shopCfg.type == 3 then
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "通行证奖励", behaviour = 1, num_new = tonumber(shopCfg.amount * rewardCount)})
                end
                LocalDataManager:WriteToFile()
            end,false,rewardCount)
        end

        --设为已领取
        local currentPass = self:GetCurrentPassData()
        if currentPass then
            local gotRewardInfo = currentPass.gotRewardInfo
            local levelKey = tostring(level)
            if not gotRewardInfo then
                gotRewardInfo = {}
                currentPass.gotRewardInfo = gotRewardInfo
            end
            local levelRewardInfo = gotRewardInfo[levelKey]
            if not levelRewardInfo then
                levelRewardInfo = {}
                gotRewardInfo[levelKey] = levelRewardInfo
            end
            levelRewardInfo[rewardType] = true
        end

        return true
    else
        return false
    end
end

---发放所有可以领取的奖励(不包括额外等级奖励)给玩家
function SeasonPassManager:DistributeAllReward()
    local distributed = false
    local curLevel,maxLevel = self:GetLevelInfo()
    curLevel = math.min(curLevel,self.m_rewardConfigCount)
    if curLevel > 0 then
        for i = 1, curLevel do
            distributed = self:DistributeReward(i,SeasonPassManager.RewardType.Normal) or distributed
            distributed = self:DistributeReward(i,SeasonPassManager.RewardType.Premium) or distributed
            distributed = self:DistributeReward(i,SeasonPassManager.RewardType.Luxury) or distributed
        end
    else
        distributed = false
    end
    return distributed
end


---获取高级通行证和豪华通行证的价格
---@return number,number premiumPrice,luxuryPrice
function SeasonPassManager:GetPassPrice()
    local premiumPrice = Shop:GetShopItemPrice(SeasonPassManager.PREMIUM_SHOP_ID)
    local luxuryPrice = Shop:GetShopItemPrice(SeasonPassManager.LUXURY_SHOP_ID)

    return premiumPrice,luxuryPrice
end

---获取上次解锁到的星级位置
function SeasonPassManager:GetUnlockFame()
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        return currentPass.lastUnlockIndex or 0
    else
        return false
    end
    return 0
end

---设置上次解锁到的星级位置
function SeasonPassManager:SetUnlockFame(index)
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        currentPass.lastUnlockIndex = index
    end
end

---获取第一个可以获得奖励的Index,或者最新领奖处
---@return number
function SeasonPassManager:GetFirstCanGetRewardIndex()
    local currentPass = self:GetCurrentPassData()
    if currentPass then
        local curLevel,maxLevel = self:GetLevelInfo()
        local gotRewardInfo = currentPass.gotRewardInfo
        if not gotRewardInfo then
            return 1
        end
        for i=1,curLevel do
            local levelKey = tostring(i)
            local levelData = gotRewardInfo[levelKey]
            if levelData then
                if not levelData[SeasonPassManager.RewardType.Normal] or
                        (self:IsBuyPremium() and not levelData[SeasonPassManager.RewardType.Premium]) or
                        (self:IsBuyLuxury() and not levelData[SeasonPassManager.RewardType.Luxury]) then
                    return i
                end
            else
                return i
            end
        end
        return math.min(curLevel,maxLevel)
    else
        return 1
    end
end

--[[
    @desc: 设置本次通行证是否第一次进入的标志
    author:{author}
    time:2024-12-30 18:12:31
    --@flag: 
    @return:
]]
function SeasonPassManager:SetIsFirstFlag(flag)
    if not self.m_saveData then
        return
    end
    if self.m_saveData.isFirstEnter == 1 or not self.m_saveData.isFirstEnter then
        self.m_saveData.isFirstEnter = flag
    end
end

function SeasonPassManager:GetIsFirstEnter()
    if not self.m_saveData or not self.m_saveData.isFirstEnter then
        return 1
    end
    return self.m_saveData.isFirstEnter
end

---@private
function SeasonPassManager:GetPackData()
    if not self.m_currentPassData then
        return
    end
    
    if not self.m_currentPassData.packs then
        self.m_currentPassData.packs = {}
    end
    return self.m_currentPassData.packs
end

function SeasonPassManager:CanBuyPack(shopID)
    shopID = shopID or 1615
    local packData = self:GetPackData()
    if not packData then
        return false
    end
    if not packData[tostring(shopID)] then
        return true
    end
    local shopCfg = ShopManager:GetCfg(shopID)
    return packData[tostring(shopID)] or 0 < shopCfg.numLimit
end

function SeasonPassManager:AddBuyPackTimes(shopID, num)
    shopID = tostring(shopID)
    local packData = self:GetPackData()
    packData[shopID] = packData[shopID] and packData[shopID] + num or num
end

function SeasonPassManager:GetPackBuyTime(shopID)
    shopID = shopID and tostring(shopID) or tostring(ConfigMgr.config_global.pass_cnYear_ticketPack)
    local packData = self:GetPackData()
    return packData[shopID] or 0 
end

SeasonPassManager:ctor()

return SeasonPassManager