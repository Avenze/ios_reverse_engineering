--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-07 11:31:57
    desc:副本的工人实体对象
]]

local Class = require("Framework.Lua.Class")
local Person = require("GamePlay.Floors.Actors.Person")
local UIView = require("Framework.UI.View")
local Interactions = require("GamePlay.Floors.Actors.Interactions")
local EventManager = require("Framework.Event.Manager")

local Random = CS.UnityEngine.Random
local UnityHelper = CS.Common.Utils.UnityHelper
local Vector3 = CS.UnityEngine.Vector3
local FloatUI = GameTableDefine.FloatUI
local CfgMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel
local InstanceDataManager = GameTableDefine.InstanceDataManager

local InstanceWorker = Class("InstanceWorker", Person)

local MOOD_HUNGER = 5
local MOOD_TIRED = 6

InstanceWorker.m_type = "TYPE_INSTANCE_WORKER"
InstanceWorker.m_category = 4000
InstanceWorker.EVENT_EATIN_IDLE_POSITION = InstanceWorker.m_category + 1
InstanceWorker.EVENT_SLEEP_IDLE_POSITION = InstanceWorker.m_category + 2

InstanceWorker.EVENT_INSTANCE_WORKER_GOTO_ACTION = InstanceWorker.m_category + 10

--关联的设备对象，用于数据管理
InstanceWorker.m_AssociationFurniture = nil

function InstanceWorker:Init(rootGo, prefab, position, targetPos, targetRotation, roomData, personID, actionPos)
    self.super.Init(self, rootGo, prefab, position, targetPos, personID)
    self.m_targetRotation = targetRotation
    self.m_actionPos = actionPos
    self.roomData = roomData  
    self.m_interactionRoomGo = {}
    self.m_triggerCounter = {}
    self.currTime = InstanceDataManager:GetCurInstanceTimeType()
    self.nextTime = nil
    self:SetMood()    
end

function InstanceWorker:Update(dt)
    self.super.Update(self, dt)
    if GameTimeManager:GetSocketTime() - (0) < 1 then   --不知道为什么这么写,先保留
        return
    end

    self:Behavior(dt)
end

function InstanceWorker:Exit()
    --退出需要处理的相关内容
    self.super.Exit(self)
end

function InstanceWorker:Event(msg, IsParams)    
    self.super.Event(self, msg, IsParams)
end

function InstanceWorker:InitFloatUIView()
    self.m_viewStack = {}
    FloatUI:SetObjectCrossCamera(self,function(view)
        self.m_view = view
        view:Invoke("ShowNpcFloat", self)
        for cmd, args in pairs(self.m_viewStack) do
            self.m_view:Invoke(cmd, table.unpack(args, 1, #args))
        end
    end, function()
        if not self.m_view then
            return
        end
        self.m_view:Invoke("HidePersonActionHint", self.lastAction)
        self.m_view = nil
    end, 0)
end

function InstanceWorker:InvokeFloatUIView(cmd, ...)
    if self.m_view then
        self.m_view:Invoke(cmd, ...)
    end

    if self.m_viewStack then
        self.m_viewStack[cmd] = {...}
    end
end

function InstanceWorker:CheckFloatState()
    local action = nil
    local moodIndicator = 0
    local args = nil
    --TODO:角色头顶的表情符号
end

function InstanceWorker:ShowMoodChangeHint(state)
    --TODO:显示头顶的表情Icon
end

function InstanceWorker:UpdateMood()

end

function InstanceWorker:OverrideStates()
--角色创建完成后会自动进入到StateLoading状态,在完成初始化后会发送 LOADING_COMPLETE 信息过来
------------------------------------------Loading-------------------------------------
    local StateLoading = self:OverrideState(self.StateLoading)
    function StateLoading:Event(person, msg, params)
        self.super.Event(self, person, msg)
        if msg == person.LOADING_COMPLETE then
            self.super.Event(self, person, msg) 
            self.loadTimer = GameTimer:CreateNewTimer(0.5, function()
                if not person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_EATING) or not person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_SLEEPING) then
                    return
                end
                person.starWorking = true
                GameTimer:StopTimer(self.loadTimer)
                person.m_interactionRoomGo = {}
                if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT) then --往工位点走
                    person:RemoveFlag(person.FLAG_INSTANCEWORKER_READY_WORKING)
                    local params = {tragetPosition = person.m_targetPosition, finalRotaionPosition = person.m_targetRotation}
                    person:SetState(person.StateWalk, params)
                    return
                end          
                if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKING) then
                    person:SetState(person.StateWork)
                    return
                end
                if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_EATING) then
                    local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_EATING)
                    local idlePositon = interactions.StateIdle:GetFurnitureIdlePositon()
                    --if person.canSuccessDo then                    
                        if idlePositon then
                            person:AddFlag(person.FLAG_EMPLOYEE_IN_QUEUE)       
                            interactions.StateIdle:PersonGetIn(idlePositon, person)
                            person.m_go.transform.position = Vector3(idlePositon.pos.x, person.m_go.transform.position.y, idlePositon.pos.z) 
                            local params  ={tragetPosition = idlePositon and idlePositon.pos or interactions.m_go.transform.position}    
                            person:SetState(person.StateWalk, params)
                            return 
                        end
                        person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_EATING)
                        person:SetState(person.StateIdle)
                        return
                    -- else
                    --     person:SetState(person.StateIdle)
                    --     return
                    -- end                                                                                                
                end                
                if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING) then
                    local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
                    local idlePositon = interactions.StateIdle:GetFurnitureIdlePositon()
                    --if person.canSuccessDo then
                        if idlePositon then
                            person:AddFlag(person.FLAG_EMPLOYEE_IN_QUEUE)       
                            interactions.StateIdle:PersonGetIn(idlePositon, person)
                            person.m_go.transform.position = idlePositon.pos
                            local params  ={tragetPosition = idlePositon and idlePositon.pos or interactions.m_go.transform.position}    
                            person:SetState(person.StateWalk, params)
                            return
                        end
                        person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
                        person:SetState(person.StateIdle)
                        return
                    -- else
                    --     person:SetState(person.StateIdle)
                    --     return
                    -- end      
                end
            end, true)
        end
    end
