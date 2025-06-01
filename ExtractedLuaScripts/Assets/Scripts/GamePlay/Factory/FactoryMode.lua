
---@class FactoryMode
local FactoryMode = GameTableDefine.FactoryMode
local MainUI = GameTableDefine.MainUI
local FloorMode = GameTableDefine.FloorMode
local FloatUI = GameTableDefine.FloatUI
local HouseContractUI = GameTableDefine.HouseContractUI
local ResMgr = GameTableDefine.ResourceManger
local CfgMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local TalkUI = GameTableDefine.TalkUI
local BuyCarManager = GameTableDefine.BuyCarManager
local ChatEventManager = GameTableDefine.ChatEventManager
local SoundEngine = GameTableDefine.SoundEngine
local StarMode = GameTableDefine.StarMode
local ValueManager = GameTableDefine.ValueManager
local ForbesRewardUI = GameTableDefine.ForbesRewardUI
local IntroduceUI = GameTableDefine.IntroduceUI
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local OrderUI = GameTableDefine.OrderUI
local GuideUI = GameTableDefine.GuideUI
local GuideManager = GameTableDefine.GuideManager
local TimerMgr = GameTimeManager

local BaseScene = require("Framework.Scene.BaseScene")

local UnityHelper = CS.Common.Utils.UnityHelper
local TweenUtil = CS.Common.Utils.DotweenUtil

local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local Factory_RECORD = "factory"

--进入时
function FactoryMode:OnEnter(cfg, go)
    --进入工厂MainUI的变化
    MainUI:EnterFactorySetUI()

    self:Init(cfg, go)

    self.m_orderData = OrderUI:GetOrderData()

    --为车间节点赋值,创建出建造模型地标
    for k, v in pairs(self.m_workShopCfg) do
        local workShop = self:GetWorkShopRoot(k)
        if not self.m_workShopRoots then
            self.m_workShopRoots = {}
        end
        self.m_workShopRoots[k] = workShop
    end

    --重置时间
    --self:ResetToZero()

    --根据存档刷新所有工厂的状态
    self:RefreshFactory()

    --订单停车场按钮事件绑定
    self:RefreshParkingLot()

    --对工厂中在生产的东西进行实时的计算
    self:Updata()

    --对话
    --TalkUI:OpenTalk("shop_npc")
    --新手引导--在没有一号工厂的时候
    if not self.m_factoryDate[self.m_cfg.mode_name]["10001"] then
        GuideManager.currStep = 600
        GuideManager:ConditionToStart()
        GuideManager:ConditionToEnd()
    end
    --GuideManager:ConditionToEnd()

end
--退出时
function FactoryMode:OnExit()
    -- FloatUI:RemoveObjectCrossCamera(uglyCode)
    for k, v in pairs(self.m_floatUI) do
        FloatUI:RemoveObjectCrossCamera(v)
    end
    FloatUI:RemoveObjectCrossCamera(self.m_floatUI["OrderArea"])
    self.m_floatUI = {}
    self.m_workShopRoots = nil
    --MainUI:ExitFactorySetUI()
end
--初始化工厂的信息
function FactoryMode:Init(cfg, go)
    --初始化数据
    self.m_cfg = cfg
    self.m_go = go
    if not cfg then
        self.m_cfg = CfgMgr.config_buildings[40001]
    end
    --self.init()
    self.m_workShopCfg = CfgMgr.config_workshop
    --工厂节点数组
    self.m_workShopRoots = nil
    --工厂UI数组
    self.m_showFactoryBumble = {}
    --工厂updata
    self.updata = nil

    self.m_floatUI = {}

    self.m_cfgProducts = CfgMgr.config_products

    self.m_factoryDate = LocalDataManager:GetCurrentRecord()["factory"]
end

--刷新所有工厂的信息
function FactoryMode:RefreshFactory()
    for k, v in pairs(self.m_workShopCfg) do
        self:RefreshWorkshop(k)
    end
end

