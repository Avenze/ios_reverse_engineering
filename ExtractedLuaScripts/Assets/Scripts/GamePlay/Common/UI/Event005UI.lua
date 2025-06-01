

local Event005UI = GameTableDefine.Event005UI
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local ActorEventManger = GameTableDefine.ActorEventManger
local CfgMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local UIView = require("GamePlay.Common.UI.Event005UIView")
local EventManager = require("Framework.Event.Manager")


function Event005UI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EVENT005_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function Event005UI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EVENT005_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function Event005UI:ShowPanel()
    self:GetView():Invoke("ShowPanel",FloorMode:GetTotalRent(), self:GetReward())
end

function Event005UI:GetReward()
    local cfg = CfgMgr.config_event[3]
    local num = 0
    if type(cfg.event_reward[2]) == "function" then
        num = cfg.event_reward[2](FloorMode:GetTotalRent())
    else
        num = cfg.event_reward[2]
    end
    
    return num
end

function Event005UI:ClaimResource(cb, onSuccess, onFail)
    local cfg = CfgMgr.config_event[3]

        local save = LocalDataManager:GetDataByKey("event_save")
        if not save["event"..cfg.id] then
            save["event"..cfg.id] = 0
        end
        save["event"..cfg.id] = save["event"..cfg.id] + 1

        ResMgr:Add(cfg.event_reward[1], self:GetReward(), nil, function(success)
            if success then
                ActorEventManger:FinishEvent(cfg)
                if cb then cb() end
            end
        end, true)
end