------------------------------------Walk走路---------------------------------------------
    local StateWalk = self:OverrideState(self.StateWalk)
    function StateWalk:Enter(person, msg, params)
        if person:HasFlag(person.FLAG_INSTANCEWORKER_READY_WORKING)
            and person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKPOS) 
            and not person:HasFlag(Person.FLAG_INSTANCEWORKER_ON_WORKSIT)
        then
            self.m_stateParams.speed = CfgMgr.config_global.character_walk_v
        else
            self.m_stateParams.speed = CfgMgr.config_global.character_run_v
        end
        --重置高度
        self.parent.m_go.transform.position = Vector3(
                                                self.parent.m_go.transform.position.x,
                                                0, 
                                                self.parent.m_go.transform.position.z)
        self.super.Enter(self, person, params)
        self.parent:SetTheDisplayOfBubbles("state")
    end
    function StateWalk:Update(person, dt)
        self.super.Update(self, person)
    end
    function StateWalk:Event(person, msg, params)
        self.super.Event(self, person, msg)               
        
        if msg == person.EVENT_INSTANCE_WORKER_GOTO_ACTION then
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)
            return
        end
        
        if msg == person.EVENT_GETIN_IDLE_POSTION then
            self.m_stateParams.tragetPosition = params.pos
            self.m_stateParams.finalRotaionPosition = params.dir
            self:Enter(person)
        end 
        
        if msg == person.EVENT_ARRIVE_FINAL_TARGET then               
            if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT) then
                person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
                person.m_flags = 2
                person:SetState(person.StateIdle)
                return
            end 
            if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKPOS) then
                person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_WORKPOS)
                person:SetState(person.StateIdle)
            end


            --有 FLAG_EMPLOYEE_IN_QUEUE 但是没有 m_idlePositon 表示进入排队检测
            if 
                person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE)
                and not person.m_idlePositon
            then
                local interactions = person:GetCurrentInteractionEntity()
                if interactions then                                    
                    interactions:Event(interactions.EVENT_PERSON_ARRIVE_TARGET, person)
                    return
                end
            end  

            --有 FLAG_EMPLOYEE_IN_QUEUE 和 m_idlePositon 表示进入指定状态
            if person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) 
                and person:HasFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
                and person.m_idlePositon
                and (person.m_idlePositon.pos - person.m_go.transform.position).magnitude < 3  
            then
                person:SetState(person.StateInstanceSleeping)
                return
            elseif person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) 
                and person:HasFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
                and person.m_idlePositon
                and (person.m_idlePositon.pos - person.m_go.transform.position).magnitude >= 1 
            then            
                local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
                interactions:Event(interactions.EVENT_PERSON_ARRIVE_TARGET, person)
                return
            end
            
            if person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) 
                and person:HasFlag(person.FLAG_INSTANCEWORKER_ON_EATING) 
                and person.m_idlePositon
                and (person.m_idlePositon.pos - person.m_go.transform.position).magnitude < 1
            then  
                person:SetState(person.StateInstanceEating)
                return
            elseif person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) 
                and person:HasFlag(person.FLAG_INSTANCEWORKER_ON_EATING)
                and person.m_idlePositon
                and (person.m_idlePositon.pos - person.m_go.transform.position).magnitude >= 1                        
            then
                local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_EATING)
                interactions:Event(interactions.EVENT_PERSON_ARRIVE_TARGET, person)
                return
            end                      
        end        
    end
    function StateWalk:Exit(person)
        self.parent:SetTheDisplayOfBubbles()
    end
