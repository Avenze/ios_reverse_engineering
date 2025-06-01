local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")

local UnityHelper = CS.Common.Utils.UnityHelper
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local Button = CS.UnityEngine.UI.Button
local AnimationUtil = CS.Common.Utils.AnimationUtil;

local BuildingPopView = Class("BuildingPopView", UIView)

function BuildingPopView:ctor()
    self.super:ctor()
end

function BuildingPopView:OnEnter()
    print("BuildingPopView:OnEnter")
    self:Hide()
end

function BuildingPopView:OnPause()
    print("BuildingPopView:OnPause")
end

function BuildingPopView:OnResume()
    print("BuildingPopView:OnResume")
end

function BuildingPopView:OnExit()
    self.super:OnExit(self)

    print("Exit BuildingPopView")
end

function BuildingPopView:Init()
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(self.m_uiObj, "Entry2").gameObject, false)
    -- ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(self.m_uiObj, "Entry3").gameObject, false)
    -- ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(self.m_uiObj, "Entry4").gameObject, false)
    -- ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(self.m_uiObj, "Entry5").gameObject, false)

    -- ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(self.m_uiObj, "EffInvokeAcailable2").gameObject, false)
    -- ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(self.m_uiObj, "BuildingA").gameObject, false)
end

function BuildingPopView:Show(functionList, name, level, hintType, newBuildingIcon, newBuildingHintContent)
    local isFirstShow = not self.m_uiObj.activeSelf
    ViewUtils:SetGoVisibility(self.m_uiObj, true)
    self:Init()
    self:SetFunctions(functionList)

    -- local barGO = UnityHelper.FindTheChild(self.m_uiObj, "Bar").gameObject

    -- UnityHelper.GetTheChildComponent(barGO, "TxtName", "TMPLocalization").text = name
    -- UnityHelper.GetTheChildComponent(barGO, "TxtLevelInfo", "TMPLocalization").text = "Lv." .. level

    -- local anim = UnityHelper.GetTheChildComponent(self.m_uiObj, "FrameBody", "Animation")
    -- AnimationUtil.Play(anim, "UiEffWildPopIn", function()
    --     anim:Stop()
    --     if isFirstShow then
    --         self:SendGuideEvent(GameTableDefine.Guide.EVENT_VIEW_OPEND, self.m_guid, functionList[1].params.localPosID)
    --     end
    -- end)
    -- self:SetBottomGo(hintType, newBuildingIcon, newBuildingHintContent)
end

function BuildingPopView:Hide()
    ViewUtils:SetGoVisibility(self.m_uiObj, false)
    self:StopTimer()
end

function BuildingPopView:SetFunctions(functionList)
    local functionNum = #functionList

    local targetStateObj = UnityHelper.FindTheChild(self.m_uiObj, "Entry" .. functionNum).gameObject

    ViewUtils:SetGoVisibility(targetStateObj, true)

    for k, v in pairs(functionList) do
        local btnObj = UnityHelper.FindTheChild(targetStateObj, "BuidingBTN_" .. k).gameObject      
        ViewUtils:SetWidgetHint(btnObj, 0,false,true) 
        
        --local fgComp = self:GetComp("BuidingBtnAll","FrameGroup",btnObj) 
        --fgComp:SetFrameChangeFunc(
        --    function(firstChild)
                -- local firstChild = UnityHelper.GetFirstChild(fgComp.gameObject)
                self:SetButtonClickHandler(
                    btnObj:GetComponent("Button"),
                    function()
                        EventManager:DispatchEvent(v.cmd, v.params)
                    end
                )
                --self:SetButtonState(btnObj,firstChild.gameObject, v.name, v.value, v.status)
            --end
        --)
        --fgComp:SetFrameByName(v.name)
    end
end

function BuildingPopView:SetButtonState(btnObj,go, name, valueString, statusString)
   
    local valueList = LuaTools:SplitString(valueString or "", "@")
   
    if name == "btn_yield" then
        UnityHelper.GetTheChildComponent(go, "TxtNum", "TMPLocalization").text = valueList[3] or ""
    elseif name == "btn_yieldup2" then
        UnityHelper.GetTheChildComponent(go, "TxtNum", "TMPLocalization").text = valueList[1] or ""
        UnityHelper.GetTheChildComponent(go, "TxtBtn", "TMPLocalization").text = GameTextLoader:ReadText("LC_WORD_BOOST")
        UnityHelper.GetTheChildComponent(go, "TxtBtn2", "TMPLocalization").text = valueList[2] or ""
    elseif name == "btn_YieldedUp" then
        self.m_countdown = tonumber(valueList[2] or 0) or 0
        local cb = function()
            if self.m_countdown >= 0 then 
                UnityHelper.GetTheChildComponent(go, "TxtBtn2", "TMPLocalization").text = GameTimeManager:FormatTimeLength(self.m_countdown or 0)
            else
                self:StopTimer()
            end
            self.m_countdown = self.m_countdown - 1
        end
        self:SetTimer(cb)
    elseif name == "btn_exchange_res" then
    elseif name == "btn_training_volume" or name == "btn_creating_volume" then
        UnityHelper.GetTheChildComponent(go, "TxtBtn2", "TMPLocalization").text = valueList[1] or ""
        UnityHelper.GetTheChildComponent(go, "TxtBtn", "TMPLocalization").text = valueList[2] or ""
    elseif name == "btn_instantFinish"
        or name == "btn_instantFinish_2"    
        or name == "btn_instantFinish_3" then
        UnityHelper.GetTheChildComponent(go, "TxtBtn2", "TMPLocalization").text = valueList[1] or ""
        UnityHelper.GetTheChildComponent(go, "TxtBtn", "TMPLocalization").text = valueList[2] or GameTextLoader:ReadText("LC_WORD_SPEED_UP")
    end

    -- 设置红点和选中效果
    local hint = LuaTools:SplitString(statusString or "", ",")
    local effGO = UnityHelper.FindTheChild(btnObj, "EffIcon").gameObject 
    ViewUtils:SetGoVisibility(effGO, hint[1] == "1")    
    ViewUtils:SetWidgetHint(btnObj, tonumber(hint[2]or 0),false,true) 
     ---
end

function BuildingPopView:SetTimer(cb)
    if self.m_countdown > 0 then
        self:StopTimer()
        self:CreateTimer(1000, cb, true, true)
    end
end

function BuildingPopView:SetBottomGo(hintType, newBuildingIcon, newBuildingHintContent)
    local bottomGo = UnityHelper.FindTheChild(self.m_uiObj, "BuildingA").gameObject
    if hintType == 0 then
        bottomGo:SetActive(true)
        GameTableDefine.SoundEngine:playEffect(SoundConst.SFX_OFFICER_SET)
        self:GetGo("State2", bottomGo).gameObject:SetActive(false)
        self:GetGo("State1", bottomGo).gameObject:SetActive(true)

        self:GetComp("State1/IconScenarioAll", "FrameGroup", bottomGo):SetFrameByName(newBuildingIcon)
        self:SetText("State1/TxtBuildingHint", newBuildingHintContent, bottomGo)
        self:SetButtonClickHandler(self:GetComp("State1/BtnTouch", "Button", bottomGo), function()
            GameTableDefine.GameMainCity:GetClickNewTentBottonHint()
        end)
    elseif hintType == 1 then
        bottomGo:SetActive(true)
        self:GetGo("State2", bottomGo).gameObject:SetActive(true)
        self:GetGo("State1", bottomGo).gameObject:SetActive(false)
        self:SetText("State2/TxtNum", newBuildingHintContent, bottomGo)
    end
end

return BuildingPopView
