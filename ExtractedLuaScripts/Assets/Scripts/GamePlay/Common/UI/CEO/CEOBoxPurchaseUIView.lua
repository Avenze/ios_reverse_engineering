--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-02-12 15:46:33
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local ConfigMgr = GameTableDefine.ConfigMgr
local CEOBoxPurchaseUI = GameTableDefine.CEOBoxPurchaseUI
local CEODataManager = GameTableDefine.CEODataManager
local GameObject = CS.UnityEngine.GameObject
local GameUIManager = GameTableDefine.GameUIManager
local EventManager = require("Framework.Event.Manager")
local EventDispatcher = EventDispatcher
---@class CEOBoxPurchaseUIView
local CEOBoxPurchaseUIView = Class("CEOBoxPurchaseUIView", UIView)

local UnityHelper = CS.Common.Utils.UnityHelper
local CanUpgradeFillColor = UnityHelper.GetColor("#5DD43F")
local CanUpgradeBoxColor = UnityHelper.GetColor("#BEFA5B")
local CantUpgradeFillColor = UnityHelper.GetColor("#04b5e9")
local CantUpgradeBoxColor = UnityHelper.GetColor("#2be7fb")


function CEOBoxPurchaseUIView:ctor()
    self.allItemsGo = {}
end

function CEOBoxPurchaseUIView:OnEnter()
    if Tools:GetTableSize(self.allItemsGo) <= 0 then
        local firstItemGo = self:GetGo("background/MediumPanel/list/item")
        table.insert(self.allItemsGo, firstItemGo)
    end
    self:GetGo("background/BottomPanel/tipText"):SetActive(false)
    self:GetGo("background/BottomPanel/Btn_skip"):SetActive(false)
    EventDispatcher:RegEvent("CLICK_ENABLE", function(go)
        local tipTxtGo = self:GetGoOrNil("background/BottomPanel/tipText")
        if tipTxtGo then
            tipTxtGo:SetActive(true)
        end
        GameUIManager:SetEnableTouch(true)
    end)
end

function CEOBoxPurchaseUIView:OnExit()
    EventDispatcher:TriggerEvent(GameEventDefine.CEOBoxPurchaseUIViewClose, self.itemLastDisplayData)
    EventDispatcher:UnRegEvent("CLICK_ENABLE")
    EventDispatcher:UnRegEvent("REWARD_ENABLE")
    self.super:OnExit(self)
    self.curTurnsData = {}
    self.isRuning = false
    if self.closeCallback then
        for _, cb in pairs(self.closeCallback) do
            cb()
        end
        self.closeCallback = nil
    end
    self.itemLastDisplayData = nil
end

function CEOBoxPurchaseUIView:AddBoxDisplayInTurns(boxType, rewards, extendData, cb)
    if not self.curTurnsData then
        self.curTurnsData = {}
    end
    local item = {boxType, rewards, extendData, cb}
    table.insert(self.curTurnsData, item)
    if Tools:GetTableSize(self.curTurnsData) > 0 then
        if not self.isRuning then
            self:ProcessBoxOpenData()
        end
    end
end

function CEOBoxPurchaseUIView:ProcessBoxOpenData()
    if self.isRuning then
        return
    end
    if Tools:GetTableSize(self.curTurnsData) > 0 then
        self.isRuning = true
        local runData = table.remove(self.curTurnsData, 1)
        if not self.closeCallback then
            self.closeCallback = {}
        end
        if runData[4] then
            table.insert(self.closeCallback, runData[4])
        end
        self:SuceessOpenCEOBox(runData[1], runData[2], runData[3], runData[4])
    else
        self:DestroyModeUIObject()
    end
end

function CEOBoxPurchaseUIView:ProcessBoxOpenDataComplateOne()
    self.isRuning = false
    self:ProcessBoxOpenData()
end

