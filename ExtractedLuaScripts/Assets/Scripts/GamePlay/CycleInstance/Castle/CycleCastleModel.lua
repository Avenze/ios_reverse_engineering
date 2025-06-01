
local CycleInstanceModelBase = require("GamePlay.CycleInstance.CycleInstanceModelBase")
local Class = require("Framework.Lua.Class")
---@class CycleCastleModel:CycleInstanceModelBase
---@field super CycleInstanceModelBase
local CycleCastleModel = Class("CycleCastleModel",CycleInstanceModelBase)

local Execute = require("Framework.Queue.Execute")

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleCastleMainViewUI = GameTableDefine.CycleCastleMainViewUI
local CycleCastleBuildingUI = GameTableDefine.CycleCastleBuildingUI
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local CycleCastleHeroManager = GameTableDefine.CycleCastleHeroManager
local FlyIconUI = GameTableDefine.FlyIconsUI
local CycleCastlePopUI = GameTableDefine.CycleCastlePopUI
local CycleCastleAIBlackBoard = GameTableDefine.CycleCastleAIBlackBoard
local FloatUI = GameTableDefine.FloatUI ---@type FloatUI

local roomSortConfig = nil   ---将self.roomConfig按照所需材料等级从低到高排序结果
local isOpenExitPop = false
local CoinFieldName = "m_CurInstanceCoin" ---存档中副本钞票存款名
local ScoreFieldName = "m_CurScore" ---存档中副本积分名
local clientQueue = nil  ---客户队列
local clientComeTimer = 0   ---客户到来的计时器


local SCENE_CLASS_PATH = "GamePlay.CycleInstance.Castle.CycleCastleScene"
local OFFLINE_TIME = 120

function CycleCastleModel:ctor()
    self:getSuper(CycleCastleModel).ctor(self)

    self.m_sceneClassPath = SCENE_CLASS_PATH

    self.instance_id = nil   ---副本ID(类型ID, 不是实例ID)
    self.m_currentScene = nil ---@type CycleCastleScene
    
    self.workCD = {} ---用于计算建筑工作循环
    self.checkMatInterval = 5
    self.checkMatTimer = 0

    self.portExport = {}

    self.clientComeTimer = 0
    self.clientTableTimer = {}

    
end

--region 生命周期

function CycleCastleModel:Init(saveData)
    self:getSuper(CycleCastleModel).Init(self,saveData)

    GameTableDefine.CycleCastleHeroManager:Reset()
    GameTableDefine.CycleCastleTaskManager:Reset()

    -- 第一次初始化model,初始化副本数据
    if not self.saveData.m_CurInstanceCoin then
        self:AddCurInstanceCoin(self.config_global.cycle_instance_cash[1])--and 99999999999999999999) 
        self:ChangeCurHeroExpRes(self.config_global.cycle_instance_cash[2])
        self:ChangeSlotCoin(self.config_global.cycle_instance_cash[3])
        GameSDKs:TrackForeign("cy_get_coin", { source = "副本初始化", num = tonumber(self.config_global.cycle_instance_cash[3]) })

        self:InitLimitTimePack()
    end

    --初始化技能存档
    self:GetCurSkillData()
    self:GetCurSkillPoints(1)
    self:GetCurSkillPoints(2)
    self:GetCurSkillPoints(3)
end

function CycleCastleModel:InitConfigData()
    self:getSuper(CycleCastleModel).InitConfigData(self)

    self.config_cy_instance_skill = ConfigMgr.config_cy_instance_skill[self.instance_id]
end

function CycleCastleModel:OnEnter()

    self:getSuper(CycleCastleModel).OnEnter(self)
    clientQueue = {}
    isOpenExitPop = false
    --将房间按照产出需要的原料序号从低到高排序,顺序计算每种产品的总量
    roomSortConfig = {}
    for k,v in pairs(self.roomsConfig) do
        table.insert(roomSortConfig,v)
    end
    table.sort(roomSortConfig,function (a,b)
        return a.material[1] < b.material[1]
    end)

    -- 初始化码头数据(弃用)
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
    --if next(self.productions) == nil then
        for k,v in pairs(self.resourceConfig) do
            local kID = tostring(k)
            if not self.productions[kID] then
                self.productions[kID] = 0
            end
        end
    --end

    self:CalculateInstanceOfflineReward()
end

function CycleCastleModel:Update(dt)

    self:getSuper(CycleCastleModel).Update(self,dt)

    if CycleInstanceDataManager:GetInstanceIsActive() then

        --TODO 礼包
        --if GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI,true) then
        --    GameTableDefine.InstancePopUI:CheckGiftPopShow()
        --end
    else
        --local instanceMainViewIndex = GameUIManager:GetUIIndex(ENUM_GAME_UITYPE.CYCLE_CASTLE_MAIN_VIEW_UI, true)
        if not isOpenExitPop and not self.m_currentScene:IsPlayingTimeLine() and GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_CASTLE_MAIN_VIEW_UI,true) then
            local txt = GameTextLoader:ReadText("TXT_INSTANCE_TIP_END")
            isOpenExitPop = true
            GameTableDefine.ChooseUI:CommonChoose(txt, function()
                CycleCastleMainViewUI:Exit()
            end, false, function()
                isOpenExitPop = false
            end)
            -- 如果正在开启引导则强制退出引导
            GameTableDefine.GuideManager:EndStep()
            GameTableDefine.GuideUI:CloseView()
        end
    end
