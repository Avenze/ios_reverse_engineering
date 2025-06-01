local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")
local Bus = require "CodeRefactoring.Actor.Actors.BusNew"

---@class BuyCarManager
local BuyCarManager = GameTableDefine.BuyCarManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local ChatEventManager = GameTableDefine.ChatEventManager
local HouseMode = GameTableDefine.HouseMode
local CompanyMode = GameTableDefine.CompanyMode
local StarMode = GameTableDefine.StarMode
local ValueManager = GameTableDefine.ValueManager
local ChooseUI = GameTableDefine.ChooseUI

local UnityHelper = CS.Common.Utils.UnityHelper;

local BUY_CAR = "buy_car"

function BuyCarManager:FirstCome(shopId)
    local isFirst = false
    local save = LocalDataManager:GetDataByKey(BUY_CAR)
    if not save["go"] then
        save["go"] = {}
    end

    if not save["go"][""..shopId] then
        save["go"][""..shopId] = true
        isFirst = true
    end
    LocalDataManager:WriteToFile()

    return isFirst
end

---检查库存是否充足
function BuyCarManager:CheckShopExit(carId, shopId)
    local save = LocalDataManager:GetDataByKey(BUY_CAR)
    local buyCar = save["buy"] or {}
    local currShop = buyCar[""..shopId] or {}
    local currCar = currShop[""..carId] or 0

    local cfg_car = ConfigMgr.config_carshop[shopId].cars[carId]
    return currCar < cfg_car.num
end

function BuyCarManager:OwnCar(carId, shopId)
    local save = LocalDataManager:GetDataByKey(BUY_CAR)
    local buyFrom = save["buy"] or {}
    if shopId then
        buyFrom = buyFrom["".. shopId]
        if not buyFrom then
            return 0
        end
        return buyFrom[""..carId] or 0
    end

    local num = 0
    for k,v in pairs(buyFrom) do
        num = num + (v[""..carId] or 0)
    end

    return num
end

function BuyCarManager:Sell(carId, shopId, garageId)
    local cfg_car = ConfigMgr.config_car[carId]
    local cfg_shop = ConfigMgr.config_carshop[shopId]
    local cfg_carInfo = cfg_shop.cars[carId]
    local houseCarPort = HouseMode:GetIdleCarPort()

    local save = LocalDataManager:GetDataByKey(BUY_CAR)
    if not save["buy"] then
        save["buy"] = {}
    end
    if not save["buy"][""..shopId] then
        save["buy"][""..shopId] = {}
    end

    local currShop = save["buy"][""..shopId]
    if not currShop[""..carId] or currShop[""..carId] < 0 then
        currShop[""..carId] = 0
    end

    currShop[""..carId] = currShop[""..carId] - 1

    HouseMode:SellCarFromGarage(garageId)

    local afterSell = function()

        -- GameSDKs:Track("sell_car", {car_id = carId, star_num = StarMode:GetStar(), left_cash =  ResMgr:GetCash()})

        if carId == self:GetDrivingCar() then--刚好卖了座驾,随便找一俩已有的车
            local data = HouseMode:GetLocalData()
            if #data == 0 then--如果还没有车位..照理应该是没法卖车的
                self:GetDrivingCar(0)
                return
            end
    
            local replaceId = 0
            for k,v in ipairs(data or {}) do
                for i,cp in ipairs(v.cp or {}) do
                    if cp.car then
                        replaceId = cp.car
                        break
                    end
                end
            end
    
            self:GetDrivingCar(replaceId)
            if replaceId > 0 then
                Bus:GetCarEntity(replaceId)
            else
                Bus:DestroyCarEntity()
                --CompanyMode:ManagerOnSpecialBuilding("bid")
            end
        end
    end
    --  local ResMgr = GameTableDefine.ResourceManger
    --  local ChooseUI = GameTableDefine.ChooseUI
    local addCash = math.floor(cfg_carInfo.price * ConfigMgr.config_global.car_sell_price)
    --ChooseUI:EarnCash(addCash, afterSell)

    ResMgr:AddCash(addCash, nil, function()
        --K119 卖车不飞图标
        --EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
        --2024-8-20添加用于的钞票消耗增加埋点上传
        local type = 1
        local amount = addCash
        local change = 0
        local position = "卖车收入["..carId.."]"
        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
    end,
    true)
    afterSell()
    --LocalDataManager:WriteToFile()
