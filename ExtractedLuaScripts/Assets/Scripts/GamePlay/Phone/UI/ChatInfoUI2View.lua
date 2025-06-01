local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local DialogueTreeUtil = CS.Common.Utils.DialogueTreeUtil
local Color = CS.UnityEngine.Color
local V2 = CS.UnityEngine.Vector2

local ConfigMgr = GameTableDefine.ConfigMgr
local ChatUI = GameTableDefine.ChatUI
local GameUIManager = GameTableDefine.GameUIManager
local PhoneUI = GameTableDefine.PhoneUI
local RewardUI = GameTableDefine.RewardUI
local ResourceManger = GameTableDefine.ResourceManger
local ChatEventManager = GameTableDefine.ChatEventManager
local BuyCarManager = GameTableDefine.BuyCarManager
local BuyHouseManager = GameTableDefine.BuyHouseManager
local CompanysUI = GameTableDefine.CompanysUI
local ChatEventUI = GameTableDefine.ChatEventUI
local GameClockManager = GameTableDefine.GameClockManager
local CompanyMode = GameTableDefine.CompanyMode
local ActorEventManger = GameTableDefine.ActorEventManger
local ChooseUI = GameTableDefine.ChooseUI

local ChatInfoUI2View = Class("ChatInfoUI2View", UIView)

local TYPE_HE = 1
local TYPE_ME = 2
local TYPE_CHOOSE = 3
local TYPE_PRESS = 4
local TYPE_NOTE = 5
local TYPE_LEAVE = 6
local TYPE_EMPTY = 7
local TYPE_HAPPENS = 8
local TYPE_EXP = 9
local typeName = {"he", "me", "empty", "press", "note", "leave", "empty", "notice", "exp"}

function ChatInfoUI2View:ctor()
    self.super:ctor()
    self.mData = {}
    self.mSaveSize ={}
end

function ChatInfoUI2View:OnExit()
    self.super:OnExit(self)
    if self.dialogueTreeController and not self.dialogueTreeController:IsNull() then
        self.dialogueTreeController:StopDialogue()
    end
    EventManager:RegEvent("EVENT_CHECK_BOSS_IN_SCENCE", nil)
    EventManager:RegEvent("EVENT_CHECK_PROBABILITY_SELECTOR", nil)
    EventManager:RegEvent("EVENT_SAVE_PROBABILITY_SELECTOR", nil)

    self:StopTimer()
    --self:CloseDialogueTree()
end

