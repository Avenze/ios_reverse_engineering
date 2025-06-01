--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-21 13:45:26
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

local InstanceDataManager = GameTableDefine.InstanceDataManager
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local SettingUI = GameTableDefine.SettingUI
local InstanceMilepostUI = GameTableDefine.InstanceMilepostUI
local InstanceProcessUI = GameTableDefine.InstanceProcessUI
local InstanceTimeUI = GameTableDefine.InstanceTimeUI
local InstanceModel = GameTableDefine.InstanceModel
local InstanceShopUI = GameTableDefine.InstanceShopUI
local InstanceAdUI = GameTableDefine.InstanceAdUI
local InstanceTaskManager = GameTableDefine.InstanceTaskManager
local InstanceUnlockUI = GameTableDefine.InstanceUnlockUI
local InstanceBuildingUI = GameTableDefine.InstanceBuildingUI
local GameUIManager = GameTableDefine.GameUIManager

---@class InstanceMainViewUIView:UIBaseView
local InstanceMainViewUIView = Class("InstanceMainViewUIView", UIView)
local notifyPopLength = 10  --通知气泡数量上线
local currentNotifyCount = 0
local empolyeeNotify = nil
local moneyNotify = nil
local milestoneNotify = nil
local notifyList = {}

function InstanceMainViewUIView:ctor()
    self.super:ctor()
    self.m_data = {}

    self.m_milestoneAnimation = nil ---@type UnityEngine.Animation
    --任务系统
    self.m_taskRewardText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskProgressSlider = nil ---@type UnityEngine.UI.Slider
    self.m_taskProgressValueText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskProgressMaxText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskDescribeText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskJumpBtn = nil ---@type UnityEngine.UI.Button

    self.m_taskClaimGO = nil ---@type UnityEngine.GameObject
    self.m_taskClaimRewardText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskClaimProgressSlider = nil ---@type UnityEngine.UI.Slider
    self.m_taskClaimProgressValueText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskClaimProgressMaxText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskClaimDescribeText = nil ---@type UnityEngine.UI.TMPLocalization
    self.m_taskClaimRewardBtn = nil ---@type UnityEngine.UI.Button

    self.m_taskDoneGO = nil ---@type UnityEngine.GameObject
end

function InstanceMainViewUIView:Exit()

    local txt = GameTextLoader:ReadText("TXT_INSTANCE_TIP_RETURN")
    GameTableDefine.ChooseUI:CommonChoose(txt, function()
        self:DestroyModeUIObject()
    end, true, nil)
end

