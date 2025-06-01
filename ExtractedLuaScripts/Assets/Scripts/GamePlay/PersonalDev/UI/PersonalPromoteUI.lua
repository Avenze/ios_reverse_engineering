--[[
    个人发展竞选UI管理器，也作为竞选功能的场景管理器和逻辑控制器在使用
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-31 11:03:33
]]
local PersonalPromoteUI = GameTableDefine.PersonalPromoteUI
local Class = require("Framework.Lua.Class");
local BaseScene = require("Framework.Scene.BaseScene")
local GameUIManager = GameTableDefine.GameUIManager
local GameResMgr = require("GameUtils.GameResManager")
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local EventManager = require("Framework.Event.Manager")
local FloatUI = GameTableDefine.FloatUI
local ConfigMgr = GameTableDefine.ConfigMgr
local UIView = require("Framework.UI.View")
local PersonalDevModel = GameTableDefine.PersonalDevModel
local FlyIconsUI = GameTableDefine.FlyIconsUI

local PromoteTimelineNames = 
{
    "OpenTimeline",
    "AnswerTimeline",
    "SpeechTimeline",
    "NormalTimeline",
    "VoteTimeline",
}

local PromoteTimelineComplateKey = 
{
    "OPEN_TIME_COMPLATE", --openTime结束
    "ANSWER_TIME_COMPLATE", --answertime结束
    "SPEECH_TIME_COMPLATE", --speechTime结束
    "NORMAL_TIME_COMPLATE", --nomaltime结束
    "VOTE_TIME_COMPLATE", --竞选time结束
    "SPEECH_TIME_EVENT_01", --演讲事件1
    "SPEECH_TIME_EVENT_02", --演讲事件2
    "SPEECH_TIME_EVENT_03", --演讲事件3
    "SPEECH_TIME_EVENT_04", --演讲事件4
}
-- function PersonalPromoteUI:ctor()
--     self.super:ctor()
-- end

function PersonalPromoteUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PERSONAL_PROMOTE_UI, self.m_view, require("GamePlay.PersonalDev.UI.PersonalPromoteUIView"), self, self.CloseView)
    return self.m_view
end

function PersonalPromoteUI:InitDefaultData()
    local stageCfg = ConfigMgr.config_stage[PersonalDevModel:GetTitle() + 1][PersonalDevModel:GetStage()]
    self.m_stepStage = 1 --当前竞选的阶段索引
    self.m_usedQuestionIDs = {} --已经使用过的题目ID
    self.m_curPlayerSupport = PersonalDevModel:GetSupportCount()
    self.m_curEnemySupport = 0
    if stageCfg then
        self.m_curEnemySupport = stageCfg.opponent_attr
        self.m_curEnemyID = stageCfg.opponent_id or 1
    end
    --头顶汽包的初始化
    if not self.m_bubbleGos then
        self.m_bubbleGos = {}
    else
        for _, go in pairs(self.m_bubbleGos) do
            GameObject.Destroy(go)
        end
        self.m_bubbleGos = {}
    end
end

function PersonalPromoteUI:GetStepStage()
    return self.m_stepStage or 1
end

function PersonalPromoteUI:AddStepStage()
    self.m_stepStage  = self.m_stepStage + 1
end

function PersonalPromoteUI:GetUsedQuestionIDs()
    return self.m_usedQuestionIDs or {}
end

function PersonalPromoteUI:AddQuestionID(questionID)
    if not self.m_usedQuestionIDs then
        self.m_usedQuestionIDs = {}
    end
    table.insert(self.m_usedQuestionIDs, questionID)
end

