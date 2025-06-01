local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local Animator = CS.UnityEngine.Animator
local DialogueActor = CS.NodeCanvas.DialogueTrees.DialogueActor
--local SoundEngine = GameTableDefine.SoundEngine
local AudioMgr = CS.Common.Utils.AudioManager.Instance

local TalkUIView = Class("TalkUIView", UIView)
local utf8 = require("utf8")

function TalkUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_allNPC = {}
    self.m_vfx = {}
    self.m_allNPCGO = {}
    
    self.titleGOLeft = nil  
    self.titleGORight = nil
    
    self.textBgCompLeft = nil
    self.textBgCompRight = nil
end

function TalkUIView:OnEnter()
    local npcRoot = self:GetGo(self.m_uiObj, "log/bg/npc")
    for k, transfrom in pairs(npcRoot.transform or {}) do
        self.m_allNPC[transfrom.name] = transfrom.gameObject
    end
    
    self.lastNPC = "azhen_left"
    self.titleGOLeft = self:GetGo("log/bg/title_left")
    self.titleGORight = self:GetGo("log/bg/title_right")
    self.textBgCompLeft = self:GetComp("log/bg/Bg2_left", "Image")
    self.textBgCompRight = self:GetComp("log/bg/Bg2_right", "Image")

    self:SetDialogueStartedHandler(handler(self, self.OnDialogueStarted))
    self:SetDialoguePausedHandler(handler(self, self.OnDialoguePaused))
    self:SetDialogueFinishedHandler(handler(self, self.OnDialogueFinished))
    self:SetDialogueSubtitlesRequestHandler(handler(self, self.OnSubtitlesRequest))
    self:SetDialogueMultipleChoiceRequestHandler(handler(self, self.OnMultipleChoiceRequest))
end

function TalkUIView:OnExit()
    if self.endCallBack then
        self.endCallBack() 
    end

    self.endCallBack = nil
    
	self.super:OnExit(self)

    if self.dialogueTreeController and not self.dialogueTreeController:IsNull() then
        self.dialogueTreeController:StopDialogue()
    end
    
    --self:CloseDialogueTree()
end

function TalkUIView:OnDialogueStarted(dialogueTree)
end

function TalkUIView:OnDialoguePaused(dialogueTree)
end

function TalkUIView:OnDialogueFinished(dialogueTree)
    self:DestroyModeUIObject()
end

