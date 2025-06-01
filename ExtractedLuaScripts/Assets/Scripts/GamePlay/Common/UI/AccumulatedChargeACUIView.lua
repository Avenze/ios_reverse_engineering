--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-12-22 10:27:02
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local GameUIManager = GameTableDefine.GameUIManager

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local Application = CS.UnityEngine.Application
local GameObject = CS.UnityEngine.GameObject

local ValueManager = GameTableDefine.ValueManager
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local AccumulatedChargeActivityDataManager = GameTableDefine.AccumulatedChargeActivityDataManager
local AccumulatedChargeACUI = GameTableDefine.AccumulatedChargeACUI
local Shop = GameTableDefine.Shop
local FeelUtil = CS.Common.Utils.FeelUtil
local Vector3 = CS.UnityEngine.Vector3
local CountryMode = GameTableDefine.CountryMode
local UnityHelper = CS.Common.Utils.UnityHelper
---@class AccumulatedChargeACUIView:UIBaseView
---@field super UIBaseView
local AccumulatedChargeACUIView = Class("AccumulatedChargeACUIView", UIView)

function AccumulatedChargeACUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.displayLeftTimer = nil
    self.leftTime = 0
    self.m_curGetID = 0 --当前可领取的ID是多少，根据存档来进行
    self.rewardGO = nil
    self.m_canBuyIndex = 1 --当前可以买的ID的Index
    self.m_animator = nil ---@type UnityEngine.Animator
    self.m_curBuyItemID = nil ---当前购买的 RewardConfigID

    self.m_configs = nil
end

function AccumulatedChargeACUIView:OnEnter()
    self.m_animator = self:GetComp(self.m_uiObj,"","Animator")
    self.m_configs = AccumulatedChargeActivityDataManager:GetAccumulatedConfigs()

    if not self.m_configs then
        --没有SDK返回的配置
        printError("AccumulatedChargeACUIView: 找不到累充活动配置,没有SDK返回的配置")
        --AccumulatedChargeACUI:CloseView()
        self:PlayCloseAnim()
        return
    end

    --顶掉其他界面注册的购买成功消息，防止报错
    --购买成功事件注册
    ShopManager:refreshBuySuccess(function(shopId)
    end)
    --购买失败事件注册
    ShopManager:refreshBuyFail(function(shopId)
    end)

    AccumulatedChargeActivityDataManager:SetEnterAccCharge()
    self.super:OnEnter()
    self.rewardGO = self:GetGo("background/Reward")
    self:SetButtonClickHandler(self:GetComp("background/Title/QuitBtn", "Button"), function()
        --AccumulatedChargeACUI:CloseView()
        self:PlayCloseAnim()
    end)
    self:SetButtonClickHandler(self:GetComp("background/congradPanel/Title/QuitBtn", "Button"), function()
        --AccumulatedChargeACUI:CloseView()
        self:PlayCloseAnim()
    end)
    -- self:InitList()
    self:InitRewardItem()
    self.m_congratulate = AccumulatedChargeActivityDataManager:CheckIsGetAllProducts()
    if self.m_congratulate then
        self.m_animator:Play("UI_scale_open_congratulation02")
        self:ShowCongratulatePanel(true)
        self.m_animator:SetBool("AllComplete",true)
    else
        --self.m_animator:Play("UI_scale_open_background01")
        self:ShowCongratulatePanel(false)
        self:RefreshAllRewardItem()
        self:ScrollToItem(self.m_canBuyIndex or 1)
        self.m_animator:SetBool("AllComplete",false)
    end

    if self.displayLeftTimer then
        GameTimer:StopTimer(self.displayLeftTimer)
        self.displayLeftTimer = nil
    end
    self.leftTime = AccumulatedChargeActivityDataManager:GetActivityLeftTime()
    if self.leftTime > 0 then
        self.displayLeftTimer = GameTimer:CreateNewTimer(1, function()
            self:UpdateLeftTimeDisplay()
        end, true,true)
    end
    --self:SetText("background/Title/time/time_txt", GameTimeManager:FormatTimeLength(self.leftTime))
    GameSDKs:TrackForeign("rank_activity", {name = "AccCharge", operation = "1"})
end

---播放Animator中的Close动画
function AccumulatedChargeACUIView:PlayCloseAnim()
    if self.m_animator then
        self.m_animator:CrossFadeInFixedTime("UI_scale_close_background01",0.5)
        GameUIManager:SetEnableTouch(false)
        local animLength = UnityHelper.GetAnimatorClipDuration(self.m_animator,"UI_scale_close_background01")
        GameTimer:CreateNewTimer(animLength,function()
            GameUIManager:SetEnableTouch(true)
            AccumulatedChargeACUI:CloseView()
        end)
    end
