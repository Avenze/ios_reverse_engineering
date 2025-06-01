--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-22 16:15:52
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local InstanceDataManager = GameTableDefine.InstanceDataManager
local InstanceModel = GameTableDefine.InstanceModel
local ConfigMgr = GameTableDefine.ConfigMgr
local FloatUI = GameTableDefine.FloatUI

local InstanceUnlockUIView = Class("InstanceUnlockUIView", UIView)

function InstanceUnlockUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function InstanceUnlockUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function InstanceUnlockUIView:OnExit()
	self.super:OnExit(self)
end

function InstanceUnlockUIView:InitView(id)
    local roomData = InstanceDataManager:GetCurRoomData(id)
    local roomConfig = InstanceModel:GetRoomConfigByID(id)

    self:SetImageSprite("RootPanel/MidPanel/icon",roomConfig.icon,nil)
    self:SetText("RootPanel/MidPanel/info/name",GameTextLoader:ReadText(roomConfig.name))
    self:SetText("RootPanel/MidPanel/info/desc",GameTextLoader:ReadText(roomConfig.desc))
    -- self.timer = GameTimer:CreateNewTimer(1,function()

    -- end,true,true)
    local timeStr = GameTimeManager:FormatTimeLength(roomConfig.unlock_times,false)
    self:SetText("RootPanel/MidPanel/requirement/time/num",timeStr)
    self:SetText("RootPanel/MidPanel/requirement/cash/num",Tools:SeparateNumberWithComma(roomConfig.unlock_require))
    
    local button = self:GetComp("RootPanel/SelectPanel/bulidBtn","Button")
    if InstanceModel:CheckRoomCondition(id) then
        button.interactable = true
    else
        button.interactable = false
    end

    self:SetButtonClickHandler(button,function()
        InstanceModel:BuyRoom(id)
        self:DestroyModeUIObject()
    end)

end


return InstanceUnlockUIView