
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject

local CycleIslandMainViewUI = GameTableDefine.CycleIslandMainViewUI
local ShopInstantUI = GameTableDefine.ShopInstantUI
local GameUIManager = GameTableDefine.GameUIManager
local CycleIslandHeroManager = GameTableDefine.CycleIslandHeroManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleToyBluePrintManager = GameTableDefine.CycleToyBluePrintManager

local roomsConfig = nil
local furnitureLevelConfig = nil
local furnitureConfig = nil
local resConfig = nil
local selectResID = nil
local selectFurData = nil
local workRoomData = nil

---@class CycleToySellUIView:UIBaseView
local CycleToySellUIView = Class("CycleToySellUIView", UIView)

function CycleToySellUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_currentModel = nil ---@type CycleToyModel
    self.m_completeBlueprintGuide  = false
end

local selectIndex = 1   --正在选择的item索引
local lastSelectedIndex = 1
local currentLabel = 1    --1是家具,2是员工
local UItype = 1       --1是工厂,2是补给,3是港口
local playSelling = false
local incomeSum = 0
local ROOM_ID = 1043
local upgradeBP = false


function CycleToySellUIView:OnEnter()
    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    self.m_completeBlueprintGuide = self.m_currentModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.Toy.UnlockBluePrint)
    self.chooseGO = self:GetGo("choose")
    
    roomsConfig = self.m_currentModel.roomsConfig
    furnitureLevelConfig = self.m_currentModel.furnitureLevelConfig
    furnitureConfig = self.m_currentModel.furnitureConfig
    resConfig = self.m_currentModel.resourceConfig

    self:SetButtonClickHandler(self:GetComp("bgCover", "Button"), function()
        if self.chooseGO.activeInHierarchy then
            self.chooseGO:SetActive(false)
        else
            self:DestroyModeUIObject()
        end
    end)
    incomeSum = 0 
    --CycleIslandMainViewUI:SetAchievementActive(false)

    self:SetButtonClickHandler(self:GetComp("choose/Image", "Button"), function()
        self.chooseGO:SetActive(false)
    end)
    self:SetButtonClickHandler(self:GetComp("choose/product/item/btn/sell_btn", "Button"), function()
        self:ProductionSell()
    end)
    self:SetButtonClickHandler(self:GetComp("choose/product/item/btn/upgrade_btn", "Button"), function()
        if self.m_completeBlueprintGuide then
            GameTableDefine.CycleToyBlueprintUI:OpenView(selectResID)
        else
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_CY3_SELL_2"))
        end
    end)
    GameTableDefine.CycleToyMainViewUI:SetEventActive(false)
    
end

function CycleToySellUIView:OnExit()
    GameTableDefine.CycleToyMainViewUI:SetPackActive(true)
    GameTableDefine.CycleToyMainViewUI:SetEventActive(true)

    --CycleIslandMainViewUI:SetAchievementActive(true)
    self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
    currentLabel = 1

    local SceneObjectRange = GameUIManager:GetUIByType(ENUM_GAME_UITYPE.CYCLE_TOY_MAIN_VIEW_UI, self.m_guid).m_uiObj
    SceneObjectRange = self:GetGo("SceneObjectRange")
    local cameraFocus = self:GetComp(SceneObjectRange, "", "CameraFocus")
    self.m_currentModel:LookAtSceneGO(self.roomID, selectIndex, cameraFocus, true)
    --self.m_currentModel:ShowSelectFurniture(nil)
    if upgradeBP then
        GameTableDefine.CycleToyPopUI:PackTrigger(6)
    end
    
end

function CycleToySellUIView:ProductionSell()
    self.chooseGO:SetActive(false)
    local newFurLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(self.roomID, selectIndex)
    self.m_currentModel:SetRoomFurnitureData(tostring(self.roomID), selectIndex, newFurLevelCfg.id, { isOpen = true })
    local curFurLevelID = self.wharfFurData[tostring(selectIndex)].id
    self:SwitchSellData(self.roomData.roomID, selectIndex, curFurLevelID)
    self:ShowWharfUI(self.roomData.roomID, selectIndex)
    playSelling = true
    GameTableDefine.CycleToyAIBlackBoard:RefreshShelf(workRoomData, selectResID)
    GameUIManager:GetEnableTouch(false)
    -- 通知房间播放解锁动画
    EventDispatcher:TriggerEvent(GameEventDefine.OnCycleProductionUnlock, selectResID, function()
        local animation = self:GetComp("RootPanel/RoomTitle/HeadPanel/priceAll", "Animation")
        AnimationUtil.Play(animation,"UI_cy3_ToySellUI_price")
    end)
