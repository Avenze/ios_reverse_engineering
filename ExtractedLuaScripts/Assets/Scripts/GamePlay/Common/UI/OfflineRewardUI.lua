---@class OfflineRewardUI
local OfflineRewardUI = GameTableDefine.OfflineRewardUI
local MainUI = GameTableDefine.MainUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local OfflineManager = GameTableDefine.OfflineManager
local EventManager = require("Framework.Event.Manager")
local ResourceManger = GameTableDefine.ResourceManger
local FloorMode = GameTableDefine.FloorMode
local TimerMgr = GameTimeManager
local CompanyMode = GameTableDefine.CompanyMode
local ShopManager = GameTableDefine.ShopManager
local StarMode = GameTableDefine.StarMode
local CountryMode = GameTableDefine.CountryMode
local GuideManager = GameTableDefine.GuideManager
local timerId = nil
local LAST_GAME_TIME = "last_game_time"

local SAVE_KEY = {[1] = "", [2]= "Euro"}

--
--function OfflineRewardUI:GetView()
--    if not self:CheckCanOpenRewardUI() then
--        return
--    end
--    local list = self:NewGetRewardValueList()
--    if not list[1] or (list[1] and list[1] <= 0) then return end
--    if not OfflineManager:GreaterThanOffline(OfflineManager.m_offlineSum) then return end
--    
--    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI, self.m_view, require("GamePlay.Common.UI.OfflineRewardUIView"), self, self.CloseView)
--    return self.m_view
--end
--
--function OfflineRewardUI:CloseView()
--    GameSDKs:ClearRewardAd()
--    GameUIManager:CloseUI(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI)
--    self.m_view = nil
--    collectgarbage("collect")
--end
--
--function OfflineRewardUI:LeaveTime()
--    local notUse, leaveTime = self:OffTimePassSecond()
--    return leaveTime
--end
--
--function OfflineRewardUI:UpdateLeaveTime()
--    if StarMode:GetStar() < ConfigMgr.config_global.offline_condition then
--        return
--    end
--
--    local lastOfflineTime = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
--    lastOfflineTime.time = GameTimeManager:GetNetWorkTimeSync(true)
--    LocalDataManager:WriteToFile()
--end
--
--function OfflineRewardUI:StartUpdateLeaveTime()
--    if timerId then
--        GameTimer:StopTimer(timerId)
--        timerId = nil
--    end
--    
--    timerId = GameTimer:CreateNewTimer(60, function()
--        self:UpdateLeaveTime()
--    end,true)
--end
--
----获取距离上次离线的时间只能用此方法的 self.result 来获取,不然就会导致错误
--function OfflineRewardUI:OffTimePassSecond()--离线总时长 
--    if self.offTimeList == nil then
--        self.offTimeList = {}
--        local lastOfflineTime = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
--        local currTime = TimerMgr:GetNetWorkTimeSync(true)
--        if lastOfflineTime.time == nil or lastOfflineTime.time == 0 then
--            lastOfflineTime.time = currTime
--            LocalDataManager:WriteToFile()
--        end
--        if lastOfflineTime.time > currTime then--对可能改过时间的人进行重置
--            lastOfflineTime.time = currTime
--            LocalDataManager:WriteToFile()
--        end
--
--        self.result = currTime - lastOfflineTime.time
--        self.result = self.result > 0 and self.result or 0
--
--        for k,v in pairs(SAVE_KEY) do
--            if lastOfflineTime["saveTime" .. v] == nil then
--                lastOfflineTime["saveTime" .. v] = 0
--            end
--
--            lastOfflineTime["saveTime" .. v] = lastOfflineTime["saveTime" .. v] + self.result
--            self.offTimeList[k] = lastOfflineTime["saveTime" .. v]
--        end
--
--    end
--        --离线的总时长(参与显示和判断是否满时间)  --距离上次离线的时长(参与当次的计算)
--    return self.offTimeList, self.result
--end
--
--function OfflineRewardUI:NewOffTimePassSecond() -- 返回离线时长列表
--    local offTimeList = {}
--
--    for k,v in pairs(SAVE_KEY) do
--        offTimeList[k] = OfflineManager.m_offlineSum or 0
--    end
--    return offTimeList
--end
--
----强制刷新离线时间
--function OfflineRewardUI:ForceRefreshOffTimePass()
--    self.offTimeList = nil 
--    self.rewardList = nil
--    return self:GetRewardValueList()   
--end
--
--function OfflineRewardUI:GetOfflineMaxTime(countryId)
--    local noUse, timeLimitImprove = FloorMode:GetManagerFurnituresBonus()
--    local shopTime = ShopManager:GetOfflineAdd(nil, countryId) * 3600
--    return ConfigMgr.config_global.offline_timelimit * 3600 + timeLimitImprove * 3600 + shopTime
--end
--
--function OfflineRewardUI:calculateReward(countryId)
--    if not countryId then
--        countryId = 1
--    end
--    local rewardList =  self:calculateRewardList()
--    return rewardList[countryId]
--end
--
--function OfflineRewardUI:NewCalculateReward(countryId)
--    if not countryId then
--        countryId = 1
--    end
--    local rewardList =  self:NewCalculateRewardList()
--    return rewardList[countryId]  
--end
--
--function OfflineRewardUI:calculateRewardList()
--    if self.rewardList == nil then 
--        self.rewardList = {}
--        local lastOfflineTime = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
--        local nowTime = TimerMgr:GetNetWorkTimeSync(true)
--        local timeMax 
--        local allPathTimeList, timePass = self:OffTimePassSecond()--过去的时间的列表  和  保存的时间的和
--                
--        for k,v in pairs(ConfigMgr.config_country) do
--            local cashTime = math.floor(timePass / 30) 
--            timeMax = self:GetOfflineMaxTime(v.id)
--            local pastSave = 0
--            local key = SAVE_KEY[v.id] 
--            if lastOfflineTime["reward" ..key] and lastOfflineTime["reward" ..key] > 0 then
--                pastSave = lastOfflineTime["reward" ..key]--之前积累的奖励值
--            end
--
--            -- if lastOfflineTime.isMax then                                           --标签已经满了
--            --     rewardList[v.id] = pastSave
--            if allPathTimeList[v.id] >= timeMax and allPathTimeList[v.id] - timePass < timeMax then  --总时长满了,但是还有一些时间需要计算
--                cashTime = math.floor((timeMax - (allPathTimeList[v.id] - timePass))/30)
--                --if cashTime < 0 then cashTime = 0 end
--                local totalRent = FloorMode:GetTotalRent(nil , v.id)
--                totalRent = cashTime * totalRent * FloorMode:OfflineRewardRate(v.id)   
--                totalRent = math.floor(totalRent)
--                self.rewardList[v.id] = totalRent + pastSave
--            elseif allPathTimeList[v.id] >= timeMax and allPathTimeList[v.id] - timePass >= timeMax then  --总时长满了,而且没有需要计算的时间
--                self.rewardList[v.id] = pastSave
--                lastOfflineTime.isMax = true
--            elseif allPathTimeList[v.id] < timeMax then                                                   
--                local totalRent = FloorMode:GetTotalRent(nil , v.id)                   --总时长都没满
--                totalRent = cashTime * totalRent * FloorMode:OfflineRewardRate(v.id)
--                totalRent = math.floor(totalRent)
--                self.rewardList[v.id] = totalRent + pastSave
--            end
--                    
--        end
--    end
--    return self.rewardList
--end
--
--function OfflineRewardUI:NewCalculateRewardList()
--    self.rewardList = {}
--    --local nowTime = TimerMgr:GetNetWorkTimeSync(true)
--    local timePass = OfflineManager.m_offlineSum
--    if not timePass then
--        _,timePass = OfflineManager:GetOffline()
--    end
--            
--    for k,v in pairs(ConfigMgr.config_country) do
--        local cashTime = math.floor(timePass / 30) 
--        --local timeMax = OfflineManager:GetOfflineMaxTime(v.id)
--        local totalRent = FloorMode:GetTotalRent(nil , v.id)                   --总时长都没满
--        totalRent = cashTime * totalRent * FloorMode:OfflineRewardRate(v.id)
--        totalRent = math.floor(totalRent)
--        self.rewardList[v.id] = totalRent
--    end
--
--    return self.rewardList
--end
--
--
--function OfflineRewardUI:GetRewardValueList()
--    local lastOfflineTime = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
--    if self.rewardList == nil then
--        self.rewardList = self:calculateRewardList()
--        for k,v in pairs(self.rewardList) do
--            local currCity = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[k]).currBuidlingId or 100
--            local max = ConfigMgr.config_buildings[currCity].offline_reward_limit
--            if v > max then
--                v = max
--            end
--            lastOfflineTime["reward" .. SAVE_KEY[k]] = v
--            lastOfflineTime.time = TimerMgr:GetNetWorkTimeSync(true)
--            LocalDataManager.WriteToFile()
--        end
--        if lastOfflineTime["reward"] < 500 and lastOfflineTime["saveTime"] >= self:GetOfflineMaxTime(1) then
--            lastOfflineTime["saveTime"] = 60
--            LocalDataManager.WriteToFile()
--        end        
--    end
--    return self.rewardList
--end
--
--function OfflineRewardUI:NewGetRewardValueList(refresh)
--    -- if self.rewardList == nil or self.rewardList[1] == 0 then
--        self.rewardList = self:NewCalculateRewardList()
--        for k, v in pairs(self.rewardList) do
--            local currCity = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[k]).currBuidlingId or 100
--            local max = ConfigMgr.config_buildings[currCity].offline_reward_limit
--            if v > max then
--                self.rewardList[k] = max
--            end
--        end
--    -- end
--
--    return self.rewardList
--end
--
--
----检测有无可以领取的钱(用于UI的显示判断)
--function OfflineRewardUI:CheckRewardValue()
--    if self.m_autoShow then
--        return false
--    end
--    local lastOfflineTime = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
--    local rewardValueList = self:NewGetRewardValueList()
--    for k,v in pairs(rewardValueList) do
--        if v > 0 then
--            return true
--        end
--    end
--    return false
--end
--
--function OfflineRewardUI:AutoDisplay(display)
--    if display == nil then
--        if self:CheckRewardValue() then
--            self:LoopCheckRewardValue()
--        end
--    elseif display == false then
--        self.m_autoShow = display
--    elseif display == true then
--        self.m_autoShow = display
--    end
--end
--
--function OfflineRewardUI:LoopCheckRewardValue()
--    if self.m_loopTimer then
--        GameTimer:StopTimer(self.m_loopTimer)
--        self.m_loopTimer = nil
--    end
--    self.m_loopTimer = GameTimer:CreateNewTimer(2,function()
--        if self:CheckCanOpenRewardUI() then
--            OfflineRewardUI:GetView()
--            GameTimer:StopTimer(self.m_loopTimer)
--            self.m_loopTimer = nil
--            self.m_autoShow = true
--        end
--    end, true)
--end
--
--function OfflineRewardUI:CheckCanOpenRewardUI()
--    if GameStateManager.m_currentGameState == GameStateManager.GAME_STATE_INSTANCE or GameStateManager.m_currentGameState == GameStateManager.GAME_STATE_CYCLE_INSTANCE then
--        return false
--    end
--    if FloorMode:GetScene() ~= nil and FloorMode:GetScene().m_GuideTimeLine == nil and GameUIManager:GetCameraStackSize() < 2 and not GuideManager.inGuide then -- and GameUIManager:CheckCameraEnable()
--        return true
--    end
--    return false
--end
--
--function OfflineRewardUI:isMax()
--    local isMax = false
--    local currCity = LocalDataManager:GetDataByKey("city_record_data").currBuidlingId or 100
--    local max = ConfigMgr.config_buildings[currCity].offline_reward_limit
--    if self:calculateReward() >= max then
--        isMax = true
--    end
--
--    return isMax
--end
--
--function OfflineRewardUI:NewIsMax()
--    local isMax = false
--    local currCity = LocalDataManager:GetDataByKey("city_record_data").currBuidlingId or 100
--    local max = ConfigMgr.config_buildings[currCity].offline_reward_limit
--    if self:NewCalculateReward() >= max then
--        isMax = true
--    end
--
--    return isMax
--end
--
----获取奖励的方法
--function OfflineRewardUI:GetReward(rewardRate)
--    for k,v in pairs(self:GetRewardValueList()) do
--        --local moneyId = ConfigMgr.config_money[k].resourceId
--        ResourceManger:AddLocalMoney(v * rewardRate , nil , function()
--            MainUI:HideButton("EventArea/OfflineReward")
--            --GameSDKs:Track("offline_reward", {reward_money = v * rewardRate, left = ResourceManger:GetCash()})
--            local lastOfflineTime = LocalDataManager:GetDataByKey(LAST_GAME_TIME)
--            lastOfflineTime.time = TimerMgr:GetNetWorkTimeSync(true)
--            lastOfflineTime["reward" .. SAVE_KEY[k]] = nil
--            lastOfflineTime.isMax = false
--            lastOfflineTime["saveTime" .. SAVE_KEY[k]] = 0     
--            self.rewardList[k] = 0
--            self.offTimeList[k] = 0
--        end, k ,true)        
--    end 
--    LocalDataManager.WriteToFile()   
--end
--
----获取奖励的方法
--function OfflineRewardUI:NewGetReward(rewardRate)
--    for k,v in pairs(self:NewGetRewardValueList()) do
--        ResourceManger:AddLocalMoney(v * rewardRate , nil , function()
--            MainUI:HideButton("EventArea/OfflineReward")
--            --GameSDKs:Track("offline_reward", {reward_money = v * rewardRate, left = ResourceManger:GetCash()})
--            -- self.rewardList[k] = nil
--            -- self.offTimeList[k] = nil
--            --2024-8-20添加用于的钞票消耗增加埋点上传
--            local type = CountryMode:GetCurrCountry()
--            local amount = v * rewardRate
--            local change = 0
--            local position = "离线奖励"
--            GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0,amount_new = tonumber(amount) or 0, position = position})
--        end, k ,true)        
--    end 
--    self.rewardList = nil
--    OfflineManager:SetReceivedTheAward()
--end


