local FragmentActivityUI = GameTableDefine.FragmentActivityUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local TLAManager = GameTableDefine.TimeLimitedActivitiesManager
local FlyIconsUI = GameTableDefine.FlyIconsUI
local ShopManager = GameTableDefine.ShopManager
local DataName = TLAManager.ActivityList[TLAManager.FRAGMENT]
local GameLauncher = CS.Game.GameLauncher 
local MainUI = GameTableDefine.MainUI 
local StarMode = GameTableDefine.StarMode
local LocalDataManager = LocalDataManager
local UIPopManager = GameTableDefine.UIPopupManager

--碎片类型 -- 现在改为只有一种碎片但是保留设计(防止意外)
FragmentActivityUI.FRAGMENT_TYPE = 
{
    PETS = "pets",          --宠物
    STAFF = "staff",        --员工
    SNACKS = "snacks",      --零食
    PROP = "prop",          --道具
}

function FragmentActivityUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI, self.m_view, require("GamePlay.Common.UI.FragmentActivityUIView"), self, self.CloseView)
    return self.m_view
end

function FragmentActivityUI:OpenView(cmd)
    UIPopManager:EnqueuePopView(self,function()
        local view = self:GetView()
        if cmd then
            view:Invoke(cmd)
        end
    end)
end

function FragmentActivityUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI)
    self.m_view = nil
    collectgarbage("collect")
    UIPopManager:DequeuePopView(self)
end

--生成一个Data用于View使用
function FragmentActivityUI:GetModeData(refer)
   if not self.m_data or refer then
    self.m_data = self:GetFragmentData()
   end  
   return self.m_data
end

--初始化碎片活动存档
function FragmentActivityUI:InitFragmentData()
    local tLAData = TLAManager:GetTLAData()
    if not tLAData[DataName] then return end
    if not tLAData[DataName].ordinary_fragments then
        tLAData[DataName].ordinary_fragments = {}
    end
    if not tLAData[DataName].tasks then
        tLAData[DataName].tasks = {}
    end    
    if not tLAData[DataName].probability then
        tLAData[DataName].probability = {}
    end
    if not tLAData[DataName].integral then
        tLAData[DataName].integral = {}
    end
    LocalDataManager:WriteToFile()
    return tLAData[DataName]
end

--初始化GetTaskItem的Data
function FragmentActivityUI:GetTaskItemData(rf)
    RefreshData = function(k)        
        self.taskItemData[k].state = self:CheckTaskState(self.taskItemData[k].id)
        self.taskItemData[k].value = self:GetIntegral(ConfigMgr.config_activity[self.taskItemData[k].id].id)
        self.taskItemData[k].canFinish = self:CheckFragmentTaskCanfinish(self.taskItemData[k])
    end
    StorTaskItemData = function(taskItemData)
        local num = 0 
        local newItemData = {}
        for k,v in pairs(taskItemData) do
            if v.state == 1 then
                num = num + 1 
                newItemData[num] = v
                taskItemData[k] = nil                            
            end
        end
        for k,v in pairs(taskItemData) do
            if v.state == 2 then
                num = num + 1 
                newItemData[num] = v
                taskItemData[k] = nil                            
            end
        end
        for k,v in pairs(taskItemData) do            
            num = num + 1 
            newItemData[num] = v
            taskItemData[k] = nil                                            
        end
        return newItemData
    end    
    if self.taskItemData == nil then
        local index = 0
        self.taskItemData = {}
        for k,v in pairs(ConfigMgr.config_activity) do
            index = index + 1
            local curr = {}            
            curr.id = v.id
            curr.threhold_activity = v.threhold_activity
            curr.reward_activity = v.reward_activity            
            curr.is_goto = v.is_goto
            self.taskItemData[index] = curr
            RefreshData(index)            
        end
        self.taskItemData = StorTaskItemData(self.taskItemData)
    end       
    if rf then
        for k,v in pairs(self.taskItemData) do
            RefreshData(k)            
        end
        self.taskItemData = StorTaskItemData(self.taskItemData)
    end
    return self.taskItemData
