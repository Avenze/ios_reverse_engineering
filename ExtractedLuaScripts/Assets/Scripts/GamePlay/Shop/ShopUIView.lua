local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local FeelUtil = CS.Common.Utils.FeelUtil
local CompanyMode = GameTableDefine.CompanyMode
local DeviceUtil = CS.Game.Plat.DeviceUtil

local IAP = GameTableDefine.IAP
local GameUIManager = GameTableDefine.GameUIManager
local ShopUI = GameTableDefine.ShopUI
local ResourceManger = GameTableDefine.ResourceManger
local Shop = GameTableDefine.Shop
local ResMgr = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local FloorMode = GameTableDefine.FloorMode
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local FlyIconsUI = GameTableDefine.FlyIconsUI
local TimerMgr = GameTimeManager
local StarMode = GameTableDefine.StarMode
local ValueManager = GameTableDefine.ValueManager
local CityMode = GameTableDefine.CityMode
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local ChooseUI = GameTableDefine.ChooseUI
local MainUI = GameTableDefine.MainUI
local IntroduceUI = GameTableDefine.IntroduceUI
local DiamondFundUI=GameTableDefine.DiamondFundUI
local AdFreeUI = GameTableDefine.AdFreeUI
local CountryMode = GameTableDefine.CountryMode
local FirstPurchaseUI = GameTableDefine.FirstPurchaseUI

---@class ShopUIView:UIBaseView
local ShopUIView = Class("ShopUIView", UIView)


function ShopUIView:ctor()
    self.super:ctor()
    self.m_dataSize = {}
    self.m_data = {}
    self.typeToIndex = {}
    self.m_doubleDiamondTimer = nil
    self.m_doubleDiamondTimerText = nil
end

function ShopUIView:OnEnter()
    print("ShopUIView:OnEnter")
    -- EventManager:RegEvent("SHOP_BUY_SUCCESS", function(shopId)
    --     ShopManager:Buy(shopId, false, function()
    --         ShopUI:SuccessBuyAfter(shopId)
    --     end,
    --     function()
    --         ShopUI:SuccessBuyBefor(shopId)
    --     end)
    -- end)
    -- EventManager:RegEvent("SHOP_BUY_FAIL", function(shopId)
    --     ShopUI:SuccessBuyAfter(shopId)
    -- end)
    FirstPurchaseUI:LockEnterShopUITime()
    ShopManager:refreshBuySuccess(function(shopId)
        ShopManager:Buy(shopId, false, function()
            ShopUI:SuccessBuyAfter(shopId)
        end,
        function()
            ShopUI:SuccessBuyBefor(shopId)
        end)
    end)
    ShopManager:refreshBuyFail(function(shopId)
        ShopUI:SuccessBuyAfter(shopId)
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/res/QuitBtn", "Button"), function()
        if self.closeCallBack then self.closeCallBack() end
        self:DestroyModeUIObject()
    end)
    --初始化列表
    self:InitList()
    --对资源钱,钻石,等进行格式的转变(部分国家货币标识问题)
    self:RefreshCash()
    self:RefreshDiamond()
    self:RefreshAdTime()
    --
    self.m_purchaseSucessGo = self:GetGo("purchase_success")
    self:SetButtonClickHandler(self.m_purchaseSucessGo:GetComponent("Button"), function()
        self.m_purchaseSucessGo:SetActive(false)
    end)

    self.m_frame1InfoGo = self:GetGo("frame1_info")
    self.m_frame1InfoGo:SetActive(false)
    self:SetButtonClickHandler(self:GetComp(self.m_frame1InfoGo, "bg", "Button"), function()
        self:CloseItemDetaild()
    end)
    GameSDKs:TrackForeign("store", {source = 1, operation_type = 0, product_id = "打开商城"})
end

function ShopUIView:RefreshDiamond()
    self:SetText("RootPanel/res/d/num", Tools:SeparateNumberWithComma(ResourceManger:GetDiamond()))
end

function ShopUIView:RefreshAdTime()
    local adRoot = self:GetGo("RootPanel/ShopContent/a")
    adRoot:SetActive(not GameConfig.IsIAP())
    if not GameConfig:IsIAP() then
        local __,exitTime = ShopManager:SpendADTime(true, 0)
        self:SetText("RootPanel/ShopContent/a/bg/num", exitTime)
    end
end

function ShopUIView:RefreshCash()
    self:SetText("RootPanel/res/c/num", Tools:SeparateNumberWithComma(ResourceManger:GetLocalMoney()))
    self:SetSprite(self:GetComp("RootPanel/res/c/icon", "Image"), "UI_Main", CountryMode.cash_icon)
end

function ShopUIView:OnPause()
    print("ShopUIView:OnPause")
end

function ShopUIView:OnResume()
    print("ShopUIView:OnResume")
end

function ShopUIView:OnExit()
    self.super:OnExit(self)
    self.m_data = nil
    self.typeToIndex = nil
    self.closeCallBack = nil
    if self.m_doubleDiamondTimer then
        GameTimer:StopTimer(self.m_doubleDiamondTimer)
        self.m_doubleDiamondTimer = nil
    end
    GameTimer:StopTimer(self.__timers["autoScro"])
    self.__timers["autoScro"] = nil

    self.dirLeft = nil
    self.dirRight = nil
    self.firstNaviToCEO = nil
    self:CleanTimer()

    -- EventManager:UnregEvent("SHOP_BUY_SUCCESS")
    -- EventManager:UnregEvent("SHOP_BUY_FAIL")
    ShopManager:refreshBuySuccess()
    ShopManager:refreshBuyFail()
    FirstPurchaseUI:UnlockEnterShopUITime()
    print("ShopUIView:OnExit")
end

function ShopUIView:CleanTimer()
    if self.__timers then
        for i = 1, 5 do
            if self.__timers["time" .. i] then
                GameTimer:StopTimer(self.__timers["time" .. i])
                self.__timers["time" .. i] = nil
            end
        end
    end
    if self.__timers["newPackShop"] then
        GameTimer:StopTimer(self.__timers["newPackShop"])
        self.__timers["newPackShop"] = nil
    end
    if self.__timers["growPackShop"] then
        GameTimer:StopTimer(self.__timers["growPackShop"])
        self.__timers["growPackShop"] = nil
    end
    if self.__timers["autoScro"] then
        GameTimer:StopTimer(self.__timers["autoScro"])
        self.__timers["autoScro"] = nil
    end
    if self.__timers["TurnPage"] then
        GameTimer:StopTimer(self.__timers["TurnPage"])
        self.__timers["TurnPage"] = nil
    end
    if self.__timers["TurnTo"] then
        GameTimer:StopTimer(self.__timers["TurnTo"])
        self.__timers["TurnTo"] = nil
    end
    if self.__timers["fragmentTip"] then
        GameTimer:StopTimer(self.__timers["fragmentTip"])
        self.__timers["fragmentTip"] = nil
    end
    if self.freeBoxCDTimer then
        GameTimer:StopTimer(self.freeBoxCDTimer)
        self.freeBoxCDTimer = nil
    end
    --self.__timers = nil
end

