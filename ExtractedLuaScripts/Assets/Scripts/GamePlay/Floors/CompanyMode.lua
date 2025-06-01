local Bus = require "CodeRefactoring.Actor.Actors.BusNew"
local UIView = require("Framework.UI.View")

---@class CompanyMode
local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local CountryMode = GameTableDefine.CountryMode
local GameClockManager = GameTableDefine.GameClockManager
local TimerMgr = GameTimeManager
local EventManager = require("Framework.Event.Manager")
local CompanysUI = GameTableDefine.CompanysUI
local OfflineRewardUI = GameTableDefine.OfflineRewardUI
local OfflineManager = GameTableDefine.OfflineManager
local ChatEventManager = GameTableDefine.ChatEventManager
local ResourceManger = GameTableDefine.ResourceManger
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local ActorManager = GameTableDefine.ActorManager

local GameObject = CS.UnityEngine.GameObject

-- local ROOMS_COMPANY = "company_in_rooms"
--data[roomId] = companyId
local COMPANY_INVITE_SAVE = "company_invite_save"
local CURR_GUIDE = "guide_data"

local interval = 1000
local lastUpdateTime = 0

local expTime = 1000
local lastExpTime = 0
local managerRoomGoData = nil

local satisfiedTime = 10000
local lastSatisfiedTime = 0

function CompanyMode:Init()
    self.mData = LocalDataManager:GetDataByKey(CountryMode.company_in_rooms)
    self.inviteData = LocalDataManager:GetDataByKey(COMPANY_INVITE_SAVE)
    self.maxCompany = {}
    --self:CheckMaxCompany()
    lastUpdateTime = TimerMgr:GetDeviceTimeInMilliSec() + 2000
    managerRoomGoData = nil

    --self:refreshTypeCount()

    -- local offlineTime = OfflineRewardUI:OfflineTime()
    -- --给每一个公司一定的离线经验
    -- local data = self:GetData()
    -- for k,v in pairs(data or {}) do
    --     local expAdd = self:RoomExpLess(k) * offlineTime
    --     if not v.currExp then
    --         v.currExp = 0
    --     end

    --     v.currExp = v.currExp + expAdd
    -- end
    --self:RefreshAZhenMessage()
end

-- function CompanyMode:CheckMaxCompany()--只要现场有满级的公司,就会触发...感觉没必要
--     for k,v in pairs(self.inviteData.companyLv or {}) do
--         local companyId = tonumber(string.sub(k, 3))
--         local isMax = self:CompanyLvMax(companyId)
--         if isMax then
--             ChatEventManager:ConditionToStart(2,companyId)

--         end
--     end
-- end

function CompanyMode:Clear()
    self.mData = nil
    self.inviteData = nil
    self.offlineRewardBefor = nil
    self.typeCount = nil
    self.companyType = {}
    self.maxCompany = nil
    managerRoomGoData = nil
end

function CompanyMode:Update()
    local curTime = TimerMgr:GetDeviceTimeInMilliSec()
    if curTime - lastUpdateTime >= interval then
        lastUpdateTime = curTime
        self:CheckCompanyState()
        self:CheckManagerRoomOnWork()
        self:CheckBossOnWork()
    end

    if curTime - lastExpTime >= expTime then
        lastExpTime = curTime
        self:UpdateCompanyExp()
    end

    if curTime - lastSatisfiedTime >= satisfiedTime then
        lastSatisfiedTime = curTime
        --self:UpdateCompanySatisfy()
    end

    if not self.offlineRewardBefor then--之后挪到update外,之前树妖是因为self:GetData,以及离线等,有些东西没准备好
        self.offlineRewardBefor = true
        --local offlineTimeList , timePass = OfflineRewardUI:OffTimePassSecond()--单位秒
        local timePass = OfflineManager.m_offline
        if timePass > 0 then
            --给每一个没到期的公司一定的离线经验
            local data = self:GetData()
            for k,v in pairs(data or {}) do
                local companyId = self:CompIdByRoomIndex(k)
                if self:IsCompanyInContract(companyId) then -- 先判断是否在合约内, 是的话计算离线收益
                    local expAdd = self:RoomExpLess(k) * timePass
                    if not v.currExp then
                        v.currExp = 0
                    end
                    v.currExp = v.currExp + expAdd * 0.2
                end
            end
        end
    end
end

function CompanyMode:GetData()
    if not self.mData then
         self:Init()
    end
    return self.mData
end

function CompanyMode:GetBuffReward(sameNum)
    -- local total = {0, 0.1, 0.2, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25}
    -- return total[sameNum]
    return 0
end

function CompanyMode:GetCompanyImprove(companyId)--之前同属性加成
    -- local currType = self.companyType[companyId]
    -- local sameNum = self.typeCount[currType]
    -- return 1 + self:GetBuffReward(sameNum)
    return 1
end

-- function CompanyMode:refreshCompanyType()
--     local companyCfg = ConfigMgr.config_company

--     self.companyType = {}--就是为了计算这个--companyId, currType

--     for k, v in pairs(self.mData) do
--         local currCfg = companyCfg[v.company_id].company_label
--         local max = 0
--         for index, currType in pairs(currCfg) do
--             local currMax = self.typeCount[max] or 0
--             local currCount = self.typeCount[currType] or 0
--             if currMax < currCount then
--                 max = currType
--             end
--         end