end

--获得碎片任务的存档
function FragmentActivityUI:GetFragmentData()
    return self:InitFragmentData()
end

--获得碎片仓库的存档
function FragmentActivityUI:GetOrdinaryFragmentsData()
    local fragmentData = self:GetFragmentData()    
    if not fragmentData or not fragmentData.ordinary_fragments then
        return nil
    end
    return fragmentData.ordinary_fragments
end

--获取碎片任务奖励
function FragmentActivityUI:GetFragmentReward(rewardCfg, num)
    local shopId = rewardCfg.shopId
    num = num or 1
    local afterBuy = function(cfg)--购买后的计数增加,暂时只能这样拆出来
        local save = ShopManager:GetLocalData()
        save["times"] = save["times"] or {}
        local times = save["times"]
        times[""..cfg.id] = (times[""..cfg.id] or 0) + 1
        LocalDataManager:WriteToFile()              
    end
    local cfg = ConfigMgr.config_shop[shopId]
    local value = ShopManager:GetValue(cfg)
    if  type(value) == "number" then
        value = value * num
    end 
    local cb = ShopManager:GetCB(cfg)      
    cb(value , cfg, afterBuy(cfg))    
end

--获取某种碎片的数量
function FragmentActivityUI:GetFragmentNum(type)
    local ordinaryFragments = self:GetOrdinaryFragmentsData()
    if not ordinaryFragments then
        return 0
    end
    type = type or self.FRAGMENT_TYPE.PETS
    local num = LocalDataManager:DecryptField(ordinaryFragments,type)
    return num
end

--获得某种碎片
function FragmentActivityUI:AddFragment(type, num, cb)
    local ordinaryFragments = self:GetOrdinaryFragmentsData()
    if not ordinaryFragments then
        return 
    end
    type = type or self.FRAGMENT_TYPE.PETS
    num = num or 1
    local curNum = LocalDataManager:DecryptField(ordinaryFragments,type)
    curNum = curNum + num
    LocalDataManager:EncryptField(ordinaryFragments,type,curNum)
    --if not ordinaryFragments[type] then
    --    ordinaryFragments[type] = 0
    --end
    --ordinaryFragments[type] = ordinaryFragments[type] + num
    LocalDataManager:WriteToFile()
    EventManager:DispatchEvent("REFRESH_FRAGMENT") 
    if cb then cb() end
end

--消耗碎片
function FragmentActivityUI:SpendFragment(type, num, cb)
    type = type or self.FRAGMENT_TYPE.PETS     
    num = num or 1
    local ordinaryFragments = self:GetOrdinaryFragmentsData()
    if  num == 0 then
        cb(true)
        return
    end
    if  not ordinaryFragments then
        cb(false)
        return
    end
    local curNum = self:GetFragmentNum(type)
    if curNum - num < 0 then
        cb(false)
        return
    end
    curNum = curNum - num
    LocalDataManager:EncryptField(ordinaryFragments,type,curNum)
    --ordinaryFragments[type] = ordinaryFragments[type] - num
    LocalDataManager:WriteToFile()
    EventManager:DispatchEvent("REFRESH_FRAGMENT")
    cb(true)
end

--清空任务的积分
function FragmentActivityUI:ClearFragment(cb)
    local tasks = self:GeTasksData()
    if tasks then
        for k,v in pairs(tasks) do
            tasks[k] = true
        end
    end
	LocalDataManager:WriteToFile()
    local integral = self:GetIntegralData()
    if not integral then return end
    for k,v in pairs(integral) do
        integral[k] = 0
    end
    if cb then cb() end
    LocalDataManager:WriteToFile()
end

--判断当前任务能否完成
function FragmentActivityUI:CheckFragmentTaskCanfinish(cfg)
    local tasksData = self:GeTasksData()
    if not tasksData then return end
    if  tasksData[tostring(cfg.id)] == nil then        
        return true
    end
    return tasksData[tostring(cfg.id)]
