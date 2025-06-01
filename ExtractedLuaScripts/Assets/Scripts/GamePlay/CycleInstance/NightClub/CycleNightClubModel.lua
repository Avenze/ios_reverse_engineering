
local CycleInstanceModelBase = require("GamePlay.CycleInstance.CycleInstanceModelBase")
local Class = require("Framework.Lua.Class")
---@class CycleNightClubModel:CycleInstanceModelBase
---@field super CycleInstanceModelBase
local CycleNightClubModel = Class("CycleNightClubModel",CycleInstanceModelBase)

local Execute = require("Framework.Queue.Execute")

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleNightClubMainViewUI = GameTableDefine.CycleNightClubMainViewUI
local CycleNightClubBuildingUI = GameTableDefine.CycleNightClubBuildingUI
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local CycleNightClubHeroManager = GameTableDefine.CycleNightClubHeroManager
local FlyIconUI = GameTableDefine.FlyIconsUI
local CycleNightClubPopUI = GameTableDefine.CycleNightClubPopUI
local CycleNightClubAIBlackBoard = GameTableDefine.CycleNightClubAIBlackBoard
local CycleNightClubBluePrintManager = GameTableDefine.CycleNightClubBluePrintManager
local FloatUI = GameTableDefine.FloatUI ---@type FloatUI
local UIView = require("Framework.UI.View") -- 当工具类使用
local ActorManager = GameTableDefine.ActorManager
local CycleInstanceClassDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")

local roomSortConfig = nil   ---将self.roomConfig按照所需材料等级从低到高排序结果
local isOpenExitPop = false
local CoinFieldName = "m_CurInstanceCoin" ---存档中副本钞票存款名
local ScoreFieldName = "m_CurScore" ---存档中副本积分名
local clientQueue = nil  ---客户队列
local clientComeTimer = 0   ---客户到来的计时器
local clientLimit = 0   ---客户数量上限
local characterPoor = nil
local durationOfStayLimit = 0   ---停留时长上限
local childPoor = nil

local SCENE_CLASS_PATH = "GamePlay.CycleInstance.NightClub.CycleNightClubScene"
local OFFLINE_TIME = 120

function CycleNightClubModel:ctor()
    self:getSuper(CycleNightClubModel).ctor(self)

    self.m_sceneClassPath = SCENE_CLASS_PATH

    self.instance_id = nil   ---副本ID(类型ID, 不是实例ID)
    self.m_currentScene = nil ---@type CycleNightClubScene

    self.workCD = {} ---用于计算建筑工作循环
    self.checkMatInterval = 5
    self.checkMatTimer = 0

    self.portExport = {}

    self.clientComeTimer = 0
    self.clientTableTimer = {}
    self.autoCreateClient = false

end

--region 生命周期

function CycleNightClubModel:Init(saveData)
    self:getSuper(CycleNightClubModel).Init(self,saveData)

    GameTableDefine.CycleNightClubHeroManager:Reset()
    GameTableDefine.CycleNightClubTaskManager:Reset()
    GameTableDefine.CycleNightClubBluePrintManager:Reset()

    -- 第一次初始化model,初始化副本数据
    if not self.saveData.m_initCash then
        self:AddCurInstanceCoin(self.config_global.cycle_instance_cash[1])--and 99999999999999999999)
        self:ChangeCurHeroExpRes(self.config_global.cycle_instance_cash[2])
        self:ChangeSlotCoin(self.config_global.cycle_instance_cash[3])
        GameSDKs:TrackForeign("cy_get_coin", { source = "副本初始化", num = tonumber(self.config_global.cycle_instance_cash[3]) })

        self:InitLimitTimePack()
        self.saveData.m_initCash = true
    end

    --初始化技能存档
    self:GetCurSkillData()
    self:GetCurSkillPoints(1)
    self:GetCurSkillPoints(2)
    self:GetCurSkillPoints(3)

    self:CheckRevertNotifyTimes()
    
    if self:GetIsPlayedOpeningTimeLine() then
        self.autoCreateClient = true
    end
end

function CycleNightClubModel:InitConfigData()
    self:getSuper(CycleNightClubModel).InitConfigData(self)
    self.config_cy_instance_skill = ConfigMgr.config_cy_instance_skill[self.instance_id]
end

function CycleNightClubModel:OnEnter()
    self:getSuper(CycleNightClubModel).OnEnter(self)
    --初始化顾客上限
    self:RefreshClientLimit()
    self:RefreshDurationOfStayLimit()
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
                        --["isOpen"] = i == "1" or i == "13" or false,   -- 初始化存档数据时,默认自动打开第一个港口
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
    
    if not self.requeueCB then
        self.requeueCB = function()
            self:CreateClient()
        end
        EventDispatcher:RegEvent("NIGHT_CLUB_CLIENT_LEAVE", self.requeueCB)
    end

end

function CycleNightClubModel:Update(dt)

    self:getSuper(CycleNightClubModel).Update(self,dt)

    if CycleInstanceDataManager:GetInstanceIsActive() then

        --TODO 礼包
        --if GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI,true) then
        --    GameTableDefine.InstancePopUI:CheckGiftPopShow()
        --end
    else
        --local instanceMainViewIndex = GameUIManager:GetUIIndex(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MAIN_VIEW_UI, true)
        if not isOpenExitPop and not self.m_currentScene:IsPlayingTimeLine() and GameUIManager:UIIsOnTop(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_MAIN_VIEW_UI,true) then
            local txt = GameTextLoader:ReadText("TXT_INSTANCE_TIP_END")
            isOpenExitPop = true
            GameTableDefine.ChooseUI:CommonChoose(txt, function()
                CycleNightClubMainViewUI:Exit()
            end, false, function()
                isOpenExitPop = false
            end)
            -- 如果正在开启引导则强制退出引导
            GameTableDefine.GuideManager:EndStep()
            GameTableDefine.GuideUI:CloseView()
        end
    end
end

function CycleNightClubModel:OnExit()
    self:getSuper(CycleNightClubModel).OnExit(self)
    EventDispatcher:UnRegEvent("NIGHT_CLUB_CLIENT_LEAVE", self.requeueCB)
    self.requeueCB = nil    
end

---游戏暂停，调用离线保存时间，退出副本和在副本中切换app到后台
function CycleNightClubModel:OnPause()
    GameTableDefine.CycleNightClubOfflineRewardUI:CloseView()
    self.m_CurOfflineRewardData = nil
    if self.saveData and CycleInstanceDataManager:GetInstanceIsActive(self.instance_id) then
        self.saveData.m_CurLastOfflineTime = GameTimeManager:GetCurServerOrLocalTime()
        LocalDataManager:WriteToFileInmmediately()
    end
    GameSDKs:TrackForeign("cy_instance_quit", { type = "退出游戏（切换后台)" })
