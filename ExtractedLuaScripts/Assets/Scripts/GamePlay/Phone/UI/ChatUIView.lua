local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ConfigMgr = GameTableDefine.ConfigMgr
local ChatInfoUI2 = GameTableDefine.ChatInfoUI2

local ChatInfoUI = GameTableDefine.ChatInfoUI
local ChatUI = GameTableDefine.ChatUI
local GameClockManager = GameTableDefine.GameClockManager
local ChatEventManager = GameTableDefine.ChatEventManager

local ChatUIView = Class("ChatUIView", UIView)

function ChatUIView:ctor()
    self.super:ctor()
end

function ChatUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/up/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:CreateTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/up/time", currH..":"..currM)
    end, true, true)

    self:InitList()
    --获取当前激活的时间id
    self.mData = self:GetChatData()
    self.mList:UpdateData()
end

function ChatUIView:GetChatData()
    local cfg = ConfigMgr.config_chat_condition
    local data, isNew = ChatUI:GetActiveChat()
    local result = {}
    for k,cdId in pairs(data) do
        local data = ChatUI:GetChatLocalData(cdId)
        local record = data[#data] or {}
        local chatcfg = ConfigMgr.config_chat[cfg[cdId].chatId]
        local item = {id = cfg[cdId].chatId, localData = data, conditionId = cdId, currIsNew = isNew[cdId]}
        local tId = chatcfg.title or ""
        if (record.last and not isNew[cdId]) or tId == "" then
            tId = record.last or ""
        end
        item.title = tId ~= "" and GameTextLoader:ReadText(tId) or ""
        table.insert(result, item)
        if self.m_currData and self.m_currData.id == item.id and self.m_currData.conditionId ~= self.m_currData.conditionId then
            self.m_selectIndex = #result
        end
    end
    return result
end

function ChatUIView:Refresh()
    self.m_id = nil
    self.m_selectIndex = nil
    self.mData = self:GetChatData()
    self.mList:UpdateData()
end

function ChatUIView:CheckCurrentIndex()
    self.mData = self:GetChatData()
    if not self.m_selectIndex then
        return
    end
    ChatInfoUI2:Refresh(self.mData[self.m_selectIndex])
end

function ChatUIView:OnExit()
    self.super:OnExit(self)
    self:StopTimer()
end

function ChatUIView:InitList()
    self.mList = self:GetComp("RootPanel/ChatList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.mData
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
end

function ChatUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local data = self.mData[index]
    local chatId = data.id
    local currData = ConfigMgr.config_chat[chatId]
    if currData then
        local name = GameTextLoader:ReadText("TXT_NPC_".. currData.head)
        self:SetText(go, "name", name .. (data.isold and "_old" or ""))
        self:SetText(go, "desc", data.title)

        local spriteImage = self:GetComp(go, "bg/head/image", "Image")
        local headName = "head_" .. currData.head
        self:SetSprite(spriteImage, "UI_BG", headName)
        -- local headName = {"azhen", "mom", "tuhao"}
        -- for k,v in pairs(headName) do
        --     local canUnlock = (v == currData.head)
        --     self:GetGo(go, "bg/head/headImage/" .. v):SetActive(canUnlock)
        -- end

        local record =  data.localData[#data.localData] or {}
        self:GetGo(go, "bg/head/notRead"):SetActive(record.id ~= data.conditionId and currData.title ~= "")
        self:GetGo(go, "bg/Finished"):SetActive(record.id == data.conditionId or currData.title == "")

        local button = self:GetComp(go,"bg", "Button")
        self:SetButtonClickHandler(button, function()
            local success = ChatEventManager:ConditionToStart(9, data.conditionId)
            if success then
                self.mData = self:GetChatData()
            end
            ChatInfoUI2:Refresh(self.mData[index])
            self.m_currData = self.mData[index]
        end)
        if self.autoOpenId == data.conditionId then
            self.autoOpenId = nil
            ChatInfoUI2:Refresh(data)
        end
    end
end

return ChatUIView
