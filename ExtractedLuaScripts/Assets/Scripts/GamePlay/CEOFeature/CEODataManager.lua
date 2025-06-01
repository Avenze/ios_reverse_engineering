--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-02-06 15:08:37
]]

---@class CEODataManager
local CEODataManager = GameTableDefine.CEODataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local EventDispatcher = EventDispatcher
local FlyIconsUI = GameTableDefine.FlyIconsUI
local StarMode = GameTableDefine.StarMode
local EventManager = require("Framework.Event.Manager")
local CountryMode = GameTableDefine.CountryMode

CEODataManager.CEOEffectType = {
    Income = "income",
    Exp = "exp"
}

CEODataManager.CEORankType = {
    Normal = "normal",
    Premium = "premium"
}

CEODataManager.CEOBuffIcon = {
    ["exp"] = "icon_enhanceEXP",
    ["income"] = "icon_enhanceMoney",
}

CEODataManager.PopTalkType = {
    ---CEO家具等级不足
    CEOFurLevelNotEnough = 1,
    ---公司满级
    CompanyLevelMax = 2,
    ---公司设施需求不满足
    CompanyDissatisfied = 3,
    ---全都满足
    Satisfied = 4
}

CEODataManager.Mood = {
    Bad = 1,
    Good = 3
}

function CEODataManager:CheckCEOOpenCondition()
    return GameTableDefine.CityMode:CheckBuildingSatisfy(200)
    -- return false
end

function CEODataManager:CheckInit()
    self:Init()
    return self.isInit
end

function CEODataManager:Init()
    if not self:CheckCEOOpenCondition() then
        return
    end
    if self.isInit then
        return
    end
    if not self.CEOData then
        self.CEOData = LocalDataManager:GetDataByKey("CEO_Data")
    end
    if not self.CEOData.curCEOCharDic then
        self.CEOData.curCEOCharDic = {}
        --TODO:初始化会给一个CEO
        local addCEOID = 1
        local ceoDataItem = {}
        ceoDataItem.Level = 1
        ceoDataItem.Exp = 0
        ceoDataItem.totalCostNum = 1
        self.CEOData.curCEOCharDic[tostring(addCEOID)] = ceoDataItem

    end
    if not self.CEOData.curKeys then
        self.CEOData.curKeys = {}
        --TODO:初始化给10把钥匙
        local initNormalKey = 0
        local initPremiumKey = 0
        self.CEOData.curKeys["normal"] = initNormalKey
        self.CEOData.curKeys["premium"] = initPremiumKey
        self.CEOData.curKeys["total_normal"] = initNormalKey
        self.CEOData.curKeys["total_premium"] = initNormalKey
    end

    if not self.CEOData.curFreeBoxCD then
        --免费宝箱的开启CD时间
        self.CEOData.curFreeBoxCD = 0
    end

    if not self.CEOData.curCEOCardsDic  then
        --拥有的ceo卡片数量
        self.CEOData.curCEOCardsDic = {}
    end
    
    --当前ceo设置到对应的房间数据
    if not self.CEOData.curCEORoomsData then
        self.CEOData.curCEORoomsData = {}
        --元素格式:ID-roomIndex(string)
    else
        --检测异常的房间CEO数据并进行修正
        local coutry1RoomDatas = LocalDataManager:GetDataByKey(CountryMode:GetCountryRooms(1))
        local coutry2RoomDatas = LocalDataManager:GetDataByKey(CountryMode:GetCountryRooms(2))
        for ceoIDKey, data in pairs(self.CEOData.curCEORoomsData) do
            local ceoID = tonumber(ceoIDKey)
            if not data.countryId then
                local roomData1 = coutry1RoomDatas[data.roomIndex]
                local roomData2 = coutry2RoomDatas[data.roomIndex]
                if roomData1 and roomData2 then
                    local isSameCEO = false
                    if roomData1.ceoFurnitureInfo and roomData1.ceoFurnitureInfo.ceoID and roomData1.ceoFurnitureInfo.ceoID == ceoID then
                        data.countryId = 1
                    end
                    if roomData2.ceoFurnitureInfo and roomData2.ceoFurnitureInfo.ceoID and roomData2.ceoFurnitureInfo.ceoID == ceoID then
                        if data.countryId then
                            roomData2.ceoFurnitureInfo.ceoID = nil
                        else
                            data.countryId = 2
                        end
                    end 
                elseif roomData1 then
                    if roomData1.ceoFurnitureInfo and roomData1.ceoFurnitureInfo.ceoID and roomData1.ceoFurnitureInfo.ceoID == ceoID then
                        data.countryId = 1
                    end
                elseif roomData2 then
                    if roomData2.ceoFurnitureInfo and roomData2.ceoFurnitureInfo.ceoID and roomData2.ceoFurnitureInfo.ceoID == ceoID then
                        data.countryId = 2
                    end
                end
            end
        end
        --修正有重复CEO的bug
        local rooms1CEOData = {}
        local rooms2CEOData = {}
        local reuseCEOIDs  = {}
        local reuseCEORoomIndexs = {}
        local resueCEOCountryIds = {}
        for roomIndex, roomData in pairs(coutry2RoomDatas) do
            if roomData.ceoFurnitureInfo and roomData.ceoFurnitureInfo.ceoID then
                local isInReuse = false
                for _, ceoid in ipairs(reuseCEOIDs) do
                    if ceoid == roomData.ceoFurnitureInfo.ceoID then
                        isInReuse = true
                    end
                end
                if isInReuse then
                    roomData.ceoFurnitureInfo = nil
                else
                    table.insert(reuseCEOIDs, roomData.ceoFurnitureInfo.ceoID)
                    table.insert(reuseCEORoomIndexs, roomIndex)
                    table.insert(resueCEOCountryIds, 2)
                end
            end
        end

        for roomIndex, roomData in pairs(coutry1RoomDatas) do
            if roomData.ceoFurnitureInfo and roomData.ceoFurnitureInfo.ceoID then
                local isInReuse = false
                for _, ceoid in ipairs(reuseCEOIDs) do
                    if ceoid == roomData.ceoFurnitureInfo.ceoID then
                        isInReuse = true
                    end
                end
                if isInReuse then
                    roomData.ceoFurnitureInfo = nil
                else
                    table.insert(reuseCEOIDs, roomData.ceoFurnitureInfo.ceoID)
                    table.insert(reuseCEORoomIndexs, roomIndex)
                    table.insert(resueCEOCountryIds, 1)
                end
            end
        end

        for index, ceoid in ipairs(reuseCEOIDs) do
            local ceoKey = tostring(ceoid)
            if not self.CEOData.curCEORoomsData[ceoKey] then
                self.CEOData.curCEORoomsData[ceoKey] = {}
                self.CEOData.curCEORoomsData[ceoKey].roomIndex = reuseCEORoomIndexs[index]
                self.CEOData.curCEORoomsData[ceoKey].countryId = resueCEOCountryIds[index]
            end
        end
    end

    ---钻石消耗转金钥匙存量
    if not self.CEOData.DiamondConsume then
        self.CEOData.DiamondConsume = 0
    end
    
    --每日免费宝箱的次数
    if not self.CEOData.dayLeftFreeTimes then
        local cfgFreeTimes = tonumber(ConfigMgr.config_global.ceochest_free_limit)
        self.CEOData.dayLeftFreeTimes = cfgFreeTimes
    end

    if self.refreshTimer then
        GameTimer:StopTimer(self.refreshTimer)
    end
    self.refreshTimer = GameTimer:CreateNewTimer(1, function()
        self:RefreshDayFreeOpenTimes()
    end, true, true)

    self:UpdateCEODataToThinking()
    self.isInit = true
    
