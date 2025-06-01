local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ActivityUI = GameTableDefine.ActivityUI
local CityMode = GameTableDefine.CityMode
local FloorMode = GameTableDefine.FloorMode
local TimerMgr = GameTimeManager
local MainUI = GameTableDefine.MainUI
local FactoryMode = GameTableDefine.FactoryMode
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI
local CycleIslandMainViewUI = GameTableDefine.CycleIslandMainViewUI
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local UnlockingSkipUIView = Class("UnlockingSkipUIView", UIView)
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")

function UnlockingSkipUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function UnlockingSkipUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self.timeLoop = nil
        self:DestroyModeUIObject()
    end)
    self.Slider = self:GetComp("RootPanel/MidPanel/prog/FillArea", "Slider")
end

function UnlockingSkipUIView:OnExit()
    self.super:OnExit(self)
end

function UnlockingSkipUIView:Refresh(config, timeWait)
    local diamondNeed = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    self.endPoint = timeWait
    local timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
    local isEnough = ResMgr:CheckDiamond(diamondNeed * timeNeed / 60)
    local mat = isEnough and "MSYH GreenOutline Material" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(timeNeed/60))

    self.btn = self:GetComp("RootPanel/SelectPanel/SkipBtn", "Button")
    self.btn.interactable = isEnough
    self:SetButtonClickHandler(self.btn, function()
        timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
        --isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(timeNeed / 60))

        FloorMode:BuildRoomNow(config, diamondNeed * math.ceil(timeNeed/60), function(isEnough)
            if isEnough then
                self:StopTimer()
                MainUI:RefreshDiamondShop()
                MainUI:RefreshQuestHint()
                self:DestroyModeUIObject()
            else
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_LACK_DIAMOND"))
            end
        end)
    end)
    self:CreateTimer(1000, function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        local timeTxt = GameTimeManager:FormatTimeLength(t)
        self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(t/60))
        local isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(t/60))
        self.btn.interactable = isEnough
        if t > 0 then
            self:SetText("RootPanel/MidPanel/prog/FillArea/timer", timeTxt)
            --self:SetText("RootPanel/MidPanel/progress", math.floor((1 - t / config.unlock_times)*100) .."%")
            self.Slider.value = 1 - t / config.unlock_times
        else
            self:StopTimer()
            self:DestroyModeUIObject()
        end
    end, true, true)
end

function UnlockingSkipUIView:RefreshWorkShopSkip(config, timeWait)
    local diamondNeed = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    self.endPoint = timeWait
    local timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
    local isEnough = ResMgr:CheckDiamond(diamondNeed * timeNeed / 60)
    local mat = isEnough and "MSYH GreenOutline Material" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(timeNeed/60), nil)
    
    self.btn = self:GetComp("RootPanel/SelectPanel/SkipBtn", "Button")
    self.btn.interactable = isEnough
    self:CreateTimer(1000,function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()     
        local timeTxt = GameTimeManager:FormatTimeLength(t)
        self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(t/60))
        local isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(t/60))       
        self.btn.interactable = isEnough
        if t > 0 then
            self:SetText("RootPanel/MidPanel/prog/FillArea/timer", timeTxt)
            self.Slider.value = 1 - t / config.unlock_times
        else            
            self.timeLoop = nil
            self:DestroyModeUIObject()            
        end
    end, true, true)
    self:SetButtonClickHandler(self.btn, function()        
               
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        ResMgr:SpendDiamond(diamondNeed * math.ceil(t/60), nil, function(isEnough)
            if isEnough then
                FactoryMode:Build(config.id)
                GameSDKs:Track("virtual_currency", {currency_type = 1, pos = "快速完成工厂修建时消耗", behaviour = 2, num_new = tonumber(diamondNeed * math.ceil(t/60))}) --消耗钻石埋点
                self:DestroyModeUIObject()
                MainUI:RefreshDiamondShop()
                EventManager:DispatchEvent("UPGRADE_FACTORY") 
            end            
        end)                
		self:DestroyModeUIObject()
    end)    
