local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
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
local CompanyMode = GameTableDefine.CompanyMode

local SceneChatInfoUIView = Class("SceneChatInfoUIView", UIView)

function SceneChatInfoUIView:ctor()
    self.super:ctor()
    self.mData = {}
    self.answerTime = 0
end

function SceneChatInfoUIView:OnExit()
    self.super:OnExit(self)
    GameTimer:StopTimer(self.__timers[self])
    self.__timers[self] = nil
end

function SceneChatInfoUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("up/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:InitList()
    self:SetButtonClickHandler(self:GetComp("background/next", "Button"), function()
        self:AutoNext()
    end)
    self.__timers = self.__timers or {}
    self.__timers[self] = GameTimer:CreateNewMilliSecTimer(
        100,
        function()
            self:Update(0.1)
        end,
    true)
end

function SceneChatInfoUIView:Refresh(conditionId, data)
    local tempCfg = ConfigMgr.config_chat_condition[conditionId]
    self.conditionId = conditionId

    self.chatId = tempCfg.chatId
    self.cfg = ConfigMgr.config_chat[self.chatId]
    self.chats = self.cfg.chats
    self.allHappens = self.cfg.happens

    self.mData = data.steps and self:split(data.steps, "_", true) or {}
    self.allDones = data.allDones or {}

    local masterCanvas = GameUIManager:GetMasterCanvasObj()
    local masterSize = masterCanvas.transform.sizeDelta
    self.screenWidth = masterSize.x

    local playerType = LocalDataManager:GetBossName()
    local npcType = self.cfg.head
    local npcName = GameTextLoader:ReadText("TXT_NPC_"..npcType)
    self:SetText("background/down/player/name", playerType)
    self:SetText("background/down/NPC/name", npcName)
    local imagePlayer = self:GetComp("background/down/icon_player", "Image")
    local imageNPC = self:GetComp("background/down/icon_NPC", "Image")
    self:SetSprite(imagePlayer, "UI_BG", "icon_"..playerType,nil, true)
    self:SetSprite(imageNPC, "UI_BG", "icon_"..npcType,nil, true)

    self.mList:UpdateData()
    self:ScrollTo(self.mList, 99)
    
    local lastStep = #self.mData > 0 and self.mData[#self.mData] or 1
    table.remove(self.mData, #self.mData)
    self:Next(lastStep)
end

function SceneChatInfoUIView:InitList()
    self.mList = self:GetComp("background/mid/AppList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.mData
    end)
    self:SetListItemNameFunc(self.mList, function(index)
        local data = self.chats[self.mData[index + 1]]

        local typeName = {"he", "me", "empty", "press", "note", "leave", "empty"}
        local name = typeName[data.txtType]
        if name then
            return name
        end

        return "empty"
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
    self:SetListItemSizeFunc(self.mList, handler(self, self.UpdateItemSize))
end

function SceneChatInfoUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.chats[self.mData[index]]
    if data then
        if data.txtType == 1 or data.txtType == 2 or data.txtType == 4 or data.txtType == 5 then--文本


            tran.sizeDelta = setSize

            local txt = self:GetComp(go, "message/desc", "TMPLocalization")
            local txtInfo = GameTextLoader:ReadText("TXT_CHAT_" .. data.txt)
            self:SetText(go, "message/desc", txtInfo)
            local perfectSize = self:GetWidgetSize(txt)
            txt.transform.sizeDelta = {
                x = 480,
                y = perfectSize.height
            }
            ViewUtils:ReseTextSize(txt)
        end

        if data.txtType == 3 then--选择
            local txt = self:GetComp(go, "message/desc", "TMPLocalization")
            local txtInfo = GameTextLoader:ReadText("TXT_CHAT_".. data.txt)
            local chooseDesc = self:split(txtInfo, "_")
            local chooseRoot = self:GetGo("background/down/choose")

            chooseRoot:SetActive(not self.allDones[data.clickIndex])--如何判定一个选项,按钮是否开关

            if not self.allDones[data.clickIndex] then
                self:SetText("background/down/choose/no/desc", chooseDesc[1])
                self:SetText("background/down/choose/yes/desc", chooseDesc[2])
                self:SetButtonClickHandler(self:GetComp(chooseRoot, "yes", "Button"), function()
                    self:GetHappen(true, self.cfg.happens[data.happenIndex], data, self.cfg,
                    function()
                        self:Next(data.next[2])
                        chooseRoot:SetActive(false)
                    end,
                    function()
                        self:Next(data.next[1])
                        chooseRoot:SetActive(false)
                    end)
                end)

                self:SetButtonClickHandler(self:GetComp(chooseRoot, "no", "Button"), function()
                    self:GetHappen(false, self.cfg.happens[data.happenIndex], data, self.cfg,
                    function()
                        self:Next(data.next[1])
                        chooseRoot:SetActive(false)
                    end,
                    function()
                        self:Next(data.next[1])
                        chooseRoot:SetActive(false)
                    end)
                end)
            end
        end
        if data.txtType == 4 then--按钮
            if not self.allDones[data.happenIndex] then
                self:GetHappen(true, self.cfg.happens[data.happenIndex], data, self.cfg,
                    function()
                        self:Next(data.next[2])
                    end,
                    function()--针对场景事件的拒绝按钮
                        self:Next(data.next[1])
                    end
                )
            end
        end
    end
end

function SceneChatInfoUIView:GetHappen(accept, happen, currMessage, cfg, acceptCallBack, rejectCallBack)--这个要保存手机和场景的对话是相同的
    --1下载 2奖励 3参加事件 4发送邀请
    local finish = function(success)
        self.allDones[currMessage.clickIndex] = true
        if success then
            if acceptCallBack then acceptCallBack() end
        else
            if rejectCallBack then rejectCallBack() end
        end
    end

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
            local other = cfg.other
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
            self.joinEvent = true
            CompanyMode:AciveManagerBusinessTrip()
            ChatEventManager:ConditionToStart(8, happenChat)
        end

        ResourceManger:SpendCash(costCash, nil, function(isEnough)
            joinEvent(eventId)
            finish(isEnough)
        end)
    end

    local giveGift = function(mainType, typeId, NumOrId)
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
            local other = cfg.other

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
        end
        RewardUI:Refresh(mainType, typeId, NumOrId or unlockId, function()
            finish(true)
        end)
    end

    local giveInvite = function(eventId, costCash)
        ChatEventUI:Refresh(eventId, costCash,
        function()--accept
            local other = cfg.other
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

            ChatEventManager:ConditionToStart(8, happenChat)
            self.goInvite = true
            finish(true)
        end,
        function()--reject
            --单纯无视它,进入下一步
            self.goInvite = false
            finish(false)
        end,
        function()--consider
            --保存信息,下次打开继续
            --关闭当前界面
            ChatEventManager:UpdateSceneChat(self.mData)
            self:DestroyModeUIObject()
        end)
    end

    local buttonFunction = {downApp, giveGift, joinEvent, giveInvite}
    buttonFunction[happen[1]](happen[2], happen[3], happen[4])
end

function SceneChatInfoUIView:randomArray(array)
    for i = #array, 1, -1 do
        local tempSave = array[i]
        local randomIndex = math.random(1,i)
        array[i] = array[randomIndex]
        array[randomIndex] = tempSave
    end
end

function SceneChatInfoUIView:AutoNext()
    if self.autoNextertfId or self.clickNextId then
        self:Next(self.autoNextId or self.clickNextId)
    end
end

function SceneChatInfoUIView:Next(nextChatId)
    if nextChatId == 5 then
        local temp
    end
    --保存数据
    table.insert(self.mData, nextChatId)

    self.mList:UpdateData()
    self:ScrollTo(self.mList, 99)

    self.autoNextId = nil
    self.clickNextId = nil
    self.waitToAnswer = false
    local data = self.chats[nextChatId]
    local nextIds = data.next
    if nextIds[1] == 0 then--全部结束
        self.canDelete = true
        ChatEventManager:LeaveNPC(self.conditionId, self.goInvite)--有问题...如果只是单纯对话,那么永远都没法完成了
        if self.joinEvent then
            CompanyMode:AciveManagerBusinessTrip()
        end
        self:DestroyModeUIObject()
        return
    end

    local nextData = nil
    for k,v in ipairs(nextIds) do
        nextData = self.chats[v]
        if nextData.waitType == 0 then
            self.autoNextId = v
            self.answerTime = nextData.waitTime or 0
            self.waitToAnswer = true
        elseif nextData.waitType == 1 then
            self.clickNextId = v
        end
    end

end

function SceneChatInfoUIView:Update(dt)
    if not self.waitToAnswer then
        return
    end

    self.answerTime = self.answerTime - dt
    if self.answerTime < 0 then
        self.waitToAnswer = false
        self:AutoNext()
    end
end

function SceneChatInfoUIView:UpdateItemSize(index, vec2)

    local data = self.chats[self.mData[index + 1]]
    local specialSize = {}
    specialSize[6] = 30--离线
    specialSize[7] = 1--空
    specialSize[3] = 1--选择

    if specialSize[data.txtType] then
        return V2(self.screenWidth, specialSize[data.txtType])
    end

    local exampleTxt = self:GetComp("exampleTxt", "TMPLocalization")
    local crt = V2(480,31.68)
    local message = GameTextLoader:ReadText("TXT_CHAT_".. data.txt)
    local real = exampleTxt:GetPreferredValues(message, crt.x, crt.y)
    local size = {}
    size.width = math.min(real.x, crt.x)
    size.height = real.y

    local highIndex = math.floor(real.y / 47.5)
    local realHeigh = highIndex <= 1 and 175 or 90 + highIndex * 40
    return V2(self.screenWidth, realHeigh)
end

function SceneChatInfoUIView:split(str, sep, is_force_number)--Tool复制来的
    assert(str and sep and #sep > 0)
    if #str == 0 then return {} end
    local reg = string.format('[%s]', sep)
    local r = {}
    local _begin = 1
    while _begin <= #str do
        local _end = string.find(str, reg, _begin) or #str + 1
        local i_words = string.sub(str, _begin, _end - 1)
        if is_force_number then
            i_words = tonumber(i_words)
        end
        table.insert(r, i_words)
        _begin = _end + 1
    end
    if string.match(string.sub(str, #str, #str), reg) then table.insert(r, '') end
    return r
end
return SceneChatInfoUIView