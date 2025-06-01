local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ShopManager = GameTableDefine.ShopManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ActorEventManger = GameTableDefine.ActorEventManger
local CompanyMode = GameTableDefine.CompanyMode

local Event006UIView = Class("Event006UIView", UIView)

function Event006UIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function Event006UIView:OnEnter()
    --GameSDKs:Track("ad_button_show", {video_id = 10010, video_namne = GameSDKs:GetAdName(10010)})
    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- GameSDKs:TrackForeign("ad_view", {ad_pos = 10010, state = 0, revenue = 0})

    local btnNoAD = self:GetComp("RootPanel/banner_ad", "Button")
    btnNoAD.gameObject:SetActive(GameConfig:IsIAP() and not GameTableDefine.ShopManager:IsNoAD())
    self:SetButtonClickHandler(btnNoAD, function()
        GameTableDefine.ShopUI:OpenAndTurnPage(1009)
    end)
end

function Event006UIView:OnExit()
	self.super:OnExit(self)
end

function Event006UIView:ShowPanel()
    local root = self:GetGo("RootPanel/MidPanel")
    local rejectBtn = self:GetComp(root, "QuitBtn", "Button")
    local confirmBtn = self:GetComp(root, "ConfirmBtn/Button", "Button")
    local cfg = ConfigMgr.config_event[4]
    local companySecond = cfg.event_reward[2]

    --local canBuy,expAdd = ShopManager:Buy(2000, true)
    local companyData = CompanyMode:GetData()
    local expAdd = 0
    for k,v in pairs(companyData or {}) do
        expAdd = expAdd + CompanyMode:RoomExpAdd(k)
    end

    expAdd = expAdd * companySecond
    self:SetText(root, "event/reward/num", expAdd)

    self:SetButtonClickHandler(rejectBtn, function()
        -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10010})
        ActorEventManger:FinishEvent(cfg)
        self:DestroyModeUIObject()
    end)

    local adEnd = function()
        CompanyMode:AddExp(companySecond)
        ActorEventManger:FinishEvent(cfg)
        self:DestroyModeUIObject()
    end
    local onSuccess = function()
    end
    local onFail = function()
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
    end
    self:SetButtonClickHandler(confirmBtn, function()
        GameSDKs:PlayRewardAd(adEnd, onSuccess, onFail, 10010)
    end)
end

return Event006UIView
