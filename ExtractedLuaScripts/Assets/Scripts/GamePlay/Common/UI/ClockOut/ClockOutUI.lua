--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-03-28 11:56:25
]]

---@class ClockOutUI

local ClockOutUI = GameTableDefine.ClockOutUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr  = GameTableDefine.ConfigMgr
local EventDispatcher = EventDispatcher
local UIPopManager = GameTableDefine.UIPopupManager

function ClockOutUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CLOCK_OUT_UI, self.m_view, require("GamePlay.Common.UI.ClockOut.ClockOutUIView"), self, self.CloseView)
    return self.m_view
end

function ClockOutUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CLOCK_OUT_UI)
    self.m_view = nil
    collectgarbage("collect")    
    --由Popup打开时，关闭界面弹出下一个Popup
    if self.m_openByPopupUI then
        UIPopManager:DequeuePopView(GameTableDefine.ClockOutPopupUI)
    end
end

function ClockOutUI:OpenView(isOpenPopupUI)
    self.m_openByPopupUI = isOpenPopupUI
    self:GetView():Invoke("OpenView")
end

function ClockOutUI:BuyClockOutIAPResult(shopId, success)
    self:GetView():Invoke("IPABuyResult")
end

function ClockOutUI:NextLevelBtnUnlock(level) 
    self:GetView():Invoke("NextLevelBtnUnlock", level)
end