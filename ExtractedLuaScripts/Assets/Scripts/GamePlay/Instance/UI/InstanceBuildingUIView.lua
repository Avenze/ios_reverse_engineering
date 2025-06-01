--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-24 10:11:12
]]

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

local InstanceDataManager = GameTableDefine.InstanceDataManager
local InstanceModel = GameTableDefine.InstanceModel
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI
local ShopInstantUI = GameTableDefine.ShopInstantUI
local GameUIManager = GameTableDefine.GameUIManager

local roomsConfig = nil
local furnitureLevelConfig = nil
local furnitureConfig = nil
local resConfig = nil

local InstanceBuildingUIView = Class("InstanceBuildingUIView", UIView)

function InstanceBuildingUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

local selectIndex = 1   --正在选择的item索引
local lastSelectedIndex = 1
local currentLabel = 1    --1是家具,2是员工
local UItype = 1    --1是工厂,2是补给,3是港口
local isOpen = false   


function InstanceBuildingUIView:OnEnter()
    
    GameTableDefine.InstanceMainViewUI:SetPackActive(false)
    GameTableDefine.InstanceMainViewUI:SetEventActive(false)
    
    roomsConfig = InstanceDataManager.config_rooms_instance
    furnitureLevelConfig = InstanceDataManager.config_furniture_level_instance
    furnitureConfig = InstanceDataManager.config_furniture_instance
    resConfig = InstanceDataManager.config_resource_instance

    self:SetButtonClickHandler(self:GetComp("bgCover","Button"), function()
        self:DestroyModeUIObject()
    end)

    InstanceMainViewUI:SetAchievementActive(false)

    self.btnPanel = self:GetGo("RootPanel/BtnPanel")
    self.factoryUI = self:GetGo("RootPanel/ProductionInfo")
    self.supplyBuildingUI = self:GetGo("RootPanel/NeedInfo")
    self.wharUI = self:GetGo("RootPanel/PortInfo")

    
    self.timer = GameTimer:CreateNewTimer(1,function()
        if UItype == 1 then
            self:ShowFactoryUI(self.roomID,selectIndex)
        elseif  UItype == 2 then
            self:ShowSupplyBuildingUI(self.roomID,selectIndex)
        elseif UItype == 3 then
            self:ShowWharfUI(self.roomID,selectIndex)
        end
    end,true,false)

end

function InstanceBuildingUIView:OnExit()
    GameTableDefine.InstanceMainViewUI:SetPackActive(true)
    GameTableDefine.InstanceMainViewUI:SetEventActive(true)
    
    InstanceMainViewUI:SetAchievementActive(true)
	self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
    currentLabel = 1

    local SceneObjectRange = GameUIManager:GetUIByType(ENUM_GAME_UITYPE.INSTANCE_MAIN_VIEW_UI, self.m_guid).m_uiObj
    SceneObjectRange = self:GetGo("SceneObjectRange")
    local cameraFocus = self:GetComp(SceneObjectRange,"","CameraFocus")
    InstanceModel:LookAtSceneGO(self.roomID,selectIndex,cameraFocus,true)
    InstanceModel:ShowSelectFurniture(nil)
end

