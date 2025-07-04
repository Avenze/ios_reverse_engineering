---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by chenlongfa.
--- DateTime: 2023/11/2 11:45
---
local Class = require("Framework.Lua.Class")

local UIBaseView = require("Framework.UI.View")
---@class BuyCarShopUIView:UIBaseView
---@field super UIBaseView
local BuyCarShopUIView = Class("BuyCarShopUIView",UIBaseView)
local BuyCarManager = GameTableDefine.BuyCarManager

local BuyCarShopUI = GameTableDefine.BuyCarShopUI
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local Tools = Tools
local ResourceManger = GameTableDefine.ResourceManger
local CountryMode = GameTableDefine.CountryMode
--local HouseMode = GameTableDefine.HouseMode
local GameTextLoader = GameTextLoader
local GameResMgr = require("GameUtils.GameResManager")
local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper
local UnityTime = CS.UnityEngine.Time
local Timer = GameTimer
local UILayer = CS.UnityEngine.LayerMask.NameToLayer("UI")
local TalkUI = GameTableDefine.TalkUI
local ValueManager = GameTableDefine.ValueManager
local HouseMode = GameTableDefine.HouseMode

local EventManager = require("Framework.Event.Manager")
local CarPrefabPath = "Assets/Res/Prefabs/Vehicles/"
local START_COUNT = 5
local ROTATE_SPEED = 60

function BuyCarShopUIView:ctor()
    self.m_closeBtn = nil ---@type UnityEngine.UI.Button
    self.m_resForbesNumText = nil ---@type UnityEngine.UI.Text
    self.m_resCashNumText = nil ---@type UnityEngine.UI.Text
    self.m_resCashIcon = nil ---@type UnityEngine.UI.Image
    self.m_resDiamondNumText = nil ---@type UnityEngine.UI.Text
    --self.m_resCarPortNumText = nil ---@type UnityEngine.UI.Text
    --self.m_resCarPortNumMaxText = nil ---@type UnityEngine.UI.Text

    self.m_shopNameText = nil ---@type UnityEngine.UI.Text -商店名
    self.m_starGOList = nil ---@type UnityEngine.GameObject[]
    self.m_carLogoImage = nil ---@type UnityEngine.UI.Image
    self.m_carNameText = nil ---@type UnityEngine.UI.Text
    self.m_carDesText = nil ---@type UnityEngine.UI.Text
    self.m_forbesText = nil ---@type UnityEngine.UI.Text -福布斯
    self.m_carPivot = nil ---@type UnityEngine.Transform
    --self.m_carModelTrans = nil ---@type UnityEngine.Transform
    self.m_curCarGO = nil ---@type UnityEngine.GameObject
    self.m_carList = nil ---@type UnityEngine.UI.ScrollRectEx

    self.m_ownedCarGO = nil ---@type UnityEngine.GameObject -拥有标识
    self.m_buyBtn = nil ---@type UnityEngine.UI.Button
    self.m_buyPriceText = nil ---@type UnityEngine.UI.Text
    --self.m_leftBtn = nil ---@type UnityEngine.UI.Button
    --self.m_rightBtn = nil ---@type UnityEngine.UI.Button

    self.m_shopConfig = nil
    self.m_shopID = nil ---@type number
    self.m_shopCarConfigList = nil ---按顺序放入CarConfig
    self.m_showCarIndex = 1 ---正在浏览的车在CarConfigList中的Index
    self.m_curShowCarConfig = nil
    self.m_carShopModel = nil ---@type UnityEngine.GameObject 摄像机与车的组合,用于渲染汽车模型到贴图上

    self.m_updateTimer = nil
    self.m_buyCarID = nil ---最后购买车辆的ID
end

