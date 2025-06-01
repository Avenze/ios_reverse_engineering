local SeasonPassUIView = require("GamePlay.Common.UI.SeasonPassUIView")
local SeasonPassManager = GameTableDefine.SeasonPassManager
local ShopManager = GameTableDefine.ShopManager
local ItemHeight = 220
local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
local BuyLevelDiamond = 100
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local Tools = Tools
local GameUIManager = GameTableDefine.GameUIManager
local UnityTime = CS.UnityEngine.Time
local SLIDER_SPEED = 1.5
local Shop = GameTableDefine.Shop
local AnimationUtil = CS.Common.Utils.AnimationUtil
local PassType = {
    Premium = "Premium",
    Luxury = "Luxury",
}

function SeasonPassUIView:ctorReward()

    self.m_rewardConfigCount = nil
    self.m_rewardConfigs = nil ---@type SeasonPassRewardConfig[]
    self.m_rewardListSlider = nil ---@type UnityEngine.UI.Slider
    self.m_rewardListMaskSlider = nil ---@type UnityEngine.UI.Slider
    self.m_rewardList = nil ---@type UnityEngine.UI.ScrollRectEx

    self.m_levelGOPrefab = nil ---@type UnityEngine.GameObject
    self.m_levelTransList = {} ---@type UnityEngine.Transform[]
    self.m_levelPosOffset = nil ---@type UnityEngine.Vector3
    self.m_rewardLevelText = nil ---@type UnityEngine.UI.Text

    self.m_sliderAnimTimer = nil
end

---加载完这一界面时调用
function SeasonPassUIView:OnEnterRewardView()
    self.m_rewardRootGO = self.m_subGODic[SeasonPassUIView.PageType.Reward]
    --经验与等级
    self.m_rewardLevelText = self:GetComp(self.m_rewardRootGO,"bg2/titleBanel/titleLevel/bg/num","TMPLocalization")
    self.m_rewardExpNowText = self:GetComp(self.m_rewardRootGO,"bg2/titleBanel/rewardHolder/have","TMPLocalization")
    self.m_rewardExpNeedText = self:GetComp(self.m_rewardRootGO,"bg2/titleBanel/rewardHolder/all","TMPLocalization")
    self.m_rewardLevelSlider = self:GetComp(self.m_rewardRootGO,"bg2/titleBanel/levelProg", "Slider")
    self.m_rewardLevelMaxSlider = self:GetComp(self.m_rewardRootGO,"bg2/titleBanel/levelProgMax", "Slider")
    self.m_rewardBuyLevelBtn = self:GetComp(self.m_rewardRootGO,"bg2/titleBanel/buyBtn","Button")
    self:SetButtonClickHandler(self.m_rewardBuyLevelBtn,handler(self,self.OnBuyLevelBtnDown))

    --通行证购买
    self.m_premiumBtn = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listTitle/premiumBtn","Button")
    self.m_luxuryBtn = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listTitle/luxuryBtn","Button")
    self.m_rewardPremiumPriceText = self:GetComp(self.m_premiumBtn.gameObject,"num","TMPLocalization")
    self.m_rewardLuxuryPriceText = self:GetComp(self.m_luxuryBtn.gameObject,"num","TMPLocalization")

    --奖励列表
    self.m_rewardListSlider = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/List/Viewport/Content/Slider","Slider")
    self.m_rewardListMaskSlider = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/List/Viewport/Content/MaskSlider","Slider")
    self.m_rewardList = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/List","ScrollRectEx")
    self:SetListUpdateFunc(self.m_rewardList,handler(self,self.OnRewardUpdate))
    self:SetListItemCountFunc(self.m_rewardList,function()
        --奖励加最后一级奖励
        return self:GetSizeOfReward() + 1
    end)
    self:SetListItemNameFunc(self.m_rewardList,handler(self,self.GetNameOfListItem))
    self:SetListLayoutFunc(self.m_rewardList,handler(self,self.RefreshRewardListSliderState))

    self.m_rewardConfigs = SeasonPassManager:GetCurrentRewardConfigs()

    --一键领取与大奖预告
    self.m_claimAllBtnRootGO = self:GetGo(self.m_rewardRootGO,"bg2/rewardList/listBanner/btn")
    self.m_claimAllBtn = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listBanner/btn/claimAllBtn","Button")
    self:SetButtonClickHandler(self.m_claimAllBtn,handler(self,self.ClaimAllReward))
    self:GetGo(self.m_rewardRootGO,"bg2/rewardList/listBanner"):SetActive(true)
    self.m_bigRewardPreview = {}
    local previewRootGO = self:GetGo(self.m_rewardRootGO,"bg2/rewardList/listBanner/item")
    self.m_bigRewardPreview.rootGO = previewRootGO

    self.m_bigRewardPreview.normal = {}
    self.m_bigRewardPreview.normal.icon = self:GetComp(previewRootGO,"bg/nomalBtn/nomalBg/icon","Image")
    self.m_bigRewardPreview.normal.numText = self:GetComp(previewRootGO,"bg/nomalBtn/nomalBg/num","TMPLocalization")
    self.m_bigRewardPreview.normal.finishBg = self:GetGo(previewRootGO,"bg/nomalBtn/finishBg")
    self.m_bigRewardPreview.normal.btn = self:GetComp(previewRootGO,"bg/nomalBtn","Button")
    self:SetButtonClickHandler(self.m_bigRewardPreview.normal.btn,function()
        local id = self.m_bigRewardPreview.normal.itemID
        if id then
            local shopConfig = ShopManager:GetCfg(id)
            local infoTitle = GameTextLoader:ReadText(shopConfig.name)
            local infoDesc = GameTextLoader:ReadText(shopConfig.desc)
            self:OpenRewardInfo(self.m_bigRewardPreview.normal.icon.gameObject,infoTitle,infoDesc)
        end
    end)

    self.m_bigRewardPreview.premium = {}
    self.m_bigRewardPreview.premium.icon = self:GetComp(previewRootGO,"bg/premiumBtn/premiumBg/icon","Image")
    self.m_bigRewardPreview.premium.numText = self:GetComp(previewRootGO,"bg/premiumBtn/premiumBg/num","TMPLocalization")
    self.m_bigRewardPreview.premium.finishBg = self:GetGo(previewRootGO,"bg/premiumBtn/finishBg")
    --self.m_bigRewardPreview.premium.lockGO = self:GetGo(previewRootGO,"bg/premiumBtn/premiumBg/lockIcon")
    self.m_bigRewardPreview.premium.btn = self:GetComp(previewRootGO,"bg/premiumBtn","Button")
    self:SetButtonClickHandler(self.m_bigRewardPreview.premium.btn,function()
        local id = self.m_bigRewardPreview.premium.itemID
        if id then
            local shopConfig = ShopManager:GetCfg(id)
            local infoTitle = GameTextLoader:ReadText(shopConfig.name)
            local infoDesc = GameTextLoader:ReadText(shopConfig.desc)
            self:OpenRewardInfo(self.m_bigRewardPreview.premium.icon.gameObject,infoTitle,infoDesc)
        end
    end)

    self.m_bigRewardPreview.luxury = {}
    self.m_bigRewardPreview.luxury.icon = self:GetComp(previewRootGO,"bg/luxuryBtn/luxuryBg/icon","Image")
    self.m_bigRewardPreview.luxury.numText = self:GetComp(previewRootGO,"bg/luxuryBtn/luxuryBg/num","TMPLocalization")
    self.m_bigRewardPreview.luxury.finishBg = self:GetGo(previewRootGO,"bg/luxuryBtn/finishBg")
    --self.m_bigRewardPreview.luxury.lockGO = self:GetGo(previewRootGO,"bg/luxuryBtn/luxuryBg/lockIcon")
    self.m_bigRewardPreview.luxury.btn = self:GetComp(previewRootGO,"bg/luxuryBtn","Button")
    self:SetButtonClickHandler(self.m_bigRewardPreview.luxury.btn,function()
        local id = self.m_bigRewardPreview.luxury.itemID
        if id then
            local shopConfig = ShopManager:GetCfg(id)
            local infoTitle = GameTextLoader:ReadText(shopConfig.name)
            local infoDesc = GameTextLoader:ReadText(shopConfig.desc)
            self:OpenRewardInfo(self.m_bigRewardPreview.luxury.icon.gameObject,infoTitle,infoDesc)
        end
    end)

    self.m_bigRewardPreview.fameNumText = self:GetComp(previewRootGO,"bg/fame/num","TMPLocalization")

    self:SetListScrollFunc(self.m_rewardList,handler(self,self.RefreshRewardPreview))

    self.m_rewardList:UpdateData(true)
    local itemTemp = self.m_rewardList:GetItemTemplate("item")
    local itemTempTrans = self:GetComp(itemTemp.gameObject,"","RectTransform")
    ItemHeight = itemTempTrans.rect.height
    self.m_levelGOPrefab = self:GetGo(itemTemp.gameObject,"bg/fame")
    --self.m_levelPosOffset = self.m_levelGOPrefab.transform.position-self.m_slider.transform.position
    self.m_levelPosOffset = self.m_rewardListSlider.transform:InverseTransformPoint(self.m_levelGOPrefab.transform.position)
    self.m_rewardListSlider.gameObject:SetActive(true)
    self.m_rewardListMaskSlider.gameObject:SetActive(true)
    self:InitSliderSize()
    self:InitPassInfo()
    --self:UpdateSliderValue()
