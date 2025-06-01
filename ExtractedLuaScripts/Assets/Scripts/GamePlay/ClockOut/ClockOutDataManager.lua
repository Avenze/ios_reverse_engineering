--[[
    下班打卡活动的相关数据逻辑管理器
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-03-27 10:00:11
]]

--@class ClockOutDataManager
local ClockOutDataManager = GameTableDefine.ClockOutDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventDispatcher = EventDispatcher
local json = require("rapidjson")
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local Application = CS.UnityEngine.Application
local Rapidjson = require("rapidjson")
local GameUIManager = GameTableDefine.GameUIManager

function ClockOutDataManager:Init()
    if self.isInit then
        return
    end
    -- self.configTheme = 
    self.m_ClockOutData = LocalDataManager:GetDataByKey("clock_out_activity_data")
    
    if not self.m_ClockOutData or Tools:GetTableSize(self.m_ClockOutData) <= 0 then
        --没有活动向服务器请求活动
        self.m_isActivityOpen = false
    elseif self.m_ClockOutData["start_time"] and self.m_ClockOutData["end_time"] then
        if self.m_ClockOutData["start_time"] > 0 and self.m_ClockOutData["start_time"] < GameTimeManager:GetCurrentServerTime(true) and
        self.m_ClockOutData["end_time"] > 0 and self.m_ClockOutData["end_time"] > GameTimeManager:GetCurrentServerTime(true) then
            --存档中活动在进行中，获取存档已经购买的商品的数据ID，如果没有的话创建存档
            if not self.m_ClockOutData["rewards_data"] then
                self.m_ClockOutData["rewards_data"] = {}
                --这里还要根据相关内容进行初始化，按照现在的数据初始化，这块内容应该不会出现的,这个初始化应该在获取活动的时候就初始化了
            end
            self.m_isActivityOpen = true
        else
            self.m_ClockOutData["rewards_data"] = nil
            self.m_isActivityOpen = false
        end
    else
        self.m_ClockOutData["rewards_data"] = nil
        self.m_isActivityOpen = false
    end

    if not self.m_isActivityOpen then
        GameSDKs:WarriorGetActivityData(GameLanguage:GetCurrentLanguageID(), Application.version, TimeLimitedActivitiesManager.ClockOut)
    else
        -- GameTableDefine.ActivityRemoteConfigManager:CheckClockOutEnable()
        self:OpenClockOutActivity()    
    end

    EventDispatcher:RegEvent(GameEventDefine.CEOBoxPurchaseUIViewClose,function(boxDisplayDatas)
        if not self.needCEOWaitDisplay then
            return
        end
        local realDisplayDatas = {}
        if self.displayRewardDatas then
            for _, item in pairs(self.displayRewardDatas) do
                table.insert(realDisplayDatas, item)
            end
            self.displayRewardDatas = nil
        end
        if boxDisplayDatas and Tools:GetTableSize(boxDisplayDatas) > 0 then
            for _, itemData in pairs(boxDisplayDatas) do
                local displayItem = {}
                displayItem.shop_id = itemData.shopID
                displayItem.icon = itemData.icon
                displayItem.num = itemData.lastNum
                if itemData.ceoid > 0 then
                    displayItem.icon_altas = "UI_Common"
                    local ceoCfg = ConfigMgr.config_ceo[itemData.ceoid]
                    if ceoCfg then
                        displayItem.icon = ceoCfg.ceo_card
                    end
                end
                table.insert(realDisplayDatas, displayItem)
            end
        end
        if Tools:GetTableSize(realDisplayDatas) > 0 then
            GameTableDefine.CycleInstanceRewardUI:ShowGiftCodeGetRewards(realDisplayDatas, true)
        end
        self.needCEOWaitDisplay = false
    end)

    EventDispatcher:RegEvent(GameEventDefine.ActivityUIViewClose, function()
        self:UICloseEventProcess()
    end)
    EventDispatcher:RegEvent(GameEventDefine.RoomBuildingUIViewClose, function()
        self:UICloseEventProcess()
    end)
    
    EventDispatcher:RegEvent(GameEventDefine.ClockOut_Charge_Buy_Msg, handler(self,self.BuyClockOutIAPResult))
    LocalDataManager:WriteToFile()
    self.isInit = true
end

function ClockOutDataManager:OpenClockOutActivity()
    if self.m_ClockOutData then
        if not self.m_ClockOutData.m_ClockOutEnable then
            GameTableDefine.ActivityRemoteConfigManager:CheckClockOutEnable()
        else
            GameTableDefine.MainUI:OpenClockOutActivity()
        end
    end
end

