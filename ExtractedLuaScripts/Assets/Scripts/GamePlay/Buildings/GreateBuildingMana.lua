---@class GreateBuildingMana
local GreateBuildingMana = GameTableDefine.GreateBuildingMana

local ResMgr = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local HouseMode = GameTableDefine.HouseMode
local CashEarn = GameTableDefine.CashEarn
local ValueManager = GameTableDefine.ValueManager
local ShopManager = GameTableDefine.ShopManager
local CountryMode = GameTableDefine.CountryMode
local EventManager = require("Framework.Event.Manager")
local Actor = require("GamePlay.Floors.Actors.Actor")
local ActorManager = require("CodeRefactoring.Actor.ActorManager")
local CEODataManager = GameTableDefine.CEODataManager

--伟大工程,在大地图界面,黄色施工节点,点击修建后产生
--带有不同功能,包括每分钟得前,提高电力,提高员工心情
--可以升级

local MOOD_IMPROVE = "mood"
local POWER_IMPROVE = "power"
local EARN_IMPROVE = "earn"

--具体特定的效果,到时需要用的地方直接取
function GreateBuildingMana:GetMoodImprove()--心情提升(number类型)
    if not self.mood then
        self.mood = self:GetFunc(MOOD_IMPROVE) + ShopManager:GetMoodImprove()
    end

    return self.mood
end

function GreateBuildingMana:GetPowerImprove()--电力提升
    if not self.power then
        self.power = self:GetFunc(POWER_IMPROVE)
    end
    return self.power 
end

function GreateBuildingMana:RefreshImprove()
    self.mood = self:GetFunc(MOOD_IMPROVE) + ShopManager:GetMoodImprove()
    self.power = self:GetFunc(POWER_IMPROVE)
end

function GreateBuildingMana:GetCashEarn(id, check)--挂机收益
    local data = LocalDataManager:GetDataByKey(CountryMode.greate_building)
    if not data[id..""] then
        return 0
    end

    local currEarn = data[id..""].earn or 0
    if check then
        return currEarn
    end

    if currEarn > 0 then
        ResMgr:AddLocalMoney(currEarn, nil, function()
            data[id..""].earn = 0
        end, nil, true)
        --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
        local type = CountryMode:GetCurrCountry()
        local amount = currEarn
        local change = 0
        local position = "["..id.."]号伟大工程"
        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
    end

    return currEarn
end

function GreateBuildingMana:UpdateBankMoney(offline)
    local data = LocalDataManager:GetDataByKey(CountryMode.greate_building)
    local needSave = false
    for k,v in pairs(data or {}) do
        local func,name,earnMax,offLineRate = self:GetFunction(k)
        if name == EARN_IMPROVE then
            if not v.earn then
                v.earn = 0
            end

            if not v.last then
                v.last = GameTimeManager:GetCurrentServerTime()
            end

            local now = GameTimeManager:GetCurrentServerTime()
            local timePass = now - v.last
            if timePass < 0 then--避免改时间导致的很长时间无法领钱
                v.last = now
                needSave = true
            end

            --每过120秒,才加一次钱
            local earnTimes = math.floor(timePass / CashEarn:BankRefreshTime())

            if earnTimes > 0 then
                local totalEarn = func[v.lv] * earnTimes
                if offline then
                    totalEarn = math.floor(totalEarn * offLineRate[v.lv])--离线比例
                end

                v.earn = v.earn + totalEarn
                v.last = v.last + earnTimes * CashEarn:BankRefreshTime()

                local max = earnMax[v.lv]
                if v.earn > max then
                    v.earn = max
                end

                EventManager:DispatchEvent("BANK_EARN", tonumber(k))

                needSave = true
            end
        end
    end

    if needSave then
        LocalDataManager:WriteToFile()
    end
end

function GreateBuildingMana:GetFunc(funcName)
    local data = LocalDataManager:GetDataByKey(CountryMode.greate_building)
    local result = 0
    for k,v in pairs(data or {}) do
        local func,name = self:GetFunction(k)
        if name == funcName and v.lv > 0 then
            result = result + func[v.lv]
        end
    end

    return result
end

function GreateBuildingMana:IsTypeBank(funcName)
    return funcName == EARN_IMPROVE
end