end

function CycleToySellUIView:ShowWharfUI(roomID, select, isFirst, isBpUpgrade)
    if select then
        selectIndex = select
    else
        selectIndex = 1
    end

    UItype = 3
    local roomCfg = roomsConfig[roomID]

    self.roomID = roomID
    --**********************************数据整理*************************************

    --获取所有家具信息
    self.roomData = self.m_currentModel:GetCurRoomData(roomID)
    self.wharfFurData = self.roomData.furList
    self.resReward = self.m_currentModel:CalculateOfflineRewards(60, true, false)
    


    --**********************************显示UI*************************************
    self.chooseGO:SetActive(false)
    --title
    self:SetText("RootPanel/RoomTitle/HeadPanel/title/name", GameTextLoader:ReadText(roomCfg.name))
    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    
    self:SetListItemCountFunc(portListScroll, function()
        return Tools:GetTableSize(resConfig)
    end)
    self:SetListItemNameFunc(portListScroll, function(index)
        return "Item"
    end)
    self:SetListUpdateFunc(portListScroll, handler(self, self.ShowPortListItem))
    --self:GetRecommendBluePrint()
    portListScroll:UpdateData()
    if isFirst then 
        --将相机焦点移动至所选设备位置
        local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
        self.m_currentModel:LookAtSceneGO(self.roomID, selectIndex, cameraFocus)
        if isBpUpgrade then
            -- 通知房间播放升级动画
            selectResID = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(ROOM_ID, selectIndex).resource_type
            EventDispatcher:TriggerEvent(GameEventDefine.OnCycleProductionUpgrade, selectResID, function()
                local animation = self:GetComp("RootPanel/RoomTitle/HeadPanel/priceAll", "Animation")
                AnimationUtil.Play(animation,"UI_cy3_ToySellUI_price")
                --self:GetComp("RootPanel/RoomTitle/HeadPanel/priceAll/vfx", "ParticleSystem"):Play()
            end)
            if not self.wharfFurData[tostring(selectIndex)].isOpen then
                self:ProductionSell()
            end
            upgradeBP = true
        else
            upgradeBP = false
        end
        
    end

end