end

function AccumulatedChargeACUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
    self.super:OnExit(self)
    if self.displayLeftTimer then
        GameTimer:StopTimer(self.displayLeftTimer)
        self.displayLeftTimer = nil
    end
    --刷新累充活动入口，活动结束应该立刻消失
    if MainUI.m_view then
        MainUI.m_view:RefreshAccumulatedChargeActivity()
    end
end

function AccumulatedChargeACUIView:UpdateLeftTimeDisplay()
    self.leftTime = AccumulatedChargeActivityDataManager:GetActivityLeftTime()
    if self.leftTime <= 0 then
        self.leftTime = 0
        if self.displayLeftTimer then
            GameTimer:StopTimer(self.displayLeftTimer)
            self.displayLeftTimer = nil
        end
    end
    if self.m_congratulate then
        self:SetText("background/congradPanel/Title/time/time_txt", GameTimeManager:FormatTimeLength(self.leftTime))
    else
        self:SetText("background/Title/time/time_txt", GameTimeManager:FormatTimeLength(self.leftTime))
    end
end

function AccumulatedChargeACUIView:InitRewardItem()
    if not self.rewardGO then
        return
    end
    local paymentCount = #self.m_configs
    local itemParent = self:GetTrans(self.m_uiObj,"background/Reward/viewport/content")
    local childCount = itemParent.childCount
    if paymentCount<childCount then
        for i = paymentCount+1, childCount do
            local trans = itemParent:Find("item"..i)
            if trans then
                trans.gameObject:SetActive(false)
            end
        end
    end
    if paymentCount>0 then
        local pgs = itemParent:Find("item"..paymentCount.."/pgs")
        if pgs then
            pgs.gameObject:SetActive(false)
        end
    end
end

---设置单个道具属性
---@param go UnityEngine.GameObject
function AccumulatedChargeACUIView:SetItemInfo(go,itemConfig,canBuy)

    local itemCount = itemConfig.count or 1
    local itemShopID = itemConfig.id ---这个道具的ShopID
    local cfgShop = ConfigMgr.config_shop[itemShopID]
    local icon = self:GetComp(go, "bg/icon", "Image")
    local iconShadow = self:GetComp(go, "bg/icon_shadow", "Image")
    self:SetSprite(icon, "UI_Shop", cfgShop.icon)
    self:SetSprite(iconShadow, "UI_Shop", cfgShop.icon)
    local value,typeName = ShopManager:GetValueByShopId(itemShopID)
    if tonumber(value) ~= nil then
        value = value * itemCount
    end
    local showValue = ShopManager:SetValueToShow(value, cfgShop)
    if tonumber(value) == nil or typeName == "offline" or typeName == "income" then
        showValue = 1
        self:SetText(go, "bg2/txt","x" .. showValue)
        self:SetText(go, "bg2/txt_shadow","x" .. showValue)
    elseif typeName == "cash" then
        if CountryMode:GetCurrCountry() == 1 then
            self:SetSprite(icon, "UI_Shop", cfgShop.icon)
        elseif CountryMode:GetCurrCountry() == 2 then
            self:SetSprite(icon, "UI_Shop", cfgShop.icon .. "_euro")
        end
        self:SetText(go, "bg2/txt", showValue)
        self:SetText(go, "bg2/txt_shadow", showValue)
    else
        self:SetText(go, "bg2/txt","x" .. showValue)
        self:SetText(go, "bg2/txt_shadow","x" .. showValue)
    end

    --K119 tip上移一层不参与缩放
    local tip = self:GetGoOrNil(go, "bg/tip")
    if tip then
        UnityHelper.AddChildToParent(go.transform, tip.transform,true)
    else
        tip = self:GetGoOrNil(go, "tip")
    end
    if self:NeedShowTip(itemShopID) then
        tip:SetActive(true)
        local tipBtn = self:GetComp(go, "bg", "Button") ---@type UnityEngine.UI.Button
        self:SetButtonClickHandler(tipBtn, function()
            local worldPos = self:GetGo(go, "bg").transform.position
            self:SetInfoPanel(itemShopID, worldPos,itemCount)
        end)
        tipBtn.enabled = true
    else
        tip:SetActive(false)
    end

    --local lightGO = self:GetGoOrNil(go,"bg/light")
    --if lightGO then
    --    if canBuy then
    --        lightGO:SetActive(false)
    --    else
    --        lightGO:SetActive(true)
    --    end
    --end
