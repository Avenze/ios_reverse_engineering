local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local BuyCarInfoUI = GameTableDefine.BuyCarInfoUI
local ConfigMgr = GameTableDefine.ConfigMgr
local BuyCarManager = GameTableDefine.BuyCarManager
local GameClockManager = GameTableDefine.GameClockManager

local BuyCarUIView = Class("BuyCarUIView", UIView)

function BuyCarUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function BuyCarUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/up/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    --获取载具图标,名称信息
    self.carCfg = ConfigMgr.config_car

    self:InitList()
    self.mList:UpdateData()

    self:CreateTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/up/time", currH..":"..currM)
    end, true, true)
end
function BuyCarUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local currData = self.carCfg[index]
    if currData then
        local isUnlock = (currData.lock == 0) and true or BuyCarManager:IsCarUnlock(index)

        local name = GameTextLoader:ReadText("TXT_CAR_C"..currData.id.."_NAME")
        self:SetText(go, "name", isUnlock and name or "???")

        local imageName = "icon_car_"..currData.id
        local image = self:GetComp(go, "icon", "Image")
        self:SetSprite(image, "UI_Common", isUnlock and imageName or "icon_car_locked")
        local button = self:GetComp(go, "icon", "Button")
        self:SetButtonClickHandler(button, function()
            if isUnlock then
                BuyCarInfoUI:Refresh(index)
            end
        end)
    end
end

function BuyCarUIView:InitList()
    self.mList = self:GetComp("RootPanel/CarList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.carCfg
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
end

function BuyCarUIView:OnExit()
    self.super:OnExit(self)
    self:StopTimer()
end

return BuyCarUIView
