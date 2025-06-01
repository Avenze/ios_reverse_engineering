local QuestManager = GameTableDefine.QuestManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloorMode = GameTableDefine.FloorMode
local CompanyMode = GameTableDefine.CompanyMode
local ResMgr = GameTableDefine.ResourceManger
local QuestUI = GameTableDefine.QuestUI
local MainUI = GameTableDefine.MainUI
local StarMode = GameTableDefine.StarMode
local CityMode = GameTableDefine.CityMode
local ActorEventManger = GameTableDefine.ActorEventManger
local QuestMgr = GameTableDefine.QuestManager
local BuyCarManager = GameTableDefine.BuyCarManager
local CountryMode = GameTableDefine.CountryMode
local HouseMode = GameTableDefine.HouseMode

local LOCAL_QUEST_DATA = "quest"
local LOCAL_QUEST_PROGRESS = "quest_progress"

local localData = nil
local cfgData = nil

local QUEST_NORMAL = 1        -- 任务为进行状态(无用)
local QUEST_REWARD = 2      -- 任务为领奖状态
local QUEST_INVALID = 3     -- 任务为完成状态并关闭（

function QuestManager:Init()
    localData = self:GetLocalData()
    self:FixeFromOld()
end

function QuestManager:Clear()
    localData = nil
    cfgData = nil
end

function QuestManager:FixeFromOld()
    if not localData or not localData[1] then
        return
    end
    --对旧的存档方式进行修改
    local newData = {}
    for k,v in pairs(localData) do
        if v.status > QUEST_NORMAL then
            newData["ID"..k] = {}
            newData["ID"..k].status = v.status
        end
    end
    LocalDataManager:Save(LOCAL_QUEST_DATA, newData)
end

function QuestManager:GetProgress(update)
    local currData = LocalDataManager:GetDataByKey(LOCAL_QUEST_PROGRESS)
    if not currData.curr then
        currData.curr = 0
    end

    if update then
        currData.curr = currData.curr + 1
        LocalDataManager:WriteToFile()
    end
    return currData.curr
end

function QuestManager:GetLocalData()
    if localData then
        return localData
    end
    localData = LocalDataManager:GetDataByKey(LOCAL_QUEST_DATA)
    self:FixeFromOld()
   return localData
end

function QuestManager:IsQuestClaimable(questStatus)
    return tonumber(questStatus) == QUEST_REWARD 
end

function QuestManager:IsQuestInvalid(questStatus)
    return tonumber(questStatus) == QUEST_INVALID 
end

function QuestManager:IsQuestFinished(questStatus)
    return tonumber(questStatus) >= QUEST_REWARD 
end

function QuestManager:IsQuestValid(questStatus)--任务未完成
    return tonumber(questStatus) < QUEST_INVALID 
end

