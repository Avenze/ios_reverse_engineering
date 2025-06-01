local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local CfgMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local MainUI = GameTableDefine.MainUI
local json = require("rapidjson")
local ShopManager = GameTableDefine.ShopManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local ActivityRankRewardGetUI = GameTableDefine.ActivityRankRewardGetUI
local ChooseUI = GameTableDefine.ChooseUI
local UnityHelper = CS.Common.Utils.UnityHelper
--[[
    @desc: 获取玩家自身当前的活动排行值
    author:{author}
    time:2022-10-10 10:49:55
    @return:
]]

function ActivityRankDataManager:CheckServerTimeInit()
    -- if not GameConfig:IsWarriorVersion() then
    --     return
    -- end
    local resultTime = GameTimeManager:GetCurrentServerTime(true)
    if self.checkServerTimerID then
        GameTimer:StopTimer(self.checkServerTimerID)
        self.checkServerTimerID = nil
    end
    if not resultTime then
        self:LoginFailHint(function()
            self.checkServerTimerID = GameTimer:CreateNewTimer(1, handler(ActivityRankDataManager, ActivityRankDataManager.HeartCheckServeTime), true)
        end)
    else
        self.checkServerTime = true
        self:Init()
    end
end

function ActivityRankDataManager:HeartCheckServeTime()
    local resultTime = GameTimeManager:GetCurrentServerTime(true)
    if resultTime then
        self.checkServerTime = true
        if self.checkServerTimerID then
            GameTimer:StopTimer(self.checkServerTimerID)
            self.checkServerTimerID = nil
        end
        self:Init()
    else
        self:LoginFailHint(function()
            -- Just to print
            -- print("Open the error msg")
        end)
    end
end

function ActivityRankDataManager:Init()
    if not self.checkServerTime then
        self:CheckServerTimeInit()
        return
    end
    if self.isInit then
        return
    end
    self.rankData = {}
    local isNeedRequestServerData = false
    -- 首先需要读取玩家本地存档相对于活动的相关数据
    self.saveRankData = LocalDataManager:GetDataByKey("activity_rank_data")
    if self.saveRankData["start_time"] and self.saveRankData["start_time"] > 0 and self.saveRankData["start_time"] < GameTimeManager:GetCurServerOrLocalTime(true) 
    and self.saveRankData["over_time"] and self.saveRankData["over_time"] > 0 and self.saveRankData["over_time"] > GameTimeManager:GetCurServerOrLocalTime(true) then
        --本地存档的活动时间还有效在活动中
        self.activityStartTime = self.saveRankData["start_time"]
        self.activityOvetTime = self.saveRankData["over_time"]
        self.activityIsOverTime = false
        self:SpawnCurRankNames()
        self:RefreshRankData()
        if self.rankCalTimer then
            GameTimer:StopTimer(self.rankCalTimer)
            self.rankCalTimer = nil
        end
        if not self:GetActivityIsOverTimer() then
            local loopTime = 3 * 60;
            self.rankCalTimer = GameTimer:CreateNewTimer(loopTime, handler(ActivityRankDataManager, ActivityRankDataManager.RefreshRankData), true)
        end
        
        self.isInit = true
    else
        if self.saveRankData["player_cur_score"] and self.saveRankData["player_cur_score"] > 0 then
            --设置玩家可以领取活动奖励了
            self.getPlayerActivityRankReward = true
        end
        self:RequestCheckActivityOpen()
        self.isInit = true
    end
end

function ActivityRankDataManager:IsActivityRankActive()
    if not GameConfig:IsWarriorVersion() then
        return false
    end
    return self.activityRankFlag
end

