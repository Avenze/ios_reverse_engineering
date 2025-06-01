
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local UnityHelper = CS.Common.Utils.UnityHelper;
local GameUIManager = GameTableDefine.GameUIManager
local CycleCastleModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local FeelUtil = CS.Common.Utils.FeelUtil
local EventManager = require("Framework.Event.Manager")

local CycleCastleOfflineRewardUIView = Class("CycleCastleOfflineRewardUIView", UIView)

function CycleCastleOfflineRewardUIView:ctor()
    self.super:ctor()
end

function CycleCastleOfflineRewardUIView:OnEnter()
    local disRewardData = {}
    -- local claimBtn = self:GetComp()


    -- self.m_CurOfflineRewardData.productions = productions
    -- self.m_CurOfflineRewardData.rewardMoney = money
    self.rewardData = CycleCastleModel:GetCurInstanceOfflineRewardData()
    -- local self.rewardData = InstanceDataManager:GetGMCurInstanceOfflineRewardData()
    if not self.rewardData then
        self:DestroyModeUIObject()
        return
    end
    
    if self.rewardData.rewardMoney and self.rewardData.rewardMoney > 0 then
        local iconName = CycleInstanceDataManager:GetInstanceBind().cashIcon
        local tempData = { ["itemType"] = 31, ["icon"] = "icon_cy2_cash2", ["str"] = BigNumber:FormatBigNumber(math.floor(self.rewardData.rewardMoney)) }
        table.insert(disRewardData, tempData)
    end
    
    if self.rewardData.rewardExp and self.rewardData.rewardExp > 0 then
        local iconName = CycleInstanceDataManager:GetInstanceBind().cashIcon
        local tempData = { ["itemType"] = 26, ["icon"] = "icon_cy2_formulaExp", ["str"] = BigNumber:FormatBigNumber(math.floor(self.rewardData.rewardExp)) }
        table.insert(disRewardData, tempData)
    end
    
    if self.rewardData.rewardPoint and self.rewardData.rewardPoint > 0 then
        local iconName = CycleInstanceDataManager:GetInstanceBind().cashIcon
        local tempData = { ["itemType"] = 201, ["icon"] = "icon_cy2_milePoint", ["str"] = BigNumber:FormatBigNumber(math.floor(self.rewardData.rewardPoint)) }
        table.insert(disRewardData, tempData)
    end
    
    if self.rewardData.productions and Tools:GetTableSize(self.rewardData.productions) > 0 then
        for _, v in ipairs(self.rewardData.productions) do
            local tempData = { ["itemType"] = 202, ["icon"] = v.resCfg.icon, ["str"] = BigNumber:FormatBigNumber(v.count) }
            table.insert(disRewardData, tempData)
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
        self:SetText(self.itemGoList[index], "num/num", data.str)
        self:SetImageSprite("RootPanel/MidPanel/reward/itemGo"..tostring(index).."/bg/icon", data.icon)
    end

    local maxTime = CycleCastleModel:GetMaxOfflineTime()
    local curDisOfflineTime = CycleCastleModel:GetCurOfflineDisplayTime()
    -- local curDisOfflineTime = 5000
    local progressValue = curDisOfflineTime / maxTime
    local maxTimeDis = GameTimeManager:FormatTimeLength(maxTime)
    local offlineTimeDis = GameTimeManager:FormatTimeLength(curDisOfflineTime)
    local progressSlider = self:GetComp("RootPanel/offlineTime/prog", "Slider")
    if progressSlider then
        progressSlider.value = progressValue
    end
    self:SetText("RootPanel/offlineTime/prog/num/time", offlineTimeDis)
    --self:SetText("RootPanel/offlineTime/prog/num/limit", maxTimeDis)
    ----判断地标是否购买，如果没有购买显示banner
    --local isBuyFlag = GameTableDefine.InstanceModel:GetLandMarkCanPurchas()
    --local bannerGo = self:GetGoOrNil("RootPanel/MidPanel/banner")
    --if bannerGo then
    --    bannerGo:SetActive(isBuyFlag)
    --end
    --
    --self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/banner/dBtn", "Button"), function()
    --    self:DestroyModeUIObject()
    --    GameTableDefine.InstanceShopUI:EnterToSpecial()
    --end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ClaimBtn", "Button"), function()
        self:DestroyModeUIObject()

        GameTableDefine.FlyIconsUI:SetCycleInstanceNum(disRewardData)
    end)
    
end


function CycleCastleOfflineRewardUIView:OnExit()
    self.super:OnExit(self)
    if self.itemGoList and Tools:GetTableSize(self.itemGoList) > 1 then
        for i = 2, Tools:GetTableSize(self.itemGoList) do
            CS.UnityEngine.GameObject.Destroy(self.itemGoList[i])
        end
        self.itemGoList = nil
    end
end

return CycleCastleOfflineRewardUIView