function ShopUIView:InitList()
    self.m_list = self:GetComp("RootPanel/ShopContent", "ScrollRectEx")
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
        if not template then
            print("data.frame is nil:"..data.frame)
        end
        local rootTrt = template:GetComponent("RectTransform")
        local trt = self:GetComp(template, "sale", "RectTransform")
        local originSize = rootTrt.rect

        if data.frame == "frame2" then
            local fpGO = self:GetGoOrNil(template,"purchase")
            if fpGO then
                local firstPurchaseIsOpen = FirstPurchaseUI:GetActivityIsOpen()
                fpGO:SetActive(firstPurchaseIsOpen)
                if not firstPurchaseIsOpen then
                    local saleTrans = self:GetComp(template,"sale","RectTransform")
                    local saleTransPos = saleTrans.position
                    local fpGOPos = fpGO.transform.position
                    saleTransPos.y = fpGOPos.y
                    saleTrans.position = saleTransPos
                end
            end
        end
        -- local si = UnityHelper.GetPreferredSize(self:GetGo(template, "sale"))
        -- print("----->", si, trt.anchoredPosition)
        -- local saleSize = trt.rect
        -- saleSize.height = CS.UnityEngine.UI.LayoutUtility.GetPreferredHeight(trt)
        local gridLayoutGroupEx = self:GetComp(template , "sale", "GridLayoutGroupEx")
        if gridLayoutGroupEx and not gridLayoutGroupEx:IsNull() then
            local gridSize = gridLayoutGroupEx:GetSize(math.ceil(#data.contents/gridLayoutGroupEx:GetConstraintCount()), 1)
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
end

--对列表的每个item的单独刷新
function ShopUIView:UpdateListItem(i, tran)
    local index = i + 1
    local data = self.m_data[index]
    local go = tran.gameObject

    if data.name then
        self:SetText(go, "title/txt", GameTextLoader:ReadText(data.name))
    end
    if data.desc then
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

function ShopUIView:UpdateAllShowItem()
    if not self.m_data then
        return
    end
    local refreshList = {}
    for k,v in pairs(self.m_data) do
        local isShow = self.m_list:GetScrollItemIsInUse(k - 1)
        if isShow then
            refreshList[k] = v
        end
    end
    for k,v in pairs(refreshList) do
        --将frame首字母大写
        local showString = v.frame:gsub("^%l", string.upper)
        showString = "Set" .. showString .. "Details"
        local fun = self[showString]
        if fun then
            local go = self.m_list:GetScrollItemTranByIndex(k - 1).gameObject
            fun(self, go, v)
            --调用不同的SetFrameXDetails()
        end
    end
end

function ShopUIView:SetBuff(BuffRoot, params)--商品id数组
    local allBuff = {"income", "offline", "mood", "diamond", "cash", "exp", "realcash"}
    local currIndex = 1
    local setNum = function(type, num)
        --if type ~= 13 and type ~= 14 then
        local currTypeName = ShopManager:TypeToName(type, true)
        if currTypeName then
            local newGo = self:GetGoOrNil(BuffRoot, currIndex .. "")
            if newGo then
                newGo:SetActive(true)

                for k,v in pairs(allBuff) do
                    local currGo = self:GetGoOrNil(newGo, v)
                    if currGo then
                        currGo:SetActive(v == currTypeName)
                        if v == currTypeName then
                            self:SetText(currGo, "num", num)
                            ViewUtils:ReseTextSize(self:GetComp(currGo, "common", "TMPLocalization"))
                        end
                    end     
                end
                currIndex = currIndex + 1
            end
        end
    end

    local currValue = nil
    local typeName = nil
    local currCfg = nil
    local allBuff = {}
    local typeCfg = {}

    local petSave = {}

    for k,v in pairs(params) do
        currCfg = ShopManager:GetCfg(v)
        if currCfg then
            currValue,typeName = ShopManager:GetValueByShopId(v)
            --currValue = ShopManager:SetValueToShow(currValue, currCfg)
            if typeName then
                if typeName == "pet" or typeName == "emplo" then
                    petSave[v] = currValue
                end

                if typeName ~= "pet" and typeName ~= "emplo" then
                    if allBuff[typeName] == nil then
                        allBuff[typeName] = 0
                        typeCfg[typeName] = currCfg
                    end
                    allBuff[typeName] = allBuff[typeName] + currValue
                end
            end
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
    if Tools:GetTableSize(allBuff) <= 0 then
        if BuffRoot then
           BuffRoot:SetActive(false) 
        end
    end
    for i = currIndex, 4 do
        local go = self:GetGoOrNil(BuffRoot, i .. "")
        -- self:GetGo(BuffRoot, i .. ""):SetActive(false)
        if go then
            go:SetActive(false)
        end
    end
end

function ShopUIView:SetFrame7Details(go, data)--新手礼包
    local isTimeGift = false
    local leftTime = -1
    local tempCentGos = {}
    local curShopID = nil
    local centGo
    for k,v in pairs(data.contents or {}) do
        local name = "temp"
        if k ~= 1 then
            name = "temp"..k
        end
        centGo = self:GetGo(go, "sale/"..name)
        --cfg = ConfigMgr.config_shop[v.id]
        if centGo then
            table.insert(tempCentGos, centGo)
            self:SetTempItemDetails(centGo, data, v)
            self:RefreshNewPlayer(centGo, data, k)
        end
        if not isTimeGift and leftTime == -1 then
            curShopID = v.id
            isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(v.id)
        end
    end
    -- 检测是否有时间限定的节点显示
    if isTimeGift then
        if leftTime > 0 then
            if self.__timers["newPackShop"] then
                GameTimer:StopTimer(self.__timers["newPackShop"])
                self.__timers["newPackShop"] = nil
            end
            self.__timers["newPackShop"] = GameTimer:CreateNewTimer(1, function()
                isTimeGift, leftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(curShopID)
                local timeStr = GameTimeManager:FormatTimeLength(leftTime)
                if leftTime > 0 then
                    for _, tmpGo in pairs(tempCentGos) do
                        self:SetText(tmpGo, "content/timer/txt", timeStr)
                    end
                else
                    if self.__timers["newPackShop"] then
                        GameTimer:StopTimer(self.__timers["newPackShop"])
                        self.__timers["newPackShop"] = nil
                    end
                    go:SetActive(false)
                end
            end, true, true)
        elseif leftTime <= 0 then
            go:SetActive(false)
        end
    end
end

function ShopUIView:RefreshNewPlayer(root, frameData, index)
    local content = frameData.contents[index]
    local contentIndex = frameData.contentIndex[index]
    local cfg = ConfigMgr.config_shop[content.id]
    local buffRoot = self:GetGo(root, "buff")
    self:SetBuff(buffRoot, cfg.param)

    local bg = self:GetComp(root, "", "Image")
    -- self:SetSprite(bg, "UI_Shop", "bg_shop_starterpack_" .. content.id)

    local canBuy,timeStay
    local btn = self:GetComp(root, "content/mBtn", "Button")

    local refresh = function(index)
        if root == nil or root:IsNull() then
            return
        end
        if btn and not btn:IsNull() then
            canBuy,timeStay = ShopManager:canBuyNewGift(content.id, TimerMgr:GetCurrentServerTime(true))
            if not canBuy then
                self:SetButtonClickHandler(btn, function()
                    EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_GOODS_OOD"))
                end)
                -- GameTimer:StopTimer(self.__timers["time" .. index])
            end
        end
    end

    refresh(contentIndex)

    -- if timeStay > 0 then
    --     self.__timers["time" .. contentIndex] = GameTimer:CreateNewTimer(1, function()
    --         refresh(contentIndex)
    --     end, true)
    -- end
end


function ShopUIView:RefreshDevelop(root, cfg, data, index)
    local shopData = data[index]

    local buffRoot = self:GetGo(root, "buff")
    self:SetBuff(buffRoot, cfg.param)

    local bg = self:GetComp(root, "bg", "Image")
    self:SetSprite(bg, "UI_Shop", "bg_shop_premiumpack_" .. shopData.id)

    local condition = cfg.param2 or {}
    local conditionRoot = self:GetGo(root, "content/req")
    local allCondition = {[5] = "star", [6] = "scene", [7] = "forbes"}
    local currCondition = nil
    local currConditionName = allCondition[condition[1]]
    local tempNode = nil

    for k,v in pairs(allCondition) do
        tempNode = self:GetGo(conditionRoot, v)
        tempNode:SetActive(currConditionName == v)
        if currConditionName == v then
            currCondition = tempNode
        end
    end

    local btnMoney = self:GetComp(root, "content/mBtn", "Button")
    local btnDiamond = self:GetComp(root, "content/dBtn", "Button")
    local btnAd = self:GetComp(root, "aBtn", "Button")


    btnMoney.gameObject:SetActive(cfg.iap_id ~= nil)
    btnDiamond.gameObject:SetActive(cfg.diamond ~= nil)
    btnAd.gameObject:SetActive(cfg.adTime ~= nil)

    local currBtn = btnMoney
    local typeEnough = true

    if cfg.iap_id then
        currBtn = btnMoney
    elseif cfg.adTime then
        currBtn = btnAd
        typeEnough = ShopManager:SpendADTime(true, cfg.adTime)
    elseif cfg.diamond then
        currBtn = btnDiamond
        typeEnough = ResourceManger:CheckDiamond(cfg.diamond)
    end

    local valueNeed = condition[2] or ""
    local canBuy = false

    if condition[1] == 5 then--声望
        canBuy = StarMode:GetStar() >= valueNeed
    elseif condition[1] == 6 then--场景
        canBuy = CityMode:CheckBuildingSatisfy(valueNeed)
        valueNeed = GameTextLoader:ReadText("TXT_BUILDING_B" .. valueNeed .. "_NAME")
    elseif condition[1] == 7 then--身价
        canBuy = ValueManager:GetValue() >= valueNeed
    end

    local amountEnough = ShopManager:CheckBuyTimes(shopData.id, 1)
    if canBuy and amountEnough and typeEnough then
        canBuy = true
    else
        canBuy = false
    end

    currBtn.interactable = canBuy

    -- self:GetGo(root, "content/sale"):SetActive(canBuy)
    self:GetGo(root, "content/req"):SetActive(not canBuy)

    if currCondition then
        self:SetText(currCondition, "num", valueNeed)
    end
end

function ShopUIView:SetFrame8Details(go, data)--成长礼包
    local allCanBuy = {}
    for k,v in pairs(data.contents or {}) do
        if not ShopManager:BoughtBefor(v.id) then
            table.insert(allCanBuy, v)
        end
    end

    self.devData = allCanBuy
    if Tools:GetTableSize(self.devData) == 0 then
        go:SetActive(false)
        return
    else
        go:SetActive(true)
    end
    if self.displayFrame8ItemSelectGos and Tools:GetTableSize(self.displayFrame8ItemSelectGos) > 0 then
        for index, go in ipairs(self.displayFrame8ItemSelectGos) do
            if index > #self.allDevData - 1 then
                GameObject.Destroy(go)
                self.displayFrame8ItemSelectGos[index] = nil
            end
        end
    end
    self.allDevData = data
    local isHaveTimeCount = false
    local tmpGo = self:GetGoOrNil(go, "sale/temp")
    local parentTrans = self:GetTrans(go, "sale")
    if not tmpGo or not parentTrans then
        return
    end
    for i = 2, Tools:GetTableSize(self.devData) do
        local newGo = GameObject.Instantiate(tmpGo, parentTrans)
        if newGo then
            if not self.displayFrame8ItemSelectGos then
                self.displayFrame8ItemSelectGos = {}
            end
            newGo.name = "temp"..i
            table.insert(self.displayFrame8ItemSelectGos, newGo)
        end
    end

    for i = 1, Tools:GetTableSize(self.devData) do
        local curData = self.devData[i]
        local root = nil
        if i == 1 then
            root = tmpGo
        else
            root = self.displayFrame8ItemSelectGos[i - 1]
        end

        local data = self.devData[i]
        local cfg = ConfigMgr.config_shop[data.id]
        self:SetTempItemDetails(root, self.allDevData, data)
        self:RefreshDevelop(root, cfg, self.devData, i)
    end

    --倒计时单独处理
    local maxTime = 0
    if self.__timers["growPackShop"] then
        GameTimer:StopTimer(self.__timers["growPackShop"])
        self.__timers["growPackShop"] = nil
    end
    for i = 1, Tools:GetTableSize(self.devData) do
        -- data.id
        local curTimeGift, curLeftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(self.devData[i].id)
        if curTimeGift and curLeftTime > 0 then
            if curLeftTime > maxTime then
                maxTime = curLeftTime
            end
        end
    end
    if Tools:GetTableSize(self.devData) > 0 and maxTime > 0 then
        self.__timers["growPackShop"] = GameTimer:CreateNewTimer(1, function()
            local isAllZero = true
            for i = 1, Tools:GetTableSize(self.devData) do
                -- data.id
                local curTimeGift, curLeftTime = GameTableDefine.IntroduceUI:CheckShopIDEffectTime(self.devData[i].id)
                local useTmpGo = tmpGo
                if i ~= 1 then
                    useTmpGo = self.displayFrame8ItemSelectGos[i-1]
                end
                local timeStr = GameTimeManager:FormatTimeLength(curLeftTime)
                self:SetText(useTmpGo, "content/timer/txt", timeStr)
                if curTimeGift and curLeftTime > 0 then
                    isAllZero = false
                end
            end
            if isAllZero then
                GameTimer:StopTimer(self.__timers["growPackShop"])
                self.__timers["growPackShop"] = nil
            end
        end, true, true)
    end
    
end

function ShopUIView:RefreshDirect(currIndex)--成长礼包的两个箭头
    if self.dirLeft and not self.dirLeft:IsNull() then
        local result = currIndex > 1 and #self.devData > 1
        self.dirLeft:SetActive(currIndex > 1 and #self.devData > 1)
        self.dirRight:SetActive(currIndex < #self.devData and #self.devData > 1)
    end
end

function ShopUIView:updateDevelopPackage(index, rootTrans)
    if index == nil then--不知道为何
        index = self.lastPackage
    end
    index = index + 1
    self.lastPackage = index
    self:RefreshDirect(self.lastPackage)
    if self.displayFrame8ItemSelectGos and index <= Tools:GetTableSize(self.displayFrame8ItemSelectGos) then
        for key, itemGo in ipairs(self.displayFrame8ItemSelectGos) do
            local checkMarkGO = self:GetGoOrNil(itemGo, "Toggle/Background/Checkmark")
            if checkMarkGO then
                checkMarkGO:SetActive(index == key)
            else
                table.remove(self.displayFrame8ItemSelectGos, key)
            end
        end 
    end
    local root = rootTrans.gameObject

    local data = self.devData[index]
    local cfg = ConfigMgr.config_shop[data.id]
    self:SetTempItemDetails(root, self.allDevData, data)
    self:RefreshDevelop(root, cfg, self.devData, index)
    
end

function ShopUIView:SetFrame1Details(go, data)--经验,现金 -- 宠物零食
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function ShopUIView:SetFramePetDetails(go, data)-- 宠物零食
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v, true)
        end
    end
end

function ShopUIView:SetFrameExpDetails(go, data)--经验
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v, true)
        end
    end
end

function ShopUIView:SetFrameCashDetails(go, data)--现金
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v, true)
        end
    end
end

function ShopUIView:SetFrame12Details(go, data)--国内经验,现金
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function ShopUIView:SetFrame2Details(go, data)--钻石
    local root = self:GetGo(go, "free/temp")

    --免费钻石商场
    self:SetText(root, "num/num", ConfigMgr.config_global.free_diamond)

    local cdTime = ShopUI:RewardDiamondCD()
    local freeBtn = self:GetComp(root, "FreeBtn", "Button")
    local icon = self:GetGo(root, "FreeBtn/icon")
    icon:SetActive(cdTime <= 0)
    if cdTime > 0 then
        freeBtn.interactable = false
        self.endPoint = GameTimeManager:GetCurrentServerTime(true) + cdTime
        self:CreateTimer(1000, function()
            local t = self.endPoint - GameTimeManager:GetCurrentServerTime(true)
            local H = math.ceil(t / 3600)
            if t > 0 then
                self:SetText(root,"FreeBtn/text", H.."H")
            else
                self:StopTimer()
                self:SetFrame2Details(go, data)
            end
        end, true, true, true)
    else
        freeBtn.interactable = true
        self:SetText(root,"FreeBtn/text", GameTextLoader:ReadText("TXT_BTN_FREE"))
        self:SetButtonClickHandler(freeBtn, function()
            freeBtn.interactable = false
            ShopUI:GetRewardDiamond(function()
                EventManager:DispatchEvent("FLY_ICON", nil, 3, nil, function()
                    self:RefreshDiamond()
                end)
                self:SetFrame2Details(go, data)
            end)
            self:InitNavigationButtons()
        end)
    end

    --facebook分享功能
    local facebookGo = self:GetGo(go, "facebook")
    local curRecord = LocalDataManager:GetCurrentRecord()
    local isGetFollowDiamond = false
    if not curRecord.getFollowDiamond or curRecord.getFollowDiamond == 0 then
        --没有领取过钻石
        isGetFollowDiamond = false
    else
        --领取过钻石
        isGetFollowDiamond = true
    end
    local facebookGoBtn = self:GetComp(facebookGo, "temp/GoBtn", "Button")
    if facebookGoBtn then
        self:SetButtonClickHandler(facebookGoBtn, function()
            if not isGetFollowDiamond then
                curRecord.getFollowDiamond = 1
                isGetFollowDiamond = true
                EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
                ResMgr:AddDiamond(100, ResMgr.EVENT_CLAIM_FOLLOW_FACEBOOK, function()
                end, true)
                --刷新显示
                self:RefreshFacebookStateDisp(isGetFollowDiamond, facebookGo)
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "Facebook跳转", behaviour = 1, num_new = 100})
            end
            GameDeviceManager:OpenURL("https://www.facebook.com/IdleOfficeTycoon")
        end)
    end
    self:RefreshFacebookStateDisp(isGetFollowDiamond, facebookGo)

    --购买钻石
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v, true)
        end
    end

    if FirstPurchaseUI:GetActivityIsOpen() then
        --首充双倍活动倒计时
        local timerText = self:GetComp(go,"purchase/timer/num","TMPLocalization")
        self.m_doubleDiamondTimerText = timerText
        if not self.m_doubleDiamondTimer then
            self.m_doubleDiamondTimer = GameTimer:CreateNewTimer(1,function()
                if not self.m_doubleDiamondTimerText:IsNull() then
                    local leftTime = FirstPurchaseUI:GetActivityLeftTime()
                    self.m_doubleDiamondTimerText.text = TimerMgr:FormatTimeLength(leftTime)
                else
                    GameTimer:StopTimer(self.m_doubleDiamondTimer)
                    self.m_doubleDiamondTimer = nil
                end
            end,true,true)
        else
            local leftTime = FirstPurchaseUI:GetActivityLeftTime()
            self.m_doubleDiamondTimerText.text = TimerMgr:FormatTimeLength(leftTime)
        end
    end