function InstanceMainViewUIView:OnEnter()

    --返回主场景
    self:SetButtonClickHandler(self:GetComp("ReturnBtn","Button"), function()
        self:Exit()
    end)
    --设置按钮
    local settingGo = self:GetGoOrNil("DetailPanel/SettingBtn")
    if settingGo then
        settingGo:SetActive(false)
    end
    self:SetButtonClickHandler(self:GetComp("DetailPanel/SettingBtn","Button"),function()
        -- SettingUI:GetView()
        -- local curLevel = InstanceDataManager:GetCurInstanceKSLevel()
        -- InstanceDataManager:SetCurInstanceKSLevel(curLevel + 1)
    end)
    --打开商店按钮
    self:SetButtonClickHandler(self:GetComp("BottomPanel/ShopBtn","Button"),function()
        InstanceShopUI:GetView()
    end)
    --打开生产线界面
    self:SetButtonClickHandler(self:GetComp("BottomPanel/ProductBtn","Button"),function()
        InstanceProcessUI:ShowView()
    end)

    --时间按钮
    self:SetButtonClickHandler(self:GetComp("ResourceBG/CurrTimeFrame","Button"),function()
        InstanceTimeUI:GetView()
    end)
    --里程碑按钮
    self:SetButtonClickHandler(self:GetComp("DetailPanel/milestone/milestoneBtn","Button"),function()
        InstanceMilepostUI:OpenUI()
    end)

    --点击工人按钮
    self:SetButtonClickHandler(self:GetComp("ResourceBG/EmployeeInterface","Button"),function()
        self:GetGo("HelpInfo_employee"):SetActive(true)
        local hungry,physical,debugWorker = self:GetDebuffCount()
        --state
        self:GetGo("HelpInfo_employee/frame/state/info/hunger"):SetActive(hungry > 0)
        self:GetGo("HelpInfo_employee/frame/state/info/physical"):SetActive(physical > 0)
        self:SetText("HelpInfo_employee/frame/state/info/hunger/num",hungry)
        self:SetText("HelpInfo_employee/frame/state/info/physical/num",physical)
        --desc
        self:GetGo("HelpInfo_employee/frame/desc/hunger"):SetActive(hungry > 0)
        self:GetGo("HelpInfo_employee/frame/desc/physical"):SetActive(physical > 0)
        local hungryStr1 = GameTextLoader:ReadText("TXT_INSTANCE_TIP_HUNGER")
        local hungryStr = string.gsub(hungryStr1,"{0}",tostring(hungry))
        local physicalStr1 = GameTextLoader:ReadText("TXT_INSTANCE_TIP_PHYSICAL")
        local physicalStr = string.gsub(physicalStr1,"{0}",tostring(physical))
        self:SetText("HelpInfo_employee/frame/desc/hunger",hungryStr)
        self:SetText("HelpInfo_employee/frame/desc/physical",physicalStr)
    end)

    --EventInstance按钮
    self:SetButtonClickHandler(self:GetComp("EventArea/IAA","Button"),function() 
        InstanceAdUI:GetView()
    end)


    self.m_milestoneAnimation = self:GetComp("DetailPanel/milestone","Animation")
    --任务系统
    --进行中
    self.m_taskOnGoingGO = self:GetGo("DetailPanel/milestone/task/ongoing")
    self.m_taskRewardText = self:GetComp("DetailPanel/milestone/task/ongoing/reward/txt","TMPLocalization")
    self.m_taskProgressSlider = self:GetComp("DetailPanel/milestone/task/ongoing/prog","Slider")
    self.m_taskProgressValueText = self:GetComp("DetailPanel/milestone/task/ongoing/prog/prog_txt/progress","TMPLocalization")
    self.m_taskProgressMaxText = self:GetComp("DetailPanel/milestone/task/ongoing/prog/prog_txt/limit","TMPLocalization")
    self.m_taskDescribeText = self:GetComp("DetailPanel/milestone/task/ongoing/desc","TMPLocalization")
    self.m_taskJumpBtn = self:GetComp("DetailPanel/milestone/task/ongoing/GotoBtn","Button")

    --已完成,待领奖
    self.m_taskClaimGO = self:GetGo("DetailPanel/milestone/task/claim")
    self.m_taskClaimRewardText = self:GetComp("DetailPanel/milestone/task/claim/reward/txt","TMPLocalization")
    self.m_taskClaimProgressSlider = self:GetComp("DetailPanel/milestone/task/claim/prog","Slider")
    self.m_taskClaimProgressValueText = self:GetComp("DetailPanel/milestone/task/claim/prog/prog_txt/progress","TMPLocalization")
    self.m_taskClaimProgressMaxText = self:GetComp("DetailPanel/milestone/task/claim/prog/prog_txt/limit","TMPLocalization")
    self.m_taskClaimDescribeText = self:GetComp("DetailPanel/milestone/task/claim/desc","TMPLocalization")
    self.m_taskClaimRewardBtn = self:GetComp("DetailPanel/milestone/task/claim/RewardBtn","Button")
    --全部完成
    self.m_taskDoneGO = self:GetGo("DetailPanel/milestone/task/done")

    self:SetButtonClickHandler(self.m_taskClaimRewardBtn,handler(self,self.CompleteTask))
    self:SetButtonClickHandler(self.m_taskJumpBtn,handler(self,self.JumpToTaskTarget))

    self:InitView()

    ---fengyu添加2023-4-24，检测是否要显示离线奖励UI
    GameTableDefine.InstanceOfflineRewardUI:GetView()
