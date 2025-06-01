local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local GameUIManager = GameTableDefine.GameUIManager
local TicketUseUI = GameTableDefine.TicketUseUI

local TicketUseUIView = Class("TicketUseUIView", UIView)


function TicketUseUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function TicketUseUIView:OnEnter()
    print("TicketUseUIView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("RootPanel/SelectPanel/ConfirmBtn", "Button"), function()
        self:DestroyModeUIObject()
        TicketUseUI:UseTicket()
    end)
end

function TicketUseUIView:OnPause()
    print("TicketUseUIView:OnPause")
end

function TicketUseUIView:OnResume()
    print("TicketUseUIView:OnResume")
end

function TicketUseUIView:OnExit()
    self.super:OnExit(self)
    print("TicketUseUIView:OnExit")
end

function TicketUseUIView:SetTicketInfo(ticketNum)
    self:SetText("RootPanel/MidPanel/tickets/num", "×".. ticketNum)
end

return TicketUseUIView