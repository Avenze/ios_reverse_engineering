local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local GameUIManager = GameTableDefine.GameUIManager
local Event001UI = GameTableDefine.Event001UI
local MainUI = GameTableDefine.MainUI
local ChooseUI = GameTableDefine.ChooseUI

local Event001UIView = Class("Event001UIView", UIView)


function Event001UIView:ctor()
    self.super:ctor()
    self.container = {}
end

function Event001UIView:OnEnter()
    --GameSDKs:Track("ad_button_show", {video_id = 10003, video_namne = GameSDKs:GetAdName(10003)})
    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10003, state = 0, revenue = 0})

    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/QuitBtn", "Button"), function()
        Event001UI:ClaimResource(self.m_eventId, false)
        self:DestroyModeUIObject()
    end)
    local adBtn = self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button", "Button")
    self:SetButtonClickHandler(adBtn, function()
        local addValue,_ = Event001UI:GetReward(self.m_eventId)

        local success = function()
            adBtn.interactable = false
            local pos = self:GetTrans("RootPanel/MidPanel/ConfirmBtn/Button").position
            Event001UI:ClaimResource(self.m_eventId, true, function()
                EventManager:DispatchEvent("FLY_ICON", pos, 2, addValue)
                MainUI:RefreshQuestHint()
                self:DestroyModeUIObject()
            end,
            function()
                if adBtn then
                    adBtn.interactable = true
                end
            end,
            function()
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
                if adBtn then
                    adBtn.interactable = true
                end
            end)
        end
        ChooseUI:EarnCash(addValue, success)
    end)

    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
    btnNoAD.gameObject:SetActive(GameConfig:IsIAP() and not GameTableDefine.ShopManager:IsNoAD())
    self:SetButtonClickHandler(btnNoAD, function()
        GameTableDefine.ShopUI:OpenAndTurnPage(1009)
    end)
end

function Event001UIView:OnPause()
    print("Event001UIView:OnPause")
end

function Event001UIView:OnResume()
    print("Event001UIView:OnResume")
end

function Event001UIView:OnExit()
    self.super:OnExit(self)
    print("Event001UIView:OnExit")
end

function Event001UIView:ShowPanel(eventId, totalRent, reward)
    local showText = GameTextLoader:ReadText("TXT_EVENT_EFFICIENCY_001")
    showText = string.format(showText, totalRent)
    self:SetText("RootPanel/MidPanel/event/efficiency", showText)
    self:SetText("RootPanel/MidPanel/event/reward/num", "+" .. Tools:SeparateNumberWithComma(reward))
    local img = self:GetComp("RootPanel/MidPanel/event/reward/icon", "Image")
    -- eventId 1 绿钞 5 黄钞（欧元）
    self.m_eventId = eventId
     self:SetSprite(img, "UI_Main", eventId == 1 and "icon_cash_001" or "icon_cash_002")
end

return Event001UIView