end

---游戏暂停，调用离线保存时间，退出副本和在副本中切换app到后台
function CycleCastleModel:OnPause()
    GameTableDefine.CycleCastleOfflineRewardUI:CloseView()
    self.m_CurOfflineRewardData = nil
    if self.saveData and CycleInstanceDataManager:GetInstanceIsActive(self.instance_id) then
        self.saveData.m_CurLastOfflineTime = GameTimeManager:GetCurServerOrLocalTime()
        LocalDataManager:WriteToFileInmmediately()
    end
    GameSDKs:TrackForeign("cy_instance_quit", { type = "退出游戏（切换后台)" })
end

---游戏恢复，调用离线的计算，主要用于在副本中切到app后台
function CycleCastleModel:OnResume()
    self:CalculateInstanceOfflineReward()
    GameTableDefine.CycleCastleOfflineRewardUI:GetView()
end


--endregion


--region 公共接口

function CycleCastleModel:GetIsFirstEnter()
    if self.saveData then
        return self.saveData.m_FirstEnter == nil
    end
    return true
end

function CycleCastleModel:SetIsFirstEnter()
    if self.saveData then
        self.saveData.m_FirstEnter = false
    end
end

---获取引导ID
function CycleCastleModel:GetGuideID()
    if self.saveData then
        return self.saveData.m_Guide
    end
    return nil
end

function CycleCastleModel:SetGuideID(value)
    if self.saveData then
        self.saveData.m_Guide = value
        LocalDataManager:WriteToFile()
    end
end

---override 计算在线收益
function CycleCastleModel:CalculateInstanceOnlineReward(dt)
    self:CalculateFactoryUnitOutput(dt)
    self:CalculatePortExport(dt)
end

---计算工厂单位时间的产量
function CycleCastleModel:CalculateFactoryUnitOutput(dt)

    --遍历所有生产类型的房间数据,如果房间已解锁则计算产量和消耗
    for k,v in pairs(roomSortConfig) do
        if v.room_category == 1 then
            local roomID = v.id
            local curRoomData = self.roomsData[roomID]
            if curRoomData.state == 2 then
                local cd = self:GetRoomCD(roomID)
                self.workCD[roomID] = self.workCD[roomID] + dt

                --计算一轮收益
                if self.workCD[roomID] >= cd then
                    self.workCD[roomID] = 0
                    local materialID = v.material[1]
                    local productID = v.production
                    local kIDMaterial = tostring(materialID)
                    local kIDProduct = tostring(productID)
                    local haveCount = self.productions[kIDMaterial]
                    local needCount = self:GetRoomMatCost(roomID)
                    local output, exp, points = self:GetRoomProduction(roomID)
                    self:AddScore(points)
                    self:ChangeCurHeroExpRes(exp)

                    --if materialID == 4 then
                    --    printf(self.productions[kIDMaterial])
                    --end
                    if materialID ~= 0 then --需要原料
                        if not self.productions[kIDMaterial] then
                            self.productions[kIDMaterial] = 0
                        end

                        if haveCount >= needCount then
                            self.productions[kIDMaterial] = self.productions[kIDMaterial] - needCount
                            self.productions[kIDProduct] = self.productions[kIDProduct] + output
                            --更新传送点状态
                            if self.m_currentScene then
                                self.m_currentScene:SetRoomEnoughMaterial(roomID,true)
                            end
                        else
                            self.productions[kIDMaterial] = 0
                            self.productions[kIDProduct] = self.productions[kIDProduct] + math.floor(haveCount / v.material[2] )
                            --更新传送点状态
                            if self.m_currentScene then
                                self.m_currentScene:SetRoomEnoughMaterial(roomID,false)
                            end
                        end

                    else
                        self.productions[kIDProduct] = self.productions[kIDProduct] + output
                        --更新传送点状态
                        if self.m_currentScene then
                            self.m_currentScene:SetRoomEnoughMaterial(roomID,true)
                        end
                    end

                    --print(productID,output,self.productions[kIDProduct])
                    self:SetRoomData(roomID, nil,nil,GameTimeManager:GetCurrentServerTime(true))
                end
            end
        end
    end
    self:SetProdutionsData(self.productions)
end


