local EventManager = require("Framework.Event.Manager")

---@class GuideManager
local GuideManager = GameTableDefine.GuideManager
local GuideUI = GameTableDefine.GuideUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local TimerMgr = GameTimeManager
local Event001UI = GameTableDefine.Event001UI
local StarMode = GameTableDefine.StarMode
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local ActorEventManger = GameTableDefine.ActorEventManger
local CompanyMode = GameTableDefine.CompanyMode
local QuestUI = GameTableDefine.QuestUI
local CityMode = GameTableDefine.CityMode
local FactoryMode = GameTableDefine.FactoryMode
local BenameUI = GameTableDefine.BenameUI
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local MainUI = GameTableDefine.MainUI
local GameClockManager = GameTableDefine.GameClockManager
local CountryMode = GameTableDefine.CountryMode
local InstanceDataManager = GameTableDefine.InstanceDataManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local CURR_GUIDE = "guide_data"


GuideManager.EVENT_VIEW_OPEND = 1
GuideManager.EVENT_VIEW_CLOSED = 2

--引导系统,不建议修改

function GuideManager:Init()
    if self.currStep and self.currStep > 0 then--这个Init会被反复调用,每次场景切换完成都会
        self:ConditionToStart()
        return
    end

    self.mSave = LocalDataManager:GetDataByKey(CURR_GUIDE)
    self.mConditions = self:ConditionsBy()
    self.inGuide = false

    self.currStep = -1
    self.endConditions = nil

    self:GetNextStep(1, true)
    self:StepSetting()
end

function GuideManager:Clear()
    self.currStep = nil
    self.mSave = nil
    self.mConditions = nil
    self.endConditions = nil
    self.click = false
    self.autoEnd = false

    self.event001 = nil
    self.employee = nil
    self.bus = nil
    self.event001UI = nil
    self.brokNode = nil
    self.levelCompany = nil
    self.player = nil
    self.elct_lack = nil
    self.timeLineDone = nil

    self.inGuide = false
    self.allDone = false
    self.brokeClick = nil
    self.levelClick = nil
    self.m_dialogCompleteHander = nil
end

function GuideManager:StepSetting()
    if FloorMode:IsInHouse() or FloorMode:IsInCarShop() then--在买车买房不出来
        return
    end
    local scene = FloorMode:GetScene()
    if (scene and scene:ifRoomUnlocked("Office_3")) or not CountryMode:IsFreeCity() then--第三个办公室解锁前,不出特殊npc
        ActorEventManger:stopCreate(false)
    else
        ActorEventManger:stopCreate(true)
    end

    if GameUIManager:IsUIOpenComplete(6) then
        --MainUI:HideButton("MainLinePanel", self:IsShowMainStoryBtn())
        if MainUI.m_view then
            MainUI.m_view:RefreshMainLinePanel(GameStateManager:IsInFloor())
        end
        --MainUI:HideButton("LeaveBtn", self:isShowLeaveBtn())
    end

    local fixeBefor = self.mSave["done13"] or false
    if self:compareStepWith(38, 54, true) and not fixeBefor then
        FloorMode.isRoomBrokenGuide = true
    else
        FloorMode.isRoomBrokenGuide = false
    end
end

---是否显示主线故事按钮,邀请5号办公室入驻后显示
function GuideManager:IsShowMainStoryBtn()
    return self.mSave["invite5"] or false
end

function GuideManager:isShowLeaveBtn()
    --K117改成主线故事1-2完成后显示大地图按钮,18星以后也显示
    if StarMode:GetStar() >= 18 then
        if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CITY_MAP) or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.EUROPE_MAP_UI)then
            return false
        else
            return true
        end
    end
    return GameTableDefine.StoryLineManager:IsCompleteStage(2)
end

function GuideManager:StartStep(step)--立即开启某步引导
    local data = self.StepData(step)
    if not data.id then
        return false
    end
end