end

--[[
    @desc: 检测对应开箱子需要的钥匙数量是否足够
    author:{author}
    time:2025-02-06 15:43:40
    --@boxType:"normal"-普通, "premium"-高级
	--@boxNum: 
    @return:
]]
function CEODataManager:CheckKeysEnoughByBox(boxType, boxNum)
    local enough = false
    if not self:CheckInit() then
        return
    end
    local leftKeys = -1
    if "normal" == boxType then
        leftKeys = self.CEOData.curKeys["normal"] - (boxNum * 10) 
    end
    if "premium" == boxType then
        leftKeys = self.CEOData.curKeys["premium"] - (boxNum * 10)
    end
    return leftKeys >= 0
end

--[[
    @desc: 获取当前钥匙的数量
    author:{author}
    time:2025-02-06 15:44:31
    --@keyType: "normal"-银钥匙, "premium"-金钥匙
    @return:
]]
function CEODataManager:GetCurKeys(keyType)
    if not self:CheckInit() then
        return 0
    end
    return self.CEOData.curKeys[keyType] or 0
end

--[[
    @desc: 获取每日的免费开宝箱剩余次数
    author:{author}
    time:2025-02-18 10:58:50
    @return:
]]
function CEODataManager:GetDayFreeLeftTimes()
    if not self:CheckInit() then
        return 0
    end
    return self.CEOData.dayLeftFreeTimes or 0
end

--[[
    @desc: 
    author:{author}
    time:2025-02-07 11:42:46
    --@boxType:"free", "normal", "premium"
	--@cb: 
    --@openSouce:1-GM工具直接开箱，2-单个里程碑开箱,3-兑换码开箱,4-商城钥匙开箱
    @return:
]]
function CEODataManager:OpenCEOBox(boxType, num, isNeedKey, cb, openSource)
    if not self:CheckInit() then
        return false
    end
    local keyRequireStrs = ConfigMgr.config_ceo_chest[boxType].chest_key_require
    local needKeyCfg = 0
    if "normal" == boxType or "premium" == boxType then
        local tmpStrs = Tools:SplitString(keyRequireStrs, ":")
        needKeyCfg = tonumber(tmpStrs[2])
    end
    if boxType == "free" then
        if self:GetFreeBoxCDTime() <= 0 and self.CEOData.dayLeftFreeTimes > 0 then
            local cfgFreeTimes = tonumber(ConfigMgr.config_global.ceochest_free_limit)
            if not self.CEOData.freeRefreshDayTime or self.CEOData.freeRefreshDayTime == 0 then
                self.CEOData.freeRefreshDayTime = GameTimeManager:GetCurrentServerTime(true)    
            end
            local rewards = {}
            rewards[1] = self:GetBoxRewards(boxType, 1)
            self:GetRealBoxRewards(rewards, boxType, openSource)
            self.CEOData.dayLeftFreeTimes  = self.CEOData.dayLeftFreeTimes - 1
            self.CEOData.curFreeBoxCD = GameTimeManager:GetCurrentServerTime(true)
            if self.CEOData.dayLeftFreeTimes <= 0 then
                self.CEOData.dayLeftFreeTimes = 0
                self.CEOData.curFreeBoxCD = 0
            end
            if cb then
                cb(true)
            end
        else
            if cb then
                cb(false)
            end
            return false
        end
    elseif "normal" == boxType then
        local needKeys = needKeyCfg * num
        if isNeedKey then
            if not self.CEOData.curKeys or not self.CEOData.curKeys.normal or self.CEOData.curKeys.normal < needKeys then
                if cb then
                    cb(false)
                end
                return false
            end
        end
        local rewards = {}
        for i = 1, num do
            local reward = self:GetBoxRewards(boxType, i)
            rewards[i] = reward
        end
        if isNeedKey then
            self.CEOData.curKeys.normal  = self.CEOData.curKeys.normal - needKeys
        end
        self:GetRealBoxRewards(rewards, boxType, openSource)
        if cb then
            cb(true)
        end
    elseif "premium" == boxType then
        local needKeys = needKeyCfg * num
        if isNeedKey then
            if not self.CEOData.curKeys or not self.CEOData.curKeys.premium or self.CEOData.curKeys.premium < needKeys then
                if cb then
                    cb(false)
                end
                return false
            end
        end
        local rewards = {}
        for i = 1, num do
            local reward = self:GetBoxRewards(boxType, i)
            rewards[i] = reward
        end
        if isNeedKey then
            self.CEOData.curKeys.premium  = self.CEOData.curKeys.premium - needKeys
        end
        self:GetRealBoxRewards(rewards, boxType, openSource)
        if cb then
            cb(true)
        end
    end
    local sourceDesc = "GM工具直接开箱"
    if openSource > 1 then
        if openSource == 2 then
            sourceDesc = "单个里程碑开箱子"
        elseif openSource == 3 then
            sourceDesc = "兑换码开箱"
        elseif openSource == 4 then
            sourceDesc = "商城钥匙开箱"
        end
    end
    GameSDKs:TrackForeign("ceo_chest_change", {type = boxType, num = tonumber(num), source = sourceDesc})
    return true
end

