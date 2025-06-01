-- local Class = require("Framework.Lua.Class")
-- local Actor = require("GamePlay.Floors.Actors.Actor")

--  local FloatUI = GameTableDefine.FloatUI
--  local FloorMode = GameTableDefine.FloorMode
--  local CfgMgr = GameTableDefine.ConfigMgr
 
--  local GameObject = CS.UnityEngine.GameObject
--  local Vector3 = CS.UnityEngine.Vector3

-- local UIView = require("Framework.UI.View")
-- local EventManager = require("Framework.Event.Manager")
-- local TimeManager = GameTimeManager

-- local Toile = Class("Toile", Actor)

-- local STATE_LOADING = "StateLoading"
-- local STATE_IDLE = "StateIdle"

-- Toile.EVENT_PERSON_IN = 301
-- Toile.EVENT_PERSON_OUT = 302
-- Toile.EVENT_PERSON_QUEUE = 303
-- Toile.EVENT_PERSON_ARRIVE_TARGET = 304

-- local toileEntity = nil

-- function Toile:ctor()
--     self:getSuper(Toile).ctor(self)
-- end

-- function Toile:Init(rootGo, furnituresGo)
--     self.m_go = rootGo
--     self.m_furnituresGo = furnituresGo
--     self:getSuper(Toile).Init(self)
--     self:SetState(self.StateIdle)
-- end

-- function Toile:Update(dt)
--     self:getSuper(Toile).Update(self, dt)
-- end

-- function Toile:Exit()
--     self:getSuper(Toile).Exit(self)
-- end

-- function Toile:Event(msg, params)
--     self:getSuper(Toile).Event(self, msg, params)
-- end

-- function Toile:InitFloatUIView()
--     FloatUI:SetObjectCrossCamera(self, function(view)
--         if view then
--             view:Invoke("ShowEventBumble")
--         end
--     end)
-- end

-- function Toile:RemoveFloatUIView()
--     FloatUI:RemoveObjectCrossCamera(self)
-- end

-- function Toile:GetToileEntity()
--     if toileEntity then
--         return toileEntity
--     end

--     toileEntity = self:CreateActor()
--     return toileEntity
-- end

-- function Toile:ClearEntity()
--     toileEntity = nil
-- end

-- function Toile:ToileAcitve()
--     if not toileEntity then
--         return 
--     end
    
--     local size = Tools:GetTableSize(toileEntity.StateIdle:GetClosestool())
--     return size > 0
-- end

-- function Toile:InitStates()
--     local StateLoading = self:InitState(STATE_LOADING)
--     function StateLoading:Enter(toile)
--         toile:CreateGo()
--     end

--     function StateLoading:Update(toile, dt)
--     end

--     function StateLoading:Exit(toile)
--     end

--     function StateLoading:Event(toile, msg)
--     end

--     -- idle
--     local StateIdle = self:InitState(STATE_IDLE)
--     function StateIdle:Enter(toile)
--         self.m_personQueue = {}
--     end

--     function StateIdle:Update(toile, dt)
--         if TimeManager:GetSocketTime() - (self.lastTime or 0) < 1 then
--             return
--         end
--         self.lastTime = TimeManager:GetSocketTime()

--         if not self.m_personQueue or #self.m_personQueue == 0 then
--             return
--         end
--         if self.m_personQueue[1] and self.m_personQueue[1].m_state.name ~= "StateQueueUp" then
--             return
--         end

--         local closestool = self:GetIdleClosestool()
--         if closestool then
--             self:PersonGetIn(closestool)
--         end
--     end

--     function StateIdle:Exit(toile)
--     end

--     function StateIdle:Event(toile, msg, params)
--         if msg == Toile.EVENT_PERSON_IN then
--             self:AddQueuePath(params[1], params[2])
--         elseif msg == Toile.EVENT_PERSON_OUT then
--             self:PersonGetOut(params[1], params[2])
--         elseif msg == Toile.EVENT_PERSON_ARRIVE_TARGET then
--             self:PersonArriveTarget(params)
--         end
--     end

--     function StateIdle:GetIdleClosestool()
--         for k, v in pairs(self:GetClosestool() or {}) do
--             if v.person == nil then
--                 return v
--             end
--         end
--         return nil
--     end

--     function StateIdle:GetClosestool()
--         if not self.m_closestool then
--             self.m_closestool = {}
--         end

