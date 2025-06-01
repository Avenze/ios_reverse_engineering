--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-08-13 15:32:49
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local GameObject = CS.UnityEngine.GameObject
local SupplementOrderUI = GameTableDefine.SupplementOrderUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI
local DeviceUtil = CS.Game.Plat.DeviceUtil
local SupplementOrderUIView = Class("SupplementOrderUIView", UIView)
local rapidjson = require("rapidjson")

function SupplementOrderUIView:ctor()
    self.super:ctor()
end

function SupplementOrderUIView:OnEnter()
    self.super:OnEnter()
    self:GetGo("background/BottomPanel/YesBtn"):SetActive(false)
    self:GetGo("background/BottomPanel/feedbackBtn"):SetActive(false)
    self:GetGo("background/BottomPanel/restoreBtn"):SetActive(false)
    self:GetGo("background/BottomPanel/CancelBtn"):SetActive(true)
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/CancelBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/feedbackBtn", "Button"), function()
        GameSDKs:Warrior_sendFeedbackMail()
        self:DestroyModeUIObject()
    end)
    
    local haveData = nil
    local datas = MainUI:GetInitSupplementOrder()
    for _, v in pairs(datas or {}) do
        haveData = v
        break
    end
    if haveData and haveData.serialId and haveData.productId and haveData.orderId then
        local iapCfg = GameTableDefine.IAP:ProductIDToCfg(haveData.productId)
        local dispText = ""
        -- if not iapCfg or iapCfg.restore == 0 then   -- 0表示不支持补单
        --     self:GetGo("background/BottomPanel/feedbackBtn"):SetActive(true)
        --     self:GetGo("background/BottomPanel/restoreBtn"):SetActive(false)
        --     dispText = GameTextLoader:ReadText("TXT_TIP_ORDER_MANUAL")
        -- elseif iapCfg and iapCfg.restore == 1 then
        --     self:GetGo("background/BottomPanel/feedbackBtn"):SetActive(false)
        --     self:GetGo("background/BottomPanel/restoreBtn"):SetActive(true)
        --     dispText = GameTextLoader:ReadText("TXT_TIP_ORDER_AUTO")
        --     self:SetButtonClickHandler(self:GetComp("background/BottomPanel/restoreBtn", "Button"), function()
        --         self:OpenRelenishWait()
        --         DeviceUtil.InvokeNativeMethod("replenishOrder", haveData.serialId, haveData.productId, haveData.orderId, "1")
        --     end)
        -- else
        --     self:DestroyModeUIObject()
        -- end
        ---新的补单流程先消耗再告知玩家联系客服
        if not iapCfg then   -- 0表示不支持补单
            self:GetGo("background/BottomPanel/feedbackBtn"):SetActive(true)
            self:GetGo("background/BottomPanel/restoreBtn"):SetActive(false)
            dispText = GameTextLoader:ReadText("TXT_TIP_ORDER_MANUAL")
        elseif iapCfg then
            self:GetGo("background/BottomPanel/feedbackBtn"):SetActive(false)
            self:GetGo("background/BottomPanel/restoreBtn"):SetActive(true)
            dispText = GameTextLoader:ReadText("TXT_TIP_ORDER_AUTO")
            self:SetButtonClickHandler(self:GetComp("background/BottomPanel/restoreBtn", "Button"), function()
                self:OpenRelenishWait()
                if GameDeviceManager:IsEditor() then
                    self:OnRestorePurchaseCallback(true, haveData.productId, "")
                else
                    DeviceUtil.InvokeNativeMethod("replenishOrder", haveData.serialId, haveData.productId, haveData.orderId, "1")
                end
            end)
        else
            self:DestroyModeUIObject()
        end
        self:SetText("background/HeadPanel/desc", dispText)
    else
        self:DestroyModeUIObject()
    end
end

function SupplementOrderUIView:OnExit()
    self.super:OnExit(self)
