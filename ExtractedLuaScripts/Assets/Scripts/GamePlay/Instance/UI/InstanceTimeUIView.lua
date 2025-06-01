--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-21 18:23:24
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
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel

local InstanceTimeUIView = Class("InstanceTimeUIView", UIView)

function InstanceTimeUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function InstanceTimeUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:Init()
end

function InstanceTimeUIView:OnExit()
	self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
end

function InstanceTimeUIView:Init()
    self.timeRangeGO = {
        [1] = self:GetGo("RootPanel/bg/part/part_1"),
        [2] = self:GetGo("RootPanel/bg/part/part_2"),
        [3] = self:GetGo("RootPanel/bg/part/part_3"),
        [4] = self:GetGo("RootPanel/bg/part/part_4"),
        [5] = self:GetGo("RootPanel/bg/part/part_5"),
    } 
    self.timer = GameTimer:CreateNewTimer(0.5,function()
        self:Show()

    end,true,true)
end

function InstanceTimeUIView:Show()
    local currentTime = InstanceDataManager:GetCurInstanceTime()
    local timeArrange = InstanceDataManager.config_global.timeArrange
    local timeType = 0
    for i=1,#timeArrange do
        local timeType = timeArrange[i].timeType
        local range = timeArrange[i].range
        if currentTime.Hour >= range[1] and currentTime.Hour < range[2] then
            for k,v in pairs(self.timeRangeGO) do
                v:SetActive(k == i )
            end
            timeType = timeArrange[i].timeType
            break
        end
    end
    local isday = InstanceModel:IsDay()
    self:GetGo("RootPanel/center/day"):SetActive(isday)
    self:GetGo("RootPanel/center/night"):SetActive(isday == false)

    local hStr = currentTime.Hour
    if currentTime.Hour < 10 then
        hStr = "0" .. hStr
    end
    local mStr = currentTime.Min
    if currentTime.Min < 10 then
        mStr="0" .. mStr
    end
    if isday then
        self:SetText("RootPanel/center/day/time",hStr..":"..mStr)
    else
        self:SetText("RootPanel/center/night/time",hStr..":"..mStr)
    end
end


return InstanceTimeUIView