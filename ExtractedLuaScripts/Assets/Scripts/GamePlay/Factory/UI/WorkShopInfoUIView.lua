local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject
local GameUIManager = GameTableDefine.GameUIManager
local CfgMgr = GameTableDefine.ConfigMgr
local FactoryMode = GameTableDefine.FactoryMode
local ConfigMgr = GameTableDefine.ConfigMgr
local ActivityUI = GameTableDefine.ActivityUI
local ResMgr = GameTableDefine.ResourceManger
local V3 = CS.UnityEngine.Vector3
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local WorkshopItemUI = GameTableDefine.WorkshopItemUI
local TimerMgr = GameTimeManager

local WorkShopInfoUIView = Class("WorkShopInfoUIView", UIView)

function WorkShopInfoUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_config = ConfigMgr.config_workshop
    self.m_cfgProducts = ConfigMgr.config_products
    --self.productsData = WorkShopInfoUI:GetProductsData()
end

function WorkShopInfoUIView:OnEnter()
    self:SetButtonClickHandler(
        self:GetComp("BgCover", "Button"),
        function()
            self:DestroyModeUIObject()
        end
    )
end

--生产形车间的菜单初始化设置
function WorkShopInfoUIView:WorkShopInfoInit(WorkShopId)
    self.WorkShopId = WorkShopId
    self.m_data = FactoryMode:GetWorkShopdata(WorkShopId)
    self.type = self.m_config[WorkShopId]["room_category"][2]

    self:SetText("RootPanel/title/bg/name", GameTextLoader:ReadText(self.m_config[WorkShopId]["name"]))

    local upgradeBtn = self:GetComp("RootPanel/btnPanel/upgradeBtn", "Button")
    local storageBtn = self:GetComp("RootPanel/btnPanel/storageBtn", "Button")
    local productBtn = self:GetComp("RootPanel/btnPanel/productBtn", "Button")
    local processBtn = self:GetComp("RootPanel/btnPanel/processBtn", "Button")

    if self.type == 104 then
        local TabView = self:GetComp("RootPanel/btnPanel", "TabView")
        TabView:SwitchtoTab(1)
    end

    self:GetGo("RootPanel/btnPanel/productBtn"):SetActive(self.type ~= 104)
    self:GetGo("RootPanel/btnPanel/storageBtn"):SetActive(self.type == 104)

    self:SetButtonClickHandler(upgradeBtn, function()
        self:refreshUpdataUI(WorkShopId)
    end)
    self:SetButtonClickHandler(productBtn, function()
        self:refreshProductUI(WorkShopId)
    end)
    self:SetButtonClickHandler(storageBtn, function()
        self:refreshStorehouseUI(WorkShopId)
    end)
    self:SetButtonClickHandler(processBtn, function()
        self:RefreshProductionPanel()
    end)
    --
    self:SetButtonClickHandler(self:GetComp("RootPanel/title/bg/boostBtn", "Button"), function()
        WorkshopItemUI:OpenUI(WorkShopId)  
    end)    
    self:UpdataProductsNum()
    if self.type == 104 then
        self:refreshUpdataUI(WorkShopId)
        self:refreshStorehouseUI(WorkShopId)
    else
        self:refreshUpdataUI(WorkShopId)
        self:refreshProductUI(WorkShopId)
    end
end

--升级菜单
function WorkShopInfoUIView:refreshUpdataUI(WorkShopId)
    self:GetGo("RootPanel/title/bg/boostBtn"):SetActive(false)
    local isMaxLv = #self.m_config[WorkShopId]["unlock_license"] <= self.m_data.Lv

    local updataRoot = self:GetGo("RootPanel/upgradePanel/detail/property")
    self:GetGo(updataRoot, "efficiency"):SetActive(self.type ~= 104)
    self:GetGo(updataRoot, "product"):SetActive(self.type ~= 104)
    self:GetGo(updataRoot, "storage"):SetActive(self.type == 104)

    --建筑等级
    self:SetText(updataRoot, "level/data/num", self.m_data.Lv)
    self:SetText(updataRoot, "level/data/next", "+1")
    self:GetGo(updataRoot, "level/data/next"):SetActive(not isMaxLv)

    --制造品类--需要修改
    local productionNum = 0
    local addProductionNum = 0
    for k, v in pairs(self.m_config[WorkShopId]["product"]) do
        if v["LvNeed"] <= self.m_data.Lv then
            productionNum = productionNum + 1
        end
        if v["LvNeed"] == self.m_data.Lv + 1 then
            addProductionNum = addProductionNum + 1
        end
    end

    self:SetText(updataRoot, "product/data/num", productionNum)

    self:GetGo(updataRoot, "product/data/next"):SetActive(not isMaxLv)

    --效率加成
    local currentBonus = self.m_config[WorkShopId]["room_bonus"][self.m_data.Lv]
    if currentBonus then
        self:SetText(updataRoot, "efficiency/data/num", currentBonus .. "%")

        self:GetGo(updataRoot, "efficiency/data/next"):SetActive(not isMaxLv)
    end

    --存储容量
    local currenRoomStorage = self.m_config[WorkShopId]["room_storage"][self.m_data.Lv]

    self:SetText(updataRoot, "storage/data/num", currenRoomStorage)

    self:GetGo(updataRoot, "storage/data/next"):SetActive(not isMaxLv)

    --升级和满级按钮
    self:GetGo("RootPanel/upgradePanel/detail/info/upgradeBtn"):SetActive(not isMaxLv)
    self:GetGo("RootPanel/upgradePanel/detail/info/maxLevel"):SetActive(isMaxLv)

    local upDataBtn = self:GetComp("RootPanel/upgradePanel/detail/info/upgradeBtn", "Button")

    if not isMaxLv then
        --效率的加值

        if WorkShopId ~= 10005 then
            local addBonus = self.m_config[WorkShopId]["room_bonus"][self.m_data.Lv + 1] - currentBonus
            self:SetText(updataRoot, "efficiency/data/next", "+" .. addBonus .. "%")
        end

        --生产物的加值
        self:SetText(updataRoot, "product/data/next", "+" .. addProductionNum)
        if self.type == 104 then
            local addRoomStorage = self.m_config[WorkShopId]["room_storage"][self.m_data.Lv + 1] - currenRoomStorage
            self:SetText(updataRoot, "storage/data/next", "+" .. addRoomStorage)
        end
        upDataBtn.interactable = FactoryMode:CanUnlock(WorkShopId)
        local addCash = self.m_config[WorkShopId]["unlock_cash"][self.m_data.Lv + 1]
        local addLicense = self.m_config[WorkShopId]["unlock_license"][self.m_data.Lv + 1]        
        self:SetText("RootPanel/upgradePanel/detail/info/cost/license/num", addLicense)
        self:SetText("RootPanel/upgradePanel/detail/info/cost/cash/num", Tools:SeparateNumberWithComma(addCash))
        self:SetButtonClickHandler(
            upDataBtn,
            function()
                ResMgr:SpendLicense(
                    addLicense,
                    nil,
                    function(isEnough)
                        if isEnough then
                            ResMgr:SpendCash(
                                addCash,
                                nil,
                                function(isEnough)
                                    if isEnough then
                                        FactoryMode:Build(WorkShopId)
                                        self:refreshUpdataUI(WorkShopId)
                                        FactoryMode:PlayUpGreatFacFB(WorkShopId)
                                        EventManager:DispatchEvent("UPGRADE_FACTORY")
                                        GameSDKs:TrackForeign("cash_event", {type_new = 1, change_new = 1, amount_new = tonumber(addCash) or 0, position = "["..tostring(WorkShopId).."]号工厂升级"})
                                    end
                                end
                            )
                        end
                    end
                )
            end
        )
    end