function CEOBoxPurchaseUIView:SuceessOpenCEOBox(boxType, rewards, extendData, cb)
    GameUIManager:SetEnableTouch(false,"CEO宝箱开启初始化")
    self:GetGo("background/MediumPanel/chestPivot/chest"):SetActive(true)
    EventDispatcher:RegEvent("REWARD_ENABLE", function(go)
        --播放节点动画
        local animatorGo = self:GetGoOrNil("background/MediumPanel/reward")
        if animatorGo and self.rewardType then
            local canvasGroup = self:GetComp(animatorGo, "", "CanvasGroup")
            -- if canvasGroup and canvasGroup.alpha~= 1 then
            --     canvasGroup.alpha = 1
            -- end
            local animatorReward = self:GetComp(animatorGo, "", "Animator")
            -- animatorReward:SetTrigger(dispItem.type)
            animatorReward:SetTrigger(self.rewardType)
            
        end
        -- local rewardGo = self:GetGoOrNil()
        -- self:GetComp("background/MediumPanel/reward", "CanvasGroup").alpha = 1
    end)
    --首先需要整合当前的数据结构，相同的ceoid需要同步
    local itemsDisplay = {}
    local itemLastDisplay = {}
    for index, boxItem in pairs(rewards) do
        -- local shopCfg = ConfigMgr.config_shop[boxItem.shopId]
        for shopID, item in pairs(boxItem) do
            local shopCfg = ConfigMgr.config_shop[shopID]
            if shopCfg then
                if shopCfg.type == 44 and extendData[index] then
                    for _, ceoid in pairs(extendData[index][shopID] or {}) do
                        local dispItem = {}
                        local ceoCfg = ConfigMgr.config_ceo[ceoid]
                        if ceoCfg then
                            local curCeoData = GameTableDefine.CEODataManager:GetCEOCharData(ceoid)
                            local curCeoLvlCfg = ConfigMgr.config_ceo_level[ceoid][curCeoData.Level]
                            local isNewCEO = GameTableDefine.CEODataManager:GetCEOIsNewGet(ceoid)
                            local buffEffectValueStr = "x"..tostring(curCeoLvlCfg.ceo_effect * 100).."%"
                            local curCeoLvlCfg = GameTableDefine.CEODataManager:GetCEOCharCfgByCharID(ceoid, curCeoData.Level)
                            local curRoomInfo, curRoomCountryId = GameTableDefine.CEODataManager:GetCEOSpecificRoomIndexByCEOID(ceoid)
                            local isHire = (tostring(curRoomInfo) ~= "0" and tostring(curRoomInfo) ~= "")
                            local curExp = curCeoData.exp
                            local nextExp = GameTableDefine.CEODataManager:GetNextLevelExp(ceoid)
                            local curCardRes = GameTableDefine.CEODataManager:GetCurCEOCardsNum(ceoid)
                            local isMax = nextExp < 0
                            dispItem.shopID = shopID
                            dispItem.type = "OnRewardCEO"
                            dispItem.num = 1
                            dispItem.icon = ceoCfg.ceo_avatar
                            dispItem.ceoid = ceoid
                            dispItem.lastNum = 1
                            dispItem.needTransformDiamond = 0
                            dispItem.ceoQuality = ceoCfg.ceo_quality
                            dispItem.name = GameTextLoader:ReadText(ceoCfg.ceo_name)
                            dispItem.isNewCeo = isNewCEO
                            dispItem.canUpgrade = not isMax
                            if not isMax then
                                dispItem.canUpgrade = curCardRes >= nextExp
                            end
                            table.insert(itemsDisplay, dispItem)
                            local isInLast = false
                            for _, lastItem in pairs(itemLastDisplay) do
                                if lastItem.ceoid > 0 and lastItem.ceoid == ceoid then
                                    lastItem.lastNum  = lastItem.lastNum + 1
                                    isInLast = true
                                end
                            end
                            if not isInLast then
                                table.insert(itemLastDisplay, dispItem)
                            end
                        end
                    end
                else
                    local dispItem = {}
                    dispItem.shopID = shopID
                    dispItem.type = "OnRewardOthers"
                    dispItem.num = item.num
                    dispItem.icon = shopCfg.icon
                    dispItem.ceoid = 0
                    dispItem.lastNum = item.num
                    dispItem.needTransformDiamond = 0
                    dispItem.ceoQuality = "others"
                    dispItem.name = GameTextLoader:ReadText(shopCfg.name)
                    dispItem.isNewCeo = false
                    dispItem.canUpgrade = false
                    local isInLast = false
                    table.insert(itemsDisplay, dispItem)
                    for _, lastItem in pairs(itemLastDisplay) do
                        if lastItem.ceoid == 0 and lastItem.shopID == shopID then
                            lastItem.lastNum  = lastItem.lastNum + item.num
                            isInLast = true
                        end
                    end
                    if not isInLast then
                        table.insert(itemLastDisplay, dispItem)
                    end
                end
            end
        end
    end

    --检测是否需要转钻石
    for _, lastItem in pairs(itemLastDisplay) do
        if lastItem.ceoid > 0 then
            local eleTranDiamond = CEODataManager:NeedTransformCEOCardToDiamond(lastItem.ceoid)
            if eleTranDiamond > 0 then
                lastItem.needTransformDiamond = eleTranDiamond * lastItem.lastNum
            end
        end
    end
    self:GetGo("background/MediumPanel/chestPivot/chest/free"):SetActive(boxType == "free")
    self:GetGo("background/MediumPanel/chestPivot/chest/normal"):SetActive(boxType == "normal")
    self:GetGo("background/MediumPanel/chestPivot/chest/premium"):SetActive(boxType == "premium")
    local curChestNode = self:GetGo("background/MediumPanel/chestPivot/chest/"..boxType)
    local rewardNode = self:GetGo("background/MediumPanel/reward")
    local lastDispNode = self:GetGo("background/MediumPanel/list")
    self:SetText(curChestNode, "num", tostring(Tools:GetTableSize(itemsDisplay)))
    rewardNode:SetActive(true)
    lastDispNode:SetActive(false)
    local bgBtn = self:GetComp("BgCover", "Button")
    local curRewardIndex = 1
    local isLastDisplay = false
    local needAnimaGos = {}
    local DispLastFunc = function() 
        for _, itemGo in pairs(self.allItemsGo) do
            itemGo:SetActive(false)
        end
        if not self.itemLastDisplayData then
            self.itemLastDisplayData = {}
        end
        for i = 1, Tools:GetTableSize(itemLastDisplay) do
            if i > Tools:GetTableSize(self.allItemsGo) then
                local addItemGo = GameObject.Instantiate(self.allItemsGo[1], self.allItemsGo[1].transform.parent)
                table.insert(self.allItemsGo, addItemGo)
            end
            local dispItemGo = self.allItemsGo[i]
            local itemData = itemLastDisplay[i]
            table.insert(self.itemLastDisplayData, itemData)
            self:SetCardNodeInfo(dispItemGo, itemData, needAnimaGos)
        end
        rewardNode:SetActive(false)
        lastDispNode:SetActive(true)
        for _, itemGo in pairs(needAnimaGos) do
            local animator = self:GetComp(itemGo, "", "Animator")
            animator:SetTrigger("OnCeoTransform")
        end
        local btnSkipGo = self:GetGoOrNil("background/BottomPanel/Btn_skip")
        if btnSkipGo then
            btnSkipGo:SetActive(false)
        end
        local tipTxtGo = self:GetGoOrNil("background/BottomPanel/tipText")
        if tipTxtGo then
            tipTxtGo:SetActive(true)
        end
        isLastDisplay = true
    end
    if bgBtn then
        self:SetButtonClickHandler(bgBtn, function()
            if isLastDisplay then
                needAnimaGos = {}
                self:ProcessBoxOpenDataComplateOne()
                return
            end
            
            if curRewardIndex <= Tools:GetTableSize(itemsDisplay) then
                -- if curRewardIndex > 1 then
                --     self:GetComp("background/MediumPanel/reward", "CanvasGroup").alpha = 0
                -- end
                --设置icon和数量
                local dispItem = itemsDisplay[curRewardIndex]
                -- self:SetSprite(self:GetComp("background/MediumPanel/reward/card/bg/mask/icon", "Image"), "UI_Shop", dispItem.icon)
                -- self:SetText("background/MediumPanel/reward/card/bg/mask/num", "x"..tostring(dispItem.num))
                -- self:GetGo("background/MediumPanel/reward/title/banner/normal"):SetActive(dispItem.ceoQuality == "normal")
                -- self:GetGo("background/MediumPanel/reward/title/banner/premium"):SetActive(dispItem.ceoQuality == "premium")
                -- self:SetText("background/MediumPanel/reward/title/name/txt", dispItem.name)
                -- self:GetGo("background/MediumPanel/reward/card/bg/mask/bg/normal"):SetActive(dispItem.ceoQuality == "normal")
                -- self:GetGo("background/MediumPanel/reward/card/bg/mask/bg/premium"):SetActive(dispItem.ceoQuality == "premium")
                -- self:GetGo("background/MediumPanel/reward/card/bg/mask/bg/others"):SetActive(dispItem.ceoQuality == "others")
                -- self:GetGo("background/MediumPanel/reward/card/vfx1/normal"):SetActive(dispItem.ceoQuality == "normal")
                -- self:GetGo("background/MediumPanel/reward/card/vfx1/premium"):SetActive(dispItem.ceoQuality == "premium")
                -- self:GetGo("background/MediumPanel/reward/card/bg/mask/tips/new"):SetActive(dispItem.isNewCeo)
                -- self:GetGo("background/MediumPanel/reward/card/bg/mask/tips/icon"):SetActive(not dispItem.isNewCeo and dispItem.canUpgrade)
                -- self:GetGo("background/MediumPanel/reward/title/banner/premium"):SetActive(dispItem.ceoQuality == "premium")
                self.rewardAnimator = self:GetComp(rewardNode, "", "Animator")
                self.rewardType = dispItem.type
                -- local animatorChest = self:GetComp(curChestNode, "", "Animator")
                local animatorChest = self:GetComp("background/MediumPanel/chestPivot/chest/"..boxType, "Animator")
                if curRewardIndex == 1 and boxType == "premium" then
                    animatorChest:SetTrigger("OnPremiumFirstOpen")
                else
                    animatorChest:SetTrigger("OnChestOpen")
                end
                self:SetSprite(self:GetComp("background/MediumPanel/reward/card/bg/mask/icon", "Image"), "UI_Shop", dispItem.icon)
                self:SetText("background/MediumPanel/reward/card/bg/mask/num", "x"..tostring(dispItem.num))
                self:GetGo("background/MediumPanel/reward/title/banner/normal"):SetActive(dispItem.ceoQuality == "normal")
                self:GetGo("background/MediumPanel/reward/title/banner/premium"):SetActive(dispItem.ceoQuality == "premium")
                self:SetText("background/MediumPanel/reward/title/name/txt", dispItem.name)
                self:GetGo("background/MediumPanel/reward/card/bg/mask/bg/normal"):SetActive(dispItem.ceoQuality == "normal")
                self:GetGo("background/MediumPanel/reward/card/bg/mask/bg/premium"):SetActive(dispItem.ceoQuality == "premium")
                self:GetGo("background/MediumPanel/reward/card/bg/mask/bg/others"):SetActive(dispItem.ceoQuality == "others")
                self:GetGo("background/MediumPanel/reward/card/vfx1/normal"):SetActive(dispItem.ceoQuality == "normal")
                self:GetGo("background/MediumPanel/reward/card/vfx1/premium"):SetActive(dispItem.ceoQuality == "premium")
                self:GetGo("background/MediumPanel/reward/card/bg/mask/tips/new"):SetActive(dispItem.isNewCeo)
                self:GetGo("background/MediumPanel/reward/card/bg/mask/tips/icon"):SetActive(not dispItem.isNewCeo and dispItem.canUpgrade)
                self:GetGo("background/MediumPanel/reward/title/banner/premium"):SetActive(dispItem.ceoQuality == "premium")
                -- local animatorReward = self:GetComp(rewardNode, "", "Animator")
                -- animatorReward:SetTrigger(dispItem.type)
                if curRewardIndex == 1 then
                    local btnSkipGo = self:GetGoOrNil("background/BottomPanel/Btn_skip")
                    if btnSkipGo then
                        btnSkipGo:SetActive(true)
                    end
                    local tipTxtGo = self:GetGoOrNil("background/BottomPanel/tipText")
                    if tipTxtGo then
                        tipTxtGo:SetActive(false)
                    end
                end
                self:SetText(curChestNode, "num", tostring(Tools:GetTableSize(itemsDisplay) - curRewardIndex))
                curRewardIndex  = curRewardIndex + 1
            else
                DispLastFunc()
            end
        end)
    end
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/Btn_skip", "Button"), function()
        curRewardIndex = Tools:GetTableSize(itemsDisplay) + 1
        DispLastFunc()
        local btnSkipGo = self:GetGoOrNil("background/BottomPanel/Btn_skip")
        if btnSkipGo then
            btnSkipGo:SetActive(false)
        end
        local tipTxtGo = self:GetGoOrNil("background/BottomPanel/tipText")
        if tipTxtGo then
            tipTxtGo:SetActive(true)
        end
    end)