function PersonalPromoteUI:OpenPersonPromoteUI()
    FlyIconsUI:SetScenceSwitchEffect(1,function()
        self:InitDefaultData()
        if self.m_timelineGos and Tools:GetTableSize(self.m_timelineGos) > 0 then
            for k, v in pairs(self.m_timelineGos) do
                GameObject.Destroy(v)
                self.m_timelineGos[k] = nil
            end
        else
            self.m_timelineGos = {}
        end
        
        EventManager:RegEvent("OPEN_TIME_COMPLATE", function(go)
            print("process OPEN_TIME_COMPLATE")
            self:ProcessOpenTimeComplete()
            
        end)
        EventManager:RegEvent("ANSWER_TIME_COMPLATE", function(go)
            print("process ANSWER_TIME_COMPLATE")
            self:ProcessAnswerTimeComplete()
        end)
        EventManager:RegEvent("SPEECH_TIME_COMPLATE", function(go)
            print("process SPEECH_TIME_COMPLATE")
            self:GetView():Invoke("ShowOneSpeechResult")
        end)
        EventManager:RegEvent("NORMAL_TIME_COMPLATE", function(go)
            print("process NORMAL_TIME_COMPLATE")
            self.m_stepStage  = self.m_stepStage + 1
            self:ProcessOpenTimeComplete()
        end)
        EventManager:RegEvent("VOTE_TIME_COMPLATE", function(go)
            print("process VOTE_TIME_COMPLATE")
            self:CloseView()
            --计算玩家是否获胜
            local isWin = self.m_curPlayerSupport >= self.m_curEnemySupport
            if isWin then
                PersonalDevModel:WinOneCampaignTurn()
            end
            --打开结果界面需要的数据
            --对手的配置id，玩家和对手的支持人数，
            GameTableDefine.PersonalPromoteResultUI:OpenPromoteResult(self.m_curEnemyID, self.m_curPlayerSupport, self.m_curEnemySupport)
            -- self:Exit()
        end)

        EventManager:RegEvent("SPEECH_TIME_EVENT_01", function(go)
            print("process SPEECH_TIME_EVENT_01")
            if not self._curQuestionID and not self._curAnswerIndex then
                return
            end
            local questionCfg = ConfigMgr.config_campaign[self._curQuestionID]
            if not questionCfg then
                return
            end
            local answerStr = GameTextLoader:ReadText(questionCfg.opion_txt[self._curAnswerIndex])
            --绑定头顶汽包
            if not self._bossBubbleData then
                self._bossBubbleData = {go = self.curBossGo}
            end
            FloatUI:SetObjectCrossCamera(self._bossBubbleData, function(view, guid)
                if view then
                    view:Invoke("PersonalDevNpcTalk", answerStr, 1)
                end
            end)
        end)

        EventManager:RegEvent("SPEECH_TIME_EVENT_02", function(go)
            print("process SPEECH_TIME_EVENT_02")
            if self._bossBubbleData then
                FloatUI:RemoveObjectCrossCamera(self._bossBubbleData)
            end
            self:GetView():Invoke("ShowSpeechAudienceResult", self._curQuestionID, self._curAnswerIndex)
        end)

        EventManager:RegEvent("SPEECH_TIME_EVENT_03", function(go)
            print("process SPEECH_TIME_EVENT_03")
            if not self._curQuestionID or self._curQuestionID == 0 then
                return
            end
            local stageCfg = ConfigMgr.config_stage[PersonalDevModel:GetTitle() + 1][PersonalDevModel:GetStage()]
            if not stageCfg then
                return
            end
            local questionCfg = ConfigMgr.config_campaign[self._curQuestionID]
            if not questionCfg then
                return
            end
            local enemyConfg = ConfigMgr.config_opponent[stageCfg.opponent_id]
            if not enemyConfg then
                return
            end
            self._enemyBubbleData = {go = self.curEnemyGo}
            self._enemyAnswerIndex = math.random(1, questionCfg.opion + 1)
            --获取对手的回答内容
            local enemyAnswerStr = "None"
            if self._enemyAnswerIndex <= questionCfg.opion then
                enemyAnswerStr = GameTextLoader:ReadText(questionCfg.opion_txt[self._enemyAnswerIndex])
                self:ChangeCurEnemySupport(questionCfg.awards[self._enemyAnswerIndex])
            else
                enemyAnswerStr = GameTextLoader:ReadText(enemyConfg.option)
                self:ChangeCurEnemySupport(enemyConfg.awards)
            end
            -- local enemyAnswerStr = 
            FloatUI:SetObjectCrossCamera(self._enemyBubbleData, function(view, guid)
                if view then
                    view:Invoke("PersonalDevNpcTalk", enemyAnswerStr, 1)
                end
            end)
        end)

        EventManager:RegEvent("SPEECH_TIME_EVENT_04", function(go)
            print("process SPEECH_TIME_EVENT_04")
            if self._enemyBubbleData then
                FloatUI:RemoveObjectCrossCamera(self._enemyBubbleData)
            end
            self:GetView():Invoke("ShowSpeechAudienceResult", self._curQuestionID, self._enemyAnswerIndex)
        end)
        local roomPath = "Assets/Res/Prefabs/Buildings/Jingxuan101.prefab" 
        GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(go)
            --UnityHelper.GetTheChildComponent(obj, child, uiType)
            local OverlayCamera = UnityHelper.GetTheChildComponent(go, "CameraCG", "Camera")            
            local mainCamera = GameTableDefine.GameUIManager:GetSceneCamera()
            UnityHelper.AddCameraToCameraStack(mainCamera,OverlayCamera,0)
            UnityHelper.SetMainCameraPhysicRayCast(false)
            --设置头顶泡泡的UI的相机为当前场景的相机
            GameTableDefine.GameUIManager:ChangeCanvas3DCamera(OverlayCamera)
            self.roomGo = go
            if not self.roomGo then
                return
            end
            self.roomGo.transform.position = CS.UnityEngine.Vector3(self.roomGo.transform.position.x + 400, self.roomGo.transform.position.y, self.roomGo.transform.position.z)
            --初始化Time的Go
            for _, name in ipairs(PromoteTimelineNames) do
                local tmpGo = UnityHelper.FindTheChildByGo(self.roomGo, name)
                self.m_timelineGos[name] = tmpGo
            end
            self:InitTimelineGoEntity()
            FlyIconsUI:SetScenceSwitchEffect(-1, function()
                self:PlayTimeline("OpenTimeline")
            end)
            
        end)

    end)
