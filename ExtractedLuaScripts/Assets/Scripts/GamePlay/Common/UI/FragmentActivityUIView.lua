local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ShopManager = GameTableDefine.ShopManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local FragmentActivityUI = GameTableDefine.FragmentActivityUI
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local FeelUtil = CS.Common.Utils.FeelUtil
local CountryMode = GameTableDefine.CountryMode
local ShopUI = GameTableDefine.ShopUI
local TimerMgr = GameTimeManager
local ActivityUI = GameTableDefine.ActivityUI
local GameUIManager = GameTableDefine.GameUIManager
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local starMode = GameTableDefine.StarMode

local FragmentActivityUIView = Class("FragmentActivityUIView", UIView)

local FRAGMENT_TYPE = 
{
    [1] = "pets",          --宠物
    [2] = "staff",         --员工
    [3] = "snacks",        --零食
    [4] = "prop",          --道具
}

function FragmentActivityUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FragmentActivityUIView:OnEnter()
    FragmentActivityUI:GetTaskItemData(true)    --获取任务数据,先获取一次
    self:SetButtonClickHandler(self:GetComp("RootPanel/common/title/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    TimeLimitedActivitiesManager:SetEnterFragment()
    self.cfgReward = FragmentActivityUI:GetRewardCfg()

    self.m_list = self:GetComp("RootPanel/shop/exchange_backup", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return Tools:GetTableSize(self.cfgReward)
    end)    
    self:SetListItemNameFunc(self.m_list, function(index)
        local ordcfg = self:GetOrderCfgByIndex(index + 1 )
        if ordcfg[1].frame[1] == 1 then
            return "Item1"
        else
            return "Item2"
        end       
    end)    
    --设置List的大小
    self:SetListItemSizeFunc(self.m_list, function(index)
        if not self.m_dataSize then
            self.m_dataSize = {}
        end
        local ordcfg = self:GetOrderCfgByIndex(index + 1 )
        if self.m_dataSize[index + 1] then
            return self.m_dataSize[index + 1]
        end
        local frame
        
        if ordcfg[1].frame[1] == 1 then
            frame =  "Item1"
        else
            frame = "Item2"
        end 

        local count = math.floor((#ordcfg))

        local template =  self.m_list:GetItemTemplate(frame)
        local rootTrt = template:GetComponent("RectTransform")
        local trt = self:GetComp(template, "sale", "RectTransform")
        local originSize = rootTrt.rect

        local gridLayoutGroupEx = self:GetComp(template , "sale", "GridLayoutGroupEx")
        if gridLayoutGroupEx and not gridLayoutGroupEx:IsNull() then
            local gridSize = gridLayoutGroupEx:GetSize(math.ceil(count/gridLayoutGroupEx:GetConstraintCount()), 1)
            self.m_dataSize[index + 1] = {x = originSize.width, y = (gridSize.y - trt.anchoredPosition.y) + 20}
        else
            local saleSize = trt.rect
            if saleSize.height > 0 then
                self.m_dataSize[index + 1] = {x = originSize.width, y = saleSize.height - trt.anchoredPosition.y + 20}
            else
                self.m_dataSize[index + 1] = {x = originSize.width, y = originSize.height + 20}
            end
        end
        return self.m_dataSize[index + 1]


    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateItem))

    self:Init()
    self:InitTask()
    self:SetButtonClickHandler(self:GetComp("RootPanel/common/btnPanel/taskBtn", "Button"), function()
        self.m_taskList:UpdateData()
    end)
end

function FragmentActivityUIView:GetOrderCfgByIndex(index)
    local num = 0
    local m_type
    -- for k,v in pairs(self.cfgReward) do
    --     if num == index then
    --         m_type = v
    --         return m_type
    --     end               
    --     num = num + 1 
    -- end
    for i = 1,10000 do
        if self.cfgReward[tostring(i)] then
            num = num + 1            
        end
        if num == index then
            m_type = self.cfgReward[tostring(i)]
            return m_type
        end
    end
end

function FragmentActivityUIView:Init()
    self.cfgActivity = ConfigMgr.config_activity    
    EventManager:RegEvent("REFRESH_FRAGMENT", function()
        self:RefreshFragmentNum()
    end)
    self:Refresh()
    self:UpDataRefresh()
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function FragmentActivityUIView:SetTempGo(go, path ,num, cb)    
    local temp
    if go then
        temp = self:GetGo(go, path)
    else
        temp = self:GetGo(path)
    end    
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    -- for k,v in pairs(parent.transform) do
    --     if temp ~= v.gameObject then
    --         GameObject.Destroy(v.gameObject) 
    --     end               
    -- end
    for i = 1, 10 do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        if i <= num then
            go:SetActive(true)
            go.name = "temp" .. i
            if cb then
                cb(i, go) 
            end 
        else
            go.name = "temp" .. i
            go:SetActive(false)
        end                     
    end          
end

--对单个temp进行设置
function FragmentActivityUIView:SetTemp(index, go)
    self:SetText(go, "num", FragmentActivityUI:GetFragmentNum(index)) 
end

function FragmentActivityUIView:Refresh()
    self:RefreshFragmentNum()
    -- self.m_list = self:GetComp("RootPanel/shop/exchange_backup", "ScrollRectEx")
    -- --设置List的数量
    -- self:SetListItemCountFunc(self.m_list, function()
    --     return Tools:GetTableSize(self.cfgReward)
    -- end)
    -- --设置List中的Item的类型
    -- self:SetListItemNameFunc(self.m_list, function(index)
    --     if self.cfgReward[tostring(index + 1)][1].frame[1] == 1 then
    --         return "Item1"
    --     else
    --         return "Item2"
    --     end
       
    -- end)
    -- --设置List中的Item的具体内容
    -- self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateItem))

    --必备--刷新List数据
    self.m_list:UpdateData(true)
end

function FragmentActivityUIView:UpDataRefresh()
    local TabView = self:GetComp("RootPanel", "TabView")
    local banner = self:GetGo("RootPanel/shop/banner")
    local bool = banner.activeSelf
    self:CreateTimer(1000, function()
        local value, endTime = FragmentActivityUI:GetTimeRemaining()
        if value > 0 then                
            self:SetText("RootPanel/task/bg/banner/timer/txt", TimerMgr:FormatTimeLength(value))
            if ConfigMgr.config_global.fragment_task_refresh == 0 then
                self:SetText("RootPanel/task/bg/list/resetTime/num", TimerMgr:FormatTimeLength(ActivityUI:CountDownToTheDay("day")))
            else
                local TLAData = TimeLimitedActivitiesManager:GetTLAData()
                local start = TLAData.fragment.startTime
                self:SetText("RootPanel/task/bg/list/resetTime/num", TimerMgr:FormatTimeLength(FragmentActivityUI:CountDownToTheTime(start,3600 * ConfigMgr.config_global.fragment_task_refresh_cd)))
            end
         
        elseif endTime > 0 then
            -- if not bool then 
                self:GetGo("RootPanel/common/btnPanel/taskBtn"):SetActive(false)
                self:GetGo("RootPanel/task"):SetActive(false) 
                banner:SetActive(true)
                TabView:SwitchtoTab(0)
                if self.witeTmie then
                    GameTimer:StopTimer(self.witeTmie)
                    self.witeTmie = nil
                end
                self.witeTmie = GameTimer:CreateNewMilliSecTimer(100,function()
                    self.m_list:UpdateData(true)
                end, false, false)                
                bool = true
            -- end            
            self:SetText(banner, "timer/txt", TimerMgr:FormatTimeLength(endTime))
        else
            --结束的显示
            self:StopTimer()
            self:DestroyModeUIObject()                                
        end
    end, true, true)        
end

function FragmentActivityUIView:UpdateItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local cfg = self:GetOrderCfgByIndex(index)
    handleCfg = function() -- 处理一些特殊的情况        
        for k,v in pairs(cfg) do
            if v.shopId == 2010 then
                if ShopManager:GetValue(ConfigMgr.config_shop[v.shopId]) == 0 then
                    cfg[k] = nil
                end
            end
        end
    end
    handleCfg()
    local type = ConfigMgr.config_shop[cfg[1].shopId].type
    self:SetText(go, "title/txt", GameTextLoader:ReadText("TXT_ACTIVITY_FRAME_" .. type))
    self:SetTempGo(go, "sale/temp", #cfg, function(num, go)
        local shopId = cfg[num].shopId
        local shopCfg = ConfigMgr.config_shop[shopId]
        local exchangeBtn = self:GetComp(go, "exchangeBtn", "Button")        
        if  shopId == 0 then
            
            return
        end
        if shopCfg.numLimit == 1 then
            exchangeBtn.interactable = not ShopManager:BoughtBefor(shopId)
        else
            exchangeBtn.interactable = true
        end 
        self:SetText(go, "name/text", GameTextLoader:ReadText(cfg[num].name))      
        self:SetText(go, "exchangeBtn/text", cfg[num].price)
        --local shopCfg =  ConfigMgr.config_shop[shopId]
        --self:SetText("", shopCfg.dose)
        self:SetSprite(self:GetComp(go, "icon", "Image"), "UI_Shop", shopCfg.icon)                                          
        self:SetButtonClickHandler(exchangeBtn, function()

            self:ShowConfim(shopCfg, cfg[num])

        end)
    end)      
end

--显示兑奖页
function FragmentActivityUIView:ShowConfim(shopCfg, rewardCfg)
    local confimGo = self:GetGo("RootPanel/confirmPanel")
    confimGo:SetActive(true)
    local purchasePanelGo = self:GetGo("RootPanel/purchasePanel")
    local detail = self:GetGo(confimGo, "info/content/detail")
    local info = self:GetGo(confimGo, "info/content/info")
    local num = 1
    local fragmentNum = FragmentActivityUI:GetFragmentNum()
    local confirm_openFB = self:GetComp("RootPanel/confirmPanel/confirm_openFB", "MMFeedbacks")
    -- local confirm_closeFB = self:GetComp("RootPanel/confirmPanel/confirm_closeFB", "MMFeedbacks")
    -- confirm_closeFB.Events.OnComplete:AddListener(function()
    --     confimGo:SetActive(false)
    -- end)
    local purchase_openFB = self:GetComp("RootPanel/purchasePanel/purchase_openFB", "MMFeedbacks")
    -- local purchase_closeFB = self:GetComp("RootPanel/purchasePanel/purchase_closeFB", "MMFeedbacks")
    -- purchase_closeFB.Events.OnComplete:AddListener(function()
    --     purchasePanelGo:SetActive(false)
    -- end)
    local exchangeBtn = self:GetComp("RootPanel/confirmPanel/info/content/exchangeBtn", "Button")
    self:SetButtonClickHandler(self:GetComp(confimGo, "bg", "Button"), function()
        --FeelUtil.PlayFeel(confirm_closeFB.gameObject)
        --confimGo:SetActive(false)
    end)        
    --FeelUtil.PlayFeel(confirm_openFB.gameObject)
    self:SetText("RootPanel/confirmPanel/info/title/txt", GameTextLoader:ReadText(rewardCfg.name))
    self:SetSprite(self:GetComp(confimGo, "info/content/reward/icon", "Image"), "UI_Shop", shopCfg.icon)
    RefreshInfo = function(num)
        local addBtn = self:GetComp(detail, "addBtn", "Button")
        local decBtn = self:GetComp(detail, "decBtn", "Button")
        decBtn.interactable = (num > 1)
        --addBtn:SetActive(fragmentNum >= rewardCfg.price * num)
        --exchangeBtn.interactable = fragmentNum >= rewardCfg.price * num        
        self:SetText("RootPanel/confirmPanel/info/content/detail/bg/num", "+" .. num)
        if shopCfg.id == 2009 or shopCfg.id == 2010 then 
            local cashNum = ShopManager:GetValue(shopCfg) * num
            self:SetText("RootPanel/confirmPanel/info/content/detail/bg/num", "+" .. Tools:SeparateNumberWithComma(cashNum))
        end
        self:SetText("RootPanel/confirmPanel/info/content/exchangeBtn/text", rewardCfg.price * num)
        self:SetButtonClickHandler(exchangeBtn, function()
            if fragmentNum >= rewardCfg.price * num then
                FragmentActivityUI:SpendFragment(nil, rewardCfg.price * num, function(isEnough)
                    if isEnough then
                        FragmentActivityUI:GetFragmentReward(rewardCfg, num)
                        GameSDKs:TrackForeign("rank_activity", {name = "Fragment", operation = "3", reward = rewardCfg.shopId, num_new = tonumber(rewardCfg.price * num) or 0})  
                        PurchaseSuccessUI:SuccessBuy(shopCfg.id, nil, nil, num, true)
                    end
                    self:GetComp("RootPanel/confirmPanel/info", "CanvasGroup").alpha = 0 
                    confimGo:SetActive(false)
                    --FeelUtil.PlayFeel(confirm_closeFB.gameObject)
                    self:Refresh()                
                end)
            else           
                purchasePanelGo:SetActive(true)
                --FeelUtil.PlayFeel(purchase_openFB.gameObject)
                local diamondNum = ResMgr.GetDiamond()
                local diamondNeed = (rewardCfg.price * num - fragmentNum) *  ConfigMgr.config_global.fragment_value
                local buyBtn = self:GetComp("RootPanel/purchasePanel/info/buyBtn", "Button")
                local shopBtn = self:GetComp("RootPanel/purchasePanel/info/shopBtn", "Button")
                buyBtn.gameObject:SetActive(diamondNum >= diamondNeed)
                shopBtn.gameObject:SetActive(diamondNum < diamondNeed)
                self:SetText("RootPanel/purchasePanel/info/detail/bg/num", "-" .. diamondNeed)
                self:SetButtonClickHandler(buyBtn, function()
                    ResMgr:SpendDiamond(diamondNeed, nil, function(isEnough)
                        if isEnough then
                            FragmentActivityUI:SpendFragment(nil, fragmentNum, function(isEnough)
                                if isEnough then
                                    FragmentActivityUI:GetFragmentReward(rewardCfg, num)
                                    GameSDKs:TrackForeign("rank_activity", {name = "Fragment", operation = "3", reward = rewardCfg.shopId, num_new = tonumber(fragmentNum) or 0}) 
                                    PurchaseSuccessUI:SuccessBuy(shopCfg.id, nil, nil, num, true)
                                end
                                self:GetComp("RootPanel/confirmPanel/info", "CanvasGroup").alpha = 0
                                confimGo:SetActive(false)
                                --FeelUtil.PlayFeel(confirm_closeFB.gameObject)
                                self:GetComp("RootPanel/purchasePanel/info", "CanvasGroup").alpha = 0
                                purchasePanelGo:SetActive(false)
                                --FeelUtil.PlayFeel(purchase_closeFB.gameObject)
                                FeelUtil.StopFeel(purchase_openFB.gameObject)
                                self:Refresh()
                                --埋点
                                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "活动碎片购买", behaviour = 2, num_new = tonumber(diamondNeed)})
                            end)
                        end
                    end)
                end)
                self:SetButtonClickHandler(shopBtn, function()
                    purchasePanelGo:SetActive(false)
                    --FeelUtil.PlayFeel(purchase_closeFB.gameObject)
                    FeelUtil.StopFeel(purchase_openFB.gameObject)
                    ShopUI:TurnTo(1000)
                end)
                self:SetButtonClickHandler(self:GetComp("RootPanel/purchasePanel/bg", "Button"), function()
                    --purchasePanelGo:SetActive(false)
                    --FeelUtil.PlayFeel(purchase_closeFB.gameObject)
                end)
            end
            --FeelUtil.StopFeel(confirm_openFB.gameObject)
        end)
    end 
    if rewardCfg.storage == 1 then
        detail:SetActive(false)
        info:SetActive(true)
        local relCfg = self:GetRelCfg(shopCfg)
        if relCfg.bonus_type == "money_enhance" then
            self:SetSprite(self:GetComp(info, "bg/icon", "Image"), "UI_Shop", "icon_shop_income")
            self:SetText(info, "bg/num", "+" .. relCfg.bonus_effect[1] * 100 .. "%")
        elseif relCfg.bonus_type == "offline_limit" then
            self:SetSprite(self:GetComp(info, "bg/icon", "Image"), "UI_Shop", "icon_shop_offline")
            self:SetText(info, "bg/num", "+" .. relCfg.bonus_effect[1])
        elseif relCfg.bonus_type == "mood_improve" then
            self:SetSprite(self:GetComp(info, "bg/icon", "Image"), "UI_Shop", "icon_shop_mood")
            self:SetText(info, "bg/num", "+" .. relCfg.bonus_effect[1])
        end                
        --self:SetText(info, "bg/num", "+" .. relCfg.bonus_effect[1])
        RefreshInfo(num)
    else
        detail:SetActive(true)
        info:SetActive(false)
        RefreshInfo(num)
        self:SetButtonClickHandler(self:GetComp(detail, "addBtn", "Button"), function()
            num = num + 1
            RefreshInfo(num)
        end)
        self:SetButtonClickHandler(self:GetComp(detail, "decBtn", "Button"), function()
            num = num - 1
            RefreshInfo(num)
        end)
    end         
