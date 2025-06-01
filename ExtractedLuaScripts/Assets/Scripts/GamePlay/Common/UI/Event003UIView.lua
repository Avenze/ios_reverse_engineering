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
local Event003UI = GameTableDefine.Event003UI
local MainUI = GameTableDefine.MainUI

local Event003UIView = Class("Event003UIView", UIView)


function Event003UIView:ctor()
    self.super:ctor()
    self.container = {}
end

function Event003UIView:OnEnter()
    --GameSDKs:Track("ad_button_show", {video_id = 10006, video_namne = GameSDKs:GetAdName(10006)})
    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10006, state = 0, revenue = 0})

    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/QuitBtn", "Button"), function()
        Event003UI:ClaimResource(false)
        self:DestroyModeUIObject()
    end)
    local adBtn = self:GetComp("RootPanel/MidPanel/ConfirmBtn/Button", "Button")
    self:SetButtonClickHandler(adBtn, function()
        adBtn.interactable = false
        Event003UI:ClaimResource(true, function()
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

function Event003UIView:OnPause()
    print("Event003UIView:OnPause")
end

function Event003UIView:OnResume()
    print("Event003UIView:OnResume")
end

function Event003UIView:OnExit()
    self.super:OnExit(self)
    print("Event003UIView:OnExit")
end

function Event003UIView:ShowPanel()

end

return Event003UIView