function InstanceBuildingUIView:ShowFactoryUI(roomID,select,isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    UItype = 1
    local roomCfg = roomsConfig[roomID]

    self.roomID = roomID
    self.btnPanel:SetActive(true)
    self.factoryUI:SetActive(true)
    self.supplyBuildingUI:SetActive(false)
    self.wharUI:SetActive(false)

    --**********************************数据整理*************************************

    --获取所有家具信息
    self.factoryFurData = InstanceDataManager:GetCurRoomData(roomID).furList
    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]

    --计算所有产出
    local productionID = roomCfg.production
    local productionNum = InstanceModel:GetRoomProduction(self.roomID)
    local productionCfg = resConfig[productionID]

    --获取原料信息
    local showNeed = Tools:GetTableSize(roomCfg.material)>1
    local needID = roomCfg.material[1]
    local resCfg = resConfig[needID]
    
    --计算CD
    local allReduce = InstanceModel:GetRoomCDReduce(self.roomID)
    local cd = roomCfg.bastCD - allReduce

    local needCount,resCfg = InstanceModel:GetRoomMatCost(self.roomID)

    --**********************************显示UI*************************************
    --BtnPanel
    local furnitureList = self:GetGo("RootPanel/ProductionInfo/furniture")
    local employeeList = self:GetGo("RootPanel/ProductionInfo/employeeList")
    local furnitureBtn = self:GetComp("RootPanel/BtnPanel/furnitureBtn","Button")
    local employeeBtn = self:GetComp("RootPanel/BtnPanel/employeeBtn","Button")


    furnitureBtn.interactable = currentLabel ~= 1
    employeeBtn.interactable = currentLabel ~= 2
    if currentLabel == 1 then
        self:GetGo("RootPanel/BtnPanel/bg2").transform:SetAsFirstSibling()
        employeeBtn.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
    else
        self:GetGo("RootPanel/BtnPanel/bg2").transform:SetAsFirstSibling()
        furnitureBtn.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
    end

    local product = self:GetGo("RootPanel/ProductionInfo/product")
    local employee = self:GetGo("RootPanel/ProductionInfo/employee")
    
    self:SetButtonClickHandler(furnitureBtn,function()
        employee:SetActive(false)
        product:SetActive(true)
        currentLabel = 1
        furnitureList:SetActive(true)
        employeeList:SetActive(false)
        self:ShowFactoryUI(roomID,selectIndex)
    end)
    self:SetButtonClickHandler(employeeBtn,function()
        employee:SetActive(true)
        product:SetActive(false)
        currentLabel = 2
        furnitureList:SetActive(false)
        employeeList:SetActive(true)
        self:ShowFactoryUI(roomID,selectIndex)
    end)

    --title
    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/title/name",GameTextLoader:ReadText(roomCfg.name))
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need"):SetActive(false)
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/storage"):SetActive(false)

    --总览
    self:SetText(employee,"bg/hunger/consume/num",string.format("-%d/day",currentFurLevelCfg.weaken * 6))
    self:SetText(employee,"bg/sleep/consume/num",string.format("-%d/day",currentFurLevelCfg.weaken * 6))
    
    if showNeed then   --原料
        self:GetGo("RootPanel/ProductionInfo/product/bg/matierial"):SetActive(true)
        self:GetGo("RootPanel/ProductionInfo/product/bg/1"):SetActive(true)

        self:SetImageSprite("RootPanel/ProductionInfo/product/bg/matierial/logo",resCfg.icon,nil)
        local needNumStr  = Tools:SeparateNumberWithComma(needCount)
        self:SetText("RootPanel/ProductionInfo/product/bg/matierial/count/num",needNumStr)
    else    
        self:GetGo("RootPanel/ProductionInfo/product/bg/matierial"):SetActive(false)
        self:GetGo("RootPanel/ProductionInfo/product/bg/1"):SetActive(false)
    end
    self:SetText("RootPanel/ProductionInfo/product/bg/cooltime/time/num",cd.."s")    --cd
    self:SetImageSprite("RootPanel/ProductionInfo/product/bg/production/logo",productionCfg.icon,nil)   --产出
    local productionCountStr  = Tools:SeparateNumberWithComma(productionNum)
    if not InstanceModel:GetLandMarkCanPurchas() then
        self:GetGo("RootPanel/ProductionInfo/product/bg/production/buffBtn"):SetActive(true)
        local instanceBind = InstanceDataManager:GetInstanceBind()
        local landmarkID = instanceBind.landmark_id
        local shopCfg = ConfigMgr.config_shop[landmarkID]
        local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
        productionNum = math.floor(productionNum * (1 + resAdd/100))
        productionCountStr  = Tools:SeparateNumberWithComma(productionNum)
    else
        self:GetGo("RootPanel/ProductionInfo/product/bg/production/buffBtn"):SetActive(false)
    end
    self:SetText("RootPanel/ProductionInfo/product/bg/production/count/num",productionCountStr)

    --显示点击的设备信息
    if currentLabel == 1 then
        self:SetImageSprite("RootPanel/ProductionInfo/furniture/info/main/icon",currentFurLevelCfg.icon)
        self:SetText("RootPanel/ProductionInfo/furniture/info/main/name",GameTextLoader:ReadText(currentFurCfg.name))
        self:SetText("RootPanel/ProductionInfo/furniture/info/main/level/bg/num",currentFurLevelCfg.level)
        self:SetText("RootPanel/ProductionInfo/furniture/info/main/desc",GameTextLoader:ReadText(currentFurCfg.desc))
    
        local currentFurMaxLevel = self:GetFurnitureMaxlevel(currentFurLevelCfg.furniture_id)
        local buyButton = self:GetComp("RootPanel/ProductionInfo/furniture/info/main/btn","Button")
        local maxButton = self:GetComp("RootPanel/ProductionInfo/furniture/info/main/maxlvl","Button")

        local willBuy = currentFurLevelCfg.level
        if self.factoryFurData[tostring(selectIndex)].state ~= 0 and currentFurLevelCfg.level < currentFurMaxLevel then
            willBuy = willBuy + 1
        end
        local willBuyFurLevelCfg = InstanceModel:GetFurlevelConfig(currentFurLevelCfg.furniture_id, willBuy)
        
        if currentFurLevelCfg.level < currentFurMaxLevel then --未达到最大等级,可继续购买升级设备
            buyButton.gameObject:SetActive(true)
            maxButton.gameObject:SetActive(false)
            local canBuy,conditions = InstanceModel:CheckFuinitureCondition(willBuyFurLevelCfg.id)
            --buyButton.interactable = canBuy
            self:SetText(buyButton.gameObject,"num",Tools:SeparateNumberWithComma(conditions))
            self:SetButtonClickHandler(buyButton,function()
 
                --购买
                if canBuy then
                    local cost = willBuyFurLevelCfg.cost
                    InstanceModel:BuyFurniture(self.roomID,selectIndex,willBuyFurLevelCfg.id)

                else
                    ShopInstantUI:EnterToPesoBuy()
                end
                self:ShowFactoryUI(self.roomID,selectIndex)
            end)
        else    --已达到最大等级,不可继续操作
            buyButton.gameObject:SetActive(false)
            maxButton.gameObject:SetActive(true)
        end

        local showWorker = willBuyFurLevelCfg.isPresonFurniture
        self:GetGo("RootPanel/ProductionInfo/furniture/info/main/bonous/seat"):SetActive(showWorker)
        local showProdction = willBuyFurLevelCfg.product > 0 
        if showProdction then
            self:GetGo("RootPanel/ProductionInfo/furniture/info/main/bonous/resouce"):SetActive(true)
            local prodCount = InstanceModel:GetFurLevelCfgAttrSum(currentFurLevelCfg.id,"product")
            local prodStr = prodCount
            if currentFurLevelCfg.level < currentFurMaxLevel then
                prodStr = string.format("%d%s",prodCount,Tools:ChangeTextColor(("+"..willBuyFurLevelCfg.product or 0),"57c92f"))
            end
            if willBuy == 1 then
                prodStr = prodCount
            end
            self:SetText("RootPanel/ProductionInfo/furniture/info/main/bonous/resouce/num",prodStr)
            self:SetImageSprite("RootPanel/ProductionInfo/furniture/info/main/bonous/resouce/icon",productionCfg.icon)
        else
            self:GetGo("RootPanel/ProductionInfo/furniture/info/main/bonous/resouce"):SetActive(false)
        end
        local showCD = willBuyFurLevelCfg.cooltime > 0  
        if showCD then
            self:GetGo("RootPanel/ProductionInfo/furniture/info/main/bonous/cooltime"):SetActive(true)
            local cdReduce = InstanceModel:GetFurLevelCfgAttrSum(currentFurLevelCfg.id,"cooltime")
            local cdStr = cdReduce
            if currentFurLevelCfg.level < currentFurMaxLevel then
                cdStr = cdReduce.."s"..Tools:ChangeTextColor("-"..willBuyFurLevelCfg.cooltime or 0,"57c92f")   
            end
            if willBuy == 1 then
                cdStr = cdReduce
            end
            self:SetText("RootPanel/ProductionInfo/furniture/info/main/bonous/cooltime/num","-"..cdStr.."s")
        else
            self:GetGo("RootPanel/ProductionInfo/furniture/info/main/bonous/cooltime"):SetActive(false)
        end

    end

    --显示item
    if currentLabel == 1 then   --家具标签,显示家具列表
        self.furnitureListScroll = self:GetComp("RootPanel/ProductionInfo/furniture/list", "ScrollRectEx")
        self:SetListItemCountFunc( self.furnitureListScroll, function()
            return Tools:GetTableSize(self.factoryFurData)
        end)
        self:SetListUpdateFunc( self.furnitureListScroll, handler(self,self.UpdateFactoryFurItem))
        self.furnitureListScroll:UpdateData()

    
    else    --员工标签,显示员工列表
        local employeeListScroll = self:GetComp(employeeList,"","ScrollRectEx")
        self:SetListItemCountFunc(employeeListScroll, function()
            local count = 0 
            for k,v in pairs(self.factoryFurData) do
                if v.worker then
                    count = count + 1
                end
            end

            return count
        end)
        self:SetListUpdateFunc(employeeListScroll, handler(self, self.UndateEmployeeItem))
        employeeListScroll:UpdateData()

    end

