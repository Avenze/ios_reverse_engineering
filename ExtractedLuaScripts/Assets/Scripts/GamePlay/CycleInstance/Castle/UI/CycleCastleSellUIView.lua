
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

local CycleIslandMainViewUI = GameTableDefine.CycleIslandMainViewUI
local ShopInstantUI = GameTableDefine.ShopInstantUI
local GameUIManager = GameTableDefine.GameUIManager
local CycleIslandHeroManager = GameTableDefine.CycleIslandHeroManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager


local roomsConfig = nil
local furnitureLevelConfig = nil
local furnitureConfig = nil
local resConfig = nil

local CycleCastleSellUIView = Class("CycleCastleSellUIView", UIView)

function CycleCastleSellUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_currentModel = nil ---@type CycleCastleModel
end

local selectIndex = 1   --正在选择的item索引
local lastSelectedIndex = 1
local currentLabel = 1    --1是家具,2是员工
local UItype = 1    --1是工厂,2是补给,3是港口
local isOpen = false


function CycleCastleSellUIView:OnEnter()

    self.m_currentModel = CycleInstanceDataManager:GetCurrentModel()
    roomsConfig = self.m_currentModel.roomsConfig
    furnitureLevelConfig = self.m_currentModel.furnitureLevelConfig
    furnitureConfig = self.m_currentModel.furnitureConfig
    resConfig = self.m_currentModel.resourceConfig

    self:SetButtonClickHandler(self:GetComp("bgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)

    --CycleIslandMainViewUI:SetAchievementActive(false)


end

function CycleCastleSellUIView:OnExit()
    GameTableDefine.CycleIslandMainViewUI:SetPackActive(true)
    GameTableDefine.CycleIslandMainViewUI:SetEventActive(true)

    --CycleIslandMainViewUI:SetAchievementActive(true)
    self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
    currentLabel = 1

    local SceneObjectRange = GameUIManager:GetUIByType(ENUM_GAME_UITYPE.CYCLE_CASTLE_MAIN_VIEW_UI, self.m_guid).m_uiObj
    SceneObjectRange = self:GetGo("SceneObjectRange")
    local cameraFocus = self:GetComp(SceneObjectRange, "", "CameraFocus")
    self.m_currentModel:LookAtSceneGO(self.roomID, selectIndex, cameraFocus, true)
    --self.m_currentModel:ShowSelectFurniture(nil)
end



function CycleCastleSellUIView:ShowWharfUI(roomID,select,isFirst)
    isOpen = isFirst
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
    portListScroll:UpdateData()

    if isFirst then 
        --将相机焦点移动至所选设备位置
        local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
        self.m_currentModel:LookAtSceneGO(self.roomID,1,cameraFocus)
    end
end

function CycleCastleSellUIView:ShowPortListItem(index,trans)
    index = index + 1
    local go = trans.gameObject

    local curFurLevelID = self.wharfFurData[tostring(index)].id
    local currentFurLevelCfg = furnitureLevelConfig[curFurLevelID]
    local resID = currentFurLevelCfg.resource_type
    local resCfg = resConfig[resID]
    --local currentFurCfg = furnitureConfig[currentFurLevelCfg.furniture_id] 
    --local resProductivity = self.m_currentModel:GetProductionAndConsumptionPerMin(index)
    --local productionsData = self.m_currentModel:GetProdutionsData()
    local curProductionCount = self.resReward[resID]
    local resSellPrice = curProductionCount * resCfg.price
    local expBuffID = self.m_currentModel:GetSkillIDByType(self.m_currentModel.SkillTypeEnum.AddSellingPrice)
    local buffNum = self.m_currentModel:GetSkillBufferValueBySkillID(expBuffID)
    resSellPrice = BigNumber:Divide(resSellPrice, 2)    -- 按照30s算
    resSellPrice = BigNumber:FormatBigNumber(resSellPrice * buffNum)
    local isLocked = self.m_currentModel:GetResLockedState(resID)
    local income, roomID, bestResID = self.m_currentModel:GetCurHighestProfit()

    local isPort = true
    if currentFurLevelCfg.resource_type > 0 then    --选中的item是码头
        isPort = true
    else
        isPort = false
    end

    if isPort then
        local isSell = self.wharfFurData[tostring(index)].isOpen --港口开关
        if isLocked then
            if isSell then
                self:GetGo(go, "product/selling"):SetActive(true)
                self:GetGo(go, "product/unsale"):SetActive(false)
                self:GetGo(go, "product/lock"):SetActive(false)
                self:SetSprite(self:GetComp(go, "product/selling/icon", "Image"), "UI_Common", resCfg.icon)
                self:SetText(go, "product/selling/price/num", resSellPrice)
                -- 展示卖出物品的图标
                self:SetSprite(self:GetComp(go, "product/selling/sellingMark/icon", "Image"), "UI_Common", resCfg.icon)
            else
                self:GetGo(go, "product/selling"):SetActive(false)
                self:GetGo(go, "product/unsale"):SetActive(true)
                self:GetGo(go, "product/lock"):SetActive(false)
                self:SetText(go, "product/unsale/price/num", resSellPrice)
                self:SetSprite(self:GetComp(go, "product/unsale/icon", "Image"), "UI_Common", resCfg.icon)
                self:GetGo(go, "product/unsale/recommendMark"):SetActive(resID == bestResID)
            end
        else
            self:GetGo(go, "product/selling"):SetActive(false)
            self:GetGo(go, "product/unsale"):SetActive(false)
            self:GetGo(go, "product/lock"):SetActive(true)
        end
        
       
    end
    self:SetButtonClickHandler(self:GetComp(go, "product/unsale", "Button"), function()
        local cancelIndex = self.m_currentModel:GetSellingIndex()
        self:SwitchSell(self.roomData.roomID, index, curFurLevelID)
        self:ShowWharfUI(self.roomData.roomID,self.selectIndex)
        --GameTableDefine.CycleInstanceDataManager:GetCurrentModel():PlayPortAnimation(cancelIndex, index)
    end)
    self:GetGo("RootPanel/RoomInfo/List/Viewport/Content/shelf"):SetActive(true)
end

function CycleCastleSellUIView:SwitchSell( roomID, index, furLevelID)
    for k, v in pairs(self.wharfFurData) do
        local furIndex = v.index
        if v.isOpen == true and furIndex <= 12 then
            local furLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, furIndex)
            self.m_currentModel:SetRoomFurnitureData(tostring(roomID), furIndex, furLevelCfg.id, { isOpen = false })
            local shipLevelID = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, furIndex + 12)
            self.m_currentModel:SetRoomFurnitureData(tostring(roomID), furIndex + 12, shipLevelID.id, { isOpen = false })
            -- 关闭老的卖出节点
            local resCfg = self.m_currentModel.resourceConfig[furLevelCfg.resource_type]
            self.m_currentModel:GetScene():ChangeSellingLogo(resCfg.prefab)
        end
    end
    local newFurLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, index)
    self.m_currentModel:SetRoomFurnitureData(tostring(roomID), index, newFurLevelCfg.id, { isOpen = true })
    local shipLevelID = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, index + 12)
    self.m_currentModel:SetRoomFurnitureData(tostring(roomID), index + 12, shipLevelID.id, { isOpen = true })
    -- 打开新的卖出节点
    local resCfg = self.m_currentModel.resourceConfig[newFurLevelCfg.resource_type]
    self.m_currentModel:GetScene():ChangeSellingLogo(nil, resCfg.prefab)

    GameSDKs:TrackForeign("cy_sell_change", {id = tonumber(resCfg.id)})