end

--任务UI初始化
function FragmentActivityUIView:InitTask()
    self.m_taskList = self:GetComp("RootPanel/task/bg/list", "ScrollRectEx")
    --设置List的数量
    self:SetListItemCountFunc(self.m_taskList, function()
        return Tools:GetTableSize(self.cfgActivity)
    end)
    --设置List中的Item的类型
    self:SetListItemNameFunc(self.m_taskList, function(index)
        return "Item"
    end)
    --设置List中的Item的具体内容
    self:SetListUpdateFunc(self.m_taskList, handler(self, self.UpdateTaskItem))

    --必备--刷新List数据
    self.m_taskList:UpdateData()    
end

--刷新任务的Item
function FragmentActivityUIView:UpdateTaskItem(index, tran)
    index = index + 1
    local data = FragmentActivityUI:GetTaskItemData()[index]                 
    --local idNum = index + 1000
    local go = tran.gameObject
    self:GetGo(go, "frame_1"):SetActive(data.state == 1)
    self:GetGo(go, "frame_2"):SetActive(data.state == 2)
    self:GetGo(go, "frame_3"):SetActive(data.state == 3)
    --local state = FragmentActivityUI:CheckTaskState(index + 1000)
    go = self:GetGo(go, "frame_" .. data.state)
    --go:SetActive(true)
    self:SetText(go, "detail", GameTextLoader:ReadText("TXT_ACTIVITY_TASK_" .. data.id - 1000))
    self:SetText(go, "reward/num", data.reward_activity) 
    local claimBtn = self:GetComp(go, "claimBtn", "Button")
    local goBtn = self:GetComp(go, "goBtn", "Button")
    --local value = FragmentActivityUI:GetIntegral(self.cfgActivity[idNum].id)
    local value = data.value or 0
    if  value >= data.threhold_activity then
        value = data.threhold_activity
    end
    self:SetText(go, "progress/text", value .. "/" .. data.threhold_activity)
    local slider = self:GetComp(go, "progress", "Slider")
    claimBtn.interactable = (value == data.threhold_activity and FragmentActivityUI:CheckFragmentTaskCanfinish(data))
    claimBtn.gameObject:SetActive(value == data.threhold_activity) --and FragmentActivityUI:CheckFragmentTaskCanfinish(self.cfgActivity[idNum]))
    goBtn.gameObject:SetActive(claimBtn.gameObject.activeSelf == false and data.is_goto == 1 and data.canFinish)
    if data.id == 1007 then
        goBtn.gameObject:SetActive(starMode:GetStar() >= ConfigMgr.config_global.wheel_condition and claimBtn.gameObject.activeSelf == false and data.is_goto == 1 and data.canFinish)
    end
    slider.value = value / data.threhold_activity
    self:SetButtonClickHandler(goBtn, function()
        self:GoToTarget(data)
    end)
    self:SetButtonClickHandler(claimBtn, function()
        FragmentActivityUI:ReceiveTaskRewards(data)
        FragmentActivityUI:GetTaskItemData(true)       
        self.m_taskList:UpdateData()
        EventManager:DispatchEvent("FLY_ICON", nil, 102, nil)
        --GameTableDefine.FlyIconsUI:ShowMoveAn(100) 
        --埋点2024-1-22要求取消
        -- GameSDKs:TrackForeign("fragment_task_id", {id = data.id})
        
    end)           