end

function SeasonPassUIView:GetSizeOfReward()
    if not self.m_rewardConfigCount then
        self.m_rewardConfigCount = #self.m_rewardConfigs
    end
    return self.m_rewardConfigCount
end

function SeasonPassUIView:GetNameOfListItem(index)
    return index < self:GetSizeOfReward() and "item" or "lastReward"
end

function SeasonPassUIView:InitSliderSize()
    local sliderSize = self.m_rewardListSlider.transform.sizeDelta
    local totalCount = self:GetSizeOfReward()
    sliderSize.y = ItemHeight * totalCount
    self.m_rewardListSlider.transform.sizeDelta = sliderSize

    local maskSliderSize = self.m_rewardListMaskSlider.transform.sizeDelta
    maskSliderSize.y = sliderSize.y
    self.m_rewardListMaskSlider.transform.sizeDelta = maskSliderSize

    local curLevelTransCount = #self.m_levelTransList
    if curLevelTransCount < totalCount then
        for i = curLevelTransCount+1, totalCount do
            local go = GameObject.Instantiate(self.m_levelGOPrefab, self.m_rewardListSlider.transform)
            self.m_levelTransList[i] = go
            go:SetActive(true)
            local rewardConfig = self.m_rewardConfigs[i]
            local levelStr = tostring(rewardConfig.level)
            self:SetText(go,"num",levelStr)
            local localPos = Vector3(self.m_levelPosOffset.x,self.m_levelPosOffset.y - ItemHeight * (i-1),self.m_levelPosOffset.z)
            go.transform.localPosition = localPos
        end
    end
end

function SeasonPassUIView:PlayUnlockAnim()
    local lastUnlockIndex = SeasonPassManager:GetUnlockFame()
    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    local canUnlockIndex = math.min(maxLevel,math.max(lastUnlockIndex,curLevel))

    if canUnlockIndex > lastUnlockIndex then
        local totalCount = maxLevel
        GameUIManager:SetEnableTouch(false)
        local curIndex = lastUnlockIndex
        if curIndex == 0 then
            curIndex = 0.5
        end
        local nextIndex = lastUnlockIndex + 1
        local sliderValue = (curIndex - 0.5) / totalCount
        --等待Slider长度初始化完成
        --GameTimer:CreateNewTimer(0.2,function()
        self.m_sliderAnimTimer = GameTimer:CreateNewMilliSecTimer(1,function()
            curIndex = curIndex + UnityTime.deltaTime * SLIDER_SPEED
            if curIndex >= nextIndex then
                SeasonPassManager:SetUnlockFame(nextIndex)
                --播放动画
                local itemElementTrans = self.m_rewardList:GetScrollItemTranByIndex(nextIndex-1)
                if itemElementTrans then
                    self:UpdateCommonReward(nextIndex,itemElementTrans.gameObject)
                end
                --TODO 暂时没有到达特效
                --local fameTrans = self.m_levelTransList[nextIndex]
                --if fameTrans then
                --    local fameGO = fameTrans.gameObject
                --    local itemAnimator = self:GetComp(fameGO,"fameBg_open","Animator")
                --    self:GetGo(fameGO,"fameBg_open"):SetActive(true)
                --    self:GetGo(fameGO,"fameBg_off"):SetActive(false)
                --    if nextIndex == curLevel then
                --        self:PlayAnimationNextFrame(itemAnimator,"DiamondFundUI_2_fameBg_open1_new",3)
                --    else
                --        self:PlayAnimationNextFrame(itemAnimator,"DiamondFundUI_2_fameBg_open1",2)
                --    end
                --end

                nextIndex = nextIndex + 1
                if nextIndex > canUnlockIndex then
                    --停止
                    GameTimer:StopTimer(self.m_sliderAnimTimer)
                    self.m_sliderAnimTimer = nil
                    curIndex = canUnlockIndex
                    GameUIManager:SetEnableTouch(true)
                    self:UpdateSliderValue()
                end
            end
            sliderValue = (curIndex - 0.5) * 1.0 / totalCount
            self.m_rewardListSlider.value = sliderValue
            self.m_rewardListMaskSlider.value = 1 - curIndex * 1.0 / totalCount
            --锁定视角
            local contentPos = self.m_rewardList.content.anchoredPosition
            contentPos.y = (curIndex-2) * ItemHeight
            self.m_rewardList:ScrollToPos(contentPos)
        end,true)
        --end)
    else
        local firstCanGetIndex = SeasonPassManager:GetFirstCanGetRewardIndex()
        local contentPos = self.m_rewardList.content.anchoredPosition
        contentPos.y = (firstCanGetIndex-2) * ItemHeight
        self.m_rewardList:ScrollToPos(contentPos)
        self:UpdateSliderValue()
    end
