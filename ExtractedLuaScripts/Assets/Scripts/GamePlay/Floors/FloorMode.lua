---@class FloorMode
local FloorMode = GameTableDefine.FloorMode
local MainUI = GameTableDefine.MainUI
--local HUD = GameTableDefine.HUD
--local ExchangeUI = GameTableDefine.ExchangeUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local ActorEventManger = GameTableDefine.ActorEventManger
local MeetingEventManager = GameTableDefine.MeetingEventManager
local CompanyMode = GameTableDefine.CompanyMode
local ConfigMgr = GameTableDefine.ConfigMgr
local SoundEngine = GameTableDefine.SoundEngine
local RateUI = GameTableDefine.RateUI
local StarMode = GameTableDefine.StarMode
local TimerMgr = GameTimeManager
local ChatEventManager = GameTableDefine.ChatEventManager
local CityMode = GameTableDefine.CityMode
local FlyIconsUI = GameTableDefine.FlyIconsUI
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local ShopManager = GameTableDefine.ShopManager
local ShopAfterPerson = GameTableDefine.ShopAfterPerson
local TalkUI = GameTableDefine.TalkUI
local PetMode = GameTableDefine.PetMode
local FactoryMode = GameTableDefine.FactoryMode
--local ActivityUI = GameTableDefine.ActivityUI
local PetInteractUI = GameTableDefine.PetInteractUI
local CountryMode = GameTableDefine.CountryMode
local OfflineRewardUI =GameTableDefine.OfflineRewardUI
local FootballClubModel = GameTableDefine.FootballClubModel
local GameObject = CS.UnityEngine.GameObject
local TimeLimitedActivitiesManager = GameTableDefine.TimeLimitedActivitiesManager
local UnityHelper = CS.Common.Utils.UnityHelper
local ActorManager = GameTableDefine.ActorManager
local PowerManager = GameTableDefine.PowerManager
local DeviceUtil = CS.Game.Plat.DeviceUtil

local EventManager = require("Framework.Event.Manager")
local Execute = require("Framework.Queue.Execute")
--local Class = require("Framework.Lua.Class");
--local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local PropertyServiceManager = require("CodeRefactoring.Actor.PropertyServiceManager")
local FloorScene = nil ---@type FloorScene


-- local ROOMS_RECORD = "rooms"
local ROOM_TYPE_OFFICE = 1
local ROOM_TYPE_PROPERTY = 2
local ROOM_TYPE_MEETING = 3
local ROOM_TYPE_TOILE = 4
local ROOM_TYPE_POWER = 5
local ROOM_TYPE_MANAGER = 6
local ROOM_TYPE_FINANCIAL = 7
local ROOM_TYPE_REST = 8
local ROOM_TYPE_ENTERTAINMENT = 9
local ROOM_TYPE_GYM = 10
local CITY_RECORD = CountryMode.city_record_data or "city_record_data"

FloorMode.F_TYPE_AUX_PERSON     = "1"
FloorMode.F_TYPE_AUX_CONDITION  = "2"
FloorMode.F_TYPE_AUX_PROPERTY   = "3"
FloorMode.F_TYPE_SHOP_PERSON    = "4"

FloorMode.isFirst = true
FloorMode.m_lastRoomBrokenIndex = 0
FloorMode.lastRoomBrokenTime = 0

function FloorMode:Init(parms)    
    Execute:Async({function()
        GameUIManager:SetFloatUILockScale(true, 18)
    end})
    FloorScene = require("GamePlay.Floors.FloorScene").new()
    self:InitConfig(parms)
    self:SetCurrentFloorIndex(1, true)
    self:InitBuildingAllRoomsData() -- 门牌号作为索引存档。
    PetMode:Init()
    MainUI:ClearEventUI()
    CompanyMode:Clear()
    CompanyMode:Init()
    FloorScene:OnEnter(parms.defaultRoomCategory)
    ActorEventManger:Init()
    ChatEventManager:Init()    
    MeetingEventManager:Init()    
    --GameTableDefine.AZhenMessage:Init()
    CityMode:PlayDefaultSound()--第一次进入场景,播放背景音乐
    --CompanyMode:RefreshAZhenMessage()
    --SoundEngine:PlayBackgroundMusic(SoundEngine.MUSIC_BG_BUIDLING_IN, true)    
    self:IsFirstInit(function()
        --来自服务器的活动数据处理
        --请求一次补单数据2024-8-13添加，进入游戏就请求一次补单数据
        DeviceUtil.InvokeNativeMethod("queryOrder", "1")
        --累充活动的初始化fengyu
        GameTableDefine.AccumulatedChargeActivityDataManager:Init()
        --排行活动初始化调用2022-10-10 fengyu
        GameTableDefine.ActivityRankDataManager:Init()
        GameTableDefine.DressUpDataManager:Init()
        TimeLimitedActivitiesManager:Init()
        --活动需要的游戏中事件触发的注册
        TimeLimitedActivitiesManager:InitActiveEvents() 
        FactoryMode:Init()
        --工厂的零件离线计算
        FactoryMode:PiecewiseCalculation()
        --工厂的零件实时计算
        FactoryMode:Updata()
        --俱乐部离线计算
        
        --俱乐部初始化
        local cfg = FootballClubModel:GetUnlockFCData()
        if cfg then
            FootballClubModel:Init(cfg,nil)
            --俱乐部实时计算
            FootballClubModel:CalculateFCData()
        end

        --宠物的离线成长计算30秒结算一次
        PetInteractUI:OfflineGrowingUp(30)
        --宠物的在线成长计算
        PetInteractUI:AllPetGrowth()      
        --周重置 和 天重置
        TimeLimitedActivitiesManager:ResetData()
        --通过SDK请求活动数据
        TimeLimitedActivitiesManager:RequestActivityData() 
        --这里防止公告检测的和显示的逻辑因为这里才有存档读取的逻辑完成
        GameTableDefine.BoardUI:InitBoardDisplay(function()
            print("InitBoardDisplay callback here!")
         end)
         --副本活动数据模块的初始化相关内容
         --GameTableDefine.InstanceDataManager:Init(
         --   function()
         --       MainUI:RefreshInstanceentrance()
         --   end
         --)

         --2023-6-26添加一个对于老存档玩家开始计算礼包的倒计时问题
         GameTableDefine.IntroduceUI:UpdateTimeLockCondition()

        --  --2023-8-18个人发展版本晋升数据模块初始化
        --  GameTableDefine.PersonalDevModel:Init()
        --2025-2-7 CEO数据管理器初始化
        GameTableDefine.CEODataManager:Init()
    end)
    --自动显示离线奖励
    OfflineRewardUI:LoopCheckRewardValue(function()
        OfflineRewardUI:GetView()
    end, false)       
end

--是第一次进入场景运行一次
function FloorMode:IsFirstInit(cb)
    if FloorMode.isFirst then
        if cb then
            cb()
        end
        FloorMode.isFirst = false
    end
end

function FloorMode:Update(dt)
    if GameStateManager:GetCurrentGameState() == GameStateManager.GAME_STATE_INSTANCE then
        return
    end
    if GameStateManager:GetCurrentGameState() == GameStateManager.GAME_STATE_CYCLE_INSTANCE then
        return
    end
    if FloorScene then
        FloorScene:Update(dt)
    end
    if ActorEventManger then
        ActorEventManger:Update(dt)
    end
    if ActorManager then
        ActorManager:Update(dt)
    end
    if MeetingEventManager then
        MeetingEventManager:Update()
    end
    if CompanyMode then
        CompanyMode:Update(dt)
    end
    if ChatEventManager then
        ChatEventManager:Update(dt)
    end
    if FootballClubModel then
		FootballClubModel:Update()
	end
    self:UpdateRoomsBroken()
end

function FloorMode:OnExit()
    ActorEventManger:Exit()
    PetMode:Exit()
    --GameTableDefine.AZhenMessage:OnExit()
    if FloorScene then
        FloorMode:ExitSpecialBuilding(true)
        FloorScene:OnExit()
        GameResMgr:Unload(FloorScene)
    end
    FloorScene = nil

    for k,v in pairs(self.doorTimer or {}) do
        GameTimer:StopTimer(v)
    end
    self.doorTimer = nil
end

function FloorMode:InitConfig(parms)
    self.m_floorId = parms.config.floor_list[1]
    self.m_currFloorConfig = ConfigMgr.config_floors[self.m_floorId]-- self.m_floorsConifg[1011]
    self.m_allRoomsIdInBuilding = {}
    self.m_area = parms.config.district
    self.m_officeBuildingID = parms.id
    for k,v in ipairs(parms.config.floor_list or {}) do
        for i,roomId in ipairs(ConfigMgr.config_floors[v].room_list) do
            --table.insert(self.m_allRoomsIdInBuilding, roomId)
            self.m_allRoomsIdInBuilding[ConfigMgr.config_rooms[roomId].room_index] = roomId
        end
    end
