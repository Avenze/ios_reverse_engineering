local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local TimerMgr = GameTimeManager
local CfgMgr = GameTableDefine.ConfigMgr
local OrderUI = GameTableDefine.OrderUI
local ActivityUI = GameTableDefine.ActivityUI
local MainUI = GameTableDefine.MainUI
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local ResourceManger = GameTableDefine.ResourceManger
local FactoryMode = GameTableDefine.FactoryMode
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local OrderUIView = Class("OrderUIView", UIView)

function OrderUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_cfgOrder = CfgMgr.config_order
    self.m_orderData = OrderUI:GetOrderData()
    self.m_cfgProducts = CfgMgr.config_products
    --self.m_ProductsData = WorkShopInfoUI:GetProductsData()
end

function OrderUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)

    --用于新手引导的订单只生成一次  
    if not self.m_orderData or Tools:GetTableSize(self.m_orderData) == 0 then
        self.m_orderData["1"] = {}
        self.m_orderData["1"].num = 1
        self.m_orderData["1"].productsId = 1 
        self.m_orderData["1"].timePoint = TimerMgr:GetCurrentServerTime(true)
        self.m_selectedProduct = 1
        WorkShopInfoUI:AddProduct(1, 1)
        LocalDataManager:WriteToFile()
    end
    OrderUI:GenerateOrders()
    --设置订单Item
    local SetItem = function () 
        self.m_list = self:GetComp("RootPanel/orderPanel/order", "ScrollRectEx")
        local index = 0
    
        for k, v in pairs(self.m_orderData) do
            if type(v) == "table" then
                index = index + 1
            end
        end
        --设置List的数量
        self:SetListItemCountFunc(self.m_list, function()
            return Tools:GetTableSize(self.m_cfgOrder)
        end)
        --设置List中的Item的类型
        self:SetListItemNameFunc(
            self.m_list,
            function(index)
                return "Item"
            end
        )
        --设置List中的Item的具体内容
        self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateCompanyCollect))    
    end
    SetItem()
    
    self:refreshOrderUI()
end