end

function InstanceMainViewUIView:OnExit()
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
	self.super:OnExit(self)
end

function InstanceMainViewUIView:InitView()
    self:Show()
    self:CheckLastOneDay()
    self.timer = GameTimer:CreateNewTimer(0.5,function()
        local curTime = InstanceDataManager:GetCurInstanceTime()
        local hStr = curTime.Hour
        if curTime.Hour < 10 then
            hStr = "0"..curTime.Hour
        end
        local mStr = curTime.Min
        if curTime.Min < 10 then
            mStr = "0"..curTime.Min
        end
        self:SetText("ResourceBG/CurrTimeFrame/CurrTime",string.format("%s:%s",hStr,mStr))
        --local isDay = InstanceModel:IsDay()
        --self:GetGo("ResourceBG/CurrTimeFrame/icon_day"):SetActive(isDay)
        --self:GetGo("ResourceBG/CurrTimeFrame/icon_night"):SetActive(not isDay)
        local curTimeType = InstanceModel.timeType
        for i = 1, 3 do
            self.timeTypeUI[i]:SetActive(i == curTimeType)
        end

        local timeRemaining = InstanceDataManager:GetLeftInstanceTime()
        local h = math.floor( timeRemaining / 3600 )
        local m = math.floor( timeRemaining % 86400 % 3600 /60 )

        local timeStr =  string.format("%dh%dm", h,m)
        self:SetText("DetailPanel/milestone/timer/num",timeStr)

        self:RefreshTaskState()

    end,true,true)

    --初始化通知弹窗
    self:InitNotifyPop(notifyPopLength)
end


function InstanceMainViewUIView:InitNotifyPop(length)
    empolyeeNotify = self:GetGo("DetailPanel/notify/employee")
    moneyNotify = self:GetGo("DetailPanel/notify/money")
    milestoneNotify = self:GetGo("DetailPanel/notify/milestone")

end

--[[
    @desc: 
    author:{author}
    time:2023-05-10 15:37:12
    --@notifyType:1:新员工  2:得钱  3:彩蛋
	--@args: 
    @return:
]]
function InstanceMainViewUIView:CallNotify(notifyType,...)
    if currentNotifyCount < 10 then
        self:GetNotify(notifyType,...)
    else
        local notify1 = notifyList[1]
        table.remove(notifyList,1)
        self:RecycleNotify(notifyType,notify1)
        self:GetNotify(notifyType,...)
    end
    
end

function InstanceMainViewUIView:GetNotify(notifyType,...)
    currentNotifyCount = currentNotifyCount + 1
    if notifyType == 1 then -- 员工
        local callback = function(go,id,...)
            self:SetText(go,"bg/content/txt",GameTextLoader:ReadText("TXT_INSTANCE_NOTIFY_EMPLOYEE"))

            go.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
            local feel = self:GetComp(go,"openFB","MMFeedbacks")
            feel.Events.OnComplete:AddListener(function()
                self:RecycleNotify(notifyType,go)
            end)
            table.insert(notifyList,go)
        end
        Tools:SetTempGo(empolyeeNotify,1,false,callback)
        
    elseif notifyType == 2 then -- 得钱
        local callback = function(go,id,...)
            local money = select (1,...)
            money = Tools:SeparateNumberWithComma(money)
            self:SetText(go,"bg/content/txt","+"..money)
            local resCfg = select (2,...)
            local Image = self:GetComp(go,"bg/category/icon","Image")
            self:SetSprite(Image,"UI_Common",resCfg.icon)

            go.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
            local feel = self:GetComp(go,"openFB","MMFeedbacks")
            feel.Events.OnComplete:AddListener(function()
                self:RecycleNotify(notifyType,go)
            end)
            table.insert(notifyList,go)
        end
        Tools:SetTempGo(moneyNotify,1,false,callback,...)
    elseif notifyType == 3 then -- 得彩蛋
        local callback = function(go,id,...)
            local level = InstanceDataManager:GetCurInstanceKSLevel()
            local rewardID = InstanceDataManager.config_achievement_instance[level].reward_id
            local rewardCfg = InstanceDataManager.config_rewardType_instance[rewardID][1]
            local Image = self:GetComp(go,"bg/category/icon","Image")
            self:SetSprite(Image,"UI_Common",rewardCfg.icon)

            go.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
            local feel = self:GetComp(go,"openFB","MMFeedbacks")
            feel.Events.OnComplete:AddListener(function()
                self:RecycleNotify(notifyType,go)
            end)
        end
        Tools:SetTempGo(milestoneNotify,1,false,callback,...)
    end
