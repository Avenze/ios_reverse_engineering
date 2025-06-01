---@class WarriorIAP
local IAP = GameTableDefine.IAP

local CfgMgr = GameTableDefine.ConfigMgr
local DeviceUtil = CS.Game.Plat.DeviceUtil
local DeviceInfo = CS.Game.Plat.DeviceInfo
local GameSDKMgr = CS.Game.SDK.SDKManager.Instance
local ProductType = CS.UnityEngine.Purchasing.ProductType

local Shop = GameTableDefine.Shop
local ConfigMgr = GameTableDefine.ConfigMgr

local rapidjson = require("rapidjson")
local EventManager = require("Framework.Event.Manager")
local UnityHelper = CS.Common.Utils.UnityHelper
local m_currentWarriorOrder

local IAP_RECORD = "warrior_order"

local WARRIOR_STATE_CREATED         = 0
local WARRIOR_STATE_PAY             = 1
local WARRIOR_STATE_AWARD           = 2
local WARRIOR_STATE_COMPLE          = 3

local ChooseUI = GameTableDefine.ChooseUI

function IAP:ctor()
    self.m_productPrice = {} ---@type table<string,string> SDK返回的商品价格,带符号
    self.m_productRoublePricePureNum = {} ---@type table<string,string> SDK返回的商品价格,纯数字 暂时安卓才有
    self.m_productPriceUS = {} ---@type table<string,number> 本地IAP配置表中读取的值,存数字
end

function IAP:Init()
    print("warrioriap -- > init")
    m_currentWarriorOrder = nil
    if self.m_productPrice or not GameDeviceManager:IsIAPVersion() then
        print("不是iap,直接返回,不拉去信息结果了")
        return
    end

    self.m_productPrice = {}
    self.m_productRoublePricePureNum = {}
    self.m_productRoublePriceNum = {}
    self.m_productList, self.m_productPriceUS, self.m_productToIAPCfg = self:GetPurchaseList()
    self.m_productData = self:GetPurchaseData()
    self.m_CountryCode = self:GetCountryCode()
    if not ConfigMgr.config_iap_country[self.m_CountryCode] then
        self.m_CountryCode = "US"
    end
    self:SetProductToShopId()
    print("请求商品信息表单 " .. self.m_productData)
    -- DeviceUtil.RequestProductData(self.m_productList, self.m_productType, self.m_productData)
    if UnityHelper.IsRuassionVersion() then
        self:RefreshRuassionIAPInfo()
    else
        DeviceUtil.InvokeNativeMethod("pullProductInfoList", self.m_productData)
    end
end

function IAP:GetOrder()
    self.m_warriorOrder = LocalDataManager:GetDataByKey("warrior_order") -- pid, state
end

function IAP:GetPriceDouble(id)
    local pid = Shop:GetShopItemPurchaseID(id)
    -- Tools:DumpTable(self.m_productPrice, "m_productPrice")
    return IAP:GetPriceDoubleByPurchaseId(pid)
end

