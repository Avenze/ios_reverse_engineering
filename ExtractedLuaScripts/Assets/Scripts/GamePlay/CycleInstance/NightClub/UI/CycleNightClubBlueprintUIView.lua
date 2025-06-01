
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3
local UILayer = CS.UnityEngine.LayerMask.NameToLayer("UI")
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local UnityTime = CS.UnityEngine.Time

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local GameUIManager = GameTableDefine.GameUIManager
local BluePrintManager = GameTableDefine.CycleNightClubBluePrintManager
local GameTimer = GameTimer
local AnimationUtil = CS.Common.Utils.AnimationUtil
local BlueprintUI = GameTableDefine.CycleNightClubBlueprintUI

local ResTypeCount = 4

-- 定义常量部分
local BPIconHeadStr = "banner_NtClub_card_"
local BPBannerHeadStr = "ui_NtClub_blueprint_banner_"

local GroupIndex = {
    [1] = 210,
    [2] = 211,
    [3] = 212
}

local FrameBgPaths = {
    [0] = "ui_NtClub_blueprint_frame_1",
    [1] = "ui_NtClub_blueprint_frame_2",
    [2] = "ui_NtClub_blueprint_frame_3",
    [3] = "ui_NtClub_blueprint_frame_4",
    [4] = "ui_NtClub_blueprint_frame_5",
    [5] = "ui_NtClub_blueprint_frame_6",
}

---产品升级界面最大预生成产品数量
local UpgradeItemMaxCount = 5
local CenterUpgradeItemIndex = math.floor(UpgradeItemMaxCount/2)

---@class CycleNightClubBlueprintUIView:UIBaseView
local CycleNightClubBlueprintUIView = Class("CycleNightClubBlueprintUIView", UIView)

function CycleNightClubBlueprintUIView:ctor()
    self.super:ctor()

    --资源栏
    self.m_resTitleImageList = {} ---@type UnityEngine.UI.Image[]
    self.m_resNumTextList = {} ---@type UnityEngine.UI.Text[]
    self.m_incomeText = nil ---@type UnityEngine.UI.Text

    self.m_productionScrollRectEX = nil ---@type UnityEngine.UI.ScrollRectEx

    --升级界面
    self.m_upgradePanel = nil ---@type UnityEngine.GameObject
    self.m_upgradePanelExitBtn = nil ---@type UnityEngine.UI.Button
    self.m_upgradePanelScrollRectEX = nil ---@type UnityEngine.UI.ScrollRectEx

    self.m_productionCount = 0
    self.m_selectedProductionIndex = -1---正在显示的玩具index

    --碎片合成
    self.m_resCombineGroupList = nil ---@type ResCombineGroup[]

    ---已解锁的最高的index
    self.m_unlockedIndex = 1
end

function CycleNightClubBlueprintUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("background/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.m_resConfigs = BluePrintManager:GetResConfigs()
    self.m_bpConfigList = self.m_currentModel.config_cy_instance_blueprint
    self.m_productionConfigs = BluePrintManager:GetProductionConfigs()
    self.m_productionCount = #self.m_productionConfigs

    --资源栏
    local resParentGO = self:GetGo("background/Title")
    for i = 1, ResTypeCount do
        self.m_resTitleImageList[i] = self:GetComp(resParentGO,"res_"..i.."/icon","Image")
        self.m_resNumTextList[i] = self:GetComp(resParentGO,"res_"..i.."/num","TMPLocalization")
    end
    self.m_incomeText = self:GetComp(resParentGO,"res_5/num","TMPLocalization")

    --产品列表
    self.m_productionScrollRectEX = self:GetComp("background/List","ScrollRectEx")
    self:SetListItemNameFunc(self.m_productionScrollRectEX,function(index)
        return "temp"
    end)
    self:SetListItemCountFunc(self.m_productionScrollRectEX,function()
        return self.m_productionCount
    end)
    self:SetListUpdateFunc(self.m_productionScrollRectEX,handler(self,self.UpdateProductList))

    --产品升级界面
    self.m_upgradePanel = self:GetGo("background/upgradePanel")
    self.m_upgradePanelAnimation = self:GetComp(self.m_upgradePanel,"","Animation")
    self.m_upgradePanelExitBtn = self:GetComp(self.m_upgradePanel,"BgCover","Button")
    self:SetButtonClickHandler(self.m_upgradePanelExitBtn,handler( self,self.HideUpgradePanel))
    self.m_upgradePanelScrollRectEX = self:GetComp("background/upgradePanel/ScrollRect","ScrollRectEx")
    self.m_upgradePanelScrollContentPos = self:GetTrans("background/upgradePanel/ScrollRect/Viewport/Content")
    self:SetListItemNameFunc(self.m_upgradePanelScrollRectEX,function(index)
        return "item"
    end)

    self:SetListScrollFunc(self.m_upgradePanelScrollRectEX,handler( self,self.UpgradePanelPageOnScroll))
    self:SetListItemCountFunc(self.m_upgradePanelScrollRectEX,function()
        return UpgradeItemMaxCount
    end)
    self:SetListUpdateFunc(self.m_upgradePanelScrollRectEX,handler(self,self.UpdateUpgradeList))
    self:SetSnapMoveDoneFunc(self.m_upgradePanelScrollRectEX,handler(self,self.OnUpgradeListSnap))
    self.m_upgradePanelPageUpBtn = self:GetComp(self.m_upgradePanel,"previous_page","Button")
    self.m_upgradePanelPageUpDown = self:GetComp(self.m_upgradePanel,"next_page","Button")
    self:SetButtonClickHandler(self.m_upgradePanelPageUpBtn,handler( self,self.UpgradePanelPageUp))
    self:SetButtonClickHandler(self.m_upgradePanelPageUpDown,handler( self,self.UpgradePanelPageDown))

    --升级材料合成界面
    self.m_resCombineGroupList = {}
    local resCombinePanelGO = self:GetGo("background/exchangePanel")
    for i = 1, ResTypeCount-1 do
        local group = {} ---@type ResCombineGroup
        self.m_resCombineGroupList[i] = group
        local groupParentGO = self:GetGo(resCombinePanelGO,"ex_"..i)
        group.curIconImage = self:GetComp(groupParentGO,"Icons/res_1","Image")
        group.curCountText = self:GetComp(group.curIconImage.gameObject,"num","TMPLocalization")
        group.nextIconImage = self:GetComp(groupParentGO,"Icons/res_2","Image")
        group.nextCountText = self:GetComp(group.nextIconImage.gameObject,"num","TMPLocalization")
        group.upgradeBtn = self:GetComp(groupParentGO,"btn","Button")
        --group.vfxAnimation = self:GetComp(groupParentGO,"vfx_fly_icon","Animation")
        local groupIndex = i
        self:SetButtonClickHandler(group.upgradeBtn,function()
            self:OnCombineBtnDown(groupIndex)
        end)
    end

    --已解锁的最高的index
    self.m_unlockedIndex = 1
    for i = 1, self.m_productionCount do
        local productionCfg = self.m_productionConfigs[i]
        local productID = productionCfg.id
        local isUnlocked = self:IsProductUnlock(productID)
        if isUnlocked then
            self.m_unlockedIndex = i
        end
    end
end

function CycleNightClubBlueprintUIView:OnExit()
    self.super:OnExit(self)

    if self.upgradeBP then
        GameTableDefine.CycleNightClubPopUI:PackTrigger(6)
    end
end

function CycleNightClubBlueprintUIView:HideUpgradePanel()

    GameUIManager:SetEnableTouch(false)
    AnimationUtil.Play(self.m_upgradePanelAnimation, "UI_cy4_NtClubBlueprintUI_close", function()
        self.m_upgradePanel:SetActive(false)
        GameUIManager:SetEnableTouch(true)
    end)
end

function CycleNightClubBlueprintUIView:UpgradePanelPageUp()
    self.m_upgradePanelScrollRectEX:SetSnapIndex(CenterUpgradeItemIndex-1)
end

function CycleNightClubBlueprintUIView:UpgradePanelPageDown()
    self.m_upgradePanelScrollRectEX:SetSnapIndex(CenterUpgradeItemIndex+1)
end

function CycleNightClubBlueprintUIView:UpgradePanelPageOnScroll()
    local anchoredPositionX = self.m_upgradePanelScrollContentPos.anchoredPosition.x
    if anchoredPositionX <= self.scroll_dis_min then
        UnityHelper.SetAnchoredPositonX(self.m_upgradePanelScrollContentPos, self.scroll_dis_min)
    end

    if anchoredPositionX >= self.scroll_dis_max then
        UnityHelper.SetAnchoredPositonX(self.m_upgradePanelScrollContentPos, self.scroll_dis_max)
    end

    -- 设置左右滑动箭头显示与隐藏
    self.m_upgradePanelPageUpBtn.gameObject:SetActive(self.m_selectedProductionIndex ~= 1)
    self.m_upgradePanelPageUpDown.gameObject:SetActive(self.m_selectedProductionIndex ~= self.m_unlockedIndex)
end

function CycleNightClubBlueprintUIView:Init(productID)
    self:FindUnlockProduction()
    self.m_productionScrollRectEX:UpdateData(true)
    local targetIndex = 1
    if productID then
        local findIndex = self:GetProductIndex(productID)
        if findIndex ~= -1 then
            targetIndex = findIndex
        end
    end
    --self:SetShowProductionIndex(targetIndex)
    self:InitTitlePanel()
    self:InitResCombiningPanel()
    self:PlayUnlockProductAnim()
end

---找到刚解锁的ProductionIndex
function CycleNightClubBlueprintUIView:FindUnlockProduction()

    local lastUnlockProductID = BluePrintManager:GetLastUnlockProductID() or 0
    local needUnlockProductIndex = nil
    for index = 1, self.m_productionCount do
        local productionCfg = self.m_productionConfigs[index]
        local productID = productionCfg.id
        if productID>lastUnlockProductID then
            local isUnlocked = self:IsProductUnlock(productID)
            if isUnlocked then
                needUnlockProductIndex = index
            else
                break
            end
        end
    end
    if needUnlockProductIndex then
        self.m_needUnlockIndex = needUnlockProductIndex
    end
end

---解锁流程
function CycleNightClubBlueprintUIView:PlayUnlockProductAnim()

    local needUnlockProductIndex = self.m_needUnlockIndex
    if needUnlockProductIndex then
        local productionCfg = self.m_productionConfigs[needUnlockProductIndex]
        local productID = productionCfg.id
        GameUIManager:SetEnableTouch(false)
        --1.滑动到解锁的位置
        self.m_productionScrollRectEX:SetSnapIndex(needUnlockProductIndex-1)
        --2.等待1s , scrollRect滑动结束
        GameTimer:CreateNewTimer(1,function()
            --3.播放解锁动画
            local trans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(needUnlockProductIndex-1)
            if not trans or trans:IsNull() then
                trans = self.m_productionScrollRectEX:GetScrollItem(needUnlockProductIndex-1)
            end
            local animator = self:GetComp(trans.gameObject,"bg/locked","Animator")
            animator:Play("UI_cy4_NtClubBlueprintUI_locktounlock")

            local animLength = UnityHelper.GetAnimatorClipDuration(animator,"UI_cy4_NtClubBlueprintUI_locktounlock")
            GameTimer:CreateNewTimer(animLength,function()
                BluePrintManager:SetLastUnlockProductID(productID)
                animator.gameObject:SetActive(false)
                self.m_needUnlockIndex = nil
                self:UpdateProductList(needUnlockProductIndex-1,trans)
                GameUIManager:SetEnableTouch(true)
            end)

            --local lockAnimation = self:GetComp(trans.gameObject,"bg/locked","Animation")
            --local find, name = AnimationUtil.GetFirstClipName(lockAnimation)
            --if find then
            --    AnimationUtil.Play(lockAnimation, name, function()
            --        --4.记录需要还原的动画
            --        --AnimationUtil.Play(lockAnimation,name,nil,0)
            --        self.m_lastUnlockAnimation = lockAnimation
            --        self.m_lastUnlockAnimName = name
            --        self.m_lastUnlockTrans = trans
            --
            --        BluePrintManager:SetLastUnlockProductID(productID)
            --        lockAnimation.gameObject:SetActive(false)
            --        self.m_needUnlockIndex = nil
            --        self:UpdateProductList(needUnlockProductIndex-1,trans)
            --        GameUIManager:SetEnableTouch(true)
            --    end)
            --else
            --    lockAnimation.gameObject:SetActive(false)
            --    GameUIManager:SetEnableTouch(true)
            --end
        end)
    end
end

---产品是否解锁
function CycleNightClubBlueprintUIView:IsProductUnlock(productID)
    local bluePrintConfigs = self.m_bpConfigList[productID] ---@type ConfigBluePrint[]
    local baseBpConfig = bluePrintConfigs[1]
    local roomID = baseBpConfig.room_id

    local isUnlocked = self.m_currentModel:RoomIsUnlock(roomID)
    return isUnlocked
end

---单纯刷新产品可升级标志 和 材料需求
function CycleNightClubBlueprintUIView:RefreshAllProductItemUpgradeableMark()
    for index = 1, self.m_unlockedIndex do
        local productionCfg = self.m_productionConfigs[index]
        local productID = productionCfg.id

        local trans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(index-1)
        if trans and not trans:IsNull() then
            local go = trans.gameObject
            --self:GetGo(go,"bg/res/Slider/upgradeIcon"):SetActive(BluePrintManager:CanUpgradeProduction(productID))

            --升级所需材料
            self:UpdateUpgradeResInfo(go,productID)
        end
    end
end

--刷新升级所需材料
function CycleNightClubBlueprintUIView:UpdateUpgradeResInfo(go,productID)
    local resGO = self:GetGo(go,"bg/res")
    local notMaxGO = self:GetGo(resGO,"Slider")
    local maxGO = self:GetGo(resGO,"max")
    local needResID,needResCount = BluePrintManager:GetProductionUpgradeResCount(productID)
    if needResID and needResCount then
        local resConfig = BluePrintManager:GetResConfigsByID(needResID)
        local haveResCount = BluePrintManager:GetUpgradeResCount(needResID)
        local resSlider = self:GetComp(resGO,"Slider","Slider")
        local canUpgradeNode = self:GetGo(resGO,"Slider/upgradeIcon")
        local cannotUpgradeNode = self:GetGo(resGO,"Slider/icon")
        if needResCount > haveResCount then
            if resConfig.icon then
                local resIcon = self:GetComp(resGO,"Slider/icon","Image")
                self:SetSprite(resIcon,"UI_Common",resConfig.icon)
            end
            canUpgradeNode:SetActive(false)
            cannotUpgradeNode:SetActive(true)
        else
            canUpgradeNode:SetActive(true)
            cannotUpgradeNode:SetActive(false)
        end
        self:SetText(resGO,"Slider/txt/num",tostring(haveResCount))
        self:SetText(resGO,"Slider/txt/max",tostring(needResCount))
        resSlider.value = 1.0 * haveResCount / needResCount
        notMaxGO:SetActive(true)
        maxGO:SetActive(false)
    else
        --已经满级
        notMaxGO:SetActive(false)
        maxGO:SetActive(true)
    end
end

function CycleNightClubBlueprintUIView:UpdateProductList(index, trans)
    index = index + 1
    local go = trans.gameObject

    --基础信息
    local productionCfg = self.m_productionConfigs[index]
    local productID = productionCfg.id
    local productIconImage = self:GetComp(go,"bg/icon","Image")
    local bluePrintConfigs = self.m_bpConfigList[productID] ---@type ConfigBluePrint[]
    local productionData = BluePrintManager:GetProductionDataByProductID(productID)
    local level = productionData.starLevel or 1
    local bpConfigNow = bluePrintConfigs[level]

    self:SetSprite(productIconImage,"UI_Common",bpConfigNow.icon,nil,false,true)

    self:SetText(go,"bg/level/num",tostring(level))
    self:SetText(go,"bg/level/num_2",tostring(level))
    self:SetText(go,"bg/name",GameTextLoader:ReadText(bluePrintConfigs[1].name))

    --是否解锁,正在解锁中的也有锁
    local resGO = self:GetGo(go,"bg/res")
    local levelGO = self:GetGo(go,"bg/level")
    local nameGO = self:GetGo(go,"bg/name")
    local isUnlocked = self:IsProductUnlock(productID) and index ~= self.m_needUnlockIndex
    resGO:SetActive(isUnlocked)
    levelGO:SetActive(isUnlocked)
    nameGO:SetActive(isUnlocked)
    self:GetGo(go,"bg/locked"):SetActive(not isUnlocked)
    local greyUI = self:GetComp(go,"bg","GreyUI")
    if isUnlocked then
        greyUI.GrayBlend = 0
        --productIconImage.material:SetFloat("_GreyBlend",0)
    else
        greyUI.GrayBlend = 1
        --productIconImage.material:SetFloat("_GreyBlend",1)
    end

    --边框
    local bgImage = self:GetComp(go,"bg","Image")
    self:SetSprite(bgImage,"UI_Common",FrameBgPaths[level])

    --是否可升级
    --local canUpgrade = BluePrintManager:CanUpgradeProduction(productID)
    --self:GetGo(go,"bg/upgradeIcon"):SetActive(isUnlocked and canUpgrade)
    --是否选中
    --local selectedMarkGO = self:GetGo(go,"bg/select")
    --selectedMarkGO:SetActive(self.m_selectedProductionIndex == index)

    --升级所需材料
    self:UpdateUpgradeResInfo(go,productID)

    --是否需要还原动画
    --if not isUnlocked and trans == self.m_lastUnlockTrans then
    --    AnimationUtil.Play(self.m_lastUnlockAnimation,self.m_lastUnlockAnimName,nil,0)
    --    self.m_lastUnlockTrans = nil
    --    self.m_lastUnlockAnimation = nil
    --    self.m_lastUnlockAnimName = nil
    --end

    --点击
    local clickBtn = self:GetComp(go,"","Button")
    clickBtn.interactable = isUnlocked
    self:SetButtonClickHandler(clickBtn,function()
        if isUnlocked then
            self:SetShowProductionIndex(index)
        end
    end)
end

function CycleNightClubBlueprintUIView:GetProductIndex(productID)
    for i = 1, self.m_productionCount do
        local productionCfg = self.m_productionConfigs[i]
        local id = productionCfg.id
        if id == productID then
            return i
        end
    end
    return -1
end

---选中对应产品
function CycleNightClubBlueprintUIView:SetShowProductionIndex(index)

    self.m_upgradePanel:SetActive(true)

    self.m_selectedProductionIndex = index

    --self:RefreshProductionView()
    self.m_upgradePanelScrollRectEX:UpdateData()
    local rect = self.m_upgradePanelScrollRectEX:GetItemRect(CenterUpgradeItemIndex)
    local targetPos = rect.position
    targetPos.x = - targetPos.x
    self.m_upgradePanelScrollRectEX:ScrollToPos(targetPos)
    self.m_upgradePanelScrollRectEX:SetSnapIndex(CenterUpgradeItemIndex)

    -- 设置左右滑动箭头显示与隐藏
    self.m_upgradePanelPageUpBtn.gameObject:SetActive(self.m_selectedProductionIndex ~= 1)
    self.m_upgradePanelPageUpDown.gameObject:SetActive(self.m_selectedProductionIndex ~= self.m_unlockedIndex)

    -- 设置左右滑动最大距离
    self.scroll_dis_min = self.m_upgradePanelScrollContentPos.anchoredPosition.x - (self.m_unlockedIndex - self.m_selectedProductionIndex) * CS.UnityEngine.Screen.width
    self.scroll_dis_max = self.m_upgradePanelScrollContentPos.anchoredPosition.x + (self.m_selectedProductionIndex - 1) * CS.UnityEngine.Screen.width
end

function CycleNightClubBlueprintUIView:RefreshTitle()
    for i = 1, ResTypeCount do
        self.m_resNumTextList[i].text = tostring(BluePrintManager:GetUpgradeResCount(self.m_resConfigs[i].id))
    end
    --收入
    local income = self.m_currentModel:GetRewardInComePerMinute() * 0.5
    self.m_incomeText.text = BigNumber:FormatBigNumber(income).."/30S"
end

---替换iconName 到 bannerName
--function CycleNightClubBlueprintUIView:ReplaceIconNameToBannerName(inputString)
--    -- 检查输入字符串是否以 BPIconHeadStr 开头
--    if string.sub(inputString, 1, string.len(BPIconHeadStr)) == BPIconHeadStr then
--        -- 提取变量部分，即去掉 BPIconHeadStr 后的部分
--        local variablePart = string.sub(inputString, string.len(BPIconHeadStr) + 1)
--        -- 拼接新的字符串
--        local resultString = BPBannerHeadStr .. variablePart
--        return resultString
--    else
--        -- 如果输入字符串不符合预期格式，返回原字符串
--        printError("蓝图 iconName格式不是banner_NtClub_card_XXXX,无法判断该用什么bannerName")
--        return inputString
--    end
--end

---产品升级界面中,获取当前滑动列表index的产品在产品Config中对应的index
function CycleNightClubBlueprintUIView:GetUpgradeProductionIndex(index)
    local curIndex = self.m_selectedProductionIndex - CenterUpgradeItemIndex + index

    if curIndex > 0 then
        curIndex = curIndex % self.m_unlockedIndex
        if curIndex == 0 then
            curIndex = self.m_unlockedIndex
        end
    else
        --从index=1,向左几位
        curIndex = - curIndex
        curIndex = curIndex % self.m_unlockedIndex
        curIndex = self.m_unlockedIndex - curIndex
    end

    return curIndex
end

function CycleNightClubBlueprintUIView:UpdateUpgradeList(index, trans)

    local productIndex = self:GetUpgradeProductionIndex(index)
    local go = trans.gameObject

    local productionUpgradeBtn = self:GetComp(go,"btn","Button")
    self:SetButtonClickHandler( productionUpgradeBtn,handler( self,self.OnProductionUpgradeBtnDown))
    local productionUpgradeBtnMaxMark = self:GetGo( productionUpgradeBtn.gameObject,"max")
    local productionNameText = self:GetComp(go,"name/txt","TMPLocalization")
    local productionNameLevelText = self:GetComp(go,"name/level/num","TMPLocalization")
    local productionNameLevel2Text = self:GetComp(go,"name/level/num_2","TMPLocalization")
    local productionNowLevelText = self:GetComp(go,"level/now/num","TMPLocalization")
    local productionNextLevelText = self:GetComp(go,"level/next/num","TMPLocalization")
    local productionNextLevelGO = self:GetGo(go,"level/next")
    local productionNextLevelArrowGO = self:GetGo(go,"level/arr")
    local productionUpgradeResTypeIcon =
    self:GetComp(go,"btn/blueprint/cost/icon","Image")
    local productionUpgradeResCountText =
    self:GetComp(go,"btn/blueprint/cost/num","TMPLocalization")
    local buffMile1Text =
    self:GetComp(go,"buffShow/milepoint/num1","TMPLocalization")
    local buffMile2Text =
    self:GetComp(go,"buffShow/milepoint/num2","TMPLocalization")
    local buffMoney1Text =
    self:GetComp(go,"buffShow/money/num1","TMPLocalization")
    local buffMoney2Text =
    self:GetComp(go,"buffShow/money/num2","TMPLocalization")
    local roomNameText =
    self:GetComp(go,"tip","TMPLocalization")
    if not self.tipOriginText then
        self.tipOriginText = roomNameText.text
    end
    
    local buffMile2ArrowGO = self:GetGo(go,"buffShow/milepoint/arr")
    local buffMoney2ArrowGO = self:GetGo(go,"buffShow/money/arr")
    local productionIcon = self:GetComp(go,"bg/icon","Image")
    
    --拉霸机3级后隐藏
    self:GetGo(go, "bg2/txt"):SetActive(self.m_currentModel:GetSlotMachineLevel() < 3)

    local productionCfg = self.m_productionConfigs[productIndex]
    local productID = productionCfg.id
    local bluePrintConfigs = self.m_bpConfigList[productID] ---@type ConfigBluePrint[]
    local baseBpConfig = bluePrintConfigs[1]
    --产品的名称在产品表中没有配置，是配在蓝图表中的
    productionNameText.text = GameTextLoader:ReadText(baseBpConfig.name)
    local bannerName = baseBpConfig.banner

    local productionData = BluePrintManager:GetProductionDataByProductID(productID)
    local level = productionData.starLevel or 0
    local levelStr = tostring(level)
    productionNowLevelText.text = levelStr
    productionNameLevelText.text = levelStr
    productionNameLevel2Text.text = levelStr
    --升级所需材料
    local needResID,needResCount = BluePrintManager:GetProductionUpgradeResCount(productID)
    if needResID and needResCount then
        local resConfig = BluePrintManager:GetResConfigsByID(needResID)
        local haveResCount = BluePrintManager:GetUpgradeResCount(needResID)
        productionUpgradeBtn.interactable = haveResCount >= needResCount
        productionUpgradeBtnMaxMark:SetActive(false)
        if resConfig.icon then
            self:SetSprite(productionUpgradeResTypeIcon,"UI_Common",resConfig.icon,nil,false,true)
        end
        productionUpgradeResCountText.text = tostring(needResCount)
        productionNextLevelText.text = tostring(level+1)
        productionNextLevelGO:SetActive(true)
        productionNextLevelArrowGO.gameObject:SetActive(true)
    else
        --已经满级
        productionUpgradeBtn.interactable = false
        productionUpgradeBtnMaxMark:SetActive(true)
        productionNextLevelGO.gameObject:SetActive(false)
        productionNextLevelArrowGO.gameObject:SetActive(false)
    end
    --Buff
    local bpConfigNow = bluePrintConfigs[level]
    local bpConfigNext = bluePrintConfigs[level+1]
    if bpConfigNext then
        buffMile1Text.text = "x"..tostring(bpConfigNow.mile_buff)
        buffMile2Text.text = "x"..tostring(bpConfigNext.mile_buff)
        buffMoney1Text.text = "x"..tostring(bpConfigNow.money_buff)
        buffMoney2Text.text = "x"..tostring(bpConfigNext.money_buff)

        buffMile2Text.gameObject:SetActive(true)
        buffMile2ArrowGO.gameObject:SetActive(true)
        buffMoney2Text.gameObject:SetActive(true)
        buffMoney2ArrowGO.gameObject:SetActive(true)
    else
        buffMile1Text.text = "x"..tostring(bpConfigNow.mile_buff)
        buffMoney1Text.text = "x"..tostring(bpConfigNow.money_buff)
        buffMile2Text.gameObject:SetActive(false)
        buffMile2ArrowGO.gameObject:SetActive(false)
        buffMoney2Text.gameObject:SetActive(false)
        buffMoney2ArrowGO.gameObject:SetActive(false)
    end
    --RoomName TODO 房间收益提示改为替换字符
    --local productionNum, _, _ = self.m_currentModel:GetRoomProduction(baseBpConfig.room_id)
    --local productPrice = self.m_currentModel.resourceConfig[productID].price
    --local bluePrintMoneyBuff,_ = BluePrintManager:GetProductBuffValue(productID, level)
    --local income = BigNumber:Multiply(bluePrintMoneyBuff * productPrice,productionNum)

    --local diffValue = 0
    --local bluePrintMoneyBuffNextLv,_ = BluePrintManager:GetProductBuffValue(productID, level + 1)
    --if bluePrintMoneyBuffNextLv then
    --    local incomeNextLv = BigNumber:Multiply((bluePrintMoneyBuffNextLv and bluePrintMoneyBuffNextLv or 0) * productPrice,productionNum)
    --    diffValue = BigNumber:FormatBigNumberSmall(BigNumber:Subtract(incomeNextLv, income))
    --end

    local roomCfg = self.m_currentModel:GetRoomConfigByID(baseBpConfig.room_id)
    roomNameText.text = string.format(self.tipOriginText, GameTextLoader:ReadText(roomCfg.name))
    self:SetSprite(productionIcon,"UI_Common",bannerName,nil,false,true)
end

function CycleNightClubBlueprintUIView:OnUpgradeListSnap(index)
    local curIndex = self:GetUpgradeProductionIndex(index)
    if index == CenterUpgradeItemIndex then
        return
    end

    self.m_selectedProductionIndex = curIndex
    local rect = self.m_upgradePanelScrollRectEX:GetItemRect(CenterUpgradeItemIndex)
    local targetPos = rect.position
    targetPos.x = - targetPos.x
    self.m_upgradePanelScrollRectEX:ScrollToPos(targetPos)
    self.m_upgradePanelScrollRectEX:SetSnapIndex(CenterUpgradeItemIndex)
    self.m_upgradePanelScrollRectEX:UpdateData()
    --再次调用 刷新界面 回收UI元素
    self.m_upgradePanelScrollRectEX:ScrollToPos(targetPos)

    -- 设置左右滑动箭头显示与隐藏
    self.m_upgradePanelPageUpBtn.gameObject:SetActive(self.m_selectedProductionIndex ~= 1)
    self.m_upgradePanelPageUpDown.gameObject:SetActive(self.m_selectedProductionIndex ~= self.m_unlockedIndex)

    -- 设置左右滑动最大距离
    self.scroll_dis_min = self.m_upgradePanelScrollContentPos.anchoredPosition.x - (self.m_unlockedIndex - self.m_selectedProductionIndex) * CS.UnityEngine.Screen.width
    self.scroll_dis_max = self.m_upgradePanelScrollContentPos.anchoredPosition.x + (self.m_selectedProductionIndex - 1) * CS.UnityEngine.Screen.width
end

function CycleNightClubBlueprintUIView:InitTitlePanel()
    for i = 1, ResTypeCount do
        local resConfig = self.m_resConfigs[i]
        self:SetSprite(self.m_resTitleImageList[i],"UI_Common",resConfig.icon,nil,false,true)
    end
    self:RefreshTitle()
end

function CycleNightClubBlueprintUIView:InitResCombiningPanel()
    for i = 1, ResTypeCount-1 do
        local group = self.m_resCombineGroupList[i]

        local curResConfig = self.m_resConfigs[i]
        local nextResConfig = self.m_resConfigs[i+1]

        self:SetSprite(group.curIconImage,"UI_Common",curResConfig.icon,nil,false,true)
        self:SetSprite(group.nextIconImage,"UI_Common",nextResConfig.icon,nil,false,true)

        group.curCountText.text = tostring(nextResConfig.cost_num)
        group.nextCountText.text = "1"
    end

    self:RefreshResCombiningPanel()
end

function CycleNightClubBlueprintUIView:OnProductionUpgradeBtnDown()
    local productID = self.m_productionConfigs[self.m_selectedProductionIndex].id
    local result = BluePrintManager:TryUpgradeProduction(productID)
    if result == BluePrintManager.BluePrintUpgradeResult.Success then
        self.upgradeBP = true
        
        local selectedTrans = self.m_productionScrollRectEX:GetScrollItemTranByIndex(self.m_selectedProductionIndex-1)
        if selectedTrans and not selectedTrans:IsNull() then
            --local level = BluePrintManager:GetProductionDataByProductID(productID).starLevel
            --local bpConfigNow = BluePrintManager:GetBPConfigByProductionLevel(productID,level)
            --local go = selectedTrans.gameObject
            --local productIconImage = self:GetComp(go,"bg/icon","Image")
            --self:SetSprite(productIconImage,"UI_Common",bpConfigNow.icon,nil,false,true)
            --self:SetText(go,"bg/level/num",tostring(level))
            self:UpdateProductList(self.m_selectedProductionIndex-1,selectedTrans)
        end
        self:RefreshTitle()
        self:RefreshResCombiningPanel()
        self:RefreshAllProductItemUpgradeableMark()
        self.m_upgradePanelScrollRectEX:UpdateData()
        local upgradeItemTrans = self.m_upgradePanelScrollRectEX:GetScrollItemTranByIndex(CenterUpgradeItemIndex)
        if upgradeItemTrans and not selectedTrans:IsNull() then
            --播放升级动画
            local animator = self:GetComp(upgradeItemTrans.gameObject,"","Animator")
            animator:Play("UI_cy4_NtClubBlueprintUI_levelup")
        end
    elseif result == BluePrintManager.BluePrintUpgradeResult.ResNotEnough then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("升级材料不足"))
    elseif result == BluePrintManager.BluePrintUpgradeResult.ResNotEnough then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("已经升到满级"))
    end
