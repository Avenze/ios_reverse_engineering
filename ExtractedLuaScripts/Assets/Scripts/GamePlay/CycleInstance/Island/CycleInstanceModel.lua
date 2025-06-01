local CycleInstanceModelBase = require("GamePlay.CycleInstance.CycleInstanceModelBase")
local Class = require("Framework.Lua.Class")
---@class CycleInstanceModel:CycleInstanceModelBase
---@field super CycleInstanceModelBase
local CycleInstanceModel = Class("CycleInstanceModel",CycleInstanceModelBase)

local Execute = require("Framework.Queue.Execute")
local EventManager = require("Framework.Event.Manager")

local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local FloatUI = GameTableDefine.FloatUI
local CycleIslandMainViewUI = GameTableDefine.CycleIslandMainViewUI
local CycleIslandBuildingUI = GameTableDefine.CycleIslandBuildingUI
local ActorManager = GameTableDefine.ActorManager
local SpicalRoomManager = GameTableDefine.SpicalRoomManager
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local CycleInstanceAIBlackBoard = GameTableDefine.CycleInstanceAIBlackBoard
local CycleIslandHeroManager = GameTableDefine.CycleIslandHeroManager
local FlyIconUI = GameTableDefine.FlyIconsUI
local CycleInstancePopUI = GameTableDefine.CycleInstancePopUI

local CycleInstanceScene = nil   ---@type CycleInstanceScene
local roomSortConfig = nil   ---将self.roomConfig按照所需材料等级从低到高排序结果
local attrThreshold = nil   ---属性阈值
local stateDebuff = nil   ---属性debuff效果
local isOpenExitPop = false
local CoinFieldName = "m_CurInstanceCoin" ---存档中副本钞票存款名
local ScoreFieldName = "m_CurScore" ---存档中副本积分名



CycleInstanceModel.TimeTypeEnum = {
    sleep = 1,  --睡觉
    eat = 2,  --吃饭
    work = 3,  --工作
}




function CycleInstanceModel:DeclareVariable()
    self.instance_id = nil   ---副本ID(类型ID, 不是实例ID)

    -- config
    --self.furnitureConfig = nil ---设备配置数据
    --self.furnitureLevelConfig_furID = nil ---根据furniturID保存家具等级表,避免大量遍历的消耗
    self.resourceConfig = nil ---产出资源配置数据
    
    self.saveData = nil
    self.roomsData = {}    ---所有房间存档数据
    self.isFirstInit = false    ---是否是第一次初始化
    self.workerList = {}  ---所有员工ID列表
    self.floatUI = {}   ---floatUI传参使用
    self.productions = {}  ---产品存量列表
    self.workCD = {} ---用于计算建筑工作循环
    self.workerAttrCalInterval = 1  ---工人属性计算间隔
    self.timeType = 0   ---副本时间类型
    self.lastTime = nil ---上一秒的副本时间
    self.actorSeatBind = {} ---吃饭或睡觉时角色的座位对应
    self.checkMatInterval = 5
    self.checkMatTimer = 0
    self.portExport = {}
end


function CycleInstanceModel:Init(saveData)
    self:DeclareVariable()
    if not saveData or next(saveData) == nil then
        printf("初始化了一个不存在的循环副本")
        return
    end
    self.saveData = saveData
    GameTableDefine.CycleIslandHeroManager:Reset()
    GameTableDefine.CycleIslandTaskManager:Reset()
    self.instance_id = tonumber(saveData.m_Instance_id)
    self:InitConfigData()
    -- 第一次初始化model,初始化副本数据
    if not self.saveData.m_CurInstanceCoin then
        self:AddCurInstanceCoin(self.config_global.cycle_instance_cash[1])--and 99999999999999999999) 
        self:ChangeCurHeroExpRes(self.config_global.cycle_instance_cash[2])
        self:ChangeSlotCoin(self.config_global.cycle_instance_cash[3])
        GameSDKs:TrackForeign("cy_get_coin", { source = "副本初始化", num = tonumber(self.config_global.cycle_instance_cash[3]) })
        
        self:InitLimitTimePack()
    end
    
    Execute:Async({function()
        GameUIManager:SetFloatUILockScale(true, 18)
    end})
    self:InitRoomData()
    self:InitWorkerList()
    self:GetCurSkillData()
    self:GetCurSkillPoints(1)
    self:GetCurSkillPoints(2)
    self:GetCurSkillPoints(3)
    self.timeType = self:GetCurInstanceTimeType()
    self.lastTime = self:GetCurInstanceTime(self.instance_id)
end

function CycleInstanceModel:InitConfigData()
    self:getSuper(CycleInstanceModel).InitConfigData(self)

    --
    self.config_cy_instance_skill = ConfigMgr.config_cy_instance_skill[self.instance_id]
end

--初始化房间存档数据
function CycleInstanceModel:InitRoomData()
    for k,v in pairs(self.roomsConfig) do
        local roomID = v.id
        local data = self:GetCurRoomData(roomID)
        if next(data) == nil then --第一次进入场景,创建存档数据结构
            local state = 0
            if v.unlock_times == 0 then
                state = 2
            end
            self:SetRoomData(roomID, 0, state, nil, 0, true)
        end
        self.roomsData[roomID] = self:GetCurRoomData(roomID)

        --初始化设备数据
        if not self.roomsData[roomID].furList or next(self.roomsData[roomID].furList) == nil then
            for i,m in pairs(v.furniture) do
                local furLevelConfig = self:GetFurlevelConfig(m.id, m.level)
                local furState = 0
                if m.level > 0 then
                    furState = 1
                end
                local name = nil
                local attrs = nil
                local prefab = nil
                if furLevelConfig.isPresonFurniture then
                    name = self:GetRandomName()
                    ---循环副本不做属性
                    --attrs = {
                    --    hungry = InstanceDataManager.config_global.employeeUpperLimit,
                    --    physical = InstanceDataManager.config_global.employeeUpperLimit,
                    --}
                    local prefabIndex = math.random(#furLevelConfig.NPC_skin)
                    prefab = furLevelConfig.NPC_skin[prefabIndex]
                end
                local isOpen = nil
                if v.room_category == 4 then
                    isOpen = false
                end
                local furData = {
                    ["state"] = furState,
                    ["name"] = name,
                    --["Attrs"] = attrs,
                    ["prefab"] = prefab,
                    ["isOpen"] = isOpen
                }
                self:SetRoomFurnitureData(roomID,i,furLevelConfig.id,furData)
            end
        end

    end
end

function CycleInstanceModel:InitWorkerList()
    
end

function CycleInstanceModel:RegisterEvnet()
    EventManager:RegEvent("CYCLE_INSTANCE_TIME_TYPE_CHANGE", function(last,current)
        self.timeType = current

        --属性不需要恢复
        if last ~= CycleInstanceModel.TimeTypeEnum.work then
            self:WorkerAttrRevert(last,false)
        end

        if current ~= CycleInstanceModel.TimeTypeEnum.work then
            self:WorkerAttrRevert(current,true)
        end

        if current == CycleInstanceModel.TimeTypeEnum.work then
            SpicalRoomManager:CycleInstanceWorkTime()
        elseif current == CycleInstanceModel.TimeTypeEnum.eat then
            SpicalRoomManager:CycleInstanceEatTime()
        elseif current == CycleInstanceModel.TimeTypeEnum.sleep then
            SpicalRoomManager:CycleInstanceSleepTime()
        end

    end)
end

function CycleInstanceModel:OnEnter()
    attrThreshold = self.config_global.stateThreshold
    stateDebuff = self.config_global.stateDebuff
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
                        ["isOpen"] = i == "1" or i == "13" or false,   -- 初始化存档数据时,默认自动打开第一个港口
                        ["lastReachTime"] = current,
                        ["lastLeaveTime"] = 0,
                    }
                    self:SetRoomFurnitureData(v.roomID,m.index,m.id,furData)
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

    self.productions = Tools:CopyTable(self:GetProdutionsData())
    if next(self.productions) == nil then
        for k,v in pairs(self.resourceConfig) do
            self.productions[tostring(k)] = 0
        end
    end
    
    self:CalculateInstanceOfflineReward()
end

--开启副本内时间计算
function CycleInstanceModel:EnableTimeTimer()

    self.lastTimeType = self:GetCurInstanceTimeType()
    if self.timer then
        GameTimer:StopTimer(self.timer)
        self.timer = nil
    end
    --创建Timer,更新副本时间并发送事件
    self.timer = GameTimer:CreateNewTimer(1,function()
        if not CycleInstanceDataManager:GetInstanceIsActive(self.instance_id) then
            GameTimer:StopTimer(self.timer)
            self.timer = nil
            return
        end
        local curTimeType = self:GetCurInstanceTimeType()
        if curTimeType ~= self.lastTimeType or curTimeType ~= self.timeType then
            EventManager:DispatchEvent("CYCLE_INSTANCE_TIME_TYPE_CHANGE", self.lastTimeType, curTimeType)
            self.lastTimeType = curTimeType
        end
        LocalDataManager:WriteToFile()
        
        --计算材料是否充足(5s刷新一次)
        if self.checkMatTimer <= self.checkMatInterval then
            self.checkMatTimer = self.checkMatTimer + 1
            self.portExport = self:CalculateOfflineRewards(60, true, false)
        else
            self.checkMatTimer = 0
        end
        
    end,true,true)
end

--关闭副本内时间计算
function CycleInstanceModel:DisableTimeTimer()
    if self.timer then
        GameTimer:StopTimer(self.timer)
        self.timer = nil
    end
end


function CycleInstanceModel:GetCurInstanceTimeType()
    local curTime = self:GetCurInstanceTime()
    local timeArrange = CycleInstanceDataManager:GetInstanceBind(self.instance_id).instance_time_arrange
    for k,v in pairs(timeArrange) do
        if curTime.Hour >= v.range[1] and curTime.Hour < v.range[2] then
            return v.timeType
        end
    end
end

