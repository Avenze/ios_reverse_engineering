---@class HouseMode
local HouseMode = GameTableDefine.HouseMode
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

local UnityHelper = CS.Common.Utils.UnityHelper
local TweenUtil = CS.Common.Utils.DotweenUtil

local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

function HouseMode:OnEnter(cfg, go) -- config_Building, go
    self.m_carData = {}
    self.m_bCfg = cfg
    self.m_hCfg = CfgMgr.config_house[self.m_bCfg.id]
    self.m_go = go
    self.m_timeGo = self:GetScene():GetGo(self.m_go, "Timeline")
    --K117 打开豪宅场景时如果有Light节点，关掉主摄像机后处理
    local lightGO = self:GetLight()
    if lightGO then
        FloorMode:GetScene():ControlGlobalVolumeDisp(false)

        GameTableDefine.LightManager:SetBuildingLight(lightGO)
    end

     --2022-12-9添加用于timelie整合换装的功能实现
    GameTableDefine.DressUpDataManager:ChangeTimelineActorDressUp(self.m_timeGo)
    self.m_selectCarId = nil

    self:SetCurrentFloorIndex(1, true)
    if self.m_bCfg and self.m_bCfg.buyhouse_timeline then
        local buyHouseFloor = self.m_bCfg.buyhouse_timeline
        --设置进入买房场景后显示的楼层
        self:SetCurrentFloorIndex(buyHouseFloor)
    end
    MainUI:SetHouseIndex(self:GetCurrentFloorIndex(), self)

    local data = self:GetLocalData(self.m_bCfg.id)
    if not data or not data.cp then
        --K117 进入豪宅后，去掉Open Tip
        GameTableDefine.CityMode:MarkComeToBuilding(cfg.id)

        self.m_salespersonData = {} -- 销售人员数据
        self.m_salespersonData.go = self:GetScene():GetGo(self.m_go, "Salesperson")
        FloatUI:SetObjectCrossCamera(self.m_salespersonData, function(view)
            if view then
                view:Invoke("ShowEventBumble", 1, function()
                    HouseContractUI:ShowPanel(self.m_hCfg)
                end)
            end
        end)
        TalkUI:OpenTalk("enter_house",{
            firstCome = self:CheckFirst(),
            placeName = GameTextLoader:ReadText("TXT_BUILDING_B" .. self.m_bCfg.id .. "_NAME"),
            garageHold = self:GetScene():GetTrans(self.m_go, "GuideLocation")
        })
        self:GetScene():GetGo(self.m_go, "People/Boss/"..LocalDataManager:GetBossSkin()):SetActive(true)
        GameTableDefine.DressUpDataManager:ChangeTimelineActorDressUp(self.m_go)
    else
        self:GetScene():GetGo(self.m_go, "Salesperson"):SetActive(false)
        self:InitCarPort()
    end
    self.m_timeGo:SetActive(false)
end

function HouseMode:OnUpdate()
end

function HouseMode:OnExit()
    if self.m_salespersonData then
        FloatUI:RemoveObjectCrossCamera(self.m_salespersonData)
    end
    for k,v in pairs(self.m_carData or {}) do
        FloatUI:RemoveObjectCrossCamera(v)
    end
    local lightGO = self:GetLight()
    if lightGO then
        GameTableDefine.LightManager:SetBuildingLight(nil)
    end
    self.m_salespersonData = nil
    self.m_bCfg = nil
    self.m_go = nil
    self.m_floorIndex = nil
    self.m_localData = nil
    self.m_carData = nil
    self.m_selectCarId = nil
end

function HouseMode:GetScene()
    return FloorMode:GetScene()
end

function HouseMode:GetLocalData(id)
    local ByIdFun = function()
        if not id then
            return self.m_localData
        end
        for i,v in pairs(self.m_localData  or {}) do
            if id == v.id then
                return v
            end
        end
    end
   
    if self.m_localData then
        return ByIdFun()
    end
    -- 初始化:
    local data = LocalDataManager:GetDataByKey("houses")
    if not data.d then
        data.d = {}
        data.f = true
    end
    self.m_localData = data.d
    return ByIdFun()
end