------------------------------------------Work工作------------------------------------------
    local StateWork = self:OverrideState(self.StateWork)
    function StateWork:Enter(person)
        self.super.Enter(self, person)
        local facPostion = Vector3(person.m_targetRotation.x, self.parent.m_go.transform.position.y, person.m_targetRotation.z)
        UnityHelper.RotateTowards(person.m_go.transform, facPostion)
        self.parent:SetTheDisplayOfBubbles("product")
    end

    function StateWork:Update(person, dt)
        self.super.Update(self, person)
    end

    function StateWork:Event(person, msg, args)
        self.super.Event(self, person, msg)
        if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_EATING) then
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)
        end
        if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING) then
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)
        end
        if msg == person.EVENT_INSTANCE_WORKER_GOTO_ACTION then
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)
        end
    end    
    function StateWork:Exit(person)
        person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_WORKING)
        self.parent:SetTheDisplayOfBubbles()
    end
-------------------------------------------StateInstanceEating----------------------------------------
    local StateInstanceEating = self:OverrideState(self.StateInstanceEating)
    function StateInstanceEating:Enter(person)
        self.super.Enter(self, person)
        person:RemoveFlag(person.FLAG_EMPLOYEE_IN_QUEUE)
        local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_EATING)
        local IdlePositon = self.parent.m_idlePositon 
        if IdlePositon and IdlePositon.posGo then

            local facPostion = UIView:GetGo(IdlePositon.posGo, "face").transform.position
            -- for k,v in pairs(interactions.StateIdle:GetPositon()) do
            --     if v.person == self.parent then
            --         IdlePositon = v
            --         break
            --     end
            -- end
            self.parent.m_go.transform.position = IdlePositon.pos
            --self.m_stateParams.finalRotaionPosition = params.dir
            UnityHelper.RotateTowards(person.m_go.transform, Vector3(facPostion.x, self.parent.m_go.transform.position.y, facPostion.z))
            self:SetAnimator(IdlePositon.anim[1])
        end
        if interactions then
            local roomId = interactions.m_sceneProcessData.config.id
            self.parent:SetTheDisplayOfBubbles("eat", roomId) 
        end         
    end

    function StateInstanceEating:Update(person, dt)
        self.super.Update(self, person)
    end

    function StateInstanceEating:Event(person, msg, args)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_INSTANCE_WORKER_GOTO_ACTION then            
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)
        end
    end   
    function StateInstanceEating:Exit(person)
        self.super.Event(self, person)
        local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_EATING)
        if interactions then
            interactions:Event(interactions.EVENT_PERSON_OUT, {person})        
        end
        person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
        self.parent:SetTheDisplayOfBubbles()        
    end