end

function FloorMode:CheckSceneOnArea()
	local currCountryId = CountryMode:GetCurrCountry()
	for i,v in ipairs(ConfigMgr.config_district or {}) do
        if v.id == self.m_area then
			return v.country == currCountryId
        end
    end
end

function FloorMode:FirstCome(buildingId, enter)--是否第一次进入场景buildingId, 以及是否正在进入
    local data = LocalDataManager:GetDataByKey(CITY_RECORD)
    if not data.enter then
        data.enter = {}
    end

    if not data.enter[""..buildingId] then
        data.enter[""..buildingId] = false
    end

    local first = (data.enter[""..buildingId] == false)
    if enter and first == true then
        data.enter[""..buildingId] = true
        LocalDataManager:WriteToFile()
    end

    return first
end

function FloorMode:MakeDoorTimer(doorObj, cb)
    self.doorTimer = self.doorTimer or {}
    if self.doorTimer[doorObj] then
        return
        --GameTimer:StopTimer(self.doorTimer[doorObj])
    end

    self.doorTimer[doorObj] = GameTimer:CreateNewTimer(2, function()
        local closeSuccess = true
        if cb then 
            closeSuccess = cb()
        end

        self.doorTimer[doorObj] = nil
        if closeSuccess == 1 then--换场景之类的,没有了动画资源
            return
        end
        if not closeSuccess then
            self:MakeDoorTimer(doorObj, cb)
        end
    end)
end

function FloorMode:GetGameProgress()
    local curr = 0;
    local total = 0;

    --计算当前游戏进度
    --1.大楼解锁(当前id,总的为最高id)
    --2.房间解锁(解锁一个算1,按当前房间计算总数)
    --3.设施解锁(每级算1,按config_furnitures_levels的算总的)
    
    local currBuild = LocalDataManager:GetDataByKey(CITY_RECORD).currBuidlingId
    local totalBuild = 0
    for k,v in pairs(ConfigMgr.config_buildings) do
        totalBuild = k
    end

    local currUnlockRoom = 0
    local totalUnlockRoom = 0

    local currFurniture = 0
    local totalFurniture = 0

    local roomsData = LocalDataManager:GetDataByKey(CountryMode.rooms)
    for index, roomData in pairs(roomsData or {}) do

        totalUnlockRoom = totalUnlockRoom + 1
        if roomData.unlock == true then
            currUnlockRoom = currUnlockRoom + 1
        end

        for furnitureIndex,furnitureData in pairs(roomData.furnitures or {}) do
            if furnitureData.level > 0 then
                currFurniture = currFurniture + furnitureData.level
            end
        end

    end

    for k,v in pairs(ConfigMgr.config_furnitures_levels) do
        totalFurniture = totalFurniture + #v
    end

    curr = currBuild + currUnlockRoom + currFurniture
    total = totalBuild + totalUnlockRoom + totalFurniture
    
    return curr / total
end

function FloorMode:GetCurrFloorId()
    return self.m_floorId
end

function FloorMode:GetCurrFloorConfig()
    return self.m_currFloorConfig
end

function FloorMode:SetCurrRoomInfo(index, id)
    self.m_curRoomIndex = index
    self.m_curRoomId = id
end

function FloorMode:IsFurnitureMaxLevel(index, id)
    local roomLocalData = self.m_curBuildingAllRoomsData[self.m_curRoomIndex]
    if not roomLocalData then
        return
    end

    local posData = roomLocalData[index]
    if posData.id ~= id then
        return
    end

    return posData.level >= #ConfigMgr.config_furnitures_levels[id]
end

function FloorMode:FindRoomByFurniture(furnitureId, furnitureLv)--找到符合购买设施的房间
    local buildingData = self:GetAllRoomsLocalData()
    for k,v in pairs(buildingData) do
        if v.unlock then
            for furnitureIndex, furnitureData in pairs(v.furnitures or {}) do
                if furnitureData.id == furnitureId and furnitureData.level < furnitureLv then
                    return self:GetRoomIdByRoomIndex(k)
                end
            end
        end
    end

    --说明需要解锁房间才能购买该设施,如何找到距离最近的房间???
    return nil    
end

function FloorMode:FurnitureUnlocakable(roomIndexs, furnitureId, furnitureLv)
    local buildingData = self:GetAllRoomsLocalData()
    local configData = ConfigMgr.config_rooms
    local search = {}
    if type(roomIndexs) == "string" then
        table.insert(search, roomIndexs)
    else
        search = roomIndexs
    end

    for k, v in pairs(search) do
        local roomId = self:GetRoomIdByRoomIndex(v)
        local currData = buildingData[configData[roomId].room_index]
        if currData.unlock then
            for furnitureIndex, furnitureData in pairs(currData.furnitures or {}) do
                if furnitureData.id == furnitureId and furnitureData.level < furnitureLv then
                    return roomId
                end
            end
        end
    end

    return nil
end

function FloorMode:BeNB()
    for roomIndex, roomV in pairs(self.m_curBuildingAllRoomsData or {}) do
        for index, furV in pairs(roomV.furnitures) do
            local id = furV.id

            local maxLevel = #ConfigMgr.config_furnitures_levels[id]

            if id ~= 10036 or furV.level > 0 then
                furV.level = maxLevel
                furV.level_id = ConfigMgr.config_furnitures_levels[id][maxLevel]["id"]
            end
        end
    end

    LocalDataManager:WriteToFile()
end