--首先会进行这个方法,判断是否开始引导,如果开始,则打开引导界面,并更新相应表现
function GuideManager:ConditionToStart()
    if self.inGuide == nil or self.inGuide == true then
        return
    end

    local d = self:StepData()

    local haveNext = true
    if d.goalConditions and not self:CheckStartCondition(d.goalConditions) then--如果是关键节点,并且已经完成,直接跳到下一步
        local stepEnd = self.currStep < 100 and 100 or 1000
        haveNext = self:GetNextStep(self.currStep + 1, false, false, stepEnd)
        d = self:StepData()
    end
    
    if not haveNext then--做完了某个分支任务,或者主线做完了
        self:GetNextStep(1, true)
        return
    end    
    
    if not d.id then--step为99或者某个支线完成了
        if self.currStep ~= 99 then
            self:GetNextStep(1, true)
        end
        return
    end
      
    if(self:CheckStartCondition(d.startConditions)) then
        self.endConditions = self:Clone(d.endConditions)
        self.inGuide = true
        self:OpenGuideView()

        self:ConditionToEnd()
    end
end

function GuideManager:Clone(object)
    local lookup_table = {}
    local _copy
    _copy = function(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end

        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function GuideManager:makeComplete()
    self.currStep = 99
    self.allDone = true
    GuideUI:CloseView()
end

function GuideManager:JumpToNext()
    local currScene = FloorMode:GetScene()
    if currScene then
        currScene:SetCameraFollowGo(nil)
    end
    --先完成一遍当前的步骤
    local currData = self:StepData()
    local currStep = currData.id

    self:CheckEndCondition(false)

    local endTo = (currStep < 99) and 99 or 500
    self:GetNextStep(nil,nil, true, endTo)
    local toStep = self.currStep
    -- GameSDKs:Track("skip_guide", {guide_id = currStep, guide_name = GameTextLoader:ReadText("TXT_GUIDE_"..currStep)})
    --发送中间所有事件的埋点
    self:TrackGuide(currStep, toStep - 1)
    self:ConditionToStart()
end

function GuideManager:TrackGuide(from, to)
    local cfg = ConfigMgr.config_guide
    for i = from, to do
        if ConfigMgr.config_guide[i] then
            --GameSDKs:Track("guide", {guide_id = i, guide_name = GameTextLoader:ReadText("TXT_GUIDE_"..i)})
            GameSDKs:TrackForeign("guide", {guide_id = i, guide_desc = GameTextLoader:ReadText("TXT_GUIDE_"..i)})
        end
    end
end

--如果满足结束引导的条件,就会关闭界面
function GuideManager:ConditionToEnd(click)
    if not self.inGuide then
        return false
    end

    if self:CheckEndCondition(click) then
        self:EndStep()
        return true
    end
end

function GuideManager:GetSpecialGo(goType)
    if goType == "BrokenItem" then
        return self.brokNode, self.brokeClick
    elseif goType == "LevelUp" then
        return self.levelCompany, self.levelClick
    end
end

function GuideManager:OpenGuideView()
    GuideUI:Show(self:StepData())
end

function GuideManager:unenforceEnd()--非强制引导强行中段
    if self.inGuide then
        local inUnforceGuide = false
        if self:compareStepWith(100, 107, true) then
            inUnforceGuide = true
        end

        if inUnforceGuide then
            GuideUI:CloseView()

            self.inGuide = false
            self.click = false
            self.autoEnd = false
            self.currStep = self.currStep + 1
            self:GetNextStep(1, true)
        end
    end
end

function GuideManager:compareStepWith(from, to, inside)
    if not self.currStep then
        return nil
    end

    if self.currStep >= from and self.currStep <= to then
        return inside == true
    end

    return inside == false
end

function GuideManager:EndStep()
    local d = self:StepData()
    if not d.id then
        return
    end

    --埋点
    --GameSDKs:Track("guide", {guide_id = d.id, guide_name = GameTextLoader:ReadText("TXT_GUIDE_"..d.id)})
    GameSDKs:TrackForeign("guide", {guide_id = d.id, guide_desc = GameTextLoader:ReadText("TXT_GUIDE_"..d.id)})

    self:StepSetting()

    if d.closeAble == 1 then
        GuideUI:CloseView()
    end

    self.inGuide = false
    self.click = false
    self.autoEnd = false
    self.currStep = self.currStep + 1
    self:ConditionToStart()
end

function GuideManager:CheckEndCondition(click)
    if click then
        self.click = true
    end
    
    if not self.endConditions or #self.endConditions == 0 then
        return self.click == true or self.autoEnd == true
    end
    

    local currCondi = nil
    local currTest = nil
    for i = #self.endConditions, 1, -1 do
        currCondi = self.endConditions[i]
        currTest = self.mConditions[currCondi[1]]
        if not currTest or currTest(currCondi) then
            table.remove(self.endConditions, i)
        end
    end

    return #self.endConditions == 0 and (self.click == true or self.autoEnd == true)
end

function GuideManager:GetNextStep(startFrom, toStart, forceRestar, endFrom)
    local lastStep = self.currStep
    if not self.mConditions then--还没初始化好,不开始引导
        return
    end

	if FloorMode:IsInHouse() or FloorMode:IsInCarShop() then--买车买房不出引导
        return
    end

    if not GameConfig:IsGuideEnabled() then--关闭引导开关,不开始引导
        self.currStep = 99
        return false
    end
   
    -- if StarMode:GetStar() >= 100 then--星星大于100就不出引导
    --     self.currStep = 99
    --     return false
    -- end  

    local currBuilding = CityMode:GetCurrentBuilding()

    if currBuilding and currBuilding > 100 then--第二个场景不再引导,但是对老玩家弹出起名界面
        local userName = LocalDataManager:GetBossName()
        if not userName then
            BenameUI:GetView()
        end

        local buildingName = LocalDataManager:GetBuildingName()
        if userName and not buildingName then
            BenameUI:BuildingName()
            self.currStep = 99
            return false
        end

        if not userName or not buildingName then
            BenameUI:GetView()
            self.currStep = 99
            return false
        end        
        return true
    end

    if self.allDone and  startFrom and startFrom < 100 then--所有步骤都完成了,就不再重复计算了
        return false
    end

    if self.inGuide then--已经在引导了
        if forceRestar == true then
            self.inGuide = false
        else
            return
        end
    end
    local haveNext = false
    local from = startFrom and startFrom or self.currStep
    local endFrom = endFrom and endFrom or 99

    local currCondition = {}
    local cfgGuide = ConfigMgr.config_guide
    for k = from, endFrom do
        local tempData = cfgGuide[k]
        if tempData and tempData.goalConditions then
            table.insert(currCondition, tempData)
        end
    end

    for k,v in pairs(currCondition) do
        if( v.goalConditions and self:CheckStartCondition(v.goalConditions)) then
            self.currStep = v.id
            haveNext = true
            break
        end
    end

    if toStart and haveNext then
        self:ConditionToStart(forceRestar)
    end

    if not haveNext and from < 100 then
        self:makeComplete()
    end

    return haveNext
end

function GuideManager:CheckStartCondition(condition)--true表示满足,false表示不满足
    if condition == nil then
        return true
    end

    local currTest = nil
    for k,v in ipairs(condition) do
        currTest = self.mConditions[v[1]]

        if currTest and not currTest(v) then
            return false
        end
    end

    return true
end

function GuideManager:StepData(step)
    
    return ConfigMgr.config_guide[step or self.currStep] or {}
end

--引导系统的核心
--引导系统由config_guide表驱动
--表中前面的配置都时用于决定界面的表现,而后面的三行goalConditions,startConditions,endConditions
--就用通过这个方法里面的配置,进行判定,如果都为true,则进跳过引导,或者进入引导,或者结束引导
--举一个例子 (2,n,1) 的配置
--第一个参数表示,它时ConditionsBy返回的对象的第几个,第二个
--后面的参数都用于ConditionsBy返回的那个方法的参数
--所以d[2] = n, d[3] = 1
--最终就是表示 
-- if GameUIManager:IsUIOpenComplete(n) then
--     return 1 == 1
-- end
--     return 1 == 0
--意思就是 如果界面n打开,返回true, 如果n没有打开,返回false
--各种各种的配置,并且配置在开始引导,完成引导,实现了现在的引导系统
--但是后面又加了非强制引导,非线性引导的需求,就让这个系统非常混乱
--也没有精力在这个项目再改这个系统了,所以就没动了
--这个ConditionsBy的思想可以参考
function GuideManager:ConditionsBy()
    --所有引导开始,结束的条件判定方法
    --返回true表示满足条件
    return {
        --1 没有打开其他界面{1, 0, 0}
        function(d)
            if d[2] == 0 then--没有其他界面
                return GameUIManager:CleanUI()
            elseif d[2] == 1 then--清空界面
                GameUIManager:OnlyExitMainUI()
                GameUIManager:SetEnableTouch(true, "清空界面")
                return true
            elseif d[2] == 3 then--
                local uiView = GameUIManager:GetUIByType(d[3])
                if uiView.DestroyModeUIObject then
                    uiView:DestroyModeUIObject()
                else
                    GameUIManager:CloseUI(d[3])
                end
                return true
            end
        end,
        --2 特定界面是否开闭{2, UIType, isOpen} 
        --UIType是Manager.txt的ENUM_GAME_UITYPE中的数字,有时不同于prefab名字,可结合UIConfig参考
        function(d)
            if GameUIManager:IsUIOpenComplete(d[2]) then
                return d[3] == 1
            end
            return d[3] == 0
        end,
        --3 出现标记{5,personType, isActive}
        function(d)
            local person = {self.event001, self.employee, self.bus,--1事件npc, 2员工, 3公交车
            self.event001UI, self.brokNode, self.levelCompany,--4事件ui, 5损坏, 6公司升级
            self.player, self.elct_lack, self.timeLineDone}--7老板, 8ui界面跳转, 9场景timeline结束
            if person[d[2]] then
                return d[3] == 1
            end
            return d[3] == 0
        end,
        --4 锁定相机到{6, type, 0}
        function(d)
            local currScene = FloorMode:GetScene()
            if not currScene then return false end
            if d[2] == 0 then--取消相机跟随
                currScene:SetCameraFollowGo(nil)
            elseif d[2] == 2 then--锁定到最近来的员工
                currScene:SetCameraFollowGo(self.employee)
            elseif d[2] == 1 then--锁定到特殊npc(防止头上图标不出现)
                if not self.event001 then
                    return false
                end
                currScene:SetCameraFollowGo(self.event001)
            elseif d[2] == 3 then
                currScene:SetCameraFollowGo(self.bus)
            elseif d[2] == 4 then--锁定到想上厕所的员工
                local wcWorker = FloorMode:GetScene():OneGoToliet()
                if wcWorker then
                    currScene:SetCameraFollowGo(wcWorker)
                    return true
                end
                return false
            elseif d[2] == 5 then--锁定到老板
                self.player = FloorMode:GetScene():GetManagerMode()
                if self.player then
                    currScene:SetCameraFollowGo(self.player.m_go)
                end
                return true
            elseif d[2] == 6 then--看向指定房间
                local roomId = FloorMode:GetRoomIdByRoomIndex(d[3])
                if roomId then
                    FloorMode:GetScene():lookAtRoom(roomId)
                end
            end
            return true
        end,
        --5 某房间的工位数{5, room_index, num, smaller_or_bigger}
        function(d)
            local roomId = FloorMode:GetRoomIdByRoomIndex(d[2])
            local data = ConfigMgr.config_rooms[roomId]
            if not data then
                return false
            end

            local currValue = FloorMode:GetRoomFurnitureNum(10001, 1, data.room_index)
            if d[4] == 0 then
                return currValue < d[3]
            else
                return currValue >= d[3]
            end
        end,
        --6 某房间是否引进过公司{6, room_index, type, true_or_false} 0read 1write
        function(d)
            local roomId = FloorMode:GetRoomIdByRoomIndex(d[2])
            local data = ConfigMgr.config_rooms[roomId]
            local companyId = CompanyMode:CompIdByRoomIndex(data.room_index)
            local invited = self.mSave["invite"..roomId] or false
            if d[3] == 0 then
                local ifInvited = invited and true or companyId ~= nil

                if companyId ~= nil then
                    self.mSave["invite"..roomId] = true
                    LocalDataManager.WriteToFile()
                end

                return d[4] == (ifInvited and 1 or 0)
            elseif d[3] == 1 then
                self.mSave["invite"..roomId] = true
                LocalDataManager.WriteToFile()
                return true
            end
        end,
        --7 某房间第某个设施没解锁{7, room_index, furniture_index, notUnlock_unlock}
        function(d)
            local roomId = FloorMode:GetRoomIdByRoomIndex(d[2])
            if not roomId then--房间都还没解锁
                return d[4] == 0 --true
            end
            local data = ConfigMgr.config_rooms[roomId]
            local result = FloorMode:GetRoomFurnitureByIndex(d[3], 1, data.room_index)
            return result == (d[4]==1 and true or false)
        end,
        --8 一些数据的存储
        --当前已存的:对应id
        function(d)
            if d[3] == 0 then--某些事没做过
                local result = self.mSave["done"..d[2]] or false
                return result == false
            elseif d[3] == 1 then --判断做过某事
                local result = self.mSave["done"..d[2]] or false
                return result == true
            elseif d[3] == 2 then --直接完成，并判断完成状态。
                self.mSave["done"..d[2]] = true
                LocalDataManager.WriteToFile()
                return true
            elseif d[3] == 3 then --直接完成，并且判断未完成状态。
                local result = self.mSave["done"..d[2]] or false
                self.mSave["done"..d[2]] = true
                LocalDataManager.WriteToFile()
                return result == false
            elseif d[3] == 4 then --检查开场timeline是否取名成功 引导取公司名字
                local data = LocalDataManager:GetCurrentRecord()
                self.mSave["done"..d[2]] = data.building_name ~= nil
                LocalDataManager.WriteToFile()
                return self.mSave["done"..d[2]]
            end
        end,
        --9 当前为哪一个场景{3, checkScene, 0}
        function(d)
            if d[2] == 1 then--城市
                return GameStateManager:IsInCity()
            elseif d[2] == 2 then--scene101
                return GameStateManager:IsInFloor()
            end
        end,
        --10 自动结束
        function(d)
            self.autoEnd = true
            return true
        end,
        --11 关闭界面或者是购买了设施
        function(d)
            local isOpen = GameUIManager:IsUIOpenComplete(5)
            if isOpen == false then
                return true
            end
            local roomId = FloorMode:GetRoomIdByRoomIndex(d[2])
            if not roomId then--房间都还没解锁
                return true
            end
            local data = ConfigMgr.config_rooms[roomId]
            local result = FloorMode:GetRoomFurnitureByIndex(d[3], 1, data.room_index)
            return result == true
        end,
        --12 当前打开的的房间
        function(d)
            local roomId = FloorMode:GetRoomIdByRoomIndex(d[2])
            local data = ConfigMgr.config_rooms[roomId]
            local isOpen = data.room_index == FloorMode.m_curRoomIndex
            if isOpen then
                return d[3] == 1
            else
                return d[3] == 0
            end
        end,
        --13 没有完成过任务
        function(d)
            local questDo = QuestUI:GetShowData()
            return questDo <= 0
        end,
        --14 调用特殊方法
        function(d)
            if d[2] == 1 then
                local floorScene = FloorMode:GetScene()
                if floorScene then
                    floorScene:InitGuideTimeLine("GuideTimeline")
                    return true
                end
                return false
            elseif d[2] == 2 then--待添加
                -- ActorEventManger:stopCreate(false)
                return true
            elseif d[2] == 3 then
                ActorEventManger:stopCreate(false)
                ActorEventManger:ActiveEvent({["id"]=1})
                return true
            elseif d[2] == 4 then
                if GameUIManager:IsUIOpenComplete(15) then
                    Event001UI:SkipAd()
                end
                return true
            elseif d[2] == 5 then
                local scene = FloorMode:GetScene()
                if scene then
                    self.player = scene:GetManagerMode()
                end
                if self.player then
                    local isWork = CompanyMode:CheckManagerRoomOnWork(true)
                    return isWork
                end
                return false          
            elseif d[2] == 6 then
                local step = d[3]
                InstanceDataManager:SetGuideID(step)
                return true
            elseif d[2] == 7 then
                local step = d[3]
                CycleInstanceDataManager:GetCurrentModel():SetGuideID(step)
                return true
            end
            
            return false
        end,
        --15 命名相关
        function(d)
            if d[2] == 1 then--是否
                if d[3] == 1 then
                    return LocalDataManager:GetBossName() == nil
                elseif d[3] == 2 then
                    return LocalDataManager:GetBuildingName() == nil
                end
            elseif d[2] == 2 then--打开界面
                if d[3] == 2 then
                    BenameUI:BuildingName()
                end
                BenameUI:GetView()--没有起名字起名字
            end
        end,
        --16 补钱
        function(d)
            if d[2] == 2 then
                local currCash = ResourceManger:GetCash()
                local lack = d[3] - currCash
                if lack > 0 then
                    ResourceManger:AddCash(lack)
                end

                return true
            elseif d[2] == 3 then
                local currDia = ResourceManger:GetDiamond()
                local lack = d[3] - currDia
                if lack > 0 then
                    ResourceManger:AddDiamond(lack)
                end

                return true
            end
        end,
        --17 房间当前选中第几个
        function(d)
            local currIndex = RoomBuildingUI:CurrChoose()
            if d[3] == 1 then
                return currIndex == d[2]
            else
                return currIndex ~= d[2]
            end
        end,
        --18 房间的解锁情况
        function(d)
            if not FloorMode:GetScene() then
                return
            end
            
            local roomId = FloorMode:GetRoomIdByRoomIndex(d[2])
            local data = ConfigMgr.config_rooms[roomId]
            local roomUnlock = FloorMode:GetScene():ifRoomUnlocked(data.room_index)
            local roomToUnlock = FloorMode:GetScene():ifRoomToUnlocked(data.room_index)
            if d[3] == 1 then
                return roomUnlock == true
            elseif d[3] == 2 then
                return roomUnlock == false
            elseif d[3] == 3 then
                return roomToUnlock == true
            elseif d[3] == 4 then
                return roomToUnlock == false
            end
        end,
        --19 特别情况
        function(d)
            if d[2] == 1 then
                --如果是夜晚没有公交车,则直接跳到18步
                if self.lastCompany then
                    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
                    if not CompanyMode:CheckCompanyWorkState(gameH, gameM, self.lastCompany) then
                        self.currStep = d[3]
                        self:ConditionToStart()
                        return false
                    end
                end

                return true
            end
        end,
        --20 某一个工厂是否已经存在(修建完成) 1   (没有)2  (是否有材料产生)3
        function(d)
            if d[2] == 1 then
                if FactoryMode:GetWorkShopdata(d[3]) and FactoryMode:GetWorkShopdata(d[3]).state ~= 0 then
                    return true
                end                                
            elseif d[2] == 3 then
                local currentLimit, storageLimit = WorkShopInfoUI:storageLimit()
                if currentLimit ~= storageLimit then
                    return true
                end                
            end            
            return false    
        end,
        --21在声望(星星)达到某种条件时
        function(d)
            if d[2] >= StarMode:GetStar() then
                return true            
            end
            return false     
        end,
        --22在遮罩消失时
        function(d)
            if d[2] == 1 then
                self.autoEnd = false
            end
            return self.autoEnd
        end,
        --23 当前循环副本房间界面显示的房间的家具等级大于等于needFurLevel{23,needFurLevel,0}
        function(d)
            local needFurLevel = d[2]
            local currentModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel()
            local roomID
            if currentModel.instance_id == 5 then
                roomID = GameTableDefine.CycleCastleBuildingUI.m_view.roomID
            elseif currentModel.instance_id == 6 then
                roomID = GameTableDefine.CycleToyBuildingUI.m_view.roomID
            elseif currentModel.instance_id == 7 then
                roomID = GameTableDefine.CycleNightClubBuildingUI.m_view.roomID
            end
            local furLevel = currentModel:GetFurlevelConfigByRoomFurIndex(roomID,1).level
            return furLevel >= needFurLevel
        end,
        --24 滑动到ShopUI的某个商品
        function(d)
            local shopID = d[2]
            GameTableDefine.ShopUI:TurnTo(shopID)
            return true
        end,
    }
end

function GuideManager:OnEvent(eventId, params)
    if eventId == self.EVENT_VIEW_OPEND then
        self:ConditionToStart()
        self:ConditionToEnd()
    elseif eventId == self.EVENT_VIEW_CLOSED then
        self:ConditionToStart()
        self:ConditionToEnd()

        if GuideManager.levelCompany and GuideManager.levelClick then
            GuideManager:GetNextStep(200, true, false, 203)
        end
        if GuideManager.brokNode and GuideManager.brokeClick then
            GuideManager:GetNextStep(300, true, false, 305)
        end
    end
end

-- function GuideManager:SetTimeLineDialogCompleteHander(cb)
--     self.m_dialogCompleteHander = cb;
-- end
EventManager:RegEvent("INVITE_COMPANY", function(companyId)
    GuideManager.lastCompany = companyId
end)

EventManager:RegEvent("Employee_come", function(employee_go)
    if not GuideManager.employee then
        GuideManager.employee = employee_go
        if GuideManager:compareStepWith(14, 17, true) then--锁定员工这一步,如果不继续强制到这一步
            --GameSDKs:Track("guide", {guide_id = 16, guide_name = GameTextLoader:ReadText("TXT_GUIDE_"..16)})
            GameSDKs:TrackForeign("guide", {guide_id = 16, guide_desc = GameTextLoader:ReadText("TXT_GUIDE_"..16)})

            GameUIManager:OnlyExitMainUI() 
            GuideManager.currStep = 17
            GuideManager.inGuide = false
            GuideManager:ConditionToStart()
        end
    end
end);

EventManager:RegEvent("Employee_leave", function()
    GuideManager.employee = nil
    GuideManager:ConditionToEnd()
end);

EventManager:RegEvent("Bus_come", function(bus_go)
    GuideManager.bus = bus_go
    GuideManager:ConditionToStart()
end);

EventManager:RegEvent("compnay_levle_up", function(levelNode, bindClick)
    GuideManager.levelCompany = levelNode
    GuideManager.levelClick = bindClick
    GuideManager:GetNextStep(200, true, false, 203)
end);

EventManager:RegEvent("room_broke", function(brokNode, bindClick)--分值引导也一样,id是固定的
    GuideManager.brokNode = brokNode
    GuideManager.brokeClick = bindClick
    GuideManager:GetNextStep(300, true, false, 305)
end);

EventManager:RegEvent("elec_lack", function(power, totalPower)
    GuideManager.elct_lack = true
    GuideManager:GetNextStep(400,true, false, 402)
end);

EventManager:RegEvent("EventSponsor_come", function(go)
    GuideManager.event001 = go
    --GuideManager:ConditionToEnd()
end);

EventManager:RegEvent("EventSopnsor_click", function(go)
    GuideManager.event001UI = go
    GuideManager:ConditionToEnd()
end);

EventManager:RegEvent("manager_fixed_complete", function()
    GuideManager.player = nil
    GuideManager:ConditionToEnd()
end)