local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ResourceManger = GameTableDefine.ResourceManger
local BuyCarManager = GameTableDefine.BuyCarManager
local BuyHouseManager = GameTableDefine.BuyHouseManager
local CompanysUI = GameTableDefine.CompanysUI

local RewardUIView = Class("RewardUIView", UIView)

function RewardUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function RewardUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("xxxx","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function RewardUIView:Refresh(mainType, typeId, NumOrId, cb)
    --mainType 1钞票钻石资源 2物质资源
    --1[2钱 3钻石]  2[1车 2房 3公司]
    --1[2 3] num   2[1 2 3] id
    local nodeName = {}
    nodeName[1] = {[2] = "cash", [3] = "diamond"}
    nodeName[2] = {[1] = "car", [3] = "company"}
    local currNode = self:GetGo("HeadPanel/reward/"..nodeName[mainType][typeId])
    currNode:SetActive(true)

    local getTxt = function(typeid, id, isName)
        local result = "TXT_"
        if typeid == 1 then
            result = result .. "CAR_C" .. id .."_"
        elseif typeid == 3 then
            result = result .. "COMPANY_C" .. id .."_"
        end

        if isName then
            result = result .. "NAME"
        else
            result = result .. "DESC"
        end

        return result
    end
    if mainType == 1 then
        self:SetText(currNode, "num/text", "+" .. NumOrId)
    else
        local name = GameTextLoader:ReadText(getTxt(typeId, NumOrId, true))
        local desc = GameTextLoader:ReadText(getTxt(typeId, NumOrId, false))
        self:SetText(currNode, "name/text", name)
        self:SetText(currNode, "desc", desc)

        local setImage = self:GetComp(currNode, "logo", "Image")
        local imageName = nil
        if typeId == 1 then
            imageName = "icon_car_" .. NumOrId
        elseif typeId == 3 then
            local newId = string.format("%03d", NumOrId)
            imageName = "icon_company_" .. newId ..GameConfig:GetLangageFileSuffix()
        end
        self:SetSprite(setImage, "UI_Common", imageName)
    end
    self:SetButtonClickHandler(self:GetComp("HeadPanel/btn_rise", "Button"), function()
        self:GetReward(mainType, typeId, NumOrId)
        if cb then cb() end
        self:DestroyModeUIObject()
    end)
end

function RewardUIView:GetReward(mainType, typeId, NumOrId)
    local pos = self:GetTrans("HeadPanel/btn_rise")
    local allReward = {}
    allReward[1] = {
        function(num)--1no
        end,
        function(num)--2cash
            EventManager:DispatchEvent("FLY_ICON", pos, 2, num)
            ResourceManger:AddCash(NumOrId, nil, nil, true)
        end,
        function(num)--3diamond
            EventManager:DispatchEvent("FLY_ICON", pos, 3, num)
            ResourceManger:AddDiamond(NumOrId, nil, nil, true)
        end
    }

    allReward[2] = {
        function(carId)--解锁车辆
            BuyCarManager:IsCarUnlock(carId, true)
        end,
        function(houseId)--结果房子
            BuyHouseManager:IsHouseUnlock(houseId, true)
        end,
        function(companyId)--解锁公司
            CompanysUI:IsCompanyUnlock(companyId, true)
        end,
    }

    allReward[mainType][typeId](NumOrId)
end

function RewardUIView:OnExit()
end

return RewardUIView