end
--生产菜单
function WorkShopInfoUIView:refreshProductUI(WorkShopId)
    
    self:GetGo("RootPanel/title/bg/boostBtn"):SetActive(true)
    self.m_productsList = self:GetComp("RootPanel/productPanel/product", "ScrollRectEx")
    self.storehouseItemGoList = {}
    --设置List的数量
    self:SetListItemCountFunc(
        self.m_productsList,
        function()
            return #self.m_config[WorkShopId]["product"]
        end
    )
    --设置List中的Item的类型
    self:SetListItemNameFunc(
        self.m_productsList,
        function(index)
            return "Item"
        end
    )
    --设置List中的Item的具体内容
    self:SetListUpdateFunc(self.m_productsList, handler(self, self.UpdateProductionPartsCollection))

    if not self.m_selectedProduct then
        if self.m_data["state"] == 2 then
            self.m_selectedProduct = self.m_data["productId"]
        else
            self.m_selectedProduct = self.m_config[WorkShopId]["product"][1]["type"]
        end
    end
    if self.setListDataTimeHandler then
        GameTimer:StopTimer(self.setListDataTimeHandler)
        self.setListDataTimeHandler = nil
    end
    self.setListDataTimeHandler = GameTimer:CreateNewMilliSecTimer(50, function() --延迟执行，等待CameraFocus位置自动修正完毕
        self.m_productsList:UpdateData()
    end)
    
    local product = self.m_cfgProducts[self.m_selectedProduct]
    local productRoot = self:GetGo("RootPanel/productPanel/bottom/detail")
    local startProductionGo = self:GetGo(productRoot, "selected/operate/btnArea/startBtn")
    local stopProductionGo = self:GetGo(productRoot, "selected/operate/btnArea/stopBtn")    
    local needLvGo = self:GetGo(productRoot, "selected/operate/btnArea/lock")
    local startProductionBtn = startProductionGo:GetComponent("Button")
    local stopProductionBtn = stopProductionGo:GetComponent("Button")
    --

    self:SetText(productRoot, "selected/name", GameTextLoader:ReadText(product["name"]))
    local Image = self:GetComp(productRoot, "selected/icon", "Image")
    self:SetSprite(Image, "UI_Common", product["icon"])
    local Image2 = self:GetComp(productRoot, "currentState/icon", "Image")
    self:SetSprite(Image2, "UI_Common", product["icon"])
    self:SetText(productRoot, "selected/desc", GameTextLoader:ReadText(product["desc"]))
    local Image = self:GetComp(productRoot, "selected/operate/need_product/item/icon", "Image")
    self:SetSprite(Image, "UI_Common", product["need_product"][1]["type"])

    self:SetButtonClickHandler(
        stopProductionBtn,
        function()
            self.m_data["state"] = 1
            LocalDataManager:WriteToFile()
            self:refreshProductUI(WorkShopId)
            --退还已经在的车间的零件
            if self.m_data["underLoad"] then
                WorkShopInfoUI:Consume(self.m_data["productId"], true)
                self.m_data["underLoad"] = false
            end
            FactoryMode:RefreshWorkshop(WorkShopId)
        end
    )

    --是否需要生产材料的 List 和 UI
    local partsList = {}
    local CanProduce = true
    local rawState = 1      --正常
    local noNeed = false
    for i, v in ipairs(product["need_product"]) do
        local type = v["type"]
        local num = v["num"]
        if type == 0 then
            noNeed = true
            break
        end
        partsList[i] = {}
        partsList[i].type = type
        partsList[i].num = num
        local productNum = WorkShopInfoUI:GetProductNum(type)
        if num > productNum then
        --if not self.productsData[tostring(type)] or num > self.productsData[tostring(type)] then
            rawState = 2    --材料不足
            CanProduce = false
        end
    end
    if WorkShopInfoUI:storageLimit() <= 0 then
        rawState = 3        --仓库满了
    end
    
    local needProductIcon = self:GetComp(productRoot, "selected/operate/need_product","Image")
    if rawState == 1 and noNeed then
        needProductIcon.color = UnityHelper.GetColor("#dadfe6")
    elseif rawState == 1 and not noNeed then 
        needProductIcon.color = UnityHelper.GetColor("#2cd007")
    elseif rawState == 2 then        
        needProductIcon.color = UnityHelper.GetColor("#ff293c")
    elseif rawState == 3 then
        needProductIcon.color = UnityHelper.GetColor("#ff9715")
    end
    
    self:GetGo(productRoot, "selected/operate/need_product/need"):SetActive(rawState == 1)
    self:GetGo(productRoot, "selected/operate/need_product/lack"):SetActive(rawState == 2)
    self:GetGo(productRoot, "selected/operate/need_product/full"):SetActive(rawState == 3)
    if not partsList[1] then
        self:GetGo(productRoot, "selected/operate/no_need"):SetActive(true)
    else
        self:GetGo(productRoot, "selected/operate/no_need"):SetActive(false)
    end
    
    startProductionBtn.interactable = CanProduce
    self:SetButtonClickHandler(
        startProductionBtn,
        function()
            if self.m_data["state"] == 2 then
                --先退还原先的材料
                if self.m_data["underLoad"] then
                    WorkShopInfoUI:Consume(self.m_data["productId"], true)
                end
            else
                self.m_data["state"] = 2
            end
            
            self.m_data["timePoint"] = TimerMgr:GetCurrentServerTime(true)
            self.m_data["productId"] = self.m_selectedProduct
            --消耗并装载材料
            WorkShopInfoUI:ConsumableMaterialGroup(self.m_data["productId"],function()
                self.m_data["underLoad"] = true
                LocalDataManager:WriteToFile()                        
            end)            
            self:refreshProductUI(WorkShopId)
            FactoryMode:RefreshWorkshop(WorkShopId)
        end
    )
    local btnStart = self.m_data["state"] == 2 and self.m_selectedProduct == self.m_data["productId"]
    local LvNeed = nil
    for k, v in pairs(self.m_config[WorkShopId]["product"]) do
        if v.type == self.m_selectedProduct then
            LvNeed = v.LvNeed
            break
        end
    end
    if self.m_data and self.m_data.Lv and LvNeed then
        startProductionGo:SetActive(not btnStart and self.m_data.Lv >= LvNeed)
        stopProductionGo:SetActive(btnStart and self.m_data.Lv >= LvNeed)
        needLvGo:SetActive(self.m_data.Lv < LvNeed)    
        self:SetText(needLvGo, "txt", string.format(GameTextLoader:ReadText("TXT_BTN_LEVEL"), LvNeed))
    else
        startProductionGo:SetActive(false)
        stopProductionGo:SetActive(false)
        needLvGo:SetActive(false)    
        self:SetText(needLvGo, "txt", string.format(GameTextLoader:ReadText("TXT_BTN_LEVEL"), LvNeed))
    end
    
    local temp = self:GetGo(productRoot, "selected/operate/need_product/item")
    temp:SetActive(false)
    for i = 1, 10 do
        local listInfo = partsList[i]
        local centGo = self:CheckDataAndGameObject(temp, partsList, i)
        if centGo then
            centGo:SetActive(listInfo ~= nil)
            if listInfo ~= nil then
                local Image = self:GetComp(centGo, "icon", "Image")
                self:SetSprite(Image, "UI_Common", self.m_cfgProducts[listInfo.type].icon)
                self:SetText(centGo, "num/txt", "x" .. listInfo.num)                
                self:SetButtonClickHandler(centGo:GetComponent("Button"), function()
                    local Info = self:GetGo("Material_info")
                    Info:SetActive(true)
                    self:SetText(Info, "name", GameTextLoader:ReadText(self.m_cfgProducts[listInfo.type].name))
                    local descText = GameTextLoader:ReadText("TXT_FACTORY_WORKSHOP_" .. self.m_cfgProducts[listInfo.type].workshop_require[1])
                    descText = string.format(GameTextLoader:ReadText("TXT_FACTORY_SOURCE"), descText)
                    self:SetText(Info, "desc", descText)    
                    self:SetButtonClickHandler(self:GetComp("Material_info/infocloseBtn", "Button"), function()
                        Info:SetActive(false)
                    end)
                end)
            end
        end
    end
    
    --buff栏的圈       
    if FactoryMode:CheckBuffUsefor(self.m_data) then
        local buffImage = self:GetComp(productRoot, "bonus/state/prog/Fill", "Image")     
        local wpBuff = self.m_data.buff   
        local cfg = ConfigMgr.config_boost[wpBuff.type]
        self:GetGo(productRoot, "bonus"):SetActive(true)
        local icon = self:GetComp(productRoot, "bonus/state/icon","Image")
        self:SetSprite(icon, "UI_Shop", cfg.icon)
        self:SetText(productRoot, "bonus/state/buff", "+" .. cfg.buff * 100 .. "%")
        self:SetText(productRoot, "bonus/state/prog/time", TimerMgr:FormatTimeLength(wpBuff.timePoint - TimerMgr:GetCurrentServerTime(true)))  
        buffImage.fillAmount = (wpBuff.timePoint - TimerMgr:GetCurrentServerTime(true)) / cfg.duration
    else
        self:GetGo(productRoot, "bonus"):SetActive(false)
    end   
        
         