function ClockOutDataManager:ProcessSDKCallbackData(warriorGiftPackData)
    if not warriorGiftPackData then return end
    if warriorGiftPackData.activityType ~= TimeLimitedActivitiesManager.ClockOut then
        GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "返回的活动类型不为11"})
        return
    end
    if not warriorGiftPackData.startTime or not warriorGiftPackData.endTime then
        GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "开始时间或者结束时间为空"})
        return 
    end
    if not self:CheckRequestDataIsValidity(warriorGiftPackData) then
        return
    end
    

    local startTime = tonumber(warriorGiftPackData.startTime)
    local endTime = tonumber(warriorGiftPackData.endTime)

    if not startTime or not endTime then
        GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "开始时间或者结束时间格式错误"})
        return
    end

    local curTime = GameTimeManager:GetCurrentServerTime(true)
    if startTime > curTime or endTime < curTime then
        GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "开始时间大于大于当前时间或者结束时间小于当前时间"})
        return
    end
    --初始化相关数据内容
    if self.m_ClockOutData then
        if self.m_ClockOutData.end_time and self.m_ClockOutData.start_time then
            if self.m_ClockOutData.end_time > curTime and self.m_ClockOutData.start_time <= curTime then 
                --存档活动在进行中
                return
            end
        end
        self:_InitWithWarriorActivityData(warriorGiftPackData)
        self:OpenClockOutActivity()
        GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放成功"})
    else
        return
    end
end

function ClockOutDataManager:GetActivityIsOpen()
    self:GetActivityLeftTime()
    if not self.m_ClockOutData or not self.m_ClockOutData.m_ClockOutEnable then
        return false
    end
    return self.m_isActivityOpen
end

--获取活动剩余时间
function ClockOutDataManager:GetActivityLeftTime()
    if not self.m_ClockOutData then
        self.m_isActivityOpen = false
        return 0
    end

    if self.m_ClockOutData.end_time and self.m_ClockOutData.end_time > 0 and self.m_ClockOutData.end_time > GameTimeManager:GetCurrentServerTime(true) then
        return self.m_ClockOutData.end_time - GameTimeManager:GetCurrentServerTime(true)
    end

    self.m_isActivityOpen = false
    return 0
end

--[[
    @desc: 提供给UI消耗当前门票给能操作的内容
    author:{author}
    time:2025-04-01 10:47:24
    --@level: 
    @return:
]]
function ClockOutDataManager:AddClockOutTicketsToCurRewardItem(level)
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return false
    end
    local opLevel, opData, isMax = ClockOutDataManager:GetCurOpertionData()
    if opLevel == 0 or isMax or opLevel ~= level then
        return false
    end
    if not self.m_ClockOutData.m_leftClockOutTickets then
        self.m_ClockOutData.m_leftClockOutTickets = 0
        return false
    end
    if self.m_ClockOutData.m_leftClockOutTickets < 1 then
        return false
    end
    if opData.curTickets >= opData.needTickets then
        return false
    end
    self.m_ClockOutData.m_leftClockOutTickets  = self.m_ClockOutData.m_leftClockOutTickets - 1
    if self:IsFirstConsumeTickets() then
        GameSDKs:TrackForeign("clockout_exposure", {type = "首次进行门票消耗"})
    end
    self.m_ClockOutData.m_configTotalTickets  = self.m_ClockOutData.m_configTotalTickets - 1
    if self.m_ClockOutData.m_configTotalTickets < 0 then
        self.m_ClockOutData.m_configTotalTickets = 0
    end
    opData.curTickets  = opData.curTickets + 1
    local isLvlUp = false
    if opData.curTickets == opData.needTickets then
        opData.canClaimStatus = true
        isLvlUp = true
        GameSDKs:TrackForeign("clockout_level", {num = opLevel})
    end

    return true, isLvlUp
end