end

function InstanceBuildingUIView:UpdateFactoryFurItem(index,trans)
    local index = index + 1
    local go = trans.gameObject
    local currentFurData = self.factoryFurData[tostring(index)]
    local currentFurLevelCfg = furnitureLevelConfig[currentFurData.id]

    local selected = self:GetGo(go,"Btn/selected")
    local unlocked = self:GetGo(go,"Btn/unlocked")
    local locked = self:GetGo(go,"Btn/locked")
    local root = nil
    if selectIndex == index then
        root = selected
        selected:SetActive(true)
        unlocked:SetActive(false)
        locked:SetActive(false)
    else
        selected:SetActive(false)

        if currentFurData.state == 0 then
            root = locked
            unlocked:SetActive(false)
            locked:SetActive(true)
        else 
            root = unlocked
            unlocked:SetActive(true)
            locked:SetActive(false)
        end
    end
    local image = self:GetComp(root,"icon","Image")
    self:SetSprite(image,"UI_Common",currentFurLevelCfg.icon)
    local showLevel = currentFurLevelCfg.level
    if currentFurData.state == 0 then
        showLevel = 0
    end
    self:SetText(root,"level/num",showLevel)
    self:SetButtonClickHandler(self:GetComp(go,"Btn","Button"),function()
        selectIndex = index
        self:ShowFactoryUI(self.roomID,selectIndex)
        self:SelectFurniture(selectIndex,currentFurData)

    end)
    if isOpen and index == selectIndex then
        self:SelectFurniture(index,currentFurData)
    end