function FloorMode:BuyFurniture(index, id, checkCondition, buySccessCallback)
    local roomLocalData = self.m_curBuildingAllRoomsData[self.m_curRoomIndex]
    if not roomLocalData then
        return
    end

    local posData = roomLocalData.furnitures[index]
    if posData.id ~= id or posData.level >= #ConfigMgr.config_furnitures_levels[id] then
        return
    end

    local achieve, conditionData = self:CheckCondition(index, id)
    local furniType = ConfigMgr.config_furnitures[posData.id].type or 0

    local ConditionCallbck = function(levelId)
        if tonumber(conditionData) then
            return 
        end

        local hasAccessory = furniType > 0
        if conditionData and hasAccessory then
            for k, v in pairs(conditionData or {}) do
                local info = {lvId = levelId, id = posData.id, index = posData.index} -- , i = index
                v.accessory_info = v.accessory_info or {}
                if not v.accessory_info[tostring(furniType)] then
                    v.accessory_info[tostring(furniType)] = {}
                else
                    for i, n in ipairs(v.accessory_info[tostring(furniType)] or {}) do
                        if n.id == posData.id and n.index == posData.index then
                            --v.accessory_info[tostring(type)][i] = info
                            v.accessory_info[tostring(furniType)][posData.id .."_" .. posData.index] = info
                            info = nil
                            break
                        end
                    end
                end
                if info then
                    --table.insert(v.accessory_info[tostring(type)], info)
                    v.accessory_info[tostring(furniType)][posData.id .."_" .. posData.index] = info
                end
            end
        end
    end

    if checkCondition then
        if posData.level > 0 then
            local levelId = ConfigMgr.config_furnitures_levels[posData.id][posData.level]["id"]
            ConditionCallbck(levelId)
        end
        return
    end

    if not achieve then
        local txt = GameTextLoader:ReadText("TXT_TIP_LACK_FACILITY")
        local cfg = ConfigMgr.config_furnitures_levels[conditionData]
        txt = string.format(txt, self:GetFurnitureName(cfg.furniture_id, cfg.level))
        EventManager:DispatchEvent("UI_NOTE", txt)
        return
    end

    local cost = ConfigMgr.config_furnitures_levels[id][posData.level + 1].cost
    self:HandleCosts(cost)

    local cb = function(isEnough)
        if isEnough then
            posData.level = posData.level + 1
            local furnitureConfig = ConfigMgr.config_furnitures_levels[posData.id][posData.level]
            posData.level_id = furnitureConfig["id"]
            ConditionCallbck(posData.level_id)

            if tostring(furniType) == self.F_TYPE_SHOP_PERSON and posData.level == 1 then
                --if GameConfig:IsIAP() then
                    local shopType = nil
                    local buyBefor = false
                    local seeBefor = ShopAfterPerson:GuideBefor()


                    if posData.id == 10052 then
                        shopType = 6
                        buyBefor = ShopManager:GetCashImprove() > 0
                    elseif posData.id == 10053 then
                        shopType = 7
                        buyBefor = ShopManager:GetOfflineAdd() > 0
                    end

                    if buyBefor then
                        self:GetScene():RefreshShopPerson(self.m_curRoomId, index)
                    elseif not seeBefor then
                        TalkUI:OpenTalk("shop_npc")
                    end
                --end
            end

            CompanyMode:IsRoomSatisfy(self.m_curRoomIndex, true)
            
            FloorScene:LevelUpFurniture(self.m_curRoomId, index, posData.level)
            if furnitureConfig.power_consume and furnitureConfig.power_consume ~= 0 then
                if furnitureConfig.power_consume > 0 then
                    EventManager:DispatchEvent(GameEventDefine.ReCalculateTotalPower)
                elseif furnitureConfig.power_consume < 0 then
                    EventManager:DispatchEvent(GameEventDefine.ReCalculatePowerUsed)
                end
            end
            RoomBuildingUI:ShowRoomPanelInfo(self.m_curRoomId)
            MainUI:RefreshQuestHint()
            MainUI:RefreshDiamondShop()
            MainUI:RefreshCashEarn()
            --MainUI:RefreshStarState()
            SoundEngine:PlaySFX(SoundEngine.BUY_SFX)

            local alreadyUnlock = posData.level > 1
            local operate = 4
            if not alreadyUnlock then
                operate = 2
            end
            --2023-4-17 暂时关闭解锁和升级设置埋点
            --GameSDKs:TrackForeign("equipment_upgrade", {equipment_id = id, equipment_level = posData.level - 1, operation_type = operate,
            --room_id = self.m_curRoomId, scene_id = CityMode:GetCurrentBuilding()})

            local spendDiamond = false
            for i,v in ipairs(cost or {}) do
                if v.type == 3 then
                    spendDiamond = true
                    -- GameSDKs:Track("cost_diamond", {cost = v.num, left = ResMgr:GetDiamond(), cost_way = "购买设施"})
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "购买设施", behaviour = 2, num_new = tonumber(v.num)})
                end
            end

            -- if not spendDiamond then
            --     -- GameSDKs:Track("get_furniture", {
            --     -- furniture_id = id,
            --     -- furniture_name = GameTextLoader:ReadText("TXT_FURNITURES_"..id.."_"..posData.level.."_NAME"),
            --     -- room_id = self.m_curRoomId,
            --     -- money_type = "cash",
            --     -- cost_money = cost[1].num,
            --     -- left_money = ResMgr:GetCash()})
            -- else
            --     -- GameSDKs:Track("get_furniture", {
            --     -- furniture_id = id,
            --     -- furniture_name = GameTextLoader:ReadText("TXT_FURNITURES_"..id.."_"..posData.level.."_NAME"),
            --     -- room_id = self.m_curRoomId,
            --     -- money_type = "diamond",
            --     -- cost_money = cost[1].num,
            --     -- left_money = ResMgr:GetDiamond()})
            -- end
            --增加一个购买家具成功的回调，来做购买成功后的逻辑
            if buySccessCallback then
               buySccessCallback() 
            end
             --2022-12-5 warrior更換sdk后增加埋點的數據内容
             local currency1 = 1
             local cost1 = cost[1].num
             local productivity1 = 0
             local cpp1 = 0
             if not spendDiamond then
                 currency1 = CountryMode:GetCurrCountry() + 1
                 productivity1 = FloorMode:GetTotalRent(nil, CountryMode:GetCurrCountry())
                 if productivity1 > 0 then
                     cpp1 = cost1 / productivity1
                 end
                 --2024-8-20添加用于设施升级到的钞票消耗埋点上传
                 local type = 1
                 local amount = cost1
                 if currency1 == 3 then
                    type = 2
                 end
                 local change = 1
                 local position = "["..id.."]号设施升级"
                 GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0,amount_new = tonumber(amount) or 0, position = position})
                 --2025-1-6fy添加用于存储玩家升级家具的绿钞总消耗
                 if type == 1 and change == 1 then
                    local cashFurTotal = LocalDataManager:GetDataByKey("UpgradeFurTotalCash")
                    if not cashFurTotal.total then
                        cashFurTotal.total = amount
                    else
                        cashFurTotal.total = cashFurTotal.total + tonumber(amount)
                    end
                    
                 end
            else
                local amount = cost1
                local diamondFurTotal = LocalDataManager:GetDataByKey("UpgradeFurTotalDiamond")
                if not diamondFurTotal.total then
                    diamondFurTotal.total = amount
                else
                    diamondFurTotal.total = diamondFurTotal.total + tonumber(amount)
                end
            end
             --currency:消耗货币类型钻石=1, 钞票=2，欧元=3,cost:消耗货币数量,productivity:钻石传0, 钞票传左上角计算的总效率(单位用分钟, 左上角是30秒的效率, 乘以2即可)
             --cpp:cost值除以productivity值用消耗的值除以上一行计算的效率, 得到这次升级消耗的钞票的这个钱数, 玩家大概用了多少分钟赚得, productivity为0时, 传0
             --2023-4-17 暂时关闭解锁和升级设置埋点
             --GameSDKs:TrackForeign("equipment_upgrade", {equipment_id = id, equipment_level = posData.level - 1, operation_type = operate,
             --room_id = self.m_curRoomId, scene_id = CityMode:GetCurrentBuilding(), currency = currency1, cost = cost1, productivity = productivity1, cpp = cpp1})
        else
            --hint
        end
    end

    ResMgr:SpendMultiple(cost, ResMgr.EVENT_BUY_FURNITURE, function(isEnough)
        cb(isEnough)
    end)
    --ResMgr:SpendCash(ConfigMgr.config_furnitures_levels[id][posData.level + 1].money, ResMgr.EVENT_BUY_FURNITURE, cb)
end

function FloorMode:CheckCondition(index, id)
    local roomLocalData = self.m_curBuildingAllRoomsData[self.m_curRoomIndex]
    local posData = roomLocalData.furnitures[index]
    local config = ConfigMgr.config_furnitures_levels
    local hireCondition = config[id][posData.level + 1].hire_condition
    if not hireCondition then
        return true, nil
    end

    -- local tragetConfig = ConfigMgr.config_furnitures_levels[hireCondition]
    local type = tostring(ConfigMgr.config_furnitures[posData.id].type)
    if type == FloorMode.F_TYPE_AUX_PERSON then -- 招募物业
        local data = {furnitures = {}, buff = {}, num = {}, reduplicate = {}} -- 处理物业专员占用了多个工作台
        for i, v in pairs(roomLocalData.furnitures) do
            data.furnitures[v.id .. "_" .. v.index] = v
            if v.accessory_info then
                local key, value = next(v.accessory_info[type] or {})
                if key then
                    data.num[key] = (data.num[key] or 0) + 1
                    data.buff[key] = data.buff[key] or {}
                    data.buff[key][data.num[key]] = v
                    if data.num[key] > 1 then
                        for _,buff in ipairs(data.buff[key]) do table.insert(data.reduplicate, buff) end
                    end
                end
            end
            if v.level_id ~= 0 
                and v.id == config[hireCondition].furniture_id
                and config[v.level_id].level >= config[hireCondition].level
                and (not v.accessory_info or (v.accessory_info[type] or {})[id.."_"..posData.index])
            then
                data = nil
                return true, {v}
            end
        end

        -- 验证重复的设施
        for i, v in pairs(data.reduplicate) do
            local key, value = next(v.accessory_info[type] or {}) 
            local targetFurniture = data.furnitures[key]
            if v.level_id ~= 0 
                and v.id == config[hireCondition].furniture_id
                and config[v.level_id].level >= config[hireCondition].level
                and targetFurniture and targetFurniture.level_id ~= value.lvId
            then
                data = nil
                v.accessory_info = nil
                return true, {v}
            end
        end
        -- 等级相等随机一个
        for i, v in pairs(data.reduplicate) do
            if v.level_id ~= 0 
                and v.id == config[hireCondition].furniture_id
                and config[v.level_id].level >= config[hireCondition].level
            then
                data = nil
                v.accessory_info = nil
                return true, {v}
            end
        end
        data = nil
    elseif type == FloorMode.F_TYPE_AUX_CONDITION then -- 购买附属条件
        local roomGoData = nil
        if FloorScene then
            roomGoData = FloorScene:GetRoomRootGoData(self:GetRoomIdByRoomIndex(self.m_curRoomIndex))
        end
        for i, v in pairs(roomLocalData.furnitures) do
            local tans,accessory = next((v.accessory_info or {})[type] or {})
            if accessory and roomGoData then
                tans = FloorScene:GetTrans(roomGoData.furnituresGo[i], "CashRegisterPos")
            end
            if v.level_id ~= 0
                and v.id == config[hireCondition].furniture_id
                and config[v.level_id].level >= config[hireCondition].level
                and (not accessory or (accessory and (not tans or (accessory.id == id and accessory.index == posData.index))))
                -- and (not v.accessory_info or not v.accessory_info[type])
            then
                return true, {v}
            end
        end
    elseif type == FloorMode.F_TYPE_AUX_PROPERTY then -- 附属设置添加属性
        local c = {}
        for i, v in pairs(roomLocalData.furnitures) do
            if v.id == config[hireCondition].furniture_id 
                -- and v.level_id ~= 0 
                -- and config[v.level_id].level > 0 
                -- and (not v.accessory_info or not v.accessory_info[type]) 
            then
                table.insert(c, v)
            end
        end
        return true, c
    end
    return false, hireCondition
