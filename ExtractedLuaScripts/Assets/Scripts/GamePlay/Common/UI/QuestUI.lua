

local QuestUI = GameTableDefine.QuestUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local StarMode = GameTableDefine.StarMode
local QuestManager = GameTableDefine.QuestManager
local CompanyMode = GameTableDefine.CompanyMode
local UIView =  require("GamePlay.Common.UI.QuestUIView")
local EventManager = require("Framework.Event.Manager")
local CountryMode = GameTableDefine.CountryMode

local QUEST_NORMAL = 1        -- 任务为进行状态
local QUEST_REWARD = 2      -- 任务为领奖状态
local QUEST_INVALID = 3     -- 任务为完成状态并关闭（

function QuestUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.QUEST_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function QuestUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.QUEST_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function QuestUI:ShowQuestPanel()
    local type1 = {}
    local type2 = {}
    local type3 = {}
    
    local total = {type1, type2, type3}
    local progressValue = 0

    local currCity = LocalDataManager:GetDataByKey("city_record_data").currBuidlingId

    local cfg = ConfigMgr.config_task
    local localData = QuestManager:GetLocalData()
    for i, v in pairs(cfg or {}) do
        if #type1 > 0 and #type2 > 0 and #type3 > 0 then
            break
        end
        if v.country == CountryMode:GetCurrCountry() then
               
                
            if #total[v.task_category] <= 0  then
                local questStatus = localData["ID".. v.id] and localData["ID".. v.id].status or 1
                if QuestManager:IsQuestValid(questStatus) then
                    if currCity >= v.goal_scene or v.country ~= 1 then
                        --local resIcon = ResMgr:GetResIcon(v.task_reward[1])
                        local reward = v.task_reward
                        local maxValue = v.task_num
                        local currValue, questDesc = QuestManager:GetQuestCondition(v, true)
                        table.insert(total[v.task_category], {id = v.id, desc = questDesc, reward = reward, currValue = currValue, maxValue = maxValue, enable = questStatus == 2})
                    end
                else
                    --完成的任务添加统计计数
                    progressValue = progressValue + v.progress_value
                end
            end
        end 
    end

    local currProgress = QuestManager:GetProgress()
    progressValue = progressValue - currProgress * ConfigMgr.config_global.quest_each_progress

    local data = {type1[1], type2[1], type3[1]}
    self:GetView():Invoke("ShowQuestPanel", data)
    self:GetView():Invoke("ShowProgress", self:GetCurrProgress(), progressValue)
end

function QuestUI:GetShowData()
    local type1 = {}
    local type2 = {}
    local type3 = {}
    local total = {type1, type2, type3}
    local progressValue = 0

    local currCity = LocalDataManager:GetDataByKey("city_record_data").currBuidlingId

    local cfg = ConfigMgr.config_task
    local localData = QuestManager:GetLocalData()
    for i, v in ipairs(cfg or {}) do
        if #type1 > 0 and #type2 > 0 and #type3 > 0 then
            break
        end
        if #total[v.task_category] <= 0 then
            local questStatus = localData["ID".. v.id] and localData["ID".. v.id].status or 1
            if QuestManager:IsQuestValid(questStatus) then
                if currCity >= v.goal_scene then
                    --local resIcon = ResMgr:GetResIcon(v.task_reward[1])
                    local reward = v.task_reward
                    local maxValue = v.task_num
                    local currValue, questDesc = QuestManager:GetQuestCondition(v, true)
                    table.insert(total[v.task_category], {id = v.id, desc = questDesc, reward = reward, currValue = currValue, maxValue = maxValue, enable = questStatus == 2})
                end
            else
                --完成的任务添加统计计数
                progressValue = progressValue + v.progress_value
            end
        end
    end

    return progressValue, type1, type2, type3
end

function QuestUI:GetProgressReward()
    --当前进度加一
    StarMode:StarRaise(1, true)
    QuestManager:GetProgress(true)
end

function QuestUI:GetCurrProgress()
    --记录当前奖励获取到那一步了
end