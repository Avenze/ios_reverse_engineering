local SeasonPassUIView = require("GamePlay.Common.UI.SeasonPassUIView")
local TaskManager = GameTableDefine.SeasonPassTaskManager
local GameObject = CS.UnityEngine.GameObject
local EventManager = require("Framework.Event.Manager")
local AnimationUtil = CS.Common.Utils.AnimationUtil ---@type Common.Utils.AnimationUtil

function SeasonPassUIView:ctorTask()
    self.dayTaskItemGoList = {}
    self.weekTaskItemGoList = {}
    self.weekTaskItemAnimator = {}
end

---加载完这一界面时调用
function SeasonPassUIView:OnEnterTaskView()
    self.taskRootGo = self.m_subGODic[SeasonPassUIView.PageType.Task]
    self.dayTitlePanelGo = self:GetGoOrNil(self.taskRootGo, "ScrollView/Viewport/Content/dailyPanel")
    self.weekTitlePanelGo = self:GetGoOrNil(self.taskRootGo, "ScrollView/Viewport/Content/weekPanel")
    local dayItemGo = self:GetGoOrNil(self.taskRootGo, "ScrollView/Viewport/Content/dayTaskItem_1")
    self.dayListTranParent = dayItemGo.transform.parent
    if Tools:GetTableSize(self.dayTaskItemGoList) <= 0 then
        table.insert(self.dayTaskItemGoList, dayItemGo)
    end
    local weekItemGo = self:GetGoOrNil(self.taskRootGo, "ScrollView/Viewport/Content/weekTaskItem_1")
    self.weekListTranParent = weekItemGo.transform.parent
    if Tools:GetTableSize(self.weekTaskItemGoList) <= 0 then
        table.insert(self.weekTaskItemGoList, weekItemGo)
    end
    self.tasksItemList = self:GetComp(self.taskRootGo, "ScrollView", "ScrollRectEx")
    self.m_rewardTaskLevelText = self:GetComp(self.taskRootGo,"titleBanel/titleLevel/bg/num","TMPLocalization")
    self.m_rewardTaskExpNowText = self:GetComp(self.taskRootGo,"titleBanel/rewardHolder/have","TMPLocalization")
    self.m_rewardTaskExpNeedText = self:GetComp(self.taskRootGo,"titleBanel/rewardHolder/all","TMPLocalization")
    self.m_rewardTaskLevelSlider = self:GetComp(self.taskRootGo,"titleBanel/levelProg","Slider")
    self.m_rewardTaskLevelMaxSlider = self:GetComp(self.taskRootGo,"titleBanel/levelProgMax","Slider")
    self.m_rewardTaskBuyLevelBtn = self:GetComp(self.taskRootGo, "titleBanel/buyBtn", "Button")
    self:SetButtonClickHandler(self.m_rewardTaskBuyLevelBtn,function()
        self:OnBuyLevelBtnDown()
        self:UpdateTaskViewLevelAndExp()
    end)

    self.taskTipsGo = self:GetGo("RootPanel/tabPanel/taskBtn/select/tip")
    self.taskTipsGoNormal = self:GetGo("RootPanel/tabPanel/taskBtn/normal/tip")
end

