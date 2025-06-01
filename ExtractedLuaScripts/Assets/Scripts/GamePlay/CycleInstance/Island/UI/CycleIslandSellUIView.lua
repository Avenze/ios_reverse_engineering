
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


local roomsConfig = nil
local furnitureLevelConfig = nil
local furnitureConfig = nil
local resConfig = nil

local CycleIslandBuildingUIView = Class("CycleIslandBuildingUIView", UIView)

function CycleIslandBuildingUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

local selectIndex = 1   --正在选择的item索引
local lastSelectedIndex = 1
local currentLabel = 1    --1是家具,2是员工
local UItype = 1    --1是工厂,2是补给,3是港口
local isOpen = false


function CycleIslandBuildingUIView:OnEnter()
    self.m_currentModel = GameTableDefine.CycleInstanceDataManager:GetCurrentModel() ---@type CycleInstanceModel
    roomsConfig = self.m_currentModel.roomsConfig
    furnitureLevelConfig = self.m_currentModel.furnitureLevelConfig
    furnitureConfig = self.m_currentModel.furnitureConfig
    resConfig = self.m_currentModel.resourceConfig

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



function CycleIslandBuildingUIView:ShowWharfUI(roomID,select,isFirst)
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

function CycleIslandBuildingUIView:ShowPortListItem(index,trans)
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
    resSellPrice = BigNumber:FormatBigNumber(resSellPrice * buffNum)
    local isLocked = self.m_currentModel:GetResLockedState(resID)
    local income, roomID, highestResID = self.m_currentModel:GetCurHighestProfit()

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
            else
                self:GetGo(go, "product/selling"):SetActive(false)
                self:GetGo(go, "product/unsale"):SetActive(true)
                self:GetGo(go, "product/lock"):SetActive(false)
                self:SetText(go, "product/unsale/price/num", resSellPrice)
                self:SetSprite(self:GetComp(go, "product/unsale/icon", "Image"), "UI_Common", resCfg.icon)
                self:GetGo(go, "product/unsale/recommendMark"):SetActive(highestResID == resID)
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
        self.m_currentModel:PlayPortAnimation(cancelIndex, index)
    end)
    self:GetGo("RootPanel/RoomInfo/List/Viewport/Content/shelf"):SetActive(true)
end

function CycleIslandBuildingUIView:SwitchSell(roomID, index, furLevelID)
    for k, v in pairs(self.wharfFurData) do
        local furIndex = v.index
        if v.isOpen == true and furIndex <= 12 then
            local furLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, furIndex)
            self.m_currentModel:SetRoomFurnitureData(tostring(roomID), furIndex, furLevelCfg.id, { isOpen = false })
            local shipLevelID = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, furIndex + 12)
            self.m_currentModel:SetRoomFurnitureData(tostring(roomID), furIndex + 12, shipLevelID.id, { isOpen = false })
            --TODO 关门动画
            
        end
    end
    local newFurLevelCfg = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, index)
    self.m_currentModel:SetRoomFurnitureData(tostring(roomID), index, newFurLevelCfg.id, { isOpen = true })
    local shipLevelID = self.m_currentModel:GetFurlevelConfigByRoomFurIndex(roomID, index + 12)
    self.m_currentModel:SetRoomFurnitureData(tostring(roomID), index + 12, shipLevelID.id, { isOpen = true })
    --TODO 开门动画
    if CycleInstanceModel.roomsConfig[roomID] then
        GameSDKs:TrackForeign("cy_sell_change", {id = tonumber(CycleInstanceModel.roomsConfig[roomID].production)})
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


return CycleIslandBuildingUIView