function TalkUIView:OnSubtitlesRequest(info)
    local statement = info.statement
    local btn = self:GetComp("log", "Button")
    if tonumber(statement.actionType.value__) == 1 then
        local onLeft = self:OnLeftSide(statement)
        local haveShowAllText = false
        local name = statement.name == "boss" and LocalDataManager:GetBossName() or statement.name
        local titlePath = onLeft and "title_left" or "title_right"
        self.titleGOLeft:SetActive(onLeft)
        self.titleGORight:SetActive(not onLeft)
        self:SetText("log/bg/" .. titlePath .. "/name", name)
        local headImage = onLeft and statement.head.."_left" or statement.head.."_right"
        self.m_allNPC[headImage]:SetActive(true)
        self.m_allNPC[headImage].transform:SetAsLastSibling()

        -- 播放表情
        local head = statement.head == "boss" and LocalDataManager:GetBossSkin() or statement.head
        local spriteName = "icon_" .. head .. "_" .. statement.headSprite
        self:SetSprite(self:GetComp(self.m_allNPC[headImage], "", "Image"), "UI_BG", spriteName)
        self.lastNPC = headImage
        
        local iconGO = self.m_allNPC[headImage]
        local talkBG = self:GetGo("log/bg")
        talkBG:SetActive(true)
        local animator = self:GetComp(iconGO, "", "Animator")
        if animator then
            animator:SetBool("Disable", false)
        end
        
        -- 刷新文字背景
        self.textBgCompLeft.gameObject:SetActive(onLeft)
        self.textBgCompRight.gameObject:SetActive(not onLeft)
        if statement.talkBGSprite then
            local talkBGImage = self:GetComp(talkBG, "Bg2_" .. (onLeft and "left" or "right"), "Image")
            if talkBGImage then
                talkBGImage.sprite = statement.talkBGSprite
            end
        end
        
        -- 播放表情特效
        local npcRoot = self:GetGo(iconGO, "vfx")
        for k, transfrom in pairs(npcRoot.transform or {}) do
            self.m_vfx[transfrom.name] = transfrom.gameObject
        end
        if statement.vfx and self.m_vfx[statement.vfx] then
            self.m_vfx[statement.vfx]:SetActive(true)
        end
        -- 播放弹出气泡
        if statement.popSprite then
            self:GetGo("log/bg/tipNode"):SetActive(true)
            self:GetComp("log/bg/tipNode/img", "Image").sprite = statement.popSprite
        end
        if statement.audio then
            --printf("对话Audio:"..statement.audio.name)
            --SoundEngine:PlaySFX(statement.audio.name)
            AudioMgr:PlaySoundFile(statement.audio)
        end

        if statement.usePrintVerbatim then
            local allText = statement.text
            local curIndex = 1
            local textLen = utf8.len(allText) -- 使用utf8.len获取正确的字符长度

            self.talkTimer = GameTimer:CreateNewMilliSecTimer(statement.characterSpeed * 1000, function()

                if curIndex <= textLen then
                    -- 获取已显示的完整字符部分
                    local curText = Tools:Utf8sub(allText, 1, curIndex)
                    -- 下一个字符开始的部分（不包括当前字符）
                    --local curText2Start = utf8.offset(allText, curIndex + 1) -- 获取下一个字符的起始位置
                    local curText2 = Tools:Utf8sub(allText, curIndex + 1, textLen) -- 从下一个字符开始到字符串结束
                    local show = curText .. "<color=#00000000>" .. curText2

                    self:SetText("log/bg/txt", show)

                    curIndex = curIndex + 1
                else
                    haveShowAllText = true
                    GameTimer:StopTimer(self.talkTimer)
                end
            end, true, false, true)

        else
            local showText = statement.text
            self:SetText("log/bg/txt", showText)
        end
        
        self:SetButtonClickHandler(btn, function()
            if statement.usePrintVerbatim and not haveShowAllText --[[可被跳过]] then
                local showText = statement.text
                self:SetText("log/bg/txt", showText)
                haveShowAllText = true
                GameTimer:StopTimer(self.talkTimer)
                print(statement.text,"跳过")
                return
            end
            
            self.m_allNPC[self.lastNPC]:SetActive(false)
            print(statement.text)
            if statement.vfx and self.m_vfx[statement.vfx] then
                self.m_vfx[statement.vfx]:SetActive(false)
            end
            self:GetGo("log/bg/tipNode"):SetActive(false)

            -- 刷新角色图片和背景
            if statement.useDisable or statement.refreshTalkBG then
                iconGO:SetActive(statement.useDisable)
                --local animator = self:GetComp(iconGO, "", "Animator")
                if animator then
                    animator:SetBool("Disable", statement.useDisable)
                end
                talkBG:SetActive(not statement.refreshTalkBG)
            end
            GameTimer:StopTimer(self.talkTimer)

            info.Continue()
        end)
       
    elseif tonumber(statement.actionType.value__) == 2 then
        local npcGO = self.m_allNPCGO[statement.name]
        local targetGO = npcGO.transform:Find(statement.emotiName)
        if targetGO then
            targetGO.gameObject:SetActive(statement.active)
        end
        self:SetButtonClickHandler(btn, function()
            targetGO.gameObject:SetActive(not statement.active)
            info.Continue()
        end)
        
    elseif tonumber(statement.actionType.value__) == 3 then
        local npcGO = self.m_allNPCGO[statement.name]
        if not npcGO then
            info.Continue()
            return
        end
        self:StopTimer()
        local animatorComp = npcGO:GetComponentInChildren(typeof(Animator))
        if not animatorComp then
            info.Continue()
            return
        end
        
        animatorComp:CrossFade(statement.stateName, statement.transitTime, statement.layerIndex);
        -- 是否立即跳到下一节点
        if not statement.waitUntilFinish then
            info.Continue()
        else
            local animatorStateInfo = animatorComp:GetCurrentAnimatorStateInfo(statement.layerIndex);
            local clipDuration = UnityHelper.GetAnimatorClipDuration(animatorComp, statement.stateName)
            clipDuration = clipDuration / animatorComp.speed
            self:StopTimer()
            self:CreateTimer(clipDuration * 1000, function()
                info.Continue()
                self:StopTimer()
            end, false, false, true)

        end
        
    elseif tonumber(statement.actionType.value__) == 4 then
        local rewardGO = self:GetGo("rewardNode")
        rewardGO:SetActive(true)
        -- 将点击事件置空
        self:SetButtonClickHandler(btn, function()

        end)
        self:SetText("rewardNode/name", GameTextLoader:ReadText(statement.name))
        self:SetText("rewardNode/desc", GameTextLoader:ReadText(statement.description))
        self:GetComp("rewardNode/img", "Image").sprite = statement.sprite
        self:StopTimer()
        self:CreateTimer(statement.blockTime * 1000, function()
            self:SetButtonClickHandler(btn, function()
                rewardGO:SetActive(false)
                info.Continue()
            end)
            self:StopTimer()
        end, false, false, true)
        
    elseif tonumber(statement.actionType.value__) == 5 then
        local Block = self:GetGo("log/Block")
        local CanvasGroup = self:GetComp("log/Block", "CanvasGroup")
        Block:SetActive(true)
        -- 将点击事件置空
        self:SetButtonClickHandler(btn, function()
        end)
        CanvasGroup.alpha = statement.strong.x
        self:GetComp("log/Block", "Image").color = statement.shadyColorChange
        self:StopTimer()
        local lastTime = 0
        local initClick = false
        if statement.autoEnd then
            self:CreateTimer(100, function()
                lastTime = lastTime + 100
                if lastTime <= statement.transTime * 1000 then
                    CanvasGroup.alpha = statement.strong.x + (statement.strong.y - statement.strong.x) * (lastTime / (statement.transTime * 1000))
                end
                if lastTime >= statement.endTime * 1000 then
                    self:StopTimer()
                    Block:SetActive(false)
                    info.Continue()
                end
            end, true, false, true)
        else
            self:CreateTimer(100, function()
                lastTime = lastTime + 100
                if lastTime <= statement.transTime * 1000 then
                    CanvasGroup.alpha = statement.strong.x + (statement.strong.y - statement.strong.x) * (lastTime / (statement.transTime * 1000))
                else
                    if not initClick then
                        initClick = true
                        self:SetButtonClickHandler(btn, function()
                            self:StopTimer()
                            Block:SetActive(false)
                            info.Continue()
                        end)
                    end
                end
            end, true, false, true)
        end
    elseif tonumber(statement.actionType.value__) == 6 then
        if not statement.parameter then
            if not self.Timeline then
                return
            end
            statement.parameter = self.Timeline.gameObject
        end
        EventManager:DispatchEvent(statement.eventName, statement.parameter)
        info.Continue()
    end