---计算码头输出量
function CycleCastleModel:CalculatePortExport(dt)
    -- if true then
    --     return
    -- end

    local comeCD = self.config_global.cycle_instance_ship_cooltime --- 来人CD
    local loadingCD = self.config_global.cycle_instance_ship_loadtime --- 吃饭时长
    local tableCount = 8

    if #clientQueue < tableCount then
        if clientComeTimer <= comeCD then
            if clientComeTimer == 0 then
                --新顾客到来
                clientQueue[#clientQueue + 1] = 0
                local roomID = self:GetSellingRoomID()
                local roomLevel = self:GetRoomLevel(roomID)
                self.m_currentScene:CreateClients(roomID, roomLevel,#clientQueue)
                printf("新顾客到来:  " .. #clientQueue)
            end
            clientComeTimer = clientComeTimer + dt
        else
            clientComeTimer = 0
        end
    end

    
    for i = 1, #clientQueue do
        if clientQueue[i] <= loadingCD then
            clientQueue[i] = clientQueue[i] + dt
        else
            clientQueue[i] = 0

            local roomID = self:GetSellingRoomID()
            local roomLevel = self:GetRoomLevel(roomID)
            printf("顾客离开:  " .. i)
            CycleCastleAIBlackBoard:LeaveSeat(i)
            printf("新顾客到来:  " .. i)
            self.m_currentScene:CreateClients(roomID, roomLevel, i)
            --得钱
            local resType = self:GetCurSellingProduct()
            local haveCount = self.productions[tostring(resType)]
            local sellCount = haveCount
            local income = sellCount * self.resourceConfig[resType].price
            local sellBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
            local buffNum = self:GetSkillBufferValueBySkillID(sellBuffID)
            income = income * buffNum
            self:AddCurInstanceCoin(income)
            CycleCastleMainViewUI:Refresh()
            --显示通知
            --local resCfg = self.resourceConfig[resType]
            --CycleCastleMainViewUI:CallNotify(2, income, resCfg)
            --显示气泡
            if income > 0 then
                self.m_currentScene:ShowGetMoneyBubble(i, income)
            end
            --清库存
            self.productions[tostring(resType)] = 0
        end
    end

--region ignore
    --local roomData = nil
    --local roomID = 0
    --for k,v in pairs(self.roomsConfig) do
    --    if v.room_category == 4 then
    --        roomID = v.id
    --        roomData = self.roomsData[v.id]
    --        break
    --    end
    --end
    --local current = GameTimeManager:GetCurrentServerTime(true)
    ----遍历港口设备,找船,因为有船一定有码头
    --for k,v in pairs(roomData.furList) do
    --    local curFurData = v
    --    local curFurLevelCfg = self.furnitureLevelConfig[curFurData.id]
    --
    --    if curFurData.state == 1 and curFurLevelCfg.shipCD > 0 then --直接找船
    --        --如果有可出售货物,就拉货开走,如果库存不够就在码头等待
    --        local portFurData = roomData.furList[tostring(v.index - 12)]  --这里直接写死,不然重复遍历去找对应的码头太耗了
    --        local partID = portFurData.id
    --        local portLevelCfg = self.furnitureLevelConfig[partID]
    --        local haveCount = self.productions[tostring(portLevelCfg.resource_type)]
    --        local shipCD = 0
    --        if self.workCD[roomID] and self.workCD[roomID][v.index] then
    --            shipCD = self.workCD[roomID][v.index]
    --        end
    --
    --        if curFurData.lastReachTime > curFurData.lastLeaveTime then  --船是靠港状态
    --            if portFurData.isOpen then
    --                if haveCount > 0 then   --有可出售货物
    --                    if shipCD < loadingCD then  --装载中
    --                        self.workCD[roomID][v.index] = shipCD + dt
    --                        if shipCD == 0 then
    --                            --self.m_currentScene:SetShipBubbles(v.index,false,portFurData.isOpen, nil)
    --                        end
    --                    else    --装载完成离港
    --                        self.workCD[roomID][v.index] = 0
    --                        local sellCount = haveCount
    --                        local income = sellCount * self.resourceConfig[portLevelCfg.resource_type].price
    --                        self.productions[tostring(portLevelCfg.resource_type)] = self.productions[tostring(portLevelCfg.resource_type)] - sellCount
    --                        self:SetRoomFurnitureData(roomID,v.index,curFurData.id,{["lastLeaveTime"] = current})
    --                        self:SetProdutionsData(self.productions)
    --                        --得钱
    --                        local sellBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
    --                        local buffNum = self:GetSkillBufferValueBySkillID(sellBuffID)
    --                        income = income * buffNum
    --  
    --                        self:AddCurInstanceCoin(income)
    --                        --self.m_currentScene:SetShipBubbles(v.index,true,portFurData.isOpen, income)
    --                        CycleCastleMainViewUI:Refresh()
    --                        --显示通知
    --                        local resCfg = self.resourceConfig[curFurLevelCfg.resource_type]
    --                        CycleCastleMainViewUI:CallNotify(2,income,resCfg)
    --                        --self.m_currentScene:PlayShipAnim(v.index,true)
    --                        --TODO 顾客离开
    --                        printf("顾客离开")
    --                    end
    --                else
    --                    --无可出售货物,cd不增加
    --                end
    --            end
    --        else    --船是离港状态
    --            if shipCD < comeCD then    --等待船来
    --                if shipCD + dt >= comeCD-7 and shipCD < comeCD-7 then
    --                    --self.m_currentScene:PlayShipAnim(v.index,false)
    --                end
    --                if self.workCD[roomID] and self.workCD[roomID][v.index] then    --不知道为什么这里会报错,加一个判空保护
    --                    self.workCD[roomID][v.index] = shipCD + dt
    --                else
    --                    print("InstanceModel 1010:", roomID, v.index)
    --                end
    --            else    --船靠港
    --                self.workCD[roomID][v.index] = 0
    --                self:SetRoomFurnitureData(roomID,v.index,curFurData.id,{["lastReachTime"] = current})
    --                --TODO 船靠港表现(新顾客到来)
    --                printf("新顾客到来")
    --            end
    --        end
    --
    --    end
    --
    --end
--endregion    
   
end


---设置副本产品信息
function CycleCastleModel:SetProdutionsData(productions)
    if not productions or next(productions) == nil then
        return
    end
    if self.saveData then
        self.saveData.m_Productions = productions
    end
    -- LocalDataManager:WriteToFile()
end

---获取副本产品信息
function CycleCastleModel:GetProdutionsData()

    if self.saveData then
        if not self.saveData.m_Productions then
            return {}
        else
            return self.saveData.m_Productions
        end
    end
end

---override 增加当前副本金钱
function CycleCastleModel:AddCurInstanceCoin(num,showFlyIcon)

    self:getSuper(CycleCastleModel).AddCurInstanceCoin(self,num,showFlyIcon)
    self:AddTaskAccumulateCoin(num)
    
    CycleCastleMainViewUI:Refresh()
    CycleCastleBuildingUI:RefreshView()
end

---获取某种资源的单位产量和消耗 (/min)
function CycleCastleModel:GetProductionAndConsumptionPerMin(resourcesID)
    --TODO
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
function CycleCastleModel:GetInComePerMinute()
    --TODO
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
function CycleCastleModel:GetCurSellingProduct()
    --TODO
    local portRoomData = self:GetRoomDataByType(4)
    for k, v in pairs(portRoomData[1].furList) do
        if v.index <= 12 and v.isOpen then
            local furLevelCfg = self.furnitureLevelConfig[v.id]
            return furLevelCfg.resource_type
        end
    end
    return 1
end

---获取一个房间每分钟的收益
function CycleCastleModel:GetRoomIncomePerMin(roomID)
    local roomIncome = self:GetRoomProduction(roomID)
    --售价buff
    local priceBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
    local buffNum = self:GetSkillBufferValueBySkillID(priceBuffID)
    roomIncome = BigNumber:Multiply(roomIncome, buffNum)
    local roomCD = self:GetRoomCD(roomID)
    local resID = self.roomsConfig[roomID].production
    local price = self.resourceConfig[resID].price

    local result = BigNumber:Multiply(roomIncome, (60 / roomCD * price))
    return result
end

---获取当前的最高收益
function CycleCastleModel:GetCurHighestProfit()
    --TODO
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
function CycleCastleModel:GetResLockedState(resourcesID)
    --TODO
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

---获取当前售卖货架的index
function CycleCastleModel:GetSellingIndex()
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

function CycleCastleModel:GetSellingRoomID()
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
    local furLevelID = 0
    for k, v in pairs(portRoomData.furList) do
        if v.index <= 12 and v.isOpen then
            furLevelID = v.id
            break
        end
    end
    local furLevelCfg = self:GetFurLevelConfigByLevelID(furLevelID)
    local resKey = furLevelCfg.resource_type
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

---获取一个房间单位时间的产品产量
function CycleCastleModel:GetRoomProduction(roomID)
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

    local heroBuff = CycleCastleHeroManager:GetHeroCurrentBuff(self.roomsConfig[roomID].hero_id)
    count = count * heroBuff
    local workerCount = self:GetWorkerNum(roomID)
    count = count * workerCount

    local roomLevelCfg = self:GetRoomLevelConfig(roomID,self:GetRoomLevel(roomID))
    exp = roomLevelCfg.exp
    local expBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddBooks)
    local buffNum = self:GetSkillBufferValueBySkillID(expBuffID)
    exp = BigNumber:Multiply(exp, buffNum)

    if not self:GetLandMarkCanPurchas() then --买了地标
        local instanceBind = CycleInstanceDataManager:GetInstanceBind()
        local landmarkID = instanceBind.landmark_id
        local shopCfg = ConfigMgr.config_shop[landmarkID]
        local resAdd = shopCfg.param[1]
        count = count * (resAdd / 100)
        resAdd = shopCfg.param2[1]
        exp = exp * (resAdd / 100)
        resAdd = shopCfg.param3[1]
        points = points * (resAdd / 100)
    end
    
    return count, exp, points
end

---获取生产某种资源的房间
function CycleCastleModel:GetRoomByProduction(productionID)
    for k,v in pairs(self.roomsConfig) do
        if v.production == productionID then
            return k
        end
    end
end

---获取一个房间单位时间的材料消耗
function CycleCastleModel:GetRoomMatCost(roomID)
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

---获取房间员工数量
function CycleCastleModel:GetWorkerNum(roomID)
    local roomData = self:GetCurRoomData(roomID)
    local furListData = roomData.furList
    for k,v in pairs(furListData) do
        local furLevelCfg = self.furnitureLevelConfig[v.id]
        if furLevelCfg.worker then
            return furLevelCfg.worker
        end
    end
    return 0
end

---override 购买房间
function CycleCastleModel:BuyRoom(roomID)
    --设置存档信息
    local timePoint = GameTimeManager:GetCurrentServerTime(true)
    self:SetRoomData(roomID,timePoint,1)

    self.m_currentScene:RefreshRoom(roomID)
    --花钱
    local cost = tonumber(self.roomsConfig[roomID].unlock_require)
    local buffID = self:GetSkillIDByType(CycleCastleModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:AddCurInstanceCoin(-cost)
    CycleCastleMainViewUI:Refresh()

    -- 礼包弹窗触发事件
    CycleCastlePopUI:PackTrigger(CycleCastlePopUI.EventType.buyRoom, roomID)

    --埋点
    local lastRoomID = roomID - 1
    local lastRoomDate = self:GetRoomDataByID(lastRoomID)
    local lastRoomFurLevelID = lastRoomDate.furList["1"].id
    local lastRoomFurLevelCfg = self:GetFurLevelConfigByLevelID(lastRoomFurLevelID)
    local roomCfg = self:GetRoomConfigByID(roomID)
    local heroData = CycleCastleHeroManager:GetHeroData(roomCfg.hero_id)

    GameSDKs:TrackForeign("cyinstance_unlock", { id = roomID, mile_level = self:GetCurInstanceKSLevel(), fur_level = lastRoomFurLevelCfg.level, hero_level = heroData.level })

end

---override 检查房间是否满足解锁条件
function CycleCastleModel:CheckRoomCondition(roomID)
    local roomData = self:GetCurRoomData(roomID)
    local roomConfig = self:GetRoomConfigByID(roomID)
    local money = self:GetCurInstanceCoin()
    local cost = tonumber(roomConfig.unlock_require)
    local buffID = self:GetSkillIDByType(CycleCastleModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    local lastRoomData = self:GetCurRoomData(roomConfig.unlock_room)
    if roomData and next(roomData) ~= nil and cost <= money and lastRoomData and lastRoomData.state and lastRoomData.state == 2 then
        return true
    else
        return false
    end
end

---override 播放房间升级动画
function CycleCastleModel:DoRoomUpgradeAnim(roomID)
    if self:getSuper(CycleCastleModel).DoRoomUpgradeAnim(self,roomID) then
        --TODO  生成家具，镜头表现等
    end
end

---override 购买家具
function CycleCastleModel:BuyFurniture(roomID, index, furLevelID)
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
    end
    --设置存档信息
    self:SetRoomFurnitureData(roomID, index, furLevelID, furnitureData)

    --刷新场景中的物体
    self.m_currentScene:RefreshRoom(roomID, index, true)

    --花钱
    local furLevelCfg = self.furnitureLevelConfig[furLevelID]
    local cost = tonumber(furLevelCfg.cost)
    local buffID = self:GetSkillIDByType(CycleCastleModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:AddCurInstanceCoin(-cost)
    CycleCastleMainViewUI:Refresh()

    --增加升级埋点,每5级埋点一次
    if furLevelCfg.level % 10 == 0 then
        GameSDKs:TrackForeign("cy_fur_upgrade", { id = tonumber(roomID), level = tonumber(furLevelCfg.level) })
    end
    
    --显示通知
    if furLevelCfg.level == 1 and furLevelCfg.isPresonFurniture then
        CycleCastleMainViewUI:CallNotify(1)
    end
end

---返回当前指定时间产出的内容
function CycleCastleModel:GetCurProductionsByTime(timeSeconds)
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


--region 场景

---@overload
---@return CycleCastleScene
function CycleCastleModel:GetScene()
    return self.m_currentScene
end

---场景是否显示标志性建筑
function CycleCastleModel:ShowSpecialGameObject(flag)
    self.m_currentScene:ShowSpecialGameObject(flag)
end

---地标购买成功的动画播放
function CycleCastleModel:BuySpecialGameObjectAnimationPlay()
    self.m_currentScene:BuySpecialGameObjectAnimationPlay()
end

--endregion


--region 里程碑

---override 设置积分等级
function CycleCastleModel:SetCurInstanceKSLevel(value)
    if self.saveData then
        self.saveData.m_CurKSLevel = value
        CycleCastleMainViewUI:CallNotify(3)
        CycleCastleMainViewUI:Refresh()
        --埋点
        local maxRoomData = self:GetHighestLevelUnlockedBuildingData()
        local roomID = maxRoomData.roomID
        local furLevelConfig = self:GetFurlevelConfigByRoomFurIndex(roomID,1)
        local furLevel = furLevelConfig and furLevelConfig.level or 1
        local heroID = self.roomsConfig[roomID].hero_id
        local heroLevel = CycleCastleHeroManager:GetHeroData(heroID).level
        local skillData = self:GetCurSkillData()

        local skill1Level = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(skillData[1]).skill_level
        local skill2Level = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(skillData[2]).skill_level
        local skill3Level = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(skillData[3]).skill_level

        GameSDKs:TrackForeign("cyinstance_mile", {level = value,
                                                  room_id = roomID,
                                                  room_fur_level = furLevel,
                                                  heroLevel = heroLevel,
                                                  skill_1_level = skill1Level,
                                                  skill_2_level = skill2Level,
                                                  skill_3_level = skill3Level
        })
    end
end

--endregion


--region 商店

---副本内特殊商品购买的回调
function CycleCastleModel:InstanceShopBuySccess(shopID,showFlyIcon,showRewardUI,complex)
    local shopCfg = GameTableDefine.ConfigMgr.config_shop[shopID]
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
            GameTableDefine.CycleCastleRewardUI:ShowGetReward({shop_id = shopID,count = 1,param = skillInfos},true)
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

---获取免费代币冷却时间(商店)
function CycleCastleModel:GetSlotFreeCoinCDTime()
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
function CycleCastleModel:GetSlotADFreeCoinCDTime()
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

---获取当前免费币当日领取次数(商店)
function CycleCastleModel:GetCurFreeSlotCoinTimes()
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
function CycleCastleModel:GetCurADFreeSlotCoinTimes()
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
function CycleCastleModel:CanGetFreeSlotCoin()
    return self:GetCurFreeSlotCoinTimes() < self.config_global.cycle_instance_freeCoinFre and self:GetSlotFreeCoinCDTime() <= 0
end

---(广告)
function CycleCastleModel:CanGetADFreeSlotCoin()
    return self:GetCurADFreeSlotCoinTimes() < self.config_global.cycle_instance_freeCoinFre and self:GetSlotADFreeCoinCDTime() <= 0
end

---获取一次免费代币
function CycleCastleModel:GetOneTimeSlotFreeCoin(showFlyIcon)
    if self:CanGetFreeSlotCoin() then
        self:ChangeSlotCoin(self.config_global.cycle_instance_freeCoinNum)
        GameSDKs:TrackForeign("cy_get_coin", { source = "商店免费领取", num = tonumber(self.config_global.cycle_instance_freeCoinNum) })
        
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

---获取当前标志性建筑是否购买
function CycleCastleModel:GetLandMarkCanPurchas()
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

function CycleCastleModel:SetLandMarkCanPurchas()
    if self.saveData then
        self.saveData.m_Landmark = true

        --购买后要立刻隐藏地标的购买提示
        if self.m_currentScene and self.m_currentScene.floatUI and self.m_currentScene.floatUI.Landmark then
            if self.m_currentScene.floatUI.Landmark.view then
                self.m_currentScene.floatUI.Landmark.view:Invoke("ShowCycleCastleSpacialGOBuyTipPop", false)
            end
        end
    end
end


--endregion


--region 离线奖励

---结算离线奖励
function CycleCastleModel:CalculateInstanceOfflineReward()
    if not self.saveData then
        return
    end
    if self.saveData.m_CurLastOfflineTime and self.saveData.m_CurLastOfflineTime > 0 then
        if not self.saveData.m_CurOfflineOffsetTime then
            self.saveData.m_CurOfflineOffsetTime = 0
        end
        local offsetTime = self.saveData.m_CurOfflineOffsetTime + (GameTimeManager:GetCurServerOrLocalTime() - self.saveData.m_CurLastOfflineTime)
        if offsetTime > OFFLINE_TIME then
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
    if not self.saveData.m_CurOfflineOffsetTime or self.saveData.m_CurOfflineOffsetTime < OFFLINE_TIME then
        return
    end
    --开始计算离线的奖励数据
    local rewardOfflineTime = math.floor(self.saveData.m_CurOfflineOffsetTime)
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
function CycleCastleModel:GetCurInstanceOfflineRewardData()
    return self.m_CurOfflineRewardData
end

---领取离线奖励
function CycleCastleModel:GetOfflineReward()
    if self.m_CurOfflineRewardData then
        self.m_CurOfflineRewardData = nil
    end
    self.m_CurDisplayOfflinesetTime = 0
end


function CycleCastleModel:GetCurOfflineDisplayTime()
    local time = 0
    if self.m_CurDisplayOfflinesetTime then
        return self.m_CurDisplayOfflinesetTime
    end
    if self.saveData and self.saveData.m_CurOfflineOffsetTime then
        return self.saveData.m_CurOfflineOffsetTime
    end
    return 0
end

function CycleCastleModel:GetMaxOfflineTime()
    return 7200
end

---计算离线奖励
function CycleCastleModel:CalculateOfflineRewards(offlineDuration, onlyEarnings, changeSaveData)
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
                --        --end
                --        --if physical < 20 then
                --        --end

                --        --curFurPor = curFurPor * (1-debuff)
                --        roomPro = roomPro + curFurPor
                --    end
                --end
                --计算这个房间一天(游戏时间)的单位产量
                local resCount, exp, point = self:GetRoomProduction(roomID)

                local times = self.config_global.cycle_instance_duration * 60 / roomCD
                resCount = resCount * times
                exp = exp * times
                point = point * times
                local curDayProduction = resCount
                if day == dayUp and lastDay > 0 then
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
        CycleCastleMainViewUI:Refresh()
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


--endregion

--region 英雄

---获取英雄存档
function CycleCastleModel:GetHeroSaveData()
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

---获取当前英雄升级所需资源
function CycleCastleModel:GetCurHeroExpRes()
    if not self.saveData.m_Experience then
        self.saveData.m_Experience = "0"
    end
    return self.saveData.m_Experience
end

function CycleCastleModel:GetCurHeroExpResShow()
    if self.saveData then
        return self.saveData.m_Experience_Show
    end
    return 0
end

---修改英雄升级资源
function CycleCastleModel:ChangeCurHeroExpRes(changeValue)
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
function CycleCastleModel:GetExpOutputPerMin()
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
function CycleCastleModel:GetPointsOutputPerMin()
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

---增加[任务开启后]积累副本[英雄经验]
function CycleCastleModel:AddTaskAccumulateHeroExp(num)
    if BigNumber:CompareBig(num,0) then
        local current = self:GetTaskAccumulateHeroExp()
        self.saveData.m_taskAccumulateHeroExp = BigNumber:Add(current,num)
    end
end

---@return string 累计[任务开启后]获取的[英雄经验]
function CycleCastleModel:GetTaskAccumulateHeroExp()
    if self.saveData and self.saveData.m_taskAccumulateHeroExp then
        return self.saveData.m_taskAccumulateHeroExp
    end
    return "0"
end

---@return number 重置[任务开启后]获取的[英雄经验]
function CycleCastleModel:ResetTaskAccumulateHeroExp()
    if self.saveData then
        self.saveData.m_taskAccumulateHeroExp = "0"
    end
end

---增加[任务开启后]积累副本[扭蛋币](消耗的扭蛋币)
function CycleCastleModel:AddTaskAccumulateSlotCoin(num)
    if num > 0 then
        local current = self:GetTaskAccumulateSlotCoin()
        self.saveData.m_taskAccumulateSlotCoin = current + num
        if self.saveData.m_taskAccumulateSlotCoin < 0 then
            self.saveData.m_taskAccumulateSlotCoin = 0
        end
    else
        --目前减少也是一样的处理
        local current = self:GetTaskAccumulateSlotCoin()
        self.saveData.m_taskAccumulateSlotCoin = current + num
        if self.saveData.m_taskAccumulateSlotCoin < 0 then
            self.saveData.m_taskAccumulateSlotCoin = 0
        end
    end
end

---@return number 累计[任务开启后]获取的[扭蛋币]
function CycleCastleModel:GetTaskAccumulateSlotCoin()
    if self.saveData and self.saveData.m_taskAccumulateSlotCoin then
        return self.saveData.m_taskAccumulateSlotCoin
    end
    return 0
end

---@return number 重置[任务开启后]获取的[扭蛋币]
function CycleCastleModel:ResetTaskAccumulateSlotCoin()
    if self.saveData then
        self.saveData.m_taskAccumulateSlotCoin = 0
    end
end

--endregion

--region 技能
CycleCastleModel.SkillTypeEnum = {
    ReduceUpgradeCosts = 1,
    AddBooks = 2,
    AddSellingPrice = 3
}

---获取当前技能ID列表
function CycleCastleModel:GetCurSkillData()
    if not self.saveData.m_Skill then
        self.saveData.m_Skill = {}
        self.saveData.m_Skill[1] = self.config_cy_instance_skill[1][0].id
        self.saveData.m_Skill[2] = self.config_cy_instance_skill[2][0].id
        self.saveData.m_Skill[3] = self.config_cy_instance_skill[3][0].id
    end

    return self.saveData.m_Skill
end

---获取当前的技能点数
function CycleCastleModel:GetCurSkillPoints(skillType)
    if not self.saveData.m_curSkillPoints then
        self.saveData.m_curSkillPoints = {}
    end
    if not self.saveData.m_curSkillPoints[skillType] then
        self.saveData.m_curSkillPoints[skillType] = 0
    end
    return self.saveData.m_curSkillPoints[skillType]
end

---升级技能
function CycleCastleModel:UpdateSkill(oldSkillID)
    local result = false
    local oldSkillCfg = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(oldSkillID)
    local nextSkillCfg = GameTableDefine.CycleCastleSkillUI:GetNextSkillItemCfg(oldSkillID)
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

function CycleCastleModel:CheckSkillCanUpdate()
    if not self.saveData.m_Skill or not self.saveData.m_curSkillPoints then
        return false
    end

    local checkResult = false
    for k, v in pairs(self.saveData.m_Skill) do
        -- local oldSkillCfg = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(v)
        local nextSkillCfg = GameTableDefine.CycleCastleSkillUI:GetNextSkillItemCfg(v)
        if nextSkillCfg then
            if self.saveData.m_curSkillPoints[k] >= nextSkillCfg.res then
                return true
            end
        end
    end
    return false
end

function CycleCastleModel:GetSkillBufferValueBySkillID(skillid)
    local skillCfg = GameTableDefine.CycleCastleSkillUI:GetCurSkillItemCfg(skillid)
    if not skillCfg then
        return nil
    end
    return skillCfg.buff
end

---获取技能ID
function CycleCastleModel:GetSkillIDByType(type)
    if self.saveData.m_Skill then
        return self.saveData.m_Skill[type] or 0
    end
    return 0
end

---增加技能点数
function CycleCastleModel:AddSkillPoints(addValue)
    local tmpAddValue = {}
    local keyTable = {}
    local maxTypeList = {}
    for k, v in pairs(self.saveData.m_curSkillPoints) do
        tmpAddValue[k] = 0
        local skillID = self:GetSkillIDByType(k)
        local skillNextCfg = GameTableDefine.CycleCastleSkillUI:GetNextSkillItemCfg(skillID)
        if not skillNextCfg then
            table.insert(maxTypeList, k)
        else
            table.insert(keyTable, k)
        end
    end
    
    if Tools:GetTableSize(keyTable) == 1 then
        tmpAddValue[keyTable[1]] = tmpAddValue[keyTable[1]] + addValue
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
                    tmpAddValue[keyTable[keyIndex]] = tmpAddValue[keyTable[keyIndex]] + 1
                else
                    tmpAddValue[maxTypeList[keyIndex]] = tmpAddValue[maxTypeList[keyIndex]] + 1
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
                tmpAddValue[keyTable[keyIndex]] = tmpAddValue[keyTable[keyIndex]] + 1
            end
        end
    end
    --TODO：这里要根据类型飞不同的Icon效果
    for k, v in pairs(self.saveData.m_curSkillPoints) do
        self.saveData.m_curSkillPoints[k] = self.saveData.m_curSkillPoints[k] + tmpAddValue[k]
    end
    return tmpAddValue
end

function CycleCastleModel:GetBuySkillTimes(shopID)
    if not self.saveData.m_BuySkillTimes then
        self.saveData.m_BuySkillTimes = {}
    end
    if not self.saveData.m_BuySkillTimes[tostring(shopID)] then
        self.saveData.m_BuySkillTimes[tostring(shopID)] = 0
    end
    return self.saveData.m_BuySkillTimes[tostring(shopID)]
end

function CycleCastleModel:AddBuySkillTimes(shopID)
    local times = self:GetBuySkillTimes(shopID)
    self.saveData.m_BuySkillTimes[tostring(shopID)]  = self.saveData.m_BuySkillTimes[tostring(shopID)] + 1
end
--endregion

--region 礼包

--全在基类里面

--endregion

--region 广告事件

--全在基类里面

--endregion

--region 拉霸机

---获取一次免费代币(广告)
function CycleCastleModel:GetOneTimeSlotADFreeCoin()
    if self:CanGetADFreeSlotCoin() then
        self:ChangeSlotCoin(self.config_global.cycle_instance_freeCoinNum)
        GameSDKs:TrackForeign("cy_get_coin", { source = "拉霸机广告", num = tonumber(self.config_global.cycle_instance_freeCoinNum) })
        
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

---返回拉霸机历史获得代币数量
function CycleCastleModel:GetHistorySlotCoin()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end

    -- 添加容错
    if not self.saveData.m_slot_machine.historyToken then
        self.saveData.m_slot_machine.historyToken = 0
    end

    return self.saveData.m_slot_machine.historyToken
end

---返回拉霸机当前代币数量
function CycleCastleModel:GetCurSlotCoin()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end
    return self.saveData.m_slot_machine.curToken
end

---返回拉霸机当前代币倍率
function CycleCastleModel:GetCurSlotMagnification()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end
    return self.saveData.m_slot_machine.magnification or 1
end

---设置拉霸机当前代币倍率
function CycleCastleModel:SetCurSlotMagnification(magnification)
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
    end
    self.saveData.m_slot_machine.magnification = magnification
end

---修改拉霸机当前代币数量，如果传入值是负数的话，就是使用代币了 
function CycleCastleModel:ChangeSlotCoin(changeVale)
    local curCoin = self:GetCurSlotCoin()
    if changeVale < 0 and curCoin + changeVale < 0 then
        return false
    end
    if changeVale<0 then
        self:AddTaskAccumulateSlotCoin(-changeVale)
    end
    self.saveData.m_slot_machine.curToken  = self.saveData.m_slot_machine.curToken + changeVale

    -- 副本拉霸机代币获得的数量总和
    if changeVale > 0 then
        self.saveData.m_slot_machine.historyToken  = self.saveData.m_slot_machine.historyToken + changeVale
    end
    return true
end

function CycleCastleModel:GetSlotMachineLevel()
    if self.saveData then
        if not self.saveData.m_slotMachineLevel then
            self.saveData.m_slotMachineLevel = 1
        end
        return self.saveData.m_slotMachineLevel
    end
end

function CycleCastleModel:SetSlotMachineLevel(level)
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
function CycleCastleModel:PushSlotNumAdd()
    if self.saveData then
        if not self.saveData.push_slot_num then
            self.saveData.push_slot_num = 1
        else
            self.saveData.push_slot_num = self.saveData.push_slot_num + 1
        end
    end
end

function CycleCastleModel:GetSlotPushNum()
    if self.saveData and self.saveData.push_slot_num then
        return self.saveData.push_slot_num
    end
    return 0
end

function CycleCastleModel:PushSlotRotioNum(rotio)
    if self.saveData then
        if not self.saveData.push_slot_rotio_num then
            self.saveData.push_slot_rotio_num = rotio
        else
            self.saveData.push_slot_rotio_num = self.saveData.push_slot_rotio_num + rotio
        end
    end
end

function CycleCastleModel:GetSlotPushNumRotio()
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
function CycleCastleModel:GetRoomLevelAndHeroLevel(roomID, heroID)
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

---override 设置引导为已完成状态
function CycleCastleModel:SetGuideCompleted(guideID)
    self:getSuper(CycleCastleModel).SetGuideCompleted(self,guideID)
    CycleCastleMainViewUI:RefreshUIEntryByGuideState()

    if guideID == 14020 then
        --解锁地标气泡
        if self:GetLandMarkCanPurchas() then
            local scene = self:GetScene()
            if scene then
                if scene.floatUI.Landmark and scene.floatUI.Landmark.view then
                    scene.floatUI.Landmark.view:Invoke("ShowCycleCastleSpacialGOBuyTipPop", true)
                end
            end
        end
    end
end

---override 返回房间升级消耗的钱,可通过技能降低消耗
function CycleCastleModel:GetRoomUpgradeCost(roomID,level)
    local roomNextLevelCfg = self:GetRoomLevelConfig(roomID,level)
    if roomNextLevelCfg.upgrade_cost then
        local cost = roomNextLevelCfg.upgrade_cost
        local buffID = self:GetSkillIDByType(CycleCastleModel.SkillTypeEnum.ReduceUpgradeCosts)
        local buffValue = self:GetSkillBufferValueBySkillID(buffID)
        cost = cost and BigNumber:Divide(cost,buffValue) or 0
        return cost
    else
        return 0
    end
end

---override 奖励金钱 每分钟数额(拉霸机，广告等)
function CycleCastleModel:GetRewardInComePerMinute()
    return self:GetCurHighestProfit()
end

return CycleCastleModel