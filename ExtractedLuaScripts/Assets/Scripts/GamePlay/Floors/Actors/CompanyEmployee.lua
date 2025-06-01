local Class = require("Framework.Lua.Class")
local Person = require "GamePlay.Floors.Actors.Person"
local Bus = require "GamePlay.Floors.Actors.Bus"
local Interactions = require "GamePlay.Floors.Actors.Interactions"
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper

local FloatUI = GameTableDefine.FloatUI
local CfgMgr = GameTableDefine.ConfigMgr
local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local GameClockManager = GameTableDefine.GameClockManager
local BuyCarManager = GameTableDefine.BuyCarManager
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local TimeManager = GameTimeManager

local CompanyEmployee = Class("CompanyEmployee", Person)

local MOOD_STATE_BAD = 1
local MOOD_STATE_NORMAL = 2
local MOOD_STATE_GOOD = 3
local MOOD_STATE_HAPPY = 4

local propertyServiceWindow = {}

CompanyEmployee.m_type = "TYPE_EMPLOYEE"
CompanyEmployee.m_category = 2000
CompanyEmployee.EVENT_GETOFF_BUS = CompanyEmployee.m_category + 1
CompanyEmployee.EVENT_GETIN_IDLE_POSTION = CompanyEmployee.m_category + 2
CompanyEmployee.EVENT_TOILE_QUEUE = CompanyEmployee.m_category + 3
CompanyEmployee.EVENT_GETIN_REST = CompanyEmployee.m_category + 4
CompanyEmployee.EVENT_TEST_QUEUE = CompanyEmployee.m_category + 5
CompanyEmployee.EVENT_GETIN_MEETING = CompanyEmployee.m_category + 6
CompanyEmployee.EVENT_GETIN_BUS = CompanyEmployee.m_category + 7
CompanyEmployee.EVENT_EMPLOYEE_DISMISS = CompanyEmployee.m_category + 8
-- CompanyEmployee.EVENT_EMPLOYEE_PROPERTY_SERVICE = CompanyEmployee.m_category + 9
CompanyEmployee.EVENT_EMPLOYEE_GOTO_ACTION = CompanyEmployee.m_category + 10

CompanyEmployee.BUFF_HIGHT_MOOD = 1 << 1

CompanyEmployee.POP_TYPE_HIGHT_MOOD  = 1
CompanyEmployee.POP_TYPE_FURN_SAT    = 2
CompanyEmployee.POP_TYPE_FURN_UNSAT  = 3
CompanyEmployee.POP_TYPE_ROOM_UNLOCK = 4
CompanyEmployee.POP_TYPE_FURN_LV     = 5
CompanyEmployee.POP_TYPE_QUEUE       = 6

---static 
function CompanyEmployee:RequestRoomService(targetGoData, brokenId, isAuto)--客房服务
    if targetGoData.idleService then
        return
    end

    local serviceNum = Tools:GetTableSize(propertyServiceWindow)
    if serviceNum <= 0 then 
        if not isAuto then EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_EVENT_BREAKDOWN")) end
        return
    end
    
    local idleService = nil
    local roomIndex = targetGoData.config.room_index
    local hint = "TXT_EVENT_LACK_PEOPLE"
    for k, v in pairs(propertyServiceWindow) do
        if v.roomIndex == roomIndex then
            -- EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_EVENT_ON_THE_WAY"))
            return
        end
        if not v.worker:HasFlag(CompanyEmployee.FLAG_EMPLOYEE_PROPERTY_ON_WORKING) 
            and v.worker:HasFlag(CompanyEmployee.FLAG_EMPLOYEE_ON_WORKING)
            and ((not v.isManager and isAuto) or (v.isManager and not isAuto)) 
        then
            idleService = v
        elseif not isAuto and v.worker:HasFlag(CompanyEmployee.FLAG_EMPLOYEE_OFF_WORKING) then
            hint = "TXT_EVENT_OFFDUTY"
        end
    end
    if not idleService then
        if not isAuto then 
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText(hint))
        end
        return
    end

    -- EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_EVENT_ON_THE_WAY"))
    local brokenCfg = CfgMgr.config_emergency[brokenId]
    local roomIndex = targetGoData.config.room_index
    local category = targetGoData.config.category[2]
    local targetTrans =  FloorMode:GetScene():GetTrans(targetGoData.go, brokenCfg.room_node[category].."/workPos") 
    local targetFaceTrans =  FloorMode:GetScene():GetTrans(targetGoData.go, brokenCfg.room_node[category].."/workPos/face")
    idleService.roomIndex = roomIndex
    idleService.serviceId = brokenId
    idleService.position = targetTrans.position
    idleService.dir = targetFaceTrans.position
    idleService.roomId = targetGoData.config.id
    idleService.worker:AddFlag(self.FLAG_EMPLOYEE_PROPERTY_ON_WORKING)
    -- idleService.worker:Event(self.EVENT_EMPLOYEE_PROPERTY_SERVICE)
    targetGoData.idleService = idleService
    -- FloorMode:GetScene():CheckRoomBrokenHint(targetGoData.config.room_index)
end