function CycleInstanceModel:Update(dt)
    --if true then
    --    return
    --end
    if CycleInstanceDataManager:GetInstanceIsActive() then
        self:CalculateInstanceOnlineReward(dt)

        if CycleInstanceScene then
            CycleInstanceScene:Update(dt)
        end
        if GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI,true) then
            GameTableDefine.InstancePopUI:CheckGiftPopShow()
        end
    else
        local instanceMainViewIndex = GameUIManager:GetUIIndex(ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI, true)
        if not isOpenExitPop and GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI,true) then
            local txt = GameTextLoader:ReadText("TXT_INSTANCE_TIP_END")
            isOpenExitPop = true
            GameTableDefine.ChooseUI:CommonChoose(txt, function()
                CycleIslandMainViewUI:Exit()
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

     --if Input.GetKeyDown(KeyCode.Z) then
     --    self:CalculateOfflineRewards(7200,false,true)
     --end
    -- if Input.GetKeyDown(KeyCode.X) then
    --     self:WorkerAttrRevert(InstanceDataManager.timeType.sleep)
    -- end
    -- if Input.GetKeyDown(KeyCode.C) then
    --     local result = BigNumber:FormatBigNumber(BigNumber:Divide(6.806800000000033E+4, 3.060969999999999E+5))
    -- end
    -- if Input.GetKeyDown(KeyCode.V) then
    --     InstanceDataManager:AddCurInstanceCoin(1000000000)
    --     InstanceMainViewUI:Refresh()
    -- end

end


function CycleInstanceModel:OnExit()
    if CycleInstanceScene then
        CycleInstanceScene:OnExit()
        self:UnregisterEvent()
        self:DisableTimeTimer()
    end
end

---游戏暂停，调用离线保存时间，退出副本和在副本中切换app到后台
function CycleInstanceModel:OnPause()
    GameTableDefine.CycleIslandOfflineRewardUI:CloseView()
    self.m_CurOfflineRewardData = nil
    if self.saveData and CycleInstanceDataManager:GetInstanceIsActive() then
        self.saveData.m_CurLastOfflineTime = GameTimeManager:GetCurServerOrLocalTime()
        LocalDataManager:WriteToFile()
    end
    GameSDKs:TrackForeign("cy_instance_quit", { type = "退出游戏（切换后台)" })
end

---游戏恢复，调用离线的计算，主要用于在副本中切到app后台
function CycleInstanceModel:OnResume()
    self:CalculateInstanceOfflineReward()
    GameTableDefine.CycleIslandOfflineRewardUI:GetView()
end

---注销事件
function CycleInstanceModel:UnregisterEvent()
    EventManager:UnregEvent("CYCLE_INSTANCE_TIME_TYPE_CHANGE")
end

--region 公共接口

function CycleInstanceModel:GetIsFirstEnter()
    if self.saveData then
        return self.saveData.m_FirstEnter == nil
    end
    return true
end

function CycleInstanceModel:SetIsFirstEnter()
    if self.saveData then
        self.saveData.m_FirstEnter = false
    end
end

---获取引导ID
function CycleInstanceModel:GetGuideID()
    if self.saveData then
        return self.saveData.m_Guide
    end
    return nil
end

function CycleInstanceModel:SetGuideID(value)

    if self.saveData then
        self.saveData.m_Guide = value
        LocalDataManager:WriteToFile()
    end
end

---计算在线收益
function CycleInstanceModel:CalculateInstanceOnlineReward(dt)
    self:CalculateFactoryUnitOutput(dt)
    self:CalculatePortExport(dt)
end

function CycleInstanceModel:RoomCanWork(roomID)
    local roomData = self:GetRoomDataByID(roomID)
    local canWork = self.timeType == CycleInstanceModel.TimeTypeEnum.work or roomData.isFullForce
    return canWork
end


---计算码头输出量
function CycleInstanceModel:CalculatePortExport(dt)
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
            local loadingCD = self.config_global.cycle_instance_ship_loadtime
            local portFurData = roomData.furList[tostring(v.index - 12)]  --这里直接写死,不然重复遍历去找对应的码头太耗了
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
                                CycleInstanceScene:SetShipBubbles(v.index,false,portFurData.isOpen, nil)
                            end
                        else    --装载完成离港
                            self.workCD[roomID][v.index] = 0
                            local sellCount = haveCount
                            local income = sellCount * self.resourceConfig[portLevelCfg.resource_type].price
                            self.productions[tostring(portLevelCfg.resource_type)] = self.productions[tostring(portLevelCfg.resource_type)] - sellCount
                            self:SetRoomFurnitureData(roomID,v.index,curFurData.id,{["lastLeaveTime"] = current})
                            self:SetProdutionsData(self.productions)
                            --得钱
                            local sellBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
                            local buffNum = self:GetSkillBufferValueBySkillID(sellBuffID)
                            income = income * buffNum
                            self:AddCurInstanceCoin(income)
                            CycleInstanceScene:SetShipBubbles(v.index,true,portFurData.isOpen, income)
                            CycleIslandMainViewUI:Refresh()
                            --显示通知
                            local resCfg = self.resourceConfig[curFurLevelCfg.resource_type]
                            CycleIslandMainViewUI:CallNotify(2,income,resCfg)
                            --船离港表现
                            CycleInstanceScene:PlayShipAnim(v.index,true)
                        end
                    else
                        --无可出售货物,cd不长
                    end
                end
            else    --船是离港状态
                if shipCD < comeCD  then    --等待船来
                    if shipCD + dt >= comeCD-7 and shipCD < comeCD-7 then
                        -- 船靠港表现
                        CycleInstanceScene:PlayShipAnim(v.index,false)
                    end
                    if self.workCD[roomID] and self.workCD[roomID][v.index] then    --不知道为什么这里会报错,加一个判空保护
                        self.workCD[roomID][v.index] = shipCD + dt
                    else
                        print("InstanceModel 1010:",roomID, v.index)
                    end
                else    --船靠港
                    self.workCD[roomID][v.index] = 0
                    self:SetRoomFurnitureData(roomID,v.index,curFurData.id,{["lastReachTime"] = current})

                end
            end

        end
    end
end

---计算工人属性(此版本不做计算)
function CycleInstanceModel:CalculateWorkerAttr(dt)
    --if self.workerAttrCalInterval < 1 then
    --    self.workerAttrCalInterval = self.workerAttrCalInterval + dt
    --    return
    --end
    --self.workerAttrCalInterval = 0
    --
    --local deltaAttr = 0 --old: InstanceDataManager.config_global.stateWeaken /60
    --for k,v in pairs(self.roomsData) do
    --    local roomID = v.roomID
    --    if v.furList and v.state == 2 then
    --        for furIndex,furData in pairs(v.furList) do
    --            deltaAttr = self:GetFurlevelConfigByRoomFurIndex(roomID,furIndex).weaken / 60
    --            if furData.worker and furData.state == 1 then
    --                if furData.worker.attrs then
    --                    furData.worker.attrs["hungry"] = furData.worker.attrs["hungry"] - deltaAttr
    --                    furData.worker.attrs["physical"]  = furData.worker.attrs["physical"] - deltaAttr
    --                    InstanceDataManager:SetRoomFurnitureData(roomID,furData.index,furData.id,{["Attrs"] = furData.worker.attrs})
    --                end
    --            end
    --        end
    --    end
    --end
end

---计算工厂单位时间的产量
function CycleInstanceModel:CalculateFactoryUnitOutput(dt)

    --遍历所有生产类型的房间数据,如果房间已解锁则计算产量和消耗
    for k,v in pairs(roomSortConfig) do
        if v.room_category == 1 then
            local roomID = v.id
            if self:RoomCanWork(roomID) then

                local curRoomData = self.roomsData[roomID]
                if curRoomData.state == 2 then
                    local cd = self:GetRoomCD(roomID)
                    self.workCD[roomID] = self.workCD[roomID] + dt

                    --计算一轮收益
                    if self.workCD[roomID] >= cd then
                        self.workCD[roomID] = 0
                        local materialID = v.material[1]
                        local productID = v.production
                        local haveCount = self.productions[tostring(materialID)]
                        local needCount = self:GetRoomMatCost(roomID)
                        local output, exp, points = self:GetRoomProduction(roomID)

                        self:AddScore(points)
                        self:ChangeCurHeroExpRes(exp)

                        --if materialID == 4 then
                        --    printf(self.productions[tostring(materialID)])
                        --end
                        if materialID ~= 0 then --需要原料
                            if not self.productions[tostring(materialID)] then
                                self.productions[tostring(materialID)] = 0
                            end

                            if haveCount > needCount then
                                self.productions[tostring(materialID)] = self.productions[tostring(materialID)] - needCount
                                self.productions[tostring(productID)] = self.productions[tostring(productID)] + output
                            else
                                self.productions[tostring(materialID)] = 0
                                self.productions[tostring(productID)] = self.productions[tostring(productID)] + math.floor(haveCount / v.material[2] )
                            end

                        else
                            self.productions[tostring(productID)] = self.productions[tostring(productID)] + output
                        end

                        --print(productID,output,self.productions[tostring(productID)])
                        self:SetRoomData(roomID, nil,nil,GameTimeManager:GetCurrentServerTime(true))

                    end

                end
            end

        end
    end
    self:SetProdutionsData(self.productions)
end

---设置副本产品信息
function CycleInstanceModel:SetProdutionsData(productions)
    if not productions or next(productions) == nil then
        return
    end
    if self.saveData then
        self.saveData.m_Productions = productions
    end
    -- LocalDataManager:WriteToFile()
end

---获取副本产品信息
function CycleInstanceModel:GetProdutionsData()

    if self.saveData then
        if not self.saveData.m_Productions then
            return {}
        else
            return self.saveData.m_Productions
        end
    end
end

---@return number 获取当前副本的时间，H:M:S
function CycleInstanceModel:GetCurInstanceTime()
    --副本中的开始时间globalData.instance_initial_time对应副本的starttime
    --副本的时间流逝频率globalData.instance_duration
    --已流逝时间真实时间
    -- local realOfftime =
    if not self.m_InstanceTimeScale then
        self.m_InstanceTimeScale = (24 * 60) / self.config_global.cycle_instance_duration
    end
    local result = {}
    result.Hour = 0
    result.Min = 0
    result.Sec = 0
    local saveData = self.saveData
    if saveData and saveData.m_StartTime and GameTimeManager:GetCurServerOrLocalTime() > saveData.m_StartTime then
        local DupOfftime = (GameTimeManager:GetSocketTime() - saveData.m_StartTime) * self.m_InstanceTimeScale
        DupOfftime = DupOfftime + 3600 * self.config_global.cycle_instance_initial_time

        result.Min = math.floor(DupOfftime % 86400 % 3600 / 60)
        result.Hour = math.floor(DupOfftime % 86400 / 3600)
    end
    return result
end


---改变副本当前时间,正数为时间向后,负数为时间向前
function CycleInstanceModel:ChangeCurrentTime(value)
    local saveData = self.saveData
    if saveData and saveData.m_StartTime then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local changeTime = 60 * self.config_global.cycle_instance_duration / 24 * value
        if saveData.m_StartTime - changeTime > now then
            saveData.m_StartTime = now
        else
            saveData.m_StartTime = saveData.m_StartTime - changeTime
        end
    end
end

function CycleInstanceModel:IsDay()
    local timeNode = self.config_global.cycle_instance_timenode
    local currentTime = self:GetCurInstanceTime()
    if currentTime.Hour >= tonumber(timeNode[1]) and currentTime.Hour < tonumber(timeNode[2]) then
        return true
    end
    return false
end

---返货当前副本中的货币
function CycleInstanceModel:GetCurInstanceCoin()
    if self.saveData then
        return LocalDataManager:DecryptField(self.saveData, CoinFieldName)
    end

    return 0
end

---增加当前副本金钱
function CycleInstanceModel:AddCurInstanceCoin(num,showFlyIcon)
    local coin = LocalDataManager:DecryptField(self.saveData, CoinFieldName)
    --coin = math.max(0, coin + num)
    coin = BigNumber:Add(coin,num)
    if BigNumber:CompareBig(0,coin) then
        coin = "0"
    end
    LocalDataManager:EncryptField(self.saveData, CoinFieldName, coin)
    self.saveData.m_CurInstanceCoin_Show = BigNumber:FormatBigNumber(coin)

    self:AddAccumulateCoin(num)
    self:AddTaskAccumulateCoin(num)

    if showFlyIcon and BigNumber:CompareBig(num,0) then
        FlyIconUI:SetCycleInstanceNum({{itemType = 31,str = num}})
    end
    
    CycleIslandMainViewUI:Refresh()
    CycleIslandBuildingUI:RefreshView()
end

function CycleInstanceModel:GetCurInstanceCoinShow()
    if self.saveData then
        return self.saveData.m_CurInstanceCoin_Show or 0
    end

    return 0
end

---增加[任务开启后]积累副本[货币]
function CycleInstanceModel:AddTaskAccumulateCoin(num)
    if BigNumber:CompareBig(num,0) then
        local current = self:GetTaskAccumulateCoin()
        self.saveData.m_taskAccumulateCoin = BigNumber:Add(current,num)
    end
end

---@return number 累计[任务开启后]获取的[货币]
function CycleInstanceModel:GetTaskAccumulateCoin()
    if self.saveData and self.saveData.m_taskAccumulateCoin then
        return self.saveData.m_taskAccumulateCoin
    end
    return 0
end

---@return number 重置[任务开启后]获取的[货币]
function CycleInstanceModel:ResetTaskAccumulateCoin()
    if self.saveData then
        self.saveData.m_taskAccumulateCoin = "0"
    end
end

---增加[任务开启后]积累副本[英雄经验]
function CycleInstanceModel:AddTaskAccumulateHeroExp(num)
    if BigNumber:CompareBig(num,0) then
        local current = self:GetTaskAccumulateHeroExp()
        self.saveData.m_taskAccumulateHeroExp = BigNumber:Add(current,num)
    end
end

---@return string 累计[任务开启后]获取的[英雄经验]
function CycleInstanceModel:GetTaskAccumulateHeroExp()
    if self.saveData and self.saveData.m_taskAccumulateHeroExp then
        return self.saveData.m_taskAccumulateHeroExp
    end
    return "0"
end

---@return number 重置[任务开启后]获取的[英雄经验]
function CycleInstanceModel:ResetTaskAccumulateHeroExp()
    if self.saveData then
        self.saveData.m_taskAccumulateHeroExp = "0"
    end
end

---增加[任务开启后]积累副本[扭蛋币](消耗的扭蛋币)
function CycleInstanceModel:AddTaskAccumulateSlotCoin(num)
    if num > 0 then
        local current = self:GetTaskAccumulateSlotCoin()
        self.saveData.m_taskAccumulateSlotCoin = current + num
        if self.saveData.m_taskAccumulateSlotCoin < 0 then
            self.saveData.m_taskAccumulateSlotCoin = 0
        end
    end
end

---@return number 累计[任务开启后]获取的[扭蛋币]
function CycleInstanceModel:GetTaskAccumulateSlotCoin()
    if self.saveData and self.saveData.m_taskAccumulateSlotCoin then
        return self.saveData.m_taskAccumulateSlotCoin
    end
    return 0
end

---@return number 重置[任务开启后]获取的[扭蛋币]
function CycleInstanceModel:ResetTaskAccumulateSlotCoin()
    if self.saveData then
        self.saveData.m_taskAccumulateSlotCoin = 0
    end
end

---增加积累副本金钱
function CycleInstanceModel:AddAccumulateCoin(num)
    if BigNumber:CompareBig(num,0) then
        local current = self:GetAccumulateCoin()
        self.saveData.m_AccumulateCoin = BigNumber:Add(current,num)
    end
end

---@return number 累计获取的货币
function CycleInstanceModel:GetAccumulateCoin()
    if self.saveData and self.saveData.m_AccumulateCoin then
        return self.saveData.m_AccumulateCoin
    end
    return 0
end

---获取某种资源的单位产量和消耗 (/min)
function CycleInstanceModel:GetProductionAndConsumptionPerMin(resourcesID)
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

---获取当前出售物品每分钟售价 (/min)
function CycleInstanceModel:GetInComePerMinute()
    local sellProductID = self:GetCurSellingProduct()
    local sellRoomCfg = nil
    for k, v in pairs(self.roomsConfig) do
        if v.production == sellProductID then
            sellRoomCfg = v
            break
        end
    end

    --售价buff
    local priceBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
    local buffNum = self:GetSkillBufferValueBySkillID(priceBuffID)

    local result = self:GetRoomProduction(sellRoomCfg.id)
    local roomCD = self:GetRoomCD(sellRoomCfg.id)
    result = BigNumber:Multiply(BigNumber:Multiply(result,self.resourceConfig[sellProductID].price),buffNum * 60.0 / roomCD)
    return result
end

---获取当前卖出的资源
function CycleInstanceModel:GetCurSellingProduct()
    local portRoomData = self:GetRoomDataByType(4)
    for k, v in pairs(portRoomData[1].furList) do
        if v.index <= 12 and v.isOpen then
            return v.index
        end
    end
    return 1
end

---获取一个房间每分钟的收益
function CycleInstanceModel:GetRoomIncomePerMin(roomID)
    local roomIncome = self:GetRoomProduction(roomID)
    local roomCD = self:GetRoomCD(roomID)
    local resID = self.roomsConfig[roomID].production
    local price = self.resourceConfig[resID].price

    local result = BigNumber:Multiply(roomIncome, (60 / roomCD * price))
    return result
end

---获取当前的最高收益
function CycleInstanceModel:GetCurHighestProfit()
    local income, roomID = 0, nil
    for k, v in pairs(self.roomsConfig) do
        local roomData = self:GetRoomDataByID(v.id)
        if v.room_category == 1 and roomData.state == 2 then
            local curRoomIncomePreMin = self:GetRoomIncomePerMin(v.id)
            if BigNumber:CompareBig(curRoomIncomePreMin, income) then
                income = curRoomIncomePreMin
                roomID = v.id
            end
        end
    end
    local resID = self.roomsConfig[roomID].production
    return income, roomID, resID
end

---获取某种资源的锁定状态
function CycleInstanceModel:GetResLockedState(resourcesID)
    for k,v in pairs(self.roomsData) do
        local roomID = v.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.production == resourcesID then
            if v.state == 2 then
                return true
            end
        end
    end

    return false
end


---获取房间工作CD
function CycleInstanceModel:GetRoomCD(roomID)
    local cd = self.roomsConfig[roomID].bastCD
    local reduce = 0 --self:GetRoomCDReduce(roomID)
    return cd - reduce
end


--endregion


--region 场景

---最高生产房间存档
function CycleInstanceModel:GetHighestLevelUnlockedBuildingData()
    if self.saveData then
        local curID = nil
        for k, v in pairs(self.saveData.m_RoomData) do
            local roomConfig = self:GetRoomConfigByID(v.roomID)
            if v.state == 2 and roomConfig.room_category == 1 then
                curID = not curID and v.roomID or (curID < v.roomID and v.roomID or curID)
            end
        end
        return self:GetRoomDataByID(curID)
    end
    
    return nil
end

function CycleInstanceModel:LocatePosition(position,IsShowMove,cb)
    CycleInstanceScene:LocatePosition(position,IsShowMove,cb)
end

function CycleInstanceModel:Position3dTo2d(position)
    return CycleInstanceScene:Position3dTo2d(position)
end

---刷新副本场景
function CycleInstanceModel:RefreshScene()
    CycleInstanceScene:RefreshScene()
end

function CycleInstanceModel:PlayPortAnimation(closeIndex, openIndex)
    CycleInstanceScene:PlayPortAnimation(closeIndex, openIndex)
end

function CycleInstanceModel:InitScene()
    --初始化场景
    CycleInstanceScene = require("GamePlay/CycleInstance/Island/CycleInstanceScene").new()
    CycleInstanceScene:InitScene()
    self:RegisterEvnet()
    CycleInstanceScene:OnEnter()
    self:EnableTimeTimer()
end

---获取英雄存档
function CycleInstanceModel:GetHeroSaveData()
    if self.saveData then
        local heroData = self.saveData["CycleIslandHero"]
        if not heroData then
            heroData = {}
            self.saveData["CycleIslandHero"] = heroData
        end
        return heroData
    end
    return {}
end

---获取任务存档
function CycleInstanceModel:GetTaskSaveData()
    if self.saveData then
        local taskData = self.saveData["CycleIslandTaskData"]
        if not taskData then
            taskData = {}
            self.saveData["CycleIslandTaskData"] = taskData
        end
        return taskData
    end
    return {}
end

---返回制定房间的数据，table中的数据结构
function CycleInstanceModel:GetCurRoomData(roomID)
    local key = tostring(roomID)
    if self.saveData and self.saveData.m_RoomData and self.saveData.m_RoomData[key] then
        return self.saveData.m_RoomData[key]
    end
    return {}
end

--[[
    @desc: 获取当前售卖货架的index
    author:{author}
    time:2024-07-11 11:38:50
    @return:
]]
function CycleInstanceModel:GetSellingIndex()
    --先找港口房间的roomData
    local portRoomData = nil
    for k, v in pairs(self.saveData.m_RoomData) do
        local roomCfg = self.roomsConfig[tonumber(v.roomID)]
        if roomCfg and roomCfg.room_category and roomCfg.room_category == 4 then
            portRoomData = v
            break
        end
    end
    if not portRoomData then
        return 1
    end
    local resKey = 0
    for k, v in pairs(portRoomData.furList) do
        if v.index <= 12 and v.isOpen then
            resKey = tonumber(k)
            break
        end
    end
    if resKey == 0 then
        return 1
    end
    return resKey
end

function CycleInstanceModel:GetSellingRoomID()
    --先找港口房间的roomData
    local portRoomData = nil
    for k, v in pairs(self.saveData.m_RoomData) do
        local roomCfg = self.roomsConfig[tonumber(v.roomID)]
        if roomCfg and roomCfg.room_category and roomCfg.room_category == 4 then
            portRoomData = v
            break
        end
    end
    if not portRoomData then
        return nil
    end
    local resKey = 0
    for k, v in pairs(portRoomData.furList) do
        if v.index <= 12 and v.isOpen then
            resKey = tonumber(k)
            break
        end
    end
    if resKey == 0 then
        return 1001
    end
    for k, v in pairs(self.saveData.m_RoomData) do
        local roomCfg = self.roomsConfig[tonumber(v.roomID)]
        if roomCfg and roomCfg.room_category == 1 then
            if resKey == roomCfg.production then
                return tonumber(v.roomID)
            end
        end
    end
    return nil
end

---设置一个副本房间的存档数据,不设置的参数传nil(不含设备列表数据)
function CycleInstanceModel:SetRoomData(roomID, buildTimePoint, state, lastSettlementTime, worker, isFullForce)
    if not roomID then
        return
    end
    local roomData = nil
    local roomIDStr = tostring(roomID)
    if not self.saveData.m_RoomData then
        self.saveData.m_RoomData = {}
    end
    if not self.saveData.m_RoomData[roomIDStr] then
        self.saveData.m_RoomData[roomIDStr] = {}
    end
    roomData = self.saveData.m_RoomData[roomIDStr]
    roomData.roomID = roomID
    roomData.buildTimePoint = buildTimePoint or self.saveData.m_RoomData[roomIDStr].buildTimePoint
    roomData.state = state or self.saveData.m_RoomData[roomIDStr].state
    roomData.lastSettlementTime = lastSettlementTime or self.saveData.m_RoomData[roomIDStr].lastSettlementTime
    if self.roomsConfig[roomID].room_category == 1 then
        if worker then
            roomData.worker = worker
        end
        if isFullForce then
            roomData.isFullForce = isFullForce
        end
    end
    -- LocalDataManager:WriteToFile()
end

---根据设备ID和设备等级获取furLevelConfig
function CycleInstanceModel:GetFurlevelConfig(furID,level)
    if level == 0 then
        level = 1
    end
    --for k,v in pairs(self.furnitureLevelConfig) do
    --    if v.furniture_id == furID and v.level == level then
    --        return v
    --    end
    --end
    local configs = self.furnitureLevelConfig_furID[furID]
    if configs and configs[level] then
        return configs[level]
    else
        printf("未找到furID为:" .. furID .. " level:" .. level .. "对应的fueLevel配置")
    end
end

--[[
    @desc: 随机取名
    author:{author}
    time:2023-04-09 10:55:27
    @return:
]]
function CycleInstanceModel:GetRandomName()
    local configName = ConfigMgr.config_character_name
    local name = {
        [1] = math.random(1, #configName.first),
        [2] = math.random(1, #configName.second)
    }
    return name
end




---设置一个副本房间的设备存档数据,四个参数每个都必须传值,不能为nil, 要设置的设备数据表,将要要设置的值都放在这里面用"attrName"= xxx,的这种形式设置
function CycleInstanceModel:SetRoomFurnitureData(roomID, index, levelID, furnitureData)

    if not roomID then
        return
    end
    local roomIDStr = tostring(roomID)
    local roomData = nil
    if self.saveData and self.saveData.m_RoomData and self.saveData.m_RoomData[roomIDStr] then
        roomData = self.saveData.m_RoomData[roomIDStr]
    else
        return
    end
    if not roomID or not index or not levelID or not furnitureData or next(furnitureData) == nil then
        return
    end

    roomData.furList = roomData.furList or {}
    local indexStr = tostring(index)
    roomData.furList[indexStr] = roomData.furList[indexStr] or {}
    roomData.furList[indexStr].index = index
    roomData.furList[indexStr].id = levelID

    for k,v in pairs(furnitureData) do
        if k == "state" then
            roomData.furList[indexStr].state = v

        elseif k == "name" then
            roomData.furList[indexStr].worker = roomData.furList[indexStr].worker or {}
            roomData.furList[indexStr].worker.name = v
        --
        --elseif k == "Attrs" then
        --    roomData.furList[indexStr].worker = roomData.furList[indexStr].worker or {}
        --    roomData.furList[indexStr].worker.attrs = v
        --    if roomData.furList[indexStr].worker.attrs["hungry"] < 0 then
        --        roomData.furList[indexStr].worker.attrs["hungry"] = 0
        --    end
        --    if roomData.furList[indexStr].worker.attrs["hungry"] > 100 then
        --        roomData.furList[indexStr].worker.attrs["hungry"] = 100
        --    end
        --    if roomData.furList[indexStr].worker.attrs["physical"] < 0 then
        --        roomData.furList[indexStr].worker.attrs["physical"] = 0
        --    end
        --    if roomData.furList[indexStr].worker.attrs["physical"] > 100 then
        --        roomData.furList[indexStr].worker.attrs["physical"] = 100
        --    end
        elseif  k == "prefab" then
            roomData.furList[indexStr].worker = roomData.furList[indexStr].worker or {}
            roomData.furList[indexStr].worker.prefab = roomData.furList[indexStr].worker.prefab or {}
            table.insert(roomData.furList[indexStr].worker.prefab,v)
        elseif k == "isOpen" then
            roomData.furList[indexStr].isOpen = v

        elseif k == "lastReachTime" then
            roomData.furList[indexStr].lastReachTime = v

        elseif k == "lastLeaveTime" then
            roomData.furList[indexStr].lastLeaveTime = v
        end
    end

end

---获取房间解锁时间点
function CycleInstanceModel:GetRoomUnlockTime(roomID)
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
    @desc: 根据设备ID获取furConfig
    author:{author}
    time:2023-04-04 16:04:08
    --@furID: 
    @return:
]]
function CycleInstanceModel:GetFurConfigByID(furID)
    for k,v in pairs (self.furnitureConfig) do
        if v.id == furID then
            return v
        end
    end
    return nil
end

---房间是否解锁
function CycleInstanceModel:RoomIsUnlock(roomID)
    local roomData = self.roomsData[roomID]
    return roomData.state > 1
end


---根据roomID返回roomCfg
function CycleInstanceModel:GetRoomConfigByID(roomID)
    return self.roomsConfig[roomID] or nil
end


---获取一个房间单位时间的产品产量
function CycleInstanceModel:GetRoomProduction(roomID)
    local count, exp, points = 0, 0, 0
    local roomData = self.roomsData[roomID]
    for k, v in pairs(roomData.furList) do
        if v.state == 1 then
            local furLevelCfg = self.furnitureLevelConfig[v.id]
            local production = tonumber(furLevelCfg.product)
            production = production * furLevelCfg.magnification
            count = count + production
            local point = tonumber(self.furnitureLevelConfig[v.id].point)
            points = points + point
        end
    end
    
    local heroBuff = CycleIslandHeroManager:GetHeroCurrentBuff(self.roomsConfig[roomID].hero_id)
    count = count * heroBuff
    local workerCount = self:GetWorkerNum(roomID)
    count = count * workerCount
    
    exp = tonumber(self.roomsConfig[roomID].exp)
    local expBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddBooks)
    local buffNum = self:GetSkillBufferValueBySkillID(expBuffID)
    exp = exp * buffNum

    if not self:GetLandMarkCanPurchas() then --买了地标
        local instanceBind = CycleInstanceDataManager:GetInstanceBind()
        local landmarkID = instanceBind.landmark_id
        local shopCfg = ConfigMgr.config_shop[landmarkID]
        local resAdd = shopCfg.param[1]
        count = count * (resAdd/100)
        resAdd = shopCfg.param2[1]
        exp = exp * (resAdd/100)
        resAdd = shopCfg.param3[1]
        points = points * (resAdd/100)
    end
    
    return count, exp, points
