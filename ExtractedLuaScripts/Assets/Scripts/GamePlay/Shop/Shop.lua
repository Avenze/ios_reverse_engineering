local CfgMgr = GameTableDefine.ConfigMgr
local IAP = GameTableDefine.IAP
---@class Shop
local Shop = GameTableDefine.Shop
local ShopManager = GameTableDefine.ShopManager
local ShopUI = GameTableDefine.ShopUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local GameUIManager = GameTableDefine.GameUIManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local UnityHelper = CS.Common.Utils.UnityHelper
local EventDispatcher = EventDispatcher

local EventManager = require("Framework.Event.Manager")
local rapidjson = require("rapidjson")
--[[
    @desc: 封装的购买接口，第三个参数用于判断购买场景
    author:{author}
    time:2025-01-03 17:47:24
    --@shopId:
	--@button:
	--@buyPosition:nil or 0表示不用解析参数
    --@realShopItems:{物品数组} or {}如果没有的话就是一个空字符串
    @return:
]]
function Shop:CreateShopItemOrder(shopId, button, buyPosition, buyExtraData)
    EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", true)
    ---2024-8-14添加，如果有单可以补，需要购买前先把单补了
    -- local testJsonData = rapidjson.encode(buyExtraData or {}) --测试转格式
    local isHaveSupplementOrder = false
    local orderData = nil
    local datas = GameTableDefine.MainUI:GetInitSupplementOrder()
    for _, v in pairs(datas or {}) do
        orderData = v
        break
    end
    if orderData and orderData.serialId and orderData.productId and orderData.orderId then
        isHaveSupplementOrder = true
    end
    if isHaveSupplementOrder then
        GameTableDefine.SupplementOrderUI:GetView()
        if button then
            button.interactable = true
        end
        return
    end

    -- 白包
    if GameDeviceManager:IsWhitePackage("iap") and shopId then
        EventManager:DispatchEvent("DOMESTIC_PURCHASE")
        EventManager:DispatchEvent("SHOP_BUY_SUCCESS", shopId)
        return  
    end

    local productid = self:GetShopItemPurchaseID(shopId)
    if not productid then
        return
    end
    if GameDeviceManager:IsEditor() then
        EventManager:DispatchEvent("DOMESTIC_PURCHASE")
        EventManager:DispatchEvent("SHOP_BUY_SUCCESS", shopId)
    else
        if GameConfig:IsLeyoHKVersion() then
            local price = self:GetShopItemPrice(shopId, true)
            GameSDKs:TrackForeign("purchase", {product_id = productid, price = price, state = 1}) -- 点击按钮
        end
        --2025-1-3 fy添加新增钻石购买的参数增加
        local newPosiiton = ""
        local shopCfg = CfgMgr.config_shop[shopId]
        if buyPosition and shopCfg and shopCfg.type == 3 then
            if buyPosition == 1 then
                newPosiiton = "1. 主线商城"
            elseif buyPosition == 2 then
                newPosiiton = "2. 副本商城"
            elseif buyPosition == 3 then
                newPosiiton = "3. 主线弹窗"
            elseif buyPosition == 4 then
                newPosiiton = "4. 副本弹窗"
            end
        end
        --2025-1-7fy 添加用于补单的需要传递一个额外商品内容告知到支付那边，用于补单
        IAP:Buy(productid, newPosiiton, buyExtraData or {})
    end
  

    -- local data = LocalDataManager:GetDataByKey("user_data")
    -- if not data.wechat_id then
    --    print("未绑定微信")
    --     return
    -- end

    -- local requestTable = {
    --     url = "create_order",
    --     msg = {
    --         shopId = ShopId,
    --         user = {userId = data.user_id, wxId = data.wechat_id},
    --     },
    --     callback = function(order)
    --         IAP:Buy(productid, order.id)
    --     end,
    --     errCallback = errCallback
    -- }
    -- GameNetwork:Socket_SendRequest(requestTable)
end