end

function UnlockingSkipUIView:RefreshBuildingSkip(config, timeWait)
    local diamondNeed = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    self.endPoint = timeWait
    local timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
    local isEnough = ResMgr:CheckDiamond(diamondNeed * timeNeed / 60)
    local mat = isEnough and "MSYH GreenOutline Material" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(timeNeed/60))

    self.btn = self:GetComp("RootPanel/SelectPanel/SkipBtn", "Button")
    self.btn.interactable = isEnough
    self:SetButtonClickHandler(self.btn, function()
        timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
        CityMode:UnlockBuildingNow(config, diamondNeed * math.ceil(timeNeed/60), function(isEnough)
            if isEnough then
                self:StopTimer()
                self:DestroyModeUIObject()
                MainUI:RefreshDiamondShop()
                MainUI:RefreshQuestHint()
            else
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_DIAMOND"))
            end
        end)
    end)
    self:CreateTimer(1000, function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        local timeTxt = GameTimeManager:FormatTimeLength(t)
        self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(t/60), nil)
        local isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(t/60))
        self.btn.interactable = isEnough
        if t > 0 then
            self:SetText("RootPanel/MidPanel/prog/FillArea/timer", timeTxt)
            --self:SetText("RootPanel/MidPanel/progress", math.floor((1 - t / config.unlock_time)*100) .."%")
            self.Slider.value = 1 - t / config.unlock_time
        else
            self:StopTimer()
            self:DestroyModeUIObject()
            CityMode:UnlockBuidlingComplete()
        end
    end, true, true)
end


function UnlockingSkipUIView:RefreshInstanceBuildingSkip(config, timeWait,handler)
    local diamondNeed = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    self.endPoint = timeWait
    local timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
    local isEnough = ResMgr:CheckDiamond(diamondNeed * timeNeed / 60)
    local mat = isEnough and "MSYH GreenOutline Material" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(timeNeed/60), nil)
    
    self.btn = self:GetComp("RootPanel/SelectPanel/SkipBtn", "Button")
    self.btn.interactable = isEnough
    self:CreateTimer(1000,function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()     
        local timeTxt = GameTimeManager:FormatTimeLength(t)
        self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(t/60))
        local isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(t/60))       
        self.btn.interactable = isEnough
        if t > 0 then
            self:SetText("RootPanel/MidPanel/prog/FillArea/timer", timeTxt)
            self.Slider.value = 1 - t / config.unlock_times
        else            
            self.timeLoop = nil
            self:DestroyModeUIObject()            
        end
    end, true, true)
    self:SetButtonClickHandler(self.btn, function()        
               
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        ResMgr:SpendDiamond(diamondNeed * math.ceil(t/60), nil, function(isEnough)
            if isEnough then
                self:StopTimer()
                local roomData = InstanceModel:GetRoomDataByID(config.id)
                InstanceDataManager:SetRoomData(config.id,roomData.buildTimePoint,2)
                GameSDKs:Track("virtual_currency", {currency_type = 1, pos = "副本加速建造", behaviour = 2, num_new = tonumber(diamondNeed * math.ceil(t/60))}) --消耗钻石埋点
                self:DestroyModeUIObject()
                InstanceMainViewUI:Refresh()
                handler.view:Hide()
                --print("销毁修建房屋FLoatUI",handler.guid)

                GameTableDefine.FloatUI:DestroyFloatUIView(handler.guid)
                --EventManager:DispatchEvent("UPGRADE_FACTORY") 
                InstanceModel:RefreshScene()  
            end            
        end)                
		self:DestroyModeUIObject()
    end)    
end