--刷新单个车间的信息
function FactoryMode:RefreshWorkshop(workShopid)

    ---K125 因未知原因(FloatUI的Timer没Stop)在办公楼场景会调用到，导致报错，所以加一个容错
    if not self.m_workShopRoots then
        return
    end

    local workShopRoot = self.m_workShopRoots[workShopid]
    local UIPosition = self:GetScene():GetGo(workShopRoot, "UIPosition")
    local Unlockablebtn = self:GetScene():GetGo(workShopRoot, "unlockable_btn")
    local RoomBox = self:GetScene():GetGo(workShopRoot, "roombox")

    --没有存档时,表示没有修建
    if not self:GetWorkShopdata(workShopid) then
        self:GetScene():GetGo(workShopRoot, "model"):SetActive(false)
        Unlockablebtn:SetActive(self:UnlockRoomState(workShopid))
        RoomBox:SetActive(self:UnlockRoomState(workShopid))

        self:GetScene():SetButtonClickHandler(
            RoomBox,
            function()
                GameTableDefine.WorkShopUnlockUI:DisplayInformation(workShopid)
                --无效需要修改
                self:LookAtWorkShop(workShopid)
            end
        )

        --金钱消耗为0时自动生成
        if self.m_workShopCfg[workShopid].unlock_cash[1] == 0 then
            local theFactory = self.m_factoryDate[self.m_cfg.mode_name]
            theFactory[tostring(workShopid)] = {}
            self:Build(workShopid)
        end
    elseif self:GetWorkShopdata(workShopid)["state"] == 0 then --修建中
        self:GetScene():GetGo(workShopRoot, "model"):SetActive(false)
        Unlockablebtn:SetActive(false)

        local timeWait = self:GetWorkShopdata(workShopid)["timePoint"] + self.m_workShopCfg[workShopid].unlock_times
        self:GetScene():SetButtonClickHandler(
            RoomBox,
            function()
                self:LookAtWorkShop(workShopid)
            end
        )
        self:RefreshFloatUI(
            workShopid,
            workShopRoot,
            "ShowFactoryUnlockButtton",
            "model/workshop/group14_polySurface8974",
            timeWait
        )

    elseif self:GetWorkShopdata(workShopid)["state"] == 1 then --待机闲置状态
        self:GetScene():GetGo(workShopRoot, "model"):SetActive(true)
        Unlockablebtn:SetActive(false)

        self:GetScene():SetButtonClickHandler(
            RoomBox,
            function()
                WorkShopInfoUI:WorkShopInfoInit(workShopid)
                self:LookAtWorkShop(workShopid)
                self:PlayWorkShopSound(self.m_workShopCfg[workShopid]["room_category"][2])
            end
        )
        self:RefreshFloatUI(workShopid)
    elseif self:GetWorkShopdata(workShopid)["state"] == 2 then --工作状态
        self:GetScene():GetGo(workShopRoot, "model"):SetActive(true)
        Unlockablebtn:SetActive(false)
        --self:RefreshFloatUI(workShopid, workShopRoot, "ParkingLotBabo", "model/SM_Bld_Shop_01")
        self:RefreshFloatUI(workShopid, workShopRoot, "ShowFactoryBumble", "group14_polySurface8974")
        self:GetScene():SetButtonClickHandler(
            RoomBox,
            function()
                WorkShopInfoUI:WorkShopInfoInit(workShopid)
                self:LookAtWorkShop(workShopid)
                self:PlayWorkShopSound(self.m_workShopCfg[workShopid]["room_category"][2])
            end
        )
    else
    end
    --检查引导
    --GuideManager:ConditionToStart()
end

--刷新(初始化)停车场(订单区)
function FactoryMode:RefreshParkingLot()
    local parkingLotBox = self:GetScene():GetGo(self.m_go, "OrderArea")
    self.m_floatUI["OrderArea"] = {}
    self.m_floatUI["OrderArea"].go = parkingLotBox
    self:CheckParkingLotBoxHint()
    self:GetScene():SetButtonClickHandler(
        parkingLotBox,
        function()
            OrderUI:GetView()
            self:LookAtParkingLot()
        end
    )
    self:ShowCallCar()
