--UIView
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local UI = GameTableDefine.FCLeagueUpUI

local FCLeagueUpUIView = Class("FCLeagueUpUIView", UIView)

function FCLeagueUpUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCLeagueUpUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/btn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:InitView()
end

function FCLeagueUpUIView:OnExit()
	self.super:OnExit(self)
end

function FCLeagueUpUIView:InitView()
    local model = UI:GetUIModel()
    --队伍logo
    self:SetImageSprite("RootPanel/title/bg",model.teamCfg.iconBG)
    self:SetImageSprite("RootPanel/title/bg/Image",model.teamCfg.icon)
    --奖杯icon
    self:SetImageSprite("RootPanel/icon/icon",model.curLeagueCfg.icon)
    --当前奖池
    self:SetText("RootPanel/info_area/rewards/num",Tools:SeparateNumberWithComma(model.curLeagueCfg.pool))
    --建筑等级上限
    self:SetText("RootPanel/info_area/building/num/num1",model.lastleagueCfg.limit)
    self:SetText("RootPanel/info_area/building/num/num2",model.curLeagueCfg.limit)
    --门票价格加成
    self:SetText("RootPanel/info_area/ticket/num/num",model.curLeagueCfg.ticket)

end

return FCLeagueUpUIView