end

---刷新升级产品按钮的状态
--function CycleNightClubBlueprintUIView:RefreshProductUpgradePanelState()
--    if self.m_selectedProductionIndex > 0 then
--        local productionCfg = self.m_productionConfigs[self.m_selectedProductionIndex]
--        local productID = productionCfg.id
--        --升级所需材料
--        local needResID,needResCount = BluePrintManager:GetProductionUpgradeResCount(productID)
--        if needResID and needResCount then
--            local haveResCount = BluePrintManager:GetUpgradeResCount(needResID)
--            self.m_productionUpgradeBtn.interactable = haveResCount >= needResCount
--        end
--    end
--end

---第groupIndex个合成按钮按下
function CycleNightClubBlueprintUIView:OnCombineBtnDown(groupIndex)
    local nextResID = self.m_resConfigs[groupIndex+1].id
    if BluePrintManager:TryCombineUpgradeRes(nextResID) then
        self:RefreshResCombiningPanel()
        self:RefreshAllProductItemUpgradeableMark()
        --self:RefreshProductUpgradePanelState()
        local flyIcon = GroupIndex[groupIndex]
        EventManager:DispatchEvent("FLY_ICON", nil, flyIcon,nil, function()
            self:RefreshTitle()
        end)
    else
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("合成材料不足"))
    end