end

function FragmentActivityUIView:UpdateDataAndItems() 
    self.m_taskList:UpdateData()           
end

--gotoBtn 的具体方法实现
function FragmentActivityUIView:GoToTarget(cfg)
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

--刷新碎片显示
function FragmentActivityUIView:RefreshFragmentNum()
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI) then
        self:SetTempGo(nil, "RootPanel/common/title/res/1", 1, function(index, go)
            self:SetTemp(FRAGMENT_TYPE[index], go)        
        end)
    end
end

function FragmentActivityUIView:OnExit()
	self.super:OnExit(self)
    if self.witeTmie then
        GameTimer:StopTimer(self.witeTmie)
        self.witeTmie = nil
    end
    self:StopTimer()
end
 
function FragmentActivityUIView:GetRelCfg(orCfg, RelCfg)
    local RelCfg
    if orCfg.type == 13 then
        RelCfg = ConfigMgr.config_pets
    elseif orCfg.type == 14 then
        RelCfg = ConfigMgr.config_employees
    elseif orCfg.type == 20 then
        RelCfg = ConfigMgr.config_equipment
    end
    for k,v in pairs(RelCfg) do
        if v.shopId == orCfg.id then
            return v
        end
    end
end

function FragmentActivityUIView:OpenGuidePanel()
    self:GetGo("RootPanel/tipsPanel"):SetActive(true)
end


return FragmentActivityUIView