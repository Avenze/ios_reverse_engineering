local ExchangeUI = GameTableDefine.ExchangeUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ResMgr = GameTableDefine.ResourceManger

function ExchangeUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EXCHANGE_UI, self.m_view, require("GamePlay.City.UI.ExchangeUIView"), self, self.CloseView)
    return self.m_view
end

function ExchangeUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EXCHANGE_UI)
    self.m_view = nil
    collectgarbage("collect")
end


--计算能换多少钱                        --消耗那种钱  --获得那种钱  --消耗总量的多少的百分比
function ExchangeUI:CalculateExchangeCurrency(spendMoney, addMoney, poportion)
    local moneyCfg = ConfigMgr.config_money     
    local spendNum = math.floor(ResMgr:Get(moneyCfg[spendMoney].resourceId) * poportion)
    if spendMoney == addMoney then
        return math.floor(ResMgr:Get(moneyCfg[spendMoney].resourceId) * (1- poportion)) , spendNum
    end
    local addNum = math.floor(self:CurrencyExchange(spendMoney, addMoney, spendNum))
    return math.floor(ResMgr:Get(moneyCfg[spendMoney].resourceId) * (1- poportion)) , addNum
end

--货币兑换                           --消耗那种钱  --获得那种钱  --消耗多少
function ExchangeUI:CurrencyExchange(spendMoney, addMoney, spendNum)
    local moneyCfg = ConfigMgr.config_money
    local addNum
    addNum = self:CurrencyProportion(spendMoney, addMoney, spendNum) * spendNum
    return addNum
end


--计算兑换汇率
function ExchangeUI:CurrencyProportion(spendMoney, addMoney, spendNum)
    local moneyCfg = ConfigMgr.config_money
    local exchangeData = LocalDataManager:GetDataByKey("exchangeMoney")
    
    if not exchangeData[tostring(moneyCfg[spendMoney].resourceId)] then
        exchangeData[tostring(moneyCfg[spendMoney].resourceId)] = 0
    end
    if not exchangeData[tostring(moneyCfg[addMoney].resourceId)] then
        exchangeData[tostring(moneyCfg[addMoney].resourceId)] = 0
    end
    LocalDataManager:WriteToFile()
    local spendECM = exchangeData[tostring(moneyCfg[spendMoney].resourceId)] -- 花费的钱曾经 被兑换 的量
    local addECM = exchangeData[tostring(moneyCfg[addMoney].resourceId)]

    local proportion
    proportion = ((moneyCfg[addMoney].proportion / moneyCfg[spendMoney].proportion))
    proportion = proportion / (((spendECM + spendNum)/moneyCfg[spendMoney].base + 1))
    return proportion
end

--将 resourceId 转换为 id
function ExchangeUI:SwitchCurrencyId(id)
    local moneyCfg = ConfigMgr.config_money
    for k,v in pairs(moneyCfg) do
        if v.resourceId == id then
            return v.id
        end
    end
    return
end

--获取所有的钱的总数
function ExchangeUI:GetAllCashNum()
    local moneyCfg = ConfigMgr.config_money
    local allCash = 0
    for k,v in pairs(moneyCfg) do
        allCash =  allCash + ResMgr:Get(v.resourceId)
    end
    return allCash
end

--增加累计值()
function ExchangeUI:AddCumulativeValue(resourceId ,spendNum)
    local cfg = ConfigMgr.config_money[self:SwitchCurrencyId(resourceId)]
    local exchangeData = LocalDataManager:GetDataByKey("exchangeMoney")
    if not exchangeData[tostring(resourceId)] then
        exchangeData[tostring(resourceId)] = 0    
    end
    if exchangeData[tostring(resourceId)] + spendNum >= cfg.max then
        exchangeData[tostring(resourceId)] = cfg.max 
        LocalDataManager:WriteToFile()
        return
    end
    exchangeData[tostring(resourceId)] = exchangeData[tostring(resourceId)] + spendNum
    LocalDataManager:WriteToFile()
end

--减少累计值()
function ExchangeUI:SpendCumulativeValue(resourceId ,addNum)
    local exchangeData = LocalDataManager:GetDataByKey("exchangeMoney")
    if not exchangeData[tostring(resourceId)] then
        exchangeData[tostring(resourceId)] = 0    
    end
    if exchangeData[tostring(resourceId)] - addNum <= 0 then
        exchangeData[tostring(resourceId)] = 0
        LocalDataManager:WriteToFile()
        return
    end
    exchangeData[tostring(resourceId)] = exchangeData[tostring(resourceId)] - addNum
    LocalDataManager:WriteToFile()
end
--互斥需求获取钱Id
function ExchangeUI:MutexId(num)
    for k,v in pairs(ConfigMgr.config_money) do
        if num ~= v.id  then
            return v.id
        end
    end 
    return 1
end