end

function InstanceMainViewUIView:RecycleNotify(notifyType,notifyGO)
    for i=1,#notifyList do
        if notifyList[i] == notifyGO then
            table.remove( notifyList,i)
            break
        end
    end
    currentNotifyCount = currentNotifyCount -1
    GameObject.Destroy(notifyGO)
end


function InstanceMainViewUIView:Show()

    --资源栏
    local money = math.floor(InstanceDataManager:GetCurInstanceCoin())  --钱
    local moneyStr = Tools:SeparateNumberWithComma(money)
    self:SetText("ResourceBG/MoneyInterface/num",moneyStr)

    local diamond = ResourceManger:GetDiamond() --钻石
    local diamondStr = Tools:SeparateNumberWithComma(diamond)
    self:SetText("ResourceBG/DiamondInterface/num",diamondStr)

    local hungry,physical,debugWorker,workerCount = self:GetDebuffCount()
    local workerButton = self:GetComp("ResourceBG/EmployeeInterface","Button")
    local worlerIcon = self:GetGo("ResourceBG/EmployeeInterface/tipBtn")
    if debugWorker > 0 then
        local showStr = Tools:ChangeTextColor(debugWorker,"ff0000").."/"..workerCount
        self:SetText("ResourceBG/EmployeeInterface/CurrPeople",showStr)
        workerButton.interactable = true
        worlerIcon:SetActive(true)
    else
        self:SetText("ResourceBG/EmployeeInterface/CurrPeople",workerCount)
        workerButton.interactable = false
        workerButton.interactable = false
        worlerIcon:SetActive(false)
    end
    local timeType1 = self:GetGo("ResourceBG/CurrTimeFrame/1")
    local timeType2 = self:GetGo("ResourceBG/CurrTimeFrame/2")
    local timeType3 = self:GetGo("ResourceBG/CurrTimeFrame/3")
    self.timeTypeUI = {
        [1] = timeType1,
        [2] = timeType2,
        [3] = timeType3
    }

    --里程碑信息栏
    local currentAchievement = InstanceDataManager:GetCurInstanceKSLevel()
    local maxLevel = InstanceModel:GetMaxAchievementLevel()

    local notClaimedLevel = InstanceDataManager:GetNotClaimedLevel()
    local currentLevelScore = InstanceDataManager:GetCurInstanceScore()
    local showNotClaimLevel = notClaimedLevel~=0 and notClaimedLevel<(currentAchievement + 1)

    local targetLevel = showNotClaimLevel and notClaimedLevel or (currentAchievement + 1)

    if targetLevel >=  maxLevel then
        targetLevel = maxLevel
    end
    local achievementConfig = InstanceDataManager.config_achievement_instance[targetLevel]
    local rewardConfig = InstanceDataManager.config_rewardType_instance[achievementConfig.reward_id][1]
    local currentLevelScoreMax = achievementConfig.condition
    currentLevelScore = showNotClaimLevel and currentLevelScoreMax or currentLevelScore
    local currentLevelScoreStr = Tools:SeparateNumberWithComma(currentLevelScore)
    local currentLevelScoreMaxStr = Tools:SeparateNumberWithComma(currentLevelScoreMax)
    self:SetText("DetailPanel/milestone/currentProg/prog/prog_txt/progress",currentLevelScoreStr)
    self:SetText("DetailPanel/milestone/currentProg/prog/prog_txt/limit",currentLevelScoreMaxStr)
    if self.m_milestoneAnimation and self.m_milestoneAnimation.isPlaying then

    else
        local slider = self:GetComp("DetailPanel/milestone/currentProg/prog","Slider")
        slider.minValue = 0
        slider.maxValue = 1
        slider.value = currentLevelScore/currentLevelScoreMax
    end
    self:SetText("DetailPanel/milestone/currentProg/reward/txt","x"..achievementConfig.reward_num)
    self:SetImageSprite("DetailPanel/milestone/currentProg/reward/icon",rewardConfig.icon)
    --local eggParent = self:GetGo("DetailPanel/milestone/milestoneProg/mask/Background/rewards")
    --for k,v in pairs(eggParent.transform) do
    --    local name = v.gameObject.name
    --    local outline = self:GetComp(v.gameObject,"","UI_outline")
    --    if tonumber(name) <= currentAchievement then
    --        outline.OutlineWidth = 17
    --    else
    --        outline.OutlineWidth = 0
    --    end
    --end
    --local rect = self:GetComp("DetailPanel/milestone/milestoneProg/mask/Background","RectTransform")
    --if currentAchievement > 4 and currentAchievement <= 8 then
    --    rect.anchoredPosition3D = Vector3(-425,rect.anchoredPosition3D.y,rect.anchoredPosition3D.z)
    --elseif currentAchievement > 8 then
    --    rect.anchoredPosition3D = Vector3(-850,rect.anchoredPosition3D.y,rect.anchoredPosition3D.z)
    --end
    --提醒有里程碑奖励没有领取
    self:RefreshRewardAnim()
    self:RefreshPackButton()

