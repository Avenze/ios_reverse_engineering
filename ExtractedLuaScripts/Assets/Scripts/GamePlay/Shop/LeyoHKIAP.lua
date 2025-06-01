local IAP = GameTableDefine.IAP

local CfgMgr = GameTableDefine.ConfigMgr
local ChooseUI = GameTableDefine.ChooseUI
local DeviceUtil = CS.Game.Plat.DeviceUtil
local DeviceInfo = CS.Game.Plat.DeviceInfo
local GameSDKMgr = CS.Game.SDK.SDKManager.Instance
local ProductType = CS.UnityEngine.Purchasing.ProductType

local Shop = GameTableDefine.Shop
local ConfigMgr = GameTableDefine.ConfigMgr

local rapidjson = require("rapidjson")
local EventManager = require("Framework.Event.Manager")

local m_currentLeyoHKOrder

local LEYOHK_STATE_CREATED         = 0
local LEYOHK_STATE_PAY             = 1
local LEYOHK_STATE_AWARD           = 2
local LEYOHK_STATE_COMPLE          = 3

local USE_LCOAL_VERIFICATIOHN      = GameDeviceManager:IsAndroidDevice()

function IAP:Init()
    print("leyohkiap -- > init")
    m_currentLeyoHKOrder = nil
    if self.m_productPrice or not GameDeviceManager:IsIAPVersion() then
        print("不是iap,直接返回,不拉去信息结果了")
        return
    end

    self.m_productPrice = {}
    self.m_productList, self.m_productPriceUS = self:GetPurchaseList()
    self.m_productData = self:GetPurchaseData()
    self:SetProductToShopId()
    print("请求商品信息表单 " .. self.m_productData)
    -- DeviceUtil.RequestProductData(self.m_productList, self.m_productType, self.m_productData)
    DeviceUtil.InvokeNativeMethod("pullProductInfoList", self.m_productData)
end

function IAP:GetOrder()
    self.m_leyoOrder = LocalDataManager:GetDataByKey("leyohk_order") -- pid, state
end

function IAP:GetPriceDouble(id)
    local pid = Shop:GetShopItemPurchaseID(id)
    -- print("----GetPriceDouble", id, pid, (pid.."_number"), self.m_productPrice[pid.."_number"])
    -- Tools:DumpTable(self.m_productPrice, "m_productPrice")
    return self:GetPriceDoubleByPurchaseId(pid)
end

function IAP:GetPriceDoubleByPurchaseId(pid)
    if self.m_productPrice[pid.."_number"] then
        return self.m_productPrice[pid.."_number"]
    end
    
    local currencyWithSymbol = IAP:GetPrice(pid)
    local firstPos, endPos = string.find(currencyWithSymbol or "", "%d+%.%d+")
    local comma = "."
    if not firstPos then
        comma = ","
        firstPos, endPos = string.find(currencyWithSymbol or "", "%d+%,%d+")
    end
    if not firstPos then
        return "0"
    end
    local price = string.sub(currencyWithSymbol, firstPos, endPos) or "0"
    local priceFormat = price
    if comma == "," then
        price = string.gsub(price, ',', '.')
    end
    return price, priceFormat, comma
end

function IAP:GetPriceCode()
    return self.m_productPrice.price_currency_code or "USD"
end

function IAP:SetPrice(data)
    self.m_productPrice.price_currency_code = data.price_currency_code
    for k, key in pairs(self.m_productList) do
        self.m_productPrice[key] = data[key] or "0"
        local doubleKey = key.."_number"
        if data[doubleKey] then
            self.m_productPrice[doubleKey] = data[doubleKey]
        end
        -- print("key", key, doubleKey, data[key], data[doubleKey], self.m_productPrice[key], self.m_productPrice[doubleKey])
    end
end

function IAP:GetPrice(purchaseID, isNumber)
    if self.m_productPrice and self.m_productPrice[purchaseID] then
        local num = self.m_productPrice[purchaseID]
        if isNumber then
            num = self.m_productPriceUS[purchaseID] or 0
        end
        return num
    end
    return "loading..."
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