-------------------------------------------StateInstanceSleeping----------------------------------------
    local StateInstanceSleeping = self:OverrideState(self.StateInstanceSleeping)
    function StateInstanceSleeping:Enter(person)
        self.super.Enter(self, person)
        person:RemoveFlag(person.FLAG_EMPLOYEE_IN_QUEUE)
        local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
        local idlePostion
        local sleepPostionGo
        local facPostion
        idlePostion = self.parent.m_idlePositon   
        sleepPostionGo = UIView:GetGo(idlePostion.posGo, "actionPos")
        -- for k,v in pairs(interactions.StateIdle:GetPositon()) do
        --     if v.person == self.parent then
        --         idlePostion = v
        --         break
        --     end
        -- end
        -- for k,v in pairs(idlePostion.furnGo.transform) do
        --     if v.position == idlePostion.pos then
        --         sleepPostionGo = UIView:GetGo(v.gameObject, "actionPos")
        --         break
        --     end
        -- end
        self.parent.StateWalk.tragetPosition = sleepPostionGo.transform.position
        facPostion = UIView:GetGo(sleepPostionGo, "face").transform.position
        self.parent.m_go.transform.position = sleepPostionGo.transform.position        

        UnityHelper.RotateTowards(person.m_go.transform, Vector3(facPostion.x, self.parent.m_go.transform.position.y, facPostion.z))
        self:SetAnimator(idlePostion.anim[1])   
        if interactions then
            local roomId = interactions.m_sceneProcessData.config.id
            self.parent:SetTheDisplayOfBubbles("sleep", roomId) 
        end    
    end

    function StateInstanceSleeping:Update(person, dt)
        self.super.Update(self, person)
    end
    
    function StateInstanceSleeping:Event(person, msg, args)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_INSTANCE_WORKER_GOTO_ACTION then            
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)
        end
    end       
    function StateInstanceSleeping:Exit(person)
        self.super.Event(self, person)
        local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
        if interactions then
            interactions:Event(interactions.EVENT_PERSON_OUT, {person})        
        end
        person:RemoveFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)        
        self.parent:SetTheDisplayOfBubbles()
    end
---------------------------------------------StateIdle----------------------------------------
    local StateIdle = self:OverrideState(self.StateIdle)
    function StateIdle:Enter(person, params)
        self.super.Enter(self, person, params)    
        local timeType = InstanceDataManager:GetCurInstanceTimeType()    
        if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT) 
            and (timeType == InstanceDataManager.timeType.work or InstanceModel.timeType == InstanceDataManager.timeType.work)
        then
            local params = {tragetPosition = person.m_targetPosition}
            person:SetState(person.StateWalk, params)
            return
        elseif person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT) then
            person:RemoveFlag(Person.FLAG_INSTANCEWORKER_ON_WORKSIT)
        end

        if person:HasFlag(person.FLAG_INSTANCEWORKER_ON_WORKPOS) then
            local params = {tragetPosition = person.m_actionPos  or person.m_targetPosition}
            person:SetState(person.StateWalk, params)
            return
        end       

        if  not person:HasFlag(person.FLAG_INSTANCEWORKER_READY_WORKING) and
            not person:HasFlag(person.FLAG_INSTANCEWORKER_ON_EATING) and
            not person:HasFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
        then
            local params = {}                
            if timeType == InstanceDataManager.timeType.work then                
                person:AddFlag(person.FLAG_INSTANCEWORKER_READY_WORKING)
                person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKPOS) 
                
                self:Enter(person)
                return
            elseif timeType == InstanceDataManager.timeType.eat then --需要根据房间情况选择       
                local idlePositon                       
                person.m_interactionRoomGo = nil
                person.m_interactionRoomGo = {}        
                local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_EATING)               
                person:AddFlag(person.FLAG_INSTANCEWORKER_ON_EATING)        
                if person.canSuccessDo then
                    interactions = person:GetInteractionEntityById(person.interactionRoomId) or interactions
                    person.m_interactionRoomGo[person.FLAG_INSTANCEWORKER_ON_EATING] = interactions
                    idlePositon = interactions.StateIdle:GetFurnitureIdlePositon()
                    if idlePositon then
                        person:AddFlag(person.FLAG_EMPLOYEE_IN_QUEUE)       
                        interactions.StateIdle:PersonGetIn(idlePositon, person)
                    end
                end
                local params  ={tragetPosition = idlePositon and idlePositon.pos or interactions.m_go.transform.position}    
                person:SetState(person.StateWalk, params)            
                return  
            elseif timeType == InstanceDataManager.timeType.sleep then                   
                local idlePositon                           
                person.m_interactionRoomGo = nil
                person.m_interactionRoomGo = {}
                local interactions = person:GetInteractionEntity(person.FLAG_INSTANCEWORKER_ON_SLEEPING)                                  
                person:AddFlag(person.FLAG_INSTANCEWORKER_ON_SLEEPING)
                if person.canSuccessDo then 
                    interactions = person:GetInteractionEntityById(person.interactionRoomId) or interactions
                    person.m_interactionRoomGo[person.FLAG_INSTANCEWORKER_ON_SLEEPING] = interactions
                    idlePositon = interactions.StateIdle:GetFurnitureIdlePositon()
                    if idlePositon then
                        person:AddFlag(person.FLAG_EMPLOYEE_IN_QUEUE)    
                        interactions.StateIdle:PersonGetIn(idlePositon, person)
                    end  
                end                                              
                local params = {tragetPosition = idlePositon and idlePositon.pos or interactions.m_go.transform.position}
                person:SetState(person.StateWalk, params)                
                return
            end                        
        end

        if person:HasFlag(person.FLAG_INSTANCEWORKER_READY_WORKING) then
            person:RemoveFlag(person.FLAG_INSTANCEWORKER_READY_WORKING)
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKING)
            person:SetState(person.StateWork)
            return
        end
             
    end    
    function StateIdle:Update(person, dt)
        self.super.Update(self, person)
        
    end
    function StateIdle:Exit(person)        
        self.parent:SetTheDisplayOfBubbles()
    end
    function StateIdle:Event(person, msg, params)
        self.super.Enter(self, person)
        if msg == person.EVENT_INSTANCE_WORKER_GOTO_ACTION then
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)           
            self:Enter(person)            
        end
    end

    