function CycleToySellUIView:ShowPortListItem(index,trans)
    index = index + 1
    local go = trans.gameObject

    local curFurLevelID = self.wharfFurData[tostring(index)].id
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID]
    local resID = currentFurLevelCfg.resource_type
    local resCfg = resConfig[resID]
    local showRedPoint = CycleToyBluePrintManager:CanUpgradeProduction(resID,true) and self.m_completeBlueprintGuide
    self:GetGo(go, "product/selling/sellBox/blue_point"):SetActive(showRedPoint)
    --local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id] 
    --local resProductivity = self.m_currentModel:GetProductionAndConsumptionPerMin(index)
    --local productionsData = self.m_currentModel:GetProdutionsData()
    local curProductionCount = self.resReward[resID]
    local resSellPrice = curProductionCount * resCfg.price
    local expBuffID = self.m_currentModel:GetSkillIDByType(self.m_currentModel.SkillTypeEnum.AddSellingPrice)
    local buffNum = self.m_currentModel:GetSkillBufferValueBySkillID(expBuffID)
    local bluePrintMoneyBuff,bluePrintMileBuff = CycleToyBluePrintManager:GetProductBuffValue(resID)
    resSellPrice = BigNumber:Divide(resSellPrice, 2)    -- 按照30s算
    resSellPrice = BigNumber:Multiply(resSellPrice,buffNum)
    resSellPrice = BigNumber:Multiply(resSellPrice,bluePrintMoneyBuff)
    local resSellPriceStr = BigNumber:FormatBigNumber(resSellPrice)
    local isUnlocked = self.m_currentModel:GetResLockedState(resID)
    local income, roomID, bestResID = self.m_currentModel:GetCurHighestProfit()
  
    local data = CycleToyBluePrintManager:GetProductionDataByProductID(currentFurLevelCfg.resource_type)
    local level = data.starLevel or 0
    local bpConfig = CycleToyBluePrintManager:GetBPConfigByProductionLevel(currentFurLevelCfg.resource_type,level)
    
    local isPort = true
    if currentFurLevelCfg.resource_type > 0 then    --选中的item是码头
        isPort = true
    else
        isPort = false
    end
    local isSell = self.wharfFurData[tostring(index)].isOpen --港口开关
    
    self:CreateTimer(1, function()
        local animator = self:GetComp(go, "", "Animator")
        if isPort then
            if isUnlocked then
                if isSell then
                    self:SetSprite(self:GetComp(go, "product/selling/sellBox/toyIcon", "Image"), "UI_Common", bpConfig.icon)
                    self:SetText(go, "product/selling/price/num", resSellPriceStr)
                    --incomeSum = incomeSum + resSellPrice
                    incomeSum = self.m_currentModel:GetInComePerMinute() / 2
                    self:SetText("RootPanel/RoomTitle/HeadPanel/priceAll/num", BigNumber:FormatBigNumber(incomeSum))
                    
                    -- 展示卖出物品的图标
                    self:SetSprite(self:GetComp(go, "product/selling/sellingMark/icon", "Image"), "UI_Common", bpConfig.icon)
                    if selectIndex == index and playSelling then
                        animator:Play("Cy3_ToySellUI_Sell_unsaletosell")
                        playSelling = false
                    else
                        animator:Play("Cy3_ToySellUI_Sell_selling")
                    end
                else
                    self:SetText(go, "product/unsale/price/num", resSellPriceStr)
                    self:SetSprite(self:GetComp(go, "product/unsale/sellBox/toyIcon", "Image"), "UI_Common", bpConfig.icon)
                    self:GetGo(go, "product/unsale/recommendMark"):SetActive(resID == bestResID)
                    if not self.wharfFurData[tostring(index)].playUnlock then
                        animator:Play("Cy3_ToySellUI_Sell_unlocking")
                        self.wharfFurData[tostring(index)].playUnlock = true
                    else
                        animator:Play("Cy3_ToySellUI_Sell_unlock")
                    end
                end
            else
                animator:Play("Cy3_ToySellUI_Sell_lock")
            end
        end
    end, false)
    
    self:SetButtonClickHandler(self:GetComp(go, "product/lock", "Button"), function()
        selectResID = resID
        selectFurData = furnitureLevelConfig
        self:SwitchSelect(index)
        -- 显示解锁提示
        local roomName = GameTextLoader:ReadText(roomsConfig[workRoomData.roomID].name)
        EventManager:DispatchEvent("UI_NOTE", string.gsub(GameTextLoader:ReadText("TXT_TIP_CY3_SELL_1"), "%%s", roomName))
        -- 显示弹窗
        self:ShowChoose(go, resSellPriceStr, bpConfig, false, true)
    end)
    
    self:SetButtonClickHandler(self:GetComp(go, "product/unsale", "Button"), function()
        selectResID = resID
        self:SwitchSelect(index)
        -- 显示弹窗
        self:ShowChoose(go, resSellPriceStr, bpConfig, false)

    end)
    
    self:SetButtonClickHandler(self:GetComp(go, "product/selling", "Button"), function()
        selectResID = resID
        self:SwitchSelect(index)
        -- 显示弹窗
        self:ShowChoose(go, resSellPriceStr, bpConfig, true)
    end)
    
    self:GetGo("RootPanel/RoomInfo/List/Viewport/Content/shelf"):SetActive(true)
end

function CycleToySellUIView:SwitchSelect(index, cb)
    local newFurLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(self.roomID, index)
    local resCfg = self.m_currentModel.resourceConfig[newFurLevelCfg.resource_type]
    local workRoomID = self.m_currentModel:GetRoomByProduction(resCfg.id)
    workRoomData = self.m_currentModel:GetRoomDataByID(workRoomID)
    local furData = self.m_currentModel:GetRoomDataByID(ROOM_ID).furList[tostring(index)]
    self:SelectFurniture(index, furData, resCfg.id, workRoomData, cb)
    selectIndex = index
    
end

function CycleToySellUIView:SwitchSellData(roomID, index, furLevelID)
    local newFurLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, index)
    self.m_currentModel:SetRoomFurnitureData(tostring(roomID), index, newFurLevelCfg.id, { isOpen = true })

    -- 打开新的卖出节点
    local resCfg = self.m_currentModel.resourceConfig[newFurLevelCfg.resource_type]
    GameSDKs:TrackForeign("cy_sell_change", {id = tonumber(resCfg.id)})
end