end

function ShopUIView:SetFrame3Details(go, data)--收入倍率
    local temp = self:GetGo(go, "sale/temp")

    local currTxt = self:GetComp(go, "title/subtitle/txt", "TextMeshProUGUI")
    local currString = nil
    if #data.contents <= 0 then
        print("error data id is:"..data.id)
        return
    end
    local useLess,currValue,type = ShopManager:Buy(data.contents[1].id, true)
    if type == 7 then
        currString = GameTextLoader:ReadText("TXT_SHOP_OFFLINE_DESC")
        currValue = ShopManager:GetOfflineAdd()
    elseif type == 6 then
        currString = GameTextLoader:ReadText("TXT_SHOP_INCOME_DESC")
        currValue = math.floor((FloorMode:GetCurrImprove() - 1 ) * 100)
    end
    currString = string.format(currString, currValue)
    currTxt.text = currString

    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function ShopUIView:SetFrame4Details(go, data)--免广告
    local temp = self:GetGo(go, "sale/temp")
    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function ShopUIView:SetFrame5Details(go, data)--钻石月卡
    local temp = self:GetGo(go, "sale/temp")

    local nowTime = TimerMgr:GetCurrentServerTime(true)
    local shopData,diamondGet = ShopManager:BuyDiamonCardData()
    local MonthCardEndTime = 0
    --local nowDay = os.date("%d", nowTime)
    local lastReceiveDay = 0

    if shopData ~= nil then
        MonthCardEndTime = shopData.last
        lastReceiveDay = shopData.get
    end

    local needBuy = false
    if shopData == nil then
        needBuy = true
    end

    local canReceive = ShopManager:GetDiamondCardReward(true, nil, nowTime)
    local dayDiatance = self:DayDiatance(nowTime,MonthCardEndTime)
    if dayDiatance <= 0 then
        if nowTime > MonthCardEndTime + 86400 then--过期了
            needBuy = true
        elseif not canReceive then--今天的奖励也领了
            needBuy = true
        end
    end

    local shopData = data.contents[1]
    local cfg = ConfigMgr.config_shop[shopData.id]
    local root = self:CheckDataAndGameObject(temp, shopData, 1)
    self:SetTempItemDetails(root, data, shopData)

    local diamondBtn = self:GetComp(root, "dBtn", "Button")
    local moneyBtn = self:GetComp(root, "mBtn", "Button")
    local freeBtn = self:GetComp(root, "FreeBtn", "Button")
    local adBtn = self:GetComp(root, "aBtn", "Button")


    diamondBtn.gameObject:SetActive(cfg.diamond == nil)
    moneyBtn.gameObject:SetActive(cfg.iap_id ~= nil)
    adBtn.gameObject:SetActive(cfg.adTime ~= nil)

    local mBtn = cfg.iap_id ~= nil and moneyBtn or diamondBtn

    mBtn.gameObject:SetActive(needBuy)
    freeBtn.gameObject:SetActive(not needBuy)

    self:GetGo(root, "remain"):SetActive(not needBuy)
    if needBuy then--SetTempItemDetails

    else
        freeBtn.interactable = canReceive
        adBtn.gameObject:SetActive(false)
        self:GetGo(root, "FreeBtn/icon"):SetActive(canReceive)
        self:SetButtonClickHandler(freeBtn, function()
            ShopManager:GetDiamondCardReward(false, function()
                self:SetFrame5Details(go, data)
                EventManager:DispatchEvent("FLY_ICON", nil, 3, nil, function()
                    self:RefreshDiamond()
                end)
            end, nil,
            function()
                ChooseUI:CommonChoose("TXT_SHOP_TIME_CHECK")
                --EventManager:DispatchEvent("UI_NOTE",  "time is wrong")
            end)
        end)

        local timeRemain = MonthCardEndTime - nowTime
        --local dayRemain = self:DayDiatance(nowTime, MonthCardEndTime)
        local txt = GameTextLoader:ReadText("TXT_SHOP_MONTH_DIAMOND_REMAIN")
        txt = string.format(txt, dayDiatance)
        self:SetText(root, "remain", txt)
        self:SetText(root, "FreeBtn/num", diamondGet)
    end
end

function ShopUIView:DayDiatance(from, to)
    if from == nil or to == nil then
        return 0
    end
    if to == 0 or from == 0 then
        return 0
    end

    local toYear = os.date("%Y", to)
    local toMon = os.date("%m", to)
    local toDay = os.date("%d", to)
    local toTime = os.time({year = toYear, month = toMon, day = toDay, hour = 0, min = 0, sec = 0})

    if from < toTime then
        local dis = toTime - from
        return math.floor(dis / 86400) + 1
    else
        return 0
    end
end

function ShopUIView:SetFrame6Details(go, data)--离线时长
    local temp = self:GetGo(go, "sale/temp")

    local currTxt = self:GetComp(go, "title/subtitle/txt", "TextMeshProUGUI")
    local currString = nil
    local useLess,currValue,type = ShopManager:Buy(data.contents[1].id, true)
    if type == 7 then
        currString = GameTextLoader:ReadText("TXT_SHOP_OFFLINE_DESC")
        currValue = ShopManager:GetOfflineAdd(true) + ConfigMgr.config_global.offline_timelimit
    elseif type == 6 then
        currString = GameTextLoader:ReadText("TXT_SHOP_INCOME_DESC")
        currValue = (FloorMode:GetCurrImprove() - 1 ) * 100
    end
    currString = string.format(currString, currValue)
    currTxt.text = currString


    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function ShopUIView:SetFrame9Details(go, data)
    local temp = self:GetGo(go, "sale/temp")

    local currTxt = self:GetComp(go, "title/subtitle/txt", "TextMeshProUGUI")
    local moodAdd = GreateBuildingMana:GetMoodImprove()
    currTxt.text = "+" .. moodAdd


    -- for k, v in ipairs(data.contents or {}) do
    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
    end
end

function ShopUIView:SetFrame10Details(go, data)
    local temp = self:GetGo(go, "sale/temp")
    local currText = self:GetComp(go, "title/subitle/txt", "TextMeshProUGUI")
    
    local shopData = data.contents[1]
    local root = self:CheckDataAndGameObject(temp, shopData, 1)
    self:SetTempItemDetails(root, data, shopData)
    
    local cfg = ConfigMgr.config_shop[shopData.id]
    local buffRoot = self:GetGo(root, "buff")
    self:SetBuff(buffRoot, cfg.param)
end

function ShopUIView:SetFrame11Details(go, data)
    local temp = self:GetGo(go, "sale/temp")
    local currText = self:GetComp(go, "title/subitle/txt", "TextMeshProUGUI")
    
    local shopData = data.contents[1]
    local root = self:CheckDataAndGameObject(temp, shopData, 1)
    self:SetTempItemDetails(root, data, shopData)
    
    local cfg = ConfigMgr.config_shop[shopData.id]
    local buffRoot = self:GetGo(root, "buff")
    self:SetBuff(buffRoot, cfg.param)
end

