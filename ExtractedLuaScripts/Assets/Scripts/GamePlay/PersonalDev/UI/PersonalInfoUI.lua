--[[
    个人发展个人信息UIController
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-23 14:56:37
]]

local PersonalInfoUI = GameTableDefine.PersonalInfoUI
local GameUIManager = GameTableDefine.GameUIManager
local GameResMgr = require("GameUtils.GameResManager")
local FlyIconsUI = GameTableDefine.FlyIconsUI

function PersonalInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PERSONAL_INFO_UI, self.m_view, require("GamePlay.PersonalDev.UI.PersonalInfoUIView"), self, self.CloseView)

    return self.m_view
end

function PersonalInfoUI:OpenPersonalInfoUI()
    FlyIconsUI:SetScenceSwitchEffect(1, function()
        if self:GetView() then
            self.m_view:Invoke("OpenPersonalInfoUI")
        else
            FlyIconsUI:SetScenceSwitchEffect(-1)
        end
    end)
    
end

function PersonalInfoUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PERSONAL_INFO_UI)

    self.m_view = nil
    collectgarbage("collect")
end