function IAP:GetPriceDoubleByPurchaseId(pid)
    -- if GameDeviceManager:IsiOSDevice() then
    --     if self.m_productPrice[pid.."_number"] then
    --         return self.m_productPrice[pid.."_number"]
    --     end
    -- end
    
    local currencyWithSymbol = IAP:GetPrice(pid)
    if GameDeviceManager:IsiOSDevice() then
        if not string.find(currencyWithSymbol, "load") then
            currencyWithSymbol = string.gsub(currencyWithSymbol, "%.00", "")
        end
    end
    -- local firstPos, endPos = string.find(currencyWithSymbol or "", "%d+%.%d+")
    -- local comma = "."
    -- if not firstPos then
    --     comma = ","
    --     firstPos, endPos = string.find(currencyWithSymbol or "", "%d+%,%d+")
    -- end
    -- if not firstPos then
    --     return "0"
    -- end
    --local price = string.sub(currencyWithSymbol, firstPos, endPos) or "0"
    -- local priceFormat = price
    -- if comma == "," then
    --     price = string.gsub(price, ',', '.')
    -- end
    -- return price, priceFormat, comma
    local price = currencyWithSymbol
    local priceFormat = currencyWithSymbol
    if GameDeviceManager:IsiOSDevice() then
        if self.m_productPrice[pid.."_number"] then
            priceFormat = self.m_productPrice[pid.."_number"]
        else
            priceFormat = currencyWithSymbol == "loading..." and currencyWithSymbol and "loading..." or string.match(currencyWithSymbol,"%d+%.?%d*") or "loading..."
            return priceFormat
        end
    elseif GameDeviceManager:IsAndroidDevice() then
        priceFormat = string.gsub(currencyWithSymbol,"%p","")   --去掉符号
    end
    priceFormat =  string.gsub(priceFormat,"%a","")             --去掉字母
    priceFormat =  string.gsub(priceFormat," ","")              --去掉空格
    local startIndex, endIndex = string.find(priceFormat,"%d+")
    if not startIndex then
        return "0"
    end
    priceFormat = string.sub(priceFormat, startIndex, endIndex)
    local comma = nil
    local numPart = string.gsub(currencyWithSymbol, "%a", "")
    numPart = string.gsub(numPart," ","")
    local startIndex2, endIndex2 = string.find(numPart, "%d")
    if startIndex2 and endIndex2 and endIndex2 > 1 then   --数字前有"$", "¥"等特殊符号就去掉
        numPart = string.sub(numPart, startIndex2)
    -- else
    --     GameSDKs:TrackForeign("ios_price_error", {iap = tostring(pid) or "None_iap", err_content = tostring(currencyWithSymbol)  or "None_Con"})
    end
    -- if UnityHelper.IsRuassionVersion() and tonumber(priceFormat) and tonumber(priceFormat) >= 1000 then
    --     numPart = Tools:SeparateNumberWithComma(tonumber(priceFormat))
    -- end
    for i = 1, #numPart do
        local tempPoint = string.sub(numPart,i,i)
        if tempPoint == "." or tempPoint == "," then
            if comma == nil then
                comma = {}
            end
            comma[i] = tempPoint
        end
    end
    if GameDeviceManager:IsiOSDevice() then
        if self.m_productPrice[pid.."_number"] then
            priceFormat = self.m_productPrice[pid.."_number"]
        end
    end
    return price, priceFormat, comma
end

function IAP:GetPriceCode()
    return "USD"
end

function IAP:SetPrice(data)
    if UnityHelper.IsRuassionVersion() then
        return
    end
    for k, key in pairs(self.m_productList) do
        --K119 SDK给的价格结构变更 TODO 有点乱  可以统一一下
        local dataOfKey = data[key]
        local typeOfData = type(dataOfKey)
        local priceString = nil
        local priceNumber = nil
        if typeOfData == "table" then
            --安卓
            priceString = dataOfKey.formattedPrice
            priceNumber = dataOfKey.numberPrice
        elseif typeOfData == "string" then
            --IOS
            priceString = dataOfKey
        end
        self.m_productPrice[key] = priceString
        --如果传了数字,那就记录这个数字,IOS才会传
        local doubleKey = key.."_number"
        if data[doubleKey] then
            self.m_productPrice[doubleKey] = data[doubleKey]
            priceNumber = data[doubleKey]
        end
        self.m_productRoublePricePureNum[key] = priceNumber
    end
end

function IAP:GetPrice(purchaseID, isNumber)
    if purchaseID == nil then
        return "loading..."
    end
    print("Lua Get Price WarriorIAP:GetPrice[11111]"..purchaseID)
    if self.m_productPrice and self.m_productPrice[purchaseID] then
        print("Lua Get Price WarriorIAP:GetPrice[222222]"..purchaseID)
        local num = self.m_productPrice[purchaseID]
        print("Lua Get Price WarriorIAP:GetPrice[33333]"..purchaseID.." num:"..num)
        if isNumber then
            num = self.m_productPriceUS[purchaseID] or 0
        end
        print("Lua Get Price WarriorIAP:GetPrice[5555555]"..purchaseID.." num:"..num)
        return num
    end
    print("Lua Get Price WarriorIAP:GetPrice[555555]"..purchaseID)
    return "loading..."
end

--[[
    @desc: 获取卢布价格
    author:{author}
    time:2023-10-30 17:50:32
    --@purchaseID:
	--@isNumber: 
    @return:number
]]
function IAP:GetRoublePrice(purchaseID)
    if self.m_productRoublePriceNum and self.m_productRoublePriceNum[purchaseID] then
        return self.m_productRoublePriceNum[purchaseID]
    end
    return 0
end

function IAP:GetSerialId(productId)
    if self.m_sarialData and self.m_sarialData[productId] then
        return self.m_sarialData[productId]
    end

    return "loading..."
end

function IAP:Close()
    self.storeObject = nil
end