function CompanyEmployee:RoomServiceComplete(person)
    local idleService = propertyServiceWindow[person]
    if idleService then
        local roomData = FloorMode:GetRoomLocalData(idleService.roomIndex)
        if roomData.room_broken_cfg_id == 201 then
            roomData.using_count = 0
        elseif roomData.room_broken_cfg_id == 202 then
            roomData.using_time = 0
        end
        if roomData.room_broken_cfg_id then
            local cdNum = roomData.room_broken_cd["" .. roomData.room_broken_cfg_id] or 0
            roomData.room_broken_cd["" .. roomData.room_broken_cfg_id] = GameTimeManager:GetCurrentServerTime() + cdNum
            roomData.room_broken_cfg_id = nil
            LocalDataManager:WriteToFile()
        end

        local roomSceneGoData = FloorMode:GetScene():GetRoomRootGoData(idleService.roomId)
        local brokenCfg = CfgMgr.config_emergency[idleService.serviceId]
        FloorMode:GetScene():InitRoomGoUIView(roomSceneGoData)
        -- FloorMode:GetScene():GetGo(roomSceneGoData.go, brokenCfg.room_node[roomSceneGoData.config.category[2]]):SetActive(false)
        idleService.roomIndex = nil
        idleService.serviceId = nil
        idleService.position = nil
        idleService.roomId = nil
        idleService.dir = nil
        roomSceneGoData.idleService = nil

        EventManager:DispatchEvent("serve_complete")
        if self:HasFlag(self.FLAG_EMPLOYEE_MANAGER_WORKER) then
            EventManager:DispatchEvent("manager_fixed_complete")
        end
    end
end

function CompanyEmployee:ResetEmployeeDailyMeeting()
    local actorList = self:GetAllActorList()
    for k, employee in pairs(actorList) do
        if employee.m_type == CompanyEmployee.m_type 
            and employee:HasFlag(employee.FLAG_ACITVE | employee.FLAG_EMPLOYEE_ON_WORKING)
            and employee.m_employeeLocalData 
        then
            employee:AddDailyMeetingMaxLimit()
        end
    end
end
--- end static

function CompanyEmployee:Init(rootGo, prefab, position, tragetPosition, targetRotaion, dismissPositon, roomData, furnitureIndex, personID)
    self.super.Init(self, rootGo, prefab, position, tragetPosition, personID)
    self.m_targetRotaion = targetRotaion
    self.m_dismissPositon =  self:PsoitonOnGround(dismissPositon)
    self.m_roomData = roomData
    self.m_buff = {buffValue=0, buffTime = {}, buffCDTime = {}}
    self.m_moodData = {}
    self.m_furnitureIndex = furnitureIndex
    self.m_moodState = nil
    self.m_triggerCounter = {}
    self.m_interactionRoomGo = {}
    self:SetMood()
end

function CompanyEmployee:Update(dt)
    self.super.Update(self, dt)

    if TimeManager:GetSocketTime() - (self.lastTime or 0) < 1 
        or self:HasFlag(self.FLAG_EMPLOYEE_OFF_WORKING)
        or self:HasFlag(self.FLAG_EMPLOYEE_PROPERTY)
    then
        return
    end
    self.lastTime = TimeManager:GetSocketTime()
    self:UpdateMood() -- 心情
    self:Behavior() -- 互动
    self:UpdateBuff() -- 增益
    --self:UpdateProperties() -- 物业突发事件
    self:SaveTriggerInfo() -- 存档
end

function CompanyEmployee:Exit()
    if self.m_idlePositon then
        self.m_idlePositon.person = nil
        self.m_idlePositon = nil
    end
    if propertyServiceWindow[self] then
        propertyServiceWindow[self] = nil
    end
    self.m_furnitureRequirement = nil
    self.m_dialogCD = nil
    self.m_interactionRoomGo = nil
    self.m_queueFront = nil
    self.m_queueBack = nil
    self.super.Exit(self)
end

function CompanyEmployee:Event(msg, params)
    self.super.Event(self, msg, params)
    if msg == self.EVENT_GETIN_BUS then
        self.m_busPosition = params
    end
end

function CompanyEmployee:InitFloatUIView()
    self.m_viewStack = {}
    FloatUI:SetObjectCrossCamera(self, function(view)
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

function CompanyEmployee:InvokeFloatUIView(cmd, ...)
    if self.m_view then
        self.m_view:Invoke(cmd, ...)
    end
    if self.m_viewStack then
        self.m_viewStack[cmd] = {...}
    end
end

function CompanyEmployee:CheckFloatState()
    local acton = nil
    local moodIndicator = 0
    local args = nil
    if self:HasFlag(self.FLAG_EMPLOYEE_ON_TOILET) then
        acton = "WCBumble"
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_REST) then
        acton = "RestBumble"
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_MEETING) then
        acton = "ConferenceBumble"
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_ENTERTAINMENT) then
        acton = "EntertainmentBumble"
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_GYM) then
        acton = "GymBumble"
    end
    if self.m_randomAnim then
        args = self.m_randomAnim.addexp
    end
    self:InvokeFloatUIView("ShowPersonActionHint", acton, self.lastAction, self.m_state == self.StateStandup, args)
    self.lastAction = acton
end

function CompanyEmployee:ShowMoodChangeHint(state)
    local moodHint = nil
    if state == MOOD_STATE_BAD then
        moodHint = "NervousBumble"
    elseif state == MOOD_STATE_NORMAL then
        moodHint = "NormalBumble"
    elseif state == MOOD_STATE_GOOD then
        moodHint = "HappyBumble"
    elseif state == MOOD_STATE_HAPPY then
        moodHint = "JoyfulBumble"
    end
    if self.m_view and moodHint then
        self.m_view:Invoke("ShowPersonMoodState", moodHint)
    end
end

function CompanyEmployee:ShowMoodTransferHint()
    if self.m_view then
        self.m_view:Invoke("ShowMoodTransfer")
    end
end

function CompanyEmployee:Behavior(dt)
    if not self:HasFlag(self.FLAG_EMPLOYEE_ON_WORKING) 
        or self:HasFlag(self.FLAG_EMPLOYEE_DISMISS)
        or not self.m_go 
        or self.m_go:IsNull()
     then
        return
    end
    if self.m_buff and self.m_buff.buffValue and self.m_buff.buffValue ~= 0 then
        return
    end

    local UpdatePersonInteraction = function(interaction)
        if not interaction then
            return
        end
        interaction:UpdatePersonInteraction(self)
    end
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_MEETING))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_TOILET))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_REST))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_ENTERTAINMENT))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_GYM))
end

