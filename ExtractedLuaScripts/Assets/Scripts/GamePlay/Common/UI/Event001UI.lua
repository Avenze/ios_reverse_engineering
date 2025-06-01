

local Event001UI = GameTableDefine.Event001UI
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local ActorEventManger = GameTableDefine.ActorEventManger
local CfgMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local UIView = require("GamePlay.Common.UI.Event001UIView")
local EventManager = require("Framework.Event.Manager")


function Event001UI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EVENT001_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function Event001UI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EVENT001_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function Event001UI:ShowPanel(eventId)
    local value,_ = self:GetReward(eventId)
    self:GetView():Invoke("ShowPanel", eventId, FloorMode:GetTotalRent(), value)
end

function Event001UI:GetReward(id)
    local cfg = CfgMgr.config_event[id or 1]
    local num = 0
    if type(cfg.event_reward[2]) == "function" then
        num = cfg.event_reward[2](FloorMode:GetTotalRent())
    else
        num = cfg.event_reward[2]
    end

    num = num + CfgMgr.config_global.event001_money--保底
    
    return num, cfg.event_reward[1]
end

function Event001UI:SkipAd()
    self.noAd = true
end

function Event001UI:ClaimResource(id, isClaim, cb, onSuccess, onFail)
    local cfg = CfgMgr.config_event[id or 1]

    if not isClaim then
        ActorEventManger:FinishEvent(cfg)
        -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10003})
    else
        local value, rewardType = self:GetReward(id)
        local fun =  rewardType == 2 and ResMgr.AddCash or ResMgr.AddEUR
        if self.noAd then
            self.noAd = false
            local save = LocalDataManager:GetDataByKey("event_save")
            if not save["event"..cfg.id] then
                save["event"..cfg.id] = 0
            end
            save["event"..cfg.id] = save["event"..cfg.id] + 1
            fun(ResMgr, value, ResMgr.EVENT_CLAIM_EVENT001, function()
                ActorEventManger:FinishEvent(cfg)
                if cb then cb() end
            end, true)
            return
        end

        local callback = function()
            local save = LocalDataManager:GetDataByKey("event_save")
            if not save["event"..cfg.id] then
                save["event"..cfg.id] = 0
            end
            save["event"..cfg.id] = save["event"..cfg.id] + 1
            fun(ResMgr, value, ResMgr.EVENT_CLAIM_EVENT001, function(success)
                if success then
                    --2024-8-20添加用于的钞票消耗增加埋点上传
                    local type = GameTableDefine.CountryMode:GetCurrCountry()
                    local amount = value
                    local change = 0
                    local position = "土豪广告"
                    GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
                    ActorEventManger:FinishEvent(cfg)
                    if cb then cb() end
                    --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10003, name = GameSDKs:GetAdName(10003), current_money = GameTableDefine.ResourceManger:GetCash()})
                end
            end, true)
        end
        --GameSDKs:Track("play_video", {video_id = 10003, current_money = GameTableDefine.ResourceManger:GetCash()})
        GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10003)
    end
end