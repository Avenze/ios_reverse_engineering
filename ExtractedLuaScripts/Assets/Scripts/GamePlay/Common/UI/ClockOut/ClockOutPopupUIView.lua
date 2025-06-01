--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-04-02 10:45:20
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local ClockOutDataManager = GameTableDefine.ClockOutDataManager
local GameTimeManager = GameTimeManager
local GameTimer = GameTimer

---@class ClockOutPopupUIView:UIBaseView
local ClockOutPopupUIView = Class("ClockOutPopupUIView", UIView)

function ClockOutPopupUIView:ctor()
end

function ClockOutPopupUIView:OnEnter()
    local rootGoTran = self:GetGo("").transform
    -- local rootGo = self:GetGo("")
    local curTheme = ClockOutDataManager:GetActivityTheme()
    self.curRootGo = self:GetGoOrNil(curTheme)
    for i = 0, rootGoTran.childCount - 1 do
        rootGoTran:GetChild(i).gameObject:SetActive(false)
    end
    if not self.curRootGo then
        return
    end
    self.curRootGo:SetActive(true)
    self:SetButtonClickHandler(self:GetComp(self.curRootGo, "main/btnPivot/confirmBtn", "Button"), function()
        --要做一个动画去做跳转
        self:DestroyModeUIObject()
        GameTableDefine.FlyIconsUI:ShowClockOutPopupUIAnim(nil)
        GameSDKs:TrackForeign("clockout_exposure", {type = "活动拍脸图弹窗确认"})
    end)

    if self.activityLeftTimer then
        GameTimer:StopTimer(self.activityLeftTimer)
        self.activityLeftTimer = nil
        
    end
    self.activityLeftTimer = GameTimer:CreateNewTimer(1, function()

        local leftTime  = GameTableDefine.ClockOutDataManager:GetActivityLeftTime()
        if leftTime <= 0 then
            if self.activityLeftTimer then
                GameTimer:StopTimer(self.activityLeftTimer)
                self.activityLeftTimer = nil
            end
            self:DestroyModeUIObject()
        else
            local timeStr = GameTimeManager:FormatTimeLength(leftTime)
            self:SetText(self.curRootGo, "main/block/timer/num", timeStr)
        end
    end, true, true)
end

function ClockOutPopupUIView:OnExit()
    self.super:OnExit(self)
end

function ClockOutPopupUIView:Init()
end

return ClockOutPopupUIView