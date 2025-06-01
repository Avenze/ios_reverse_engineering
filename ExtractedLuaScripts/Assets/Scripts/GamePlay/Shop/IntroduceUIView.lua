local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local PurchaseSuccessUI=GameTableDefine.PurchaseSuccessUI


local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local ShopUI = GameTableDefine.ShopUI
local IAP = GameTableDefine.IAP

local Shop = GameTableDefine.Shop

---@class IntroduceUIView:UIBaseView
local IntroduceUIView = Class("IntroduceUIView", UIView)

function IntroduceUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_currType = nil ---当前礼包类型
end

function IntroduceUIView:OnEnter()
    ShopManager:refreshBuySuccess(function(shopId)
        --内购
        ShopManager:Buy(shopId, false, function()
        end,
        function()
            PurchaseSuccessUI:SuccessBuy(shopId)
            self:DestroyModeUIObject()
        end, true)
    end)
    ShopManager:refreshBuyFail(function(shopId)
        EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", false)
	end)
end

function IntroduceUIView:Introduce(shopId, cb, openType)
    local root = self:GetGo("RootPanel")
    local shopCfg = ConfigMgr.config_shop[shopId]
    local popupCfg = ConfigMgr.config_popup[shopId]
    local type = shopCfg.type
    if cb then
        self.closeCB = cb
    end

    local isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(shopId)

    GameSDKs:TrackForeign("game_gift_bag", {state = openType or 0, gift_name = popupCfg.note, gift_id = tostring(shopId)})

    --根据类型,决定使用哪个节点
    local allNode = {"starterpack", "premiumpack", "ad", "managerpack", "month_diamond", "petpack","adfreepack"}
    local currType = nil--对应上面的index

    if type == 10 then
        currType = 5
    elseif type == 12 then
        local packageType = shopCfg.param3[1]
        if packageType == 1 then
            currType = 1
        elseif packageType == 2 then
            currType = 2
        elseif packageType == 3 then
            currType = 4
        elseif packageType == 4 then
            currType = 6
        elseif packageType == 5 then
            currType = 7  
        end
    end

    self.m_currType = currType

    if currType then
        local showNode
        local currNode
        for k,v in pairs(allNode) do
            currNode = self:GetGo(root, v)
            currNode:SetActive(k == currType)

            if currType == k then
                showNode = currNode
            end
        end

        local normalTitleGo = self:GetGoOrNil(root, "title")
        local speTitlGo = self:GetGoOrNil(root, "starterpack/title")
        local cfgPop = ConfigMgr.config_popup[shopId]
        if currType ~= 1 and currType ~= 3 and currType ~= 4 and currType ~= 7 then
            self:SetText("RootPanel/title/txt", GameTextLoader:ReadText(cfgPop.title))
            --设置title的Image图片
            -- self:SetSprite(self:GetComp(showNode, "icon", "Image"), "UI_BG", "bg_shop_starterpack_" .. shopId)
            self:SetSprite(self:GetComp("RootPanel/title", "Image"), "UI_BG", cfgPop.bg_title)
            self:SetSprite(self:GetComp("RootPanel/title/light1", "Image"), "UI_BG", cfgPop.light_title)
            self:SetSprite(self:GetComp("RootPanel/title/light2", "Image"), "UI_BG", cfgPop.light_title)
            if normalTitleGo then
                normalTitleGo:SetActive(true)
            end
            if speTitlGo then
                speTitlGo:SetActive(false)
            end
            self:SetButtonClickHandler(self:GetComp("RootPanel/title/quitBtn","Button"), function()
                self:DestroyModeUIObject()
            end)
        else
            if normalTitleGo then
                normalTitleGo:SetActive(false)
            end
            if speTitlGo then
                speTitlGo:SetActive(true)
            end
            local quitBtn = self:GetComp(showNode, "title/quitBtn", "Button")
            self:SetButtonClickHandler(quitBtn, function()
                self:DestroyModeUIObject()
            end)
        end
        self:SetText(showNode, "offvalue/num", math.floor(cfgPop.offvalue * 100) .. "%")
        self:GetGo(showNode, "offvalue"):SetActive(cfgPop.offvalue > 0)
        if currType == 4 then
            normalTitleGo:SetActive(false)
            self:SetText(showNode, "title/txt", GameTextLoader:ReadText(cfgPop.title))
            local goBtn = self:GetComp(showNode, "goBtn", "Button")
            self:SetText(goBtn.gameObject, "text", Shop:GetShopItemPrice(shopId))
            self:SetButtonClickHandler(goBtn, function()
                GameSDKs:TrackForeign("game_gift_bag", {state = 4, gift_name = popupCfg.note, gift_id = tostring(shopId)})

                ---------------------
                --将popuID转换成ShopId,如果不成功则返回
                local trackPrice = Shop:GetShopItemPrice(shopId, true)--美元单位
                local cfgShop = ConfigMgr.config_shop[shopId]
                if not cfgShop then
                    return
                end
                --判断是不是(存在内购码)内购
                if cfgShop.iap_id then
                    --用shopId判断是不是新手礼包
                    if cfgShop.type == 12 and cfgShop.param3[1] == 1 then--新手礼包
                        local canBuy = ShopManager:canBuyNewGift(cfgShop.id)
                        if not canBuy then
                            --TODO:提示礼包已过期
                            return
                        end
                    end
                    GameSDKs:TrackForeign("store", {source = 2, operation_type = 1, product_id = IAP:GetPurchaseId(cfgShop.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) and trackPrice or 0})
                    --创建一个内购订单             
                    Shop:CreateShopItemOrder(shopId)
                else
                end
                -------------------
                -- ShopUI:TurnTo(shopId, cb)
            end)
        end
        if currType == 7 then
            local adGo = self:GetGoOrNil(showNode, "ad")
            if adGo then
                adGo:SetActive(true)
            end
        end

        local goBtn = self:GetComp("RootPanel/btn/goBtn", "Button")

        self:SetText(goBtn.gameObject, "text", Shop:GetShopItemPrice(shopId))

        --处理倒计时显示
        if self.effectTimer then
            GameTimer:StopTimer(self.effectTimer)
            self.effectTimer = nil
        end
        local timerNode = self:GetGoOrNil(showNode, "bg/buff/timer")
        local timerNode1 = self:GetGoOrNil(showNode, "1/buff/timer")
        local timerNode2 = self:GetGoOrNil(showNode, "2/buff/timer")
        local buffNode = self:GetGoOrNil(showNode, "bg/buff")
        local buffNode1 = self:GetGoOrNil(showNode, "1/buff")
        local buffNode2 = self:GetGoOrNil(showNode, "2/buff")
        if timerNode1 and timerNode2 then
            goBtn.gameObject:SetActive(false)
            --新手礼包现在改成2个了，一个是1037，1189
            if currType == 1 then
                local btn1037 = self:GetComp(showNode, "1/goBtn", "Button")
                local btn1189 = self:GetComp(showNode, "2/goBtn", "Button")
                if btn1037 then
                    self:SetText(btn1037.gameObject, "text", Shop:GetShopItemPrice(1037))
                end
                if btn1189 then
                    self:SetText(btn1189.gameObject, "text", Shop:GetShopItemPrice(1189))
                end

                self:SetButtonClickHandler(btn1037, function()
                    GameSDKs:TrackForeign("game_gift_bag", {state = 4, gift_name = popupCfg.note, gift_id = tostring(1037)})
                    local trackPrice = Shop:GetShopItemPrice(1037, true)--美元单位
                    local cfgShop = ConfigMgr.config_shop[1037]
                    if not cfgShop then
                        return
                    end
                    --判断是不是(存在内购码)内购
                    if cfgShop.iap_id then
                        --用shopId判断是不是新手礼包
                        if cfgShop.type == 12 and cfgShop.param3[1] == 1 then--新手礼包
                            local canBuy = ShopManager:canBuyNewGift(cfgShop.id)
                            if not canBuy then
                                --TODO:提示礼包已过期
                                return
                            end
                        end
                        GameSDKs:TrackForeign("store", {source = 2, operation_type = 1, product_id = IAP:GetPurchaseId(cfgShop.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) and trackPrice or 0 })
                            --创建一个内购订单             
                        Shop:CreateShopItemOrder(1037)                                    
                    end
                end)

                self:SetButtonClickHandler(btn1189, function()
                    GameSDKs:TrackForeign("game_gift_bag", {state = 4, gift_name = popupCfg.note, gift_id = tostring(1189)})
                    local trackPrice = Shop:GetShopItemPrice(1189, true)--美元单位
                    local cfgShop = ConfigMgr.config_shop[1189]
                    if not cfgShop then
                        return
                    end
                    --判断是不是(存在内购码)内购
                    if cfgShop.iap_id then
                        --用shopId判断是不是新手礼包
                        if cfgShop.type == 12 and cfgShop.param3[1] == 1 then--新手礼包
                            local canBuy = ShopManager:canBuyNewGift(cfgShop.id)
                            if not canBuy then
                                --TODO:提示礼包已过期
                                return
                            end
                        end
                        GameSDKs:TrackForeign("store", {source = 2, operation_type = 1, product_id = IAP:GetPurchaseId(cfgShop.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) and trackPrice or 0})
                            --创建一个内购订单             
                        Shop:CreateShopItemOrder(1189)                                    
                    end
                end)
            end
        else
            if currType == 4 then
                goBtn.gameObject:SetActive(false)

            else
                goBtn.gameObject:SetActive(true)
            end
        end
        if isTimeGift and leftTime > 0 then
            self.effectTimer = GameTimer:CreateNewTimer(1, function()
                if leftTime > 0 then
                    isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(shopId)
                    local timeStr = GameTimeManager:FormatTimeLength(leftTime)
                    
                    if timerNode then
                        self:SetText(timerNode, "num", timeStr)
                    end
                    if timerNode1 then
                        self:SetText(timerNode1, "num", timeStr)
                    end
                    if timerNode2 then
                        self:SetText(timerNode2, "num", timeStr)
                    end
                else
                    if self.effectTimer then
                        GameTimer:StopTimer(self.effectTimer)
                        self.effectTimer = nil
                    end
                end
            end, true, true)
        end
        self:SetButtonClickHandler(goBtn, function()
            GameSDKs:TrackForeign("game_gift_bag", {state = 4, gift_name = popupCfg.note, gift_id = tostring(shopId)})

            ---------------------
            --将popuID转换成ShopId,如果不成功则返回
            local trackPrice = Shop:GetShopItemPrice(shopId, true)--美元单位
            local cfgShop = ConfigMgr.config_shop[shopId]
            if not cfgShop then
                return
            end
            --判断是不是(存在内购码)内购
            if cfgShop.iap_id then
                --用shopId判断是不是新手礼包
                if cfgShop.type == 12 and cfgShop.param3[1] == 1 then--新手礼包
                    local canBuy = ShopManager:canBuyNewGift(cfgShop.id)
                    if not canBuy then
                        --TODO:提示礼包已过期
                        return
                    end
                end
                GameSDKs:TrackForeign("store", {source = 2, operation_type = 1, product_id = IAP:GetPurchaseId(cfgShop.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) and trackPrice or 0})
                    --创建一个内购订单             
                Shop:CreateShopItemOrder(shopId)
            else                                      
            end
            -------------------
           -- ShopUI:TurnTo(shopId, cb)
        end)

        -- self:SetButtonClickHandler(self:GetComp("RootPanel/btn/quitBtn","Button"), function()
        --     if cb then cb() end
        --     GameSDKs:TrackForeign("game_gift_bag", {state = 3, gift_name = popupCfg.note, gift_id = tostring(shopId)})
        --     self:DestroyModeUIObject()
        -- end)

        if type == 12 then
            if currType ~= 2 then
                if currType ~= 1 then
                    local buffNode = self:GetGo(showNode, "buff")
                    self:SetBuff(buffNode, shopCfg.param)
                else
                    --新手礼包1专有折扣率
                    local cfg1 = ConfigMgr.config_popup[1037]
                    self:SetText(showNode, "1/offvalue/num", math.floor(cfg1.offvalue * 100) .. "%")
                    self:GetGo(showNode, "1/offvalue"):SetActive(cfg1.offvalue > 0)

                    self:SetBuff(buffNode1, shopCfg.param)
                    local shopCfg2 = ConfigMgr.config_shop[1189]
                    if shopCfg2 then
                        --新手礼包2专有折扣率
                        local cfg2 = ConfigMgr.config_popup[1189]
                        self:SetText(showNode, "2/offvalue/num", math.floor(cfg2.offvalue * 100) .. "%")
                        self:GetGo(showNode, "2/offvalue"):SetActive(cfg2.offvalue > 0)

                        self:SetBuff(buffNode2, shopCfg2.param)
                    end
                end
            else
                local buffNodeTmp = self:GetGo(showNode, "bg/buff")
                self:SetBuff(buffNodeTmp, shopCfg.param)
            end
        end
        local imageName = nil
        if currType == 1 then
            self:SetSprite(self:GetComp(showNode, "icon", "Image"), "UI_BG", "bg_shop_starterpack_" .. shopId)
        elseif currType == 2 then
            self:SetSprite(self:GetComp(showNode, "bg/icon", "Image"), "UI_BG", "bg_shop_premiumpack_" .. shopId)
            --这里根据礼包id来设置的UI的子节点的，所以根据prefab来设置的
            -- local bgNode = {1038,1039,1040,1041,1042,1043,1044,1045,1046,1094}
            -- for k, v in ipairs(bgNode) do
            --     self:GetGo(showNode, tostring(v)):SetActive(v == shopId)
            -- end
        end
    end
    --修改后的AD类型
    if shopId == 1068 then
        local goBtn = self:GetComp("RootPanel/btn/goBtn", "Button")
        goBtn.gameObject:SetActive(false)
        local ADPackepPopuCfg = ConfigMgr.config_popup[1068]    
        local ADCfgPopuCfg = ConfigMgr.config_popup[1009]
        self:SetText("RootPanel/title/txt", GameTextLoader:ReadText(ADCfgPopuCfg.title))
        self:SetText("RootPanel/adfreepack/offvalue/num", math.floor(ADPackepPopuCfg.offvalue * 100) .. "% Off!")
        self:GetGo("RootPanel/adfreepack/ad/offvalue"):SetActive(false)
        local ADPackeCfg = ConfigMgr.config_shop[1068]
        local ADCfg = ConfigMgr.config_shop[1009]
        local buffNode = self:GetGo("RootPanel/adfreepack/buff")
        self:SetBuff(buffNode, ADPackeCfg.param)
        local ADPackeBtn = self:GetComp("RootPanel/adfreepack/goBtn", "Button")
        local ADBtn = self:GetComp("RootPanel/adfreepack/ad/goBtn", "Button")
        self:SetText(ADPackeBtn.gameObject, "text", Shop:GetShopItemPrice(1068))
        self:SetText(ADBtn.gameObject, "text", Shop:GetShopItemPrice(1009))
        self:SetButtonClickHandler(ADPackeBtn, function()
            GameSDKs:TrackForeign("game_gift_bag", {state = 4, gift_name = ADPackepPopuCfg.note, gift_id = tostring(1068)})
            Shop:CreateShopItemOrder(1068)
            GameSDKs:TrackForeign("store", {source = 2, operation_type = 1, product_id = IAP:GetPurchaseId(ADPackeCfg.iap_id), pay_type = 1, cost_num_new = tonumber(Shop:GetShopItemPrice(1068)) and Shop:GetShopItemPrice(1068) or 0})
        end)
        self:SetButtonClickHandler(ADBtn, function()
            GameSDKs:TrackForeign("game_gift_bag", {state = 4, gift_name = ADCfgPopuCfg.note, gift_id = tostring(1009)})
            Shop:CreateShopItemOrder(1009)
            GameSDKs:TrackForeign("store", {source = 2, operation_type = 1, product_id = IAP:GetPurchaseId(ADCfg.iap_id), pay_type = 1, cost_num_new = tonumber(Shop:GetShopItemPrice(1009)) and Shop:GetShopItemPrice(1009) or 0})
        end)
    end