end

---游戏恢复，调用离线的计算，主要用于在副本中切到app后台
function CycleNightClubModel:OnResume()
    self:CalculateInstanceOfflineReward()
    GameTableDefine.CycleNightClubOfflineRewardUI:GetView()
    self:CheckRevertNotifyTimes()
end


--endregion


--region 公共接口

function CycleNightClubModel:GetIsFirstEnter()
    if self.saveData then
        return self.saveData.m_FirstEnter == nil
    end
    return true
end

function CycleNightClubModel:SetIsFirstEnter()
    if self.saveData then
        self.saveData.m_FirstEnter = false
    end
end

---获取引导ID
function CycleNightClubModel:GetGuideID()
    if self.saveData then
        return self.saveData.m_Guide
    end
    return nil
end

function CycleNightClubModel:SetGuideID(value)
    if self.saveData then
        self.saveData.m_Guide = value
        LocalDataManager:WriteToFile()
    end
end

---override 计算在线收益
function CycleNightClubModel:CalculateInstanceOnlineReward(dt)
    self:CalculateFactoryUnitOutput(dt)
    self:CreateClient(dt)
end

---计算工厂单位时间的产量
function CycleNightClubModel:CalculateFactoryUnitOutput(dt)

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

function CycleNightClubModel:RefreshClientLimit()
    local roomLevelSort = self:GetHighestUnlockedRoomByRoomLevel()
    if #roomLevelSort == 0 then
        clientLimit = 0
        characterPoor = roomLevelSort[1] and roomLevelSort[1].character_id or nil
        return
    end
    clientLimit = roomLevelSort[1].character_num
    characterPoor = roomLevelSort[1].character_id
end

function CycleNightClubModel:GetClientLimit()
    return clientLimit
end

function CycleNightClubModel:RefreshDurationOfStayLimit()
    local roomLevelSort = self:GetHighestUnlockedRoomByRoomLevel()
    if #roomLevelSort == 0 then
        return
    end
    durationOfStayLimit = roomLevelSort[1].interact_time
end

function CycleNightClubModel:GetDurationOfStayLimit()
    local limit = math.random(durationOfStayLimit[1], durationOfStayLimit[2])
    return limit
end

---获取最高房间等级的已解锁房间
---@return table roomLevelCfg
function CycleNightClubModel:GetHighestUnlockedRoomByRoomLevel()
    local roomLevelSort = {}
    for k,v in pairs(self.roomsData) do
        local roomID = tonumber(k)
        local roomCfg = self:GetRoomConfigByID(roomID)
        if roomCfg.room_category == 1 and v.state == 2 then
            local roomLevelCfg = self:GetRoomLevelConfig(roomID, v.level)
            table.insert(roomLevelSort, roomLevelCfg)
        end
    end

    table.sort(roomLevelSort, function(a, b) return a.id > b.id end)
    return roomLevelSort
end

