---@class ResourceManger
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local CfgMgr = GameTableDefine.ConfigMgr
local CountryMode = GameTableDefine.CountryMode
local EventManager = require("Framework.Event.Manager")
local ValueManager = GameTableDefine.ValueManager
local AES = CS.Common.Utils.AES
local UnityHelper = CS.Common.Utils.UnityHelper
local encryptTag = UnityHelper.GetMD5("HareRush")

local GameTimeManager = GameTimeManager
local LocalDataManager = LocalDataManager
local MainUI = GameTableDefine.MainUI
local GameStateManager = GameStateManager
local CityMode = GameTableDefine.CityMode

local record = nil
local RESOURCE_RECORD = "resource"

local STATEMENT = 1
local CASH = 2
local DIAMOND = 3
local TICKET = 4 --广告卷
local LICENSE = 5
local EURO = 6
local TOKEN = 7

local WHEEL_TICKET = 9 --转盘卷

local currCashMax = 0--0表示不设上限

local RES_TYPE = {
    [STATEMENT] = "statement",
    ---- resource type
    [CASH] = "cash",
    [DIAMOND] = "diamond",
    [TICKET] = "ticket",
    [LICENSE] ="license",
    [EURO] = "euro",
    [TOKEN] = "Token",
    [WHEEL_TICKET] = "Wheel_Ticket",
}

local ENCRYPT_RES_TYPE = {
    --[STATEMENT] = "statement",
    ---- resource type
    [RES_TYPE[CASH]] = true,
    [RES_TYPE[DIAMOND]] = true,
    --[TICKET] = "ticket",
    [RES_TYPE[LICENSE]] = true,
    [RES_TYPE[EURO]] = true,
    --[TOKEN] = "Token",
}

local RES_ICON = {
    [STATEMENT] = "",
    [CASH] = "icon_cash_001",
    [DIAMOND] = "icon_diamond_001",
    [TICKET] = "icon_shop_ticket",
    [LICENSE] ="icon_building_license",
    [EURO] = "icon_cash_002",
    [WHEEL_TICKET] = "icon_UI_wheel",
}

local STATEMENT_ENABLE = {
    [RES_TYPE[CASH]] = false,
    [RES_TYPE[DIAMOND]] = false,
    [RES_TYPE[TICKET]] = false,
    [RES_TYPE[WHEEL_TICKET]] = false
}
local STATEMENT_LIMIT = 1000

ResourceManger.EVENT_INIT = 1
ResourceManger.EVENT_BUY_BUILIDNG = 2
ResourceManger.EVENT_BUY_FURNITURE = 3
ResourceManger.EVENT_COLLECTION_DAILY_LEVEL_REWARDS = 4
ResourceManger.EVENT_COLLECTION_DAILY_REWARDS = 5
ResourceManger.EVENT_COLLECTION_AD_REWARDS = 6
ResourceManger.EVENT_BUY_TICKET = 7
ResourceManger.EVENT_USE_TICKET = 8
ResourceManger.EVENT_UNLOCK_ROOM = 9
ResourceManger.EVENT_CLAIM_EVENT001 = 10
ResourceManger.EVENT_QUEST_REWARD = 11
ResourceManger.EVENT_CLAIM_COMPANY_REWARD = 12
ResourceManger.EVENT_CLAIM_FOLLOW_FACEBOOK = 13
ResourceManger.EVENT_BUY_PASS_LEVEL = 14
ResourceManger.EVENT_UPGRADE_CEO_DESK = 15

local function Init()
    record = LocalDataManager:GetDataByKey(RESOURCE_RECORD)
    if record and Tools:GetTableSize(record) == Tools:GetTableSize(RES_TYPE) then
        return
    end

    if not record[RES_TYPE[CASH]] then
        ResourceManger:AddCash(ConfigMgr.config_global.initial_money, ResourceManger.EVENT_INIT)
    end

    if not record[RES_TYPE[DIAMOND]] then
        ResourceManger:AddDiamond(ConfigMgr.config_global.initial_diamond, ResourceManger.EVENT_INIT)
    end

    if not record[RES_TYPE[TICKET]] then
        ResourceManger:AddTicket(0, ResourceManger.EVENT_INIT)
    end

    if not record[RES_TYPE[LICENSE]] then
        ResourceManger:AddLicense(0, ResourceManger.EVENT_INIT)
    end

    if not record[RES_TYPE[EURO]] then
        ResourceManger:AddEUR(0, ResourceManger.EVENT_INIT)
    end

    if not record[RES_TYPE[WHEEL_TICKET]] then
        ResourceManger:AddWheelTicket(0, ResourceManger.EVENT_INIT)
    end