--[[
    @desc: 获取奖励内容
    author:{author}
    time:2025-02-07 11:10:15
    --@boxType: "free", "normal", "premium"
    @return:
]]
function CEODataManager:GetBoxRewards(boxType, index)
    local rewards = {}
    local curBoxCfg = ConfigMgr.config_ceo_chest[boxType]
    if not curBoxCfg then
        return rewards
    end
    local rewardCfgStrs = Tools:SplitString(curBoxCfg.chest_content, ",")
    for _, rewardItemStr in pairs(rewardCfgStrs) do
        local eleRewardStr = Tools:SplitString(rewardItemStr, ":")
        if not rewards[tonumber(eleRewardStr[1])] then
            rewards[tonumber(eleRewardStr[1])] = {}
        end
        if not rewards[tonumber(eleRewardStr[1])].num then
            rewards[tonumber(eleRewardStr[1])].num = tonumber(eleRewardStr[2])
        else
            rewards[tonumber(eleRewardStr[1])].num  = rewards[tonumber(eleRewardStr[1])].num + tonumber(eleRewardStr[2])
        end
    end
    --需要解析对应的卡牌转ceoid的数据
    local delID = {}
    for shopID, items in pairs(rewards) do
        local shopCfg = ConfigMgr.config_shop[shopID]
        if not shopCfg then
            table.insert(delID, shopID)
        else
            if shopCfg.type == 44 then
                items.extendData = {}
                for i = 1,items.num do
                    local ceoid = self:GetCEOCardReward(shopCfg.param[1])
                    table.insert(items.extendData, ceoid)
                end
            end
        end
    end
    if "free" == boxType then 
    elseif "normal" == boxType then
    elseif "premium" == boxType then
    end
    return rewards
end

--[[
    @desc: 根据CEO的卡片类型获取对应的CEO类型的卡
    author:{author}
    time:2025-02-08 14:41:32
    --@cardType: "normal", "premium"
    @return:ceoid
]]
function CEODataManager:GetCEOCardReward(cardType)
    local result = 0
    local cfgCeoIDList = {}
    local id = 0
    if "normal" == cardType then
        id = 1
    elseif "premium" == cardType then
        id = 2
    end
    local cardsStrs = Tools:SplitString(ConfigMgr.config_ceo_card[id].card_content, ",")
    for _, itemStr in pairs(cardsStrs) do
        if tonumber(itemStr) and (self:GetCEOCharStatusByCEOID(tonumber(itemStr)) == 1 or self:GetCEOCharStatusByCEOID(tonumber(itemStr)) == 2) then
            table.insert(cfgCeoIDList, tonumber(itemStr))
        end
    end
    local randomIndex = math.random(1, Tools:GetTableSize(cfgCeoIDList))
    
    --卡池概率计算
    -- - $$单卡概率=100_{百分比}*单卡权重/总权重$$
    -- - $$单卡权重=基础权重/[（卡牌数量+1）*数量系数]$$
    -- - $$总权重=\varSigma_{单卡权重}$$
    -- - 卡牌数量=当前等级ceo消耗的卡牌数（即当前等级ceo升级到该等级总共消耗了多少张卡牌）+拥有ceo卡牌数（如果ceo满级了，拥有卡牌数=0，因为被自动转化为钻石了）
    --放大1000倍进行计算
    local basePersent = math.floor((1/Tools:GetTableSize(cfgCeoIDList)) * 1000)
    local realPercentList = {}
    local calParam = 1
    local newTotalPercent = 1
    for index, ceoid in ipairs(cfgCeoIDList) do
        local currentCards = self:GetCurCEOCardsNum(ceoid)
        local costCards = self:GetCEOTotalCost(ceoid)
        local realPercent = math.floor(basePersent / (currentCards + costCards + 1) * calParam)
        realPercentList[index] = {}
        realPercentList[index].min = newTotalPercent
        realPercentList[index].max = newTotalPercent + realPercent
        newTotalPercent  = newTotalPercent + realPercent
    end
    local newRandomValue = math.random(1, newTotalPercent)
    for index, percentItem in pairs(realPercentList) do
        if newRandomValue >= percentItem.min and newRandomValue < percentItem.max then
            randomIndex = index
            break
        end
    end

    result = cfgCeoIDList[randomIndex]
    return result
end

function CEODataManager:GetFreeBoxCDTime()
    if not self:CheckInit() then
        return 0
    end
    if not self.CEOData.curFreeBoxCD or self.CEOData.curFreeBoxCD == 0 or self.CEOData.dayLeftFreeTimes <= 0 then
        return 0
    end
    local offsetTime = GameTimeManager:GetCurrentServerTime(true) - self.CEOData.curFreeBoxCD
    local configCDTime = ConfigMgr.config_ceo_chest["free"].chest_cooltime * 60
    local curCDTime = configCDTime - offsetTime
    if curCDTime > 0 then
        return curCDTime
    else
        return 0
    end
end

function CEODataManager:GetDayRefreshTimeLeft()
    if not self:CheckInit() then
        return 0
    end
    if not self.CEOData.freeRefreshDayTime or self.CEOData.freeRefreshDayTime == 0 or self.CEOData.dayLeftFreeTimes > 0 then
        return 0
    end
    local curTimeLeft = GameTimeManager:SecondsUntilTomorrow(GameTimeManager:GetCurrentServerTime(true))
    return curTimeLeft
end

--[[
    @desc: 
    author:{author}
    time:2025-02-07 12:00:21
    --@diamond: 
    @return:
]]
function CEODataManager:SpendDiamondCount(diamond)
    if not self:CheckInit() then
        return
    end
    self.curDiamondAddKeys = 0
    local oldDiamondConsume = self.CEOData.DiamondConsume
    self.CEOData.DiamondConsume  = self.CEOData.DiamondConsume + diamond
    local keyDiamond = ConfigMgr.config_global.diamond_key_ratio[1]
    local keyAdds = ConfigMgr.config_global.diamond_key_ratio[2]
    local addKey = math.floor(self.CEOData.DiamondConsume / keyDiamond) * keyAdds
    if addKey > 0 then
        self.curDiamondAddKeys = addKey
        self.CEOData.DiamondConsume  = self.CEOData.DiamondConsume - (addKey * keyDiamond)
        GameSDKs:TrackForeign("ceo_key_change", {type = "premium", source = "钻石消耗", num = tonumber(addKey)}) 
        self:AddCEOKey("premium", addKey, true)
    end
    FlyIconsUI:ShowCEOSpendDiamondAnim(diamond, oldDiamondConsume, addKey, function(callkey)
        if self.curDiamondAddKeys > 0 then
            FlyIconsUI:ShowCEOAddKeyAnim("premium", self.curDiamondAddKeys, true, nil, nil)
            self.curDiamondAddKeys = 0
        end
    end)
end