function HouseMode:GetTempCarPort(init)
    local data = LocalDataManager:GetDataByKey("houses")
    if init and not data.t then
        data.t = {}
    end
    return data.t
end

function HouseMode:DelTempCarPort()
    local data = LocalDataManager:GetDataByKey("houses")
    data.t = nil
    LocalDataManager:WriteToFile()
end

function HouseMode:CheckFirst()
    local data = LocalDataManager:GetDataByKey("houses")
    local first = data.f
    data.f = nil
    LocalDataManager:WriteToFile()
    return first
end

function HouseMode:GetCurrentFloorIndex()
    return self.m_floorIndex or 1
end

function HouseMode:GoUpstairs()
    self:SetCurrentFloorIndex(self:GetCurrentFloorIndex() + 1)
end

function HouseMode:GoDownstairs()
    self:SetCurrentFloorIndex(self:GetCurrentFloorIndex() - 1)
end

function HouseMode:SetCurrentFloorIndex(index, isInit, cb)
    if self.m_hCfg.floor_num <= 1 then
        return
    end

    if isInit then
        for i=1,self.m_hCfg.floor_num do
            if i ~= 1 then
                local floorDefGo = HouseMode:GetScene():GetGo(self.m_go, i.."F").gameObject
                UnityHelper.IgnoreRenderer(floorDefGo, true)
            end
        end
        self.m_floorIndex = 1
        return
    end

    index = math.min(math.max(1, index), self.m_hCfg.floor_num)
    if self.m_floorIndex == index then
        return
    end
    local last = self.m_floorIndex
    self.m_floorIndex = index
    self:SwitchFloorIndex(last, cb)
end

function HouseMode:SwitchFloorIndex(lastFloorIndex, cb)
    if lastFloorIndex then
        local floorDefGo = HouseMode:GetScene():GetGo(self.m_go, lastFloorIndex.."F") 
        UnityHelper.IgnoreRenderer(floorDefGo, true)
    end
    local index = self:GetCurrentFloorIndex()
    local floorDefGo = HouseMode:GetScene():GetGo(self.m_go, index.."F")
    UnityHelper.IgnoreRenderer(floorDefGo, false)
    MainUI:SetHouseIndex(self:GetCurrentFloorIndex(), self)
    HouseMode:GetScene():SetCameraCapsule(floorDefGo.transform.position, cb)
end

function HouseMode:BuyHouse(cb)
    local num = self.m_hCfg.price
    ResMgr:SpendCash(num, nil, function(result)
        if cb then cb(result) end
        if not result then
            --购买失败
            return
        end

        local data = HouseMode:GetLocalData()
        local d = {id = self.m_hCfg.id, cp = {}}
        local temp_car = nil
        local temp_from = nil
        local tempData = self:GetTempCarPort()
        if tempData then
            temp_car = tempData.car
            temp_from = tempData.from
            self:DelTempCarPort()
        end

        for i,v in ipairs(self.m_hCfg.garage or {}) do
            table.insert(d.cp, {id = v, car = temp_car, from = temp_from})
            temp_car = nil
            temp_from = nil
        end
        table.insert(data, d)

        local houseCfg = CfgMgr.config_buildings[d.id] or {}
        local value = houseCfg.wealth_buff or 0
        ForbesRewardUI:SetCfg(houseCfg)

        ValueManager:GetValue(true)
        -- GameSDKs:Track("buy_house", {house_id = d.id, star_num = StarMode:GetStar(), left_cash =  ResMgr:GetCash()})
        GameSDKs:TrackForeign("asset_buy",{type = 1, id = d.id, star_new= tonumber(StarMode:GetStar())})
        --2023增加运营要求的af埋点，第一个房产购买
        if d.id == 10001 then
            -- GameSDKs:Track("af_house_first", {buildingID = d.id})
            GameSDKs:TrackControl("af", "af,af_house_first", {af_buildingID = d.id})
            GameSDKs:TrackControl("af", "af,assetbuy_house_10001", {})
        end
        if d.id == 10002 then
            GameSDKs:TrackControl("af", "af,assetbuy_house_10002", {})
        end
        if d.id == 10003 then
            GameSDKs:TrackControl("af", "af,assetbuy_house_10003", {})
        end
         --2024-8-20添加的钞票消耗埋点上传
         local type = GameTableDefine.CountryMode:GetCurrCountry()
         local amount = num
         local change = 1
         local position = "["..d.id.."]号房产购买"
         GameSDKs:TrackForeign("cash_event", {type_new = tonumber(type) or 0, change_new = tonumber(change) or 0, amount_new = tonumber(amount) or 0,position = position})
        --LocalDataManager:WriteToFile()
        
        FloatUI:RemoveObjectCrossCamera(self.m_salespersonData)
        self.m_salespersonData = nil
        self:InitCarPort()
        ChatEventManager:ConditionToStart(10, self.m_hCfg.id)
    end)