function IAP:Buy(id, param, buyItemInfo)
    local buyExtraData = rapidjson.encode(buyItemInfo)
    if UnityHelper.IsRuassionVersion() then
        --俄区sdk新增了一个支付参数需要上报用户的全局属性
        local newCommonProp = GameSDKs:GetTrackPlayerCommonAttr(false)
        local commonPropJson = nil
        if newCommonProp and type(newCommonProp) == "table" and Tools:GetTableSize(newCommonProp) > 0 then
            commonPropJson = rapidjson.encode(newCommonProp)
        end
        if not commonPropJson then
            commonPropJson = rapidjson.encode({})
        end
        --第一个是卢布价格，第二个是美金价格 
        DeviceUtil.InvokeNativeMethod("purchase", id, tostring( self:GetRoublePrice(id)), self:GetPrice(id, true), self:GetCurrencyCody(), "", param or "", buyExtraData, commonPropJson)
    else
        --2024-6-4 WarriorSDK修改全球定价需要修改的内容fengyu
        -- DeviceUtil.InvokeNativeMethod("purchase", id, self:GetPrice(id, true), "")
        if self.m_productRoublePricePureNum[id] then
            if GameDeviceManager:IsiOSDevice() then
                DeviceUtil.InvokeNativeMethod("purchase", id, tostring(self.m_productRoublePricePureNum[id]), "", param or "", buyExtraData)
            else
                DeviceUtil.InvokeNativeMethod("purchase", id, self.m_productRoublePricePureNum[id], "", param or "", buyExtraData)
            end
        else
            --2024-11-21 因为阿拉伯地区的IOS价格返回异常可能会导致拉不起订单，所以拉起订单这里异常了要用配置的美元去拉起订单了
            if GameDeviceManager:IsiOSDevice() then
                DeviceUtil.InvokeNativeMethod("purchase", id, tostring(self:GetPrice(id, true)) or 0, "", param or "", buyExtraData)
            end
        end
        
    end
    
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
end

function IAP:GetPurchaseList()
    local productList = {}
    local productPriceUS = {}
    local productToIAP = {}
    for k, v in pairs(CfgMgr.config_iap or {}) do
        local purchaseID = v[GameDeviceManager:GetAppBundleIdentifier()]
        if purchaseID then
            table.insert(productList, purchaseID)
            productToIAP[purchaseID] = v
            -- table.insert(productType,  v.not_consumption and ProductType.NonConsumable or ProductType.Consumable)
            if v.price_en[2] == nil then
                productPriceUS[purchaseID] = tostring(v.price_en[2])
            end
            productPriceUS[purchaseID] = tostring(v.price_en[2])
        end
    end
    return productList, productPriceUS, productToIAP
end

function IAP:GetPurchaseData()
    local data = {}
    local currPurchaseId = nil
    local identifier = GameDeviceManager:GetAppBundleIdentifier()
    if GameDeviceManager:IsiOSDevice() then
        for k, v in pairs(CfgMgr.config_iap or {}) do
            table.insert(data, v[identifier])
        end
    else
        for k, v in pairs(CfgMgr.config_iap or {}) do
            currPurchaseId = v[identifier]
            data[v.item_name] = currPurchaseId
        end
    end
    local json = ""
    if data and type(data) == "table" and Tools:GetTableSize(data) > 0 then
        json = rapidjson.encode(data)
    end
    return json
end

function IAP:GetPurchaseId(configId)
    local cfg = CfgMgr.config_iap[configId]
    if cfg then
        return cfg[GameDeviceManager:GetAppBundleIdentifier()]
    end
end

function IAP:PurchaseFailed(product, error)
    print("PurchaseFailed", error)
    local errorStr = Tools:FormatString(GameTextLoader:ReadText("TXT_TIP_PURCHASE_FAIL"), error)
    -- ChooseUI:CommonChoose(errorStr)
    --TODO：新增判断2024-9-2提示玩家有订单没有完成，进入丢单补单流程,调用主界面的补单获取流程进行
    if error == "query" then
        --请求一次刷新补单
        DeviceUtil.InvokeNativeMethod("queryOrder", "1")
    end
    GameSDKs:TrackForeign("error_event", {error_pos = "1", error_msg = errorStr})
    Shop:BuyFailed(product)
end