end

---获取一个房间所有冷却缩减
function CycleInstanceModel:GetRoomCDReduce(roomID)
    local count = 0
    --local roomData = self.roomsData[roomID]
    --for k,v in pairs(roomData.furList) do
    --    if v.state == 1 then
    --        local attrSum = self:GetFurLevelCfgAttrSum(v.id, "cooltime")
    --        count = count + attrSum
    --    end
    --end
    return count
end

---获取一个房间单位时间的材料消耗
function CycleInstanceModel:GetRoomMatCost(roomID)
    local count = 0
    local roomCfg = self.roomsConfig[roomID]
    if #roomCfg.material > 1 then
        local production = self:GetRoomProduction(roomID)
        local materialCfg = self.resourceConfig[roomCfg.material[1]]
        count = production * roomCfg.material[2]
        return count, materialCfg
    else
        return count, nil
    end
end

---修改房间员工数量
--function CycleInstanceModel:ModifyRoomWorker(roomID, value)
--    local roomData = self:GetCurRoomData(roomID)
--    if not roomData then
--        return
--    end
--    if not roomData.worker then
--        return
--    end
--    roomData.worker = roomData.worker + value
--    if roomData.worker < 0 then
--        roomData.worker = 0
--    end
--end

---获取房间员工数量
function CycleInstanceModel:GetWorkerNum(roomID)
    local roomData = self:GetCurRoomData(roomID)
    --return roomData.worker or 0
    local furListData = roomData.furList
    for k,v in pairs(furListData) do
        local furLevelCfg = self.furnitureLevelConfig[v.id]
        if furLevelCfg.worker then
            return furLevelCfg.worker
        end
    end
    return 0
end

---房间是全力模式
function CycleInstanceModel:GetRoomIsFullForce(roomID)
    local roomData = self:GetCurRoomData(roomID)
    return roomData.isFullForce
end

