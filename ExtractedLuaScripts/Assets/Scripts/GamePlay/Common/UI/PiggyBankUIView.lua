local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local Shop = GameTableDefine.Shop
local ResMgr = GameTableDefine.ResourceManger
local ShopManager = GameTableDefine.ShopManager
local PiggyBankUI = GameTableDefine.PiggyBankUI
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local ResourceManger = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI
local CfgMgr = GameTableDefine.ConfigMgr
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
local PigIconPathDefault = "background/list/mainPanel/Pig/icon_1"
local NextPigIconPathDefault = "background/list/foretellPanel/Pig/icon_1"

---@class PiggyBankUIView:UIBaseView
local PiggyBankUIView = Class("PiggyBankUIView", UIView)

function PiggyBankUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function PiggyBankUIView:OnEnter()
    --printf(debug.getinfo(1).source)
    --数据初始化
    self:Init()
    --购买成功
    ShopManager:refreshBuySuccess(function(shopId)
        GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 4, order_state_desc = "进入小猪购买成功回调"})

        local Earnings = PiggyBankUI:CalculateEarnings()
        self:playSuccessfulPurchase(Earnings,function()
            GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 5, order_state_desc = "播放小猪购买成功的动画"})
            ShopManager:Buy(shopId, false, function()
                GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 10, order_state_desc = "发放小猪奖励成功 afterBuy => callBack"})
            end,function()
                GameSDKs:TrackForeign("money_box", {id = tostring(shopId or ""), order_state = 9, order_state_desc = "发放小猪奖励成功 afterBuy => beforCallBack, times次数增加"})
                if self:refresh(true, true) then
                    --AnimationUtil.Play(self.m_piggyAnimation,"piggybank_init",function()
                    --    AnimationUtil.Play(self.m_piggyAnimation,"piggybank_idle")
                    --end)
                else
                    --self:DestroyModeUIObject()
                end
            end)
        end)
    end)
    --失败
    ShopManager:refreshBuyFail(function(shopId)

    end)

    self:SetButtonClickHandler(self:GetComp("background/HeadPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    --刷新界面
    if not self:refresh(false, true) then
        self:DestroyModeUIObject()
        return
    end

    AnimationUtil.Play(self.m_piggyAnimation,"piggybank_idle")
    --self:SetText(self:GetGo(""), "text", "")
    --埋点
    local num
    local shopId = self.cfgPiggyBank[math.min(self.PiggyBankData.level, Tools:GetTableSize(CfgMgr.config_piggybank)) + 1000].shopId
    if self.buyBtn.interactable then
        num = 2
    else
        num = 1
    end
    GameSDKs:TrackForeign("money_box", {id = tostring(shopId), state = num})
end

--初始化需要的数据
function PiggyBankUIView:Init()
    self.PiggyBankData = PiggyBankUI:GetPiggyBankData()
    if  not self.PiggyBankData.value then
        self.PiggyBankData.value = 0
    end
    if  not self.PiggyBankData.level then
        self.PiggyBankData.level = 1
    end
    self.buyBtn = self:GetComp("background/list/mainPanel/BtnPanel/mBtn","Button")
    self.slider = self:GetComp("background/list/mainPanel/MediumPanel/Frame/prog", "Slider")
    self.m_titleShadowText = self:GetComp("background/HeadPanel/bg/titleShadow","TMPLocalization")
    self.m_titleText = self:GetComp("background/HeadPanel/bg/title","TMPLocalization")
    self.m_shopIconImage = self:GetComp("background/list/mainPanel/Pig/icon_1","Image")
    self.m_ShopIconParent = self:GetTrans("background/list/mainPanel/Pig")
    self.m_piggyAnimation = self:GetComp("background","Animation")
    self.m_piggyMileGo = self:GetGo("DiamondFly")
    self.m_piggyMileAnimation = self:GetComp("DiamondFly","Animation")
    self.m_starLockGO = self:GetGo("background/list/mainPanel/BtnPanel/mBtn/lock")
    self.m_starLockText = self:GetComp("background/list/mainPanel/BtnPanel/mBtn/lock/star/num","TMPLocalization")
    self.m_levelText = self:GetComp("background/list/mainPanel/MediumPanel/level/num","TMPLocalization")
    self.m_offValueText = self:GetComp("background/list/mainPanel/BtnPanel/offvalue/offvalue1/layout/num","TMPLocalization")
    self.cfgPiggyBank = CfgMgr.config_piggybank

    self:SetButtonClickHandler(self:GetComp("reward", "Button"),function()
        self:GetGo("reward"):SetActive(false)
    end)

    self:RefreshMileList() -- 里程碑奖励
    LocalDataManager:WriteToFile()

    self.Initial = true
end

---里程碑奖励列表
function PiggyBankUIView:RefreshMileList()
    self.m_mile_list = self:GetComp("background/list/miliPanel/list", "ScrollRectEx")
    --设置List的数量
    local mileRewardConf = PiggyBankUI:GetMileRewardConf()
    self:SetListItemCountFunc(self.m_mile_list, function()
        return #mileRewardConf
    end)

    self:SetListItemNameFunc(self.m_mile_list,function(index)
        return "item"
    end)

    --设置List中的Item的具体内容
    self:SetListUpdateFunc(self.m_mile_list, handler(self, self.UpdateUIElement))
end

function PiggyBankUIView:UpdateUIElement(index, tran)
    index = index + 1
    local go = tran.gameObject

    local mileRewardConf = PiggyBankUI:GetMileRewardConf()
    local mileReward = mileRewardConf[index]
    self:SetText(go, "text", mileReward.id - 1000)
    
    local mileShopConf = CfgMgr.config_shop[mileReward.mile_reward]
    self:SetText(go, "num", mileShopConf and mileShopConf.amount or 0)

    local icon = self:GetComp(go, "icon","Image")
    self:SetSprite(icon, "UI_Shop", mileShopConf and mileShopConf.icon or "")

    -- claim下的节点再填充一遍
    --self:SetText(go, "claimed/text", mileReward.id - 1000)
    --local claimIcon = self:GetComp(go, "claimed/icon","Image")
    --self:SetSprite(claimIcon, "UI_Shop", mileShopConf and mileShopConf.icon or "")
    -- claim下的节点再填充一遍

    local claimBtn = self:GetComp(go, "btn", "Button")

    --local showEnable = self.PiggyBankData.level + 1000 + 2 >= mileReward.id
    --self:GetGo(go, "btn"):SetActive(showEnable)

    local hadClaim = Tools:CheckContain(mileReward.id, self.PiggyBankData.draw_history or {})
    self:GetGo(go, "claimed"):SetActive(hadClaim)
    
    local hadBuy = self.PiggyBankData.level + 1000 >= mileReward.id
    local drawEnable = hadBuy and not hadClaim
    claimBtn.interactable = drawEnable
    self:GetGo(go, "btn/redPoint"):SetActive(drawEnable)
    
    self:SetButtonClickHandler(claimBtn, function()
        claimBtn.interactable = false
        self:GetGo(go, "btn/redPoint"):SetActive(false)
        PiggyBankUI:GetMileReward(mileReward.id)
    end)

    self:SetButtonClickHandler(self:GetComp(go, "icon", "Button"), function()
        self:OpenRewardInfo(go, mileShopConf.name, mileShopConf.desc)
    end)

    local tipsBtn = self:GetComp(go, "bg2/tipsBtn", "Button")
    if tipsBtn then
        self:SetButtonClickHandler(tipsBtn, function()
            self:OpenRewardInfo(go, mileShopConf.name, mileShopConf.desc)
        end)
    end
    
    self:GetGo(go, "bg1"):SetActive(mileReward.import ~= 1)
    self:GetGo(go, "bg2"):SetActive(mileReward.import == 1)
end

function PiggyBankUIView:OpenRewardInfo(curGo, name, desc)
    local infoGo = self:GetGoOrNil("reward")
    if infoGo.isActive then
        return
    end

    if infoGo then
        self:SetText("reward/rewardInfo/title/txt", GameTextLoader:ReadText(name))
        self:SetText("reward/rewardInfo/fix/txt", GameTextLoader:ReadText(desc))
        local rewardInfoGo = self:GetGoOrNil("reward/rewardInfo")

        local locationPos = self:GetGoOrNil(curGo, "icon/pivot")
        local clampRectTransform = self:GetTrans("reward")
        local arrowTrans = self:GetTrans(rewardInfoGo, "arrow")
        UnityHelper.ClampInfoUIPosition(rewardInfoGo.transform, arrowTrans, locationPos.transform.position, clampRectTransform)
        --rewardInfoGo.transform.position = locationPos.transform.position

        infoGo:SetActive(true)
    end
end

---刷新里程碑奖励列表
function PiggyBankUIView:RefreshMilePart()
    self.m_mile_list:UpdateData()
    
    local mileRewardConf = PiggyBankUI:GetMileRewardConf()
    local maxIndex = 0
    for index, mileReward in pairs(mileRewardConf) do
        maxIndex = index
        local hadClaim = Tools:CheckContain(mileReward.id, self.PiggyBankData.draw_history or {})
        if self.PiggyBankData.level + 1000 < mileReward.id or not hadClaim then
            break
        end
    end

    --local contentPos = self.m_mile_list.content.anchoredPosition
    --local itemSize = UnityHelper.GetItemSizeByContent(self.m_mile_list.content.transform)
    --contentPos.x = -(maxIndex - 1) * itemSize.x

    self.m_mile_list:ScrollTo(maxIndex, 3)
end

-- 刷新预告栏位
function PiggyBankUIView:RefreshPrevPart()
    -- 在玩家达到满级（即便玩家最后一级还未付费），直接删除预告栏位
    if self.PiggyBankData.level >= Tools:GetTableSize(CfgMgr.config_piggybank) then
        self:GetGo("background/list/foretellPanel"):SetActive(false)
        return
    end

    -- 显示当前等级钻石最大额度
    local cfgCur = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    self:SetText("background/list/foretellPanel/textShow/now", cfgCur.reward[1].num)

    -- 显示下一等级数
    self:SetText("background/list/foretellPanel/bubble/level/num", self.PiggyBankData.level + 1)

    -- 显示下一等级钻石最大额度
    local cfgNext = self.cfgPiggyBank[self.PiggyBankData.level + 1000 + 1]
    self:SetText("background/list/foretellPanel/textShow/next", cfgNext.reward[1].num)

    -- 显示下一等级icon
    local nextIcon = self:GetGoOrNil(string.gsub(cfgNext.icon, "mainPanel", "foretellPanel"))
    if not nextIcon then
        nextIcon = self:GetGoOrNil(NextPigIconPathDefault)
    end

    --self:GetComp(nextIcon, "","Animator").enabled = false
    for k, v in pairs(self:GetTrans("background/list/foretellPanel/Pig")) do
        v.gameObject:SetActive(false)
    end

    nextIcon:SetActive(true)
end

function PiggyBankUIView:RefreshTitle()
    local cfg = self.cfgPiggyBank[math.min(self.PiggyBankData.level, Tools:GetTableSize(CfgMgr.config_piggybank)) + 1000]
    if cfg then
        local shopConfig = CfgMgr.config_shop[cfg.shopId]
        if shopConfig then
            self.m_titleText.text = GameTextLoader:ReadText(shopConfig.name)
            self.m_titleShadowText.text = GameTextLoader:ReadText(shopConfig.name)

            --self:SetSprite(self.m_shopIconImage,"UI_Shop",shopConfig.icon)
            local shopIcon = self:GetGoOrNil(cfg.icon or PigIconPathDefault)
            if not shopIcon then
                shopIcon = self:GetGoOrNil(PigIconPathDefault)
            end

            if not self.pigIconFirstSprite then
                self.pigIconFirstSprite = self:GetComp(shopIcon, "", "Image").sprite
            end

            if PiggyBankUI:CheckIsLvFull() then -- 新增个功能需求，小猪全解锁后，小猪动画暂停，界面特效隐藏。
                --shopIcon = self:GetGoOrNil(PigIconPathDefault)
                -- 满级后，复位为第一帧sprite
                self:GetComp(shopIcon, "","Image").sprite = self.pigIconFirstSprite
                self:GetComp(shopIcon, "","Animator").enabled = false
                self:GetGo("background/list/mainPanel/bg/vfx_bglight"):SetActive(false)
                self:GetGo("background/list/mainPanel/bg/vfx_lizi"):SetActive(false)
            end

            if shopIcon then
                for k, v in pairs(self.m_ShopIconParent) do
                    v.gameObject:SetActive(false)
                end

                shopIcon:SetActive(true)
            end
            self.m_levelText.text = tostring(cfg.level)
        end
        --折扣
        if self.m_offValueText then
            self.m_offValueText.text = string.format("%d%%", cfg.offvalue or 33)
        end
    end
end

--刷新
function PiggyBankUIView:refresh(refreshContent, showInitAnim)
    if not PiggyBankUI:CheckUsefor() then
        self.buyBtn.interactable = false
        if not refreshContent then
            return false
        end
    end
    
    self:RefreshTitle()
    self:RefreshDiamondText()
    self:CalculationValue()
    self:SetBlookGo()
    self:SetButton()

    self:RefreshMilePart() -- 刷新里程碑奖励
    self:RefreshPrevPart() -- 预览奖励
    if showInitAnim then
        AnimationUtil.Play(self.m_piggyAnimation, "piggybank_init", function()
            if not PiggyBankUI:CheckIsLvFull() then
                AnimationUtil.Play(self.m_piggyAnimation, "piggybank_idle")
            end
        end)
    else
        if not PiggyBankUI:CheckIsLvFull() then
            AnimationUtil.Play(self.m_piggyAnimation, "piggybank_idle")
        end
    end
    
    return true
end

--刷新钻石数量
function PiggyBankUIView:RefreshDiamondText()
    self:SetText("diamonds/num", Tools:SeparateNumberWithComma(ResMgr:GetDiamond()))
end

function PiggyBankUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
    --printf(debug.getinfo(1).source)
    self.super:OnExit(self)
    self.PiggyBankData = nil
    self.buyBtn = nil
    self.slider = nil
    self.cfgPiggyBank = nil
end

---播放钻石领取后动画
function PiggyBankUIView:PlayDiamondFly(cb)
    self.m_piggyMileGo:SetActive(true)
    AnimationUtil.Play(self.m_piggyMileAnimation, "DiamondFly_Anim_PiggyBank", function()
        self.m_piggyMileGo:SetActive(false)
        
        if cb then
            cb()
        end
    end)
end

--播放购买的动画
function PiggyBankUIView:playSuccessfulPurchase(Earnings,callback)
    local config = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    local openAnim = config and config.anim or "piggybank_open"
    AnimationUtil.Play(self.m_piggyAnimation,openAnim,function()
        GameTimer:CreateNewTimer(0.1,function()
            if callback then
                callback()
            end
        end,false)
    end)
    --self:GetGo("reward"):SetActive(true)
    --local bgBtn = self:GetComp("reward/bg", "Button")
    --self:SetButtonClickHandler(bgBtn, function()
    --    self:GetGo("reward"):SetActive(false)
    --end)
    --self:SetText(self:GetGo("reward/reward/content"), "num", Earnings.num)
    --local image = self:GetComp("reward/reward/content/icon","Image")
    --if Earnings.type ==2 then
    --    self:SetSprite(image, "UI_Common", "icon_cash_001")
    --elseif Earnings.type == 3 then
    --    self:SetSprite(image, "UI_Common", "icon_diamond_001")
    --end
    --local feel = self:GetComp("reward/PurchaseFeedback", "MMFeedbacks")
    --if feel then
    --    feel:PlayFeedbacks()
    --end
end

--计算Slider的百分值,和进度数值显示
function PiggyBankUIView:CalculationValue()
    local cfg = self.cfgPiggyBank[math.min(self.PiggyBankData.level, Tools:GetTableSize(CfgMgr.config_piggybank)) + 1000]
    local threhold = cfg.threhold[#cfg.threhold]
    local piggyValue = self.PiggyBankData.value
    local isLvFull = PiggyBankUI:CheckIsLvFull()
    if isLvFull then
        piggyValue = threhold
    end

    self.slider.value = piggyValue / threhold
    self:SetText(self:GetGo("background/list/mainPanel/MediumPanel/Frame/prog/rewardHolder"), "progress/num", math.min(threhold, piggyValue) .. "/" .. threhold)

    local showNum = PiggyBankUI:CalculateEarnings().num
    self:SetText("background/vfx/num", "+" .. Tools:SeparateNumberWithComma(showNum))
    self:SetText("background/list/mainPanel/MediumPanel/money/money/num", Tools:SeparateNumberWithComma(showNum))
    self:GetGo("background/list/mainPanel/MediumPanel/money/money"):SetActive(not isLvFull)

    local tips = piggyValue >= threhold and "TXT_SHOP_PIGGYBANK_DESC_2" or "TXT_SHOP_PIGGYBANK_DESC_1"
    tips = GameTextLoader:ReadText(tips)
    self:SetText("background/list/mainPanel/MediumPanel/tip", tips)

    local halfReward = cfg.reward[1].num * 0.25
    local halfTips = GameTextLoader:ReadText("TXT_SHOP_PIGGYBANK_DESC_3")
    halfTips = string.format(halfTips, Tools:SeparateNumberWithComma(halfReward))
    self:SetText("background/list/mainPanel/MediumPanel/Frame/prog/rewardHolder/tip", halfTips)

    self:GetGo("background/list/mainPanel/MediumPanel/money/full"):SetActive(isLvFull)
    self:GetGo("background/list/mainPanel/MediumPanel/money/fullShadow"):SetActive(isLvFull)
    --return math.min(1,piggyValue / threhold)
end

--获得节点组件并生成
function PiggyBankUIView:SetBlookGo()
    local block = self:GetGo("background/list/mainPanel/MediumPanel/Frame/prog/rewardHolder/block")
    local block2 = self:GetGo("background/list/mainPanel/MediumPanel/Frame/prog/rewardHolder/block_2")
    local cfg = self.cfgPiggyBank[math.min(self.PiggyBankData.level, Tools:GetTableSize(self.cfgPiggyBank)) + 1000]
    local rewardConfig = cfg.reward[1]
    local rewardMax = rewardConfig.num
    --设置数量
    self:SetText(block, "num", Tools:SeparateNumberWithComma(rewardMax))
    self:SetText(block2, "num", Tools:SeparateNumberWithComma(rewardMax * 0.25) )
    --设置类型
    local isDiamond = rewardConfig.type == 3
    local isCash = rewardConfig.type == 2
    self:GetGo(block, "icon"):SetActive(isDiamond)
    self:GetGo(block, "C"):SetActive(isCash)
    self:GetGo(block2, "icon"):SetActive(isDiamond)
    self:GetGo(block2, "C"):SetActive(isCash)


    --local blook = self:GetGo("background/list/mainPanel/MediumPanel/Frame/prog/rewardHolder/block")
    --local parent = blook.transform.parent.gameObject
    --local num = #self.cfgPiggyBank[self.PiggyBankData.level + 1000].threhold
    --local cfg = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    --local rect = self:GetComp("background/list/mainPanel/MediumPanel/Frame/prog", "RectTransform")
    --for i = 1, num do
    --    local Go
    --    if self:GetGoOrNil(parent, "blook" .. i ) then
    --        Go = self:GetGo(parent, "blook" .. i )
    --    else
    --        Go = GameObject.Instantiate(blook, parent.transform)
    --    end
    --
    --    Go:SetActive(true)
    --    Go.name = "blook" .. i
    --    --设置数量
    --    self:SetText(Go, "num", cfg.reward[i].num)
    --    --设置类型
    --    local isDiamond = cfg.reward[i].type == 3
    --    local isCash = cfg.reward[i].type == 2
    --    self:GetGo(Go, "icon"):SetActive(isDiamond)
    --    self:GetGo(Go, "C"):SetActive(isCash)
    --    --设置位置
    --    local x = rect.rect.width * (cfg.threhold[i] / cfg.threhold[num]) - rect.rect.width / 2
    --    self:GetComp(Go,"", "RectTransform").anchoredPosition3D = Vector3(x,0,0)
    --    self:GetGo(Go, "unlock"):SetActive(cfg.threhold[i] <= self.PiggyBankData.value)
    --end
    --blook:SetActive(false)
end

--对按钮的设置
function PiggyBankUIView:SetButton()
    local cfg = self.cfgPiggyBank[math.min(self.PiggyBankData.level, Tools:GetTableSize(self.cfgPiggyBank)) + 1000]
    --self.buyBtn.interactable = cfg.threhold[1] <= self.PiggyBankData.value
    local canBuy,state,condition = false,0,0
    canBuy,state,condition = PiggyBankUI:CheckCanBuy()

    self.buyBtn.interactable = canBuy
    self:GetGo("background/list/mainPanel/BtnPanel/offvalue"):SetActive(self.PiggyBankData.value >= cfg.threhold[1])

    if PiggyBankUI:CheckIsLvFull() then -- 满级
        self:GetGo("background/list/mainPanel/BtnPanel/mBtn"):SetActive(false)
        self:GetGo("background/list/mainPanel/BtnPanel/maxBtn"):SetActive(true)
    else
        self:GetGo("background/list/mainPanel/BtnPanel/mBtn"):SetActive(true)
        self:GetGo("background/list/mainPanel/BtnPanel/maxBtn"):SetActive(false)

        local price = Shop:GetShopItemPrice(cfg.shopId)
        self:SetText("background/list/mainPanel/BtnPanel/mBtn/text", price)
    end

    self:SetButtonClickHandler(self.buyBtn, function()
        -- 创建小猪订单
        GameSDKs:TrackForeign("money_box", {id = tostring(cfg.shopId), order_state = -1, order_state_desc = "创建小猪订单"})
        Shop:CreateShopItemOrder(cfg.shopId, self.buyBtn)
    end)
    if state == 2 and condition then
        self.m_starLockGO:SetActive(true)
        self.m_starLockText.text = tostring(condition)
    else
        self.m_starLockGO:SetActive(false)
    end
end

return PiggyBankUIView