end

function AccumulatedChargeACUIView:RefreshRewardItem(index)
    local itemGo = self:GetGoOrNil(self.rewardGO, "viewport/content/item"..index)
    if itemGo then
        local rewardConfig = self.m_configs[index]
        local canBuy = AccumulatedChargeActivityDataManager:CheckCanBuy(rewardConfig.id)
        self.m_canBuyIndex = canBuy and index or self.m_canBuyIndex
        local isHaveBuy = AccumulatedChargeActivityDataManager:CheckIsHaveBuy(rewardConfig.id)
        local itemClaimBtn = self:GetComp(itemGo, "bg/get/btn_claim", "Button")
        if itemClaimBtn then
            itemClaimBtn.interactable = false
        end
        if rewardConfig.iap_id > 0 then
            local price = Shop:GetIapConfigPrice(rewardConfig.iap_id)
            if price then
                self:SetText(itemGo, "bg/get/btn_claim/txt", price)
                self:SetText(itemGo, "bg/get/btn_now/txt", price)
            end
        else
            self:SetText(itemGo, "bg/get/btn_claim/txt",  GameTextLoader:ReadText(canBuy and "TXT_BTN_CLAIM" or "TXT_BTN_CLAIM_FREE"))
            self:SetText(itemGo, "bg/get/btn_now/txt",  GameTextLoader:ReadText(canBuy and "TXT_BTN_CLAIM" or "TXT_BTN_CLAIM_FREE"))
        end
        local claimBtnGo = self:GetGoOrNil(itemGo, "bg/get/btn_claim")
        local haveBtnGo = self:GetGoOrNil(itemGo, "bg/get/btn_haved")
        local nowBtnGo = self:GetGoOrNil(itemGo, "bg/get/btn_now")
        local lockGo = self:GetGoOrNil(itemGo, "bg/get/btn_claim/lock")
        local unlock = self:GetGoOrNil(itemGo,"bg/unlock")
        --local bgGO = self:GetGoOrNil(itemGo,"bg")

        --K119 道具内容填充
        local item1GO = self:GetGoOrNil(itemGo,"bg/icon/item1")
        local item2GO = self:GetGoOrNil(itemGo,"bg/icon/item2")

        local rewardCount = rewardConfig.reward and #rewardConfig.reward or 0
        if rewardCount >0 then
            --k119这一步要把tip从bg下提取出来,后面才能缩放
            self:SetItemInfo(item1GO,rewardConfig.reward[1],canBuy)
            item1GO:SetActive(true)
            local item1GOIconTrans = self:GetTrans(item1GO,"bg")
            if rewardCount >1 then
                self:SetItemInfo(item2GO,rewardConfig.reward[2],canBuy)

                --加号
                local addGONormal = self:GetGoOrNil(item2GO,"add_normal")
                local addGONow = self:GetGoOrNil(item2GO,"add_now")
                if addGONormal then
                    addGONormal:SetActive(not canBuy)
                end
                if addGONow then
                    addGONow:SetActive(canBuy)
                end
                item2GO:SetActive(true)
                item1GOIconTrans.localScale = Vector3(1,1,1)
            else
                item2GO:SetActive(false)
                item1GOIconTrans.localScale = Vector3(1.3,1.3,1)
            end
        else
            item1GO:SetActive(false)
            item2GO:SetActive(false)
        end

        if claimBtnGo then
            if not isHaveBuy and not canBuy or (rewardConfig.iap_id > 0 and not canBuy)then
                claimBtnGo:SetActive(true)
                itemClaimBtn.interactable  = false
                if lockGo then
                    local groupAlph = self:GetComp(lockGo, "", "CanvasGroup")
                    if groupAlph then
                        groupAlph.alpha = 1
                    end
                    lockGo:SetActive(not isHaveBuy)
                end
            else
                claimBtnGo:SetActive(false)
            end
        end

        if nowBtnGo then
            if not isHaveBuy and canBuy then
                nowBtnGo:SetActive(true)

                local nowBtn = self:GetComp(itemGo, "bg/get/btn_now", "Button")
                nowBtn.interactable = true
                self:SetButtonClickHandler(nowBtn, function()
                    nowBtn.interactable = false
                    print("AccumulatedChargeACUIView:BuyButton Click down buy id is:"..rewardConfig.id)
                    AccumulatedChargeActivityDataManager:BuyProduct(rewardConfig.id, function (itemID, isSuccess)
                    end, nowBtn)
                end)
            else
                nowBtnGo:SetActive(false)
            end
        end

        if unlock then
            unlock:SetActive(not isHaveBuy and canBuy)
        end

        if haveBtnGo then
            haveBtnGo:SetActive(isHaveBuy)
            --K119 打开播放特效
            if self.m_curBuyItemID == rewardConfig.id then
                --因为动画在控制何时fx_open出现 所以只能这样做
                --local fx = self:GetComp(haveBtnGo,"btn/fx_open","ParticleSystem") ---@type UnityEngine.ParticleSystem
                --local fxMain = fx.main
                --fxMain.playOnAwake = true
                self.m_curBuyItemID = nil
                --播放打钩动画
                local rewardAni = self:GetComp(haveBtnGo, "", "Animation")
                AnimationUtil.Play(rewardAni, "Payment_reward_btn_haved")
            end
            local haveTxtGO = self:GetGoOrNil(haveBtnGo,"txt")
            if haveTxtGO then
                haveTxtGO:SetActive(rewardConfig.iap_id == 0)
            end
        end
    end
