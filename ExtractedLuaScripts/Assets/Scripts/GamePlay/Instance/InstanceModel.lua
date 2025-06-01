--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 17:16:00
]]
---@class InstanceModel
local InstanceModel = GameTableDefine.InstanceModel
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceDataManager = GameTableDefine.InstanceDataManager
local FloatUI = GameTableDefine.FloatUI
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI
local GameUIManager = GameTableDefine.GameUIManager
local ActorManager = GameTableDefine.ActorManager
local SpicalRoomManager = GameTableDefine.SpicalRoomManager
local ShopManager = GameTableDefine.ShopManager
local InstanceAIBlackBoard = GameTableDefine.InstanceAIBlackBoard

local EventManager = require("Framework.Event.Manager")
local Execute = require("Framework.Queue.Execute")
local Class = require("Framework.Lua.Class");
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local InstanceScene = nil   ---@type InstanceScene
local roomSortConfig = nil   --将self.roomConfig按照所需材料等级从低到高排序结果
local attrThreshold = nil   --属性阈值
local stateDebuff = nil   --属性debuff效果
local isOpenExitPop = false

--[[
    @desc: 声明所有变量
    author:{author}
    time:2023-03-31 11:36:28
    @return:
]]
function InstanceModel:DeclareVariable()
    self.instanceID = nil   --副本ID
    self.roomsConfig = nil  --所有房间配置数据
    self.furnitureConfig = nil --设备配置数据
    self.furnitureLevelConfig = nil --设备等级配置数据
    self.furnitureLevelConfig_furID = {} --根据furniturID保存家具等级表,避免大量遍历的消耗
    self.resourceConfig = nil --产出资源配置数据
    self.roomsData = {}    --所有房间存档数据
    self.isFirstInit = false    --是否是第一次初始化
    self.workerList = {}  --所有员工ID列表
    self.floatUI = {}   --floatUI传参使用
    self.productions = {}  --产品存量列表
    self.workCD = {} --用于计算建筑工作循环
    self.workerAttrCalInterval = 1  --工人属性计算间隔
    self.timeType = 0   --副本时间类型
    self.lastTime = nil --上一秒的副本时间
    self.actorSeatBind = {} --吃饭或睡觉时角色的座位对应
end

function InstanceModel:Init()
    self:DeclareVariable()
    Execute:Async({function()
        GameUIManager:SetFloatUILockScale(true, 18)
    end})
    self:InitConfigData()
    self:InitRoomData()
    self:InitWorkerList()
    self:RegisterEvnet()
    --初始化场景
    InstanceScene = require("GamePlay.Instance.InstanceScene").new()
    InstanceScene:InitScene()
    InstanceScene:OnEnter()
    self.timeType = InstanceDataManager:GetCurInstanceTimeType()
    self.lastTime = InstanceDataManager:GetCurInstanceTime()
end

--[[
    @desc: 初始化config数据
    author:{author}
    time:2023-03-31 11:36:56
    @return:
]]
function InstanceModel:InitConfigData()
    self.roomsConfig = InstanceDataManager.config_rooms_instance
    self.furnitureConfig = InstanceDataManager.config_furniture_instance
    self.furnitureLevelConfig = InstanceDataManager.config_furniture_level_instance
    self.resourceConfig = InstanceDataManager.config_resource_instance

    for k,v in pairs(self.furnitureLevelConfig) do
        local furID = v.furniture_id
        if not self.furnitureLevelConfig_furID[furID] then
            self.furnitureLevelConfig_furID[furID] = {}
        end
        table.insert(self.furnitureLevelConfig_furID[furID],v)
    end
end

--[[
    @desc: 初始化房间存档数据
    author:{author}
    time:2023-03-31 11:37:09
    @return:
]]
function InstanceModel:InitRoomData()
    for k,v in pairs(self.roomsConfig) do
        local roomID = v.id
        local data = InstanceDataManager:GetCurRoomData(roomID)
        if next(data) == nil then --第一次进入场景,创建存档数据结构
            local state = 0
            if v.unlock_times == 0 then
                state = 2
            end
            InstanceDataManager:SetRoomData(roomID,0,state)
        end
        self.roomsData[roomID] = InstanceDataManager:GetCurRoomData(roomID)
        
        --初始化设备数据
        if not self.roomsData[roomID].furList or next(self.roomsData[roomID].furList) == nil then
            for i,m in pairs(v.furniture) do
                local furLevelConfig = self:GetFurlevelConfig(m.id,m.level)
                local furState = 0
                if m.level == 1 then
                    furState = 1
                end
                local name = nil
                local attrs = nil
                local prefab = nil
                if furLevelConfig.isPresonFurniture then
                    name = self:GetRandomName()
                    attrs = {
                        hungry = InstanceDataManager.config_global.employeeUpperLimit,
                        physical = InstanceDataManager.config_global.employeeUpperLimit,
                    }
                    local prefabIndex =  math.random(#furLevelConfig.NPC_skin)
                    prefab = furLevelConfig.NPC_skin[prefabIndex]
                end
                local isOpen = nil
                if v.room_category == 4 then
                    isOpen = true
                end
                local furData = {
                    ["state"] = furState,
                    ["name"] = name,
                    ["Attrs"] = attrs,
                    ["prefab"] = prefab,
                    ["isOpen"] = isOpen
                }
                InstanceDataManager:SetRoomFurnitureData(roomID,i,furLevelConfig.id,furData)
            end
        end
       
    end      
end

--[[
    @desc: 初始化员工id列表
    author:{author}
    time:2023-03-31 11:40:44
    @return:
]]
function InstanceModel:InitWorkerList()
    local data = InstanceDataManager:GetCurRoomData()
    for k,v in pairs(self.roomsData) do
        if v.furList and next(v.furList) ~= nil then
            local roomID = v.roomID
            if not self.workerList[roomID] then
                self.workerList[roomID] = {}
            end
            for i,m in pairs(v.furList) do
                local furConfig = self:GetFurLevelConfigByLevelID(m.id)
                if furConfig.isPresonFurniture and m.state == 1 then
                    table.insert(self.workerList[roomID],m.index)  --m.id => furLevelID
                end
            end
        end
    end
end

--[[
    @desc: 注册事件
    author:{author}
    time:2023-03-31 13:39:52
    @return:
]]
function InstanceModel:RegisterEvnet()
    EventManager:RegEvent("INSTANCE_TIME_TYPE_CHANGE", function(last,current)
        self.timeType = current
        
        if last ~= InstanceDataManager.timeType.work then
            self:WorkerAttrRevert(last,false)
        end

        if current ~= InstanceDataManager.timeType.work then
            self:WorkerAttrRevert(current,true)
        end

        if current == InstanceDataManager.timeType.work then
            SpicalRoomManager:InstanceWorkTime()
        elseif current == InstanceDataManager.timeType.eat then
            SpicalRoomManager:InstanceEatTime()
        elseif current == InstanceDataManager.timeType.sleep then
            SpicalRoomManager:InstanceSleepTime()
        end

    end)
end

--[[
    @desc: 注销事件
    author:{author}
    time:2023-03-31 13:40:06
    @return:
]]
function InstanceModel:UnregisterEvent()
    EventManager:UnregEvent("INSTANCE_TIME_TYPE_CHANGE")
end

function InstanceModel:OnEnter()
    attrThreshold = InstanceDataManager.config_global.stateThreshold
    stateDebuff = InstanceDataManager.config_global.stateDebuff
    isOpenExitPop = false
    --将房间按照产出需要的原料序号从低到高排序,顺序计算每种产品的总量
    roomSortConfig = {}
    for k,v in pairs(self.roomsConfig) do
        table.insert(roomSortConfig,v)
    end
    table.sort(roomSortConfig,function (a,b)
        return a.material[1] < b.material[1]
    end)

    
    for k,v in pairs(self.roomsData) do
        local roomCfg = self.roomsConfig[v.roomID]
        local current = GameTimeManager:GetCurrentServerTime(true)
        if roomCfg.room_category == 4 then
            --如果是港口则需要保存每条船的CD
            self.workCD[v.roomID] = {}
            for i,m in pairs(v.furList) do
                if not m.lastReachTime then   --如果存档中没有船的数据
                    local furData = {
                        ["isOpen"] = true,
                        ["lastReachTime"] = current,
                        ["lastLeaveTime"] = 0,
                    }
                    InstanceDataManager:SetRoomFurnitureData(v.roomID,m.index,m.id,furData)
                end
            end
            for i,m in pairs(v.furList) do
                if m.lastReachTime > m.lastLeaveTime then 
                    local curCD = current - (m.lastReachTime or 0)
                    self.workCD[v.roomID][m.index] = curCD 
                else
                    local curCD = current - (m.lastLeaveTime or 0)
                    self.workCD[v.roomID][m.index] = curCD
                end
            end
        elseif roomCfg.room_category == 1 then
            local lastSettlementTime = v.lastSettlementTime or current
            local roomCD = self:GetRoomCD(v.roomID)
            local curCD = (current - lastSettlementTime) % roomCD
            self.workCD[v.roomID] = curCD
        end

    end
    
    self.productions = Tools:CopyTable(InstanceDataManager:GetProdutionsData()) 
    if next(self.productions) == nil then
        for k,v in pairs(self.resourceConfig) do
            self.productions[tostring(k)] = 0
        end
    end

end

function InstanceModel:Update(dt)
    if InstanceDataManager:GetInstanceIsActive() then
        self:CalculateInstanceOnlineReward(dt)

        if InstanceScene then
            InstanceScene:Update(dt)
        end
        if GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI,true) then
            GameTableDefine.InstancePopUI:CheckGiftPopShow()
        end
    else
        local instanceMainViewIndex = GameUIManager:GetUIIndex(ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI, true)
        if not isOpenExitPop and GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI,true) then
            local txt = GameTextLoader:ReadText("TXT_INSTANCE_TIP_END")
            isOpenExitPop = true
            GameTableDefine.ChooseUI:CommonChoose(txt, function()
                InstanceMainViewUI:Exit()
            end, false, function()
                isOpenExitPop = false
            end)
            -- 如果正在开启引导则强制退出引导
            GameTableDefine.GuideManager:EndStep()
            GameTableDefine.GuideUI:CloseView()
        end
    end

    ActorManager:Update(dt)
    local Input = CS.UnityEngine.Input
    local KeyCode = CS.UnityEngine.KeyCode 
    -- end
    if GameConfig:IsDebugMode() then
        if GameDeviceManager:IsiOSDevice() then

        elseif GameDeviceManager:IsAndroidDevice() then

        else
            if Input.GetMouseButtonDown(2) then
                GameTableDefine.CheatUI:GetView()
            end
        end
    end

    -- if Input.GetKeyDown(KeyCode.Z) then
    --     self:CalculateOfflineRewards(7200,false,true)
    -- end
    -- if Input.GetKeyDown(KeyCode.X) then
    --     self:WorkerAttrRevert(InstanceDataManager.timeType.sleep)
    -- end
    -- if Input.GetKeyDown(KeyCode.C) then
    --     self:GetCurProductionsByTime(120,true)
    -- end
    -- if Input.GetKeyDown(KeyCode.V) then
    --     InstanceDataManager:AddCurInstanceCoin(1000000000)
    --     InstanceMainViewUI:Refresh()
    -- end