end

function HouseMode:noHouse()
    local data = self:GetLocalData()
    return #data == 0
end

function HouseMode:OwnHouse(houseId)
    local data = self:GetLocalData()
    for k,v in pairs(data) do
        if v.id == houseId then
            return 1
        end
    end

    return 0
end

function HouseMode:SellCarFromGarage(garageId)
    local data = HouseMode:GetLocalData()
    if #data == 0 then
        return
    end

    for k,v in ipairs(data or {}) do
        for i, cp in ipairs(v.cp or {}) do
            if cp.id == garageId then
                cp.car = nil
                cp.from = nil
            end
        end
    end

    ValueManager:GetValue(true)
end

---是否不存在车位存档
function HouseMode:NotHavePort(housePortList,id)
    for i,v in ipairs(housePortList) do
        if v.id == id then
            return false
        end
    end

    return true
end

function HouseMode:GetIdleCarPort()
    local data = HouseMode:GetLocalData()
    if #data == 0 then
        return self:GetTempCarPort(true)
    end
    for k,v in ipairs(data or {}) do
        for i,cp in ipairs(v.cp or {}) do
            if not cp.car then
                return cp, cp.id--cp和车库id
            end
        end
        --K119 豪宅车位要跟随配置增加
        local houseCfg = CfgMgr.config_house[v.id]
        for portIndex,portID in ipairs(houseCfg.garage) do
            if self:NotHavePort(v.cp,portID) then
                local cp = {id = portID}
                table.insert(v.cp,cp)
                return cp,portID
            end
        end
    end
    return nil
end

function HouseMode:BoughtHouse()
    self.m_timeGo:SetActive(true)
    SoundEngine:SetTimeLineVisible(true)
    local timeLine = self.m_timeGo:GetComponent("PlayableDirector")
    local TLCamera = UnityHelper.GetTheChildComponent(self.m_timeGo, "CameraCG", "Camera")
    if TLCamera then
        UnityHelper.SetCameraRenderType(TLCamera, 1)
        UnityHelper.AddCameraToCameraStack(GameUIManager:GetSceneCamera(), TLCamera, 0)
    end
    EventManager:RegEvent("CMD_HOUSE_TL_END", function(go)
        if TLCamera then
            UnityHelper.RemoveCameraFromCameraStack(GameUIManager:GetSceneCamera(), TLCamera)

            -- local succ, position = self:GetScene():GetSceneGroundPosition(TLCamera.transform.position)
            -- self:GetScene():LocateSpecialBuildingTarget(TLCamera.transform.position)
        end
        self.m_timeGo:SetActive(false)
        GameUIManager:SetEnableTouch(true)

        --f GameConfig:IsIAP() then
            ForbesRewardUI:OpenSimple(function()
                IntroduceUI:ValueImprove(function()
                    TalkUI:OpenTalk("house_bought")
                end)
            end)
        -- else
        --     TalkUI:OpenTalk("house_bought")
        -- end

        EventManager:UnregEvent("CMD_HOUSE_TL_END")
        SoundEngine:SetTimeLineVisible(false)
    end)
    if self.m_bCfg.buyhouse_timeline then
        local buyHouseFloor = self.m_bCfg.buyhouse_timeline
        --买房后后显示的楼层
        self:SetCurrentFloorIndex(buyHouseFloor)
    end
    timeLine:Play()
    GameUIManager:SetEnableTouch(false)
end

