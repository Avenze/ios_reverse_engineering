local MeetingEventManager = GameTableDefine.MeetingEventManager
local CfgMgr = GameTableDefine.ConfigMgr
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
local CompanyMode = GameTableDefine.CompanyMode
local GameClockManager = GameTableDefine.GameClockManager
local EventMeetingUI = GameTableDefine.EventMeetingUI

local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local lcoalData = nil
local scene = nil
local timer = nil
local interval = 0
local isActiveEvent = false
local TimerMgr = GameTimeManager

function MeetingEventManager:Init()
    scene = FloorMode:GetScene()
    interval = 1 * 1000
    self.lastUpdateTime = TimerMgr:GetDeviceTimeInMilliSec() + 5000
    isActiveEvent = false
end

function MeetingEventManager:Update()
    if not interval or interval == 0 then
        return
    end
    local curTime = TimerMgr:GetDeviceTimeInMilliSec()
    if curTime - self.lastUpdateTime >= interval then
        self.lastUpdateTime = curTime
        self:CheckEvent()
    end
end

function MeetingEventManager:Exit()
    interval = 0
    self.lastUpdateTime = 0
end

function MeetingEventManager:GetLocalDate()
    if lcoalData then
        return lcoalData
    end
    lcoalData = LocalDataManager:GetDataByKey("meeting_event")
    return lcoalData
end

function MeetingEventManager:CheckEvent()
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    local durationCfg = CfgMgr.config_global.tempConf_duration or {}
    if gameH < durationCfg[1] or gameH > durationCfg[2] then
        if isActiveEvent then
            MainUI:SetMeetingEventHint(false)
            EventMeetingUI:DestroyModeUIObject()
            isActiveEvent = false
        end
        return
    end
    if isActiveEvent then
        return
    end

    local curDate = DiamondRewardUI:GetDate()
    local lcoalData = self:GetLocalDate()
    if (lcoalData.date ~= curDate or lcoalData.count < CfgMgr.config_global.tempConf_limit) 
        and (lcoalData.time_point or 0) < TimerMgr:GetCurrentServerTime()
        and self:CheckDailyMeetingComplete()
    then
        self:ActiveEvent()
    end
end

function MeetingEventManager:ActiveEvent()
    MainUI:SetMeetingEventHint(true)
    isActiveEvent = true
end

function MeetingEventManager:FinishEvent()
    local data = self:GetLocalDate()
    local curDate = DiamondRewardUI:GetDate()
    if data then
        if data.date ~= curDate then
            data.count = 1
            data.date = curDate
        else
            data.count = data.count + 1
        end
        local t = math.random(CfgMgr.config_global.tempConf_interval[1], CfgMgr.config_global.tempConf_interval[2]) * 60
        data.time_point = TimerMgr:GetCurrentServerTime() + t
    end
    isActiveEvent = false
    MainUI:SetMeetingEventHint(false)
end

function MeetingEventManager:CheckDailyMeetingComplete()
    local compData = CompanyMode:GetData()
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    local compNum = 0
    for roomIndex, v in pairs(compData or {}) do
        if not self:CheckRoomDailyMeetingComplete(roomIndex) then
            return false
        end
        compNum = compNum + 1
    end
    return compNum > 0 and true or false
end

function MeetingEventManager:CheckRoomDailyMeetingComplete(roomIndex)
    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
    if not roomId then
        return true
    end
    local roomGoData = FloorMode:GetScene():GetRoomRootGoData(roomId)
    if not roomGoData then
        return true
    end
    
    for k, person in pairs(roomGoData.employee or {}) do
        if person:CheckDailyMeetingValid() then
            return false
        end
    end
    return true
end