end

function FloorMode:GetScene()
    return FloorScene
end

function FloorMode:GetAllRoomsLocalData()
    if self.m_curBuildingAllRoomsData then
        return self.m_curBuildingAllRoomsData
    end
    return LocalDataManager:GetDataByKey(CountryMode.rooms)
end

function FloorMode:GetRoomLocalData(roomIndex, countryId)
    if not countryId or countryId == CountryMode:GetCurrCountry() then
        local roomsData = self:GetAllRoomsLocalData()
        return roomsData[roomIndex] or {}
    else
        local roomsData = LocalDataManager:GetDataByKey(CountryMode:GetCountryRooms(countryId))
        return roomsData[roomIndex] or {}
    end
end

function FloorMode:InitBuildingAllRoomsData()
    self.m_curBuildingAllRoomsData = LocalDataManager:GetDataByKey(CountryMode.rooms)
    local hasNewData = false
    local roomsData = self.m_curBuildingAllRoomsData
    for k, roomId in pairs(self.m_allRoomsIdInBuilding or {}) do
        local roomCfg = ConfigMgr.config_rooms[roomId]
        local roomIndex = roomCfg.room_index
        if not roomsData[roomIndex] then
            roomsData[roomIndex] = {}
            roomsData[roomIndex].unlock = roomCfg.unlock_require == 0
            roomsData[roomIndex].furnitures = {}
            roomsData[roomIndex].type = roomCfg.category[2]
            roomsData[roomIndex].unlockTime = 0--什么时候解锁完成
            --roomsData[roomIndex].companyReward = 0--公司离开的奖励
            roomsData[roomIndex].leaveCompany = nil
        end
        --纠正CEO有安排CEO时桌子还是0级的bug
        if roomsData[roomIndex].ceoFurnitureInfo then
            if roomsData[roomIndex].ceoFurnitureInfo.ceoID and roomsData[roomIndex].ceoFurnitureInfo.level <= 0 then
                roomsData[roomIndex].ceoFurnitureInfo.level = 1
            end
        end
        local furnituresData = roomsData[roomIndex].furnitures
        --修复CEO删掉阿珍带来的数据异常的bug
        if self:IsTypeManager(roomCfg.category) then
            --删除出问题的azhen和桌子,包含自由城和欧洲
            local indexDel = {}
            for i, v in ipairs(furnituresData) do
                if v.id == 10004 or v.id == 11004 or v.id == 10050 or v.id == 11050 then
                    table.insert(indexDel, i)
                end
            end
            for i = Tools:GetTableSize(indexDel), 1, -1 do
                table.remove(furnituresData, indexDel[i])
            end
            --282版本错误数据问题的修复
            if Tools:GetTableSize(furnituresData) > Tools:GetTableSize(roomCfg.furniture) then
                local cfgIndexMax = Tools:GetTableSize(roomCfg.furniture)
                local delDatas = {}
                for i = Tools:GetTableSize(furnituresData), Tools:GetTableSize(roomCfg.furniture) + 1, -1 do
                    table.insert(delDatas, table.remove(furnituresData,i))
                end
                for i = 1, Tools:GetTableSize(delDatas) do
                    local furIndex = Tools:GetTableSize(furnituresData) + 1 - i
                    local delItem = delDatas[i]
                    local furData = furnituresData[furIndex]
                    if delItem.id == furData.id then
                        furData.level = 7
                    end
                end
            end
        end
        
        if #furnituresData ~= #roomCfg.furniture and #roomCfg.furniture > 0 then
            local newFurnituresId = {}
            for i, furniture in ipairs(roomCfg.furniture or {}) do
                if not furnituresData[i] or furnituresData[i].id ~= furniture.id then
                    local furnitureData = {}
                    furnitureData.id = furniture.id
                    furnitureData.index = furniture.index
                    furnitureData.level = roomsData[roomIndex].unlock and (furniture.level or 0) or 0
                    furnitureData.level_id = 0
                    if furnitureData.level > 0 then
                        furnitureData.level_id = ConfigMgr.config_furnitures_levels[furnitureData.id][furnitureData.level]["id"]
                    end
                    if not furnituresData[i] then
                        table.insert(furnituresData, furnitureData)
                    else
                        table.insert(furnituresData, i, furnitureData)
                    end
                    if ConfigMgr.config_furnitures[furnitureData.id].type ~= 0 then
                        newFurnituresId[i] = furniture.id
                    end
                    hasNewData = true
                end
            end
            for i, id in pairs(newFurnituresId or {}) do
                self.m_curRoomIndex = roomIndex
                self:BuyFurniture(i, id, true)
            end
            self.m_curRoomIndex = nil
        end
    end
    if hasNewData then
        LocalDataManager:WriteToFile()
    end
    return roomsData
end


function FloorMode:GetCurrRoomLocalData(roomIndex)
    roomIndex = self:RoomIndexNumber2RoomIndex(roomIndex)
    return self.m_curBuildingAllRoomsData[roomIndex or self.m_curRoomIndex] or {}
end

function FloorMode:GetCurrRoomProgress()--计算当前房间的完成度
    local currData = self:GetCurrRoomLocalData().furnitures or {}
    local activeNum = 0
    local total = 0
    for i = 1, #currData do
        local currId = currData[i].id or nil
        local currCfg = ConfigMgr.config_furnitures_levels[currId] or {}
        total = total + #currCfg
        activeNum = activeNum + currData[i].level
    end
    
    -- total = #currData
    return activeNum / total
end

--function FloorMode:GetEnergy()
--    local water,power = 0,0
--    local localdata = LocalDataManager:GetDataByKey(CountryMode.rooms)
--    local furnitureCfg = ConfigMgr.config_furnitures_levels
--    for roomIndex,roomData in pairs(localdata or {}) do
--        for furnitureIndex,furnitureData in pairs(roomData.furnitures or{}) do
--            local furnitureId = furnitureData.id
--
--            local currCgf = furnitureCfg[furnitureId] or {}
--
--            local currLevelCfg = currCgf[furnitureData.level or 0]
--            if currLevelCfg and currLevelCfg.power_consume then
--                --water = water + currLevelCfg.water_consume
--                power = power + currLevelCfg.power_consume
--            end
--        end
--    end
--
--    local buildingPower = GreateBuildingMana:GetPowerImprove()
--    power = power + buildingPower
--
--    return power, water
--end

--function FloorMode:GetTotalPower()--调用得是否过于频繁...而且计算量感觉也不少
--    local power = 0
--    local localdata = LocalDataManager:GetDataByKey(CountryMode.rooms)
--    local furnitureCfg = ConfigMgr.config_furnitures_levels
--    for roomIndex,roomData in pairs(localdata or {}) do
--        for furnitureIndex,furnitureData in pairs(roomData.furnitures or{}) do
--            local furnitureId = furnitureData.id
--            local currCgf = furnitureCfg[furnitureId] or {}
--            local currLevelCfg = currCgf[furnitureData.level or 0]
--            if currLevelCfg and currLevelCfg.power_consume > 0 then
--                    power = power + currLevelCfg.power_consume
--            end
--        end
--    end
--
--    local buildingPower = GreateBuildingMana:GetPowerImprove()
--    return power + buildingPower
--end

function FloorMode:isWarmPower(power, totalpower)--是否出现红字提示
    if not power then
        power = PowerManager:GetCurrentPower()
    end

    --if not totalpower then
    --    totalpower = self:GetTotalPower()
    --end

    return power <= 0
end

function FloorMode:IsWorkerSatisfy(roomIndex)
    
end

function FloorMode:PowerEnough(num)
    local power, _ = PowerManager:GetCurrentPower()
    --local totalPower = self:GetTotalPower()
    return power - num >= 0
end

function FloorMode:GetAllWorldRent()--计算所有国家加一起的收益
    local allWorldRent = 0
    for k,v in pairs(ConfigMgr.config_country) do
        allWorldRent =  allWorldRent + self:GetTotalRent(nil, k)
    end
    return allWorldRent
end