--[[
    @desc: 添加下班打卡的门票
    author:{author}
    time:2025-04-01 18:59:42
    --@num:
	--@addChannel: 添加渠道1-GM命令，2-活跃任务，3-广告位（任意广告），4-办公室设施购买和升级
    --@exendParam: 用于埋点的额外参数
    @return:
]]
function ClockOutDataManager:AddClockOutTickets(num, addChannel, exendParam)
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return
    end
    --step1.如果已经升满级就不在增加门票了
    local isMaxLevel = true
    for level, rewardData in pairs(self.m_ClockOutData.rewards_data) do
        if not rewardData.canClaimStatus then
            isMaxLevel = false
            break
        end
    end
    if isMaxLevel then
        return
    end
    if not self.m_ClockOutData.m_leftClockOutTickets then
        self.m_ClockOutData.m_leftClockOutTickets = 0
    end
    if self.m_ClockOutData.m_leftClockOutTickets >= self.m_ClockOutData.m_configTotalTickets then
        if self.m_ClockOutData.m_leftClockOutTickets > self.m_ClockOutData.m_configTotalTickets then 
            self.m_ClockOutData.m_leftClockOutTickets = self.m_ClockOutData.m_configTotalTickets
        end
        return
    end
    self.m_ClockOutData.m_leftClockOutTickets  = self.m_ClockOutData.m_leftClockOutTickets + num
    local source = "GM命令"
    if addChannel > 1 then
        if addChannel == 2 then
            source = "活跃任务["..tostring(exendParam or 0).."]"
        end
        if addChannel == 3 then
            source = "广告位["..tostring(exendParam or 0).."]"
        end
        if addChannel == 4 then
            source = "设施升级"
        end
        GameSDKs:TrackForeign("clockout_ticket", {num = num, source = source})
    end
    local maxTickets = self.m_ClockOutData.m_configTotalTickets
    --step2.如果门票数已经大于等于当前升满级的门票数，直接获取到当前最大门票值
    if self.m_ClockOutData.m_leftClockOutTickets > maxTickets then
        self.m_ClockOutData.m_leftClockOutTickets = maxTickets
    end
    if addChannel == 2 or addChannel == 4 then
        if not self.waitAnimTickets then
            self.waitAnimTickets = num
        else
            self.waitAnimTickets  = self.waitAnimTickets + num
        end
    else
        self.waitAnimTickets = 0
        GameTableDefine.FlyIconsUI:ShowClockOutTicketsGetAnim(num, function()
         end)
    end
end


function ClockOutDataManager:CheckClockOutTicketsEnough(num)
    if not self.m_ClockOutData.m_leftClockOutTickets then
        return false
    end
    return self.m_ClockOutData.m_leftClockOutTickets >= num
end