end

---下一帧播放动画，以免和Entry冲突
function SeasonPassUIView:PlayAnimationNextFrame(animator,animName,frame)
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

---将ListSlider放到最下面
function SeasonPassUIView:RefreshRewardListSliderState()
    self.m_rewardListSlider.transform:SetAsLastSibling()
    self.m_rewardListMaskSlider.transform:SetAsLastSibling()
end

---刷新刷新大奖预览
function SeasonPassUIView:RefreshRewardPreview()
    if self.m_needUpdatePreview then
        --关键奖励与一键领取
        local curShowLastIndex = 1
        for i = self.m_rewardConfigCount, 1,-1 do
            if self.m_rewardList:GetScrollItemIsInUse(i-1) then
                curShowLastIndex = i
                break
            end
        end
        local curShowLastTrans = self.m_rewardList:GetScrollItemTranByIndex(curShowLastIndex-1)
        if curShowLastTrans then
            if curShowLastTrans.position.y > self.m_bigRewardPreview.normal.finishBg.transform.position.y then
                --最后一个元素超过预览后就不显示预览了
                curShowLastIndex = self.m_rewardConfigCount+1
            end
        end
        local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
        if curLevel>=maxLevel then
            --满级后不显示预览
            curShowLastIndex = self.m_rewardConfigCount + 1
        else
            --预览大于等于当前通行证等级
            curShowLastIndex = math.max(curShowLastIndex,curLevel+1)
        end
        local needShowGrandPoint = nil
        for i = curShowLastIndex,self.m_rewardConfigCount do
            if self.m_rewardConfigs[i].grand_point == 1 then
                needShowGrandPoint= i
                break
            end
        end
        if needShowGrandPoint then
            self.m_bigRewardPreview.rootGO:SetActive(true)
            self:UpdateBigRewardPreview(needShowGrandPoint)
        else
            self.m_bigRewardPreview.rootGO:SetActive(false)
        end
    end
end

function SeasonPassUIView:UpdateSliderValue()
    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    local sliderValue = (curLevel - 0.5) / maxLevel
    self.m_rewardListSlider.value = sliderValue
    self.m_rewardListMaskSlider.value = 1 - curLevel * 1.0 / maxLevel
    if curLevel >= maxLevel then
        local goldLineGO = self:GetGoOrNil(self.m_rewardListSlider.gameObject, "goldLine")
        if goldLineGO then
            goldLineGO:SetActive(false)
        end
    end
end

function SeasonPassUIView:UpdateLevelAndExp()
    local curLevel, maxLevel = SeasonPassManager:GetLevelInfo()
    --local _, maxLevelExtend = SeasonPassManager:GetLevelInfo(true)
    local nowExp, needExp = SeasonPassManager:GetExpInfo()

    if curLevel >= maxLevel then
        --curLevel = maxLevel
        self.m_rewardLevelMaxSlider.value = 1.0 * nowExp / needExp
    else
        self.m_rewardLevelSlider.value = 1.0 * nowExp / needExp
    end
    self.m_rewardBuyLevelBtn.gameObject:SetActive(curLevel < maxLevel)
    self.m_rewardLevelMaxSlider.gameObject:SetActive(curLevel >= maxLevel)


    self.m_rewardLevelText.text = tostring(curLevel >= maxLevel and maxLevel or curLevel)
    self.m_rewardExpNowText.text = tostring(nowExp)
    self.m_rewardExpNeedText.text = tostring(needExp)
    
    self.m_rewardBuyLevelBtn.interactable = curLevel < maxLevel
end

---刷新通行证购买按钮的状态
function SeasonPassUIView:InitPassInfo()
    local premiumPrice,luxuryPrice = SeasonPassManager:GetPassPrice()
    self.m_rewardPremiumPriceText.text = tostring(premiumPrice)
    self.m_rewardLuxuryPriceText.text = tostring(luxuryPrice)

    self:SetButtonClickHandler(self.m_premiumBtn,function()
        --SeasonPassManager:BuyPremiumPass()
        self:ShowPassPurchaseUI(PassType.Premium)
    end)

    self:SetButtonClickHandler(self.m_luxuryBtn,function()
        --SeasonPassManager:BuyLuxuryPass()
        self:ShowPassPurchaseUI(PassType.Luxury)
    end)

    self:RefreshPassInfo()
end

---刷新通行证购买按钮的状态
function SeasonPassUIView:RefreshPassInfo()
    self.m_premiumBtn.gameObject:SetActive(not SeasonPassManager:IsBuyPremium())
    self.m_luxuryBtn.gameObject:SetActive(not SeasonPassManager:IsBuyLuxury())
end

function SeasonPassUIView:EnableRewardVfxAnim(vfxGO,iconAnimator,canGetReward)
    vfxGO:SetActive(canGetReward)
    if not canGetReward then
        --重置动画
        iconAnimator.enabled = true
        iconAnimator:Play(iconAnimator:GetCurrentAnimatorStateInfo(0).fullPathHash, -1, 0)
        iconAnimator:Update(0)
    end
    iconAnimator.enabled = canGetReward
