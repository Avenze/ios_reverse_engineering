-- local Class = require("Framework.Lua.Class")
-- local Actor = require("GamePlay.Floors.Actors.Actor")

--  local FloatUI = GameTableDefine.FloatUI
--  local FloorMode = GameTableDefine.FloorMode
--  local CfgMgr = GameTableDefine.ConfigMgr
 
--  local GameObject = CS.UnityEngine.GameObject

-- local UIView = require("Framework.UI.View")
-- local EventManager = require("Framework.Event.Manager")
-- local TimeManager = GameTimeManager

-- local Lounge = Class("Lounge", Actor)

-- local STATE_LOADING = "StateLoading"
-- local STATE_IDLE = "StateIdle"

-- Lounge.EVENT_PERSON_IN = 401
-- Lounge.EVENT_PERSON_OUT = 402

-- Lounge.m_type = "TYPE_LOUNGE"

-- local loungeEntity = nil

-- function Lounge:ctor()
--     self:getSuper(Lounge).ctor(self)
-- end

-- function Lounge:Init(rootGo, furnituresGo)
--     self.m_go = rootGo
--     self.m_furnituresGo = furnituresGo
--     self:getSuper(Lounge).Init(self)
--     self:SetState(self.StateIdle)
-- end

-- function Lounge:Update(dt)
--     self:getSuper(Lounge).Update(self, dt)
-- end

-- function Lounge:Exit()
--     self:getSuper(Lounge).Exit(self)
-- end

-- function Lounge:Event(msg, params)
--     self:getSuper(Lounge).Event(self, msg, params)
-- end

-- function Lounge:InitFloatUIView()
--     FloatUI:SetObjectCrossCamera(self, function(view)
--         if view then
--             view:Invoke("ShowEventBumble")
--         end
--     end)
-- end

-- function Lounge:RemoveFloatUIView()
--     FloatUI:RemoveObjectCrossCamera(self)
-- end

-- function Lounge:GetLoungeEntity()
--     if loungeEntity then
--         return loungeEntity
--     end

--     loungeEntity = self:CreateActor()
--     return loungeEntity
-- end

-- function Lounge:ClearEntity()
--     loungeEntity = nil
-- end

-- function Lounge:LoungeAcitve()
--     local size = Tools:GetTableSize(loungeEntity.StateIdle:GetSofa())
--     return size > 0
-- end

-- function Lounge:InitStates()
--     local StateLoading = self:InitState(STATE_LOADING)
--     function StateLoading:Enter(lounge)
--         lounge:CreateGo()
--     end

--     function StateLoading:Update(lounge, dt)
--     end

--     function StateLoading:Exit(lounge)
--     end

--     function StateLoading:Event(lounge, msg)
--     end

--     -- idle
--     local StateIdle = self:InitState(STATE_IDLE)
--     function StateIdle:Enter(lounge)
--         self.m_personQueue = {}
--     end

--     function StateIdle:Update(lounge, dt)
--     end

--     function StateIdle:Exit(lounge)
--     end

--     function StateIdle:Event(lounge, msg, params)
--         if msg == Lounge.EVENT_PERSON_IN then
--             self:PersonGetIn(params[1], params[2])
--         elseif msg == Lounge.EVENT_PERSON_OUT then
--             self:PersonGetOut(params[1], params[2])
--         end
--     end

--     function StateIdle:GetSofa()
--         if not self.m_sofa then
--             self.m_sofa = {}
--         end
--         local size = Tools:GetTableSize(self.parent.m_furnituresGo or {})
--         if size == 0 or size == self.lastFurnituresCount then
--             return self.m_sofa
--         end
        
--         for i,v in pairs(self.parent.m_furnituresGo or {}) do
--             if v ~= -1 and not 
--                 self.m_sofa[i] and 
--                 string.find(v.name, CfgMgr.config_furnitures[10033].object_name, 1) then
--                 self.m_sofa[i] = {}
--                 self.m_sofa[i][1] = {pos = UIView:GetTrans(v, "workPos_1").position, dir = UIView:GetTrans(v, "face_1").position}
--                 self.m_sofa[i][2] = {pos = UIView:GetTrans(v, "workPos_2").position, dir = UIView:GetTrans(v, "face_2").position}
--                 self.m_sofa[i][3] = {pos = UIView:GetTrans(v, "workPos_3").position, dir = UIView:GetTrans(v, "face_3").position}
--                 self.lastFurnituresCount = size
--             end
--         end
--         return self.m_sofa
--     end

--     function StateIdle:PersonGetIn(person, personCount)
--         local sofa = nil
--         for k,v in pairs(self:GetSofa() or {}) do
--             for i,p in ipairs(v) do
--                 if p.person == nil then
--                     sofa = p
--                     break
--                 end
--             end
--         end
--         if not sofa then
--             --if #self.m_personQueue > 0 then
--                 local pos = self.parent.m_go.transform.position
--                 pos.x = pos.x + math.random(-6,6)
--                 pos.z = pos.z + math.random(-6,6)
--                 person.m_sofa = {pos = pos, isStand = true}
--                 person:Event(person.EVENT_GETIN_REST, person.m_sofa)
--             --end
--             --table.insert(self.m_personQueue, person)
--             return
--         end
--         sofa.person = person
--         person.m_sofa = sofa
--         person:Event(person.EVENT_GETIN_REST, sofa)
--     end

--     function StateIdle:PersonGetOut(person, personCount)
--         person.m_sofa.person = nil
--         person.m_sofa = nil
--         person.m_estingNum = math.random(CfgMgr.config_global.tired[1], CfgMgr.config_global.tired[2])
--         -- local queue = table.remove(self.m_personQueue, 1)
--         -- if queue then
--         --     self:PersonGetIn(queue, personCount)
--         -- end
--     end
-- end

-- return Lounge