function BuyCarShopUIView:OnEnter()
    self.m_buyCarID = nil
    self:LoadCarShopModel()
    self.m_closeBtn = self:GetComp(self.m_uiObj,"RootPanel/shop/quitBtn","Button")
    --res
    self.m_resForbesNumText = self:GetComp(self.m_uiObj,"RootPanel/res/forbes/num","TMPLocalization")
    self.m_resCashNumText = self:GetComp(self.m_uiObj,"RootPanel/res/cash/num","TMPLocalization")
    self.m_resCashIcon = self:GetComp(self.m_uiObj,"RootPanel/res/cash/icon","Image")
    self.m_resDiamondNumText = self:GetComp(self.m_uiObj,"RootPanel/res/diamonds/num","TMPLocalization")
    --self.m_resCarPortNumText = self:GetComp(self.m_uiObj,"RootPanel/res/garage/num/num1","TMPLocalization")
    --self.m_resCarPortNumMaxText = self:GetComp(self.m_uiObj,"RootPanel/res/garage/num/num2","TMPLocalization")
    --title
    self.m_starGOList = {}
    for i = 1, START_COUNT do
        self.m_starGOList[i] = self:GetGo(self.m_uiObj,"RootPanel/info/title/star/"..i.."/fill")
    end
    self.m_carLogoImage = self:GetComp(self.m_uiObj,"RootPanel/info/title/bg/mark","Image")
    self.m_carNameText = self:GetComp(self.m_uiObj,"RootPanel/info/title/bg/text","TMPLocalization")
    self.m_carDesText = self:GetComp(self.m_uiObj,"RootPanel/info/title/desc","TMPLocalization")
    self.m_forbesText = self:GetComp(self.m_uiObj,"RootPanel/info/forbes/num","TMPLocalization")
    self.m_shopNameText = self:GetComp(self.m_uiObj,"RootPanel/shop/bg/text","TMPLocalization")
    self.m_carList = self:GetComp(self.m_uiObj,"RootPanel/info/list","ScrollRectEx")
    --buyButton
    self.m_ownedCarGO = self:GetGo(self.m_uiObj,"RootPanel/btn_area/owned")
    self.m_buyBtn = self:GetComp(self.m_uiObj,"RootPanel/btn_area/btn","Button")
    self.m_buyPriceText = self:GetComp(self.m_uiObj,"RootPanel/btn_area/price/txt","TMPLocalization")
    --left right Button
    --self.m_leftBtn = self:GetComp(self.m_uiObj,"RootPanel/info/left_page","Button")
    --self.m_rightBtn = self:GetComp(self.m_uiObj,"RootPanel/info/right_page","Button")
    --car pivot
    --self.m_carPivot = self:GetTrans(self.m_uiObj,"RootPanel/info/car/pivot")

    self:SetButtonClickHandler(self.m_closeBtn,handler(self,self.OnCloseBtnDown))
    self:SetButtonClickHandler(self.m_buyBtn,handler(self,self.OnBuyBtnDown))
    --self:SetButtonClickHandler(self.m_leftBtn,handler(self,self.OnLeftPageBtnDown))
    --self:SetButtonClickHandler(self.m_rightBtn,handler(self,self.OnRightPageBtnDown))

    self.m_updateTimer = Timer:CreateNewMilliSecTimer(2,function()
        self:Update()
    end,true)

    self:SetListItemCountFunc(self.m_carList, function()
        return Tools:GetTableSize(self.m_shopCarConfigList)
    end)
    self:SetListItemNameFunc(self.m_carList, function(index)
        return "item"
    end)
    self:SetListUpdateFunc(self.m_carList, handler(self, self.UpdateCarList))

    self:RefreshResPanel()
end

function BuyCarShopUIView:Init(carShopID)
    self.m_shopConfig = BuyCarShopUI:GetCarShopConfig(carShopID)
    self.m_shopID = carShopID
    self.m_shopCarConfigList = {}
    local carConfigs = self.m_shopConfig["cars"]
    local carIndex = 1
    if carConfigs then
        for k,v in pairs(carConfigs) do
            self.m_shopCarConfigList[carIndex] = v
            carIndex = carIndex + 1
        end
    end
    
    table.sort(self.m_shopCarConfigList, function(a, b) 
        return a.id < b.id
    end)
    local shopName = GameTextLoader:ReadText("TXT_BUILDING_B"..carShopID.."_NAME")
    self.m_shopNameText.text = shopName
    --self:InitShowCar(1)
    self:SelectNotSoldCar()
    self:ShowEnterDialogue()
end

function BuyCarShopUIView:InitCamera()
    local camera = self:GetComp(self.m_carShopModel,"CarCamera","Camera")
    if camera then
        local modelIcon = self:GetComp("RootPanel/info/car","Image")
        local renderTexture = modelIcon.material:GetTexture("_BaseMap")
        if renderTexture then
            camera.targetTexture = renderTexture
        end
    end
