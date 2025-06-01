local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper;

local GameUIManager = GameTableDefine.GameUIManager

local UIDemoView = Class("UIDemoView", UIView)

function UIDemoView:ctor()
    self.super:ctor()
end

function UIDemoView:Preoad()
end

function UIDemoView:OnEnter()
    print("UIDemoView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
   
    self:InitToggle()
    self:InitTabView()
    self:InitList()
end

function UIDemoView:OnPause()
    print("UIDemoView:OnPause")
end

function UIDemoView:OnResume()
    print("UIDemoView:OnResume")
end

function UIDemoView:OnExit()
    self.super:OnExit(self)
    print("UIDemoView:OnExit")
end

function UIDemoView:InitToggle()
    local panels = {}
    for i=1,3 do
        local panelGo = self:GetGo("RootPanel/Panel"..i)
        panelGo:SetActive(false)
        panels[i] = panelGo
    end
    for k,v in pairs(self:GetTrans("RootPanel/Toggle") or {}) do
        local curIdx = k
        local toggle =  v.gameObject:GetComponent("Toggle")
        self:SetToggleValueChangeHandler(toggle, function(isOn)
            panels[curIdx + 1]:SetActive(isOn)
            if isOn then
                self.m_curToggle = curIdx
                print("--->cur select toggle:", curIdx)
            end
        end)
    end
end

function UIDemoView:InitTabView()
    local tabView = self:GetComp("RootPanel/Panel1", "TabView")
    local panelTab = { self:GetGo("RootPanel/Panel1/PanelTab0"), self:GetGo("RootPanel/Panel1/PanelTab1")}
    panelTab[1]:SetActive(false)
    panelTab[2]:SetActive(false)
    --tabView:SwitchtoTab(0)
    tabView:SetUpdateFunc(function(index, tran)
        self.m_tabIndex = index + 1
        panelTab[1]:SetActive(self.m_tabIndex == 1)
        panelTab[2]:SetActive(self.m_tabIndex == 2)
    end)
end


local m_data = {
    {name = "Item8"},
    {name = "Item3"},
    {name = "Item4"},
    {name = "Item5"},
    {name = "Item6"},
    {name = "Item7"},
    {name = "Item1"},
    {name = "Item2"},
    -- {name = "Item1"},
    -- {name = "Item2"},
    -- {name = "Item1"},
    -- {name = "Item2"},
    -- {name = "Item1"},
    -- {name = "Item2"},
    -- {name = "Item1"},
    -- {name = "Item2"},
}

function UIDemoView:InitList()
    local list = self:GetComp("RootPanel/Panel1/PanelTab0/List", "ScrollRectEx")
    self:SetListItemCountFunc(list, function ()
        return #m_data
    end)

    self:SetListItemNameFunc(list, function (index)
        return m_data[index + 1].name
    end)
    self:SetListUpdateFunc(list, function (index, tran)
        local go = tran.gameObject
        --self:SetText(go, "textIndex","index:"..index)
        if index == 1 then
            self:InitSlider(go)
        elseif index == 2 then
            local switch = self:GetComp(go, "Switch", "Toggle")
            self:SetToggleValueChangeHandler(switch, function(isOn)
                print("--->switch state:", isOn and "on" or "off")
                self:SetText(go, "State",isOn and "ON" or "OFF")

            end)
        elseif index == 3 then
            local bar = self:GetComp(go, "CircBar", "Image")
            self:InitCircBar(bar)
        elseif index == 4 then
            local gameObjects = {}
            for i=1,5 do
                gameObjects[i] = self:GetGo(go, "MultiSelect"..i)
            end
            self:InitCheckBox(gameObjects)
        elseif index == 5 then
            local button = self:GetComp(go, "Button2", "Button")
            button.interactable = false
        elseif index == 0 then
            --widget, hint, isGreen, hideText
            self:SetWidgetHint(self:GetGo(go, "HindDot1"), 1, self.HINT_GREEN, true)
            self:SetWidgetHint(self:GetGo(go, "HindDot2"), 1, self.HINT_GREEN, false)
            
            self:SetWidgetHint(self:GetGo(go, "HindDot3"), 22, self.HINT_RED, true)
            self:SetWidgetHint(self:GetGo(go, "HindDot4"), 22, self.HINT_RED, false)

            self:SetWidgetHint(self:GetGo(go, "HindDot5"), 33, self.HINT_BLUE, true)
            self:SetWidgetHint(self:GetGo(go, "HindDot6"), 33, self.HINT_BLUE, false)
        end
    end)
    list:UpdateData()
end

function UIDemoView:InitSlider(go)
    local slider = self:GetComp(go, "Slider", "Slider")
    local input = self:GetComp(go, "NumInput", "TMP_InputField")
    slider.maxValue = 1000
    slider.minValue = 1
    
    local OnSliderValueChangeHandler = function(value, byInput)
        value = math.ceil(value)
        slider:SetValueWithoutNotify(value)
        input:SetTextWithoutNotify(value)
    end
    local InputValueChangeHandler = function(str)
        local currentValue = tonumber(str)
        if currentValue == nil then
            currentValue = slider.minValue
        end
        currentValue = math.min(math.max(currentValue, slider.minValue), slider.maxValue)
        OnSliderValueChangeHandler(currentValue)
    end
    self:SetSliderValueChangeHandler(slider, OnSliderValueChangeHandler)
    self:SetTMPInputValueChangeHandler(input, InputValueChangeHandler)
end

function UIDemoView:InitCircBar(bar)
    if self.m_bar == bar then
        return 
    end

    if not self.m_bar then
        self.m_bar = bar
        self.m_barProcess = 0
    end

    self:CreateTimer(100, function( )
        self.m_barProcess = self.m_barProcess + 0.01
        if self.m_barProcess > 1 then
            self.m_barProcess = 0
        end
        self.m_bar.fillAmount = self.m_barProcess
    end, true, true)
end

function UIDemoView:InitCheckBox(go)
    for k,v in pairs(go) do
        local normalGo = self:GetGo(v, "Normal")
        local clickGo = self:GetGo(v, "Click")
        normalGo:SetActive(true)
        clickGo:SetActive(false)
        self:SetButtonClickHandler(self:GetComp(v, "Button", "Button"), function()
            normalGo:SetActive(not normalGo.activeSelf)
            clickGo:SetActive(not clickGo.activeSelf)
        end)
    end
end

------floor
function UIDemoView:SetRoomId(id)
    self.m_roomID = id
    print("=====> click room id:", self.m_roomID)
end

function UIDemoView:InitRoomInfo(m_data)
    local list = self:GetComp("RootPanel/Panel1/PanelTab1/List", "ScrollRectEx")
    self:SetListItemCountFunc(list, function ()
        return math.ceil(#m_data / 2)
    end)
    self:SetListUpdateFunc(list, function (index, tran)
        local go = tran.gameObject
        for i=1,2 do
            local itemIndex = index * 2 + i
            local itemGo = self:GetGo(go, "i"..i)
            local itemData = m_data[itemIndex]
            itemGo:SetActive(itemData ~= nil)
            if itemData then
                self:SetWidgetHint(itemGo, itemData.hint, self.HINT_READ)
            end
        end
    end)
    list:UpdateData()
end

return UIDemoView