--------------------------------------------------------
function ShopUIView:SetFrame13Details(go, data)        
    for k = 1, #data.contents do
        local temp = self:GetGo(go, "sale/temp_" .. k)
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)               
        if centGo then
            --self:SetTempItemDetails(centGo, data, v)
            if k == 1 then  --免广告
                self:SetTempItemDetails(centGo, data, v)
                local TipsBtn = self:GetComp(centGo, "tipBtn", "Button")
                self:SetButtonClickHandler(TipsBtn, function()  -- 说明
                    AdFreeUI:GetView()
                end)
                
            elseif k == 2 then  --月卡
                --获取时间
                local nowTime = TimerMgr:GetCurrentServerTime(true)
                local shopData,diamondGet = ShopManager:BuyDiamonCardData() -- 得到上次获取钻石的时间,和下次能获取砖石的时间 shopData,与获取钻石的数量diamondGet
                local MonthCardEndTime = 0
                --local nowDay = os.date("%d", nowTime)
                local lastReceiveDay = 0
                
                if shopData ~= nil then
                    MonthCardEndTime = shopData.last
                    lastReceiveDay = shopData.get
                end
            
                local needBuy = false
                if shopData == nil then
                    needBuy = true
                end
            
                local canReceive = ShopManager:GetDiamondCardReward(true, nil, nowTime) --没有购买 和 最后领取时间与当前时间相同 时返回false   
                local dayDiatance = self:DayDiatance(nowTime,MonthCardEndTime)
                
                

                if dayDiatance <= 0 then
                    if nowTime > MonthCardEndTime + 86400 then--过期了
                        needBuy = true
                    elseif not canReceive then--今天的奖励也领了
                        needBuy = true
                    end
                end
            
                local shopData = data.contents[k]
                local cfg = ConfigMgr.config_shop[shopData.id]
                self:SetTempItemDetails(centGo, data, shopData)
                local diamondBtn = self:GetComp(centGo, "dBtn", "Button")
                local moneyBtn = self:GetComp(centGo, "mBtn", "Button")
                local freeBtn = self:GetComp(centGo, "FreeBtn", "Button")
                local adBtn = self:GetComp(centGo, "aBtn", "Button")
                

                --设置面板中的说明文本
                local tip1 = string.format(GameTextLoader:ReadText("TXT_SHOP_DIAMOND_PASS_TIP1"),tostring(cfg.amount+cfg.param[1]*cfg.param2[1]))
                local tip2 = string.format(GameTextLoader:ReadText("TXT_SHOP_DIAMOND_PASS_TIP2"),tostring(cfg.param[1]))
                local tip3 = string.format(GameTextLoader:ReadText("TXT_SHOP_DIAMOND_PASS_TIP3"),tostring(cfg.amount))
               
                self:SetText(centGo,"tip1", tip1)                
                self:SetText(centGo,"tip2", tip2)
                self:SetText(centGo,"tip3", tip3) 
            
                diamondBtn.gameObject:SetActive(cfg.diamond == nil)
                moneyBtn.gameObject:SetActive(cfg.iap_id ~= nil)
                adBtn.gameObject:SetActive(cfg.adTime ~= nil)
            
                local mBtn = cfg.iap_id ~= nil and moneyBtn or diamondBtn
            
                mBtn.gameObject:SetActive(needBuy)
                freeBtn.gameObject:SetActive(not needBuy)
            
                self:GetGo(centGo, "remain"):SetActive(not needBuy)
                if needBuy then--SetTempItemDetails
            
                else
                    freeBtn.interactable = canReceive
                    adBtn.gameObject:SetActive(false)
                    self:GetGo(centGo, "FreeBtn/icon"):SetActive(canReceive)
                    self:SetButtonClickHandler(freeBtn, function()
                        ShopManager:GetDiamondCardReward(false, function()
                            self:SetFrame13Details(go, data)
                            EventManager:DispatchEvent("FLY_ICON", nil, 3, nil, function()
                                self:RefreshDiamond()
                            end)
                        end, nil,
                        function()
                            ChooseUI:CommonChoose("TXT_SHOP_TIME_CHECK")
                            --EventManager:DispatchEvent("UI_NOTE",  "time is wrong")
                        end)
                        
                    end)
            
                    local timeRemain = MonthCardEndTime - nowTime
                    --local dayRemain = self:DayDiatance(nowTime, MonthCardEndTime)
                    local txt = GameTextLoader:ReadText("TXT_SHOP_MONTH_DIAMOND_REMAIN")
                    txt = string.format(txt, dayDiatance)
                    self:SetText(centGo, "remain", txt)
                    self:SetText(centGo, "FreeBtn/num", diamondGet)
                end            
            elseif k == 3 then  --钻石基金
                local mBtn = self:GetComp(centGo, "mBtn", "Button")
                -----设置说明文本--富文本和format同时都有 % 时需要配文档时将富文本的 % 设置为 %%
                local totalDiamonds = 0
                local fundCfg = ConfigMgr.config_fund      
                for i = 1, #fundCfg do       
                    totalDiamonds = totalDiamonds + fundCfg[i].diamond                                            
                end        
                local introduceText = string.format(GameTextLoader:ReadText("TXT_FUND_DESC2"),tostring(totalDiamonds)) 
                self:SetText(centGo,"tip", introduceText)
                -----
                self:SetButtonClickHandler(mBtn, function()
                    DiamondFundUI:GetView()
                end)
            end

        end            
    end    
end
function ShopUIView:SetFrame14Details(go, data)    
    for k = 1, #data.contents do        
        local temp = self:GetGo(go, "sale/viewport/content/temp_" .. k)
        local v = data.contents[k]
        local cfg = ConfigMgr.config_shop[v.id]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
        local buffRoot = self:GetGo(centGo, "buff")
        self:SetBuff(buffRoot, cfg.param)        
    end
end

--[[
    @desc: 万圣节商品货架列表
    author:{author}
    time:2022-10-24 10:43:12
    --@go:
	--@data: 
    @return:
]]
function ShopUIView:SetFrame15Details(go, data)
    local temp = self:GetGo(go, "sale/temp")

    local currTxt = self:GetComp(go, "title/subtitle/txt", "TextMeshProUGUI")
    local currString = nil
    if #data.contents <= 0 then
        print("error data id is:"..data.id)
        return
    end

    for k = 1, data.max_count do
        local v = data.contents[k]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
            local buffRoot = self:GetGo(centGo, "buff")
            if buffRoot then
                local cfg = ConfigMgr.config_shop[v.id]
                self:SetBuff(buffRoot, cfg.param) 
            end
        end
    end
end
function ShopUIView:SetFrame16Details(go, data)
    for k = 1, #data.contents do
        
        local temp = self:GetGo(go, "sale/temp_" .. k)
        local v = data.contents[k]
        local cfg = ConfigMgr.config_shop[v.id]
        local centGo = self:CheckDataAndGameObject(temp, v, k)
        if centGo then
            self:SetTempItemDetails(centGo, data, v)
        end
        local buffRoot = self:GetGo(centGo, "buff")
        self:SetBuff(buffRoot, cfg.param)        
    end
end

--[[
    @desc: CEO宝箱货架
    author:{author}
    time:2025-02-17 11:40:50
    --@go:
	--@data: 
    @return:
]]
function ShopUIView:SetFrameCEOChestDetails(go, data)--CEO宝箱
    local frameTipsBtn = self:GetComp(go, "title/tipsBtn", "Button")
    self:SetButtonClickHandler(frameTipsBtn, function()
        --TODO:节点tips按钮显示
        self:ShowCEOChestSysTip()
    end)
    local temp = self:GetGo(go, "sale/temp")
    --freeBox
    --setp1.设置免费宝箱的tipsbtn
    local freeBoxData = {}
    local freeGo = self:CheckDataAndGameObject(temp, freeBoxData, 1)
    local freeBoxCfg = ConfigMgr.config_ceo_chest["free"]
    self:GetGo(freeGo, "aBtn"):SetActive(true)
    self:GetGo(freeGo, "kBtn"):SetActive(false)
    local currLeftFreeTimes = GameTableDefine.CEODataManager:GetDayFreeLeftTimes()
    local canOpenFree = (GameTableDefine.CEODataManager:GetFreeBoxCDTime() <= 0 and  currLeftFreeTimes > 0)
    self:SetButtonClickHandler(self:GetComp(freeGo, "tipsBtn", "Button"), function()
        self:ShowCEOChestOpenTip("free")
    end)
    
    self:SetSprite(self:GetComp(freeGo, "icon", "Image"), "UI_Shop", "icon_ceo_chest_free")
    self:SetText(freeGo, "name/text", GameTextLoader:ReadText(freeBoxCfg.chest_name))
    -- icon_btn_AD
    -- self:SetSprite(self:GetComp(freeGo, "aBtn/icon", "Image"), "UI_Common", "icon_btn_AD");
    local freeBtn = self:GetComp(freeGo, "aBtn", "Button")
    if self.freeBoxCDTimer then
        GameTimer:StopTimer(self.freeBoxCDTimer)
        self.freeBoxCDTimer = nil
    end
    local FreeDisplayFunc = function() 
        --更新CD倒计时
        local curCDTime = 0
        local isTimeCD = true
        if currLeftFreeTimes > 0 then
            curCDTime = GameTableDefine.CEODataManager:GetFreeBoxCDTime()
        else
            curCDTime = GameTableDefine.CEODataManager:GetDayRefreshTimeLeft()
            isTimeCD = false
        end
        self:GetGo(freeGo, "aBtn/remain"):SetActive(curCDTime == 0)
        self:GetGo(freeGo, "aBtn/common"):SetActive(curCDTime == 0)
        self:GetGo(freeGo, "aBtn/limit"):SetActive(curCDTime == 0)
        self:GetGo(freeGo, "aBtn/timer"):SetActive(curCDTime ~= 0)
        if curCDTime == 0 then
            currLeftFreeTimes = GameTableDefine.CEODataManager:GetDayFreeLeftTimes()
            canOpenFree = (GameTableDefine.CEODataManager:GetFreeBoxCDTime() <= 0 and  currLeftFreeTimes > 0)
            if self.freeBoxCDTimer then
                GameTimer:StopTimer(self.freeBoxCDTimer)
                self.freeBoxCDTimer = nil
            end
            freeBtn.interactable = canOpenFree
            self:SetText(freeGo, "aBtn/remain", tostring(currLeftFreeTimes))
            self:SetText(freeGo, "aBtn/limit", tostring(ConfigMgr.config_global.ceochest_free_limit))
        else
            local dispTimeCD = GameTimeManager:FormatTimeLength(curCDTime)
            -- if not isTimeCD then
            --     dispTimeCD = GameTimeManager:FormatTimeLength(curCDTime)
            -- end
            self:SetText(freeGo, "aBtn/timer", dispTimeCD)
        end
        self:GetGo(freeGo, "aBtn/tips"):SetActive(canOpenFree)
        self:InitNavigationButtons()
    end 
    if not canOpenFree then
        self.freeBoxCDTimer = GameTimer:CreateNewTimer(1, function()
            FreeDisplayFunc()
        end, true, true)
    else
        FreeDisplayFunc()
    end
    freeBtn.interactable = canOpenFree
    self:SetButtonClickHandler(freeBtn, function() 
        freeBtn.interactable = false
        GameSDKs:PlayRewardAd(function()
            GameTableDefine.CEODataManager:OpenCEOBox("free", 1, false, function(flag) 
                if flag then
                    if self.freeBoxCDTimer then
                        GameTimer:StopTimer(self.freeBoxCDTimer)
                        self.freeBoxCDTimer = nil
                    end
                    currLeftFreeTimes = GameTableDefine.CEODataManager:GetDayFreeLeftTimes()
                    canOpenFree = (GameTableDefine.CEODataManager:GetFreeBoxCDTime() <= 0 and  currLeftFreeTimes > 0)
                    freeBtn.interactable = canOpenFree
                    if not canOpenFree then
                        self.freeBoxCDTimer = GameTimer:CreateNewTimer(1, function()
                            FreeDisplayFunc()
                        end, true, true)
                    else
                        FreeDisplayFunc()
                    end
                end
            end, 4)
            self:RefreshDiamond()
            self.m_list:UpdateData(true)
            local scrollIndex = -1
            for i, v in pairs(self.m_data) do
                if v.frame == "frameCEOChest" then
                    scrollIndex = i - 1
                    break
                end
            end
            if scrollIndex >= 0 then
                self.m_list:ScrollTo(scrollIndex, 3)
            end
        end,function() 
            FreeDisplayFunc()
        end, function() 
            FreeDisplayFunc()
        end, 10015)
    end)
    self.ceoBoxBtnGos = {}
    --step2.其他2个宝箱的设置
    for k = 1, data.max_count do 
        local v = data.contents[k]
        
        -- if not self.ceoBoxBtnGos["normal"] and boxType == "normal" then
        --     self.ceoBoxBtnGos["normal"] = centGo
        -- end
        -- if not self.ceoBoxBtnGos["premium"] and boxType == "premium" then
        --     self.ceoBoxBtnGos["premium"] = centGo
        -- end
        local centGo = self:CheckDataAndGameObject(temp, v, k + 1)
        if centGo then
            if v.id then
                local shopCfg = ConfigMgr.config_shop[v.id]
                if shopCfg and shopCfg.type == 42 then
                    if not self.ceoBoxBtnGos[shopCfg.param[1]] then
                        self.ceoBoxBtnGos[shopCfg.param[1]] = centGo
                    end
                end
            end
            self:SetTempItemDetails(centGo, data, v)
        end
    end
    
end
--------------------------------------------------------

function ShopUIView:CheckDataAndGameObject(temp, data, index)
    local tarans = temp.transform.parent
    local go = tarans.gameObject
    local centTrans = self:GetTrans(go, "temp_"..index)
    temp:SetActive(false)
    if data then
        if not centTrans or centTrans:IsNull() then
            local newGo = GameObject.Instantiate(temp, tarans)
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