function OrderUIView:refreshOrderUI()
    
    self.m_list:UpdateData()

    if self.m_selectedProduct == nil or self.m_orderData[tostring(self.m_selectedProduct)].timePoint > TimerMgr:GetCurrentServerTime(true) then
        for k, v in pairs(self.m_orderData) do
            if type(v) == "table" then
                if v.timePoint <= TimerMgr:GetCurrentServerTime(true) then
                    self.m_selectedProduct = tonumber(k)
                    break
                end
            end
        end    
    end

    local upperLimit = OrderUI:CalculateUpperLimit()
    local rewardBtn = self:GetComp("reward/bg", "Button")
    self:SetButtonClickHandler(rewardBtn, function()
        -- self:GetGo("reward"):SetActive(false)
        self:refreshOrderUI()
    end)
    --完成订单的累计时,发放奖励
    if not self.m_orderData["completionsNum"] then
        self.m_orderData["completionsNum"] = 0
    end
    if upperLimit <= self.m_orderData["completionsNum"] then
        --加许可证
        ResourceManger:AddLicense(
            1,
            nil,
            function()
                --总累加值,用于计算许可证发放
                if not self.m_orderData["total"] then
                    self.m_orderData["total"] = 0
                end
                self.m_orderData["total"] = self.m_orderData["total"] + 1

                --打开奖励页面
                self:GetGo("reward"):SetActive(true)

                --清空累计值
                self.m_orderData["completionsNum"] = 0
                --播放动画
                -- local feel = self:GetComp("reward/PurchaseFeedback", "MMFeedbacks")
                -- if feel then
                --     feel:PlayFeedbacks()
                -- end
            end,
            true
        )
        self:refreshOrderUI()
        --刷新MainUI显示
        MainUI:RefreshLicenseState()
    end
    self:SetText("RootPanel/orderPanel/title/license/num", ResourceManger:GetLicense())
    --没有办法生成订单时
    if self.m_selectedProduct == nil then
        self:GetGo("RootPanel/orderPanel/bottom/detail/null"):SetActive(true)
        return
    else
        self:GetGo("RootPanel/orderPanel/bottom/detail/null"):SetActive(false)
    end

    local productsId = self.m_orderData[tostring(self.m_selectedProduct)]["productsId"]

    local Root = self:GetGo("RootPanel/orderPanel/bottom/detail")
    local Image = self:GetComp(Root, "need/icon", "Image")
    local Slider = self:GetComp(Root, "count/bg/prog", "Slider")

    Slider.value = self.m_orderData["completionsNum"] / upperLimit
    self:SetText(Root, "count/bg/num", self.m_orderData["completionsNum"] .. "/" .. upperLimit)
    self:SetSprite(Image, "UI_Common", self.m_cfgProducts[productsId]["icon"])
    self:SetText(Root, "need/name", GameTextLoader:ReadText(self.m_cfgProducts[productsId]["name"]))

    local productNum = WorkShopInfoUI:GetProductNum(productsId)
    if productNum >= self.m_orderData[tostring(self.m_selectedProduct)]["num"] then
       self:SetText(Root, "need/need", "<color=#0AA859>" .. productNum .. "</color>" .. "/" .. self.m_orderData[tostring(self.m_selectedProduct)]["num"])
    else
        self:SetText(Root, "need/need", productNum .. "/" .. self.m_orderData[tostring(self.m_selectedProduct)]["num"])
    end
    --if not self.m_ProductsData[tostring(productsId)] then
    --    self.m_ProductsData[tostring(productsId)] = 0
    --end
    --if self.m_ProductsData[tostring(productsId)] >= self.m_orderData[tostring(self.m_selectedProduct)]["num"] then
    --   self:SetText(Root, "need/need", "<color=#0AA859>" .. self.m_ProductsData[tostring(productsId)] .. "</color>" .. "/" .. self.m_orderData[tostring(self.m_selectedProduct)]["num"])
    --else
    --    self:SetText(Root, "need/need", self.m_ProductsData[tostring(productsId)] .. "/" .. self.m_orderData[tostring(self.m_selectedProduct)]["num"])
    --end
    
    local finishBtn = self:GetComp(Root, "reward/startBtn", "Button")
    --订单需求的数量
    local orderNum = self.m_orderData[tostring(self.m_selectedProduct)]["num"]
    --仓库有的数量
    finishBtn.interactable = self.m_selectedProduct and OrderUI:CheckOrderFinish(self.m_orderData[tostring(self.m_selectedProduct)])
    --完成订单的价值
    local awardNum = self.m_cfgProducts[productsId]["value"] * self.m_orderData[tostring(self.m_selectedProduct)]["num"]

    self:SetText(Root, "reward/cash/num", Tools:SeparateNumberWithComma(awardNum))

    self:SetButtonClickHandler(
        finishBtn,
        function()
            if not self.m_selectedProduct then
                return
            end
            --扣材料--
            if WorkShopInfoUI:SpendProduct(orderNum, productsId) then
                --给资源--
                ResourceManger:AddCash(
                    awardNum,
                    nil,
                    function()
                        EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)

                        --播放动画
                        FactoryMode:PlayOrderSendCarFB(self.m_selectedProduct)
                        --生成新订单
                        OrderUI:GenerateOrder(self.m_selectedProduct)
                        --订单进入CD--
                        self.m_orderData[tostring(self.m_selectedProduct)]["timePoint"] = TimerMgr:GetCurrentServerTime(true) + self.m_cfgOrder[self.m_selectedProduct]["cooltime"]
                        self.m_orderData[tostring(self.m_selectedProduct)].prohibit = nil
                        self.m_selectedProduct = nil
                        --加累计值--
                        if not self.m_orderData["completionsNum"] then
                            self.m_orderData["completionsNum"] = 0
                        end

                        self.m_orderData["completionsNum"] = self.m_orderData["completionsNum"] + 1
                        if not self.m_orderData["total_num"] then
                            self.m_orderData["total_num"] = 0
                        end
                        self.m_orderData["total_num"] = self.m_orderData["total_num"] + 1
                        EventManager:DispatchEvent("FACTORY_ORDER")
                        GameSDKs:Track("factory_order", {total_num_new = tonumber(self.m_orderData["total_num"]) or 0}) --订单完成时埋点
                        FactoryMode:CheckParkingLotBoxHint()
                        GameSDKs:TrackForeign("cash_event", {type_new = 1, change_new = 0, amount_new = tonumber(awardNum) or 0, position = "订单完成"})
                    end,
                    true,
                    true
                )
                self:refreshOrderUI()
                MainUI:RefreshFactorytips()
            end
        end
    )
    --取消订单按钮
    local cancelBtn = self:GetComp(Root, "reward/cancelBtn", "Button")
    self:SetButtonClickHandler(cancelBtn, function()
        --让订单进入CD
        if not self.m_selectedProduct or not self.m_orderData[tostring(self.m_selectedProduct)] then
            return
        end
        OrderUI:AddProductInProhibit(self.m_selectedProduct, productsId)
        OrderUI:GenerateOrder(self.m_selectedProduct)
        self.m_orderData[tostring(self.m_selectedProduct)]["timePoint"] = TimerMgr:GetCurrentServerTime(true) + self.m_cfgOrder[self.m_selectedProduct]["cooltime"]
        self.m_selectedProduct = nil
        FactoryMode:CheckParkingLotBoxHint()
        FactoryMode:HiddenSendCar()
        self:refreshOrderUI()
        MainUI:RefreshFactorytips()    
    end)    