end
--对单个Item进行一个设置,发生改变时自动遍历修改
function WorkShopInfoUIView:UpdateProductionPartsCollection(index, tran)
    index = index + 1
    local go = tran.gameObject
    self.storehouseItemGoList[index] = go  
    local data = self.m_config[self.WorkShopId]["product"][index]
    if not data then
        return
    end
    local product = self.m_cfgProducts[data["type"]]
    local productName = product["name"]
    self:SetText(go, "bg/unlocked/name", GameTextLoader:ReadText(productName))
    local Image = self:GetComp(go, "bg/icon", "Image")
    local icon = product["icon"]
    self:SetSprite(Image, "UI_Common", icon)

    local originalTime = product["base_time"]
    -- local improveEfficiency = self.m_config[self.WorkShopId]["room_bonus"][self.m_data.Lv]

    -- local timeText = originalTime * (100 - improveEfficiency) / 100

    local bonus = (self.m_config[self.WorkShopId]["room_bonus"][self.m_data.Lv] / 100) + 1
    local base_time = FactoryMode:GetSpeed(self.WorkShopId,data["type"])

    self:SetText(go, "bg/unlocked/selected/time/time", string.format("%.1f", base_time) .. "S")
    --local productNum = self.productsData[tostring(data["type"])] or 0
    local productNum = WorkShopInfoUI:GetProductNum(data["type"])
    self:CreateTimerByGo(1000, function()
        if not go then

        else
            self:SetText(go, "bg/unlocked/storage/num", tostring(productNum))
        end
    end, true, true, go)
    if self.m_selectedProduct == data.type then
        self:GetGo(go, "bg/unlocked/selected"):SetActive(true)
    else
        self:GetGo(go, "bg/unlocked/selected"):SetActive(false)
    end
    local bgBtn = self:GetComp(go, "bg", "Button")

    local CanProduce = self.m_data["Lv"] >= data.LvNeed

    self:GetGo(go, "bg/unlocked"):SetActive(CanProduce)

    self:GetGo(go, "bg/locked"):SetActive(not CanProduce)
    --控制生产中能否点击的
    --bgBtn.interactable = CanProduce
    self:SetButtonClickHandler(bgBtn, function()
        self.m_selectedProduct = data.type
        self:refreshProductUI(self.WorkShopId)
    end)
