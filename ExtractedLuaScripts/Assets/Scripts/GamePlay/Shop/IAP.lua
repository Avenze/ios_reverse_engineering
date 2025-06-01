local IAP = GameTableDefine.IAP

-- local System = GameTableDefine.System
local CfgMgr = GameTableDefine.ConfigMgr
local DeviceUtil = CS.Game.Plat.DeviceUtil
local DeviceInfo = CS.Game.Plat.DeviceInfo
local GameSDKMgr = CS.Game.SDK.SDKManager.Instance
local ProductType = CS.UnityEngine.Purchasing.ProductType

local Shop = GameTableDefine.Shop

local rapidjson = require("rapidjson")
local EventManager = require("Framework.Event.Manager")
local UnityHelper = CS.Common.Utils.UnityHelper
local m_buySuccessFunc,m_buyFailedFunc

function IAP:Init()
    m_buySuccessFunc = nil
    m_buyFailedFunc = nil
    if self.m_productPrice or not GameDeviceManager:IsIAPVersion() then
        return
    end

    self.m_productPrice = {}
    -- for k, v in pairs(CfgMgr.config_iap or {}) do
    --     local purchaseID = v[GameDeviceManager:GetAppBundleIdentifier()]
    --     if purchaseID then
    --         self.m_productPrice[purchaseID..".local_price_en"] = v.price_en[1]..v.price_en[2]
    --     end
    -- end
    self.m_productList, self.m_productType = self:GetPurchaseList()
    -- DeviceUtil.RequestProductData(self.m_productList, self.m_productType)
end

function IAP:CheckUnfinishedTransactions()
    if GameDeviceManager:IsPCDevice() then
        return
    end
    DeviceUtil.CheckUnfinishedTransactions()
end

function IAP:GetPriceFromString(currencyWithSymbol)
    local firstPos, endPos = string.find(currencyWithSymbol or "", "%d+%.%d+")
    if not firstPos then
        return "0"
    end
    local price = string.sub(currencyWithSymbol, firstPos, endPos) or "0"
    return price
end

function IAP:SetPrice(data)
    for k, key in pairs(self.m_productList) do
        self.m_productPrice[key] = data[key] or ("$" .. self:GetPriceFromString(key))
    end
end