---显示这一界面时调用
function SeasonPassUIView:OnShowTaskView()
    local dayTaskDatas = TaskManager:GetDayTaskData()
    if Tools:GetTableSize(dayTaskDatas) > 0 then
        if Tools:GetTableSize(self.dayTaskItemGoList) > Tools:GetTableSize(dayTaskDatas) then
            for i = 1, Tools:GetTableSize(self.dayTaskItemGoList), 1 do
                if i > Tools:GetTableSize(dayTaskDatas) then
                    self.dayTaskItemGoList[i]:SetActive(false)
                end
            end
        elseif Tools:GetTableSize(self.dayTaskItemGoList) < Tools:GetTableSize(dayTaskDatas) then
            local createNum = Tools:GetTableSize(self.dayTaskItemGoList)
            for i = 1, Tools:GetTableSize(dayTaskDatas) - createNum do
                local curAddIndex = self.dayTaskItemGoList[Tools:GetTableSize(self.dayTaskItemGoList)].transform:GetSiblingIndex() + 1
                local addItemGo = GameObject.Instantiate(self.dayTaskItemGoList[1], self.dayListTranParent)
                addItemGo.transform:SetSiblingIndex(curAddIndex)
                table.insert(self.dayTaskItemGoList, addItemGo)
            end
        end
    end
    local weekTaskDatas = TaskManager:GetWeekTaskData()
    if Tools:GetTableSize(weekTaskDatas) > 0 then
        if Tools:GetTableSize(self.weekTaskItemGoList) > Tools:GetTableSize(weekTaskDatas) then
            for i = 1, Tools:GetTableSize(self.weekTaskItemGoList), 1 do
                if i > Tools:GetTableSize(weekTaskDatas) then
                    self.weekTaskItemGoList[i]:SetActive(false)
                end
            end
        elseif Tools:GetTableSize(self.weekTaskItemGoList) < Tools:GetTableSize(weekTaskDatas) then
            local createNum = Tools:GetTableSize(self.weekTaskItemGoList)
            for i = 1, Tools:GetTableSize(weekTaskDatas) - createNum do
                local curAddIndex = self.weekTaskItemGoList[Tools:GetTableSize(self.weekTaskItemGoList)].transform:GetSiblingIndex() + 1
                local addItemGo = GameObject.Instantiate(self.weekTaskItemGoList[1], self.weekListTranParent)
                addItemGo.transform:SetSiblingIndex(curAddIndex)
                table.insert(self.weekTaskItemGoList, addItemGo)
            end
        end
    end
    --初始化周任务条目的动画状态
    for _, itemGo in pairs(self.weekTaskItemGoList) do
        local animator = self:GetComp(itemGo, "", "Animator")
        table.insert(self.weekTaskItemAnimator, animator)
    end
    EventManager:RegEvent("EVENT_SEASONTASK_DAY_REFRESH", function(go)
        self:RefreshTaskDayItemContent()
        self:RefreshTaskHintPoint()
    end)
    EventManager:RegEvent("EVENT_SEASONTASK_WEEK_REFRESH", function(go)
        self:RefreshTaskWeekItemContent()
        self:RefreshTaskHintPoint()
    end)
    
    if self.taskRefreshTimer then
        GameTimer:StopTimer(self.taskRefreshTimer)
        self.taskRefreshTimer = nil
    end
    self.taskRefreshTimer = GameTimer:CreateNewTimer(1, function()
        self:RefreshTaskCDTime()
    end, true, true)
 
    self:UpdateTaskViewLevelAndExp()
    self:RefreshTaskDayItemContent()
    self:RefreshTaskWeekItemContent()
    self:RefreshTaskHintPoint()
end

---离开这一界面或关闭整个界面(当前正在此界面)时调用
function SeasonPassUIView:OnExitTaskView(isCloseView)
    if self.taskRefreshTimer then
        GameTimer:StopTimer(self.taskRefreshTimer)
        self.taskRefreshTimer = nil
    end
    EventManager:UnregEvent("EVENT_SEASONTASK_DAY_REFRESH")
    EventManager:UnregEvent("EVENT_SEASONTASK_WEEK_REFRESH")
end