end

---唯一入口来读取存档中的数据，根据Type获取对应的值，加密的或者未加密的.
local function Get(type)
    if not record then
        Init()
    end
    --从AES加密数据中获取原始值
    local needEncrypt = ENCRYPT_RES_TYPE[type]
    if needEncrypt then
        local resValue = LocalDataManager:DecryptField(record,type)
        return resValue
    end
    --返回未加密的原始值
    return record[type] or 0
end

local function AddStatement(num, type, event)
    if not STATEMENT_ENABLE[type] then
        return
    end

    if not record[RES_TYPE[STATEMENT]] then
        record[RES_TYPE[STATEMENT]] = {}
    end
    if not record[RES_TYPE[STATEMENT]][type] then
        record[RES_TYPE[STATEMENT]][type] = {}
    end

    if #record[RES_TYPE[STATEMENT]][type] >= STATEMENT_LIMIT then
        table.remove(record[RES_TYPE[STATEMENT]][type], 1)
    end
    table.insert(record[RES_TYPE[STATEMENT]][type], {
             time = GameTimeManager:GetCurrentServerTime(),
             event = event,
             num = num,
             balance = Get(type)
            })
end

---保存数据的统一接口，会对关键数据进行加密
local function Save(num, type, event, cb, refreshLater)
    if not record then
        Init()
    end
    if num and type then
        local curValue = Get(type)
        if curValue + num < 0 then
            if cb then cb(false) end
            return
        end

        if type == "diamond" then
            -- 排行榜作弊检查
            --  1. 当前持有总钻石量>50万，视为作弊用户
            --  2. 单次钻石变化量>6万，视为作弊用户
            local cycleIsActive = GameTableDefine.CycleInstanceDataManager:GetInstanceIsActive()
            if cycleIsActive then
                local cycleModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
                if cycleModel then
                    local rankManagerClass = cycleModel:GetRankManager()
                    if rankManagerClass then
                        rankManagerClass:CheatCheck(curValue, num)
                    end
                end
            end
        end

        curValue = curValue+num
        local needEncrypt = ENCRYPT_RES_TYPE[type]
        if needEncrypt then
            LocalDataManager:EncryptField(record,type,curValue)
            record[type] = 0 --丢掉未加密原有值,防止删除字段从原字段恢复数据
        else
            record[type] = curValue
        end
        --2024-8-20增加用户属性埋点
        -- [CASH] = "cash",
        -- [DIAMOND] = "diamond",
        -- [TICKET] = "ticket",
        -- [LICENSE] ="license",
        -- [EURO] = "euro",
        -- [TOKEN] = "Token",
        -- [WHEEL_TICKET] = "Wheel_Ticket",
        if type == "cash" then
            GameSDKs:SetUserAttrToWarrior({ob_cash1_num = curValue})
        end
        if type == "diamond" then
            if num < 0 then
                --2024-12-24通行证任务模块调用花费钻石
                GameTableDefine.SeasonPassTaskManager:GetWeekTaskProgress(1, math.abs(num))
                --2025-2-7 添加CEO钻石消耗计数
                GameTableDefine.CEODataManager:SpendDiamondCount(math.abs(num))
                GameSDKs:SetUserAttrToWarrior({ob_diamond_num = curValue})
            end
        end
        if type == "euro" then
            GameSDKs:SetUserAttrToWarrior({ob_cash2_num = curValue})
        end
    end
    if event then
        AddStatement(num, type, event)
    end
    if cb then cb(true) end
    LocalDataManager:WriteToFile()
    if not (event == ResourceManger.EVENT_INIT) and not refreshLater and not GameStateManager:IsInstanceState() then
        MainUI:UpdateResourceUI()
    end
    return true
    --show effect
end

local function Add(num, type, event, cb, refreshLater)
    if tonumber(num) and type then
        num = math.abs(num)
        return Save(num, type, event, cb, refreshLater)
    end
end

local function Spend(num, type, event, cb)
    if tonumber(num) and type then
        num = -math.abs(num)
        return Save(num, type, event, cb)
    end
end

local function CheckResEnough(type, num)
    if not tonumber(num) or num < 0 then
        return
    end
    local curNum = Get(type)
    return curNum >= num
end

---public
function ResourceManger:ClearData()
    record = nil
end
function ResourceManger:GetResType(type)
    if not type then
        return RES_TYPE
    end
    return RES_TYPE[type]
end
function ResourceManger:GetResIcon(type)
    return RES_ICON[type]
end