end

function FactoryMode:GetScene()
    return FloorMode:GetScene()
end

--获取所有的车间根节点 m_worShopRoots
function FactoryMode:SetAllWorkShopRoots()
    for i = 1, Tools:GetTableSize(self.m_workShopCfg) do
        local NEWNUM = i + 10000
        self.m_workShopRoots[i] = self:GetWorkShopRoot(NEWNUM)
    end
end

--通过id获得车间根节点
function FactoryMode:GetWorkShopRoot(workShopid)
    local rootName = self.m_workShopCfg[workShopid].object_name
    return self:GetScene():GetGo(self.m_go, rootName)
end

--建造这个车间
function FactoryMode:Build(workShopid)
    local workShopdata = self:GetWorkShopdata(workShopid)
    if workShopdata.state ~= 2 then
        workShopdata.state = 1
    end
    if not workShopdata.Lv then
        workShopdata.Lv = 0
    end
    workShopdata.Lv = workShopdata.Lv + 1

    GameSDKs:TrackForeign("factory_build_upgrade", {id = workShopid, level_new = tonumber(workShopdata.Lv) or 0}) --工厂升级(建造)埋点
    LocalDataManager:WriteToFile()
    --刷新MainUI显示
    MainUI:RefreshLicenseState()
    --解锁新的建筑后需要刷新被他解锁的工厂--(因为需要刷新前置解锁所以需要全刷)
    self:RefreshFactory()
    --self:RefreshWorkshop(workShopid)
end

--判断当前车间能否解锁和升级
function FactoryMode:CanUnlock(workShopid)
    local workShopdata = self:GetWorkShopdata(workShopid)
    local notBuy = true
    local workShopLv = 0
    if not workShopdata then
    else
        notBuy = false
        workShopLv = workShopdata["Lv"]
    end
    local unlockCash = self.m_workShopCfg[workShopid].unlock_cash[workShopLv + 1]
    local unlockLicense = self.m_workShopCfg[workShopid].unlock_license[workShopLv + 1]
    local unlockRoom = self.m_workShopCfg[workShopid].unlock_room

    local unlockRoomState = not notBuy or self:UnlockRoomState(workShopid)

    if unlockCash <= ResMgr:GetCash() and unlockCash then
        if unlockLicense <= ResMgr:GetLicense() and unlockLicense then
            if unlockRoomState then
                return true
            end
        end
    else
        return false
    end
end

--前置解锁房间是否存在
function FactoryMode:UnlockRoomState(workShopid)
    local unlockRoom = self.m_workShopCfg[workShopid].unlock_room
    if unlockRoom == 0 then
        return true
    end
    local unlockRoomState = false
    if self:GetWorkShopdata(unlockRoom) then
        local unlockWSData = self:GetWorkShopdata(unlockRoom)
        if unlockWSData["Lv"] then
            unlockRoomState = true
        end
    end
    return unlockRoomState
end

--通过id获取车间的存档数据
function FactoryMode:GetWorkShopdata(workShopid)
    if not self.m_factoryDate or Tools:GetTableSize(self.m_factoryDate) == 0 then return nil end
    local theFactory = self.m_factoryDate[self.m_cfg.mode_name]

    local workShopName = tostring(workShopid)
    local shopdata = theFactory[workShopName]

    if not shopdata then
        return nil
    else
        return shopdata
    end
end

--获取当前工厂的存档
function FactoryMode:GetTheFactoryData()
    if not self.m_factoryDate or Tools:GetTableSize(self.m_factoryDate) == 0 then return nil end
    local theFactory = self.m_factoryDate[self.m_cfg.mode_name]
    return theFactory
end


-- 将视角移到指定车间
function FactoryMode:LookAtWorkShop(workShopId)
    self:GetScene():LocatePosition(self.m_workShopRoots[workShopId].transform.position, true)
    -- self:GetScene():SetCameraCapsule(self.m_workShopRoots[workShopId].transform.position)