function HouseMode:InitCarPort()
    local hoseData = self:GetLocalData(self.m_bCfg.id)
    if not hoseData then
        return
    end

    for i,v in ipairs(hoseData.cp or {}) do
        if v.car then
            self:CreateCarGo(v.car, i, v.from, v.id)
        end
    end
end

function HouseMode:CreateCarGo(id, index, buyFrom, garageId)
    local carData = CfgMgr.config_car[id]
    local shopData = CfgMgr.config_carshop[buyFrom]
    local data = {id = id, num = 1, price = shopData.cars[id].price, value = carData.wealth_buff}


    -- local carData = CfgMgr.config_car[id]

    -- local shopData = CfgMgr.config_carshop[buyFrom]
    -- local data = {id = id, num = 1, price = shopData.cars[id].price}

    -- local ShowDetails = function(check)
    --     if self.m_carData[garageId] and self.m_carData[garageId].view then
    --         if self.m_selectCarId and self.m_carData[self.m_selectCarId] and self.m_carData[self.m_selectCarId].view then--有选过的就隐藏上一个选过的
    --             self.m_carData[self.m_selectCarId].view:Invoke("ShowCarPortBumble", nil ,nil, false)
    --         end
    --         self.m_selectCarId = garageId
    --         self.m_carData[garageId].view:Invoke("ShowCarPortDetails")--再打开详细信息
    --         self:GetScene():LocateSpecialBuildingTarget(self.m_carData[garageId].go.transform.position)
    --     end
    -- end

    local showDetail = function(check)
        if self.m_carData[garageId] and self.m_carData[garageId].view then
            self.m_carData[garageId].view:Invoke("RefreshCarPortBumble", true, self.m_carData[garageId].carId)
            
        end

        if self.m_carData[self.m_selectCarId] and self.m_carData[self.m_selectCarId].view then
            self.m_carData[self.m_selectCarId].view:Invoke("RefreshCarPortBumble", false)
            self.m_selectCarId = nil
            return
        end
        self.m_selectCarId = garageId

    end

    local sellCar = function()
        BuyCarManager:Sell(id, buyFrom, garageId)
        --local doPath = self:GetScene():GetGo(self.m_go, "Garage/pos" .. index)
        --TweenUtil.PlayDoPath(doPath)
        local addCash = math.floor(data.price * CfgMgr.config_global.car_sell_price)
        --新增一个FloatUI用来显示卖车的钱
        local sellPos = {go = self.m_carData[garageId].go}
        FloatUI:SetObjectCrossCamera(sellPos, function(view)
            if view then
                view:Invoke("ShowCashDisplay",addCash,self.m_carData[garageId].carGO)
            end
        end)
        local sellCarFX = self:GetScene():GetGoOrNul(self.m_go, "Garage/pos" .. index.."/FX_sellcar")
        if sellCarFX then
            sellCarFX:SetActive(false)
            sellCarFX:SetActive(true)
        end
    end

    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/Prefabs/Vehicles/" .. carData.pfb .. ".prefab", self:GetScene(), function(go)
        go.name = carData.pfb
        local rootGo = self:GetScene():GetGo(self.m_go, "Garage/pos" .. index)
        UnityHelper.AddChildToParent(rootGo.transform, go.transform)

        self.m_carData[garageId] = {go = rootGo, carId = id,carGO = go}
        FloatUI:SetObjectCrossCamera(self.m_carData[garageId], function(view)
            if view then
                view:Invoke("InitCarPortBumbel", data, showDetail, self.m_selectCarId == garageId, sellCar)
            end
        end, nil, carData.pfb .. "/car", false)
        self:GetScene():SetButtonClickHandler(rootGo, showDetail)--点击车辆
        self:GetScene():SetButtonClickHandler(self:GetScene():GetGo(self.m_go, "GuideLocation"), function()--点击地板
            if self.m_carData[self.m_selectCarId] and self.m_carData[self.m_selectCarId].view then
                self.m_carData[self.m_selectCarId].view:Invoke("RefreshCarPortBumble", false)
            end
            self.m_selectCarId = nil
        end)
    end)
end

---获取Light节点
function HouseMode:GetLight()
    local scene = self:GetScene()
    if scene then
        return scene:GetGoOrNul(self.m_go,"Light")
    else
        return nil
    end
end