end

function PersonalPromoteUI:InitTimelineGoEntity()
    if self.roomGo then
        local loadConut = 0
        local personGo = UnityHelper.FindTheChildByGo(self.roomGo, "NPC")
        local bossGo = UnityHelper.FindTheChildByGo(personGo, "Boss")
        local enemyGo = UnityHelper.FindTheChildByGo(personGo, "Enemy")
        local bossActorEn = UnityHelper.FindTheChildByGo(bossGo, "BossEntity")
        local enemyActorEn = UnityHelper.FindTheChildByGo(enemyGo, "EnemyEntity")
        --生成当前的boss的Go对象，并添加到父节点
        if self.curBossGo then
            GameObject.Destroy(self.curBossGo)
        end
        local bossEn = GameTableDefine.FloorMode:GetCurBossEntity()
        if bossEn and bossEn:GetEntityGo() then
            self.curBossGo = UnityHelper.CopyGameByGo(bossEn:GetEntityGo(), bossGo)
            if self.curBossGo then
                self.curBossGo.transform.localPosition = bossActorEn.transform.localPosition
                self.curBossGo.transform.rotation = bossActorEn.transform.rotation
                self.curBossGo.transform.localScale = bossActorEn.transform.localScale
                --这里拷过来的boss可能是在隐藏楼层的，所以要把render设置回来
                PersonalDevModel:ClearCopyGameObjectStage(self.curBossGo)
            end
            self:BindBossAndEnemyToTimeline("Boss")
        end
        --TODO:生成配置对应的对手的Go
        if self.curEnemyGo then
            GameObject.Destroy(self.curEnemyGo)
            self.curEnemyGo = nil
        end
        local enemyPath = "Assets/Res/Prefabs/character/Boss_003.prefab"
        local stageCfgTitle = ConfigMgr.config_stage[PersonalDevModel:GetTitle() + 1]
        if stageCfgTitle then
            local stageCfg = stageCfgTitle[PersonalDevModel:GetStage()]
            if not stageCfg then
                stageCfg = stageCfgTitle[PersonalDevModel:GetStage() - 1]
            end
            if stageCfg then
                local opponentCfg = ConfigMgr.config_opponent[stageCfg.opponent_id]
                if opponentCfg then
                    enemyPath = "Assets/Res/Prefabs/character/"..opponentCfg.prefab..".prefab"
                end
            end
        end
        GameResMgr:AInstantiateObjectAsyncManual(enemyPath, self, function(go)
            self.curEnemyGo = go
            self.curEnemyGo.transform.parent = enemyGo.transform
            self.curEnemyGo.transform.localPosition = enemyActorEn.transform.localPosition
            self.curEnemyGo.transform.rotation = enemyActorEn.transform.rotation
            self.curEnemyGo.transform.localScale = enemyActorEn.transform.localScale
            self:BindBossAndEnemyToTimeline("Enemy")
        end)
        
    end
end

function PersonalPromoteUI:BindBossAndEnemyToTimeline(bindType)
    --替换所有timeline中的boss和enemy
    for _, timeline in pairs(self.m_timelineGos) do
        local playableDirector = timeline:GetComponent("PlayableDirector")
        if playableDirector then
            if bindType == "Boss" then
                if not UnityHelper.ChangeTimelineSourceObject(playableDirector, "Boss", self.curBossGo) then
                    print("PersonalPromoteUI:Change Timelie actor curBoss failed")
                end
            end
            --换对手模型
            if bindType == "Enemy" then
                if not UnityHelper.ChangeTimelineSourceObject(playableDirector, "Enemy", self.curEnemyGo) then
                    print("PersonalPromoteUI:Change Timelie actor enemy failed")
                end
            end
        end
    end
