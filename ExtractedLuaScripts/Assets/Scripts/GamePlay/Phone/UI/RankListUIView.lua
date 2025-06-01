local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local BuyCarManager = GameTableDefine.BuyCarManager
local BuyHouseManager = GameTableDefine.BuyHouseManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CityMode = GameTableDefine.CityMode
local HouseMode = GameTableDefine.HouseMode

local RankListUIView = Class("RankListUIView", UIView)

function RankListUIView:ctor()
    self.super:ctor()
end

function RankListUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/down/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:InitBaseData()
    self:InitTitle()

    self.mData = self:GetData()
    self:InitRankList()
    self.mList:UpdateData()

    self:GetWorthData()
    self:InitWorthList()
    self.mListCar:UpdateData()
    self.mListHouse:UpdateData()

    local scrollRoot = self:GetGo("RootPanel/PricePanel/statistic/Viewport/Content")
    self:SetButtonClickHandler(self:GetComp(scrollRoot, "car_statistic/expandBtn", "Button"), function()
        self:GetGo(scrollRoot, "CarList"):SetActive(true)
        self:GetGo(scrollRoot, "car_statistic/closeBtn"):SetActive(true)
    end)
    self:SetButtonClickHandler(self:GetComp(scrollRoot, "car_statistic/closeBtn", "Button"), function()
        self:GetGo(scrollRoot, "CarList"):SetActive(false)
        self:GetGo(scrollRoot, "car_statistic/closeBtn"):SetActive(false)
    end)
    self:SetButtonClickHandler(self:GetComp(scrollRoot, "house_statistic/expandBtn", "Button"), function()
        self:GetGo(scrollRoot, "HouseList"):SetActive(true)
        self:GetGo(scrollRoot, "house_statistic/closeBtn"):SetActive(true)
    end)

    self:SetButtonClickHandler(self:GetComp(scrollRoot, "house_statistic/closeBtn", "Button"), function()
        self:GetGo(scrollRoot, "HouseList"):SetActive(false)
        self:GetGo(scrollRoot, "house_statistic/closeBtn"):SetActive(false)
    end)
end

function RankListUIView:InitBaseData()
    local content = self:GetGo("RootPanel/PricePanel/statistic/Viewport/Content")
    local carData = BuyCarManager:GetBoughtData()
    local myCar = 0
    for k,v in pairs(carData or {}) do
        myCar = myCar + 1
    end
    local maxCar = 5--如何获取买车上限
    self:SetText(content, "car_statistic/prog/num", myCar .."/"..maxCar)
    local progressCar = self:GetComp(content, "car_statistic/prog", "Slider")
    progressCar.value = myCar / maxCar

    local houseData = HouseMode:GetLocalData() -- CityMode:GetHousesLocalData()
    local myHouse = 0
    for k,v in pairs(houseData or {}) do
        myHouse = myHouse + 1
    end
    local maxHouse = CityMode:GetTotalHouse()
    self:SetText(content, "house_statistic/prog/num", myHouse .."/"..maxHouse)
    local progressHouse = self:GetComp(content, "house_statistic/prog", "Slider")
    progressHouse.value = myHouse / maxHouse
end

function RankListUIView:InitTitle()
    local titleRoot = self:GetGo("RootPanel/up")
    local toRank = self:GetComp(titleRoot, "toRank", "Button")
    local toWorth = self:GetComp(titleRoot, "toWorth", "Button")
    local chooseRank = self:GetGo(toRank.gameObject, "choose")
    local chooseWorth = self:GetGo(toWorth.gameObject, "choose")

    self:SetButtonClickHandler(toRank, function()
        self:GetGo("RootPanel/RankPanel"):SetActive(true)
        self:GetGo("RootPanel/PricePanel"):SetActive(false)
        chooseRank:SetActive(true)
        chooseWorth:SetActive(false)
        --UnityHelper.SetSiblingIndex(toWorth.gameObject.transform,1)
        --UnityHelper.SetSiblingIndex(toRank.gameObject.transform,3)
    end)

    self:SetButtonClickHandler(toWorth, function()
        self:GetGo("RootPanel/RankPanel"):SetActive(false)
        self:GetGo("RootPanel/PricePanel"):SetActive(true)
        chooseRank:SetActive(false)
        chooseWorth:SetActive(true)
        --UnityHelper.SetSiblingIndex(toRank.gameObject.transform,1)
        --UnityHelper.SetSiblingIndex(toWorth.gameObject.transform,3)
    end)