function IAP:PurchaseResult(data)
    Tools:DumpTable(data, "PurchaseResult")
    GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)
    if data.fs_iap_buy_product_successful then
        Shop:BuySuccess(data.productId)
        local cycleIsActive = GameTableDefine.CycleInstanceDataManager:GetInstanceIsActive()
        if cycleIsActive then
            local cycleModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
            if cycleModel then
                local rankManagerClass = cycleModel:GetRankManager()
                if rankManagerClass then
                    rankManagerClass:ReportRank()
                end
            end
        end

        self.m_warriorOrder[data.productId] = (self.m_warriorOrder[data.productId] or 0) + 1
        LocalDataManager:WriteToFile()
        LocalDataManager:UpdateLoadLocalData()
    elseif data.failMsg then
        IAP:PurchaseFailed(data.productId, data.failMsg)
        
    end
end

--废弃
function IAP:CreateOrder(id)
    local data = LocalDataManager:GetDataByKey("user_data")
	local requestTable = {
		url = GameNetwork.CREATE_ORDER_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
			userId = GameSDKs:GetThirdAccountInfo(),
			appId = GameNetwork.HEADR["X-WRE-APP-ID"],
			amount = self:GetPrice(id, true),
            productId = id,
		},
		callback = function(response)
            if response.data and response.data.serialId then
                m_currentWarriorOrder = response.data.serialId 
                print("--------> IAP CreateOrder", id, self:GetPrice(id, true), m_currentWarriorOrder)
                self.m_warriorOrder[m_currentWarriorOrder] = {pid = id, status = WARRIOR_STATE_CREATED}
                DeviceUtil.InvokeNativeMethod("purchase", id, self:GetPrice(id, true), m_currentWarriorOrder)
                LocalDataManager:WriteToFile()
                if GameDeviceManager:IsiOSDevice() then
                    GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
                end
            end
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
end

--废弃
function IAP:CheckOrder(productId, signature, original)
    print("--------> IAP CheckOrder ordier id", m_currentWarriorOrder)
    print("--------> IAP CheckOrder signature", signature)
    print("--------> IAP CheckOrder original", original)
    if not m_currentWarriorOrder then
        return
    end
    local data = LocalDataManager:GetDataByKey("user_data")
	local requestTable = {
		url = GameNetwork.CHECK_ORDER_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
			serialId = m_currentWarriorOrder,--,
			dataJson = original, --rapidjson.encode(original),
			sign = signature,
		},
		callback = function(response)
            if response.data and response.data.state == 1 then
                local shopId = self:ShopIdFromProductId(productId)
                GameSDKs:TrackForeign("purchase", {product_id = productId, price = Shop:GetShopItemPrice(shopId, true), state = 3})

                Shop:BuySuccess(productId)
                self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_AWARD
                self.m_warriorOrder[m_currentWarriorOrder].signature = nil
                self.m_warriorOrder[m_currentWarriorOrder].original = nil
                LocalDataManager:UpdateLoadLocalData()
                LocalDataManager:WriteToFile()
                self:CostOrder()
            else
                if self.m_warriorOrder[m_currentWarriorOrder] then
                    self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_COMPLE
                    self.m_warriorOrder[m_currentWarriorOrder].signature = nil
                    self.m_warriorOrder[m_currentWarriorOrder].original = nil
                    LocalDataManager:WriteToFile()
                end
                Shop:BuyFailed(productId)
            end
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
    self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_PAY
    self.m_warriorOrder[m_currentWarriorOrder].signature = signature
    self.m_warriorOrder[m_currentWarriorOrder].original = original
    LocalDataManager:WriteToFile()
end

--废弃
function IAP:CheckOrderIOS(productId, receipt, transactionId, serialId)
    print("--------> IAP CheckOrder ordier id", m_currentWarriorOrder)
    print("--------> IAP CheckOrder receipt", receipt)
    print("--------> IAP CheckOrder transactionId", transactionId)
    print("--------> IAP CheckOrder serialId", serialId)
    if not m_currentWarriorOrder then
        return
    end
    local data = LocalDataManager:GetDataByKey("user_data")
	local requestTable = {
		url = GameNetwork.CHECK_ORDER_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
			transactionId = transactionId,
			payload = receipt,
			serialId = serialId,
		},
		callback = function(response)
            if response.data and response.data.state == 1 then
                local shopId = self:ShopIdFromProductId(productId)
                GameSDKs:TrackForeign("purchase", {product_id = productId, price = Shop:GetShopItemPrice(shopId, true), state = 3})

                Shop:BuySuccess(productId)
                self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_AWARD
                self.m_warriorOrder[m_currentWarriorOrder].payload = nil
                self.m_warriorOrder[m_currentWarriorOrder].transactionId = nil
                LocalDataManager:UpdateLoadLocalData()
                LocalDataManager:WriteToFile()
                self:CostOrder()
            else
                if self.m_warriorOrder[m_currentWarriorOrder] then
                    self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_COMPLE
                    self.m_warriorOrder[m_currentWarriorOrder].payload = nil
                    self.m_warriorOrder[m_currentWarriorOrder].transactionId = nil
                    LocalDataManager:WriteToFile()
                end
                Shop:BuyFailed(productId)
            end
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
    self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_PAY
    self.m_warriorOrder[m_currentWarriorOrder].payload = receipt
    self.m_warriorOrder[m_currentWarriorOrder].transactionId = transactionId
    LocalDataManager:WriteToFile()