function FloorMode:GetTotalRent(roomIndex, countryId)--计算房间的总收益: (设施+公司) * (大楼倍率+商城倍率)
    local totalRent = 0    
    local buildingData
    local companyData
    local currCity
    if countryId == 0 then countryId = nil end
    if countryId == 3 then
        countryId = GameTableDefine.CityMode:CheckBuildingSatisfy(700) and 2 or 1
    end
    if countryId then
        buildingData = LocalDataManager:GetDataByKey("rooms" .. CountryMode.SAVE_KEY[countryId])
        companyData = LocalDataManager:GetDataByKey("company_in_rooms" .. CountryMode.SAVE_KEY[countryId])
        currCity = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[countryId]).currBuidlingId or 100
    else
        buildingData = LocalDataManager:GetDataByKey(CountryMode.rooms)
        companyData = LocalDataManager:GetDataByKey(CountryMode.company_in_rooms)
        currCity = LocalDataManager:GetDataByKey(CITY_RECORD).currBuidlingId or 100
    end 
    
    local furnitureCfg = ConfigMgr.config_furnitures_levels
    local companyCfg = ConfigMgr.config_company

    local getRentByRoomIndex = function(index)
        local roomData = buildingData[index]
        if not roomData then
            return 0
        end
        
        local totalRent = 0
        local checkRent = 0  
        local beforeCEOAddRent = 0
        --local companyId = CompanyMode:CompIdByRoomIndex(index)
        local companyId = nil
        if companyData[index] and companyData[index].company_id then
            companyId = companyData[index].company_id
        end
        if companyId then--没公司则完全没有收益
            local currCompanyRent = 0
            local currBuildingRent = 0

            local currCompanyData = companyData[index]
            local currLevel = CompanyMode:GetCompanyLevel(companyId)
            local cfg = companyCfg[currCompanyData.company_id]
            currCompanyRent = cfg.base_rent[currLevel > cfg.levelMax and cfg.levelMax or currLevel]

            for furnitureIndex,furnitureData in pairs(roomData.furnitures or {}) do
                local currCfg = furnitureCfg[furnitureData.id] or {}
                local currLevelCfg = currCfg[furnitureData.level]
                if currLevelCfg and currLevelCfg.rent_addition then
                    currBuildingRent = currBuildingRent + currLevelCfg.rent_addition
                end
            end

            local satisfy = CompanyMode:checkRoomSatisfy(index, companyId, countryId)
            if not satisfy then
                currCompanyRent = currCompanyRent * ConfigMgr.config_global.rent_debuff
            end

            totalRent = currCompanyRent + currBuildingRent;
            checkRent, beforeCEOAddRent = self:GetSingleOfficeRent(index)
        end

        return checkRent, beforeCEOAddRent
    end

    if roomIndex then
        totalRent = getRentByRoomIndex(roomIndex)
    else
        for index,roomData in pairs(buildingData or {}) do
            local curRoomRealRent = getRentByRoomIndex(index)
            totalRent = totalRent + curRoomRealRent
        end
    end

    local managerRent,useLess = self:GetManagerFurnituresBonus(countryId)
    totalRent = totalRent + managerRent

    
    local currRent = 1
    if(currCity ~= nil) then
        currRent = ConfigMgr.config_buildings[currCity].money_enhance--当前大楼的收益系数
    end

    currRent = currRent + ShopManager:GetCashImprove(nil, countryId)
    return math.floor(totalRent * currRent)
end

function FloorMode:GetCurrImprove()
    local currCity = LocalDataManager:GetDataByKey(CITY_RECORD).currBuidlingId or 100
    local currRent = 1
    if(currCity ~= nil) then
        currRent = ConfigMgr.config_buildings[currCity].money_enhance--当前大楼的收益系数
    end

    currRent = currRent + ShopManager:GetCashImprove()
    return currRent
end

function FloorMode:GetRent(roomIndex, check)--计算单独设施租金
    local rent = 0
    local localdata = LocalDataManager:GetDataByKey(CountryMode.rooms)
    local furnitureCfg = ConfigMgr.config_furnitures_levels
    for index,roomData in pairs(localdata or {}) do
        for furnitureIndex,furnitureData in pairs(roomData.furnitures or{}) do
            local need = roomIndex == nil or roomIndex == index--是否需要该数据
            local rentAble = roomData.type == 1 and (CompanyMode:CompIdByRoomIndex(index) ~= nil or check) --只有可入驻的房间,设施才有租金加成
            if need == false or roomData.unlock == false or rentAble == false then break end

            local furnitureId = furnitureData.id
            local currCfg = furnitureCfg[furnitureId] or {}
            local currLevelCfg = currCfg[furnitureData.level]
            if currLevelCfg and currLevelCfg.rent_addition then
                rent = rent + currLevelCfg.rent_addition
            end
        end
    end

    return rent
end

function FloorMode:GetSceneEnhance()
    local currCity = LocalDataManager:GetDataByKey(CITY_RECORD).currBuidlingId
    local currRent = 1
    if currCity ~= nil then
        currRent = ConfigMgr.config_buildings[currCity].money_enhance--当前大楼的收益系数
    end
    
    currRent = currRent + ShopManager:GetCashImprove()
    return currRent
end

function FloorMode:GetCompanyImporve(roomIndex)
    local companyId = CompanyMode:CompIdByRoomIndex(roomIndex)
    if companyId == nil then
        return 0
    end
    local companyQuality = ConfigMgr.config_company[companyId].company_quality
    return 1 + ConfigMgr.config_global.bonus_company[companyQuality]
end

function FloorMode:GetCompanyRent(roomIndex)
    local rent = 0
    local localdata = LocalDataManager:GetDataByKey(CountryMode.rooms)
    local companyCfg = ConfigMgr.config_company
    for index,roomData in pairs(localdata or {}) do
        local need = index == roomIndex or roomIndex == nil
        if need == true and roomData.unlock == true then
            local companyId = CompanyMode:CompIdByRoomIndex(index)
            if companyId then
                local cfg = companyCfg[companyId] or nil
                local lv = CompanyMode:GetCompanyLevel(companyId)
                --cfg = cfg and cfg.base_rent or 0
                local currRent = cfg.base_rent[lv > cfg.levelMax and cfg.levelMax or lv]
                local satisfy = CompanyMode:IsRoomSatisfy(index)
                if not satisfy then
                    currRent = currRent * ConfigMgr.config_global.rent_debuff
                end
                rent = rent + currRent
            end
        end
    end
    
    return rent
end

function FloorMode:GetEmployeePay(roomIndex)
    local rent = 0
    local localdata = LocalDataManager:GetDataByKey(CountryMode.rooms)
    local furnitureCfg = ConfigMgr.config_furnitures_levels
    for index,roomData in pairs(localdata or {}) do
        for furnitureIndex,furnitureData in pairs(roomData.furnitures or{}) do
            local need = roomIndex == nil or roomIndex == index--是否需要该数据
            local rentAble = roomData.type ~= 1
            if need == false or roomData.unlock == false or rentAble == false then break end

            local furnitureId = furnitureData.id
            local currLevelCfg = furnitureCfg[furnitureId][furnitureData.level]
            if currLevelCfg and currLevelCfg.rent_addition and currLevelCfg.rent_addition < 0 then
                rent = rent + currLevelCfg.rent_addition
            end
        end
    end
    
    return rent
end

function FloorMode:GetQuality()
    local totalQuality = {rent_addition = 0, support = 0, office = 0, clean = 0, comfort = 0, health = 0, network = 0, addexp = 0, time = 0, pleasure = 0}
    local localData = LocalDataManager:GetDataByKey(CountryMode.rooms)
    local furnitureCfg = ConfigMgr.config_furnitures_levels

    for r_index, r_data in pairs(localData or {}) do
        for f_index, f_data in pairs(r_data.furnitures or {}) do
            if f_data.level > 0 then
                local currData = furnitureCfg[f_data.id][f_data.level]
                for q_index, q_data in pairs(totalQuality) do
                    local value = currData[q_index] or 0
                    totalQuality[q_index] = totalQuality[q_index] + value
                end
            end
        end
    end
    return totalQuality
end

function FloorMode:OfflineRewardRate(countryId)
    local currCity = LocalDataManager:GetDataByKey(CITY_RECORD).currBuidlingId
    if countryId then currCity = LocalDataManager:GetDataByKey("city_record_data" .. CountryMode.SAVE_KEY[countryId]).currBuidlingId end
    if currCity == nil then return 0 end
    return ConfigMgr.config_buildings[currCity].reward_index
end