--[[
    @desc: 添加CEO钥匙
    author:{author}
    time:2025-02-08 12:00:15
    --@keyType:"normal"普通钥匙, "premium"高级钥匙
	--@num: 
    --@haveFly:已经播放过飞钥匙的动画了，不用再播放了
    @return:
]]
function CEODataManager:AddCEOKey(keyType, num, haveFly)
    if not self:CheckInit() then
        return
    end
    if "premium" == keyType then
        if not self.CEOData.curKeys["total_premium"] then
            self.CEOData.curKeys["total_premium"] = self.CEOData.curKeys.premium
        end
        self.CEOData.curKeys.premium  = self.CEOData.curKeys.premium + num
        self.CEOData.curKeys["total_premium"] = self.CEOData.curKeys["total_premium"] + num
    end
    if "normal" == keyType then
        if not self.CEOData.curKeys["total_normal"] then
            self.CEOData.curKeys["total_normal"] = self.CEOData.curKeys.normal
        end
        self.CEOData.curKeys.normal = self.CEOData.curKeys.normal + num
        self.CEOData.curKeys["total_normal"]  = self.CEOData.curKeys["total_normal"] + num
    end
    if not haveFly then
        FlyIconsUI:ShowCEOAddKeyAnim(keyType, num, false, nil, nil)
    end
end

--[[
    @desc: 添加一个对应类型的随机卡片
    author:{author}
    time:2025-02-10 10:19:28
    --@cardType: "normal"-普通卡牌, "premium"--豪华卡牌
    @return:
]]
function CEODataManager:AddCEORandomCard(cardType)
    if not self:CheckInit() then
        return
    end
end

--[[
    @desc: 添加指定类型的CEO卡牌
    author:{author}
    time:2025-02-10 10:20:53
    --@cardIDType: 
    @return:
]]
function CEODataManager:AddCEOSpecificCard(cardIDType)
    if not self:CheckInit() then
        return
    end
    self:GetCEOCardByCEOID(cardIDType)
end

--[[
    @desc: 解雇一个CEO 
    author:{author}
    time:2025-02-10 10:27:58
    --@ceoID: ceo类型ID
    --@cb:cb(error_code)0-成功，1-英雄没有在雇佣中, 2-没有这个英雄
    @return:
]]
function CEODataManager:FireCEO(ceoID, cb)
    if not self:CheckInit() then
        return
    end
    for ceoIdStr, roomID in pairs(self.CEOData.curCEORoomsData) do
        if tonumber(ceoIdStr) == ceoID then
            self.CEOData.curCEORoomsData[tostring(ceoID)] = nil
            if cb then
                cb(0)
            end
            return
        end
    end
    local haveCharID = 0
    for ceoIdStr, ceoItem in pairs(self.CEOData.curCEOCharDic) do
        if ceoID == tonumber(ceoIdStr) then
            haveCharID = ceoID
            break
        end 
    end 
    if haveCharID <= 0 then
        if cb then
            cb(2)
        end
        return 
    end
    
    if cb then
        cb(1)
    end
end


--[[
    @desc: 雇佣一个CEO到一个房间
    author:{author}
    time:2025-02-10 10:28:11
    --@ceoID:CEO类型ID
	--@roomID: 房间ID
    --@cb:cb(error_code):0-安排成功,1-已经安排在其他房间了，2-没有这个英雄
    @return:
]]
function CEODataManager:HireCEO(ceoID, roomIndex, countryId, cb)
    if not self:CheckInit() then
        return
    end
    for ceoIdStr, roomData in pairs(self.CEOData.curCEORoomsData) do
        local roomCEOID = tonumber(ceoIdStr)
    
        if roomCEOID == ceoID then
            if cb then
                cb(1)
            end
            return
        end
    end
    local haveCharID = 0
    for ceoIdStr, ceoItem in pairs(self.CEOData.curCEOCharDic) do
        if ceoID == tonumber(ceoIdStr) then
            haveCharID = ceoID
            break
        end 
    end
    if haveCharID <= 0 then
        if cb then
            cb(2)
        end
        return 
    end
    if not self.CEOData.curCEORoomsData[tostring(ceoID)] then
        self.CEOData.curCEORoomsData[tostring(ceoID)] = {}
    end
    self.CEOData.curCEORoomsData[tostring(ceoID)].roomIndex = roomIndex
    self.CEOData.curCEORoomsData[tostring(ceoID)].countryId = countryId
    if cb then
        cb(0)
    end
end

--[[
    @desc: 返回对应CEO类型ID对应的房间ID
    author:{author}
    time:2025-02-10 11:00:45
    --@ceoID:对应的CEOID 
    @return:对应的房间ID，如果是0则没有绑定房间
]]
function CEODataManager:GetCEOSpecificRoomIndexByCEOID(ceoID)
    if not self:CheckInit() then
        return "", 0
    end

    if not self.CEOData.curCEORoomsData[tostring(ceoID)] then
        return "", 0
    end
    local roomIndex = self.CEOData.curCEORoomsData[tostring(ceoID)].roomIndex or ""
    local countryId  = self.CEOData.curCEORoomsData[tostring(ceoID)].countryId or 1
    return roomIndex, countryId
end

--[[
    @desc: 获取当前CEO角色对应的房间信息
    author:{author}
    time:2025-02-10 11:19:34
    @return:{}-key:CharacterID, value-roomID
]]
function CEODataManager:GetAllCEORoomInfoData()
    if not self:CheckInit() then
        return {}
    end
    return self.CEOData.curCEORoomsData
end


function CEODataManager:GetAllCEOCharaInfoData()
    if not self:CheckInit() then
        return {}
    end
    return self.CEOData.curCEOCharDic
end

--[[
    @desc: 获取对应的CharID对应的配置数据
    author:{author}
    time:2025-02-10 11:23:57
    --@charID: 
    @return:nil配置没有对应的配置数据
]]
function CEODataManager:GetCEOCharCfgByCharID(ceoid, level)
    if not ConfigMgr.config_ceo_level[ceoid] or not ConfigMgr.config_ceo_level[ceoid][level] then
        return nil
    end
    return ConfigMgr.config_ceo_level[ceoid][level]
end

---@return number 返回对应CEO当前等级
function CEODataManager:GetCEOLevel(ceoID)
    if not self:CheckInit() then
        return 0
    end
    local kID = tostring(ceoID)
    local ceoData = self.CEOData.curCEOCharDic[kID]
    return ceoData and ceoData.Level or 0
end

function CEODataManager:GetCEOCharData(ceoid)
    if not self:CheckInit() then
        return nil
    end
    local ceoKey = tostring(ceoid)
    return self.CEOData.curCEOCharDic[ceoKey] or nil