end

--对单个Item进行一个设置,发生改变时自动遍历修改
function OrderUIView:UpdateCompanyCollect(index, tran)
    index = index + 1
    local go = tran.gameObject
    local Data = self.m_orderData[tostring(index)]
    self:GetGo(go, "unlockable"):SetActive(false)
    self:GetGo(go, "lock"):SetActive(false)
    if Data == nil then
        self:GetGo(go, "lock"):SetActive(true)
        if self.m_orderData[tostring(index - 1)] ~= nil or index == 1 then
            self:GetGo(go, "unlockable"):SetActive(true)
            self:GetGo(go, "lock"):SetActive(false)
            self:SetText(go, "unlockable/unlockBtn/cost",  Tools:SeparateNumberWithComma(self.m_cfgOrder[index].cost[2] or 0))
            local resNum = 0
            local path = "icon_cash_001"
            if self.m_cfgOrder[index].cost[1] == 2 then--现金
                path = "icon_cash_001"
                resNum = ResourceManger:GetCash()
            elseif self.m_cfgOrder[index].cost[1] == 3 then -- 钻石
                path = "icon_diamond_001"
                resNum = ResourceManger:GetDiamond()
            else
                
            end
            local icon = self:GetComp(go,"unlockable/unlockBtn/icon", "Image")
            self:SetSprite(icon, "UI_Main", path)
            local btnUnlock = self:GetComp(go, "unlockable/unlockBtn", "Button")
            btnUnlock.interactable = (resNum >= self.m_cfgOrder[index].cost[2])
            self:SetButtonClickHandler(btnUnlock, function()
                ResourceManger:Spend(self.m_cfgOrder[index].cost[1], self.m_cfgOrder[index].cost[2], nil, function(isEnough)
                    if isEnough then
                        OrderUI:GenerateOrder(index)
                        FactoryMode:PlayOrderCallCarFB(index)
                        FactoryMode:CheckParkingLotBoxHint()
                        self:refreshOrderUI()
                        MainUI:RefreshFactorytips()
                        if tonumber(self.m_cfgOrder[index].cost[1]) == 3 then 
                            GameSDKs:TrackForeign("virtual_currency", {currency_type = 2, pos = "工厂订单解锁", behaviour = 2, num_new = tonumber(self.m_cfgOrder[index].cost[2])})
                        end
                    end
                end)               
            end)
        end
        return
    end
    local completeCD = true
    if self.m_orderData[tostring(index)]["timePoint"] then
        completeCD = self.m_orderData[tostring(index)]["timePoint"] <= TimerMgr:GetCurrentServerTime(true)
    end
    self:GetGo(go, "normal"):SetActive(completeCD)
    self:GetGo(go, "wait"):SetActive(not completeCD)

    -- --订单需求的数量
    -- local orderNum = self.m_orderData[tostring(index)]["num"]
    -- --仓库有的数量
    -- local storehouseNum = self.m_ProductsData[tostring(Data["productsId"])]
    local canFinish = OrderUI:CheckOrderFinish(self.m_orderData[tostring(index)])
    self:GetGo(go, "normal/ready"):SetActive(canFinish)
    if completeCD then
        local Image = self:GetComp(go, "normal/icon", "Image")

        --local productId = Data["productsId"]

        self:SetSprite(Image, "UI_Common", self.m_cfgProducts[Data["productsId"]]["icon"])
        self:SetText(go, "normal/name", GameTextLoader:ReadText(self.m_cfgProducts[Data["productsId"]]["name"]))
        self:SetText(go, "normal/need/num", "x" .. Data["num"])

        if self.m_selectedProduct == index then
            self:GetGo(go, "normal/selected"):SetActive(true)
        else
            self:GetGo(go, "normal/selected"):SetActive(false)
        end
        local bgBtn = self:GetComp(go, "normal", "Button")
        self:SetButtonClickHandler(
            bgBtn,
            function()
                self.m_selectedProduct = index
                self:refreshOrderUI()
            end
        )
    else
        local timer = nil        
        if not self.timerList then
            self.timerList = {}
        end
        local spendDiameNum
        local skipBtn = self:GetComp(go, "wait/skipBtn", "Button")
        local diamondNeed = CfgMgr.config_global.skip_diamond or 1
        if not self.timerList or not self.timerList[index] then 
            timer = GameTimer:CreateNewTimer(1, function()
                local t = self.m_orderData[tostring(index)]["timePoint"] - TimerMgr:GetCurrentServerTime(true)
                
                if t >= 0 then
                    self:SetText(go, "wait/time", TimerMgr:FormatTimeLength(t))                                        
                    --每60秒需要多少钻石
                    spendDiameNum = diamondNeed * math.ceil(t / 60)
                    self:SetText(go, "wait/skipBtn/cost", spendDiameNum)                    
                else
                    --
                    GameTimer:StopTimer(timer)
                    if self.timerList and self.timerList[index] then                    
                        self.timerList[index] = nil
                    end
                    FactoryMode:PlayOrderCallCarFB(index)
                    self.m_orderData[tostring(index)]["timePoint"] = TimerMgr:GetCurrentServerTime(true)
                    MainUI:RefreshFactorytips()
                end
            end, true, true)
            self.timerList[index] = timer
        end
        self:SetButtonClickHandler(skipBtn,function()
            local spendDiameNum = diamondNeed * math.ceil((self.m_orderData[tostring(index)]["timePoint"] - TimerMgr:GetCurrentServerTime(true)) / 60)
            ResourceManger:SpendDiamond(spendDiameNum, nil, function(isEnough)
                if isEnough then
                    GameTimer:StopTimer(timer)
                    if self.timerList[index] then                    
                        self.timerList[index] = nil
                    end
                    self.m_orderData[tostring(index)]["timePoint"] = TimerMgr:GetCurrentServerTime(true)
                    OrderUI:GenerateOrder(index)
                    FactoryMode:PlayOrderCallCarFB(index)
                    self:refreshOrderUI()
                    MainUI:RefreshFactorytips()
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 2, pos = "工厂订单加速", behaviour = 2, num_new = tonumber(spendDiameNum)})
                end
            end)                                     
        end)        
    end
end

function OrderUIView:StopTimerList()
    if not self.timerList then
        return
    end
    for k,v in pairs(self.timerList) do
        GameTimer:StopTimer(v)        
    end
    self.timerList = nil
end

function OrderUIView:OnExit()
    self.super:OnExit(self)
    self:StopTimerList()
end

return OrderUIView