end

function SupplementOrderUIView:OnRestorePurchaseCallback(successful, productId, extra)
    self:CloseRelenishWait()
    local dispText = GameTextLoader:ReadText("TXT_PURCHASE_Restored")
    local realSuccessful = false
    if successful then
        local iapCfg = GameTableDefine.IAP:ProductIDToCfg(productId)
        if iapCfg and iapCfg.restore == 1 then
            local shopId = GameTableDefine.IAP:ShopIdFromProductId(productId)
                 GameTableDefine.ShopManager:Buy(shopId, false, nil, function ()
                    GameTableDefine.PurchaseSuccessUI:SuccessBuy(shopId, nil)
            end)
            realSuccessful = true
        end
        if iapCfg and iapCfg.restore == 0 then
            local extraData = rapidjson.decode(extra)
            local shopID = GameTableDefine.IAP:ShopIdFromProductId(productId)
            
            local rewardsData, isAccumulate = GameTableDefine.SupplementOrderUI:ParseRestoreZeroRealItems(shopID, extraData)
            if isAccumulate ~= 0 then
                if isAccumulate == 1 then
                    --补偿累充权限
                    GameTableDefine.AccumulatedChargeActivityDataManager:BuyProductCallbackByRestore(iapCfg.id, true)
                elseif isAccumulate == 2 then
                    --补偿通信证权限,现在就是一个通行证的方式，ID都是确定的
                    if shopID == GameTableDefine.SeasonPassManager.PREMIUM_SHOP_ID then
                        GameTableDefine.SeasonPassManager:SetIsBuyPremiumPass()
                        GameTableDefine.SeasonPassUI:OpenViewByDataUpdate(shopID)
                    elseif shopID == GameTableDefine.SeasonPassManager.LUXURY_SHOP_ID then
                        GameTableDefine.SeasonPassManager:SetIsBuyLuxuryPass()
                        GameTableDefine.SeasonPassUI:OpenViewByDataUpdate(shopID)
                    end
                elseif isAccumulate == 3 then
                    GameTableDefine.ClockOutDataManager:BuyClockOutIAPResult(shopID, true)
                end
            else
                GameTableDefine.ShopManager:BuyByGiftCode(rewardsData, function(realRewardDatas)
                    --realRewardDatas = {{icon1, num1}, {icon2, num2}}
                    --这里显示UI奖励内容
                    GameTableDefine.CycleInstanceRewardUI:ShowGiftCodeGetRewards(realRewardDatas, true)
                end, true)
            end
            realSuccessful = true
        end
    end
    if not realSuccessful then
        dispText = GameTextLoader:ReadText("TXT_TIP_ORDER_MANUAL")
    end
    self:GetGo("background/BottomPanel/YesBtn"):SetActive(realSuccessful)
    self:GetGo("background/BottomPanel/feedbackBtn"):SetActive(not realSuccessful)
    self:GetGo("background/BottomPanel/restoreBtn"):SetActive(false)
    self:GetGo("background/BottomPanel/CancelBtn"):SetActive(false)
    self:SetText("background/HeadPanel/desc", dispText)
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/YesBtn", "Button"), function()
        if not realSuccessful then
            GameSDKs:Warrior_sendFeedbackMail()
        end
        self:DestroyModeUIObject()
    end)
end

function SupplementOrderUIView:OpenRelenishWait()
    self:GetGo("background/HeadPanel/icon"):SetActive(true)
    local dispText = GameTextLoader:ReadText("TXT_PURCHASE_Searching")
    self:SetText("background/HeadPanel/desc", dispText)
    self:GetGo("background/BottomPanel"):SetActive(false)
end

function SupplementOrderUIView:CloseRelenishWait()
    self:GetGo("background/HeadPanel/icon"):SetActive(false)
    self:GetGo("background/BottomPanel"):SetActive(true)
end


return SupplementOrderUIView