--[[
    @desc: 请求服务器是否开启了排行活动
    author:{author}
    time:2022-10-10 13:47:52
    @return:
]]
function ActivityRankDataManager:RequestCheckActivityOpen()
    print("Request server to get activity is open")
    -- 如果没有存档活动数据去服务器请求活动对应的开启时间结束时间等等
    local requestTable = {
        callback = function(response)
            if response.data and response.data ~= "" then
                local data = json.decode(response.data)
                local oldStartime = self.saveRankData["start_time"]
                self.saveRankData["start_time"] = tonumber(data.DingShiHuoYue_android.beginTime)
                local oldOverTime = self.saveRankData["over_time"]
                self.saveRankData["over_time"] = tonumber(data.DingShiHuoYue_android.endTime)
                if GameDeviceManager:IsiOSDevice() then
                    self.saveRankData["start_time"] = tonumber(data.DingShiHuoYue_ios.beginTime)
                    self.saveRankData["over_time"] = tonumber(data.DingShiHuoYue_ios.endTime)
                end
                if self.requestTimer then
                    GameTimer:StopTimer(self.requestTimer)
                    self.requestTimer = nil
                end
                self.activityStartTime = self.saveRankData["start_time"]
                self.activityOvetTime = self.saveRankData["over_time"]
                if self:GetActivityIsOverTimer() then
                    self.requestTimer = GameTimer:CreateNewTimer(300, handler(ActivityRankDataManager, ActivityRankDataManager.RequestCheckActivityOpen))
                else
                    if not self.getPlayerActivityRankReward then
                        self:CheckNotifyMainUIReOpen()
                        self:SpawnCurRankNames(true) 
                        self:RefreshRankData()
                    end
                end
            end
        end,
        errorcallback = function(error)
            if not self.requestTimer then
                self.requestTimer = GameTimer:CreateNewTimer(300, handler(ActivityRankDataManager, ActivityRankDataManager.RequestCheckActivityOpen))
            end
        end
    }
    GameNetwork:HTTP_PublicSendRequest(GameNetwork.GET_ACTIVITY_RANK_OPEN_URL, requestTable, nil, "GET")
end