end


function CEODataManager:GetCEOTotalCost(ceoid)
    if not self:CheckInit() then
        return 0
    end
    local ceoKey = tostring(ceoid)
    if not self.CEOData.curCEOCharDic[ceoKey] then
        return 0
    end
    return self.CEOData.curCEOCharDic[ceoKey].totalCostNum or 0
end
--[[
    @desc: 根据CEOID获取当前CEO角色对应的状态
    author:{author}
    time:2025-02-10 14:30:19
    --@ceoID: ceoID-CEO的类型ID，对应表config_ceo
    @return:--状态值:0-CEO系统没有解锁,1-拥有，2-卡池中没抽到，3-还未进入卡池锁定中，4-没有这个CEO配置
]]
function CEODataManager:GetCEOCharStatusByCEOID(ceoID)
    if not self:CheckInit() then
        return 0
    end
    local status = 2 --状态值:0-CEO系统没有解锁,1-拥有，2-卡池中没抽到，3-还未进入卡池锁定中，4-没有这个CEO配置
    local ceoCfg = ConfigMgr.config_ceo[ceoID]
    if not ceoCfg then
        status = 4
        return status
    end
    for ceoIdStr, exp in pairs(self.CEOData.curCEOCharDic) do
        if ceoID == tonumber(ceoIdStr) then
            status = 1
            return status
        end
    end
    local conditionsStr = Tools:SplitString(ceoCfg.ceo_unlock_condition, ";")
    --TODO:CEO 1.0版本只有场景解锁的条件，后面待扩展
    for _, conditionStr in pairs(conditionsStr) do
        local conContentsStr = Tools:SplitString(conditionStr, ":")
        local conType = tonumber(conContentsStr[1])
        local conParam = tonumber(conContentsStr[2])
        if 1 == conType then
            if not GameTableDefine.CityMode:CheckBuildingSatisfy(conParam) then
                status = 3
                return status
            end
        end
    end
    return status
end

--region CEO对应家具的操作

---修改房间CEO的UI接口，会修改CEO家具存档 并发送修改CEO模型的事件
function CEODataManager:ChangeRoomCEO(roomIndex,newCeoID, countryId)
    local roomSaveData = FloorMode:GetRoomLocalData(roomIndex, countryId)
    local oldCeoID = roomSaveData.ceoFurnitureInfo.ceoID

    if oldCeoID == newCeoID then
        return
    end

    if oldCeoID then
        self:FireCEO(oldCeoID)
    end

    local oldRoomIndex, oldCountryId = self:GetCEOSpecificRoomIndexByCEOID(newCeoID)
    if oldRoomIndex ~= "" then
        self:FireCEO(newCeoID)
        local oldRoomSaveData = FloorMode:GetRoomLocalData(oldRoomIndex, oldCountryId)
        oldRoomSaveData.ceoFurnitureInfo.ceoID = nil
        EventDispatcher:TriggerEvent(GameEventDefine.ChangeCEOActor,oldRoomIndex, oldCountryId)
    end

    self:HireCEO(newCeoID,roomIndex, countryId)

    roomSaveData.ceoFurnitureInfo.ceoID = newCeoID
    EventDispatcher:TriggerEvent(GameEventDefine.ChangeCEOActor,roomIndex, countryId)
    LocalDataManager:WriteToFile()
end

---交换房间CEO的UI接口，会修改CEO家具存档 并发送修改CEO模型的事件
function CEODataManager:ExchangeRoomCEO(ceoID1,ceoID2)

    if ceoID1 == ceoID2 then
        return
    end

    local roomIndex1, countryId1 = self:GetCEOSpecificRoomIndexByCEOID(ceoID1)
    local roomIndex2, countryId2 = self:GetCEOSpecificRoomIndexByCEOID(ceoID2)
    local roomSaveData1 = FloorMode:GetRoomLocalData(roomIndex1, countryId1)

    self:FireCEO(ceoID1)

    roomSaveData1.ceoFurnitureInfo.ceoID = ceoID2

    local roomSaveData2
    if roomIndex2 ~= "" then
        roomSaveData2 = FloorMode:GetRoomLocalData(roomIndex2, countryId2)
        self:FireCEO(ceoID2)
        self:HireCEO(ceoID1,roomIndex2, countryId2)
        roomSaveData2.ceoFurnitureInfo.ceoID = ceoID1
        EventDispatcher:TriggerEvent(GameEventDefine.ChangeCEOActor,roomIndex2, countryId2)
    end

    self:HireCEO(ceoID2,roomIndex1, countryId1)

    EventDispatcher:TriggerEvent(GameEventDefine.ChangeCEOActor,roomIndex1, countryId1)
    LocalDataManager:WriteToFile()
end

---@return number
function CEODataManager:GetCEOByRoomIndex(roomIndex, countryId)
    local roomSaveData = FloorMode:GetRoomLocalData(roomIndex, countryId)
    if not roomSaveData or not roomSaveData.ceoFurnitureInfo then
        return nil
    end
    return roomSaveData.ceoFurnitureInfo.ceoID
end

---@return number
function CEODataManager:GetCEOFurnitureLevelByRoomIndex(roomIndex,countryId)
    local roomSaveData = FloorMode:GetRoomLocalData(roomIndex, countryId)
    if not roomSaveData or not roomSaveData.ceoFurnitureInfo then
        return 0
    end
    return roomSaveData.ceoFurnitureInfo.level
end

---CEO桌子升级
function CEODataManager:UpgradeCEODesk(roomIndex, countryId)
    local roomSaveData = FloorMode:GetRoomLocalData(roomIndex, countryId)
    if not roomSaveData.ceoFurnitureInfo then
        roomSaveData.ceoFurnitureInfo = {level = 0}
    end
    if roomSaveData.ceoFurnitureInfo then
        roomSaveData.ceoFurnitureInfo.level = roomSaveData.ceoFurnitureInfo.level + 1
        EventDispatcher:TriggerEvent(GameEventDefine.UpgradeCEODesk, roomIndex, countryId)

        local deskLevelConfig = ConfigMgr.config_ceo_furniture_level[roomSaveData.ceoFurnitureInfo.level]
        local starReward = deskLevelConfig.table_reward
        StarMode:StarRaise(starReward, true)
        EventManager:DispatchEvent("FLY_ICON", nil, 5, nil)    end
end

