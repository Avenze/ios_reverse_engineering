--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 13:50:44
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local Application = CS.UnityEngine.Application
local GameObject = CS.UnityEngine.GameObject

local ValueManager = GameTableDefine.ValueManager
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local QuestionSurveyDataManager = GameTableDefine.QuestionSurveyDataManager
local QuestionSurveyUI = GameTableDefine.QuestionSurveyUI
local QuestionSurveyUIView = Class("QuestionSurveyUIView", UIView)

function QuestionSurveyUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function QuestionSurveyUIView:OnEnter()
    self.super:OnEnter()
    if not QuestionSurveyDataManager:GetQuestionIsOpen() then
        QuestionSurveyUI:CloseView()
        return
    end
    self.currQuestionID = QuestionSurveyDataManager:GetCurQuestionID()
    if self.currQuestionID <= 0 then
        QuestionSurveyUI:CloseView()
        return
    end
    self.curCfg = ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch][self.currQuestionID]
    if not self.curCfg then
        QuestionSurveyUI:CloseView()
        return
    end
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        QuestionSurveyUI:CloseView()
    end)

    self:InitPanelButton()
    self:RefreshPanelDisplay(self.currQuestionID)
end

--[[
    @desc: 
    author:{author}
    time:2023-03-30 14:28:49
    @return:返回当前显示的Panel，其他的需要关闭显示
]]
function QuestionSurveyUIView:GetCurPanelGo()
    if not self.curCfg then
        return nil
    end

    --单选1，多选2, 3公告型，如提示通告，4-可以选择中断答题的通告型，5-结束通告型
    self:GetGo("RootPanel/MainPanel"):SetActive(self.curCfg.type == 3)
    self:GetGo("RootPanel/SubjectPanel"):SetActive(self.curCfg.type == 1 or self.curCfg.type == 2)
    self:GetGo("RootPanel/RewardPanel"):SetActive(self.curCfg.type == 4)
    self:GetGo("RootPanel/StagePanel"):SetActive(self.curCfg.type == 5)
    if self.curCfg.type == 3 then
        return self:GetGo("RootPanel/MainPanel")
    end

    if self.curCfg.type == 1 or self.curCfg.type == 2 then
        return self:GetGo("RootPanel/SubjectPanel")
    end
    
    if self.curCfg.type == 4 then
        return self:GetGo("RootPanel/RewardPanel")
    end

    if self.curCfg.type == 5 then
        return self:GetGo("RootPanel/StagePanel")
    end

    return nil
end