--         self.companyType[v.company_id] = max
--     end

-- end

function CompanyMode:DispatchEff(companyId)
    local haveEff = false
    local companyCfg = ConfigMgr.config_company[companyId]
    for index, currType in pairs(companyCfg["company_label"..GameConfig:GetLangageFileSuffix()]) do
        for companyId, companyType in pairs(self.companyType) do
            if currType == companyType and self.typeCount[currType] > 1 then
                haveEff = true
                local roomIndex = self:GetRoomIndexByCompanyId(companyId)
                EventManager:DispatchEvent("SHOW_TYPE_EFF", roomIndex, currType, self.typeCount[currType])
            end
        end
    end

    return haveEff
end

-- function CompanyMode:refreshTypeCount(changeCompanyId)--增加或者减少某个公司的id,减少计算量
--     if not self.typeCount then--就是为了计算这个
--         self.typeCount = {}--typeId:num
--     end

--     local changetypeCount = function(labels, change, default)
--         for index, currType in pairs(labels) do
--             if self.typeCount[currType] then
--                 self.typeCount[currType] = self.typeCount[currType] + change
--             else
--                 self.typeCount[currType] = default
--             end
--         end
--     end

--     local companyCfg = ConfigMgr.config_company

--     if changeCompanyId then
--         local change = -1--减去
--         if self:IsCompanyInContract(changeCompanyId) then
--             change = 1--增加
--         end

--         changetypeCount(companyCfg[changeCompanyId].company_label, change, change > 0 and 1 or 0)
--     else
--         for k, v in pairs(self.mData) do
--             changetypeCount(companyCfg[v.company_id].company_label, 1, 1)
--         end
--     end

--     --self:refreshCompanyType()
-- end

function CompanyMode:GetCompanyExp(companyId)--如果正在招募的,获取当前的,如果没有,则返回保存的
    local roomIndex = self:GetRoomIndexByCompanyId(companyId)
    if roomIndex then
        return self.mData[roomIndex].currExp
    end
    local currExp = self.inviteData["companyExp"] and self.inviteData["companyExp"]["ID"..companyId] or 0
    return currExp and currExp or 0
end

function CompanyMode:RenewCompany(roomIndex, companyId, workTime)
    if not  self.mData[roomIndex] then
        return
    end

    self.mData[roomIndex].time = TimerMgr:GetCurrentServerTime() + workTime
    GameSDKs:TrackControlCheckData("af", "af,corp_renew_2", {})
end

function CompanyMode:IsRoomSatisfy(roomIndex, refresh)
    local companyId = self:CompIdByRoomIndex(roomIndex)

    if not companyId then
        return false--初始默认位不满意,引入相应公司会重新计算
    end

    if not self.mData[roomIndex] then
        self.mData[roomIndex] = {}
    end

    local result = self.mData[roomIndex].satisfy

    if result == nil or refresh then
        local satisfy = self:checkRoomSatisfy(roomIndex)
        result = satisfy
        self.mData[roomIndex].satisfy = satisfy

        local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
        if satisfy then
            EventManager:DispatchEvent("COMPANY_HAPPY",companyId, roomId)
        end
    end
    
    return result
end

--function CompanyMode:RefreshAZhenMessage()
--    local roomId = nil
--    local satisfy = false
--    local checkSatisfy = function(companyId, roomIndex)
--        roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
--        satisfy = self:IsRoomSatisfy(roomIndex, true)
--        if satisfy then
--            EventManager:DispatchEvent("COMPANY_HAPPY",companyId, roomId)
--        else
--            EventManager:DispatchEvent("COMPANY_ANGRY",companyId, roomId)
--        end
--    end
--    for k,v in pairs(self.mData or {}) do
--        checkSatisfy(v.company_id, k)
--    end
--end