function SeasonPassUIView:RefreshTaskDayItemContent()
    local dayTaskDatas = TaskManager:GetDayTaskData()
    local keys = {}
    local seenKeys = {}
    for k, v in pairs(dayTaskDatas) do
        if not seenKeys[k] then
            if v.curState == 1 then
                table.insert(keys, k)
                seenKeys[k] = true
            end
        end
    end
    for k, v in pairs(dayTaskDatas) do
        if not seenKeys[k] then
            if v.curState == 0 then
                table.insert(keys, k)
                seenKeys[k] = true
            end
        end
    end
    for k, v in pairs(dayTaskDatas) do
        if not seenKeys[k] then
            table.insert(keys, k)
        end
    end
    
    local complateNum = 0
    -- local itemIndex = 1
    for itemIndex, key in ipairs(keys) do
        local taskData = dayTaskDatas[key]
        if taskData.curState == 2 then
            complateNum  = complateNum + 1
        end
        if itemIndex <= Tools:GetTableSize(self.dayTaskItemGoList) then
            local itemGO = self.dayTaskItemGoList[itemIndex]
            -- local slider = self:GetComp(itemGO, "frame/progress", "Slider")
            local maxProgress = taskData.curTaskCfg.threhold
            if maxProgress == 0 then
                if taskData.curProgress ~= 0 then
                    maxProgress = taskData.curProgress
                else
                    maxProgress = 1
                end
            end
            -- slider.value = taskData.curProgress / maxProgress
            local isComplate = taskData.curProgress == maxProgress
            self:SetText(itemGO, "frame/progressTask/need", tostring(maxProgress))
            local color = "ee161a"
            if isComplate then
                color = "25b256"
            end
            self:SetSprite(self:GetComp(itemGO, "frame/taskIcon", "Image"), "UI_Common", taskData.curTaskCfg.task_icon)
            self:SetText(itemGO, "frame/progressTask/now", tostring(taskData.curProgress), color)
            local taskDescStr = GameTextLoader:ReadText(taskData.curTaskCfg.task_desc)
            local realDescStr = string.gsub(taskDescStr, "%[num%]", tostring(taskData.curTaskCfg.threhold))
            self:SetText(itemGO, "frame/detail", realDescStr)
            self:SetText(itemGO, "frame/reward/num", "x"..taskData.curTaskCfg.reward)
            -- self:SetText(itemGO, "frame/progress/text", tostring(taskData.curProgress).."/"..tostring(taskData.curTaskCfg.threhold))
            local showGotoParam = false
            if taskData.curTaskCfg.group == 3 or taskData.curTaskCfg.group == 5 then
                if taskData.curTaskCfg.group == 3 then
                    if GameTableDefine.StarMode:GetStar() >= 8 then
                        showGotoParam = true
                    end
                elseif taskData.curTaskCfg.group == 5 then
                    showGotoParam = true
                end
            end
            self:GetGo(itemGO, "frame/gotoBtn"):SetActive(taskData.curTaskCfg.is_goto == 1 and taskData.curState == 0 and showGotoParam)
            local gotoBtn = self:GetComp(itemGO, "frame/gotoBtn", "Button")
            if taskData.curTaskCfg.is_goto == 1 and taskData.curState == 0 then
                self:SetButtonClickHandler(gotoBtn, function()
                    if GameStateManager:CheckStateIsCurrentState(GameStateManager.GAME_STATE_CYCLE_INSTANCE) then
                        return
                    end
                    if taskData.curTaskCfg.group == 3 or taskData.curTaskCfg.group == 5 then
                        if taskData.curTaskCfg.group == 3 then
                            EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", true)
                            --GameTableDefine.UIPopupManager:ClearQueuePopView()
                            GameTableDefine.RouletteUI:GetView()
                            self:DestroyModeUIObject()
                            
                        elseif taskData.curTaskCfg.group == 5 then
                            EventDispatcher:TriggerEvent("BLOCK_POP_VIEW", true)
                            --GameTableDefine.UIPopupManager:ClearQueuePopView()
                            self:OpenConditonRoomUI()
                            self:DestroyModeUIObject()
                        end
                    end
                end)
            end
            self:GetGo(itemGO, "frame/claimBtn"):SetActive(taskData.curState == 1 or (taskData.curState == 0 and not showGotoParam))
            local claimBtn = self:GetComp(itemGO, "frame/claimBtn", "Button")
            if taskData.curState == 1 then
                claimBtn.interactable = true
                self:SetButtonClickHandler(claimBtn, function()
                    claimBtn.interactable = false
                    GameTableDefine.SeasonPassTaskManager:ClaimedDayTask(taskData.curTaskCfg.group,function(exp) 
                        if exp > 0 then
                            self:UpdateTaskViewLevelAndExp()
                            self:RefreshTaskDayItemContent()
                            self:RefreshTaskHintPoint()
                            local flyData = {{id="exp", num=exp}}
                            self:FlyIcon(flyData, nil)
                        end
                    end)
                end)
            elseif taskData.curState == 0 then
                claimBtn.interactable = false
            end
            self:GetGo(itemGO, "frame/claimedBtn"):SetActive(taskData.curState == 2)
            self:GetGo(itemGO, "frame/progressTask"):SetActive(taskData.curState ~= 2)
        end
    end
    self:SetText(self.dayTitlePanelGo, "progress/all", tostring(Tools:GetTableSize(dayTaskDatas)))
    self:SetText(self.dayTitlePanelGo, "progress/have", tostring(complateNum))
end

