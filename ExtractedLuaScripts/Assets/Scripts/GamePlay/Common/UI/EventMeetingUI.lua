

local EventMeetingUI = GameTableDefine.EventMeetingUI
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local MeetingEventManager = GameTableDefine.MeetingEventManager
local CfgMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local UIView = require("GamePlay.Common.UI.EventMeetingUIView")
local EventManager = require("Framework.Event.Manager")
local CompanyEmployee = require "CodeRefactoring.Actor.Actors.CompanyEmployeeNew"
local ActorManager = require("CodeRefactoring.Actor.ActorManager")
local InteractionsManager = require "CodeRefactoring.Interactions.InteractionsManager"
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")

function EventMeetingUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EVENT_MEETING_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function EventMeetingUI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EVENT_MEETING_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function EventMeetingUI:DestroyModeUIObject()
    if self.m_view then
        self:GetView():Invoke("DestroyModeUIObject")
    end
end

function EventMeetingUI:ShowPanel()
    local meeting = InteractionsManager:GetEntities(ActorDefine.Flag.FLAG_EMPLOYEE_ON_MEETING)
    if not meeting then
        return
    end
   
    local personNum = 0
    local office = FloorMode:GetRoomLocalData("Office_1") or {}
    for k,v in pairs(office.furnitures or {}) do
        -- TODO：会议室，现在1号地区是10001，2号地区是11001，以后需要改成动态的比较好
        if v.id == 10001 or v.id == 11001 then
            personNum = personNum + 1
        end
    end

    local maxExp = 0
    for k,v in pairs(meeting or {}) do
        local _,pos = next(v:GetPosition())
        if pos and pos.localData then
            local expNum = {}
            CompanyEmployee:SetPersonBonuses(expNum, {"addexp"}, pos.localData)
            local exp = (expNum.addexp or 0) * personNum
            if exp > maxExp then
                maxExp = exp
            end
        end
    end
    if maxExp == 0 then
        return
    end
    self:GetView():Invoke("ShowPanel", maxExp)
end

function EventMeetingUI:FinishEvent(isClaim, cb, onSuccess, onFail)
    local cfg = CfgMgr.config_event[1]

    if not isClaim then
        MeetingEventManager:FinishEvent()
        -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10008})
        if cb then cb() end
        return
    end
    local callback = function()
        MeetingEventManager:FinishEvent()
        if cb then cb() end
        ActorManager:ResetEmployeeDailyMeeting()
        --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10008, name = GameSDKs:GetAdName(10008), current_money = GameTableDefine.ResourceManger:GetCash()})
    end
    --GameSDKs:Track("play_video", {video_id = 10005})
    GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10008)
end