function ChatInfoUI2View:OnEnter()
    local anim = self.m_uiObj:GetComponent("Animation")
    AnimationUtil.Play(anim, "Chat_open")
    -- function()
    --     -- self.initUIComplete = true
    --     -- self:UpdateList2Tail(true)
    -- end
    self:SetButtonClickHandler(self:GetComp("RootPanel/up/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
  
    self:CreateTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/up/time", currH..":"..currM)
    end, true, true)

    self.inputTxt = self:GetComp("RootPanel/down/input/dialog/desc", "TMPLocalization")
    self.sendButton = self:GetComp("RootPanel/down/input/sendBtn", "Button")
    self.sendButton.interactable = false
    self:SetButtonClickHandler(self.sendButton, function()
        local data = self.mData[#self.mData]
        data.txtType = TYPE_ME
        self:UpdateList2Tail(true)
        self:SaveReocrd(data.uid)
        self.sendButton.interactable = false
        if self.m_subtitlesRequestInfo then
            self.m_subtitlesRequestInfo:Continue()
        end
    end)
    self:InitList()
    self:SetDialogueStartedHandler(handler(self, self.OnDialogueStarted))
    self:SetDialoguePausedHandler(handler(self, self.OnDialoguePaused))
    self:SetDialogueFinishedHandler(handler(self, self.OnDialogueFinished))
    self:SetDialogueSubtitlesRequestHandler(handler(self, self.OnSubtitlesRequest))
    self:SetDialogueMultipleChoiceRequestHandler(handler(self, self.OnMultipleChoiceRequest))
    EventManager:RegEvent("EVENT_CHECK_BOSS_IN_SCENCE", function(PhoneChatBossCheckTask)
        local uid = PhoneChatBossCheckTask.uid.value
        local isNoteData, _, data = self:CheckNoteData({uid = uid})
        if isNoteData then
            PhoneChatBossCheckTask.bossInScene.value = data[2]
        else
            local isActive ,cfg = ActorEventManger:CheckEventOnActivity(PhoneChatBossCheckTask.bossId.value)
            PhoneChatBossCheckTask.bossInScene.value = isActive
            self:SaveReocrd({uid,isActive})
        end
    end)
    
    EventManager:RegEvent("EVENT_CHECK_PROBABILITY_SELECTOR", function(ProbabilitySelector)
        local uid = ProbabilitySelector.uid.value
        local isNoteData, _, data = self:CheckNoteData({uid = uid})
        if isNoteData then
            ProbabilitySelector.recordId.value = data[2]
        end
    end)

    EventManager:RegEvent("EVENT_SAVE_PROBABILITY_SELECTOR", function(ProbabilitySelector)
        local uid = ProbabilitySelector.uid.value
        local index = ProbabilitySelector.recordId.value
        local isNoteData, _, data = self:CheckNoteData({uid = uid})
        if isNoteData then
            return
        end
        self:SaveReocrd({uid, index})
    end)
end

function ChatInfoUI2View:InitList()
    self.mList = self:GetComp("RootPanel/mid/AppList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.mData
    end)
    self:SetListItemNameFunc(self.mList, function(index)
        local data = self.mData[index + 1]
        local name = typeName[data.txtType]
        if name then
            return name
        end
        return "empty"
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
    self:SetListItemSizeFunc(self.mList, handler(self, self.UpdateItemSize))
end

function ChatInfoUI2View:UpdateItemSize(index)
    local dataIndex = index + 1
    local data = self.mData[dataIndex]
    if #self.mData < 1 or data.txtType == TYPE_CHOOSE then
        return {x = 0, y = 0}
    end
    if not self.mSaveSize[dataIndex] then
        local template = self.mList:GetItemTemplate(typeName[data.txtType])
        local trt = template:GetComponent("RectTransform")
        local originSize = trt.rect
        if not data.txt or data.txt == ""  then
            return {x = originSize.width, y = originSize.height}
        end

        local content = self:GetComp(template, "message/desc", "TMPLocalization")
        local diffHeight, fontX, fontY = 0, 0, 0
        if content then
            local crt = content:GetComponent("RectTransform")
            local newSize = content:GetPreferredValues(data.txt, crt.rect.width, crt.rect.height)
            fontX = math.min(crt.rect.width, newSize.x)
            fontY = math.max(crt.rect.height, newSize.y)
            diffHeight = math.max(0, newSize.y - crt.rect.height)

            -- local perfectHeight = content:GetPreferredHeight()
            -- diffHeight = math.max(0, perfectHeight - crt.rect.height)
        end

        self.mSaveSize[dataIndex] = 
        {
            x = originSize.width,
            y = originSize.height + diffHeight,
            font_x = fontX,
            font_y = fontY,
            -- offset_x = 0,
            -- offset_y = diffHeight,
            -- originSize = originSize,
        }
    end
    return self.mSaveSize[dataIndex]
end

function ChatInfoUI2View:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.mData[index]
    if not data then
        return
    end

    local SetHead =function()
        local headImage = self:GetComp(go, "node/head", "Image")
        local headName = data.txtType == TYPE_ME and "head_" .. LocalDataManager:GetBossSkin() or data.head
        self:SetSprite(headImage, "UI_BG", headName)
    end

    if data.txtType == TYPE_HE or data.txtType == TYPE_ME or data.txtType == TYPE_NOTE then --文本
        SetHead()
        local txt = self:SetText(go, "message/desc", data.txt)
        local size = self:UpdateItemSize(index - 1)
        txt.transform.sizeDelta = {
            x = size.font_x,
            y = size.font_y
        }
        if data.specialType and data.txtType == TYPE_HE then
            self:GetGo(go, "message"):SetActive(data.specialType == 0)
            self:GetGo(go, "waiting"):SetActive(data.specialType == 1)
        end
    elseif data.txtType == TYPE_PRESS then
        SetHead()

        local resIcon = "icon_chat_reward_" .. ResourceManger:GetResType(data.happens[1][3])
        local headImage = self:GetComp(go, "message/icon", "Image")
        self:SetSprite(headImage, "UI_Common", resIcon)

        local button = self:GetComp(go, "message", "Button")
        button.interactable = index == #self.mData


        self:SetButtonClickHandler(button, function()
            --如果是加钱
            local success = function()
                ResourceManger:AddCash(data.happens[1][4], nil, function()
                    EventManager:DispatchEvent("FLY_ICON", nil, data.happens[1][3], data.happens[1][4])
                    self:UpdateList2Tail(nil, {txtType = TYPE_HAPPENS, txt = data.txt})
                    self:SaveReocrd(data.uid)
                    if self.m_subtitlesRequestInfo then
                        self.m_subtitlesRequestInfo:Continue()
                    end
                    GameSDKs:TrackForeign("cash_event", {type_new = 1, change_new = 0, amount_new = tonumber(data.happens[1][4]) or 0, position = "["..tostring(data.uid).."]号手机聊天活动绿钞"})
                    GameSDKs:TrackForeign("corp_reward", { num = tonumber(data.happens[1][4]) or 0})
                end, true)
            end

            if data.happens[1][3] == 2 then
                ChooseUI:EarnCash(data.happens[1][4], success)
            else
                ResourceManger:Add(data.happens[1][4], data.happens[1][3], nil, function()
                    EventManager:DispatchEvent("FLY_ICON", nil, data.happens[1][3], data.happens[1][4])
                    self:UpdateList2Tail(nil, {txtType = TYPE_HAPPENS, txt = data.txt})
                    self:SaveReocrd(data.uid)
                    if self.m_subtitlesRequestInfo then
                        self.m_subtitlesRequestInfo:Continue()
                    end
                end, true)
            end
        end)

        self:GetGo(go, "message/checked"):SetActive(index ~= #self.mData)
    elseif data.txtType == TYPE_HAPPENS then
        self:SetText(go, "message/desc", data.txt)
    elseif data.txtType == TYPE_EXP then
        SetHead()
        local button = self:GetComp(go, "message", "Button")
        self:SetButtonClickHandler(button, function()
            GameTableDefine.ShopUI:OpenAndTurnPage(2000)
        end)
        if self.m_subtitlesRequestInfo then
            self.m_subtitlesRequestInfo:Continue()
        end
    end
end

function ChatInfoUI2View:StartDialogue(asset)
    if not asset then
        return
    end
    
    local path = "Assets/Res/UI/DT_assets/"..asset .. ".asset"
    GameResMgr:AInstantiateObjectAsyncManual(path, self, function(dialogTree)
        if not self.m_uiObj or self.m_uiObj:IsNull() then
            return
        end
        self.isRecording = nil
        local variables = dialogTree.blackboard.variables
        for k,v in pairs(variables or {}) do
            if k == "EnableRecord" then
                self.isRecording = v.value
            elseif k == "bossName" then
                -- v.value = LocalDataManager:GetBossName()
                --CS.NodeCanvas.Framework.IBlackboardExtensions.SetVariableValue(dialogTree.blackboard, k, LocalDataManager:GetBossName())
                v.value = LocalDataManager:GetBossName()
            elseif k == "ifFirstTime" then
                local isFirst = ChatEventManager:FirstTime(self.selectData.id)
                v.value = isFirst
            end
        end
        self.dialogueTreeController = self.m_uiObj:GetComponent("DialogueTreeController")
        self.dialogueTreeController:StartDialogue(dialogTree, self.dialogueTreeController, nil)
    end)
end

function ChatInfoUI2View:Refresh(data)
    if data then
        self.localData = Tools:CopyTable(data.localData)
        self.selectData = data

        local cfg = ConfigMgr.config_chat[data.id]
        self:SetText("RootPanel/up/name", "[".. GameTextLoader:ReadText("TXT_NPC_"..cfg.head) .. "]")
    end
    -- local path = "Assets/Res/UI/DT_assets/"..self.cfg.DTasset..".asset"
    -- GameResMgr:AInstantiateObjectAsyncManual(path, self, function(dialogTree)
    --     local dialogueTreeController = self.m_uiObj:GetComponent("DialogueTreeController")
    --     dialogueTreeController:StartDialogue(dialogTree, dialogueTreeController, nil)
    -- end)
    
    if self:ReplayLocalData() then
        if not self.selectData.currIsNew then
            return
        end
        -- local lastRecord = self.selectData.localData[#self.selectData.localData] or {}
        -- local cfg = ConfigMgr.config_chat_condition[self.selectData.id]
        -- if lastRecord.done and lastRecord.id == self.selectData.id and not lastRecord.clear and cfg.timeLimit ~= 0 then
        --     return
        -- end
        self.globalData = nil
        self.noteData = {}
        self.conditionId = self.selectData.id
        self.cfg = ConfigMgr.config_chat[self.selectData.id]
        self:StartDialogue(self.cfg.DTasset)
    end
end

function ChatInfoUI2View:ReplayLocalData()
    if not self.localData or #self.localData == 0 then
        return true
    end
    local data = table.remove(self.localData, 1)
    local chatId = ConfigMgr.config_chat_condition[data.id].chatId
    self.globalData = data
    self.noteData = data.steps
    self.conditionId = data.id
    self.cfg = ConfigMgr.config_chat[chatId]
    self:StartDialogue(self.cfg.DTasset)
end

function ChatInfoUI2View:OnDialogueStarted(dialogueTree)
    print("OnDialogueStarted")
end

function ChatInfoUI2View:OnDialoguePaused(dialogueTree)
    print("OnDialoguePaused")
end

function ChatInfoUI2View:OnDialogueFinished(dialogueTree)
    print("OnDialogueFinished")
    if self.globalData and self.globalData.done then
        self:Refresh()
    else
        -- self:UpdateList2Tail(nil, {txtType = TYPE_LEAVE})
        self.done = true
        ChatUI:UpdateChat(self.conditionId, self.noteData, self.done, self.isRecording, self.lastChatTextId)
        ChatUI:GetView():Invoke("CheckCurrentIndex")
    end
end

function ChatInfoUI2View:OnSubtitlesRequest(SubtitlesRequestInfo)
    --print("OnSubtitlesRequest", SubtitlesRequestInfo.statement.text, SubtitlesRequestInfo.statement.head, SubtitlesRequestInfo.statement.name)
    local statement = SubtitlesRequestInfo.statement
    local isNoteData, isEnd = self:CheckNoteData(statement) 
    local topData = self.mData[#self.mData]
    local data = {}
    data.specialType = statement.specialType
    data.uid = statement.uid
    if statement.textID and statement.textID ~= "" and not isNoteData then
        self.lastChatTextId = statement.textID
    end
    if topData and topData.specialType == 1 then -- 移除上一个阶段的“输入中”
        table.remove(self.mData, #self.mData)
    end

    self.waitStatement = nil
    if data.specialType == 1 then -- 输入中
        data.head = self.mData[1].head
        data.txtType = self.mData[1].txtType
        -- self.waitStatement = SubtitlesRequestInfo
    elseif data.specialType == 2 then -- 奖励
        data = self:FormatAwardsInfo(statement, isNoteData)
    else
        data.txt = statement.text
        data.head = statement.head
        data.name = statement.name
        data.txtType = (statement.head and statement.head ~= "") and TYPE_HE or ((isNoteData or statement.autoFiniash) and TYPE_ME or TYPE_CHOOSE)
    end
    if isEnd then
        self:UpdateList2Tail(true, data)
    else
        table.insert(self.mData, data)
    end
    if not isNoteData and statement.autoFiniash then
        self:SaveReocrd(data.uid)
    end

    if statement.autoFiniash or isNoteData then
        if data.txtType == TYPE_PRESS then
            if not isNoteData then
                ResourceManger:Add(data.happens[1][3], data.happens[1][4], nil, function()
                    EventManager:DispatchEvent("FLY_ICON", nil, data.happens[1][3], data.happens[1][4])
                    table.insert(self.mData, {txtType = TYPE_HAPPENS, txt = data.txt})
                end, true)
            else
                table.insert(self.mData, {txtType = TYPE_HAPPENS, txt = data.txt})
            end
        end
        self.m_subtitlesRequestInfo = nil
        SubtitlesRequestInfo:Continue()
    else
        self.m_subtitlesRequestInfo = SubtitlesRequestInfo
    end
end

function ChatInfoUI2View:OnMultipleChoiceRequest(MultipleChoiceRequestInfo)
    print("OnMultipleChoiceRequest")
    local inputRoot = self:GetGo("RootPanel/down/input")
    local chooseRoot = self:GetGo("RootPanel/down/choose")
    inputRoot:SetActive(false)
    chooseRoot:SetActive(true)
    for k,v in pairs(MultipleChoiceRequestInfo.options or {}) do
        local isNoteData, isEnd = self:CheckNoteData(k) 
        if isNoteData then
            inputRoot:SetActive(true)
            chooseRoot:SetActive(false)
            MultipleChoiceRequestInfo.SelectOption(v)
            return
         end

        local btn = self:GetComp(chooseRoot, "BTN_"..v, "Button")
        self:SetText(btn.gameObject, "desc", k.text)
        self:SetButtonClickHandler(btn, function()
            self:SaveReocrd(k.uid)
            inputRoot:SetActive(true)
            chooseRoot:SetActive(false)
            MultipleChoiceRequestInfo.SelectOption(v)
            -- self:GetHappen(true, self.cfg.happens[data.happenIndex], data, self.cfg,
            -- function()
            --     --self:Next(data.next[2])
            --     self:SetNext(data.next[2], true)
            --     chooseRoot:SetActive(false)
            -- end,
            -- function()
            --     --self:Next(data.next[1])
            --     self:SetNext(data.next[1], true)
            --     chooseRoot:SetActive(false)
            -- end)
        end)
    end
end

function ChatInfoUI2View:UpdateList2Tail(newItem, newData)
    if newData then
        table.insert(self.mData, newData)
    end
    local last = self.mData[#self.mData]
    if last and last.txtType == TYPE_CHOOSE then
        self.sendButton.interactable = true
        self.inputTxt.text = last.txt
    else
        self.inputTxt.text = ""
        self.sendButton.interactable = false
    end
    if not self.mList or self.mList:IsNull() then
        return
    end
    self.mList:UpdateData(newItem or false)
    self:ScrollTo(self.mList, #self.mData)
end

function ChatInfoUI2View:FormatAwardsInfo(statement, isNoteData)
    if not statement then
        return
    end
    local happensFun = function(h)
        return Tools:SplitString(h, ":", true)
    end

    local otherFun = function(o)
        local other = {}
        if not tonumber(h) then -- chance:id
            other = Tools:SplitString(h, ":", true)
        else --id,id
            table.insert(other, {1, tonumber(h)})
        end
        return other
    end

    local happens = statement.happens
    local other = statement.parameters
    local cfg = {happens = {}, other = {}, txtType = TYPE_HAPPENS, specialType = statement.specialType, uid = statement.uid}
    for i = 0, happens.Count - 1 do
        table.insert(cfg.happens, happensFun(happens[i]))
    end

    for i = 0, other.Count - 1 do
        local v = other[i]
        if tonumber(v) then
            table.insert(cfg.other, {100, tonumber(v)})
        else
            table.insert(cfg.other, happensFun(v))
        end
    end

    if cfg.happens[1][1] == 2 and cfg.happens[1][2] == 1 then -- 红包送钞票和钻石
        cfg.txtType = TYPE_PRESS
        cfg.head = self.mData[1].head
    elseif cfg.happens[1][1] == 3 then -- 触发新的聊天事件
        cfg.txtType = TYPE_EMPTY
    elseif cfg.happens[1][1] == 5 then -- 召唤土豪不需要显示
        cfg.txtType = TYPE_EMPTY
    elseif cfg.happens[1][1] == 6 then--公司经验
        cfg.txtType = TYPE_EXP
        cfg.head = "head_hr"
    end
    cfg.txt = self:GetHappen(true, cfg, isNoteData)
    return cfg
end

function ChatInfoUI2View:GetHappen(accept, data, isNoteData)--这个要保存手机和场景的对话是相同的
    --1下载 2奖励 3参加事件 4直接奖励
    local finish = function(success)
        -- if success then
        --     if acceptCallBack then acceptCallBack() end
        -- else
        --     if rejectCallBack then rejectCallBack() end
        -- end
    end

    local happen = data.happens[1]
    if not happen then--本身没有数据,保存,结束
        finish(true)
        return
    end

    if not accept then--拒绝参加
        print("拒绝参加事件")
        finish(false)
        return
    end

    local downApp = function(appId)
        finish(true)
        PhoneUI:DonwApp(appId)
        GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_CHAT_UI)
        self:DestroyModeUIObject()
    end

    local joinEvent = function(eventId, costCash)
        print("参加事件"..eventId)
        local joinEvent = function(eventId)
            local other = data.other
            local total = 0
            local last = 0
            for k,v in pairs(other) do
                total  = total + v[1]
                v[1] = v[1] + last
                last = v[1]
            end
            local curr = math.random(0, total)
            local happenChat = nil
            for k,v in pairs(other) do
                if curr <= v[1] then
                    happenChat = v[2]
                    break
                end
            end
            -- CompanyMode:AciveManagerBusinessTrip()
            ChatEventManager:ConditionToStart(8, happenChat)
        end

        ResourceManger:SpendCash(costCash, nil, function(isEnough)
            joinEvent(eventId)
            finish(isEnough)
        end)
    end

    local giveGift = function(mainType, typeId, NumOrId)
        --mainType 1钞票钻石资源         2物质资源
        -- typeId  1[2钱 3钻石]         2[1车 2房 3公司]
        -- num   配置在other
        local unlockId = nil
        if mainType == 2 then--解锁资源
            local isUnlock = {
                function(id)
                    return BuyCarManager:IsCarUnlock(id)
                end,
                function(id)
                    return BuyHouseManager:IsHouseUnlock(id)
                end,
                function(id)
                    return CompanysUI:IsCompanyUnlock(id)
                end
            }
            local isUnlock = isUnlock[typeId]
            local other = data.other

            self:randomArray(other)

            for k,v in pairs(other) do
                if not isUnlock(v) then
                    unlockId = v
                    break
                end
            end

            if not unlockId then--可解锁的都解锁了,就使用备用的
                mainType = 1
                typeId = 2
                NumOrId = 2000
            end
            RewardUI:Refresh(mainType, typeId, NumOrId or unlockId, function()
                finish(true)
            end)
        else
            local txt = GameTextLoader:ReadText("TXT_REWARD_" .. string.upper(ResourceManger:GetResType(typeId)) .. "_INCOME")
            txt = string.format(txt, NumOrId)
            return txt
        end
    end

    local giveGiftSoon = function(mainType, typeId, NumOrId)
        --mainType 1钞票钻石资源 2物质资源
        --1[2钱 3钻石]  2[1车 2房 3公司]
        -- num   配置在other
        local unlockId = nil
        if mainType == 2 then--解锁资源
            local isUnlock = {
                function(id)
                    return BuyCarManager:IsCarUnlock(id)
                end,
                function(id)
                    return BuyHouseManager:IsHouseUnlock(id)
                end,
                function(id)
                    return CompanysUI:IsCompanyUnlock(id)
                end
            }
            local isUnlock = isUnlock[typeId]
            self:randomArray(data.other)
            for k,v in pairs(data.other) do
                if not isUnlock(v[2]) or (isNoteData and isUnlock(v[2])) then
                    unlockId = v[2]
                    break
                end
            end

            -- if not unlockId then--可解锁的都解锁了,就使用备用的
            --     ResourceManger:Add(2, 5000, nil, nil, true)
            --     EventManager:DispatchEvent("FLY_ICON", nil, 2, NumOrId)
            --     finish(true)
            --     return "奖励现金"
            -- end
        end
        --如果是给资源,调用相关方法
        --如果是解锁,返回必要的数据
        if mainType == 1 then
            ResourceManger:Add(typeId, NumOrId, nil, nil, true)
            EventManager:DispatchEvent("FLY_ICON", nil, typeId, NumOrId)
            local txt = GameTextLoader:ReadText("TXT_REWARD_" .. ResourceManger:GetResIcon(typeId) .. "_DESC")
            txt = string.format(txt, NumOrId)
            return txt
        elseif mainType == 2 then
            if typeId == 1 then
                BuyCarManager:IsCarUnlock(NumOrId, true)
            elseif typeId == 2 then
                BuyHouseManager:IsHouseUnlock(NumOrId, true)
            elseif typeId == 3 then
                local companyId = NumOrId or unlockId
                if not isNoteData then
                    CompanysUI:IsCompanyUnlock(companyId, true)
                end
                -- finish(true)
                if companyId then
                    local companyName = GameTextLoader:ReadText("TXT_COMPANY_C"..companyId.."_NAME")
                    local txt = GameTextLoader:ReadText("TXT_REWARD_COMPANY")
                    txt = string.format(txt, companyName)
                    return txt
                end
            end
        end
        -- finish(true)
    end

    local activeBossEvent = function()
        local other = data.other
        if not other[1][2] or isNoteData then
            return 
        end
        ActorEventManger:ActiveEventByChat(other[1][2])
    end

    local buttonFunction = {downApp, giveGift, joinEvent, giveGiftSoon, activeBossEvent}
    local choose = buttonFunction[happen[1]]
    if choose then
        return choose(happen[2], happen[3], happen[4])
    else
        return nil
    end

    --return buttonFunction[happen[1]](happen[2], happen[3], happen[4])
end

function ChatInfoUI2View:randomArray(array)
    for i = #array, 1, -1 do
        local tempSave = array[i]
        local randomIndex = math.random(1,i)
        array[i] = array[randomIndex]
        array[randomIndex] = tempSave
    end
end

function ChatInfoUI2View:CheckNoteData(statement, cb)
    if not statement then
        return
    end
    local id = statement.uid
    for k,v in ipairs(self.noteData or {}) do
        local isEnd =  k == #self.noteData and #self.localData == 0
        if type(v) == "number" and id == v then
            statement.NoteData = true
            if cb then cb() end
            return true, isEnd
        elseif type(v) == "table" and id == v[1] then
            statement.NoteData = true
            if cb then cb() end
            return true, isEnd, v
        end
    end
    statement.NoteData = false
    return false, true
    -- if statement.NoteData then
    --     self:UpdateList2Tail(true)
    -- end
    -- statement.NoteData = false
end

function ChatInfoUI2View:SaveReocrd(step)
    if not step or (type(step) == "number" and step <= 0) or (type(step) == "table" and step[1] <= 0) then
        return
    end
    table.insert(self.noteData, step)
    ChatUI:UpdateChat(self.conditionId, self.noteData, self.done, self.isRecording, self.lastChatTextId)
end

return ChatInfoUI2View