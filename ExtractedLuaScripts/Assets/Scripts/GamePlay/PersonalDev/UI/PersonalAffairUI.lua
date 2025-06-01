--[[
    用于个人发展个人事务处理UI控制对象
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-24 10:10:20
]]

local PersonalAffairUI = GameTableDefine.PersonalAffairUI
local GameUIManager = GameTableDefine.GameUIManager
local PersonalDevModel = GameTableDefine.PersonalDevModel
local ConfigMgr = GameTableDefine.ConfigMgr
local GameResMgr = require("GameUtils.GameResManager")
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local FlyIconsUI = GameTableDefine.FlyIconsUI

local AffairTimelineNames = 
{
    "OpenTimeline",
    "WorkTimeline",
    "RestTimeline",
}


function PersonalAffairUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PERSONAL_AFFAIR_UI, self.m_view, require("GamePlay.PersonalDev.UI.PersonalAffairUIView"), self, self.CloseView)
    
    return self.m_view
end

function PersonalAffairUI:CloseView()

    if self.m_timelineGos and Tools:GetTableSize(self.m_timelineGos) > 0 then
        for k, v in pairs(self.m_timelineGos) do
            GameObject.Destroy(v)
            self.m_timelineGos[k] = nil
        end
    else
        self.m_timelineGos = {}
    end
    if self.roomGo then
        GameObject.Destroy(self.roomGo)
        self.roomGo = nil
    end
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PERSONAL_AFFAIR_UI)

    self.m_view = nil
    collectgarbage("collect")
end

function PersonalAffairUI:OpenAffairUI()
    FlyIconsUI:SetScenceSwitchEffect(1, function()
        self:InitDefaultData()
        if not self:GetView() then
            return
        end
        self:GetView():Invoke("OpenAffairUI", PersonalDevModel:GetAffairsQueue())
        GameTableDefine.MainUI:Hideing()
        local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
        if not devCfg then
            self:CloseView()
            return 
        end
        -- self.curQuestionID = PersonalDevModel:GetAffairsQueue()
        local roomPath = devCfg.affair_perfab
        GameResMgr:AInstantiateObjectAsyncManual(roomPath, self, function(go)
            local OverlayCamera = UnityHelper.GetTheChildComponent(go, "Overlay Camera", "Camera")            
            local mainCamera = GameTableDefine.GameUIManager:GetSceneCamera()
            UnityHelper.AddCameraToCameraStack(mainCamera,OverlayCamera,0)
            self.roomGo = go
            if not self.roomGo then
                self:CloseView()
                return
            end
            for _, name in ipairs(AffairTimelineNames) do
                local tmpGO = UnityHelper.FindTheChildByGo(self.roomGo, name)
                self.m_timelineGos[name] = tmpGO
            end
            self:InitTimelineGoEntity()
            FlyIconsUI:SetScenceSwitchEffect(-1)
        end)
    end)
    
    
end

function PersonalAffairUI:InitDefaultData()
    if self.m_timelineGos and Tools:GetTableSize(self.m_timelineGos) > 0 then
        for k, v in pairs(self.m_timelineGos) do
            GameObject.Destroy(v)
            self.m_timelineGos[k] = nil
        end
    else
        self.m_timelineGos = {}
    end
end

function PersonalAffairUI:InitTimelineGoEntity()
    if self.roomGo then
        if self.curBossGo then
            GameObject.Destroy(self.curBossGo)
            self.curBossGo = nil
        end
        if self.curSecretaryGo then
            GameObject.Destroy(self.curSecretaryGo)
            self.curSecretaryGo = nil
        end
        local bossPosGo = UnityHelper.FindTheChildByGo(self.roomGo, "PersonPos")
        local bossGo = UnityHelper.FindTheChildByGo(self.roomGo, "PersonPos/Boss_001")
        local secretaryPosGo = UnityHelper.FindTheChildByGo(self.roomGo, "MishuPos")
        local secretaryGo = UnityHelper.FindTheChildByGo(self.roomGo, "MishuPos/Secretary_001")
        local bossEn = GameTableDefine.FloorMode:GetCurBossEntity()
        if bossEn then
            self.curBossGo = UnityHelper.CopyGameByGo(bossEn:GetEntityGo(), bossPosGo)
            if self.curBossGo then
                self.curBossGo.transform.localPosition = bossGo.transform.localPosition
                self.curBossGo.transform.localScale = bossGo.transform.localScale
                self.curBossGo.transform.rotation = bossGo.transform.rotation
                PersonalDevModel:ClearCopyGameObjectStage(self.curBossGo)
            end
        end
        local secretaryEn = GameTableDefine.FloorMode:GetCurSecretaryEntity()
        if secretaryEn then
            self.curSecretaryGo = UnityHelper.CopyGameByGo(secretaryEn:GetEntityGo(), secretaryPosGo)
            if self.curSecretaryGo then
                self.curSecretaryGo.transform.localPosition = secretaryGo.transform.localPosition
                self.curSecretaryGo.transform.localScale = secretaryGo.transform.localScale
                self.curSecretaryGo.transform.rotation = secretaryGo.transform.rotation
                PersonalDevModel:ClearCopyGameObjectStage(self.curSecretaryGo)
            end
        end
        secretaryGo:SetActive(false)
        bossGo:SetActive(false)
        --绑定Timeline的角色
        if self.curBossGo and self.curSecretaryGo then
            for _, timeline in pairs(self.m_timelineGos) do
                local playableDirector = timeline:GetComponent("PlayableDirector")
                if playableDirector then
                    if not UnityHelper.ChangeTimelineSourceObject(playableDirector, "Boss", self.curBossGo) then
                        print("Error:AffairUI:change boss actor failed")
                    end
                    if not UnityHelper.ChangeTimelineSourceObject(playableDirector, "Mishu", self.curSecretaryGo) then
                        print("Error:AffairUI:change secretary actor failed")
                    end
                end
            end
        end
        --判断当前的事物数量来播放对应的动画
        if PersonalDevModel:GetCurAffairLimit() > 0 then
            self:PlayTimeline("OpenTimeline")
        else
            self:PlayTimeline("RestTimeline")
        end
    end
end

function PersonalAffairUI:PlayTimeline(timelineName)
    -- for _, go in pairs(self.m_timelineGos) do
    --     go:SetActive(false)
    -- end
    if self.curTimelineName then
        if self.m_timelineGos[self.curTimelineName] then 
            local curPlayable = self.m_timelineGos[self.curTimelineName]:GetComponent("PlayableDirector")
            if curPlayable then
                curPlayable:Stop()
            end
        end
    end
    if self.m_timelineGos[timelineName] then
        local playable = self.m_timelineGos[timelineName]:GetComponent("PlayableDirector")
        if playable then
            self.m_timelineGos[timelineName]:SetActive(true)
            self.curBossGo:SetActive(true)
            self.curSecretaryGo:SetActive(true)
            playable:Play()
            self.curTimelineName = timelineName
        end
    end
end