function IAP:Buy(id, param)
    self:CreateOrder(id)
end

function IAP:GetPurchaseList()
    local productList = {}
    local productPriceUS = {}
    for k, v in pairs(CfgMgr.config_iap or {}) do
        local purchaseID = v[GameDeviceManager:GetAppBundleIdentifier()]
        if purchaseID then
            table.insert(productList,  purchaseID)
            -- table.insert(productType,  v.not_consumption and ProductType.NonConsumable or ProductType.Consumable)
            if v.price_en[2] == nil then
                productPriceUS[purchaseID] = tostring(v.price_en[2])
            end
            productPriceUS[purchaseID] = tostring(v.price_en[2])
        end
    end
    return productList, productPriceUS
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
    GameSDKs:TrackForeign("purchase", {product_id = product, price = self:GetPrice(product, true), state = 10, msgError = error})-- 逻辑 支付失败
    print("PurchaseFailed", error)
    Shop:BuyFailed(product)
end

function IAP:PurchaseResult(data)
    Tools:DumpTable(data, "PurchaseResult")
    if GameDeviceManager:IsiOSDevice() then
        GameTableDefine.FlyIconsUI:SetNetWorkLoading(false)
    end
    if data.fs_iap_buy_product_successful then
        GameSDKs:TrackForeign("purchase", {product_id = data.productId, price = self:GetPrice(data.productId, true), state = 9})-- 逻辑 支付成功
        if GameDeviceManager:IsiOSDevice() then
            self:CheckOrderIOS(data.productId, data.receipt, data.transactionId, data.serialId)
        else
            self:CheckOrder(data.productId, data.signture, data.signtureData)
        end
    elseif data.failMsg then
        IAP:PurchaseFailed(data.productId, data.failMsg)
    else
        GameSDKs:TrackForeign("purchase", {product_id = data.productId, price = self:GetPrice(data.productId, true), state = 11})-- 逻辑 支付取消
        print("PurchaseFailed cancel")
    end
end

function IAP:CreateOrder(id)
    local data = LocalDataManager:GetDataByKey("user_data")
    local num,_,__ = IAP:GetPriceDoubleByPurchaseId(id)
    local amount = math.floor(tonumber(num) * 100)
    if amount == 0 then
        ChooseUI:CommonChoose("TXT_TIP_SHOP_DISCONNECT")
        GameSDKs:TrackForeign("purchase", {product_id = id, price = self:GetPrice(id, true), state = 15}) -- 逻辑 商店请求未响应
        return
    end

	local requestTable = {
		url = GameNetwork.CREATE_ORDER_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
			userId = GameSDKs:GetThirdAccountInfo(),
			-- appId = GameNetwork.HEADR["X-LEYO-APP-ID"],
			amount = amount,-- self:GetPrice(id, true),
            productId = id,
            amount_code = self:GetPriceCode(),
            type = GameDeviceManager:IsAndroidDevice() and 1 or 2,
            afId = "",
		},
		callback = function(response)
            if response.data and response.data.serialId then
                GameSDKs:TrackForeign("purchase", {product_id = id, price = self:GetPrice(id, true), state = 7}) -- 逻辑 获取订单号成功
               
                m_currentLeyoHKOrder = response.data.serialId 
                print("--------> IAP CreateOrder", id, self:GetPrice(id, true), m_currentLeyoHKOrder)
                self.m_leyoOrder[m_currentLeyoHKOrder] = {pid = id, status = LEYOHK_STATE_CREATED}
                DeviceUtil.InvokeNativeMethod("purchase", id, self:GetPrice(id, true), m_currentLeyoHKOrder)
                LocalDataManager:WriteToFile()
                if GameDeviceManager:IsiOSDevice() then
                    GameTableDefine.FlyIconsUI:SetNetWorkLoading(true)
                end
            else
                GameSDKs:TrackForeign("purchase", {product_id = id, price = self:GetPrice(id, true), state = 8})-- 逻辑 获取订单号失败
            end
		end,
        errorCallback = function()
            GameSDKs:TrackForeign("purchase", {product_id = id, price = self:GetPrice(id, true), state = 8})-- 逻辑 获取订单号失败
        end,
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token

    if USE_LCOAL_VERIFICATIOHN then
        requestTable.callback({data = {serialId = tostring(GameTimeManager:GetCurrentServerTime())}})
    else
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
    end