function GreateBuildingMana:GetFunction(buildingId)
    local currCfg = ConfigMgr.config_buildings[tonumber(buildingId)]
    if currCfg.power_improve then
        return currCfg.power_improve, POWER_IMPROVE
    elseif currCfg.mood_improve then
        return currCfg.mood_improve, MOOD_IMPROVE
    elseif currCfg.earn_improve then
        return currCfg.earn_improve, EARN_IMPROVE, currCfg.earn_max, currCfg.earn_rate
    end
end

function GreateBuildingMana:GetLv(buildingId)
    local data = LocalDataManager:GetDataByKey(CountryMode.greate_building)

    local currLv = 0
    local maxLv = 0
    if data[""..buildingId] then
        currLv = data[""..buildingId].lv
    end

    maxLv = #ConfigMgr.config_buildings[buildingId].unlock_require

    return currLv, maxLv
end

function GreateBuildingMana:BuyBuilding(buildingId, check)
    local currLv, maxLv = self:GetLv(buildingId)
    local cfg = ConfigMgr.config_buildings[buildingId]

    local isMax = currLv == maxLv
    local enoughCash = false
    local enoughStar = false
    local noCD = true--先不弄冷却
    local lackValue = false--身价

    local currCfg = ConfigMgr.config_buildings[buildingId]
    local cashNeed = currCfg.unlock_require[currLv+1]
    local starNeed = currCfg.starNeed
    local valueNeed = 0

    --if GameConfig:IsIAP() then
        valueNeed = currCfg.wealth_request[currLv + 1] or 0
        lackValue = valueNeed > ValueManager:GetValue()
    --end

    enoughCash = ResMgr:CheckCash(cashNeed)
    enoughStar = StarMode:GetStar() >= starNeed

    local buyAble = false
    if enoughCash and enoughStar and noCD and not isMax and not lackValue then
        buyAble = true
    end

    if check then
        valueNeed = currCfg.wealth_request[1] or 0
        return buyAble, cashNeed, starNeed, valueNeed
    end

    if buyAble then
        local buy = function(isEnough)
            if isEnough then
                local data = LocalDataManager:GetDataByKey(CountryMode.greate_building)
                if not data[""..buildingId] then
                    data[""..buildingId] = {}
                    data[""..buildingId].lv = 0
                end

                local curr = data[""..buildingId]
                curr.lv = curr.lv + 1

                CityMode:RefreshBuildingState(buildingId)--更新图标
                CityMode:RefreshGreateDetail(buildingId)--更新信息信息
                self:RefreshImprove()
                if cfg.power_improve and cfg.power_improve~=0 then
                    EventManager:DispatchEvent(GameEventDefine.ReCalculateTotalPower)
                end
                ActorManager:RefreshEmployeesMood()
                GameSDKs:TrackForeign("asset_buy",{type = 3, id = buildingId, star_new = tonumber(StarMode:GetStar()), level_new = tonumber(curr.lv) })
                if buildingId == 30001 then
                    GameSDKs:TrackControl("af", "af,assetbuy_invest_30001", {})
                end
                if buildingId == 30002 then
                    GameSDKs:TrackControl("af", "af,assetbuy_invest_30002", {})
                end
                if buildingId == 30003 then
                    GameSDKs:TrackControl("af", "af,assetbuy_invest_30003", {})
                end
                self:GetCEOUpdateReward(buildingId)
                --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
                local type = CountryMode:GetCurrCountry()
                local amount = enoughCash
                local change = 1
                local position = "["..buildingId.."]号伟大工程"
                GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
                
            end
        end

        ResMgr:SpendCash(cfg.unlock_require[currLv + 1], nil, buy)
    end
end

--[[
    @desc: 检测是否获取CEO对应的奖励内容
    author:{author}
    time:2025-02-24 16:48:29
    --@buildingId: 
    @return:
]]
function GreateBuildingMana:GetCEOUpdateReward(buildingId)
    if not CEODataManager:CheckCEOOpenCondition() then
        return
    end
    local buildingCfg = ConfigMgr.config_buildings[buildingId]
    if buildingCfg then
        for _, item in pairs(buildingCfg.ceo_reward) do
            local shopCfg = ConfigMgr.config_shop[item[1]]
            if shopCfg then
                local num = shopCfg.amount * item[2]
                if shopCfg.type == 43 then
                    GameSDKs:TrackForeign("ceo_key_change", {type = shopCfg.param[1], source = "伟大工程升级", num = tonumber(num)}) 
                    GameTableDefine.CEODataManager:AddCEOKey(shopCfg.param[1], num)    
                end
            end
        end
    end
    
end