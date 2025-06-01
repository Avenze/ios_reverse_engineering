--[[
    个人竞选UIView界面
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-31 10:30:31
]]


local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local GameResMgr = require("GameUtils.GameResManager")
local UnityHelper = CS.Common.Utils.UnityHelper

local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr

local PersonalDevModel = GameTableDefine.PersonalDevModel
local PersonalPromoteUI = GameTableDefine.PersonalPromoteUI

local PersonalPromoteUIView = Class("PersonalPromoteUIView", UIView)

function PersonalPromoteUIView:ctor()
    self.super:ctor()
end

function PersonalPromoteUIView:OnEnter()
    print("PersonalPromoteUIView:OnEnter")

end

function PersonalPromoteUIView:OnExit()
    self.super:OnExit(self)
end

function PersonalPromoteUIView:Hiding(isShow)
    local CanasGroup = self:GetComp("RootPanel","CanvasGroup")
    if not isShow then           
        CanasGroup.alpha = 0
        CanasGroup.interactable = false
    else
        CanasGroup.alpha = 1
        CanasGroup.interactable = true
    end
end

function PersonalPromoteUIView:openTimelineComplate(stageIndex)
    self:ClearInfoPanelDisp()
    self:GetGo("RootPanel/panel_"..1):SetActive(true)
    local currQutionGo = self:GetGoOrNil("RootPanel/QuestionBubble_"..stageIndex)
    if currQutionGo then
        for i = 1, currQutionGo.transform.childCount do 
            local childGo = currQutionGo.transform:GetChild(i - 1).gameObject
            local btn = self:GetComp(childGo, "icon", "Button")
            self:SetButtonClickHandler(btn, function()
                print("Now display the Promote question UI")
                currQutionGo:SetActive(false)
                self:GetGo("RootPanel/panel_"..1):SetActive(false)
                GameTableDefine.PersonalPromoteUI:PlayTimeline("AnswerTimeline")
            end)
        end
        currQutionGo:SetActive(true)
    end
    --剩余回合数
    self:SetText("RootPanel/panel_1/round/prog/bg/num", tostring(3 - stageIndex))
    --支持度百分比
    local totalSupport = PersonalPromoteUI:GetCurEnemySupport() + PersonalPromoteUI:GetCurPlayerSupport()
    if totalSupport > 0 then
        local playerSupportP = math.ceil(PersonalPromoteUI:GetCurPlayerSupport() / totalSupport * 100)
        self:SetText("RootPanel/panel_1/property/item1/bg/num", tostring(playerSupportP))
        self:SetText("RootPanel/panel_1/property/item2/bg/num", tostring(PersonalPromoteUI:GetCurPlayerSupport()))
    end
    self:Hiding(true)
end

function PersonalPromoteUIView:AnswerTimelineComplete()
    self:ClearInfoPanelDisp()
    self:GetGo("RootPanel/panel_"..2):SetActive(true)
    local curLvl = PersonalDevModel:GetTitle() + 1
    local curStage = PersonalDevModel:GetStage()
    local stageCfg = ConfigMgr.config_stage[curLvl][curStage]
    if not stageCfg then
        return
    end
    local selQuestionID = 0
    local forCount = 0
    local campaignMax = Tools:GetTableSize(stageCfg.campaign)
    while(selQuestionID == 0 or forCount >= campaignMax) do
        local randIndex = math.random(1, campaignMax)
        local isNotInUsed = true
        for _, v in ipairs(PersonalPromoteUI:GetUsedQuestionIDs()) do
            if v == stageCfg.campaign[randIndex] then
                isNotInUsed = false
                break
            end
        end
        if isNotInUsed then
            selQuestionID = stageCfg.campaign[randIndex]
        end
        forCount  = forCount + 1
    end
    if selQuestionID == 0 then
        --没有找到题是一个卡死的问题为了避免卡死，先选一个题给干上
        selQuestionID = stageCfg.campaign[1]
    else
        PersonalPromoteUI:AddQuestionID(selQuestionID)
    end
    local questionCfg = ConfigMgr.config_campaign[selQuestionID]
    if not questionCfg then
        --TODO:没有对应的问题配置处理关闭竞选的相关操作
        print("Lua:Error:PersonalPromoteUIView:question cfg is none, id is:"..tostring(selQuestionID))
        return
    end
    self:RefreshQuestionDisplay(selQuestionID)
end

function PersonalPromoteUIView:ClearInfoPanelDisp()
    for i = 1, 3 do
        self:GetGo("RootPanel/panel_"..i):SetActive(false)
    end
    for i = 1, 4 do 
        self:GetGo("RootPanel/QuestionBubble_"..i):SetActive(false)
    end

    for _, go in pairs(self.m_answerItemGos or {}) do
        go:SetActive(false)
    end
    self:GetGo("RootPanel/ElectionFeedback/bad"):SetActive(false)
    self:GetGo("RootPanel/ElectionFeedback/normal"):SetActive(false)
    self:GetGo("RootPanel/ElectionFeedback/good"):SetActive(false)
    self:GetGo("RootPanel/ElectionFeedback"):SetActive(false)
    self:GetGo("RootPanel/panel_3"):SetActive(false)
end