--[[
    @desc: GM开启下班打卡活动
    author:{author}
    time:2025-03-27 18:10:37
    --@duration: 
    @return:
]]
function ClockOutDataManager:GMOpenClockOutActivity(duration)
    if not self.m_ClockOutData then
        self.m_ClockOutData = LocalDataManager:GetDataByKey("clock_out_activity_data")
    end
    

    -- local warriorActivityData = {
    --     "awards" [
    --         "1,0;0;10;1336,1_1337,1",
    --         "2,0;0;100;1336,1_1337,1",
    --         "3,1701;0;1000;1336,2_1337,5_1340,10",
    --         "4,0;1;10000;1336,1_1337,1"
    --     ],
    --     "clock_out_theme": "normal",
    --     "open_conditions": [
    --         {
    --             "type": 30,
    --             "value": "6",
    --             "compareType": 20
    --         }
    --     ],
    --     "instanceID": 214,
    --     "activityType": 11,
    --     "previewTime": 1742947200,
    --     "startTime": 1742947200,
    --     "settlementTime": 1743033600,
    --     "endTime": 1743033600,
    --     "icon": "icon1",
    --     "activityName": "下班打卡测试",
    --     "backgroundImg": "111",
    --     "tag": "",
    --     "content": "{seasonpass_theme=chineseyear, packContent=1481;40;0;1605,20_1714,30, level_20=100;3002,1;3002,3;3002,6;1, level_11=100;3002,1;3002,3;3002,6;0, level_10=100;3002,1;3002,3;3002,6;1, storeId=1479,1480, level_13=100;3002,1;3002,3;3002,6;0, level_12=100;3002,1;3002,3;3002,6;0, level_15=100;3002,1;3002,3;3002,6;1, level_14=100;3002,1;3002,3;3002,6;0, level_3=100;3002,1;3002,3;3002,6;0, level_17=100;3002,1;3002,3;3002,6;0, level_4=100;3002,1;3002,3;3002,6;0, level_16=100;3002,1;3002,3;3002,6;0, level_5=100;3002,1;3002,3;3002,6;1, level_19=100;3002,1;3002,3;3002,6;0, level_6=100;3002,1;3002,3;3002,6;0, level_18=100;3002,1;3002,3;3002,6;0, level_7=100;3002,1;3002,3;3002,6;0, level_8=100;3002,1;3002,3;3002,6;0, level_9=100;3002,1;3002,3;3002,6;0, seasonpass_type=tuibiji, level_1=100;3002,1;3002,3;3002,6;0, level_2=100;3002,1;3002,3;3002,6;0}"
    -- }
    --参数;分割
    --param1:level,0 or  ipa_config-id
    --param2:1大奖，0非大奖
    --param3:门票解锁数量
    --param4:里程碑奖励内容:shopID1,num1_shopID2,num2
    --14层
    local activityDataStr = "{\"WarriorActivityData\":{\"awards\":[\"1;0;0;10;1296,1_1290,5\",\"2;0;0;40;1299,1_1290,10\",\"3;0;0;70;1335,5_1336,5\",\"4;0;0;90;1725,10_1726,5\",\"5;0;0;120;1727,2_1728,1\",\"6;0;0;140;1723,2_1724,1\",\"7;0;0;140;1723,2_1724,1\",\"8;0;0;140;1723,2_1724,1\",\"9;0;0;140;1723,2_1724,1\",\"10;0;0;140;1723,2_1724,1\",\"11;0;0;140;1723,2_1724,1\",\"12;0;0;140;1723,2_1724,1\",\"13;0;0;140;1723,2_1724,1\",\"14;0;1;160;1130,1_1723,2_1724,1\"],\"clock_out_theme\":\"normal1\",\"open_conditions\":[{\"type\":10,\"value\":\"6\",\"compareType\":20}],\"instanceID\":214,\"activityType\":11,\"previewTime\":1742947200,\"startTime\":1742947200,\"settlementTime\":1743033600,\"endTime\":1743033600,\"icon\":\"icon1\",\"activityName\":\"下班打卡测试\",\"backgroundImg\":\"111\",\"tag\":\"\",\"content\":\"{seasonpass_theme=chineseyear, packContent=1481;40;0;1605,20_1714,30, level_20=100;3002,1;3002,3;3002,6;1, level_11=100;3002,1;3002,3;3002,6;0, level_10=100;3002,1;3002,3;3002,6;1, storeId=1479,1480, level_13=100;3002,1;3002,3;3002,6;0, level_12=100;3002,1;3002,3;3002,6;0, level_15=100;3002,1;3002,3;3002,6;1, level_14=100;3002,1;3002,3;3002,6;0, level_3=100;3002,1;3002,3;3002,6;0, level_17=100;3002,1;3002,3;3002,6;0, level_4=100;3002,1;3002,3;3002,6;0, level_16=100;3002,1;3002,3;3002,6;0, level_5=100;3002,1;3002,3;3002,6;1, level_19=100;3002,1;3002,3;3002,6;0, level_6=100;3002,1;3002,3;3002,6;0, level_18=100;3002,1;3002,3;3002,6;0, level_7=100;3002,1;3002,3;3002,6;0, level_8=100;3002,1;3002,3;3002,6;0, level_9=100;3002,1;3002,3;3002,6;0, seasonpass_type=tuibiji, level_1=100;3002,1;3002,3;3002,6;0, level_2=100;3002,1;3002,3;3002,6;0}\"}}"
    --7层的
    -- local activityDataStr = "{\"WarriorActivityData\":{\"awards\":[\"1;0;0;10;1296,1_1290,5\",\"4;0;0;90;1725,10_1726,5\",\"5;0;0;120;1727,2_1728,1\",\"6;0;0;140;1723,2_1724,1\",\"7;0;1;160;1130,1_1723,2_1724,1\",\"2;0;0;40;1299,1_1290,10\",\"3;0;0;70;1335,5_1336,5\"],\"clock_out_theme\":\"normal1\",\"open_conditions\":[{\"type\":10,\"value\":\"6\",\"compareType\":20}],\"instanceID\":214,\"activityType\":11,\"previewTime\":1742947200,\"startTime\":1742947200,\"settlementTime\":1743033600,\"endTime\":1743033600,\"icon\":\"icon1\",\"activityName\":\"下班打卡测试\",\"backgroundImg\":\"111\",\"tag\":\"\",\"content\":\"{seasonpass_theme=chineseyear, packContent=1481;40;0;1605,20_1714,30, level_20=100;3002,1;3002,3;3002,6;1, level_11=100;3002,1;3002,3;3002,6;0, level_10=100;3002,1;3002,3;3002,6;1, storeId=1479,1480, level_13=100;3002,1;3002,3;3002,6;0, level_12=100;3002,1;3002,3;3002,6;0, level_15=100;3002,1;3002,3;3002,6;1, level_14=100;3002,1;3002,3;3002,6;0, level_3=100;3002,1;3002,3;3002,6;0, level_17=100;3002,1;3002,3;3002,6;0, level_4=100;3002,1;3002,3;3002,6;0, level_16=100;3002,1;3002,3;3002,6;0, level_5=100;3002,1;3002,3;3002,6;1, level_19=100;3002,1;3002,3;3002,6;0, level_6=100;3002,1;3002,3;3002,6;0, level_18=100;3002,1;3002,3;3002,6;0, level_7=100;3002,1;3002,3;3002,6;0, level_8=100;3002,1;3002,3;3002,6;0, level_9=100;3002,1;3002,3;3002,6;0, seasonpass_type=tuibiji, level_1=100;3002,1;3002,3;3002,6;0, level_2=100;3002,1;3002,3;3002,6;0}\"}}"
    local data = Rapidjson.decode(activityDataStr)
    -- local warriorActivityData = data.WarriorActivityData
    --添加一个接口用于校验数据是否正确
    if not self:CheckRequestDataIsValidity(data.WarriorActivityData, true) then
        return
    end
    self:_InitWithWarriorActivityData(data.WarriorActivityData, true, duration)
    self:OpenClockOutActivity()
