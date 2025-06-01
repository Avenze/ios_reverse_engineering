local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local CountryMode = GameTableDefine.CountryMode
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ResMgr = GameTableDefine.ResourceManger
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr

local RoomUnlockUIView = Class("RoomUnlockUIView", UIView)

function RoomUnlockUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function RoomUnlockUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function RoomUnlockUIView:OnExit()
    self.super:OnExit(self)
end

function RoomUnlockUIView:Refresh(data)
    local isCsahEnough = ResMgr:GetLocalMoney() >= data.unlock_require
    self:SetSprite(self:GetComp("RootPanel/MidPanel/icon", "Image"), "UI_Common", 
    "icon_room_"..data.category[2].."W", nil, true)

    local color = isCsahEnough and "FFDC2F" or "FFFFFF"
    local mat = isCsahEnough and "" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/ClaimBtn/cash/num", Tools:SeparateNumberWithComma(data.unlock_require))
    self:SetSprite(self:GetComp("RootPanel/SelectPanel/ClaimBtn/cash/icon", "Image"), "UI_Main", ResMgr:GetResIcon(CountryMode:GetCurrCountryCurrency()))
    
    self:SetText("RootPanel/MidPanel/info/room_name",
    GameTextLoader:ReadText(data.room_name))

    self:SetText("RootPanel/MidPanel/info/desc",
    GameTextLoader:ReadText(data.room_desc))

    self:SetText("RootPanel/MidPanel/requirement/time/num",
    GameTimeManager:FormatTimeLength(data.unlock_times))


    local power = 0
    for k,v in pairs(data.furniture or {}) do        
        if v.level > 0 then
            power = power + ConfigMgr.config_furnitures_levels[v.id][v.level].power_consume
        end
    end

    --self:GetGo("RootPanel/MidPanel/requirement/elec"):SetActive(power ~= 0)
    local isPowerEnough = FloorMode:PowerEnough(math.abs(power))
    --if power ~= 0 then
    local color = isPowerEnough and "FFDC2F" or "FFFFFF"
    local mat = isPowerEnough and "" or "MSYH RedOutline Material"
    self:SetText("RootPanel/MidPanel/requirement/elec/num", power)
    --end

    local btn = self:GetComp("RootPanel/SelectPanel/ClaimBtn", "Button")
    btn.interactable = isPowerEnough
    self:SetButtonClickHandler(btn, function()
        isCsahEnough = ResMgr:GetLocalMoney() >= data.unlock_require
        if isCsahEnough then
            FloorMode:UnlockRoom(data.unlock_require, data)
            self:DestroyModeUIObject()
        else
            GameTableDefine.ShopInstantUI:EnterToCashBuy()
        end
    end)
end

return RoomUnlockUIView