end

--用于创建小UI的复制
function WorkShopInfoUIView:CheckDataAndGameObject(temp, data, index)
    local tarans = temp.transform.parent
    local go = tarans.gameObject
    local centTrans = self:GetTrans(go, "temp_" .. index)
    temp:SetActive(false)
    if data then
        if not centTrans or centTrans:IsNull() then
            local newGo = GameObject.Instantiate(temp, tarans)
            newGo.name = "temp_" .. index
            newGo:SetActive(true)
            return newGo
        else
            centTrans.gameObject:SetActive(true)
        end
        return centTrans.gameObject
    else
        if centTrans and not centTrans:IsNull() then
            centTrans.gameObject:SetActive(false)
        end
        return nil
    end
end

--刷新仓库
function WorkShopInfoUIView:refreshStorehouseUI(WorkShopId)
    local storehouseRoot = self:GetGo("RootPanel/storagePanel/bottom")
    self:GetGo("RootPanel/title/bg/boostBtn"):SetActive(false)
    self.storehouseItemGoList = {}
    self.listProducts = {}
    local index = 1
    local productsData = WorkShopInfoUI:GetProductsData()
    for k, v in pairs(productsData) do
        if type(v) == "number" then
            local curr = {}

            curr.id = tonumber(k)
            curr.num = WorkShopInfoUI:GetProductNum(k)
            --curr.num = v
            if curr.num ~= 0 then
                self.listProducts[index] = curr
                index = index + 1
            end
            --continue
            --while true do
            --    if curr.num == 0 then
            --        break
            --    end
            --
            --    self.listProducts[index] = curr
            --    index = index + 1
            --
            --    break
            --end
            --
        end
    end
    if #self.listProducts == 0 then
        self:GetGo(storehouseRoot, "detail/empty"):SetActive(true)
        self:GetGo(storehouseRoot, "detail/selected"):SetActive(false)
    else
        self:GetGo(storehouseRoot, "detail/empty"):SetActive(false)
        self:GetGo(storehouseRoot, "detail/selected"):SetActive(true)
        local allProductsNum = WorkShopInfoUI:GetTheTotal()
        local currentLimit, storageLimit = WorkShopInfoUI:storageLimit()
        local slider = self:GetComp(storehouseRoot, "storage/prog", "Slider")
        slider.value = allProductsNum / storageLimit
        self:SetText(storehouseRoot, "storage/stock/num", allProductsNum .. "/" .. storageLimit)
        if not self.m_selectedProduct then
            self.m_selectedProduct = self.listProducts[1].id
        end

        local Image = self:GetComp(storehouseRoot, "detail/selected/icon", "Image")

        self:SetSprite(Image, "UI_Common", self.m_cfgProducts[self.m_selectedProduct]["icon"])
        self:SetText(storehouseRoot, "detail/selected/name", GameTextLoader:ReadText(self.m_cfgProducts[self.m_selectedProduct]["name"]))
        self:SetText(storehouseRoot, "detail/selected/desc", GameTextLoader:ReadText(self.m_cfgProducts[self.m_selectedProduct]["desc"]))
        local selectProductNum = WorkShopInfoUI:GetProductNum(self.m_selectedProduct)
        self:SetText(storehouseRoot, "detail/selected/stock/num", tostring(selectProductNum))
        --self:SetText(storehouseRoot, "detail/selected/stock/num", self.productsData[tostring(self.m_selectedProduct)])
        
        local clearBtn= self:GetComp(storehouseRoot, "detail/selected/deleteBtn", "Button")
        self:SetButtonClickHandler(clearBtn, function()
            self:GetGo("clearPanel"):SetActive(true)
        end)
        local SetClearUI = function()    
            local slider = self:GetComp("clearPanel/RootPanel/MidPanel/slider", "Slider")            
            local verNum = 0
            slider.value = 0                    
            self:SetText("clearPanel/RootPanel/MidPanel/slider/handle/bubble/num", verNum)  
            self:SetSprite(self:GetComp("clearPanel/RootPanel/MidPanel/icon", "Image"), "UI_Common", self.m_cfgProducts[self.m_selectedProduct]["icon"])
            self:SetText("clearPanel/RootPanel/MidPanel/info/name", GameTextLoader:ReadText(self.m_cfgProducts[self.m_selectedProduct]["name"]))
            self:SetText("clearPanel/RootPanel/MidPanel/info/desc", GameTextLoader:ReadText(self.m_cfgProducts[self.m_selectedProduct]["desc"]))
            self:SetText("clearPanel/RootPanel/MidPanel/info/storage/txt", tostring(selectProductNum))
            --self:SetText("clearPanel/RootPanel/MidPanel/info/storage/txt", self.productsData[tostring(self.m_selectedProduct)])
            UnityHelper.SetSliderValueChangeHandler(slider, function()
                local curSelectProductNum = WorkShopInfoUI:GetProductNum(self.m_selectedProduct)
                verNum = math.floor(slider.value * curSelectProductNum)
                self:SetText("clearPanel/RootPanel/MidPanel/info/storage/txt", tostring(curSelectProductNum))
                --verNum = math.floor(slider.value * self.productsData[tostring(self.m_selectedProduct)])
                --self:SetText("clearPanel/RootPanel/MidPanel/info/storage/txt", self.productsData[tostring(self.m_selectedProduct)])
                self:SetText("clearPanel/RootPanel/MidPanel/slider/handle/bubble/num", verNum)                  
             end)
            self:SetButtonClickHandler(self:GetComp("clearPanel/BgCover", "Button"), function()
                self:GetGo("clearPanel"):SetActive(false)
            end)
            self:SetButtonClickHandler(self:GetComp("clearPanel/RootPanel/SelectPanel/ConfirmBtn", "Button"), function()
                --local text = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField").text
                local num = tonumber(verNum)
                local curSelectProductNum = WorkShopInfoUI:GetProductNum(self.m_selectedProduct)
                if num and num >= 0 and math.floor(num) == num and num <= curSelectProductNum then
                --if num and num >= 0 and math.floor(num) == num and num <= self.productsData[tostring(self.m_selectedProduct)] then
                    WorkShopInfoUI:SpendProduct(num, self.m_selectedProduct)
                    self:GetGo("clearPanel"):SetActive(false)
                    FactoryMode:CheckParkingLotBoxHint()
                    self:refreshStorehouseUI(WorkShopId)
                else
                    EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_LACK_INPUT"))
                end                   
            end)
        end
        SetClearUI()
    end
    self.m_storehouseList = self:GetComp("RootPanel/storagePanel/storage", "ScrollRectEx")

    self:SetListItemCountFunc(
        self.m_storehouseList,
        function()
            return Tools:GetTableSize(self.listProducts)
        end
    )

    self:SetListItemNameFunc(
        self.m_storehouseList,
        function(index)
            return "Item"
        end
    )

    self:SetListUpdateFunc(self.m_storehouseList, handler(self, self.UpdateWarehousePartsCollection))
    
    self.m_storehouseList:UpdateData()