function SeasonPassUIView:RefreshTaskWeekItemContent()
    local weekTaskDatas = TaskManager:GetWeekTaskData()
    local keys = {}
    local seenKeys = {}
    for k, v in pairs(weekTaskDatas) do
        if not seenKeys[k] then
            if v.curState == 1 then
                table.insert(keys, k)
                seenKeys[k] = true
            end
        end
    end
    for k, v in pairs(weekTaskDatas) do
        if not seenKeys[k] then
            if v.curState == 0 then
                table.insert(keys, k)
                seenKeys[k] = true
            end
        end
    end
    for k, v in pairs(weekTaskDatas) do
        if not seenKeys[k] then
            table.insert(keys, k)
        end
    end
    
    local complateNum = 0
    -- local itemIndex = 1
    for itemIndex, key in ipairs(keys) do
        local taskData = weekTaskDatas[key]
        if taskData.curState == 2 then
            complateNum  = complateNum + taskData.curStep
        else
            complateNum  = complateNum + taskData.curStep - 1
        end
        local curCfg = taskData.curTaskCfg[taskData.curStep]
        local isLast = false
        if not taskData.curTaskCfg[taskData.curStep + 1] then
            isLast = true
        end
        if itemIndex <= Tools:GetTableSize(self.weekTaskItemGoList) then
            local itemGO = self.weekTaskItemGoList[itemIndex]
            -- local slider = self:GetComp(itemGO, "frame_1/progress", "Slider")
            local maxProgress = curCfg.threhold
            if maxProgress == 0 then
                if taskData.curProgress ~= 0 then
                    maxProgress = taskData.curProgress
                else
                    maxProgress = 1
                end
            end
            -- slider.value = taskData.curProgress / maxProgress
            local isComplate = taskData.curProgress >= maxProgress
            local taskDescStr = GameTextLoader:ReadText(curCfg.task_desc)
            local realDescStr = string.gsub(taskDescStr, "%[num%]", tostring(curCfg.threhold))
            self:SetText(itemGO, "frame/progressTask/need", tostring(maxProgress))
            local color = "ee161a"
            if isComplate then
                color = "25b256"
            end
            self:SetSprite(self:GetComp(itemGO, "frame/taskIcon", "Image"), "UI_Common", curCfg.task_icon)
            local nowNumAdujst = taskData.curProgress
            if taskData.curProgress >= curCfg.threhold then
                nowNumAdujst = curCfg.threhold
            end
            self:SetText(itemGO, "frame/progressTask/now", tostring(nowNumAdujst), color)
            self:SetText(itemGO, "frame/detail", realDescStr)
            self:SetText(itemGO, "frame/reward/num", "x"..curCfg.reward)
            -- self:SetText(itemGO, "frame_1/progress/text", tostring(taskData.curProgress).."/"..tostring(curCfg.threhold))
            self:GetGo(itemGO, "frame/gotoBtn"):SetActive(taskData.curState == 0 and curCfg.is_goto == 1)
            local gotoBtn = self:GetComp(itemGO, "frame/gotoBtn", "Button")
            if curCfg.is_goto == 1 and taskData.curState == 0 then
                self:SetButtonClickHandler(gotoBtn, function()
                    if curCfg.group == 2 then
                        self:ChangePage(SeasonPassUIView.PageType.Game)
                    end
                end)
            end
            self:GetGo(itemGO, "frame/claimBtn"):SetActive(taskData.curState == 1 or (curCfg.is_goto ~= 1 and taskData.curState == 0))
            local claimBtn = self:GetComp(itemGO, "frame/claimBtn", "Button")
            local curAnimator = self:GetComp(itemGO, "", "Animator")
            if taskData.curState == 1 then
                
                claimBtn.interactable = true
                self:SetButtonClickHandler(claimBtn, function()
                    claimBtn.interactable = false
                    GameTableDefine.SeasonPassTaskManager:ClaimedWeekTask(curCfg.group,function(exp)
                        --播放切换特效 
                        if isLast then
                            self:UpdateTaskViewLevelAndExp()
                            self:RefreshTaskWeekItemContent()
                            self:RefreshTaskHintPoint()
                            local flyData = {{id="exp", num=exp}}
                            self:FlyIcon(flyData, nil)
                        else
                            AnimationUtil.AddKeyFrameEventOnObj(itemGO, "ANIM_END", function()
                                self:UpdateTaskViewLevelAndExp()
                                self:RefreshTaskWeekItemContent()
                                self:RefreshTaskHintPoint()
                                local flyData = {{id="exp", num=exp}}
                                self:FlyIcon(flyData, nil)
                                curAnimator:Play("UI_tuibiji_weekTaskItem_1_normal")
                            end)
                            curAnimator:Play("UI_tuibiji_weekTaskItem_1_done")
                        end
                        
                    end)
                end)
            elseif taskData.curState == 0 then
                claimBtn.interactable = false
            end
            self:GetGo(itemGO, "frame/claimedBtn"):SetActive(taskData.curState == 2)
            self:GetGo(itemGO, "frame/progressTask"):SetActive(taskData.curState ~= 2)
        end
    end
    local maxTaskNum = 0
    if Tools:GetTableSize(weekTaskDatas) > 0 then
        for _, weekItem in pairs(weekTaskDatas) do
            maxTaskNum  = maxTaskNum + Tools:GetTableSize(weekItem.curTaskCfg)
        end
    end
    self:SetText(self.weekTitlePanelGo, "progress/all", tostring(maxTaskNum))
    self:SetText(self.weekTitlePanelGo, "progress/have", tostring(complateNum))