end

function InstanceBuildingUIView:UndateEmployeeItem(index,trans)
    index = index + 1
    local go = trans.gameObject
    local currentFurData = self.factoryFurData[tostring(index)]
    if currentFurData.state == 0 then
        self:GetGo(go,"lock"):SetActive(true)
        self:GetGo(go,"unlock"):SetActive(false)
        return
    else
        self:GetGo(go,"lock"):SetActive(false)
        self:GetGo(go,"unlock"):SetActive(true)
    end

    local currentFurLevelCfg = furnitureLevelConfig[currentFurData.id]
    local workerData = currentFurData.worker
    if not workerData and currentFurData ~= 1 then
        return
    end
    local characterNameCfg = ConfigMgr.config_character_name
    local lang = GameLanguage:GetCurrentLanguageID()
    local name = GameTextLoader:ReadText(characterNameCfg.first[workerData.name[1]] or 1)
    if lang == "cn" or lang == "tc" then
        name = name..GameTextLoader:ReadText(characterNameCfg.second[workerData.name[2]] or 1)
    end
    self:SetText(go,"unlock/icon/name/txt",name)
    --2023-10-24设置配置的icon
    if tonumber(workerData.prefab) then
        local characterCfg = ConfigMgr.config_character[tonumber(workerData.prefab)]
        if characterCfg and characterCfg.character_icon ~= "0" then
            local image = self:GetComp(go, "unlock/icon/head", "Image")
            self:SetSprite(image, "UI_Common", characterCfg.character_icon)
        end
    end
    local currentHungryStr = math.floor(workerData.attrs.hungry)
    if workerData.attrs.hungry < ConfigMgr.config_global.instance_state_threshold then
        currentHungryStr = Tools:ChangeTextColor(currentHungryStr,"ff0000")
    else    
        currentHungryStr = Tools:ChangeTextColor(currentHungryStr,"ffffff")
    end
    local currentPhisicalStr =  math.floor(workerData.attrs.physical)
    if workerData.attrs.physical < ConfigMgr.config_global.instance_state_threshold then
        currentPhisicalStr = Tools:ChangeTextColor(currentPhisicalStr,"ff0000")
    else    
        currentPhisicalStr = Tools:ChangeTextColor(currentPhisicalStr,"ffffff")
    end
    self:SetText(go,"unlock/state/hunger/info/progress/pro",string.format("%s/%d",currentHungryStr , math.floor(ConfigMgr.config_global.instance_employee_upperlimit)))
    self:GetComp(go,"unlock/state/hunger/info/progress","Slider").value = workerData.attrs.hungry/ConfigMgr.config_global.instance_employee_upperlimit
    self:SetText(go,"unlock/state/phisical/info/progress/pro",string.format("%s/%d",currentPhisicalStr, math.floor(ConfigMgr.config_global.instance_employee_upperlimit)))
    self:GetComp(go,"unlock/state/phisical/info/progress","Slider").value = workerData.attrs.physical/ConfigMgr.config_global.instance_employee_upperlimit

    local minAttr = {}
    if workerData.attrs.hungry < workerData.attrs.physical then
        minAttr = {type = "hungry",num = workerData.attrs.hungry}
    else
        minAttr = {type = "physical",num = workerData.attrs.physical}
    end
    if minAttr.num < ConfigMgr.config_global.instance_state_threshold then
        if minAttr.type == "hungry" then
            self:GetGo(go,"unlock/icon/debuff/hunger"):SetActive(true)                
            self:GetGo(go,"unlock/icon/debuff/physical"):SetActive(false)                
        else
            self:GetGo(go,"unlock/icon/debuff/hunger"):SetActive(false)                
            self:GetGo(go,"unlock/icon/debuff/physical"):SetActive(true)      
        end
    else
        self:GetGo(go,"unlock/icon/debuff/hunger"):SetActive(false)                
        self:GetGo(go,"unlock/icon/debuff/physical"):SetActive(false)
    end
end


