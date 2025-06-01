--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-05-23 15:13:41
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local UnityHelper = CS.Common.Utils.UnityHelper
local FAQUI = GameTableDefine.FAQUI
local ConfigMgr = GameTableDefine.ConfigMgr

local FAQUIView = Class("FAQUIView", UIView)

function FAQUIView:ctor()
    self.super:ctor()
    self.m_categoryData = {}
    self.m_curFAQData = {}
    self.m_categoryDataSize = {}
    self.m_curFAQDataSize = {}
end

function FAQUIView:OnEnter()
    self.m_curSelCategoryIndex = 0   --当前选择的问题类型的index
    self.m_curFAQIndex = 0           --选择当前类型问题具体问题的Index
    self.m_categoryData = {}
    self.m_curFAQData = {}
    self.m_categoryDataSize = {}
    self.m_curFAQDataSize = {}
    self:SetButtonClickHandler(self:GetComp("RootPanel/up/QuitBtn", "Button"), function()
        if self.m_curSelCategoryIndex == 0 and self.m_curFAQIndex == 0 then
            self:DestroyModeUIObject()
        elseif 0 == self.m_curFAQIndex and 0~= self.m_curSelCategoryIndex then
            --这时是返回到主界面的方法了
            self:ShowFAQMainPage()
        elseif 0 ~= self.m_curFAQIndex and 0~= self.m_curSelCategoryIndex then
            --这时是返回到对应的问题类型界面
            self:ShowSelCategoryPage(self.m_curSelCategoryIndex)
        end
    end)
    self.m_categoryGo = self:GetGoOrNil("RootPanel/categoryList")
    self.m_categoryList = self:GetComp("RootPanel/categoryList", "ScrollRectEx")
    self.m_questionGo = self:GetGoOrNil("RootPanel/questionPanel")
    self.m_questionList = self:GetComp("RootPanel/questionPanel", "ScrollRectEx")
    self.m_DetailContentGo = self:GetGoOrNil("RootPanel/answerPanel")
    for i = 1, 4 do
        local tmpData = {}
        tmpData.title = "TXT_FAQ_TYPE_"..i
        tmpData.icon = "icon_faq_type_"..i
        table.insert(self.m_categoryData, tmpData)
    end
    self:ShowFAQMainPage()
end

function FAQUIView:ShowFAQMainPage()
    self.m_curFAQIndex = 0
    self.m_curSelCategoryIndex = 0
    if self.m_categoryGo then
        self.m_categoryGo:SetActive(true)
    end
    if self.m_questionGo then
        self.m_questionGo:SetActive(false)
    end
    if self.m_DetailContentGo then
        self.m_DetailContentGo:SetActive(false)
    end
    self:SetText("RootPanel/up/title", GameTextLoader:ReadText("TXT_FAQ_TITLE"))
    self:SetListItemCountFunc(self.m_categoryList, function()
        return #self.m_categoryData
    end)

    -- self:SetListItemSizeFunc(self.m_categoryList, function(index)
    --     if self.m_categoryDataSize[index + 1] then
    --         return self.m_categoryDataSize[index + 1]
    --     end
    --     local data = self.m_categoryData[index + 1]
    --     if not data then
    --         return
    --     end
    --     local template = self.m_categoryList:GetItemTemplate("temp")
    --     local rootTrt = template:GetComponent("RectTransform")
    --     local trt = self:GetComp(template, "name", "RectTransform")
    --     local originSize = rootTrt.rect
    --     local gridLayoutGroupEx = self:GetComp(template, "name", "GridLayoutGroupEx")
    --     if gridLayoutGroupEx and not gridLayoutGroupEx:IsNull() then
    --         local gridSize = gridLayoutGroupEx:GetSize(1, 1)
    --         self.m_categoryDataSize[index + 1] = {x = originSize.width, y = (gridSize.y - trt.anchoredPosition.y) + 20}
    --     else
    --         local saleSize = trt.rect
    --         if saleSize.height > 0 then
    --             self.m_categoryDataSize[index + 1] = {x = originSize.width, y = saleSize.height - trt.anchoredPosition.y + 20}
    --         else
    --             self.m_categoryDataSize[index + 1] = {x = originSize.width, y = originSize.height + 20}
    --         end
    --     end
    --     return self.m_categoryDataSize[index + 1]
    -- end)

    self:SetListUpdateFunc(self.m_categoryList, handler(self, self.UpdateCategoryListItem))
    self.m_categoryList:UpdateData()
end