end

---刷新资源置换界面
function CycleNightClubBlueprintUIView:RefreshResCombiningPanel()
    for i = 1, ResTypeCount-1 do
        local groupIndex = i
        local nextResID = self.m_resConfigs[groupIndex+1].id

        local canCombine = BluePrintManager:CanCombineUpgradeRes(nextResID)
        local group = self.m_resCombineGroupList[i]
        group.upgradeBtn.interactable = canCombine
    end
end

--region 引导专用接口

function CycleNightClubBlueprintUIView:GetGo(obj, child)
    if obj == "GetMaxLvProduction" then
        return self:GetMaxLvProduction()
    else
        return self:getSuper(CycleNightClubBlueprintUIView).GetGo(self,obj, child)
    end
end

---用来给引导返回最有价值房间
function CycleNightClubBlueprintUIView:GetMaxLvProduction(needBtn)
    local room_datas = self.m_currentModel.roomsData
    local maxLv = 0
    local maxLvProductionIndex = 1
    for index = 1, self.m_productionCount do
        local productionCfg = self.m_productionConfigs[index]
        local blueprint_conf = self.m_currentModel.config_cy_instance_blueprint[productionCfg.id]
        local room_id = blueprint_conf[1].room_id
        local room_data = room_datas[room_id]
        if room_data.state == 2 then
            local curFurLevelID = room_data.furList["1"].id --当前选中的家具levelID
            local currentFurLevelCfg = self.m_currentModel.furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
            local furLevel = currentFurLevelCfg.level
            local room_lv_confs = self.m_currentModel.config_cy_instance_roomsLevel[room_id]
            for _, room_lv_conf in ipairs(room_lv_confs) do
                if room_lv_conf.fur_levelRange[1] <= furLevel and room_lv_conf.fur_levelRange[2] >= furLevel then
                    if room_lv_conf.id > maxLv then
                        maxLv = room_lv_conf.id
                        maxLvProductionIndex = index
                        break
                    end
                end
            end
        end
    end

    local uiItemGO = self.m_productionScrollRectEX:GetScrollItem(maxLvProductionIndex-1).gameObject
    if not needBtn then
        return self:GetGo(uiItemGO,"bg")
    end

    return self:GetComp(uiItemGO, "", "Button")