function FloorMode:UnlockRoom(cash, config)
    if StarMode:GetStar() < (config.star or 0) then
		EventManager:DispatchEvent("UI_NOTE", "star is not enough")
        return
    end

    ResMgr:SpendLocalMoney(cash, ResMgr.EVENT_UNLOCK_ROOM, function(isEnough)
        if isEnough then
            self.m_curBuildingAllRoomsData[config.room_index].toUnlock = true
            self.m_curBuildingAllRoomsData[config.room_index].unlockTime = TimerMgr:GetCurrentServerTime(true) + config.unlock_times
            local furnitureLv = 0
            for i, furniture in ipairs(config.furniture or {}) do
                local furnitureData = self.m_curBuildingAllRoomsData[config.room_index].furnitures[i]
                furnitureData.level = furniture.level or 0
                furnitureData.level_id = 0
                if furnitureData.level > 0 then
                    furnitureData.level_id = ConfigMgr.config_furnitures_levels[furnitureData.id][furnitureData.level]["id"]
                    furnitureLv = furnitureData.level

                    self.m_curRoomIndex = config.room_index
                    self:BuyFurniture(i, furniture.id, true)
                    self.m_curRoomIndex = nil
                end
            end
            
            local roomId = self:GetRoomIdByRoomIndex(config.room_index)

            GameSDKs:TrackForeign("build_upgrade", {build_id = roomId, build_level_new = 1, operation_type = 1, scene_id = CityMode:GetCurrentBuilding()})

            --2024-8-20添加用于设施升级到的钞票消耗埋点上传
            --获取当前房间是属于哪个地区的
            local type = CountryMode:GetCurrCountry()            
            local amount = cash
            local change = 1
            local position = "["..roomId.."]号办公楼房间解锁"
            GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0,amount_new = tonumber(amount) or 0, position = position})

            FloorScene:InitRoomGo(roomId)
            MainUI:RefreshQuestHint()
            GameTimer:CreateNewMilliSecTimer(300, function()
                FloorScene:RefreshInteraction(roomId, furnitureLv)
            end)
            if config.room_index_number == ConfigMgr.config_global.rate_appear[2] then
                RateUI:ShowPanel()
            end
        end
    end)
end

function FloorMode:IsUnlockRoomById(roomId)
    local data = self:GetAllRoomsLocalData()
    local roomConfig = ConfigMgr.config_rooms[roomId]
    local roomData = data[roomConfig.room_index]
    if not roomData then
        return false
    end

    return roomData.unlock
end

function FloorMode:IsUnlockRoomByIndexNum(roomIndex)
    local roomId = self:GetRoomIdByRoomIndex(roomIndex)
    if not roomId then
        return false
    end
    return self:IsUnlockRoomById(roomId)
end

function FloorMode:BuildRoomNow(config, diamondNeed, cb)
    ResMgr:SpendDiamond(diamondNeed, nil, function(isEnough)
        if isEnough then
            self.m_curBuildingAllRoomsData[config.room_index].unlockTime = 1
            -- GameSDKs:Track("cost_diamond", {cost = diamondNeed, left = ResMgr:GetDiamond(), cost_way = "加速房间解锁"..config.id})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "加速房间解锁"..config.id, behaviour = 2, num_new = tonumber(diamondNeed)})
            FloorScene:InitRoomGo(self:GetRoomIdByRoomIndex(config.room_index))
        end
        cb(isEnough)
    end)
end

function FloorMode:RefreshFloorScene(roomIndex)
    FloorScene:InitRoomGo(self:GetRoomIdByRoomIndex(roomIndex))
end

function FloorMode:RefreshFloorSceneById(roomId)
    FloorScene:InitRoomGo(roomId)
end

function FloorMode:GetRoomIdByRoomIndex(roomIndex)
    roomIndex = self:RoomIndexNumber2RoomIndex(roomIndex)
    if self.m_allRoomsIdInBuilding then
        return self.m_allRoomsIdInBuilding[roomIndex]
    end
end

function FloorMode:GetRoomIndexNumberByRoomIndex(roomIndex)
    return string.match(roomIndex, "%d+")
end

