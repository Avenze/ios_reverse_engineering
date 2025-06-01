local ShopUI = GameTableDefine.ShopUI
local ConfigMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local CfgMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI
local ShopManager = GameTableDefine.ShopManager
local CityMode = GameTableDefine.CityMode
local TimerMgr = GameTimeManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local ActivityUI = GameTableDefine.ActivityUI
local EventManager = require("Framework.Event.Manager")
local CountryMode = GameTableDefine.CountryMode
local IAP = GameTableDefine.IAP
local FirstPurchaseUI = GameTableDefine.FirstPurchaseUI

function ShopUI:GetView()
    --TEMPLATE 构建测试数据
    --印尼"IDR 429,000.00"
    --日本"JP¥ 3,440"
    -- local testData = {
    --     iap_price = {
    --         ["ad_free_pack"]= "JP¥ 3,440",
    --         ["cat_black"]= "JP¥ 3,440",
    --         ["chihuahua_black"]= "JP¥ 3,440",
    --         ["chihuahua_brown"]= "JP¥ 3,440",
    --         ["christmaselk"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.baoan.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.baoan.999"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.bonus.1199"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.bonus.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.coupon.399"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.coupon.799"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.coupon.99"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.dia.1199"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.dia.12499"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.dia.2499"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.dia.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.dia.5999"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.dia.99"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.diapack1.299"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.diapack2.899"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.diapack3.1099"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.diapack4.1199"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.diapack5.2999"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.diapack6.3099"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.monthdia.299"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.noads.1599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.offline.1199"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.offline.2499"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.offline.299"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.offline.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet1.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet2.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet3.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet4.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet5.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet6.999"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet7.999"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.pet8.1199"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack2.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack3.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack4.599"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack5.699"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack6.699"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack7.799"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack8.799"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.premiumpack9.999"]= "JP¥ 3,440",
    --         ["com.idle.property.real.estate.tycoon.mogul.starterpack.199"]= "JP¥ 3,440",
    --         ["costume_deer"]= "JP¥ 3,440",
    --         ["costume_santaclaus"]= "JP¥ 3,440",
    --         ["costume_yeti"]= "JP¥ 3,440",
    --         ["diamondpass"]= "JP¥ 3,440",
    --         ["elk"]= "JP¥ 3,440",
    --         ["employees_eros"]= "JP¥ 3,440",
    --         ["employees_lover"]= "JP¥ 3,440",
    --         ["ghost_cat"]= "JP¥ 3,440",
    --         ["ghost_knight"]= "JP¥ 3,440",
    --         ["ghost_lady"]= "JP¥ 3,440",
    --         ["golden_retriever"]= "JP¥ 3,440",
    --         ["growth_fund"]= "JP¥ 3,440",
    --         ["growth_fund_new"]= "JP¥ 3,440",
    --         ["husky_black"]= "JP¥ 3,440",
    --         ["husky_gray"]= "JP¥ 3,440",
    --         ["managerpack"]= "JP¥ 3,440",
    --         ["newyearreward_node_1"]= "JP¥ 3,440",
    --         ["newyearreward_node_2"]= "JP¥ 3,440",
    --         ["newyearreward_node_3"]= "JP¥ 3,440",
    --         ["newyearreward_node_4"]= "JP¥ 3,440",
    --         ["newyearreward_node_5"]= "JP¥ 3,440",
    --         ["newyearreward_pack_1"]= "JP¥ 3,440",
    --         ["newyearreward_pack_2"]= "JP¥ 3,440",
    --         ["penguin"]= "JP¥ 3,440",
    --         ["pet_bordercollie"]= "JP¥ 3,440",
    --         ["pet_bordercolliewhite"]= "JP¥ 3,440",
    --         ["petpack"]= "JP¥ 3,440",
    --         ["piggy_bank_1"]= "JP¥ 3,440",
    --         ["piggy_bank_10"]= "JP¥ 3,440",
    --         ["piggy_bank_11"]= "JP¥ 3,440",
    --         ["piggy_bank_2"]= "JP¥ 3,440",
    --         ["piggy_bank_3"]= "JP¥ 3,440",
    --         ["piggy_bank_4"]= "JP¥ 3,440",
    --         ["piggy_bank_5"]= "JP¥ 3,440",
    --         ["piggy_bank_6"]= "JP¥ 3,440",
    --         ["piggy_bank_7"]= "JP¥ 3,440",
    --         ["piggy_bank_8"]= "JP¥ 3,440",
    --         ["piggy_bank_9"]= "JP¥ 3,440",
    --         ["premiumpack1"]= "JP¥ 3,440",
    --         ["premiumpack10"]= "JP¥ 3,440",
    --         ["premiumpack10_new"]= "JP¥ 3,440",
    --         ["rabbit_brown"]= "JP¥ 3,440",
    --         ["shop_diamond_12000"]= "JP¥ 3,440",
    --         ["shop_diamond_1800"]= "JP¥ 3,440",
    --         ["shop_diamond_300"]= "JP¥ 3,440",
    --         ["shop_diamond_30000"]= "JP¥ 3,440",
    --         ["shop_diamond_3600"]= "JP¥ 3,440",
    --         ["shop_diamond_5000"]= "JP¥ 3,440",
    --         ["thanksgiving_festival_pack"]= "JP¥ 3,440",
    --         ["thanksgiving_resource_pack"]= "JP¥ 3,440",
    --     }
    -- }
    
    -- IAP:SetPrice(testData.iap_price)

    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.SHOP_UI, self.m_view, require("GamePlay.Shop.ShopUIView"), self, self.CloseView)
    return self.m_view