--         local size = Tools:GetTableSize(self.parent.m_furnituresGo or {})
--         if size == 0 or size == self.lastFurnituresCount then
--             return self.m_closestool
--         end
        
--         for i,v in pairs(self.parent.m_furnituresGo or {}) do
--             if v ~= -1 and not 
--                 self.m_closestool[i] and 
--                 string.find(v.name, CfgMgr.config_furnitures[10009].object_name, 1) then
--                 self.m_closestool[i] = {go = v, person = nil}
--                 self.lastFurnituresCount = size
--             end
--         end
--         return self.m_closestool
--     end

--     function StateIdle:PersonGetIn(closestool)
--         local person = table.remove(self.m_personQueue, 1)
--         if person then
--             if person.m_queueBack then
--                 person.m_queueBack.m_queueFront = nil
--             end
--             person.m_queueBack = nil
--             person.m_inQueue = nil
                    
--             closestool.person = person
--             person.m_closestool = closestool
--             person:Event(person.EVENT_GETIN_IDLE_POSTION, {
--                 pos = UIView:GetTrans(closestool.go, "workPos").position, 
--                 dir = UIView:GetTrans(closestool.go, "face").position
--             })
--         end
--         if #self.m_personQueue > 0 then
--             self:UpdateQueue()
--         end
--     end

--     function StateIdle:PersonGetOut(person, personCount)
--         if person.m_closestool then
--             person.m_closestool.person = nil
--             person.m_closestool = nil
--             person.m_toiletNum = math.random(CfgMgr.config_global.toilet[1], CfgMgr.config_global.toilet[2])
--         end
--     end

--     function StateIdle:UpdatePersonQueue(index)
--     end


--     function StateIdle:AddQueuePath(person)
--         if person.m_inQueue or not person:HasFlag(person.FLAG_EMPLOYEE_ON_TOILET) then
--             return
--         end
  
--         person.m_queueFront = self.m_personQueue[#self.m_personQueue]
--         table.insert(self.m_personQueue, person)
--         if person.m_queueFront then
--             person.m_queueFront.m_queueBack = person
--             person.m_inQueue = true
--         end

--         if self.m_queuePath then
--             self:UpdateQueue(person)
--             return
--         end

--         local seeker = person.m_go:GetComponent("Seeker")
--         if seeker then
--             local cb = seeker.pathCallback
--             seeker.pathCallback = function(p)
--                 if p.error ~= nil then
--                     self.m_queuePath = {}
--                     local lastPos =  p.vectorPath[0]
--                     for i = 1, p.vectorPath.Count - 1 do
--                         if Vector3.Distance(lastPos, p.vectorPath[i]) > 1 then
--                             table.insert(self.m_queuePath, 1, p.vectorPath[i])
--                             lastPos = p.vectorPath[i]
--                         end
--                     end
--                     self:UpdateQueue()
--                 end
--                 seeker.pathCallback = cb
--             end
--             local start = UIView:GetTrans(self.parent.m_go, "QueueStart")
--             seeker:StartPath(start.position, self.parent.m_go.transform.position)
--         else
--             error(debug.traceback("person have no path component!"))
--         end
--     end

--     function StateIdle:UpdateQueue(person)
--         if not self.m_queuePath then
--             return
--         end

--         local ReSetTragetPosition = function(per, id)
--             local pos = self.m_queuePath[id] or self.parent.m_go.transform.position
--             if per.m_state.name == "StateWalk" then
--                 per.m_state.m_stateParams = {tragetPosition = pos}
--                 per.m_state:Enter(per)
--             else
--                 per:SetState(per.StateWalk, {tragetPosition = pos})
--             end
--         end

--         if person then
--             ReSetTragetPosition(person, person:GetQueueId())
--             return
--         end
--         for i,per in ipairs(self.m_personQueue or {}) do
--             ReSetTragetPosition(per, per:GetQueueId())
--         end
--     end

--     function StateIdle:PersonArriveTarget(person)
--         if person.m_closestool then
--             person:SetState(person.StateSitting)
--             return
--         end

--         if self.m_personQueue[1] ~= person then
--             person:SetState(person.StateQueueUp)
--             return
--         end

--         local closestool = self:GetIdleClosestool()
--         if closestool then
--             self:PersonGetIn(closestool)
--         else
--             person:SetState(person.StateQueueUp)
--         end
--     end
-- end

-- return Toile