local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ConfigMgr = GameTableDefine.ConfigMgr
local ExchangeUI = GameTableDefine.ExchangeUI
local ResMgr = GameTableDefine.ResourceManger
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local GameClockManager = GameTableDefine.GameClockManager
local ExchangeUIView = Class("ExchangeUIView", UIView)

function ExchangeUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ExchangeUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/head/quit_btn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/down/bg/overviewBtn", "Button"), function()
        self:RefreshOverView()
    end)
    self:CreateTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/head/time", currH..":"..currM)
    end, true, true)
    self:Init()
end

function ExchangeUIView:OnExit()
	self.super:OnExit(self)
    self:StopTimer()
end

function ExchangeUIView:Init()
    self.moneyCfg = ConfigMgr.config_money    
    self.spendDropDown = self:GetComp("RootPanel/exchange_page/bg/transfer/Dropdown", "TMP_Dropdown")
    self.addDropDown = self:GetComp("RootPanel/exchange_page/bg/recevies/Dropdown", "TMP_Dropdown")
    self.slider = self:GetComp("RootPanel/exchange_page/bg/value/Slider", "Slider")
    self.slider.value = 0     
    self.spendNum = 0
    self.addNum = 0
    self.surpluNum = 0    
    self:RefreshNum(self.slider.value)
    self:SetDropDown(self.spendDropDown)
    self:SetDropDown(self.addDropDown)
    self.spendDropDown.value = 0
    self.addDropDown.value = 1
    self:RefreshExchangeCurrencyTxt()
    
    --self:SetDropdownText(self.spendDropDown, 2, names[2])
    local skinName = "head_" .. LocalDataManager:GetBossSkin()    
    local currImage = nil    
    currImage = self:GetComp("RootPanel/head/head/inner", "Image")
    self:SetSprite(currImage, "UI_BG", skinName)

    UnityHelper.SetDropdownValueChangeHandler(self.spendDropDown, function()
        if self.spendDropDown.value == self.addDropDown.value then
            self.addDropDown.value = ExchangeUI:MutexId(self.spendDropDown.value + 1) - 1
        end
        self.slider.value = 0
        self:RefreshExchangeCurrencyTxt()
        self:RefreshNum(self.slider.value)
    end)
    UnityHelper.SetDropdownValueChangeHandler(self.addDropDown, function()
        if self.addDropDown.value == self.spendDropDown.value then
            self.spendDropDown.value = ExchangeUI:MutexId(self.addDropDown.value + 1) - 1
        end
        self.slider.value = 0
        self:RefreshExchangeCurrencyTxt()
        self:RefreshNum(self.slider.value)
    end)
    UnityHelper.SetSliderValueChangeHandler(self.slider, function()    
       self:RefreshNum(self.slider.value)
    end)
    self:SetButtonClickHandler(self:GetComp("RootPanel/exchange_page/bg/confirmBtn","Button"), function()      
        ResMgr:Spend(self.moneyCfg[self.spendDropDown.value + 1].resourceId, self.spendNum , nil, function(isEnough)
            if isEnough then
                --消耗钞票
                local controyCode = 1
                if self.moneyCfg[self.spendDropDown.value + 1].resourceId == 6 then
                    controyCode = 2
                end
                GameSDKs:TrackForeign("cash_event", {type_new = tonumber(controyCode), change_new = 1, amount_new = tonumber(self.spendNum) or 0, position = "货币兑换(玩家进行手机银行的货币兑换时)"})
                ResMgr:Add(self.moneyCfg[self.addDropDown.value + 1].resourceId, self.addNum, nil, function(isEnough) 
                    if isEnough then
                        if self.spendDropDown.value ~= self.addDropDown.value then
                            ExchangeUI:AddCumulativeValue(self.moneyCfg[self.spendDropDown.value + 1].resourceId, self.spendNum)
                            ExchangeUI:SpendCumulativeValue(self.moneyCfg[self.addDropDown.value + 1].resourceId, self.addNum)
                        end
                        EventManager:DispatchEvent("CASH_SPEND")
                        --获得钞票
                        local addCountry = 1
                        if controyCode == 1 then
                            addCountry = 2
                        end
                        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(addCountry), change_new = 0, amount_new = tonumber(self.addNum) or 0, position = "货币兑换(玩家进行手机银行的货币兑换时)"})
                        self.slider.value = 0                                                                      
                        self:RefreshNum(self.slider.value)
                        
                                                                      
                    end
                end)
            end
        end)
    end)      