--[[
    @desc: 刷新竞选答题显示
    author:{author}
    time:2023-09-12 15:35:31
    --@questionID: 
    @return:
]]
function PersonalPromoteUIView:RefreshQuestionDisplay(questionID)
    local questionCfg = ConfigMgr.config_campaign[questionID]
    if not questionCfg then
        return
    end
    local panelGo = self:GetGo("RootPanel/panel_2")
    local questionTxt = GameTextLoader:ReadText(questionCfg.topic_desc)
    self:SetText(panelGo, "option/bg1/prog/top/title", questionTxt)
    --设置提问头像
    self:SetSprite(self:GetComp("RootPanel/panel_2/option/bg1/prog/top/character/icon", "Image"), "UI_Shop", questionCfg.npc_type)
    local answerTxts = {}
    local replyTxts = {}
    for i = 1, questionCfg.opion do
        local tmpTxt1 = GameTextLoader:ReadText(questionCfg.opion_txt[i])
        local tmpTxt2 = GameTextLoader:ReadText(questionCfg.option_reply[i])
        table.insert(answerTxts, tmpTxt1)
        table.insert(replyTxts, tmpTxt2)
    end
    if not self.m_answerItemGos then
        self.m_answerItemGos = {}
        local itemGo = self:GetGo("RootPanel/panel_2/option/bg1/prog/answer/item")
        table.insert(self.m_answerItemGos, itemGo)
    end
    if Tools:GetTableSize(self.m_answerItemGos) < questionCfg.opion then
        while(Tools:GetTableSize(self.m_answerItemGos) < questionCfg.opion) do
            local newGo = GameObject.Instantiate(self.m_answerItemGos[1], self.m_answerItemGos[1].transform.parent)
            table.insert(self.m_answerItemGos, newGo)
        end
    end
    --设置答题内容了
    for i = 1, Tools:GetTableSize(self.m_answerItemGos) do
        local itemGo = self.m_answerItemGos[i]
        if i <= questionCfg.opion then
            itemGo:SetActive(true)
            local btn = itemGo:GetComponent("Button")
            self:SetText(itemGo, "title", answerTxts[i])
            self:SetButtonClickHandler(btn, function()
                print("Select the campaign answer index is:"..i)
                PersonalPromoteUI:ChangeToSpeechProcess(questionID, i, answerTxts[i])
                self:ClearInfoPanelDisp()
            end)
        else
            itemGo:SetActive(false)
        end
    end
end

function PersonalPromoteUIView:ShowSpeechAudienceResult(questionID, answerID)
    self:ClearInfoPanelDisp()
    self:GetGo("RootPanel/ElectionFeedback"):SetActive(true)
    local questCfg = ConfigMgr.config_campaign[questionID]
    if not questCfg then
        self:GetGo("RootPanel/ElectionFeedback"):SetActive(false)
        return
    end
    local replayType = questCfg.icon_reply[answerID] or 1
    if replayType == 1 then
        self:GetGo("RootPanel/ElectionFeedback/good"):SetActive(true)
    elseif replayType == 2 then
        self:GetGo("RootPanel/ElectionFeedback/normal"):SetActive(true)
    elseif replayType == 3 then
        self:GetGo("RootPanel/ElectionFeedback/bad"):SetActive(true)
    end
    if self._audienceShowTimer then
        GameTimer:StopTimer(self._audienceShowTimer)
        self._audienceShowTimer = nil
    end
    self._audienceShowTimer = GameTimer:CreateNewTimer(1.5, function()
        self:GetGo("RootPanel/ElectionFeedback"):SetActive(false)
    end)
end

function PersonalPromoteUIView:ShowOneSpeechResult()
    self:ClearInfoPanelDisp()
    self:GetGo("RootPanel/panel_3"):SetActive(true)
    -- TODO：需要进一步做数据相关的显示内容
    local curQuestCfg = ConfigMgr.config_campaign[PersonalPromoteUI:GetCurQuestionID()]
    local curAwards = curQuestCfg.awards[PersonalPromoteUI:GetCurAnswerIndex()]
    self:GetGo("RootPanel/panel_3/info/bg/property/spt/add"):SetActive(curAwards >= 0)
    self:GetGo("RootPanel/panel_3/info/bg/property/spt/reduce"):SetActive(curAwards < 0)
    self:SetText("RootPanel/panel_3/info/bg/property/spt/add/num", tostring(curAwards))
    self:SetText("RootPanel/panel_3/info/bg/property/spt/reduce/num", tostring(curAwards))
    self:SetText("RootPanel/panel_3/info/bg/property/spt/now/num", tostring(PersonalPromoteUI:GetCurPlayerSupport()))
    self:SetText("RootPanel/panel_3/info/bg/reaction/txt/add", GameTextLoader:ReadText(curQuestCfg.option_reply[PersonalPromoteUI:GetCurAnswerIndex()]))
    local iconStr = "ui_personal_smile"
    local iconReply = curQuestCfg.icon_reply[PersonalPromoteUI:GetCurAnswerIndex()]
    if iconReply == 2 then
        iconStr = "ui_personal_aloof"
    elseif iconReply == 3 then
        iconStr = "ui_personal_rage"
    end
    self:SetSprite(self:GetComp("RootPanel/panel_3/info/bg/reaction/txt/icon", "Image"), "UI_Common", iconStr)
    local curLvl = PersonalDevModel:GetTitle() + 1
    local curStage = PersonalDevModel:GetStage()
    local stageCfg = ConfigMgr.config_stage[curLvl][curStage]
    if not stageCfg or not curQuestCfg then
        return
    end

    self:SetButtonClickHandler(self:GetComp("RootPanel/panel_3/info/bg/btnarea/conf_btn", "Button"), function()
        self:ClearInfoPanelDisp()
        if PersonalPromoteUI:GetStepStage() < 3 then
            PersonalPromoteUI:PlayTimeline("NormalTimeline")
        else
            PersonalPromoteUI:PlayTimeline("VoteTimeline")
        end
    end)
end

return PersonalPromoteUIView
