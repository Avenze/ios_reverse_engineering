--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2025-02-19 10:16:53
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local ConfigMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager

---@class CEOChestPreviewUIView 
local CEOChestPreviewUIView = Class("CEOChestPreviewUIView ", UIView)

function CEOChestPreviewUIView:ctor()
    self.m_data = {}
end

function CEOChestPreviewUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self.m_list = self:GetComp("RootPanel/info/list", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return Tools:GetTableSize(self.m_data)
    end)
    self:SetListItemNameFunc(self.m_list, function(index)
        return "item"
    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateItem))
end

function CEOChestPreviewUIView:OnExit()
    self.super:OnExit(self)
end

function CEOChestPreviewUIView:OpenChestPreview(boxType)
    local id = 0
    if "normal" == boxType then
        id = 1
    elseif "premium" == boxType then
        id = 2
    end
    local cardCfg = ConfigMgr.config_ceo_card[id]
    local realCeoIDs = {}
    self.m_data = {}
    if cardCfg then
        local cfgCeoIDS = Tools:SplitString(cardCfg.card_content, ",", true)
        for _, ceoid in pairs(cfgCeoIDS) do
            local ceoStatus = GameTableDefine.CEODataManager:GetCEOCharStatusByCEOID(ceoid)
            if ceoStatus == 1 or ceoStatus == 2 then
                table.insert(realCeoIDs, ceoid)
            end
        end
        if Tools:GetTableSize(realCeoIDs) > 0 then
            local percent = tonumber(string.format("%."..tostring(4).."f", 1/Tools:GetTableSize(realCeoIDs))) * 100
            for _, realId in pairs(realCeoIDs) do
                local ceoCfg = ConfigMgr.config_ceo[realId]
                if ceoCfg then
                    local dispItem = {}
                    dispItem.icon = ceoCfg.ceo_card
                    dispItem.name = GameTextLoader:ReadText(ceoCfg.ceo_name)
                    dispItem.percent = tostring(percent).."%"
                    table.insert(self.m_data, dispItem)
                end
            end
            self.m_list:UpdateData()
        end
    end
end

function CEOChestPreviewUIView:UpdateItem(i, tran)
    local index = i + 1
    local data = self.m_data[index]
    local go = tran.gameObject
    self:SetSprite(self:GetComp(go, "bg/card", "Image"), "UI_Common", data.icon)
    self:SetText(go, "bg/name", data.name)
    self:SetText(go, "bg/proba/num", data.percent)
end
return CEOChestPreviewUIView