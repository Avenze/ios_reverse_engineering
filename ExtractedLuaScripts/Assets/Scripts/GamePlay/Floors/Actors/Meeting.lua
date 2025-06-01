-- local Class = require("Framework.Lua.Class")
-- local Actor = require("GamePlay.Floors.Actors.Actor")

--  local FloatUI = GameTableDefine.FloatUI
--  local FloorMode = GameTableDefine.FloorMode
--  local CfgMgr = GameTableDefine.ConfigMgr
 
--  local GameObject = CS.UnityEngine.GameObject

-- local UIView = require("Framework.UI.View")
-- local EventManager = require("Framework.Event.Manager")
-- local TimeManager = GameTimeManager

-- local Meeting = Class("Meeting", Actor)

-- local STATE_LOADING = "StateLoading"
-- local STATE_IDLE = "StateIdle"

-- Meeting.EVENT_PERSON_IN = 501
-- Meeting.EVENT_PERSON_OUT = 502

-- Meeting.m_type = "TYPE_MEETING"

-- local MeetingEntity = nil

-- function Meeting:ctor()
--     self:getSuper(Meeting).ctor(self)
-- end

-- function Meeting:Init(rootGo, furnituresGo)
--     self.m_go = rootGo
--     self.m_furnituresGo = furnituresGo
--     self:getSuper(Meeting).Init(self)
--     self:SetState(self.StateIdle)
-- end

-- function Meeting:Update(dt)
--     self:getSuper(Meeting).Update(self, dt)
-- end

-- function Meeting:Exit()
--     self:getSuper(Meeting).Exit(self)
-- end

-- function Meeting:Event(msg, params)
--     self:getSuper(Meeting).Event(self, msg, params)
-- end

-- function Meeting:InitFloatUIView()
--     FloatUI:SetObjectCrossCamera(self, function(view)
--         if view then
--             view:Invoke("ShowEventBumble")
--         end
--     end)
-- end

-- function Meeting:RemoveFloatUIView()
--     FloatUI:RemoveObjectCrossCamera(self)
-- end

-- function Meeting:GetMeetingEntity()
--     if MeetingEntity then
--         return MeetingEntity
--     end

--     MeetingEntity = self:CreateActor()
--     return MeetingEntity
-- end

-- function Meeting:ClearEntity()
--     MeetingEntity = nil
-- end

-- function Meeting:MeetingAcitve()
--     local size = Tools:GetTableSize(MeetingEntity.StateIdle:GetChair())
--     return size > 0 and self.m_roomId == nil
-- end

-- function Meeting:SetRoomId(id)
--     self.m_roomId = id
-- end

-- function Meeting:InitStates()
--     local StateLoading = self:InitState(STATE_LOADING)
--     function StateLoading:Enter(Meeting)
--         Meeting:CreateGo()
--     end

--     function StateLoading:Update(Meeting, dt)
--     end

--     function StateLoading:Exit(Meeting)
--     end

--     function StateLoading:Event(Meeting, msg)
--     end

--     -- idle
--     local StateIdle = self:InitState(STATE_IDLE)
--     function StateIdle:Enter(Meeting)
--         self.m_personQueue = {}
--     end

--     function StateIdle:Update(Meeting, dt)
--     end

--     function StateIdle:Exit(Meeting)
--     end

--     function StateIdle:Event(Meeting, msg, params)
--         if msg == Meeting.EVENT_PERSON_IN then
--             self:PersonGetIn(params[1], params[2])
--         elseif msg == Meeting.EVENT_PERSON_OUT then
--             self:PersonGetOut(params[1], params[2])
--         end
--     end

--     function StateIdle:GetChair()
--         if not self.m_chair then
--             self.m_chair = {}
--         end

--         local size = Tools:GetTableSize(self.parent.m_furnituresGo or {})
--         if size == 0 or size == self.lastFurnituresCount then
--             return self.m_chair
--         end
        
--         for i,v in pairs(self.parent.m_furnituresGo or {}) do
--             if v ~= -1 and not 
--                 self.m_chair[i] and 
--                 string.find(v.name, CfgMgr.config_furnitures[10006].object_name, 1) then
--                 self.m_chair[i] = {}
--                 for k=1,10 do
--                     self.m_chair[i][k] = {pos = UIView:GetTrans(v, "workPos_"..k).position, dir = UIView:GetTrans(v, "face_"..k).position}
--                 end
--                 self.lastFurnituresCount = size
--             end
--         end
--         return self.m_chair
--     end

--     function StateIdle:PersonGetIn(person, personCount)
--         local chair = nil
--         for k,v in pairs(self:GetChair() or {}) do
--             for i,p in ipairs(v) do
--                 if p.person == nil then
--                     chair = p
--                     break
--                 end
--             end
--         end
--         if not chair then
--             local pos = self.parent.m_go.transform.position
--             pos.x = pos.x + math.random(-6,6)
--             pos.z = pos.z + math.random(-6,6)
--             person.m_chair = {pos = pos, isStand = true}
--             person:Event(person.EVENT_GETIN_MEETING, person.m_chair)
--             return
--         end
--         chair.person = person
--         person.m_chair = chair
--         person:Event(person.EVENT_GETIN_MEETING, chair)
--     end

--     function StateIdle:PersonGetOut(person, personCount)
--         person.m_chair.person = nil
--         person.m_chair = nil
--         if personCount == 0 then
--             self.parent:SetRoomId(nil)
--         end
--     end
-- end

-- return Meeting