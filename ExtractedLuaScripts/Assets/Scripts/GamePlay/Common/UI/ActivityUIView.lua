local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ActivityUI = GameTableDefine.ActivityUI
local ShopUI = GameTableDefine.ShopUI
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local MainUI = GameTableDefine.MainUI
local UnityHelper = CS.Common.Utils.UnityHelper
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local SoundEngine = GameTableDefine.SoundEngine
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local CfgMgr = GameTableDefine.ConfigMgr
local Vector3 = CS.UnityEngine.Vector3
local TimerMgr = GameTimeManager

local ActivityUIView = Class("ActivityUIView", UIView)

function ActivityUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function ActivityUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/title/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    self:Init()
    self:Refresh()
    self:UpData()
end

--初始化数据
function ActivityUIView:Init()
    self.slider = self:GetComp("RootPanel/dailyReward/prog", "Slider")
    self.cfgActivityReward = ActivityUI:GetActivityReward()    
    self.cfgActivity = CfgMgr.config_activity
    self.slider.value = ActivityUI:GetDayActivity() / self:GetMaxDayActivity()
end

--刷新
function ActivityUIView:Refresh()
    self.cfgActivityReward = ActivityUI:GetActivityReward()   
    self:SetText("RootPanel/dailyReward/dayActivity/num", ActivityUI:GetDayActivity())
    self:SetText("RootPanel/weekReward/weekActivity/num", ActivityUI:GetWeeklyActivity())
    self:SetText("RootPanel/res/c/num", Tools:SeparateNumberWithComma(ResourceManger:GetCash()))
    self:SetText("RootPanel/res/d/num", Tools:SeparateNumberWithComma(ResourceManger:GetDiamond()))
    self:SliderMove()
    self:GenerateBlock()
    self:GenerateWeekBlock()
    self:RefreshList()    
end

--复制生成slider上的节点
function ActivityUIView:GenerateBlock()
    local block = self:GetGo("RootPanel/dailyReward/prog/rewardHolder/block")
    local parent = block.transform.parent.gameObject
    local index = 1
    local rect = self:GetComp("RootPanel/dailyReward/prog", "RectTransform")
    local rewardHolder = self:GetComp("RootPanel/dailyReward/prog/rewardHolder", "RectTransform")
    for i,v in pairs(self.cfgActivityReward.day) do        
        local go
        local canReceive = ActivityUI:GetActivityData("gift", v.id)
        if self:GetGoOrNil(parent, "block" .. index ) then
            go = self:GetGo(parent, "block" .. index )
        else
            go = GameObject.Instantiate(block, parent.transform)
        end
        go:SetActive(true)
        go.name = "block" .. index     
        self:SetText(go, "num", v.require)
        local icon = self:GetComp(go, "icon", "Image")        
        self:SetSprite(icon, "UI_Common", v.icon, nil, true)
        local x = rect.rect.width * (v.require / self:GetMaxDayActivity()) - rect.rect.width /2 - rewardHolder.anchoredPosition.x
        self:GetComp(go,"", "RectTransform").anchoredPosition3D = Vector3(x,0,0)
        index = index + 1
        local getBtn = self:GetComp(go, "icon", "Button")
        getBtn.interactable = canReceive
        -- self:GetGo(go, "locked"):SetActive(v.require > ActivityUI:GetDayActivity())
        -- self:GetGo(go, "unlock"):SetActive(v.require <= ActivityUI:GetDayActivity())
        self:GetGo(go, "locked"):SetActive(v.require / self:GetMaxDayActivity() > self.slider.value)
        self:GetGo(go, "unlock"):SetActive(v.require / self:GetMaxDayActivity() <= self.slider.value and canReceive)
        local CanvasGroup = self:GetComp(go, "", "CanvasGroup")
        if v.require <= ActivityUI:GetDayActivity() and canReceive then
            CanvasGroup.alpha = 1
            self:SetButtonClickHandler(getBtn, function()                
                ActivityUI:GetActivityData("gift", v.id, true)
                ActivityUI:GetActivityGife("day", v.id)
                GameSDKs:TrackForeign("activity_reward", {id = v.id, type = 1}) 
                LocalDataManager:WriteToFile()
                self:Refresh()
            end)
        elseif v.require > ActivityUI:GetDayActivity() and canReceive then
            CanvasGroup.alpha = 1
            self:SetButtonClickHandler(getBtn, function()
                self:OpenInfo(go, v) 
            end)
        else
            self:GetGo(go, "received"):SetActive(true)              
            CanvasGroup.alpha = 0.5            
        end                
    end
    block:SetActive(false)
