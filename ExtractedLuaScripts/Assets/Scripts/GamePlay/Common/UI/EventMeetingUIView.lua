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
local EventMeetingUI = GameTableDefine.EventMeetingUI
local MainUI = GameTableDefine.MainUI

local EventMeetingUIView = Class("EventMeetingUIView", UIView)


function EventMeetingUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function EventMeetingUIView:OnEnter()
    --GameSDKs:Track("ad_button_show", {video_id = 10008, video_namne = GameSDKs:GetAdName(10008)})
    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10008, state = 0, revenue = 0})

    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/QuitBtn", "Button"), function()
        EventMeetingUI:FinishEvent(false)
        self:DestroyModeUIObject()
    end)

    local adBtn = self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button", "Button")
    self:SetButtonClickHandler(adBtn, function()
        adBtn.interactable = false
        EventMeetingUI:FinishEvent(true, function()
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
    end)

    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
    btnNoAD.gameObject:SetActive(GameConfig:IsIAP() and not GameTableDefine.ShopManager:IsNoAD())
    self:SetButtonClickHandler(btnNoAD, function()
        GameTableDefine.ShopUI:OpenAndTurnPage(1009)
    end)
end

function EventMeetingUIView:OnPause()
    print("EventMeetingUIView:OnPause")
end

function EventMeetingUIView:OnResume()
    print("EventMeetingUIView:OnResume")
end

function EventMeetingUIView:OnExit()
    self.super:OnExit(self)
    print("EventMeetingUIView:OnExit")
end

function EventMeetingUIView:ShowPanel(num)
    --local showText = GameTextLoader:ReadText("TXT_EVENT_EFFICIENCY_001")
    --showText = string.format(showText, totalRent)
    --self:SetText("RootPanel/MidPanel/event/efficiency", showText)
    self:SetText("RootPanel/MidPanel/event/reward/num", "+" .. num)
end

return EventMeetingUIView