end

function FragmentActivityUI:GetTaskState()
    local tasks = self:GetTaskItemData()
    local finishCount = 0
    local haveFinished = false
    for k,v in pairs(tasks) do
        local data = v
        if (data.value or 0) >= data.threhold_activity then
            finishCount = finishCount + 1
            if true then
                haveFinished = self:CheckFragmentTaskCanfinish(data) or haveFinished
            end
        end
    end
    return finishCount, #tasks, haveFinished
end

--剩余的时间值
function FragmentActivityUI:GetTimeRemaining()
    self:GetModeData()
    if not self.m_data or not self.m_data.duration then return 0 , 0 end
    local timeRemaining = self.m_data.duration - GameTimeManager:GetCurrentServerTime(true)
    local timeEnd = self.m_data.endTime - GameTimeManager:GetCurrentServerTime(true)
    return timeRemaining , timeEnd
end

--处理奖励数据并得到
function FragmentActivityUI:GetRewardCfg()
    local cfgReward = ConfigMgr.config_fragment_reward
    local value = 1
    local curr = {}
    for k,v in pairs(cfgReward) do
        local type = v.frame[2]
        if not curr[tostring(type)] then
            curr[tostring(type)] = {}
        end
        table.insert(curr[tostring(type)] ,v)
    end
    return curr
end

--获得任务存档
function FragmentActivityUI:GeTasksData()
    local fragmentData = self:GetFragmentData()    
    if not fragmentData or not fragmentData.tasks then
        return nil
    end
    return fragmentData.tasks
end

--获得掉落率的存档
function FragmentActivityUI:GetProbabilityData()
    local fragmentData = self:GetFragmentData()  
    if not fragmentData or not fragmentData.probability then
        return nil
    end
    return fragmentData.probability
end

--领取碎片任务奖励
function FragmentActivityUI:ReceiveTaskRewards(cfg)
    local tasksData = self:GeTasksData()
    if not tasksData then return end
    if not tasksData[tostring(cfg.id)] then
        tasksData[tostring(cfg.id)] = false
    end
    tasksData[tostring(cfg.id)] = false
    LocalDataManager:WriteToFile()
    FragmentActivityUI:AddFragment(nil, cfg.reward_activity)
    
    GameSDKs:TrackForeign("rank_activity", {name = "Fragment", operation = "4", num_new = tonumber(cfg.reward_activity) or 0, source = 2, type = cfg.id})
end

--获得积分的存档
function FragmentActivityUI:GetIntegralData()
    local fragmentData = self:GetFragmentData()  
    if not fragmentData or not fragmentData.integral then
        return nil
    end
    return fragmentData.integral
end

--获取积分数
function FragmentActivityUI:GetIntegral(id)
    local integralData = self:GetIntegralData()
    if not integralData then return  end 
    if not integralData[tostring(id)] then
        return 0
    end 
    return integralData[tostring(id)]
end

--增加积分
function FragmentActivityUI:AddIntegral(id,cb)
    local integralData = self:GetIntegralData()
    if not integralData then return end 
    if not integralData[tostring(id)] then
        integralData[tostring(id)] = 0
    end       
    integralData[tostring(id)] = integralData[tostring(id)] + 1
    LocalDataManager:WriteToFile()
    local taskCfg = ConfigMgr.config_activity[id]
    if integralData[tostring(id)] == taskCfg.threhold_activity then
        EventManager:DispatchEvent("FLY_ICON", nil, 103, nil)
    end
    if cb then cb(id) end    
end