function UnlockingSkipUIView:RefreshCycleIslandBuildingSkip(config, timeWait,handler)
    local diamondNeed = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    self.endPoint = timeWait
    local timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
    local isEnough = ResMgr:CheckDiamond(diamondNeed * timeNeed / 60)
    local mat = isEnough and "MSYH GreenOutline Material" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(timeNeed/60), nil)

    self.btn = self:GetComp("RootPanel/SelectPanel/SkipBtn", "Button")
    self.btn.interactable = isEnough
    self:CreateTimer(1000,function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        local timeTxt = GameTimeManager:FormatTimeLength(t)
        self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(t/60))
        local isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(t/60))
        self.btn.interactable = isEnough
        if t > 0 then
            self:SetText("RootPanel/MidPanel/prog/FillArea/timer", timeTxt)
            self.Slider.value = 1 - t / config.unlock_times
        else
            self.timeLoop = nil
            self:DestroyModeUIObject()
        end
    end, true, true)
    self:SetButtonClickHandler(self.btn, function()

        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        ResMgr:SpendDiamond(diamondNeed * math.ceil(t/60), nil, function(isEnough)
            if isEnough then
                self:StopTimer()
                local currentModel = CycleInstanceDataManager:GetCurrentModel()
                local roomData = currentModel:GetRoomDataByID(config.id)
                currentModel:SetRoomData(config.id,roomData.buildTimePoint,2)
                local room = currentModel:GetScene():GetRoomByID(config.id)
                room:HideBubble(CycleInstanceDefine.BubbleType.IsBuilding)
                GameSDKs:Track("virtual_currency", {currency_type = 1, pos = "循环副本加速建造", behaviour = 2,  num_new = tonumber(diamondNeed * math.ceil(t/60))}) --消耗钻石埋点
                self:DestroyModeUIObject()
                CycleInstanceDataManager:GetCycleInstanceMainViewUI():Refresh()

                --EventManager:DispatchEvent("UPGRADE_FACTORY")
                currentModel:RefreshScene()
                room:OnBuildCompleted()
            end
        end)
        self:DestroyModeUIObject()
    end)
end

function UnlockingSkipUIView:RefreshFootballClubSkip(config, timeWait)

    local diamondNeed = ConfigMgr.config_global.skip_diamond or 1--每60秒需要多少钻石
    self.endPoint = timeWait
    local timeNeed = self.endPoint - TimerMgr:GetCurrentServerTime()
    local isEnough = ResMgr:CheckDiamond(diamondNeed * timeNeed / 60)
    local mat = isEnough and "MSYH GreenOutline Material" or "MSYH RedOutline Material"
    self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(timeNeed/60))

    self.btn = self:GetComp("RootPanel/SelectPanel/SkipBtn", "Button")
    self.btn.interactable = isEnough
    self:SetButtonClickHandler(self.btn, function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        ResMgr:SpendDiamond(diamondNeed * math.ceil(t/60), nil, function(isEnough)
            if isEnough then
                MainUI:RefreshCashEarn()
                self:StopTimer()
                self:DestroyModeUIObject()
                GameTableDefine.FootballClubController:BuyRoomFinished(config.id)
                GameSDKs:Track("virtual_currency", {currency_type = 1, pos = "快速完成足球俱乐部修建时消耗", behaviour = 2, num_new = tonumber(diamondNeed * math.ceil(t/60))}) --消耗钻石埋点
            end            
        end)                
    end)
    self:CreateTimer(1000, function()
        local t = self.endPoint - TimerMgr:GetCurrentServerTime()
        local timeTxt = GameTimeManager:FormatTimeLength(t)
        self:SetText("RootPanel/SelectPanel/SkipBtn/cost", diamondNeed * math.ceil(t/60), nil)
        local isEnough = ResMgr:CheckDiamond(diamondNeed * math.ceil(t/60))
        self.btn.interactable = isEnough
        if t > 0 then
            self:SetText("RootPanel/MidPanel/prog/FillArea/timer", timeTxt)
            --self:SetText("RootPanel/MidPanel/progress", math.floor((1 - t / config.unlock_time)*100) .."%")
            self.Slider.value = 1 - t / config.unlockTime
        else
            self:StopTimer()
            self:DestroyModeUIObject()
            --GameTableDefine.FootballClubController:BuyRoomFinished(self.config.id)

        end
    end, true, true)

end
return UnlockingSkipUIView