end

function InstanceModel:OnExit() 
    InstanceScene:OnExit()
end

--[[
    @desc: 房间是否解锁
    author:{author}
    time:2023-03-31 13:41:01
    @return:
]]
function InstanceModel:RoomIsUnlock(roomID)
    local roomData = self.roomsData[roomID]
    return roomData.state > 1
end

--[[
    @desc: 购买房间
    author:{author}
    time:2023-03-31 13:41:14
    --@roomID: 
    @return:
]]
function InstanceModel:BuyRoom(roomID)
    --设置存档信息
    local timePoint = GameTimeManager:GetCurrentServerTime(true)
    InstanceDataManager:SetRoomData(roomID,timePoint,1)

    InstanceScene:RefreshRoom(roomID)
    --花钱
    local cost = self.roomsConfig[roomID].unlock_require
    InstanceDataManager:AddCurInstanceCoin(-cost)
    InstanceMainViewUI:Refresh()
    
    --AI通知, 现在直接在购买时通知AI会导致房子还在建,排队的人已经进入睡觉或吃饭了, 所以先注释掉  
    --local roomCfg = self.roomsConfig[roomID]
    --for i = 1, #roomCfg.furniture do
    --    local furData = roomCfg.furniture[i]
    --    local furLevelCfg = self:GetFurlevelConfig(furData.id,furData.level)
    --    InstanceAIBlackBoard:OnBuyFurCallBack(roomCfg, i, furLevelCfg)
    --end

    --埋点
    for k,v in pairs(self.roomsData[roomID].furList) do
        if v.state == 1 then
            local furLevelID = v.id
            local furLevelCfg = self.furnitureLevelConfig[furLevelID]
            --GameSDKs:TrackForeign("equipment_upgrade", {equipment_id_instance = tostring(furLevelCfg.furniture_id) , equipment_level_instance = furLevelCfg.level , room_id_instance  = tostring(roomID)})
            --local res,money = self:CalculateOfflineRewards(60,false,false)
            --if money == 0 then
            --    money = 1
            --end
            --local moneyFormat = math.floor(money)
            -- GameSDKs:TrackForeign("equipment_upgrade", {equipment_id_instance = tostring(furLevelCfg.furniture_id) , 
            -- equipment_level_instance = furLevelCfg.level , room_id_instance  = tostring(roomID),
            --     --[[ cost_instance = cost,
            --                 productivity_instance = moneyFormat, cpp_instance = cost/moneyFormat ]]
            -- })
        end
    end

end

--[[
    @desc: 检查房间是否满足解锁条件
    author:{author}
    time:2023-03-31 13:41:40
    --@roomID: 
    @return:
]]
function InstanceModel:CheckRoomCondition(roomID)
    local roomData = InstanceDataManager:GetCurRoomData(roomID)
    local roomConfig = self:GetRoomConfigByID(roomID)
    local money = InstanceDataManager:GetCurInstanceCoin()
    local lastRoomData = InstanceDataManager:GetCurRoomData(roomConfig.unlock_room)
    if roomData and next(roomData) ~= nil and roomConfig.unlock_require <= money and lastRoomData and lastRoomData.state and lastRoomData.state == 2 then
        return true
    else
        return false
    end
end

--[[
    @desc: 购买家具
    author:{author}
    time:2023-03-31 13:42:02
    --@furLevelID: 
    @return:
]]
function InstanceModel:BuyFurniture(roomID,index,furLevelID)
    local roomData = self.roomsData[roomID]
    local furData = roomData.furList[tostring(index)]
    local isNew = true
    if furData and next(furData) ~= nil then
        isNew = false
    end
    --设置存档信息
    InstanceDataManager:SetRoomFurnitureData(roomID,index,furLevelID,{["state"] = 1})
    --刷新工人列表
    local furLevelData = self:GetFurLevelConfigByLevelID(furLevelID)
    if furLevelData.isPresonFurniture and furLevelData.level == 1 then
        table.insert(self.workerList[roomID],index)
    end
    
    --刷新场景中的物体
    InstanceScene:RefreshRoom(roomID,index,true)

    --花钱
    local furLevelCfg = self.furnitureLevelConfig[furLevelID]
    local cost = furLevelCfg.cost
    InstanceDataManager:AddCurInstanceCoin(-cost)
    InstanceMainViewUI:Refresh()         

    --显示通知
    if furLevelCfg.level == 1 and furLevelCfg.isPresonFurniture then
        InstanceMainViewUI:CallNotify(1)
    end
    
    --AI通知
    local roomCfg = self.roomsConfig[roomID]
    InstanceAIBlackBoard:OnBuyFurCallBack(roomCfg, index, furLevelCfg)
    
    --埋点
    --GameSDKs:TrackForeign("equipment_upgrade", {equipment_id_instance = tostring(furLevelCfg.furniture_id) , equipment_level_instance = furLevelCfg.level, room_id_instance  = tostring(roomID)})
    --local _,money = self:CalculateOfflineRewards(60,false,false)
    --money = math.floor(money)
    --if money == 0 then
    --    money = 1
    --end
    -- GameSDKs:TrackForeign("equipment_upgrade", {equipment_id_instance = tostring(furLevelCfg.furniture_id) , 
    -- equipment_level_instance = furLevelCfg.level, room_id_instance = tostring(roomID),
    --     --[[ cost_instance = cost, productivity_instance = money,
    --         cpp_instance = cost/money]]
    -- })