end

function ClockOutDataManager:ClockOutEnable()
    return self.m_ClockOutData and self.m_ClockOutData.m_ClockOutEnable and self:GetActivityLeftTime() > 0
end

function ClockOutDataManager:CheckRequestDataIsValidity(data, isGM)
    if not isGM then
        if not data.startTime or not data.endTime or not tonumber(data.startTime) or not tonumber(data.endTime) then
            --没有配置开始或者结束时间,或者开始时间或者结束时间格式错误
            GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "没有配置开始或者结束时间,或者开始时间或者结束时间格式错误"})
            return false
        end
    
        if tonumber(data.startTime) > tonumber(data.startTime) then
            --配置的开始时间大于结束时间了
            GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "配置的开始时间大于结束时间了"})
            return false
        end
    end
    
    --主题配置错误，使用默认主题
    if not self:CheckClockOutThemeIsValiable(data.clock_out_theme) then
        data.clock_out_theme = "normal1"
    end

    if not data.open_conditions or Tools:GetTableSize(data.open_conditions) <= 0 then
        --没有配置开启条件
        if GameTableDefine.StarMode.GetStar() < 3 then
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "没有配置开放条件且当前玩家星级小于3星"})
            end
            return false
        end
    end
    for index, condition in pairs(data.open_conditions) do
        if not condition.type or not condition.value or not condition.compareType then
            ---条件中的值有空的
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "开放条件配置错误,有空值"})
            end
            return false
        end
    end
    local rewardDatas, levelDatas = self:ParseClockOutRewardsConfig(data.awards)
    for i, level in ipairs(levelDatas) do
        if i ~= level then
            --里程碑奖励等级不连续
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "里程碑奖励等级不连续"})
            end
            return false
        end
        if not rewardDatas[level] then
            --对应等级里程碑数据配置错误
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "对应等级里程碑数据配置错误"})
            end
            return false
        end
        if rewardDatas[level].level ~= level then
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "对应等级里程碑数据配置错误"})
            end
            return false
        end
        if not rewardDatas[level].shopId then
            --里程碑奖励（免费或者付费）格式错误
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "里程碑奖励（免费或者付费）格式错误"})
            end
            return false
        end
        if rewardDatas[level].shopId > 0 and not GameTableDefine.Shop:GetShopItemPurchaseID(rewardDatas[level].shopId) then
            --付费节点的商品ID没有对应ipaid或者purchaseid
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "付费节点的商品ID没有对应ipaid或者purchaseid"})
            end
            return false
        end
        if not rewardDatas[level].rewardType or rewardDatas[level].rewardType > 1 then
            --是否为大奖的配置错误
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "是否为大奖的配置错误"})
            end
            return false
        end
        if not rewardDatas[level].needTickets or rewardDatas[level].needTickets <= 0 then
            --里程碑节点等级需求门票数异常
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "里程碑节点等级需求门票数异常"})
            end
            return false
        end

        if not rewardDatas[level].rewardsData or Tools:GetTableSize(rewardDatas[level].rewardsData) <= 0 then
            --里程碑节点奖励配置错误
            if not isGM then
                GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "里程碑节点奖励配置错误"})
            end
            return false
        end

        for _, itemReward in pairs(rewardDatas[level].rewardsData) do
            if not itemReward.shopId or not itemReward.num or itemReward.num <= 0 then
                --奖励的商品配置错误
                if not isGM then
                    GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "奖励的商品配置错误"})
                end
                return false
            end
            local shopCfg = ConfigMgr.config_shop[itemReward.shopId]
            if not shopCfg then
                --配置的奖励在商品表中找不到
                if not isGM then
                    GameSDKs:TrackForeign("activity_open", {name = "下班打卡", state = "开放失败", reason = "配置的奖励在商品表中找不到"})
                end
                return false
            end
        end
    end

    return true
end

