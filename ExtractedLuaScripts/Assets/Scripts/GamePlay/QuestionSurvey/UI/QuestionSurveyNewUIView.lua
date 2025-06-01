--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 13:50:44
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local ULiteWebView = CS.Common.Utils.ULiteWebView.Ins
local UnityHelper = CS.Common.Utils.UnityHelper

---@type QuestionSurveyDataManager
local QuestionSurveyDataManager = GameTableDefine.QuestionSurveyDataManager

---@type QuestionSurveyNewUI
local QuestionSurveyNewUI = GameTableDefine.QuestionSurveyNewUI
local QuestionSurveyNewUIView = Class("QuestionSurveyNewUIView", UIView)

function QuestionSurveyNewUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function QuestionSurveyNewUIView:OnEnter()
    self.super:OnEnter()
    if not QuestionSurveyDataManager:GetQuestionIsOpen() then
        QuestionSurveyNewUI:CloseView()
        return
    end

    self.RootPanel = self:GetGo("RootPanel")
    self.mainPanel = self:GetGo("RootPanel/MainPanel")
    self.surveyPanel = self:GetGo("RootPanel/SurveyPanel")
    self.surveyCloseBtn = self:GetGo("RootPanel/SurveyPanel/topPanel/QuitBtn")
    self.stagePanel = self:GetGo("RootPanel/StagePanel")
    self.surveyAwardNum = self:GetComp("RootPanel/StagePanel/data/reward/num/num", "TMPLocalization")
    self.surveyCloseBtn:SetActive(false)

    local award = 0
    local mathcRuleIndex = GameTableDefine.QuestionSurveyDataManager:matchRule()
    local surveyConfig = GameTableDefine.ConfigMgr.config_survey_new[CS.UnityEngine.Application.version] or {}
    if mathcRuleIndex > 0 then
        local surveyConf = surveyConfig[mathcRuleIndex] or {}
        award = surveyConf and surveyConf.award or 0
    end
    self.surveyAwardNum.text = tostring(award)
    

    -- 引导页不给关闭
    --self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
    --    QuestionSurveyNewUI:CloseView()
    --end)

    -- 打开问卷页面
    self:SetButtonClickHandler(self:GetComp("RootPanel/MainPanel/Btn", "Button"), function()
        self:ShowSurvey()
    end)

    -- 关闭问卷页面，显示领奖页面
    self:SetButtonClickHandler(self:GetComp("RootPanel/SurveyPanel/topPanel/QuitBtn", "Button"), function()
        ULiteWebView:Close();
        QuestionSurveyDataManager:CloseSurvey()
        self:ShowAward()

        self.googleSurveyPageOpen = false
        print("关闭 google 问卷页...")
    end)

    -- 领取奖励，关闭页面
    self:SetButtonClickHandler(self:GetComp("RootPanel/StagePanel/Btn", "Button"), function()
        QuestionSurveyDataManager:AwardSurvey()
        QuestionSurveyNewUI:CloseView()

    end)
    
    self:RefreshPanelDisplay()

    local _self = self
    self.setUIToTopTimerId = GameTimer:CreateNewMilliSecTimer(200, function()
        UnityHelper.SetSurveyUIToTop(_self.RootPanel)
    end, true)
end

-- 显示 介绍页
function QuestionSurveyNewUIView:ShowIntro()
    self.mainPanel:SetActive(true)
    self.surveyPanel:SetActive(false)
    self.stagePanel:SetActive(false)
end

-- 显示 问卷页
function QuestionSurveyNewUIView:ShowSurvey()
    self.mainPanel:SetActive(false)
    self.surveyPanel:SetActive(true)
    self.stagePanel:SetActive(false)
    self.googleSurveyPageOpen = true
    print("显示 google 问卷页...")

    local surveyId, languageId, url = QuestionSurveyNewUI:LoadUrl() -- 加载 google form url
    if url ~= "" then
        local topPanelHeight = self:GetGo("RootPanel/SurveyPanel/topPanel").transform.rect.height
        topPanelHeight = math.floor(topPanelHeight or 150)

        print("显示 问卷页 (高):", surveyId, languageId, url, topPanelHeight)
        ULiteWebView:Show(topPanelHeight, 90, 0, 0);
        ULiteWebView:LoadUrl(url);

        local _self = self
        self.delayShowCloseBtnTimerId = GameTimer:CreateNewTimer(5, function()
            QuestionSurveyDataManager:ShowSurvey(surveyId, languageId, url)
            _self.surveyCloseBtn:SetActive(true)
        end)
    else
        QuestionSurveyNewUI:CloseView()
    end
end

-- 显示 奖励页
function QuestionSurveyNewUIView:ShowAward()    
    self.mainPanel:SetActive(false)
    self.surveyPanel:SetActive(false)
    self.stagePanel:SetActive(true)
end



--[[
    @desc: 刷新当前显示面板的提示
    author:{author}
    time:2023-03-30 15:14:40
    @return:
]]
function QuestionSurveyNewUIView:RefreshPanelDisplay()
    local showTimestamp = QuestionSurveyDataManager:GetShowSurveyTimestamp()
    if not showTimestamp or showTimestamp <= 0 then
        self:ShowIntro()

        return
    end

    local awardTimestamp = QuestionSurveyDataManager:GetAwardSurveyTimestamp()
    if not awardTimestamp or awardTimestamp <= 0 then
        self:ShowAward()
        return
    end

    QuestionSurveyNewUI:CloseView()
end

function QuestionSurveyNewUIView:OnExit()
    if self.delayShowCloseBtnTimerId then
        GameTimer:StopTimer(self.delayShowCloseBtnTimerId)
    end

    if self.setUIToTopTimerId then
        GameTimer:StopTimer(self.setUIToTopTimerId)
    end

    print("页面退出时...", self.googleSurveyPageOpen)
    if self.googleSurveyPageOpen then
        print("页面退出时，检查 google page是否关闭...")
        
        ULiteWebView:Close();
        QuestionSurveyDataManager:CloseSurvey()
    end
    self.super:OnExit(self)
end

return QuestionSurveyNewUIView