end

---奖励列表中的元素
function SeasonPassUIView:UpdateCommonReward(index,go)

    local rewardConfig = self.m_rewardConfigs[index]
    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    local rewardLevel = rewardConfig.level
    local levelEnough = curLevel >= rewardLevel

    --normal
    local normalRewards = rewardConfig.normal_rewards
    if normalRewards then
        local btnRootGO = self:GetGo(go,"bg/nomalBtn")
        local icon = self:GetComp(btnRootGO,"nomalBg/icon","Image")
        local shopConfig = ShopManager:GetCfg(normalRewards[1])
        local normalRewardCount = normalRewards[2] or 1
        self:SetSprite(icon,"UI_Shop",shopConfig.icon,nil,false,true)
        local showValue,typeName = ShopManager:GetValue(shopConfig)
        if tonumber(showValue) ~= nil then
            showValue = showValue * normalRewardCount
        else
            showValue = 1
        end
        self:SetText(btnRootGO,"nomalBg/num",tostring(showValue))

        local isGotReward = SeasonPassManager:IsGotReward(rewardLevel,SeasonPassManager.RewardType.Normal)
        local btn = self:GetComp(btnRootGO,"","Button")
        local canGetReward = levelEnough and (not isGotReward)
        self:SetButtonClickHandler(btn,function()
            if SeasonPassManager:DistributeReward(rewardLevel,SeasonPassManager.RewardType.Normal) then
                self:UpdateCommonReward(index,go)
                self:RefreshClaimAllRewardBtn()
            else
                local infoTitle = GameTextLoader:ReadText(shopConfig.name)
                local infoDesc = GameTextLoader:ReadText(shopConfig.desc)
                local pivot = self:GetGoOrNil(icon.gameObject,"pivot") or icon.gameObject
                self:OpenRewardInfo(pivot,infoTitle,infoDesc)
            end
        end)
        self:GetGo(btnRootGO,"finishBg"):SetActive(isGotReward)
        --动效
        local vfxGO = self:GetGo(btnRootGO,"nomalBg/vfx")
        local iconAnimator = self:GetComp(btnRootGO,"nomalBg","Animator")
        self:EnableRewardVfxAnim(vfxGO,iconAnimator,canGetReward)
    end

    --premium
    local premiumRewards = rewardConfig.premium_rewards
    if premiumRewards then
        local btnRootGO = self:GetGo(go,"bg/premiumBtn")
        local icon = self:GetComp(btnRootGO,"premiumBg/icon","Image")
        local shopConfig = ShopManager:GetCfg(premiumRewards[1])
        local count = premiumRewards[2] or 1
        self:SetSprite(icon,"UI_Shop",shopConfig.icon,nil,false,true)
        local showValue,typeName = ShopManager:GetValue(shopConfig)
        if tonumber(showValue) ~= nil then
            showValue = showValue * count
        else
            showValue = 1
        end
        self:SetText(btnRootGO,"premiumBg/num",tostring(showValue))

        local isGotReward = SeasonPassManager:IsGotReward(rewardLevel,SeasonPassManager.RewardType.Premium)
        local btn = self:GetComp(btnRootGO,"","Button")
        local canGetReward = levelEnough and SeasonPassManager:IsBuyPremium() and not isGotReward
        self:SetButtonClickHandler(btn,function()
            if SeasonPassManager:DistributeReward(rewardLevel,SeasonPassManager.RewardType.Premium) then
                self:UpdateCommonReward(index,go)
                self:RefreshClaimAllRewardBtn()
            else
                local infoTitle = GameTextLoader:ReadText(shopConfig.name)
                local infoDesc = GameTextLoader:ReadText(shopConfig.desc)
                local pivot = self:GetGoOrNil(icon.gameObject,"pivot") or icon.gameObject
                self:OpenRewardInfo(pivot,infoTitle,infoDesc)
            end
        end)
        self:GetGo(btnRootGO,"finishBg"):SetActive(isGotReward)
        --动效
        local vfxGO = self:GetGo(btnRootGO,"premiumBg/vfx")
        local iconAnimator = self:GetComp(btnRootGO,"premiumBg","Animator")

        --解锁动画
        local lockGO = self:GetGo(btnRootGO,"premiumBg/lockIcon")
        if self.m_needPlayUnlockPassType == PassType.Premium then
            lockGO:SetActive(true)
            local anim = self:GetComp(lockGO,"lockIcon","Animation")
            local find, name = AnimationUtil.GetFirstClipName(anim)
            AnimationUtil.Play(anim, name, function()
                lockGO:SetActive(false)
                if canGetReward then
                    self:EnableRewardVfxAnim(vfxGO,iconAnimator,true)
                end
            end)
        else
            lockGO:SetActive(not SeasonPassManager:IsBuyPremium())
        end
        --必须等解锁动画播放完后再切换特效显示
        self:EnableRewardVfxAnim(vfxGO,iconAnimator,canGetReward and self.m_needPlayUnlockPassType ~= PassType.Premium)
    end

    --luxury
    local luxuryRewards = rewardConfig.luxury_rewards
    if luxuryRewards then
        local btnRootGO = self:GetGo(go,"bg/luxuryBtn")
        local icon = self:GetComp(btnRootGO,"luxuryBg/icon","Image")
        local shopConfig = ShopManager:GetCfg(luxuryRewards[1])
        local count = luxuryRewards[2] or 1
        self:SetSprite(icon,"UI_Shop",shopConfig.icon,nil,false,true)
        local showValue,typeName = ShopManager:GetValue(shopConfig)
        if tonumber(showValue) ~= nil then
            showValue = showValue * count
        else
            showValue = 1
        end
        self:SetText(btnRootGO,"luxuryBg/num",tostring(showValue))

        local isGotReward = SeasonPassManager:IsGotReward(rewardLevel,SeasonPassManager.RewardType.Luxury)
        local btn = self:GetComp(btnRootGO,"","Button")
        local canGetReward = levelEnough and SeasonPassManager:IsBuyLuxury() and not isGotReward
        self:SetButtonClickHandler(btn,function()
            if SeasonPassManager:DistributeReward(rewardLevel,SeasonPassManager.RewardType.Luxury) then
                self:UpdateCommonReward(index,go)
                self:RefreshClaimAllRewardBtn()
            else
                local infoTitle = GameTextLoader:ReadText(shopConfig.name)
                local infoDesc = GameTextLoader:ReadText(shopConfig.desc)
                local pivot = self:GetGoOrNil(icon.gameObject,"pivot") or icon.gameObject
                self:OpenRewardInfo(pivot,infoTitle,infoDesc)
            end
        end)
        self:GetGo(btnRootGO,"finishBg"):SetActive(isGotReward)

        --动效
        local vfxGO = self:GetGo(btnRootGO,"luxuryBg/vfx")
        local iconAnimator = self:GetComp(btnRootGO,"luxuryBg","Animator")
        --解锁动画
        local lockGO = self:GetGo(btnRootGO,"luxuryBg/lockIcon")
        if self.m_needPlayUnlockPassType == PassType.Luxury then
            lockGO:SetActive(true)
            local anim = self:GetComp(lockGO,"lockIcon","Animation")
            local find, name = AnimationUtil.GetFirstClipName(anim)
            AnimationUtil.Play(anim, name, function()
                lockGO:SetActive(false)
                if canGetReward then
                    self:EnableRewardVfxAnim(vfxGO,iconAnimator,true)
                end
            end)
        else
            lockGO:SetActive(not SeasonPassManager:IsBuyLuxury())
        end
        --必须等解锁动画播放完后再切换特效显示
        self:EnableRewardVfxAnim(vfxGO,iconAnimator,canGetReward and self.m_needPlayUnlockPassType ~= PassType.Luxury)
    end

    --local level = rewardConfig.level
    --self:SetText(go,"bg/fame/fameBg_open/num",tostring(level))
    --self:GetGo(go,"bg/blackMask"):SetActive(not levelEnough)
    self:GetGo(go,"bg/fame"):SetActive(false)
