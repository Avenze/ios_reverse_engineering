--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-29 10:58:41
]]


---@class QuestionSurveyDataManager
local QuestionSurveyDataManager = GameTableDefine.QuestionSurveyDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode

-- 匹配问卷规则
function QuestionSurveyDataManager:matchRule(currStar)
    local userStar = currStar or StarMode:GetStar() -- 知名度
    print("匹配问卷规则，当前星星: ", userStar, currStar)
    
    local userBuildingId = CityMode:GetCurrentBuilding() -- 所处场景
    if userBuildingId then
        userBuildingId = math.floor(userBuildingId / 100)
    else
        userBuildingId = 0
    end

    local surveyConf = ConfigMgr.config_survey_new
    local appVer = CS.UnityEngine.Application.version
    local surveyConfig = surveyConf[appVer] or {}
    for i, v in pairs(surveyConfig) do
        local star_num_min = v.star_num_limit[1] or 0
        local star_num_max = v.star_num_limit[2] or 0
        local star_num_min_enable = star_num_min == 0 or star_num_min ~= 0 and star_num_min <= userStar
        local star_num_max_enable = star_num_max == 0 or star_num_max ~= 0 and star_num_max > userStar

        local scene_id_min = v.scene_id_limit[1] or 0
        local scene_id_max = v.scene_id_limit[2] or 0
        local scene_id_min_enable = scene_id_min == 0 or scene_id_min ~= 0 and scene_id_min <= userBuildingId
        local scene_id_max_enable = scene_id_max == 0 or scene_id_max ~= 0 and scene_id_max >= userBuildingId

        if star_num_min_enable and star_num_max_enable and scene_id_min_enable and scene_id_max_enable then
            print("匹配问卷规则: ", i)
            return i
        end
    end

    print("匹配问卷规则: ", 0)
    return 0
end

--[[
    @desc: 初始化问卷调查数据内容
    author:{author}
    time:2023-03-29 11:01:10
    @return:
]]
function QuestionSurveyDataManager:Init(currStar)
    self.isQuestionOpen = false
    self.curQuestionSurveyNewData = LocalDataManager:GetDataByKey("QuestionSurveyNewData")
    local surveyConf = ConfigMgr.config_survey_new
    local appVer = CS.UnityEngine.Application.version
    if surveyConf[appVer] then -- 配置了开启版本，并且没有记录此版本问卷的领取奖励时间
        local curVerData = self.curQuestionSurveyNewData and self.curQuestionSurveyNewData[appVer] or nil
        if not curVerData or not curVerData.awardTimestamp or curVerData.awardTimestamp <= 0 then
            local mathcRuleIndex = self:matchRule(currStar) -- 并且匹配开启规则
            if mathcRuleIndex ~= 0 then
                self.isQuestionOpen = true
            end
        end
    end

    self.isInit = true
    LocalDataManager:WriteToFile()
    
    --if needCheckSave then
    --    --如果没有解锁第二个办公区的话就不进行问卷的初始化检查存档
    --    local cityData = LocalDataManager:GetDataByKey(GameTableDefine.CountryMode.city_record_data)
    --    if not cityData then
    --        return
    --    end
    --    if not cityData.currBuidlingId or cityData.currBuidlingId < 200 then
    --        return
    --    end
    --end
    --self.curQuestionSurveyData = LocalDataManager:GetDataByKey("QuestionSurveyData")
    --self.isQuestionOpen = false
    --if ConfigMgr.config_global.survey_switch <= 0 then
    --    if self.curQuestionSurveyData.curQuestionID then 
    --        self.curQuestionSurveyData.curQuestionID = 0
    --        LocalDataManager:WriteToFile()
    --    end
    --    return
    --end
    --if not self.curQuestionSurveyData.curQuestionID or self.curQuestionSurveyData.curQuestionID ~= ConfigMgr.config_global.survey_switch then
    --    --重制数据了
    --    self.curQuestionSurveyData.curQuestionID = ConfigMgr.config_global.survey_switch
    --    self.curQuestionSurveyData.rewardData = {} --领取奖励数据
    --    self.curQuestionSurveyData.haveSubmitQuestionIds = {} --完成任务ID的数据
    --    self.curQuestionSurveyData.isComplete = false
    --end
    --self.isQuestionOpen = not self.curQuestionSurveyData.isComplete
    --self.isInit = true
    --LocalDataManager:WriteToFile()