end

function IntroduceUIView:SetBuff(BuffRoot, params)--商品id数组
    local allBuff = {"income", "offline", "mood", "diamond", "cash", "exp", "realcash"}
    local currIndex = 1
    local petIconName = nil
    local petName = nil
    local setNum = function(type, num)
        --if type ~= 13 and type ~= 14 then
        local currTypeName = ShopManager:TypeToName(type, true)
        if currTypeName then
            local newGo = self:GetGoOrNil(BuffRoot, currIndex .. "")
            if newGo then
                newGo:SetActive(true)

                for k,v in pairs(allBuff) do
                    -- local currGo = self:GetGo(newGo, v)
                    local currGo = self:GetGoOrNil(newGo, v)
                    if currGo then
                        currGo:SetActive(v == currTypeName)
                        if v == currTypeName then
                            self:SetText(currGo, "num", num)
                            self:SetText(currGo, "num/num_2", num)
                            --只有新手礼包才修改Icon
                            if self.m_currType == 1 then
                                --宠物替换icon 为 small图标
                                if currTypeName == "income" or currTypeName == "offline" or currTypeName == "mood" then
                                    local petImage = self:GetComp(currGo,"icon","Image")
                                    self:SetSprite(petImage,"UI_Shop",petIconName.."_small")

                                    local tipInfoGO = self:GetGo(currGo,"icon/tipbtn/info")
                                    self:SetText(tipInfoGO,"title/txt",petName)
                                    self:SetText(tipInfoGO,"fix/num",num)
                                end
                            end
                        end
                    end
                end
                currIndex = currIndex + 1
            end
        end
        --else
            -- for k_buff,v_buff in pairs(num) do
            --     local newGo = self:GetGoOrNil(BuffRoot, currIndex .. "")
            --     if newGo then
            --         newGo:SetActive(true)

            --         for k,v in pairs(allBuff) do
            --             local currGo = self:GetGo(newGo, v)
            --             currGo:SetActive(v == k_buff)
            --             if v == k_buff then
            --                 self:SetText(currGo, "num", v_buff)
            --             end
            --         end
            --         currIndex = currIndex + 1
            --     end
            -- end
        --end
    end

    local currValue = nil
    local typeName = nil
    local currCfg = nil
    local allBuff = {}
    local typeCfg = {}

    local petSave = {}

    for k,v in pairs(params) do
        currCfg = ShopManager:GetCfg(v)
        currValue,typeName = ShopManager:GetValueByShopId(v)
        --currValue = ShopManager:SetValueToShow(currValue, currCfg)

        if typeName == "pet" or typeName == "emplo" then
            petSave[v] = currValue
            petIconName = currCfg.icon
            petName = currCfg.name and GameTextLoader:ReadText(currCfg.name) or "unknown"
        end

        if typeName ~= "pet" and typeName ~= "emplo" then
            if allBuff[typeName] == nil then
                allBuff[typeName] = 0
                typeCfg[typeName] = currCfg
            end
            allBuff[typeName] = allBuff[typeName] + currValue
        end
        --setNum(currCfg.type, currValue)
    end

    for k,v in pairs(petSave) do
        if v.income then
            if allBuff["income"] == nil then
                allBuff["income"] = 0
                typeCfg["income"] = ShopManager:GetCfg(1010)
            end
            allBuff["income"] = allBuff["income"] + v.income
        end
        if v.offline then
            if allBuff["offline"] == nil then
                allBuff["offline"] = 0
                typeCfg["offline"] = ShopManager:GetCfg(1012)
            end
            allBuff["offline"] = allBuff["offline"] + v.offline
        end
        if v.mood then
            if allBuff["mood"] == nil then
                allBuff["mood"] = 0
                typeCfg["mood"] = ShopManager:GetCfg(1006)
            end
            allBuff["mood"] = allBuff["mood"] + v.mood
        end
    end

    for k,v in pairs( allBuff) do
        currValue = ShopManager:SetValueToShow(v, typeCfg[k])
        setNum(typeCfg[k].type, currValue)
    end

    for i = currIndex, 4 do
        local indexGO = self:GetGoOrNil(BuffRoot, i .. "")
        if indexGO then
            indexGO:SetActive(false)
        end
    end
end

function IntroduceUIView:OnExit()
	self.super:OnExit(self)

    ShopManager:refreshBuySuccess()
	ShopManager:refreshBuyFail()
    if self.effectTimer then
        GameTimer:StopTimer(self.effectTimer)
        self.effectTimer = nil
    end
    if self.closeCB then
        self.closeCB()
        self.closeCB = nil
    end
end

return IntroduceUIView