end

--[[
    @desc: 检查家具是否满足解锁条件
    author:{author}
    time:2023-03-31 13:42:18
    --@furLevelID: 
    @return:
]]
function InstanceModel:CheckFuinitureCondition(furLevelID)
    local furLevelConfig = self.furnitureLevelConfig[furLevelID]
    local curCash = InstanceDataManager:GetCurInstanceCoin()
    local canBuy = curCash >= furLevelConfig.cost

    return canBuy,furLevelConfig.cost
end

--[[
    @desc: 刷新副本场景
    author:{author}
    time:2023-05-06 18:09:44
    @return:
]]
function InstanceModel:RefreshScene()
    InstanceScene:RefreshScene()
end

--[[
    @desc: 刷新房间显示
    author:{author}
    time:2023-04-09 14:14:25
    @return:
]]
function InstanceModel:RefreshRoom(roomID,index)
    InstanceScene:RefreshRoom(roomID,index)
end

--[[
    @desc: 根据设备ID获取furConfig
    author:{author}
    time:2023-04-04 16:04:08
    --@furID: 
    @return:
]]
function InstanceModel:GetFurConfigByID(furID)
    for k,v in pairs (InstanceDataManager.config_furniture_instance) do
       if v.id == furID then
            return v
       end 
    end
    return nil
end

--[[
    @desc: 根据设备ID获取furLevelConfig
    author:{author}
    time:2023-04-04 16:04:40
    --@furLevelID: 
    @return:
]]
function InstanceModel:GetFurLevelConfigByLevelID(furLevelID) 
    return ConfigMgr.config_furniture_level_instance[furLevelID] or nil
end

--[[
    @desc: 根据设备ID和设备等级获取furLevelConfig
    author:{author}
    time:2023-04-04 16:04:48
    --@furID:
	--@level: 
    @return:
]]
function InstanceModel:GetFurlevelConfig(furID,level)
    if level == 0 then
        level = 1
    end
    for k,v in pairs(self.furnitureLevelConfig) do
        if v.furniture_id == furID and v.level == level then
            return v
        end
    end
end

function InstanceModel:GetFurlevelConfigByRoomFurIndex(roomID,index)
    local furLevelID = self.roomsData[roomID].furList[tostring(index)].id
    return self:GetFurLevelConfigByLevelID(furLevelID)
end

function InstanceModel:GetRoomConfigByID(roomID)
    return self.roomsConfig[roomID] or nil
end

function InstanceModel:GetRoomDataByID(roomID)
    return self.roomsData[roomID]
end