function CEODataManager:GetCEOBuffAddValue(ceoid)

    local incomeAdd = 1
    local expAdd = 1
    if not self:CheckInit() then
        return incomeAdd, expAdd
    end
    local ceoKey = tostring(ceoid)
    if self.CEOData.curCEOCharDic[ceoKey] then 
        local ceoCfg = ConfigMgr.config_ceo[ceoid]
        local ceoLvlCfg = ConfigMgr.config_ceo_level[ceoid][self.CEOData.curCEOCharDic[ceoKey].Level]
        if ceoCfg and ceoLvlCfg then
            if ceoCfg.ceo_effect_type == "income" then
                incomeAdd = ceoLvlCfg.ceo_effect
            end
            if ceoCfg.ceo_effect_type == "exp" then
                expAdd = ceoLvlCfg.ceo_effect
            end
        end
    end
    return incomeAdd, expAdd
end
---是否是新CEO，在CEOList中没点击过
function CEODataManager:IsNewCEO(ceoID)
    if not self.CEOData then
        return false
    end
    if not self.CEOData.NotNewCEOs then
        self.CEOData.NotNewCEOs = {}
        return true
    end
    if not self.CEOData.NotNewCEOs[tostring(ceoID)] then
        return true
    else
        return false
    end
end

---设为不是NEW CEO，在CEOList中点击过
function CEODataManager:SetIsNotNewCEO(ceoID)
    if not self.CEOData then
        return
    end
    if not self.CEOData.NotNewCEOs then
        self.CEOData.NotNewCEOs = {}
    end
    self.CEOData.NotNewCEOs[tostring(ceoID)] = true
end

---设为不是NEW CEO，在CEOList中点击过
function CEODataManager:NeedShowHint()
    if not self.CEOData or not self.CEOData.curCEOCardsDic then
        return false
    end
    if not self:GetGuideTriggered() then
        return false
    end
    local ceoDatas = self.CEOData.curCEOCharDic
    for kID,v in pairs(ceoDatas) do
        if not self.CEOData.NotNewCEOs or not self.CEOData.NotNewCEOs[kID] then
            return true
        else
            local ceoID = tonumber(kID)
            local ceoLevel = v.Level or 1
            local nextCEOLevelConfig = CEODataManager:GetCEOLevelConfig(ceoID,ceoLevel+1)
            if nextCEOLevelConfig then
                local needFragment = nextCEOLevelConfig.ceo_cost[1][2]
                local haveFragment = CEODataManager:GetCurCEOCardsNum(ceoID)
                local canUpgrade = haveFragment >= needFragment
                if canUpgrade then
                    return true
                end
            end
        end
    end
    return false
end

--endregion

---@return CEOConfig
function CEODataManager:GetCEOConfig(ceoID)
    return ConfigMgr.config_ceo[ceoID]
end

---@return CEOLevelConfig
function CEODataManager:GetCEOLevelConfig(ceoID,level)
    local ceoLevelCfgList = ConfigMgr.config_ceo_level[ceoID]
    if ceoLevelCfgList then
        return ceoLevelCfgList[level]
    else
        return nil
    end
end

---将CEO引导设为已触发
function CEODataManager:SetGuideTriggered()
    self.CEOData.IsGuideTriggered = true
    local floorScene = FloorMode:GetScene()
    if floorScene then
        floorScene:ShowAllCEO3DIcons()
    end
end

---将CEO引导2设为已触发
function CEODataManager:SetGuide2Triggered()
    if not self.CEOData then
        self.CEOData = LocalDataManager:GetDataByKey("CEO_Data")
    end
    self.CEOData.IsGuide2Triggered = true
end

---引导是否已触发
function CEODataManager:GetGuideTriggered()
    if not self.CEOData then
        self.CEOData = LocalDataManager:GetDataByKey("CEO_Data")
    end
    if not self.CEOData then
        return false
    end
    return self.CEOData.IsGuideTriggered and true or false
end

---引导2是否已触发
function CEODataManager:GetGuide2Triggered()
    return self.CEOData.IsGuide2Triggered and true or false
end

--[[
    @desc: 实际给东西的方法
    author:{author}
    time:2025-02-11 15:51:37
    --@rewards: 这是可以用来显示的reward
    @return:
]]
function CEODataManager:GetRealBoxRewards(rewards, boxType, openSource)
    local lastRewads = {}
    local lastRewardExtends = {}
    local boxDispwardExtends = {}
    -- for _, rewardItem in pairs(rewards) do
    --     for itemID, itemNum in pairs(rewardItem) do
    --         local shopCfg = ConfigMgr.config_shop[itemID]
    --         if shopCfg then
    --             local shopType = shopCfg.type
    --         end
    --     end
    -- end
    for index, boxItems in pairs(rewards) do
        if not boxDispwardExtends[index] then
            boxDispwardExtends[index] = {}
        end
        for shopID, item in pairs(boxItems) do
            local itemReward  = {}
            -- if not lastRewads[shopID] then
            --     lastRewads[shopID] = itemReward
            -- else
            --     lastRewads[shopID][2] = lastRewads[shopID][2] + item.num
            -- end
            itemReward[shopID] = item.num
            if not lastRewads[shopID] then
                lastRewads[shopID] = itemReward
            else
                lastRewads[shopID][shopID]  = lastRewads[shopID][shopID] + item.num
            end
            if item.extendData then
                if not lastRewardExtends[shopID] then
                    lastRewardExtends[shopID] = {}
                end
                if not boxDispwardExtends[index][shopID] then
                    boxDispwardExtends[index][shopID] = {}
                end
                for _, ceoid in pairs(item.extendData) do
                    table.insert(lastRewardExtends[shopID], ceoid)
                    table.insert(boxDispwardExtends[index][shopID], ceoid)
                end
            end
        end
    end

    for shopID, realItem in pairs(lastRewads) do
        local testParam = realItem
        GameTableDefine.ShopManager:BuyByGiftCode(realItem, nil, false, false, lastRewardExtends[shopID], openSource)
    end
    local displaylastRewardDatas = {}
    GameTableDefine.CEOBoxPurchaseUI:SuceessOpenCEOBox(boxType, rewards, boxDispwardExtends)
end