end

function AccumulatedChargeACUIView:RefreshAllRewardItem()
    
    if not self.rewardGO then
        return
    end
    for k, v in ipairs(self.m_configs) do
        --print("config_payment:k:"..k.." v.id is:"..v.id)
        self:RefreshRewardItem(k)
    end
end

---是否有提示按钮（只有收益经理/离线经理/宠物/人物/套装需要提示按钮打开详情界面）
function AccumulatedChargeACUIView:NeedShowTip(itemID)
    local rewardConfig = ShopManager:GetCfg(itemID)
    if rewardConfig.type == ShopManager.ItemType.Pet or
            rewardConfig.type == ShopManager.ItemType.Employee or
            rewardConfig.type == ShopManager.ItemType.Equipment or
            rewardConfig.type == ShopManager.ItemType.InCome or
            rewardConfig.type == ShopManager.ItemType.Offline
    then
        return true
    else
        return false
    end
end

---显示获取所有奖励后的祝贺界面
function AccumulatedChargeACUIView:ShowCongratulatePanel(show)
    if show then
        self:GetGo("background/Title"):SetActive(false)
        self:GetGo("background/Reward"):SetActive(false)
        self:GetGo("background/congradPanel"):SetActive(true)
    else
        self:GetGo("background/Title"):SetActive(true)
        self:GetGo("background/Reward"):SetActive(true)
        self:GetGo("background/congradPanel"):SetActive(false)
    end
end

--[[
    @desc: 设置对应的物品ID解锁带来的UI对应的显示
    author:{author}
    time:2022-12-22 15:06:18
    --@itemIndex: 
    @return:
]]
function AccumulatedChargeACUIView:SetItemUnlock(itemID)
    self.rewardGO = self:GetGo("background/Reward")
    if not self.rewardGO then
        --self:RefreshAllRewardItem()
        return
    end
    local index = 0
    for k, v in ipairs(self.m_configs) do
        if v.id == itemID then
            index = k
            break
        end
    end
    if index > 0 then
        local itemGo = self:GetGoOrNil(self.rewardGO, "viewport/content/item"..index)
        if itemGo then
            local feedbackGo = self:GetGoOrNil(itemGo, "bg/get/btn_claim/lock/unlockFB")
            if feedbackGo then
                self.m_canBuyIndex = index
                FeelUtil.PlayFeel(feedbackGo, "acc_charge_unlock")
                return
            end
        else
            printError("累充活动配置数超出了Payment.prefab支持的数量 配置了"..index.."个")
        end
    end
end

---解锁动画播放完成的回调
function AccumulatedChargeACUIView:OnFeelComplete()
    self:RefreshRewardItem(self.m_canBuyIndex)
end

function AccumulatedChargeACUIView:AfterBuyCallback(itemID, isSuccess)
    print("AccumulatedChargeACUIView:buy item complate callback:"..itemID)
    if isSuccess then
        self.m_curBuyItemID = itemID
        self:RefreshRewardItem(itemID)
        if not AccumulatedChargeActivityDataManager:CheckIsGetAllProducts() then
            self.rewardGO = self:GetGo("background/Reward")
            self:SetItemUnlock(itemID + 1)
        else
            self.m_congratulate = true
            self:ShowCongratulatePanel(true)
            self.m_animator:SetBool("AllComplete",true)
        end
    end