end

function TalkUIView:OnMultipleChoiceRequest(MultipleChoiceRequestInfo)
    
end

function TalkUIView:OpenTalk(id, setting, finalCallBack, beginCallBack, TLGo)
    if TLGo then
        -- 初始化角色GO
        self.Timeline = TLGo
        local npcRoot = self:GetGo(TLGo, "People")
        for k, transfrom in pairs(npcRoot.transform or {}) do
            --self.m_allNPCGO[transfrom.name] = transfrom.gameObject
            -- 使用DialogueActor类来标记剧场角色
            local comps = transfrom:GetComponentsInChildren(typeof(DialogueActor))
            if comps and comps.Length > 0 then
                for i = 0, comps.Length - 1 do
                    if comps[i].gameObject.name == "Boss" then
                        local bossSkin = LocalDataManager:GetBossSkin()
                        self.m_allNPCGO[comps[i].gameObject.name] = self:GetGo(comps[i].gameObject, bossSkin)
                    else
                        self.m_allNPCGO[comps[i].gameObject.name] = comps[i].gameObject
                    end
                end
            end
            
        end     
    end
    
    local path = "Assets/Res/UI/UI_Talk/talk_" .. id .. ".asset"
    GameResMgr:AInstantiateObjectAsyncManual(path, self, function(dialogTree)
        if not self.m_uiObj or self.m_uiObj:IsNull() then
            return
        end

        self:GetGo(self.m_uiObj, "log"):SetActive(true)
        
        self.dialogueTreeController = self.m_uiObj:GetComponent("DialogueTreeController")

        self.dialogueTreeController.graph = dialogTree

        self.mBlackBoard = self.dialogueTreeController.graph.blackboard

        self.mSetting = setting or {}

        if finalCallBack then
            self.endCallBack = finalCallBack    
        end

        -- for k,v in pairs(self.mSetting or {}) do
        --     UnityHelper.SetGraphBlackboardValue(self.mBlackBoard, k, v)
        -- end

        -- if beginCallBack then beginCallBack() end
        -- UnityHelper.StartDialogueTree(self.dialogueTreeController)
        local variables = self.mBlackBoard.variables
        for k,v in pairs(variables or {}) do
            if self.mSetting[k] then
                v.value = self.mSetting[k]
            end
        end

        if beginCallBack then beginCallBack() end
        self.dialogueTreeController:StartDialogue()
    end)
end

function TalkUIView:OnLeftSide(statement)
    if not statement or not statement.talkSide then
        return false
    end
    return statement.talkSide.value__ == 1
end

return TalkUIView