----------------------------StateQueueUp---------------------------
    local StateQueueUp = self:OverrideState(self.StateQueueUp)
    function StateQueueUp:Enter(person, params)
        self.super.Enter(self, person, params)  
        self.parent:SetTheDisplayOfBubbles("state")    
    end
    function StateQueueUp:Update(person, dt)
        self.super.Update(self, person)
    end
    function StateQueueUp:Exit(person)      
        self.parent:SetTheDisplayOfBubbles()
    end
    function StateQueueUp:Event(person, msg, params)
        self.super.Enter(self, person)
        if msg == person.EVENT_GETIN_IDLE_POSTION then

            local params  = {tragetPosition = params.pos, finalRotaionPosition = params.dir}    
            person:SetState(person.StateWalk, params)   
        
        end 
        if msg == person.EVENT_INSTANCE_WORKER_GOTO_ACTION then
            
            person:AddFlag(person.FLAG_INSTANCEWORKER_ON_WORKSIT)
            person:SetState(person.StateIdle)            
        end
    end
end

function InstanceWorker:SetMood()    
    self.m_triggerCounter[self.FLAG_INSTANCEWORKER_ON_SLEEPING] = 0
    self.m_triggerCounter[self.FLAG_INSTANCEWORKER_ON_EATING] = 0    
end

function InstanceWorker:SetSpawnPos(spwanPos)
    self.spawnPos = spwanPos
end

function InstanceWorker:SetWorkingPos(workingPos)
    self.workingPos = workingPos
end

function InstanceWorker:SetWorkSitPos(workSitPos)
    self.workSitPos = workSitPos
end

function InstanceWorker:GetSpawnPos()
    return self.spawnPos
end

function InstanceWorker:GetWorkingPos()
    return self.workingPos
end

function InstanceWorker:GetWorkSitPos()
    return self.workSitPos
end

function InstanceWorker:Behavior(dt)
    if not self.m_go or self.m_go:IsNull() then
        return
    end
    if not self.starWorking then
        return
    end
    local timeType = InstanceModel.timeType
    if self.currTime ~= timeType then
        if self.behaviorTimer then
            GameTimer:StopTimer(self.behaviorTimer)
        end        
        local actionTime = math.random(2000,2500)/1000  --不知道这里为什么用随机数
        self.behaviorTimer = GameTimer:CreateNewTimer(actionTime, function() 
            if self.canSuccessDo ~= timeType then
                self.canSuccessDo = nil
                self.interactionRoomId = nil
            end
            self.m_interactionRoomGo = nil
            self.m_interactionRoomGo = {}
            if self.m_idlePositon then
                self.m_idlePositon.person = nil
                self.m_idlePositon = nil
            end            
            self.m_flags = 2
            self:Event(self.EVENT_INSTANCE_WORKER_GOTO_ACTION)            
        end)
        -- for k,v in pairs(Interactions:GetEntities(self.FLAG_INSTANCEWORKER_ON_EATING)) do
        --     v.StateIdle.m_personQueue = nil
        --     v.StateIdle.m_personQueue = {}
        -- end
        -- for k,v in pairs(Interactions:GetEntities(self.FLAG_INSTANCEWORKER_ON_SLEEPING)) do
        --     v.StateIdle.m_personQueue = nil
        --     v.StateIdle.m_personQueue = {}
        -- end    
        self.currTime = timeType      
    end
    local UpdatePersonInteraction = function(ineraction)
        if not ineraction then
            return
        end
        ineraction:UpdatePersonInteraction(self)
    end
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_INSTANCEWORKER_ON_EATING))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_INSTANCEWORKER_ON_SLEEPING))
end