function ResourceManger:GetShopCashType(type)
    if not type or type == 0 then
        if CityMode:CheckBuildingSatisfy(700) then
            return RES_TYPE[EURO]
        else
            return RES_TYPE[CASH]
        end
    elseif type == 3 then
        if CityMode:CheckBuildingSatisfy(700) then
            return RES_TYPE[EURO]
        else
            return RES_TYPE[CASH]
        end
    elseif type == 1 then
        return RES_TYPE[CASH]
    elseif type == 2 then
        return RES_TYPE[EURO]
    end
end

function ResourceManger:GetShopCashIcon(resType,cfgIcon)
    if resType == RES_TYPE[CASH] then
        return cfgIcon
    else
        return cfgIcon.."_euro"
    end
end

--
function ResourceManger:Get(type)
    return Get(RES_TYPE[type])
end

function ResourceManger:Add(type, num, event, cb, refreshLater)
    Add(num, RES_TYPE[type], event, cb, refreshLater)
end

function ResourceManger:Spend(type, num, event, cb)
    Spend(num, RES_TYPE[type], event, cb)
end

function ResourceManger:CheckEnough(type, num)
    return CheckResEnough(RES_TYPE[type], num)
end

--
function ResourceManger:SetCashMax(num)
    if num then
        currCashMax = num
        MainUI:RefreshCashEarn()
    else
        currCashMax = 0
    end
end

function ResourceManger:GetCash()
    return Get(RES_TYPE[CASH])
end
--只能检查绿钞--基本不用了
--function ResourceManger:CashMax(num)
--    if tonumber(num) and num > 0 then
--        local curr = self:GetCash()
--        if curr and currCashMax ~= 0 and curr + num >= currCashMax then
--            return true, math.floor(currCashMax - curr)
--        end
--        return false, num
--    end
--
--    return false,0
--end

--默认检测当前的钱满了没
function ResourceManger:CashCurrMax(num, countryId)
    if tonumber(num) and num > 0 then
        if not countryId then
            countryId = CountryMode:GetCurrCountry() or 1
        end
        local lv = LocalDataManager:GetDataByKey("bank")
        lv = lv["lv" .. CountryMode.SAVE_KEY[countryId]]
        local limit = CfgMgr.config_bank[lv][ValueManager.limitKey[countryId]]
        local resourceId = CfgMgr.config_money[countryId].resourceId
        local curr = Get(RES_TYPE[resourceId])
        if curr >= limit then
       
            return true , 0             --满了
        else
            if curr + num >= limit then --加了才满
                return true ,  limit - curr
            end
                                                                                
            return false , num          --没满
        end
    end    
end


function ResourceManger:AddCash(num, event, cb, refreshLater, beyondMax)
    local curr = self:GetCash()
    if curr and not beyondMax then--没初始化时没有curr
        local max,toAdd = self:CashCurrMax(num)
        if max then
            if toAdd > 0 then
                Add(toAdd, RES_TYPE[CASH], event, cb, refreshLater)
                EventManager:DispatchEvent("CASH_MAX")
            else
                if cb then cb(true) end
                LocalDataManager:WriteToFile()
            end

            return toAdd
        end
    end
    Add(num, RES_TYPE[CASH], event, cb, refreshLater)
    return num
end

function ResourceManger:SpendCash(num, event, cb)
    Spend(num, RES_TYPE[CASH], event, cb)
    EventManager:DispatchEvent("CASH_SPEND")
end

function ResourceManger:CheckCash(num)
    return CheckResEnough(RES_TYPE[CASH], num)
end

--
function ResourceManger:GetDiamond()
    return Get(RES_TYPE[DIAMOND])
end

function ResourceManger:AddDiamond(num, event, cb, refreshLater)
    Add(num, RES_TYPE[DIAMOND], event, cb, refreshLater)
end

function ResourceManger:SpendDiamond(num, event, cb)
    Spend(num, RES_TYPE[DIAMOND], event, cb)
end

function ResourceManger:CheckDiamond(num)
    return CheckResEnough(RES_TYPE[DIAMOND], num)
end

--
function ResourceManger:GetTicket()
    return Get(RES_TYPE[TICKET])
end

function ResourceManger:AddTicket(num, event, cb)
    if GameTableDefine.ShopManager:IsNoAD() then
        --转换成钻石
        local diamond = num * 30
        self:AddDiamond(diamond, event, cb)
    else
        Add(num, RES_TYPE[TICKET], event, cb)
    end
end

function ResourceManger:SpendTicket(num, event, cb)
    Spend(num, RES_TYPE[TICKET], event, cb)
end

function ResourceManger:CheckTicket(num)
    return CheckResEnough(RES_TYPE[TICKET], num)
end

function ResourceManger:GetEuro()
    return Get(RES_TYPE[EURO])
end