end

---最后的循环奖励,唯一一个
function SeasonPassUIView:UpdateLastReward(index, go)
    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    local curGetAdditional, maxAdditional,canGetCount = SeasonPassManager:GetAdditionalRewardInfo()
    local isBuyLuxury = SeasonPassManager:IsBuyLuxury()
    local tipGO = self:GetGo(go,"tip")
    local iconBtn
    if isBuyLuxury and curLevel >= maxLevel then
        self:GetGo(go,"lock"):SetActive(false)
        self:GetGo(go,"unLock"):SetActive(true)
        self:SetText(go,"unLock/showNum/haveNum", curGetAdditional)
        self:SetText(go,"unLock/showNum/limitNum", maxAdditional)
        self:SetText(go,"unLock/numBg/num",canGetCount)
        local additionalBtn = self:GetComp(go,"unLock/showNum/btn","Button")
        additionalBtn.interactable = canGetCount > 0
        self:SetButtonClickHandler(additionalBtn,function()
            SeasonPassManager:DistributeAdditionalReward()
            self:UpdateLastReward(index,go)
        end)
        iconBtn = self:GetComp(go,"unLock/icon","Button")
    else
        self:SetText(go,"lock/numBg/num",tostring(canGetCount))
        self:GetGo(go,"lock"):SetActive(true)
        self:GetGo(go,"unLock"):SetActive(false)
        iconBtn = self:GetComp(go,"lock/icon","Button")
    end
    self:SetButtonClickHandler(iconBtn,function()
        tipGO:SetActive(not tipGO.activeSelf)
    end)
end

---大奖预告
function SeasonPassUIView:UpdateBigRewardPreview(index)

    local rewardConfig = self.m_rewardConfigs[index]
    --local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    local rewardLevel = rewardConfig.level
    --local levelEnough = curLevel >= rewardLevel

    --normal
    local normalRewards = rewardConfig.normal_rewards
    if normalRewards then
        local itemID = normalRewards[1]
        local shopConfig = ShopManager:GetCfg(itemID)
        local normalRewardCount = normalRewards[2] or 1
        self:SetSprite(self.m_bigRewardPreview.normal.icon,"UI_Shop",shopConfig.icon,nil,false,true)
        local showValue,typeName = ShopManager:GetValue(shopConfig)
        if tonumber(showValue) ~= nil then
            showValue = showValue * normalRewardCount
        else
            showValue = 1
        end
        self.m_bigRewardPreview.normal.numText.text = tostring(showValue)
        self.m_bigRewardPreview.normal.itemID = itemID

        local isGotReward = SeasonPassManager:IsGotReward(rewardLevel,SeasonPassManager.RewardType.Normal)
        self.m_bigRewardPreview.normal.finishBg:SetActive(isGotReward)
    end

    --premium
    local premiumRewards = rewardConfig.premium_rewards
    if premiumRewards then
        local itemID = premiumRewards[1]
        local shopConfig = ShopManager:GetCfg(itemID)
        local count = premiumRewards[2] or 1
        self:SetSprite(self.m_bigRewardPreview.premium.icon,"UI_Shop",shopConfig.icon,nil,false,true)
        local showValue,typeName = ShopManager:GetValue(shopConfig)
        if tonumber(showValue) ~= nil then
            showValue = showValue * count
        else
            showValue = 1
        end
        self.m_bigRewardPreview.premium.numText.text = tostring(showValue)
        self.m_bigRewardPreview.premium.itemID = itemID

        --self.m_bigRewardPreview.premium.lockGO:SetActive(not SeasonPassManager:IsBuyPremium())

        local isGotReward = SeasonPassManager:IsGotReward(rewardLevel,SeasonPassManager.RewardType.Premium)
        self.m_bigRewardPreview.premium.finishBg:SetActive(isGotReward)
    end

    --luxury
    local luxuryRewards = rewardConfig.luxury_rewards
    if luxuryRewards then
        local itemID = luxuryRewards[1]
        local shopConfig = ShopManager:GetCfg(itemID)
        local count = luxuryRewards[2] or 1
        self:SetSprite(self.m_bigRewardPreview.luxury.icon,"UI_Shop",shopConfig.icon,nil,false,true)
        local showValue,typeName = ShopManager:GetValue(shopConfig)
        if tonumber(showValue) ~= nil then
            showValue = showValue * count
        else
            showValue = 1
        end
        self.m_bigRewardPreview.luxury.numText.text = tostring(showValue)
        self.m_bigRewardPreview.luxury.itemID = itemID

        --self.m_bigRewardPreview.luxury.lockGO:SetActive(not SeasonPassManager:IsBuyLuxury())

        local isGotReward = SeasonPassManager:IsGotReward(rewardLevel,SeasonPassManager.RewardType.Luxury)
        self.m_bigRewardPreview.luxury.finishBg:SetActive(isGotReward)
    end

    self.m_bigRewardPreview.fameNumText.text = tostring(rewardLevel)