end

--废弃
function IAP:CostOrder()
    print("--------> IAP CostOrder ordier id", m_currentWarriorOrder)
    if not m_currentWarriorOrder then
        return
    end
    local data = LocalDataManager:GetDataByKey("user_data")
    local requestTable = {
		url = GameNetwork.COST_ORDER_URL,
        -- isLoading = true,
        fullMsgTalbe = true,
		msg = {
			serialId = m_currentWarriorOrder,
		},
		callback = function(response)
            if response.data and response.data.state == 1 then
                if self.m_unfinishedTransactions then
                    self.m_unfinishedTransactions[m_currentWarriorOrder] = nil
                end
                self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_COMPLE
                m_currentWarriorOrder = nil
                LocalDataManager:WriteToFile()
                print("--------> IAP CostOrder complete")
                self:CheckUnfinishedTransactions()
            end
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
end


function IAP:CheckUnfinishedTransactions()
    --俄区新的支付不走这个流程了
    if UnityHelper.IsRuassionVersion() then
        return
    end
    print("--------> IAP CheckUnfinishedTransactions")
    -- if self.m_unfinishedTransactions then
    --     for k,v in pairs(self.m_unfinishedTransactions  or {}) do
    --         m_currentWarriorOrder = k
    --         if self.m_warriorOrder[m_currentWarriorOrder].status == WARRIOR_STATE_PAY then
    --             Shop:BuySuccess(v)
    --             self.m_warriorOrder[m_currentWarriorOrder].status = WARRIOR_STATE_AWARD
    --             self.m_warriorOrder[m_currentWarriorOrder].signature = nil
    --             self.m_warriorOrder[m_currentWarriorOrder].original = nil
    --         end
    --         LocalDataManager:UpdateLoadLocalData()
    --         LocalDataManager:WriteToFile()
    --         self:CostOrder()
    --         return
    --     end
    --     for k,v in pairs(self.m_warriorOrder or {}) do
    --         if v.status == WARRIOR_STATE_CREATED then
    --             self.m_warriorOrder[k] = nil
    --             LocalDataManager:WriteToFile()
    --         end
    --     end
    -- end
    local data = LocalDataManager:GetDataByKey("user_data")
    local requestTable = {
		url = GameNetwork.CHECK_UNFINISHED_ORDER_URL,
        -- isLoading = true,
        fullMsgTalbe = true,
		msg = {
            userId = GameSDKs:GetThirdAccountInfo(),
			appId = GameNetwork.HEADR["X-WRE-APP-ID"],
        },
		callback = function(response)
            -- if not response.data or #response.data <= 0 then
            --     return
            -- end
            -- self.m_unfinishedTransactions = {}
            -- for k,v in pairs(response.data) do
            --     self.m_unfinishedTransactions[v.serialId] = v.productId
            -- end
            -- self:CheckUnfinishedTransactions()
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    if GameConfig:UseWarriorOldAPI() then
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
    else
        requestTable.url = GameSDKs.CHECK_UNFINISHED_ORDER_URL
        GameSDKs:Warrior_request(requestTable)
    end
end

function IAP:SetProductToShopId()
    self.productToShop = {}

    local data = {}
    local identifier = GameDeviceManager:GetAppBundleIdentifier()
    local currId = nil
    local currData = nil
    local currCfg = ConfigMgr.config_iap

    for k,v in pairs(ConfigMgr.config_shop or {}) do
        currId = v.iap_id
        currData = currCfg[currId]
        if currData then
            data[k] = currData[identifier]
        end
    end

    for k,v in pairs(data) do
        self.productToShop[v] = k
    end

end

function IAP:ShopIdFromProductId(productId)
    if self.productToShop == nil then
        self:SetProductToShopId()
    end

    return self.productToShop[productId]
end

function IAP:ProductIDToCfg(productId)
    return self.m_productToIAPCfg[productId]
end

function IAP:AccumulatedChargeIDFromProductId(productId)
    if self.productToAccumulatedCharge == nil then
        self:SetProductToAccumulatedChargeID()
    end
    return self.productToAccumulatedCharge[productId]
end

function IAP:SetProductToAccumulatedChargeID()
    self.productToAccumulatedCharge = {}

    local data = {}
    local identifier = GameDeviceManager:GetAppBundleIdentifier()
    local currId = nil
    local currData = nil
    local currCfg = ConfigMgr.config_iap

    local accConfigs = GameTableDefine.AccumulatedChargeActivityDataManager:GetAccumulatedConfigs()
    for k,v in pairs(accConfigs or {}) do
        if v.iap_id > 0 then
            currId = v.iap_id
            currData = currCfg[currId]
            if currData then
                data[k] = currData[identifier]
            end
        end
    end

    for k,v in pairs(data) do
        self.productToAccumulatedCharge[v] = k
    end
end


--[[
    @desc: 刷新俄区包(PayerMax支付)的价格相关内容
    author:{author}
    time:2023-12-25 11:39:22
    @return:
]]
function IAP:RefreshRuassionIAPInfo()
     --2023-10-26 添加用于俄语版本新的支付方式添加的内容
        --jsondata:
        --[[
            __jsontype:"object"
            __name:"json.object"
            ad_free_pack:"us$24.99"-"JP¥2,880"
            cat_black:"us$6.99"
            chihuahua_black:"us$7.99"
            com.idle.property.real.estate.tycoon.mogul.baoan.599:"us$5.99"
        ]]
        --[[
            m_productList:
            1:"com.idle.property.real.estate.tycoon.baoan.599"
            10:"com.idle.property.real.estate.tycoon.mogul.premiumpack8.799"
        ]]
        self.m_productPrice = {}
        self.m_productRoublePriceNum = {}
        local netData = {}
        local iapCountryCfg = ConfigMgr:GetCurrentIAPCountryCfg(self.m_CountryCode)
        for k, key in pairs(self.m_productList) do
            local iapCfgItem = nil
            for k, tmpCfg in pairs(ConfigMgr.config_iap) do
                 if tmpCfg["com.warrior.obxso.gp"] == key then
                    iapCfgItem = tmpCfg
                    break
                 end
            end
            if iapCfgItem then
                netData[key] = iapCfgItem[iapCountryCfg.iap_price]
            end
        end
        -- for k, key in pairs(self.m_productList) do
        --     self.m_productPrice[key] = data[key] or "0"
        --     local doubleKey = key.."_number"
        --     if data[doubleKey] then
        --         self.m_productPrice[doubleKey] = data[doubleKey]
        --     end
        --     -- print("key", key, doubleKey, data[key], data[doubleKey], self.m_productPrice[key], self.m_productPrice[doubleKey])
        -- end
        for k, key in pairs(self.m_productList) do
            local tmpStr = netData[key]
            if tmpStr then
                self.m_productRoublePriceNum[key] = tmpStr
                local tmpDisStr = Tools:SeparateNumberWithComma(tonumber(tmpStr), true)
                tmpDisStr = iapCountryCfg.currency_symbol..string.gsub(tmpDisStr, ",", iapCountryCfg.thousand_code)
                self.m_productPrice[key] = tmpDisStr
            end
        end
end

--[[
    @desc: GM修改当前的地区码
    author:{author}
    time:2023-12-26 10:11:53
    --@countryCode: 
    @return:
]]
function IAP:GMModifyCountryCode(countryCode)
    self.m_CountryCode = countryCode
    self:RefreshRuassionIAPInfo()
end

--[[
    @desc: PayerMax获取当前的货币码
    author:{author}
    time:2023-12-27 13:18:50
    @return:
]]
function IAP:GetCurrencyCody()
    if self.m_CountryCode then
        local iapCountryCfg = ConfigMgr:GetCurrentIAPCountryCfg(self.m_CountryCode)
        if iapCountryCfg then
            return iapCountryCfg.currency_code
        end
    end
    return "USD"
end

--[[
    @desc: PayerMax获取当前的国家码
    author:{author}
    time:2023-12-27 13:18:50
    @return:
]]
function IAP:GetCountryCode()
    local countryCode = DeviceUtil.GetCountryCode() or "US"
    local iapCountryCfg =  ConfigMgr:GetCurrentIAPCountryCfg(countryCode)
    if not iapCountryCfg.open then
        countryCode = "US"
    else
        countryCode = iapCountryCfg.country_code
    end
    return countryCode
end 