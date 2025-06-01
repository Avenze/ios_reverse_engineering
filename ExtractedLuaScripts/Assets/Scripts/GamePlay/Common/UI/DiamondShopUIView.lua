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
local DiamondShopUI = GameTableDefine.DiamondShopUI
local CfgMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local DiamondShopUIView = Class("DiamondShopUIView", UIView)


function DiamondShopUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function DiamondShopUIView:OnEnter()
    print("DiamondShopUIView:OnEnter")
    local btn = self:GetComp("RootPanel/BottomPanel/frame2/lower/BuyBtn", "Button")
    --btn.interactable = CfgMgr.config_global.ticket_price <= ResMgr.GetDiamond()
    self:SetButtonClickHandler(btn, function()
        btn.interactable = false
        DiamondShopUI:BuyTicket()
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn", "Button"), function()
        self:DestroyModeUIObject()
    end)
end

function DiamondShopUIView:OnPause()
    print("DiamondShopUIView:OnPause")
end

function DiamondShopUIView:OnResume()
    print("DiamondShopUIView:OnResume")
end

function DiamondShopUIView:OnExit()
    self.super:OnExit(self)
    print("DiamondShopUIView:OnExit")
end

function DiamondShopUIView:SetShopInfo(diamondInfo, ticketInfo, ticketPrice, isFree, cdTime)
    self:SetText("RootPanel/MidPanel/frame1/upper/txt", diamondInfo)
    self:SetText("RootPanel/MidPanel/frame2/upper/txt", ticketInfo)
    self:SetText("RootPanel/BottomPanel/frame2/lower/BuyBtn/text", ticketPrice)
    self:SetText("RootPanel/BottomPanel/frame2/lower/UnaffordableBtn/text", ticketPrice)

    self:GetGo("RootPanel/BottomPanel/frame2/lower/UnaffordableBtn"):SetActive(CfgMgr.config_global.ticket_price > ResMgr.GetDiamond())
    
    local buttonRoot = self:GetGo("RootPanel/BottomPanel/frame1/lower")
    self:GetGo(buttonRoot, "FreeBtn"):SetActive(isFree)
    self:GetGo(buttonRoot, "VideoBtn"):SetActive(isFree == false and cdTime <= 0)
    self:GetGo(buttonRoot, "WaitBtn"):SetActive(isFree == false and cdTime > 0)

    -- 瓦瑞尔要求"ad_view"和"puchase" state为0事件不上传了2022-10-13
    -- if isFree == false and cdTime <= 0 then
    --     --GameSDKs:Track("ad_button_show", {video_id = 10002, video_namne = GameSDKs:GetAdName(10002)})
    --     GameSDKs:TrackForeign("ad_view", {ad_pos = 10002, state = 0, revenue = 0})
    -- end

    if cdTime and cdTime > 0 then
        self.endPoint = GameTimeManager:GetCurrentServerTime(true) + cdTime
        self:CreateTimer(1000 * 60, function()
            local t = self.endPoint - GameTimeManager:GetCurrentServerTime(true)
            local H = math.ceil(t / 3600)
            --local timeTxt = GameTimeManager:FormatTimeLength(t)
            if t > 0 then
                self:SetText("RootPanel/BottomPanel/frame1/lower/WaitBtn/text", H.."H")
            else
                self:StopTimer()
                self:SetShopInfo(diamondInfo, ticketInfo, ticketPrice, isFree, 0)
            end
        end, true, true)
    end
    if isFree then
        local freeBtn = self:GetComp(buttonRoot, "FreeBtn", "Button")
        self:SetButtonClickHandler(freeBtn, function()
            freeBtn.interactable = false
            DiamondShopUI:ClaimDiamond(function()
                EventManager:DispatchEvent("FLY_ICON", self:GetTrans("FreeBtn").position,
                3, DiamondShopUI:RewardNum(isFree))
            end)
            
        end)
    end  
    if cdTime <= 0 then
        local adButton = self:GetComp(buttonRoot, "VideoBtn", "Button")
        local pos = self:GetTrans("VideoBtn").position
        self:SetButtonClickHandler(adButton, function()
            --按钮界面开始转圈
            adButton.interactable = false
            DiamondShopUI:ClaimDiamond(function()--finish
                EventManager:DispatchEvent("FLY_ICON", pos,
                3, DiamondShopUI:RewardNum(isFree))
            end,
            function()--succes
                if adButton then
                    adButton.interactable = true
                end
            end,
            function()--fail
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
                if adButton then
                    adButton.interactable = true
                end
            end
            )
        end)
    end
end


return DiamondShopUIView