--[[
    @desc: 根据房间类型获取房间信息
    author:{author}
    time:2023-08-23 10:39:18
    --@type: 1:工厂 2:卧室 3:餐厅 4:码头
    @return:
]]
function InstanceModel:GetRoomDataByType(type)
    local result = nil 
    for k,v in pairs(self.roomsConfig) do
        if v.room_category == type  then
            if not result then
                result = {}
            end
            result[#result + 1] = self.roomsData[k]
        end
    end
    return result
end

--[[
    @desc: 卸载场景中的员工
    author:{author}
    time:2023-03-31 13:42:41
    @return:
]]
function InstanceModel:UnloadWorker()
end

--[[
    @desc: 随机取名
    author:{author}
    time:2023-04-09 10:55:27
    @return:
]]
function InstanceModel:GetRandomName()
    local configName = ConfigMgr.config_character_name
    --local lang = GameLanguage:GetCurrentLanguageID()
    local name = {
        [1] = math.random(1, #configName.first),
        [2] = math.random(1, #configName.second)
    }
    return name
end

--[[
    @desc: 获取房间解锁时间点
    author:{author}
    time:2023-04-09 10:55:14
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomUnlockTime(roomID)
    local roomData = self.roomsData[roomID]
    local unlockNeedTime = self.roomsConfig[roomID].unlock_times
    if roomData then
        local result = roomData.buildTimePoint + unlockNeedTime
        return result 
    else
        return 0
    end
end

--[[
    @desc: 获取一个房间已解锁的工人数量
    author:{author}
    time:2023-04-12 14:36:26
    @return:
]]
function InstanceModel:GetRoomUnlockWorkerCount(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local furLevelCfg = self.furnitureLevelConfig[v.id]
            if furLevelCfg.isPresonFurniture then
                count = count + 1               
            end
        end
    end
    return count
end

--[[
    @desc: 获取一个房间所有已解锁的座位数(餐厅座位/宿舍床位)
    author:{author}
    time:2023-04-10 17:09:27
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomSeatCount(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local seat =  self:GetFurLevelCfgAttrSum(v.id,"seat")
            count = count + seat
        end
    end
    return count
end 

--[[
    @desc: 获取一个家具(餐桌/床)座位的数量
    author:{author}
    time:2023-04-25 18:20:16
    --@furnitureID: 
    @return:
]]
function InstanceModel:GetAllFurSeatCount(furnitureID)
    local count = 0
    for k,v in pairs(self.furnitureLevelConfig) do
        if v.furniture_id == furnitureID and v.seat > 0 then
            count = count + v.seat
        end
    end
    return count
end

--[[
    @desc: 获取一个房间所有冷却缩减
    author:{author}
    time:2023-04-10 17:09:27
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomCDReduce(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local attrSum = self:GetFurLevelCfgAttrSum(v.id,"cooltime")
            count = count + attrSum
        end
    end
    return count
end 

--[[
    @desc: 获取房间工作CD
    author:{author}
    time:2023-04-17 15:59:34
    @return:
]]
function InstanceModel:GetRoomCD(roomID)
    local cd = self.roomsConfig[roomID].bastCD
    local reduce = self:GetRoomCDReduce(roomID)
    return cd - reduce
end

--[[
    @desc: 获取轮船CD
    author:{author}
    time:2023-04-18 15:49:45
    --@index: 船在港口设备列表中的位置索引
    @return: 轮船CD
]]
function InstanceModel:GetShipCD(index)
    local portID = 0
    local shipLevelID = 0
    for k,v in pairs(self.roomsConfig) do
        if v.room_category == 4 then
            portID = v.id 
            break
        end
    end
    shipLevelID = self.roomsData[portID].furList[tostring(index)].id
    local furlevelData = self.furnitureLevelConfig[shipLevelID]
    return furlevelData.shipCD
end

--[[
    @desc: 获取码头的容量
    author:{author}
    time:2024年3月4日11:28:15author
    --@index: 码头在港口设备列表中的位置索引
    @return: 码头最大容量
]]
function InstanceModel:GetPortStorage(index)
    local portID = 0
    for k,v in pairs(self.roomsConfig) do
        if v.room_category == 4 then
            portID = v.id 
            break
        end
    end
    local roomData = self.roomsData[portID]
    local portLevelID = roomData.furList[tostring(index)].id
    local furLevelData = self.furnitureLevelConfig[portLevelID]
    return furLevelData.storage
end

--[[
    @desc: 获取一个房间单位时间的产品产量
    author:{author}
    time:2023-04-10 17:35:47
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomProduction(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local production = self:GetFurLevelCfgAttrSum(v.id,"product")
            local debuff = 0
            if v.worker and v.worker.attrs.hungry < attrThreshold then
                debuff = debuff + stateDebuff
            end
            if v.worker and v.worker.attrs.physical < attrThreshold then
                debuff = debuff + stateDebuff
            end
            if v.worker then
                production = production * (1 - debuff)
            end
            count = count + production
        end
    end
    local productCfg = self.resourceConfig[roomData.id]
    return count, productCfg
end 

--[[
    @desc: 获取一个房间单位时间的材料消耗
    author:{author}
    time:2023-04-10 17:35:47
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomMatCost(roomID)
    local count = 0
    local roomCfg = self.roomsConfig[roomID]
    if #roomCfg.material > 1 then
        local production = self:GetRoomProduction(roomID)
        local materialCfg = self.resourceConfig[roomCfg.material[1]]
        count = production * roomCfg.material[2]
        return count, materialCfg
    else
        return count,nil
    end
end 

--[[
    @desc: 获取一个房间的饥饿值回复量
    author:{author}
    time:2023-04-13 09:53:07
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomHunger(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local production = self:GetFurLevelCfgAttrSum(v.id,"hungry")
            count = count + production
        end
    end
    return count
end

--[[
    @desc: 获取一个房间的体力值回复量
    author:{author}
    time:2023-04-13 09:53:07
    --@roomID: 
    @return:
]]
function InstanceModel:GetRoomPhysical(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local production = self:GetFurLevelCfgAttrSum(v.id,"phisical")
            count = count + production
        end
    end
    return count
end

--[[
    @desc: 获取一个家具在改等级所加的属性之和
    author:{author}
    time:2023-04-12 15:20:22
    --@levelID:
	--@attr: 
    @return:
]]
function InstanceModel:GetFurLevelCfgAttrSum(levelID,attr)
    local furLevelConfig = self.furnitureLevelConfig[levelID]
    if not furLevelConfig[attr] then
        return 
    end
    --local attrSum = 0
    --local furID = furLevelConfig.furniture_id
    --local findTable = self.furnitureLevelConfig_furID[furID]
    --for k,v in pairs(findTable) do
    --    if furID == v.furniture_id and v.level <= furLevelConfig.level then
    --        attrSum  = attrSum + v[attr]
    --    end
    --end
    --return attrSum
    return furLevelConfig.attrSum[attr]
end

--[[
    @desc: 获取某种资源是否被解锁
    author:{author}
    time:2023-04-19 15:01:05
    --@resourcesID: 
    @return:
]]
function InstanceModel:GetResIsUnlock(resourcesID)
    for k,v in pairs(self.roomsConfig) do
        if v.production == resourcesID and self.roomsData[v.id].state == 2 then
            return true
        end
    end
    return false
end

--[[
    @desc: 获取某种产品的材料
    author:{author}
    time:2023-04-19 15:19:30
    --@resourcesID: 
    @return:
]]
function InstanceModel:GetProductionMaterial(resourcesID)
    local resID,count 
    for k,v in pairs(self.roomsConfig) do
        if v.production == resourcesID then
            resID = v.material
            break
        end
    end
    count = self.productions[tostring(resID)] or 0
    return resID,count 
end

--[[
    @desc: 获取某种资源的单位产量和消耗 (/min)
    author:{author}
    time:2023-04-19 16:08:56
    --@resourcesID: 
    @return:
]]
function InstanceModel:GetProductionAndConsumptionPerMin(resourcesID)
    local Production,Consumption = 0,0
    for k,v in pairs(self.roomsData) do
        local roomID = v.roomID
        if v.state == 2 then
            local roomCfg = self.roomsConfig[roomID]
            if roomCfg.production == resourcesID then
                local curRoomProd = self:GetRoomProduction(roomID)
                local curRoomCD = self:GetRoomCD(roomID)
                curRoomProd = curRoomProd * 60 / curRoomCD
                Production = Production + curRoomProd
            end
            if roomCfg.material[1] == resourcesID then
                local curRoomCons = self:GetRoomMatCost(roomID)
                local curRoomCD = self:GetRoomCD(roomID)
                curRoomCons = curRoomCons * 60 / curRoomCD
                Consumption = Consumption + curRoomCons
            end
        end
    end

    return Production,Consumption
end

--[[
    @desc: 获取空座位
    author:{author}
    time:2023-04-14 11:00:08
    --@roomID: 房间ID
    --@index: 家具位置索引
    @return:房间ID,设备索引,房间GO,子设备GO
]]
function InstanceModel:GetEmptySeat(roomID, index)
    local roomID,index,subIndex,roomGO,furGO = roomID, index
    local InstanceRoom = InstnaceScene.Rooms[roomID]
    roomGO = InstanceRoom.GORoot
    local subFurList = InstanceRoom.roomGO.subFurList[index]
    for k,v in ipairs(subFurList) do
        if not v.isUsed then 
            subIndex = k
            furGO = v.GO
            break
        end
    end
    return roomID,index,subIndex,roomGO,furGO
end

--[[
    @desc: 在座位上绑定角色
    author:{author}
    time:2023-04-14 11:50:18
    --@roomID:房间ID
	--@index:家具位置索引
	--@subIndex: 家具子物体位置索引
    @return:
]]
function InstanceModel:SetSeatWorker(roomID,index,subIndex)
    local InstanceRoom = InstnaceScene.Rooms[roomID]
    local subFurList = InstanceRoom.roomGO.subFurList[index]
    if not subFurList then
        return
    end
    subFurList[subIndex].isUsed = true
end

--[[
    @desc: 计算在线收益
    author:{author}
    time:2023-04-18 10:00:12
    @return:
]]
function InstanceModel:CalculateInstanceOnlineReward(dt)
    self:CalculatePortExport(dt)
    if self.timeType == InstanceDataManager.timeType.work then
        self:CalculateWorkerAttr(dt)
        self:CalculateFactoryUnitOutput(dt)
    end
end

--[[
    @desc: 计算码头输出量
    author:{author}
    time:2023-04-17 15:54:26
    @return:
]]
function InstanceModel:CalculatePortExport(dt)
    -- if true then
    --     return
    -- end
    local roomData = nil
    local roomID = 0
    for k,v in pairs(self.roomsConfig) do
        if v.room_category == 4 then
            roomID = v.id
            roomData = self.roomsData[v.id]
            break
        end
    end
    local current = GameTimeManager:GetCurrentServerTime(true)
    --遍历港口设备,找船,因为有船一定有码头
    for k,v in pairs(roomData.furList) do
        local curFurData = v
        local curFurLevelCfg = self.furnitureLevelConfig[curFurData.id]
        if curFurData.state == 1 and curFurLevelCfg.shipCD > 0 then --直接找船
            --如果有可出售货物,就拉货开走,如果库存不够就在码头等待
            local comeCD = curFurLevelCfg.shipCD
            local loadingCD = InstanceDataManager.config_global.instance_ship_loadtime
            local portFurData = roomData.furList[tostring(v.index - 6)]  --这里直接写死,不然重复遍历去找对应的码头太耗了
            local partID = portFurData.id
            local portLevelCfg = self.furnitureLevelConfig[partID]
            local haveCount = self.productions[tostring(portLevelCfg.resource_type)]
            local shipCD = 0
            if self.workCD[roomID] and self.workCD[roomID][v.index] then
                shipCD = self.workCD[roomID][v.index]
            end

            if curFurData.lastReachTime > curFurData.lastLeaveTime  then  --船是靠港状态
                if portFurData.isOpen then
                    if haveCount > 0 then   --有可出售货物
                        if shipCD < loadingCD then  --装载中
                            self.workCD[roomID][v.index] = shipCD + dt
                            if shipCD == 0 then
                                InstanceScene:SetShipBubbles(v.index,false,portFurData.isOpen)
                            end
                        else    --装载完成离港
                            InstanceScene:SetShipBubbles(v.index,true,portFurData.isOpen)

                            self.workCD[roomID][v.index] = 0
                            local sellCount = portLevelCfg.storage
                            if haveCount < sellCount then
                                sellCount = haveCount
                            end
                            local income = sellCount * self.resourceConfig[portLevelCfg.resource_type].price
                            self.productions[tostring(portLevelCfg.resource_type)] = self.productions[tostring(portLevelCfg.resource_type)] - sellCount
                            InstanceDataManager:SetRoomFurnitureData(roomID,v.index,curFurData.id,{["lastLeaveTime"] = current})
                            InstanceDataManager:SetProdutionsData(self.productions)
                            --得钱
                            InstanceDataManager:AddCurInstanceCoin(income)
                            InstanceMainViewUI:Refresh()
                            --显示通知
                            local resCfg = self.resourceConfig[curFurLevelCfg.resource_type]
                            InstanceMainViewUI:CallNotify(2,income,resCfg)
                            --TODO 船离港表现
                            InstanceScene:PlayShipAnim(v.index,true)
                        end
                    else    --无可出售货物,cd不长
                    end
                end
            else    --船是离港状态
                if shipCD < comeCD  then    --等待船来
                    if shipCD + dt >= comeCD-7 and shipCD < comeCD-7 then
                        --TODO 船靠港表现
                        InstanceScene:PlayShipAnim(v.index,false)
                    end
                    if self.workCD[roomID] and self.workCD[roomID][v.index] then    --不知道为什么这里会报错,加一个判空保护
                        self.workCD[roomID][v.index] = shipCD + dt
                    else
                        print("InstanceModel 1010:",roomID, v.index)
                    end
                else    --船靠港
                    self.workCD[roomID][v.index] = 0
                    InstanceDataManager:SetRoomFurnitureData(roomID,v.index,curFurData.id,{["lastReachTime"] = current})

                end
            end
            
        end
    end
end

--[[
    @desc: 计算单位时间的产量
    author:{author}
    time:2023-04-17 14:40:36
    @return:
]]
function InstanceModel:CalculateFactoryUnitOutput(dt)
    
    --遍历所有生产类型的房间数据,如果房间已解锁则计算产量和消耗
    for k,v in pairs(roomSortConfig) do
        if v.room_category == 1 then
            local roomID = v.id
            local curRoomData = self.roomsData[roomID]
            if curRoomData.state ==2 then
                local cd = self:GetRoomCD(roomID)
                self.workCD[roomID] = self.workCD[roomID] + dt

                --计算一轮收益
                if self.workCD[roomID] >= cd then  
                    self.workCD[roomID] = 0
                    local materialID = v.material[1]
                    local productID = v.production
                    local haveCount = self.productions[tostring(materialID)]
                    local needCount = self:GetRoomMatCost(roomID)
                    local output = self:GetRoomProduction(roomID)
    
                    if not self:GetLandMarkCanPurchas() then --买了1.5
                        local instanceBind = InstanceDataManager:GetInstanceBind()
                        local landmarkID = instanceBind.landmark_id
                        local shopCfg = ConfigMgr.config_shop[landmarkID]
                        local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
                        if materialID ~= 0 then --需要原料
                            if not self.productions[tostring(materialID)] then
                                self.productions[tostring(materialID)] = 0
                            end
    
                            if haveCount > needCount then
                                self.productions[tostring(materialID)] = self.productions[tostring(materialID)] - needCount
                                self.productions[tostring(productID)] = self.productions[tostring(productID)] + output * (1 + resAdd/100)
                            else    
                                self.productions[tostring(materialID)] = 0 
                                self.productions[tostring(productID)] =self.productions[tostring(productID)] + math.floor( (haveCount / v.material[2] ) * 1.5)
                            end
                                
                        else
                            self.productions[tostring(productID)] = self.productions[tostring(productID)] + output * (1 + resAdd/100)
                        end 
                    else
                        if materialID ~= 0 then --需要原料
                            if not self.productions[tostring(materialID)] then
                                self.productions[tostring(materialID)] = 0
                            end
    
                            if haveCount > needCount then
                                self.productions[tostring(materialID)] = self.productions[tostring(materialID)] - needCount
                                self.productions[tostring(productID)] = self.productions[tostring(productID)] + output
                            else    
                                self.productions[tostring(materialID)] = 0 
                                self.productions[tostring(productID)] =self.productions[tostring(productID)] + math.floor( haveCount / v.material[2] ) 
                            end
                                
                        else
                            self.productions[tostring(productID)] = self.productions[tostring(productID)] + output
                        end 
                    end

                    --print(productID,output,self.productions[tostring(productID)])
                    InstanceDataManager:SetRoomData(roomID, nil,nil,GameTimeManager:GetCurrentServerTime(true))   
                      
                end
            
            end

        end
    end
    InstanceDataManager:SetProdutionsData(self.productions) 
end

--[[
    @desc: 计算工人属性
    author:{author}
    time:2023-04-20 14:59:18
    --@dt: 
    @return:
]]
function InstanceModel:CalculateWorkerAttr(dt)
    if self.workerAttrCalInterval < 1 then
        self.workerAttrCalInterval = self.workerAttrCalInterval + dt
        return
    end
    self.workerAttrCalInterval = 0

    local deltaAttr = 0 --old: InstanceDataManager.config_global.stateWeaken /60
    for k,v in pairs(self.roomsData) do
        local roomID = v.roomID
        if v.furList and v.state == 2 then
            for furIndex,furData in pairs(v.furList) do
                deltaAttr = self:GetFurlevelConfigByRoomFurIndex(roomID,furIndex).weaken / 60
                if furData.worker and furData.state == 1 then
                    if furData.worker.attrs then
                        furData.worker.attrs["hungry"] = furData.worker.attrs["hungry"] - deltaAttr
                        furData.worker.attrs["physical"]  = furData.worker.attrs["physical"] - deltaAttr
                        InstanceDataManager:SetRoomFurnitureData(roomID,furData.index,furData.id,{["Attrs"] = furData.worker.attrs})
                    end
                end
            end
        end
    end
end

--[[
    @desc: 玩家属性恢复
    author:{author}
    time:2023-04-20 17:50:00
    --@timeType: 
    @return:
]]
function InstanceModel:WorkerAttrRevert(timeType,isShow)
    if timeType == InstanceDataManager.timeType.work then
        return
    end
    self.actorSeatBind[timeType] = {}

    local workerList = {}
    for k,v in pairs(self.roomsData) do
        local roomCfg = self.roomsConfig[v.roomID]
        if roomCfg.room_category ==1 and v.state ==2 then
            for furK,furV in pairs(v.furList) do
                if furV.state == 1 and furV.worker then
                    table.insert(workerList,{
                        roomID =  v.roomID,
                        furData = furV
                    })
                end
            end
        end
    end

    if timeType == InstanceDataManager.timeType.sleep then
        --获取恢复数
        local seatCount = 0
        --按照体力值从低到高排序
        table.sort(workerList,function (a,b)
            return a.furData.worker.attrs["physical"] < b.furData.worker.attrs["physical"]
        end)
        --按照恢复速度对功能房间排序x
        local rooms = {}
        for k,v in pairs(self.roomsData) do
            local roomCfg = self.roomsConfig[v.roomID]
            if v.state == 2 and roomCfg.room_category == 2 then
                local revortNum = self:GetRoomPhysical(v.roomID)
                table.insert(rooms,{
                    roomID = v.roomID,
                    revort = revortNum
                })
            end
        end
        table.sort(rooms,function (a,b)
            return a.revort > b.revort
        end)
        for roomIndex = 1,#rooms do
            local roomSeatCount = self:GetRoomSeatCount(rooms[roomIndex].roomID)
            for i=1,roomSeatCount do
                if #workerList > 0 then
                    local worker = workerList[1]
                    if not isShow then
                        local attr = worker.furData.worker.attrs
                        InstanceDataManager:SetRoomFurnitureData(worker.roomID,worker.furData.index,worker.furData.id,{["Attrs"] = {
                            ["hungry"] = attr.hungry ,
                            ["physical"] = attr.physical+ rooms[roomIndex].revort,
                        }})
                    else
                        InstanceScene:TagPeopleCanDo(worker.roomID, worker.furData.index, rooms[roomIndex].roomID)
                        if not self.actorSeatBind[timeType] then
                            self.actorSeatBind[timeType] = {}
                        end
                        if not self.actorSeatBind[timeType][worker.roomID] then
                            self.actorSeatBind[timeType][worker.roomID] = {}
                        end
                        self.actorSeatBind[timeType][worker.roomID][worker.furData.index] = rooms[roomIndex].roomID
                    
                    end

                    table.remove(workerList,1)
                end

            end
        end

    elseif timeType == InstanceDataManager.timeType.eat then
        --获取恢复数
        local seatCount = 0
        for k,v in pairs(self.roomsData) do
            local roomCfg = self.roomsConfig[v.roomID]
            if roomCfg.room_category == 3 and v.state == 2 then
                local roomSeatCount = self:GetRoomSeatCount(v.roomID)
                seatCount = seatCount + roomSeatCount
                -- for furK,furV in pairs(v.furList) do
                --     if furV.state == 1 then
                --     end
                -- end
            end
        end
        --按照饥饿值从低到高排序
        table.sort(workerList ,function (a,b)
            return a.furData.worker.attrs["hungry"] < b.furData.worker.attrs["hungry"]
        end)

        local count = 0
        local revort = 0
        local roomId = 0
        for k,v in pairs(self.roomsConfig) do
            if v.room_category == 3 then
                revort= self:GetRoomHunger(v.id) 
                roomId = v.id
                break
            end
        end
        for i=1,seatCount do
            if  #workerList > 0 then
                local worker = workerList[1]
                if not isShow then
                    local attr = worker.furData.worker.attrs
                    InstanceDataManager:SetRoomFurnitureData(worker.roomID,worker.furData.index,worker.furData.id,{["Attrs"]  = {
                        ["hungry"] = attr.hungry + revort,
                        ["physical"] = attr.physical
                    }}) 

                else
                    InstanceScene:TagPeopleCanDo(worker.roomID, worker.furData.index, roomId)
                    if not self.actorSeatBind[timeType] then
                        self.actorSeatBind[timeType] = {}
                    end
                    if not self.actorSeatBind[timeType][worker.roomID] then
                        self.actorSeatBind[timeType][worker.roomID] = {}
                    end
                    self.actorSeatBind[timeType][worker.roomID][worker.furData.index] = roomId
                end

                table.remove(workerList,1)
            end
        end
    end
end

---为worker安排一个空的进餐座位
function InstanceModel:FindEatSeat(worker)
    local timeType = InstanceDataManager.timeType.eat
    --获取恢复数
    local seatCount = 0
    for k,v in pairs(self.roomsData) do
        local roomCfg = self.roomsConfig[v.roomID]
        if roomCfg.room_category == 3 and v.state == 2 then
            local roomSeatCount = self:GetRoomSeatCount(v.roomID)
            seatCount = seatCount + roomSeatCount
        end
    end

    local roomId = 0
    for k,v in pairs(self.roomsConfig) do
        if v.room_category == 3 then
            roomId = v.id
            break
        end
    end
    if not self.actorSeatBind[timeType] then
        return false
    end
    local usedCount = 0
    for roomID,room in pairs(self.actorSeatBind[timeType]) do
        for furId ,v in pairs(room) do
            usedCount = usedCount + 1
        end
    end
    if usedCount >= seatCount then
        return false
    end
    local workerRoomID = worker.data.roomID
    local workerFurIndex = worker.data.furnitureIndex
    if not self.actorSeatBind[timeType][workerRoomID] then
        self.actorSeatBind[timeType][workerRoomID] = {}
    end
    if not self.actorSeatBind[timeType][workerRoomID][workerFurIndex] then
        InstanceScene:TagPeopleCanDo(workerRoomID, workerFurIndex, roomId)
        self.actorSeatBind[timeType][workerRoomID][workerFurIndex] = roomId
        return true
    else
        return false --已经在座位上了,调用前应该先判断，正确来说不应执行到这里。
    end
end

---为worker安排一个空的睡觉座位
function InstanceModel:FindSleepSeat(worker)
    local timeType = InstanceDataManager.timeType.sleep
    --找到空座位

    local usedSeatDic = {}
    local seatBind = self.actorSeatBind[timeType]
    if not seatBind then
        return
    end
    for wrID,room in pairs(seatBind) do
        for workerFurId ,interactionRoomID in pairs(room) do
            usedSeatDic[interactionRoomID] = (usedSeatDic[interactionRoomID] or 0) + 1
        end
    end

    local workerRoomID = worker.data.roomID
    for k,v in pairs(self.roomsData) do
        local roomID = v.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 2 and v.state == 2 then
            local roomSeatCount = self:GetRoomSeatCount(roomID)
            if roomSeatCount > (usedSeatDic[roomID] or 0) then
                local workerFurIndex = worker.data.furnitureIndex
                if not seatBind[workerRoomID] then
                    seatBind[workerRoomID] = {}
                end
                seatBind[workerRoomID][workerFurIndex] = roomID
                return true
            end
        end
    end
    return false
    --local roomId = 0
    --for k,v in pairs(self.roomsConfig) do
    --    if v.room_category == 3 then
    --        roomId = v.id
    --        break
    --    end
    --end
    --if not self.actorSeatBind[timeType] then
    --    return false
    --end
    --local usedCount = 0
    --if usedCount >= seatCount then
    --    return false
    --end
    --local workerFurIndex = worker.data.furnitureIndex
    --if not self.actorSeatBind[timeType][workerRoomID] then
    --    self.actorSeatBind[timeType][workerRoomID] = {}
    --end
    --if not self.actorSeatBind[timeType][workerRoomID][workerFurIndex] then
    --    InstanceScene:TagPeopleCanDo(workerRoomID, workerFurIndex, roomId)
    --    self.actorSeatBind[timeType][workerRoomID][workerFurIndex] = roomId
    --    return true
    --else
    --    return false --已经在座位上了,调用前应该先判断，正确来说不应执行到这里。
    --end
end

function InstanceModel:IsDay()
    local timeNode = InstanceDataManager.config_global.timeNode
    local currentTime = InstanceDataManager:GetCurInstanceTime()
    if currentTime.Hour >= tonumber(timeNode[1]) and currentTime.Hour < tonumber(timeNode[2]) then
        return true
    end
    return false
end

--[[
    @desc: 计算离线奖励
    author:{author}
    time:2023-04-24 15:22:48
    --@offlineDuration:离线时间,单位s 
    @return:
]]
function InstanceModel:CalculateOfflineRewards(offlineDuration, onlyEarnings, changeSaveData)
    local instanceDay = offlineDuration / (60 * InstanceDataManager.config_global.oneDayDuration)
    local lastDay = offlineDuration % (60 * InstanceDataManager.config_global.oneDayDuration) / (60 * InstanceDataManager.config_global.oneDayDuration)
    local dayUp = math.ceil(instanceDay)
    --初始化资源统计表
    local resTable = {}
    for k,v in pairs(self.resourceConfig) do
        resTable[k] = 0
    end

    --计算一天的属性回复量
    local hungryRevertSum = 0
    local physicalRevertSum = 0
    local workerCount = 0
    for k,v in pairs(self.roomsData) do
        local roomData = v
        local roomID = roomData.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomData.state == 2 then
            if roomCfg.room_category == 2 then  --宿舍
                local curRevert = self:GetRoomPhysical(roomID)
                local seat = self:GetRoomSeatCount(roomID)
                curRevert = curRevert * seat
                physicalRevertSum = physicalRevertSum +curRevert
            elseif  roomCfg.room_category == 3 then --餐厅
                local curRevert = self:GetRoomHunger(roomID)
                local seat = self:GetRoomSeatCount(roomID)
                curRevert = curRevert * seat
                hungryRevertSum = hungryRevertSum + curRevert
            elseif  roomCfg.room_category == 1 then --工厂
                for furIndex,furV in pairs(roomData.furList) do
                    local furLevelCfg = self:GetFurlevelConfigByRoomFurIndex(roomID,furIndex)
                    if furLevelCfg.isPresonFurniture and furV.state == 1 then
                        workerCount = workerCount + 1 
                    end
                end
            end
        end
    
    end
    hungryRevertSum = hungryRevertSum * 2   --一天两顿饭
    local hungryRevertAve = hungryRevertSum / workerCount   --平均每人每天恢复饥饿值
    local physicalRevertAve = physicalRevertSum / workerCount   --平均每人每天恢复体力值

    --按天计算每个建筑的产能
    for day=1,dayUp do
        for i=1,#roomSortConfig do
            local roomCfg = roomSortConfig[i]
            local roomID = roomCfg.id
            local roomData = self.roomsData[roomID]
    
            if roomData.state == 2 and roomCfg.room_category == 1 then
                local FurList = roomData.furList
                local roomCD = self:GetRoomCD(roomID)
                local roomPro = 0   --这个房间的单位产量(一轮CD)
                for furIndex,furV in pairs(FurList) do
                    local furData = furV
                    local furLevelCfg = self.furnitureLevelConfig[furData.id]
                    if furData.worker and furData.state == 1 then
                        local efficiency = 1
                        local hungry = furData.worker.attrs.hungry
                        local physical = furData.worker.attrs.physical
                        -- local furProduct = furLevelCfg.Product 
                        --计算属性导致生产数量的变化
                        local deltaHungry = hungryRevertAve - 
                            furLevelCfg.weaken * InstanceDataManager.config_global.oneDayDuration * self:GetWorkTimeRatio()
                        local deltaPhysical = physicalRevertAve - 
                            furLevelCfg.weaken * InstanceDataManager.config_global.oneDayDuration * self:GetWorkTimeRatio()
                        hungry = hungry + day * deltaHungry
                        physical = physical + day * deltaPhysical
                        local curFurPor = self:GetFurLevelCfgAttrSum(furLevelCfg.id,"product")

                        local debuff = 0
                        if hungry < 20 then
                            debuff = debuff + stateDebuff
                        end
                        if physical < 20 then
                            debuff = debuff + stateDebuff
                        end
                        if not self:GetLandMarkCanPurchas() then -- 买了石像 *1.5(根据配置)
                            local instanceBind = InstanceDataManager:GetInstanceBind()
                            local landmarkID = instanceBind.landmark_id
                            local shopCfg = ConfigMgr.config_shop[landmarkID]
                            local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
                            curFurPor = math.floor(curFurPor * (1 + resAdd/100))
                            
                        end
                        curFurPor = curFurPor * (1-debuff)
                        roomPro = roomPro + curFurPor
                    end
                end
                --计算这个房间一天(游戏时间)的单位产量
                local curDayProdction = roomPro * InstanceDataManager.config_global.oneDayDuration * 60 /roomCD
                if day == dayUp then
                    curDayProdction = curDayProdction * lastDay
                end
                resTable[roomCfg.production] = resTable[roomCfg.production] + curDayProdction
            end
        end
    end

    print("计算消耗前==================================",debug.traceback())
    for k,v in pairs(resTable) do
        print(k,resTable[k])
    end

    if onlyEarnings then
        return resTable
    end

    --计算消耗
    local calResType = {}
    for i=1,#roomSortConfig do
        local roomCfg = roomSortConfig[i]
        local roomID  = roomCfg.id
        local roomData = self.roomsData[roomID]
        if roomCfg.room_category == 1 and roomData.state == 2 then
            local materialID = roomCfg.material[1]
            local productID = roomCfg.production
            local output = resTable[productID]
            
            if materialID ~= 0 and not calResType[materialID]  then --需要原料
                calResType[materialID] = true
                local haveCount = resTable[materialID]
                local needCount = resTable[productID] * roomCfg.material[2]
                if haveCount > needCount then
                    resTable[materialID] = resTable[materialID] - needCount
                    resTable[productID] =  output
                else    
                    resTable[materialID] = 0 
                    resTable[productID] = math.floor( haveCount / roomCfg.material[2] ) 
                end
            else
                resTable[productID] = output
            end
        end
    end
    calResType = nil

    if not self:GetLandMarkCanPurchas() then --买了
        local instanceBind = InstanceDataManager:GetInstanceBind()
        local landmarkID = instanceBind.landmark_id
        local shopCfg = ConfigMgr.config_shop[landmarkID]
        local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
        for k,v in pairs(resTable) do
            resTable[k] = resTable[k] * (1 + resAdd/100)
        end
    end

    print("计算生产消耗后==================================")
    for k,v in pairs(resTable) do
        print(k,resTable[k])
    end

    local productions = changeSaveData and self.productions or Tools:CopyTable(self.productions)

    --计算港口卖出
    local money = 0
    for k,v in pairs(self.roomsData) do
        roomID = v.roomID
        local saleCount = 0
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 4 and v.state == 2  then   
            local furList = v.furList
            for furIndex,furData in pairs(furList) do
                local furLevelCfg = self.furnitureLevelConfig[furData.id]
                if furData.state == 1 and furLevelCfg.shipCD > 0 then  --找船
                    local portFurData = furList[tostring(furData.index - 6)]
                    if portFurData.isOpen then
                        local partID = portFurData.id
                        local portLevelCfg = self.furnitureLevelConfig[partID]
                        local saleCount = portLevelCfg.storage * offlineDuration / (furLevelCfg.shipCD + InstanceDataManager.config_global.instance_ship_loadtime)
                        local curResID = portLevelCfg.resource_type
                        local resCfg = self.resourceConfig[curResID]
                        if resTable[curResID] >= saleCount then
                            resTable[curResID] = resTable[curResID] - saleCount
                            money = money + saleCount * resCfg.price
                        else
                            local storag = productions[tostring(curResID)]
                            if storag + resTable[curResID] >= saleCount then
                                productions[tostring(curResID)] = storag - (saleCount-resTable[curResID])
                                resTable[curResID] = 0
                                money = money + saleCount * resCfg.price
                            else
                                saleCount = productions[tostring(curResID)] + resTable[curResID]
                                productions[tostring(curResID)] = 0
                                resTable[curResID] = 0
                                money = money + saleCount * resCfg.price
                            end
                        end
                        
                    end
                end
            end
        end
    end

    --计算员工离线属性影响
    if changeSaveData then
        
        for k,v in pairs(self.roomsData) do
            if v.state == 2 and v.furList then
                for furIndex,furData in pairs(v.furList) do
                    local furLevelCfg = self.furnitureLevelConfig[furData.id]
                    if furData.state == 1 and furData.worker then
                        local furLevelCfg = self:GetFurLevelConfigByLevelID(furData.id)
                        local attr = furData.worker.attrs
                        -- attr.hungry = attr.hungry + hungryRevertAve * (dayUp-1 + lastDay)
                        -- attr.physical = attr.physical + physicalRevertAve * (dayUp-1 + lastDay)
                        attr.hungry = attr.hungry + (hungryRevertAve - 
                        furLevelCfg.weaken * InstanceDataManager.config_global.oneDayDuration * self:GetWorkTimeRatio()) * (dayUp - 1 + lastDay)
                        attr.physical = attr.physical + (physicalRevertAve - 
                        furLevelCfg.weaken * InstanceDataManager.config_global.oneDayDuration * self:GetWorkTimeRatio()) * (dayUp - 1 + lastDay)
                        InstanceDataManager:SetRoomFurnitureData(v.roomID,furData.index,furData.id,{Attrs = attr})
                    end
                end
            end
        end
        
    end
    
    print("计算卖出消耗后==================================")
    for k,v in pairs(resTable) do
        productions[tostring(k)] = (productions[tostring(k)] or 0) + resTable[k]
        print(k,resTable[k])
    end

    if changeSaveData then
        InstanceDataManager:SetProdutionsData(productions)
        InstanceDataManager:AddCurInstanceCoin(money)
        InstanceMainViewUI:Refresh()
    end

    local resReward = {}
    for k,v in pairs(resTable) do
        if resTable[k] > 0 then
            local resCfg = self.resourceConfig[k]
            table.insert(resReward,{
                count = resTable[k],
                resCfg = resCfg
            })
        end
    end

    return resReward,money

end

--[[
    @desc: 获取工作时间比例
    author:{author}
    time:2023-04-25 18:59:26
    @return:
]]
function InstanceModel:GetWorkTimeRatio()
    return 0.5
end

--[[
    @desc: 获取家具GameObject
    author:{author}
    time:2023-04-26 18:27:52
    @return:
]]
function InstanceModel:GetSceneRoomFurnitureGo(roomID, furIndex, subIndex)
    return InstanceScene:GetSceneRoomFurnitureGo(roomID, furIndex, subIndex)
end

--[[
    @desc: 相机看向目标对象
    author:{author}
    time:2023-04-28 15:12:22
    @return:
]]
function InstanceModel:LookAtSceneGO(roomID,furIndex,cameraFocus,isBack,callback)
    InstanceScene:LookAtSceneGO(roomID,furIndex,cameraFocus,isBack,callback)
end
--[[
    @desc: 将相机的位置移动到目标点
    author:{author}
    time:2023-05-08 15:34:53
    @return:
]]
function InstanceModel:LocatePosition(position,IsShowMove,cb)
    InstanceScene:LocatePosition(position,IsShowMove,cb)
end

--[[
    @desc: 显示选中的家具
    author:{author}
    time:2023-05-05 19:18:12
    --@furGO:
	--@preBuy: 
    @return:
]]
function InstanceModel:ShowSelectFurniture(furGO,preBuy)
    InstanceScene:ShowSelectFurniture(furGO,preBuy)
end
    
--[[
    @desc: 返回当前指定时间产出的内容
    author:{author}
    time:2023-05-04 16:55:42
    --@timeSeconds: 指定的时间
    @return:产出的内容
]]
function InstanceModel:GetCurProductionsByTime(timeSeconds)
    local result = {}
    --资源产出的相关计算
    local resTable = self:CalculateOfflineRewards(timeSeconds, true, true)
    
    for key, v in pairs(resTable) do
        if v > 0 then
            local tmpData = {}
            tmpData.resourcesID = key
            tmpData.amount = v
            table.insert(result, tmpData)
            print(key,v)
        end
    end
    return result
end

--[[
    @desc: 获取某个员工的状态
    author:{author}
    time:2023-05-05 10:57:57
    @return:
    ]]
    function InstanceModel:GetWorkerAttr(roomID,furIndex)
        return self.roomsData[roomID].furList[tostring(furIndex)] and self.roomsData[roomID].furList[tostring(furIndex)].worker and self.roomsData[roomID].furList[tostring(furIndex)].worker.attrs or {}
    end
    
--[[
@desc: 设置场景特殊物品现隐
author:{author}
time:2023-05-08 14:49:55
--@active: 
@return:
]]
function InstanceModel:ShowSpecialGameObject(active)
    InstanceScene:ShowSpecialGameObject(active)
end

--[[
    @desc: 3D坐标转2D坐标
    author:{author}
    time:2023-05-08 15:50:23
    --@position: 
    @return:
]]
function InstanceModel:Position3dTo2d(position)
   return InstanceScene:Position3dTo2d(position)
end

function InstanceModel:EventInstanceBack(state)
    InstanceScene:EventInstanceBack(state)
end

--[[
    @desc: 获取房间GameObject
    author:{author}
    time:2023-08-23 10:01:05
    @return:
]]
function InstanceModel:GetRoomGameObjectByID(roomID)
    return InstanceScene:GetRoomGameObjectByID(roomID)
end

--[[
    @desc: 获取家具GameObject
    author:{author}
    time:2023-08-25 18:26:22
    --@roomID:
	--@furIndex:
	--@subIndex: 
    @return:
]]
function InstanceModel:GetFurGameObject(roomID, furIndex, subIndex)
    return InstanceScene:GetSceneRoomFurnitureGo(roomID, furIndex, subIndex)
end

function InstanceModel:GetLandMarkCanPurchas()
    local instanceBind = InstanceDataManager:GetInstanceBind()
    local landmarkID = instanceBind.landmark_id
    return ShopManager:CheckBuyTimes(landmarkID)
end


--[[
    @desc: 获取成就等级奖励, 返回{type1 = num1, type2 = num2 ... }
    author:{author}
    time:2023-10-16 16:04:42
    --@level: 
    @return:
]]
function InstanceModel:GetLevelReward(level)
    local rewards = {}
    for k,v in pairs(InstanceDataManager.config_achievement_instance) do
        if v.level <= level then
            local rewardType = v.reward_id
            if not rewards[rewardType] then
                rewards[rewardType] = v.reward_num
            else    
                rewards[rewardType] = rewards[rewardType] + v.reward_num
            end
        end
    end    
    return rewards
end

---获得还没开启的奖励
function InstanceModel:GetRewardNotOpened()
    local rewards = {}
    local level = InstanceDataManager:GetCurInstanceKSLevel()
    for k,v in pairs(InstanceDataManager.config_achievement_instance) do
        if v.level <= level and not InstanceDataManager:IsRewardClaimed(v.level) then
            local rewardType = v.reward_id
            if not rewards[rewardType] then
                rewards[rewardType] = v.reward_num
            else
                rewards[rewardType] = rewards[rewardType] + v.reward_num
            end
        end
    end
    return rewards
end

---获取某个特定等级的奖励
function InstanceModel:GetRewardByLevel(level)
    local rewards = {}
    for k,v in pairs(InstanceDataManager.config_achievement_instance) do
        if v.level == level then
            local rewardType = v.reward_id
            rewards[rewardType] = v.reward_num
            break
        end
    end
    return rewards
end

---获取里程碑满级积分和当前等级总积分
---@return number,number 满级积分，当前等级总积分
function InstanceModel:GetMaxAndCurAchievementScore()
    local curLevel = InstanceDataManager:GetCurInstanceKSLevel()
    local curScore = InstanceDataManager:GetCurInstanceScore()
    local maxScore = 0
    for i,v in ipairs(InstanceDataManager.config_achievement_instance) do
        maxScore = maxScore + v.condition
        if v.level == curLevel then
            curScore = curScore + maxScore
        end
    end
    return maxScore,curScore
end

---获取里程碑最大等级
function InstanceModel:GetMaxAchievementLevel()
    local config = InstanceDataManager.config_achievement_instance
    local result = 0
    for k,v in pairs(config) do
        if v.level >= result then
            result = v.level
        end
    end
    return result
end

function InstanceModel:SceneSwtichDayOrLight(isDay)
    if InstanceScene then
        InstanceScene:SceneSwtichDayOrLight(isDay)
        
    end
end

local function ContainsNumber(tbl, num)
    for _, value in pairs(tbl) do
        if value == num then
            return true
        end
    end
    return false
end

---是否购买某设施 大于等于level等级 needCount数量,限定在roomIDList范围统计
---@return boolean,number,number
function InstanceModel:IsBuyFurnitureLevelAndCount(furnitureID, level, needCount, roomIDList)
    local buyCount = 0
    local baseFurName = self:GetFurConfigByID(furnitureID).name
    for _,roomID in ipairs(roomIDList) do
        local roomData = InstanceDataManager:GetCurRoomData(roomID)
        if roomData.furList and next(roomData.furList) ~= nil then
            for i,m in pairs(roomData.furList) do
                local furLevelConfig = self:GetFurLevelConfigByLevelID(m.id)
                local furName = self:GetFurConfigByID(furLevelConfig.furniture_id).name
                --判断是否是同名设施
                if furName == baseFurName and m.state == 1 and furLevelConfig.level>=level then
                    buyCount = buyCount + 1
                end
            end
        end
    end
    return buyCount>= needCount,buyCount, needCount
end

---在任务中需要跳转到需要购买的第一个家具所在房间和家具index
---@return number,number  roomID,furnitureIndex
function InstanceModel:FirstNeedBuyFurniture(furnitureID, level, roomIDList)
    local roomIDCount = #roomIDList
    if roomIDCount>0 then
        local baseFurName = self:GetFurConfigByID(furnitureID).name
        for i = 1, roomIDCount do
            local roomID = roomIDList[i]
            local roomData = InstanceDataManager:GetCurRoomData(roomID)
            if roomData and roomData.state == 2 and roomData.furList and next(roomData.furList) ~= nil then
                local furCount = Tools:GetTableSize(roomData.furList)
                for index = 1, furCount do
                    local furData = roomData.furList[tostring(index)]
                    if furData then
                        local furLevelConfig = self:GetFurLevelConfigByLevelID(furData.id)
                        local furName = self:GetFurConfigByID(furLevelConfig.furniture_id).name
                        if furName == baseFurName then
                            if (furData.state == 1 and furLevelConfig.level<level) or furData.state == 0 then
                                return roomID,index
                            end
                        end
                    end
                end
            end
        end
    end
    return 0,0
end