end

---弹出进店对话
function BuyCarShopUIView:ShowEnterDialogue()
    local shopName = GameTextLoader:ReadText("TXT_BUILDING_B"..self.m_shopID.."_NAME")
    TalkUI:OpenTalk("enter_carshop",
            { firstCome = BuyCarManager:FirstCome(self.m_shopID) ,placeName = shopName},
            function()

            end)
end
---从当前Index开始往后数选中第一个没有Sold的车辆。如果全部Sold则选中Index==1的车辆
function BuyCarShopUIView:SelectNotSoldCar()
    local len = #self.m_shopCarConfigList
    local startIndex
    if self.m_showCarIndex and self.m_showCarIndex>0 and self.m_showCarIndex<=len then
        startIndex = self.m_showCarIndex
    else
        startIndex = 1
    end
    local index = startIndex
    if len>0 then
        while true do
            local carId = self.m_shopCarConfigList[index].id
            local isSold = BuyCarManager:OwnCar(carId,self.m_shopID) > 0
            if not isSold then
                self:InitShowCar(index)
                return
            end
            index = index+1
            if index>len then
                index = 1
            end
            if index == startIndex then
                break
            end
        end
    end
    self:InitShowCar(1)
end

---设置当前展示的汽车
function BuyCarShopUIView:InitShowCar(carIndexInShop)
    local shopCarConfig = self.m_shopCarConfigList[carIndexInShop]
    if shopCarConfig then
        self.m_showCarIndex = carIndexInShop
        local carID = shopCarConfig["id"]
        local carConfig = BuyCarShopUI:GetCarConfig(carID)
        self.m_curShowCarConfig = carConfig
        self:RefreshTitlePanel()
        self:RefreshBuyBtnPanel()
        self:RefreshModelPanel()
        self:RefreshCarList()
    else
        --找不到配置
    end
end

---刷新资源数量
function BuyCarShopUIView:RefreshResPanel()
    self:RefreshForbes()
    self:RefreshCash()
    self:RefreshDiamonds()
    --self:RefreshCarPort()
end

---刷新福布斯
function BuyCarShopUIView:RefreshForbes()
    local forbes = ValueManager:GetValue(true)
    self.m_resForbesNumText.text = Tools:SeparateNumberWithComma(forbes)
end

---刷新钱
function BuyCarShopUIView:RefreshCash()
    self.m_resCashNumText.text = Tools:SeparateNumberWithComma(ResourceManger:GetLocalMoney())
    self:SetSprite(self.m_resCashIcon, "UI_Main", CountryMode.cash_icon)
end

---刷新钻石
function BuyCarShopUIView:RefreshDiamonds()
    self.m_resDiamondNumText.text = Tools:SeparateNumberWithComma(ResourceManger:GetDiamond())
end

-----刷新车位占用情况
--function BuyCarShopUIView:RefreshCarPort()
--    local carCount,carPortCount = HouseMode:GetCarPortOccupyInfo()
--    self.m_resCarPortNumText.text = tostring(carCount)
--    self.m_resCarPortNumMaxText.text = tostring(carPortCount)
--end

function BuyCarShopUIView:GetCurShowCarConfig()
    return self.m_curShowCarConfig
end

function BuyCarShopUIView:UpdateCarList(index,tran)
    index = index + 1
    local go = tran.gameObject
    local shopCarConfig = self.m_shopCarConfigList[index]
    local carId = shopCarConfig.id
    local carConfig = BuyCarShopUI:GetCarConfig(carId)
    local isSelect = self.m_showCarIndex == index
    local isSold = BuyCarManager:OwnCar(carId,self.m_shopID) > 0
    local normalRoot = self:GetGo(go,"info/bg_normal")
    local selectRoot = self:GetGo(go,"info/bg_select")
    local soldRoot = self:GetGo(go,"info/bg_sold")
    local activeGO
    if isSold then
        activeGO = soldRoot
        normalRoot:SetActive(false)
        selectRoot:SetActive(false)
        soldRoot:SetActive(true)
    elseif isSelect then
        activeGO = selectRoot
        normalRoot:SetActive(false)
        selectRoot:SetActive(true)
        soldRoot:SetActive(false)
    else
        activeGO = normalRoot
        normalRoot:SetActive(true)
        selectRoot:SetActive(false)
        soldRoot:SetActive(false)
    end
    local carSpriteName = "icon_".. carConfig.pfb
    local carLogoName = carConfig.logo
    local name = GameTextLoader:ReadText("TXT_CAR_C"..carId.."_NAME")
    local carIconImage = self:GetComp(activeGO,"car_icon","Image")
    local logoImage = self:GetComp(activeGO,"title/mark","Image")
    self:SetSprite(carIconImage, "UI_Common", carSpriteName)
    self:SetSprite(logoImage, "UI_Common", carLogoName)
    self:SetText(activeGO,"title/name", name)
    local btn = self:GetComp(activeGO,"","Button")
    self:SetButtonClickHandler(btn,function()
        if not isSold then
            self:InitShowCar(index)
        end
    end)