--这个data就是content对应的
function ShopUIView:SetTempItemDetails(centGo, rootData, data, isNewNum)
    --绑定具体某个商品的显示以及点击的效果
    local v = ConfigMgr.config_shop[data.id]
    if v.name then
        self:SetText(centGo, "name", GameTextLoader:ReadText(v.name))
    end
    if v.desc then
        self:SetText(centGo, "desc", GameTextLoader:ReadText(v.desc))
    end

    local value = ShopManager:GetValueByShopId(data.id)
    
    --2024-10-18 fy 策划需求修改双倍效果调整：设置动画机状态
    local normalDiamondNum = 0
    local doubleDiamondNum = 0
    if v.type == 3 then
        if FirstPurchaseUI:IsFirstDouble(data.id) then
            value = math.floor(value / 2)
        end
        normalDiamondNum = value
        doubleDiamondNum = 2 * value
        -- self:GetGo(centGo, "double"):SetActive(ShopManager:FirstBuy(data.id))
        --2024-10-18 fy 策划需求修改双倍效果调整：设置动画机状态
        local animator = centGo:GetComponent("Animator")
        if animator then
            GameTimer:CreateNewMilliSecTimer(1,function()
                if not animator:IsNull() then
                    local isFirst = FirstPurchaseUI:IsFirstDouble(data.id)
                    if isFirst then
                        animator:SetBool("double", true)
                        animator:SetTrigger("displayDouble")
                    else
                        animator:SetBool("double", false)
                    end
                end
            end)
        end
    elseif v.type == 5 then --免广告
        self:GetGo(centGo, "bg/area"):SetActive(true)
        local tipBtn = self:GetComp(centGo,"bg/area/tipicon/tipBtn","Button")
        self:SetButtonClickHandler(tipBtn,function()
            AdFreeUI:GetView()
        end)
    elseif v.type == 42 then --CEO宝箱
        
        self:GetGo(centGo, "aBtn"):SetActive(false)
        self:GetGo(centGo, "kBtn"):SetActive(true)
        local openBtn = self:GetComp(centGo, "kBtn", "Button")
        local boxType = v.param[1]
        local curBoxCfg = ConfigMgr.config_ceo_chest[boxType]        
        value = GameTableDefine.CEODataManager:GetCurKeys(v.param[1])
        local needKeys = 0
        if "normal" == boxType or "premium" == boxType then
            local tmpStrs = Tools:SplitString(ConfigMgr.config_ceo_chest[boxType].chest_key_require, ":")
            needKeys = tonumber(tmpStrs[2])
        end
        local openBoxDisp = function()
            value = GameTableDefine.CEODataManager:GetCurKeys(v.param[1])
            -- 单独设置CEO宝箱相关内容
            -- self:GetGo(centGo, "kBtn/time"):SetActive(false)
            local curKeys = value
            
            local keyIcon = ""
            local keyRequireStrs = ConfigMgr.config_ceo_chest[boxType].chest_key_require
            if "normal" == boxType or "premium" == boxType then
                local tmpStrs = Tools:SplitString(keyRequireStrs, ":")
                needKeys = tonumber(tmpStrs[2])
                keyIcon = "icon_ceo_key_"..boxType
            end
            self:GetGo(centGo, "kBtn/have"):SetActive(true)
            self:GetGo(centGo, "kBtn/need"):SetActive(true)
            self:GetGo(centGo, "kBtn/common"):SetActive(true)
            self:SetText(centGo, "kBtn/have", tostring(curKeys))
            self:SetText(centGo, "kBtn/need", tostring(needKeys))
            self:SetText(centGo, "name/text", GameTextLoader:ReadText(curBoxCfg.chest_name))
            self:SetSprite(self:GetComp(centGo, "icon", "Image"), "UI_Shop", v.icon)
            self:SetSprite(self:GetComp(centGo, "kBtn/icon", "Image"), "UI_Shop", keyIcon)
            self:GetGo(centGo, "kBtn/tips"):SetActive(curKeys >= needKeys)
            openBtn.interactable = true
            for refreshKey, go in pairs(self.ceoBoxBtnGos or {}) do
                local dispValue = tostring(GameTableDefine.CEODataManager:GetCurKeys(refreshKey))
                self:SetText(go, "kBtn/have", dispValue)
            end
            self:RefreshDiamond()
        end
        openBoxDisp()
        self:SetButtonClickHandler(openBtn, function()
            -- openBtn.interactable = false
            --首先判断能开几个箱子
            if needKeys > 0 then 
                local openBoxNum = math.floor(value / needKeys)
                if openBoxNum > 0 then
                    if openBoxNum == 1 then
                        GameTableDefine.CEODataManager:OpenCEOBox(boxType, 1, true, function(flag)
                            if flag then
                                openBoxDisp()
                            end
                        end,4)
                    else
                        --打开多个箱子的界面
                        self:ShowMoreCEOBoxOpen(boxType, function()
                            openBoxDisp()
                        end)
                    end
                else
                    --不能开箱子的时候需要打开够买钥匙的界面
                    self:ShowBuyCEOKeyOpen(boxType, function()
                        openBoxDisp()
                    end)
                    GameSDKs:TrackForeign("ceo_exposure", {type = "钥匙礼包界面开启"})
                end
            end
            
        end)
        self:SetButtonClickHandler(self:GetComp(centGo, "tipsBtn", "Button"), function()
            self:ShowCEOChestOpenTip(boxType)
        end)
        return
    end

    local valueShow = ShopManager:SetValueToShow(value, v)

    if v.type == 13 or v.type == 14 then
        for k,v in pairs(valueShow) do
            valueShow = v
            break
        end
    end
    local cashIcon = nil
    if CountryMode:GetCurrCountry() == 2 then
        cashIcon = "icon_cash_002"
    elseif CountryMode:GetCurrCountry() == 1 then
        cashIcon = "icon_cash_001"
    end
    if isNewNum then
        self:SetText(centGo, "num/num", valueShow)
        local cashImage = self:GetComp(centGo, "num/icon", "Image")
        if cashImage and cashIcon then
            self:SetSprite(cashImage, "UI_Main", cashIcon)
        end
        ----2024-10-18 fy 策划需求修改双倍效果调整：设置动画机状态
        if v.type == 3 then
            local normalShow = ShopManager:SetValueToShow(normalDiamondNum, v)
            local doubleShow = ShopManager:SetValueToShow(doubleDiamondNum, v)
            self:SetText(centGo, "num/num", normalShow)
            self:SetText(centGo, "num/doubleNum", doubleShow)
        end
    else
        self:SetText(centGo, "num", valueShow)
    end

    self:SetSprite(self:GetComp(centGo, "icon", "Image"), "UI_Shop", v.icon)


    local btn = nil
    local btnDiamond = self:GetComp(centGo, "dBtn", "Button")
    local btnCash = self:GetComp(centGo, "mBtn", "Button")
    local btnAd = self:GetComp(centGo, "aBtn", "Button")

    btnDiamond.gameObject:SetActive(v.diamond ~= nil)
    btnCash.gameObject:SetActive(v.iap_id ~= nil)
    btnAd.gameObject:SetActive(v.adTime ~= nil)

    local btn = btnDiamond
    if v.iap_id then
        btn = btnCash
    elseif v.adTime then
        btn = btnAd
    end
    if data.id == 1094 then
        local stopFlag = 0
    end
    local amountEnough = ShopManager:CheckBuyTimes(data.id, data.amount)--起名不太好,和shop表的amount一样了,实际上是另外的,表示数量限制的    
    btn.interactable = amountEnough
    
    if v.iap_id then
        local price = Shop:GetShopItemPrice(v.id)
        local priceOriginal, priceNum, comma = IAP:GetPriceDouble(v.id)
        local trackPrice = Shop:GetShopItemPrice(v.id, true)--美元单位
        local discount = IntroduceUI:GetDiscountByShopId(v.id)
        if discount <= 0 then
            discount = 0
        end
        self:SetText(centGo ,"content/offvalue/num", math.floor(discount * 100) .. "%" .. "\n" .. "Off")

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
            --cheatPrice = string.format("%.2f", cheatPrice)  --保留两位小数
            -- if comma ~= "." then
            --     cheatPrice = string.gsub(cheatPrice, '%.', ',')
            -- end
            -- if priceNumFormat then
            --     cheatPrice = string.gsub(price, priceNumFormat, cheatPrice)
            -- end
            if priceNum then
                local isHaveUSDSymbol = string.find(priceOriginal, "%$")
                local head = string.gsub(priceOriginal,"%p","")
                head = string.gsub(head,"%d","")
                local back = ""
                
                local cheatPriceInt = math.floor( cheatPrice )
                local cheatPriceStr = tostring(cheatPriceInt)
                local digitDiff = #cheatPriceStr - #priceNum
                back = cheatPriceStr
                if comma then
                    for k,v in pairs(comma) do 
                        local front = string.sub(back, 1, k +digitDiff -1 )
                        local after = string.sub(back, k +digitDiff -1 +1)
        
                        back = front..v..after
                    end
                end
                if isHaveUSDSymbol then
                    cheatPrice = head.."$"..back
                else
                    cheatPrice = head..back
                end
            else
                cheatPrice = priceOriginal
            end
           
        end
        -- if UnityHelper.IsRuassionVersion() then
        --     --针对俄区新支付所的修改
        --     cheatPrice = string.gsub(string.gsub(cheatPrice, ",", " "), "₽", "₽ ")
        -- end 
        self:SetText(btn.gameObject, "common", cheatPrice)
        self:SetText(btn.gameObject, "text", price)
        --GameSDKs:TrackForeign("store", {operation_type = 0, product_id = IAP:GetPurchaseId(v.iap_id), pay_type = 1, cost_num = trackPrice})
        -- 瓦瑞尔要求"ad_view"和"purchase" state为0事件不上传了2022-10-13
        -- GameSDKs:TrackForeign("purchase", {product_id = IAP:GetPurchaseId(v.iap_id), price = trackPrice, state = 0})

        self:SetButtonClickHandler(btn, function()
            btn.interactable = false
            if v.type == 12 and v.param3[1] == 1 then--新手礼包
                local canBuy = ShopManager:canBuyNewGift(v.id)
                if not canBuy then
                    --TODO:提示礼包已过期
                    return
                end
            end           
            if rootData.info then
                self:ShowItemDetails(rootData, v, valueShow)
            else
                -- GameSDKs:Track("store_show", {goods_id = IAP:GetPurchaseId(v.iap_id), goods_type = ShopManager:TypeToName(v.type)})
                -- GameSDKs:TrackForeign("purchase", {product_id = IAP:GetPurchaseId(v.iap_id), price = trackPrice, state = 1}) -- 挪至 CreateShopItemOrder内部
                GameSDKs:TrackForeign("store", {source = 1, operation_type = 1, product_id = IAP:GetPurchaseId(v.iap_id), pay_type = 1, cost_num_new = tonumber(trackPrice) or 0})
                --local infoData = {icon = v.icon, value = value, typeIcon = rootData.icon, type = type, txt = rootData.name}
                Shop:CreateShopItemOrder(data.id, btn, 1)
                -- EventManager:RegEvent("EVENT_EDIT_BUY", function(iapId)
                --     local purchaseId = IAP:GetPurchaseId(iapId)
                --     Shop:BuySuccess(purchaseId)
                -- end);
                -- if UnityHelper.OnlyEventOnEdit ~= nil then
                --     UnityHelper.OnlyEventOnEdit("EVENT_EDIT_BUY", v.iap_id)
                -- end
            end
        end)
    elseif v.diamond then
        --self:SetText(centGo, "BuyBtn/text", Tools:SeparateNumberWithComma(v.diamond))
        self:SetText(btn.gameObject, "text", Tools:SeparateNumberWithComma(v.diamond))
        --GameSDKs:TrackForeign("store", {operation_type = 0, product_id = data.id, pay_type = 3, cost_num = v.diamond})

        self:SetButtonClickHandler(btn, function()
            if rootData.info then
                -- GameSDKs:Track("store_show", {goods_id = data.id, goods_type = ShopManager:TypeToName(type)})
                self:ShowItemDetails(rootData, v, valueShow)
            else
                local canBuy,value,type = ShopManager:Buy(data.id, true)
                local infoData = {icon = data.icon, value = value, typeIcon = rootData.icon, type = type, txt = rootData.name}
                GameSDKs:TrackForeign("store", {source = 1, operation_type = 1, product_id = data.id, pay_type = 3, cost_num_new = tonumber(data.diamond) or 0})
                if canBuy then
                    ShopManager:Buy(data.id, false, function()
                        ShopUI:SuccessBuyAfter(data.id)
                    end,function()
                        ShopUI:SuccessBuyBefor(data.id)
                    end
                    )    
                else
                    GameSDKs:TrackForeign("store", {source = 1, operation_type = 3, product_id = IAP:GetPurchaseId(data.diamond), pay_type = 3, cost_num_new = tonumber(data.diamond) or 0})
                    --跳转到钻石购买界面
                    ShopUI:OpenAndTurnPage(1000)
                    --self.m_list:ScrollTo(2, 5)
                end
            end
        end)
    elseif v.adTime then
        local btnText = v.adTime
        local adEnough = ShopManager:SpendADTime(true, v.adTime)
        if not amountEnough then
            btnText = GameTextLoader:ReadText("TXT_BTN_CLAIMED")
        end

        self:GetGo(btn.gameObject, "icon"):SetActive(amountEnough)
        self:GetGo(btn.gameObject, "text"):SetActive(amountEnough)
        self:GetGo(btn.gameObject, "bought"):SetActive(not amountEnough)

        self:SetText(btn.gameObject, "text", btnText)
        btn.interactable = adEnough and amountEnough

        self:SetButtonClickHandler(btn, function()
            if rootData.info then
                self:ShowItemDetails(rootData, v, valueShow)
            else
                local canBuy,value,type = ShopManager:Buy(data.id, true)
                local infoData = {icon = data.icon, value = value, typeIcon = rootData.icon, type = type, txt = rootData.name}
                if canBuy then
                    ShopManager:Buy(data.id, false, function()
                        ShopUI:SuccessBuyAfter(data.id)
                    end,function()
                        ShopUI:SuccessBuyBefor(data.id)
                    end
                    )
    
                else
                    EventManager:DispatchEvent("UI_NOTE", "多看广告吧")
                end
            end
        end)
    end