---@param value boolean
function CycleInstanceModel:SetRoomIsFullForce(roomID, value)
    -- 数据
    local roomData = self:GetCurRoomData(roomID)
    roomData.isFullForce = value
    -- 表现
    if self.timeType == CycleInstanceModel.TimeTypeEnum.sleep then
        local personList = CycleInstanceScene.personList[roomID]
        if personList and personList[1] then
            personList = personList[1]
            for pIndex,worker in pairs(personList) do
                worker:ForceWork(value)
            end
        end
    end
end


---房间是否解锁
function CycleInstanceModel:RoomIsUnlock(roomID)
    local roomData = self.roomsData[roomID]
    return roomData.state > 1
end

---购买房间
function CycleInstanceModel:BuyRoom(roomID)
    --设置存档信息
    local timePoint = GameTimeManager:GetCurrentServerTime(true)
    self:SetRoomData(roomID,timePoint,1)

    CycleInstanceScene:RefreshRoom(roomID)
    --花钱
    local cost = tonumber(self.roomsConfig[roomID].unlock_require)
    local buffID = self:GetSkillIDByType(CycleInstanceModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:AddCurInstanceCoin(-cost)
    CycleIslandMainViewUI:Refresh()

    --AI通知, 现在直接在购买时通知AI会导致房子还在建,排队的人已经进入睡觉或吃饭了, 所以先注释掉  
    --local roomCfg = self.roomsConfig[roomID]
    --for i = 1, #roomCfg.furniture do
    --    local furData = roomCfg.furniture[i]
    --    local furLevelCfg = self:GetFurlevelConfig(furData.id,furData.level)
    --    InstanceAIBlackBoard:OnBuyFurCallBack(roomCfg, i, furLevelCfg)
    --end

    -- 礼包弹窗触发事件
    CycleInstancePopUI:PackTrigger(CycleInstancePopUI.EventType.buyRoom, roomID)
    
    --埋点
    local lastRoomID = roomID - 1
    local lastRoomDate = self:GetRoomDataByID(lastRoomID)
    local lastRoomFurLevelID = lastRoomDate.furList["1"].id
    local lastRoomFurLevelCfg = self:GetFurLevelConfigByLevelID(lastRoomFurLevelID)
    local roomCfg = self:GetRoomConfigByID(roomID)
    local heroData = CycleIslandHeroManager:GetHeroData(roomCfg.hero_id)
    
    GameSDKs:TrackForeign("cyinstance_unlock", { id = roomID, mile_level_new = tonumber(self:GetCurInstanceKSLevel()) or 0, fur_level_new = tonumber(lastRoomFurLevelCfg.level) or 0, hero_level_new = tonumber(heroData.level) or 0 })

end

---检查房间是否满足解锁条件
function CycleInstanceModel:CheckRoomCondition(roomID)
    local roomData = self:GetCurRoomData(roomID)
    local roomConfig = self:GetRoomConfigByID(roomID)
    local money = self:GetCurInstanceCoin()
    local cost = tonumber(roomConfig.unlock_require)
    local buffID = self:GetSkillIDByType(CycleInstanceModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    local lastRoomData = self:GetCurRoomData(roomConfig.unlock_room)
    if roomData and next(roomData) ~= nil and cost <= money and lastRoomData and lastRoomData.state and lastRoomData.state == 2 then
        return true
    else
        return false
    end
end


---购买家具
function CycleInstanceModel:BuyFurniture(roomID, index, furLevelID)
    local roomData = self.roomsData[roomID]
    local furData = roomData.furList[tostring(index)]
    local isNew = true
    if furData and next(furData) ~= nil then
        isNew = false
    end
    local furnitureData = {["state"] = 1 }
    --刷新工人列表
    local furLevelData = self.furnitureLevelConfig[furLevelID]
    if furLevelData.isPresonFurniture and furLevelData.level >1 then
        local preLevelData = self.furnitureLevelConfig[furLevelID-1]
        if preLevelData.worker<furLevelData.worker then
            local prefabIndex = math.random(#furLevelData.NPC_skin)
            furnitureData.prefab = furLevelData.NPC_skin[prefabIndex]
        end
    else
        if furLevelData.isPresonFurniture and furLevelData.level == 1 then
            table.insert(self.workerList[roomID], index)
        end
    end
    --设置存档信息
    self:SetRoomFurnitureData(roomID, index, furLevelID, furnitureData)

    --刷新场景中的物体
    CycleInstanceScene:RefreshRoom(roomID, index, true)

    --花钱
    local furLevelCfg = self.furnitureLevelConfig[furLevelID]
    local cost = tonumber(furLevelCfg.cost)
    local buffID = self:GetSkillIDByType(CycleInstanceModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:AddCurInstanceCoin(-cost)
    CycleIslandMainViewUI:Refresh()
    --增加升级埋点,每5级埋点一次
    if furLevelCfg.level % 10 == 0 then
        GameSDKs:TrackForeign("cy_fur_upgrade", { id = tonumber(roomID), level = tonumber(furLevelCfg.level) })
    end
    --显示通知
    if furLevelCfg.level == 1 and furLevelCfg.isPresonFurniture then
        CycleIslandMainViewUI:CallNotify(1)
    end

    --AI通知
    --local roomCfg = self.roomsConfig[roomID]
    --InstanceAIBlackBoard:OnBuyFurCallBack(roomCfg, index, furLevelCfg)
    --
    ----埋点
    --GameSDKs:TrackForeign("equipment_upgrade", {equipment_id_instance = tostring(furLevelCfg.furniture_id) , equipment_level_instance = furLevelCfg.level, room_id_instance  = tostring(roomID)})
    --local _,money = self:CalculateOfflineRewards(60,false,false)
    --money = math.floor(money)
    --if money == 0 then
    --    money = 1
    --end
    --GameSDKs:TrackForeign("equipment_upgrade", {equipment_id_instance = tostring(furLevelCfg.furniture_id) ,
    --                                            equipment_level_instance = furLevelCfg.level, room_id_instance = tostring(roomID),
    --    --[[ cost_instance = cost, productivity_instance = money,
    --        cpp_instance = cost/money]]
    --})
end

---显示选中的家具
function CycleInstanceModel:ShowSelectFurniture(furGO,preBuy)
    CycleInstanceScene:ShowSelectFurniture(furGO,preBuy)
end

--[[
    @desc: 获取家具GameObject
    author:{author}
    time:2023-04-26 18:27:52
    @return:
]]
function CycleInstanceModel:GetSceneRoomFurnitureGo(roomID, furIndex, subIndex)
    return CycleInstanceScene:GetSceneRoomFurnitureGo(roomID, furIndex, subIndex)
end

---获取一个家具(餐桌/床)座位的数量
function CycleInstanceModel:GetAllFurSeatCount(furnitureID)
    return self.furnitureConfig[furnitureID].seat
end

--endregion


--region 里程碑

function CycleInstanceModel:GetMaxAchievementLevel()
    return Tools:GetTableSize(self.config_cy_instance_reward)
end

---增加积分,自动处理越界情况
function CycleInstanceModel:AddScore(num)
    if BigNumber:CompareBig(num,0) then
        local isMaxLevel = false
        local curAchievement = self:GetCurInstanceKSLevel()
        local nextLevel = curAchievement + 1

        if curAchievement == #self.config_cy_instance_reward then
            isMaxLevel = true
            return
        end
        if isMaxLevel then
            nextLevel = curAchievement
        end
        local curAchiCfg = self.config_cy_instance_reward[nextLevel]
        local currentAchi = self:GetCurInstanceScore()
        local addedAchi = BigNumber:Add(currentAchi,num)
        if not BigNumber:CompareBig(curAchiCfg.experience,addedAchi)then
            if isMaxLevel then
                self:SetCurInstanceScore(curAchiCfg.experience)
                --CycleIslandMainViewUI:PlayMilestoneAnim()
                --return
            else
                self:SetCurInstanceKSLevel(nextLevel)
                --self:SetCurInstanceScore(0)
                self:SetCurInstanceScore(curAchiCfg.experience)
                local remainder = BigNumber:Subtract( addedAchi,curAchiCfg.experience)
                self:AddScore(remainder)
            end
        else
            self:SetCurInstanceScore(addedAchi)
            --CycleIslandMainViewUI:PlayMilestoneAnim()
            --return
        end
    end
end

---返回当前副本的分数
function CycleInstanceModel:GetCurInstanceScore()
    if self.saveData then
        return LocalDataManager:DecryptField(self.saveData,ScoreFieldName)
    end
    return 0
end

---设置积分
function CycleInstanceModel:SetCurInstanceScore(value)
    if self.saveData then
        LocalDataManager:EncryptField(self.saveData,ScoreFieldName,value)
        self.saveData.m_CurScore_Show = BigNumber:FormatBigNumber(value)
    end
end

function CycleInstanceModel:GetCurInstanceScoreShow()
    if self.saveData then
        return self.saveData.m_CurScore_Show or 0
    end
    return 0
end


---获得当前里程碑
function CycleInstanceModel:GetCurInstanceKSLevel()
    local result = 0
    if not self.saveData.m_CurKSLevel then
        self.saveData.m_CurKSLevel = 0
        --增加用户属性2024-8-20
        local userAttrData = {}
        userAttrData["ob_cy_"..tostring(self.instance_id or 1).."_milepoint_level"] = 0
        GameSDKs:SetUserAttrToWarrior(userAttrData)
    end
    result = self.saveData.m_CurKSLevel or 0

    return result
end

---设置积分等级
function CycleInstanceModel:SetCurInstanceKSLevel(value)
    if self.saveData then
        self.saveData.m_CurKSLevel = value
        CycleIslandMainViewUI:CallNotify(3)
        --for k, v in ipairs(self.config_achievement_instance) do
        --    if self.saveData.m_CurKSLevel >= v.level then
        --        --if v.pack > self.saveData.curMaxGiftID and GameTableDefine.ShopManager:CheckBuyTimes(v.pack) then
        --        --    GameTableDefine.InstancePopUI:SetSaveShowID(v.pack)
        --        --    CycleIslandMainViewUI:RefreshPackButton()
        --        --    -- break
        --        --end
        --    end
        --end

        -- LocalDataManager:WriteToFile()

        local maxRoomData = self:GetHighestLevelUnlockedBuildingData()
        local roomID = maxRoomData.roomID
        local furLevelConfig = self:GetFurlevelConfigByRoomFurIndex(roomID,1)
        local furLevel = furLevelConfig and furLevelConfig.level or 1
        local heroID = self.roomsConfig[roomID].hero_id
        local heroLevel = CycleIslandHeroManager:GetHeroData(heroID).level
        local skillData = self:GetCurSkillData()

        local skill1Level = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[1]).skill_level
        local skill2Level = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[2]).skill_level
        local skill3Level = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillData[3]).skill_level

        GameSDKs:TrackForeign("cyinstance_mile", {level_new = tonumber(value) or 0,
                                                  room_id = roomID,
                                                  room_fur_level_new = tonumber(furLevel) or 0,
                                                  heroLevel_new = tonumber(heroLevel) or 0,
                                                  skill_1_level_new = tonumber(skill1Level) or 0,
                                                  skill_2_level_new = tonumber(skill2Level) or 0,
                                                  skill_3_level_new = tonumber(skill3Level) or 0
        })
        --增加用户属性2024-8-20
        local userAttrData = {}
        userAttrData["ob_cy_"..tostring(self.instance_id or 1).."_milepoint_level"] = value
        GameSDKs:SetUserAttrToWarrior(userAttrData)
    end
end

function CycleInstanceModel:GetScene()
    return CycleInstanceScene
end

---返回当前副本的分数
function CycleInstanceModel:GetCurInstanceScore()
    if self.saveData then
        return LocalDataManager:DecryptField(self.saveData,ScoreFieldName)
    end
    return 0
end

--[[
    @desc:获取当前里程碑所有没有领取的里程碑奖励 
    author:{author}
    time:2024-07-02 15:05:20
    @return:
]]
function CycleInstanceModel:GetAllSKRewardNotClaim()
    local resultRewards = {}
    for k, v in pairs(self.config_cy_instance_reward) do
        local isClaimed = false
        for k1, v1 in pairs(self.saveData.m_ObtainRewards or {}) do
            if v1 == v.level then
                isClaimed = true
                break
            end
        end 
        -- if not isClaimed and v.level <= self:GetCurInstanceKSLevel() then
        if not isClaimed then
            local reward = self:GetRewardByLevel(v.level)
            if reward and next(reward) ~= nil then
                table.insert(resultRewards, self:GetRewardByLevel(v.level)) 
            end
        end
    end

    return resultRewards
end

--[[
    @desc:获得当前等级的奖励 
    author:{author}
    time:2024-07-02 14:30:43
    --@level: 
    @return:
]]
function CycleInstanceModel:GetRewardByLevel(level)
    local rewards = {}
    if level > self:GetCurInstanceKSLevel() then
        return rewards
    end
    for k, v in pairs(self.config_cy_instance_reward) do
        if v.level == level then
            rewards.level = level
            rewards.shop_id = v.shop_id
            rewards.count = v.count
            break
        end
    end
    return rewards
end

function CycleInstanceModel:RealGetRewardByLevel(level)
    if level > self:GetCurInstanceKSLevel() then
        return false
    end
    for _, v in pairs(self.saveData.m_ObtainRewards or {}) do
        if v == level then
            return false
        end
    end
    if not self.saveData.m_ObtainRewards then
        self.saveData.m_ObtainRewards = {}
    end
    for k, v in pairs(self.saveData.m_ObtainRewards) do
        if v == level then
            return false
        end
    end
    table.insert(self.saveData.m_ObtainRewards, level)
    local shopID = self.config_cy_instance_reward[level].shop_id
    local shopCfg = ConfigMgr.config_shop[shopID]
    if shopCfg.type == 3 or shopCfg.type == 4 or shopCfg.type == 29 then
        local amount = shopCfg.amount * self.config_cy_instance_reward[level].count
        if shopCfg.type == 3 then
            ResourceManger:AddDiamond(amount)
            --埋点
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "循环副本里程碑", behaviour = 1, num_new = tonumber(amount)})
        elseif shopCfg.type == 4 then
			ResourceManger:AddTicket(amount)
			GameSDKs:TrackForeign("ad_ticket", {behavior = 1, num_new = tonumber(amount) or 0, source = "里程碑奖励"})
        elseif shopCfg.type == 29 then
            ResourceManger:AddWheelTicket(amount)
            GameSDKs:TrackForeign("wheel_ticket", {behavior = 1, num_new = tonumber(amount)})
        end
    else
        --首先判断是否要转换成钻石发放
        local addDiamond = self:GetSameShopItemConverToDiamond(shopID)
        if addDiamond > 0 then
            ResourceManger:AddDiamond(addDiamond)
        end
        
        --小时现金
        if shopCfg.type == 9 then
            local resType = ResourceManger:GetShopCashType(shopCfg.country)
            local cashType = 2
            local countryCode = 1
            local amount = shopCfg.amount * self.config_cy_instance_reward[level].count * 3600 / 30
            local num = GameTableDefine.FloorMode:GetTotalRent() * amount
            if resType == "euro" and GameTableDefine.CityMode:CheckBuildingSatisfy(700) then
                num = GameTableDefine.FloorMode:GetTotalRent(nil, 2) * amount
                cashType = 6
                countryCode = 2
            end
            ResourceManger:Add(cashType, num, nil, nil, true)
            GameSDKs:TrackForeign("cash_event", {type_new = tonumber(countryCode), change_new = 0, amount_new = tonumber(num) or 0, position = "副本里程碑奖励"})
        else
            GameTableDefine.ShopManager:Buy(shopID, false, nil, nil)
        end
    end
    GameSDKs:TrackForeign("cy_mile_claim", { level = tonumber(level) })
    return true
