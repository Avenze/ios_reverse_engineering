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
local GameClockManager = GameTableDefine.GameClockManager
local CompanyMode = GameTableDefine.CompanyMode

local ChatInfoUIView = Class("ChatInfoUIView", UIView)

function ChatInfoUIView:ctor()
    self.super:ctor()
    self.mData = {}
    self.answerTime = 0
end

function ChatInfoUIView:OnExit()
    self.super:OnExit(self)
    GameTimer:StopTimer(self.__timers[self])
    GameTimer:StopTimer(self.__timers["chatTimeShow"])
    GameTimer:StopTimer(self.__timers["chatShowTime"])
    self.__timers[self] = nil

    ChatUI:UpdateChat(self.conditionId, self.mData, self.canDelete, self.allDones)
end

function ChatInfoUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/up/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:InitList()
    self:SetButtonClickHandler(self:GetComp("RootPanel/down/input/sendBtn", "Button"), function()
        self:AutoNext()
    end)
    self.__timers = self.__timers or {}
    self.__timers["chatTimeShow"] = GameTimer:CreateNewMilliSecTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/up/time", currH..":"..currM)
    end, true, true)
    self.__timers[self] = GameTimer:CreateNewMilliSecTimer(
        100,
        function()
            self:Update(0.1)
        end,
    true)
end