function InstanceBuildingUIView:ShowSupplyBuildingUI(roomID,select,isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    UItype = 2
    local roomCfg = roomsConfig[roomID]

    self.roomID= roomID
    self.btnPanel:SetActive(false)
    self.factoryUI:SetActive(false)
    self.supplyBuildingUI:SetActive(true)
    self.wharUI:SetActive(false)

    --**********************************数据整理*************************************

    --获取所有家具信息
    self.SupplyBuildingFurData = InstanceDataManager:GetCurRoomData(roomID).furList
    local currentFurLevelCfg = furnitureLevelConfig[self.SupplyBuildingFurData[tostring(selectIndex)].id]
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]

    --计算所有供给
    local supplySeatSum = InstanceModel:GetRoomSeatCount(roomID)
    local supplyHungerSum = InstanceModel:GetRoomHunger(roomID)
    local supplyPhysicalSum = InstanceModel:GetRoomPhysical(roomID)

    --**********************************显示UI*************************************
    --title
    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/title/name",GameTextLoader:ReadText(roomCfg.name))
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need"):SetActive(true)
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/storage"):SetActive(false)
    if roomCfg.room_category ==2 then
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need/item/hunger"):SetActive(false)
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need/item/physical"):SetActive(true)
        self:SetText("RootPanel/RoomTitle/HeadPanel/bg/need/item/base","+"..supplyPhysicalSum.."/day")

    elseif roomCfg.room_category ==3 then
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need/item/hunger"):SetActive(true)
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need/item/physical"):SetActive(false)
        self:SetText("RootPanel/RoomTitle/HeadPanel/bg/need/item/base","+"..supplyHungerSum * 2 .."/day")
    end

    --显示点击的设备信息
    self:SetImageSprite("RootPanel/NeedInfo/furniture/info/main/icon",currentFurLevelCfg.icon)
    self:SetText("RootPanel/NeedInfo/furniture/info/main/name",GameTextLoader:ReadText(currentFurCfg.name))
    self:SetText("RootPanel/NeedInfo/furniture/info/main/level/bg/num",currentFurLevelCfg.level)
    self:SetText("RootPanel/NeedInfo/furniture/info/main/desc",GameTextLoader:ReadText(currentFurCfg.desc))

    local currentFurMaxLevel = self:GetFurnitureMaxlevel(currentFurLevelCfg.furniture_id)
    local buyButton = self:GetComp("RootPanel/NeedInfo/furniture/info/main/btn","Button")
    local maxButton = self:GetComp("RootPanel/NeedInfo/furniture/info/main/maxlvl","Button")
    local willBuy = currentFurLevelCfg.level
    local isMaxLevel = currentFurLevelCfg.level >= currentFurMaxLevel
    if self.SupplyBuildingFurData[tostring(selectIndex)].state ~= 0 and not isMaxLevel then
        willBuy = willBuy + 1
    end
    local willBuyFurLevelCfg = InstanceModel:GetFurlevelConfig(currentFurLevelCfg.furniture_id, willBuy)    
    if isMaxLevel then
        buyButton.gameObject:SetActive(false)
        maxButton.gameObject:SetActive(true)
    else
        buyButton.gameObject:SetActive(true)
        maxButton.gameObject:SetActive(false)
        local canBuy,conditions = InstanceModel:CheckFuinitureCondition(willBuyFurLevelCfg.id)
        --buyButton.interactable = canBuy
        self:SetText(buyButton.gameObject,"num",Tools:SeparateNumberWithComma(conditions))
        self:SetButtonClickHandler(buyButton,function()
            -- 购买
            if canBuy then
                local cost = willBuyFurLevelCfg.cost
                InstanceModel:BuyFurniture(self.roomID,selectIndex,willBuyFurLevelCfg.id)
            else
                ShopInstantUI:EnterToPesoBuy()
            end
            self:ShowSupplyBuildingUI(self.roomID,selectIndex)
        end)
    end

    if willBuyFurLevelCfg.seat > 0 then
        local currentSeatCount = InstanceModel:GetFurLevelCfgAttrSum(currentFurLevelCfg.id,"seat")
        local seatStr = currentSeatCount
        if currentFurLevelCfg.level < currentFurMaxLevel then
            seatStr = string.format("%d%s",currentSeatCount,Tools:ChangeTextColor(("+"..willBuyFurLevelCfg.seat),"57c92f"))
        end
        if willBuy == 1 then
            seatStr = currentSeatCount
        end
        self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/seat"):SetActive(true)
        self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/physical"):SetActive(false)
        self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/hunger"):SetActive(false)
        self:SetText("RootPanel/NeedInfo/furniture/info/main/bonous/seat/num",seatStr)
    else
        if roomCfg.room_category == 2 then
            self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/seat"):SetActive(false)
            self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/physical"):SetActive(true)
            self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/hunger"):SetActive(false)
            local physicalCount = InstanceModel:GetFurLevelCfgAttrSum(currentFurLevelCfg.id,"phisical")
            local physicalStr = physicalCount
            if currentFurLevelCfg.level < currentFurMaxLevel then
                local tempStr = tostring(Tools:ChangeTextColor(("+"..willBuyFurLevelCfg.phisical or 0),"57c92f"))
                physicalStr = physicalCount..tempStr
            end
            if willBuy == 1 then
                physicalStr = physicalCount
            end
            self:SetText("RootPanel/NeedInfo/furniture/info/main/bonous/physical/num",physicalStr.."/day")
        elseif roomCfg.room_category == 3 then
            self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/seat"):SetActive(false)
            self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/physical"):SetActive(false)
            self:GetGo("RootPanel/NeedInfo/furniture/info/main/bonous/hunger"):SetActive(true)
            local hungerCount = InstanceModel:GetFurLevelCfgAttrSum(currentFurLevelCfg.id,"hungry")
            local hungerStr = hungerCount * 2
            if currentFurLevelCfg.level < currentFurMaxLevel then
                hungerStr = hungerCount * 2 ..Tools:ChangeTextColor(("+"..(willBuyFurLevelCfg.hungry * 2) or 0),"57c92f")
            end
            if willBuy == 1 then
                hungerStr = hungerCount * 2
            end
            self:SetText("RootPanel/NeedInfo/furniture/info/main/bonous/hunger/num",hungerStr.."/day")
        end
    
    end
   
   
    --显示item
    local furnitureListScroll = self:GetComp("RootPanel/NeedInfo/furniture/list", "ScrollRectEx")
    self:SetListItemCountFunc(furnitureListScroll, function()
        return Tools:GetTableSize(self.SupplyBuildingFurData)
    end)
    self:SetListUpdateFunc(furnitureListScroll, handler(self, self.UpdateSupplyBuildingFurItem))
    furnitureListScroll:UpdateData()

