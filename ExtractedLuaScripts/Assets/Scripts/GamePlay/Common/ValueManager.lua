local ValueManager = GameTableDefine.ValueManager
local EventManager = require("Framework.Event.Manager")
local ResMgr = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local HouseMode = GameTableDefine.HouseMode
local CfgMgr = GameTableDefine.ConfigMgr
local StarMode = GameTableDefine.StarMode
local MainUI = GameTableDefine.MainUI
local CountryMode = GameTableDefine.CountryMode

local VALUE = "bank"--奖励领取情况,可领取到哪里
local currHouse = nil
local currCar = nil


local cashLimit = 1
local euro_limit = 2
ValueManager.limitKey = 
{
    [cashLimit] = "cashLimit",
    [euro_limit] = "euro_limit"
}

--对身价相关的管理
function ValueManager:GetValue(refresh)
    -- if not GameConfig:IsIAP() then
    --     return 0,0,0
    -- end

    if refresh or currHouse == nil then
        currHouse, currCar = self:CalculateValue()
        self:RefreshRank(currHouse + currCar)
    end

    return currHouse + currCar, currHouse, currCar
end

function ValueManager:RefreshRank(currValue)
    -- if not GameConfig:IsIAP() then
    --     return
    -- end
    
    local cfg = ConfigMgr.config_wealthrank

    local rankData = LocalDataManager:GetDataByKey(VALUE)
    local currRank = self:GetPlayerRank()

    if currRank then
        if rankData["max"] == nil and currRank or rankData["max"] > currRank then
            rankData["max"] = currRank
        end
    end

    MainUI:SetPhoneNum()
end

function ValueManager:GetRankReward(check)
    local cfg = ConfigMgr.config_wealthrank

    local rankData = LocalDataManager:GetDataByKey(VALUE)
    local max = rankData["max"] or nil--最高身价
    local last = rankData["last"] or nil--奖励领取到哪

    if check then
        local allReward = {}
        local rewardAble = false
        if last ~= max then
            rewardAble = true
            if last == nil then
                last = #cfg
            end
            for i = last, max, -1 do
                if i <= Tools:GetTableSize(cfg) and i ~= 0 then
                    table.insert(allReward, cfg[i].reward)
                end
            end
        end
        local reward = MainUI:AddMultiple(allReward, true, nil, true, true)
        return rewardAble,reward--都nil就是没进过排行版，一样大就是领过奖了
    end

    if max ~= last then
        self.alreadyGot = false
        if last == nil then
            last = #cfg
        end

        -- local rewardCash = 0
        -- local rewardDiamond = 0
        -- local rewardStar = 0
        -- local currData = nil
        -- local allReward = {}

        -- for i = last, max, -1 do
        --     currData = cfg[i]
        --     if currData and currData.reward then
        --         for k,v in pairs(currData.reward) do
        --             -- if v[1] == 2 then
        --             --     rewardCash = rewardCash + v[2]
        --             -- elseif v[1] == 3 then
        --             --     rewardDiamond = rewardDiamond + v[2]
        --             -- elseif v[1] == 4 then
        --             --     rewardStar = rewardStar + v[2]
        --             -- end
        --             if allReward[v[1]] == nil then
        --                 allReward[v[1]] = 0
        --             end
        --             allReward[v[1]] = allReward[v[1]] + v[2]
        --         end
        --     end
        -- end
        local callBack = function()
            if self.alreadyGot == true then
                return
            end

            self.alreadyGot = true
            rankData["last"] = rankData["max"]
            LocalDataManager:WriteToFile()
            MainUI:SetPhoneNum()
        end

        local allReward = {}
        for i = last, max, -1 do
            table.insert(allReward, cfg[i].reward)
        end
        --身价只加一个...所以
        local currData = nil
        MainUI:AddMultiple(allReward, true, callBack, true)
        -- for i = last, max, -1 do
        --     currData = cfg[i]
        --     if currData and currData.reward then
        --         MainUI:AddMultiple(currData.reward, true, callBack)
        --     end
        -- end

        -- if allReward[2] and allReward[2] > 0 then
        --     ResMgr:AddCash(allReward[2], nil, callBack, true)
        -- end
        -- if allReward[3] and allReward[3] > 0 then
        --     ResMgr:AddDiamond(allReward[3], nil, callBack, true)
        -- end
        -- if allReward[5] and allReward[5] > 0 then
        --     StarMode:StarRaise(allReward[5], true, callBack)
        -- end
        
    end