end

function ShopUIView:SuccessBuyAfter(shopID)
    self.m_list:UpdateData(true)
    self:RefreshDiamond()
    self:RefreshCash()
    self:RefreshAdTime()
    if self.curBuyCEOKeyType then
        self:ShowBuyCEOKeyOpen(self.curBuyCEOKeyType, nil, true)
    end
end

function ShopUIView:CloseItemDetaild(closeNow)
    if closeNow then
        if self.m_detailsItemGo and #self.m_detailsItemGo > 0 then
            for i,go in ipairs(self.m_detailsItemGo) do
                go:SetActive(false)
            end
        end
        self.m_detailsItemGo = nil
        self.m_frame1InfoGo:SetActive(false)
        return
    end
    local feel = self:GetGo(self.m_frame1InfoGo, "closeFeedback")
    FeelUtil.PlayFeel(feel, "shopDetailClose")
end

EventManager:RegEvent("shopDetailClose", function()
    ShopUI:GetView():Invoke("CloseItemDetaild", true)
end)

function ShopUIView:ShowItemDetails(rootData, data, valueShow)--公司经验,现金等的详细详细
    --显示商品的详细详细,感觉有些写得不是很好,有时间重新改一下,有很多重复的代码
    self.m_frame1InfoGo:SetActive(true)
    local feel = self:GetComp(self.m_frame1InfoGo, "openFeedback", "MMFeedbacks")
    FeelUtil.PlayFeel(feel.gameObject)

    self:SetSprite(self:GetComp(self.m_frame1InfoGo, "info/content/bg/time/icon", "Image"), "UI_Shop", data.icon)
    self:SetText(self.m_frame1InfoGo, "info/content/bg/time/bg/num", Tools:SeparateNumberWithComma(data.amount))

    local isPetSnacks = data.type == 18 -- 宠物零食
    local itemInfo = {{icon = data.icon, num = valueShow}}
    if isPetSnacks then
        local id = data.param[1] or 1001
        local cfg = ConfigMgr.config_snack[id]
        itemInfo = {
            {icon = "icon_pet_hunger", num = "+" .. Tools:SeparateNumberWithComma(cfg.hunger_add)},
            {icon = "ui_sprit_level_rise", num = "+" .. cfg.exp_add / 100 + ConfigMgr.config_global.pet_exp_basespeed.. "%"},
            {icon = "icon_time", num = "+" .. math.floor((cfg.exp_duration / 60)) .. "min" },
        }
        self:SetText(self.m_frame1InfoGo, "info/content/bg/income/title", GameTextLoader:ReadText("TXT_MISC_SNACK_EFFECT"))
    else
        self:SetText(self.m_frame1InfoGo, "info/content/bg/income/title", GameTextLoader:ReadText("TXT_SHOP_DETAIL_INFO"))
    end

    self.m_detailsItemGo = {}
    local parent = self:GetTrans("info/content/bg/income/bg")
    local tmp = {icon = self:GetTrans("info/content/bg/income/bg/icon1"), num = self:GetTrans("info/content/bg/income/bg/num1")}
    local GetCurGo = function(name, i)
        local trans = i == 1 and tmp[name] or self:GetTrans("info/content/bg/income/bg/" .. name ..i)
        if not trans then
            trans = GameObject.Instantiate(tmp[name], parent)
            trans.name = name ..i
        end
        local go = trans.gameObject
        go:SetActive(true)
        table.insert(self.m_detailsItemGo, go)
        return go
    end
    for i,v in ipairs(itemInfo or {}) do
        local iconGo = GetCurGo("icon", i)
        local numGo = GetCurGo("num", i)
        self:SetSprite(iconGo:GetComponent("Image"), "UI_Shop", v.icon)
        numGo:GetComponent("TextMeshProUGUI").text = v.num
    end

    if rootData.name then
        self:SetText(self.m_frame1InfoGo, "title/txt", GameTextLoader:ReadText(rootData.name))
    end
    local btn = self:GetComp(self.m_frame1InfoGo, "info/content/bg/income/BuyBtn", "Button")

    if data.diamond then
        self:SetText(self.m_frame1InfoGo, "info/content/bg/income/BuyBtn/text", Tools:SeparateNumberWithComma(data.diamond))
        local canBuy,value,type = ShopManager:Buy(data.id, true)

        local infoData = {icon = data.icon, value = value, typeIcon = rootData.icon, type = type, txt = rootData.name}
        self:SetButtonClickHandler(btn, function()
            btn.interactable = false
            GameSDKs:TrackForeign("store", {source = 1, operation_type = 1, product_id = data.id, pay_type = 3, cost_num_new = tonumber(data.diamond) or 0})
            self:CloseItemDetaild()
            if canBuy then
                ShopManager:Buy(data.id, false, function()
                    btn.interactable = true
                    ShopUI:SuccessBuyAfter(data.id)
                end,function()
                    ShopUI:SuccessBuyBefor(data.id)
                end
                )
            else
                GameSDKs:TrackForeign("store", {source = 1, operation_type = 3, product_id = data.id, pay_type = 3, cost_num_new = tonumber(data.diamond) or 0})
                ShopUI:OpenAndTurnPage(1000)
                btn.interactable = true
            end
        end)
    elseif data.iap_id then--目前不会出现这个情况
        self:SetButtonClickHandler(btn, function()
            local purchaseId = IAP:GetPurchaseId(data.iap_id)
            local price = Shop:GetShopItemPrice(data.id, true)
            -- GameSDKs:Track("store_show", {goods_id = purchaseId, goods_type = ShopManager:TypeToName(type)})
            -- GameSDKs:TrackForeign("purchase", {product_id = purchaseId, price = price, state = 1}) -- 挪至 CreateShopItemOrder内部
            GameSDKs:TrackForeign("store", {source = 1, operation_type = 1, product_id = purchaseId, pay_type = 1, cost_num_new = tonumber(price) or 0})
            self:CloseItemDetaild()
            Shop:CreateShopItemOrder(data.id, btn, 1)
            
            EventManager:RegEvent("EVENT_EDIT_BUY", function(iapId)
                local purchaseId = IAP:GetPurchaseId(iapId)
                Shop:BuySuccess(purchaseId)
            end);
            if GameDeviceManager:IsEditor() then
                EventManager:DispatchEvent("EVENT_EDIT_BUY", v.iap_id)
            end
        end)
    elseif data.adTime then

    end

end



function ShopUIView:ShowPurchaseSucessGo(data)
    self.m_purchaseSucessGo:SetActive(true)
    self:SetSprite(self:GetComp("RootPanel/purchase_sucess/sale/icon", "Image"), "UI_Shop", data.icon)
    self:SetSprite(self:GetComp("RootPanel/purchase_sucess/reward/income/icon", "Image"), "UI_Shop", data.icon)
    self:SetText("RootPanel/purchase_sucess/reward/income/num", Tools:SeparateNumberWithComma(data.amount))
end

function ShopUIView:ShowList(data, refresh)
    self:CleanTimer()
    self.m_data = data
    if refresh then
        self.m_dataSize = {}
        --self:RefreshNaviga()
    end
    self.m_list:UpdateData(true)
    self:InitNavigationButtons()
    self:ShowFragmentTip()
    
end

function ShopUIView:TurnPage(index, isCEOTurn)
    if self.__timers["TurnPage"] then
        GameTimer:StopTimer(self.__timers["TurnPage"])
        self.__timers["TurnPage"] = nil
    end
    self.__timers["TurnPage"] = GameTimer:CreateNewTimer(0.5, function()--wait list init
        self.m_list:ScrollTo(index or 0, 3)
        if isCEOTurn then
            self.firstNaviToCEO = true
        end
    end)
end

function ShopUIView:TurnTo(index, closeCb)
    if self.__timers["TurnTo"] then
        GameTimer:StopTimer(self.__timers["TurnTo"])
        self.__timers["TurnTo"] = nil
    end
    self.closeCallBack = closeCb
    self.__timers["TurnTo"] = GameTimer:CreateNewTimer(0.5, function()--wait list init
        self.m_list:ScrollTo(index, 3)
    end)
end

---跳转到购买钻石的位置，要显示两排钻石
function ShopUIView:TurnToBuyDiamond(index, closeCb)
    if self.__timers["TurnTo"] then
        GameTimer:StopTimer(self.__timers["TurnTo"])
        self.__timers["TurnTo"] = nil
    end
    self.closeCallBack = closeCb
    self.__timers["TurnTo"] = GameTimer:CreateNewTimer(0.1, function()--wait list init

        local diamondFameRect = self.m_list:GetItemRect(index)
        if diamondFameRect.yMin ~=0 then
            local contentPos = self.m_list.content.anchoredPosition
            local minY = diamondFameRect.yMin + self.m_list.viewport.rect.height
            contentPos.y = -minY
            self.m_list:ScrollToPos(contentPos)
            return
        end

        self.m_list:ScrollTo(index, 3)

        --local diamondFameTrans = self.m_list:GetScrollItemTranByIndex(index)
        --if diamondFameTrans and not diamondFameTrans:IsNull() then
        --    local go4 = self:GetGoOrNil(diamondFameTrans.gameObject,"sale/temp_4")
        --    if go4 then
        --        local contentPos = self.m_list.content.anchoredPosition
        --        local minY = go4.transform.rect.minY
        --        contentPos.y = minY
        --        --self.m_list:ScrollToPos
        --    end
        --end
    end)
end