end

---奖励列表更新回调，刷新对应列表元素显示内容
function SeasonPassUIView:OnRewardUpdate(index, tran)
    index = index + 1
    local go = tran.gameObject

    if index <= self:GetSizeOfReward() then
        self:UpdateCommonReward(index,go)
    else
        self:UpdateLastReward(index,go)
    end
end

function SeasonPassUIView:OnBuyLevelBtnDown()
    self:InitBuyLevelWindow()
    self.m_buyLevelWinGO:SetActive(true)

    local haveDiamond = ResourceManger:GetDiamond()
    local isResEnough = haveDiamond >= BuyLevelDiamond
    self:SetText("buyLevelWindow/buyBtn/resbanner/have", Tools:SeparateNumberWithComma(haveDiamond), not isResEnough and "FF1C1C" or "FFFFFF")
    --self.m_buyLevelWinHaveDiaText.text = Tools:SeparateNumberWithComma(haveDiamond)
    self.m_buyLevelWinBuyBtn.interactable = isResEnough

    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    self.m_buyLevelWinNowText.text = tostring(curLevel)
    self.m_buyLevelWinNextText.text = tostring(curLevel+1)
end

---显示这一界面时调用
function SeasonPassUIView:OnShowRewardView()
    ShopManager:refreshBuySuccess(function(shopId)
        if shopId == SeasonPassManager.PREMIUM_SHOP_ID or shopId == SeasonPassManager.LUXURY_SHOP_ID then
            local animator
            if shopId == SeasonPassManager.PREMIUM_SHOP_ID then
                SeasonPassManager:SetIsBuyPremiumPass()
                animator = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listTitle/premium","Animator")
                self.m_needPlayUnlockPassType = PassType.Premium
            elseif shopId == SeasonPassManager.LUXURY_SHOP_ID then
                SeasonPassManager:SetIsBuyLuxuryPass()
                animator = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listTitle/luxury","Animator")
                self.m_needPlayUnlockPassType = PassType.Luxury
            end

            local cb = function()
                self.m_rewardList:UpdateData()
                self:RefreshClaimAllRewardBtn()
                self.m_needPlayUnlockPassType = nil
                GameTimer:CreateNewTimer(1,function()
                    animator.enabled = false
                    GameUIManager:SetEnableTouch(true,"通行证解锁动画")
                end)
            end
            GameUIManager:SetEnableTouch(false,"通行证解锁动画")
            AnimationUtil.AddKeyFrameEventOnObj(animator.gameObject, "ANIM_END", cb) -- 调用的Unity的方法, 一次穿越
            animator.enabled = true
            animator:Play("Unlock")

            if self.m_passPurchasePanelGO then
                self.m_passPurchasePanelGO:SetActive(false)
            end
            self:RefreshPassInfo()
        end
    end)

    ShopManager:refreshBuyFail(function()

    end)

    --self.m_needUpdatePreview = false
    --self.m_rewardList:UpdateData()
    --刷新预览
    self.m_needUpdatePreview = true

    self:RefreshClaimAllRewardBtn()

    self:UpdateLevelAndExp()
    --播放解锁动画
    self:PlayUnlockAnim()
    self:RefreshRewardPreview()

    --切入界面时 如果看向额外奖励那么需要刷新额外奖励的信息
    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
    if curLevel > maxLevel then
        local additionalRewardTrans = self.m_rewardList:GetScrollItemTranByIndex(maxLevel)
        if additionalRewardTrans then
            self:UpdateLastReward(maxLevel+1,additionalRewardTrans.gameObject)
        end
    end
end

---购买等级窗口
function SeasonPassUIView:InitBuyLevelWindow()

    if self.m_initBuyLevelWindow then
        return
    end

    BuyLevelDiamond = ConfigMgr.config_global.pass_rewards_levelUpBuy

    self.m_buyLevelWinGO = self:GetGo("buyLevelWindow")
    self.m_buyLevelWinNowText = self:GetComp(self.m_uiObj,"buyLevelWindow/now","TMPLocalization")
    self.m_buyLevelWinNextText = self:GetComp(self.m_uiObj,"buyLevelWindow/next","TMPLocalization")
    self.m_buyLevelWinHaveDiaText = self:GetComp(self.m_uiObj,"buyLevelWindow/buyBtn/resbanner/have","TMPLocalization")
    self.m_buyLevelWinNeedDiaText = self:GetComp(self.m_uiObj,"buyLevelWindow/buyBtn/resbanner/need","TMPLocalization")

    --self.m_buyLevelWinExitBtn = self:GetComp(self.m_uiObj,"buyLevelWindow/bg/titleBanner/quitBtn","Button")
    self.m_buyLevelWinCloseBtn = self:GetComp(self.m_uiObj,"buyLevelWindow/BgCover","Button")
    self.m_buyLevelWinBuyBtn = self:GetComp(self.m_uiObj,"buyLevelWindow/buyBtn","Button")

    self.m_buyLevelWinNeedDiaText.text = tostring(BuyLevelDiamond)

    --self:SetButtonClickHandler(self.m_buyLevelWinExitBtn,function()
    --    self.m_buyLevelWinGO:SetActive(false)
    --end)
    self:SetButtonClickHandler(self.m_buyLevelWinCloseBtn,function()
        self.m_buyLevelWinGO:SetActive(false)
    end)
    self:SetButtonClickHandler(self.m_buyLevelWinBuyBtn,function()
        SeasonPassManager:BuyLevel(function(success)
            if success then
                self.m_buyLevelWinGO:SetActive(false)

                if self.m_currentPage == SeasonPassUIView.PageType.Task then
                    self:UpdateTaskViewLevelAndExp()
                end
                if not (self.m_currentPage == SeasonPassUIView.PageType.Reward) then
                    return
                end
                self:UpdateLevelAndExp()
                local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()
                if curLevel <= maxLevel then
                    --self:UpdateSliderValue()
                    --self.m_rewardList:UpdateData()
                    ----更新Slider上的fame信息
                    --local fameGO = self.m_levelTransList[curLevel]
                    --if fameGO then
                    --    self:GetGo(fameGO,"fameBg_open"):SetActive(true)
                    --    self:GetGo(fameGO,"fameBg_off"):SetActive(false)
                    --end
                    self:PlayUnlockAnim()
                    self:RefreshClaimAllRewardBtn()
                else
                    local additionalRewardTrans = self.m_rewardList:GetScrollItemTranByIndex(maxLevel)
                    if additionalRewardTrans then
                        self:UpdateLastReward(maxLevel+1,additionalRewardTrans.gameObject)
                    end
                end
                --self:RefreshRewardRedPoint()
                --需要更新下任务的红点
                self:RefreshTaskHintPoint()
            end
        end)
    end)
    self.m_initBuyLevelWindow = true