end
--将视角移动到停车场
function FactoryMode:LookAtParkingLot()
    local parkingLotBox = self:GetScene():GetGo(self.m_go, "OrderArea")
    self:GetScene():LocatePosition(parkingLotBox.transform.position, true)
end
--送货动画
function FactoryMode:PlaySendCarFB(workshopId)
    if not self.m_workShopRoots then
        return
    end
    local Root = self.m_workShopRoots[workshopId]
    local feel = self:GetScene():GetComp(Root, "SendCarFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end
--进货动画
function FactoryMode:PlayCallCarFB(workshopId)
    if not self.m_workShopRoots then
        return
    end
    local Root = self.m_workShopRoots[workshopId]
    local feel = self:GetScene():GetComp(Root, "CallCarFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end
--完成订单动画
function FactoryMode:PlayOrderSendCarFB(OrderNum)
    local Root = self:GetScene():GetGoOrNul(self.m_go, "OrderArea/pos" .. OrderNum)
    if not Root then
        return
    end
    local feel = self:GetScene():GetComp(Root, "SendCarFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end
--生成订单动画
function FactoryMode:PlayOrderCallCarFB(OrderNum)
    if not self.m_go or self.m_go == nil then
        return
    end
    if self:GetScene() == nil then
        return
    end    
    local feel = self:GetScene():GetComp(self.m_go, "OrderArea/pos" .. OrderNum ..  "/CallCarFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end
--播放升级工厂的动画
function FactoryMode:PlayUpGreatFacFB(workshopId)
    if not self.m_workShopRoots then
        return
    end
    local Root = self.m_workShopRoots[workshopId]
    local feel = self:GetScene():GetComp(Root, "UIPosition/upgradeFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end
--显示一个订单的节点
function FactoryMode:ShowCallCar()
    for k, v in pairs(self.m_orderData) do
        if type(v) == "table" then
            if v["timePoint"] <= TimerMgr:GetCurrentServerTime(true) then
                local Root = self:GetScene():GetGoOrNul(self.m_go, "OrderArea/pos" .. tonumber(k) .. "/SendTruck")
                if Root == nil then
                    return
                end
                Root:SetActive(true)
            end
        end
    end
end
--隐藏一个订单的节点
function FactoryMode:HiddenSendCar()
    for k, v in pairs(self.m_orderData) do
        if type(v) == "table" then
            if v["timePoint"] >= TimerMgr:GetCurrentServerTime(true) then
                local Call = self:GetScene():GetGoOrNul(self.m_go, "OrderArea/pos" .. tonumber(k) .. "/CallTruck")
                local Send = self:GetScene():GetGoOrNul(self.m_go, "OrderArea/pos" .. tonumber(k) .. "/SendTruck")
                if Call == nil then
                    return
                end
                Call:SetActive(false)
                Send:SetActive(false)
            end
        end
    end
end
--刷新生成悬浮UI
function FactoryMode:RefreshFloatUI(id, go, funcName, attmat, timeWait)
    local workShopData = self:GetWorkShopdata(id)

    -- if workShopData.state == 0 then
    --     FloatUI:RemoveObjectCrossCamera(self.m_floatUI[id])
    -- else
    if workShopData.state == 2 or workShopData.state == 0 then
        if not self.m_floatUI[id] then
            self.m_floatUI[id] = {}
            self.m_floatUI[id].go = go
        end
        FloatUI:SetObjectCrossCamera(self.m_floatUI[id], function(view)
            if view then
                view:Invoke(funcName, self.m_workShopCfg[id], timeWait)
            end
        end, nil, attmat)
    elseif self.m_floatUI[id] then
        FloatUI:RemoveObjectCrossCamera(self.m_floatUI[id])
    end
end
--播放进入房间的音乐
function FactoryMode:PlayWorkShopSound(type)
    if type == 101 then
        SoundEngine:PlaySFX(SoundEngine.FACTORY1_SFX)
    elseif type == 102 then
        SoundEngine:PlaySFX(SoundEngine.FACTORY2_SFX)
    elseif type == 103 then
        SoundEngine:PlaySFX(SoundEngine.FACTORY3_SFX)
    elseif type == 104 then
        SoundEngine:PlaySFX(SoundEngine.FACTORY4_SFX)
    end
end
--停车场悬浮气泡的UI
function FactoryMode:CheckParkingLotBoxHint()
    if OrderUI:AnyOrderCanFinish() then
        if not self.m_floatUI["OrderArea"] then
            return
        end
        FloatUI:SetObjectCrossCamera(
            self.m_floatUI["OrderArea"],
            function(view)
                if view then
                    view:Invoke("ParkingLotBabo")
                end
            end,
            nil,
            "model/SM_Bld_Shop_01"
        )
    elseif self.m_floatUI["OrderArea"] then
        FloatUI:RemoveObjectCrossCamera(self.m_floatUI["OrderArea"])
    end
end
------------------------- 离线收益的计算 ----------------------
function FactoryMode:PiecewiseCalculation(pastTime, check, cb)
    local thread = coroutine.create(function ( a, b )
        local addList = {}
        if not self.m_factoryDate then
            return
        end
        self.m_addList = nil
        if not pastTime then
            --pastTime = GameTableDefine.OfflineRewardUI:LeaveTime()
            pastTime = GameTableDefine.OfflineManager.m_offline
        end
        if pastTime < 30 then
            return
        end
        local Times = 10
        for i = 1, Times do
            self:OfflineOutput(pastTime / Times, check)
        end
        if not check then
            self:ResetToZero()
        end
        for k,v in pairs(self.m_addList or {}) do
            addList[k] = v
        end
        self.m_addList = nil
        if cb then
            cb(addList)
        end
    end)
    coroutine.resume(thread)
end


function FactoryMode:OfflineOutput(pastTime, check)
    if not self.m_factoryDate or Tools:GetTableSize(self.m_factoryDate) == 0 then
        return
    end
    --local productData = WorkShopInfoUI:GetProductsData()
    local list = {}
    local factoryDate = {}
    for k,v in pairs(self.m_factoryDate[self.m_cfg.mode_name]) do
        local curr = {}
        for i,o in pairs(v) do
            curr[i] = v[i]
        end
        curr.factoryId = k
        curr.weight = FactoryMode:GetWeight(v.productId)
        table.insert(factoryDate, curr)
    end
    table.sort(factoryDate, function(a, b)
        return a.weight < b.weight
    end)

    for k, v in ipairs(factoryDate) do
        local productId = v["productId"]
        local productCfg = self.m_cfgProducts[productId]
        if v["state"] == 2 then
            local addSpeed = 1 / self:GetSpeed(v.factoryId)
            if not list[productId] then
                list[productId] = 0
            end
            if not WorkShopInfoUI:EnoughPartsToProduce(productId) then
                local canhold = true
                for i,s in pairs(productCfg.need_product) do
                    if not list[s.type] or list[s.type] - addSpeed * s.num < 0 then
                        local curNum = WorkShopInfoUI:GetProductNum(s.type)
                        if curNum < s.num then
                        --if not productData[tostring(s.type)] or productData[tostring(s.type)] < s.num then
                            if check then
                                if not self.m_addList or not self.m_addList[s.type] or self.m_addList[s.type] < s.num then
                                    canhold = false
                                end
                            else
                                canhold = false
                            end
                        end
                    end
                end
                if canhold then
                    list[productId] = list[productId] + addSpeed
                    for i,s in pairs(productCfg.need_product) do
                        list[s.type] = list[s.type] - addSpeed * s.num
                    end
                end
            else
                list[productId] = list[productId] + addSpeed
                for i, s in pairs(productCfg["need_product"]) do
                    if s["type"] == 0 then
                        break
                    end
                    if not list[s["type"]] then
                        list[s["type"]] = 0
                    end
                    list[s["type"]] = list[s["type"]] - addSpeed * s["num"]
                end
            end
        end
    end
    self:CalculationTime(list, pastTime, check)
end

function FactoryMode:CalculationTime(list, pastTime, check)
    local type
    local timeing = nil
    local buffTimeing = nil
    local liquidationtimeing = nil
    local totalSpeed = 0
    --local ProductsData = WorkShopInfoUI:GetProductsData()
    local currentLimit = WorkShopInfoUI:storageLimit()
    for k, v in pairs(list) do
        if v < 0 then
            local productNum = WorkShopInfoUI:GetProductNum(k)
            if timeing == nil or timeing > productNum / -(v) then
                timeing = productNum / -(v)
            end
            --if timeing == nil or timeing > ProductsData[tostring(k)] / -(v) then
            --    timeing = ProductsData[tostring(k)] / -(v)
            --end
        end
        totalSpeed = totalSpeed + v
    end

    if totalSpeed > 0 then
        liquidationtimeing = currentLimit / totalSpeed
    else
        liquidationtimeing = nil
    end
    local timeingList = {buffTimeing or 999999999, timeing or 999999999, liquidationtimeing or 999999999}
    local minTimeing = math.min(table.unpack(timeingList))
    if minTimeing == liquidationtimeing then
        self:Result(list, minTimeing, true , pastTime, check)
    elseif buffTimeing == nil and timeing == nil and liquidationtimeing == nil then
        self:Result(list, nil, false, pastTime, check)
    else
        self:Result(list, minTimeing, false, pastTime, check)
    end
end

function FactoryMode:Result(list, timeing, liquidation, pastTime, check)
    if pastTime <= 5 then return end
    local factoryDate = self.m_factoryDate[self.m_cfg.mode_name]
    local currSecond = self.second or nil
    local needBack = false
    local useTime
    if timeing == nil or timeing >= pastTime then
        useTime = pastTime
    else
        needBack = true
        useTime = timeing
    end
    for k, v in pairs(list) do
        local addNum = useTime * v
        self:CreatAddList(k, addNum)
        if not check then
            if addNum >= 0 then
                WorkShopInfoUI:AddProduct(math.floor(addNum), k)
            else
                addNum = -addNum
                WorkShopInfoUI:SpendProduct(math.floor(addNum), k)
            end

        end
    end
    LocalDataManager:WriteToFile()
    if liquidation or timeing == nil or timeing < 1 then
        needBack = false
    end
    if needBack then
        return self:OfflineOutput(pastTime - timeing, check)
    end
end

function FactoryMode:GetWeight(productId)
    if not productId then
        return 1
    end
    local productCfg = self.m_cfgProducts[productId]
    local weight = 1
    local allWeight = {}
    for k,v in pairs(productCfg.need_product) do
        if v.type == 0 then
            return weight
        else
            allWeight[k] = weight + self:GetWeight(v.type)
        end
    end
    return math.max(table.unpack(allWeight))
end

function FactoryMode:ResetToZero()
    local factoryDate = self.m_factoryDate[self.m_cfg.mode_name]
    for i, v in pairs(factoryDate) do
        if v.state == 2 then
            v.timePoint = TimerMgr:GetCurrentServerTime(true)
        end
    end
    LocalDataManager:WriteToFile()
end

function FactoryMode:CreatAddList(type, num)
    if not self.m_addList then
        self.m_addList = {}
    end
    if not self.m_addList[type] then
        self.m_addList[type] = 0
    end
    self.m_addList[type] = self.m_addList[type] + num
end
------------------------------------------------------

--获得加入效率计算后的此车间生成此零件的时间(CD)
function FactoryMode:GetSpeed(workshopId,productId)
    local workShopData = self:GetWorkShopdata(workshopId)
    local product
    if productId then
        product = self.m_cfgProducts[productId]
    else
        product = self.m_cfgProducts[workShopData["productId"]]
    end
    local originalTime = product["base_time"]
    --基础的数据 1 ,建筑本身等级带来的数据, buff效果带来的数据 
    local buffBonus = self:GetBuff(workshopId) + 1
    --K125 玩家存档错误，等级超出上限，强制变为1级
    local bonusConfigs = self.m_workShopCfg[tonumber(workshopId)]["room_bonus"]
    if workShopData.Lv > #bonusConfigs then
        workShopData.Lv = 1
    end
    local levelBonus = (bonusConfigs[workShopData.Lv] / 100) + 1
    local bonus = levelBonus * buffBonus
    local base_time = originalTime / bonus
    return base_time
end
--获取工厂当前所拥有的加速buff,和buff的时效
function FactoryMode:GetBuff(workshopId)
    local cfgboost = CfgMgr.config_boost
    local workShopData = self:GetWorkShopdata(workshopId)
    if not workShopData.buff then
        workShopData.buff = {}
    end
    LocalDataManager:WriteToFile()
    if not workShopData.buff.type then
        return 0 , TimerMgr:GetCurrentServerTime(true)
    elseif workShopData.buff.timePoint <= TimerMgr:GetCurrentServerTime(true) then
        return 0 , workShopData.buff.timePoint
    else
        return cfgboost[workShopData.buff.type].buff, workShopData.buff.timePoint
    end
end
--检查当前车间的buff是否有效
function FactoryMode:CheckBuffUsefor(workShopData)
    local bool = false
    if not workShopData.buff or Tools:GetTableSize(workShopData.buff) == 0  or workShopData.buff.timePoint <= TimerMgr:GetCurrentServerTime(true) then

    else
        bool = true
    end
    return bool
end

--获取一段时间内的某一个车间的生产量 -- 哪个车间, 时长(可以超出上限)
function FactoryMode:Airdrop(workshopId, duration, cb)
    local workShopData = self:GetWorkShopdata(workshopId)
    local num = 0
    if workShopData.productId and workShopData.state == 2 then
        num = math.floor(duration / self:GetSpeed(workshopId))
        WorkShopInfoUI:AddProduct(num, workShopData.productId, function()

        end, true)
    end
    self:CheckParkingLotBoxHint()
    if  cb then
        cb()
    end
end

--使一个车间获得他的单次产出
function FactoryMode:GetOutput(workshopId)
    local workShopData = self:GetWorkShopdata(workshopId)
    if workShopData.state == 2 then
        local base_time = self:GetSpeed(workshopId)
        local t = workShopData["timePoint"] + base_time - TimerMgr:GetCurrentServerTime(true)
        if t < 0 then
            if not WorkShopInfoUI:EnoughPartsToProduce(workShopData["productId"]) then
                --当仓库没有材料但是车间有装载材料时
                if workShopData.underLoad and workShopData.underLoad == true then
                    WorkShopInfoUI:AddProduct(1, workShopData["productId"], function()
                        workShopData.underLoad = false
                        self:PlaySendCarFB(tonumber(workshopId))
                    end)
                end
            else
                WorkShopInfoUI:ConsumableMaterialGroup(workShopData["productId"], function()
                    self:PlayCallCarFB(tonumber(workshopId))
                    WorkShopInfoUI:AddProduct(1, workShopData["productId"], function()
                        self:PlaySendCarFB(tonumber(workshopId))
                    end)
                end)
            end
            -- 因为存在 t 比 base_time 大好几圈的问题(缺材料恢复,或者爆仓后恢复)所以需要处理
            workShopData["timePoint"] = workShopData["timePoint"] + (base_time) * (math.floor(math.abs(t) / base_time) + 1)
        end
    end
end

--开启工厂产出的实时计算
function FactoryMode:Updata()
    if not self.m_factoryDate or Tools:GetTableSize(self.m_factoryDate) == 0  then
        return
    end
    if self.updata == nil then
        self.updata =
        GameTimer:CreateNewMilliSecTimer(1000, function()
            --MainUI:RefreshFactorytips()
            if WorkShopInfoUI:storageLimit() > 0 then
                for i, v in pairs(self.m_factoryDate[self.m_cfg.mode_name]) do
                    self:GetOutput(i)
                end
            end
        end, true, true)
    end
end