end

function IAP:CheckOrder(productId, signature, original)
    print("--------> IAP CheckOrder ordier id", m_currentLeyoHKOrder)
    print("--------> IAP CheckOrder signature", signature)
    print("--------> IAP CheckOrder original", original)
    if not m_currentLeyoHKOrder then
        return
    end
    local data = LocalDataManager:GetDataByKey("user_data")
	local requestTable = {
		url = GameNetwork.CHECK_ORDER_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
			serialId = m_currentLeyoHKOrder,--,
			dataJson = original, --rapidjson.encode(original),
			sign = signature,
		},
		callback = function(response)
            if response.data and response.data.state == 1 then
                GameSDKs:TrackForeign("purchase", {product_id = productId, price = self:GetPrice(productId, true), state = 3}) --逻辑 效验成功

                Shop:BuySuccess(productId)
                self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_AWARD
                self.m_leyoOrder[m_currentLeyoHKOrder].signature = nil
                self.m_leyoOrder[m_currentLeyoHKOrder].original = nil
                LocalDataManager:UpdateLoadLocalData()
                LocalDataManager:WriteToFile()
                self:CostOrder(productId)
            else
                GameSDKs:TrackForeign("purchase", {product_id = productId, price = self:GetPrice(productId, true), state = 12})-- 逻辑 效验失败
                if self.m_leyoOrder[m_currentLeyoHKOrder] then
                    self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_COMPLE
                    self.m_leyoOrder[m_currentLeyoHKOrder].signature = nil
                    self.m_leyoOrder[m_currentLeyoHKOrder].original = nil
                    LocalDataManager:WriteToFile()
                end
                Shop:BuyFailed(productId)
            end
		end,
        errorCallback = function()
            GameSDKs:TrackForeign("purchase", {product_id = productId, price = self:GetPrice(productId, true), state = 12})-- 逻辑 效验失败
        end,
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    if USE_LCOAL_VERIFICATIOHN then
        requestTable.callback({data = {state = 1}})
    else
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
        self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_PAY
        self.m_leyoOrder[m_currentLeyoHKOrder].signature = signature
        self.m_leyoOrder[m_currentLeyoHKOrder].original = original
        LocalDataManager:WriteToFile()
    end
end


function IAP:CheckOrderIOS(productId, receipt, transactionId, serialId)
    print("--------> IAP CheckOrder ordier id", m_currentLeyoHKOrder)
    print("--------> IAP CheckOrder receipt", receipt)
    print("--------> IAP CheckOrder transactionId", transactionId)
    print("--------> IAP CheckOrder serialId", serialId)
    if not m_currentLeyoHKOrder then
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
                self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_AWARD
                self.m_leyoOrder[m_currentLeyoHKOrder].payload = nil
                self.m_leyoOrder[m_currentLeyoHKOrder].transactionId = nil
                LocalDataManager:UpdateLoadLocalData()
                LocalDataManager:WriteToFile()
                self:CostOrder()
            else
                if self.m_leyoOrder[m_currentLeyoHKOrder] then
                    self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_COMPLE
                    self.m_leyoOrder[m_currentLeyoHKOrder].payload = nil
                    self.m_leyoOrder[m_currentLeyoHKOrder].transactionId = nil
                    LocalDataManager:WriteToFile()
                end
                Shop:BuyFailed(productId)
            end
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token

    if USE_LCOAL_VERIFICATIOHN then
        requestTable.callback({data = {state = 1}})
    else
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
        self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_PAY
        self.m_leyoOrder[m_currentLeyoHKOrder].payload = receipt
        self.m_leyoOrder[m_currentLeyoHKOrder].transactionId = transactionId
        LocalDataManager:WriteToFile()
    end