function CompanyEmployee:UpdateMood()
    if self.m_mood == self.m_targetMood then -- 需要配置
        return
    end
    self.m_mood = self.m_mood + self.m_moodTransferVlaue
    self.m_mood = math.max(math.min(self.m_mood, self.m_targetMood), GreateBuildingMana:GetMoodImprove())
    self:SetTargetMood("standard_mood", self.m_standardMood)
    self:MoodStateChange()
end

function CompanyEmployee:MoodStateChange()
    local caluMood = nil
    if self.m_mood <= CfgMgr.config_global.mood_section[1] then
        caluMood = MOOD_STATE_BAD
    elseif self.m_mood <= CfgMgr.config_global.mood_section[2] then
        caluMood = MOOD_STATE_NORMAL
    elseif self.m_mood <= CfgMgr.config_global.mood_section[3] then
        caluMood = MOOD_STATE_GOOD
    else
        caluMood = MOOD_STATE_HAPPY
    end
    if caluMood ~= self.m_moodState and self.m_moodState ~= nil then
        self:ShowMoodChangeHint(caluMood)
    end
    self.m_moodState = caluMood
end

function CompanyEmployee:GetMoodState()
    return self.m_moodState
end

function CompanyEmployee:SetTargetMood(moodType, mood, transferValue, isShow)
    if mood then
        if not transferValue then
            transferValue = self.m_mood > mood and CfgMgr.config_global.base_moon_down_rate or CfgMgr.config_global.base_moon_up_rate
            transferValue = self.m_mood == mood and 0 or transferValue
        end
        if self.m_moodData[moodType]
            and self.m_moodData[moodType].targetMood == mood
            and self.m_moodData[moodType].transferValue == transferValue 
        then
            return
        end
        self.m_moodData[moodType] = {}
        self.m_moodData[moodType].targetMood = mood
        self.m_moodData[moodType].transferValue = transferValue
        --self.m_moodData[moodType].isShow = isShow
    else
        if not self.m_moodData[moodType] then
            return
        end
        self.m_moodData[moodType] = nil
    end

    self.m_targetMood = 0
    self.m_moodTransferVlaue = 0
    local minNum, maxNum = nil, nil
    local size = Tools:GetTableSize(self.m_moodData)
    for i,v in pairs(self.m_moodData) do
        if (size > 1 and i ~= "standard_mood") or size == 1 then
            if not minNum or v.targetMood < minNum then
                minNum = v.targetMood
            end
            if not maxNum or v.targetMood > maxNum then
                maxNum = v.targetMood
            end
            self.m_moodTransferVlaue = v.transferValue + self.m_moodTransferVlaue
        end
    end
    self.m_targetMood = self.m_moodTransferVlaue > 0 and maxNum or minNum
    self:ShowMoodTransferHint()
end

function CompanyEmployee:GetMood()
    return self.m_mood or 0
end

function CompanyEmployee:GetMoodChange()
    return self.m_moodTransferVlaue or 0
end

function CompanyEmployee:SetMood()
    self.m_mood = 70
    self.m_standardMood = 70
    self.m_targetMood = 70
    self:UpdateFurnitureMood()
    if not self.m_employeeLocalData then
        return
    end
    if self.m_employeeLocalData.mood then
        self.m_mood = self.m_employeeLocalData.mood
    end
    if self.m_employeeLocalData.trigger then
        for i,v in pairs(self.m_employeeLocalData.trigger or {}) do
            self.m_triggerCounter[tonumber(i)] = v
        end
    end
    self:SetTargetMood("standard_mood", self.m_standardMood)
    self:MoodStateChange()
end

function CompanyEmployee:UpdateFurnitureMood()
    local companyData = CompanyMode:CompanyExist(self.m_roomData.config.room_index)
    local roomFurnituresData = FloorMode:GetRoomLocalData(self.m_roomData.config.room_index)
    if not companyData then
        return
    end

    local currFurnitureCfg = roomFurnituresData.furnitures[self.m_furnitureIndex]
    local companyCfg = CfgMgr.config_company[companyData.company_id]
    local targetMood = GreateBuildingMana:GetMoodImprove()
    local currFurnitureData = nil

    local furnituresDataFiltrationById = {}
    for i, v in ipairs(roomFurnituresData.furnitures or {}) do
        local furnitureCfg = CfgMgr.config_furnitures[v.id] or {}
        if not furnituresDataFiltrationById[v.id] 
            and (furnitureCfg.fixedmood_facility == 2 or (furnitureCfg.fixedmood_facility == 1 and self.m_furnitureIndex == i))
        then
            for k, fLId in ipairs(companyCfg.facility_requirement or {}) do
                local fCLCg = CfgMgr.config_furnitures_levels[fLId] or {}
                if fCLCg.furniture_id == v.id and v.level >= fCLCg.level then
                    local furnitureLevelCfg = CfgMgr.config_furnitures_levels[v.id][fCLCg.level] -- 公司表的设施等级为标准来计算
                    targetMood = targetMood + furnitureLevelCfg.mood_bonus
                    if furnitureCfg.fixedmood_facility == 2 and not furnituresDataFiltrationById[v.id] then
                        furnituresDataFiltrationById[v.id] = true
                    end
                end
                if fCLCg.furniture_id == v.id then
                    if not self.m_furnitureRequirement then
                        self.m_furnitureRequirement = {}
                    end
                    if self.m_furnitureRequirement[fLId] == nil then
                        self.m_furnitureRequirement[fLId] = false
                    end
                    self.m_furnitureRequirement[fLId] = v.level >= fCLCg.level or self.m_furnitureRequirement[fLId]
                end
            end
        end
        if i == self.m_furnitureIndex then
            currFurnitureData = v
        end
    end
    self.m_standardMood = targetMood
    self.m_employeeLocalData = currFurnitureData.employee_info
    self:SetTargetMood("standard_mood", self.m_standardMood)
