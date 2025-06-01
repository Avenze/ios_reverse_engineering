local CashEarn = GameTableDefine.CashEarn
local ResourceManger = GameTableDefine.ResourceManger
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local TimerMgr = GameTimeManager
local CountryMode = GameTableDefine.CountryMode
local EventManager = require("Framework.Event.Manager")
--管理赚钱,包括左上角每30秒加一次钱,以及伟大工程每120秒加一次钱

local EACH_SECOND = 30
local BANK_SECOND = 120
local ECPM_SECOND = 3--广告价值刷新时间
local createTime = nil
function CashEarn:Update()
    if LocalDataManager:IsNewPlayerRecord() then
        return
    end
    for k,v in pairs(ConfigMgr.config_country) do
        local countryId = v.id    
        local num = FloorMode:GetTotalRent(nil, countryId)
        --local pay = FloorMode:GetEmployeePay()--有些员工需要付钱
        local totalAdd = num --+ pay
        local currCash = ResourceManger:Get(ConfigMgr.config_money[v.id].resourceId)
        local isMax = false
        ---cash_event需要修改下添加逻辑
        local addResult = ResourceManger:AddLocalMoney(totalAdd, nil, nil, countryId)
        isMax = addResult ~= totalAdd
        if addResult ~= 0 then
            local type = countryId
            local amount = addResult
            local change = 0
            local position = "30秒现金收入"
            GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
        end
        if v.id == CountryMode:GetCurrCountry() and not GameStateManager:IsInstanceState() and not GameStateManager:IsCycleInstanceState() then
            EventManager:DispatchEvent("NOT_CASH_CHANGE", num, 0, currCash, isMax)
        end
    end
end

function CashEarn:UpdateBank()
    GreateBuildingMana:UpdateBankMoney()
end

function CashEarn:BankRefreshTime()
    return BANK_SECOND
end

function CashEarn:SendEcpmEvent()
    local ecpm = GameSDKs:GetTotalEcpm()
    if createTime == nil then
        local data = LocalDataManager:GetRootRecord()
        local time, data = next(data)
        createTime = time
    end

    local nowTime = TimerMgr:GetCurrentServerTime()
    local timePass = math.floor(nowTime - createTime)
    -- GameSDKs:Track("ltv,ecpm", {lifetime = tostring(timePass), value = tostring(ecpm)})
end

function CashEarn:Init()
    self.runTime = 0
    self.__timers = self.__timers or {}
    self.__timers[self] = GameTimer:CreateNewMilliSecTimer(
        EACH_SECOND * 1000,
        function()
            self:Update()
            --self:UpdateBank()
            --self.runTime = self.runTime + EACH_SECOND
            --GameSDKs:Track("GameRunTime", {time = 30})
        end,
        true)

    self.__timers["bank_cash"] = GameTimer:CreateNewMilliSecTimer(
        BANK_SECOND * 1000,
        function()
            self:UpdateBank()
        end,
        true)
    
    -- self.__timers["ecpm_time"] = GameTimer:CreateNewMilliSecTimer(
    --     ECPM_SECOND * 1000,
    --     function()
    --         self:SendEcpmEvent()
    --     end,
    --     true)
end