end

-- 清除问卷存档
function QuestionSurveyDataManager:ClearSurvey()
    self.curQuestionSurveyNewData = LocalDataManager:GetDataByKey("QuestionSurveyNewData")
    local appVer = CS.UnityEngine.Application.version
    self.curQuestionSurveyNewData[appVer] = nil
    
    LocalDataManager:WriteToFile()
end

--region 新问卷
-- 显示 问卷
function QuestionSurveyDataManager:ShowSurvey(surveyId, languageId, url)
    print("记录显示问卷:", surveyId, languageId, url)
    
    local surveyVer = CS.UnityEngine.Application.version
    if not self.curQuestionSurveyNewData[surveyVer] then
        self.curQuestionSurveyNewData[surveyVer] = {}
    end

    -- 记录打开页面时间、显示语言、显示的问卷地址、问卷表ID
    self.curQuestionSurveyNewData[surveyVer].showTimestamp = GameTimeManager:GetCurrentServerTime()
    self.curQuestionSurveyNewData[surveyVer].showLanguageId = languageId
    self.curQuestionSurveyNewData[surveyVer].showUrl = url
    self.curQuestionSurveyNewData[surveyVer].showSurveyId = surveyId

    -- 埋点
    if GameConfig:IsWarriorVersion() then
        local cityData = LocalDataManager:GetDataByKey(GameTableDefine.CountryMode.city_record_data)
        --GameSDKs:TrackForeign("survey_show", { survey_version = CS.UnityEngine.Application.version, survey_language_id = languageId, survey_url = url, survey_star = GameTableDefine.StarMode:GetStar(), survey_scene_id = cityData.currBuidlingId or 0 })
        GameSDKs:TrackForeign("questionnaire_activity", { questionnaire_activity_scroll = surveyId, questionnaire_activity_star = GameTableDefine.StarMode:GetStar(), questionnaire_activity_scene_id = cityData.currBuidlingId or 0 })
    end
end

-- 关闭 问卷
function QuestionSurveyDataManager:CloseSurvey()
    local surveyVer = CS.UnityEngine.Application.version
    if not self.curQuestionSurveyNewData[surveyVer] then
        self.curQuestionSurveyNewData[surveyVer] = {}
    end

    -- 记录关闭页面时间
    self.curQuestionSurveyNewData[surveyVer].closeTimestamp = GameTimeManager:GetCurrentServerTime()

    -- 埋点
    --if GameConfig:IsWarriorVersion() then
    --    local cityData = LocalDataManager:GetDataByKey(GameTableDefine.CountryMode.city_record_data)
    --    GameSDKs:TrackForeign("survey_close", { survey_version = CS.UnityEngine.Application.version, survey_language_id = self.curQuestionSurveyNewData[surveyVer].showLanguageId, survey_url = self.curQuestionSurveyNewData[surveyVer].showUrl, survey_star = GameTableDefine.StarMode:GetStar(), survey_scene_id = cityData.currBuidlingId or 0 })
    --end
end

