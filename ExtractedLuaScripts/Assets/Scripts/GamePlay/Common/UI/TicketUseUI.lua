

local TicketUseUI = GameTableDefine.TicketUseUI
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local CfgMgr = GameTableDefine.ConfigMgr
local UIView = require("GamePlay.Common.UI.TicketUseUIView")
local EventManager = require("Framework.Event.Manager")

function TicketUseUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.TICKET_USE_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function TicketUseUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.TICKET_USE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function TicketUseUI:CheckSkipAd(handler, ad_id)
    if ResMgr:CheckTicket(1) then
        self.adHandler = handler
        self.id = ad_id
        TicketUseUI:ShowUseTicketPanel()
        return true
    end
    return false
end

function TicketUseUI:ShowUseTicketPanel()
    local ticketNum = ResMgr:GetTicket()
    self:GetView():Invoke("SetTicketInfo", ticketNum)
end

function TicketUseUI:UseTicket()
    if not self.adHandler then
        return
    end

    ResMgr:SpendTicket(1, ResMgr.EVENT_USE_TICKET, function(success)
        if success then 
            self.adHandler()
            self.adHandler = nil
            -- GameSDKs:Track("end_video", {ad_type = "激励视频", ad_result = "跳过", video_id = self.id, name = GameSDKs:GetAdName(self.id), current_money = GameTableDefine.ResourceManger:GetCash()})
        end
    end)
end