function OfflineRewardUI:GetView()
    self:GetModel()
    if not self:CheckCanOpenRewardUI() then
        return
    end
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI, self.m_view, require("GamePlay.Common.UI.OfflineRewardUIView"), self, self.CloseView)
    return self.m_view

end

function OfflineRewardUI:Refresh()
    self:GetModel()
    if not self:CheckCanOpenRewardUI() then
        return
    end
    if self.m_view then
        self.m_view:Refresh()
    end
end

---@class OfflineRewardUIModelDefine
---@field offlineData offlineData
---@field countryID number
---@field recommend table
---@field maxTime number
local OfflineRewardUIModelDefine = {}

function OfflineRewardUI:GetModel()
    ---@type OfflineRewardUIModelDefine
    self.model = {
        countryID = CountryMode:GetCurrCountry(),
        offlineData = Tools:CopyTable(OfflineManager.offlineData),
        recommend = self:GetRecommend(),
        maxTime = OfflineManager:GetOfflineMaxTime(CountryMode:GetCurrCountry())
    }
    return self.model
end

function OfflineRewardUI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI)
    self.m_view = nil
    collectgarbage("collect")
    GameTableDefine.UIPopupManager:DequeuePopView(self)
end

function OfflineRewardUI:CheckCanOpenRewardUI()
    if GameStateManager.m_currentGameState == GameStateManager.GAME_STATE_INSTANCE or 
        GameStateManager.m_currentGameState == GameStateManager.GAME_STATE_CYCLE_INSTANCE or
        GameStateManager.m_currentGameState == GameStateManager.GAME_STATE_CITY then
        return false
    end
    if not self:HaveOfflineReward() then
        return false
    end
    if not GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.MAIN_UI, true) then
        return false
    end
    if FloorMode:GetScene() ~= nil and FloorMode:GetScene().m_GuideTimeLine == nil and GameUIManager:GetCameraStackSize() < 2 and not GuideManager.inGuide then -- and GameUIManager:CheckCameraEnable()
        return true
    end
    return false