function CompanyMode:InviteCompany(roomIndex, companyId, workTime, cash_cost)
    if not  self.mData[roomIndex] then
        self.mData[roomIndex] = {}
    end
    self.mData[roomIndex].leaveCompany = nil

    self.mData[roomIndex].company_id = companyId
    self.mData[roomIndex].roomIndexNum = roomIndex
    self.mData[roomIndex].time = TimerMgr:GetCurrentServerTime() + workTime
    local saveLv = self.inviteData["companyLv"] and self.inviteData["companyLv"]["ID"..companyId] or nil
    self.mData[roomIndex].level = saveLv and saveLv or ConfigMgr.config_company[companyId].levelBegin
    local saveExp = self.inviteData["companyExp"] and self.inviteData["companyExp"]["ID"..companyId] or 0
    self.mData[roomIndex].currExp = saveExp and saveExp or 0
    self.mData[roomIndex].workerName = {}
    
    local currConfig = ConfigMgr.config_company[companyId]

    -- GameSDKs:Track("com_introduction", {com_id = companyId, com_name = GameTextLoader:ReadText("TXT_COMPANY_C"..companyId.."_NAME"),
    --                                         com_grade = GameTextLoader:ReadText("TXT_COMPANY_QUALITY_" .. currConfig.company_quality),
    --                                         int_type = cash_cost == 0 and "reward" or "cash",
    --                                         cost_money = cash_cost}--初始为1级,所以这里减1,在第一次升级后显示的就是1
    -- )

    if roomIndex == "Office_5" then
        local guideSave = LocalDataManager:GetDataByKey(CURR_GUIDE)
        guideSave["invite5"] = true
        --K117  为了确保跳过引导也能正常出现主线故事入口，提前刷新一次
        if MainUI.m_view then
            MainUI.m_view:RefreshMainLinePanel(GameStateManager:IsInFloor())
        end
    end

    ChatEventManager:ConditionToStart(1, companyId)
    
    MainUI:RefreshQuestHint()
    MainUI:RefreshCashEarn()
    MainUI:RefreshStarState()--引进公司会改变星级吗???

    local satisfy = self:IsRoomSatisfy(roomIndex, true)--经常需要用到,而且计算量不少,所以存起来,每次可能改变时再重新计算
    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)

    if satisfy then
        EventManager:DispatchEvent("COMPANY_HAPPY",companyId, roomId)
    else
        EventManager:DispatchEvent("COMPANY_ANGRY",companyId, roomId)
    end
    --同类型公式buff暂时关闭
    --self:refreshTypeCount(companyId)
    local haveEff = false--self:DispatchEff(companyId)
    
    --刷新界面悬浮图标
    FloorMode:RefreshFloorSceneById(FloorMode:GetRoomIdByRoomIndex(roomIndex))

    --保存经验,等级等信息
    local companyQuality = ConfigMgr.config_company[companyId].company_quality
    if self.inviteData["qualityNum"] == nil then
        self.inviteData["qualityNum"] = {}
    end
    if self.inviteData["qualityNum"]["QU"..companyQuality] == nil then
        self.inviteData["qualityNum"]["QU"..companyQuality] = 0
    end
    
    if self.inviteData["companyLv"] == nil then
        self.inviteData["companyLv"] = {}
    end

    if self.inviteData["companyLv"]["ID"..companyId] == nil then
        self.inviteData["companyLv"]["ID".. companyId] = self.mData[roomIndex].level
        MainUI:RefreshCollectionHint()
    end

    self.inviteData["qualityNum"]["QU"..companyQuality] = self.inviteData["qualityNum"]["QU"..companyQuality] + 1
    --self.inviteData["companyLv"]["ID".. companyId] = self.mData[roomIndex].level

    EventManager:DispatchEvent("INVITE_COMPANY", companyId)

    LocalDataManager:WriteToFile()

    --EventManager:DispatchEvent("INVITE_COMPANY",companyId, haveEff)
end

function CompanyMode:GetRoomIndexByCompanyId(companyId)
    local allData = {}
    for k, v in pairs(self.mData) do
        if v.company_id == companyId then
            return k
        end
    end

    return nil
end

--通过公司Id检测这个公司在所以地区是否已经被招募
function CompanyMode:CheckCompanyAlreadyExists(companyId)     
    for k,v in pairs(ConfigMgr.config_country) do
        local string = "company_in_rooms" .. CountryMode.SAVE_KEY[v.id]
        -- if v.id == 1 or nil then
        --     string = "company_in_rooms"
        -- else
        --     string = "company_in_rooms" .. v.id
        -- end        
        for i,o in pairs(LocalDataManager:GetDataByKey(string)) do
            if o.company_id == companyId then
                return true
            end
        end 
    end
    return false
end

function CompanyMode:FireCompany(roomIndex, roomId, fireTye)--取消合约
    local companyId = self:CompIdByRoomIndex(roomIndex)
    
    if not self.mData[roomIndex] then
        return
    end
    
    local currData = self.mData[roomIndex]
    -- if self:CompanyLvUp(companyId, true) then
    --     --获取升级奖励
    --     GameTableDefine.CompanyLvUpUI:GetReward(companyId, currData.level)
    -- end

    if not self.inviteData["companyExp"] then
        self.inviteData["companyExp"] = {}
    end
    self.inviteData["companyExp"]["ID"..companyId] = currData.currExp

    FloorMode:GetScene():DismissEmployee(roomId)
    self.mData[roomIndex] = nil

    EventManager:DispatchEvent("COMPANY_FIRE", companyId)

    MainUI:RefreshCashEarn()
    --self:refreshTypeCount(companyId)
    --2024-11-18fy添加，解除公司合约时的埋点增加
    local corplvl = self:GetCompanyLevel(companyId)
    local isMax = self:CompanyLvMax(companyId)
    GameSDKs:Track("corp_checkout", {id = tonumber(companyId) or 0, type = tonumber(fireTye) or 0, level = tonumber(corplvl) or 0, max = isMax})
end

function CompanyMode:IsCompanyInContract(companyId)
    local roomIndex = self:GetRoomIndexByCompanyId(companyId)
    if not roomIndex then
        return false
    end

    -- local data = self.mData[roomIndex]
    -- return data.leaveCompany and false or true
    local data = FloorMode:GetAllRoomsLocalData()
    local leave = data[roomIndex].leaveCompany
    return leave == nil
end