end

function IAP:CostOrder(productId)
    print("--------> IAP CostOrder ordier id", m_currentLeyoHKOrder)
    if not m_currentLeyoHKOrder then
        return
    end
    local data = LocalDataManager:GetDataByKey("user_data")
    local requestTable = {
		url = GameNetwork.COST_ORDER_URL,
        -- isLoading = true,
        fullMsgTalbe = true,
		msg = {
			serialId = m_currentLeyoHKOrder,
		},
		callback = function(response)
            if response.data and response.data.state == 1 then
                GameSDKs:TrackForeign("purchase", {product_id = productId, price = self:GetPrice(productId, true), state = 13})-- 逻辑 消耗订单成功
                
                if self.m_unfinishedTransactions then
                    self.m_unfinishedTransactions[m_currentLeyoHKOrder] = nil
                end
                self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_COMPLE
                m_currentLeyoHKOrder = nil
                LocalDataManager:WriteToFile()
                print("--------> IAP CostOrder complete")
                self:CheckUnfinishedTransactions()
            else
                GameSDKs:TrackForeign("purchase", {product_id = productId, price = self:GetPrice(productId, true), state = 14})-- 逻辑 消耗订单失败
            end
		end,
        errorCallback = function()
            GameSDKs:TrackForeign("purchase", {product_id = productId, price = self:GetPrice(productId, true), state = 14})-- 逻辑 消耗订单失败
        end,
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    if USE_LCOAL_VERIFICATIOHN then
        requestTable.callback({data = {state = 1}})
    else
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
    end
end


function IAP:CheckUnfinishedTransactions()
    print("--------> IAP CheckUnfinishedTransactions")
    if self.m_unfinishedTransactions then
        for k,v in pairs(self.m_unfinishedTransactions  or {}) do
            m_currentLeyoHKOrder = k
            if self.m_leyoOrder[m_currentLeyoHKOrder].status == LEYOHK_STATE_PAY then
                Shop:BuySuccess(v)
                self.m_leyoOrder[m_currentLeyoHKOrder].status = LEYOHK_STATE_AWARD
                self.m_leyoOrder[m_currentLeyoHKOrder].signature = nil
                self.m_leyoOrder[m_currentLeyoHKOrder].original = nil
            end
            LocalDataManager:UpdateLoadLocalData()
            LocalDataManager:WriteToFile()
            self:CostOrder()
            return
        end
        for k,v in pairs(self.m_leyoOrder or {}) do
            if v.status == LEYOHK_STATE_CREATED then
                self.m_leyoOrder[k] = nil
                LocalDataManager:WriteToFile()
            end
        end
    end
    local data = LocalDataManager:GetDataByKey("user_data")
    local requestTable = {
		url = GameNetwork.CHECK_UNFINISHED_ORDER_URL,
        -- isLoading = true,
        fullMsgTalbe = true,
		msg = {
            userId = GameSDKs:GetThirdAccountInfo(),
			appId = GameNetwork.HEADR["X-LEYO-APP-ID"],
        },
		callback = function(response)
            if not response.data or #response.data <= 0 then
                return
            end
            self.m_unfinishedTransactions = {}
            for k,v in pairs(response.data) do
                self.m_unfinishedTransactions[v.serialId] = v.productId
            end
            self:CheckUnfinishedTransactions()
		end
	}
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = data.token
    if USE_LCOAL_VERIFICATIOHN then
    else
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
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

    local configs = GameTableDefine.AccumulatedChargeActivityDataManager:GetAccumulatedConfigs()
    for k,v in pairs(configs or {}) do
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