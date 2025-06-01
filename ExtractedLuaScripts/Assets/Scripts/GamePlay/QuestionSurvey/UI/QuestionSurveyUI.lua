--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 11:54:55
    问卷调查UI的Control对象
]]

local QuestionSurveyUI = GameTableDefine.QuestionSurveyUI
local QuestionSurveyDataManager = GameTableDefine.QuestionSurveyDataManager
local GameUIManager = GameTableDefine.GameUIManager

function QuestionSurveyUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.QUESTION_SURVEY, self.m_view, require("GamePlay.QuestionSurvey.UI.QuestionSurveyUIView"), self, self.CloseView)
    return self.m_view
end

function QuestionSurveyUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.QUESTION_SURVEY)
    self.m_view = nil
    collectgarbage("collect")
end