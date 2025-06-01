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
local Event004UI = GameTableDefine.Event004UI
local MainUI = GameTableDefine.MainUI

local Event004UIView = Class("Event004UIView", UIView)


function Event004UIView:ctor()
    self.super:ctor()
    self.container = {}
end

function Event004UIView:OnEnter()
    --GameSDKs:Track("ad_button_show", {video_id = 10009, video_namne = GameSDKs:GetAdName(10009)})
    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10009, state = 0, revenue = 0})
    
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/QuitBtn", "Button"), function()
        Event004UI:ClaimResource(self.eventId, false)
        self:DestroyModeUIObject()
    end)

    local adBtn = self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button", "Button")
    self:SetButtonClickHandler(adBtn, function()
        local pos = self:GetTrans("RootPanel/MidPanel/ConfirmBtn/Button").position
        adBtn.interactable = false
        Event004UI:ClaimResource(self.eventId, true, function()
            EventManager:DispatchEvent("FLY_ICON", pos,
                3, Event004UI:GetReward(self.eventId))
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

function Event004UIView:OnPause()
    print("Event004UIView:OnPause")
end

function Event004UIView:OnResume()
    print("Event004UIView:OnResume")
end

function Event004UIView:OnExit()
    self.super:OnExit(self)
    print("Event004UIView:OnExit")
end

function Event004UIView:ShowPanel(id, reward)
    self.eventId = id
    self:SetText("RootPanel/MidPanel/event/reward/num", "+" .. reward)
end

return Event004UIView