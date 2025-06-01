--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-24 10:27:20
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local UnityHelper = CS.Common.Utils.UnityHelper;
local GameUIManager = GameTableDefine.GameUIManager
local InstanceOfflineRewardUI = GameTableDefine.InstanceOfflineRewardUI
local InstanceDataManager = GameTableDefine.InstanceDataManager
local FeelUtil = CS.Common.Utils.FeelUtil
local EventManager = require("Framework.Event.Manager")

local InstanceOfflineRewardUIView = Class("InstanceOfflineRewardUIView", UIView)

function InstanceOfflineRewardUIView:ctor()
    self.super:ctor()
end

function InstanceOfflineRewardUIView:OnEnter()
    -- local claimBtn = self:GetComp()
    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ClaimBtn", "Button"), function()
        InstanceOfflineRewardUI:CloseView()
        local instanceBind = InstanceDataManager:GetInstanceBind()
        EventManager:DispatchEvent("FLY_ICON", nil, instanceBind.cash_fly, nil, function()
            GameTableDefine.InstanceMainViewUI:Refresh()
        end)
        GameTableDefine.FlyIconsUI:SetInstanceResItem(self.rewardData.productions)
        EventManager:DispatchEvent("FLY_ICON", nil, 107, nil)
    end)

    -- self.m_CurOfflineRewardData.productions = productions
    -- self.m_CurOfflineRewardData.rewardMoney = money
    self.rewardData = InstanceDataManager:GetCurInstanceOfflineRewardData()
    -- local self.rewardData = InstanceDataManager:GetGMCurInstanceOfflineRewardData()
    if not self.rewardData then
        InstanceOfflineRewardUI:CloseView()
        return
    end
    local disRewardData = {}
    if self.rewardData.rewardMoney and self.rewardData.rewardMoney > 0 then
        local iconName = InstanceDataManager:GetInstanceBind().cashIcon
        local tempData = {["icon"] = iconName, ["count"] = math.floor(self.rewardData.rewardMoney)}
        table.insert(disRewardData, tempData)
    end
    if self.rewardData.productions and Tools:GetTableSize(self.rewardData.productions) > 0 then
        for _, v in ipairs(self.rewardData.productions) do
            local tempData = {["icon"] = v.resCfg.icon, ["count"] = math.floor(v.count)}
            table.insert( disRewardData,tempData)
        end
    end
    local itemGo1 = self:GetGoOrNil("RootPanel/MidPanel/reward/item")
    local parentGo = self:GetGoOrNil("RootPanel/MidPanel/reward")
    self.itemGoList = {}
    if itemGo1 then
        itemGo1.name = "itemGo1"
        table.insert(self.itemGoList,itemGo1)
    end

    for i = 2, Tools:GetTableSize(disRewardData), 1 do
        local tempGo = UnityHelper.CopyGameByGo(itemGo1, parentGo)
        if tempGo then
            tempGo.name = "itemGo"..i
        end
        table.insert(self.itemGoList, tempGo)
    end
    for index, data in ipairs(disRewardData) do
        self:SetText(self.itemGoList[index], "num/num", Tools:SeparateNumberWithComma(data.count))
        self:SetImageSprite("RootPanel/MidPanel/reward/itemGo"..tostring(index).."/bg/icon", data.icon)
    end

    local maxTime = InstanceDataManager:GetMaxOfflineTime()
    local curDisOfflineTime = InstanceDataManager:GetCurOfflineDisplayTime()
    -- local curDisOfflineTime = 5000
    local progressValue = curDisOfflineTime / maxTime
    local maxTimeDis = GameTimeManager:FormatTimeLength(maxTime)
    local offlineTimeDis = GameTimeManager:FormatTimeLength(curDisOfflineTime)
    local progressSlider = self:GetComp("RootPanel/offlineTime/prog", "Slider")
    if progressSlider then
        progressSlider.value = progressValue
    end
    self:SetText("RootPanel/offlineTime/prog/num/time", offlineTimeDis)
    self:SetText("RootPanel/offlineTime/prog/num/limit", maxTimeDis)
    --判断地标是否购买，如果没有购买显示banner
    local isBuyFlag = GameTableDefine.InstanceModel:GetLandMarkCanPurchas()
    local bannerGo = self:GetGoOrNil("RootPanel/MidPanel/banner")
    if bannerGo then
        bannerGo:SetActive(isBuyFlag)
    end

    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/banner/dBtn", "Button"), function()
        InstanceOfflineRewardUI:CloseView()
        GameTableDefine.InstanceShopUI:EnterToSpecial()
    end)

end

function InstanceOfflineRewardUI:OnPause()
    InstanceOfflineRewardUI:CloseView()
end

function InstanceOfflineRewardUIView:OnExit()
    self.super:OnExit(self)
    if self.itemGoList and Tools:GetTableSize(self.itemGoList) > 1 then
        for i = 2, Tools:GetTableSize(self.itemGoList) do
            CS.UnityEngine.GameObject.Destroy(self.itemGoList[i])
        end
        self.itemGoList = nil
    end
end

return InstanceOfflineRewardUIView