--[[
    @desc: 刷新当前显示面板的提示
    author:{author}
    time:2023-03-30 15:14:40
    @return:
]]
function QuestionSurveyUIView:RefreshPanelDisplay(questionID)
    self.curCfg = ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch][self.currQuestionID] 
    if not self.curCfg then
        QuestionSurveyUI:CloseView()
        return
    end
    self.curAnswerIds = {}
    self.curPanelGo = self:GetCurPanelGo()
    --单选1，多选2, 3公告型，如提示通告，4-可以选择中断答题的通告型，5-结束通告型
    -- self:GetGo("RootPanel/MainPanel"):SetActive(self.curCfg.type == 3)
    -- self:GetGo("RootPanel/SubjectPanel"):SetActive(self.curCfg.type == 1 or self.curCfg.type == 2)
    -- self:GetGo("RootPanel/RewardPanel"):SetActive(self.curCfg.type == 4)
    -- self:GetGo("RootPanel/StagePanel"):SetActive(self.curCfg.type == 5)
    if self.curCfg.type == 3 or self.curCfg.type==4 or self.curCfg.type == 5 then
        self:SetText(self.curPanelGo, "data/title/txt", GameTextLoader:ReadText(self.curCfg.question_txt))
        self:SetText(self.curPanelGo, "data/Viewport/Content/desc", GameTextLoader:ReadText(self.curCfg.opion_txt))
        return
    end
    self.m_data = {}
    --这里就是设置答题的相关初始化和内容了
    for i = 1, self.curCfg.opion do 
        local itemData = {}
        itemData.index = i
        itemData.quetionDesc = string.gsub(self.curCfg.opion_txt, "NUM", tostring(i))
        itemData.type = self.curCfg.type
        itemData.isSelect = false
        -- if i == 1 and self.curCfg.type == 1 then
        --     itemData.isSelect = true
        -- end
        table.insert(self.m_data, itemData)
    end
    self:GetGo("RootPanel/SubjectPanel/data_1"):SetActive(self.curCfg.type == 1)
    self:GetGo("RootPanel/SubjectPanel/data_2"):SetActive(self.curCfg.type == 2)
    self.curListGo = nil
    if self.curCfg.type == 1 then
        self.curListGo = self:GetGoOrNil("RootPanel/SubjectPanel/data_1")
    end
    if self.curCfg.type == 2 then
        self.curListGo = self:GetGoOrNil("RootPanel/SubjectPanel/data_2")
    end

    if not self.curListGo then
        QuestionSurveyUI:CloseView()
        return
    end
    local curNum, maxNum = QuestionSurveyDataManager:GetCurQuestionPro(self.currQuestionID)
    if maxNum ~= 0 then
        local pro = curNum / maxNum
        self:SetText(self.curListGo, "prog/num/num_1", curNum)
        self:SetText(self.curListGo, "prog/num/num_2", maxNum)
        local slider = self:GetComp(self.curListGo, "prog/Slider","Slider")
        slider.value = pro
        self:GetGo(self.curListGo, "prog"):SetActive(true)
    else
        self:GetGo(self.curListGo, "prog"):SetActive(false)
    end
    -- self:UpdateQuetionTips(false)
    local TipsGO = self:GetGoOrNil(self.curListGo, "Tips")
    if  TipsGO then
        TipsGO:SetActive(false)
    end
    self:SetText(self.curListGo, "ScrollRectEx/Viewport/Content/txt", GameTextLoader:ReadText(self.curCfg.question_txt))
    self.mList = self:GetComp(self.curListGo, "Scroll", "ScrollRectEx")
    self.mTitleList = self:GetComp(self.curListGo, "ScrollRectEx", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.m_data
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
    self.mList:UpdateData()
    self.mList:ScrollToTop(99)
    if self.mTitleList then
        self.mTitleList:ScrollToTop(99)
    end
end

--[[
    @desc: 初始化当前各个面板的按钮点击回调
    author:{author}
    time:2023-03-30 15:14:54
    @return:
]]
function QuestionSurveyUIView:InitPanelButton()
    --单选1，多选2, 3公告型，如提示通告，4-可以选择中断答题的通告型，5-结束通告型
    -- self:GetGo("RootPanel/MainPanel"):SetActive(self.curCfg.type == 3)
    -- self:GetGo("RootPanel/SubjectPanel"):SetActive(self.curCfg.type == 1 or self.curCfg.type == 2)
    -- self:GetGo("RootPanel/RewardPanel"):SetActive(self.curCfg.type == 4)
    -- self:GetGo("RootPanel/StagePanel"):SetActive(self.curCfg.type == 5)
    self:SetButtonClickHandler(self:GetComp("RootPanel/MainPanel/Btn", "Button"), function()
        self:SubmitCurQuestion()
    end
    )

    self:SetButtonClickHandler(self:GetComp("RootPanel/SubjectPanel/Btn", "Button"), function()
        self:SubmitCurQuestion()
    end
    )

    self:SetButtonClickHandler(self:GetComp("RootPanel/StagePanel/Btn", "Button"), function()
        self:SubmitCurQuestion()
    end
    )
    self:SetButtonClickHandler(self:GetComp("RootPanel/RewardPanel/BtnArea/ContinueBtn", "Button"), function()
        self:SubmitCurQuestion()
    end
    )

    self:SetButtonClickHandler(self:GetComp("RootPanel/RewardPanel/BtnArea/FinishBtn", "Button"), function()
        QuestionSurveyUI:CloseView()
    end
    )
end

function QuestionSurveyUIView:OnExit()
    self.super:OnExit(self)
end

function QuestionSurveyUIView:SubmitCurQuestion(isExitUI)

    if not self.curCfg then
        return
    end
    if self.curCfg.type == 1 or self.curCfg.type == 2 then
        if not self.m_data or Tools:GetTableSize(self.m_data) <= 0 then 
            self:UpdateQuetionTips(true)
            return 
        end
    end
    local curAnswerIds = {}
    for k, data in ipairs(self.m_data) do
        if data.isSelect then
            table.insert(curAnswerIds, data.index)
        end
    end
    local sumit = QuestionSurveyDataManager:SubmitQuestion(self.curCfg["number"], self.curCfg["type"], self.curCfg["id"], curAnswerIds)
    if  sumit ~= 1 then
        self:UpdateQuetionTips(true)
        self:SumitErrorTips(sumit)
        return 
    end
    
    if not QuestionSurveyDataManager:GetQuestionIsOpen() or isExitUI then
        QuestionSurveyUI:CloseView()
        return
    end
    self.currQuestionID = QuestionSurveyDataManager:GetCurQuestionID()
    self:RefreshPanelDisplay(self.currQuestionID)
end

function QuestionSurveyUIView:SumitErrorTips(errorType)

    -- EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
end

function QuestionSurveyUIView:UpdateListItem(index, tran)
    local curIndex = index + 1
    local go = tran.gameObject
    local data = self.m_data[curIndex]
    self:GetGo(go, "normal"):SetActive(not data.isSelect)
    self:GetGo(go, "choose"):SetActive(data.isSelect)
    local questContent = GameTextLoader:ReadText(data.quetionDesc)
    self:SetText(go, "normal/txt", questContent)
    self:SetText(go, "choose/txt", questContent)
    self:SetButtonClickHandler(self:GetComp(go, "", "Button"), function()
        if self.curCfg.type == 1 then
            for i, data in ipairs(self.m_data) do
                if i ~= curIndex then
                    data.isSelect = false
                end
            end
            data.isSelect = true
        elseif self.curCfg.type == 2 then
            data.isSelect = not data.isSelect
        end
        if self.mList then
            self.mList:UpdateData()
        end
        -- self:UpdateQuetionTips(true)
    end)
    
end

function QuestionSurveyUIView:UpdateQuetionTips(isOperationed)
    -- if not self.curListGo then
    --     return
    -- end
    local selectNum = 0
    for i, v in ipairs(self.m_data) do
        if v.isSelect then
            selectNum  = selectNum + 1
        end
    end
    if self.curCfg.type == 1 then
        -- TipsGO:SetActive(selectNum ~= 1)
        if selectNum ~= 1 then
            -- self:SetText(TipsGO, "txt", GameTextLoader:ReadText("TXT_SURVEY_TIP_1"))
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_SURVEY_TIP_1"))
        end
        return
    end
    
    if self.curCfg.type == 2 then
        local cfgMin = self.curCfg.limit[1]
        local cfgMax = self.curCfg.limit[2]
        if not (selectNum >= cfgMin and selectNum <= cfgMax) then
            local desc = ""
            if selectNum < cfgMin then
                desc = GameTextLoader:ReadText("TXT_SURVEY_TIP_7")
                desc = Tools:FormatString(desc, tostring(cfgMin), tostring(selectNum))
            elseif selectNum > cfgMax then
                desc = GameTextLoader:ReadText("TXT_SURVEY_TIP_6")
                desc = Tools:FormatString(desc, tostring(cfgMax), tostring(selectNum))
            end
            EventManager:DispatchEvent("UI_NOTE", desc)
        end
    end
end
return QuestionSurveyUIView