function ShopUIView:InitNavigationButtons()
    local tempBtn = self:GetGo("RootPanel/IndexPanel/btn_temp")
    tempBtn:SetActive(false)

    local root = self:GetTrans("RootPanel/IndexPanel")

    local currData = nil
    local currGo = nil
    for i = 1, 20 do
        currData = self.m_data[i]
        if currData then
            currGo = self:GetGoOrNil(root.gameObject, i .. "")
            if currGo == nil then
                currGo = GameObject.Instantiate(tempBtn, root)
                currGo.name = i
            end
            currGo:SetActive(true)
            self:SetSprite(self:GetComp(currGo, "icon", "Image"), "UI_Shop", currData.icon)
            self:SetButtonClickHandler(currGo:GetComponent("Button"), function()
                if self.m_data[i].frame == "frameCEOChest" then
                    if not self.firstNaviToCEO then
                        self.m_list:ScrollTo(i - 1, 3)
                        self.firstNaviToCEO = true
                    else
                        self.m_list:ScrollTo(i - 1, 3)
                    end
                    GameSDKs:TrackForeign("ceo_exposure", {type = "商城ceo页签点击"})
                else
                    self.m_list:ScrollTo(i - 1, 3)
                end
            end)
            --判断钻石和facebook是否有免费图标
            if currData.name == "TXT_SHOP_DIAMOND" then
                local freeIconDisp = false
                local curRecord = LocalDataManager:GetCurrentRecord()
                if ShopUI:RewardDiamondCD() <= 0 then
                    freeIconDisp = true
                end
                if curRecord then
                    if not curRecord.getFollowDiamond or curRecord.getFollowDiamond == 0 then
                        freeIconDisp = true
                    end
                end
                local freeIconGo = self:GetGoOrNil(currGo, "free_icon")
                
                if freeIconGo then
                    freeIconGo:SetActive(freeIconDisp)
                end
            end
            if currData.frame == "frameCEOChest" then
                local state, icon = GameTableDefine.CEODataManager:CheckCEOBoxCanUse()
                self:GetGo(currGo, "chest"):SetActive(state > 0)
                self:SetSprite(self:GetComp(currGo, "chest/icon", "Image"), "UI_Shop", icon)
                local freeIconGo = self:GetGoOrNil(currGo, "free_icon")
                if freeIconGo then
                    freeIconGo:SetActive(false)
                end
            else
                local chestGO = self:GetGoOrNil(currGo, "chest")
                if chestGO and chestGO.activeInHierarchy then
                    chestGO:SetActive(false)
                end
            end
        else
            currGo = self:GetGoOrNil(root.gameObject, i .. "")
            if currGo then
                currGo:SetActive(false)
            else
                break
            end
        end
    end
end

--[[
    @desc: 过滤地区商品显示的内容，用于列表刷新显示
    author:{author}
    time:2022-10-21 18:27:54
    --@data: 
    @return:
]]
function ShopUIView:FilterContryShopData(data)
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
-- function ShopUIView:SuccessBuy(shopId, shopFrameData)--{showValue, type} --在完成购买级数之前调用
--     local root = self:GetGo("RootPanel/purchase_sucess")
--     root:SetActive(true)
--     local openFeel = self:GetGo(root, "PurchaseFeedback")
--     local closeFeel = self:GetGo(root, "CloseFeedback")
--     local allType = {"income", "offline", "mood", "exp", "cash", "diamond", "ad", "monthd"}
--     local value,typeName = ShopManager:GetValueByShopId(shopId)
--     local cfg = ShopManager:GetCfg(shopId)
--     local showValue = ShopManager:SetValueToShow(value, cfg)

--     local allShow = {}
--     local data = {}

--     local data = {}

--     if cfg.type ~= 12 then
--         data.icon = cfg.icon
--         data.show = showValue
--         data.name = cfg.name
--         data.typeName = typeName
--         table.insert(allShow, data)
--     else
--         local allParam = cfg.param
--         local currCfg = nil
--         local backDiamond = 0
--         for k,v in pairs(allParam) do
--             currCfg = ShopManager:GetCfg(v)
--             if ShopManager:CheckBuyTimes(v) then--还可以购买
--                 value,typeName = ShopManager:GetValueByShopId(v)
--                 showValue = ShopManager:SetValueToShow(value, currCfg)
--                 data = {}
--                 data.icon = currCfg.icon
--                 data.name = currCfg.name
--                 data.typeName = typeName
--                 data.show = showValue
--                 table.insert(allShow, data)
--             else--无法购买了,补偿钻石
--                 if currCfg.type == 13 or currCfg.type == 14 then--宠物,保安
--                     backDiamond = backDiamond + currCfg.param2[1]
--                 else--功能npc
--                     backDiamond = backDiamond + currCfg.param[1]
--                 end
--             end
--             -- currCfg = ShopManager:GetCfg(v)
--             -- value,typeName = ShopManager:GetValueByShopId(v)
--             -- showValue = ShopManager:SetValueToShow(value, currCfg)
--             -- data = {}
--             -- data.icon = currCfg.icon
--             -- data.name = currCfg.name
--             -- data.typeName = typeName
--             -- data.show = showValue
--             -- table.insert(allShow, data)
--         end

--         if backDiamond > 0 then
--             data = {}
--             data.icon = "icon_shop_diamond_3"
--             data.name = "TXT_SHOP_COMPENSATE"
--             data.typeName = "diamond"
--             data.show = Tools:SeparateNumberWithComma(backDiamond)
--             ResourceManger:AddDiamond(backDiamond, nil, nil, true)
--             GameSDKs:Track("get_diamond", {get = backDiamond, left = ResMgr:GetDiamond(), get_way = "重复购买补偿"})
--             GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "重复购买补偿", behaviour = 1, num = backDiamond})

--             table.insert(allShow, data)
--         end
--     end

--     self.successData = allShow
--     local showSuccess = nil
--     showSuccess = function()
--         local currData = self.successData[1]
--         if currData == nil then
--             return
--         end

--         local closeBtn = self:GetComp(root, "bg", "Button")
--         if self.successData[2] == nil then--结束后关闭节点       
--             EventManager:RegEvent("purchase_success_close", function()
--                 MainUI:UpdateResourceUI()
--                 root:SetActive(false)
--                 EventManager:UnregEvent("purchase_success_close")
--             end)
    
--             self:SetButtonClickHandler(closeBtn, function()
--                 FeelUtil.PlayFeel(closeFeel, "purchase_success_close")
--             end)
--         else--结束后播放下一个
--             self:SetButtonClickHandler(closeBtn, function()
--                 table.remove(self.successData, 1)
--                 EventManager:RegEvent("purchase_success_close", function()
--                     if showSuccess then showSuccess() end
--                 end)
--                 FeelUtil.PlayFeel(closeFeel, "purchase_success_close")
--             end)
--         end

--         local icon = self:GetComp(root, "sale/icon", "Image")
--         self:SetSprite(icon, "UI_Shop", currData.icon)

--         self:SetText(root, "reward/title/text", GameTextLoader:ReadText(shopFrameData.name))

--         local currType = currData.typeName

--         local rewardRoot = self:GetGo(root, "reward")
--         for k,v in pairs(allType) do
--             self:GetGo(rewardRoot, v):SetActive(currType == v)
--         end

--         if currType ~= "pet" and currType ~= "emplo" then
--             local currRoot = self:GetGo(rewardRoot, currType)
--             self:SetText(currRoot, "num", currData.show)
--         else
--             local currRoot = nil
--             for k,v in pairs(currData.show) do
--                 currRoot = self:GetGo(rewardRoot, k)
--                 currRoot:SetActive(true)
--                 self:SetText(currRoot, "num", v)
--             end
--         end
--         FeelUtil.PlayFeel(openFeel)
--     end

--     showSuccess()
-- end
--[[
    @desc: 刷新facebook的状态
    author:{author}
    time:2024-01-22 10:55:03
    --@isGetFollowDiamond:
	--@facebookGo: 
    @return:
]]
function ShopUIView:RefreshFacebookStateDisp(isGetFollowDiamond, facebookGo)
    local claimedGO = self:GetGoOrNil(facebookGo, "temp/Claimed")
    if claimedGO then
        claimedGO:SetActive(isGetFollowDiamond)
    end
    local tipsGo = self:GetGoOrNil(facebookGo, "temp/GoBtn/icon")
    if tipsGo then
        tipsGo:SetActive(not isGetFollowDiamond)
    end
    if isGetFollowDiamond then
        self:InitNavigationButtons()
        self:RefreshDiamond()
        MainUI:UpdateResourceUI()
    end
    MainUI:RefreshDiamondShop()
end

function ShopUIView:ShowFragmentTip()
    if self.__timers["fragmentTip"] then
        GameTimer:StopTimer(self.__timers["fragmentTip"])
        self.__timers["fragmentTip"] = nil
    end
    self.__timers["fragmentTip"] = GameTimer:CreateNewTimer(1, function()--wait list init
        local value, endTime = GameTableDefine.FragmentActivityUI:GetTimeRemaining()
        self:GetGo("RootPanel/activity_banner"):SetActive(value>0)
        local fragmentCfg = ConfigMgr.config_activity[1008]
        self:SetText("RootPanel/activity_banner/bg/bg/num", fragmentCfg.count)
    end, true, true)
end

--[[
    @desc: 打开CEO宝箱系统的说明内容
    author:{author}
    time:2025-02-17 17:06:02
    @return:
]]
function ShopUIView:ShowCEOChestSysTip()
    local panelGo = self:GetGo("RootPanel/HelpInfo_ceo")
    panelGo:SetActive(true)
    self:SetButtonClickHandler(self:GetComp(panelGo, "", "Button"), function()
        panelGo:SetActive(false)
    end)
    GameSDKs:TrackForeign("ceo_exposure", {type = "ceo提示界面开启"})
end

--[[
    @desc: 打开具体箱子的说明内容
    author:{author}
    time:2025-02-17 17:06:23
    --@boxType: 
    @return:
]]
function ShopUIView:ShowCEOChestOpenTip(boxType)
    local panelGo = self:GetGo("RootPanel/frameCEO_boxView")
    local listGo = self:GetGo("RootPanel/frameCEO_boxView/info/res")
    self:SetButtonClickHandler(self:GetComp("RootPanel/frameCEO_boxView/bg", "Button"), function()
        panelGo:SetActive(false)
    end)
    for i = 0, listGo.transform.childCount - 1 do
        listGo.transform:GetChild(i).gameObject:SetActive(false)
    end
    local chestCfg = ConfigMgr.config_ceo_chest[boxType]
    if chestCfg then
        for index, rewardItemStr in pairs(Tools:SplitString(chestCfg.chest_content, ",")) do
            local dispGo = nil
            if index >= listGo.transform.childCount then
                dispGo = GameObject.Instantiate(listGo.transform:GetChild(0).gameObject, listGo.transform)
            end
        end
        panelGo:SetActive(true)
        self:SetText(panelGo, "info/title/txt", GameTextLoader:ReadText(chestCfg.chest_name))
        for index, rewardItemStr in pairs(Tools:SplitString(chestCfg.chest_content, ",")) do
            local dispGo = listGo.transform:GetChild(index - 1).gameObject
            if dispGo then
                dispGo:SetActive(true)
                local itemData = Tools:SplitString(rewardItemStr, ":", true)
                local shopCfg = ConfigMgr.config_shop[itemData[1]]
                if shopCfg then
                    self:GetGo(dispGo, "tipBtn"):SetActive(shopCfg.type == 44)
                    self:SetSprite(self:GetComp(dispGo, "icon", "Image"), "UI_Shop", shopCfg.icon)
                    self:SetText(dispGo, "bg/num", itemData[2])
                    if shopCfg.type == 44 then
                        self:SetButtonClickHandler(self:GetComp(dispGo, "tipBtn", "Button"), function()
                            GameTableDefine.CEOChestPreviewUI:OpenChestPreview(shopCfg.param[1])
                        end)
                    end
                end
            end
        end
    end
end