--完成事件的触发
function FragmentActivityUI:TaskEventTrigger(id)
    if TLAManager:GetTLAStateByCfg(self:GetModeData(), true) ~= 2 then return end -- 1 号活动的状态要是开启状态
    self:AddIntegral(id, function(id)
        self:GetTaskItemData(true) 
        if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI) then
            self:GetView().m_taskList:UpdateData()  
        end
    end) 
    local probabilityData = self:GetProbabilityData()
    if not probabilityData then return end
    local cfgFragmentActivity = ConfigMgr.config_activity
    local cfg 
    for k,v in pairs(cfgFragmentActivity) do
        if v.id == id then
            cfg = v
            break
        end        
    end
    if not cfg then return end    
    if not probabilityData[tostring(id)] then
        probabilityData[tostring(id)] = 0
    end 
    local probability = probabilityData[tostring(id)] + cfg.chance
    local rdm = math.random(0, 100)  
    if rdm <= probability then --获得
        self:AddFragment(nil, cfg.count, function()
        GameSDKs:TrackForeign("rank_activity", {name = "Fragment", operation = "4", num_new = tonumber(cfg.count) or 0, source = 1, type = id})  
        --加碎片回调(表现)
        EventManager:DispatchEvent("FLY_ICON", nil, 100, nil)
        --FlyIconsUI:ShowMoveAn(100)
        end)
        probabilityData[tostring(id)] = 0
    else                       --不获得
        probabilityData[tostring(id)] = probabilityData[tostring(id)] + cfg.addition
    end    
    LocalDataManager:WriteToFile()
    
end 

--任务状态判断
function FragmentActivityUI:CheckTaskState(id)
    local cfg = ConfigMgr.config_activity
    local value = FragmentActivityUI:GetIntegral(cfg[id].id)
    local canfinsh = FragmentActivityUI:CheckFragmentTaskCanfinish(cfg[id])
    if value or 0 < cfg[id].threhold_activity then
        return 2  --能完成但是积分不够
    elseif value >= cfg[id].threhold_activity and canfinsh then
        return 1  --能完成
    else
        return 3  --已领取
    end
end

function FragmentActivityUI:UpdateDataAndItems()
    self:GetTaskItemData(true)
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI) then
        --self:GetView():Invoke("UpdateDataAndItems")
        self:OpenView("UpdateDataAndItems")
    end
end

-- 倒计时到某个时间
function FragmentActivityUI:CountDownToTheTime(startTime, interval, once) -- 开始时时间戳, 时间间隔(s),是否只计算一次间隔
    local oneDay = 3600 * 24
    local now = GameTimeManager:GetCurrentServerTime(true)
    if once then
        local remaining = startTime + interval - now
        if remaining > 0 then
            return remaining
        end
        return 0
    else
        local times = 1
        local remaining = startTime + interval * times - now
        local needRefresh = false
        while remaining < 0 do
            needRefresh = true
            times = times + 1
            remaining = startTime + interval * times - now
        end
        return remaining,needRefresh
    end
end 

function FragmentActivityUI:OpenGuidePanel()
    local tLAData = TLAManager:GetTLAData()
    local fragmentData = tLAData["fragment"]
    local firstEnter, enterDay = TLAManager:CheckIsFirstEnterFragment()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not fragmentData or (enterDay == day) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if self.waitOpenTimer then
        return
    end
    if StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
            GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI) then
        self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(1000,function()
            --GameTimer:StopTimer(self.waitOpenTimer)
            if not (StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
                    GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI)) then
                if not firstEnter then
                    --self:GetView():Invoke("OpenGuidePanel")
                    self:OpenView("OpenGuidePanel")
                    TLAManager:SetIsFirstEnterFragment()
                elseif enterDay ~= day then
                    self:OpenView()
                end
                GameTimer:StopTimer(self.waitOpenTimer)
                self.waitOpenTimer = nil
            end
        end,true,false)
        return 
    end
    if not firstEnter then
        --self:GetView():Invoke("OpenGuidePanel")
        self:OpenView("OpenGuidePanel")
        TLAManager:SetIsFirstEnterFragment()
    elseif enterDay ~= day and not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI) then
        self:OpenView()
    end

end