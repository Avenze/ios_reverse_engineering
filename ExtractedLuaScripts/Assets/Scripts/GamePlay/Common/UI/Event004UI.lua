

local Event004UI = GameTableDefine.Event004UI
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local ActorEventManger = GameTableDefine.ActorEventManger
local CfgMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local UIView = require("GamePlay.Common.UI.Event004UIView")
local EventManager = require("Framework.Event.Manager")


function Event004UI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EVENT004_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function Event004UI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EVENT004_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function Event004UI:ShowPanel(eventId)
    self:GetView():Invoke("ShowPanel",eventId, self:GetReward(eventId))
end

function Event004UI:GetReward(eventId)
    local cfg = CfgMgr.config_event[eventId] or CfgMgr.config_event[2]
    local num = 0
    if type(cfg.event_reward[2]) == "function" then
        num = cfg.event_reward[2](FloorMode:GetTotalRent())
    else
        num = cfg.event_reward[2]
    end
    
    return num
end

function Event004UI:SkipAd()
    self.noAd = true
end

function Event004UI:ClaimResource(eventId, isClaim, cb, onSuccess, onFail)
    local cfg = CfgMgr.config_event[eventId] or CfgMgr.config_event[2]

    if not isClaim then
        ActorEventManger:FinishEvent(cfg)
        -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10009})
    else

        local callback = function()
            local cfg = cfg or CfgMgr.config_event[2]--有些就会cfg为空,不知道为什么
            ResMgr:Add(cfg.event_reward[1], self:GetReward(eventId), nil, function(success)
                if success then
                    ActorEventManger:FinishEvent(cfg)
                    if cb then cb() end
                    if cfg.event_reward[1] == 3 then
                        local reward = self:GetReward(eventId)
                        -- GameSDKs:Track("get_diamond", {get = reward, left = ResMgr:GetDiamond(), get_way = "钻石土豪"})
                        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石土豪", behaviour = 1, num_new = tonumber(reward)})
                    end
                    --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10003, name = GameSDKs:GetAdName(10003), current_money = GameTableDefine.ResourceManger:GetCash()})
                end
            end, true)
        end
        GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10009)
    end
end