end

---提醒有里程碑奖励没有领取
function InstanceMainViewUIView:RefreshRewardAnim()
    local rewardAnim = self:GetComp("DetailPanel/milestone/currentProg/reward","Animation")
    if rewardAnim then
        local needShowRewardAnim = InstanceDataManager:IsAnyRewardCanClaim()
        if needShowRewardAnim then
            rewardAnim:Play()
            self:GetGo("DetailPanel/milestone/currentProg/reward/vfx_charge_1"):SetActive(true)
            self:GetGo("DetailPanel/milestone/currentProg/reward/vfx_charge_2"):SetActive(true)
        else
            AnimationUtil.Reset(rewardAnim,"instance_charge")
            self:GetGo("DetailPanel/milestone/currentProg/reward/vfx_charge_1"):SetActive(false)
            self:GetGo("DetailPanel/milestone/currentProg/reward/vfx_charge_2"):SetActive(false)
        end
    end
end

function InstanceMainViewUIView:GetShowScoreAndShowMaxScore()
    if true then
        return 1, 1
    end
    local currentAchievement = InstanceDataManager:GetCurInstanceKSLevel()
    local maxLevel = InstanceModel:GetMaxAchievementLevel()

    local notClaimedLevel = InstanceDataManager:GetNotClaimedLevel()
    local showScore = InstanceDataManager:GetCurInstanceScore()
    local showNotClaimLevel = notClaimedLevel~=0 and notClaimedLevel<(currentAchievement + 1)

    local targetLevel = showNotClaimLevel and notClaimedLevel or (currentAchievement + 1)

    if targetLevel >=  maxLevel then
        targetLevel = maxLevel
    end
    local achievementConfig = InstanceDataManager.config_achievement_instance[targetLevel]
    local showMaxScore = achievementConfig.condition
    showScore = showNotClaimLevel and showMaxScore or showScore

    return showScore,showMaxScore
end