function CompanyMode:CompIdByRoomIndex(roomIndex)
    local data = self:GetData()--self.mData[roomIndex] or {}
    local data = data[roomIndex]
    if data and data.company_id then
        return data.company_id
    end
end

function CompanyMode:CompanyExist(roomIndex)
    local data = self:GetData()
    return data[roomIndex]

    -- if data[roomIndex] and TimerMgr:GetCurrentServerTime() <= data[roomIndex].time then
    --     return data[roomIndex]
    -- end
end

function CompanyMode:GetCompanyemployee_skin(roomIndex, employeeIndex)
    -- if true then
    --     return "BeiDaiNan_3"
    -- end
    local data = self:GetData()
    if not data[roomIndex] then
        return
    end
    local cfg = ConfigMgr.config_company[data[roomIndex].company_id]
    local skinIndex = employeeIndex or math.random(1, #cfg.employee_appearance)
    skinIndex = skinIndex%#cfg.employee_appearance
    if skinIndex == 0 then
        skinIndex = #cfg.employee_appearance
    end
    local skinId = cfg.employee_appearance[skinIndex]
    local prefab = ConfigMgr.config_character[skinId].prefab
    return prefab --, "Assets/Res/Prefabs/character/" .. prefab .. ".prefab"
end

function CompanyMode:CheckCompanyExpState(roomIndex)--因为存档结构,用roomIndex更方便,companyId反过来却无法获得roomIndex只能遍历
    local companyId = self:CompIdByRoomIndex(roomIndex)

    if not companyId then
        return false,0--无公司
    end

    if self:CompanyLvMax(companyId) then
        return false,3--已经满级
    end

    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    if not self:CheckCompanyWorkState(gameH, gameM, companyId) then
        return false,1--下班
    end

    if FloorMode:IsRoomBroken(roomIndex) then
        return false,2--待维修
    end

    if not self:IsCompanyInContract(companyId) then
        return false,3--解约
    end
        
    return true,99--其他
end

function CompanyMode:GetEmployeeData(roomIndex)
    local result = {}
    local companyId = self:CompIdByRoomIndex(roomIndex)
    if not companyId then
        return result
    end

    local toSave = false
    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
    local roomData = FloorMode:GetScene():GetRoomRootGoData(roomId) or {}
    for i, employee in pairs(roomData.employee or {}) do
        if employee then
            if not self.mData[roomIndex].workerName then
                self.mData[roomIndex].workerName = {}
            end

            local allName = self.mData[roomIndex].workerName
            local configName = ConfigMgr.config_character_name
            local lang = GameLanguage:GetCurrentLanguageID()
            local data = {name = "", change = employee:GetMoodChange(), mood = employee:GetMood(), moodState = employee:GetMoodState()}
            if type(allName[i]) ~= "table" or (type(allName[i]) == "table" and allName[i][1] == nil) then
                allName[i] = {}
                allName[i][1] = math.random(1, #configName.first)
                allName[i][2] = math.random(1, #configName.second)
                toSave = true
            end
            data.name = GameTextLoader:ReadText(configName.first[allName[i][1] or 1])
            if lang == "cn" or lang == "tc" then
                data.name = data.name..GameTextLoader:ReadText(configName.second[allName[i][2] or 1])
            end
            -- print(data.name, allName[i].first, allName[i].second)
            table.insert(result, data)
        end
    end

    if toSave then
        LocalDataManager:WriteToFile()
    end

    return result
end

function CompanyMode:EmployeesExpAdd(roomIndex,ignoreMood)
    local companyId = self:CompIdByRoomIndex(roomIndex)
    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
    if not companyId then
        return 0,0
    end

    local improve = ConfigMgr.config_global.employee_improve_exp[1] --{40, 70, 90, 999}
    local rate = ConfigMgr.config_global.employee_improve_exp[2]--{0.5, 0.7, 1, 1.2}
    local getImproveRate = function(mood)
        for i,v in ipairs(improve) do
            if mood <= v then
                return rate[i]
            end
        end
        return 1.2
    end

    local workerAdd = ConfigMgr.config_global.employee_base_exp--20
    local currExp = 0--经验增加
    local totalExp = 0--
    local roomData = FloorMode:GetScene():GetRoomRootGoData(roomId) or {}
    for i, employee in pairs(roomData.employee or {}) do
        if employee then
            if ignoreMood then
                currExp = currExp + workerAdd
            else
                local isExHappy = employee:IsHighMoodBuff()
                if isExHappy then
                    currExp = currExp + workerAdd * 2
                else
                    currExp = currExp + workerAdd * getImproveRate(employee:GetMood())
                end
            end

            totalExp = totalExp + workerAdd
        end
    end

    return currExp, totalExp
end

function CompanyMode:RoomExpLess(roomIndex)--离线给予的经验
    local companyId = self:CompIdByRoomIndex(roomIndex)

    if not companyId then
        return 0
    end

    local basCompany = ConfigMgr.config_company[companyId].expBasic
    local basEmployee = ConfigMgr.config_global.employee_base_exp
    local lessRate = ConfigMgr.config_global.employee_improve_exp[2][1]--0.5

    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
    --local roomData = FloorMode:GetScene():GetRoomRootGoData(roomId)
    local totalEmployees = FloorMode:GetRoomFurnitureNum(10001, 1, roomIndex)

    local total = basCompany + totalEmployees * basEmployee * lessRate
    local sameTypeImprove = self:GetCompanyImprove(companyId)

    return sameTypeImprove * total
end

function CompanyMode:checkRoomSatisfy(roomIndex, companyId, countryId)
    local roomData
    if companyId then
        if countryId then
            roomData = LocalDataManager:GetDataByKey("rooms" .. CountryMode.SAVE_KEY[countryId])
            roomData = roomData[roomIndex]
        else
            roomData = LocalDataManager:GetDataByKey(CountryMode.rooms)
            roomData = roomData[roomIndex]
        end        
    else
        companyId = self:CompIdByRoomIndex(roomIndex)    
        roomData = FloorMode:GetCurrRoomLocalData(roomIndex)
    end
    if not companyId then
        return true
    end
  
    local cfg_company = ConfigMgr.config_company[companyId] or {}

    local checkEnough = function(furnitureId, level)
        local defResult = furnitureId == 10001 and true or false
        for i,v in pairs(roomData.furnitures) do
            if v.id  == furnitureId then
                if furnitureId == 10001 then--办公室不同处理
                    if v.level == 0 then
                        --未解锁的不管
                    elseif v.level < level then
                        return false--一张办公桌不满足就变红
                    end
                elseif v.level >= level then
                    return true--一张其他设施满足就变绿
                end
            end
        end

        return defResult
    end

    local lvData = nil
    for k,v in pairs(cfg_company.facility_requirement) do
        lvData = ConfigMgr.config_furnitures_levels[v]
        if not checkEnough(lvData.furniture_id, lvData.level) then
            return false
        end
    end

    return true
end

function CompanyMode:RoomExpAdd(roomIndex,ignoreMood)
    
    local companyId = self:CompIdByRoomIndex(roomIndex)
     
    if not companyId then
        return 0
    end

    local basicAdd = ConfigMgr.config_company[companyId].expBasic
    local employeeExp,employeeExpTotal = self:EmployeesExpAdd(roomIndex,ignoreMood)
     --2025-2-25获取房间中的CEO加成
     local ceoExpAdd = 1
     local ceoIncomeAdd = 1
     if GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
         local haveCeoId = GameTableDefine.CEODataManager:GetCEOByRoomIndex(roomIndex)
         if haveCeoId then
            local furLvl = GameTableDefine.CEODataManager:GetCEOFurnitureLevelByRoomIndex(roomIndex)
            local ceoLvl = GameTableDefine.CEODataManager:GetCEOLevel(haveCeoId)
            ceoIncomeAdd, ceoExpAdd = GameTableDefine.CEODataManager:GetCEOBuffAddValue(haveCeoId)
            local curDeskConfig = ConfigMgr.config_ceo_furniture_level[furLvl]
            if curDeskConfig then
                local furLevelEnough = curDeskConfig.table_ceo_limit>=ceoLvl
                if not furLevelEnough then
                    ceoIncomeAdd = ((ceoIncomeAdd - 1) * curDeskConfig.table_debuff) + 1
                    ceoExpAdd = ((ceoExpAdd - 1) * curDeskConfig.table_debuff) + 1
                end
            end
         end
     end
    local add = math.floor((basicAdd + employeeExp) * ceoExpAdd)
    return add, employeeExp/employeeExpTotal
    --exp/totalexp计算员经验的增长速率
end

-- --某个不同国家的房间中的公司加经验
-- function CompanyMode:SoPsRoomExpAdd(countryId, roomIndex)
--     local string
--     if countryId == 1 or nil then
--         string = "company_in_rooms"
--     else
--         string = "company_in_rooms" .. countryId
--     end
--     local data = LocalDataManager:GetDataByKey(string)
--     local companyId = data.roomIndex.company_id       
--     local basicAdd = ConfigMgr.config_company[companyId].expBasic


--     local employeeExp,employeeExpTotal = self:EmployeesExpAdd(roomIndex)


--     ----------------------
    
--     local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
--         roomIndex = self:RoomIndexNumber2RoomIndex(roomIndex)
--         if self.m_allRoomsIdInBuilding then
--             return self.m_allRoomsIdInBuilding[roomIndex]
--         end
        
--     if not companyId then
--         return 0,0
--     end

--     local improve = ConfigMgr.config_global.employee_improve_exp[1] --{40, 70, 90, 999}
--     local rate = ConfigMgr.config_global.employee_improve_exp[2]--{0.5, 0.7, 1, 1.2}
--     local getImproveRate = function(mood)
--         for i,v in ipairs(improve) do
--             if mood <= v then
--                 return rate[i]
--             end
--         end
--     end

--     local workerAdd = ConfigMgr.config_global.employee_base_exp--20
--     local currExp = 0--经验增加
--     local totalExp = 0--
--     local roomData = FloorMode:GetScene():GetRoomRootGoData(roomId) or {}
--     for i, employee in pairs(roomData.employee or {}) do
--         if employee then
--             local isExHappy = employee:IsHighMoodBuff()
--             if isExHappy then
--                 currExp = currExp + workerAdd * 2
--             else
--                 currExp = currExp + workerAdd * getImproveRate(employee:GetMood())
--             end

--             totalExp = totalExp + workerAdd
--         end
--     end

--     return currExp, totalExp

--     ----------------------
--     --实际增加,最少增加
--     local improve = self:GetCompanyImprove(companyId)

--     local add = math.floor((basicAdd + employeeExp) * improve)
--     return add, employeeExp/employeeExpTotal

-- end

function CompanyMode:CompanyExpProgress(roomIndex)
    local data = self.mData[roomIndex]
    if not data then
        return 0
    end
    
    local currExp = data.currExp or 0
    local totalExp = ConfigMgr.config_company[data.company_id] or {}
    local currLv = data.level
    totalExp = totalExp.expMax[currLv] or 10000

    local result = currExp / totalExp
    result = result > 1 and 1 or result

    return result
end

function CompanyMode:RoomAddExp(roomIndex, exp)
    local data = self:GetData()
    local currData = data[roomIndex]

    if currData then
        local currConfig = ConfigMgr.config_company[currData.company_id]
        if not currData.currExp then
            currData.currExp = 0
        end

        if not currData.level then
            currData.level = ConfigMgr.config_company[currData.company_id].levelBegin
            self.inviteData[currData.company_id .."level"] = currData.level
        end
       
        currData.currExp = currData.currExp + exp

        local maxExp = currConfig.expMax[currData.level < currConfig.levelMax and currData.level or currConfig.levelMax - 1]
        if currData.level < currConfig.levelMax and currData.currExp > maxExp then
            --currData.currExp = maxExp
            self.maxCompany[currData.company_id .. "_" .. currData.level] = true
            local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
            FloorMode:GetScene():InitRoomGo(roomId)
        end
    end
end

function CompanyMode:CompanyLvMax(companyId)
    if not self.inviteData or not self.inviteData.companyLv then
        return false
    end
    local currLv = self.inviteData["companyLv"]["ID"..companyId] or 0
    local maxLv = ConfigMgr.config_company[companyId].levelMax
    return currLv >= maxLv
end

function CompanyMode:CompanyLvUp(companyId, check)
    if not companyId then
        return false
    end
    
    local data = self:GetData()
    local roomIndex = self:GetRoomIndexByCompanyId(companyId)
    local currData = data[roomIndex]

    if currData then
        local currConfig = ConfigMgr.config_company[currData.company_id]

        if not currData.level then
            currData.level = ConfigMgr.config_company[companyId].levelBegin
        end

        if not currData.currExp then
            local lastExp = self.inviteData["companyExp"] and self.inviteData["companyExp"]["ID"..companyId] or 0
            currData.currExp = lastExp and lastExp or 0
        end

        local maxExp = currConfig.expMax[currData.level < currConfig.levelMax and currData.level or currConfig.levelMax - 1]

        if check then
            return currData.level < currConfig.levelMax and currData.currExp >= maxExp
        end
        if currData.level < currConfig.levelMax and currData.currExp >= maxExp then
            currData.level = currData.level + 1
            --调用通行证任务接口，更新任务进度2024-12-23
            GameTableDefine.SeasonPassTaskManager:GetDayTaskProgress(4, 1)
            --2024-9-13添加，公司升级上报ajdust埋点
            GameSDKs:TrackControlCheckData("af", "af,corp_upgrade_10", {})
            if currData.level < currConfig.levelMax then
                currData.currExp = currData.currExp - maxExp
            else
                currData.currExp = maxExp
            end
            self.inviteData["companyLv"]["ID"..currData.company_id] = currData.level
            -- GameSDKs:Track("com_levelup", {com_id = companyId, com_name = GameTextLoader:ReadText("TXT_COMPANY_C"..companyId.."_NAME"),
            --                                 com_grade = GameTextLoader:ReadText("TXT_COMPANY_QUALITY_" .. currConfig.company_quality),
            --                                 com_level = currData.level - 1}--初始为1级,所以这里减1,在第一次升级后显示的就是1
            -- )

            MainUI:RefreshCashEarn()
            MainUI:RefreshCollectionHint()

            ChatEventManager:ConditionToStart(3, currData.level - 1)--初始为1级
            if currData.level == currConfig.levelMax then
                ChatEventManager:ConditionToStart(2,companyId)

                local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
                EventManager:DispatchEvent("COMPANY_LV_MAX", companyId, roomId)
            end
            return true
        end
    end

    return false
end

function CompanyMode:UpdateCompanyExp()--公司经验每秒加一次
    local companyConfig = ConfigMgr.config_company;
    local data = self:GetData()
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime() 
    local needSave = false

    if not self.companyTimes then
        self.companyTimes = 0
    end

    self.companyTimes = self.companyTimes + 1

    for k,v in pairs(data or {}) do
        if self:CheckCompanyExpState(k) then
            local currConfig = companyConfig[v.company_id]

            if not v.currExp then 
                v.currExp = 0 
            end
            if not v.level then 
                v.level = ConfigMgr.config_company[v.company_id].levelBegin

                if not self.inviteData["companyLv"] then
                    self.inviteData["companyLv"] = {}
                end

                self.inviteData["companyLv"]["ID"..v.company_id] = v.level
                needSave = true
            end

            local expAdd = self:RoomExpAdd(k)

            if FloorMode:IsRoomBroken(k) then--断电
                expAdd = 0
            end

            v.currExp = math.floor(v.currExp + expAdd)

            local maxExp = currConfig.expMax[v.level < currConfig.levelMax and v.level or currConfig.levelMax - 1]

            if v.level < currConfig.levelMax and v.currExp > maxExp then
                if not self.maxCompany[v.company_id .. "_" .. v.level] then--避免反复发送
                    self.maxCompany[v.company_id .. "_" .. v.level] = true
                    local roomId = FloorMode:GetRoomIdByRoomIndex(v.roomIndexNum)
                    FloorMode:GetScene():InitRoomGo(roomId)
                end
            end
        end
    end

    if self.companyTimes == 120 or needSave then--2分钟存一次
        self.companyTimes = 0
        LocalDataManager:WriteToFile()
    end
end

---@param ignoreMood boolean 是否不受员工心情影响(商城用)
function CompanyMode:AddExp(seconds,ignoreMood)--给所有招募的公司增加经验
    local companyConfig = ConfigMgr.config_company;
    local data = self:GetData()
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime() 

    for k,v in pairs(data or {}) do
        local currConfig = companyConfig[v.company_id]

        if not v.currExp then 
            v.currExp = 0 
        end
        if not v.level then 
            v.level = ConfigMgr.config_company[v.company_id].levelBegin

            if not self.inviteData["companyLv"] then
                self.inviteData["companyLv"] = {}
            end

            self.inviteData["companyLv"]["ID"..v.company_id] = v.level
        end

        local expAdd = self:RoomExpAdd(k,ignoreMood)

        v.currExp = math.floor(v.currExp + expAdd * seconds)

        local maxExp = currConfig.expMax[v.level < currConfig.levelMax and v.level or currConfig.levelMax - 1]

        if v.level < currConfig.levelMax and v.currExp > maxExp then
            if not self.maxCompany[v.company_id .. "_" .. v.level] then--避免反复发送
                self.maxCompany[v.company_id .. "_" .. v.level] = true
                local roomId = FloorMode:GetRoomIdByRoomIndex(v.roomIndexNum)
                FloorMode:GetScene():InitRoomGo(roomId)
            end
        end
    end
    LocalDataManager:WriteToFile()
end

function CompanyMode:GetCompanyLevel(companyId)--最好加一个没招募过就返回0
    if not self.inviteData then
        self:Init()
    end
    if not self.inviteData["companyLv"] or not self.inviteData["companyLv"]["ID"..companyId] then
        return ConfigMgr.config_company[companyId].levelBegin
    end
    return self.inviteData["companyLv"]["ID"..companyId]
end

function CompanyMode:CheckCompanyState()
    local data = self:GetData()
    local saveData = false
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime() 
    for k,v in pairs(data or {}) do
        local roomId = FloorMode:GetRoomIdByRoomIndex(v.roomIndexNum)
        if TimerMgr:GetCurrentServerTime() > v.time then--合约时间到了
            local dataRoom = FloorMode:GetAllRoomsLocalData()
            
            if not dataRoom[k].leaveCompany then
                dataRoom[k].leaveCompany = v.company_id
                --CompanysUI:ExcludeCompany(v.company_id, true)--待续约的公司排除在公司池

                FloorMode:GetScene():InitRoomGo(roomId)
                --self:refreshTypeCount(v.company_id)
                saveData = true
            end
        end

        if self:CheckCompanyWorkState(gameH, gameM, v.company_id) then
            if roomId then
                FloorMode:GetScene():SetCompanyStartWork(roomId)
            end
        else
            if roomId then
                FloorMode:GetScene():SetCompanyEndWork(roomId)
            end
        end
    end
    if saveData then
        LocalDataManager:WriteToFile()
    end
end

function CompanyMode:GetCompanySameQualityNumber(quality)
    if not self.inviteData or not self.inviteData.qualityNum then
        return 0
    end

    -- if not self.inviteData.qualityNum["QU"..quality] then
    --     return 0
    -- end

    if not self.inviteData then
        self.inviteData = {}
    end

    if not self.inviteData.qualityNum then
        self.inviteData.qualityNum = {}
    end

    local num = 0

    for k,v in pairs(self.inviteData.qualityNum) do
        local saveQuality = string.sub(k,3)
        saveQuality = tonumber(quality)
        if saveQuality >= quality then
            num = num + v
        end
    end

    return num
end

function CompanyMode:GetNumByLevel(level, quality)
    if not self.inviteData then
        return 0
    end

    local num = 0
    local cfg = ConfigMgr.config_company
    for k,v in pairs(self.inviteData.companyLv or {}) do
        local companyId = k:gsub("%D+", "")
        if v > level then
            local companyQuality = cfg[tonumber(companyId)].company_quality
            if companyQuality >= quality then
                num = num + 1
            end
        end
    end

    return num
end

function CompanyMode:CheckCompanyWorkState(gameH, gameM, companyId)
    if not gameH or not gameM then
        GameClockManager:Init()
        GameClockManager:CalculateCurrGameTime()
        return false
    end
    local currTVlaue = gameH * 60 + gameM
    local cfg = ConfigMgr.config_company[companyId]
    if currTVlaue >= cfg.starWork and currTVlaue <= cfg.endWork then
        return true
    end
    return false
end

function CompanyMode:CheckManagerRoomOnWork(isRequest, propertyId, force)
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    gameH = gameH or 0
    
    local isWorking = gameH >= ConfigMgr.config_global.workday_duration[1] and gameH <= ConfigMgr.config_global.workday_duration[2]
    local returnRet = {}
    local managerId = nil

    if not managerRoomGoData then
        managerRoomGoData = {}
        local floorConfig = FloorMode:GetCurrFloorConfig() or {}
        for k,roomId in ipairs(floorConfig.room_list or {}) do
            local roomConfig = ConfigMgr.config_rooms[roomId]
            if roomConfig.category[2] == 6 or roomConfig.category[2] == 2 then
                managerRoomGoData[roomId] = FloorMode:GetScene():GetRoomRootGoData(roomId)
            end
        end
    end

    for roomId, goData in pairs(managerRoomGoData) do
        local curRoomIsWorking = isWorking
        if goData.config.room_index == "ManagerRoom_104" then
            local localData = FloorMode:GetRoomLocalData(goData.config.room_index) or {}
            curRoomIsWorking = curRoomIsWorking and localData.business_day ~= gameH and goData.onSpecialBuilding == nil
            managerId = roomId
        end

        local localData = FloorMode:GetRoomLocalData(goData.config.room_index)
        if localData.unlock then
            if not isRequest then
                if curRoomIsWorking then
                    FloorMode:GetScene():SetCompanyStartWork(roomId, force)
                else
                    FloorMode:GetScene():SetCompanyEndWork(roomId, force)
                    --K133 没有公司的房间 CEO与老板办公室一起下班
                    EventDispatcher:TriggerEvent(GameEventDefine.CEOOffWorkWithBuilding)
                end
            end
        else
            curRoomIsWorking = nil
        end
        if localData.unlock then
            returnRet[roomId] = curRoomIsWorking
        end
    end
    if isRequest then
        return returnRet[propertyId or managerId]
    end
end

---是否是BOSS上班时间
function CompanyMode:IsBossWorkingTime()
    local isWork = CompanyMode:CheckManagerRoomOnWork(true)
    return isWork
end

function CompanyMode:CheckBossOnWork()
    local boss = ActorManager:GetFloorBossEntity()

    if not boss then
        return
    end
    local isWorkingTime = self:IsBossWorkingTime()
    if isWorkingTime then
        local needStart = boss:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
        if needStart then
            FloorMode:GetScene():SetBossStartWork()
        end
    else
        local needEnd = not boss:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
        if needEnd then
            FloorMode:GetScene():SetBossEndWork()
        end
    end
end

function CompanyMode:AciveManagerBusinessTrip()
    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime()
    local localData = FloorMode:GetRoomLocalData("ManagerRoom_104") or {}
    local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")
    local goData = FloorMode:GetScene():GetRoomRootGoData(roomId)
    if localData.business_day == gameH then
        return
    end
    localData.business_day = gameH
    --FloorMode:GetScene():SetCompanyEndWork(roomId)
    self:CheckManagerRoomOnWork(nil, nil, true)
    LocalDataManager:WriteToFile()
end

function CompanyMode:ManagerOnSpecialBuilding(bid)
    local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")
    local goData = FloorMode:GetScene():GetRoomRootGoData(roomId)
    if goData.onSpecialBuilding then
        return
    end
    goData.onSpecialBuilding = bid
    -- FloorMode:GetScene():SetCompanyEndWork(roomId)
    self:CheckManagerRoomOnWork(nil, nil, true)
end

function CompanyMode:ManagerLeaveSpecialBuilding()
    local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")
    local goData = FloorMode:GetScene():GetRoomRootGoData(roomId)
    if not goData.onSpecialBuilding then
        return
    end

    goData.onSpecialBuilding = nil
    self:CheckManagerRoomOnWork(nil, nil, true)

    local h,m,s = GameClockManager:GetCurrGameTime()
    local isWord = h >= ConfigMgr.config_global.workday_duration[1] and h <= ConfigMgr.config_global.workday_duration[2]
    if isWord then
        --买车后老板在办公室
        --第一次买会为空,需要处理
        local bossCar = Bus:GetCarEntity()
        bossCar:AddFlag(ActorDefine.Flag.FLAG_CAMERA_FOLLOW_CAR)
    end
end


function CompanyMode:SpendDiamondAddExp(cfg, cb)
    if not cfg.diamond then
        return
    end
    ResourceManger:SpendDiamond(cfg.diamond, nil, function()
        local data = CompanyMode:GetData()
        for k,v in pairs(data or {}) do
            if not v.currExp then 
                v.currExp = 0 
            end
            if not v.level then 
                v.level = ConfigMgr.config_company[v.company_id].levelBegin
            end
            v.currExp = math.floor(v.currExp + (cfg.amount or 0))
        end
        if cb then cb() end
    end)
end

return CompanyMode