end

function RankListUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local currData = self.mData[index]
    if currData then
        self:SetText(go, "rank", index)
        self:GetGo(go, "bg/isPlayer"):SetActive(currData.isPlayer)
        self:SetText(go, "bg/name", currData.name)
        self:SetText(go, "bg/worth", currData.worth)
    end
end

function RankListUIView:InitRankList()
    self.mList = self:GetComp("RootPanel/RankPanel/RankList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.mData
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
end

function RankListUIView:GetData()
    if self.mData then
        return self.mData
    end

    local data = {
        {name = "小明", worth = 1400},
        {name = "小红", worth = 1500},
        {name = "小黑", worth = 1700},
        {name = "小白", worth = 500},
        {name = "小张", worth = 1400},
        {name = "小王", worth = 1700},
        {name = "小紫", worth = 14000},
        {name = "小绿", worth = 400},
        {name = "小粉", worth = 4500},
        {name = "小刘", worth = 4040},
        {name = "小飞", worth = 4010}
    }

    table.insert(data, {name = "玩家", worth = 3000, isPlayer = true})

    table.sort(data, function(a,b)
        return a.worth > b.worth
    end)

    return data
end

function RankListUIView:OnExit()
    self.super:OnExit(self)
end

--身价相关
function RankListUIView:GetWorthData()
    self.mCar = {}
    self.mHouse = {}
    local carBought = BuyCarManager:GetBoughtData()
    local houseBought = HouseMode:GetLocalData()
    for k, v in pairs(carBought) do
        table.insert(self.mCar, {id = tonumber(string.sub(k,4)), own = v})
    end
    
    for k, v in pairs(houseBought or {}) do
        table.insert(self.mHouse, {id = k, own = 1})
    end
end

function RankListUIView:InitWorthList()
    self.mListCar = self:GetComp("RootPanel/PricePanel/statistic/Viewport/Content/CarList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mListCar, function()
        return #self.mCar
    end)
    self:SetListUpdateFunc(self.mListCar, handler(self, self.UpdateListItemCar))

    self.mListHouse = self:GetComp("RootPanel/PricePanel/statistic/Viewport/Content/HouseList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mListHouse, function()
        return #self.mHouse
    end)
    self:SetListUpdateFunc(self.mListHouse, handler(self, self.UpdateListItemHouse))
end

function RankListUIView:UpdateListItemCar(index, tran)
    index = index + 1
    local go = tran.gameObject
    local currData = self.mCar[index]
    if currData then
        local cfg = ConfigMgr.config_car[currData.id]
        self:SetText(go, "name", cfg.name)
        self:SetText(go, "num", currData.own)

        self:GetGo(go, "currUse"):SetActive(currData.id == BuyCarManager:GetDrivingCar())

        local button = self:GetComp(go, "icon", "Button")
        self:SetButtonClickHandler(button, function()
            BuyCarManager:GetDrivingCar(currData.id)
            self.mListCar:UpdateData()
        end)
    end
end

function RankListUIView:UpdateListItemHouse(index, tran)
    index = index + 1
    local go = tran.gameObject
    local currData = self.mHouse[index]
    if currData then
        local cfg = ConfigMgr.config_house[currData.id]
        self:SetText(go, "name", cfg.name)
    end
end
return RankListUIView