function InstanceMainViewUIView:GetDebuffCount()
    local workers = InstanceModel.workerList
    local hungry,physical,debugWorker,allWorker = 0,0,0,0
    local stateThreshold = InstanceDataManager.config_global.stateThreshold
    for k,v in pairs(workers) do
        if next(v) ~= nil then
            for _,furIndex in pairs(v) do
                local attrs = InstanceModel:GetWorkerAttr(k,furIndex)
                allWorker = allWorker + 1
                if attrs.hungry < stateThreshold or attrs.physical < stateThreshold  then
                    debugWorker = debugWorker + 1
                    if attrs.hungry < stateThreshold  then
                        hungry = hungry + 1
                    end
                    if attrs.physical < stateThreshold  then
                        physical = physical + 1
                    end
                end
            end
        end
    end

    return hungry,physical,debugWorker,allWorker
end

function InstanceMainViewUIView:GetMaxAchievementLevel()
    local config = InstanceDataManager.config_achievement_instance
    local result = 0
    for k,v in pairs(config) do
        if v.level >= result then
            result = v.level
        end
    end
    return result
end


function InstanceMainViewUIView:SetAchievementActive(active)
    self:GetGo("DetailPanel/milestone"):SetActive(active)
    self:GetGo("DetailPanel/SettingBtn"):SetActive(false)
    if active then
        self:RefreshRewardAnim()
    end
end

function InstanceMainViewUIView:SetEventActive(active)
    self:GetGo("EventArea"):SetActive(active)
end

function InstanceMainViewUIView:SetEventIAAActive(active)
    self:GetGo("EventArea/IAA"):SetActive(active)
end

function InstanceMainViewUIView:SetPackActive(active)
    self:GetGo("DetailPanel/GiftPack"):SetActive(active)
end

--region 任务系统 Task

---刷新任务系统的UI显示
function InstanceMainViewUIView:RefreshTaskState()
    local taskData = InstanceTaskManager:GetCurrentTaskData()
    if taskData and taskData.taskID ~= 0 and not taskData.obtain then
        self.m_taskDoneGO:SetActive(false)
        local complete,curValue,needValue = InstanceTaskManager:CheckCurTaskComplete()
        local taskConfig = ConfigMgr.config_task_instance[taskData.taskID]

        self.m_taskOnGoingGO:SetActive(not complete)
        self.m_taskClaimGO:SetActive(complete)
        local rewardText,progText,progLimitText,progSlider,descText
        if not complete then
            rewardText = self.m_taskRewardText
            progText = self.m_taskProgressValueText
            progLimitText = self.m_taskProgressMaxText
            progSlider = self.m_taskProgressSlider
            descText = self.m_taskDescribeText
            self.m_taskJumpBtn.gameObject:SetActive(taskConfig.jump==1)
        else
            rewardText = self.m_taskClaimRewardText
            progText = self.m_taskClaimProgressValueText
            progLimitText = self.m_taskClaimProgressMaxText
            progSlider = self.m_taskClaimProgressSlider
            descText = self.m_taskClaimDescribeText
        end

        rewardText.text = tostring(taskConfig.value)
        progText.text = tostring(curValue)
        progLimitText.text = tostring(needValue)
        progSlider.value = curValue/needValue

        if taskConfig.task_type == 1 then
            --房间修建
            local roomName = GameTextLoader:ReadText(InstanceDataManager.config_rooms_instance[taskConfig.type1_roomid].name)
            local str = GameTextLoader:ReadText("TXT_INSTANCE_TASK_TYPE_1")
            str = string.gsub(str, "%[roomName%]", roomName)
            descText.text = str
        elseif taskConfig.task_type == 2 then
            --购买设施
            local str = GameTextLoader:ReadText("TXT_INSTANCE_TASK_TYPE_2")
            str = string.gsub(str, "%[num%]", taskConfig.type2_fur_amount)
            local furName = GameTextLoader:ReadText(ConfigMgr.config_furniture_instance[taskConfig.type2_fur_info[1]].name)
            str = string.gsub(str, "%[furName%]", furName)
            str = string.gsub(str, "%[level%]", taskConfig.type2_fur_info[2])
            descText.text = str
        elseif taskConfig.task_type == 3 then
            --累积货币赚取
            local str = GameTextLoader:ReadText("TXT_INSTANCE_TASK_TYPE_3")
            str = string.gsub(str, "%[cashAmount%]", taskConfig.type3_cash_amount)
            descText.text = str
        end
    else
        self.m_taskOnGoingGO:SetActive(false)
        self.m_taskClaimGO:SetActive(false)
        self.m_taskDoneGO:SetActive(true)
    end