-- 领取 奖励
function QuestionSurveyDataManager:AwardSurvey()
    local surveyVer = CS.UnityEngine.Application.version
    if not self.curQuestionSurveyNewData[surveyVer] or not self.curQuestionSurveyNewData[surveyVer].showTimestamp or not self.curQuestionSurveyNewData[surveyVer].showSurveyId then
        return
    end

    if self.curQuestionSurveyNewData[surveyVer].awardTimestamp and self.curQuestionSurveyNewData[surveyVer].awardTimestamp > 0 then
        return
    end

    -- 记录领取奖励时间
    self.curQuestionSurveyNewData[surveyVer].awardTimestamp = GameTimeManager:GetCurrentServerTime()

    local award = 0
    local showSurveyId = self.curQuestionSurveyNewData[surveyVer].showSurveyId
    local surveyConf = ConfigMgr.config_survey_new[CS.UnityEngine.Application.version] or {}

    for _, v in pairs(surveyConf) do
        if v.id == showSurveyId then
            award = v.award
            break
        end
    end

    if award > 0 then
        GameTableDefine.ResourceManger:AddDiamond(award, nil, function()
            EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
        end)
    end

    self:Init()
    EventManager:DispatchEvent(GameEventDefine.OnBuyBuilding)

    -- 埋点
    if GameConfig:IsWarriorVersion() then
        GameSDKs:TrackForeign("questionnaire_reward", { questionnaire_reward_diamond = award })
    end
end

-- 返回问卷页面显示时间
function QuestionSurveyDataManager:GetShowSurveyTimestamp()
    local surveyVer = CS.UnityEngine.Application.version
    return self.curQuestionSurveyNewData[surveyVer] and self.curQuestionSurveyNewData[surveyVer].showTimestamp or 0
end

-- 返回问卷领奖时间
function QuestionSurveyDataManager:GetAwardSurveyTimestamp()
    local surveyVer = CS.UnityEngine.Application.version
    return self.curQuestionSurveyNewData[surveyVer] and self.curQuestionSurveyNewData[surveyVer].awardTimestamp or 0
end

--endregion

--[[
    @desc: 
    author:{author}
    time:2023-03-29 11:22:49
    --@partID:提交答题的阶段id
	--@type:答题的类型，多选，单选,单选1，多选2, 3公告型，如提示通告，4-可以选择中断答题的通告型，5-结束通告型
	--@questionIDs: {🆔}，题的id组
    @return:1-提交成功，2-当前没有答题，3-答题的数量超标，4-已经回答过该题了
]]
function QuestionSurveyDataManager:SubmitQuestion(partID, type, questionID, answerIDs, isOver)
    if not self.isQuestionOpen then
        return 2 
    end
    if not ConfigMgr.config_survey[partID] or not ConfigMgr.config_survey[partID][questionID] then
        return 2
    end
    local tmpCfg = ConfigMgr.config_survey[partID][questionID]
    --单选
    if type == 1 and Tools:GetTableSize(answerIDs) ~= 1 then
        return 3
    end
    --多选，需要判断是否满足配置的提交数量，如果不满足的话需要提示玩家
    if type == 2 then
        if not tmpCfg["limit"][1] or not tmpCfg["limit"][2] then
            return 3
        end
    end
    if type == 2 and (Tools:GetTableSize(answerIDs)< tmpCfg["limit"][1] or Tools:GetTableSize(answerIDs) > tmpCfg["limit"][2]) then
        return 3
    end
    if self.curQuestionSurveyData.haveSubmitQuestionIds and Tools:GetTableSize(self.curQuestionSurveyData.haveSubmitQuestionIds) > 0 then
        for _, id in pairs(self.curQuestionSurveyData.haveSubmitQuestionIds) do
            if id == questionID then
                return 4
            end
        end
    end
    table.insert(self.curQuestionSurveyData.haveSubmitQuestionIds, questionID)
    --检查是否有钻石奖励
    local ishaveReward = 0
    if tmpCfg["reward"] and tmpCfg["reward"] > 0 then
        ishaveReward = 1
        -- GameTableDefine.EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
        -- GameTableDefine.ResourceManger:AddDiamond(tmpCfg["reward"], nil, nil, true)
        -- GameTableDefine.ResourceManger:AddDiamond(tmpCfg["reward"], nil, function()                                                       
        --     GameTableDefine.EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
        -- end,true)
        GameTableDefine.ResourceManger:AddDiamond(tmpCfg["reward"], nil, function()
			EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
		end)
    end
    --打点进行
    if GameConfig:IsWarriorVersion() then
        local cityData = LocalDataManager:GetDataByKey(GameTableDefine.CountryMode.city_record_data)
        GameSDKs:TrackForeign("questionnaire_activity", {questionnaire_activity_scroll = ConfigMgr.config_global.survey_switch, questionnaire_activity_question = questionID,questionnaire_activity_opion = answerIDs,questionnaire_activity_star = GameTableDefine.StarMode:GetStar(),questionnaire_activity_scene_id = cityData.currBuidlingId or 0})
    end

    if type == 5 then
        self.curQuestionSurveyData.isComplete = true
    end
    if self.curQuestionSurveyData.isComplete then
        self.isQuestionOpen = false
        GameTableDefine.MainUI:RefreshQuestionSurvey()
    end
    LocalDataManager:WriteToFile()
    return 1