end

function ValueManager:GetPlayerRank()
    local data = ConfigMgr.config_wealthrank
    local playerValue = self:GetValue()
    local total = #data
    local rank = nil
    local defeat = nil

    for i = total, 1, -1 do
        if playerValue > data[i].value then
            rank = total - i + 1
            break
        end
    end

    if rank ~= nil then
        defeat = #data - rank + 1
    end

    return rank,defeat
end

function ValueManager:CalculateValue()--实际运算也不多,就买车买房卖车的时候会计算,所以就不存了
    local data = LocalDataManager:GetDataByKey("houses")
    local cfgBuilding = CfgMgr.config_buildings
    local cfgCar = CfgMgr.config_car

    local currId = nil
    local currValue = 0
    local totalHouse = 0
    local totalCar = 0

    if data.d then
        for k,v in pairs(data.d) do
            currId = v.id
            currValue = cfgBuilding[currId]
            if currValue then
                currValue = currValue.wealth_buff
            end
            if currValue then
                totalHouse = totalHouse + currValue
            end

            for carK, carV in pairs(v.cp or {}) do
                if carV.car then
                    currValue = cfgCar[carV.car]
                    if currValue then
                        currValue = currValue.wealth_buff
                    end
                    if currValue then
                        totalCar = totalCar + currValue--车的价值
                    end
                end
            end
        end
    end

    currValue = 0
    if data.t then
        currId = data.t.car
        if currId then
            currValue = cfgCar[currId]
            if currValue then
                currValue = currValue.wealth_buff
            end
            if currValue then
                totalCar = totalCar + currValue
            end
        end
    end

    return totalHouse, totalCar
end
--value--1表示绿钞2表示欧元
function ValueManager:CurrCashLimit(type)
    -- if not GameConfig.IsIAP() then--非付费版本不设置限制
    --     return 0
    -- end
    type = type or 1 
    local _nouse, currData = self:GetCashLevelData(type)
    return currData[self.limitKey[type]]   
end
--value--1表示绿钞2表示欧元
function ValueManager:GetCashLevelData(type)  
    type = type or 1    
    local save = LocalDataManager:GetDataByKey(VALUE)
    
    if save["lv" .. CountryMode.SAVE_KEY[type]] == nil then
        save["lv" .. CountryMode.SAVE_KEY[type]] = 1
    end
    LocalDataManager.WriteToFile()
    local currLevel = save["lv" .. CountryMode.SAVE_KEY[type]]
    local cfgBank = ConfigMgr.config_bank
    local currData = cfgBank[currLevel]
    local nextData = cfgBank[currLevel + 1]
    return currLevel, currData, nextData
end

function ValueManager:RaiseCashLevel(check, type)
    type = type or 1
    local save = LocalDataManager:GetDataByKey(VALUE)    
    if save["lv" .. CountryMode.SAVE_KEY[type]] == nil then
        save["lv" .. CountryMode.SAVE_KEY[type]] = 1
    end
    local isMax = false
    local currData = ConfigMgr.config_bank[save["lv" .. CountryMode.SAVE_KEY[type]] + 1]
    if currData == nil or currData[self.limitKey[type]] == nil then
        isMax = true
    end

    if check then
        if isMax == true then
            return false, isMax
        end

        return StarMode:GetStar() >= currData.fame, isMax
    end

    if isMax then
        return
    end

    save["lv" .. CountryMode.SAVE_KEY[type]] = save["lv" .. CountryMode.SAVE_KEY[type]] + 1
    ResMgr:SetCashMax(ValueManager:CurrCashLimit(type))
    LocalDataManager.WriteToFile()
end

function ValueManager:InitBankData()
    local save = LocalDataManager:GetDataByKey(VALUE)
    local moneyConfig = ConfigMgr.config_money
    local bankConfig = ConfigMgr.config_bank
    for i = 1, #moneyConfig do
        for p = 1, #bankConfig do
            local saveKay = save["lv" .. CountryMode.SAVE_KEY[i]]
            if save["lv" .. CountryMode.SAVE_KEY[i]] == nil or not (i == 1 and bankConfig[saveKay].cashLimit or bankConfig[saveKay].euro_limit) then
                local limit = i == 1 and bankConfig[p].cashLimit or bankConfig[p].euro_limit
                if limit then
                    save["lv" .. CountryMode.SAVE_KEY[i]] = p
                end
            end
        end
       
    end
end 