end

function InstanceBuildingUIView:UpdateSupplyBuildingFurItem(index,trans)
    index = index + 1
    local go = trans.gameObject
    local currentFurData = self.SupplyBuildingFurData[tostring(index)]
    local currentFurLevelCfg = furnitureLevelConfig[currentFurData.id]

    local selected = self:GetGo(go,"Btn/selected")
    local unlocked = self:GetGo(go,"Btn/unlocked")
    local locked = self:GetGo(go,"Btn/locked")
    local root = nil
    if selectIndex == index then
        root = selected
        selected:SetActive(true)
        unlocked:SetActive(false)
        locked:SetActive(false)
    else
        selected:SetActive(false)

        if currentFurData.state == 0 then
            root = locked
            unlocked:SetActive(false)
            locked:SetActive(true)
        else
            root = unlocked
            unlocked:SetActive(true)
            locked:SetActive(false)
        end
    end
    local image = self:GetComp(root, "icon", "Image")
    self:SetSprite(image,"UI_Common", currentFurLevelCfg.icon)
    local showLevel = currentFurLevelCfg.level
    if currentFurData.state == 0 then
        showLevel = 0
    end
    self:SetText(root,"level/num", showLevel)
    self:SetButtonClickHandler(self:GetComp(go, "Btn","Button"), function()
        selectIndex = index
        self:ShowSupplyBuildingUI(self.roomID,selectIndex)
        self:SelectFurniture(index,currentFurData)
    end)
    if isOpen and index == selectIndex then
        self:SelectFurniture(index,currentFurData)
    end
end



