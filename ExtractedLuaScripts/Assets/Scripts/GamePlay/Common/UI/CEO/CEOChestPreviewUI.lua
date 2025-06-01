--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-02-19 10:16:34
]]

---@class CEOChestPreviewUI
local CEOChestPreviewUI = GameTableDefine.CEOChestPreviewUI
local GameUIManager = GameTableDefine.GameUIManager

function CEOChestPreviewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CEO_CHEST_PREVIEW_UI, self.m_view, require("GamePlay.Common.UI.CEO.CEOChestPreviewUIView"), self, self.CloseView)
    return self.m_view
end

function CEOChestPreviewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CEO_CHEST_PREVIEW_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CEOChestPreviewUI:OpenChestPreview(boxType)
    self:GetView():Invoke("OpenChestPreview", boxType)
end