function ClockOutDataManager:_InitWithWarriorActivityData(warriorActivityData, isGM, duration)
    if isGM then
        self.m_ClockOutData.start_time = GameTimeManager:GetCurrentServerTime(true)
        self.m_ClockOutData.end_time = self.m_ClockOutData.start_time + (duration * 60)
    else
        self.m_ClockOutData.start_time = tonumber(warriorActivityData.startTime)
        self.m_ClockOutData.end_time = tonumber(warriorActivityData.endTime)
    end
    local gmOptions = warriorActivityData.open_conditions
    
    self.m_ClockOutData.enterDay = nil
    self.m_ClockOutData.rewards_data = {} --需要根据运营配置数据初始化节点数据内容
    self.m_ClockOutData.m_clock_out_theme = warriorActivityData.clock_out_theme
    --当前需要的总门票数
    self.m_ClockOutData.m_configTotalTickets = 0
    local configTotalTickets = 0
    for _, rewardStr in ipairs(warriorActivityData.awards) do
        local rewardItemData = {}
        local arrayrewardStr = Tools:SplitString(rewardStr, ";")
        if Tools:GetTableSize(arrayrewardStr) >= 5 then
            local dataStrs1 = Tools:SplitString(arrayrewardStr[1], ",")
            rewardItemData.level = tonumber(arrayrewardStr[1])
            rewardItemData.shopId = tonumber(arrayrewardStr[2])
            rewardItemData.rewardType = tonumber(arrayrewardStr[3])
            rewardItemData.needTickets = tonumber(arrayrewardStr[4])
            configTotalTickets = configTotalTickets + rewardItemData.needTickets
            for _, rewardsStr in ipairs(Tools:SplitString(arrayrewardStr[5], "_")) do
                local rewardItemStrs = Tools:SplitString(rewardsStr, ",")
                local rewardItem = {}
                rewardItem.shopId = tonumber(rewardItemStrs[1])
                rewardItem.num = tonumber(rewardItemStrs[2])
                if not rewardItemData.rewardsData then
                    rewardItemData.rewardsData = {}
                end
                table.insert(rewardItemData.rewardsData, rewardItem)
            end
            rewardItemData.curTickets = 0
            rewardItemData.claimStatus = false
            rewardItemData.canClaimStatus = false
            -- if rewardItemData.level == Tools:GetTableSize(self.m_ClockOutData.rewards_data) + 1 then
            self.m_ClockOutData.rewards_data[rewardItemData.level] = rewardItemData
            -- end
        end
    end
    self.m_ClockOutData.m_configTotalTickets = configTotalTickets
    self.m_ClockOutData.m_openConditions = gmOptions
    self.m_ClockOutData.m_leftClockOutTickets = 0
    self.m_ClockOutData.m_ClockOutEnable = nil
    self.m_ClockOutData.isOpenedHelpTips = nil
    self.m_ClockOutData.HaveEnteredUI = nil
    self.m_ClockOutData.HaveConsumeTicket = nil
    self.m_ClockOutData.m_groupTag = warriorActivityData.tag or ""
    self.m_isActivityOpen = true
    local flag = 1
    if flag == 1 then
        print("Test update script is success")
    end
end

function ClockOutDataManager:GetAllRewardsData()
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return {}
    end
    return self.m_ClockOutData.rewards_data or {}

end

function ClockOutDataManager:GetActivityTheme()
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return "normal1"
    end
    
    return self.m_ClockOutData.m_clock_out_theme or "normal1"
end

--[[
    @desc: 当前有可以领取或者购买的奖励等级，0就是没有
    author:{author}
    time:2025-03-31 16:30:10
    @return:
]]
function ClockOutDataManager:GetHaveCanClaimReward()
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return 0
    end

    for level, rewardData in pairs(self.m_ClockOutData.rewards_data or {}) do
        if rewardData.canClaimStatus and not rewardData.claimStatus then
            return level
        end
    end
    return 0
end

function ClockOutDataManager:CheckHaveTicketLevelUp()
    if not self:GetActivityIsOpen() or not self.m_ClockOutData or not self.m_ClockOutData.rewards_data then
        return false
    end

    local levelData = {}
    for level, data in pairs(self.m_ClockOutData.rewards_data) do
        table.insert(levelData, level)
    end
    table.sort(levelData)

    for _, level in ipairs(levelData) do
        local data = self.m_ClockOutData.rewards_data[level]
        if data and not data.canClaimStatus then
            if self.m_ClockOutData.m_leftClockOutTickets + data.curTickets >= data.needTickets then
                return true
            end
        end
    end
    return false
end

function ClockOutDataManager:GetLeftTickets()
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return 0
    end

    return self.m_ClockOutData.m_leftClockOutTickets or 0
end

function ClockOutDataManager:CheckCanClaimedReward(level)
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return false
    end
    if not self.m_ClockOutData.rewards_data[level] then
        return false
    end

    if level ~= self:GetHaveCanClaimReward() then
        return false
    end

    if self.m_ClockOutData.rewards_data[level] then
        return not self.m_ClockOutData.rewards_data[level].claimStatus --没有被领取
    end
    return true