function ChatInfoUIView:Refresh(data)
    self.chatId = data.id
    self.conditionId = data.conditionId
    self.cfg = ConfigMgr.config_chat[data.id]
    self.chats = self.cfg.chats
    self.allHappens = self.cfg.happens

    --self.InputAni = self:GetComp("RootPanel/down/input", "Animation")
    self.inputTxt = self:GetComp("RootPanel/down/input/dialog/desc", "TMPLocalization")
    self.sendButton = self:GetComp("RootPanel/down/input/sendBtn", "Button")

    self.inputTxt.text = ""
    self.sendButton.interactable = false

    local talkerName = GameTextLoader:ReadText("TXT_NPC_"..self.cfg.head)
    self:SetText("RootPanel/up/name", "[".. talkerName .. "]")
    self.mData = data.steps and self:split(data.steps, "_", true) or {}
    self.allDones = data.allDones or {}

    local masterCanvas = GameUIManager:GetMasterCanvasObj()
    local masterSize = masterCanvas.transform.sizeDelta
    self.screenWidth = masterSize.x

    self.mList:UpdateData()
    self:ScrollTo(self.mList, 99)
    
    local lastStep = #self.mData > 0 and self.mData[#self.mData] or 1
    table.remove(self.mData, #self.mData)
    --self:Next(lastStep)
    self:SetNext(lastStep, true)
end

function ChatInfoUIView:InitList()
    self.mList = self:GetComp("RootPanel/mid/AppList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.mData
    end)
    self:SetListItemNameFunc(self.mList, function(index)
        local data = self.chats[self.mData[index + 1]]

        local typeName = {"he", "me", "empty", "press", "note", "leave", "empty", "notice"}
        local name = typeName[data.txtType]
        if name then
            return name
        end

        return "empty"
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
    self:SetListItemSizeFunc(self.mList, handler(self, self.UpdateItemSize))
end

function ChatInfoUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.chats[self.mData[index]]
    if data then
        if data.txtType == 1 or data.txtType == 2 or data.txtType == 4 or data.txtType == 5 then--文本
            local headImage = self:GetComp(go, "node/head", "Image")
            local headName = data.txtType == 2 and LocalDataManager:GetBossSkin() or self.cfg.head
            headName = "head_" .. headName 
            self:SetSprite(headImage, "UI_BG", headName)

            local txt = self:GetComp(go, "message/desc", "TMPLocalization")
            local txtInfo = GameTextLoader:ReadText("TXT_CHAT_".. data.txt)
            self:SetText(go, "message/desc", txtInfo)
            local perfectSize = self:GetWidgetSize(txt)
            txt.transform.sizeDelta = {
                x = 280,
                y = perfectSize.height
            }
            ViewUtils:ReseTextSize(txt)


            if data.txtType == 1 then
                if self.waitChatId and self.mData[index] == self.waitChatId then--当前为最新的一步,且是半自动
                    if self.showTime > 0 then--半自动
                        self:GetGo(go, "message"):SetActive(false)
                        self:GetGo(go, "waiting"):SetActive(true)
                        self.__timers["chatShowTime"] = GameTimer:CreateNewMilliSecTimer(self.showTime * 1000, function()
                            self:GetGo(go, "message"):SetActive(true)
                            self:GetGo(go, "waiting"):SetActive(false)
                            self:ShowEnd(self.waitChatId)
                            self.waitChatId = nil
                        end)
                    else
                        self:ShowEnd(self.waitChatId)
                        self.waitChatId = nil
                    end
                end
            end
        end

        if data.txtType == 3 then--选择
            local txt = self:GetComp(go, "message/desc", "TMPLocalization")
            local txtInfo = GameTextLoader:ReadText("TXT_CHAT_".. data.txt)
            local chooseDesc = self:split(txtInfo, "_")
            local chooseRoot = self:GetGo("RootPanel/down/choose")

            chooseRoot:SetActive(not self.allDones[data.clickIndex])--如何判定一个选项,按钮是否开关

            if chooseRoot.activeSelf then
                self:GetGo("RootPanel/down/input"):SetActive(false)
            end
            self:SetText("RootPanel/down/choose/no/desc", chooseDesc[1])
            self:SetText("RootPanel/down/choose/yes/desc", chooseDesc[2])
            self:SetButtonClickHandler(self:GetComp(chooseRoot, "yes", "Button"), function()
                self:GetGo("RootPanel/down/input"):SetActive(true)

                self:GetHappen(true, self.cfg.happens[data.happenIndex], data, self.cfg,
                function()
                    --self:Next(data.next[2])
                    self:SetNext(data.next[2], true)
                    chooseRoot:SetActive(false)
                end,
                function()
                    --self:Next(data.next[1])
                    self:SetNext(data.next[1], true)
                    chooseRoot:SetActive(false)
                end)
            end)

            self:SetButtonClickHandler(self:GetComp(chooseRoot, "no", "Button"), function()
                self:GetGo("RootPanel/down/input"):SetActive(true)

                self:GetHappen(false, self.cfg.happens[data.happenIndex], data, self.cfg,
                function()
                    --self:Next(data.next[1])
                    self:SetNext(data.next[1], true)
                    chooseRoot:SetActive(false)
                end,
                function()
                    --self:Next(data.next[1])
                    self:SetNext(data.next[1], true)
                    chooseRoot:SetActive(false)
                end)
            end)
        end
        if data.txtType == 4 then--按钮
            local buttonImage = self:GetComp(go, "message/GameObject/Button", "Image")

            
            local getButtonName = function(data)
                if data[1] == 1 then
                    return "btn_reward_car"
                elseif data[1] == 3 then
					return "xxx"
                end
                local reward = {}
                reward[1] = {[2] = "btn_reward_cash", [3] = "btn_reward_diamond"} 
                reward[2] = {[1] = "btn_reward_car", [2] = "btn_reward_house", [3] = "btn_reward_company"}
                
                return reward[data[2]][data[3]]
            end

            local happenData = self.cfg.happens[data.happenIndex]
            local buttonName = getButtonName(happenData)
            self:SetSprite(buttonImage, "UI_Common", buttonName)

            local buttonRoot = self:GetGo(go, "message/GameObject/Button")
            self:SetButtonClickHandler(self:GetComp(buttonRoot, "", "Button"), function()
                self:GetHappen(true, self.cfg.happens[data.happenIndex], data, self.cfg,
                function()
                    buttonRoot:SetActive(false)
                end)
            end)

            buttonRoot:SetActive(not self.allDones[data.clickIndex])
        end
        if data.txtType == 8 then
            if not self.allDones[data.clickIndex] then
                local txt = self:GetHappen(true, self.cfg.happens[data.happenIndex], data, self.cfg)
                self:SetText(go, "message/desc", txt)
            end
        end
    end
end

function ChatInfoUIView:GetHappen(accept, happen, currMessage, cfg, acceptCallBack, rejectCallBack)--这个要保存手机和场景的对话是相同的
    --1下载 2奖励 3参加事件 4直接奖励
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
            local other = cfg.other

            self:randomArray(other)

            for k,v in pairs(other) do
                if not isUnlock(v[2]) then
                    unlockId = v[2]
                    break
                end
            end

            if not unlockId then--可解锁的都解锁了,就使用备用的
                ResourceManger:Add(2, 5000, nil, nil, true)
                EventManager:DispatchEvent("FLY_ICON", nil, 2, NumOrId)
                finish(true)
                return "奖励现金"
            end
        end
        --如果是给资源,调用相关方法
        --如果是解锁,返回必要的数据
        if mainType == 1 then
            ResourceManger:Add(typeId, NumOrId, nil, nil, true)
            EventManager:DispatchEvent("FLY_ICON", nil, typeId, NumOrId)
        elseif mainType == 2 then
            if typeId == 1 then
                BuyCarManager:IsCarUnlock(NumOrId, true)
            elseif typeId == 2 then
                BuyHouseManager:IsHouseUnlock(NumOrId, true)
            elseif typeId == 3 then
                local companyId = NumOrId or unlockId
                CompanysUI:IsCompanyUnlock(companyId, true)
                finish(true)

                local companyName = GameTextLoader:ReadText("TXT_COMPANY_C"..companyId.."_NAME")
                local txt = GameTextLoader:ReadText("TXT_REWARD_COMPANY")
                txt = string.format(txt, companyName)
                return txt
            end
        end
        finish(true)
    end

    local buttonFunction = {downApp, giveGift, joinEvent, giveGiftSoon}
    return buttonFunction[happen[1]](happen[2], happen[3], happen[4])
end

function ChatInfoUIView:RandomOther(other)
    local total = 0
    local last = 0
    for k,v in pairs(other) do
        total = total + v[1]
        v[1] = v[1] + last
        last = v[1]
    end

    local curr = math.random(0, total)
    local result = nil
    for k, v in pairs(other) do
        if curr <= v[1] then
            return v[2]
        end
    end

    return other[1][2]
end

function ChatInfoUIView:randomArray(array)
    for i = #array, 1, -1 do
        local tempSave = array[i]
        local randomIndex = math.random(1,i)
        array[i] = array[randomIndex]
        array[randomIndex] = tempSave
    end
end

function ChatInfoUIView:AutoNext()
    if self.autoNextId then
        self:SetNext(self.autoNextId, true)
    end
end

function ChatInfoUIView:SetNext(nextId, goNow)--在nextId作为下一步显示,并且准备下一步
    self.autoNextId = nil
    self.waitToAnswer = false--等回复
    self.showTime = 0--聊天内容具体出来的时间
    self.waitChatId = nil--等显示
    local data = self.chats[nextId]
    local nextIds = data.next
    if nextIds[1] == 0 then
        self.canDelete = true
        return
    end

    if data.waitType == 3 then
        self.waitChatId = nextId
        self.showTime = data.waitTime or 0
    end

    local nextData = nil
    for k,v in ipairs(nextIds) do--更新下一步
        nextData = self.chats[v]
        if nextData.waitType == 0 then--自动回复
            self.autoNextId = v
            self.answerTime = nextData.waitTime or 0
            self.waitToAnswer = true
        elseif nextData.waitType == 1 then--点击回复
            self.autoNextId = v
        elseif nextData.waitType == 3 then--立刻出来,但是有延迟
            self.autoNextId = v
            self.answerTime = 0
            self.waitToAnswer = true
        end
    end

    if nextData.txtType == 2 and nextData.waitType == 1 then
        self.playerInput = true
        if self.showTime == 0 then
            self:ShowEnd(self.autoNextId)
        end
    else
        self.playerInput = false
        self.inputTxt.text = ""
        self.sendButton.interactable = false
    end

    if goNow then
        table.insert(self.mData, nextId)
        self.mList:UpdateData()
        self:ScrollTo(self.mList, 99)
    end
end

function ChatInfoUIView:ShowEnd(chatId)
    if self.playerInput then
        self.inputTxt.text = GameTextLoader:ReadText("TXT_CHAT_".. self.chats[self.autoNextId].txt)
        self.sendButton.interactable = true
    end
end

function ChatInfoUIView:Update(dt)
    if not self.waitToAnswer then
        return
    end

    self.answerTime = self.answerTime - dt
    if self.answerTime < 0 and self.waitChatId == nil then
        self.waitToAnswer = false
        self:AutoNext()
    end
end

function ChatInfoUIView:UpdateItemSize(index, vec2)

    local data = self.chats[self.mData[index + 1]]
    local specialSize = {}
    specialSize[6] = 30--离线
    specialSize[7] = 1--空
    specialSize[3] = 1--选择
    specialSize[7] = 30--解锁公司

    if specialSize[data.txtType] then
        return V2(self.screenWidth - 210, specialSize[data.txtType])
    end

    local exampleTxt = self:GetComp("exampleTxt", "TMPLocalization")
    local crt = V2(280,31.68)
    local message = GameTextLoader:ReadText("TXT_CHAT_".. data.txt)
    local real = exampleTxt:GetPreferredValues(message, crt.x, crt.y)
    local size = {}
    size.width = math.min(real.x, crt.x)
    size.height = real.y

    local highIndex = math.floor(real.y / 31)
    local realHeigh = highIndex <= 2 and 130 or 95 + highIndex * 27
    return V2(self.screenWidth - 210, realHeigh)
end

function ChatInfoUIView:split(str, sep, is_force_number)--Tool复制来的
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
return ChatInfoUIView