end

--复制生成周的block
function ActivityUIView:GenerateWeekBlock()
    local block = self:GetGo("RootPanel/weekReward/rewardHolder/block")
    local parent = block.transform.parent.gameObject
    local index = 1    
    for i= 1, Tools:GetTableSize(self.cfgActivityReward.week)  do
        local k = self.cfgActivityReward.week[1004 + i]
        local v = self.cfgActivityReward.week[1004 + i]
        local go
        local canReceive = ActivityUI:GetActivityData("gift", v.id)
        if self:GetGoOrNil(parent, "block" .. index ) then
            go = self:GetGo(parent, "block" .. index )
        else
            go = GameObject.Instantiate(block, parent.transform)
        end
        go.name = "block" .. index
        self:SetText(go, "num", v.require)
        local icon = self:GetComp(go, "icon", "Image")
        self:SetSprite(icon, "UI_Common", v.icon, nil, true)
        index = index + 1
        local getBtn = self:GetComp(go, "icon", "Button")
        getBtn.interactable = canReceive
        self:GetGo(go, "locked"):SetActive(v.require > ActivityUI:GetWeeklyActivity())
        self:GetGo(go, "unlock"):SetActive(v.require <= ActivityUI:GetWeeklyActivity())
        local CanvasGroup = self:GetComp(go, "", "CanvasGroup")
        if v.require <= ActivityUI:GetWeeklyActivity() and canReceive then
            CanvasGroup.alpha = 1
            self:SetButtonClickHandler(getBtn, function()   
                ActivityUI:GetActivityData("gift", v.id, true)         
                ActivityUI:GetActivityGife("week", v.id)
                GameSDKs:TrackForeign("activity_reward", {id =  v.id, type =2})                
                LocalDataManager:WriteToFile()
                self:Refresh()            
            end)                       
        elseif v.require > ActivityUI:GetWeeklyActivity() and canReceive then
            CanvasGroup.alpha = 1
            self:SetButtonClickHandler(getBtn, function()
                self:OpenInfo(go, v) 
            end)
        else            
            CanvasGroup.alpha = 0.5            
        end
    end
    block:SetActive(false)
end

--刷新列表
function ActivityUIView:RefreshList()
    self.m_list = self:GetComp("RootPanel/task", "ScrollRectEx")    

    self:SetListItemCountFunc(self.m_list, function()        
        return Tools:GetTableSize(self.cfgActivity)
    end)
    self:SetListItemNameFunc(self.m_list, function(index)       
        return "Item"
    end)    
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateList))
    
    self.m_list:UpdateData()
end
--时间显示与检测重置
function ActivityUIView:UpData()
    self:CreateTimer(100, function()
        local timeString = GameTextLoader:ReadText("TXT_ACTIVITY_WEEK_RESET")      
        self:SetText("RootPanel/dailyReward/resetTime/num", TimerMgr:FormatTimeLength(ActivityUI:CountDownToTheDay("day")))
        --self:SetText("RootPanel/weekReward/resetTime/num", string.format(timeString, TimerMgr:FormatTimeLength(ActivityUI:CountDownToTheDay("week"))))
        self:SetText("RootPanel/weekReward/resetTime/num", TimerMgr:FormatTimeLength(ActivityUI:CountDownToTheDay("week")))
    end, true, true)
end