end

---刷新车辆标题,车名，星级，简介
function BuyCarShopUIView:RefreshTitlePanel()
    local carConfig = self.m_curShowCarConfig
    local carId = carConfig["id"]
    local forbes = carConfig["wealth_buff"] or 0

    self:SetSprite(self.m_carLogoImage, "UI_Common", carConfig.logo)
    local name = GameTextLoader:ReadText("TXT_CAR_C"..carId.."_NAME")
    local desc = GameTextLoader:ReadText("TXT_CAR_C"..carId.."_DESC")
    self.m_carNameText.text = name
    self.m_carDesText.text = desc

    local star = carConfig["star"] or 1
    for i = 1, START_COUNT do
        self.m_starGOList[i]:SetActive(i<=star)
    end

    self.m_forbesText.text = "+"..tostring(forbes)

    --print("self.m_shopCarConfigList"..#self.m_shopCarConfigList)
    --self.m_leftBtn.interactable = self.m_showCarIndex > 1
    --self.m_rightBtn.interactable = self.m_showCarIndex < #self.m_shopCarConfigList
    --local imageName = "icon_car_"..carId
    --self:SetSprite(self.m_car, "UI_Common", imageName)
end

---更换车辆模型
function BuyCarShopUIView:RefreshModelPanel()
    if not self.m_carPivot then
        return
    end
    local carConfig = self.m_curShowCarConfig
    --local carId = carConfig["id"]
    local prefabPath = CarPrefabPath..carConfig["pfb"]..".prefab"
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath,self,function(go)
        if carConfig ~= self.m_curShowCarConfig then
            GameObject.Destroy(go)
            return
        end
        if self.m_curCarGO then
            GameObject.Destroy(self.m_curCarGO)
        end
        self.m_curCarGO = go
        UnityHelper.AddChildToParent(self.m_carPivot,go.transform)
        UnityHelper.SetGameObjectLayerRecursively(go,UILayer)
        UnityHelper.ChangeActorDayOrNightMatColor(go, true)
    end)
    --local imageName = "icon_BossCar_"..string.format("%03d",carId)
    --self:SetImageSprite("RootPanel/info/icon",imageName)
end

function BuyCarShopUIView:RefreshCarList()
    self.m_carList:UpdateData()
    if not self.m_carList:GetScrollItemIsInUse(self.m_showCarIndex-1) then
        self.m_carList:ScrollTo(self.m_showCarIndex-1)
    end
end

---车辆自动旋转
function BuyCarShopUIView:Update()
    if self.m_curCarGO and not self.m_curCarGO:IsNull() then
        self.m_curCarGO.transform:Rotate(0,ROTATE_SPEED*UnityTime.deltaTime,0)
    end
end

---刷新购买按钮和价格
function BuyCarShopUIView:RefreshBuyBtnPanel()
    local price = self.m_shopCarConfigList[self.m_showCarIndex]["price"]
    --local money = ResourceManger:GetLocalMoney()
    --local cashEnough = money >= price
    local carConfig = self.m_curShowCarConfig
    local carID = carConfig["id"]
    --local canBuy = BuyCarManager:Buy(carID,self.m_shopID,true) == 1
    local existCar = BuyCarManager:CheckShopExit(carID,self.m_shopID) --是否有库存
    self.m_ownedCarGO:SetActive(not existCar)
    self.m_buyBtn.interactable = existCar
    self.m_buyPriceText.text = Tools:SeparateNumberWithComma(price)
end