end

function ClockOutDataManager:GetCurOpertionData()
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return 0, {}
    end

    local resultLevel = 1
    local resultData = {}
    for level = 1, Tools:GetTableSize(self.m_ClockOutData.rewards_data) do
        if self.m_ClockOutData.rewards_data[level] then
            if not self.m_ClockOutData.rewards_data[level].canClaimStatus then
                resultLevel = level
                resultData = self.m_ClockOutData.rewards_data[level]
                break
            end
        end
    end

    if resultLevel == 1 and Tools:GetTableSize(resultData) == 0 then
        resultLevel = Tools:GetTableSize(self.m_ClockOutData.rewards_data)
        resultData = self.m_ClockOutData.rewards_data[resultLevel]
    end
    local isMax = false
    if resultData.canClaimStatus then
        isMax = true
    end
    return resultLevel, resultData, isMax
end

function ClockOutDataManager:ClaimClockOutReward(level)
    if not self.m_ClockOutData or not self:GetActivityIsOpen() then
        return 0, {}
    end
    if not self.m_ClockOutData.rewards_data[level] then
        return false
    end
    --没有达到领取要求（门票没有填充）或者已经领取过了
    if not self.m_ClockOutData.rewards_data[level].canClaimStatus or self.m_ClockOutData.rewards_data[level].claimStatus then
        return false
    end

    --如果不是1级的话看看上一级是否已经领取过了
    if level > 1 then
        local beforeLvl = level - 1
        if not self.m_ClockOutData.rewards_data[beforeLvl] or not self.m_ClockOutData.rewards_data[beforeLvl].claimStatus then
            return false
        end
    end
    self.m_ClockOutData.rewards_data[level].claimStatus = true
    --实际给奖励了
    local lastRewards = {}
    local isHaveCEOBox = false
    for _, rewardItem in pairs(self.m_ClockOutData.rewards_data[level].rewardsData) do
        local shopCfg = ConfigMgr.config_shop[rewardItem.shopId]
        if shopCfg and shopCfg.type == 42 then
            isHaveCEOBox = true
        end
        if not lastRewards[rewardItem.shopId] then
            lastRewards[rewardItem.shopId] = rewardItem.num
        else
            lastRewards[rewardItem.shopId]  = lastRewards[rewardItem.shopId] + rewardItem.num
        end
    end

    GameTableDefine.ShopManager:BuyByGiftCode(lastRewards, function(realRewardDatas)
        --realRewardDatas = {{icon1, num1}, {icon2, num2}}
        --这里显示UI奖励内容
        if not isHaveCEOBox then
            GameTableDefine.CycleInstanceRewardUI:ShowGiftCodeGetRewards(realRewardDatas, true)
        else
            self.needCEOWaitDisplay = true
            self.displayRewardDatas = realRewardDatas
        end
    end, false, false, nil, 5)
    GameSDKs:TrackForeign("clockout_reward", {level = level})
    return true
end

function ClockOutDataManager:GetEnterDay()
    if self.m_ClockOutData and self.m_ClockOutData.enterDay then
        return self.m_ClockOutData.enterDay
    end
    return nil
end

function ClockOutDataManager:SetEnterDay()
    if not self:GetActivityIsOpen() then
        return
    end
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    self.m_ClockOutData.enterDay = day
end

function ClockOutDataManager:UICloseEventProcess()
    if self.waitAnimTickets and self.waitAnimTickets > 0 then
        GameTableDefine.FlyIconsUI:ShowClockOutTicketsGetAnim(self.waitAnimTickets, function()
            self.waitAnimTickets = 0
         end)
    end
end 

function ClockOutDataManager:GetClockOutChargeShoIDByPurchaseID(purchaseId)
    if not self:GetActivityIsOpen() then
        return nil
    end
    if self.m_ClockOutData.rewards_data then
        for level, itemReward in pairs(self:GetAllRewardsData()) do
            if itemReward.shopId > 0 then
                local configPurchaseId = GameTableDefine.Shop:GetShopItemPurchaseID(itemReward.shopId)
                if configPurchaseId == purchaseId then
                    return GameTableDefine.Shop:GetShopItemIDByPurchaseID(purchaseId)
                end
            end
        end
    end
    return nil
end

function ClockOutDataManager:GetClockOutChargeShopID(shopId)
    if not self:GetActivityIsOpen() then
        return nil
    end
    if self.m_ClockOutData.rewards_data then
        for level, itemReward in pairs(self:GetAllRewardsData()) do
            if itemReward.shopId > 0 and itemReward.shopId == shopId then
                return shopId
            end
        end
    end
    return nil