function ActivityUIView:UpdateList(index, tran)
    index = index + 1
    local go = tran.gameObject
    local slider = self:GetComp(go, "frame/progress", "Slider")
    local gotoBtn = self:GetComp(go, "frame/gotoBtn", "Button")
    local getBtn = self:GetComp(go, "frame/claimBtn", "Button")
    local claimed = self:GetGo(go, "frame/claimed")
    local icon = self:GetComp(go, "frame/icon", "Image")
    local h_list = self:SortCfg()
    local cfg = h_list[index]
    local value = ActivityUI:GetEventNum(cfg.id)
    local isSatisfy = value >= cfg.threhold
    local canReceive = ActivityUI:GetActivityData("value", cfg.id)
    claimed:SetActive(not canReceive)
    getBtn.gameObject:SetActive(isSatisfy and canReceive)
    gotoBtn.gameObject:SetActive(not isSatisfy and cfg.is_goto ~= 0 and canReceive)
    --self:GetGo(go, "frame/claimBtn"):SetActive(isSatisfy)
    --self:SetSprite(icon, "UI_Common", self.cfgActivity["100".. index].icon, nil, true)
    self:SetText(go, "frame/detail", GameTextLoader:ReadText(cfg.task_desc)) 
    
    self:SetText(go, "frame/progress/text", value .. "/" .. cfg.threhold)
    slider.value = value / cfg.threhold
    self:SetButtonClickHandler(gotoBtn, function()
        self:GoToTarget(cfg)
    end)
    self:SetButtonClickHandler(getBtn, function()
        getBtn.interactable = false
        ActivityUI:AddDWActivity(cfg.reward)
        local checkClockOutTickets = function(currID)
            if currID == 1001 then
                return 3
            elseif currID == 1002 then
                return 3
            elseif currID == 1003 then
                return 3
            elseif currID == 1004 then
                return 10
            elseif currID == 1005 then
                return 10
            elseif currID == 1006 then
                return 10
            elseif currID == 1007 then
                return 10
            elseif currID == 1008 then
                return 10
            end
            return 0
        end
        GameTableDefine.ClockOutDataManager:AddClockOutTickets(checkClockOutTickets(cfg.id), 2, cfg.id)
        ActivityUI:GetActivityData("value", cfg.id, true)
        SoundEngine:PlaySFX(SoundEngine.BUY_SFX)
        GameSDKs:TrackForeign("daily_task", {id = cfg.id})
        self:Refresh()
        LocalDataManager:WriteToFile()
        MainUI:RefreshActivityHint()--活跃度的红点
    end)    
    self:SetText(go, "frame/reward/num", cfg.reward)    
end

--对数据进行排序
function ActivityUIView:SortCfg()
    local list = {}    
    for i = 1, (Tools:GetTableSize(self.cfgActivity)) do
        local value = ActivityUI:GetEventNum(1000 + i)
        local isSatisfy = value >= self.cfgActivity[1000 + i].threhold
        local canReceive = ActivityUI:GetActivityData("value", 1000 + i)
        if #list == 0 then
            table.insert(list, self.cfgActivity[1000 + i])
        elseif isSatisfy and canReceive then
            table.insert(list, 1, self.cfgActivity[1000 + i])        
        elseif canReceive and not isSatisfy then
            for j,o in ipairs(list) do                
                if not ActivityUI:GetActivityData("value", o.id) then
                    table.insert(list, j, self.cfgActivity[1000 + i])
                    break  
                elseif #list == j then     
                    table.insert(list, j + 1, self.cfgActivity[1000 + i])
                    break                 
                end
            end 
        elseif not canReceive then
            table.insert(list, self.cfgActivity[1000 + i])        
        end    
    end   
    return list 
end

--计算每天或者每周的奖励的数量 -- 弃用了
function ActivityUIView:CalculateReward(type)
    local key
    local num = 0
    if type == "day" then
        key = 1
    elseif type == "week" then
        key = 2
    end
    for k,v in pairs(self.cfgActivityReward) do
        if v.type == key then
            num = num + 1
        end
    end
    return num 
end

--获取最大的每日活跃值
function ActivityUIView:GetMaxDayActivity()
    local maxActivity = 0
    for k,v in pairs(self.cfgActivityReward.day) do
        if v.require > maxActivity then
            maxActivity = v.require
        end
    end
    return maxActivity
end

-- gotoBtn 的具体方法实现
function ActivityUIView:GoToTarget(cfg)
    if cfg.id == 1003 then
        self:DestroyModeUIObject()
        GameTableDefine.PetListUI:GetView() 
    elseif cfg.id == 1007 then
        self:DestroyModeUIObject()
        GameTableDefine.RouletteUI:GetView()
    elseif cfg.id == 1008 then
        ShopUI:TurnTo(1066)
    end