function InstanceBuildingUIView:ShowWharfUI(roomID,select,isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    
    UItype = 3
    local roomCfg = roomsConfig[roomID]

    self.roomID = roomID
    self.btnPanel:SetActive(false)
    self.factoryUI:SetActive(false)
    self.supplyBuildingUI:SetActive(false)
    self.wharUI:SetActive(true)
    --**********************************数据整理*************************************

    --获取所有家具信息
    self.wharfFurData = InstanceDataManager:GetCurRoomData(roomID).furList
    local curFurLevelID = self.wharfFurData[tostring(selectIndex)].id
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID]
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]

    --**********************************显示UI*************************************
    --title
    self:SetText("RootPanel/RoomTitle/HeadPanel/bg/title/name",GameTextLoader:ReadText(roomCfg.name))
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/need"):SetActive(false)
    self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/storage"):SetActive(true)
    local storage = currentFurLevelCfg.storage
    if storage <= 0 then
        self:GetGo("RootPanel/RoomTitle/HeadPanel/bg/storage"):SetActive(false)
    else    
        local productions = InstanceDataManager:GetProdutionsData()
        local storage = productions[tostring(currentFurLevelCfg.resource_type)] or 0
        storage = math.floor(storage)
        local showStr = Tools:SeparateNumberWithComma(storage).."/"..currentFurLevelCfg.storage
        self:SetText("RootPanel/RoomTitle/HeadPanel/bg/storage/item/base", showStr)
        local materialCfg = resConfig[currentFurLevelCfg.resource_type]
        self:SetImageSprite("RootPanel/RoomTitle/HeadPanel/bg/storage/item/icon",materialCfg.icon)
    end

    --显示点击的设备信息
    self:SetImageSprite("RootPanel/PortInfo/furniture/info/main/icon",currentFurLevelCfg.icon)
    self:SetText("RootPanel/PortInfo/furniture/info/main/name",GameTextLoader:ReadText(currentFurCfg.name))
    self:SetText("RootPanel/PortInfo/furniture/info/main/level/bg/num",currentFurLevelCfg.level)
    self:SetText("RootPanel/PortInfo/furniture/info/main/desc",GameTextLoader:ReadText(currentFurCfg.desc))

    local currentFurMaxLevel = self:GetFurnitureMaxlevel(currentFurLevelCfg.furniture_id)
    local buyButton = self:GetComp("RootPanel/PortInfo/furniture/info/main/btn","Button")
    local maxButton = self:GetComp("RootPanel/PortInfo/furniture/info/main/maxlvl","Button")
    local isMaxLevel = currentFurLevelCfg.level >= currentFurMaxLevel

    local willBuy = currentFurLevelCfg.level
    if self.wharfFurData[tostring(selectIndex)].state ~= 0 then
        willBuy = willBuy + 1
    end
    local willBuyFurLevelCfg = InstanceModel:GetFurlevelConfig(currentFurLevelCfg.furniture_id, willBuy)
    if isMaxLevel then
        buyButton.gameObject:SetActive(false)
        maxButton.gameObject:SetActive(true)
    else
        buyButton.gameObject:SetActive(true)
        maxButton.gameObject:SetActive(false)
        local canBuy,conditions = InstanceModel:CheckFuinitureCondition(willBuyFurLevelCfg.id)
        local showConditionTips = false
        --buyButton.interactable = canBuy
        self:SetText(buyButton.gameObject,"num",Tools:SeparateNumberWithComma(conditions))
        self:SetButtonClickHandler(buyButton,function()
            if willBuyFurLevelCfg.conditionID ~= 0 then --是船
                local matFurLevelCfg = furnitureLevelConfig[willBuyFurLevelCfg.conditionID]

                if self.wharfFurData[tostring(selectIndex-6)].state ~= 1 then
                    showConditionTips = true
                end
            end

            -- 购买
            if canBuy then
                if showConditionTips then
                    local conditionFurLevelCfg = furnitureLevelConfig[willBuyFurLevelCfg.conditionID]
                    local currentFurCfg = furnitureConfig[conditionFurLevelCfg.furniture_id]
                    local showText = string.format(GameTextLoader:ReadText("TXT_TIP_LACK_FACILITY"),GameTextLoader:ReadText(currentFurCfg.name))
                    EventManager:DispatchEvent("UI_NOTE", showText)
                    return
                end
                local cost = willBuyFurLevelCfg.cost
                InstanceModel:BuyFurniture(self.roomID,selectIndex,willBuyFurLevelCfg.id)
            else
                ShopInstantUI:EnterToPesoBuy()
            end
            self:ShowWharfUI(self.roomID,selectIndex)
        end)
    end

    local isPort = true
    if currentFurLevelCfg.storage > 0 then    --选中的item是码头
        isPort = true
    else    
        isPort = false
    end
    
    self:GetGo("RootPanel/PortInfo/furniture/info/main/openState"):SetActive(isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/storage"):SetActive(isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/benifit"):SetActive(isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/localization"):SetActive(not isPort)
    self:GetGo("RootPanel/PortInfo/furniture/info/main/bonous/cooltime"):SetActive(not isPort)
    
    if isPort then  --码头信息
        local isOpen = self.wharfFurData[tostring(selectIndex)].isOpen --港口开关
        local toggle = self:GetComp("RootPanel/PortInfo/furniture/info/main/openState","Toggle")

        if self.wharfFurData[tostring(selectIndex)].state == 1 then
            toggle.interactable = true
            toggle.isOn = not isOpen
        else
            toggle.interactable = false
            toggle.isOn = true
        end

        self:SetToggleValueChangeHandler(toggle,function(bool)
            --print("ToggleValueChange",selectIndex,currentFurLevelCfg.id)
            if  lastSelectedIndex == selectIndex then

            InstanceDataManager:SetRoomFurnitureData(roomID,selectIndex,currentFurLevelCfg.id,{isOpen = not bool})
            local furGO = InstanceModel:GetSceneRoomFurnitureGo(roomID,selectIndex)
            -- local doorPathHead = "Miscellaneous/Environment/Port_1/model/Easter_Men_0"
            -- local doorPath = doorPathHead..selectIndex
            local doorGO = self:GetGo(furGO,"Door")
                if bool then
                    --关
                    local feel = self:GetComp(doorGO,"closeFB","MMFeedbacks")
                    feel:PlayFeedbacks()
                else
                    --开
                    local feel = self:GetComp(doorGO,"openFB","MMFeedbacks")
                    feel:PlayFeedbacks()
                end
            end
 
        end)


        local storage = currentFurLevelCfg.storage  --库存
        local stotageStr = Tools:SeparateNumberWithComma(storage)
        if currentFurLevelCfg.level < currentFurMaxLevel then
            stotageStr = stotageStr ..Tools:ChangeTextColor("+"..Tools:SeparateNumberWithComma( willBuyFurLevelCfg.storage - storage),"57c92f")  
        end 
        if willBuy == 1 then
            stotageStr =  storage
        end
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/storage/num",stotageStr)

        local storage = currentFurLevelCfg.storage  --预期收入
        local sellingPrice = storage * resConfig[currentFurLevelCfg.resource_type].price
        local sellingPriceStr = Tools:SeparateNumberWithComma(sellingPrice) 
        if currentFurLevelCfg.level < currentFurMaxLevel then
            local nextSellingPrice = willBuyFurLevelCfg.storage * resConfig[currentFurLevelCfg.resource_type].price
            sellingPriceStr = sellingPriceStr..Tools:ChangeTextColor("+"..  Tools:SeparateNumberWithComma(nextSellingPrice - sellingPrice),"57c92f")  
        end 
        if willBuy == 1 then
            sellingPriceStr = Tools:SeparateNumberWithComma(sellingPrice) 
        end
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/benifit/num",sellingPriceStr)
    else

        local partLevelID = currentFurLevelCfg.conditionID  --船停靠码头
        local partlevelCfg = furnitureLevelConfig[partLevelID].furniture_id
        local partCfg = furnitureConfig[partlevelCfg]
        local stotageStr = GameTextLoader:ReadText(partCfg.name)
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/localization/num",stotageStr)
        
        local shipCD = currentFurLevelCfg.shipCD  --船CD
        local shipCDStr =  shipCD.."s"
        if currentFurLevelCfg.level < currentFurMaxLevel then
            local cdReduce = willBuyFurLevelCfg.shipCD - shipCD
            shipCDStr = shipCD.."s"..Tools:ChangeTextColor(cdReduce.."s","57c92f")  
        end 
        if willBuy == 1 then
            shipCDStr =  shipCD.."s"
        end
        self:SetText("RootPanel/PortInfo/furniture/info/main/bonous/cooltime/num",shipCDStr)

    end
    

    --显示item
    local furnitureListScroll = self:GetComp("RootPanel/PortInfo/furniture/list", "ScrollRectEx")
    self:SetListItemCountFunc(furnitureListScroll, function()
        return Tools:GetTableSize(self.wharfFurData)
    end)
    self:SetListUpdateFunc(furnitureListScroll, handler(self, self.UpdateWharfFurItem))
    furnitureListScroll:UpdateData()

    lastSelectedIndex = selectIndex
end

function InstanceBuildingUIView:UpdateWharfFurItem(index,trans)
    index = index + 1
    local go = trans.gameObject
    local currentFurData = self.wharfFurData[tostring(index)]
    local currentFurLevelCfg = furnitureLevelConfig[currentFurData.id]
    go.name = currentFurLevelCfg.furniture_id

    local selected = self:GetGo(go,"Btn/selected")
    local unlocked = self:GetGo(go,"Btn/unlocked")
    local locked = self:GetGo(go,"Btn/locked")
    local root = nil
    if selectIndex == index then
        root = selected
        selected:SetActive(true)
        unlocked:SetActive(false)
        locked:SetActive(false)
    else
        selected:SetActive(false)

        if currentFurData.state == 0 then
            root = locked
            unlocked:SetActive(false)
            locked:SetActive(true)
        else
            root = unlocked
            unlocked:SetActive(true)
            locked:SetActive(false)
        end
    end
    local image = self:GetComp(root, "icon", "Image")
    self:SetSprite(image,"UI_Common", currentFurLevelCfg.icon)
    local showLevel = currentFurLevelCfg.level
    if currentFurData.state == 0 then
        showLevel = 0
    end
    self:SetText(root,"level/num",showLevel)
    self:SetButtonClickHandler(self:GetComp(go, "Btn","Button"), function()
        selectIndex = index
        --print("selectIndex",selectIndex)
        self:ShowWharfUI(self.roomID,selectIndex)

        if selectIndex > 6 then
            self:SelectFurniture(index - 6,self.wharfFurData[tostring(selectIndex-6)])
        else    
            self:SelectFurniture(index,currentFurData)
        end
    end)

    if isOpen and index == selectIndex then
        self:SelectFurniture(index,currentFurData)
    end

end


function InstanceBuildingUIView:GetFurnitureMaxlevel(furnitureID)
    local furnitureLevelConfig_furID = InstanceModel.furnitureLevelConfig_furID
    local furLevelCfgs = furnitureLevelConfig_furID[furnitureID]
    local max = 0
    for k,v in pairs(furLevelCfgs) do
        if v.furniture_id == furnitureID and v.level >= max then
            max = v.level
        end
    end
    return max
end

function InstanceBuildingUIView:SelectFurniture(index,furData)

    --将相机焦点移动至所选设备位置
    local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
    InstanceModel:LookAtSceneGO(self.roomID,index,cameraFocus)
    --所选设备闪烁
    local prebuy = furData.state == 0
    local roomCfg = roomsConfig[self.roomID]
    local furGO = nil
    furGO = InstanceModel:GetSceneRoomFurnitureGo(self.roomID,index)

    -- if roomCfg.room_category == 2 or  roomCfg.room_category == 3 then
    --     furGO = InstanceModel:GetSceneRoomFurnitureGo(self.roomID,index,1)
    -- else
    --     furGO = InstanceModel:GetSceneRoomFurnitureGo(self.roomID,index)
    -- end
    
    InstanceModel:ShowSelectFurniture(furGO,prebuy)
end


return InstanceBuildingUIView