end

--对单个Item进行一个设置,发生改变时自动遍历修改
function WorkShopInfoUIView:UpdateWarehousePartsCollection(index, tran)
    index = index + 1
    local go = tran.gameObject    
    local productId = self.listProducts[index].id
    local productNum = self.listProducts[index].num
    local data = self.m_config[self.WorkShopId]["product"][index]
    self.storehouseItemGoList[index] = go  
    local Image = self:GetComp(go, "bg/unlocked/icon", "Image")
    local currentLimit, storageLimit = WorkShopInfoUI:storageLimit()
    self:CreateTimerByGo(1000, function()
        if not go then

        else
            local productNum = WorkShopInfoUI:GetProductNum(productId)
            self:SetText(go, "bg/unlocked/storage/num", tostring(productNum))
            --self:SetText(go, "bg/unlocked/storage/num", self.productsData[tostring(productId)] or 0)
        end
    end, true, true, go)
    self:SetSprite(Image, "UI_Common", self.m_cfgProducts[productId]["icon"])
    self:SetText(go, "bg/name", GameTextLoader:ReadText(self.m_cfgProducts[productId]["name"]))
    if self.m_selectedProduct == productId then
        self:GetGo(go, "bg/unlocked/selected"):SetActive(true)
    else
        self:GetGo(go, "bg/unlocked/selected"):SetActive(false)
    end
    local bgBtn = self:GetComp(go, "bg", "Button")
    self:SetButtonClickHandler(bgBtn, function()
        self.m_selectedProduct = productId
        self:refreshStorehouseUI(self.WorkShopId)
    end)