end

-- 设置DropDown的文字
function ExchangeUIView:SetDropDown(DropDown)
    for k,v in pairs(self.moneyCfg) do
        self:SetDropdownText(DropDown, v.id, GameTextLoader:ReadText("TXT_MONEY_" .. k))        
    end
end

function ExchangeUIView:RefreshNum(value)
    self.surpluNum, self.addNum = ExchangeUI:CalculateExchangeCurrency(self.spendDropDown.value + 1, self.addDropDown.value + 1, value)
    self.spendNum = (ResMgr:Get(self.moneyCfg[self.spendDropDown.value + 1].resourceId) - self.surpluNum)
    --ResMgr:Get(self.moneyCfg[self.spendDropDown.value + 1].resourceId)
    self:RefreshExchangeCurrencyTxt()
    self:SetText("RootPanel/exchange_page/bg/transfer/bg_numb/txt_numb", self.surpluNum)  
    self:SetText("RootPanel/exchange_page/bg/recevies/bg_numb/txt_numb", self.addNum)
    self:SetText("RootPanel/exchange_page/bg/value/Slider/Handle Slide Area/Handle/img_msg/txt_msg", math.floor(self.slider.value * 100) .. "%")
end

--刷新比例
function ExchangeUIView:RefreshExchangeCurrencyTxt()
    local currency = ExchangeUI:CurrencyProportion(self.spendDropDown.value + 1, self.addDropDown.value + 1, self.spendNum)
    currency = string.format("%.5f",currency)
    self:SetText("RootPanel/exchange_page/bg/rate/num", currency)    
end

--刷新初始化饼状图
function ExchangeUIView:RefreshOverView()
    self:SetTempGo("RootPanel/overview_page/bg_01/icon_01", function(index, go, allCash)
        self:SetTemp(index, go, allCash)
    end)
    
    self:SetTempGo("RootPanel/overview_page/bg_02/item", function(index, go, allCash)
        self:SetNumTemp(index, go, allCash)
    end)
    self:SetTempGo("RootPanel/overview_page/bg_01/txt/item", function(index, go, allCash)
        self:SetNameTemp(index, go, allCash)
    end)
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function ExchangeUIView:SetTempGo(path , cb)    
    local temp = self:GetGo(path)
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    local allCash = ExchangeUI:GetAllCashNum()
    for i = 1, 5 do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        local cfg = self.moneyCfg[i]
        go.name = "temp" .. i
        go:SetActive(true)
        if not cfg then
            go:SetActive(false)
        else
            cb(i, go, allCash)
        end                                      
    end          
end

--对单个饼状图temp进行设置
function ExchangeUIView:SetTemp(index, go, allCash)    
    local image = self:GetComp(go, "", "Image")
    image.color = UnityHelper.GetColor("#" .. self.moneyCfg[index].color)
    local alreadyHave = 0
    if index == 1 then
        image.fillAmount = 1
        return
    end
    for i = 1, index - 1 do
        alreadyHave = alreadyHave + ResMgr:Get(self.moneyCfg[i].resourceId)
    end
    image.fillAmount = 1 - alreadyHave / allCash        
end

--对单个数量temp进行设置
function ExchangeUIView:SetNumTemp(index, go, allCash)  
    self:SetText(go, "numb", Tools:SeparateNumberWithComma(ResMgr:Get(self.moneyCfg[index].resourceId)))
    self:SetText(go, "name", GameTextLoader:ReadText("TXT_MONEY_" .. index))
    local iocn = self:GetComp(go, "icon_money", "Image")
    self:SetSprite(iocn, "UI_Main", "icon_cash_00" .. index)
end

--对名字单独设置
function ExchangeUIView:SetNameTemp(index, go, allCash)  
    local icon = self:GetComp(go, "icon_point", "Image")
    icon.color = UnityHelper.GetColor("#" .. self.moneyCfg[index].color)
    self:SetText(go, "name", GameTextLoader:ReadText("TXT_MONEY_" .. index))
end

return ExchangeUIView