end

function CycleCastleSellUIView:GetFurnitureMaxlevel(furnitureID)
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

function CycleCastleSellUIView:SelectFurniture(index,furData)

    --将相机焦点移动至所选设备位置
    local cameraFocus = self:GetComp("RootPanel/RoomTitle/SceneObjectRange", "CameraFocus")
    -- self.m_currentModel:LookAtSceneGO(self.roomID,index,cameraFocus)
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

---用来给引导返回最高售价的物品
function CycleCastleSellUIView:GetBestSellGO()

    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    local resCount = Tools:GetTableSize(resConfig)
    local income, roomID, bestResID = self.m_currentModel:GetCurHighestProfit()

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

---用来给引导返回1号物品
function CycleCastleSellUIView:GetFirstSellGO()
    local portListScroll = self:GetComp("RootPanel/RoomInfo/List", "ScrollRectEx")
    local uiItemGO = portListScroll:GetScrollItem(0).gameObject
    return self:GetGo(uiItemGO,"product")
end

function CycleCastleSellUIView:GetGo(obj, child)
    if obj == "GetBestSellRectGO" then
        return self:GetBestSellGO()
    elseif obj == "GetFirstSellRectGO" then
        return self:GetFirstSellGO()
    else
        return self:getSuper(CycleCastleSellUIView).GetGo(self,obj, child)
    end
end

function CycleCastleSellUIView:GetBestSellBtn()
    local bestSellGO = self:GetBestSellGO()
    if bestSellGO then
        local btn = self:GetComp(bestSellGO,"unsale","Button")
        return btn
    end
    return nil
end

function CycleCastleSellUIView:GetComp(obj, child, uiType)
    if obj == "GetBestSellBtn" then
        return self:GetBestSellBtn()
    else
        return self:getSuper(CycleCastleSellUIView).GetComp(self,obj, child,uiType)
    end
end

return CycleCastleSellUIView