end

function CycleInstanceModel:IsLevelRewardClaimed(level)
    local result = false
    for k, v in pairs(self.saveData.m_ObtainRewards or {}) do
        if v == level then
            return true
        end
    end
    return result
end

---获得当前未领奖的等级
function CycleInstanceModel:GetNotClaimedLevel()
    if self.saveData and self.saveData.m_CurKSLevel then
        for i = 1, self.saveData.m_CurKSLevel do
            if not self:IsLevelRewardClaimed(i) then
                return i
            end
        end
        return 0
    end
    return 0
end

---是否有任何奖励可以领取
function CycleInstanceModel:IsAnyRewardCanClaim()
    if self.saveData then
        local curLevel = self:GetCurInstanceKSLevel()
        if curLevel>0 then
            for i = 1, curLevel do
                if not self:IsLevelRewardClaimed(i) then
                    return true
                end
                --if not self.saveData.m_ObtainRewards or not self.saveData.m_ObtainRewards[tostring(i)] then
                --    return true
                --end
            end
        end
    end
    return false
end

function CycleInstanceModel:GetSameShopItemConverToDiamond(shopId)
    local backDiamond = 0
    local currCfg = GameTableDefine.ShopManager:GetCfg(shopId)
    if currCfg and GameTableDefine.ShopManager:BoughtBefor(shopId) then 
        --增加单个商品购买时判断是否转钻石
        if currCfg.type == 13 or currCfg.type == 14 then--宠物保安,配置在param2[1]
            backDiamond = backDiamond + currCfg.param2[1]
        elseif currCfg.type == 6 or currCfg.type == 7 then--npc
            backDiamond = backDiamond + currCfg.param[1]
        elseif currCfg.type == 5 then--免广告
            backDiamond = backDiamond + currCfg.param[1]
        end
        
    end
    return backDiamond
end
--endregion


--region 商店

--[[
    @desc:副本内特殊商品购买的回调 
    author:{author}
    time:2024-06-28 14:42:34
    --@shopID: 
    @return: 道具数量
]]
function CycleInstanceModel:InstanceShopBuySccess(shopID,showFlyIcon,showRewardUI,complex)
    local shopCfg = ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return 0
    end

    if 26 ~= shopCfg.type and 27 ~= shopCfg.type and 30 ~= shopCfg.type then
        return 0
    end

    complex = complex or 1

    if 26 == shopCfg.type then
        --增加英雄经验
        local num =  ShopManager:GetValueByShopId(shopID)
        if complex > 1 then
            num = BigNumber:Multiply(complex,num)
        end
        self:ChangeCurHeroExpRes(num)

        if showFlyIcon then
            FlyIconUI:SetCycleInstanceNum({{itemType = 26,str = BigNumber:FormatBigNumber(num)}})
        elseif showRewardUI then
            --获得奖励界面
            GameTableDefine.CycleInstanceRewardUI:ShowGetReward({shop_id = shopID,count = num},true)
        end

        return num
    end
    if 27 == shopCfg.type then
        --增加技能点
        self:AddBuySkillTimes(shopID)
        local skillInfos = self:AddSkillPoints(shopCfg.amount * complex)
        if showFlyIcon then
            local res = {}
            for k,v in pairs(skillInfos) do
                if v>0 then
                    table.insert(res,{itemType = 27,str = v,icon = "icon_cy1_skill_"..k})
                end
            end
            FlyIconUI:SetCycleInstanceNum(res)
        elseif showRewardUI then
            --获得奖励界面
            GameTableDefine.CycleInstanceRewardUI:ShowGetReward({shop_id = shopID,count = 1,param = skillInfos},true)
        end
        return skillInfos
    end
    if 30 == shopCfg.type then
        --增加拉霸机代币
        local coin = shopCfg.amount * complex
        self:ChangeSlotCoin(coin)
        GameSDKs:TrackForeign("cy_get_coin", { source = "商店购买", num = tonumber(coin), shopID = tonumber(shopID) })

        if showFlyIcon then
            FlyIconUI:SetCycleInstanceNum({{itemType = 30,str = coin}})
        elseif showRewardUI then
            --获得奖励界面
            GameTableDefine.CycleInstanceRewardUI:ShowGetReward({shop_id = shopID,count = coin},true)
        end

        return coin
    end
end

--[[
    @desc:获取免费代币冷却时间(商店)
    author:{author}
    time:2024-07-03 16:25:55
    @return:
]]
function CycleInstanceModel:GetSlotFreeCoinCDTime()
    local isFirst = false
    if not self.saveData.m_GetSlotFreeCoinTime then
        isFirst = true
        -- self.saveData.m_GetSlotFreeCoinTime = GameTimeManager:GetCurrentServerTime(true)
    end
    if isFirst then
        return 0
    end
    local offsetTime = GameTimeManager:GetCurrentServerTime(true) - self.saveData.m_GetSlotFreeCoinTime
    local cfgTime = self.config_global.cycle_instance_freeCoinTime * 60
    if offsetTime >= cfgTime then
        return 0
    else
        return cfgTime - offsetTime
    end
end

---获取免费代币冷却时间(广告)
function CycleInstanceModel:GetSlotADFreeCoinCDTime()
    local isFirst = false
    if not self.saveData.m_GetSlotADFreeCoinTime then
        isFirst = true
    end
    if isFirst then
        return 0
    end
    local offsetTime = GameTimeManager:GetCurrentServerTime(true) - self.saveData.m_GetSlotADFreeCoinTime
    local cfgTime = self.config_global.cycle_instance_freeCoinTime * 60
    if offsetTime >= cfgTime then
        return 0
    else
        return cfgTime - offsetTime
    end
end

--[[
    @desc: 获取当前免费币当日领取次数(商店)
    author:{author}
    time:2024-07-03 16:50:31
    @return:
]]
function CycleInstanceModel:GetCurFreeSlotCoinTimes()
    if not self.saveData.m_CurGetFreeCoinTimes then
        self.saveData.m_CurGetFreeCoinTimes = 0
    end
    if self.saveData.m_GetSlotFreeCoinDayTime then
        local saveDay = GameTimeManager:GetTimeLengthDate(self.saveData.m_GetSlotFreeCoinDayTime).d
        local curDay = GameTimeManager:GetTimeLengthDate(GameTimeManager:GetCurrentServerTime(true)).d
        if saveDay ~= curDay then
            self.saveData.m_CurGetFreeCoinTimes = 0
            self.saveData.m_GetSlotFreeCoinDayTime = GameTimeManager:GetCurrentServerTime(true)
        end
    end
    return self.saveData.m_CurGetFreeCoinTimes
end

---获取当前免费币当日领取次数(广告)
function CycleInstanceModel:GetCurADFreeSlotCoinTimes()
    if not self.saveData.m_CurGetADFreeCoinTimes then
        self.saveData.m_CurGetADFreeCoinTimes = 0
    end
    if self.saveData.m_GetSlotADFreeCoinDayTime then
        local saveDay = GameTimeManager:GetTimeLengthDate(self.saveData.m_GetSlotADFreeCoinDayTime).d
        local curDay = GameTimeManager:GetTimeLengthDate(GameTimeManager:GetCurrentServerTime(true)).d
        if saveDay ~= curDay then
            self.saveData.m_CurGetADFreeCoinTimes = 0
            self.saveData.m_GetSlotADFreeCoinDayTime = GameTimeManager:GetCurrentServerTime(true)
        end
    end
    return self.saveData.m_CurGetADFreeCoinTimes
end

---(商店)
function CycleInstanceModel:CanGetFreeSlotCoin()
    return self:GetCurFreeSlotCoinTimes() < self.config_global.cycle_instance_freeCoinFre and self:GetSlotFreeCoinCDTime() <= 0
end

---(广告)
function CycleInstanceModel:CanGetADFreeSlotCoin()
    return self:GetCurADFreeSlotCoinTimes() < self.config_global.cycle_instance_freeCoinFre and self:GetSlotADFreeCoinCDTime() <= 0
end

--[[
    @desc: 获取一次免费代币
    author:{author}
    time:2024-07-03 17:36:08
    @return:
]]
function CycleInstanceModel:GetOneTimeSlotFreeCoin(showFlyIcon)
    if self:CanGetFreeSlotCoin() then
        self:ChangeSlotCoin(self.config_global.cycle_instance_freeCoinNum)
        GameSDKs:TrackForeign("cy_get_coin", { source = "商店免费领取", num = tonumber(ConfigMgr.config_global.cycle_instance_freeCoinNum) })
        if not self.saveData.m_GetSlotFreeCoinDayTime then
            self.saveData.m_GetSlotFreeCoinDayTime = GameTimeManager:GetCurrentServerTime(true)
        end
        self.saveData.m_CurGetFreeCoinTimes  = self.saveData.m_CurGetFreeCoinTimes + 1
        self.saveData.m_GetSlotFreeCoinTime = GameTimeManager:GetCurrentServerTime(true)
        if showFlyIcon then
            FlyIconUI:SetCycleInstanceNum({{itemType = 30,str = self.config_global.cycle_instance_freeCoinNum}})
        end
        return true
    else
        return false
    end
end

---获取一次免费代币(广告)
function CycleInstanceModel:GetOneTimeSlotADFreeCoin()
    if self:CanGetADFreeSlotCoin() then
        self:ChangeSlotCoin(self.config_global.cycle_instance_freeCoinNum)
        GameSDKs:TrackForeign("cy_get_coin", { source = "拉霸机广告", num = tonumber(ConfigMgr.config_global.cycle_instance_freeCoinNum) })
        if not self.saveData.m_GetSlotADFreeCoinDayTime then
            self.saveData.m_GetSlotADFreeCoinDayTime = GameTimeManager:GetCurrentServerTime(true)
        end
        self.saveData.m_CurGetADFreeCoinTimes  = self.saveData.m_CurGetADFreeCoinTimes + 1
        self.saveData.m_GetSlotADFreeCoinTime = GameTimeManager:GetCurrentServerTime(true)
        return true
    else
        return false
    end
end

--[[
    @desc:返回拉霸机当前代币数量 
    author:{author}
    time:2024-07-03 17:27:55
    @return:
]]
function CycleInstanceModel:GetCurSlotCoin()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end
    return self.saveData.m_slot_machine.curToken
end

---返回拉霸机当前代币倍率
function CycleInstanceModel:GetCurSlotMagnification()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end
    return self.saveData.m_slot_machine.magnification or 1
end

---设置拉霸机当前代币倍率
function CycleInstanceModel:SetCurSlotMagnification(magnification)
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end
    self.saveData.m_slot_machine.magnification = magnification
end

--[[
    @desc:修改拉霸机当前代币数量，如果传入值是负数的话，就是使用代币了 
    author:{author}
    time:2024-07-03 17:28:31
    --@changeVale: 
    @return:true修改成功，false修改失败
]]
function CycleInstanceModel:ChangeSlotCoin(changeVale)
    local curCoin = self:GetCurSlotCoin()
    if changeVale < 0 and curCoin + changeVale < 0 then
        return false
    end
    if changeVale<0 then
        self:AddTaskAccumulateSlotCoin(-changeVale)
    end
    self.saveData.m_slot_machine.curToken  = self.saveData.m_slot_machine.curToken + changeVale
    return true
end
--[[
    @desc:是不是当前副本最后一天了 
    author:{author}
    time:2024-06-28 14:44:52
    @return:
]]
function CycleInstanceModel:IsLastOneDay()
    local timeRemaining = nil
    if CycleInstanceDataManager.instanceState.isActive == CycleInstanceDataManager:GetInstanceState() then
        timeRemaining = self:GetLeftInstanceTime()
        if timeRemaining <= 3600 * 24 then
            return true
        end
    else
        return false
    end
end

function CycleInstanceModel:GetLeftInstanceTime()
    if self.saveData.m_StartTime and self.saveData.m_EndTime and self.saveData.m_EndTime - self.saveData.m_StartTime > 0 and self.saveData.m_EndTime - GameTimeManager:GetCurServerOrLocalTime() > 0 then
        return self.saveData.m_EndTime - GameTimeManager:GetCurServerOrLocalTime()
    end
    return 0
end

---获取最后一天的打折数据
function CycleInstanceModel:GetLastOneDayDiscount()

    return 0