--[[
    @desc: 创建累充活动的订单
    author:fengyu
    time:2022-12-23 15:10:26
    --@itemID: 
    @return:
]]
function Shop:CreateAccumulatedRechargeItemOrder(itemID, btn)

    ---2024-8-14添加，如果有单可以补，需要购买前先把单补了
    -- local testJsonData = rapidjson.encode(buyExtraData or {}) --测试转格式
    local isHaveSupplementOrder = false
    local orderData = nil
    local datas = GameTableDefine.MainUI:GetInitSupplementOrder()
    for _, v in pairs(datas or {}) do
        orderData = v
        break
    end
    if orderData and orderData.serialId and orderData.productId and orderData.orderId then
        isHaveSupplementOrder = true
    end
    if isHaveSupplementOrder then
        GameTableDefine.SupplementOrderUI:GetView()
        if button then
            button.interactable = true
        end
        return
    end

    if GameDeviceManager:IsWhitePackage("iap") and itemID then
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", itemID, true)
        
        return
    end

    local configs = GameTableDefine.AccumulatedChargeActivityDataManager:GetAccumulatedConfigs()
    if not configs then
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", itemID, false)
        return
    end
    local itemCfg = configs[itemID]
    if not itemCfg then
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", itemID, false)
        return
    end
    local productid = self:GetPurchaseIDByIAPID(itemCfg.iap_id)
    if not productid then
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", itemID, false)
        return
    end

    if GameDeviceManager:IsEditor() then
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", itemID, true)
    else
        --2025-1-8fy 对于累充商品的补单只能用一个特殊的标识符号好标记其是累充商品了
        IAP:Buy(productid, "", {IsAccumulateItem = true})
    end
end


--[[
    @desc: 下班打卡的购买订单创建
    author:{author}
    time:2025-04-04 14:37:28
    --@shopId:
	--@button: 
    @return:
]]
function Shop:CreateClockOutDataItemOrder(shopId, button)
    local isHaveSupplementOrder = false
    local orderData = nil
    local datas = GameTableDefine.MainUI:GetInitSupplementOrder()
    for _, v in pairs(datas or {}) do
        orderData = v
        break
    end
    if orderData and orderData.serialId and orderData.productId and orderData.orderId then
        isHaveSupplementOrder = true
    end
    if isHaveSupplementOrder then
        GameTableDefine.SupplementOrderUI:GetView()
        if button then
            button.interactable = true
        end
        return
    end

    if GameDeviceManager:IsWhitePackage("iap") and shopId then
        -- EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", purchaseID, true)
        EventDispatcher:TriggerEvent(GameEventDefine.ClockOut_Charge_Buy_Msg, shopId, true)
        return
    end
    
    local productid = self:GetShopItemPurchaseID(shopId)
    if not productid then
        EventDispatcher:TriggerEvent(GameEventDefine.ClockOut_Charge_Buy_Msg, shopId, false)
        return
    end

    if GameDeviceManager:IsEditor() then
        EventDispatcher:TriggerEvent(GameEventDefine.ClockOut_Charge_Buy_Msg, shopId, true)
    else
        --2025-1-8fy 对于累充商品的补单只能用一个特殊的标识符号好标记其是累充商品了
        IAP:Buy(productid, "", {IsClockOutItem = true})
    end
end

function Shop:GetShopItemPurchaseID(shopItemID)--得到谷歌商城或苹果商店的商品唯一id
    local shopData = CfgMgr.config_shop[shopItemID]
    if not shopData or not shopData.iap_id then
        return
    end

    local cfg = CfgMgr.config_iap[shopData.iap_id]
    if cfg then
        return cfg[GameDeviceManager:GetAppBundleIdentifier()]
    end
end

function Shop:GetShopItemPrice(shopItemID, isNum)
    local purchaseID = self:GetShopItemPurchaseID(shopItemID)
    return IAP:GetPrice(purchaseID, isNum)
end

function Shop:GetIapConfigPrice(iap_id, isNum)
    local cfg = CfgMgr.config_iap[iap_id]
    if cfg then
        local purchaseID = cfg[GameDeviceManager:GetAppBundleIdentifier()]
        return IAP:GetPrice(purchaseID, isNum)
    end
end

function Shop:GetPurchaseIDByIAPID(iap_id)
    local cfg = CfgMgr.config_iap[iap_id]
    
    if cfg then
        local purchaseID = cfg[GameDeviceManager:GetAppBundleIdentifier()]
        return purchaseID
    end
    return nil
