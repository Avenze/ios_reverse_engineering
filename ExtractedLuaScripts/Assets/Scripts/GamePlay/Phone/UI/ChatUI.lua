local ChatUI = GameTableDefine.ChatUI
local PhoneUI = GameTableDefine.PhoneUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local ChatEventManager = GameTableDefine.ChatEventManager

local EventManager = require("Framework.Event.Manager")

local ACTIVE_CHAT = "chat_event"

function ChatUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.APP_CHAT_UI, self.m_view, require("GamePlay.Phone.UI.ChatUIView"), self, self.CloseView)
    return self.m_view
end

function ChatUI:Refresh()
    self:GetView():Invoke("Refresh")
end

function ChatUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_CHAT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function ChatUI:GetActiveChatNum()
    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not save.npc then
        save.npc = {}
    end

    local total = 0
    for k,v in pairs(save.npc) do
        if v and #v > 0 then
            local cfg = ConfigMgr.config_chat[v[1]]
            if cfg then
                total = total + (cfg.title ~= "" and 1 or 0)
            end
        end
    end
    return total
end

function ChatUI:GetActiveChat()
    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    if not save.npc then
        save.npc = {}
    end
    local data = {}
    local isNew = {}
    for k,v in pairs(save.npc) do
        if v and #v > 0 then
            if ConfigMgr.config_chat[v[1]] then
                table.insert(data, v[1])
                isNew[v[1]] = true
            end
        else
            local record = save.npc_record[k]
            if #record > 0 then
                local chatCfg = ConfigMgr.config_chat[record[#record].id]
                if chatCfg then
                    table.insert(data, record[#record].id)
                end
            end
        end
    end
    return data, isNew
end

function ChatUI:GetNpcByConditionId(id)
    if not  ConfigMgr.config_chat_condition[id] then
        return nil
    end
    local chatId = ConfigMgr.config_chat_condition[id].chatId
    return self:GetNpcByChatId(chatId)
end

function ChatUI:GetNpcByChatId(id)
    return ConfigMgr.config_chat[id].head
end

function ChatUI:GetChatLocalData(id)
    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    local head = nil
    if id then
        head = self:GetNpcByConditionId(id) or ""
    end
    if not head then
        return save.npc_record
    end
    if not save.npc_record then
        save.npc_record = {}
    end
    if not save.npc_record[head] then
        save.npc_record[head] = {}
    end
    if save.phoneEvent then
        save.phoneEvent = nil
    end
    return save.npc_record[head]
end

function ChatUI:ClearChatLocalData()
    local hasChange = false
    local record = ChatUI:GetChatLocalData()
    for k,v in pairs(record or {}) do
        for i,re in pairs(v) do
            if re.clear and re.done then
                table.remove(v, i)
                hasChange = true

                if re.id == 118 then
                    ChatEventManager:FirstTime(re.id, true)
                end
            end
        end
    end
    if hasChange then
        LocalDataManager:WriteToFile()
    end
end

function ChatUI:GetNpcLocalData(id)
    local save = LocalDataManager:GetDataByKey(ACTIVE_CHAT)
    local head = self:GetNpcByConditionId(id)
    if not save.npc then
        save.npc = {}
    end
    if not save.npc[head] then
        save.npc[head] = {}
    end
    if save.phoneEvent then
        save.phoneEvent = nil
    end
    return save.npc[head]
end

function ChatUI:FinishChat(conditionId)--完成某事件
    local npc = self:GetNpcLocalData(conditionId)
    if npc[1] == conditionId then
        table.remove(npc, 1)
        LocalDataManager:WriteToFile()
        -- if not done then
        --     return
        -- end
        PhoneUI:Refresh()
        MainUI:SetPhoneNum()
    end
end

function ChatUI:UpdateChat(conditionId, steps, done, isRecording, lastChatId)
    local isNewdata = true
    local npcRecord = self:GetChatLocalData(conditionId)
    local data = {id = conditionId, steps = steps, done = done, last = lastChatId}
    if not isRecording then
        data.clear =true
    end
    for i,record in ipairs(npcRecord or {}) do
        if record.id == conditionId then
            -- if done and not isRecording then
            --     isNewdata = false
            --     npcRecord[i] = nil
            -- else
                isNewdata = false
                npcRecord[i] = data
            -- end
            LocalDataManager:WriteToFile()
            break
        end
    end
    if isNewdata then
        table.insert(npcRecord, data)
        LocalDataManager:WriteToFile()
    end
    self:FinishChat(conditionId)
    -- self:Refresh()
end

function ChatUI:ActiveChat(conditionId)--激活某事件
    local npc = self:GetNpcLocalData(conditionId)
    for k, v in pairs(npc) do
        if v == conditionId then --不允许激活重复的
            return false
        end
    end
    table.insert(npc, conditionId)
    LocalDataManager:WriteToFile()
    --如果手机打开,则刷星
    if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.PHONE_UI) then
        PhoneUI:Refresh()
    end
    MainUI:SetPhoneNum()
    return true
end