end

function AccumulatedChargeACUIView:RefreshAllItems()
    --self:InitRewardItem()
    self:RefreshAllRewardItem()
    -- self.m_list:ScrollTo(i - 1, 3)
    local _list = self:GetComp("background/Reward", "ScrollRectEx")
    if _list then
        _list:ScrollToTop(3)
    end
end

--[[
    @desc: 设置对应的物品ID已领取后的状态
    author:{author}
    time:2022-12-22 15:08:08
    --@itemIndex: 
    @return:
]]
function AccumulatedChargeACUIView:SetItemGettedReward(itemID)

end

--[[
    @desc: 设置物品的初始化统一状态，然后在根据数据刷新打开可领取状态
    author:{author}
    time:2022-12-22 15:09:05
    --@itemIndex: 
    @return:
]]
function AccumulatedChargeACUIView:SetItemInitState(itemID)

end

function AccumulatedChargeACUIView:SetInfoPanel(shopID, newPos,count)
    local shopCfg = ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return
    end
    local value, typeName = ShopManager:GetValueByShopId(shopID)
    --可叠加
    if count and type(count) == "number" and value and type(value) == "number" then
        value = value * count
    end
    local showValue = ShopManager:SetValueToShow(value, shopCfg)
    local confirmPanel = self:GetGo("background/confirmPanel")
    if not confirmPanel then
        return
    end
    local infoGo = self:GetGo("background/confirmPanel/info")
    infoGo.transform.position = newPos
    infoGo.transform.localPosition = Vector3(infoGo.transform.localPosition.x, infoGo.transform.localPosition.y + 80, infoGo.transform.localPosition.z)
    self:SetText(confirmPanel, "info/title/txt", GameTextLoader:ReadText(shopCfg.name))
    local reward = self:GetComp(confirmPanel, "info/content/reward/icon", "Image")
    self:SetSprite(reward, "UI_Shop", shopCfg.icon)
    self:SetText(confirmPanel, "info/content/txt", GameTextLoader:ReadText(shopCfg.desc))
    if tonumber(value) == nil then
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        for k, v in pairs(showValue) do
            local iconName = "icon_shop_income"
            local strDisp = "+"..v
            if k == "income" then
                iconName = "icon_shop_income"
            elseif k == "offline" then
                iconName = "icon_shop_offline"
                strDisp  = strDisp.."H"
            elseif k == "mood" then
                iconName = "icon_shop_mood"
            end
            self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", iconName)
            self:SetText(confirmPanel, "info/content/info/bg/num", strDisp)
        end
    elseif typeName == "offline" then
        --离线经理
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_offline")
        self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. showValue .. "H")
    elseif typeName == "income" then
        --收益经理
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(true)
        self:SetSprite(self:GetComp(confirmPanel, "info/content/info/bg/icon", "Image"), "UI_Shop", "icon_shop_income")
        self:SetText(confirmPanel, "info/content/info/bg/num", "+" .. showValue)
    else
        self:GetGo(confirmPanel, "info/content/info/bg"):SetActive(false)
    end
    confirmPanel:SetActive(true)
end

--function AccumulatedChargeACUIView:InitList()
--    self.m_list = self:GetComp("background/Reward", "ScrollRectEx")
--    self:SetListItemCountFunc(self.m_list, function()
--        return #ConfigMgr.config_payment
--    end)
--
--    -- self.mList = self:GetComp("RootPanel/rank/RankList", "ScrollRectEx")
--    -- self:SetListItemCountFunc(self.mList, function()
--    --     return #self.rankData
--    -- end)
--    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
--end
--
--function AccumulatedChargeACUIView:UpdateListItem(index, tran)
--    local name = tran.name
--end

function AccumulatedChargeACUIView:ScrollToItem(index)
    local itemGo = self:GetGoOrNil(self.rewardGO, "viewport/content/item"..index)
    if itemGo then
        local contentTrans = self:GetTrans(self.rewardGO, "viewport/content")
        local pos = contentTrans.localPosition
        pos.y = -itemGo.transform.localPosition.y
        contentTrans.localPosition = pos
        print(pos)
    end
end

EventManager:RegEvent("acc_charge_unlock", function()
    AccumulatedChargeACUI:GetView():Invoke("OnFeelComplete")
end)

return AccumulatedChargeACUIView