end

function ShopUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.SHOP_UI)
    self.m_view = nil
    self.shopidToIndex = nil
    self.currTime = nil
    collectgarbage("collect")
end

function ShopUI:EnterShop(refresh)--是否更新下面的导航页签
    --shopFrameCfg--货架信息
    local shopFrameCfg = ConfigMgr.config_shop_frame
    --商品列表--shopCfg
    local shopCfg = ConfigMgr.config_shop
    --
    local data = {} -- {frame="frame0"}
    local specialFrame = {["frame7"] = true, ["frame8"] = true, ["frame10"] = true, ["frame11"] = true, ["frame14"] = true}

    for i,v in ipairs(shopFrameCfg or {}) do
        local item = nil

        
       --------??---------
        if not specialFrame[v.frame] then
            item = {}
            for k,m in pairs(v) do
                item[k] = m
            end
        else

            if v.frame == "frame7" then--新手礼包
                local realContent = {}
                local contentIndex = {}
                local currTime = TimerMgr:GetCurrentServerTime()
                --设置互斥购买
                for k, v in pairs(v.contents or {}) do
                    local tmpCanBuy = ShopManager:EnableBuy(v.id)
                    local buyTimes = ShopManager:CheckBuyTimes(v.id)
                    if (not tmpCanBuy) and not buyTimes then
                        ShopManager:SetBuyExclusionShopItem(v.id)
                    end
                end
                local canBuy
                for k,v in pairs(v.contents or {}) do
                    canBuy = ShopManager:canBuyNewGift(v.id, currTime)
                    if canBuy then
                        table.insert(realContent, v)
                        table.insert(contentIndex, k)
                    end
                end

                if #realContent > 0 then
                    item = {}
                    for k,m in pairs(v) do
                        item[k] = m
                    end

                    item["contents"] = realContent
                    item["contentIndex"] = contentIndex
                end
            elseif v.frame == "frame8" then--成长礼包
                local allBuy = true
                local realContent = {}
                local contentIndex = {}
                for k,v in pairs(v.contents or {}) do
                    if not ShopManager:BoughtBefor(v.id) then
                        allBuy = false
                        break
                    end
                end

                -- if not allBuy then
                --     item = {}
                --     for k,m in pairs(v) do
                --         item[k] = m
                --     end
                -- end
                if not allBuy then
                    for k, v in pairs(v.contents or {}) do
                        local canBuy = ShopManager:EnableBuy(v.id) and not ShopManager:CheckShopItemTimeLimit(v.id)
                        local isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(v.id)
                        local timeCheckOK = true
                        if isTimeGift and leftTime == 0 then
                            timeCheckOK = false
                        end
                        if canBuy and timeCheckOK then
                            table.insert(realContent, v)
                            table.insert(contentIndex, k)
                        end
                    end
                end
                
                if #realContent > 0 then
                    item = {}
                    for k, m in pairs(v) do
                        item[k] = m
                    end
                    item["contents"] = realContent
                    item["contentIndex"] = contentIndex
                end

            elseif v.frame == "frame10" then --npc礼包
                local bought = ShopManager:BoughtNPCPackage()
                if not bought then
                    item = {}
                    for k,m in pairs(v) do
                        item[k] = m
                    end
                end
            elseif v.frame == "frame11" then --宠物礼包
                local shopData = v.contents[1]
                local bought = ShopManager:BoughtBefor(shopData.id)
                if not bought then
                    item = {}
                    for k,m in pairs(v) do
                        item[k] = m
                    end
                end
            elseif v.frame == "frame14" then --免广告礼包                
                local allBuy = true
                for k,v in pairs(v.contents) do
                    if not ShopManager:BoughtBefor(v.id) then
                        allBuy = false
                        break
                    end
                end
                if not allBuy then
                    item = {}
                    for k,m in pairs(v) do
                        item[k] = m
                    end
                end                          
            end
        end
        if item ~= nil then
            ---CEO货架必须CEO系统解锁才可以加入到商品货架中
            if v.frame == "frameCEOChest" then
                if GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
                    table.insert(data, item)
                end
            else
                table.insert(data, item)
            end
        end
    end
    data = self:FilterContryShopData(data)
    local shopId2Index = {}
    for k,v in pairs(data) do
        for k2,v2 in pairs(v.contents or {}) do
            shopId2Index[v2.id] = k - 1
        end
        if #v.contents == 0 then--国内content配置为0
            shopId2Index[1000] = k - 1
        end
    end
    self.shopidToIndex = shopId2Index

    self:GetView():Invoke("ShowList", data, refresh)