end

---跳转到任务目标
function InstanceMainViewUIView:JumpToTaskTarget()
    local taskData = InstanceTaskManager:GetCurrentTaskData()
    if taskData and taskData.taskID ~= 0 then
        local taskConfig = ConfigMgr.config_task_instance[taskData.taskID]
        if taskConfig then
            if taskConfig.task_type == 1 then
                --房间修建
                self:LocateRoom(taskConfig.type1_roomid)
            elseif taskConfig.task_type == 2 then
                --购买设施
                self:LocateFurniture(taskConfig)
            elseif taskConfig.task_type == 3 then
                --累积货币赚取
            end
        end
    end
end

---跳转到对应需要解锁的
function InstanceMainViewUIView:LocateRoom(roomID,furIndex)
    local curRoomData = InstanceModel.roomsData[roomID]
    if curRoomData then
        if curRoomData.state == 0 then
            --未解锁,显示解锁界面
            GameUIManager:SetEnableTouch(false)
            InstanceModel:LookAtSceneGO(roomID,nil,nil,nil,function()
                local unlock_room = InstanceModel.roomsConfig[roomID].unlock_room
                if InstanceModel:RoomIsUnlock(unlock_room) then
                    InstanceUnlockUI:ShowUI(roomID)
                end
                GameUIManager:SetEnableTouch(true)
            end)
        elseif curRoomData.state == 1 then
            --在解锁中,显示悬浮进度，跳转到对应建筑
            InstanceModel:LookAtSceneGO(roomID)
        elseif curRoomData.state == 2 then
            GameUIManager:SetEnableTouch(false)
            InstanceModel:LookAtSceneGO(roomID,furIndex,nil,nil,function()
                GameUIManager:SetEnableTouch(true)
                --已解锁,显示RoomUI
                local curRoomCfg = InstanceDataManager.config_rooms_instance[roomID]
                if curRoomCfg then
                    if curRoomCfg.room_category == 1 then
                        InstanceBuildingUI:ShowFactoryUI(roomID,furIndex)
                    elseif curRoomCfg.room_category == 2 or curRoomCfg.room_category == 3 then
                        InstanceBuildingUI:ShowSupplyBuildingUI(roomID,furIndex)
                    else
                        InstanceBuildingUI:ShowWharfUI(roomID,furIndex)
                    end
                end
            end)
        end
    end
end

---跳转到对应需要购买的家具
function InstanceMainViewUIView:LocateFurniture(taskConfig)
    local furID,furLevel,roomList = taskConfig.type2_fur_info[1],taskConfig.type2_fur_info[2],taskConfig.type2_fur_room
    local roomID,furIndex = InstanceModel:FirstNeedBuyFurniture(furID,furLevel,roomList)
    if roomID ~= 0 then
        --房间解锁，找到第一个不符合的家具
        self:LocateRoom(roomID,furIndex)
    else
        --房间没解锁,跳转到第一个未解锁房间
        local firstRoomID = roomList[1]
        self:LocateRoom(firstRoomID)
    end
end

---获取任务奖励
function InstanceMainViewUIView:CompleteTask()
    if InstanceTaskManager:CompleteTask() then
        self:Show()
        self:RefreshTaskState()
    end
end

---刷新里程碑
function InstanceMainViewUIView:RefreshMilepost()
    self:Show()
end
--endregion