function BuyCarShopUIView:OnCloseBtnDown()
    TalkUI:OpenTalk("car_exit",{},function()
        BuyCarShopUI:CloseView()
        if self.m_buyCarID then
            --买了车辆退出需要根据时间判断是否返回FloorScene
            BuyCarManager:GetDrivingCar(self.m_buyCarID)
            self.m_buyCarID = nil
            BuyCarManager:SetNeedShowBuyCarBack(true)
            if GameTableDefine.CompanyMode:IsBossWorkingTime() then
                BuyCarManager:SetNeedShowBuyCarBack(false)
                GameTableDefine.FloorMode:ExitCarShop()
                GameTableDefine.CityMapUI:CloseView()
            end
        end
    end)
end

--function BuyCarShopUIView:OnLeftPageBtnDown()
--    if self.m_showCarIndex > 1 then
--        self:InitShowCar(self.m_showCarIndex-1)
--    end
--end
--
--function BuyCarShopUIView:OnRightPageBtnDown()
--    if self.m_showCarIndex < #self.m_shopCarConfigList then
--        self:InitShowCar(self.m_showCarIndex+1)
--    end
--end

function BuyCarShopUIView:OnBuyBtnDown()

    if not self.m_carPivot then
        return
    end

    local carConfig = self.m_curShowCarConfig
    local carID = carConfig["id"]
    local canBuy = BuyCarManager:Buy(carID,self.m_shopID,true)

    if canBuy == 1 then --钱和车位都够
        BuyCarManager:Buy(carID,self.m_shopID)
        self.m_carPivot.gameObject:SetActive(false)
        self:SelectNotSoldCar()
        self:RefreshCash()
        self.m_buyCarID = carID
        PurchaseSuccessUI:SuccessBuyCar(carID,function()
            self:RefreshForbes()
            self.m_carPivot.gameObject:SetActive(true)
        end)
    elseif canBuy == -1 then --钱不够
        GameTableDefine.ShopInstantUI:EnterToCashBuy(function()
            self:RefreshCash()
        end,"车")
    elseif canBuy == -2 then --车位不够
        --EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("没有车位了"))
        TalkUI:OpenTalk("car_lackPlace", { noHouse = HouseMode:noHouse()})
    end
    --local price = self.m_shopCarConfigList[self.m_showCarIndex]["price"]
    --local money = ResourceManger:GetLocalMoney()
    --local cashEnough = money >= price
    --if cashEnough then
    --
    --else
    --
    --end
end

function BuyCarShopUIView:LoadCarShopModel()
    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/UI/CarShopModel.prefab",self,function(go)
        self.m_carShopModel = go
        self:InitCamera()
        self.m_carPivot = self:GetTrans(go,"pivot")
        self:RefreshModelPanel()
    end)
end

function BuyCarShopUIView:OnExit(view)
    local camera = self:GetComp(self.m_carShopModel,"CarCamera","Camera")
    if camera then
        camera.targetTexture = nil
    end
    if self.m_carShopModel then
        GameObject.Destroy(self.m_carShopModel)
        self.m_carShopModel = nil
        self.m_carPivot = nil
    end
    if self.m_updateTimer then
        Timer:StopTimer(self.m_updateTimer)
    end
    self.super:OnExit(self)
end

function BuyCarShopUIView:ReleaseRenderTargetUse(object)
    -- local cam1Go = object.transform:Find("Mirror/MirrorCamera", "Camera")
    local cam1 = self:GetComp(object, "Mirror/MirrorCamera", "Camera")
    -- local cam2 = object:GetComponent("CarCamera", "Camera")
    local cam2 = self:GetComp(object, "CarCamera", "Camera")
    if cam1 then
        UnityHelper.ClearRenderTextureBuffer(cam1)
    end
    if cam2 then
        UnityHelper.ClearRenderTextureBuffer(cam2)
    end
    -- if cam1 and cam1.targetTexture then
    --     local rt = cam1.targetTexture
    --     cam1.targetTexture = nil
    --     if rt then
    --         rt:Clear()
    --     end
    -- end
    -- if cam2 and cam2.targetTexture then
    --     local rt = cam2.targetTexture
    --     cam2.targetTexture = nil
    --     if rt then
    --         rt:Clear()
    --     end
    -- end
end

return BuyCarShopUIView