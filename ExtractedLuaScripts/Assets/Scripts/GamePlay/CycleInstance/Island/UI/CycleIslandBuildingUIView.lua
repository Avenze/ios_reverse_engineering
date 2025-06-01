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

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleIslandMainViewUI = GameTableDefine.CycleIslandMainViewUI
local ShopInstantUI = GameTableDefine.ShopInstantUI
local GameUIManager = GameTableDefine.GameUIManager
local CycleIslandHeroManager = GameTableDefine.CycleIslandHeroManager


local roomsConfig = nil
local furnitureLevelConfig = nil
local furnitureConfig = nil
local resConfig = nil

---@classCycleIslandBuildingUIView :UIBaseView
local CycleIslandBuildingUIView = Class("CycleIslandBuildingUIView", UIView)

function CycleIslandBuildingUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_currentModel = nil ---@type CycleInstanceModel
    
    self.RoomHeroPanel = nil
    self.RoomTitlePanel = nil
    self.RoomInfoPanel = nil
    self.BG = nil
    self.RoomCarteen = nil
    self.RoomDormitory = nil
    
    self.HeroIconImage = nil
    self.productImage = nil
    self.upgrageTip = nil
    self.heroTalk = nil
    self.matierial = nil
    self.matierial_1 = nil
    self.matierialImage = nil
    self.stuckIcon = nil
    self.resourceImage = nil
    self.heroBtn = nil
    self.furImage = nil
    self.progressSlider = nil
    self.progressProductImage = nil
    self.progressBonus = nil
    self.progressEmployee = nil
    self.progressResouce = nil
    self.progressResouceImage = nil
    self.upgradeMaxlvl = nil
    self.upgradeBtnGO = nil
    self.feel = nil
    self.upgradeBtn = nil
    self.employeeItem = nil
    self.animator = nil
    self.toggle = nil
    self.cameraFocus = nil
    
    self.lastTipsText = nil
    
    self.UItype = nil    --1是工厂,2是补给,3是港口
end

local selectIndex = 1   --正在选择的item索引
local lastSelectedIndex = 1
local currentLabel = 1    --1是家具,2是员工
local isOpen = false