end

function CEOBoxPurchaseUIView:SetCardNodeInfo(dispItemGo, itemData, needAnimaGos)
    local ceoNode = self:GetGo(dispItemGo,"ceo")
    local otherNode = self:GetGo(dispItemGo,"others")
    ceoNode:SetActive(true)
    if itemData.ceoid > 0 then
        local ceoCfg = ConfigMgr.config_ceo[itemData.ceoid]
        local curCeoData = GameTableDefine.CEODataManager:GetCEOCharData(itemData.ceoid)
        if not curCeoData then
            return
        end
        local curCeoLvlCfg = ConfigMgr.config_ceo_level[itemData.ceoid][curCeoData.Level]
        local isNewCEO = GameTableDefine.CEODataManager:GetCEOIsNewGet(itemData.ceoid)
        local buffEffectValueStr = "x"..tostring(curCeoLvlCfg.ceo_effect * 100).."%"
        local curCeoLvlCfg = GameTableDefine.CEODataManager:GetCEOCharCfgByCharID(itemData.ceoid, curCeoData.Level)
        local curRoomInfo, curCountryId = GameTableDefine.CEODataManager:GetCEOSpecificRoomIndexByCEOID(itemData.ceoid)
        local isHire = (tostring(curRoomInfo) ~= "0" and tostring(curRoomInfo) ~= "")
        local curExp = curCeoData.exp
        local nextExp = GameTableDefine.CEODataManager:GetNextLevelExp(itemData.ceoid)
        local curCardRes = GameTableDefine.CEODataManager:GetCurCEOCardsNum(itemData.ceoid)
        local isMax = nextExp < 0
        
        self:GetGo(dispItemGo, "ceo/quality/normal"):SetActive(ceoCfg.ceo_quality == "normal")
        self:GetGo(dispItemGo, "ceo/quality/premium"):SetActive(ceoCfg.ceo_quality == "premium")
        self:SetText(dispItemGo, "ceo/levelPanel/num", tostring(curCeoData.Level))
        local resIcon = "icon_enhanceMoney"
        if ceoCfg.ceo_effect_type == "exp" then
            resIcon = "icon_enhanceExp"
        end
        self:SetSprite(self:GetComp(dispItemGo, "ceo/buffPanel/resIcon", "Image"), "UI_Common", resIcon)
        self:SetText(dispItemGo, "ceo/buffPanel/text", buffEffectValueStr)
        self:GetGo(dispItemGo, "HIRED"):SetActive(isHire)
        self:SetSprite(self:GetComp(dispItemGo, "ceo/icon", "Image"), "UI_Shop", itemData.icon)
        self:SetText(dispItemGo, "ceo/upgradeSlider/have/name", GameTextLoader:ReadText(ceoCfg.ceo_name))
        self:GetGo(dispItemGo, "ceo/upgradeSlider/have/number"):SetActive(not isMax)
        self:GetGo(dispItemGo, "ceo/upgradeSlider/have/max"):SetActive(isMax)
        local silder = self:GetComp(dispItemGo, "ceo/upgradeSlider/have/Slider", "Slider")
        local fillImage = self:GetComp(silder.gameObject,"Fill Area/Fill","Image")
        local fillBoxImage = self:GetComp(silder.gameObject,"Fill Area/Fill/fillBox","Image")
        if not isMax then
            silder.value = curCardRes / nextExp
            if silder.value > 1 then
                silder.value = 1
            end
            self:SetText(dispItemGo, "ceo/upgradeSlider/have/number/have", curCardRes)
            self:SetText(dispItemGo, "ceo/upgradeSlider/have/number/need", nextExp)

            --Slider颜色
            fillImage.color = CantUpgradeFillColor
            fillBoxImage.color = CantUpgradeBoxColor
        else
            silder.value = 1

            --Slider颜色
            fillImage.color = CanUpgradeFillColor
            fillBoxImage.color = CanUpgradeBoxColor
        end
        self:GetGo(dispItemGo, "ceo/upgradeSlider/have/icons/arr"):SetActive(curCardRes >= nextExp)
        local cardIconGO = self:GetGo(dispItemGo,"ceo/upgradeSlider/have/icons/card")
        cardIconGO:SetActive(curCardRes < nextExp)
        if curCardRes < nextExp then
            local cardImage = self:GetComp(cardIconGO,"","Image")
            self:SetSprite(cardImage,"UI_Common",ceoCfg.ceo_card,nil,false,true)
        end

        self:GetGo(dispItemGo, "ceo/tips/new"):SetActive(isNewCEO)
        self:GetGo(dispItemGo, "ceo/tips/icon"):SetActive(not isNewCEO and curCardRes >= nextExp)
        self:SetText(dispItemGo, "ceo/bg/num", "x"..tostring(itemData.lastNum))
        if itemData.needTransformDiamond > 0 then
            self:SetSprite(self:GetComp(dispItemGo, "others/icon", "Image"), "UI_Shop", "icon_cy2_diamond")
            self:SetText(dispItemGo, "others/bg/num", "x"..tostring(itemData.needTransformDiamond))
            self:SetText(dispItemGo, "others/name/txt", GameTextLoader:ReadText("TXT_SHOP_DIAMOND"))
            table.insert(needAnimaGos, dispItemGo)
        else
            otherNode:SetActive(false)
        end
    else
        ceoNode:SetActive(false)
        otherNode:SetActive(true)
        self:SetSprite(self:GetComp(dispItemGo, "others/icon", "Image"), "UI_Shop", itemData.icon)
        self:SetText(dispItemGo, "others/bg/num", "x"..tostring(itemData.lastNum))
        self:SetText(dispItemGo, "others/name/txt", itemData.name)
    end
    
    dispItemGo:SetActive(true)
end

return CEOBoxPurchaseUIView