---计算码头输出量
function CycleNightClubModel:CreateClient(dt)    
    local comeCD = self.config_global.cycle_instance_bar_cooltime --- 来人CD
    
    if clientComeTimer <= comeCD then
        clientComeTimer = clientComeTimer + (dt or 0)
    else
        --在指定引导步骤之前不刷新顾客（引导ID16005），如果用以中途退出等形式中断了引导，则下次回到副本后正常刷新顾客
        local cur_guide_id = self:GetGuideID()
        if not self.autoCreateClient and (not cur_guide_id or cur_guide_id < 16005) then
            return
        end
        
        --生成顾客
        clientComeTimer = 0
        local queueLimit = self.config_global.cycle_instance_queue_LimitNum
        if CycleNightClubAIBlackBoard:GetOutClubClientNum() >= queueLimit then
            return
        end
        if characterPoor == nil then
            return
        end
        local id = characterPoor[math.random(1, #characterPoor)]
        self.m_currentScene:CreateClient(id)
        print("新顾客到来:  " .. id)
    end
end

function CycleNightClubModel:PreloadChild()
    local curChildList = ActorManager:GetActorByType("CycleToyChild")
    local curNum = curChildList and #curChildList or 0
    if curNum >= clientLimit then
        return
    end
    
    -- 生成气氛组
    local count = clientLimit * (self.config_global.cy4_costume_preload or 0.75)
    for i = 1, count do
        local id = characterPoor[math.random(1, #characterPoor)]
        self.m_currentScene:CreateClient(id, true)
        printf("预加载顾客:  " .. id)
    end
end

function CycleNightClubModel:SellAllProduct(productions, preview)
    local produtions = productions or self:GetProdutionsData()
    local incomeSum = 0
    for k, v in pairs(produtions) do
        local haveCount = v
        local sellCount = haveCount
        local income = sellCount * self.resourceConfig[tonumber(k)].price
        local sellBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
        local buffNum = self:GetSkillBufferValueBySkillID(sellBuffID)
        income = BigNumber:Multiply(income,buffNum)
        local bluePrintMoneyBuff,bluePrintMileBuff = CycleNightClubBluePrintManager:GetProductBuffValue(tonumber(k))
        income = BigNumber:Multiply(income,bluePrintMoneyBuff)
        incomeSum = incomeSum + income
        produtions[k] = 0
    end

    if preview then
        return incomeSum
    end

    self:AddCurInstanceCoin(incomeSum)
    --CycleInstanceDataManager:GetCycleInstanceMainViewUI():Refresh()
    return incomeSum
end


---设置副本产品信息
function CycleNightClubModel:SetProdutionsData(productions)
    if not productions or next(productions) == nil then
        return
    end
    if self.saveData then
        self.saveData.m_Productions = productions
    end
    -- LocalDataManager:WriteToFile()
end

---获取副本产品信息
function CycleNightClubModel:GetProdutionsData()

    if self.saveData then
        if not self.saveData.m_Productions then
            return {}
        else
            return self.saveData.m_Productions
        end
    end
end

---override 增加当前副本金钱
function CycleNightClubModel:AddCurInstanceCoin(num,showFlyIcon)

    self:getSuper(CycleNightClubModel).AddCurInstanceCoin(self,num,showFlyIcon)
    self:AddTaskAccumulateCoin(num)

    CycleNightClubMainViewUI:Refresh()
    CycleNightClubBuildingUI:RefreshView()
end

---获取某种资源的单位产量和消耗 (/min)
function CycleNightClubModel:GetProductionAndConsumptionPerMin(resourcesID)
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
function CycleNightClubModel:GetInComePerMinute()
    local priceSum = 0
    for k, v in pairs(self.roomsConfig) do
        if self:ProductIsSelling(v.production) then
            local result = self:GetRoomProduction(v.id)
            local roomCD = self:GetRoomCD(v.id)
            --蓝图BUFF
            local bluePrintMoneyBuff,bluePrintMileBuff = CycleNightClubBluePrintManager:GetProductBuffValue(v.production)
            local sellPrice = BigNumber:Multiply( self.resourceConfig[v.production].price,bluePrintMoneyBuff)

            result = BigNumber:Multiply(BigNumber:Multiply(result, sellPrice), 60.0 / roomCD)
            priceSum = priceSum + result
        end
    end

    --售价buff
    local priceBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
    local buffNum = self:GetSkillBufferValueBySkillID(priceBuffID)
    local result = BigNumber:Multiply(priceSum, buffNum)
    return result
end

---获取当前卖出的资源
function CycleNightClubModel:GetCurSellingProduct()
    local selling = {}
    local portRoomData = self:GetRoomDataByType(4)
    for k, v in pairs(portRoomData[1].furList) do
        if v.isOpen then
            local furLevelCfg = self.furnitureLevelConfig[v.id]
            table.insert(selling, furLevelCfg.resource_type)
        end
    end
    return selling
end

---产品是否正在出售
function CycleNightClubModel:ProductIsSelling(resID)
    local roomID = self:GetRoomByProduction(resID)
    return self:RoomIsUnlock(roomID)
end

function CycleNightClubModel:HaveProductCanSale()
    --local portRoomData = self:GetRoomDataByType(4)
    --for k, v in pairs(portRoomData[1].furList) do
    --    local furLevelCfg = self:GetFurLevelConfigByLevelID(v.id)
    --    if not v.isOpen and self:GetResLockedState(furLevelCfg.resource_type) then
    --        return true
    --    end
    --end
    return false
end

---获取一个房间每分钟的收益
function CycleNightClubModel:GetRoomIncomePerMin(roomID)
    --TODO
    local roomIncome = self:GetRoomProduction(roomID)
    local roomCD = self:GetRoomCD(roomID)
    local resID = self.roomsConfig[roomID].production
    local price = self.resourceConfig[resID].price

    local result = BigNumber:Multiply(roomIncome, (60 / roomCD * price))
    return result
end

---获取当前的最高收益
function CycleNightClubModel:GetCurHighestProfit(isSelling)
    --TODO
    local income, roomID = 0, nil
    for k, v in pairs(self.roomsConfig) do
        local roomData = self:GetRoomDataByID(v.id)
        local roomCfg = self:GetRoomConfigByID(roomData.roomID)
        if v.room_category == 1 and roomData.state == 2 then
            if isSelling then
                if self:ProductIsSelling(roomCfg.production) then
                    local curRoomIncomePreMin = self:GetRoomIncomePerMin(v.id)
                    if BigNumber:CompareBig(curRoomIncomePreMin, income) then
                        income = curRoomIncomePreMin
                        roomID = v.id
                    end
                end
            else
                local curRoomIncomePreMin = self:GetRoomIncomePerMin(v.id)
                if BigNumber:CompareBig(curRoomIncomePreMin, income) then
                    income = curRoomIncomePreMin
                    roomID = v.id
                end
            end
        end
    end
    local resID = self.roomsConfig[roomID] and self.roomsConfig[roomID].production or nil
    return income, roomID, resID
end

---获取某种资源的锁定状态
function CycleNightClubModel:GetResLockedState(resourcesID)
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
function CycleNightClubModel:GetSellingIndex()
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

function CycleNightClubModel:GetSellingRoomID()
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

---通过家具ID获取产量
function CycleNightClubModel:GetRoomProductionByFurId(roomID, furId)
    local count = 0
    local furLevelCfg = self.furnitureLevelConfig[furId]
    local production = tonumber(furLevelCfg.product)
    production = production * furLevelCfg.magnification
    count = count + production

    local heroBuff = CycleNightClubHeroManager:GetHeroCurrentBuff(self.roomsConfig[roomID].hero_id)
    count = count * heroBuff
    local workerCount = self:GetWorkerNum(roomID)
    count = count * workerCount

    if not self:GetLandMarkCanPurchas() then --买了地标
        local instanceBind = CycleInstanceDataManager:GetInstanceBind()
        local landmarkID = instanceBind.landmark_id
        local shopCfg = ConfigMgr.config_shop[landmarkID]
        local resAdd = shopCfg.param[1]
        count = count * (resAdd / 100)
    end

    return count
end

---获取一个房间单位时间的产品产量
function CycleNightClubModel:GetRoomProduction(roomID)
    local count, exp, points = 0, 0, 0

    --- 开场TimeLine结束，才计算奖励
    if not self:GetIsPlayedOpeningTimeLine() then
        return count, exp, points
    end

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

    local heroBuff = CycleNightClubHeroManager:GetHeroCurrentBuff(self.roomsConfig[roomID].hero_id)
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

    --蓝图BUFF
    local roomCfg = self:GetRoomConfigByID(roomID)
    local bluePrintMoneyBuff,bluePrintMileBuff = CycleNightClubBluePrintManager:GetProductBuffValue(roomCfg.production)
    points = BigNumber:Multiply(points,bluePrintMileBuff)

    return count, exp, points
end

---获取生产某种资源的房间
function CycleNightClubModel:GetRoomByProduction(productionID)
    for k,v in pairs(self.roomsConfig) do
        if v.production == productionID then
            return k
        end
    end
end

---获取一个房间单位时间的材料消耗
function CycleNightClubModel:GetRoomMatCost(roomID)
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
function CycleNightClubModel:GetWorkerNum(roomID)
    --夜店副本 固定一个房间一个员工
    return 1
end

---override 购买房间
function CycleNightClubModel:BuyRoom(roomID)
    --设置存档信息
    local timePoint = GameTimeManager:GetCurrentServerTime(true)
    self:SetRoomData(roomID,timePoint,1)

    self.m_currentScene:RefreshRoom(roomID)

    --花钱
    local cost = tonumber(self.roomsConfig[roomID].unlock_require)
    local buffID = self:GetSkillIDByType(CycleNightClubModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:AddCurInstanceCoin(-cost)
    CycleNightClubMainViewUI:Refresh()

    -- 礼包弹窗触发事件
    CycleNightClubPopUI:PackTrigger(CycleNightClubPopUI.EventType.buyRoom, roomID)

    --埋点
    local lastRoomID = roomID - 1
    local lastRoomData = self:GetRoomDataByID(lastRoomID)
    if lastRoomData then
        local lastRoomFurLevelID = lastRoomData.furList["1"].id
        local lastRoomFurLevelCfg = self:GetFurLevelConfigByLevelID(lastRoomFurLevelID)
        local roomCfg = self:GetRoomConfigByID(roomID)
        local heroData = CycleNightClubHeroManager:GetHeroData(roomCfg.hero_id)

        GameSDKs:TrackForeign("cyinstance_unlock", { id = roomID, mile_level = self:GetCurInstanceKSLevel(), fur_level = lastRoomFurLevelCfg.level, hero_level = heroData.level })
    end
end

---override 检查房间是否满足解锁条件
function CycleNightClubModel:CheckRoomCondition(roomID)
    local roomData = self:GetCurRoomData(roomID)
    local roomConfig = self:GetRoomConfigByID(roomID)
    local money = self:GetCurInstanceCoin()
    local cost = tonumber(roomConfig.unlock_require)
    local buffID = self:GetSkillIDByType(CycleNightClubModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    local lastRoomData = self:GetCurRoomData(roomConfig.unlock_room)
    if roomData and next(roomData) ~= nil and cost <= money then
        if roomConfig.unlock_room and roomConfig.unlock_room ~= 0 then
            return lastRoomData.state == 2
        else
            --没有前置房间
            return true
        end
    else
        return false
    end
end

---override 播放房间升级动画
function CycleNightClubModel:DoRoomUpgradeAnim(roomID)
    if self:getSuper(CycleNightClubModel).DoRoomUpgradeAnim(self,roomID) then
        --TODO  生成家具，镜头表现等
    end
end

---override 升级房间完成
function CycleNightClubModel:UpgradeRoomComplete(roomID)
    self:getSuper(CycleNightClubModel).UpgradeRoomComplete(self, roomID)
    self:RefreshClientLimit()
    self:RefreshDurationOfStayLimit()
end

---override 购买家具
function CycleNightClubModel:BuyFurniture(roomID, index, furLevelID)
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
    local buffID = self:GetSkillIDByType(CycleNightClubModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:AddCurInstanceCoin(-cost)
    CycleNightClubMainViewUI:Refresh()
    GameTableDefine.CycleNightClubPopUI:PackTrigger(7, furLevelCfg.id)

    -- 小猪解锁
    self:UnlockPiggyBankTrigger(furLevelCfg.id)
    
    --增加升级埋点,每5级埋点一次
    if furLevelCfg.level % 10 == 0 then
        GameSDKs:TrackForeign("cy_fur_upgrade", { id = tonumber(roomID), level = tonumber(furLevelCfg.level) })
    end

    --显示通知
    if furLevelCfg.level == 1 and furLevelCfg.isPresonFurniture then
        CycleNightClubMainViewUI:CallNotify(1)
    end
end

---返回当前指定时间产出的内容
function CycleNightClubModel:GetCurProductionsByTime(timeSeconds)
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

---获取下一个可出售的房间
---return roomCfg
function CycleNightClubModel:GetNextRoomCanSelling()
    local roomLevelSort = {}
    for k,v in pairs(self.roomsData) do
        local roomID = tonumber(k)
        local roomCfg = self:GetRoomConfigByID(roomID)
        if roomCfg.room_category == 1 and v.state == 2 then
            if not self:ProductIsSelling(roomCfg.production) then
                table.insert(roomLevelSort, roomCfg)
                --return roomCfg
            end
        end
    end
    table.sort(roomLevelSort,function(a, b) return a.id < b.id end)
    return #roomLevelSort > 0 and roomLevelSort[1] or nil
end

--endregion


--region 场景

---@overload
---@return CycleNightClubScene
function CycleNightClubModel:GetScene()
    return self.m_currentScene
end

---场景是否显示标志性建筑
function CycleNightClubModel:ShowSpecialGameObject(flag)
    self.m_currentScene:ShowSpecialGameObject(flag)
end

---地标购买成功的动画播放
function CycleNightClubModel:BuySpecialGameObjectAnimationPlay()
    self.m_currentScene:BuySpecialGameObjectAnimationPlay()
end

--endregion


--region 里程碑

---override 设置积分等级
function CycleNightClubModel:SetCurInstanceKSLevel(value)
    if self.saveData then
        self.saveData.m_CurKSLevel = value
        CycleNightClubMainViewUI:CallNotify(3)
        CycleNightClubMainViewUI:Refresh()
        --埋点
        local maxRoomData = self:GetHighestLevelUnlockedBuildingData()
        local roomID = maxRoomData.roomID
        local furLevelConfig = self:GetFurlevelConfigByRoomFurIndex(roomID,1)
        local furLevel = furLevelConfig and furLevelConfig.level or 1
        local heroID = self.roomsConfig[roomID].hero_id
        local heroLevel = CycleNightClubHeroManager:GetHeroData(heroID).level
        local skillData = self:GetCurSkillData()

        local skill1Level = GameTableDefine.CycleNightClubSkillUI:GetCurSkillItemCfg(skillData[1]).skill_level
        local skill2Level = GameTableDefine.CycleNightClubSkillUI:GetCurSkillItemCfg(skillData[2]).skill_level
        local skill3Level = GameTableDefine.CycleNightClubSkillUI:GetCurSkillItemCfg(skillData[3]).skill_level

        GameSDKs:TrackForeign("cyinstance_mile", {
            level = value,
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
function CycleNightClubModel:InstanceShopBuySccess(shopID,showFlyIcon,showRewardUI,complex)
    local shopCfg = GameTableDefine.ConfigMgr.config_shop[shopID]
    if not shopCfg then
        return 0
    end

    if 26 ~= shopCfg.type and 27 ~= shopCfg.type and 30 ~= shopCfg.type and 36 ~= shopCfg.type then
        return 0
    end

    complex = complex or 1

    if 26 == shopCfg.type then
        --增加英雄经验
        local num = ShopManager:GetValueByShopId(shopID)
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
            GameTableDefine.CycleNightClubRewardUI:ShowGetReward({shop_id = shopID,count = 1,param = skillInfos},true)
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
    if 36 == shopCfg.type then
        --增加蓝图碎片
        local num = shopCfg.amount * complex
        CycleNightClubBluePrintManager:ChangeUpgradeResCount(shopCfg.param[1],num)
        GameSDKs:TrackForeign("cy_bp_res", { source = "内购", num = tonumber(num), type = 1 })

        if showFlyIcon then
            FlyIconUI:SetCycleInstanceNum({{itemType = 36,str = num, icon =shopCfg.icon}})
        elseif showRewardUI then
            --获得奖励界面
            GameTableDefine.CycleInstanceRewardUI:ShowGetReward({shop_id = shopID,count = num},true)
        end

        return num
    end
end

---获取免费代币冷却时间(商店)
function CycleNightClubModel:GetSlotFreeCoinCDTime()
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
function CycleNightClubModel:GetSlotADFreeCoinCDTime()
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
function CycleNightClubModel:GetCurFreeSlotCoinTimes()
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
function CycleNightClubModel:GetCurADFreeSlotCoinTimes()
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
function CycleNightClubModel:CanGetFreeSlotCoin()
    return self:GetCurFreeSlotCoinTimes() < self.config_global.cycle_instance_freeCoinFre and self:GetSlotFreeCoinCDTime() <= 0
end

---(广告)
function CycleNightClubModel:CanGetADFreeSlotCoin()
    return self:GetCurADFreeSlotCoinTimes() < self.config_global.cycle_instance_freeCoinFre and self:GetSlotADFreeCoinCDTime() <= 0
end

---获取一次免费代币
function CycleNightClubModel:GetOneTimeSlotFreeCoin(showFlyIcon)
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
function CycleNightClubModel:GetLandMarkCanPurchas()
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

function CycleNightClubModel:SetLandMarkCanPurchas()
    if self.saveData then
        self.saveData.m_Landmark = true

        --购买后要立刻隐藏地标的购买提示
        if self.m_currentScene and self.m_currentScene.floatUI and self.m_currentScene.floatUI.Landmark then
            if self.m_currentScene.floatUI.Landmark.view then
                self.m_currentScene.floatUI.Landmark.view:Invoke("ShowCycleNightClubSpacialGOBuyTipPop", false)
            end
        end
    end
end


--endregion


--region 离线奖励

---结算离线奖励
function CycleNightClubModel:CalculateInstanceOfflineReward()
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
function CycleNightClubModel:GetCurInstanceOfflineRewardData()
    return self.m_CurOfflineRewardData
end

---领取离线奖励
function CycleNightClubModel:GetOfflineReward()
    if self.m_CurOfflineRewardData then
        self.m_CurOfflineRewardData = nil
    end
    self.m_CurDisplayOfflinesetTime = 0
end


function CycleNightClubModel:GetCurOfflineDisplayTime()
    local time = 0
    if self.m_CurDisplayOfflinesetTime then
        return self.m_CurDisplayOfflinesetTime
    end
    if self.saveData and self.saveData.m_CurOfflineOffsetTime then
        return self.saveData.m_CurOfflineOffsetTime
    end
    return 0
end

function CycleNightClubModel:GetMaxOfflineTime()
    return 7200
end

---计算离线奖励
function CycleNightClubModel:CalculateOfflineRewards(offlineDuration, onlyEarnings, changeSaveData)
    local instanceDay = offlineDuration / (60 * self.config_global.cycle_instance_duration)
    local lastDay = offlineDuration % (60 * self.config_global.cycle_instance_duration) / (60 * self.config_global.cycle_instance_duration)
    local dayUp = math.ceil(instanceDay)
    --初始化资源统计表
    local resTable = {}
    for k,v in pairs(self.resourceConfig) do
        resTable[k] = 0
    end

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

                --计算这个房间游戏中一天的产量
                local resCount, exp, point = self:GetRoomProduction(roomID)
                local times = self.config_global.cycle_instance_duration * 60 / roomCD
                resCount = resCount * times
                exp = exp * times
                point = point * times
                if day == dayUp and lastDay > 0 then
                    resCount = resCount * lastDay
                    exp = exp * lastDay
                    point = point * lastDay
                end

                resTable[roomCfg.production] = resTable[roomCfg.production] + resCount
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
    --local calResType = {}
    --for i=1,#roomSortConfig do
    --    local roomCfg = roomSortConfig[i]
    --    local roomID  = roomCfg.id
    --    local roomData = self.roomsData[roomID]
    --    if roomCfg.room_category == 1 and roomData.state == 2 then
    --        local materialID = roomCfg.material[1]
    --        local productID = roomCfg.production
    --        local output = resTable[productID]
    --
    --        if materialID ~= 0 and not calResType[materialID] then --需要原料
    --            calResType[materialID] = true
    --            local haveCount = resTable[materialID]
    --            local needCount = resTable[productID] * roomCfg.material[2]
    --            if haveCount > needCount then
    --                resTable[materialID] = resTable[materialID] - needCount
    --                resTable[productID] = output
    --            else
    --                resTable[materialID] = 0
    --                resTable[productID] = math.floor(haveCount / roomCfg.material[2])
    --            end
    --        else
    --            resTable[productID] = output
    --        end
    --    end
    --end
    --calResType = nil

    if onlyEarnings then
        return resTable
    end

    --print("计算生产消耗后==================================")
    --for k,v in pairs(resTable) do
    --    print(k,resTable[k])
    --end

    --local productions = changeSaveData and self.productions or Tools:CopyTable(self.productions)
    local productions = resTable

    --计算港口卖出
    local money = 0
    money = self:SellAllProduct(productions, true)

    --for k,v in pairs(self.roomsData) do
    --    local roomID = v.roomID
    --    local saleCount = 0
    --    local roomCfg = self.roomsConfig[roomID]
    --    if roomCfg.room_category == 4 and v.state == 2 then
    --        local furList = v.furList
    --        for furIndex,furData in pairs(furList) do
    --            local furLevelCfg = self.furnitureLevelConfig[furData.id]
    --            if furData.state == 1 and furLevelCfg.shipCD > 0 then  --找船
    --                local portFurData = furList[tostring(furData.index - 12)]
    --                if portFurData.isOpen then
    --                    local partID = portFurData.id
    --                    local portLevelCfg = self.furnitureLevelConfig[partID]
    --                    --local saleCount = portLevelCfg.storage * offlineDuration / (furLevelCfg.shipCD + self.config_global.cycle_instance_ship_loadtime)
    --                    local curResID = portLevelCfg.resource_type
    --                    saleCount = (productions[curResID] or 0) + (resTable[curResID] or 0)
    --                    local resCfg = self.resourceConfig[curResID]
    --                    if resTable[curResID] >= saleCount then
    --                        resTable[curResID] = resTable[curResID] - saleCount
    --                        money = money + saleCount * resCfg.price
    --                    else
    --                        local storag = productions[tostring(curResID)]
    --                        if storag + resTable[curResID] >= saleCount then
    --                            productions[tostring(curResID)] = storag - (saleCount-resTable[curResID])
    --                            resTable[curResID] = 0
    --                            money = money + saleCount * resCfg.price
    --                        else
    --                            saleCount = productions[tostring(curResID)] + resTable[curResID]
    --                            productions[tostring(curResID)] = 0
    --                            resTable[curResID] = 0
    --                            money = money + saleCount * resCfg.price
    --                        end
    --                    end
    --                end
    --            end
    --        end
    --    end
    --end
    --local expBuffID = self:GetSkillIDByType(self.SkillTypeEnum.AddSellingPrice)
    --local buffNum = self:GetSkillBufferValueBySkillID(expBuffID)
    --money = money * buffNum

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

    --- 开场TimeLine结束，才计算奖励
    if not self:GetIsPlayedOpeningTimeLine() then
        money = 0
        expSum = 0
        pointSum = 0
    end

    if changeSaveData then
        self:SetProdutionsData(productions)
        self:AddCurInstanceCoin(money)
        self:ChangeCurHeroExpRes(expSum)
        self:AddScore(pointSum)
        CycleNightClubMainViewUI:Refresh()
    end

    local resReward = {}
    for k,v in pairs(resTable) do
        --if resTable[k] > 0 then
        --    local resCfg = self.resourceConfig[k]
        --    table.insert(resReward,{
        --        count = resTable[k],
        --        resCfg = resCfg
        --    })
        --end

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
function CycleNightClubModel:GetHeroSaveData()
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
function CycleNightClubModel:GetCurHeroExpRes()
    if not self.saveData.m_Experience then
        self.saveData.m_Experience = "0"
    end
    return self.saveData.m_Experience
end

function CycleNightClubModel:GetCurHeroExpResShow()
    if self.saveData then
        return self.saveData.m_Experience_Show
    end
    return 0
end

---修改英雄升级资源
function CycleNightClubModel:ChangeCurHeroExpRes(changeValue)
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
function CycleNightClubModel:GetExpOutputPerMin()
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
function CycleNightClubModel:GetPointsOutputPerMin()
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
function CycleNightClubModel:AddTaskAccumulateHeroExp(num)
    if BigNumber:CompareBig(num,0) then
        local current = self:GetTaskAccumulateHeroExp()
        self.saveData.m_taskAccumulateHeroExp = BigNumber:Add(current,num)
    end
end

---@return string 累计[任务开启后]获取的[英雄经验]
function CycleNightClubModel:GetTaskAccumulateHeroExp()
    if self.saveData and self.saveData.m_taskAccumulateHeroExp then
        return self.saveData.m_taskAccumulateHeroExp
    end
    return "0"
end

---@return number 重置[任务开启后]获取的[英雄经验]
function CycleNightClubModel:ResetTaskAccumulateHeroExp()
    if self.saveData then
        self.saveData.m_taskAccumulateHeroExp = "0"
    end
end

---增加[任务开启后]积累副本[扭蛋币](消耗的扭蛋币)
function CycleNightClubModel:AddTaskAccumulateSlotCoin(num)
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
function CycleNightClubModel:GetTaskAccumulateSlotCoin()
    if self.saveData and self.saveData.m_taskAccumulateSlotCoin then
        return self.saveData.m_taskAccumulateSlotCoin
    end
    return 0
end

---@return number 重置[任务开启后]获取的[扭蛋币]
function CycleNightClubModel:ResetTaskAccumulateSlotCoin()
    if self.saveData then
        self.saveData.m_taskAccumulateSlotCoin = 0
    end
end

--endregion

--region 技能
CycleNightClubModel.SkillTypeEnum = {
    ReduceUpgradeCosts = 1,
    AddBooks = 2,
    AddSellingPrice = 3
}

---获取当前技能ID列表
function CycleNightClubModel:GetCurSkillData()
    if not self.saveData.m_Skill then
        self.saveData.m_Skill = {}
        self.saveData.m_Skill[1] = self.config_cy_instance_skill[1][0].id
        self.saveData.m_Skill[2] = self.config_cy_instance_skill[2][0].id
        self.saveData.m_Skill[3] = self.config_cy_instance_skill[3][0].id
    end

    return self.saveData.m_Skill
end

---获取当前的技能点数
function CycleNightClubModel:GetCurSkillPoints(skillType)
    if not self.saveData.m_curSkillPoints then
        self.saveData.m_curSkillPoints = {}
    end
    if not self.saveData.m_curSkillPoints[skillType] then
        self.saveData.m_curSkillPoints[skillType] = 0
    end
    return self.saveData.m_curSkillPoints[skillType]
end

---升级技能
function CycleNightClubModel:UpdateSkill(oldSkillID)
    local result = false
    local oldSkillCfg = GameTableDefine.CycleNightClubSkillUI:GetCurSkillItemCfg(oldSkillID)
    local nextSkillCfg = GameTableDefine.CycleNightClubSkillUI:GetNextSkillItemCfg(oldSkillID)
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

function CycleNightClubModel:CheckSkillCanUpdate()
    if not self.saveData.m_Skill or not self.saveData.m_curSkillPoints then
        return false
    end

    local checkResult = false
    for k, v in pairs(self.saveData.m_Skill) do
        -- local oldSkillCfg = GameTableDefine.CycleNightClubSkillUI:GetCurSkillItemCfg(v)
        local nextSkillCfg = GameTableDefine.CycleNightClubSkillUI:GetNextSkillItemCfg(v)
        if nextSkillCfg then
            if self.saveData.m_curSkillPoints[k] >= nextSkillCfg.res then
                return true
            end
        end
    end
    return false
end

function CycleNightClubModel:GetSkillBufferValueBySkillID(skillid)
    local skillCfg = GameTableDefine.CycleNightClubSkillUI:GetCurSkillItemCfg(skillid)
    if not skillCfg then
        return nil
    end
    return skillCfg.buff
end

---获取技能ID
function CycleNightClubModel:GetSkillIDByType(type)
    if self.saveData.m_Skill then
        return self.saveData.m_Skill[type] or 0
    end
    return 0
end

---增加技能点数
function CycleNightClubModel:AddSkillPoints(addValue)
    local tmpAddValue = {}
    local keyTable = {}
    local maxTypeList = {}
    for k, v in pairs(self.saveData.m_curSkillPoints) do
        tmpAddValue[k] = 0
        local skillID = self:GetSkillIDByType(k)
        local skillNextCfg = GameTableDefine.CycleNightClubSkillUI:GetNextSkillItemCfg(skillID)
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

function CycleNightClubModel:GetBuySkillTimes(shopID)
    if not self.saveData.m_BuySkillTimes then
        self.saveData.m_BuySkillTimes = {}
    end
    if not self.saveData.m_BuySkillTimes[tostring(shopID)] then
        self.saveData.m_BuySkillTimes[tostring(shopID)] = 0
    end
    return self.saveData.m_BuySkillTimes[tostring(shopID)]
end

function CycleNightClubModel:AddBuySkillTimes(shopID)
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
function CycleNightClubModel:GetOneTimeSlotADFreeCoin()
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
function CycleNightClubModel:GetHistorySlotCoin()
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
function CycleNightClubModel:GetCurSlotCoin()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
    end
    return self.saveData.m_slot_machine.curToken
end

---返回拉霸机当前代币倍率
function CycleNightClubModel:GetCurSlotMagnification()
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
    end
    return self.saveData.m_slot_machine.magnification or 1
end

---设置拉霸机当前代币倍率
function CycleNightClubModel:SetCurSlotMagnification(magnification)
    if not self.saveData.m_slot_machine then
        self.saveData.m_slot_machine = {}
        self.saveData.m_slot_machine.curToken = 0
        self.saveData.m_slot_machine.magnification = 1 --初始化的倍率为1
        self.saveData.m_slot_machine.historyToken = 0 -- 副本拉霸机代币获得的数量总和
    end
    self.saveData.m_slot_machine.magnification = magnification
end

---修改拉霸机当前代币数量，如果传入值是负数的话，就是使用代币了
function CycleNightClubModel:ChangeSlotCoin(changeVale)
    local curCoin = self:GetCurSlotCoin()
    if changeVale < 0 and curCoin + changeVale < 0 then
        return false
    end
    if changeVale<0 then
        self:AddTaskAccumulateSlotCoin(-changeVale)
    end

    self.saveData.m_slot_machine.curToken  = self.saveData.m_slot_machine.curToken + changeVale

    if changeVale > 0 then
        -- 累计 获得 拉霸机代币的数量
        self.saveData.m_slot_machine.historyToken  = self.saveData.m_slot_machine.historyToken + changeVale
        GameTableDefine.CycleNightClubRankManager:ChangeSlotCoin()
    else
        -- 累计 消耗 的拉霸机代币数量
        if not self.saveData.m_slot_machine.historyCostToken then
            self.saveData.m_slot_machine.historyCostToken = 0
        end

        self.saveData.m_slot_machine.historyCostToken  = self.saveData.m_slot_machine.historyCostToken + math.abs(changeVale)
    end

    printf("拉霸机代币数"..self.saveData.m_slot_machine.curToken)
    return true
end

---累计 消耗 的拉霸机代币数量
function CycleNightClubModel:GetCurSlotHistoryCostToken()
    if not self.saveData.m_slot_machine.historyCostToken then
        self.saveData.m_slot_machine.historyCostToken = 0
    end

    return self.saveData.m_slot_machine.historyCostToken
end

---小猪充能
function CycleNightClubModel:ChangeSlotPiggyBank(needCoins)
    local piggyBankInfo = self:GetCurSlotPiggyBankInfo()
    piggyBankInfo.value = piggyBankInfo.value + needCoins
end

---购买小猪
function CycleNightClubModel:BuySlotPiggyBank()
    local piggyBankInfo = self:GetCurSlotPiggyBankInfo()

    -- todo 发放礼包奖品
    local piggyBankConf = self.config_cy_instance_piggypack[piggyBankInfo.lv]
    if not piggyBankConf then
        return
    end

    self:ChangeSlotCoin(piggyBankConf.reward)

    -- 购买时间及当时数据
    piggyBankInfo.record[tostring(piggyBankInfo.lv)].time = os.time()
    piggyBankInfo.record[tostring(piggyBankInfo.lv)].value = piggyBankInfo.value

    -- 升级并重置数值
    piggyBankInfo.value = 0
    piggyBankInfo.lv = piggyBankInfo.lv + 1

    return piggyBankConf.reward
end


---小猪数据
function CycleNightClubModel:GetCurSlotPiggyBankInfo()
    if not self.saveData.m_slot_machine_piggy_bank then
        self.saveData.m_slot_machine_piggy_bank = { value = 0, lv = 1, record = {}}
    end

    if not self.saveData.m_slot_machine_piggy_bank.record[tostring(self.saveData.m_slot_machine_piggy_bank.lv)] then
        self.saveData.m_slot_machine_piggy_bank.record[tostring(self.saveData.m_slot_machine_piggy_bank.lv)] = {}
    end

    if not self.saveData.m_slot_machine_piggy_bank.show_time then
        self.saveData.m_slot_machine_piggy_bank.show_time = {}
    end

    return self.saveData.m_slot_machine_piggy_bank
end

---小猪当前等级数据及最大值
function CycleNightClubModel:GetPiggyBankValue()
    local piggyBankInfo = self:GetCurSlotPiggyBankInfo()
    if not piggyBankInfo.value or not piggyBankInfo.lv then
        return nil, nil, piggyBankInfo
    end

    local piggyBankConf = self.config_cy_instance_piggypack[piggyBankInfo.lv]
    if not piggyBankConf then
        return nil, nil, piggyBankInfo
    end

    local unlock_value = 0
    if piggyBankConf.key[1] == 1 then -- 引导ID
        if not piggyBankInfo.unlock_time then
            unlock_value = 999999
        end
    elseif piggyBankConf.key[1] == 2 then -- 间隔上个礼包解锁次数
        unlock_value = piggyBankConf.key[2]
    end

    local curValue = piggyBankInfo.value - unlock_value
    local maxValue = piggyBankConf.time
    if maxValue <= 0 then
        return nil, nil, piggyBankInfo
    end

    return math.min(curValue, maxValue), maxValue, piggyBankInfo, piggyBankConf
end

-- 解锁后，首次展示时间
function CycleNightClubModel:ShowPiggyBankFirst()
    local piggyBankInfo = self:GetCurSlotPiggyBankInfo()
    if not piggyBankInfo.show_time[tostring(piggyBankInfo.lv)] then
        piggyBankInfo.show_time[tostring(piggyBankInfo.lv)] = os.time()
    end
end

-- 小猪解锁
function CycleNightClubModel:UnlockPiggyBankTrigger(fur_id)
    local piggyBankInfo = self:GetCurSlotPiggyBankInfo()
    if piggyBankInfo.unlock_time then
        return
    end

    local piggyBankConf = self.config_cy_instance_piggypack[1]
    if piggyBankConf.key[2] == fur_id then
        piggyBankInfo.unlock_time = os.time()

        -- 解锁后，刷新按钮状态
        GameTableDefine.CycleNightClubSlotMachineUI:RefreshPiggyBank()
        GameTableDefine.CycleNightClubMainViewUI:RefreshPiggyBank()
    end
end

function CycleNightClubModel:GetSlotMachineLevel()
    if self.saveData then
        if not self.saveData.m_slotMachineLevel then
            self.saveData.m_slotMachineLevel = 1
        end
        return self.saveData.m_slotMachineLevel
    end
end

function CycleNightClubModel:SetSlotMachineLevel(level)
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
function CycleNightClubModel:PushSlotNumAdd()
    if self.saveData then
        if not self.saveData.push_slot_num then
            self.saveData.push_slot_num = 1
        else
            self.saveData.push_slot_num = self.saveData.push_slot_num + 1
        end
    end
end

function CycleNightClubModel:GetSlotPushNum()
    if self.saveData and self.saveData.push_slot_num then
        return self.saveData.push_slot_num
    end
    return 0
end

function CycleNightClubModel:PushSlotRotioNum(rotio)
    if self.saveData then
        if not self.saveData.push_slot_rotio_num then
            self.saveData.push_slot_rotio_num = rotio
        else
            self.saveData.push_slot_rotio_num = self.saveData.push_slot_rotio_num + rotio
        end
    end
end

function CycleNightClubModel:GetSlotPushNumRotio()
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
function CycleNightClubModel:GetRoomLevelAndHeroLevel(roomID, heroID)
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
function CycleNightClubModel:SetGuideCompleted(guideID)
    self:getSuper(CycleNightClubModel).SetGuideCompleted(self,guideID)
    CycleNightClubMainViewUI:RefreshUIEntryByGuideState()

    if guideID == CycleInstanceClassDefine.GuideDefine.NightClub.UnlockMilestone then
        --解锁地标气泡
        if self:GetLandMarkCanPurchas() then
            local scene = self:GetScene()
            if scene then
                if scene.floatUI.Landmark and scene.floatUI.Landmark.view then
                    scene.floatUI.Landmark.view:Invoke("ShowCycleNightClubSpacialGOBuyTipPop", true)
                end
            end
        end
    end
end

---override 返回房间升级消耗的钱,可通过技能降低消耗
function CycleNightClubModel:GetRoomUpgradeCost(roomID,level)
    local roomNextLevelCfg = self:GetRoomLevelConfig(roomID,level)
    if roomNextLevelCfg.upgrade_cost then
        local cost = roomNextLevelCfg.upgrade_cost
        local buffID = self:GetSkillIDByType(CycleNightClubModel.SkillTypeEnum.ReduceUpgradeCosts)
        local buffValue = self:GetSkillBufferValueBySkillID(buffID)
        cost = cost and BigNumber:Divide(cost,buffValue) or 0
        return cost
    else
        return 0
    end
end

-----临时开启引导相关功能
-----返回引导是否完成
--function CycleNightClubModel:IsGuideCompleted(guideID)
--    return true
--end

---override 离线推送
function CycleNightClubModel:SendNotification()
    --仅推送给进入副本的用户
    if self:GetIsFirstEnter() then
        return
    end
    --仅在活动开启期间推送
    if not CycleInstanceDataManager:GetInstanceIsActive(self.saveData.m_Instance_id) then
        return
    end

    --3.建筑修建完成
    --遍历所有房间,如果房间正在解锁中
    local now = GameTimeManager:GetTheoryTime()
    do
        local title = GameTextLoader:ReadText("TXT_INSTANCE_Notify_build_title")
        local content = GameTextLoader:ReadText("TXT_INSTANCE_Notify_build_desc")
        for k,v in pairs(self.roomsData) do
            local roomID = v.roomID
            local curRoomData = v
            if curRoomData.state == 1 then
                local timePoint = curRoomData.buildTimePoint
                local roomCfg = self:GetRoomConfigByID(roomID)
                local endPoint = timePoint + roomCfg.unlock_times
                local countdown = endPoint - now
                if countdown > 0 then
                    GameDeviceManager:AddNotification(title, countdown, content,nil,2003)
                end
            end
        end
    end

    --4.副本离线收益达到上限
    do
        if not self.saveData.m_notify then
            self.saveData.m_notify = {}
        end
        local currentDate = GameTimeManager:GetTimeLengthDate(now)
        if self.saveData.m_notify.day then
            if self.saveData.m_notify.day ~= currentDate.d then
                self.saveData.m_notify.offlineTimes = 0
                self.saveData.m_notify.day = currentDate.d
                self.saveData.m_notify.lastOfflineTime = 0
            end
        else
            self.saveData.m_notify.day = currentDate.d
        end
        --每天只提醒前两次
        local notifyTime = self.saveData.m_notify.offlineTimes or 0
        if notifyTime < 2 then
            local countdown = OFFLINE_TIME * 60
            --若活动结束时间<本次最大离线时长时间，则不再推送
            if now + countdown < self.saveData.m_EndTime then
                local title = GameTextLoader:ReadText("TXT_INSTANCE_Notify_offline_title")
                local content = GameTextLoader:ReadText("TXT_INSTANCE_Notify_offline_desc")
                GameDeviceManager:AddNotification(title, countdown, content,nil,2004)
                self.saveData.m_notify.offlineTimes = notifyTime + 1
                self.saveData.m_notify.lastOfflineTime = now
                LocalDataManager:WriteToFile()
                printf("增加副本离线提示次数,当前已用次数为"..self.saveData.m_notify.offlineTimes)
            end
        end
    end
end

---检查是否应该还原离线推送的提示次数
function CycleNightClubModel:CheckRevertNotifyTimes()
    if not self.saveData.m_notify then
        return
    end
    local now = GameTimeManager:GetTheoryTime()
    if self.saveData.m_notify.day then
        local currentDate = GameTimeManager:GetTimeLengthDate(now)
        if self.saveData.m_notify.day ~= currentDate.d then
            self.saveData.m_notify.offlineTimes = 0
            self.saveData.m_notify.day = currentDate.d
            self.saveData.m_notify.lastOfflineTime = 0
            return
        end
    else
        return
    end
    --每天只提醒前两次
    local offLineTime = OFFLINE_TIME * 60
    local notifyTime = self.saveData.m_notify.offlineTimes or 0
    if notifyTime>0 then
        --进游戏的时间距离上次提示少于一定时间，那就是没有触发成功，则不计次数
        local lastOfflineTime = self.saveData.m_notify.lastOfflineTime or 0
        if now-lastOfflineTime<offLineTime then
            notifyTime = notifyTime-1
            self.saveData.m_notify.offlineTimes = notifyTime
            self.saveData.m_notify.lastOfflineTime = 0
            LocalDataManager:WriteToFile()
            printf("还原副本离线提示次数,当前已用次数为"..self.saveData.m_notify.offlineTimes)
        end
    end
end

---获取本副本的蓝图Manager
function CycleNightClubModel:GetBluePrintManager()
    return CycleNightClubBluePrintManager
end

--蓝图是否能升级或材料是否能合成
function CycleNightClubModel:CheckBlueprintTip()
    return CycleNightClubBluePrintManager:CanUpgradeAnyProduction() or CycleNightClubBluePrintManager:CanCombineAnyRes()
end

---override 奖励金钱 每分钟数额(拉霸机，广告等)
function CycleNightClubModel:GetRewardInComePerMinute()
    return self:GetInComePerMinute()
end

---返回引导是否完成
--function CycleNightClubModel:IsGuideCompleted(guideID)
    --TODO  所有引导视为已完成
    --return true
--end

return CycleNightClubModel