function ResourceManger:AddEuro(num, event, cb)
    Add(num, RES_TYPE[EURO], event, cb)
end

function ResourceManger:SpendEuro(num, event, cb)
    Spend(num, RES_TYPE[EURO], event, cb)
end

function ResourceManger:CheckEuro(num)
    return CheckResEnough(RES_TYPE[EURO], num)
end

function ResourceManger:SpendMultiple(data, event, cb)
    if not self:CheckMultiple(data) then
        cb(false)
        return
    end
    for i,v in ipairs(data or {}) do
        local c = i == #data and cb or nil
        Spend(v.num, RES_TYPE[v.type], event, c)
    end
end

function ResourceManger:CheckMultiple(data)
    for i, v in ipairs(data or {}) do
        local isEnough = CheckResEnough(RES_TYPE[v.type], v.num)
        if not isEnough then
            return false
        end
    end
    return true
end

function ResourceManger:GetLicense()
    return Get(RES_TYPE[LICENSE])
end

function ResourceManger:AddLicense(num, event, cb)
    Add(num, RES_TYPE[LICENSE], event, cb)
end

function ResourceManger:SpendLicense(num, event, cb)
    Spend(num, RES_TYPE[LICENSE], event, cb)
    EventManager:DispatchEvent("LICENSE_SPEND")
end

function ResourceManger:GetEUR()
    return Get(RES_TYPE[EURO])
end

function ResourceManger:AddEUR(num, event, cb)
    Add(num, RES_TYPE[EURO], event, cb)
end

function ResourceManger:SpendEUR(num, event, cb)
    Spend(num, RES_TYPE[EURO], event, cb) 
    EventManager:DispatchEvent("EUR_SPEND")
end

--获取当前地区的钱
function ResourceManger:GetLocalMoney()    
    local currCountry = CountryMode:GetCurrCountry()
    local resourceId = CfgMgr.config_money[currCountry].resourceId 
    return Get(RES_TYPE[resourceId])
end
--增加当前地区的钱
function ResourceManger:AddLocalMoney(num, event, cb, countryId, refreshLater, beyondMax)
    -- local currCountry = CountryMode:GetCurrCountry() 
    -- local resourceId = CfgMgr.config_money[currCountry].resourceId
    -- Add(num, RES_TYPE[resourceId], event, cb)
    
    if not countryId or countryId == 0 then
        countryId = CountryMode:GetCurrCountry() or 1
    end
    if countryId == 3 then
        countryId = CityMode:CheckBuildingSatisfy(700) and 2 or 1
    end
    local lv = LocalDataManager:GetDataByKey("bank")
    lv = lv["lv" .. CountryMode.SAVE_KEY[countryId]]
    local limit = CfgMgr.config_bank[lv][ValueManager.limitKey[countryId]]
    local resourceId = CfgMgr.config_money[countryId].resourceId
    local curr = Get(RES_TYPE[resourceId])
    local reAdd = 0
    if not limit then
        return
    end
    if not beyondMax then
        if curr >= limit then           --已经满了
            if countryId == CountryMode:GetCurrCountry() then
                EventManager:DispatchEvent("CASH_MAX")
            end
        else
            if curr + num >= limit then --加了才满
                reAdd = limit - curr
                if countryId == CountryMode:GetCurrCountry() then
                    EventManager:DispatchEvent("CASH_MAX")
                end
            else
                reAdd = num   --没满
            end                                                                    
        end
    else
        reAdd = num                    --不管上限
    end
    
    Add(reAdd, RES_TYPE[resourceId], event, cb, refreshLater)
    return reAdd
end

--检查当前地区的钱
function ResourceManger:CheckLocalMoney(num)    
    local localMoney = self:GetLocalMoney()
    return localMoney >= num 
end

--花费当前地区的钱
function ResourceManger:SpendLocalMoney(num, event, cb , countryId)
    if not countryId then
        countryId = CountryMode:GetCurrCountry() 
    end    
    local resourceId = CfgMgr.config_money[countryId].resourceId
    Spend(num, RES_TYPE[resourceId], event, cb)
    EventManager:DispatchEvent("CASH_SPEND")
end

--region:转盘卷
function ResourceManger:GetWheelTicket()
    return Get(RES_TYPE[WHEEL_TICKET])
end

function ResourceManger:AddWheelTicket(num, event, cb)
    Add(num, RES_TYPE[WHEEL_TICKET], event, cb)
end

function ResourceManger:SpendWheelTicket(num, event, cb)
    Spend(num, RES_TYPE[WHEEL_TICKET], event, cb)
end

function ResourceManger:CheckWheelTicket(num)
    return CheckResEnough(RES_TYPE[WHEEL_TICKET], num)
end