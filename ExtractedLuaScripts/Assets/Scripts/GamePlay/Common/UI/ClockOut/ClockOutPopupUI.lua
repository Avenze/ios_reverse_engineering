--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-04-02 10:45:06
]]

---@class ClockOutPopupUI
local ClockOutPopupUI = GameTableDefine.ClockOutPopupUI
local GameUIManager = GameTableDefine.GameUIManager
local ClockOutDataManager = GameTableDefine.ClockOutDataManager
local GameLanucher = GameTableDefine.GameLanucher
local GameTimeManager = GameTimeManager
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local UIPopManager = GameTableDefine.UIPopupManager

function ClockOutPopupUI:GetView()
    local viewClass = require("GamePlay.Common.UI.ClockOut.ClockOutPopupUIView")

    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CLOCK_OUT_POPUP_UI, self.m_view, viewClass, self, self.CloseView)
    return self.m_view
end

function ClockOutPopupUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CLOCK_OUT_POPUP_UI)
    self.m_view = nil
    collectgarbage("collect")
    GameTableDefine.UIPopupManager:DequeuePopView(GameTableDefine.ClockOutPopupUI)
end

function ClockOutPopupUI:OpenView()
    if not ClockOutDataManager:GetActivityIsOpen() then
        UIPopManager:DequeuePopView(self)
        return
    end
    self:GetView():Invoke("Init")
    ClockOutDataManager:SetEnterDay()
end

function ClockOutPopupUI:CheckCanOpen()
    if not ClockOutDataManager:GetActivityIsOpen() then
        return false
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return false
    end

    if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CLOCK_OUT_UI) then
        return false
    end
    local now = GameTimeManager:GetCurrentServerTime(true)
    local enterDay = ClockOutDataManager:GetEnterDay()
    if enterDay then
        return false
    end
    
    return true
end

return ClockOutPopupUI