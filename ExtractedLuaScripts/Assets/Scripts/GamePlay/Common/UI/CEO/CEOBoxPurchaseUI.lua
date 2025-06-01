--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-02-12 15:44:54
]]

---@class CEOBoxPurchaseUI
local CEOBoxPurchaseUI = GameTableDefine.CEOBoxPurchaseUI
local GameUIManager = GameTableDefine.GameUIManager
local CEODataManager = GameTableDefine.CEODataManager

function CEOBoxPurchaseUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CEO_PURCHASE_UI, self.m_view, require("GamePlay.Common.UI.CEO.CEOBoxPurchaseUIView"), self, self.CloseView)
    return self.m_view
end

function CEOBoxPurchaseUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CEO_PURCHASE_UI)
    self.m_view = nil
    collectgarbage("collect")

    --刷新列表
    GameTableDefine.PetListUI:RefreshCEOPanel()
    --判断是否应该弹出CEO引导
    if CEODataManager:GetGuideTriggered() and not CEODataManager:GetGuide2Triggered() then
        CEODataManager:SetGuide2Triggered()
        GameTableDefine.GuideManager.currStep = 2200
        GameTableDefine.GuideManager:ConditionToStart()
    end
end

function CEOBoxPurchaseUI:SuceessOpenCEOBox(boxType, rewards, extendData, cb)
    -- self:GetView():Invoke("SuceessOpenCEOBox", boxType, rewards, extendData, cb)
    self:GetView():Invoke("AddBoxDisplayInTurns", boxType, rewards, extendData, cb)
end

return CEOBoxPurchaseUI