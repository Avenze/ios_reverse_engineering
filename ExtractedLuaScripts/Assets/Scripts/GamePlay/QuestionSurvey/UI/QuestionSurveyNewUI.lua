--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 11:54:55
    问卷调查UI的Control对象
]]

local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local ConfigMgr = GameTableDefine.ConfigMgr

---@class QuestionSurveyNewUI
local QuestionSurveyNewUI = GameTableDefine.QuestionSurveyNewUI
local QuestionSurveyDataManager = GameTableDefine.QuestionSurveyDataManager
local GameUIManager = GameTableDefine.GameUIManager

local QuestionSurveyNewUIView = require("GamePlay.QuestionSurvey.UI.QuestionSurveyNewUIView")


function QuestionSurveyNewUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.QUESTION_SURVEY_NEW, self.m_view, QuestionSurveyNewUIView, self, self.CloseView)
    return self.m_view
end

-- 加载 google form url
function QuestionSurveyNewUI:LoadUrl()
    local userStar = StarMode:GetStar() -- 知名度
    local userBuildingId = CityMode:GetCurrentBuilding() -- 所处场景
    local languageId = GameLanguage:GetCurrentLanguageID() -- 语言ID

    --local surveyAward = 0
    local surveyId = 0
    local url = ""
    local surveyConfig = ConfigMgr.config_survey_new[CS.UnityEngine.Application.version] or {}
    local mathcRuleIndex = QuestionSurveyDataManager:matchRule()
    if mathcRuleIndex > 0 then
        local surveyConf = surveyConfig[mathcRuleIndex] or {}
        if not languageId or not surveyConf[string.upper(languageId)] then
            languageId = "en"
        end

        url = surveyConf[string.upper(languageId)] or ""
        surveyId = surveyConf.id
        --surveyAward = surveyConf.award
    end

    return surveyId, languageId, url
end

function QuestionSurveyNewUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.QUESTION_SURVEY_NEW)
    self.m_view = nil
    collectgarbage("collect")
end