end


function CompanyEmployee:SaveTriggerInfo()
    if self.m_employeeLocalData then
        if not self.m_employeeLocalData.trigger then
            self.m_employeeLocalData.trigger = {}
        end
        for i,v in pairs(self.m_triggerCounter or {}) do
            self.m_employeeLocalData.trigger[tostring(i)] = v
        end
        self.m_employeeLocalData.mood = self.m_mood
    end
    --LocalDataManager:WriteToFile()
end

function CompanyEmployee:UpdateBuff()
    if not self.m_buff then
        return
    end

    if not self:HasFlag(self.FLAG_EMPLOYEE_ON_WORKING) 
        or self:HasFlag(self.FLAG_EMPLOYEE_DISMISS | self.FLAG_EMPLOYEE_ON_ACTION) 
    then
        if UnityHelper.HasFlag(self.m_buff.buffValue or 0, self.BUFF_HIGHT_MOOD) then
            self.m_buff.buffValue = UnityHelper.RemoveFlag(self.m_buff.buffValue or 0, self.BUFF_HIGHT_MOOD)
            self.m_buff.buffTime[self.BUFF_HIGHT_MOOD] = 0
            FloorMode:GetScene():GetGo(self.m_go, "VFX_highmood"):SetActive(false)
        end
        return
    end
    self:UpdateHightMoodBuff()
end

function CompanyEmployee:UpdateHightMoodBuff()
    if self.m_state.name ~= "StateWork" then
        return
    end

    local curTime = GameTimeManager:GetCurrentServerTime()
    if UnityHelper.HasFlag(self.m_buff.buffValue or 0, self.BUFF_HIGHT_MOOD) then
        if self.m_buff.buffTime[self.BUFF_HIGHT_MOOD] < curTime then
            self.m_buff.buffValue = UnityHelper.RemoveFlag(self.m_buff.buffValue or 0, self.BUFF_HIGHT_MOOD)
            FloorMode:GetScene():GetGo(self.m_go, "VFX_highmood"):SetActive(false)
        end
        return
    end
    
    local p = CfgMgr.config_global.highmood_probility(self.m_mood)
    if self.m_mood >= CfgMgr.config_global.highmood_threshold 
        and math.random(0,100) < p 
        and (self.m_buff.buffCDTime[self.BUFF_HIGHT_MOOD] or 0) < curTime 
    then
        self.m_buff.buffValue = UnityHelper.AddFlag(self.m_buff.buffValue or 0, self.BUFF_HIGHT_MOOD)
        self.m_buff.buffTime[self.BUFF_HIGHT_MOOD] = curTime + CfgMgr.config_global.highmood_duration
        self.m_buff.buffCDTime[self.BUFF_HIGHT_MOOD] = curTime + CfgMgr.config_global.highmood_cooltime
        FloorMode:GetScene():GetGo(self.m_go, "VFX_highmood"):SetActive(true)
        self:CheckPopTalking(CompanyEmployee.POP_TYPE_HIGHT_MOOD)
    end
end

function CompanyEmployee:IsHighMoodBuff()
    return self:IsBuff(self.BUFF_HIGHT_MOOD)
end

function CompanyEmployee:IsBuff(buff)
    if not self.m_buff then
        return false
    end
    return UnityHelper.HasFlag(self.m_buff.buffValue or 0, buff)
end

-- function CompanyEmployee:UpdatePopTalking()
--     local requirement = nil
--     for k, v in pairs(self.m_furnitureRequirement or {}) do
--         if requirement == nil then
--             requirement = v
--         else
--             requirement = v and requirement
--         end
--     end

--     if requirement ~= nil then
--         if requirement then
--             self:CheckPopTalking(CompanyEmployee.POP_TYPE_FURN_SAT)
--         else
--             self:CheckPopTalking(CompanyEmployee.POP_TYPE_FURN_UNSAT)
--         end
--     end
-- end

function CompanyEmployee:CheckPopTalking(talkingType)
    if not self:HasFlag(self.FLAG_EMPLOYEE_ON_WORKING) or self:HasFlag(self.FLAG_EMPLOYEE_PROPERTY) then
        return
    end

    local cfg = CfgMgr.config_dialog[talkingType]
    if not cfg then
        return
    end

    if cfg.type == self.POP_TYPE_HIGHT_MOOD then
        self:CheckHighMoodPop(cfg)
    elseif cfg.type == self.POP_TYPE_FURN_SAT then
        self:CheckFurnitureSatisfiedPop(cfg)
    elseif cfg.type == self.POP_TYPE_FURN_UNSAT then
        self:CheckFurnitureUnsatisfiedPop(cfg)
    elseif cfg.type == self.POP_TYPE_ROOM_UNLOCK then
        self:CheckRoomUnlockPop(cfg)
    elseif cfg.type == self.POP_TYPE_FURN_LV then
        self:CheckInteractiveEndPop(cfg)
    elseif cfg.type == self.POP_TYPE_QUEUE then
        self:CheckInteractiveQueuePop(cfg)
    end
end

function CompanyEmployee:CheckHighMoodPop(cfg)
    self:ShowTalkPop(cfg)
