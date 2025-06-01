

local Event003UI = GameTableDefine.Event003UI
local GameUIManager = GameTableDefine.GameUIManager
local ActorEventManger = GameTableDefine.ActorEventManger
local GameClockManager = GameTableDefine.GameClockManager

function Event003UI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.EVENT003_UI, self.m_view, require("GamePlay.Common.UI.Event003UIView"), self, self.CloseView)
    return self.m_view
end

function Event003UI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.EVENT003_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function Event003UI:ShowPanel()
    self:GetView():Invoke("ShowPanel")
end


function Event003UI:ClaimResource(isClaim, cb, onSuccess, onFail)
    if not isClaim then
        ActorEventManger:FinishEvent({id = 100})
        -- GameSDKs:Track("reject_video", {ad_type = "激励视频", video_id = 10006})
    else
        local callback = function()
            GameClockManager:skipTheNightAway()
            ActorEventManger:BatmanCastSpell()
            --MainUI:PlaySkipNight()
            if cb then cb() end
            --GameSDKs:Track("end_video", {ad_type = "奖励视频", video_id = 10006, name = GameSDKs:GetAdName(10006), current_money = GameTableDefine.ResourceManger:GetCash()})
        end
        --GameSDKs:Track("play_video", {video_id = 10005})
        GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10006)
    end
end