function QuestManager:GetQuestCondition(cfg, getDesc)
    local currValue = 0
    local desc = nil
    if cfg.company_quality then
        currValue = CompanyMode:GetCompanySameQualityNumber(cfg.company_quality)
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_INVITE")
            local quality = GameTextLoader:ReadText("TXT_COMPANY_QUALITY_"..cfg.company_quality)
            desc = string.format(desc, cfg.task_num, quality)
        end
    elseif cfg.company_lv then
        currValue = CompanyMode:GetNumByLevel(cfg.company_lv[1], cfg.company_lv[2])
        if getDesc then
            if cfg.company_lv[2] == 1 then
                desc = GameTextLoader:ReadText("TXT_QUEST_COMPANY_LEVELUP1")
                desc = string.format(desc, cfg.task_num, cfg.company_lv[1])
            else
                desc = GameTextLoader:ReadText("TXT_QUEST_COMPANY_LEVELUP2")
                local qualityName = GameTextLoader:ReadText("TXT_COMPANY_QUALITY_"..cfg.company_lv[2])
                desc = string.format(desc,cfg.task_num, qualityName, cfg.company_lv[1])
            end
        end
    elseif cfg.target_facility then
        currValue = FloorMode:GetFurnitureNum(cfg.target_facility[1], cfg.target_facility[2])
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_BUY")
            local furName = GameTextLoader:ReadText("TXT_FURNITURES_"..cfg.target_facility[1]..'_'..cfg.target_facility[2].."_NAME")
            desc = Tools:FormatString(desc, cfg.task_num, furName)
        end
    elseif cfg.detail_facility then
        local roomId = FloorMode:GetRoomIdByRoomIndex(cfg.detail_facility[1])
        local roomData = ConfigMgr.config_rooms[roomId] or {}
        currValue = FloorMode:GetRoomFurnitureNum(cfg.detail_facility[2], cfg.detail_facility[3], roomData.room_index)
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_SPECIAL_BUY")
            local room_index_num = cfg.detail_facility[1]:gsub("%D+", "")
            local roomName = GameTextLoader:ReadText("TXT_ROOM_R"..room_index_num.."_NAME")
            local furName = GameTextLoader:ReadText("TXT_FURNITURES_"..cfg.detail_facility[2]..'_'..cfg.detail_facility[3].."_NAME")
            desc = Tools:FormatString(desc, roomName,cfg.task_num, furName)
        end
    elseif cfg.target_employee then-- TXT_QUEST_HIRE
        currValue = FloorMode:GetFurnitureNum(cfg.target_employee[1], cfg.target_employee[2])
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_HIRE")
            local workerName = GameTextLoader:ReadText("TXT_FURNITURES_"..cfg.target_employee[1]..'_'..cfg.target_employee[2].."_NAME")
            desc = Tools:FormatString(desc, cfg.task_num, workerName)
        end
    elseif cfg.detail_employee then
        local roomId = FloorMode:GetRoomIdByRoomIndex(cfg.detail_employee[1])
        local roomData = ConfigMgr.config_rooms[roomId] or {}
        currValue = FloorMode:GetRoomFurnitureNum(cfg.detail_employee[2], cfg.detail_employee[3], roomData.room_index)
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_SPECIAL_HIRE")
            local room_index_num = cfg.detail_employee[1]:gsub("%D+","")
            local roomName = GameTextLoader:ReadText("TXT_ROOM_R"..room_index_num.."_NAME")
            local workerName = GameTextLoader:ReadText("TXT_FURNITURES_"..cfg.detail_employee[2]..'_'..cfg.detail_employee[3].."_NAME")
            desc = Tools:FormatString(desc, roomName, cfg.task_num, workerName)
        end
    elseif cfg.room_index_num then--房间的id
        currValue = 0
        if FloorMode:IsUnlockRoomByIndexNum(cfg.room_index_num) then
            currValue = 1 
        end
        
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_UNLOCK")
            local room_index_num = cfg.room_index_num:gsub("%D+","")
            local roomName = GameTextLoader:ReadText("TXT_ROOM_R"..room_index_num.."_NAME")
            desc = string.format(desc, roomName)
        end
    elseif cfg.star_target then
        currValue = StarMode:GetStar()
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_RISE")
            desc = string.format(desc, cfg.task_num)
        end
    elseif cfg.building_target then--要求数值上下一个大楼id必须比上一个大
        currValue = 0
        local currBuilding = CityMode:GetCurrentBuilding() or 0
        if currBuilding >= cfg.building_target then currValue = 1 end
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_MOVE")
            local name = GameTextLoader:ReadText("TXT_BUILDING_B"..cfg.building_target.."_NAME")
            desc = string.format(desc, name)
        end
    elseif cfg.total_rent then
        currValue = FloorMode:GetTotalRent()
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_STAR_efficiency")
            desc = string.format(desc, cfg.task_num)
        end
    elseif cfg.event then
        currValue = ActorEventManger:EventFinishTimes(cfg.event)
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_GUIDE")
            desc = string.format(desc, cfg.task_num)
        end
    elseif cfg.buy_car then
        currValue = BuyCarManager:OwnCar(cfg.buy_car)
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_CAR")
            local carName = GameTextLoader:ReadText("TXT_CAR_C"..cfg.buy_car.."_NAME")
            desc = string.format(desc, cfg.task_num, carName)
        end
    elseif cfg.buy_house then
        currValue = HouseMode:OwnHouse(cfg.buy_house)
        if getDesc then
            desc = GameTextLoader:ReadText("TXT_QUEST_HOUSE")
            local houseName = GameTextLoader:ReadText("TXT_BUILDING_B"..cfg.buy_house.."_NAME")
            desc = string.format(desc, houseName)
        end
    end
    return currValue, desc