end

function BuyCarManager:Buy(carId, shopId, check)
    local cfg_car = ConfigMgr.config_car[carId]
    local cfg_carshop = ConfigMgr.config_carshop[shopId]
    local cfg_carInfo = cfg_carshop.cars[carId]
    local houseCarPort, garageId = HouseMode:GetIdleCarPort()
    --还要检测车位是否足够
    if check then
        if not ResMgr:CheckCash(cfg_carInfo.price) then--钱不够
            return -1
        end

        if houseCarPort == nil or houseCarPort.car ~= nil then--车库位不够
            return -2
        end

        return 1
    end

    local buyCar = function(isEnough)
        local save = LocalDataManager:GetDataByKey(BUY_CAR)
        if not save["buy"] then
            save["buy"] = {}
        end
        local isFirstBuy = Tools:GetTableSize(save["buy"]) <= 0
        if isEnough then
            if not save["buy"]["" .. shopId] then
                save["buy"][""..shopId] = {}
            end

            local currShop = save["buy"][""..shopId]

            if not currShop[""..carId] then
                currShop[""..carId] = 0
            end
            
            currShop["".. carId] = currShop["".. carId] + 1
            ChatEventManager:ConditionToStart(4, carId)
            houseCarPort.car = carId
            houseCarPort.from = shopId

            ValueManager:GetValue(true)

            -- GameSDKs:Track("buy_car", {car_id = carId, star_num = StarMode:GetStar(), left_cash =  ResMgr:GetCash()})
            --LocalDataManager:WriteToFile()
            if isFirstBuy then
                GameSDKs:TrackControl("af", "af,assetbuy_firstcar", {})
            end
            GameSDKs:TrackForeign("asset_buy",{type = 2, id = carId, star_new = tonumber(StarMode:GetStar())})
             --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
             local type = GameTableDefine.CountryMode:GetCurrCountry()
             local amount = cfg_carInfo.price
             local change = 1
             local position = "["..carId.."]号车购买"
             GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
            --GameSDKs:TrackForeign("asset_buy",{
            --    type = 2,
            --    id = carId,
            --    star = GameTableDefine.StarMode:GetStar(),
            --    income = GameTableDefine.FloorMode:GetTotalRent(),
            --    perLevel = GameTableDefine.PersonalDevModel:GetTitle(),
            --    scene = GameTableDefine.CountryMode:GetMaxDevelopCountryBuildingID()
            --})
        end
    end

    ResMgr:SpendCash(cfg_carInfo.price, nil, buyCar)
end

function BuyCarManager:IsCarUnlock(carId, toUnlock)--现在好像没有解锁车的概念了..
    local cfg = ConfigMgr.config_car[carId]
    if not cfg.lock then
        return true
    end

    local save = LocalDataManager:GetDataByKey(BUY_CAR)
    if not save.carUnlock then
        save.carUnlock = {}
    end

    if toUnlock then
        save.carUnlock[""..carId] = true
        LocalDataManager:WriteToFile()
    end

    return save.carUnlock[""..carId] and true or false
end

function BuyCarManager:GetBoughtData(carId)
    local save = LocalDataManager:GetDataByKey(BUY_CAR)

    if not save["buy"] then
        save["buy"] = {}
    end

    if carId then
        return save["buy"]["".. carId] or 0
    end

    return save["buy"]
end

---@param changeId number 更换BOSS正在开的车为某ID的车
function BuyCarManager:GetDrivingCar(changeId)--用于上下班的车
    local save = LocalDataManager:GetDataByKey(BUY_CAR)

    if changeId then
        save.drivingCar = changeId > 0 and changeId or nil
        LocalDataManager:WriteToFile()
        EventManager:DispatchEvent(GameEventDefine.ChangeBossCar,changeId)
        Bus:GetCarEntity(save.drivingCar)
    end

    return save.drivingCar
end

function BuyCarManager:CanCarFly(carId)
    if not carId then
        carId = self:GetDrivingCar()
    end

    local data = ConfigMgr.config_car[carId] or {}
    return data.fly or false
end

---设为需要播放买新车返回动画
function BuyCarManager:SetNeedShowBuyCarBack(need)
    self.m_needShowBuyCarBack = need
end

---是否需要播放买新车返回动画
function BuyCarManager:GetNeedShowBuyCarBack()
    return self.m_needShowBuyCarBack
end