end

function ClockOutDataManager:GetClockOutRewardLevelByShopId(shopId)
    if not self:GetActivityIsOpen() then
        return 0
    end
    if self.m_ClockOutData.rewards_data then
        for level, itemReward in pairs(self:GetAllRewardsData()) do
            if itemReward.shopId > 0 and shopId == itemReward.shopId then
                return level
            end
        end
    end
    return 0
end

function ClockOutDataManager:BuyClockOutIAPResult(shopId, success)
    if success and shopId then
        local level = self:GetClockOutRewardLevelByShopId(shopId)
        if level and level > 0 then
            local result = self:ClaimClockOutReward(level)
            if result and GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CLOCK_OUT_UI) then
                GameTableDefine.ClockOutUI:NextLevelBtnUnlock(level) 
            end
        end
    end

    if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CLOCK_OUT_UI) then
        GameTableDefine.ClockOutUI:BuyClockOutIAPResult(shopId, success)
    end
end

function ClockOutDataManager:CheckClockOutThemeIsValiable(theme)
    local configTheme = {"normal1", "normal2", "halloween", "thanksgiving", "newyear", "chineseyear", "easter"}
    for _, cfgTheme in pairs(configTheme) do
        if theme == cfgTheme then
            return true
        end
    end
    return false
end

function ClockOutDataManager:ParseClockOutRewardsConfig(rewardsData)
    local resultData = {}
    local levelsData = {}
    for _, rewardStr in ipairs(rewardsData) do
        local rewardItemData = {}
        local arrayrewardStr = Tools:SplitString(rewardStr, ";")
        if Tools:GetTableSize(arrayrewardStr) >= 5 then
            rewardItemData.level = tonumber(arrayrewardStr[1]) or 0
            table.insert(levelsData, tonumber(arrayrewardStr[1]))
            rewardItemData.shopId = tonumber(arrayrewardStr[2])
            rewardItemData.rewardType = tonumber(arrayrewardStr[3])
            rewardItemData.needTickets = tonumber(arrayrewardStr[4])
            for _, rewardsStr in ipairs(Tools:SplitString(arrayrewardStr[5], "_")) do
                local rewardItemStrs = Tools:SplitString(rewardsStr, ",")
                local rewardItem = {}
                rewardItem.shopId = tonumber(rewardItemStrs[1])
                rewardItem.num = tonumber(rewardItemStrs[2])
                if not rewardItemData.rewardsData then
                    rewardItemData.rewardsData = {}
                end
                table.insert(rewardItemData.rewardsData, rewardItem)
            end
            resultData[rewardItemData.level] = rewardItemData
        end
    end
    if Tools:GetTableSize(levelsData) > 0 then
        table.sort(levelsData)
    end
    return resultData, levelsData
end

function ClockOutDataManager:IsPlayHelpTipsAnimation()
    if not self:GetActivityIsOpen() then
        return true
    end
    if not self.m_ClockOutData then
        return true
    end

    return self.m_ClockOutData.isOpenedHelpTips
end

function ClockOutDataManager:OpenClockOutHelpTips()
    if not self:GetActivityIsOpen() then
        return
    end

    if not self.m_ClockOutData then
        return
    end

    if not self.m_ClockOutData.isOpenedHelpTips then
        self.m_ClockOutData.isOpenedHelpTips = true
    end
end

function ClockOutDataManager:IsFirstEnterClockOutFlag()
    if not self.m_ClockOutData or not self.m_ClockOutData.HaveEnteredUI then
        if not self.m_ClockOutData.HaveEnteredUI then
            self.m_ClockOutData.HaveEnteredUI = true
        end
        return true
    end
    
    return not self.m_ClockOutData.HaveEnteredUI
end

function ClockOutDataManager:IsFirstConsumeTickets()
    if not self.m_ClockOutData or not self.m_ClockOutData.HaveConsumeTicket then
        if not self.m_ClockOutData.HaveConsumeTicket then
            self.m_ClockOutData.HaveConsumeTicket = true
        end
        return true
    end
    
    return not self.m_ClockOutData.HaveConsumeTicket
end

function ClockOutDataManager:GetConfigTotalTickets()
    if not self:GetActivityIsOpen() then
        return 0
    end
    if not self.m_ClockOutData or not self.m_ClockOutData.m_configTotalTickets then
        return 0
    end

    return self.m_ClockOutData.m_configTotalTickets
end

function ClockOutDataManager:GetClockOutGroup()
    if not self.m_ClockOutData or not self.m_ClockOutData.m_groupTag then
        return ""
    end
    return self.m_ClockOutData.m_groupTag
end