end

--[[
    @desc: 返回当前是否有开启问卷调查
    author:{author}
    time:2023-03-29 11:22:44
    @return:
]]
function QuestionSurveyDataManager:GetQuestionIsOpen()
    return self.isQuestionOpen
end

--[[
    @desc: 领取奖励,:这个应该用不到了，调整到了每部提交奖励获取了
    author:{author}
    time:2023-03-29 11:55:01
    --@partID: 
    @return:
]]
function QuestionSurveyDataManager:GetQuestionReward(partID)
    if not self.isQuestionOpen then
        return false
    end
    --TODO判断能否领奖
    local canGetReward = false
    if not self.curQuestionSurveyData.rewardData then
        self.curQuestionSurveyData.rewardData = {}
    end

    LocalDataManager:WriteToFile()
    return true
end

function QuestionSurveyDataManager:GetIsInit()
    return self.isInit
end


function QuestionSurveyDataManager:GetCurQuestionID()
    local result = 0
    if ConfigMgr.config_global.survey_switch <= 0 then
        return result
    end
    if not ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch] then
        return 0
    end
    if self.curQuestionSurveyData.isComplete then
        return result
    end
    --如果没有存档的问题回答的话，直接获取第一个问答ID
    if not self.curQuestionSurveyData.haveSubmitQuestionIds or Tools:GetTableSize(self.curQuestionSurveyData.haveSubmitQuestionIds) <= 0 then
        -- result = ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch][1].id
        -- local tmpQuestID = 0
        for k, v in pairs(ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch]) do
            result = v.id
            break
        end
        if result ~= 0 then
            for k, v in pairs(ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch]) do
                if result > v.id then
                    result = v.id
                end
            end
        end
        return result
    end

    --如果有提交的ID那就获取最大的ID，然后+1并判断配置数据是否有这个ID
    local tmpID = self.curQuestionSurveyData.haveSubmitQuestionIds[1]
    for key, id in ipairs(self.curQuestionSurveyData.haveSubmitQuestionIds) do
        if tmpID < id then
            tmpID = id
        end
    end
    if ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch][tmpID+1] then
        result = tmpID + 1
    end
    return result
end

function QuestionSurveyDataManager:GetCurQuestionPro(questionID)
    local curNum = 0
    local maxNum = 0
    local curCfg = ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch][questionID]
    if not curCfg then
        return 0, 0
    end
    local curQuestStage = curCfg.stage
    if curQuestStage == 0 then
        return 0, 0
    end
    for k, v in pairs(ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch]) do
        if v.stage == curQuestStage then
            maxNum  = maxNum + 1
        end
    end

    for k, v in pairs(self.curQuestionSurveyData.haveSubmitQuestionIds) do
        local tmpCfg = ConfigMgr.config_survey[ConfigMgr.config_global.survey_switch][v]
        if tmpCfg then
            if tmpCfg.stage == curQuestStage then
                curNum  = curNum + 1
            end
        end
    end
    return curNum + 1, maxNum
end