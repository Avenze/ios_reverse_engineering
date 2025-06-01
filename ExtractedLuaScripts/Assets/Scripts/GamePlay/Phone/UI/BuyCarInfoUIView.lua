local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local BuyCarManager = GameTableDefine.BuyCarManager
local ConfigMgr = GameTableDefine.ConfigMgr

local BuyCarInfoUIView = Class("BuyCarInfoUIView", UIView)

function BuyCarInfoUIView:ctor()
    self.super:ctor()
end

function BuyCarInfoUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("background/BottomPanel/CancelBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function BuyCarInfoUIView:Refresh(carId)
    local currCfg = ConfigMgr.config_car[carId]

    local name = GameTextLoader:ReadText("TXT_CAR_C"..carId.."_NAME")
    local desc = GameTextLoader:ReadText("TXT_CAR_C"..carId.."_DESC")
    local imageName = "icon_car_"..carId

    self:SetText("background/BottomPanel/title/name", name)
    self:SetText("background/BottomPanel/YesBtn/icon/cost", currCfg.price)
    self:SetText("background/BottomPanel/bg/desc", desc)
    local icon = self:GetComp("background/HeadPanel/icon", "Image")
    self:SetSprite(icon, "UI_Common", imageName)

    self.ownData = BuyCarManager:GetBoughtData(carId)

    self:SetText("background/BottomPanel/YesBtn/carNum", self.ownData)

    local buyButton = self:GetComp("background/BottomPanel/YesBtn", "Button")
    buyButton.interactable = BuyCarManager:Buy(carId, true)
    self:SetButtonClickHandler(buyButton, function()
        BuyCarManager:Buy(carId)
        self:Refresh(carId)
    end)
end

function BuyCarInfoUIView:OnExit()
    self.super:OnExit(self)
end

return BuyCarInfoUIView