end

function ShopUI:GetShopData(content)

end

--处理生成出来的Data(过滤非本国家的的数据)
function ShopUI:FilterContryShopData(data)
    local contryID = CountryMode:GetCurrCountry()
    local displayData = Tools:CopyTable(data)
    local index = 1
    while displayData[index] do 
        if displayData[index].country == 0 or displayData[index].country == contryID then
            local index2 = 1
            while displayData[index].contents[index2] do
                local v2 = displayData[index].contents[index2]
                if ConfigMgr.config_shop[v2.id] and ConfigMgr.config_shop[v2.id].country > 0 and ConfigMgr.config_shop[v2.id].country ~= contryID then
                    table.remove(displayData[index].contents, index2)
                -- elseif not ShopManager:CheckBuyTimes(v2.id) and ConfigMgr.config_shop[v2.id].type == 12 then
                --     table.remove(displayData[index].contents, index2)
                else
                    index2  = index2 + 1
                end
            end
            index  = index + 1
        else
            table.remove(displayData, index)
        end
    end
    -- index = 1
    -- while displayData[index] do
    --     if #displayData[index].contents <= 0 then
    --         table.remove(displayData, index)
    --     else
    --         index  = index + 1
    --     end
    -- end
    return displayData
end

function ShopUI:SuccessBuyBefor(id)--成功购买的提示
    local data = ConfigMgr.config_shop[id]
    local needRefresh = data.type == 12--目前就礼包购买后可能会不消失,从而影响数据

    PurchaseSuccessUI:SuccessBuy(id,nil,nil,nil,nil)
    if FirstPurchaseUI:IsShopDiamond(id) then
        --K136 首充双倍购买后标记为已购买
        --FirstPurchaseUI:SetNotFirstDouble(id)
        self:OpenAndTurnPageDiamond(1000)
    else
        self:OpenAndTurnPage(id, needRefresh)
    end

    --活跃度--参数填config_activity 的 id   
    
    
    -- local frameData = {}
    -- local cfgFrame = ConfigMgr.config_shop_frame or {}
    -- local getShopFrameBuyId = function(shopId)
    --     for k,v in pairs(cfgFrame or {}) do
    --         for k2, v2 in pairs(v.contents or {}) do
    --             if v2.id == shopId then
    --                 return v.id
    --             end
    --         end
    --     end
    -- end

    -- local shopFrameId = getShopFrameBuyId(id)
    -- for k,v in pairs(cfgFrame) do
    --     if v.id == shopFrameId then
    --         frameData = v
    --         break
    --     end
    -- end
    
    --self:GetView():Invoke("SuccessBuy", id, frameData)
end

function ShopUI:SuccessBuyAfter(shopID)
    --2025-3-20 增加一个商城钻石购买消耗也算
    local cfg = ConfigMgr.config_shop[shopID]
    if cfg and cfg.diamond and cfg.diamond > 0 then
        EventManager:DispatchEvent("DOMESTIC_PURCHASE")
    end
    self:GetView():Invoke("SuccessBuyAfter", shopID)
end