end
function CompanyEmployee:CheckFurnitureUnsatisfiedPop(cfg)
    local fIds = {}
    for k, v in pairs(self.m_furnitureRequirement or {}) do
        if not v then table.insert(fIds, k) end
    end
    local fId = fIds[math.random(1, #fIds)]
    local fLvId, fLv = CfgMgr.config_furnitures_levels[fId].furniture_id, CfgMgr.config_furnitures_levels[fId].level
    local insertText = FloorMode:GetFurnitureName(fLvId, fLv)
    self:ShowTalkPop(cfg, insertText)
end
function CompanyEmployee:CheckFurnitureSatisfiedPop(cfg)
    self:ShowTalkPop(cfg)
end
function CompanyEmployee:CheckRoomUnlockPop(cfg)
    local roomIndex = nil
    for i,v in ipairs(cfg.room_index or {}) do
        local data = FloorMode:GetRoomLocalData(v)
        if data and data.unlock == false then
            roomIndex = v
            break
        end
    end
    if roomIndex then
        local room_index_number = string.match(roomIndex, "%d+")
        local insertText = FloorMode:GetRoomName(room_index_number)
        self:ShowTalkPop(cfg, insertText)
    end
end
function CompanyEmployee:CheckInteractiveEndPop(cfg)
    if not self.m_randomAnim then
        return 
    end
    local lv = self.m_randomAnim.furnitureLv or 1
    local newCfg = Tools:CopyTable(cfg)

    for i,v in ipairs(newCfg.npc_dialog or {}) do
        newCfg.npc_dialog[i] = string.format(v, lv)
    end

    local furnitureName = FloorMode:GetFurnitureName(self.m_randomAnim.fId, lv)
    self:ShowTalkPop(newCfg, furnitureName)
end
function CompanyEmployee:CheckInteractiveQueuePop(cfg)
    local interactions = self:GetCurrentInteractionEntity()
    if not interactions then
        return
    end
    local roomName = FloorMode:GetRoomName(interactions.m_config.room_index_number)
    self:ShowTalkPop(cfg, roomName)
end

function CompanyEmployee:ShowTalkPop(cfg, insertText)
    if math.random(0, 100) >= cfg.dialog_probility then
        return
    end
    if cfg.dialog_cooltime then
        self.m_dialogCD = self.m_dialogCD or {}
        if (self.m_dialogCD[cfg.id] or 0) >= TimeManager:GetSocketTime() then
            return 
        end
        self.m_dialogCD[cfg.id] = TimeManager:GetSocketTime() + cfg.dialog_cooltime
    end
    
    if self.m_view then
        local text = cfg.npc_dialog[math.random(1, #cfg.npc_dialog)]
        text = GameTextLoader:ReadText(text)
        if insertText then
            text = string.format(text, insertText)
        end
        -- text = string.format("%s<sprite=%s>", text, "icon_mood_"..self:GetMoodState())
        self.m_view:Invoke("ShowPersonTalkingPop", text, self:GetMoodState())
    end
end

function CompanyEmployee:GetDailyMeetingLocalData()
    if not self.m_employeeLocalData then
        return {num = "0", max = "0"} -- debug info
    end
    if tonumber(self.m_employeeLocalData.met_day) then
        self.m_employeeLocalData.daily_meeting_info = {day = self.m_employeeLocalData.met_day, num = 1, max = 1}
        self.m_employeeLocalData.met_day = nil
    end
    if not self.m_employeeLocalData.daily_meeting_info then
        self.m_employeeLocalData.daily_meeting_info = {}
    end

    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    if self.m_employeeLocalData.daily_meeting_info.day ~= gameD then
        self.m_employeeLocalData.daily_meeting_info = {day = gameD, num = 0, max = 1}
    end
    return self.m_employeeLocalData.daily_meeting_info
end

function CompanyEmployee:CheckDailyMeetingValid()
    local localData = self:GetDailyMeetingLocalData()
    if localData.num < localData.max then
        return true
    end
    return false
end

function CompanyEmployee:AddDailyMeetingMaxLimit()
    local localData = self:GetDailyMeetingLocalData()
    localData.max = localData.max + 1
end

function CompanyEmployee:AddDailyMeetingNumber()
    local localData = self:GetDailyMeetingLocalData()
    localData.num = localData.num + 1
end

function CompanyEmployee:GetDebugInfo()
    local toiletInfo    = "尿:" .. (self.m_triggerCounter[self.FLAG_EMPLOYEE_ON_TOILET] or 0) .. "\n"
    local restInfo      = "疲:" .. (self.m_triggerCounter[self.FLAG_EMPLOYEE_ON_REST] or 0) .. "\n"
    local enterInfo     = "娱:" .. (self.m_triggerCounter[self.FLAG_EMPLOYEE_ON_ENTERTAINMENT] or 0) .. "\n"
    local gymInfo       = "健:" .. (self.m_triggerCounter[self.FLAG_EMPLOYEE_ON_GYM] or 0) .. "\n"
    local moodInfo      = "心:" .. (self.m_mood or 0) .. "\n"
    local moodTInfo     = "变:" .. (self.m_moodTransferVlaue or 0) .. "," .. (self.m_targetMood or 0) .. "\n"
    local meetingInfo   = "会:" .. (self:GetDailyMeetingLocalData().num .. "," ..self:GetDailyMeetingLocalData().max) .. "\n"
    local buffInfo      = "益:" .. (self.m_buff.buffValue or 0) .. "\n"
    local stateInfo     = "态:" .. self.m_state.name .. "\n"
    local queueInfo     = "队:" 
    local flagInfo      = {}
    for i=1,40 do
        if self:HasFlag(1 << i) then
            table.insert(flagInfo, i)
        end
        if i>=30 and i <= 33 and self:HasFlag(1 << i) then
            queueInfo = queueInfo .. i .. ","
        end
    end
    queueInfo = queueInfo .. (self:HasFlag(self.FLAG_EMPLOYEE_IN_QUEUE) and self:GetQueueId() or 0) .. "\n"
    flagInfo = "旗:"..table.concat(flagInfo, ",") .. "\n"
    return table.concat({queueInfo, toiletInfo, restInfo, enterInfo, gymInfo, moodInfo, moodTInfo, meetingInfo, buffInfo, stateInfo, flagInfo})
end

-- function CompanyEmployee:GetEntity(ent)
--     return Interactions:GetEntity(ent)
-- end 

function CompanyEmployee:SetPersonBonuses(randomAnim, types, localData)
    local data = localData or self.m_idlePositon.localData
    local config = CfgMgr.config_furnitures_levels[data.id][data.level] or {}
    for i, type in ipairs(types or {}) do
        randomAnim[type] = config[type] or 0
    end
    randomAnim.furnitureLv = data.level
    randomAnim.fId = data.id
    if not data.accessory_info then
        return
    end
    for k, v in pairs(data.accessory_info) do
        if k == FloorMode.F_TYPE_AUX_CONDITION or k == FloorMode.F_TYPE_AUX_PROPERTY then
            for i, info in pairs(v) do
                local accessoryLevelId = info.lvId
                local accessoryId, accessoryLevel = CfgMgr.config_furnitures_levels[accessoryLevelId].furniture_id, CfgMgr.config_furnitures_levels[accessoryLevelId].level
                local accessoryConifg = CfgMgr.config_furnitures_levels[accessoryId][accessoryLevel]
                for _, type in ipairs(types or {}) do
                    randomAnim[type] = randomAnim[type] + (accessoryConifg[type] or 0)
                end
            end
        end
    end
end

function CompanyEmployee:GetInteractionEntity(tag)
    if not self.m_interactionRoomGo then
        self.m_interactionRoomGo = {}
    end
    if self.m_interactionRoomGo[tag] 
        and (self.m_updateIntercationTag == self.m_interactionRoomGo[tag]:GetPersonUpdateIntercationTag() or self.m_state ~= self.StateWork)
    then
        return self.m_interactionRoomGo[tag]
    end
    local entities = Interactions:GetEntities(tag)
    local dis1,dis2 = nil
    local defaultEntity = nil
    for k,v in pairs(entities or {}) do
        local pY = self.m_targetPosition.y
        local iY = 99999
        if v.m_go and not v.m_go:IsNull() then
            iY = v.m_go.transform.position.y
        end
        local d = math.abs(pY - iY) -- UnityHelper.CalculateDistanceY(self.m_go, v.m_go) -- math.abs(self.m_go.transform.position.y - v.m_go.transform.position.y)
        local size = self:GetTableSize(v.StateIdle:GetPosition())
        if not dis1 or d < dis1 then
            defaultEntity = v
            dis1 = d
        end
        if (not dis2 or d < dis2) and size > 0 then
            self.m_interactionRoomGo[tag] = v
            dis2 = d
        end
    end
    if self.m_interactionRoomGo[tag] then
        self.m_updateIntercationTag = self.m_interactionRoomGo[tag]:GetPersonUpdateIntercationTag()
        return self.m_interactionRoomGo[tag]
    else
        return defaultEntity
    end
end

function CompanyEmployee:GetCurrentInteractionEntity()
    if self:HasFlag(self.FLAG_EMPLOYEE_ON_TOILET) then
        return self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_TOILET)
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_REST) then
        return self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_REST)
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_MEETING) then
        return self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_MEETING)
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_ENTERTAINMENT) then
        return self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_ENTERTAINMENT)
    elseif self:HasFlag(self.FLAG_EMPLOYEE_ON_GYM) then
        return self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_GYM)
    end
