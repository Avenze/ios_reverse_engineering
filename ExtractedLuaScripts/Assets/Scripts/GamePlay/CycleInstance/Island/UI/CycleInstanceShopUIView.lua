--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-27 17:15:32
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local Shop = GameTableDefine.Shop
local IAP = GameTableDefine.IAP
local DeviceUtil = CS.Game.Plat.DeviceUtil
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local FeelUtil = CS.Common.Utils.FeelUtil

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local FirstPurchaseUI = GameTableDefine.FirstPurchaseUI

---@class CycleInstanceShopUIView:UIBaseView
local CycleInstanceShopUIView = Class("CycleInstanceShopUIView", UIView)

function CycleInstanceShopUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_dataSize = {}
    self.typeToIndex = {}
    self.m_currentModel = nil ---@type CycleInstanceModel
end

function CycleInstanceShopUIView:OnEnter()
    FirstPurchaseUI:LockEnterShopUITime()
    print("InstanceShopUIView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("RootPanel/title/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.curInstanceLvl = self.m_currentModel:GetCurInstanceKSLevel()
    ShopManager:refreshBuySuccess(function(shopId)
        ShopManager:Buy(shopId, false, function()
            print("InstanceShopUIView:ShopManagerBuy first function")
            -- self.m_list:UpdateData(true) 
            local cfgShop = ConfigMgr.config_shop[shopId]
            -- if cfgShop.type == 12 then
            --     for _, childId in ipairs(cfgShop.param) do
            --         self.m_currentModel:InstanceShopBuySccess(tonumber(childId))
            --         GameTableDefine.InstanceFlyIconManager:StorageShopItem(childId)
            --     end
            -- else
            --     GameTableDefine.InstanceFlyIconManager:StorageShopItem(shopId)
            -- end
            if cfgShop.type == 27 or cfgShop.type == 26 or cfgShop.type == 30 then
                self.m_currentModel:InstanceShopBuySccess(shopId,true)
            end
            self:ShowList(self:UpdateSaleData(), true)
            self:RefreshDiamond()
        end,
        function()
            print("InstanceShopUIView:ShopManagerBuy second function")
            local data = ConfigMgr.config_shop[shopId]
            if data then
                PurchaseSuccessUI:SuccessBuy(shopId,nil,nil,nil,nil,function()
                    --GameTableDefine.InstanceFlyIconManager:ReleaseFlyIcons()
                end)
            end
        end)
    end)
    ShopManager:refreshBuyFail(function(shopId)
        if self.m_list then
            self.m_list:UpdateData(true)
        end
    end)


    if not self.m_currentModel:GetLandMarkCanPurchas() then
        local frame2Go = self:GetGoOrNil("RootPanel/mainview/Viewport/Content/frame2")
        if frame2Go then
            GameObject.Destroy(frame2Go)
        end
    end

    -- self.m_frame1InfoGo = self:GetGo("RootPanel/frame1_info")
    -- self.m_frame1InfoGo:SetActive(false)
    -- self:SetButtonClickHandler(self:GetComp(self.m_frame1InfoGo, "bg", "Button"), function()
    --     self:CloseItemDetaild()
    -- end)

    --初始化列表
    self:InitList()
    self:RefreshDiamond()

    self:SetButtonClickHandler(self:GetComp("frame1_info/bg","Button"),function()
        self:GetGo("frame1_info"):SetActive(false)
    end)
end

function CycleInstanceShopUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
    if self.__timers["TurnPage"] then
        GameTimer:StopTimer(self.__timers["TurnPage"])
        self.__timers["TurnPage"] = nil
    end
    if self.freeGetTimer then
        GameTimer:StopTimer(self.freeGetTimer)
        self.freeGetTimer = nil 
    end
	self.super:OnExit(self)
    FirstPurchaseUI:UnlockEnterShopUITime()
end


function CycleInstanceShopUIView:InitList()
    self.m_list = self:GetComp("RootPanel/mainview", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return #self.m_data
    end)
    self:SetListItemNameFunc(self.m_list, function(index)
        local data = self.m_data[index + 1]
        return data.frame
    end)
    self:SetListItemSizeFunc(self.m_list, function(index)
        if self.m_dataSize[index + 1] then
            return self.m_dataSize[index + 1]
        end
        local data = self.m_data[index + 1]
        if not data then
            return
        end
        local template =  self.m_list:GetItemTemplate(data.frame)
        if template:IsNull() then
            print("data.frame is nil:"..data.frame)
            return
        end
        local rootTrt = template:GetComponent("RectTransform")
        local trt = self:GetComp(template, "sale", "RectTransform")
        local originSize = rootTrt.rect

        -- local si = UnityHelper.GetPreferredSize(self:GetGo(template, "sale"))
        -- print("----->", si, trt.anchoredPosition)
        -- local saleSize = trt.rect
        -- saleSize.height = CS.UnityEngine.UI.LayoutUtility.GetPreferredHeight(trt)
        local gridLayoutGroupEx = self:GetComp(template , "sale", "GridLayoutGroupEx")
        if gridLayoutGroupEx and not gridLayoutGroupEx:IsNull() and data.content then
            local gridSize = gridLayoutGroupEx:GetSize(math.ceil(#data.content/gridLayoutGroupEx:GetConstraintCount()), 1)
            self.m_dataSize[index + 1] = {x = originSize.width, y = (gridSize.y - trt.anchoredPosition.y) + 20}
        else
            local saleSize = trt.rect
            if saleSize.height > 0 then
                self.m_dataSize[index + 1] = {x = originSize.width, y = saleSize.height - trt.anchoredPosition.y + 20}
            else
                self.m_dataSize[index + 1] = {x = originSize.width, y = originSize.height + 20}
            end
        end
        return self.m_dataSize[index + 1]
    end)

    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateListItem))
    self:ShowList(self:UpdateSaleData(), true)
end

function CycleInstanceShopUIView:UpdateSaleData()
    local shopFrameCfg = {}
   
    for i, v in pairs(self.m_currentModel.config_cy_instance_shop) do
        shopFrameCfg[#shopFrameCfg + 1] = v
    end
    table.sort( shopFrameCfg, function (a,b)
        return a.id < b.id
    end )
    local shopCfg = ConfigMgr.config_shop
    local data = {}
    
    for i, v in pairs(shopFrameCfg or {}) do
        local item = Tools:CopyTable(v)
        local isFrame2 = false
        local isFrame1 = false
        for k, m in pairs(item) do
            --item[k] = m
            if m == "frame2" then
                isFrame2 = true
            end
            if m == "frame1" then
                isFrame1 = true
            end
        end
        --需要添加一个特殊的商品用于免费的商品
        if isFrame1 and item.content then
            local freeItemData = {}
            freeItemData.shopID = 0
            freeItemData.limit = 0
            freeItemData.isFree = true
            freeItemData.canUse = self.m_currentModel:CanGetFreeSlotCoin()
            freeItemData.amount = ConfigMgr.config_global.cycle_instance_freeCoinNum
            freeItemData.icon = ConfigMgr.config_global.cycle_instance_freeCoinIcon
            freeItemData.leftTimes = ConfigMgr.config_global.cycle_instance_freeCoinFre - self.m_currentModel:GetCurFreeSlotCoinTimes()
            if freeItemData.leftTimes < 0 then
                freeItemData.leftTimes = 0
            end
            table.insert(item.content, 1, freeItemData)
        end
        if item ~= nil and Tools:GetTableSize(item) > 0 then
            if isFrame2 then
                if self.m_currentModel:GetLandMarkCanPurchas() then
                    table.insert(data, item)
                end
            -- elseif isFrame4 then
            --     local remove = false
            --     for k=#v.content,1,-1 do
            --         local m = v.content[k]
            --         for i=1,1 do    --continue
            --             local shopCfg = ConfigMgr.config_shop[m.shopID]
            --             if not shopCfg then
            --                 table.remove(item.content, k)
            --                 remove = true
            --                 break
            --                 --k = k + 1
            --             end
            --             local canBuy = ShopManager:CheckBuyTimes(m.shopID)
            --             --需要检测其子项能不能购买
            --             local isChildCanNotBuy = not ShopManager:CheckChildShopItemBuyTimes(m.shopID)
            --             if not canBuy or not self:CheckCanGetLvlGift(m.shopID) or not isChildCanNotBuy then
            --                 table.remove(item.content, k)
            --                 remove = true
            --                 break
            --                 --k = k + 1
            --             end 
            --         end
            --     end
            --     if Tools:GetTableSize(item.content) > 0 then
            --         table.insert(data, item)
            --     end
            else
                table.insert(data, item)
            end
        end 
    end 
    return data
end

--对列表的每个item的单独刷新
function CycleInstanceShopUIView:UpdateListItem(i, tran)
    local index = i + 1
    local data = self.m_data[index]
    local go = tran.gameObject

    if data.title then
        self:SetText(go, "title/txt", GameTextLoader:ReadText(data.title))
    end
    if data.desc and tostring(data.desc) ~= "0" then
        print(data.desc)
        self:SetText(go, "title/subtitle/txt", GameTextLoader:ReadText(data.desc))
    end
    --5 钻石月卡
    --6 离线
    --7 新手礼包
    --8 成长礼包
    --11 宠物礼包

    --将frame首字母大写
    local showString = data.frame:gsub("^%l", string.upper)
    showString = "Set" .. showString .. "Details"
    local fun = self[showString]
    if fun then
        fun(self, go, data)
        --调用不同的SetFrameXDetails()
    end
end



function CycleInstanceShopUIView:ShowList(data, refresh)
    self:CleanTimer()
    self.m_data = data
    if refresh then
        self.m_dataSize = {}
        --self:RefreshNaviga()
    end
    self.m_list:UpdateData(true)
end

function CycleInstanceShopUIView:RefreshDiamond()
    local curDiamond = tonumber(GameTableDefine.ResourceManger:GetDiamond())
    self:SetText("RootPanel/title/res/diamondShow/num", Tools:SeparateNumberWithComma(curDiamond))
    GameTableDefine.CycleIslandMainViewUI:Refresh()
end

function CycleInstanceShopUIView:CleanTimer()
    
end

function CycleInstanceShopUIView:SetFrame1Details(go, data)
    print("Set Instance shop frame1")
    local temp = self:GetGo(go, "sale/temp")
    for k = 1, Tools:GetTableSize(data.content) do
        local v = data.content[k]
        --检测当前的免费领取如果当日次数已经没有直接不显示了
        if v.isFree and v.leftTimes <= 0 then
            local flag = 1
        else
            local centGo = self:CheckDataAndGameObject(temp, v, k)
            if centGo then
                self:SetTempItemDetails(centGo, data, v)
            end
        end
    end

end

function CycleInstanceShopUIView:SetFrame3Details(go, data)
    print("Set Instance shop frame3")
    local temp = self:GetGo(go, "sale/temp")
    for k = 1, Tools:GetTableSize(data.content) do
        local v = data.content[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function CycleInstanceShopUIView:SetFrame2Details(go, data)
    print("Set Instance shop frame2")
    local shopId = 0
    local itemGo = self:GetGoOrNil(go, "sale/moaiStatue/content")
    if not itemGo then
        return
    end
    if data.content and Tools:GetTableSize(data.content) then
        shopId = data.content[1].shopID
    end
    if not ShopManager:CheckBuyTimes(shopId) then
        go:SetActive(false)
        return
    end
    local canBuy = ShopManager:CheckBuyTimes(shopId)
    local shopCfg = ConfigMgr.config_shop[shopId]
    if not shopCfg or not shopCfg.diamond then
        go:SetActive(false)
        return
    end
    --添加当前的副本地标购买检测
    go:SetActive(self.m_currentModel:GetLandMarkCanPurchas())
    -- "InstanceNewShopUI(Clone)/RootPanel/mainview/Viewport/Content/frame2/sale/moaiStatue/content/dBtn/text"
    self:SetText(go, "sale/moaiStatue/content/dBtn/text", tostring(shopCfg.diamond))
    if canBuy then
        go:SetActive(true)
        local enoughDiamond = false
        local btn = self:GetComp(go, "sale/moaiStatue/content/dBtn", "Button")
        if GameTableDefine.ResourceManger:GetDiamond() >= shopCfg.diamond then
            enoughDiamond = true
        else
            enoughDiamond = false
        end
        self:SetButtonClickHandler(btn, function()
            if enoughDiamond then
                ShopManager:Buy(shopId, false, function()
                    GameObject.Destroy(go)
                    for i, v in ipairs(self.m_data) do
                        if i == 3 then
                            table.remove(self.m_data, i)
                            break
                        end
                    end
                    self:ShowList(self:UpdateSaleData(), true)
                    self.m_list:ScrollToTop(99)
                    self:RefreshDiamond()
                    self:DestroyModeUIObject()
                    self.m_currentModel:BuySpecialGameObjectAnimationPlay()
                    self.m_currentModel:SetLandMarkCanPurchas()
                end,
                function()
                    -- PurchaseSuccessUI:SuccessBuy(shopId)
                end)
            else
                self.m_list:ScrollTo(99,10)
            end
        end)
    else
        local btn = self:GetComp(go, "sale/moaiStatue/content/dBtn", "Button")
        if btn then
            btn.interactable = false
        end
    end
end

function CycleInstanceShopUIView:SetFrame4Details(go, data)
    local itemsName = {}
    local curGiftContent = {}
    for i, v in pairs(data.content) do
        local shopCfg = ConfigMgr.config_shop[v.shopID]
        if shopCfg then
            -- local canBuy, value ,type = ShopManager:Buy(v.shopID, true)
            -- local timeCanBuy = ShopManager:CheckBuyTimes(v.shopID)
            -- local isChildCanNotBuy = not ShopManager:CheckChildShopItemBuyTimes(v.shopID)
            -- if canBuy and self:CheckCanGetLvlGift(v.shopID) and timeCanBuy and isChildCanNotBuy then
            --     table.insert(curGiftContent, v)
            -- end
            table.insert(curGiftContent, v)
            table.insert(itemsName,""..v.shopID)
        end 
    end
    if Tools:GetTableSize(curGiftContent) <= 0 then
        go:SetActive(false)
        return
    end
    go:SetActive(true)
    local saleTrans = self:GetGo(go, "sale").transform
    local childCount = saleTrans.childCount
    for i=0,childCount -1 do
        saleTrans:GetChild(i).gameObject:SetActive(false)
    end
    for _, itemName in ipairs(itemsName) do
        local tmpGo = self:GetGo(go, "sale/"..itemName)
        tmpGo:SetActive(false)
        for k, v in ipairs(curGiftContent) do
            if v.shopID == tonumber(itemName) then
                local shopCfg = ConfigMgr.config_shop[v.shopID]
                if shopCfg then
                    local trackPrice = 0
                    if shopCfg.iap_id then
                        local price = Shop:GetShopItemPrice(shopCfg.id)
                        local priceOriginal, priceNum, comma = IAP:GetPriceDouble(shopCfg.id)
                        trackPrice = Shop:GetShopItemPrice(shopCfg.id, true)
                        local cheatPrice = 0
                        local discount = GameTableDefine.IntroduceUI:GetDiscountByShopId(shopCfg.id)
                        if priceNum then
                            cheatPrice = tonumber(priceNum) / (1 - discount)
                        end
                        if GameDeviceManager:IsiOSDevice() then
                            if cheatPrice == 0 then
                                cheatPrice = priceOriginal
                            elseif tonumber(cheatPrice) then
                                cheatPrice = DeviceUtil.InvokeNativeMethod("formaterPrice", cheatPrice)
                            end
                        else
                            if priceNum then
                                local head = string.gsub(priceOriginal, "%p", "")
                                head = string.gsub(head, "%d", "")
                                local back = ""
                                if comma then
                                    local cheatPriceInt = math.floor(cheatPrice)
                                    local cheatPriceStr = tostring(cheatPrice)
                                    local digitDiff = #cheatPriceStr - #priceNum
                                    back = cheatPriceStr
                                    for k1, v1 in pairs(comma) do
                                        local front = string.sub(back, 1, k1 + digitDiff - 1)
                                        local after = string.sub(back, k1 + digitDiff)
                                        back = front..v1..after
                                    end
                                end
                                cheatPrice = head..back
                            else
                                cheatPrice = priceOriginal
                            end
                        end
                        self:SetText(tmpGo, "content/mBtn/text", price)
                    end
                    tmpGo:SetActive(true)
                    local btn = self:GetComp(tmpGo, "content/mBtn", "Button")
                    btn.interactable = true
                    self:SetButtonClickHandler(self:GetComp(tmpGo, "content/mBtn", "Button"), function()
                        btn.interactable = false
                        local shopID = tonumber(itemName)
                        if data.info and data.info > 0 then
                            self:ShowItemDetails(data, v, 0)
                        else
                            GameSDKs:TrackForeign("store", {source = 3, operation_type = 1, product_id = IAP:GetPurchaseId(shopCfg.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) or 0})
                            Shop:CreateShopItemOrder(v.shopID, btn)
                        end
                    end)
                    break;
                end
                
            end
        end
    end

    -- local temp = self:GetGo(go, "sale/temp")
    -- for k = 1, Tools:GetTableSize(curGiftContent) do
    --     local v = data.content[k]
    --     local centGo = self:CheckDataAndGameObject(temp, v, k)
    --     if centGo then
    --         self:SetTempItemDetails(centGo, data, v)
    --     end
    -- end
end

function CycleInstanceShopUIView:SetFramePesoDetails(go, data)
    print("Set Instance shop frame5")
    local temp = self:GetGo(go, "sale/temp")

    self:GetGo(go,"offvalue"):SetActive(self.m_currentModel:IsLastOneDay())
    self:SetText(go, "offvalue/num", string.format("-%d%%", self.m_currentModel:GetLastOneDayDiscount() * 100))

    for k = 1, Tools:GetTableSize(data.content) do
        local v = data.content[k]
        local shopV = ConfigMgr.config_shop[v.shopID]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        local time = shopV.amount * 60 * 60
        local resReward, money = self.m_currentModel:CalculateOfflineRewards(time,false,false)
        self:SetText(centGo, "info/num", Tools:SeparateNumberWithComma(money))
        local image = self:GetComp(centGo,"icon","Image")
        self:SetSprite(image,"UI_Shop",shopV.icon)
        self:SetText(centGo, "dBtn/text", shopV.diamond)
        local canBuy, value, type = ShopManager:Buy(shopV.id, true)
        local buyButton = self:GetComp(centGo, "dBtn", "Button")

        local isInstanceLastOneDay = self.m_currentModel:IsLastOneDay()
        if (shopV.type == 22 or shopV.type == 25) and isInstanceLastOneDay then
            buyButton.gameObject:SetActive(not isInstanceLastOneDay)
            buyButton = self:GetComp(centGo, "dBtn_sale", "Button")
            buyButton.gameObject:SetActive(isInstanceLastOneDay)
            
            self:SetText(buyButton.gameObject, "price_old/text", Tools:SeparateNumberWithComma(math.ceil(shopV.diamond)))
            self:SetText(buyButton.gameObject, "price_new/text", Tools:SeparateNumberWithComma(math.ceil(shopV.diamond * (1-self.m_currentModel:GetLastOneDayDiscount()))))
        end
        buyButton.interactable = canBuy
        self:SetButtonClickHandler(
            buyButton,
            function()
                if canBuy then
                    ShopManager:Buy(shopV.id, false, function()
                        GameObject.Destroy(go)
                        for i, v in ipairs(self.m_data) do
                            if i == 3 then
                                table.remove(self.m_data, i)
                                break
                            end
                        end
                        self.m_list:ScrollTo(99)
                        self:RefreshDiamond()
                        self.m_currentModel:AddCurInstanceCoin(value,true)
                        self:ShowList(self:UpdateSaleData(), true)
                        --GameTableDefine.InstanceFlyIconManager:StorageShopItem(shopV.id)
                    end, 
                            function()
                                PurchaseSuccessUI:SuccessBuy(shopV.id,nil,nil,nil,nil,function()
                                    --GameTableDefine.InstanceFlyIconManager:ReleaseFlyIcons()
                                end)
                            end)
                end
            end
        )

    end
end


function CycleInstanceShopUIView:CheckDataAndGameObject(temp, data, index)
    local trans = temp.transform.parent
    local go = trans.gameObject
    local centTrans = self:GetTrans(go, "temp_"..index)
    temp:SetActive(false)
    if data then
        if not centTrans or centTrans:IsNull() then
            local newGo = GameObject.Instantiate(temp, trans)
            newGo.name = "temp_"..index
            newGo:SetActive(true)
            return newGo
        else
            centTrans.gameObject:SetActive(true)
        end
        return centTrans.gameObject
    else
        if centTrans and not centTrans:IsNull() then
            centTrans.gameObject:SetActive(false)
        end
        return nil
    end
end

function CycleInstanceShopUIView:SetTempItemDetails(centGo, rootData, data)
    if data.isFree then
        local fBtn = self:GetComp(centGo, "fBtn", "Button")
        local mBtn = self:GetComp(centGo, "mBtn", "Button")
        local dBtn = self:GetComp(centGo, "dBtn", "Button")
        mBtn.gameObject:SetActive(false)
        dBtn.gameObject:SetActive(false)
        fBtn.gameObject:SetActive(true)
        fBtn.interactable = data.canUse

        if self.freeGetTimer then
            GameTimer:StopTimer(self.freeGetTimer)
            self.freeGetTimer = nil 
        end
        if not data.canUse and data.amount ~= 0 then
            self:GetGo(centGo, "timeRes/num"):SetActive(false)
            self:GetGo(centGo, "timeRes/text"):SetActive(false)
            self:GetGo(centGo, "timeRes/time"):SetActive(true)
            self.freeGetTimer = GameTimer:CreateNewTimer(1, function()
                local timeStr =  GameTimeManager:FormatTimeLength(self.m_currentModel:GetSlotFreeCoinCDTime())
                self:SetText(centGo, "timeRes/time", timeStr) 
            end, true, true)
        else
            self:GetGo(centGo, "timeRes/num"):SetActive(true)
            self:GetGo(centGo, "timeRes/text"):SetActive(true)
            self:GetGo(centGo, "timeRes/time"):SetActive(false)
        end
        --可领取数量
        self:SetText(centGo, "propDesc/numAndBuff", data.amount or 0)
        self:SetText(centGo, "propDesc/numAndBuff_white", data.amount or 0)
        --图标
        self:SetSprite(self:GetComp(centGo, "icon", "Image"), "UI_Shop", data.icon)
        --每日可领取次数
        self:SetText(centGo, "timeRes/num", data.leftTimes)
        self:SetButtonClickHandler(fBtn, function()
            fBtn.interactable = false
            if self.m_currentModel:GetOneTimeSlotFreeCoin(true) then
                self:ShowList(self:UpdateSaleData(), true)
            else
                fBtn.interactable = true
            end
        end)
        local bg2Go = self:GetGoOrNil(centGo, "bg2")
        local bgGo = self:GetGoOrNil(centGo, "bg")
        if bg2Go then
            bg2Go:SetActive(true)
        end
        if bgGo then
            bgGo:SetActive(false)
        end
        return
    end
    local v = ConfigMgr.config_shop[data.shopID]
    local slotTxtGo = self:GetGoOrNil(centGo, "propDesc/numAndBuff")
    local skillTxtGo = self:GetGoOrNil(centGo, "propDesc/numAndBuff_white")
    if slotTxtGo then
        slotTxtGo:SetActive(v.type == 30)
    end
    if skillTxtGo then
        skillTxtGo:SetActive(v.type == 26 or v.type == 27)
    end
    if v.name then
        self:SetText(centGo, "name", GameTextLoader:ReadText(v.name))
    end
    if v.desc then
        self:SetText(centGo, "desc", GameTextLoader:ReadText(v.desc))
    end
    local timeResGo = self:GetGoOrNil(centGo, "timeRes")
    if timeResGo then
        timeResGo:SetActive(data.limit > 0)
        local leftNum = data.limit - self.m_currentModel:GetBuySkillTimes(data.shopID)
        if leftNum < 0 then
            leftNum = 0
        end
        self:SetText(centGo, "timeRes/num", leftNum)
    end
    --可领取数量
    self:SetText(centGo, "propDesc/numAndBuff", v.amount)
    self:SetText(centGo, "propDesc/numAndBuff_white", v.amount)
    local value = GameTableDefine.ShopManager:GetValueByShopId(data.shopID)

    if v.type == 3 then
        local isFirstDouble = FirstPurchaseUI:IsFirstDouble(data.shopID)
        if isFirstDouble then
            value = math.floor(value / 2 )
        end
        local doubleGo = self:GetGoOrNil(centGo, "double")
        if doubleGo then
            doubleGo:SetActive(isFirstDouble)
        end
    end

    local valueShow = GameTableDefine.ShopManager:SetValueToShow(value, v)

    if v.type == 13 or v.type == 14 then
        for k, v in pairs(valueShow) do
            valueShow = v
            break
        end
    end
    
    if (v.type == 22 or v.type == 25) then
        self:GetGo(centGo,"offvalue"):SetActive(self.m_currentModel:IsLastOneDay())
        self:SetText(centGo, "offvalue/num", string.format("-%d%%", self.m_currentModel:GetLastOneDayDiscount() * 100))
    end
    self:SetText(centGo, "diamondNum/num", valueShow)
    self:SetSprite(self:GetComp(centGo, "icon", "Image"), "UI_Shop", v.icon)
    local btn = nil
    local btnDiamond = self:GetComp(centGo, "dBtn", "Button")
    local btnCash = self:GetComp(centGo, "mBtn", "Button")
    local iconBtn = self:GetComp(centGo, "icon", "Button")
    btnDiamond.gameObject:SetActive(v.diamond ~= nil)
    if btnCash then
        btnCash.gameObject:SetActive(v.iap_id ~= nil)
    end
    local btn = btnDiamond
    if v.iap_id and btnCash then
        btn = btnCash
    end

    local bg2Go = self:GetGoOrNil(centGo, "bg2")
    
    local limitEnough = ShopManager:CheckBuyTimes(data.shopID, data.amount)
    if v.iap_id then
        btn.interactable = limitEnough
    elseif v.diamond then
        local bgGo = self:GetGoOrNil(centGo, "bg")
        if bg2Go then
            bg2Go:SetActive(false)
        end
        if bgGo then
            bgGo:SetActive(true)
        end
            btn.interactable = true
        end
    if data.limit > 0 then
        btn.interactable = (data.limit - self.m_currentModel:GetBuySkillTimes(data.shopID)) > 0
    end
    if v.iap_id then
        local price = Shop:GetShopItemPrice(v.id)
        local priceOriginal, priceNum, comma = IAP:GetPriceDouble(v.id)
        local trackPrice = Shop:GetShopItemPrice(v.id, true)
        local discount = GameTableDefine.IntroduceUI:GetDiscountByShopId(v.id)
        if discount <= 0 then
            discount = 0
        end
        self:SetText(centGo, "content/offvalue/num", math.floor(discount * 100).."%".."\n".."Off")

        local cheatPrice = 0
        if priceNum then
            cheatPrice = tonumber(priceNum) / (1 - discount)
        end
        if GameDeviceManager:IsiOSDevice() then
            if cheatPrice == 0 then
                cheatPrice = priceOriginal
            elseif tonumber(cheatPrice) then
                cheatPrice = DeviceUtil.InvokeNativeMethod("formaterPrice", cheatPrice)
            end
        else
            if priceNum then
                local head = string.gsub(priceOriginal, "%p", "")
                head = string.gsub(head, "%d", "")
                local back = ""
                if comma then
                    local cheatPriceInt = math.floor(cheatPrice)
                    local cheatPriceStr = tostring(cheatPrice)
                    local digitDiff = #cheatPriceStr - #priceNum
                    back = cheatPriceStr
                    for k, v in pairs(comma) do
                        local front = string.sub(back, 1, k + digitDiff - 1)
                        local after = string.sub(back, k + digitDiff)
                        back = front..v..after
                    end
                end
                cheatPrice = head..back
            else
                cheatPrice = priceOriginal
            end
        end
        self:SetText(btn.gameObject, "common", cheatPrice)
        self:SetText(btn.gameObject, "text", price)

        self:SetButtonClickHandler(btn, function()
            btn.interactable = false
            if rootData.info and rootData.info > 0 then
                self:ShowItemDetails(rootData, v, valueShow)
            else
                GameSDKs:TrackForeign("store", {source = 3, operation_type = 1, product_id = IAP:GetPurchaseId(v.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) or 0})
                Shop:CreateShopItemOrder(data.shopID, btn)
            end
        end)
    elseif v.diamond then
        self:SetText(btn.gameObject, "text", Tools:SeparateNumberWithComma(v.diamond))

        --每个商店获取的资源类型的图标显示
        local calTime = 0
        local shopCfg = ConfigMgr.config_shop[data.shopID]
        if shopCfg and shopCfg.param and Tools:GetTableSize(shopCfg.param) > 0 and tonumber(shopCfg.param[1]) then
            calTime = tonumber(shopCfg.param[1]) * 60
        end
    
        if calTime > 0 then
            local itemInfo = GameTableDefine.self.m_currentModel:GetCurProductionsByTime(calTime)
            local icon2Go = self:GetGoOrNil(centGo, "info/icon2")
            local icon3Go = self:GetGoOrNil(centGo, "info/icon3")
            if icon2Go then
                icon2Go:SetActive(false)
            end
            if icon3Go then
                icon3Go:SetActive(false)
            end
            for i, v in ipairs(itemInfo or {}) do
                if i > 3 then
                    break
                end
                local resCfg = self.m_currentModel.resourceConfig[v.resourcesID]
                if resCfg then
                    if i == 1 then
                        self:SetSprite(self:GetComp(centGo, "info/icon", "Image"), "UI_Common", resCfg.icon)
                    elseif i == 2 and icon2Go then
                        self:SetSprite(self:GetComp(centGo, "info/icon2","Image"), "UI_Common", resCfg.icon)
                        icon2Go:SetActive(true)
                    elseif i == 3 and icon3Go then
                        self:SetSprite(self:GetComp(centGo, "info/icon3","Image"), "UI_Common", resCfg.icon)
                        icon3Go:SetActive(true)
                    end
                end
            end
        end
        local canBuy, value ,type = ShopManager:Buy(data.shopID, true)
        local function DiamondClick(selectData,_rootData)
            --判断一下当前是不是技能购买，如果是的话是有购买限制的
            if type == 27 and data.limit - self.m_currentModel:GetBuySkillTimes(data.shopID) <= 0 then
                return
            end
            self:ShowConfirmPanel(selectData,function()
                canBuy,value ,type = ShopManager:Buy(selectData.id, true)
                if canBuy then
                    --买得起
                    ShopManager:Buy(selectData.id, false, function()
                        print("InstanceShopUIView:ShopManagerBuy first function")
                        local data = ConfigMgr.config_shop[selectData.id]
                        if data then
                            local cfgShop = ConfigMgr.config_shop[selectData.id]
                            if cfgShop.type == 27 or cfgShop.type == 26 or cfgShop.type == 30 then
                                self.m_currentModel:InstanceShopBuySccess(selectData.id,false,true)
                            end
                            self:ShowList(self:UpdateSaleData(), true)
                            self:RefreshDiamond()
                            
                        end
                    end,
                            function()
                                print("InstanceShopUIView:ShopManagerBuy second function")
                            end)
                else
                    --买不起，跳转到钻石
                    self.m_list:ScrollTo(99,10)
                end
                self:HideConfirmPanel()
            end)
        end
        local isInstanceLastOneDay = self.m_currentModel:IsLastOneDay()
        if (v.type == 22 or v.type == 25) and isInstanceLastOneDay then
            self:SetText(btn.gameObject, "text", Tools:SeparateNumberWithComma(math.ceil(v.diamond * self.m_currentModel:GetLastOneDayDiscount())))
            btn.gameObject:SetActive(not isInstanceLastOneDay)
            btn = self:GetComp(centGo, "dBtn_sale", "Button")
            btn.gameObject:SetActive(isInstanceLastOneDay)
            
            self:SetText(btn.gameObject, "price_old/text", Tools:SeparateNumberWithComma(math.ceil(v.diamond )))
            self:SetText(btn.gameObject, "price_new/text", Tools:SeparateNumberWithComma(math.ceil(v.diamond * (1-self.m_currentModel:GetLastOneDayDiscount()))))
        end

        self:GetGo(centGo, "propDesc/descTimeText"):SetActive(v.type == 26)
        --判断一下当前是不是技能购买，如果是的话是有购买限制的
        if data.limit > 0 and type == 27 and data.limit - self.m_currentModel:GetBuySkillTimes(data.shopID) <= 0 then
            canBuy = false
            btn.interactable = false
            if iconBtn then
                iconBtn.interactable = false
            end
        end
        --btn.interactable = canBuy
        self:SetButtonClickHandler(btn, function()
            DiamondClick(v,rootData)
        end)
        if iconBtn then
            self:SetButtonClickHandler(iconBtn, function()
                DiamondClick(v,rootData)
            end)
        end
    end
end

function CycleInstanceShopUIView:ShowItemDetails(rootData, data, valueShow)
    if not self.m_frame1InfoGo then
        return
    end
    self.m_frame1InfoGo:SetActive(true)
    -- local feel = self:GetComp(self.m_frame1InfoGo, "openFeedback", "MMFeedbacks")
    -- FeelUtil.PlayFeel(feel.gameObject)

    self:SetSprite(self:GetComp(self.m_frame1InfoGo, "info/content/bg/item/icon", "Image"), "UI_Shop", data.icon)
    self:SetButtonClickHandler(self:GetComp(self.m_frame1InfoGo,  "bg", "Button"), function()
        self:CloseItemDetaild()
    end)

    local calTime = 0
    if data.param and Tools:GetTableSize(data.param) > 0 and tonumber(data.param[1]) then
        calTime = tonumber(data.param[1]) * 60
        local titleStr = string.format(GameTextLoader:ReadText(data.name), tostring(data.param[1]))
        self:SetText(self.m_frame1InfoGo, "info/content/bg/item/name", titleStr)
        local descStr = string.format(GameTextLoader:ReadText("TXT_INSTANCE_SHOP_Time_DESC"), tostring(data.param[1]))
        self:SetText(self.m_frame1InfoGo, "info/content/bg/item/desc", descStr)
    end

    if calTime <= 0 then
        self:CloseItemDetaild()
        return
    end
    local itemInfo = GameTableDefine.self.m_currentModel:GetCurProductionsByTime(calTime)
    self.m_detailItemGo = {}
    local parent = self:GetTrans("info/content/bg/income/content")
    local itemGo = self:GetGoOrNil("info/content/bg/income/content/item")
    if itemGo then
        -- itemGo.name = "item1"
        table.insert(self.m_detailItemGo, itemGo)
    end
    if Tools:GetTableSize(itemInfo) > 1 then
        for i = 2, Tools:GetTableSize(itemInfo) do
            local tmpItemGo = GameObject.Instantiate(itemGo, parent)
            tmpItemGo.name = "item"..i
            table.insert(self.m_detailItemGo, tmpItemGo)
        end
    end
   
    -- tmpData.resourcesID = key
    -- tmpData.amount = math.floor(math.random(1, 4) * (timeSeconds / 60))
    for i, v in ipairs(itemInfo or {}) do
        local resCfg = self.m_currentModel.resourceConfig[v.resourcesID]
        if i <= Tools:GetTableSize(self.m_detailItemGo) and resCfg then
            local resItemGo = self.m_detailItemGo[i]
            self:SetSprite(self:GetComp(resItemGo, "icon", "Image"), "UI_Common", resCfg.icon)
            self:SetText(resItemGo, "bg/num", Tools:SeparateNumberWithComma(math.floor(v.amount)))    
        end
    end
    if rootData.name then
        self:SetText(self.m_frame1InfoGo, "title/txt", GameTextLoader:ReadText(rootData.name))
    end
    local btn = self:GetComp(self.m_frame1InfoGo, "info/content/bg/income/BuyBtn", "Button")
    self:SetText("info/contentbg/income/BuyBtn/text", tostring(data.diamond))
    if not data.diamond then
        self:CloseItemDetaild()
        return
    end
    self:SetText(self.m_frame1InfoGo, "info/content/bg/income/BuyBtn/text", Tools:SeparateNumberWithComma(data.diamond))
    local canBuy, value, type = ShopManager:Buy(data.id, true)
    btn.interactable = canBuy
    self:SetButtonClickHandler(btn, function()
        btn.interactable = false
        GameSDKs:TrackForeign("store", {source = 3, operation_type = 1, product_id = data.id, pay_type = 3, cost_num_new = tonumber(data.diamond) or 0})
        self:CloseItemDetaild()
        if canBuy then
            ShopManager:Buy(data.id, false, function()
                local curResGetData = {}
                for k, v in ipairs(itemInfo) do
                    local resEle = {}
                    resEle[v.resourcesID] = v.amount
                    curResGetData[v.resourcesID] = resEle
                end
                if Tools:GetTableSize(curResGetData) > 0 then
                    -- GameTableDefine.InstanceDataManager:AddProdutionsData(curResGetData)
                end
                GameTableDefine.InstanceFlyIconManager:StorageShopItem(data.id)
                btn.interactable = true
                self.m_list:UpdateData(true)
                self:RefreshDiamond()
            end,
            function()
                local data = ConfigMgr.config_shop[data.id]
                if data then
                    PurchaseSuccessUI:SuccessBuy(data.id,nil,nil,nil,nil,function()
                        GameTableDefine.InstanceFlyIconManager:ReleaseFlyIcons()
                    end)
                end
            end)
        else
            GameSDKs:TrackForeign("store", {source = 3, operation_type = 3, product_id = IAP:GetPurchaseId(data.diamond), pay_type = 3, cost_num_new = tonumber(data.diamond) or 0})
            self:CloseItemDetaild()
            btn.interactable = true
        end
    end)
end

function CycleInstanceShopUIView:CloseItemDetaild()
    if self.m_detailItemGo and Tools:GetTableSize(self.m_detailItemGo) > 0 then
        for i, go in ipairs(self.m_detailItemGo) do
            if i ~= 1 then
                GameObject.Destroy(go)
            end
        end
        self.m_detailItemGo = nil
        
    end
    -- local feel = self:GetGo(self.m_frame1InfoGo, "closeFeedback")
    -- FeelUtil.PlayFeel(feel)
    self.m_frame1InfoGo:SetActive(false)
end

function CycleInstanceShopUIView:EnterToSpecial()
    if self.m_list then
        self.m_list:ScrollTo(3, 99)
    end
end

--检测是否能购买对应等级的礼包
function CycleInstanceShopUIView:CheckCanGetLvlGift(shopID)
    local resultID = 0
    local instanceBind = CycleInstanceDataManager:GetInstanceBind()
    for k, v in ipairs(self.m_currentModel.config_achievement_instance) do
        if shopID == instanceBind.landmark_gift then
            return true
        end
        if v.pack > 0 and v.pack == shopID and self.curInstanceLvl >= v.level then
            return true
        end
    end
    return false
end

function CycleInstanceShopUIView:TurnPage(index)
    if self.__timers["TurnPage"] then
        GameTimer:StopTimer(self.__timers["TurnPage"])
        self.__timers["TurnPage"] = nil
    end
    self.__timers["TurnPage"] = GameTimer:CreateNewTimer(0.5, function()--wait list init
        self.m_list:ScrollTo(index or 0, 2)
    end)
end

---显示购买确认界面
function CycleInstanceShopUIView:ShowConfirmPanel(shopConfig,confirmCallback)
    local frame1Panel = self:GetGoOrNil("frame1_info")
    if frame1Panel then
        self:SetText(frame1Panel,"info/title/txt",GameTextLoader:ReadText(shopConfig.name))
        local iconImage = self:GetComp(frame1Panel,"info/item/icon","Image")
        self:SetSprite(iconImage,"UI_Shop",shopConfig.icon)
        local displayNum = shopConfig.amount
        if shopConfig.type == 26 then
            displayNum = BigNumber:FormatBigNumber(shopConfig.amount * self.m_currentModel:GetExpOutputPerMin())
        end
        self:SetText(frame1Panel,"info/item/bg/num",displayNum)
        self:SetText(frame1Panel,"info/BuyBtn/text",shopConfig.diamond)
        local buyBtn = self:GetComp(frame1Panel,"info/BuyBtn","Button")
        self:SetButtonClickHandler(buyBtn,function()
            if confirmCallback then
                confirmCallback()
            end
        end)
        frame1Panel:SetActive(true)
    else
        if confirmCallback then
            confirmCallback()
        end
    end
end

---隐藏购买确认界面
function CycleInstanceShopUIView:HideConfirmPanel()
    local frame1Panel = self:GetGoOrNil("frame1_info")
    if frame1Panel then
        frame1Panel:SetActive(false)
    end
end

return CycleInstanceShopUIView