end

function WorkShopInfoUIView:PlayBuffAnim()
    --buff栏的圈       
    local productRoot = self:GetGo("RootPanel/productPanel/bottom/detail")
    local buffImage = self:GetComp(productRoot, "bonus/state/prog/Fill", "Image")     
    local wpBuff = self.m_data.buff   
    local cfg = ConfigMgr.config_boost[wpBuff.type]
    self:GetGo(productRoot, "bonus"):SetActive(true)
    local icon = self:GetComp(productRoot, "bonus/state/icon","Image")
    self:SetSprite(icon, "UI_Shop", cfg.icon)
    self:SetText(productRoot, "bonus/state/buff", "+" .. cfg.buff * 100 .. "%")
    self:SetText(productRoot, "bonus/state/prog/time", TimerMgr:FormatTimeLength(wpBuff.timePoint - TimerMgr:GetCurrentServerTime(true)))  
    buffImage.fillAmount = (wpBuff.timePoint - TimerMgr:GetCurrentServerTime(true)) / cfg.duration

    self:GetGo("RootPanel/productPanel/bottom/detail/bonus"):SetActive(true)
    local feel = self:GetComp("RootPanel/productPanel/bottom/detail/bonus/state/openFB", "MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end
end

--生产流水线菜单 -- 一小时的产出
function WorkShopInfoUIView:RefreshProductionPanel()   
    FactoryMode:PiecewiseCalculation(36000, true, function(addList)  
    local GuideData = LocalDataManager:GetDataByKey("guide_data")  
    --初次点击埋点
    if not GuideData["done610"] then
        GameSDKs:TrackForeign("factory_first_enter", {renown_new = tonumber(GameTableDefine.StarMode:GetStar()) or 0, state = 3}) --初次接触工厂埋点
        GuideData["done610"] = true
    end 
        local productsCfg = CfgMgr.config_products 
        local factoryDate = {}
        local cfg = {}
        local ordPr ={}        
        for k,v in pairs(productsCfg) do
            local curr = {}
            curr.productId = k
            curr.weight = FactoryMode:GetWeight(k)
            table.insert(factoryDate, curr)  
        end
        table.sort(factoryDate, function(a, b)
            return a.weight > b.weight
        end)
        local Recursion
        Recursion = function(productId, list)
            if not list[productId] then
                local curr = {}
                ordPr[productId] = {}
                local cfg = productsCfg[productId]
                curr.id = productId
                curr.son = {}
                for k,v in pairs(cfg.need_product) do
                    if v.type == 0 then
                        break
                    end
                    Recursion(v.type, curr.son)
                end                
                table.insert(list, curr)
            end
        end
        for k,v in ipairs(factoryDate) do
            if not ordPr[v.productId] then
                Recursion(v.productId, cfg)
            end
        end

        ----------------------------------------------------------------
        local processPanel = self:GetGo("processPanel")
        processPanel:SetActive(true)
        self:SetButtonClickHandler(self:GetComp(processPanel ,"RootPanel/HeadPanel/quitBtn", "Button"), function()
            processPanel:SetActive(false)            
        end)
        self:CreatItemList(cfg, addList)
        self:CreatBottomPanel(cfg, addList)
    end)  
end

--生成图标
function WorkShopInfoUIView:CreatItemList(cfg, addList)
    if not self.choiceNum then
        self.choiceNum = 1
    end
    local currCfg = cfg[self.choiceNum]
    local temp = self:GetGo("processPanel/RootPanel/MidPanel/Viewport/Content/temp")
    for k,v in pairs(temp.transform.parent.transform) do
        if v.name ~= "temp" then
            GameObject.Destroy(v.gameObject)
        end
    end
    temp:SetActive(false)
    local tempNum = 1
    SetState = function(go, cfg)
        local id = cfg.id
        local state = 1 --没有生成
        local p_List = WorkShopInfoUI:GetProductList()
        local generating = false
        local addNum = addList[id] or 0
        for k,v in pairs(FactoryMode:GetTheFactoryData()) do
            if v.productId and v.productId == id and v.state == 2 then
                generating = true
                break
            end
        end                
        if not p_List[id] then
            state = 0 --没有解锁
        elseif generating then
            state = 2 --生成中
        end
        cfg.state = state
        local currRoot
        if state == 0 then
            currRoot = self:GetGo(go, "product/locked")            
            local workShopTyep = GameTextLoader:ReadText("TXT_FACTORY_WORKSHOP_" .. self.m_cfgProducts[cfg.id].workshop_require[1])
            local dose = string.format(GameTextLoader:ReadText("TXT_FACTORY_CONDITION"), self.m_cfgProducts[cfg.id].workshop_require[2], workShopTyep) 
            self:SetText(currRoot, "bg/state/locked/txt", dose)
        elseif state == 1 then
            currRoot = self:GetGo(go, "product/stop")
        else
            currRoot = self:GetGo(go, "product/producing")
        end   
        local change
        if addNum >= 0 then
            change = self:GetGo(currRoot, "bg/state/change") 
            
        else
            change = self:GetGo(currRoot, "bg/state/change_bad")

        end
        change:SetActive(true)
        if addNum >= 0 then        
            self:SetText(change, "num", "+" .. Tools:SeparateNumberWithComma(math.floor(addNum / 10)) .. "/H")
        else
            self:SetText(change, "num", Tools:SeparateNumberWithComma(math.floor(addNum / 10)) .. "/H")
        end
        currRoot:SetActive(true)

        local productCfg = self.m_cfgProducts[id]    
        local icon = self:GetComp(currRoot, "bg/bg/icon", "Image") 
        self:SetSprite(icon, "UI_Common", productCfg.icon)
        self:SetText(currRoot, "bg/name/text", GameTextLoader:ReadText(productCfg.name))
        local productNum = WorkShopInfoUI:GetProductNum(id)
        self:SetText(currRoot, "bg/state/storage/num", Tools:SeparateNumberWithComma(productNum))
        --self:SetText(currRoot, "bg/state/storage/num", Tools:SeparateNumberWithComma(self.productsData[tostring(id)] or 0))
        
        return state

    end
    local SetLine
    SetLine = function(cfg)
        local go = cfg.go 
        if Tools:GetTableSize(cfg.son) == 1 then        
            local state = cfg.son[1].state
            self:GetGo(go,"lineLevel/1/locked"):SetActive(state == 0)                
            self:GetGo(go,"lineLevel/1/stop"):SetActive(state == 1) 
            self:GetGo(go,"lineLevel/1/producing"):SetActive(state == 2)            
        elseif Tools:GetTableSize(cfg.son) == 2 then
            local state1 = cfg.son[1].state
            local state2 = cfg.son[2].state
            
            self:GetGo(go,"lineLevel/2/group1/locked"):SetActive(state1 == 0)
            self:GetGo(go,"lineLevel/2/group1/stop"):SetActive(state1 == 1)
            self:GetGo(go,"lineLevel/2/group1/producing"):SetActive(state1 == 2)

            self:GetGo(go,"lineLevel/2/group2/locked"):SetActive(state2 == 0)
            self:GetGo(go,"lineLevel/2/group2/stop"):SetActive(state2 == 1)
            self:GetGo(go,"lineLevel/2/group2/producing"):SetActive(state2 == 2)      
        else

        end
        for k,v in ipairs(cfg.son) do
            SetLine(v)
        end
    end

    if not self.productionPanelCfg then
        self.productionPanelCfg = {}
    end
    local CopyTemp
    CopyTemp = function(cfg, parent)
        local go = GameObject.Instantiate(temp, parent.transform)
        go:SetActive(true)
        self.productionPanelCfg[cfg.id] = go
        cfg.state = SetState(go, cfg)
        cfg.go = go
        --画线
        if Tools:GetTableSize(cfg.son) == 1 then       
            self:GetGo(go,"lineLevel/1/locked"):SetActive(cfg.state == 0)                
            self:GetGo(go,"lineLevel/1/stop"):SetActive(cfg.state == 1) 
            self:GetGo(go,"lineLevel/1/producing"):SetActive(cfg.state == 2)            
        elseif Tools:GetTableSize(cfg.son) == 2 then
            
            self:GetGo(go,"lineLevel/2/group1/locked"):SetActive(cfg.state == 0)
            self:GetGo(go,"lineLevel/2/group1/stop"):SetActive(cfg.state == 1)
            self:GetGo(go,"lineLevel/2/group1/producing"):SetActive(cfg.state == 2)

            self:GetGo(go,"lineLevel/2/group2/locked"):SetActive(cfg.state == 0)
            self:GetGo(go,"lineLevel/2/group2/stop"):SetActive(cfg.state == 1)
            self:GetGo(go,"lineLevel/2/group2/producing"):SetActive(cfg.state == 2)      
        else
        
        end
        --自动画线
        -- if needLine then
        --     GameTimer:CreateNewMilliSecTimer(1000, function()                             
        --         local LineRenderer = self:GetComp(go, "lineLevel", "LineRenderer")
        --         local startFoldSpot = self:GetGo(parent.transform.parent.gameObject, "startFoldSpot").transform.position                
        --         local startSpot = self:GetGo(parent.transform.parent.gameObject, "startSpot").transform.position                
        --         local endSpot = self:GetGo(go, "endSpot").transform.position                
        --         local endFoldSpot = self:GetGo(go, "endFoldSpot").transform.position
                
        --         -- startFoldSpot = V3(startFoldSpot.x, startFoldSpot.y,  -1)
        --         -- startSpot = V3(startSpot.x, startSpot.y,  -1)
        --         -- endSpot = V3(endSpot.x, endSpot.y,  -1)
        --         -- endFoldSpot = V3(endFoldSpot.x, endFoldSpot.y,  -1)
        --         -- local startFoldSpot = GameUIManager.m_uiCamera:ScreenToWorldPoint(self:GetGo(parent, "startFoldSpot").transform.localPosition)
        --         -- local startSpot = GameUIManager.m_uiCamera:ScreenToWorldPoint(self:GetGo(parent, "startSpot").transform.localPosition)
        --         -- local endSpot = GameUIManager.m_uiCamera:ScreenToWorldPoint(self:GetGo(go, "endSpot").transform.localPosition)
        --         -- local endFoldSpot = GameUIManager.m_uiCamera:ScreenToWorldPoint(self:GetGo(go, "endFoldSpot").transform.localPosition)


        --         LineRenderer.positionCount = 4
        --         LineRenderer:SetPosition(0, startSpot)
        --         LineRenderer:SetPosition(1, startFoldSpot)
        --         LineRenderer:SetPosition(2, endFoldSpot)
        --         LineRenderer:SetPosition(3, endSpot)
        --     end, false, false)
        -- end

        for k,v in ipairs(cfg.son) do
            CopyTemp(v, self:GetGo(go, "slot"))
        end
    end
    CopyTemp(cfg[self.choiceNum], temp.transform.parent)
    
    --SetLine(cfg[self.choiceNum])

end

--创建按钮
function WorkShopInfoUIView:CreatBottomPanel(cfg, addList)
    local leftBtn = self:GetComp("processPanel/RootPanel/BottomPanel/leftBtn", "Button")
    local rightBtn = self:GetComp("processPanel/RootPanel/BottomPanel/rightBtn", "Button")
    local point = self:GetGo("processPanel/RootPanel/BottomPanel/Point/temp")
    for k,v in pairs(point.transform.parent.transform) do
        if v.name == "temp(Clone)" then
            GameObject.Destroy(v.gameObject)
        end
    end
    local SetPoint = function(go, index)
        self:GetGo(go,"off"):SetActive(self.choiceNum ~= index)
        self:GetGo(go,"on"):SetActive(self.choiceNum == index)        
    end
    point:SetActive(false)
    local pointGoList = {}
    for k,v in ipairs(cfg) do
        local parent = point.transform.parent
        local go = GameObject.Instantiate(point, parent.transform)
        go:SetActive(true)
        SetPoint(go, k)
        table.insert(pointGoList, go)
    end
    self:SetButtonClickHandler(leftBtn, function()
        self:SwitchButton(false, cfg)
        self:CreatItemList(cfg, addList)
        for k,v in pairs(pointGoList) do
            SetPoint(v, k)
        end
    end)
    self:SetButtonClickHandler(rightBtn, function()
        self:SwitchButton(true, cfg)
        self:CreatItemList(cfg, addList)
        for k,v in pairs(pointGoList) do
            SetPoint(v, k)
        end
    end)
end

--选择按钮
function WorkShopInfoUIView:SwitchButton(add, cfg)
    if not self.choiceNum then
        self.choiceNum = 1
    end
    if add then
        if self.choiceNum + 1 > #cfg then
            self.choiceNum = 1
            return
        end
        self.choiceNum = self.choiceNum + 1
    else
        if self.choiceNum - 1 < 1 then
            self.choiceNum = #cfg
            return
        end
        self.choiceNum = self.choiceNum - 1
    end                                    
end

--实时刷新的
function WorkShopInfoUIView:UpdataProductsNum()
    local storehouseRoot = self:GetGo("RootPanel/storagePanel/bottom") 
    local slider = self:GetComp(storehouseRoot, "storage/prog", "Slider")
    
    local currentLimit, storageLimit = WorkShopInfoUI:storageLimit()
    local buffImage = self:GetComp("RootPanel/productPanel/bottom/detail/bonus/state/prog/Fill", "Image") 
    self.updataTime = GameTimer:CreateNewMilliSecTimer(1000, function()
        --self.productsData = WorkShopInfoUI:GetProductsData()
        local allProductsNum = WorkShopInfoUI:GetTheTotal() 
        --2024-11-26fy添加容错
        if not allProductsNum then
            return
        end
        if self.type == 104 then                         
            slider.value = allProductsNum / storageLimit
            self:SetText(storehouseRoot, "storage/stock/num", allProductsNum .. "/" .. storageLimit)
            local productNum = WorkShopInfoUI:GetProductNum(self.m_selectedProduct)
            self:SetText(storehouseRoot, "detail/selected/stock/num", tostring(productNum))
            --self:SetText(storehouseRoot, "detail/selected/stock/num", self.productsData[tostring(self.m_selectedProduct)])
        end       
        self:SetText("processPanel/RootPanel/HeadPanel/storage/num", allProductsNum .. "/" .. storageLimit)
        for k,v in pairs(self.productionPanelCfg or {}) do
            local productNum = WorkShopInfoUI:GetProductNum(k)
            if productNum then
                self:SetText(v, "product/producing/bg/state/storage/num", Tools:SeparateNumberWithComma(productNum))
            end
            --self:SetText(v, "product/producing/bg/state/storage/num", Tools:SeparateNumberWithComma(self.productsData[tostring(k)] or 0))
        end
        if FactoryMode:CheckBuffUsefor(self.m_data) then
            local wpBuff = self.m_data.buff
            local cfg = ConfigMgr.config_boost[wpBuff.type]
            --self:GetGo("RootPanel/productPanel/bottom/detail/bonus"):SetActive(true)
            local time = wpBuff.timePoint - TimerMgr:GetCurrentServerTime(true)
            self:SetText("RootPanel/productPanel/bottom/detail/bonus/state/prog/time", TimerMgr:FormatTimeLength(time))
            buffImage.fillAmount = (time) / cfg.duration
        end
    end, true, true)
end

--创建一种以为gameObject为Key的循环时间  
function WorkShopInfoUIView:CreateTimerByGo(intervalInMilliSec, func, isLoop, execImmediately, gameObject)
    if not self.goTimerList then
        self.goTimerList = {}
    end
    if self.goTimerList[gameObject] then
        GameTimer:StopTimer(self.goTimerList[gameObject])
    end
    if isLoop then    
        self.goTimerList[gameObject] = GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, isLoop, execImmediately)
    else
        GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, false, execImmediately)
    end    
end

function WorkShopInfoUIView:OnExit()
    if self.setListDataTimeHandler then
        GameTimer:StopTimer(self.setListDataTimeHandler)
        self.setListDataTimeHandler = nil
    end
    for k,v in pairs(self.goTimerList or {}) do
        GameTimer:StopTimer(v)
    end
    self.goTimerList = nil
    GameTimer:StopTimer(self.updataTime)
    self.updataTime = nil
    self.super:OnExit(self)
    self:StopTimer()
end

return WorkShopInfoUIView
 