local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local ShopManager = GameTableDefine.ShopManager
---@class DiamondFundUIView:UIBaseView
local DiamondFundUIView = Class("DiamondFundUIView", UIView)
local Shop = GameTableDefine.Shop
local StarMode = GameTableDefine.StarMode
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local DiamondFundUI = GameTableDefine.DiamondFundUI
local MainUI = GameTableDefine.MainUI
local UnityTime = CS.UnityEngine.Time

local FOUND_SHOP_ID = 1067
---总奖励数量
local TOTAL_COUNT = 13
local SliderSpeed = 1.0

--存档中的数据
local fundData = nil
local shop = nil

local AnimNames = {
    Open = "open",
    Unlock = "unlock",
    UnlockIdle = "idle2",
}

function DiamondFundUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_fundAnimator = nil ---@type UnityEngine.Animator
    self.m_sliderAnimTimer = nil
    self.m_slider = nil ---@type UnityEngine.UI.Slider
end

function DiamondFundUIView:OnEnter()

    TOTAL_COUNT = math.floor(#ConfigMgr.config_fund / 2)

    self.m_fundAnimator = self:GetComp("background/MediumPanel","Animator")
    self.m_slider = self:GetComp("background/MediumPanel/top/bg2/listBg/List/Viewport/Content/Slider","Slider")

    --关闭按钮
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("background/MediumPanel/quitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)

    --购买成功
    ShopManager:refreshBuySuccess(function(shopId)
        if shopId == FOUND_SHOP_ID then
            ShopManager:Buy(shopId, false, function()
                GameTableDefine.GameUIManager:SetEnableTouch(false)
                --播放解锁动画,等1s再刷新界面
                self:PlayAnim(AnimNames.Unlock,"ANIM_END",function()
                    local totalCount = math.floor(#ConfigMgr.config_fund / 2)
                    for i = 1, totalCount do
                        local item = self.m_list:GetScrollItemTranByIndex(i-1)
                        if item then
                            local lockAnim = self:GetComp(item.gameObject,"bg/premiumBtn/premiumBg/lockIcon/lockIcon","Animation")
                            AnimationUtil.Play(lockAnim,"Unlock_act")
                        end
                    end
                    self:GetGo("background/MediumPanel/top/bg2/listBg/listBanner"):SetActive(false)
                    GameTimer:CreateNewTimer(1.2,function()
                        --适配slider长度
                        --local start = self.m_list.content.anchoredPosition
                        --self.m_list:ScrollTo(9999)
                        --self.m_list:ScrollToPos(start)
                        self:Refresh()
                        GameTableDefine.GameUIManager:SetEnableTouch(true)
                    end)
                end)
            end,function()
                --PurchaseSuccessUI:SuccessBuy(shopId)
            end)
        end
    end)
    ShopManager:refreshBuyFail(
        function(shopId)
            if shopId == FOUND_SHOP_ID then
                self:Refresh()
            end
        end)
    --是否领取过的存档数据
    if not shop then
        shop = LocalDataManager:GetDataByKey("shop")
        if shop["fund_data"] == nil then
            shop["fund_data"] = {}
        end
        fundData = shop["fund_data"]
    end
    for i = 1, #ConfigMgr.config_fund do
        if fundData["fame" .. i] == nil then
            fundData["fame" .. i] = true
        end
    end
    LocalDataManager:WriteToFile()

    if not DiamondFundUI:IsBoughtFund() then
        --设置说明文本--富文本和format同时都有 % 时需要配文档时将富文本的 % 设置为 %%
        --包括能免费获取的钻石
        local totalDiamonds = 0 ---所有钻石数
        for i = 1, #ConfigMgr.config_fund do
            local diamond = ConfigMgr.config_fund[i].diamond
            totalDiamonds = totalDiamonds + diamond
        end
        --local introduceText = string.format(GameTextLoader:ReadText("TXT_FUND_DESC2"), tostring(totalDiamonds))
        --self:SetText(self:GetGo("background/MediumPanel/top/bg2/listBg/listBanner"), "tip", introduceText)
        --self:SetText("background/MediumPanel/top/bg2/listBg/listBanner/listTip/num", totalDiamonds)
        local totalStr = GameTextLoader:ReadText("TXT_FUND_DESC6")
        totalStr = string.gsub(totalStr,"%[num%]",tostring(totalDiamonds))
        self:SetText("background/MediumPanel/top/bg2/listBg/listBanner/listTip/tip", totalStr)

        self:GetGo("background/MediumPanel/top/bg2/listBg/listBanner"):SetActive(true)
        self.m_fundAnimator:Play(AnimNames.Open)
    else
        self:GetGo("background/MediumPanel/top/bg2/listBg/listBanner"):SetActive(false)
        self.m_fundAnimator:Play(AnimNames.UnlockIdle)
    end
    --原价与折扣
    local price,cheatPrice,discount = DiamondFundUI:GetPrice()
    self:SetText("background/MediumPanel/top/bg2/btnBanelBg/btn_buy/common",cheatPrice)
    self:SetText("background/MediumPanel/top/bg2/btnBanelBg/btn_buy/txt", price)
    self:SetText("background/MediumPanel/top/bg2/btnBanelBg/btn_buy/offvalue/num",(math.floor((1-discount)*100)).."%")

    --购买权限按钮
    local buyBtn = self:GetComp("background/MediumPanel/top/bg2/btnBanelBg/btn_buy", "Button")
    self:SetButtonClickHandler(buyBtn, function()
        if not DiamondFundUI:IsBoughtFund() then
            self:Refresh()
            --商城购买--
            --创建一个内购订单但是因为是测试阶段不会生效所以电脑端会去执行后面的代码
            Shop:CreateShopItemOrder(FOUND_SHOP_ID)
        end
    end)

    --显示星级
    self:SetText("background/MediumPanel/top/bg3/starIcon/starLevel",StarMode:GetStar())
    --local starBtn = self:GetComp("background/MediumPanel/top/bg3/starIcon","Button")
    --if starBtn then
    --    self:SetButtonClickHandler(starBtn,function()
    --        GameTableDefine.MainUI:ShowHelpInfo("HelpInfo_reputation")
    --    end)
    --end

    self:RefreshResPanel()
    self:initList()

    --适配slider长度
    self:Refresh()
    --self.m_list:ScrollTo(9999)
    --self.m_list:ScrollTo(0)
    --再次Update才能正确显示隐藏Item
    --self.m_list:UpdateData()
    self.m_slider.gameObject:SetActive(true)
    local sliderSize = self.m_slider.transform.sizeDelta
    local totalCount = math.floor(#ConfigMgr.config_fund / 2)
    sliderSize.y = 295.5695 * totalCount
    self.m_slider.transform.sizeDelta = sliderSize

    --一次性获取按钮
     local rewardBtn = self:GetComp("background/MediumPanel/top/bg2/btnBanelBg/mBtn", "Button")
     self:SetButtonClickHandler(rewardBtn,function()
         local allDiamond = 0
         for i = 1, #ConfigMgr.config_fund do
             if DiamondFundUI:IsCanGet(fundData, ConfigMgr.config_fund, i) then
                 allDiamond = allDiamond + ConfigMgr.config_fund[i].diamond
                 fundData["fame" .. i] = false
                 LocalDataManager:WriteToFile()

                 GameSDKs:TrackForeign("growth_fund", {id = ConfigMgr.config_fund[i].id})
             end
         end
         ResourceManger:AddDiamond(allDiamond, nil,
                 function()
                     EventManager:DispatchEvent("FLY_ICON", nil, 108, nil,function()
                         if DiamondFundUI.m_view then
                             self:RefreshResPanel()
                         end
                     end)
                     GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石成长基金", behaviour = 1, num_new = tonumber(allDiamond)})
                 end,
                 true)
         self:Refresh()
     end)

    --播放解锁动画
    self:PlayUnlockAnim()
end

---播放基金页面动画
function DiamondFundUIView:PlayAnim(stateName,key,callback,normalizedTime)
    local animator = self.m_fundAnimator
    --local cb = function()
    --    if animator and not animator:IsNull() then --确保注册这个回调的Animator还存在,不然换场景时刚好调用会报错
    --        if callback then
    --            callback()
    --        end
    --    end
    --end
    --AnimationUtil.AddKeyFrameEventOnObj(animator.gameObject, key, cb) -- 调用的Unity的方法, 一次穿越
    local checkEndTimer
    checkEndTimer = GameTimer:CreateNewMilliSecTimer(200,function()
        if not animator:GetCurrentAnimatorStateInfo(0):IsName(stateName) then
            GameTimer:StopTimer(checkEndTimer)
            if callback then
                callback()
            end
        end
    end,true)

    if stateName and animator then
        animator:Play(stateName, -1, normalizedTime or 0)
    end
end

--奖励表
function DiamondFundUIView:initList()
    self.m_list = self:GetComp("background/MediumPanel/top/bg2/listBg/List", "ScrollRectEx")
    --设置List的数量,免费和付费的各占一半
    local totalCount = math.floor(#ConfigMgr.config_fund / 2)
    self:SetListItemCountFunc(self.m_list, function()
        if DiamondFundUI:IsBoughtFund() then
            return totalCount
        else
            return totalCount + 1
        end
    end)
    self:SetListItemNameFunc(self.m_list,function(index)
        if index < totalCount then
            return "item"
        else
            return "block"
        end
    end)
    --设置List中的Item的具体内容
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateUIElement))
    --必备--刷新List数据
    --self.m_list:UpdateData()
end

---设置Slider的值
function DiamondFundUIView:SetSliderValue(value)
    --self.m_slider.gameObject:SetActive(true)
    --local offsetMin = self.m_slider.transform.offsetMin
    --if DiamondFundUI:IsBoughtFund() then
    --    offsetMin.y = 0
    --else
    --    local blockTran = self:GetTrans("background/MediumPanel/top/bg2/listBg/List/Viewport/Content/block")
    --    local blockHeight = blockTran.rect.height
    --    offsetMin.y = blockHeight
    --end
    --self.m_slider.transform.offsetMin = offsetMin
    self.m_slider.value = value
end

function DiamondFundUIView:PlayUnlockAnim()
    local lastUnlockIndex = self:GetUnlockFame()
    local canUnlockIndex = lastUnlockIndex
    local totalCount = math.floor(#ConfigMgr.config_fund / 2)
    local star = StarMode:GetStar()
    for i = math.max(1,lastUnlockIndex), totalCount do
        local fame = ConfigMgr.config_fund[i].fame
        if star >= fame then
            canUnlockIndex = i
        else
            break
        end
    end
    if canUnlockIndex > lastUnlockIndex then
        GameTableDefine.GameUIManager:SetEnableTouch(false)
        local curIndex = lastUnlockIndex
        if curIndex == 0 then
            curIndex = 0.5
        end
        local nextIndex = lastUnlockIndex + 1
        local sliderValue = (curIndex - 0.5) / totalCount
        --等待Slider长度初始化完成
        --GameTimer:CreateNewTimer(0.2,function()
        self.m_sliderAnimTimer = GameTimer:CreateNewMilliSecTimer(1,function()
            curIndex = curIndex + UnityTime.deltaTime * SliderSpeed
            if curIndex >= nextIndex then
                --播放动画
                local itemElementTrans = self.m_list:GetScrollItemTranByIndex(nextIndex-1)
                if itemElementTrans then
                    self:SetUnlockFame(nextIndex)
                    self:UpdateUIElement(nextIndex-1,itemElementTrans)
                    local itemAnimator = self:GetComp(itemElementTrans.gameObject,"bg/fame/fameBg_open","Animator")
                    if self:IsNewest(nextIndex) then
                        --itemAnimator:Play("DiamondFundUI_2_fameBg_open1_new",0,0)
                        self:PlayAnimationNextFrame(itemAnimator,"DiamondFundUI_2_fameBg_open1_new",3)
                    else
                        --itemAnimator:Play("DiamondFundUI_2_fameBg_open1",0,0)
                        self:PlayAnimationNextFrame(itemAnimator,"DiamondFundUI_2_fameBg_open1",2)
                    end
                end
                nextIndex = nextIndex + 1
                if nextIndex > canUnlockIndex then
                    --停止
                    GameTimer:StopTimer(self.m_sliderAnimTimer)
                    self.m_sliderAnimTimer = nil
                    curIndex = canUnlockIndex
                    GameTableDefine.GameUIManager:SetEnableTouch(true)
                end
            end
            sliderValue = (curIndex - 0.5) * 1.0 / totalCount
            self:SetSliderValue(sliderValue)
            --锁定视角
            local contentPos = self.m_list.content.anchoredPosition
            contentPos.y = (curIndex-2) * 295.5695
            self.m_list:ScrollToPos(contentPos)
        end,true)
        --end)
    else
        local firstCanGetIndex = self:GetFirstCanGetIndex()
        local contentPos = self.m_list.content.anchoredPosition
        contentPos.y = (firstCanGetIndex-2) * 295.5695
        self.m_list:ScrollToPos(contentPos)
        --self.m_list:ScrollTo(math.max(0,firstCanGetIndex-2))
    end
end

---刷新钻石数量
function DiamondFundUIView:RefreshResPanel()
    self:SetText("background/MediumPanel/top/diamonRes/num",ResourceManger:GetDiamond())
end

function DiamondFundUIView:Refresh()
    local isBoughtFund = DiamondFundUI:IsBoughtFund()
    local star = StarMode:GetStar()
    local buyBtnGO = self:GetGo("background/MediumPanel/top/bg2/btnBanelBg/btn_buy")
    buyBtnGO:SetActive(not isBoughtFund)
    local rewardBtn = self:GetComp("background/MediumPanel/top/bg2/btnBanelBg/mBtn", "Button")
    rewardBtn.interactable = DiamondFundUI:IsCanDraw(fundData, ConfigMgr.config_fund)
    rewardBtn.gameObject:SetActive(isBoughtFund)
    --主界面基金红点
    MainUI:RefreshDiamondFund()

    self.m_list:UpdateData()

    --设置Slider到上次解锁的位置
    local totalCount = #ConfigMgr.config_fund / 2
    local unlockIndex = self:GetUnlockFame()
    if unlockIndex == 0 then
        unlockIndex = 0.5
    end
    local sliderValue = (unlockIndex - 0.5) / totalCount
    self:SetSliderValue(sliderValue)

    if not isBoughtFund then
        --local star = StarMode:GetStar()
        local totalCanGetDiamonds = 0 ---购买后能立即获取的钻石数
        for i = 1, #ConfigMgr.config_fund do
            local fundConfig = ConfigMgr.config_fund[i]
            if star >= fundConfig.fame then
                if fundConfig.isPay or fundData["fame" .. i] then
                    totalCanGetDiamonds = totalCanGetDiamonds + ConfigMgr.config_fund[i].diamond
                end
            end
        end
        --self:SetText("background/MediumPanel/top/bg2/listBg/listBanner/buyTip/num", totalCanGetDiamonds)
        local totalStr = GameTextLoader:ReadText("TXT_FUND_DESC8")
        totalStr = string.gsub(totalStr,"%[num%]",tostring(totalCanGetDiamonds))
        self:SetText("background/MediumPanel/top/bg2/listBg/listBanner/buyTip/tip", totalStr)
    end
end

function DiamondFundUIView:GetReward(index)
    local fundConfig = ConfigMgr.config_fund[index]
    --最后一个参数 true 控制 是在动画完成是再增加
    ResourceManger:AddDiamond(fundConfig.diamond, nil, function()
        EventManager:DispatchEvent("FLY_ICON", nil, 108,nil, function()
            if DiamondFundUI.m_view then
                self:RefreshResPanel()
            end
        end)
        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石成长基金", behaviour = 1, num_new = tonumber(fundConfig.diamond)})
    end, true)
    fundData["fame" .. index] = false
    LocalDataManager:WriteToFile()
    GameSDKs:TrackForeign("growth_fund", {id = fundConfig.id}) --埋点
    self:Refresh()
end

--对单个Item进行一个设置,发生改变时自动遍历修改
function DiamondFundUIView:UpdateUIElement(index, tran)
    index = index + 1

    local totalCount = math.floor(#ConfigMgr.config_fund / 2)
    if index > totalCount then
        --是最后一个元素 block
        return
    end

    local go = tran.gameObject

    local payIndex = index
    local freeIndex = index + totalCount

    local payConfig = ConfigMgr.config_fund[payIndex]
    local freeConfig = ConfigMgr.config_fund[freeIndex]

    --self:SetText(go, "bg/fame/num", payConfig.fame)
    local fameOpen = self:GetGo(go,"bg/fame/fameBg_open")
    local fameOff = self:GetGo(go,"bg/fame/fameBg_off")
    local isUnlockFame = self:IsUnlockFame(payIndex)
    if isUnlockFame then
        fameOpen:SetActive(true)
        fameOff:SetActive(false)
        self:SetText(go, "bg/fame/fameBg_open/num", payConfig.fame)
        self:GetGo(go,"bg/blacMask"):SetActive(false)
    else
        fameOpen:SetActive(false)
        fameOff:SetActive(true)
        self:SetText(go, "bg/fame/fameBg_off/num", payConfig.fame)
        self:GetGo(go,"bg/blacMask"):SetActive(true)
    end

    self:SetText(go, "bg/premiumBtn/premiumBg/num", payConfig.diamond)
    self:SetText(go, "bg/nomalBtn/nomalBg/num", freeConfig.diamond)

    self:SetSprite(self:GetComp(go, "bg/premiumBtn/premiumBg/icon", "Image"),
            "UI_Shop", payConfig.icon)
    self:SetSprite(self:GetComp(go, "bg/nomalBtn/nomalBg/icon", "Image"),
            "UI_Shop", freeConfig.icon)

    local canGetPay = DiamondFundUI:IsCanGet(fundData, ConfigMgr.config_fund, payIndex)
    local canGetFree = DiamondFundUI:IsCanGet(fundData, ConfigMgr.config_fund, freeIndex)

    local claimPayBtn = self:GetComp(go, "bg/premiumBtn", "Button")
    local claimFreeBtn = self:GetComp(go, "bg/nomalBtn", "Button")

    claimPayBtn.interactable = canGetPay
    claimFreeBtn.interactable = canGetFree

    --已获取奖励标记
    local claimedMarkPay = self:GetGoOrNil(claimPayBtn.gameObject,"finishBg")
    local claimedMarkFree = self:GetGoOrNil(claimFreeBtn.gameObject,"finishBg")

    local unlockVFXGO = self:GetGoOrNil(claimPayBtn.gameObject,"vfx")

    local claimedPay = not fundData["fame" .. payIndex]
    local claimedFree = not fundData["fame" .. freeIndex]

    if claimedMarkPay then
        claimedMarkPay:SetActive(claimedPay)
    end

    if claimedMarkFree then
        claimedMarkFree:SetActive(claimedFree)
    end

    if unlockVFXGO then
        unlockVFXGO:SetActive(not claimedPay)
        local vfxAnimation = self:GetComp(unlockVFXGO,"","Animation")
        local time = UnityTime.time % AnimationUtil.GetAnimLength(vfxAnimation,"DiamondFundUI_2_brushlight")
        AnimationUtil.SetTime(vfxAnimation,"DiamondFundUI_2_brushlight",time)
    end

    --可以获取奖励标记
    --local claimableMarkPay = self:GetGoOrNil(claimPayBtn.gameObject,"premiumBg/redIcon")
    --local claimableMarkFree = self:GetGoOrNil(claimFreeBtn.gameObject,"nomalBg/redIcon")

    local claimableFlashPay = self:GetGoOrNil(claimPayBtn.gameObject,"flash")
    local claimableFlashFree = self:GetGoOrNil(claimFreeBtn.gameObject,"flash")

    --if claimableMarkPay then
    --    claimableMarkPay:SetActive(canGetPay)
    --end

    --if claimableMarkFree then
    --    claimableMarkFree:SetActive(canGetFree)
    --end

    if claimableFlashPay then
        claimableFlashPay:SetActive(canGetPay)
    end

    if claimableFlashFree then
        claimableFlashFree:SetActive(canGetFree)
    end

    --广告标记
    local adMark = self:GetGoOrNil(claimFreeBtn.gameObject,"nomalBg/adIcon")
    if adMark then
        adMark:SetActive(freeConfig.isAd and (not claimedFree) and (not DiamondFundUI:IsBoughtFund()))
    end

    self:SetButtonClickHandler(claimPayBtn, function()
        if canGetPay then
            self:GetReward(payIndex)
        end
    end)
    self:SetButtonClickHandler(claimFreeBtn, function()
        if canGetFree then
            if not DiamondFundUI:IsBoughtFund() and freeConfig.isAd then
                claimFreeBtn.interactable = false
                GameSDKs:PlayRewardAd(
                        function()
                            self:GetReward(freeIndex)
                        end,
                        function()
                            claimFreeBtn.interactable = true
                        end,
                        function()
                            claimFreeBtn.interactable = true
                        end,
                        10014)
            else
                self:GetReward(freeIndex)
            end
        end
    end)
    --图标锁
    if DiamondFundUI:IsBoughtFund() then
        self:GetGo(go, "bg/premiumBtn/premiumBg/lockIcon"):SetActive(false)
    else
        self:GetGo(go, "bg/premiumBtn/premiumBg/lockIcon"):SetActive(true)
    end
    --知名度图标动画
    if DiamondFundUI.m_view then
        local itemAnimator = self:GetComp(go,"bg/fame/fameBg_open","Animator")
        if self:IsNewest(index) then
            self:PlayAnimationNextFrame(itemAnimator,"DiamondFundUI_2_fameBg_open2_new",2)
            --itemAnimator:Play("DiamondFundUI_2_fameBg_open2_new",0,0)
            --itemAnimator:SetBool("IsNew",true)
        else
            self:PlayAnimationNextFrame(itemAnimator,"DiamondFundUI_2_fameBg_open2")
            --itemAnimator:Play("DiamondFundUI_2_fameBg_open2",0,0)
            --itemAnimator:SetBool("IsNew",false)
        end
    end
    --if CanGet then
    --    self:GetGo(go, "bg/locked"):SetActive(false)
    --else
    --    self:GetGo(go, "bg/locked"):SetActive(true)
    --
    --    if not fundData["fame" .. index] then
    --        self:GetGo(go, "bg/locked"):SetActive(false)
    --    end
    --end
    --控制装饰线
    --if index == #cfg then
    --    self:GetGo(go, "line"):SetActive(false)
    --    self:GetGo(go, "bg/locked/line"):SetActive(false)
    --end
end

---是否解锁某个等级，用来做知名度进度条动画表现
function DiamondFundUIView:IsUnlockFame(index)
    if fundData then
        local targetFame = ConfigMgr.config_fund[index].fame
        local lastFame = fundData.lastUnlockIndex and ConfigMgr.config_fund[fundData.lastUnlockIndex].fame or 0
        return lastFame >= targetFame
    end
    return false
end

function DiamondFundUIView:GetUnlockFame()
    if fundData then
        return fundData.lastUnlockIndex or 0
    end
    return 0
end

function DiamondFundUIView:SetUnlockFame(index)
    if fundData then
        fundData.lastUnlockIndex = index
    end
end

---获取第一个可以获得奖励的Index
function DiamondFundUIView:GetFirstCanGetIndex()
    local totalCount = math.floor(#ConfigMgr.config_fund / 2)
    local isBoughtFund = DiamondFundUI:IsBoughtFund()
    for i = 1, totalCount do
        if (isBoughtFund and fundData["fame" .. i]) or fundData["fame" .. (i + totalCount)] then
            return i
        end
    end
    return 1
end

---是否是最新达到的等级
function DiamondFundUIView:IsNewest(index)
    local fundConfig = ConfigMgr.config_fund[index]
    local star = StarMode:GetStar()
    if fundConfig.fame <= star then
        local nextIndex = index + 1
        if nextIndex > TOTAL_COUNT then
            return true
        else
            local nextConfig = ConfigMgr.config_fund[nextIndex]
            return nextConfig.fame > star
        end
    else
        return false
    end
end

---下一帧播放动画，以免和Entry冲突
function DiamondFundUIView:PlayAnimationNextFrame(animator,animName,frame)
    local curFrame = UnityTime.frameCount
    local timer = nil
    frame = frame or 1
    timer = GameTimer:CreateNewMilliSecTimer(1,function()
        if UnityTime.frameCount > curFrame + frame then
            if animator and not animator:IsNull() then
                if animator.gameObject.activeInHierarchy then
                    animator:Play(animName)
                    GameTimer:StopTimer(timer)
                end
            else
                GameTimer:StopTimer(timer)
            end
        end
    end,true,false)
end

function DiamondFundUIView:OnExit()
    ShopManager:refreshBuySuccess()
    ShopManager:refreshBuyFail()
    self.super:OnExit(self)

    if self.m_sliderAnimTimer then
        GameTimer:StopTimer(self.m_sliderAnimTimer)
        self.m_sliderAnimTimer = nil
    end
    shop = nil
    fundData = nil
end

return DiamondFundUIView