end

---离开这一界面或关闭整个界面(当前正在此界面)时调用
function SeasonPassUIView:OnExitRewardView(isCloseView)

    if self.m_sliderAnimTimer then
        GameTimer:StopTimer(self.m_sliderAnimTimer)
        self.m_sliderAnimTimer = nil
    end

    ShopManager:refreshBuySuccess()
    ShopManager:refreshBuyFail()
end

function SeasonPassUIView:ShowPassPurchaseUI(passType)

    self.m_tryBuyPassType = passType
    if not self.m_passPurchasePanelGO then
        self.m_passPurchasePanelGO = self:GetGo("passPurchaseWindow")
        self.m_passPurchasePremiumTypeIconGO = self:GetGo("passPurchaseWindow/icons/premiumIcon")
        self.m_passPurchaseLuxuryTypeIconGO = self:GetGo("passPurchaseWindow/icons/luxuryIcon")
        local buyBtn = self:GetComp("passPurchaseWindow/btns/btn_buy","Button")
        self.m_passPurchasePremiumValueGO = self:GetGo("passPurchaseWindow/btns/btn_buy/offvalue/num_1")
        self.m_passPurchaseLuxuryValueGO = self:GetGo("passPurchaseWindow/btns/btn_buy/offvalue/num_2")

        self:SetButtonClickHandler(buyBtn,function()
            if self.m_tryBuyPassType == PassType.Premium then
                SeasonPassManager:BuyPremiumPass()
            elseif self.m_tryBuyPassType == PassType.Luxury then
                SeasonPassManager:BuyLuxuryPass()
            end
        end)

        self.m_passPurchasePriceText = self:GetComp("passPurchaseWindow/btns/btn_buy/num","TMPLocalization")
        local passPurchaseQuitBtn = self:GetComp("passPurchaseWindow/BgCover","Button")
        self:SetButtonClickHandler(passPurchaseQuitBtn,function()
            self.m_passPurchasePanelGO:SetActive(false)
        end)
        local passPurchaseCloseBtn = self:GetComp("passPurchaseWindow/closeBtn","Button")
        self:SetButtonClickHandler(passPurchaseCloseBtn,function()
            self.m_passPurchasePanelGO:SetActive(false)
        end)
        self.m_purchaseScrollView = self:GetComp("passPurchaseWindow/list","ScrollRectEx")

        self.m_passPurchaseItemAllGOList = {}
        self.m_passPurchaseItemUpgradeGOList = {}
        self.m_passPurchaseItemAllPrefab = self:GetGo("passPurchaseWindow/list/Viewport/Content/allList/rewardItem")
        self.m_passPurchaseItemUpgradePrefab = self:GetGo("passPurchaseWindow/list/Viewport/Content/upgradeList/rewardItem")
        self.m_passPurchaseItemAllPrefab:SetActive(false)
        self.m_passPurchaseItemUpgradePrefab:SetActive(false)
    end
    self.m_passPurchasePanelGO:SetActive(true)

    local shopID
    if self.m_tryBuyPassType == "Premium" then
        shopID = SeasonPassManager.PREMIUM_SHOP_ID
    elseif self.m_tryBuyPassType == "Luxury" then
        shopID = SeasonPassManager.LUXURY_SHOP_ID
    end
    local priceStr = Shop:GetShopItemPrice(shopID)
    self.m_passPurchasePriceText.text = priceStr

    local curLevel,maxLevel = SeasonPassManager:GetLevelInfo()

    local allGO = self:GetGo("passPurchaseWindow/list/Viewport/Content/allList")
    local finishLuxuryGO = self:GetGo("passPurchaseWindow/list/Viewport/Content/finishList_luxury")
    local finishTextGO = self:GetGo("passPurchaseWindow/list/Viewport/Content/finishText")
    local upgradeGO = self:GetGo("passPurchaseWindow/list/Viewport/Content/upgradeList")
    local premiumGO = self:GetGo("passPurchaseWindow/list/Viewport/Content/allList/panel/text")
    local luxuryGO = self:GetGo("passPurchaseWindow/list/Viewport/Content/allList/panel/text_2")

    local allCanGetItemDatas = {}

    if self.m_tryBuyPassType == "Premium" then
        self.m_passPurchasePremiumValueGO:SetActive(true)
        self.m_passPurchaseLuxuryValueGO:SetActive(false)
        premiumGO:SetActive(true)
        luxuryGO:SetActive(false)
        self.m_passPurchasePremiumTypeIconGO:SetActive(true)
        self.m_passPurchaseLuxuryTypeIconGO:SetActive(false)
        for i = 1, self.m_rewardConfigCount do
            local rewardInfo = self.m_rewardConfigs[i].premium_rewards
            if rewardInfo then
                allCanGetItemDatas[#allCanGetItemDatas + 1] = {id = rewardInfo[1],count = rewardInfo[2]}
            end
        end
    elseif self.m_tryBuyPassType == "Luxury" then
        self.m_passPurchasePremiumValueGO:SetActive(false)
        self.m_passPurchaseLuxuryValueGO:SetActive(true)
        premiumGO:SetActive(false)
        luxuryGO:SetActive(true)
        self.m_passPurchasePremiumTypeIconGO:SetActive(false)
        self.m_passPurchaseLuxuryTypeIconGO:SetActive(true)
        for i = 1, self.m_rewardConfigCount do
            local rewardInfo = self.m_rewardConfigs[i].luxury_rewards
            if rewardInfo then
                allCanGetItemDatas[#allCanGetItemDatas + 1] = {id = rewardInfo[1],count = rewardInfo[2]}
            end
        end
    end
    --解锁的所有奖励
    local needShowDatas
    local needShowListParentTrans
    local itemPrefab
    local itemGOList
    --无论如何都要显示的解锁奖励
    do
        needShowDatas = self:CombineRewardDatas(allCanGetItemDatas)
        needShowListParentTrans = allGO.transform
        itemPrefab = self.m_passPurchaseItemAllPrefab
        itemGOList = self.m_passPurchaseItemAllGOList
        self:ShowPassPurchaseListItems(needShowDatas,needShowListParentTrans,itemPrefab,itemGOList)
    end
    --当前购买后可立即领取的奖励
    if curLevel >= maxLevel then
        finishLuxuryGO:SetActive(self.m_tryBuyPassType == "Luxury")
        finishTextGO:SetActive(true)
        upgradeGO:SetActive(false)
    else
        finishLuxuryGO:SetActive(false)
        finishTextGO:SetActive(false)
        upgradeGO:SetActive(true)
        local upgradeCanGetItemDatas = {}
        local canGetCount = 0
        for i = 1, curLevel do
            canGetCount = canGetCount + 1
            upgradeCanGetItemDatas[canGetCount] = allCanGetItemDatas[i]
        end
        needShowDatas = self:CombineRewardDatas(upgradeCanGetItemDatas)
        needShowListParentTrans = upgradeGO.transform
        itemPrefab = self.m_passPurchaseItemUpgradePrefab
        itemGOList = self.m_passPurchaseItemUpgradeGOList
        self:ShowPassPurchaseListItems(needShowDatas,needShowListParentTrans,itemPrefab,itemGOList)
    end
    --每次打开滑动到最上方
    local contentPos = self.m_purchaseScrollView.content.anchoredPosition
    contentPos.y = 0
    self.m_purchaseScrollView:ScrollToPos(contentPos)
end

---在对应List下显示所有奖励
function SeasonPassUIView:ShowPassPurchaseListItems(needShowDatas,needShowListParentTrans,itemPrefab,itemGOList)
    local needShowCount = #needShowDatas
    local haveItemGOCount = #itemGOList
    if needShowCount > haveItemGOCount then
        for i = haveItemGOCount+1, needShowCount do
            local itemGOData = {}
            itemGOList[i] = itemGOData
            itemGOData.go = GameObject.Instantiate(itemPrefab,needShowListParentTrans)
            itemGOData.go:SetActive(true)
            itemGOData.icon = self:GetComp(itemGOData.go,"icon","Image")
            itemGOData.numText = self:GetComp(itemGOData.go,"num","TMPLocalization")
        end
        haveItemGOCount = needShowCount
    end
    for i = 1, haveItemGOCount do
        local itemGOData = itemGOList[i]
        if i<=needShowCount then
            itemGOData.go:SetActive(true)
            local rewardID = needShowDatas[i].id
            local rewardCount = needShowDatas[i].count
            local shopConfig = ShopManager:GetCfg(rewardID)
            local showValue,typeName = ShopManager:GetValue(shopConfig)
            if tonumber(showValue) ~= nil then
                showValue = showValue * rewardCount
            else
                showValue = 1
            end
            self:SetSprite(itemGOData.icon,"UI_Shop",shopConfig.icon)
            itemGOData.numText.text = tostring(showValue)
        else
            itemGOData.go:SetActive(false)
        end
    end
end

---整合奖励，同类数量相加
function SeasonPassUIView:CombineRewardDatas(sourceDatas)
    local combinedDataList = {}
    local itemDataDic = {}
    local sourceDataCount = #sourceDatas
    for i = 1, sourceDataCount do
        local rewardData = sourceDatas[i]
        local itemID = rewardData.id
        local itemCount = rewardData.count
        local combinedItemData = itemDataDic[itemID]
        if not combinedItemData then
            combinedItemData = {id = itemID,count = 0}
            itemDataDic[itemID] = combinedItemData
            combinedDataList[#combinedDataList + 1] = combinedItemData
        end
        combinedItemData.count = combinedItemData.count + itemCount
    end
    return combinedDataList
end

function SeasonPassUIView:RefreshClaimAllRewardBtn()
    self:RefreshRewardRedPoint()
    self.m_claimAllBtnRootGO.gameObject:SetActive(SeasonPassManager:CanClaimAnyReward(false,3))
end

---刷新奖励页签的红点提示
function SeasonPassUIView:RefreshRewardRedPoint()
    local canClaimCount = SeasonPassManager:GetCanClaimRewardCount()
    if canClaimCount > 0 then
        self.m_rewardRedPointNormalGO:SetActive(true)
        self.m_rewardRedPointSelectGO:SetActive(true)
        local numStr = tostring(canClaimCount)
        self.m_rewardRedPointNormalNumText.text = numStr
        self.m_rewardRedPointSelectNumText.text = numStr
    else
        self.m_rewardRedPointNormalGO:SetActive(false)
        self.m_rewardRedPointSelectGO:SetActive(false)
    end
end

function SeasonPassUIView:ClaimAllReward()

    if SeasonPassManager:DistributeAllReward() then
        self:RefreshClaimAllRewardBtn()
        self.m_rewardList:UpdateData()
    end
end

--[[
    @desc:补单成功后的界面刷新回调 
    author:{author}
    time:2025-01-13 21:13:36
    --@shopid: 
    @return:
]]
function SeasonPassUIView:ResotreBuySccuess(shopId)
    if shopId == SeasonPassManager.PREMIUM_SHOP_ID or shopId == SeasonPassManager.LUXURY_SHOP_ID then
        local animator
        if shopId == SeasonPassManager.PREMIUM_SHOP_ID then
            animator = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listTitle/premium","Animator")
            self.m_needPlayUnlockPassType = PassType.Premium
        elseif shopId == SeasonPassManager.LUXURY_SHOP_ID then
            
            animator = self:GetComp(self.m_rewardRootGO,"bg2/rewardList/listTitle/luxury","Animator")
            self.m_needPlayUnlockPassType = PassType.Luxury
        end

        local cb = function()
            self.m_rewardList:UpdateData()
            self:RefreshClaimAllRewardBtn()
            self.m_needPlayUnlockPassType = nil
            GameTimer:CreateNewTimer(1,function()
                animator.enabled = false
                GameUIManager:SetEnableTouch(true,"通行证解锁动画")
            end)
        end
        GameUIManager:SetEnableTouch(false,"通行证解锁动画")
        AnimationUtil.AddKeyFrameEventOnObj(animator.gameObject, "ANIM_END", cb) -- 调用的Unity的方法, 一次穿越
        animator.enabled = true
        animator:Play("Unlock")

        if self.m_passPurchasePanelGO then
            self.m_passPurchasePanelGO:SetActive(false)
        end
        self:RefreshPassInfo()
    end
end