end

---相机看向目标对象
function CycleInstanceModel:LookAtSceneGO(roomID,furIndex,cameraFocus,isBack,callback)
    CycleInstanceScene:LookAtSceneGO(roomID,furIndex,cameraFocus,isBack,callback)
end

---获取当前标志性建筑是否购买
function CycleInstanceModel:GetLandMarkCanPurchas()
    --local instanceBind = CycleInstanceDataManager:GetInstanceBind()
    --local result = false
    --local landmarkID = instanceBind.landmark_id
    --local result = ShopManager:CheckBuyTimes(landmarkID)
    --return result
    --
    if self.saveData then
        if not self.saveData.m_Landmark then
            return true
        end
        return not self.saveData.m_Landmark
    end
    return true
end

function CycleInstanceModel:SetLandMarkCanPurchas()
    if self.saveData then
        self.saveData.m_Landmark = true

        --购买后要立刻隐藏地标的购买提示
        if CycleInstanceScene and CycleInstanceScene.floatUI and CycleInstanceScene.floatUI.Landmark then
            if CycleInstanceScene.floatUI.Landmark.view then
                CycleInstanceScene.floatUI.Landmark.view:Invoke("ShowInstanceSpacialGOBuyTipPop", false)
            end
        end
    end
end

---场景是否显示标志性建筑
function CycleInstanceModel:ShowSpecialGameObject(flag)
    CycleInstanceScene:ShowSpecialGameObject(flag)

end

--[[
    @desc: 地标购买成功的动画播放
    author:{author}
    time:2024-07-06 16:08:13
    @return:
]]
function CycleInstanceModel:BuySpecialGameObjectAnimationPlay()
    CycleInstanceScene:BuySpecialGameObjectAnimationPlay()
end

function CycleInstanceModel:EventInstanceBack()
    CycleInstanceScene:EventInstanceBack()
end
---结算离线奖励
function CycleInstanceModel:CalculateInstanceOfflineReward()
    if not self.saveData then
        return
    end
    if self.saveData.m_CurLastOfflineTime and self.saveData.m_CurLastOfflineTime > 0 then
        if not self.saveData.m_CurOfflineOffsetTime then
            self.saveData.m_CurOfflineOffsetTime = 0
        end
        local offsetTime = self.saveData.m_CurOfflineOffsetTime + (GameTimeManager:GetCurServerOrLocalTime() - self.saveData.m_CurLastOfflineTime)
        if offsetTime > 120 then
            if self.saveData.m_CurOfflineOffsetTime then
                self.saveData.m_CurOfflineOffsetTime = self.saveData.m_CurOfflineOffsetTime + offsetTime
            else
                self.saveData.m_CurOfflineOffsetTime = offsetTime
            end
        end
        local maxTime = self:GetMaxOfflineTime()
        if self.saveData.m_CurOfflineOffsetTime > maxTime then
            self.saveData.m_CurOfflineOffsetTime = maxTime
        end
        self.saveData.m_CurLastOfflineTime = nil
        LocalDataManager:WriteToFile()
    end
    self.m_CurOfflineRewardData = nil

    --累积不满2分钟不计算离线奖励
    if not self.saveData.m_CurOfflineOffsetTime or self.saveData.m_CurOfflineOffsetTime < 2 * 60 then
        return
    end
    --开始计算离线的奖励数据
    local rewardOfflineTime = math.floor(self.saveData.m_CurOfflineOffsetTime * 0.5)
    local productions, money, exp, point = self:CalculateOfflineRewards(rewardOfflineTime,false,true)
    if not self.m_CurOfflineRewardData then
        self.m_CurOfflineRewardData = {}
    end
    self.m_CurOfflineRewardData.productions = productions
    self.m_CurOfflineRewardData.rewardMoney = money
    self.m_CurOfflineRewardData.rewardExp = exp
    self.m_CurOfflineRewardData.rewardPoint = point
    self.m_CurDisplayOfflinesetTime = self.saveData.m_CurOfflineOffsetTime
    self.saveData.m_CurLastOfflineTime = nil
    self.saveData.m_CurOfflineOffsetTime = 0
    LocalDataManager:WriteToFile()
end

---获取当前离线奖励的数据内容，提供给离线奖励UI显示使用
function CycleInstanceModel:GetCurInstanceOfflineRewardData()
    return self.m_CurOfflineRewardData
end

---领取离线奖励
function CycleInstanceModel:GetOfflineReward()
    if self.m_CurOfflineRewardData then
        self.m_CurOfflineRewardData = nil
    end
    self.m_CurDisplayOfflinesetTime = 0
end


function CycleInstanceModel:GetCurOfflineDisplayTime()
    local time = 0
    if self.m_CurDisplayOfflinesetTime then
        return self.m_CurDisplayOfflinesetTime
    end
    if self.saveData and self.saveData.m_CurOfflineOffsetTime then
        return self.saveData.m_CurOfflineOffsetTime
    end
    return 0
end

function CycleInstanceModel:GetMaxOfflineTime()
    return 7200
end

---计算离线奖励
function CycleInstanceModel:CalculateOfflineRewards(offlineDuration, onlyEarnings, changeSaveData)
    local instanceDay = offlineDuration / (60 * self.config_global.cycle_instance_duration)
    local lastDay = offlineDuration % (60 * self.config_global.cycle_instance_duration) / (60 * self.config_global.cycle_instance_duration)
    local dayUp = math.ceil(instanceDay)
    --初始化资源统计表
    local resTable = {}
    for k,v in pairs(self.resourceConfig) do
        resTable[k] = 0
    end

    --计算一天的属性回复量
    --local hungryRevertSum = 0
    --local physicalRevertSum = 0
    --local workerCount = 0
    --for k,v in pairs(self.roomsData) do
    --    local roomData = v
    --    local roomID = roomData.roomID
    --    local roomCfg = self.roomsConfig[roomID]
    --    if roomData.state == 2 then
    --        if roomCfg.room_category == 2 then  --宿舍
    --            local curRevert = self:GetRoomPhysical(roomID)
    --            local seat = self:GetRoomSeatCount(roomID)
    --            curRevert = curRevert * seat
    --            physicalRevertSum = physicalRevertSum +curRevert
    --        elseif  roomCfg.room_category == 3 then --餐厅
    --            local curRevert = self:GetRoomHunger(roomID)
    --            local seat = self:GetRoomSeatCount(roomID)
    --            curRevert = curRevert * seat
    --            hungryRevertSum = hungryRevertSum + curRevert
    --        elseif  roomCfg.room_category == 1 then --工厂
    --            for furIndex,furV in pairs(roomData.furList) do
    --                local furLevelCfg = self:GetFurlevelConfigByRoomFurIndex(roomID,furIndex)
    --                if furLevelCfg.isPresonFurniture and furV.state == 1 then
    --                    workerCount = workerCount + 1
    --                end
    --            end
    --        end
    --    end
    --
    --end
    --hungryRevertSum = hungryRevertSum * 2   --一天两顿饭
    --local hungryRevertAve = hungryRevertSum / workerCount   --平均每人每天恢复饥饿值
    --local physicalRevertAve = physicalRevertSum / workerCount   --平均每人每天恢复体力值

    --按天计算每个建筑的产能
    local expSum, pointSum = 0,0
    for day=1,dayUp do
        for i=1,#roomSortConfig do
            local roomCfg = roomSortConfig[i]
            local roomID = roomCfg.id
            local roomData = self.roomsData[roomID]

            if roomData.state == 2 and roomCfg.room_category == 1 then
                local FurList = roomData.furList
                local roomCD = self:GetRoomCD(roomID)
                --local roomPro = 0   --这个房间的单位产量(一轮CD)
                --for furIndex,furV in pairs(FurList) do
                --    local furData = furV
                --    local furLevelCfg = self.furnitureLevelConfig[furData.id]
                --    if furData.worker and furData.state == 1 then
                --        --local efficiency = 1
                --        --local hungry = furData.worker.attrs.hungry
                --        --local physical = furData.worker.attrs.physical
                --        ---- local furProduct = furLevelCfg.Product 
                --        ----计算属性导致生产数量的变化
                --        --local deltaHungry = hungryRevertAve -
                --        --        furLevelCfg.weaken * InstanceDataManager.config_global.cycle_instance_duration * self:GetWorkTimeRatio()
                --        --local deltaPhysical = physicalRevertAve -
                --        --        furLevelCfg.weaken * InstanceDataManager.config_global.cycle_instance_duration * self:GetWorkTimeRatio()
                --        --hungry = hungry + day * deltaHungry
                --        --physical = physical + day * deltaPhysical
                --        local curFurPor = self:GetFurLevelCfgAttrSum(furLevelCfg.id,"product")
                --        --
                --        --local debuff = 0
                --        --if hungry < 20 then
                --        --    debuff = debuff + stateDebuff
                --        --end
                --        --if physical < 20 then
                --        --    debuff = debuff + stateDebuff
                --        --end
                --        if not self:GetLandMarkCanPurchas() then -- 买了石像 *1.5(根据配置)
                --            local instanceBind = CycleInstanceDataManager:GetInstanceBind()
                --            local landmarkID = instanceBind.landmark_id
                --            local shopCfg = ConfigMgr.config_shop[landmarkID]
                --            local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
                --            curFurPor = math.floor(curFurPor * (1 + resAdd/100))
                --
                --        end
                --        --curFurPor = curFurPor * (1-debuff)
                --        roomPro = roomPro + curFurPor
                --    end
                --end
                --计算这个房间一天(游戏时间)的单位产量
                local resCount, exp, point = self:GetRoomProduction(roomID)
                
                --计算这个房间一天(游戏时间)的单位产量
                local times = self.config_global.cycle_instance_duration * 60 / roomCD
                resCount = resCount * times
                exp = exp * times
                point = point * times
                local curDayProduction = resCount
                if day == dayUp then
                    resCount = resCount * lastDay
                    exp = exp * lastDay
                    point = point * lastDay
                    curDayProduction = resCount
                end
                resTable[roomCfg.production] = resTable[roomCfg.production] + curDayProduction

                expSum = expSum + exp
                pointSum = pointSum + point
            end
        end
    end

    --print("计算消耗前==================================",debug.traceback())
    --for k,v in pairs(resTable) do
    --    print(k,resTable[k])
    --end
    
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

            if materialID ~= 0 and not calResType[materialID] then --需要原料
                calResType[materialID] = true
                local haveCount = resTable[materialID]
                local needCount = resTable[productID] * roomCfg.material[2]
                if haveCount > needCount then
                    resTable[materialID] = resTable[materialID] - needCount
                    resTable[productID] = output
                else
                    resTable[materialID] = 0
                    resTable[productID] = math.floor(haveCount / roomCfg.material[2])
                end
            else
                resTable[productID] = output
            end
        end
    end
    calResType = nil

    if onlyEarnings then
        return resTable
    end

    --print("计算生产消耗后==================================")
    --for k,v in pairs(resTable) do
    --    print(k,resTable[k])
    --end

    local productions = changeSaveData and self.productions or Tools:CopyTable(self.productions)

    --计算港口卖出
    local money = 0
    for k,v in pairs(self.roomsData) do
        local roomID = v.roomID
        local saleCount = 0
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 4 and v.state == 2 then
            local furList = v.furList
            for furIndex,furData in pairs(furList) do
                local furLevelCfg = self.furnitureLevelConfig[furData.id]
                if furData.state == 1 and furLevelCfg.shipCD > 0 then  --找船
                    local portFurData = furList[tostring(furData.index - 12)]
                    if portFurData.isOpen then
                        local partID = portFurData.id
                        local portLevelCfg = self.furnitureLevelConfig[partID]
                        --local saleCount = portLevelCfg.storage * offlineDuration / (furLevelCfg.shipCD + self.config_global.cycle_instance_ship_loadtime)
                        local curResID = portLevelCfg.resource_type
                        saleCount = (productions[curResID] or 0) + (resTable[curResID] or 0) 
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
    local expBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
    local buffNum = self:GetSkillBufferValueBySkillID(expBuffID)
    money = money * buffNum

    --计算员工离线属性影响
    --if changeSaveData then
    --
    --    for k,v in pairs(self.roomsData) do
    --        if v.state == 2 and v.furList then
    --            for furIndex,furData in pairs(v.furList) do
    --                local furLevelCfg = self.furnitureLevelConfig[furData.id]
    --                if furData.state == 1 and furData.worker then
    --                    local furLevelCfg = self:GetFurLevelConfigByLevelID(furData.id)
    --                    local attr = furData.worker.attrs
    --                    -- attr.hungry = attr.hungry + hungryRevertAve * (dayUp-1 + lastDay)
    --                    -- attr.physical = attr.physical + physicalRevertAve * (dayUp-1 + lastDay)
    --                    attr.hungry = attr.hungry + (hungryRevertAve -
    --                            furLevelCfg.weaken * InstanceDataManager.config_global.cycle_instance_duration * self:GetWorkTimeRatio()) * (dayUp - 1 + lastDay)
    --                    attr.physical = attr.physical + (physicalRevertAve -
    --                            furLevelCfg.weaken * InstanceDataManager.config_global.cycle_instance_duration * self:GetWorkTimeRatio()) * (dayUp - 1 + lastDay)
    --                    InstanceDataManager:SetRoomFurnitureData(v.roomID,furData.index,furData.id,{Attrs = attr})
    --                end
    --            end
    --        end
    --    end
    --
    --end

    --print("计算卖出消耗后==================================")
    --for k,v in pairs(resTable) do
    --    productions[tostring(k)] = (productions[tostring(k)] or 0) + resTable[k]
    --    print(k,resTable[k])
    --end

    if changeSaveData then
        self:SetProdutionsData(productions)
        self:AddCurInstanceCoin(money)
        self:ChangeCurHeroExpRes(expSum)
        self:AddScore(pointSum)
        CycleIslandMainViewUI:Refresh()
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
        --resReward[k] = {
        --    count = 435300000000,
        --    resCfg = self.resourceConfig[k]
        --}
    end

    return resReward, money, expSum, pointSum