end

--奖励预览
function ActivityUIView:OpenInfo(go, cfg)
    local openFB = self:GetComp(go, "icon/previewFB", "MMFeedbacks")
    if openFB then
        openFB:PlayFeedbacks()
    end
    local infoUI = self:GetGo("preview")
    local sprite = self:GetComp("preview/frame/icon", "Image")
    self:SetSprite(sprite, "UI_Common", cfg.icon, nil, true)
    self:SetButtonClickHandler(self:GetComp("preview/frame/closeBtn","Button"), function()
        local closeFB = self:GetComp(go, "preview/frame/closeBtn/closeFB", "MMFeedbacks")
        if closeFB then
            closeFB:PlayFeedbacks()
        end
    end)       
    local copyItem = function()
        local item = self:GetGo("preview/frame/reward/item")
        local parent = item.transform.parent.gameObject
        local index = 1 
        local goIndex = 1   
        for i = 1,10 do 
            local go
            if self:GetGoOrNil(parent, "item" .. index ) then
                go = self:GetGo(parent, "item" .. index )
            else
                go = GameObject.Instantiate(item, parent.transform)
            end
            go.name = "item" .. index            
            local icon = self:GetComp(go, "icon", "Image")           
            local cfg = CfgMgr.config_shop[cfg.reward[i]]
            if cfg then
                local value = ShopManager:GetValue(cfg)
                if type(value) == "number" then
                    self:SetText(go, "num", Tools:SeparateNumberWithComma(value))
                else 
                    self:SetText(go, "num",  GameTextLoader:ReadText(cfg.name))
                end
                self:SetSprite(icon, "UI_Shop", cfg.icon, nil, true)                
                go:SetActive(true)
                goIndex  = goIndex + 1
            else
                go:SetActive(false)
            end    
            index = index + 1       
        end
        --展示CEO的奖励内容2025-2-24
        if GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
            local ceoItemRewards = cfg.ceo_reward
            for ceoIndex = 1, Tools:GetTableSize(ceoItemRewards) do
                if ceoIndex + goIndex <= 10 then
                    local dispGo = parent.transform:GetChild(ceoIndex + goIndex).gameObject
                    if dispGo then
                        local ceoItemData = ceoItemRewards[ceoIndex]
                        local ceoShopCfg = CfgMgr.config_shop[ceoItemData[1]]
                        local icon = ceoShopCfg.icon
                        local num = ceoShopCfg.amount * ceoItemData[2]
                        self:SetSprite(self:GetComp(dispGo, "icon", "Image"), "UI_Shop", icon, nil, true)
                        self:SetText(dispGo, "num", Tools:SeparateNumberWithComma(num))
                        dispGo:SetActive(true)
                    end
                end
            end
        end
        item:SetActive(false)
    end
    copyItem() 
end

-- 计算总的每日活跃度长
function ActivityUIView:AllRequire()  
    local value = 0       
    for k,v in pairs(self.cfgActivity) do
        value = value + v.reward
    end
    return value
end

--进度条动效控制
function ActivityUIView:SliderMove()
    GameTimer:StopTimer(self.sliderTime)
    local value = ActivityUI:GetDayActivity() / self:GetMaxDayActivity()
    if value > 1 then
        value = 1
    end
    self.sliderTime = GameTimer:CreateNewMilliSecTimer(1, function()         
        if  not self.slider then
            GameTimer:StopTimer(self.sliderTime)            
        end
        if self.slider and self.slider.value  >= value then
            self.slider.value =  value
            GameTimer:StopTimer(self.sliderTime)
            return  
        end
        if self.slider then
            self.slider.value = self.slider.value + 0.01
            self:GenerateBlock()
        end                        
    end, true, true)
end

function ActivityUIView:OnExit()
	self.super:OnExit(self)
    GameTimer:StopTimer(self.sliderTime)   
    self.slider = nil
    self.cfgActivityReward = nil
    self.cfgActivity = nil
    EventDispatcher:TriggerEvent(GameEventDefine.ActivityUIViewClose)
end

return ActivityUIView