function CycleIslandBuildingUIView:OnEnter()

    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    roomsConfig = self.m_currentModel.roomsConfig
    furnitureLevelConfig = self.m_currentModel.furnitureLevelConfig
    furnitureConfig = self.m_currentModel.furnitureConfig
    resConfig = self.m_currentModel.resourceConfig

    self.RoomHeroPanel = self:GetGo("RootPanel/RoomHero")
    self.RoomTitlePanel = self:GetGo("RootPanel/RoomInfo")
    self.RoomInfoPanel = self:GetGo("RootPanel/RoomTitle")
    self.BG = self:GetGo("RootPanel/bg")
    self.RoomCarteen = self:GetGo("RootPanel/RoomCarteen")
    self.RoomDormitory = self:GetGo("RootPanel/RoomDormitory")

    self.HeroIconImage = self:GetComp("RootPanel/RoomHero/heroIcon", "Image")
    self.productImage = self:GetComp("RootPanel/RoomHero/heroIcon/heroInfo/resource/icon", "Image")
    self.upgrageTip = self:GetGo("RootPanel/RoomHero/heroIcon/heroInfo/upgrageTip")
    self.heroTalk = self:GetGo("RootPanel/RoomHero/heroTalk")
    self.matierial = self:GetGo("RootPanel/RoomInfo/product/bg/matierial")
    self.matierial_1 = self:GetGo("RootPanel/RoomInfo/product/bg/1")
    self.matierialImage = self:GetComp("RootPanel/RoomInfo/product/bg/matierial/logo", "Image")
    self.stuckIcon = self:GetGo("RootPanel/RoomInfo/product/bg/matierial/stuckIcon")
    self.resourceImage = self:GetComp("RootPanel/RoomInfo/product/bg/production/type/resource", "Image")
    self.heroBtn = self:GetComp("RootPanel/RoomHero/heroIcon", "Button")
    self.furImage = self:GetComp("RootPanel/RoomInfo/upgrade/bg/icon", "Image")
    self.progressSlider = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress", "Slider")
    self.progressProductImage = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/bonus/icon", "Image")
    self.progressBonus = self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/bonus")
    self.progressEmployee = self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/effect/employee")
    self.progressResouce = self:GetGo("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce")
    self.progressResouceImage = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce", "Image")
    self.upgradeMaxlvl = self:GetGo("RootPanel/RoomInfo/upgrade/bg/maxlvl")
    self.upgradeBtnGO = self:GetGo("RootPanel/RoomInfo/upgrade/bg/btn")
    self.feel = self:GetComp("RootPanel/RoomInfo/upgrade/bg/progress/Fill Area/Fill/vfx/fb", "MMFeedbacks")
    self.upgradeBtn = self:GetComp("RootPanel/RoomInfo/upgrade/bg/btn", "ButtonEx")
    self.employeeItem = self:GetGo("RootPanel/RoomInfo/employee/bg/temp")
    self.animator = self:GetComp("RootPanel/RoomInfo/workstate/bg/toggle", "Animator")
    self.toggle = self:GetComp("RootPanel/RoomInfo/workstate/bg/toggle", "Button")
    self.cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")

    self.lastTipsText = nil
    
    
    self:SetButtonClickHandler(self:GetComp("bgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)

    --CycleIslandMainViewUI:SetAchievementActive(false)

end

function CycleIslandBuildingUIView:OnExit()
    GameTableDefine.CycleIslandMainViewUI:SetPackActive(true)
    GameTableDefine.CycleIslandMainViewUI:SetEventActive(true)

    --CycleIslandMainViewUI:SetAchievementActive(true)
    self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
    currentLabel = 1

    local SceneObjectRange = GameUIManager:GetUIByType(ENUM_GAME_UITYPE.CYCLE_ISLAND_MAIN_VIEW_UI, self.m_guid).m_uiObj
    SceneObjectRange = self:GetGo("SceneObjectRange")
    local cameraFocus = self:GetComp(SceneObjectRange, "", "CameraFocus")
    self.m_currentModel:LookAtSceneGO(self.roomID, selectIndex, cameraFocus, true)
    --self.m_currentModel:ShowSelectFurniture(nil)
end

function CycleIslandBuildingUIView:ShowFactoryUI(roomID, select, isFirst)
    printf("ShowFactoryUI")
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    self.UItype = 1
    local roomCfg = roomsConfig[roomID]

    self.roomID = roomID

    --**********************************数据整理*************************************

    --获取所有家具信息
    self.factoryFurData = self.m_currentModel:GetCurRoomData(roomID).furList
    local curFurLevelID = self.factoryFurData[tostring(selectIndex)].id --当前选中的家具levelID
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID] --当前选中的家具levelConfig
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]
    local nextFurLevelCfg = self.m_currentModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

    --计算所有产出
    local productionID = roomCfg.production
    local productionNum, expNum, pointNum = self.m_currentModel:GetRoomProduction(self.roomID)
    local productionCfg = resConfig[productionID]
    local showMatNum = roomCfg.material[2] and tonumber(productionNum) * roomCfg.material[2]


    --获取原料信息
    local showNeed = Tools:GetTableSize(roomCfg.material) > 1
    local isResEnough = true --检测当前的消耗是否足够
    if showNeed then
        local needID = roomCfg.material[1]
        --local resCfg = resConfig[needID]
        local matList = self.m_currentModel.portExport
        local nowNeedRes = self.m_currentModel:GetProdutionsData()
        local needResCount = BigNumber:Multiply(productionNum, roomCfg.material[2])
        if not nowNeedRes[tostring(needID)] then
            isResEnough = false
        elseif matList[needID] == 0 then
            isResEnough = false
        end
    end

    -- 英雄相关
    local heroData = CycleIslandHeroManager:GetHeroData(roomCfg.hero_id)
    local heroCfg = CycleIslandHeroManager:GetHeroConfig(heroData.heroID, heroData.level)
    local heroCanUpgrade = CycleIslandHeroManager:CanUpgrade(roomCfg.hero_id)
    local income, resRoomID, resID = self.m_currentModel:GetCurHighestProfit()
    --需要获取到当前售卖的房间ID
    local curSellingRoomID = self.m_currentModel:GetSellingRoomID()
    
    local isNotCurSelling = false
    if resRoomID == roomID and curSellingRoomID and curSellingRoomID ~= roomID then
        --当前收益最高的是自己，且当前售卖的不是自己
        isNotCurSelling = true
    end
    
    --计算CD
    local allReduce = self.m_currentModel:GetRoomCDReduce(self.roomID)
    local cd = roomCfg.bastCD - allReduce
    local needCount,resCfg = self.m_currentModel:GetRoomMatCost(self.roomID)
    
    --员工数据
    local workerMax = currentFurCfg.seat
    local curWorker = self.m_currentModel:GetWorkerNum(self.roomID)
    

    --**********************************显示UI*************************************
    self.RoomHeroPanel:SetActive(true)
    self.RoomInfoPanel:SetActive(true)
    self.RoomTitlePanel:SetActive(true)
    self.BG:SetActive(true)
    self.RoomCarteen:SetActive(false)
    self.RoomDormitory:SetActive(false)
    
    -- 英雄相关
    self:SetSprite(self.HeroIconImage, "UI_Common", heroCfg.icon)
    self:SetText("RootPanel/RoomHero/heroIcon/heroInfo/level/num", heroCfg.level)
    self:SetSprite(self.productImage, "UI_Common", productionCfg.icon)
    self.upgrageTip:SetActive(heroCanUpgrade)
    self:SetText("RootPanel/RoomHero/heroIcon/heroInfo/buff/num", string.format("%.2f", heroCfg.buff))
    -- if resNotEnought then
    local curTipsText = nil
    if not isResEnough then
        curTipsText = "TXT_INSTANCE_HERO_TALK_2"
    end
    if isNotCurSelling then
        curTipsText = "TXT_INSTANCE_HERO_TALK_1"
    end
    if curTipsText then
        if not self.lastTipsText or curTipsText ~= self.lastTipsText then
            self:SetText("RootPanel/RoomHero/heroTalk/content", GameTextLoader:ReadText(curTipsText))
            self.heroTalk:SetActive(true)
        end
    else
        self.heroTalk:SetActive(false)
    end
    self.lastTipsText = curTipsText

    -- 房间名
    self:SetText("RootPanel/RoomTitle/HeadPanel/title/name", GameTextLoader:ReadText(roomCfg.name))
    -- 生产栏
    if showNeed then
        self.matierial:SetActive(true)
        self.matierial_1:SetActive(true)
        self:SetText("RootPanel/RoomInfo/product/bg/matierial/count/num", BigNumber:FormatBigNumber(needCount), not isResEnough and "FF1414" or "FFFFFF")
        self:SetSprite(self.matierialImage, "UI_Common", resCfg.icon)
        self.stuckIcon:SetActive(not isResEnough)
    else
        self.matierial:SetActive(false)
        self.matierial_1:SetActive(false)
    end
    self:SetText("RootPanel/RoomInfo/product/bg/cooltime/time/num", roomCfg.bastCD)
    self:SetSprite(self.resourceImage, "UI_Common", productionCfg.icon)
    self:SetText("RootPanel/RoomInfo/product/bg/production/type/resource/count/num", BigNumber:FormatBigNumber(productionNum))
    self:SetText("RootPanel/RoomInfo/product/bg/production/type/exp/count/num", BigNumber:FormatBigNumber(expNum))
    self:SetText("RootPanel/RoomInfo/product/bg/production/type/point/count/num", BigNumber:FormatBigNumber(pointNum))
    self:SetButtonClickHandler(self.heroBtn, function()
        GameTableDefine.CycleIslandHeroUpgradeUI:OpenView(roomCfg.hero_id)
    end)
    
    -- 升级栏
    self:SetSprite(self.furImage, "UI_Common", currentFurLevelCfg.icon)
    self:SetText("RootPanel/RoomInfo/upgrade/bg/name", GameTextLoader:ReadText(currentFurCfg.name))
    self:SetText("RootPanel/RoomInfo/upgrade/bg/level/num", currentFurLevelCfg.level)

    self.progressSlider.value = currentFurLevelCfg.stage_show
    self:SetSprite(self.progressProductImage, "UI_Common", productionCfg.icon)
    if not nextFurLevelCfg then
        self.progressBonus:SetActive(false)
    end

    if currentFurLevelCfg.worker_show then
        self.progressEmployee:SetActive(true)
        self.progressResouce:SetActive(false)
    else
        self.progressEmployee:SetActive(false)
        self.progressResouce:SetActive(true)
        self:SetText("RootPanel/RoomInfo/upgrade/bg/progress/effect/resouce/icon/num", currentFurLevelCfg.magnification_show)
        self:SetSprite(self.progressResouceImage, "UI_Common", productionCfg.icon)
    end
    local cost = nextFurLevelCfg and nextFurLevelCfg.cost
    local buffID = self.m_currentModel:GetSkillIDByType(self.m_currentModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = self.m_currentModel:GetSkillBufferValueBySkillID(buffID)
    cost = cost and BigNumber:Divide(cost,buffValue)
    self:SetText("RootPanel/RoomInfo/upgrade/bg/btn/cash/cost/num", BigNumber:FormatBigNumber(cost or 0))
    self:SetText("RootPanel/RoomInfo/upgrade/bg/btn/cash/now/num", self.m_currentModel:GetCurInstanceCoinShow())
    self.upgradeMaxlvl:SetActive(not nextFurLevelCfg)
    self.upgradeBtnGO:SetActive(nextFurLevelCfg)


    -- local canBuy = cost and cost <= self.m_currentModel:GetCurInstanceCoin()
    local canBuy = cost and BigNumber:CompareBig(self.m_currentModel:GetCurInstanceCoin(), cost)
 
    local function ClickBuyFurniture()
        --printf(111111111111)
        if not canBuy then
            -- CS.UnityEngine.EventSystems.EventSystem.current.SetSelectedGameObject(nil);
            return
        end
        self.m_currentModel:BuyFurniture(self.roomID,selectIndex,nextFurLevelCfg.id)
        self:ShowFactoryUI(self.roomID,selectIndex)
        self.feel:PlayFeedbacks()
    end

    self.upgradeBtn.interactable = canBuy

     self:SetButtonClickHandler(self.upgradeBtn, function()        --单机升级按钮
         -- 购买
         ClickBuyFurniture()
     end)
     --连点升级按钮
    self:SetButtonHoldHandler(self.upgradeBtn, function()        --单机升级按钮
         ClickBuyFurniture()
     end,nil, 0.4, 0.13)
    -- local longButton = self:GetComp("RootPanel/RoomInfo/upgrade/bg/longBtn", "LongPressButton")
    -- longButton.interactable = canBuy
    --if self.upgradeBtn then
    --    UnityHelper.SetLongHandleClick(self.upgradeBtn, function()
    --        -- print("longButton pressed down ==========")
    --        ClickBuyFurniture()
    --    end, nil, 0, 0)
    --end
    -- 员工栏
    Tools:SetTempGo(self.employeeItem, workerMax, true, function(go, index)
        self:GetGo(go, "on"):SetActive(index <= curWorker)
    end)
    
    -- 工作状态栏
    local isFF = self.m_currentModel:GetRoomIsFullForce(self.roomID)
    self.animator:SetBool("On", isFF)
    self:SetButtonClickHandler(self.toggle, function()
        self.m_currentModel:SetRoomIsFullForce(self.roomID, not isFF)
        self.animator:SetBool("On", not isFF)
        self:ShowFactoryUI(self.roomID,selectIndex)
    end)


    if isFirst then
        --将相机焦点移动至所选设备位置
        self.m_currentModel:LookAtSceneGO(self.roomID, 1, self.cameraFocus)
    end
end


function CycleIslandBuildingUIView:ShowSupplyBuildingUI(roomID, select, isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end
    self.UItype = 2
    local roomCfg = roomsConfig[roomID]

    self.roomID= roomID

    --**********************************数据整理*************************************

    --获取所有家具信息
    self.SupplyBuildingFurData = self.m_currentModel:GetCurRoomData(roomID).furList
    local currentFurLevelCfg = furnitureLevelConfig[self.SupplyBuildingFurData[tostring(selectIndex)].id]
    local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id]

    --计算所有供给
    local supplySeatSum = self.m_currentModel:GetRoomSeatCount(roomID)
    local supplyHungerSum = self.m_currentModel:GetRoomHunger(roomID)
    local supplyPhysicalSum = self.m_currentModel:GetRoomPhysical(roomID)

    --**********************************显示UI*************************************
    -- 房间名
    self:SetText("RootPanel/RoomTitle/HeadPanel/title/name", GameTextLoader:ReadText(roomCfg.name))
    
    if roomCfg.room_category == 3 then
        self.RoomHeroPanel:SetActive(false)
        self.RoomInfoPanel:SetActive(false)
        self.RoomTitlePanel:SetActive(true)
        self.BG:SetActive(true)
        self.RoomCarteen:SetActive(true)
        self.RoomDormitory:SetActive(false)
    elseif roomCfg.room_category == 2 then
        self.RoomHeroPanel:SetActive(false)
        self.RoomInfoPanel:SetActive(false)
        self.RoomTitlePanel:SetActive(true)
        self.BG:SetActive(true)
        self.RoomCarteen:SetActive(false)
        self.RoomDormitory:SetActive(true)
    end

    --将相机焦点移动至所选设备位置
    self.m_currentModel:LookAtSceneGO(self.roomID, 1, self.cameraFocus)
   
end

function CycleIslandBuildingUIView:UpdateSupplyBuildingFurItem(index,trans)
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



function CycleIslandBuildingUIView:ShowWharfUI(roomID,select,isFirst)
    isOpen = isFirst
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end

    self.UItype = 3
    local roomCfg = roomsConfig[roomID]

    self.roomID = roomID
    self.btnPanel:SetActive(false)
    --**********************************数据整理*************************************

    --获取所有家具信息
    self.wharfFurData = self.m_currentModel:GetCurRoomData(roomID).furList
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
        local productions = self.m_currentModel:GetProdutionsData()
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
    local willBuyFurLevelCfg = self.m_currentModel:GetFurlevelConfig(currentFurLevelCfg.furniture_id, willBuy)
    if isMaxLevel then
        buyButton.gameObject:SetActive(false)
        maxButton.gameObject:SetActive(true)
    else
        buyButton.gameObject:SetActive(true)
        maxButton.gameObject:SetActive(false)
        local canBuy,conditions = self.m_currentModel:CheckFuinitureCondition(willBuyFurLevelCfg.id)
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
                self.m_currentModel:BuyFurniture(self.roomID,selectIndex,willBuyFurLevelCfg.id)
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

                self.m_currentModel:SetRoomFurnitureData(roomID,selectIndex,currentFurLevelCfg.id,{isOpen = not bool})
                local furGO = self.m_currentModel:GetSceneRoomFurnitureGo(roomID,selectIndex)
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

function CycleIslandBuildingUIView:UpdateWharfFurItem(index,trans)
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


function CycleIslandBuildingUIView:GetFurnitureMaxlevel(furnitureID)
    local furnitureLevelConfig_furID = self.m_currentModel.furnitureLevelConfig_furID
    local furLevelCfgs = furnitureLevelConfig_furID[furnitureID]
    local max = 0
    for k,v in pairs(furLevelCfgs) do
        if v.furniture_id == furnitureID and v.level >= max then
            max = v.level
        end
    end
    return max
end

function CycleIslandBuildingUIView:SelectFurniture(index,furData)

    --将相机焦点移动至所选设备位置
    local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
    self.m_currentModel:LookAtSceneGO(self.roomID,index,cameraFocus)
    --所选设备闪烁
    local prebuy = furData.state == 0
    local roomCfg = roomsConfig[self.roomID]
    local furGO = nil
    furGO = self.m_currentModel:GetSceneRoomFurnitureGo(self.roomID,index)

    -- if roomCfg.room_category == 2 or  roomCfg.room_category == 3 then
    --     furGO = self.m_currentModel:GetSceneRoomFurnitureGo(self.roomID,index,1)
    -- else
    --     furGO = self.m_currentModel:GetSceneRoomFurnitureGo(self.roomID,index)
    -- end

    self.m_currentModel:ShowSelectFurniture(furGO,prebuy)
end


return CycleIslandBuildingUIView