function CEODataManager:GetCEOCardByCEOID(ceoid)
    local ceoKey = tostring(ceoid)
    if not self.curNewCEOIDs then
        self.curNewCEOIDs = {}
    end
    if not self.CEOData.curCEOCharDic[ceoKey] then
        local ceoDataItem = {}
        ceoDataItem.Level = 1
        ceoDataItem.Exp = 0
        ceoDataItem.totalCostNum = 1
        self.CEOData.curCEOCharDic[ceoKey] = ceoDataItem
        table.insert(self.curNewCEOIDs, ceoid)
    else
        if not self.CEOData.curCEOCardsDic[ceoKey] then
            self.CEOData.curCEOCardsDic[ceoKey] = 1
        else
            self.CEOData.curCEOCardsDic[ceoKey]  = self.CEOData.curCEOCardsDic[ceoKey] + 1
        end
        local delIndex = -1
        for index, id in pairs(self.curNewCEOIDs) do
            if id == ceoid then
                delIndex = index
                break;
            end
        end
        if delIndex > 0 then
            self.curNewCEOIDs[delIndex] = nil
        end
    end
    -- GameTableDefine.MainUI:RefreshPetHint()
    self:UpdateCEODataToThinking()
end

function CEODataManager:GetCurNewCEOs()
    return self.curNewCEOIDs or {}
end

function CEODataManager:GetCEOIsNewGet(ceoid)
    for _, id in pairs(self.curNewCEOIDs or {}) do
        if id == ceoid then
            return true
        end
    end
    return false
end

function CEODataManager:NeedTransformCEOCardToDiamond(ceoid)
    local result = -1
    local ceoKey = tostring(ceoid)
    if not self.CEOData.curCEOCharDic[ceoKey] and not self.CEOData.curCEOCardsDic[ceoKey] then
        return -1
    end
    local isMaxCEO = false
    local nextLvl = self.CEOData.curCEOCharDic[ceoKey].Level + 1
    if not ConfigMgr.config_ceo_level[ceoid][nextLvl] then
        result = ConfigMgr.config_ceo[ceoid].ceo_diamond_value
    end
    return result 
end

--[[
    @desc: 获取当前CEO的卡牌数量
    author:{author}
    time:2025-02-12 11:47:22
    --@ceoid: 
    @return:
]]
function CEODataManager:GetCurCEOCardsNum(ceoid)
    if not self:CheckInit() then
        return 0
    end
    local ceoKey = tostring(ceoid)
    return self.CEOData.curCEOCardsDic[ceoKey] or 0
end

function CEODataManager:GetCurCEOCostTotalCard()
end

---清空这个CEO的所有碎片,转换为钻石时调用
function CEODataManager:ClearCurCEOCards(ceoid)
    if not self:CheckInit() then
        return false
    end
    local ceoKey = tostring(ceoid)
    if self.CEOData.curCEOCardsDic[ceoKey] then
        self.CEOData.curCEOCardsDic[ceoKey] = 0
    end
    return true
end

--[[
    @desc: 升级指定的CEO
    author:{author}
    time:2025-02-12 11:49:01
    --@ceoid:
	--@cb: (errorcode)1-成功,2-系统未初始化,3-没有这个CEO，4-已经到最大等级不能再升级了，5-材料不够
    @return:
]]
function CEODataManager:UpgradeCurCEO(ceoid, cb)
    if not self:CheckInit() then
        if cb then
            cb(2)
        end
        return
    end
    local ceoKey = tostring(ceoid)
    if not self.CEOData.curCEOCharDic[ceoKey] then
        if cb then
            cb(3)
        end
        return
    end
    local nextLevel = self.CEOData.curCEOCharDic[ceoKey].Level + 1
    local ceoLevelConfigs = ConfigMgr.config_ceo_level[ceoid]
    if not ceoLevelConfigs or not ceoLevelConfigs[nextLevel] then
        if cb then
            cb(4)
        end
        return
    end
    local needCost = ceoLevelConfigs[nextLevel].ceo_cost[1][2]
    if not self.CEOData.curCEOCardsDic[ceoKey] or self.CEOData.curCEOCardsDic[ceoKey] < needCost then
        if cb then
            cb(5)
        end
        return
    end
    local ceoCfg = ConfigMgr.config_ceo[ceoid]
    GameSDKs:TrackForeign("ceo_upgrade", {id = tonumber(ceoid), quality = ceoCfg.ceo_quality, type = ceoCfg.ceo_effect_type, level = tonumber(self.CEOData.curCEOCharDic[ceoKey].Level + 1)})
    self.CEOData.curCEOCardsDic[ceoKey]  = self.CEOData.curCEOCardsDic[ceoKey] - needCost
    self.CEOData.curCEOCharDic[ceoKey].Level  = self.CEOData.curCEOCharDic[ceoKey].Level + 1
    if not self.CEOData.curCEOCharDic[ceoKey].totalCostNum then
        self.CEOData.curCEOCharDic[ceoKey].totalCostNum = needCost
    else
        self.CEOData.curCEOCharDic[ceoKey].totalCostNum  = self.CEOData.curCEOCharDic[ceoKey].totalCostNum + needCost
    end
    local roomIndex, countryId = self:GetCEOSpecificRoomIndexByCEOID(ceoid)
    if roomIndex ~= "" then
        EventDispatcher:TriggerEvent(GameEventDefine.RoomCEOUpgrade, roomIndex)
    end
    if cb then
        cb(1)
    end
    self:UpdateCEODataToThinking()
end

--[[
    @desc: 返回下一级需要的经验值，如果<0则表示当前已是最大等级
    author:{author}
    time:2025-02-19 16:13:39
    --@ceoid:
	--@curLevel: 
    @return:
]]
function CEODataManager:GetNextLevelExp(ceoid)
    local needRes = 0
    if not self:CheckInit() then
        return needRes
    end
    local ceoKey = tostring(ceoid)
    if not self.CEOData.curCEOCharDic[ceoKey] then
        return 0
    end
    local nextLevel = self.CEOData.curCEOCharDic[ceoKey].Level + 1
    local ceoLevelConfigs = ConfigMgr.config_ceo_level[ceoid]
    if not ceoLevelConfigs or not ceoLevelConfigs[nextLevel] then
        return -1
    end
    local needRes = ceoLevelConfigs[nextLevel].ceo_cost[1][2]
    return needRes
end

--[[
    @desc: GM指定CEO的等级，如果等级不存在就直接设置为最大等级
    author:{author}
    time:2025-02-14 16:15:00
    --@ceoid:
	--@lvl: 
    @return:
]]
function CEODataManager:GMModifyCEOLevel(ceoid, lvl)
    local ceoKey = tostring(ceoid)
    if self.CEOData.curCEOCharDic[ceoKey] then
        local setLvl = lvl
        if not ConfigMgr.config_ceo_level[ceoid][lvl] then
            return
        else
            self.CEOData.curCEOCharDic[ceoKey].Level = lvl
        end
    end
end

