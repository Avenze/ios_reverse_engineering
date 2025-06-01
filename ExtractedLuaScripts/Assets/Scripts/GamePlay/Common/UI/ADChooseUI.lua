--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-10 17:42:37
]]

local ADChooseUI = GameTableDefine.ADChooseUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ResMgr = GameTableDefine.ResourceManger

function ADChooseUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.AD_TICKET_CHOOSE_UI, self.m_view, require("GamePlay.Common.UI.ADChooseUIView"), self, self.CloseView)
    return self.m_view
end

function ADChooseUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.AD_TICKET_CHOOSE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function ADChooseUI:CommonChoose(txt, cb, showCancel, canceCb, extendType, extendNum)--文本, 确定回调, 显示取消按钮, 取消回调, 额外显示的资源和数量，可以为nil
    local title = GameTextLoader:IsTextID(txt) and GameTextLoader:ReadText(txt) or txt
    --title = string.format(title, price)
    self:GetView():Invoke("CommonChoose", title, cb, showCancel, canceCb, nil, extendType, extendNum)
end