local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ResMgr = GameTableDefine.ResourceManger

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local DoubleRewardUIView = Class("DoubleRewardUIView", UIView)

function DoubleRewardUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function DoubleRewardUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function DoubleRewardUIView:OnExit()
    self.super:OnExit(self)
end

function DoubleRewardUIView:Show(cb, allReward)
    if allReward[2] then
        self:SetText("RootPanel/SelectPanel/benefit/2/num", "+"..allReward[2])
        self:SetSprite(self:GetComp("RootPanel/SelectPanel/benefit/2/icon", "Image"), "UI_Common", ResMgr:GetResIcon(2))

        self:SetText("RootPanel/SelectPanel/reward/2/num", "+"..allReward[2])
        --self:SetSprite(self:GetComp("RootPanel/SelectPanel/reward/2/icon", "Image"), "UI_Common", ResMgr:GetResIcon(2))
        self:GetGo("RootPanel/SelectPanel/benefit/2"):SetActive(true)
        self:GetGo("RootPanel/SelectPanel/reward/2"):SetActive(true)
    else
        self:GetGo("RootPanel/SelectPanel/benefit/2"):SetActive(false)
        self:GetGo("RootPanel/SelectPanel/reward/2"):SetActive(false)
    end
    if allReward[3] then
        self:SetText("RootPanel/SelectPanel/benefit/3/num", "+"..allReward[3])
        self:SetSprite(self:GetComp("RootPanel/SelectPanel/benefit/3/icon", "Image"), "UI_Common", ResMgr:GetResIcon(3))

        self:SetText("RootPanel/SelectPanel/reward/3/num", "+"..allReward[3])
        --self:SetSprite(self:GetComp("RootPanel/SelectPanel/reward/3/icon", "Image"), "UI_Common", ResMgr:GetResIcon(3))
        self:GetGo("RootPanel/SelectPanel/benefit/3"):SetActive(true)
        self:GetGo("RootPanel/SelectPanel/reward/3"):SetActive(true)
    else
        self:GetGo("RootPanel/SelectPanel/benefit/3"):SetActive(false)
        self:GetGo("RootPanel/SelectPanel/reward/3"):SetActive(false)
    end

    if allReward[6] then
        self:SetText("RootPanel/SelectPanel/benefit/6/num", "+"..allReward[6])
        self:SetSprite(self:GetComp("RootPanel/SelectPanel/benefit/6/icon", "Image"), "UI_Common", ResMgr:GetResIcon(6))

        self:SetText("RootPanel/SelectPanel/reward/6/num", "+"..allReward[6])
        --self:SetSprite(self:GetComp("RootPanel/SelectPanel/reward/6/icon", "Image"), "UI_Common", ResMgr:GetResIcon(6))
        self:GetGo("RootPanel/SelectPanel/benefit/6"):SetActive(true)
        self:GetGo("RootPanel/SelectPanel/reward/6"):SetActive(true)
    else
        self:GetGo("RootPanel/SelectPanel/benefit/6"):SetActive(false)
        self:GetGo("RootPanel/SelectPanel/reward/6"):SetActive(false)
    end

    local btnDoubel = self:GetComp("RootPanel/SelectPanel/DoubleBtn", "Button")
    local btnNormal = self:GetComp("RootPanel/SelectPanel/ClaimBtn", "Button")

    --GameSDKs:Track("ad_button_show", {video_id = 10005, video_namne = GameSDKs:GetAdName(10005)})
    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10005, state = 0, revenue = 0})

    self:SetButtonClickHandler(btnDoubel, function()
        btnDoubel.interactable = false
        GameSDKs:PlayRewardAd(function()
            cb(true)
            --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10005, name = GameSDKs:GetAdName(10005), current_money = GameTableDefine.ResourceManger:GetCash()})
            self:DestroyModeUIObject()
        end, 
        function()
            if btnDoubel then
                btnDoubel.interactable = true
            end
        end,
        function()
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
            if btnDoubel then
                btnDoubel.interactable = true
            end
        end,
        10005)
    end)

    self:SetButtonClickHandler(btnNormal, function()
        btnNormal.interactable = false
        cb(false)
        -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10005})
        self:DestroyModeUIObject()
    end)

    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
    btnNoAD.gameObject:SetActive(GameConfig:IsIAP() and not GameTableDefine.ShopManager:IsNoAD())
    self:SetButtonClickHandler(btnNoAD, function()
        GameTableDefine.ShopUI:OpenAndTurnPage(1009)
    end)
end

return DoubleRewardUIView