function InstanceMainViewUIView:RefreshPackButton()
    local packData = {}
    for k, v in pairs(InstanceDataManager.config_achievement_instance) do
        if v.pack ~= 0 and InstanceDataManager:GetCurInstanceKSLevel() >= v.level and GameTableDefine.ShopManager:CheckBuyTimes(v.pack) then
            packData[#packData + 1] = { id = v.pack, icon = v.pack_icon }
        end
    end
    -- 创建礼包btn
    local item = self:GetGo("DetailPanel/GiftPack/temp")
    local num = Tools:GetTableSize(packData)
    self.btnGO = {}
    Tools:SetTempGo(item, num, true, function(go, i)
        local GO = go.gameObject
        local index = i
        self:SetSprite(self:GetComp(GO, "activityIcon", "Image"), "UI_Shop", packData[i].icon)
        local timeStr = self:GetRemainingTimeString()
        self:SetText(GO, "time/num", timeStr)
        self.btnGO[index] = GO
        local btn = self:GetComp(GO, "", "Button")
        self:SetButtonClickHandler(btn, function(args)
            local packID = args[1]
            GameTableDefine.InstancePopUI:ShowGiftPop(packID)
        end, nil, packData[i].id)
    end)

    -- 创建timer循环刷新时间
    if not self.packBtnTimer then
        self.packBtnTimer = GameTimer:CreateNewTimer(1, function()
            local timeStr = self:GetRemainingTimeString()

            for i = 1, #self.btnGO do
                self:SetText(self.btnGO[i], "time/num", timeStr)
            end
        end, true, true)
    end
end

function InstanceMainViewUIView:GetRemainingTimeString()
    local state = InstanceDataManager:GetInstanceState()
    local timeRemaining = 0
    if state == InstanceDataManager.instanceState.isActive then
        timeRemaining = InstanceDataManager:GetLeftInstanceTime()
    else
        GameTimer:StopTimer(self.packBtnTimer)
        self.packBtnTimer = nil
        return
    end
    local timeDate = GameTimeManager:GetTimeLengthDate(timeRemaining)
    local d = timeDate.d
    local h = timeDate.h + d * 24
    local m = timeDate.m
    local s = timeDate.s
    if h < 10 then h = "0"..h end
    if m < 10 then m = "0"..m end
    if s < 10 then s = "0"..s end
    local timeStr = string.format("%s:%s:%s",h,m,s)
    return timeStr
end

function InstanceMainViewUIView:RefreshShopButton()
    self:GetGo("BottomPanel/ShopBtn/icon"):SetActive(InstanceDataManager:IsLastOneDay())
end

function InstanceMainViewUIView:CheckLastOneDay()
    if not self.IsLastOneDay then
        if not self.CheckLastOneDayTimer then
            self.CheckLastOneDayTimer = GameTimer:CreateNewTimer(1, function()
                if InstanceDataManager:IsLastOneDay() then
                    self.IsLastOneDay = true
                    self:RefreshShopButton()
                    GameTimer:StopTimer(self.CheckLastOneDayTimer)
                    self.CheckLastOneDayTimer = nil
                end
            end, true, true)            
        end
    end
end

---播放动画前计算Slider的max,min,value
function InstanceMainViewUIView:RefreshSlider()
    local showScore,showMaxScore = self:GetShowScoreAndShowMaxScore()

    local slider = self:GetComp("DetailPanel/milestone/currentProg/prog","Slider")
    local curProgress = (slider.value-slider.minValue)/(slider.maxValue-slider.minValue)
    local targetProgress = showScore/showMaxScore
    --printf(string.format("curProgress/targetProgress = %.2f/%.2f",curProgress,targetProgress))
    if targetProgress ~= curProgress then
        local len = 1/(targetProgress-curProgress)
        local min = -curProgress*(len)
        local max = min+len
        slider.maxValue = max
        slider.minValue = min
        slider.value = len * curProgress + min
        return true
    else
        return false
    end
end

---播放里程碑分数奖励动画
function InstanceMainViewUIView:PlayMilestoneAnim()
    if self:RefreshSlider() then
        AnimationUtil.Reset(self.m_milestoneAnimation,"instance_integral_Fly")
        self.m_milestoneAnimation:Play()
    end
end

return InstanceMainViewUIView