function FloorMode:IsTypeOffice(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_OFFICE
end

function FloorMode:IsTypeProperty(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_PROPERTY
end

function FloorMode:IsTypeMeeting(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_MEETING
end

function FloorMode:IsTypeToile(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_TOILE
end

function FloorMode:IsTypePower(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_POWER
end

function FloorMode:IsTypeManager(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_MANAGER
end

function FloorMode:IsTypeFinancial(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_FINANCIAL
end

function FloorMode:IsTypeRest(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_REST
end

function FloorMode:IsTypeEntertainment(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_ENTERTAINMENT
end

function FloorMode:IsTypeGym(category)
    if not category then
        return false
    end
    return category[2] == ROOM_TYPE_GYM
end

function FloorMode:IsSpecialRoom(category)
    if not category then 
        return false
    end
    return category[2] == ROOM_TYPE_MANAGER or category[2] == ROOM_TYPE_PROPERTY
end

function FloorMode:IsOfficeRoom(category)
    if not category then 
        return false
    end
    return category[2] == ROOM_TYPE_OFFICE
end

function FloorMode:GetRoomFurnitureByIndex(index, level, roomIndex)
    local data = self:GetAllRoomsLocalData()
    --如果data为空,直接返回0
    if next(data) == nil then
        return 0
    end

    if roomIndex then
        data = data[roomIndex]
    end

    local compareLevel = level == nil and 0 or level
    for k, furniture in pairs(data.furnitures or {}) do
        if k == index then
            return furniture.level >= compareLevel
        end
    end

    return false
end

function FloorMode:GetRoomFurnitureNum(id, lv, roomIndex)
    local data = self:GetAllRoomsLocalData()
    --如果data为空,直接返回0
    if next(data) == nil then
        return 0
    end

    if roomIndex then
        data = data[roomIndex]
    end

    if not data then
        return 0
    end

    local num = 0
    local compareLevel = lv == nil and 0 or lv

    for k, furniture in pairs(data.furnitures or {}) do
        if furniture.id == id and furniture.level >= compareLevel then
            num = num + 1
        end
    end

    return num
end

function FloorMode:GetFurnitureSameLevelNumber(furnitureLevelId)
    local data = self:GetAllRoomsLocalData()
    local num = 0
    for k,room in pairs(data) do
        for k2,furniture in pairs(room.furnitures) do
            if furniture.level_id == furnitureLevelId then
                num = num + 1
            end
        end
    end
    return num
end

function FloorMode:GetFurnitureNum(id, lv, roomIndex)
    local data = self:GetAllRoomsLocalData()
    if roomIndex then
        local temp = data[roomIndex]
        data = {}
        data[roomIndex] = temp
    end
    local num = 0
    for k,room in pairs(data) do
        for k2,furniture in pairs(room.furnitures) do
            if (furniture.id % 100)== (id % 100)  and furniture.level >= lv then
                num = num + 1
            end
        end
    end
    return num
end

function FloorMode:GetUnlockRoomSameCategoryNumber(category)
    local data = self:GetAllRoomsLocalData()
    local num = 0
    for k,room in pairs(data) do
        if room.type == category and room.unlock then
            num = num + 1
        end
    end
    return num
end

function FloorMode:SetFurnitureOnCenter(cameraFocus, isBack)
    local scene = self:GetScene()
    local go = scene.selectFurniturePositionGo
    local size = cameraFocus.m_cameraSize
    local speed = cameraFocus.m_cameraMoveSpeed
    local target2DPosition = cameraFocus.position
    local cb = nil
    if isBack then
        local data = scene:GetSetCameraLocateRecordData() or {}
        data.isBack = true
        size = data.offset or size
        target2DPosition = data.offset2dPosition
        go = data.go3d
        cb = nil
    elseif not scene:GetSetCameraLocateRecordData() then
        cb = function()
            local roomCfg = ConfigMgr.config_rooms[self.m_curRoomId]
            SoundEngine:PlaySFX(SoundEngine.ROOM_SFX[roomCfg.category[2]])
        end
    end 
    if not go then
        return
    end
    --start2DPositon.z = 0
    scene:Locate3DPositionByScreenPosition(go, target2DPosition, size, speed, cb)
end

function FloorMode:IsRoomBroken(roomIndex)
    local loaclData = self:GetRoomLocalData(roomIndex)
    if loaclData then
        return loaclData.room_broken_cfg_id ~= nil
    end
    return false
end

---计算房间是否损坏 todo 消耗特别大
function FloorMode:UpdateRoomsBroken()
    --if TimerMgr:GetSocketTime() - (self.lastRoomBrokenTime or 0) < 1
    --then
    --    return
    --end
    --self.lastRoomBrokenTime = TimerMgr:GetSocketTime() --很多都是间隔1s错峰

    --local localData = self:GetAllRoomsLocalData()
    --for roomIndex, data in pairs(localData) do
    --    local roomId = self:GetRoomIdByRoomIndex(roomIndex)
    --    local roomConfig = ConfigMgr.config_rooms[roomId]
    --    if tonumber(data.room_broken_cd) or not data.room_broken_cd then
    --        data.room_broken_cd = {}
    --    end
    --    self:UpdateRoomBroken(data, roomConfig)
    --    self:UpdateOfficeBreaking(data, roomConfig)
    --    if data.room_broken_cfg_id then
    --        local roomGoDdata = FloorScene:GetRoomRootGoData(roomConfig.id)
    --        PropertyServiceManager:RequestRoomService(roomGoDdata, data.room_broken_cfg_id, true)
    --    end
    --end

    --每帧只更新一个房间,并且至少间隔一秒才会从新计算.
    if self.m_lastRoomBrokenIndex == 0 and TimerMgr:GetSocketTime() - self.lastRoomBrokenTime < 1 then
        return
    end
    local localData = self:GetAllRoomsLocalData()
    local data,roomIndex
    local index = 0
    for k, v in pairs(localData) do
        index = index+1
        if index == self.m_lastRoomBrokenIndex then
            data = v
            roomIndex = k
            break
        end
    end
    if not data then
        self.m_lastRoomBrokenIndex = 0
        roomIndex,data = next(localData)
        self.lastRoomBrokenTime = TimerMgr:GetSocketTime()
    end
    if data then
        local roomId = self:GetRoomIdByRoomIndex(roomIndex)
        local roomConfig = ConfigMgr.config_rooms[roomId]
        if tonumber(data.room_broken_cd) or not data.room_broken_cd then
            data.room_broken_cd = {}
        end
        self:UpdateRoomBroken(data, roomConfig)
        self:UpdateOfficeBreaking(data, roomConfig)
        if data.room_broken_cfg_id then
            local roomGoData = FloorScene:GetRoomRootGoData(roomConfig.id)
            PropertyServiceManager:RequestRoomService(roomGoData, data.room_broken_cfg_id, true)
        end
        self.m_lastRoomBrokenIndex = self.m_lastRoomBrokenIndex+1
    end
end

function FloorMode:UpdateRoomBroken(localData, config)
    if not config then
        return
    end
    --local roomGodata = FloorScene:GetRoomRootGoData(config.id)
    for k,v in pairs(ConfigMgr.config_emergency or {}) do
        local id = self:CheckRoomBroken(localData, config, v)
        if id then
            localData.room_broken_cfg_id = id
            localData.room_broken_cd["" .. id] =(v.cd or 0)
            LocalDataManager:WriteToFile()
            local roomGoDdata = FloorScene:GetRoomRootGoData(config.id)
            -- CompanyEmployee:RequestRoomService(roomGoDdata, id, true)
            self:GetScene():InitRoomGoUIView(roomGoDdata)
            self:GetScene():PlayRoomBrokenVFX(config.id, true)
            if id == 200 then
                EventManager:DispatchEvent("Power_off",true) -- 找不到对应的注册事件?
            end
            return
        end
    end
end

function FloorMode:CheckRoomBroken(localData, roomConfig, emergencyConfig)
    if not roomConfig or not roomConfig.id then
        return
    end
    local roomGodata = FloorScene:GetRoomRootGoData(roomConfig.id)
    if not UnityHelper.HasFlag(emergencyConfig.room_category_tag, 1 << roomConfig.category[2])
        or localData.room_broken_cfg_id ~= nil
        or not localData.unlock 
        or not roomGodata
        or (FloorMode:IsTypeOffice(roomConfig.category) and not roomGodata.isWork)
        or (localData.room_broken_cd["" .. emergencyConfig.id] or 0) >= GameTimeManager:GetCurrentServerTime()
    then
        return
    end

    if emergencyConfig.id == 201 and self.isRoomBrokenGuide then
        if localData.using_count and localData.using_count > 5 then
            return emergencyConfig.id
        end
    end

    local p = 0
    if emergencyConfig.id == 200 then
        local power, _ = PowerManager:GetCurrentPower()
        local totalPower = PowerManager:GetTotalPower()
        p = (totalPower - power) * 100 / totalPower
        if p < emergencyConfig.happen_threshold then
            return
        end
    else
        p = emergencyConfig.id == 201 and localData.using_count or localData.using_time
        p = p or 0

        -- print("事件ID:", emergencyConfig.id, "房间:", roomConfig.id,  "当前数值:", p, "阀值:", roomConfig[string.format("emergency_%s_threshold", emergencyConfig.id)])
        if p and (p < roomConfig[string.format("emergency_%s_threshold", emergencyConfig.id)] or p % (emergencyConfig.random_interval or p) ~= 0) then
            return
        end
    end

    local random = math.random(0, 100)
    if random < emergencyConfig.happen_probility(p) then
        return emergencyConfig.id
    end
end

function FloorMode:UpdateOfficeBreaking(localData, config)
    if not config 
        or not self:IsTypeOffice(config.category) 
        or localData.room_broken_cfg_id ~= nil
        or not localData.unlock 
        or localData.unlockTime > 1
    then
        return
    end

    local roomGodata = FloorScene:GetRoomRootGoData(config.id)
    if roomGodata and roomGodata.isWork then
        local num = 0
        for i, v in pairs(localData.furnitures) do
            if v.level > 0 and v.id == 10001 then -- 工位
                num = num + 1
            end
        end
        localData.using_time = (localData.using_time or 0) + num
    end
end

function FloorMode:GetManagerFurnituresBonus(countryId)
    local benefit, offlimit = 0, 0
    local roomData
    if countryId then
        roomData = LocalDataManager:GetDataByKey("rooms" .. CountryMode.SAVE_KEY[countryId])
    else
        roomData = LocalDataManager:GetDataByKey(CountryMode.rooms)
    end    
    roomData = roomData["ManagerRoom_104"]
    if not roomData or not roomData.unlock then
        return benefit, offlimit
    end
 
    for i,v in ipairs(roomData.furnitures or {}) do
        if v.level > 0 then
            local levelCfg = ConfigMgr.config_furnitures_levels[v.id][v.level]
            benefit = (levelCfg.benefit or 0) + benefit
            offlimit = (levelCfg.offlimit or 0) + offlimit
        end
    end
    return benefit, offlimit
end

function FloorMode:RoomIndexNumber2RoomIndex(roomIndexNumber)
    if not tonumber(roomIndexNumber) then 
        return roomIndexNumber
    end
    for k,v in pairs(ConfigMgr.config_rooms or {}) do
        if v.room_index_number == tonumber(roomIndexNumber) then
            return v.room_index
        end
    end
end

function FloorMode:GetCurrentFloorIndex()
    return self.m_floorIndex or 1
end

function FloorMode:SetCurrentFloorIndex(index, isInit, cb)
    local cfg = self:GetCurrFloorConfig()
    if cfg.floor_count <= 1 then
        return
    end

    if isInit then
        for i=1,cfg.floor_count do
            --UnityHelper.MarkAsIgnoreRendererRootNode(floorDefGo)
            if i ~= 1 then
                local floorDefGo = GameObject.Find(i.."F").gameObject
                UnityHelper.IgnoreRenderer(floorDefGo, true)
            end
        end
        self.m_floorIndex = 1
        return
    end

    index = math.min(math.max(1, index), cfg.floor_count)
    if self.m_floorIndex == index then
        return
    end
    local last = self.m_floorIndex
    self.m_floorIndex = index
    self:GetScene():SwitchFloorIndex(last, cb)
end

function FloorMode:GoUpstairs()
    self:SetCurrentFloorIndex(self:GetCurrentFloorIndex() + 1)
end

function FloorMode:GoDownstairs()
    local cfg = self:GetCurrFloorConfig()
    self:SetCurrentFloorIndex(self:GetCurrentFloorIndex() - 1)
end

function FloorMode:InitSpecialBuilding(id, cb)
    if self.m_specialBuilding then
        return
    end
    
    EventManager:RegEvent("EVENT_S_BUILDING_LOCATE_POSITION", function(pos, showMove)
        if not pos then 
            return 
        end
        self:GetScene():LocatePosition(pos, showMove)
    end)
    self.m_specialBuilding = id
    self:GetScene():CreateSpecialHouse(id, cb)
end

function FloorMode:ExitSpecialBuilding(disableEffect, goOffice)
    EventManager:UnregEvent("EVENT_S_BUILDING_LOCATE_POSITION")
    if disableEffect then
        self:GetScene():LeaveSpecialBuilding()
        self.m_specialBuilding = nil
        return
    end

    -- 修改为返回为大地图
    local cb = function()             
        self:GetScene():LeaveSpecialBuilding()
        self.m_specialBuilding = nil
        FlyIconsUI:SetScenceSwitchEffect(-1)
        SoundEngine:SetTimeLineVisible(true)
        GameStateManager:EnterCity()
    end
    FlyIconsUI:SetScenceSwitchEffect(1, cb)
end

---买车返回办公室需要执行以下
function FloorMode:ExitCarShop()
    EventManager:UnregEvent("EVENT_S_BUILDING_LOCATE_POSITION")
    -- 修改为返回为大地图
    local cb = function()
        self:GetScene():LeaveCarShop()
        FlyIconsUI:SetScenceSwitchEffect(-1)
        SoundEngine:SetTimeLineVisible(true)
        if CountryMode:GetCurrCountry() ~= self.m_currFloorConfig.country then
            CountryMode:SetCurrCountry(self.m_currFloorConfig.country)
            GreateBuildingMana:RefreshImprove()
            MainUI:RefreshCashEarn()
            MainUI:UpdateResourceUI()
        end
        local buildingId = GameTableDefine.CityMode:GetCurrentBuilding()
        GameStateManager:EnterBuildingFloor({id = buildingId, config = GameTableDefine.ConfigMgr.config_buildings[buildingId]})
        CityMode:PlayDefaultSound()
        --MainUI:Hideing(true)
        --MainUI:Init(FloorMode:IsInOffice())
        --MainUI:SetPowerBtnState(true)
        FloorScene:SetBossStartWork(true)
    end
    FlyIconsUI:SetScenceSwitchEffect(1, cb)
end

function FloorMode:CheckWheelGo()
    if self:GetScene() and self:GetScene().wheelNode then
        return true
    end    
    return false
end
function FloorMode:CheckUseGravity()
    if self.m_currFloorConfig.country == 2  then
        return true
    end 
    return false
end

function FloorMode:GotoSpecialBuilding(id)
    local cb = function()
        FlyIconsUI:SetScenceSwitchEffect(-1)
        MainUI:PlayUIAnimation(true)
        MainUI:InitCameraScale("IndoorScale")
        local bgmPlay = SoundEngine[ConfigMgr.config_buildings[id].bgm]
        SoundEngine:PlayBackgroundMusic(bgmPlay, true)
    end

    MainUI:InitCameraScale("IndoorScale",nil, true)
    MainUI:PlayUIAnimation(false)
    FlyIconsUI:SetScenceSwitchEffect(1, function()
        FloorMode:InitSpecialBuilding(id, cb)
        MainUI:SetPowerBtnState(false)
    end)
end

function FloorMode:HandleCosts(costs)
    for k,v in pairs(costs) do
        self:HandleCost(v)
    end
end
function FloorMode:HandleCost(cost)
    if cost.type == 2 then
        cost.type = CountryMode:GetCurrCountryCurrency()
        --cost.num = ExchangeUI:CurrencyExchange(1, ExchangeUI:SwitchCurrencyId(cost.type), cost.num)
    end
end
function FloorMode:IsInHouse()
    return GameStateManager:IsInFloor() and self.m_specialBuilding and CityMode:IsTypeHouse(self.m_specialBuilding)
end

function FloorMode:IsInCarShop()
    return GameStateManager:IsInFloor() and self.m_specialBuilding and CityMode:IsTypeCarShop(self.m_specialBuilding)
end

function FloorMode:IsInFactory()
    return GameStateManager:IsInFloor() and self.m_specialBuilding and CityMode:IsTypeFactory(self.m_specialBuilding)
end

function FloorMode:IsInFootballClub()
    return GameStateManager:IsInFloor() and self.m_specialBuilding and CityMode:IsTypeFootballClub(self.m_specialBuilding)
end

function FloorMode:IsInOffice()
    return GameStateManager:IsInFloor() and (self.m_specialBuilding == nil or CityMode:IsTypeOffice(self.m_specialBuilding))
end

local roomNameDic = {}

function FloorMode:GetRoomName(room_index_number)
    local str = roomNameDic[room_index_number]
    if not str then
        str = GameTextLoader:ReadText("TXT_ROOM_R" .. room_index_number .. "_NAME")
        roomNameDic[room_index_number] = str
    end
    return str
    --return GameTextLoader:ReadText("TXT_ROOM_R" .. room_index_number .. "_NAME")
    -- if not roomCfg or not roomCfg.room_name then
    --     return ""
    -- end
    -- return GameTextLoader:ReadText(roomCfg.room_name)
end

local roomDescDic = {}
function FloorMode:GetRoomDesc(room_index_number)
    -- if not roomCfg or not roomCfg.room_desc then
    --     return ""
    -- end
    local str = roomDescDic[room_index_number]
    if not str then
        str = GameTextLoader:ReadText("TXT_ROOM_R" .. room_index_number .. "_DESC")
        roomDescDic[room_index_number] = str
    end
    return str
    --return GameTextLoader:ReadText("TXT_ROOM_R" .. room_index_number .. "_DESC")
    -- return GameTextLoader:ReadText(roomCfg.room_desc)
end

local furnitureNameDic = {}
function FloorMode:GetFurnitureName(id, level)
    local idDic = furnitureNameDic[id]
    if idDic then
        if not idDic[level] then
            idDic[level] = "TXT_FURNITURES_" .. id .. "_" .. level .. "_NAME"
        end
    else
        idDic = {}
        furnitureNameDic[id] = idDic
        idDic[level] = "TXT_FURNITURES_" .. id .. "_" .. level .. "_NAME"
    end
    return GameTextLoader:ReadText(idDic[level])
end

local furnitureDescDic = {}
function FloorMode:GetFurnitureDesc(id, level)
    local idDic = furnitureDescDic[id]
    if idDic then
        if not idDic[level] then
            idDic[level] = "TXT_FURNITURES_" .. id .. "_" .. level .. "_DESC"
        end
    else
        idDic = {}
        furnitureDescDic[id] = idDic
        idDic[level] = "TXT_FURNITURES_" .. id .. "_" .. level .. "_DESC"
    end
    return GameTextLoader:ReadText(idDic[level])
end

function FloorMode:GetCurBossEntity()
    if FloorScene then
        return FloorScene:GetCurBossEntity()
    end
    return nil
end
function FloorMode:GetCurSecretaryEntity()
    if FloorScene then
        return FloorScene:GetCurSecretaryEntity()
    end
    return nil
end

--[[
    @desc: 白天黑夜切换的相关逻辑
    author:{author}
    time:2023-09-04 18:29:02
    --@isDay: 
    @return:
]]
function FloorMode:SceneSwtichDayOrLight(isDay)
    if FloorScene then
        --设置场景上有vfx_day/vfx_night节点的打开和关闭
        FloorScene:SceneSwtichDayOrLight(isDay)
    end
end

function FloorMode:IsProcessDayNightScene()
    if FloorScene then
        return FloorScene:IsProcessDayNightScene()
    end
    return false
end

function FloorMode:SetSceneWheelNum(num)
    if FloorScene then
        FloorScene:SetSceneWheelNum(num)
    end
end

---获取当前所在的办公楼的BuildingID
function FloorMode:GetOfficeBuildingID()
    return self.m_officeBuildingID
end

---根据建筑ID确定是否该开启主摄像机的后处理
function FloorMode:ResetPostProcessing(buildingId)
    local mainCamera = GameTableDefine.GameUIManager:GetSceneCamera() ---@type UnityEngine.Camera
    if mainCamera then
        buildingId = buildingId or FloorMode:GetOfficeBuildingID()
        local buildingConfig = ConfigMgr.config_buildings[buildingId]
        if buildingConfig and buildingConfig.new_building == 1 then
            UnityHelper.SetCameraPostProcessing(mainCamera,false)
        else
            UnityHelper.SetCameraPostProcessing(mainCamera,true)
        end
    end
end

function FloorMode:GetSingleOfficeRent(roomIndex)
    local companyRent = FloorMode:GetCompanyRent(roomIndex)
    local baseRent = FloorMode:GetRent(roomIndex)
    local improve = FloorMode:GetSceneEnhance()
    local totalRent = (companyRent + baseRent) * improve
    local checkRent = totalRent

    --需要计算是否有CEO入住然后获取的收入增加2025-2-25 fy
    if GameTableDefine.CEODataManager:CheckCEOOpenCondition() then
        local haveCeoId = GameTableDefine.CEODataManager:GetCEOByRoomIndex(roomIndex)
        
        if haveCeoId then
            local furLvl = GameTableDefine.CEODataManager:GetCEOFurnitureLevelByRoomIndex(roomIndex)
            local ceoLvl = GameTableDefine.CEODataManager:GetCEOLevel(haveCeoId)
            local incomeAdd, expAdd = GameTableDefine.CEODataManager:GetCEOBuffAddValue(haveCeoId)
            local curDeskConfig = ConfigMgr.config_ceo_furniture_level[furLvl]
            if curDeskConfig then
                local furLevelEnough = curDeskConfig.table_ceo_limit>=ceoLvl
                if not furLevelEnough then
                    incomeAdd = ((incomeAdd - 1) * curDeskConfig.table_debuff) + 1
                    expAdd = ((expAdd - 1) * curDeskConfig.table_debuff) + 1
                end
                checkRent  = math.floor(totalRent * incomeAdd)
            end
        end
    end
    return checkRent, totalRent
end