end

function Person:ResetTriggerCounter()
    local UpdatePersonInteraction = function(interaction)
        if not interaction then
            return
        end
        interaction:ResetTriggerCounter(self)
    end
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_MEETING))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_TOILET))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_REST))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_ENTERTAINMENT))
    UpdatePersonInteraction(self:GetInteractionEntity(self.FLAG_EMPLOYEE_ON_GYM))
end

function CompanyEmployee:OverrideStates()
    --
    local StateLoading = self:OverrideState(self.StateLoading)
    function StateLoading:Event(person, msg, params)
        self.super.Event(self, person, msg)
        if msg == person.LOADING_COMPLETE then
            -- person.m_go.transform.localScale = {x=3,y=3,z=3}
            if person:HasFlag(person.FLAG_EMPLOYEE_OFF_WORKING) then
                person:SetState(person.StateInBus)
            elseif person:HasFlag(person.FLAG_EMPLOYEE_ON_WORKING) then
                -- UnityHelper.IgnoreRendererByObject(FloorMode:GetScene():GetGo(person.m_roomData.go, "struct/DiTan"), person.m_go)
                person.m_go.transform.position = person.m_targetPosition
                UnityHelper.RotateTowards(person.m_go.transform, person.m_targetRotaion)
                person:SetState(person.StateWork)
            elseif person:HasFlag(person.FLAG_EMPLOYEE_BY_BUS) then
                local bus = Bus:GetBusEntity()
                bus:Event(bus.EVENT_NEW_PASSENGER, person)
            else
                local params = {tragetPosition = person.m_targetPosition, finalRotaionPosition = person.m_targetRotaion}
                person:SetState(person.StateWalk, params)
            end
            if person:HasFlag(person.FLAG_EMPLOYEE_PROPERTY_WORKER | person.FLAG_EMPLOYEE_MANAGER_WORKER) then
                propertyServiceWindow[person] = nil
                propertyServiceWindow[person] = {worker = person, roomIndex = nil, serviceType = nil, serviceState = 0}
                propertyServiceWindow[person].isManager = person:HasFlag(person.FLAG_EMPLOYEE_MANAGER_WORKER)
            end
            person:InitFloatUIView()
        elseif msg == person.EVENT_GETOFF_BUS then 
            EventManager:DispatchEvent("Employee_come",person.m_go)
            person.m_go.transform.position = params
            person:SetState(person.StateWalk, {tragetPosition = person.m_targetPosition, finalRotaionPosition = person.m_targetRotaion, speed = CfgMgr.config_global.character_run_v})
        end
        person:SetModeActive(true)
    end

    -- idle
    -- local StateIdle = self:OverrideState(self.StateIdle)
    -- function StateIdle:Event(person, msg, params)
    --     self.super.Event(self, person, msg)
    --     if msg == person.EVENT_GETIN_REST then
    --         person:SetState(person.StateWalk, {tragetPosition = params.pos, finalRotaionPosition = params.dir})
    --     end
    -- end
    
    --
    local StateWalk = self:OverrideState(self.StateWalk)
    function StateWalk:Enter(person, msg, params)
        if person:HasFlag(person.FLAG_EMPLOYEE_ON_TOILET) then
            if person.m_go then
                --print("Enter toilet state walk, go's name is:"..person.m_go.name)
            end
        end
        if person:HasFlag(person.FLAG_EMPLOYEE_ON_TOILET) and not person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) then--上厕所改成跑步
            self.m_stateParams.speed = CfgMgr.config_global.character_run_v
        end
        if person:HasFlag(person.FLAG_EMPLOYEE_OFF_WORKING) and person.m_busPosition and not person:HasFlag(person.FLAG_EMPLOYEE_ON_ACTION) then
            self.m_stateParams = {tragetPosition = person.m_busPosition, speed = CfgMgr.config_global.character_run_v}
        end
        if person:HasFlag(person.FLAG_EMPLOYEE_DISMISS) then
            person:RemoveFlag(person.FLAG_EMPLOYEE_OFF_WORKING | person.FLAG_EMPLOYEE_ON_WORKING)
            self.m_stateParams = {tragetPosition = person.m_dismissPositon, speed = CfgMgr.config_global.character_run_v}
        end
        if person:HasFlag(person.FLAG_EMPLOYEE_PROPERTY_ON_WORKING) then
            FloorMode:GetScene():GetGo(person.m_go, "WorkState"):SetActive(true)
        end
        if person:HasFlag(person.FLAG_EMPLOYEE_MANAGER_LEAVE) then
            person:RemoveFlag(person.FLAG_EMPLOYEE_MANAGER_LEAVE)
            if person:HasFlag(person.FLAG_EMPLOYEE_OFF_WORKING) then
                person:Event(person.EVENT_ARRIVE_FINAL_TARGET)
                return
            end
        end
        self.super.Enter(self, person, params)
        person:CheckFloatState()
    end
    
    function StateWalk:Event(person, msg, params)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_ARRIVE_FINAL_TARGET then
            if person:HasFlag(person.FLAG_EMPLOYEE_ON_ACTION) and person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) then
                local interactions = person:GetCurrentInteractionEntity()
                interactions:Event(interactions.EVENT_PERSON_ARRIVE_TARGET, person)
            elseif person.m_busPosition then
                local bus = Bus:GetBusEntity()
                if person:HasFlag(person.FLAG_EMPLOYEE_MANAGER_WORKER) then
                    bus = Bus:GetCarEntity() or bus
                end
                bus:Event(bus.EVENT_PERSON_IN, {person, 0})
            elseif person:HasFlag(person.FLAG_EMPLOYEE_PROPERTY_ON_WORKING) then
                person:SetState(person.StateService)
            elseif person:HasFlag(person.FLAG_EMPLOYEE_DISMISS) then
                person:Exit()
            else
                person:SetState(person.StateSitting)
            end
        elseif msg == person.EVENT_GETIN_IDLE_POSTION then
            self.m_stateParams.tragetPosition = params.pos
            self.m_stateParams.finalRotaionPosition = params.dir
            self:Enter(person)
        elseif msg == person.EVENT_GETIN_BUS and not person:HasFlag(person.FLAG_EMPLOYEE_ON_ACTION) then
            self.m_stateParams.tragetPosition = params
            self.m_stateParams.speed = CfgMgr.config_global.character_run_v
            self:Enter(person)
        elseif msg == person.EVENT_EMPLOYEE_DISMISS then
            self:Enter(person)
        elseif msg == person.EVENT_ADD_FLAG and params == person.FLAG_EMPLOYEE_PROPERTY_ON_WORKING then
            local window = propertyServiceWindow[person]
            if window then
                self.m_stateParams = {tragetPosition = window.position, finalRotaionPosition = window.dir, speed = CfgMgr.config_global.character_run_v}
                self:Enter(person)
            end
        elseif (msg == person.EVENT_ADD_FLAG and params == person.FLAG_EMPLOYEE_ON_MEETING) or msg == person.EVENT_EMPLOYEE_GOTO_ACTION then
            local interactions = person:GetCurrentInteractionEntity()
            if not interactions then
                return
            end
            local _,posData = next(interactions.StateIdle:GetPosition())
            self.m_stateParams =  {tragetPosition = posData.pos or interactions.m_go.transform.position}
            self:Enter(person)
        elseif msg == person.EVENT_ADD_FLAG and params == person.FLAG_EMPLOYEE_MANAGER_LEAVE then
            local bus = Bus:GetBusEntity()
            if person:HasFlag(person.FLAG_EMPLOYEE_MANAGER_WORKER) then
                bus = Bus:GetCarEntity() or bus
            end
            bus:Event(bus.EVENT_PERSON_IN, {person, 0})
        end
    end

    --
    local StateSitting = self:OverrideState(self.StateSitting)
    function StateSitting:Event(person, msg)
        if msg == person.EVENT_IDLE2SIT_END then
            if person:HasFlag(person.FLAG_EMPLOYEE_ON_ACTION) and person:HasFlag(person.FLAG_EMPLOYEE_IN_QUEUE) then 
                person:SetState(person.StateToilet)
            else
                person:SetState(person.StateWork)
                EventManager:DispatchEvent("Employee_leave")
            end
        end
    end

    --
    local StateWork = self:OverrideState(self.StateWork)
    function StateWork:Enter(person)
        self.super.Enter(self, person)
        if not person:HasFlag(person.FLAG_EMPLOYEE_OFF_WORKING) then
            person:AddFlag(person.FLAG_EMPLOYEE_ON_WORKING)
        end
    end
    function StateWork:Update(person, dt)
        self.super.Update(self, person)
        --self:Behavior(person)
        if person:HasFlag(person.FLAG_EMPLOYEE_DISMISS) 
            or person:HasFlag(person.FLAG_EMPLOYEE_ON_ACTION) 
            or (person:HasFlag(person.FLAG_EMPLOYEE_OFF_WORKING) and person.m_busPosition) 
            or person:HasFlag(person.FLAG_EMPLOYEE_PROPERTY_ON_WORKING) 
        then
            person:SetState(person.StateStandup)
            return
        end
        self:CheckPopTolking(person)
    end

    function StateWork:Event(person, msg, args)
        self.super.Event(self, person)
    end

    function StateWork:CheckPopTolking(person)
        if TimeManager:GetSocketTime() - (self.lastUpdateTime or 0) < 1 then
            return
        end
        self.lastUpdateTime = TimeManager:GetSocketTime()
        local requirement = nil
        for k, v in pairs(person.m_furnitureRequirement or {}) do
            if requirement == nil then
                requirement = v
            else
                requirement = v and requirement
            end
        end
        if requirement ~= nil then
            if requirement then
                person:CheckPopTalking(CompanyEmployee.POP_TYPE_FURN_SAT)
            else
                person:CheckPopTalking(CompanyEmployee.POP_TYPE_FURN_UNSAT)
            end
        end
    end

    --
    local StateStandup = self:OverrideState(self.StateStandup)
    function StateStandup:Enter(person)
        self.super.Enter(self, person)
    end
    function StateStandup:Event(person, msg)
        self.super.Event(self, person, msg)
        if msg == person.EVENT_SIT2IDLE_END then
            local params = nil
            if person:HasFlag(person.FLAG_EMPLOYEE_DISMISS) then
                params = {tragetPosition = person.m_dismissPositon, finalRotaionPosition = person.m_targetRotaion, speed = CfgMgr.config_global.character_run_v}
            elseif person:HasFlag(person.FLAG_EMPLOYEE_PROPERTY_ON_WORKING) then
                local window = propertyServiceWindow[person]
                if window then
                    params = {tragetPosition = window.position, finalRotaionPosition = window.dir, speed = CfgMgr.config_global.character_run_v}
                end
            elseif person:HasFlag(person.FLAG_EMPLOYEE_ON_ACTION) then
                local interactions = person:GetCurrentInteractionEntity()
                local _,posData = next(interactions.StateIdle:GetPositon())
                params = {tragetPosition = posData.pos or interactions.m_go.transform.position}
            else
                params = {tragetPosition = person.m_targetPosition, finalRotaionPosition = person.m_targetRotaion}
            end
            person:SetState(person.StateWalk, params)
        end
    end

    -- 开会 娱乐 上厕所 休息 通用
    local StateToilet = self:OverrideState(self.StateToilet)
    function StateToilet:Enter(person)
        self.super.Enter(self, person)
        if person.m_randomAnim.pleasure > 0 then
             person:SetTargetMood("entertainment_type_", 500, person.m_randomAnim.pleasure)
        end
    end
    function StateToilet:Exit(person)
        if person.m_randomAnim and person.m_randomAnim.addexp > 0 then
            CompanyMode:RoomAddExp(person.m_roomData.config.room_index, person.m_randomAnim.addexp)
            person:AddDailyMeetingNumber() -- 等待修改为永久存档
        end
        person:CheckPopTalking(CompanyEmployee.POP_TYPE_FURN_LV) -- 在互动行为结束后会进入一次检定
        self.super.Exit(self, person)
        person:SetTargetMood("entertainment_type_")
        person:CheckFloatState()
        person.m_randomAnim = nil
        GameTimer:CreateNewTimer(math.random(4, 8), function()
            person:CheckPopTalking(CompanyEmployee.POP_TYPE_ROOM_UNLOCK) -- 回去的路上检查功能型房间在场景中存在并且未解锁
        end)
    end

    local StateQueueUp = self:OverrideState(self.StateQueueUp)
    function StateQueueUp:Update(person, dt)
        self.super.Update(self, person, dt)
        if TimeManager:GetSocketTime() - (self.lastUpdateTime or 0) < 1 then
            return
        end
        self.lastUpdateTime = TimeManager:GetSocketTime()
        local interactions = person:GetCurrentInteractionEntity()
        if not interactions then
            return
        end
        local moodData = person.m_moodData["interaction_type_" .. interactions.m_interactionType]
        if not moodData or moodData.transferValue >= 0 then
            return
        end
        person:CheckPopTalking(CompanyEmployee.POP_TYPE_QUEUE)
    end
end

return CompanyEmployee