function CycleToySellUIView:ShowChoose(selectGO, resSellPriceStr, bpConfig, isSell, isLocked)
    self.chooseGO:SetActive(false)
    
    self.chooseGO:SetActive(not isLocked)
    self.chooseGO.transform.position = selectGO.transform.position
    self:GetGo("choose/product/item/btn/sell_btn"):SetActive(not isSell)
    self:GetComp("choose/product/item/btn/upgrade_btn", "Button").interactable = self.m_completeBlueprintGuide
    self:SetSprite(self:GetComp("choose/product/item/Box/toyIcon", "Image"), "UI_Common", bpConfig.icon)
    self:SetText("choose/product/item/price/num", resSellPriceStr)
    local showRedPoint = CycleToyBluePrintManager:CanUpgradeProduction(bpConfig.res_id,true) and self.m_completeBlueprintGuide
    self:GetGo("choose/product/item/Box/blue_point"):SetActive(showRedPoint)
    for i = 1, 4 do
        local levelGO = self:GetGo("choose/product/item/star/" .. i)
        self:GetGo(levelGO, "on"):SetActive(bpConfig.starLevel >= i)
        self:GetGo(levelGO, "off"):SetActive(not (bpConfig.starLevel >= i))
    end
end

function CycleToySellUIView:GetFurnitureMaxlevel(furnitureID)
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

function CycleToySellUIView:SelectFurniture(index, furData, resID, workRoomData, cb)
    --将相机焦点移动至所选设备位置
    local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
    if selectIndex == index then
        GameTableDefine.CycleToyAIBlackBoard:RefreshShelf(workRoomData, resID)
        GameUIManager:GetEnableTouch(false)
    
    else
        self.m_currentModel:LookAtSceneGO(self.roomID, index, cameraFocus, false, cb)
    end
end

---用来给引导返回最高售价的物品
function CycleToySellUIView:GetBestSellGO()

    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    local resCount = Tools:GetTableSize(resConfig)
    local income, roomID, bestResID = self.m_currentModel:GetCurHighestProfit(true)

    for index = 1, resCount do
        local curFurLevelID = self.wharfFurData[tostring(index)].id
        local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID]
        local resID = currentFurLevelCfg.resource_type
        if resID == bestResID then
            --portListScroll:ScrollTo(index-1)
            local uiItemGO = portListScroll:GetScrollItem(index-1).gameObject
            return self:GetGo(uiItemGO,"product")
        end
    end
end

---用来给引导返回上次打开过的房间出售的物品
function CycleToySellUIView:GetLastSellGO()

    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    local resCount = Tools:GetTableSize(resConfig)
    local lastRoomID = GameTableDefine.CycleToyBuildingUI.roomID
    local roomCfg = self.m_currentModel:GetRoomConfigByID(lastRoomID)
    local lastResID = roomCfg.production

    for index = 1, resCount do
        local curFurLevelID = self.wharfFurData[tostring(index)].id
        local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID]
        local resID = currentFurLevelCfg.resource_type
        if resID == lastResID then
            local uiItemGO = portListScroll:GetScrollItem(index-1).gameObject
            return self:GetGo(uiItemGO,"product")
        end
    end
end

---用来给引导返回1号物品
function CycleToySellUIView:GetFirstSellGO()
    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    local uiItemGO = portListScroll:GetScrollItem(0).gameObject
    return self:GetGo(uiItemGO,"product")
end

---用来给引导返回1号物品Btn
function CycleToySellUIView:GetFirstSellBtn()
    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    local uiItemGO = portListScroll:GetScrollItem(0).gameObject
    return self:GetComp(uiItemGO,"product/unsale","Button")
end

function CycleToySellUIView:GetGo(obj, child)
    if obj == "GetBestSellRectGO" then
        return self:GetBestSellGO()
    elseif obj == "GetLastSellRectGO" then
        return self:GetLastSellGO()
    elseif obj == "GetFirstSellRectGO" then
        return self:GetFirstSellGO()
    else
        return self:getSuper(CycleToySellUIView).GetGo(self,obj, child)
    end
end

function CycleToySellUIView:GetBestSellBtn()
    local bestSellGO = self:GetBestSellGO()
    if bestSellGO then
        local btn = self:GetComp(bestSellGO,"unsale","Button")
        return btn
    end
    return nil
end

function CycleToySellUIView:GetComp(obj, child, uiType)
    if obj == "GetBestSellBtn" then
        return self:GetBestSellBtn()
    elseif obj == "GetFirstSellBtn" then
        return self:GetFirstSellBtn()
    else
        return self:getSuper(CycleToySellUIView).GetComp(self,obj, child,uiType)
    end
end

return CycleToySellUIView