end

function QuestManager:GetQuestClaimableNumber()--主要用于红点
    local num = 0
    local cfg = ConfigMgr.config_task
    local localData = self:GetLocalData()

    local currCity = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[CountryMode:GetCurrCountry()]).currBuidlingId or 0
    local type1 = {}
    local type2 = {}
    local type3 = {}
    
    local total = {type1, type2, type3}
    
    for i, v in pairs(cfg or {}) do        
        if #type1 > 0 and #type2 > 0 and #type3 > 0 then
            break
        end           
        if #total[v.task_category] <= 0 then
            local questStatus = localData["ID".. v.id] and localData["ID".. v.id].status or 1            
            if QuestMgr:IsQuestValid(questStatus) and currCity >= v.goal_scene and v.country == CountryMode:GetCurrCountry() then
                local maxValue = v.task_num
                local currValue, questDesc = QuestMgr:GetQuestCondition(v, true)
                if currValue >= maxValue then
                    return 1
                else
                    table.insert(total[v.task_category], {id = v.id})
                end
            end 
        end
    end

    return 0
end


function QuestManager:ClaimReward(id, adDouble)
    local localData = self:GetLocalData()
    local cfg = ConfigMgr.config_task[id]
    local reward = cfg.task_reward

    local callback = function(success)
        if not success then
            return
        end
        if not localData["ID".. id] then
            localData["ID".. id] = {}
        end
        localData["ID".. id].status = QUEST_INVALID
        QuestUI:ShowQuestPanel()
    end
    local rate = adDouble == true and 2 or 1

    local allReward = {}--2:cash, 3:diamond
    allReward[reward[1][1]] = reward[1][2]
    if reward[2] then
        allReward[reward[2][1]] = reward[2][2]
    end

    if allReward[2] then
        ResMgr:AddCash(allReward[2] * rate, ResMgr.EVENT_QUEST_REWARD, callback, true)
        --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
        local type = 1
        local amount = allReward[2] * rate
        local change = 0
        local position = "["..id.."]任务奖励获取"
        GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0, position = position})
    end
    if allReward[3] then
        ResMgr:AddDiamond(allReward[3] * rate, ResMgr.EVENT_QUEST_REWARD, callback, true)
        -- GameSDKs:Track("get_diamond", {get = allReward[3] * rate, left = ResMgr:GetDiamond(), get_way = "任务"..id})
        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "任务"..id, behaviour = 1, num_new = tonumber( allReward[3] * rate)})
        MainUI:RefreshDiamondShop()
    end
    if allReward[6] then
        ResMgr:AddLocalMoney(allReward[6] * rate, ResMgr.EVENT_QUEST_REWARD, callback, nil, true)
         --2024-8-20添加用于伟大建筑的钞票消耗埋点上传
         local type = 2
         local amount = allReward[6] * rate
         local change = 0
         local position = "["..id.."]任务奖励获取"
         GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
    end
    local currValue, desc = self:GetQuestCondition(cfg, true)
    -- GameSDKs:Track("gt_task", {task_id = id, task_name = desc})

    if cfg.task_category == 1 or cfg.task_category == 2 or cfg.task_category == 3 then
        GameSDKs:TrackForeign("mainline_task", {id_new = tonumber(id), type = 1})
    end
    -- 2024-5-29 gxy 运营新增埋点需求,完成主线任务15时触发
    if id == 15 then
        GameSDKs:TrackControl("af", "af,main_task_15", {af_buildingID = 0})
    end
end

function QuestManager:RewardNum(id)
    local cfg = ConfigMgr.config_task[id]
    local reward = cfg.task_reward
    return reward
end