end


--[[
    @desc: 返回当前指定时间产出的内容
    author:{author}
    time:2023-05-04 16:55:42
    --@timeSeconds: 指定的时间
    @return:产出的内容
]]
function CycleInstanceModel:GetCurProductionsByTime(timeSeconds)
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



--endregion


--region 英雄
--[[
    @desc: 获取当前英雄升级所需资源
    author:{author}
    time:2024-07-03 20:29:37
    @return:
]]
function CycleInstanceModel:GetCurHeroExpRes()
    if not self.saveData.m_Experience then
        self.saveData.m_Experience = "0"
    end
    return self.saveData.m_Experience
end

function CycleInstanceModel:GetCurHeroExpResShow()
    if self.saveData then
        return self.saveData.m_Experience_Show
    end
    return 0
end

--[[
    @desc: 修改英雄升级资源
    author:{author}
    time:2024-07-03 20:32:39
    --@changeValue: 
    @return:
]]
function CycleInstanceModel:ChangeCurHeroExpRes(changeValue)
    local curExpStr = self:GetCurHeroExpRes()
    if BigNumber:CompareBig("0",changeValue) and BigNumber:CompareBig("-"..curExpStr,changeValue) then
        return false
    end
    self.saveData.m_Experience  = BigNumber:Add(self.saveData.m_Experience,changeValue)
    self.saveData.m_Experience_Show = BigNumber:FormatBigNumber(self.saveData.m_Experience)
    self:AddTaskAccumulateHeroExp(changeValue)
    return true
end

---获取经验产出效率(/min)
function CycleInstanceModel:GetExpOutputPerMin()
    local result = 0
    for k, v in pairs(self.roomsConfig) do
        if v.room_category == 1 then
            local roomData = self:GetRoomDataByID(k)
            if roomData and roomData.state == 2 then
                local roomCD = self:GetRoomCD(k)
                local _, exp = self:GetRoomProduction(k)
                result = result + (60 / roomCD) * exp
            end

        end
    end
    return result
end

---获取积分产出效率(/min)
function CycleInstanceModel:GetPointsOutputPerMin()
    local result = 0
    for k, v in pairs(self.roomsConfig) do
        if v.room_category == 1 then
            local roomData = self:GetRoomDataByID(k)
            if roomData and roomData.state == 2 then
                local roomCD = self:GetRoomCD(k)
                local _, _,points = self:GetRoomProduction(k)
                result = result + (60 / roomCD) * points
            end

        end
    end
    return result
end

--endregion


--region 任务


--endregion


--region 拉霸机


--endregion


--region 技能
CycleInstanceModel.SkillTypeEnum = {
    ReduceUpgradeCosts = 1,
    AddBooks = 2,
    AddSellingPrice = 3
}

--[[
    @desc:获取当前技能ID列表 
    author:{author}
    time:2024-06-28 09:56:33
    @return:
]]
function CycleInstanceModel:GetCurSkillData()
    if not self.saveData.m_Skill then
        self.saveData.m_Skill = {}
        self.saveData.m_Skill[1] = self.config_cy_instance_skill[1][0].id
        self.saveData.m_Skill[2] = self.config_cy_instance_skill[2][0].id
        self.saveData.m_Skill[3] = self.config_cy_instance_skill[3][0].id
    end

    return self.saveData.m_Skill
end

--[[
    @desc:获取当前的技能点数 
    author:{author}
    time:2024-06-28 10:21:42
    @return:
]]
function CycleInstanceModel:GetCurSkillPoints(skillType)
    if not self.saveData.m_curSkillPoints then
        self.saveData.m_curSkillPoints = {}
    end
    if not self.saveData.m_curSkillPoints[skillType] then
        self.saveData.m_curSkillPoints[skillType] = 0
    end
    return self.saveData.m_curSkillPoints[skillType]
end

--[[
    @desc:升级技能 
    author:{author}
    time:2024-06-28 10:22:00
    --@oldSkillID:
	--@nextSkillID: 
    @return:
]]
function CycleInstanceModel:UpdateSkill(oldSkillID)
    local result = false
    local oldSkillCfg = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(oldSkillID)
    local nextSkillCfg = GameTableDefine.CycleInstanceSkillUI:GetNextSkillItemCfg(oldSkillID)
    if not oldSkillCfg or not nextSkillCfg then
        return result
    end
    if not self.saveData.m_curSkillPoints or not self.saveData.m_curSkillPoints[oldSkillCfg.skill_type] or not self.saveData.m_Skill then
        return result
    end
    local isHaveSkillID = false
    for _, id in pairs(self.saveData.m_Skill) do
        if id == oldSkillID then
            isHaveSkillID = true
            break
        end
    end
    if not isHaveSkillID then
        return result
    end
    if nextSkillCfg.res > self.saveData.m_curSkillPoints[oldSkillCfg.skill_type] then
        return result
    end
    self.saveData.m_curSkillPoints[oldSkillCfg.skill_type] = self.saveData.m_curSkillPoints[oldSkillCfg.skill_type] - nextSkillCfg.res
    self.saveData.m_Skill[nextSkillCfg.skill_type] = nextSkillCfg.id
    GameSDKs:TrackForeign("cy_skill_upgrade", { id = tonumber(nextSkillCfg.skill_type), level = tonumber(nextSkillCfg.skill_level) })
    result = true
    return result
end

function CycleInstanceModel:CheckSkillCanUpdate()
    if not self.saveData.m_Skill or not self.saveData.m_curSkillPoints then
        return false
    end

    local checkResult = false
    for k, v in pairs(self.saveData.m_Skill) do
        -- local oldSkillCfg = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(v)
        local nextSkillCfg = GameTableDefine.CycleInstanceSkillUI:GetNextSkillItemCfg(v)
        if nextSkillCfg then
            if self.saveData.m_curSkillPoints[k] >= nextSkillCfg.res then
                return true
            end
        end
    end
    return false
end

function CycleInstanceModel:GetSkillBufferValueBySkillID(skillid)
    local skillCfg = GameTableDefine.CycleInstanceSkillUI:GetCurSkillItemCfg(skillid)
    if not skillCfg then
        return nil
    end
    return skillCfg.buff
end

---获取技能点数
function CycleInstanceModel:GetSkillIDByType(type)
    if self.saveData.m_Skill then
        return self.saveData.m_Skill[type] or 0
    end
    return 0
end

---增加技能点数
function CycleInstanceModel:AddSkillPoints(addValue)
    local tmpAddValue = {}
    local keyTable = {}
    local maxTypeList = {}
    for k, v in pairs(self.saveData.m_curSkillPoints) do
        tmpAddValue[k] = 0
        local skillID = self:GetSkillIDByType(k)
        local skillNextCfg = GameTableDefine.CycleInstanceSkillUI:GetNextSkillItemCfg(skillID)
        if not skillNextCfg then
            table.insert(maxTypeList, k)
        else
            table.insert(keyTable, k)
        end
    end
    
    if Tools:GetTableSize(keyTable) == 1 then
        tmpAddValue[keyTable[1]]  = tmpAddValue[keyTable[1]] + addValue
    else
        for i = 1, addValue do
            if Tools:GetTableSize(maxTypeList) == 0 or Tools:GetTableSize(keyTable) == 0 then
                local randValue = math.random()
                local keyIndex = 0
                local firstValue = 1 / 3
                local secValue = 2 / 3
                if randValue >= 0 and randValue < firstValue then
                    keyIndex = 1
                elseif randValue >= firstValue and randValue < secValue then
                    keyIndex = 2
                else
                    keyIndex = 3
                end
                if Tools:GetTableSize(maxTypeList) == 0 then
                    tmpAddValue[keyTable[keyIndex]]  = tmpAddValue[keyTable[keyIndex]] + 1
                else
                    tmpAddValue[maxTypeList[keyIndex]]  = tmpAddValue[maxTypeList[keyIndex]] + 1
                end
            elseif Tools:GetTableSize(keyTable) == 2 then
                local randValue = math.random()
                local keyIndex = 0
                local firstValue = 1 / 3
                local secValue = 2 / 3
                if randValue >= 0 and randValue < 0.5 then
                    keyIndex = 1
                elseif randValue >= 0.5 then
                    keyIndex = 2
                end
                tmpAddValue[keyTable[keyIndex]]  = tmpAddValue[keyTable[keyIndex]] + 1
            end
        end
    end
    --TODO：这里要根据类型飞不同的Icon效果
    for k, v in pairs(self.saveData.m_curSkillPoints) do
        self.saveData.m_curSkillPoints[k] = self.saveData.m_curSkillPoints[k] + tmpAddValue[k]
    end
    return tmpAddValue
end

function CycleInstanceModel:GetBuySkillTimes(shopID)
    if not self.saveData.m_BuySkillTimes then
        self.saveData.m_BuySkillTimes = {}
    end
    if not self.saveData.m_BuySkillTimes[tostring(shopID)] then
        self.saveData.m_BuySkillTimes[tostring(shopID)] = 0
    end
    return self.saveData.m_BuySkillTimes[tostring(shopID)]
end

function CycleInstanceModel:AddBuySkillTimes(shopID)
    local times = self:GetBuySkillTimes(shopID)
    self.saveData.m_BuySkillTimes[tostring(shopID)]  = self.saveData.m_BuySkillTimes[tostring(shopID)] + 1
end
--endregion


--region 跑起来需要的老接口代码

---是否购买某设施 当前等级是多少
---@return number
function CycleInstanceModel:IsBuyFurnitureLevelAndCount(furnitureID, roomID)
    if not GameStateManager:IsCycleInstanceState() then
        return 0
    end
    local curLevel = 0
    local baseFurName = self:GetFurConfigByID(furnitureID).name
    local roomData = self:GetCurRoomData(roomID)
    if roomData.furList and next(roomData.furList) ~= nil then
        for i,m in pairs(roomData.furList) do
            local furLevelConfig = self:GetFurLevelConfigByLevelID(m.id)
            local furName = self:GetFurConfigByID(furLevelConfig.furniture_id).name
            --判断是否是同名设施
            if furName == baseFurName and m.state == 1 then
                curLevel = furLevelConfig.level
            end
        end
    end
    return curLevel
end

function CycleInstanceModel:GetRoomDataByID(roomID)
    return self.roomsData[roomID]
end

function CycleInstanceModel:CanDisplayEnterUI()
    if GameTableDefine.StarMode:GetStar() < 4 then
        return false
    end
    if not self.saveData then
        return false
    end
    if CycleInstanceDataManager:GetInstanceIsActive() or CycleInstanceDataManager:GetInstanceRewardIsActive() then
        if not GameTableDefine.FloorMode:IsInOffice() or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.CITY_MAP) or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.EUROPE_MAP_UI) then
            return false
        end
        if GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.FRAGMENT_ACTIVITY_UI) or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI) or GameTableDefine.GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.LIMIT_PACK_UI) then
            return false
        end
        local now = GameTimeManager:GetCurrentServerTime()
        if not self.saveData.m_CurEnterTime or self.saveData.m_CurEnterTime == 0 then
            self.saveData.m_CurEnterTime = now
            LocalDataManager:WriteToFile()
            return true
        end

        local today = os.date("%d", now)
        local last = os.date("%d", self.saveData.m_CurEnterTime)

        if today ~= last then
            self.saveData.m_CurEnterTime = now
            return true
        end
    end
    return false
end


--[[
    @desc: 获取某个员工的状态
    author:{author}
    time:2023-05-05 10:57:57
    @return:
    ]]
function CycleInstanceModel:GetWorkerAttr(roomID,furIndex)
    return self.roomsData[roomID].furList[tostring(furIndex)] and self.roomsData[roomID].furList[tostring(furIndex)].worker and self.roomsData[roomID].furList[tostring(furIndex)].worker.attrs or {}
end

--[[
    @desc: 获取房间GameObject
    author:{author}
    time:2023-08-23 10:01:05
    @return:
]]
function CycleInstanceModel:GetRoomGameObjectByID(roomID)
    return CycleInstanceScene:GetRoomGameObjectByID(roomID)
end


---获得还没开启的奖励
function CycleInstanceModel:GetRewardNotOpened()
    local rewards = {}
    --local level = CycleInstanceModel:GetCurInstanceKSLevel()
    --for k,v in pairs(CycleInstanceDataManager.config_achievement_instance) do
    --    if v.level <= level and not CycleInstanceDataManager:IsRewardClaimed(v.level) then
    --        local rewardType = v.reward_id
    --        if not rewards[rewardType] then
    --            rewards[rewardType] = v.reward_num
    --        else
    --            rewards[rewardType] = rewards[rewardType] + v.reward_num
    --        end
    --    end
    --end
    return rewards
end

--endregion


--region 睡觉和吃饭的座位

---获取一个房间所有已解锁的座位数(餐厅座位/宿舍床位)
function CycleInstanceModel:GetRoomSeatCount(roomID)
    local count = 0
    local roomData = self.roomsData[roomID]
    for k,v in pairs(roomData.furList) do
        if v.state == 1 then
            local seat =  6
            count = count + seat
        end
    end
    return count
end

---获取房间家具提供的座位数量(餐厅座位/宿舍床位)
function CycleInstanceModel:GetRoomFurnitureSeatCount(furID)
    return 6
end

---获取一个房间的饥饿值回复量
function CycleInstanceModel:GetRoomHunger(roomID)
    return 1000
    --local count = 0
    --local roomData = self.roomsData[roomID]
    --for k,v in pairs(roomData.furList) do
    --    if v.state == 1 then
    --        local production = self:GetFurLevelCfgAttrSum(v.id,"hungry")
    --        count = count + production
    --    end
    --end
    --return count
end