function CEODataManager:GMRefreshFreeTimes()
    if self.CEOData and self.CEOData.dayLeftFreeTimes then
        local cfgFreeTimes = tonumber(ConfigMgr.config_global.ceochest_free_limit)
        self.CEOData.dayLeftFreeTimes = cfgFreeTimes
        self.CEOData.freeRefreshDayTime = 0
        self.CEOData.curFreeBoxCD = 0
    end
end

function CEODataManager:RefreshDayFreeOpenTimes()
    if not self.CEOData or not self.CEOData.freeRefreshDayTime or self.CEOData.freeRefreshDayTime <= 0 then
        return
    end
    if self.CEOData.freeRefreshDayTime > 0 then
        if not GameTimeManager:IsSameDay(self.CEOData.freeRefreshDayTime, GameTimeManager:GetCurrentServerTime(true)) then
            local cfgFreeTimes = tonumber(ConfigMgr.config_global.ceochest_free_limit)
            self.CEOData.dayLeftFreeTimes = cfgFreeTimes
            self.CEOData.freeRefreshDayTime = 0
            self.CEOData.curFreeBoxCD = 0
        end
    end
end

function CEODataManager:OnPause()
    if self.refreshTimer then
        GameTimer:StopTimer(self.refreshTimer)
        self.refreshTimer = nil
    end
end

function CEODataManager:OnResume()
    if self.refreshTimer then
        GameTimer:StopTimer(self.refreshTimer)
        self.refreshTimer = GameTimer:CreateNewTimer(1, function()
            self:RefreshDayFreeOpenTimes()
        end, true, true)
    end
end

--[[
    @desc: 返回当前宝箱的可使用状态
    author:{author}
    time:2025-02-27 14:18:18
    @return:0-没有可以使用的宝箱， 1-有可食用的高级宝箱，2-有可使用的普通宝箱，3-有可使用的免费宝箱
]]
function CEODataManager:CheckCEOBoxCanUse()
    local useState = 0
    local useIcon = ""
    if not self:CheckInit() then
        return useState, ""
    end
    local premiumKeyRequireStrs = ConfigMgr.config_ceo_chest["premium"].chest_key_require
    local premiumNeedKeyCfg = 0
    local premiumTmpStrs = Tools:SplitString(premiumKeyRequireStrs, ":")
    premiumNeedKeyCfg = tonumber(premiumTmpStrs[2])
    useIcon = ConfigMgr.config_ceo_chest["premium"].chest_icon
    
    --step1.高级箱子
    if self.CEOData.curKeys["premium"] >= premiumNeedKeyCfg then
        useState = 1
        return useState, useIcon
    end

    local normalKeyRequireStrs = ConfigMgr.config_ceo_chest["normal"].chest_key_require
    local normalNeedKeyCfg = 0
    local normalTmpStrs = Tools:SplitString(normalKeyRequireStrs, ":")
    normalNeedKeyCfg = tonumber(normalTmpStrs[2])
    useIcon = ConfigMgr.config_ceo_chest["normal"].chest_icon
    --step2.普通箱子
    if self.CEOData.curKeys["normal"] >= normalNeedKeyCfg then
        useState = 2
        return useState, useIcon
    end
    --免费箱子 
    useIcon = ConfigMgr.config_ceo_chest["free"].chest_icon
    if self.CEOData.dayLeftFreeTimes > 0 and self:GetFreeBoxCDTime() <= 0 then
        useState = 3
        return useState, useIcon
    end
    return useState, useIcon
end

-- commonProp.normal_key_num = GameTableDefine.CEODataManager:GetKeysData("normal", 1)
-- 		commonProp.premium_key_num = GameTableDefine.CEODataManager:GetKeysData("premium", 1)
-- 		commonProp.normal_key_total_num = GameTableDefine.CEODataManager:GetKeysData("normal", 2)
-- 		commonProp.premium_key_total_num = GameTableDefine.CEODataManager:GetKeysData("premium", 2)
-- 		commonProp.normal_ceo_num = GameTableDefine.CEODataManager:GetCEOData("normal", 1)
-- 		commonProp.premium_ceo_num = GameTableDefine.CEODataManager:GetCEOData("premium", 1)
-- 		commonProp.normal_card_num = GameTableDefine.CEODataManager:GetCEOData("normal", 2)
-- 		commonProp.premium_card_num = GameTableDefine.CEODataManager:GetCEOData("premium", 2)
function CEODataManager:GetKeysData(keyType, dataType)
    if not self:CheckInit() then
        return 0
    end
    if dataType == 1 then
        return self.CEOData.curKeys[keyType] or 0
    end
    if dataType == 2 then
        local key = "total_"..keyType
        return self.CEOData.curKeys[key] or 0
    end
    return 0
end

function CEODataManager:GetCEOData(ceoType, dataType)
    if not self:CheckInit() then
        return 0
    end
    local result = 0
    
        -- totalCostNum
    for ceoKey, ceo in pairs(self.CEOData.curCEOCharDic) do 
        local ceoCfg = ConfigMgr.config_ceo[tonumber(ceoKey)]
        if ceoCfg then
            if ceoType == ceoCfg.ceo_quality then
                if dataType == 1 then
                    result  = result + 1
                elseif dataType == 2 then
                    result  = result + (ceo.totalCostNum or 0)
                end
            end
        end
    end
    return result
end


--[[
    @desc: 上报数数用户属性CEO相关内容
    author:{author}
    time:2025-04-02 14:23:32
    @return:
]]
function CEODataManager:UpdateCEODataToThinking()
    if not self.CEOData or not self.CEOData.curCEOCharDic or not self.CEOData.curCEOCardsDic or not self.CEOData.curCEORoomsData then
        return
    end
    local  ceoData = {}
    for ceoIdKey, ceoItemData in pairs(self.CEOData.curCEOCharDic) do
        local tmpItemData = {}
        tmpItemData.ceo_id = tonumber(ceoIdKey)
        local ceoCfg = ConfigMgr.config_ceo[tmpItemData.ceo_id]
        if ceoCfg then
            tmpItemData.ceo_quality = ceoCfg.ceo_quality
            tmpItemData.ceo_level = tonumber(ceoItemData.Level)
            tmpItemData.ceo_storage = tonumber(self.CEOData.curCEOCardsDic[ceoIdKey] or 0)
            local stateDesc = "闲置 "
            if self.CEOData.curCEORoomsData[ceoIdKey] then
                stateDesc = "工作 "
            end
            tmpItemData.ceo_state = stateDesc 
            table.insert(ceoData, tmpItemData)
        end
    end
    if Tools:GetTableSize(ceoData) > 0 then
        GameSDKs:SetUserAttrToWarrior({ob_ceo_statistics = ceoData})
    end
end