function ShopUI:OpenAndTurnPage(shopId, refresh)
    if refresh then
        self:EnterShop(true)
    else
        self:EnterShop()
    end

    local index = self.shopidToIndex[shopId] or 0
    local isCEOTurn = false
    if shopId == 1723 then
        index = index
        isCEOTurn = true
    end
    self:GetView():Invoke("TurnPage", index, isCEOTurn)
end

---显示两排钻石奖励,只对钻石有效
function ShopUI:OpenAndTurnPageDiamond(shopId, refresh)
    if refresh then
        self:EnterShop(true)
    else
        self:EnterShop()
    end

    local index = self.shopidToIndex[shopId] or 0

    self:GetView():Invoke("TurnToBuyDiamond", index)
end

function ShopUI:TurnTo(shopId, closeCb)
    self:EnterShop()
    local index = self.shopidToIndex[shopId] or 0
    self:GetView():Invoke("TurnTo", index, closeCb)
end

function ShopUI:RewardDiamondCD()
    local data = DiamondRewardUI:GetLocalData()
    local cdTime = math.max((data.video_diamond_time or 0) - GameTimeManager:GetCurrentServerTime(true), 0)
    return cdTime
end
function ShopUI:GetRewardDiamond(cb)
    local data = LocalDataManager:GetDataByKey("ad_diamond_reward")
    local diamondNumber = CfgMgr.config_global.free_diamond or 10
    ResMgr:AddDiamond(diamondNumber, ResMgr.EVENT_COLLECTION_DAILY_REWARDS, function(success)
        if success then
            local currTime = GameTimeManager:GetCurrentServerTime()
            local needTime = CfgMgr.config_global.diamond_cooltime * Tools:GetCheat(3600, 1)
            data.video_diamond_time = currTime + needTime
            LocalDataManager:WriteToFile()

            -- GameSDKs:Track("get_diamond", {get = diamondNumber, left = ResMgr:GetDiamond(), get_way = "钻石商城"})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石商城", behaviour = 1, num_new = tonumber(diamondNumber)})

            if cb then cb() end
            MainUI:RefreshDiamondShop()
            MainUI:RefreshRewardDiamond()
        end
    end, true)
end
--下面的都没用用了..但还是留着

-- function ShopUI:NextDiamondTime()
--     local lcoalData = DiamondRewardUI:GetLocalData()
--     local cdTime = math.max((lcoalData.video_diamond_time or 0) - GameTimeManager:GetCurrentServerTime(), 0)
--     return cdTime
-- end

-- function ShopUI:GetFreeDiamond(cb, onSuccess, onFail)
--     local lcoalData = DiamondRewardUI:GetLocalData()

--     local isFree = DiamondRewardUI:IsNewDay()
--     if isFree then
--         local diamondNumber = CfgMgr.config_global.free_diamond or 10
--         ResMgr:AddDiamond(diamondNumber, ResMgr.EVENT_COLLECTION_DAILY_REWARDS, function(success)
--             if success then
--                 GameSDKs:Track("get_diamond", {get = diamondNumber, left = ResMgr:GetDiamond(), get_way = "钻石商城"})
--                 GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石商城", behaviour = 1, num = diamondNumber})
--                 lcoalData.free_reward_date = DiamondRewardUI:GetDate()
--                 LocalDataManager:WriteToFile()
--                 if cb then cb() end
--                 MainUI:RefreshDiamondShop()
--             end
--         end, true)
--     else
--         local callback = function()
--             local diamondNumber = CfgMgr.config_global.video_diamond or 10
--             ResMgr:AddDiamond(diamondNumber, ResMgr.EVENT_COLLECTION_AD_REWARDS, function(success)
--                 if success then
--                     local currTime = GameTimeManager:GetCurrentServerTime()
--                     local needTime = CfgMgr.config_global.diamond_cooltime * Tools:GetCheat(3600, 1)
--                     lcoalData.video_diamond_time = currTime + needTime
--                     LocalDataManager:WriteToFile()
--                     GameSDKs:Track("get_diamond", {get = diamondNumber, left = ResMgr:GetDiamond(), get_way = "钻石商城"})
--                     GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石商城", behaviour = 1, num = diamondNumber})
--                     if cb then cb() end
--                     MainUI:RefreshDiamondShop()
--                 end
--             end, true)
--         end
--         GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10002)
--     end
-- end

function ShopUI:UpdateAllShowItem()
    if self.m_view then
        self.m_view:Invoke("UpdateAllShowItem")
    end
end