end

function CycleNightClubBlueprintUIView:GetHighestBtn()
    local highestIndex = 1
    for i = self.m_productionCount, 1,-1 do
        --基础信息
        local productionCfg = self.m_productionConfigs[i]
        local productID = productionCfg.id

        local isUnlocked = BluePrintManager:IsProductUnlock(productID)
        if isUnlocked then
            highestIndex = i
            break
        end
    end

    local highestTrans = self.m_productionScrollRectEX:GetScrollItem(highestIndex-1)
    if highestTrans then
        local btn = self:GetComp(highestTrans.gameObject,"","Button")
        return btn
    end
    return nil
end

function CycleNightClubBlueprintUIView:GetGuideUpgradeBtn()
    local curItem = self.m_upgradePanelScrollRectEX:GetScrollItem(CenterUpgradeItemIndex)
    return self:GetComp(curItem.gameObject,"btn","Button")
end

function CycleNightClubBlueprintUIView:GetComp(obj, child, uiType)
    if obj == "GetHighestBtn" then
        return self:GetHighestBtn()
    elseif obj == "GetMaxLvProduction" then
        return self:GetMaxLvProduction(true)
    elseif obj == "GetGuideUpgradeBtn" then
        return self:GetGuideUpgradeBtn()
    else
        return self:getSuper(CycleNightClubBlueprintUIView).GetComp(self,obj, child,uiType)
    end
end
--endregion

return CycleNightClubBlueprintUIView