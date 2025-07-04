---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by .
--- DateTime: 2024/12/24 17:01
---

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local SeasonPassManager = GameTableDefine.SeasonPassManager
local GameTimeManager = GameTimeManager
local GameTimer = GameTimer

---@class SeasonPassPopupUIView:UIBaseView
local SeasonPassPopupUIView = Class("SeasonPassPopupUIView", UIView)

function SeasonPassPopupUIView:ctor()

end

function SeasonPassPopupUIView:OnEnter()
    --退出按钮
    self.m_quitBtn = self:GetComp("BgCover","Button")
    self:SetButtonClickHandler(self.m_quitBtn,function()
        self:DestroyModeUIObject()
        GameTableDefine.UIPopupManager:DequeuePopView(GameTableDefine.SeasonPassPopupUI)
    end)
    --跳转按钮
    self.m_quitBtn = self:GetComp("RootPanel/btn","Button")
    self:SetButtonClickHandler(self.m_quitBtn,function()
        GameTableDefine.SeasonPassUI:OpenView(true)
        self:DestroyModeUIObject()
    end)

    --活动倒计时
    self.m_countDownText = self:GetComp(self.m_uiObj, "RootPanel/time/time_txt","TMPLocalization")
    self.m_updateTimer = GameTimer:CreateNewTimer(1,function()
        local leftTime = SeasonPassManager:GetActivityLeftTime()
        if leftTime > 86400 then
            local timeDate = GameTimeManager:GetTimeLengthDate(leftTime)
            self.m_countDownText.text = string.format("%dd %dh",timeDate.d,timeDate.h)
        else
            self.m_countDownText.text = GameTimeManager:FormatTimeLength(leftTime)
        end
    end,true,true)
end

function SeasonPassPopupUIView:Init()
end

function SeasonPassPopupUIView:OnExit(view)

    if self.m_updateTimer then
        GameTimer:StopTimer(self.m_updateTimer)
        self.m_updateTimer = nil
    end

    self.super:OnExit(self)
end

return SeasonPassPopupUIView