--选择互动物体的策略(距离最近的,有可进入点的)
function InstanceWorker:GetInteractionEntity(tag)
    --因为房间的互动脚本需要时间初始化,所以AI的逻辑需要等待房间的初始化完成了才能走       
    if  self.m_interactionRoomGo and self.m_interactionRoomGo[tag] and Tools:GetTableSize(self.m_interactionRoomGo[tag]) ~= 0 then
        return self.m_interactionRoomGo[tag]
    end
    
    local entities = Interactions:GetEntities(tag)
    local distance
    local defaultEntity = nil
    for k, v in pairs(entities or {}) do        
        local currPotion = self.m_go.transform.position
        local entitiePotion = v.m_go.transform.position   
        local closer = false
        local canGetInto = false
        if Tools:GetTableSize(v.StateIdle:GetPositon()) ~= 0 then
            if not distance then
                distance = (currPotion - entitiePotion).magnitude
                defaultEntity = v
            end         
            if defaultEntity and (currPotion - entitiePotion).magnitude < distance then    
                closer = true                 
            end
            if defaultEntity and v.StateIdle:GetFurnitureIdlePositon() ~= nil then       
                canGetInto = true                                      
            end              
            if defaultEntity and defaultEntity.StateIdle:GetFurnitureIdlePositon() == nil and closer then
                distance = (currPotion - entitiePotion).magnitude
                defaultEntity = v  
            end
            if defaultEntity and defaultEntity.StateIdle:GetFurnitureIdlePositon() == nil and canGetInto then
                distance = (currPotion - entitiePotion).magnitude
                defaultEntity = v  
            end    
            if closer and canGetInto then
                distance = (currPotion - entitiePotion).magnitude
                defaultEntity = v
            end   
        end         
    end
    self.m_interactionRoomGo[tag] = defaultEntity
    return self.m_interactionRoomGo[tag]
end

function InstanceWorker:GetCurrentInteractionEntity()
    if self:HasFlag(self.FLAG_INSTANCEWORKER_ON_EATING) then
        return self:GetInteractionEntity(self.FLAG_INSTANCEWORKER_ON_EATING)
    elseif self:HasFlag(self.FLAG_INSTANCEWORKER_ON_SLEEPING) then
        return self:GetInteractionEntity(self.FLAG_INSTANCEWORKER_ON_SLEEPING)
    end
end


function InstanceWorker:SetTargetMood(moodType, mood, transferValue, isShow)
end

--设置气泡的显示
function InstanceWorker:SetTheDisplayOfBubbles(typeB, interactiveRoomId)
    local workerAttr = InstanceModel:GetWorkerAttr(self.roomData.roomId, self.roomData.index)
    local state =
    {
        interactiveRoomId = interactiveRoomId,
        roomId = self.roomData.roomId,
        index = self.roomData.index,
        workProgress = 0,
        hungry = workerAttr.hungry,
        physical = workerAttr.physical,
        productionID = InstanceDataManager.config_rooms_instance[self.roomData.roomId].production
    }
    local speed
    if typeB == "product" then
        local roomCfg = InstanceDataManager.config_rooms_instance[state.roomId]
        local allReduce = InstanceModel:GetRoomCDReduce(state.roomId)
        local cd = roomCfg.bastCD - allReduce
        speed = 1 / cd
    elseif typeB == "eat" then
        speed = InstanceModel:GetRoomHunger(state.interactiveRoomId)
        
    elseif typeB == "sleep" then  
        speed = InstanceModel:GetRoomPhysical(state.interactiveRoomId) 
    end  
    state.speed = speed

    self.bubbleState = state
    self.typeB = typeB
    FloatUI:SetObjectCrossCamera(self, function(view)        
        view:Invoke("RefreshInstanceWorkerBubble", self.typeB, self.bubbleState)                  
    end,function()
        if not self.view then
            return
        end
        self.view:Invoke("RefreshInstanceWorkerBubble")        
    end,0)                   
end

function InstanceWorker:GetInteractionEntityById(EntityId)  
    local interaction
    GetEntity = function(tag)
        local entities = Interactions:GetEntities(tag)
        for k,v in pairs(entities) do
            if v.m_config and EntityId == v.m_config.id then                
                interaction = v
            end
        end
    end
    GetEntity(self.FLAG_INSTANCEWORKER_ON_EATING)
    GetEntity(self.FLAG_INSTANCEWORKER_ON_SLEEPING)
    return interaction   
end 

return InstanceWorker