---获取一个房间的体力值回复量
function CycleInstanceModel:GetRoomPhysical(roomID)
    return 1000
    --local count = 0
    --local roomData = self.roomsData[roomID]
    --for k,v in pairs(roomData.furList) do
    --    if v.state == 1 then
    --        local production = self:GetFurLevelCfgAttrSum(v.id,"phisical")
    --        count = count + production
    --    end
    --end
    --return count
end

--[[
    @desc: 玩家属性恢复
    author:{author}
    time:2023-04-20 17:50:00
    --@timeType:
    @return:
]]
function CycleInstanceModel:WorkerAttrRevert(timeType,isShow)
    if timeType == CycleInstanceModel.TimeTypeEnum.work then
        return
    end
    if not CycleInstanceScene then
        return
    end
    self.actorSeatBind[timeType] = {}

    local workerList = {}
    for k,v in pairs(self.roomsData) do
        local roomCfg = self.roomsConfig[v.roomID]
        if roomCfg.room_category ==1 and v.state ==2 then
            --for furK,furV in pairs(v.furList) do
            --    if furV.state == 1 and furV.worker then
            --        table.insert(workerList,{
            --            roomID =  v.roomID,
            --            furData = furV
            --        })
            --    end
            --end
            local room = CycleInstanceScene.Rooms[v.roomID]
            for workerIndex,worker in pairs(room.workers[1] or {}) do
                table.insert(workerList,{
                    roomID =  v.roomID,
                    worker = worker,
                    workerIndex = workerIndex
                })
            end
        end
    end

    if timeType == CycleInstanceModel.TimeTypeEnum.sleep then
        --获取恢复数
        local seatCount = 0
        --按照体力值从低到高排序
        --table.sort(workerList,function (a,b)
        --    return a.furData.worker.attrs["physical"] < b.furData.worker.attrs["physical"]
        --end)
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
                    if isShow then
                        CycleInstanceScene:TagPeopleCanDo(worker.roomID, worker.workerIndex, rooms[roomIndex].roomID)
                        if not self.actorSeatBind[timeType] then
                            self.actorSeatBind[timeType] = {}
                        end
                        if not self.actorSeatBind[timeType][worker.roomID] then
                            self.actorSeatBind[timeType][worker.roomID] = {}
                        end
                        self.actorSeatBind[timeType][worker.roomID][worker.workerIndex] = rooms[roomIndex].roomID

                    end

                    table.remove(workerList,1)
                end

            end
        end

    elseif timeType == CycleInstanceModel.TimeTypeEnum.eat then
        --获取恢复数
        local seatCount = 0
        for k,v in pairs(self.roomsData) do
            local roomCfg = self.roomsConfig[v.roomID]
            if roomCfg.room_category == 3 and v.state == 2 then
                local roomSeatCount = self:GetRoomSeatCount(v.roomID)
                seatCount = seatCount + roomSeatCount
            end
        end
        --按照饥饿值从低到高排序
        --table.sort(workerList ,function (a,b)
        --    return a.furData.worker.attrs["hungry"] < b.furData.worker.attrs["hungry"]
        --end)

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
                if isShow then
                    CycleInstanceScene:TagPeopleCanDo(worker.roomID, worker.workerIndex, roomId)
                    if not self.actorSeatBind[timeType] then
                        self.actorSeatBind[timeType] = {}
                    end
                    if not self.actorSeatBind[timeType][worker.roomID] then
                        self.actorSeatBind[timeType][worker.roomID] = {}
                    end
                    self.actorSeatBind[timeType][worker.roomID][worker.workerIndex] = roomId
                end

                table.remove(workerList,1)
            end
        end
    end
end

---为worker安排一个空的进餐座位
function CycleInstanceModel:FindEatSeat(worker)
    local timeType = CycleInstanceModel.TimeTypeEnum.eat
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
        CycleInstanceScene:TagPeopleCanDo(workerRoomID, workerFurIndex, roomId)
        self.actorSeatBind[timeType][workerRoomID][workerFurIndex] = roomId
        return true
    else
        return false --已经在座位上了,调用前应该先判断，正确来说不应执行到这里。
    end
end

---为worker安排一个空的睡觉座位
function CycleInstanceModel:FindSleepSeat(worker)
    local timeType = CycleInstanceModel.TimeTypeEnum.sleep
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
end

--[[
    @desc: 根据设备ID获取furLevelConfig
    author:{author}
    time:2023-04-04 16:04:40
    --@furLevelID:
    @return:
]]
function CycleInstanceModel:GetFurLevelConfigByLevelID(furLevelID)
    return self.furnitureLevelConfig[furLevelID]
end

function CycleInstanceModel:GetFurlevelConfigByRoomFurIndex(roomID,index)
    local furLevelID = self.roomsData[roomID].furList[tostring(index)].id
    return self:GetFurLevelConfigByLevelID(furLevelID)
end

--[[
    @desc: 根据房间类型获取房间信息
    author:{author}
    time:2023-08-23 10:39:18
    --@type: 1:工厂 2:卧室 3:餐厅 4:码头
    @return:
]]
function CycleInstanceModel:GetRoomDataByType(type)
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
    @desc: 获取一个家具在改等级所加的属性之和
    author:{author}
    time:2023-04-12 15:20:22
    --@levelID:
	--@attr:
    @return:
]]
function CycleInstanceModel:GetFurLevelCfgAttrSum(levelID,attr)
    local furLevelConfig = self.furnitureLevelConfig[levelID]
    if not furLevelConfig[attr] then
        return
    end
    return furLevelConfig.product
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
function CycleInstanceModel:GetFurGameObject(roomID, furIndex, subIndex)
    return self:GetSceneRoomFurnitureGo(roomID, furIndex, subIndex)
end
--endregion


--region 礼包

function CycleInstanceModel:GetGiftCfgByID(giftIDOrShopID)
    local id = tonumber(giftIDOrShopID)
    if self.giftsConfig[id] then
        return self.giftsConfig[id]
    end
    return self.giftsConfigByShopID[id]
end

---增加礼包已购买次数
function CycleInstanceModel:AddGiftPackBuyTimes(packID,times)
    if self.saveData then
        if not self.saveData.m_giftPackBuyTimes then
            self.saveData.m_giftPackBuyTimes = {}
        end
        local kPackID = tostring(packID)
        self.saveData.m_giftPackBuyTimes[kPackID] = (self.saveData.m_giftPackBuyTimes[kPackID] or 0) + times
    end
end

---礼包已购买次数
function CycleInstanceModel:GetGiftPackBuyTimes(packID)
    if self.saveData then
        if not self.saveData.m_giftPackBuyTimes then
            return 0
        end
        local kPackID = tostring(packID)
        return self.saveData.m_giftPackBuyTimes[kPackID] or 0
    end
    return 0
end

function CycleInstanceModel:InitLimitTimePack()
    if self.saveData then
        if not self.saveData.m_LimitTimePack then
            self.saveData.m_LimitTimePack = {}
        end
        for k, v in pairs(self.giftsConfig) do
            if v.type == 1 then
                self:AddLimitTimePack(k)
            end
        end
    end
end

---添加限时礼包
function CycleInstanceModel:AddLimitTimePack(giftsID)
    if self.saveData then
        local giftsCfg = self:GetGiftCfgByID(giftsID)
        self.saveData.m_LimitTimePack[tostring(giftsID)] = {
            id = giftsID,
            time = giftsCfg.type > 1 and GameTimeManager:GetCurrentServerTime(true) or nil
        }
    end
end

function CycleInstanceModel:SetLimitTimePackCD(giftsID)
    if self.saveData then
        local giftsCfg = self:GetGiftCfgByID(giftsID)
        if self.saveData.m_LimitTimePack[tostring(giftsCfg.id)] and giftsCfg.type == 1 then
            local now = GameTimeManager:GetCurrentServerTime(true)
            self.saveData.m_LimitTimePack[tostring(giftsCfg.id)].time = now
        end
    end
end

---可以添加限时礼包
function CycleInstanceModel:CanAddLimitTimePack(giftsID)
    if self.saveData then
        local giftsCfg = self:GetGiftCfgByID(giftsID)
        if not self.saveData.m_LimitTimePack or not self.saveData.m_LimitTimePack[tostring(giftsCfg.id)] then   -- 存档中没有礼包信息可以直接加
            return true
        end
        if self.saveData.m_LimitTimePack and self.saveData.m_LimitTimePack[tostring(giftsCfg.id)] then
            local now = GameTimeManager:GetCurrentServerTime(true)

            if giftsCfg.type == 1 then -- 常驻礼包未领取过时可以直接加, 领取CD结束后可以加
                if not self.saveData.m_LimitTimePack[tostring(giftsCfg.id)].time or self.saveData.m_LimitTimePack[tostring(giftsCfg.id)].time + (giftsCfg.time + giftsCfg.cd) * 60 < now then
                    return true
                end
            end
            if giftsCfg.type == 2 and self.saveData.m_LimitTimePack[tostring(giftsCfg.id)].time + (giftsCfg.time + giftsCfg.cd) * 60 > now then    -- 限时礼包时间范围内可以加
                return true
            end
        end
    end
    return false
end

function CycleInstanceModel:GetLimitTimePackData(id)
    if self.saveData and self.saveData.m_LimitTimePack then
        return self.saveData.m_LimitTimePack[tostring(id)]
    end
end

function CycleInstanceModel:GetActivePackList()
    if self.saveData and self.saveData.m_LimitTimePack then
        local result = {}
        local temp = {}
        local now = GameTimeManager:GetCurrentServerTime(true)    
        for k, v in pairs(self.saveData.m_LimitTimePack) do
            local giftsCfg = self:GetGiftCfgByID(k)
            if giftsCfg.type == 1 then
                table.insert(temp, { id = v.id })
            elseif giftsCfg.type == 2 then
                local startTime = v.time
                local endTime = v.time + giftsCfg.time * 60
                if endTime >= now then
                    table.insert(temp, { id = v.id })
                end
            end
            
        end
        table.sort(temp,function(a, b) return a.id < b.id end)
        for i = 1, #temp do
            table.insert(result, temp[i].id)
        end
        return result
    end
end


--endregion


--region 广告事件

---iaa 广告事件存档
function CycleInstanceModel:GetEventData()
    if self.saveData then
        if not self.saveData.m_Event then
            local now = GameTimeManager:GetCurrentServerTime(true)
            local curDay = GameTimeManager:GetTimeLengthDate(now).d
            self.saveData.m_Event = {}
            self.saveData.m_Event.day = curDay
            self.saveData.m_Event.count = 0
            self.saveData.m_Event.lastTime = 0
        end
        return self.saveData.m_Event
    end
    return nil
end

---iaa 新增广告事件计数
function CycleInstanceModel:AddEventTime()
    if self.saveData then
        self.saveData.m_Event = self:GetEventData()
        local now = GameTimeManager:GetCurrentServerTime(true)
        local curDay = GameTimeManager:GetTimeLengthDate(now).d
        if curDay ~= self.saveData.m_Event.day then
            self.saveData.m_Event.count = 0
        end
        self.saveData.m_Event.count = self.saveData.m_Event.count + 1
        self.saveData.m_Event.lastTime = now
        LocalDataManager:WriteToFile()
    end
end

--endregion



--region 拉霸机
function CycleInstanceModel:GetSlotMachineLevel()
    if self.saveData then
        if not self.saveData.m_slotMachineLevel then
            self.saveData.m_slotMachineLevel = 1
        end
        return self.saveData.m_slotMachineLevel
    end
end

function CycleInstanceModel:SetSlotMachineLevel(level)
    if self.saveData then
        if not self.saveData.m_slotMachineLevel or self.saveData.m_slotMachineLevel < level then
            GameSDKs:TrackForeign("cy_slot_upgrade", {level = level})
        end
        self.saveData.m_slotMachineLevel = level
    end
end

--[[
    @desc: 拉霸機使用次數
    author:{author}
    time:2024-08-15 11:20:00
    @return:
]]
function CycleInstanceModel:PushSlotNumAdd()
    if self.saveData then
        if not self.saveData.push_slot_num then
            self.saveData.push_slot_num = 1
        else
            self.saveData.push_slot_num  = self.saveData.push_slot_num + 1
        end
    end
end

function CycleInstanceModel:GetSlotPushNum()
    if self.saveData and self.saveData.push_slot_num then
        return self.saveData.push_slot_num
    end
    return 0
end

function CycleInstanceModel:PushSlotRotioNum(rotio)
    if self.saveData then
        if not self.saveData.push_slot_rotio_num then
            self.saveData.push_slot_rotio_num = rotio
        else
            self.saveData.push_slot_rotio_num  = self.saveData.push_slot_rotio_num + rotio
        end
    end
end

function CycleInstanceModel:GetSlotPushNumRotio()
    if self.saveData and self.saveData.push_slot_rotio_num then
        return self.saveData.push_slot_rotio_num
    end
    return 0
end
--[[
    @desc: 获取房间家具等级以及英雄等级
    author:{author}
    time:2024-08-15 14:52:20
    --@roomID:
	--@heroID: 
    @return:
]]
function CycleInstanceModel:GetRoomLevelAndHeroLevel(roomID, heroID)
    local furLevel = 0
    local heroLevel = 0
    if self.saveData and self.saveData.m_RoomData then
        local curRoomData = self.saveData.m_RoomData[tostring(roomID)]
        if curRoomData and curRoomData.state and curRoomData.state == 2 then
            if self.furnitureLevelConfig[curRoomData.furList["1"].id] then
                furLevel = self.furnitureLevelConfig[curRoomData.furList["1"].id].level
            end
            local herosData = self:GetHeroSaveData()
            if herosData[heroID] then
                heroLevel = herosData[heroID].level
            end
        end
    end
    return furLevel, heroLevel
end
--endregion

---override 奖励金钱 每分钟数额(拉霸机，广告等)
function CycleInstanceModel:GetRewardInComePerMinute()
    return self:GetCurHighestProfit()
end

return CycleInstanceModel