end

--[[
    @desc: 打开符合条件的房间的UI，跳转升级或者购买家具行为
    author:{author}
    time:2024-12-23 10:59:54
    @return:
]]
function SeasonPassUIView:OpenConditonRoomUI()
    local firstRoomID = nil
    local findRoomID = nil
    local firstRoomIndex = nil
    local findRoomIndex = nil
    for key, v in pairs(GameTableDefine.FloorMode:GetAllRoomsLocalData()) do
        local isOffice = string.find(key, "Office_")
        local isFirstOffice = string.find(key, "Office_1")
        if isFirstOffice then
            firstRoomID = GameTableDefine.FloorMode:GetRoomIdByRoomIndex(key)
            firstRoomIndex = key
        end
        if isOffice then
            local roomData = GameTableDefine.FloorMode:GetCurrRoomLocalData(key)
            if roomData then
                -- findRoomID = GameTableDefine.FloorMode:GetRoomIdByRoomIndex(key)
                for _, curData in pairs(roomData.furnitures or {}) do
                    if not curData.isMax then
                        findRoomID = GameTableDefine.FloorMode:GetRoomIdByRoomIndex(key)
                        findRoomIndex = key
                        break
                    end
                end
            end
        end
    end
    if findRoomID and findRoomIndex then
        GameTableDefine.FloorMode:SetCurrRoomInfo(findRoomIndex, findRoomID)
        GameTableDefine.RoomBuildingUI:ShowRoomPanelInfo(findRoomID)
    elseif firstRoomID and firstRoomIndex then
        GameTableDefine.FloorMode:SetCurrRoomInfo(firstRoomIndex, firstRoomID)
        GameTableDefine.RoomBuildingUI:ShowRoomPanelInfo(firstRoomID)
    end
end

function SeasonPassUIView:RefreshTaskCDTime()
    local dayTime = GameTimeManager:FormatTimeLength(GameTableDefine.SeasonPassTaskManager:GetDayRefreshTimeLeft())
    local weekTime = GameTimeManager:FormatTimeLength(GameTableDefine.SeasonPassTaskManager:GetWeekRefreshTimeLeft())
    -- local dayTime = GameTableDefine.SeasonPassTaskManager:GetDayRefreshTimeLeft()
    -- local weekTime = GameTableDefine.SeasonPassTaskManager:GetWeekRefreshTimeLeft()
    self:SetText("ScrollView/Viewport/Content/dailyPanel/coolTime", dayTime)
    self:SetText("ScrollView/Viewport/Content/weekPanel/coolTime", weekTime)
end

function SeasonPassUIView:UpdateTaskViewLevelAndExp()
    local curLevel,maxLevel = GameTableDefine.SeasonPassManager:GetLevelInfo()
    local nowExp,needExp = GameTableDefine.SeasonPassManager:GetExpInfo()
    if curLevel >= maxLevel then
        --curLevel = 20
        self.m_rewardTaskLevelMaxSlider.value = nowExp/ needExp
    else
        self.m_rewardTaskLevelSlider.value = nowExp/ needExp
    end
    self.m_rewardTaskBuyLevelBtn.gameObject:SetActive(curLevel < maxLevel)
    self.m_rewardTaskLevelMaxSlider.gameObject:SetActive(curLevel >= maxLevel)
    
    self.m_rewardTaskLevelText.text = tostring(curLevel >= maxLevel and maxLevel or curLevel)
    self.m_rewardTaskExpNowText.text = tostring(nowExp)
    self.m_rewardTaskExpNeedText.text = tostring(needExp)
    

    self.m_rewardTaskBuyLevelBtn.interactable = curLevel < maxLevel
end

function SeasonPassUIView:RefreshTaskHintPoint()
    local totalNum = GameTableDefine.SeasonPassTaskManager:GetCanClaimTaskTotalNum()
    if not self.taskTipsGo then
        self.taskTipsGo = self:GetGo("RootPanel/tabPanel/taskBtn/select/tip")
    end
    if not self.taskTipsGoNormal then
        self.taskTipsGoNormal = self:GetGo("RootPanel/tabPanel/taskBtn/normal/tip")
    end
    self.taskTipsGo:SetActive(totalNum > 0)
    self.taskTipsGoNormal:SetActive(totalNum > 0)
    if totalNum > 0 then
        self:SetText(self.taskTipsGo, "num", totalNum)
        self:SetText(self.taskTipsGoNormal, "num", totalNum)
    end
end