--[[
    @desc: 打开多个宝箱开启的界面
    author:{author}
    time:2025-02-18 17:54:23
    --@boxType: 
    @return:
]]
function ShopUIView:ShowMoreCEOBoxOpen(boxType, cb)
    local keyIcon = "icon_ceo_key_"..boxType
    local panelGo = self:GetGo("RootPanel/frameCEO_moreOpen")
    
    self:SetButtonClickHandler(self:GetComp("RootPanel/frameCEO_moreOpen/bg", "Button"), function()
        if cb then
            cb()
        end
        panelGo:SetActive(false)
    end)
    local curBoxCfg = ConfigMgr.config_ceo_chest[boxType]
    local needKeyCfg = 0
    local curKeys = GameTableDefine.CEODataManager:GetCurKeys(boxType)
    local maxBoxNum = 0
    if curBoxCfg then
        local keyRequireStrs = curBoxCfg.chest_key_require
        if "normal" == boxType or "premium" == boxType then
            local tmpStrs = Tools:SplitString(keyRequireStrs, ":")
            needKeyCfg = tonumber(tmpStrs[2])
        end
        if needKeyCfg > 0 then
            maxBoxNum = math.floor(curKeys / needKeyCfg)
        end
        if maxBoxNum > 10 then
            maxBoxNum = 10
        end
        self:SetText("RootPanel/frameCEO_moreOpen/info/title/txt", GameTextLoader:ReadText(curBoxCfg.chest_name))
        self:SetSprite(self:GetComp("RootPanel/frameCEO_moreOpen/info/content/bg/chest/icon", "Image"), "UI_Shop", curBoxCfg.chest_icon)
        self:SetSprite(self:GetComp("RootPanel/frameCEO_moreOpen/info/content/bg/ratio/boxIcons/icon", "Image"), "UI_Shop", curBoxCfg.chest_icon)
        self:SetSprite(self:GetComp("RootPanel/frameCEO_moreOpen/info/content/bg/ratio/keyIcons/icon", "Image"), "UI_Shop", keyIcon)
        self:SetSprite(self:GetComp("RootPanel/frameCEO_moreOpen/info/content/bg/keys/icon", "Image"), "UI_Shop", keyIcon)
        self:SetText("RootPanel/frameCEO_moreOpen/info/content/bg/ratio/keyNum", tostring(needKeyCfg))
        self:SetText("RootPanel/frameCEO_moreOpen/info/content/bg/keys/num", tostring(curKeys))
        self:SetText("RootPanel/frameCEO_moreOpen/info/content/bg/btnMore/num", tostring(maxBoxNum))
    end
    self:SetButtonClickHandler(self:GetComp("RootPanel/frameCEO_moreOpen/info/content/bg/btnOne", "Button"), function()
        GameTableDefine.CEODataManager:OpenCEOBox(boxType, 1, true, cb,4)
        panelGo:SetActive(false)
        self:RefreshDiamond()
     end)

     self:SetButtonClickHandler(self:GetComp("RootPanel/frameCEO_moreOpen/info/content/bg/btnMore", "Button"), function()
        GameTableDefine.CEODataManager:OpenCEOBox(boxType, maxBoxNum, true, cb,4)
        panelGo:SetActive(false)
        self:RefreshDiamond()
     end)
    panelGo:SetActive(true)
end

function ShopUIView:ShowBuyCEOKeyOpen(boxType, cb, isBuy)
    self.curBuyCEOKeyType = boxType
    local isBuyClick = isBuy or false
    local keyIcon = "icon_ceo_key_"..boxType
    local panelGo = self:GetGo("RootPanel/frameCEO_buyKey")
    if not GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
        panelGo:SetActive(false)
        return
    end
    self:SetButtonClickHandler(self:GetComp("RootPanel/frameCEO_buyKey/info/main/quitBtn", "Button"), function()
        -- if cb and not isBuyClick then
        --     cb()
        -- end
        if not isBuyClick then
            self.m_list:UpdateData(true)
        else
            local scrollIndex = -1
            for i, v in pairs(self.m_data) do
                if v.frame == "frameCEOChest" then
                    scrollIndex = i - 1
                    break
                end
            end
            if scrollIndex >= 0 then
                self.m_list:ScrollTo(scrollIndex, 3)
            end
        end    
        self.curBuyCEOKeyType = nil
        panelGo:SetActive(false)
    end)
    panelGo:SetActive(true)
    local keyBundleCfg = ConfigMgr.config_ceo_keybundle[boxType]
    if not keyBundleCfg then
        return
    end
    --step1.设置主要的内容
    local mainShopCfg = ConfigMgr.config_shop[keyBundleCfg.main_content]
    if mainShopCfg and mainShopCfg.iap_id then
        self:SetText("info/main/title/txt", GameTextLoader:ReadText(keyBundleCfg.key_name))
        self:SetSprite(self:GetComp(panelGo, "info/main/content/bg/key/icon", "Image"), "UI_Shop", mainShopCfg.icon)
        self:SetText("info/main/content/bg/countBg/num", mainShopCfg.amount)
        --TODO:设置价格和绑定购买的设置
        local mainPrice = Shop:GetShopItemPrice(mainShopCfg.id)
        self:SetText("info/main/content/mBtn/text", mainPrice)
        local mainMBtn = self:GetComp("info/main/content/mBtn", "Button")
        mainMBtn.interactable = true
        self:SetButtonClickHandler(mainMBtn, function()
            mainMBtn.interactable = false
            isBuyClick = true
            Shop:CreateShopItemOrder(mainShopCfg.id, mainMBtn, 1)
        end)
    end
    local packageGo = self:GetGo(panelGo, "info/pack")
    local curPackageChildCount = packageGo.transform.childCount
    for i = 0, curPackageChildCount - 1 do
        packageGo.transform:GetChild(i).gameObject:SetActive(false)
    end
    local tmpGo = self:GetGo("info/pack/temp")
    for i = 1, Tools:GetTableSize(keyBundleCfg.pack_content) do
        local packShopCfg = ConfigMgr.config_shop[keyBundleCfg.pack_content[i]]
        local dispGo = nil
        local offValue = keyBundleCfg.pack_offvalue[i] * 100
        if i - 1 < curPackageChildCount then
            dispGo = packageGo.transform:GetChild(i - 1).gameObject
        else
            dispGo = GameObject.Instantiate(tmpGo, packageGo.transform)
        end
        dispGo:SetActive(true)
        for i = 0, dispGo.transform.childCount - 1 do
            dispGo.transform:GetChild(i).gameObject:SetActive(false)
        end
        local curDispGo = self:GetGo(dispGo, "bg_"..tostring(packShopCfg.param[1]))
        curDispGo:SetActive(true)
        if packShopCfg and packShopCfg.iap_id then
            self:SetText(curDispGo, "title/txt", GameTextLoader:ReadText(packShopCfg.name))
            local realPrice = Shop:GetShopItemPrice(packShopCfg.id)
            local priceOriginal, priceNum, comma = IAP:GetPriceDouble(packShopCfg.id)
            local trackPrice = Shop:GetShopItemPrice(packShopCfg.id, true)
            local discount = keyBundleCfg.pack_offvalue[i]
            local cheatPrice = 0
            if discount <= 0 then
                discount = 0
            end
            local offPrice = "0"
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
                    local isHaveUSDSymbol = string.find(priceOriginal, "%$")
                    local head = string.gsub(priceOriginal, "%p", "")
                    head = string.gsub(head, "%d", "")
                    local back = ""
                    local cheatPriceInt = math.floor( cheatPrice )
                    local cheatPriceStr = tostring(cheatPriceInt)
                    local digitDiff = #cheatPriceStr - #priceNum
                    back = cheatPriceStr
                    if comma then
                        for k,v in pairs(comma) do 
                            local front = string.sub(back, 1, k +digitDiff -1 )
                            local after = string.sub(back, k +digitDiff -1 +1)
            
                            back = front..v..after
                        end
                    end
                    if isHaveUSDSymbol then
                        cheatPrice = head.."$"..back
                    else
                        cheatPrice = head..back
                    end
                else
                    cheatPrice = priceOriginal
                end
            end
            local itemsParentGo = self:GetGo(curDispGo, "content/product")
            local itemTmpGo = self:GetGo(itemsParentGo, "item")
            local itemTmpPlus = self:GetGo(itemsParentGo, "+")
            local curItemChildCount = itemsParentGo.transform.childCount
            -- local itemDataCount = Tools:GetTableSize(packShopCfg.param)
            local itemDataCount = 1
            --需要重新拆分显示效果的内容
            if packShopCfg.param2[1] and tonumber(packShopCfg.param2[1]) then
                itemDataCount = tonumber(packShopCfg.param2[1])
            end
            self:SetText(curDispGo, "off/text", tostring(math.floor(offValue)).."%")
            self:SetText(curDispGo, "content/mBtn/txt", realPrice)
            self:SetText(curDispGo, "content/mBtn/common", cheatPrice)
            local mBtn = self:GetComp(curDispGo, "content/mBtn", "Button")
            mBtn.interactable = true
            self:SetButtonClickHandler(mBtn, function()
                mBtn.interactable  = false
                isBuyClick = true
                Shop:CreateShopItemOrder(packShopCfg.id, mBtn, 1)
            end)
            for i = 1, curItemChildCount do 
                itemsParentGo.transform:GetChild(i-1).gameObject:SetActive(i <= itemDataCount - 1)
            end
            for i = 1, itemDataCount do
                -- local itemShopCfg = ConfigMgr.config_shop[tonumber(packShopCfg.param[i])]
                local itemGo = nil
                local plusGo = nil
                if i == 1 then
                    itemGo = itemTmpGo
                else
                    local itemGoIndex = math.floor(i / 2) + i
                    local itemPlusIndex  = itemGoIndex - 1
                    if itemPlusIndex >= curItemChildCount then
                        plusGo = GameObject.Instantiate(itemTmpPlus, itemsParentGo.transform)
                    else
                        plusGo = itemsParentGo.transform:GetChild(itemPlusIndex).gameObject
                    end
                    
                    if itemGoIndex >= curItemChildCount then
                        itemGo = GameObject.Instantiate(itemTmpGo, itemsParentGo.transform)
                    else
                        itemGo = itemsParentGo.transform:GetChild(itemGoIndex).gameObject
                    end
                    
                end
                if plusGo then
                    plusGo:SetActive(true)
                end
                if itemGo then
                    itemGo:SetActive(true)
                    self:SetText(itemGo, "countBg/num", tostring(math.floor(packShopCfg.amount/itemDataCount)))
                    self:SetSprite(self:GetComp(itemGo, "icon", "Image"), "UI_Shop", packShopCfg.icon)
                end
            end
        end
    end
end

function ShopUIView:GetCEOChest2KeyBtn()
    for i = 1, 20 do
        local currData = self.m_data[i]
        if currData then
            if currData.frame == "frameCEOChest" then
                local trans = self.m_list:GetScrollItem(i-1)
                return self:GetComp(trans.gameObject,"sale/temp_2/kBtn","Button")
            end
        end
    end
end

function ShopUIView:GetCEOHelpTipsBtn()
    for i = 1, 20 do
        local currData = self.m_data[i]
        if currData then
            if currData.frame == "frameCEOChest" then
                local trans = self.m_list:GetScrollItem(i - 1)
                return self:GetComp(trans.gameObject, "title/tipsBtn", "Button")
            end
        end
    end
end

function ShopUIView:GetCEOChestFrameGO()
    for i = 1, 20 do
        local currData = self.m_data[i]
        if currData then
            if currData.frame == "frameCEOChest" then
                self.m_list:ScrollTo(i-1)
                local trans = self.m_list:GetScrollItem(i-1)
                local go = self:GetGo(trans.gameObject,"title")
                return go
            end
        end
    end
end

function ShopUIView:GetGo(obj, child)
    if obj == "GetCEOChestFrameGO" then
        return self:GetCEOChestFrameGO()
    else
        return self:getSuper(ShopUIView).GetGo(self,obj, child)
    end
end

function ShopUIView:GetComp(obj, child, uiType)
    if obj == "GetCEOChest2KeyBtn" then
        return self:GetCEOChest2KeyBtn()
    elseif obj == "GetCEOHelpTipsBtn" then
        return self:GetCEOHelpTipsBtn()
    else
        return self:getSuper(ShopUIView).GetComp(self,obj, child,uiType)
    end
end

return ShopUIView