function IAP:GetPrice(purchaseID)
    if self.m_productPrice and self.m_productPrice[purchaseID] then
        return self.m_productPrice[purchaseID]
    end
    return "loading..." --self.m_productPrice[purchaseID..".local_price_en"
    -- return self.m_productPrice[purchaseID] or self:GetPriceFromString(purchaseID)
end

function IAP:Close()
    self.storeObject = nil
end

function IAP:GetOrder()
end

function IAP:Buy(id, param, succ, failed)
    m_buySuccessFunc = succ
    m_buyFailedFunc = failed
    DeviceUtil.Buy(id, param)
end

function IAP:GetPurchaseList()
    local productList = {}
    local productType = {}
    for k, v in pairs(CfgMgr.config_iap or {}) do
        local purchaseID = v[GameDeviceManager:GetAppBundleIdentifier()]
        table.insert(productList,  purchaseID)
        table.insert(productType,  v.not_consumption and ProductType.NonConsumable or ProductType.Consumable)
    end
    return productList, productType
end

function IAP:GetPurchaseId(configId)
    local cfg = CfgMgr.config_iap[configId]
    if cfg then
        return cfg[GameDeviceManager:GetAppBundleIdentifier()]
    end
end

-- function IAP:AndroidTransactionSuccess(purchaseToken, signedData, signature)
--     local requestTable = {
--         url = "order_googlepay",
--         msg = {
--             ["sinature_data"] = signedData,
--             ["signature"] = signature
--         },
--         callback = function(response)
--             if response.status ~= 200 then
--                 if m_buyFailedFunc then m_buyFailedFunc() end
--                 return
--             end
--             DeviceUtil.ConfirmTransactionCompleted(purchaseToken)
--             if response.success then
--                 if m_buySuccessFunc then m_buySuccessFunc() end
--                 -- GameTableDefine.Shop:PayCallBack()
--                 -- GameSDKs:SetAdjustEvent("EVENT_IAP_NUM")
--                 -- GameSDKs:SetAdjustEvent("EVENT_PURCHASE", tonumber(response.currency))
--             end
--         end
--     }
--     -- GameNetwork:Socket_SendRequest(requestTable)
-- end

function IAP:TransactionCompleted(product)
    print("-----IAP-> receipt:", product.receipt, product.definition.type)
    local transactionInfo = rapidjson.decode(product.receipt)
    local transactionID = transactionInfo.TransactionID
    local store = transactionInfo.Store
    local receipt = nil
    local signature = nil
    local signedData = nil
    local url = nil
    Tools:DumpTable(transactionInfo, "-----IAP-> transactionInfo:")
    if store == "AppleAppStore" then
        -- local rec =  DeviceUtil.GetIOSReceipt(product)
        -- print(rec)
        url = "order_appstore"
        receipt = transactionInfo.Payload
    elseif store == "GooglePlay" then
        url = "order_googlepay"
        local Payload = rapidjson.decode(transactionInfo.Payload)
        signature = Payload.signature
        signedData = rapidjson.decode(Payload.json)
    end
    local requestTable = {
        url = url,
        msg = {
            -- ["product"] = product,
            ["receipt"] = receipt,
            ["sinature_data"] = signedData,
            ["signature"] = signature
        },
        callback = function(response)
            if response.status ~= 200 then
                if m_buyFailedFunc then m_buyFailedFunc() end
                m_buyFailedFunc = nil
                m_buySuccessFunc = nil
                return
            end
            if response.success and m_buySuccessFunc then -- or store == "AppleAppStore"
                local cfg = Shop:GetIapConfigByPurchaseID(signedData.productId)
                if signedData.acknowledged and not cfg.not_consumption then
                    self:PurchaseFailed()
                    return
                end

                GameSDKs:TrackForeign("purchase", {product_id = signedData.productId, price = Shop:GetShopItemPrice(signedData.productId, true), state = 3})

                m_buySuccessFunc()
                m_buyFailedFunc = nil
                m_buySuccessFunc = nil
                DeviceUtil.ConfirmPendingPurchase(product)
                GameSDKMgr:Track("adjust,4vp9hp",rapidjson.encode({orderId=signedData.orderId, productId = signedData.productId,  purchaseTime = signedData.purchaseTime,purchaseState = signedData.purchaseState}))
                print("-----IAP-> product.definition.type:", product.definition.type)
            end
        end
    }
    Tools:DumpTable(requestTable, "-----IAP->requestTable:")
    self:LocalVerificationPurchases(requestTable)
    -- GameNetwork:Socket_SendRequest(requestTable)
end

-- - ["requestTable"] = {
--     -     ["msg"] = {
--     -         ["product"]       = UnityEngine.Purchasing.Product: 1592007288,
--     -         ["signature"]     = "j0Rnu3vf085NnBU19qGpyBYOMJAIFq23sXdhHcgcaL4x1iIRgKpQa7nydLVvH34JHVd/Z2fm0Nd1tbBWypu9gPFrPjht2XxgBuQtxBSdbUUTchWv8gTry40BQoYe+Yn6WXy/nAQCzOsldBl7NA5Kld4138uTtcd4OnARAJg4NaYj2+gGnUx7RZPkCxAWgOq/qBV5CpytcQW37Psj4MkVJZYiQuGBIvK4z9RfGbPI9NW90lHP4FNUpChTfMcTDpjF+MziavrqaehPNbj7zA4+6Meol5ntpTloK7NLLNKOom2cRPvC1pTbhA8z0hWPpomF9gGMkvvVpSz2xO7i7ful0A==",
--     -         ["sinature_data"] = "{"orderId":"GPA.3310-0486-7423-95689","packageName":"com.idle.property.real.estate.tycoon.mogul","productId":"com.idle.property.real.estate.tycoon.mogul.dia.99","purchaseTime":1642398996796,"purchaseState":0,"purchaseToken":"icdfhkbckjphmkmekicabecp.AO-J1OxiAbjh28k0Frpe__CWmsVE5AcFXSOhorFVFoO86OAvUNJ0mzN6ovmWuHgKu6M1XYvhoCkDVmalY3k6G-yNlCnoe5qvudC12-mK9pUxTg8RdM_QrGwwR4luh5TWFubO2TmHPR1H","acknowledged":false}",
--     -     },
--     -     ["url"]      = "order_googlepay",
--     - },

local gpOrder = rapidjson.decode("{\"orderId\":\"GPA.3310-0486-7423-95689\",\"packageName\":\"com.idle.property.real.estate.tycoon.mogul\",\"productId\":\"com.idle.property.real.estate.tycoon.mogul.dia.99\",\"purchaseTime\":1642398996796,\"purchaseState\":0,\"purchaseToken\":\"icdfhkbckjphmkmekicabecp.AO-J1OxiAbjh28k0Frpe__CWmsVE5AcFXSOhorFVFoO86OAvUNJ0mzN6ovmWuHgKu6M1XYvhoCkDVmalY3k6G-yNlCnoe5qvudC12-mK9pUxTg8RdM_QrGwwR4luh5TWFubO2TmHPR1H\",\"acknowledged\":false}")
gpOrder.signature = "j0Rnu3vf085NnBU19qGpyBYOMJAIFq23sXdhHcgcaL4x1iIRgKpQa7nydLVvH34JHVd/Z2fm0Nd1tbBWypu9gPFrPjht2XxgBuQtxBSdbUUTchWv8gTry40BQoYe+Yn6WXy/nAQCzOsldBl7NA5Kld4138uTtcd4OnARAJg4NaYj2+gGnUx7RZPkCxAWgOq/qBV5CpytcQW37Psj4MkVJZYiQuGBIvK4z9RfGbPI9NW90lHP4FNUpChTfMcTDpjF+MziavrqaehPNbj7zA4+6Meol5ntpTloK7NLLNKOom2cRPvC1pTbhA8z0hWPpomF9gGMkvvVpSz2xO7i7ful0A=="
function IAP:TestCheck()
    local requestTable = {
        url = "order_googlepay",
        msg = {
            -- ["product"] = product,
            GPOrder = gpOrder,
        },
        callback = function(response)
            -- if response.status ~= 200 then
            --     if m_buyFailedFunc then m_buyFailedFunc() end
            --     m_buyFailedFunc = nil
            --     return
            -- end
            -- if response.success then -- or store == "AppleAppStore"
            --     if m_buySuccessFunc then m_buySuccessFunc() end
            --     m_buySuccessFunc = nil
            --     DeviceUtil.ConfirmPendingPurchase(product)
            --     GameSDKMgr:Track("adjust,4vp9hp", signedData)
            -- end
        end
    }
    Tools:DumpTable(requestTable, "requestTable")
    GameNetwork:HTTP_SendRequest(requestTable)
end

-- 0 PurchasingUnavailable,
-- 1 NoProductsAvailable,
-- 2 AppNotKnown
function IAP:InitializeFailed(error)
    print("InitializeFailed", error)
end

-- 0 PurchasingUnavailable,
-- 1 ExistingPurchasePending,
-- 2 ProductUnavailable,
-- 3 SignatureInvalid,
-- 4 UserCancelled,
-- 5 PaymentDeclined,
-- 6 DuplicateTransaction,
-- 7 Unknown
function IAP:PurchaseFailed(product, error)
    print("PurchaseFailed", error)
    if error == 6 then -- DuplicateTransaction
        IAP:TransactionCompleted(product)
        return
    end
    if m_buyFailedFunc then m_buyFailedFunc() end
    m_buyFailedFunc = nil
    m_buySuccessFunc = nil
end

function IAP:LocalVerificationPurchases(requestTable)
    requestTable.callback({status=200, success = true})
end

EventManager:RegEvent("FS_IAP_PRODUCT_DATA_RECEIVED", handler(IAP, IAP.SetPrice))
EventManager:RegEvent("FS_IAP_PRODUCT_INIT_FAILED", handler(IAP, IAP.InitializeFailed))
EventManager:RegEvent("FS_IAP_BUY_PRODUCT_FAILED", handler(IAP, IAP.PurchaseFailed))
EventManager:RegEvent("FS_IAP_BUY_PRODUCT_SUCCESSFUL", handler(IAP, IAP.TransactionCompleted))