function FAQUIView:UpdateCategoryListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local curData = self.m_categoryData[index]
    if curData then
        self:SetSprite(self:GetComp(go, "icon", "Image"), "UI_Common", curData.icon)
        self:SetText(go, "name", GameTextLoader:ReadText(curData.title))
        self:SetButtonClickHandler(self:GetComp(go, "", "Button"), function()
            self:ShowSelCategoryPage(index)
        end)
    end
end

function FAQUIView:UpdateQuestionListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local curData = self.m_curFAQData[index]
    if curData then
        self:SetText(go, "name", GameTextLoader:ReadText(curData))
        self:SetButtonClickHandler(self:GetComp(go, "", "Button"), function()
            self:ShowSelFAQContent(index)
        end)
    end
end

function FAQUIView:ShowSelCategoryPage(categoryIndex)
    if categoryIndex < 1 or  categoryIndex > 4 then
        return
    end
    local categorCfg = ConfigMgr.config_faq[categoryIndex]
    if not categorCfg then
        return
    end
    if self.m_categoryGo then
        self.m_categoryGo:SetActive(false)
    end
    if self.m_questionGo then
        self.m_questionGo:SetActive(true)
    end
    if self.m_DetailContentGo then
        self.m_DetailContentGo:SetActive(false)
    end
    self.m_curSelCategoryIndex = categoryIndex
    self.m_curFAQIndex = 0
    --设置标题
    self:SetText("RootPanel/up/title", GameTextLoader:ReadText("TXT_FAQ_TYPE_"..categoryIndex))
    self.m_curFAQData = {}
    self.m_curFAQDataSize = {}
    for k, v in ipairs(categorCfg) do
        table.insert(self.m_curFAQData, v.question_txt)
    end
    self:SetListItemCountFunc(self.m_questionList, function()
        return #self.m_curFAQData
    end)

    -- self:SetListItemSizeFunc(self.m_questionList, function(index)
    --     if self.m_curFAQDataSize[index + 1] then
    --         return self.m_curFAQDataSize[index + 1]
    --     end
    --     local data = self.m_curFAQData[index + 1]
    --     if not data then
    --         return
    --     end
    --     local template = self.m_questionList:GetItemTemplate("temp")
    --     local rootTrt = template:GetComponent("RectTransform")
    --     local trt = self:GetComp(template, "name", "RectTransform")
    --     local originSize = rootTrt.rect
    --     local gridLayoutGroupEx = self:GetComp(template, "name", "GridLayoutGroupEx")
    --     if gridLayoutGroupEx and not gridLayoutGroupEx:IsNull() then
    --         local gridSize = gridLayoutGroupEx:GetSize(1, 1)
    --         self.m_curFAQDataSize[index + 1] = {x = originSize.width, y = (gridSize.y - trt.anchoredPosition.y) + 20}
    --     else
    --         local saleSize = trt.rect
    --         if saleSize.height > 0 then
    --             self.m_curFAQDataSize[index + 1] = {x = originSize.width, y = saleSize.height - trt.anchoredPosition.y + 20}
    --         else
    --             self.m_curFAQDataSize[index + 1] = {x = originSize.width, y = originSize.height + 20}
    --         end
    --     end
    --     return self.m_curFAQDataSize[index + 1]
    -- end)

    self:SetListUpdateFunc(self.m_questionList, handler(self, self.UpdateQuestionListItem))
    self.m_questionList:UpdateData()
end

function FAQUIView:ShowSelFAQContent(questIndex)
    if not self.m_curSelCategoryIndex or  self.m_curSelCategoryIndex == 0 then
        return
    end

    if self.m_categoryGo then
        self.m_categoryGo:SetActive(false)
    end
    if self.m_questionGo then
        self.m_questionGo:SetActive(false)
    end
    if self.m_DetailContentGo then
        self.m_DetailContentGo:SetActive(true)
    end
    self.m_curFAQIndex = questIndex
    local questCfg = ConfigMgr.config_faq[self.m_curSelCategoryIndex]
    if not questCfg or not questCfg[self.m_curFAQIndex] then
        return
    end
    self:SetText(self.m_DetailContentGo, "Viewport/Content/temp/q", GameTextLoader:ReadText(questCfg[self.m_curFAQIndex].question_txt))
    self:SetText(self.m_DetailContentGo, "Viewport/Content/temp/a", GameTextLoader:ReadText(questCfg[self.m_curFAQIndex].answer_txt))
end

function FAQUIView:OnExit()
    self.super:OnExit(self)
end

return FAQUIView