end

function PersonalPromoteUI:PlayTimeline(timelineName)
    for _, go in pairs(self.m_timelineGos) do
        go:SetActive(false)
    end
    -- if self.curTimelineName then
    --     if self.m_timelineGos[self.curTimelineName] then
    --         local curPlayable = self.m_timelineGos[self.curTimelineName]:GetComponent("PlayableDirector")
    --         if curPlayable then
    --             curPlayable:Stop()
    --         end
    --     end
    -- end
    if self.m_timelineGos[timelineName] then
        local playable = self.m_timelineGos[timelineName]:GetComponent("PlayableDirector")
        if playable then
            self.m_timelineGos[timelineName]:SetActive(true)
            if self.curBossGo then
                self.curBossGo:SetActive(true)
            end
            if self.curEnemyGo then
                self.curEnemyGo:SetActive(true)
            end
            self.curTimelineName = timelineName
            playable:Play()
        end
    end
end

function PersonalPromoteUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PERSONAL_PROMOTE_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function PersonalPromoteUI:Exit()
    UnityHelper.SetMainCameraPhysicRayCast(true)
    GameTableDefine.GameUIManager:RestoreCanvas3DCamera()
    self:ClearData()
end

function PersonalPromoteUI:ClearData()
    self.m_timelineGos = {}

    EventManager:UnregEvent("OPEN_TIME_COMPLATE")
    EventManager:UnregEvent("ANSWER_TIME_COMPLATE")
    EventManager:UnregEvent("SPEECH_TIME_COMPLATE")
    EventManager:UnregEvent("NORMAL_TIME_COMPLATE")
    EventManager:UnregEvent("VOTE_TIME_COMPLATE")
    EventManager:UnregEvent("SPEECH_TIME_EVENT_01")
    EventManager:UnregEvent("SPEECH_TIME_EVENT_02")
    EventManager:UnregEvent("SPEECH_TIME_EVENT_03")
    EventManager:UnregEvent("SPEECH_TIME_EVENT_04")

    self.m_bubbleGos = {}
    self.m_stepStage = 1
    self.m_usedQuestionIDs = {}
    self._curQuestionID = nil
    self._curAnswerIndex = 0
    self._enemyAnswerIndex = 0
    self._bossBubbleData = nil
    self._enemyBubbleData = nil
    self.curEnemyGo = nil
    self.curBossGo = nil
     --最后释放当前竞选场景的go
     if self.roomGo then
        GameObject.Destroy(self.roomGo)
        self.roomGo = nil
    end
end

function PersonalPromoteUI:ProcessOpenTimeComplete()
    local curStageIndex = self.m_stepStage
    self:GetView():Invoke("openTimelineComplate", curStageIndex)
end

function PersonalPromoteUI:ProcessAnswerTimeComplete()
    self:GetView():Invoke("AnswerTimelineComplete")
end

--[[
    @desc: 点击选出竞选问题集进行显示
    author:{author}
    time:2023-09-08 14:12:07
    @return:
]]
function PersonalPromoteUI:ChangeToSpeechProcess(questionID, answerIndex, answerStr)
    -- function()
    --     FloatUI:RemoveObjectCrossCamera(bubbleData)
    -- end
    self._curQuestionID = questionID
    self._curAnswerIndex = answerIndex
    local questCfg = ConfigMgr.config_campaign[questionID]
    if questCfg then
        local rewards = questCfg.awards[self._curAnswerIndex] or 0
        self:ChangeCurPlayerSupport(rewards)
    end
    --这里根据答题的内容给予对应的分数（支持率）
    self:PlayTimeline("SpeechTimeline")
end

function PersonalPromoteUI:GetCurEnemySupport()
    return self.m_curEnemySupport or 0
end

function PersonalPromoteUI:GetCurPlayerSupport()
    return self.m_curPlayerSupport or 0
end

function PersonalPromoteUI:ChangeCurEnemySupport(changeValue)
    self.m_curEnemySupport  = self.m_curEnemySupport + changeValue
    if self.m_curEnemySupport < 0 then
        self.m_curEnemySupport = 0
    end
end

function PersonalPromoteUI:ChangeCurPlayerSupport(changeValue)
    self.m_curPlayerSupport  = self.m_curPlayerSupport + changeValue
    if self.m_curPlayerSupport < 0 then
        self.m_curPlayerSupport = 0
    end
end

function PersonalPromoteUI:GetCurQuestionID()
    return self._curQuestionID or 0
end

function PersonalPromoteUI:GetCurAnswerIndex()
    return self._curAnswerIndex or 1
end