end

function OfflineRewardUI:LoopCheckRewardValue(func, immediately)
    if self.m_loopTimer then
        GameTimer:StopTimer(self.m_loopTimer)
        self.m_loopTimer = nil
    end
    self:GetModel()
    if immediately then
        func()
        return
    end
    self.m_loopTimer = GameTimer:CreateNewTimer(2, function()
        if self:CheckCanOpenRewardUI() then
            GameTableDefine.UIPopupManager:EnqueuePopView(self, function()
                func()
            end, "OfflineRewardUI")
            GameTimer:StopTimer(self.m_loopTimer)
            self.m_loopTimer = nil
            self.m_autoShow = true
        end 
    end, true)
end

function OfflineRewardUI:GetRecommend()
    local recommend = ConfigMgr.config_global.offline_manager_recommend
    for k, v in ipairs(recommend) do
        local shopCfg = ShopManager:GetCfg(tonumber(v))
        if ShopManager:CheckBuyTimes(shopCfg.id, shopCfg.numLimit) then
            return shopCfg
        end
    end
end

--获取奖励的方法
function OfflineRewardUI:NewGetReward(rewardRate)
    local income = self.model.offlineData.areaData[self.model.countryID].offlineReward * rewardRate
    ResourceManger:AddLocalMoney(income, nil, function()
        MainUI:HideButton("EventArea/OfflineReward")
        --GameSDKs:Track("offline_reward", {reward_money = v * rewardRate, left = ResourceManger:GetCash()})
        -- self.rewardList[k] = nil
        -- self.offTimeList[k] = nil
        --2024-8-20添加用于的钞票消耗增加埋点上传
        local type = CountryMode:GetCurrCountry()
        local amount = income
        local change = 0
        local position = "离线奖励"
        GameSDKs:TrackForeign("cash_event", { type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position })
    end, k, true)
    
    OfflineManager:CleanOfflineData(self.model.countryID)
end

---有可领取离线精力
function OfflineRewardUI:HaveOfflineReward(countryID)
    self:GetModel()

    countryID = countryID or self.model.countryID
    local offlineData = self.model.offlineData.areaData[countryID]
    if offlineData.offlineTime > 0 and offlineData.offlineReward > 0 then
        return true
    end
    return false
end

function OfflineRewardUI:CheckCanOpen()
    return true
end