function ActivityRankDataManager:LocalTestInit()
    --测试数据，本地的功能测试
    --读取存档的玩家的活动数据
    self.saveRankData = LocalDataManager:GetDataByKey("activity_rank_data")
    self.rankData = {}
    self.activityRankFlag = true
    self.activityIsOverTime = false
    --TODO:测使用就是每次进游戏都是从新开始活动，活动持续5分钟
    self.activityStartTime = GameTimeManager:GetCurServerOrLocalTime(true)
    self.activityOvetTime = self.activityStartTime + CfgMgr.config_global.activity_duration
    
    local isNeedSave = false
    if self.saveRankData ~= nil then
        if self.saveRankData["start_time"] and self.saveRankData["start_time"] > 0 and self.saveRankData["start_time"] > self.activityStartTime then
            self.activityStartTime = self.saveRankData["start_time"]
        else
            self.saveRankData["start_time"] = self.activityStartTime
            isNeedSave = true
        end
        
        if self.saveRankData["over_time"] and self.saveRankData["over_time"] > 0 and self.saveRankData["over_time"] > self.activityOvetTime then
            self.activityOvetTime = self.saveRankData["over_time"]
        else
            self.saveRankData["over_time"] = self.activityOvetTime
            isNeedSave = true
        end
        if not self.saveRankData["player_cur_score"] then
            self.saveRankData["player_cur_score"] = 0
            isNeedSave = true
        end

        if not self.saveRankData["other_player_name_ids"] then
            local haveUserID = {}
            self.saveRankData["other_player_name_ids"] = {}
            local CfgPlayername = CfgMgr.config_playername
            for id, v in ipairs(CfgPlayername) do
                table.insert(haveUserID, v.name)
            end
            if #haveUserID > CfgMgr.config_global.activity_poolsize then
                while #self.saveRankData["other_player_name_ids"] <= CfgMgr.config_global.activity_poolsize do
                    local index = math.random(1, #haveUserID - 1)
                    table.insert(self.saveRankData["other_player_name_ids"], haveUserID[index])
                    table.remove(haveUserID, index)
                end
                isNeedSave = true
            end
        end
    end

    if isNeedSave then
        LocalDataManager:WriteToFile()
    end
    self:RefreshRankData()
    self.activityIsOverTime = (self.activityOvetTime > GameTimeManager:GetCurServerOrLocalTime(true))
    
    if self.rankCalTimer then
        GameTimer:StopTimer(self.rankCalTimer)
        self.rankCalTimer = nil
    end
    if not self:GetActivityIsOverTimer() then
        local loopTime = CfgMgr.config_global.activity_freshtime
        self.rankCalTimer = GameTimer:CreateNewTimer(loopTime, handler(ActivityRankDataManager, ActivityRankDataManager.RefreshRankData), true)
    end
    self.isInit = true
end

function ActivityRankDataManager:RefreshLastRankData()
    local rankData = {}
    local cfg = CfgMgr.config_activityrank
    
    for k, v in ipairs(cfg) do
        --print("刷新活动排行榜 k is:"..k.." v is:"..tostring(v))
        local infoData = self:GetRankElementData(k, true)
        if infoData then
            table.insert(rankData, {id = k, head = infoData.head, name = infoData.name, value = infoData.score, isPlayer = false})
        end
    end
    --添加玩家的相关数据
    local playerhead = "head_"..LocalDataManager:GetBossSkin()
    local playername = LocalDataManager:GetBossName()
    local playerScore = 0
    if self.saveRankData["player_cur_score"] then
        playerScore = self.saveRankData["player_cur_score"]
    else
        self.saveRankData["player_cur_score"] = 0
        playerScore = 0
    end
    table.insert(rankData, {id = 9999, head = playerhead, name = playername, value = playerScore, isPlayer = true})
    
    table.sort(rankData, function(a,b)
        if a.value ~= b.value then
            return a.value > b.value
        else
            return a.id > b.id
        end
    end)

    self.rankData = Tools:CopyTable(rankData)
end

function ActivityRankDataManager:RefreshRankData()
    print("从新刷新排行榜数据")
    --step1.检测活动是否已经结束
    if self:GetActivityIsOverTimer() then
        if self.rankCalTimer then
            GameTimer:StopTimer(self.rankCalTimer)
            self.rankCalTimer = nil
        end
    end
    local rankData = {}
    local itemData = {head = "", name = "", value = 0, isPlayer = false}
    local offsetActivityTime = GameTimeManager:GetCurServerOrLocalTime(true) --已经进行了游戏的时间，按秒计算
    local totalActivityTime = 1000

    local cfg = CfgMgr.config_activityrank
    
    for k, v in ipairs(cfg) do
        --print("刷新活动排行榜 k is:"..k.." v is:"..tostring(v))
        local infoData = self:GetRankElementData(k)
        if infoData then
            table.insert(rankData, {id = k, head = infoData.head, name = infoData.name, value = infoData.score, isPlayer = false})
        end
    end
    --添加玩家的相关数据
    local playerhead = "head_"..LocalDataManager:GetBossSkin()
    local playername = LocalDataManager:GetBossName()
    local playerScore = 0
    if self.saveRankData["player_cur_score"] then
        playerScore = self.saveRankData["player_cur_score"]
    else
        self.saveRankData["player_cur_score"] = 0
        playerScore = 0
    end
    table.insert(rankData, {id = 9999, head = playerhead, name = playername, value = playerScore, isPlayer = true})
    
    table.sort(rankData, function(a,b)
        if a.value ~= b.value then
            return a.value > b.value
        else
            return a.id > b.id
        end
    end)

    self.rankData = Tools:CopyTable(rankData)
end

function ActivityRankDataManager:GetActivityIsOverTimer()
    --检测活动是否已经结束
    if not self.activityOvetTime then
        return true
    end
    if GameTimeManager:GetCurServerOrLocalTime(true) and GameTimeManager:GetCurServerOrLocalTime(true) >= self.activityOvetTime then
        return true
    end
    if not self.activityStartTime then
        return true
    end
    if GameTimeManager:GetCurServerOrLocalTime() and GameTimeManager:GetCurServerOrLocalTime() < self.activityStartTime then
        return true
    end
    return false
end

function ActivityRankDataManager:GetRankData()
    for i, v in ipairs(self.rankData) do
        if v.isPlayer then
            v.value = self.saveRankData["player_cur_score"]
            break;
        end
    end
    table.sort(self.rankData, function(a,b)
        if a.value ~= b.value then
            return a.value > b.value
        else
            return a.id > b.id
        end
    end)
    for i ,v in ipairs(self.rankData) do
        if v.isPlayer then
            v.id = i
            break
        end
    end
    if #self.rankData >= CfgMgr.config_global.activity_poolsize then
        local result = {}
        for i, v in ipairs(self.rankData) do
            if i > CfgMgr.config_global.activity_poolsize then
                break
            end
            table.insert(result, v)
        end
        return result
    else
        return self.rankData
    end
end

function ActivityRankDataManager:GetPlayerRankData()
    for i, v in ipairs(self.rankData) do
        if v.isPlayer then
            v.id = i
            return v
        end
    end
    return nil
end

function ActivityRankDataManager:GetRankElementData(index, isLastRank)
    local infoData ={head = "", name = "nil", score = 0}
    local nameCfg = CfgMgr.config_playername
    local activityCfg = CfgMgr.config_activityrank
    if not self.saveRankData["other_player_name_ids"] then
        self:SpawnCurRankNames(true)
    end
    --TODO：暂时都按照index来取，等玩家数据部分完成后再实装读取数据等相关内容
    for i, v in ipairs(activityCfg) do
        if i == index then
            infoData.head = v.NPC_avatar
            local nameId = tonumber(self.saveRankData["other_player_name_ids"][index].nameID)
            local randomParam = tonumber(self.saveRankData["other_player_name_ids"][index].randomParam)
            if index <= #self.saveRankData["other_player_name_ids"] and nameId <=  #CfgMgr.config_playername then
                
                infoData.name = CfgMgr.config_playername[nameId].name
            else
                infoData.name = "random_"..index
            end
            infoData.score = self:GetRandomRankValue(v, randomParam, isLastRank)
            break
        end
    end
    return infoData
end

function ActivityRankDataManager:GetCurrentLeftTime()
    if self:GetActivityIsOverTimer() then
        return 0;
    end
    if self.activityOvetTime > 0 then
        return self.activityOvetTime - GameTimeManager:GetCurServerOrLocalTime(true)
    end
    return 0
end

function ActivityRankDataManager:GetPassedTime()
    if self:GetActivityIsOverTimer() then
        if self.activityOvetTime and self.activityStartTime then
            return self.activityOvetTime - self.activityStartTime
        else
            return 0
        end
    end
    if self.activityStartTime > 0 then
        local passTime = GameTimeManager:GetCurServerOrLocalTime(true) - self.activityStartTime
        if passTime > 0 then
            return passTime
        else
            return 0
        end
    end
    return 0
end

function ActivityRankDataManager:GetRandomRankValue(configItem, randomParam, isLastRank)
    if isLastRank then
        return configItem.first_value + (configItem.final_value * (1 + (configItem.index * randomParam))) 
    end
    local usedFinalValue = configItem.final_value
    local totalTime = self.activityOvetTime - self.activityStartTime
    if totalTime > 0 then
        local param1 = self:GetPassedTime() / totalTime
        local param2 = configItem.index * randomParam
        local param3 = usedFinalValue * param1 * param2
        return configItem.first_value + param3
    end
    return 0
end

--玩家升级家具时获取排行数据值的接口
function ActivityRankDataManager:PlayerCheckGetRankValue(furnituresLevel)
    if self:GetActivityIsOverTimer() then
        return false
    end
    if not self.saveRankData["add_product_percent"] then
        self.saveRankData["add_product_percent"] = 0
    end
    local tokenCfg = CfgMgr.config_token
    local getProductPercent = 0
    local cfgItem = nil
    for i, v in ipairs(tokenCfg) do
        if v.level == furnituresLevel then
            cfgItem = v
        end
    end
    if not cfgItem then
        return false
    end
    local isNeedSave = false
    getProductPercent = cfgItem.chance
    --step1获取当前保存的增益概率
    if self.saveRankData["add_product_percent"] and self.saveRankData["add_product_percent"] > 0 then
        getProductPercent = getProductPercent + self.saveRankData["add_product_percent"]
    end
    if getProductPercent <= 0 then
        return false
    end
    local getRandValue = math.random(1, 100 - 1)

    if getRandValue > getProductPercent * 100 then
        self.saveRankData["add_product_percent"] = self.saveRankData["add_product_percent"] + cfgItem.add
        LocalDataManager:WriteToFile()
        return false
    end
    self.saveRankData["add_product_percent"] = 0
    if self.saveRankData["player_cur_score"] then
        self.saveRankData["player_cur_score"] = self.saveRankData["player_cur_score"] + cfgItem.amount
    else
        self.saveRankData["player_cur_score"] = cfgItem.amount
    end
    LocalDataManager:WriteToFile()
    return true
end

function ActivityRankDataManager:CanDisplayMainUIEntry()
    if self.getPlayerActivityRankReward then
        return self.saveRankData and self.saveRankData["player_cur_score"] > 0
    else
        return not self:GetActivityIsOverTimer()
    end
end

-- 返回玩家是否能领取奖励
function ActivityRankDataManager:CanGetPlayerScoreReward()
    if self.getPlayerActivityRankReward then
        return self.saveRankData["player_cur_score"]
    else
        return 0
    end
end

function ActivityRankDataManager:ReallyGetRankReward()
    local playerData = self:GetPlayerRankData()
    if playerData and playerData.id and playerData.value then
        GameSDKs:TrackForeign("rank_activity", {name = "DingShiHuoYue", operation = "2", rank_new = tonumber(playerData.id) or 0, score_new = tonumber(playerData.value) or 0})
    end
    ActivityRankRewardGetUI:CloseView()
    if self.saveRankData["player_cur_score"] <= 0 then
        return
    end
    local rewardIndex = 0
    for key = #CfgMgr.config_activityrank, 1, -1 do
        if key == #CfgMgr.config_activityrank and self.saveRankData["player_cur_score"] < CfgMgr.config_activityrank[key].final_value then 
            rewardIndex = key
            break
        elseif key == 1 and self.saveRankData["player_cur_score"] >= CfgMgr.config_activityrank[1].final_value then
            rewardIndex = 1
            break
        elseif self.saveRankData["player_cur_score"] >= CfgMgr.config_activityrank[key].final_value and self.saveRankData["player_cur_score"] < CfgMgr.config_activityrank[key - 1].final_value then
            rewardIndex = key
            break
        end
    end
    
    self.getPlayerActivityRankReward = false
    self.saveRankData["player_cur_score"] = 0
    if rewardIndex > 0 then
        local rewardID = tonumber(CfgMgr.config_activityrank[rewardIndex].reward)
        if rewardID and rewardID > 0 then
            --发放奖励了
            ShopManager:Buy(rewardID, false, function()           
            end,function()                        
                --self:refresh()   
                PurchaseSuccessUI:SuccessBuy(rewardID)                        
            end) 
        end
    end
    LocalDataManager:WriteToFile()
    LocalDataManager:Update()
    if self:GetActivityIsOverTimer() then
        self:RequestCheckActivityOpen()
    else
        self:CheckNotifyMainUIReOpen()
        self:SpawnCurRankNames(true) 
        self:RefreshRankData()
    end
end

function ActivityRankDataManager:GetLastActivityRankReward()
    if not self.getPlayerActivityRankReward then
        return
    end
    self:lastRefreshRankData()
end

function ActivityRankDataManager:GetActivityRankReward(notOnline)
    -- self:TestGetRewardFunc()
    if not self.getPlayerActivityRankReward and not notOnline then
        return
    end
    if not notOnline then
        self:RefreshLastRankData()
        GameTableDefine.ActivityRankUI:GetView()
        GameTableDefine.ActivityRankUI:LastActivityShow()
        return
    end
    local rewardIndex = 0
    for key = #CfgMgr.config_activityrank, 1, -1 do
        if key == #CfgMgr.config_activityrank and self.saveRankData["player_cur_score"] < CfgMgr.config_activityrank[key].final_value then 
            rewardIndex = key
            break
        elseif key == 1 and self.saveRankData["player_cur_score"] >= CfgMgr.config_activityrank[1].final_value then
            rewardIndex = 1
            break
        elseif self.saveRankData["player_cur_score"] >= CfgMgr.config_activityrank[key].final_value and self.saveRankData["player_cur_score"] < CfgMgr.config_activityrank[key - 1].final_value then
            rewardIndex = key
            break
        end
    end
    if rewardIndex > 0 then
        local rewardID = tonumber(CfgMgr.config_activityrank[rewardIndex].reward)
        ActivityRankRewardGetUI:GetView()
        if rewardID > 0 then
            ActivityRankRewardGetUI:ShowRewardItem(rewardID)
        else
            ActivityRankRewardGetUI:ShowNoRewardInfo()
        end

    end
end

function ActivityRankDataManager:SpawnCurRankNames(isNeedRespawn)
    if self.saveRankData["other_player_name_ids"] and #self.saveRankData["other_player_name_ids"] >= #CfgMgr.config_activityrank then
        if not isNeedRespawn then
            return
        end
    end
    local haveUserID = {}
    self.saveRankData["other_player_name_ids"] = {}
    local CfgPlayername = CfgMgr.config_playername
    for id, v in ipairs(CfgPlayername) do
        table.insert(haveUserID, v.id)
    end
    if #haveUserID > #CfgMgr.config_activityrank then
        local useIndex = 1
        while #self.saveRankData["other_player_name_ids"] < #CfgMgr.config_activityrank do
            local index = math.random(1, #haveUserID - 1)
            local offsetValue = math.random(1, 499)
            local configItem = CfgMgr.config_activityrank[useIndex]
            local strIndex1, strIndex2 = string.find(configItem.interval, ",")
            local randValue1 = tonumber(string.sub(configItem.interval, 0, strIndex1 - 1))
            local randValue2 = tonumber(string.sub(configItem.interval, strIndex2 + 1))
            if randValue1 and randValue2 then
                offsetValue = math.random(randValue1 + 1, randValue2 - 1)
            end
            table.insert(self.saveRankData["other_player_name_ids"], {nameID = haveUserID[index], randomParam = offsetValue})
            table.remove(haveUserID, index)
            useIndex = useIndex + 1
        end
    end

end

function ActivityRankDataManager:TestGetRewardFunc()
    self.saveRankData["player_cur_score"] = 500000
    self.getPlayerActivityRankReward = true
end

function ActivityRankDataManager:GMAddPlayerRankScore()
    if GameConfig:IsDebugMode() then
        if self:CanGetPlayerScoreReward() and self:GetActivityIsOverTimer() then
            self:GMLocalOpenActivityRank()
        else
            self.saveRankData["player_cur_score"] = self.saveRankData["player_cur_score"] + 1000
            LocalDataManager:WriteToFile()
        end
    end
end

function ActivityRankDataManager:CheckNotifyMainUIReOpen()
    print("在线领取完奖励后再次请求开启活动后显示按钮")
    if self.checkDispTimer then
        GameTimer:StopTimer(self.checkDispTimer)
        self.checkDispTimer = nil
    end
    if LocalDataManager:IsNewPlayerRecord() then
        self.checkDispTimer = GameTimer:CreateNewTimer(5, function()
            if not LocalDataManager:IsNewPlayerRecord() then
                GameTimer:StopTimer(self.checkDispTimer)
                self.checkDispTimer = nil
                MainUI:ReOpenActivityRankBtn()
            end
        end, true)
    else
        MainUI:ReOpenActivityRankBtn()
    end
    
end

function ActivityRankDataManager:LoginFailHint(cb)
	local txt = GameTextLoader:ReadText("TXT_TIP_LOGIN_SERVER_TIMEFAIL")
	ChooseUI:CommonChoose(txt, function()
		cb()
	end, true, function()
        UnityHelper.ApplicationQuit()
	end)
end

function ActivityRankDataManager:GMLocalOpenActivityRank()
    local oldStartime = self.saveRankData["start_time"]
    self.saveRankData["start_time"] = GameTimeManager:GetCurServerOrLocalTime()
    local oldOverTime = self.saveRankData["over_time"]
    self.saveRankData["over_time"] = self.saveRankData["start_time"] + 180
    if self.requestTimer then
        GameTimer:StopTimer(self.requestTimer)
        self.requestTimer = nil
    end
    self.activityStartTime = self.saveRankData["start_time"]
    self.activityOvetTime = self.saveRankData["over_time"]
    if self:GetActivityIsOverTimer() then
        self.requestTimer = GameTimer:CreateNewTimer(300, handler(ActivityRankDataManager, ActivityRankDataManager.RequestCheckActivityOpen))
    else
        if not self.getPlayerActivityRankReward then
            self:CheckNotifyMainUIReOpen()
            self:SpawnCurRankNames(true) 
            self:RefreshRankData()
        end
    end
end