end

function Shop:GetIapConfigByPurchaseID(purchaseID)
    for k,v in pairs(CfgMgr.config_iap or {}) do
        if v[GameDeviceManager:GetAppBundleIdentifier()] == purchaseID then
            return v
        end
    end
end

function Shop:GetShopItemPriceByIAP(iap_id)
    local cfg = CfgMgr.config_iap[iap_id]
    if cfg then
        return IAP:GetPrice(cfg[GameDeviceManager:GetAppBundleIdentifier()])
    end
end

function Shop:GetShopItemIDByIAPID(iap_id)
    local cfg = CfgMgr.config_iap[iap_id]
    if cfg then
        for shopId, shopItem in pairs(CfgMgr.config_shop) do
            if iap_id == shopItem.iap_id then
                return shopId
            end
        end
    end
    return nil
end

function Shop:GetShopItemIDByPurchaseID(purchaseId)
    local iapCfg = self:GetIapConfigByPurchaseID(purchaseId)
    if iapCfg then
        for shopId, shopItem in pairs(CfgMgr.config_shop) do
            if iapCfg.id == shopItem.iap_id then
                return shopId
            end
        end
    end
    return nil
end

function Shop:BuySuccess(productId)
    local shopId = IAP:ShopIdFromProductId(productId)
    local shopCfg = CfgMgr.config_shop[shopId]
    if shopCfg and shopCfg.type == 17 then
        GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 1, order_state_desc = "触发SHOP_BUY_SUCCESS事件"})
    end

    if shopId then
        EventManager:DispatchEvent("DOMESTIC_PURCHASE")
        EventManager:DispatchEvent("SHOP_BUY_SUCCESS", shopId)
        -- ShopManager:Buy(shopId, false, function()
        --     if GameUIManager:IsUIOpen(55) then--商城成功购买
        --         ShopUI:SuccessBuyAfter(shopId)
        --     end
        -- end
        -- , function()
        --     if GameUIManager:IsUIOpen(55) then
        --         ShopUI:SuccessBuyBefor(shopId)--成功购买的信息
        --     else
        --         PurchaseSuccessUI:SuccessBuy(shopId)
        --     end
        -- end)
    end
    local accumulatedID = IAP:AccumulatedChargeIDFromProductId(productId)
    if accumulatedID then
        EventManager:DispatchEvent("DOMESTIC_PURCHASE")
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", accumulatedID, true)
    end
    local clockOutDataShopID = GameTableDefine.ClockOutDataManager:GetClockOutChargeShoIDByPurchaseID(productId)
    if clockOutDataShopID then
        EventDispatcher:TriggerEvent(GameEventDefine.ClockOut_Charge_Buy_Msg, shopId, true)
    end
end

function Shop:BuyFailed(productId)
    local shopId = IAP:ShopIdFromProductId(productId)
    if shopId then
        EventManager:DispatchEvent("SHOP_BUY_FAIL", shopId)
        ShopManager:BuyFailed(shopId)
        FlyIconsUI:FailService()
        -- if GameUIManager:IsUIOpen(55) then
        --     ShopUI:SuccessBuyAfter(shopId)--刷新
        -- end
    end
    
    local accumulatedID = IAP:AccumulatedChargeIDFromProductId(productId)
    if accumulatedID then
        EventManager:DispatchEvent("ACCUMULATED_CHARGE_BUY_MSG", accumulatedID, false)
    end

    local clockOutDataShopID = GameTableDefine.ClockOutDataManager:GetClockOutChargeShoIDByPurchaseID(productId)
    if clockOutDataShopID then
        EventDispatcher:TriggerEvent(GameEventDefine.ClockOut_Charge_Buy_Msg, shopId, false)
    end
end

-- function Shop:PurchaseSucceeds(purchaseID)
--     local iapCfg = self:GetIapConfigByPurchaseID(purchaseID)
--     local shopCfg = self:GetShopConfigByIapID(iapCfg.id)
--     ShopManager:Buy(shopCfg.id, false, function()
--         self.m_list:UpdateData(true)
--         self:SuccessBuy(infoData)
--         self:RefreshDiamond()
--     end)
-- end

-- function Shop:PurchaseFailed(purchaseID)
-- end