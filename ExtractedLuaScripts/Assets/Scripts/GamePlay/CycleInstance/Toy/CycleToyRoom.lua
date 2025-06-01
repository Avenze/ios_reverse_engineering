local Class = require("Framework.Lua.Class")
local CycleInstanceRoomBase = require("GamePlay.CycleInstance.CycleInstanceRoomBase")
---@class CycleToyRoom:CycleInstanceRoomBase
---@field super CycleInstanceRoomBase
local CycleToyRoom = Class("CycleToyRoom",CycleInstanceRoomBase)
local FloatUI = GameTableDefine.FloatUI
local UIView = require("Framework.UI.View")
local Transport = require("GamePlay.CycleInstance.Toy.Module.FactoryTransport")
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")
local GameResMgr = require("GameUtils.GameResManager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local TimerMgr = GameTimeManager
local CycleToyAIBlackBoard = GameTableDefine.CycleToyAIBlackBoard
local EventDispatcher = EventDispatcher
local CycleToyBluePrintManager = GameTableDefine.CycleToyBluePrintManager
local AnimationUtil = CS.Common.Utils.AnimationUtil

local UnityHelper = CS.Common.Utils.UnityHelper;

local transportGOName = "tranport"

function CycleToyRoom:ctor()
    self.super.ctor(self)
    self.m_transport = nil ---@type FactoryTransport -传送带

    self.m_floatUIHandler = nil
    self.m_needShowFloatUIList = {} ---@type table<number,boolean> -所有需要显示的FloatUI

    self.m_instanceModel = nil ---@type CycleToyModel

    self.m_conveyorSystem = nil ---@type Conveyor.ConveyorSystem -传送带系统
    self.m_conveyorPrefabAddress = nil
    self.m_productEventHandler = nil
    self.m_productUnlockEventHandler = nil
    self.m_productUpgradeEventHandler = nil
    self.m_shelfGODic = nil ---@type table<number,UnityEngine.GameObject> -商品ID对应的货架
end

function CycleToyRoom:Init(roomType,data,roomCfg,GO,cb,model)

    local conveyorGO = UIView:GetGoOrNil(GO,"Conveyor")
    if conveyorGO then
        self.m_conveyorSystem = UIView:GetComp(conveyorGO,"","ConveyorSystem")
    end

    self.super.Init(self,roomType,data,roomCfg,GO,cb,model)

    local transportGO = UIView:GetGoOrNil(self.GORoot,transportGOName)
    if transportGO then
        self.m_transport = Transport.new()
        self.m_transport:Init(transportGO)
    end

    self:InitFloatUIView()

    if self:NeedUpgrade() then
        --房间是否能升级的气泡
        self:ShowBubble(CycleInstanceDefine.BubbleType.CanUpgrade)
    elseif self:IsUpgrading() then
        local curTime = TimerMgr:GetCurrentServerTime()
        local remainingTime = self.roomData.completeTime - curTime
        if remainingTime >0 then
            --房间升级中的气泡
            self:ShowBubble(CycleInstanceDefine.BubbleType.IsUpgrading)
        else
            --房间升级完成的气泡
            self:ShowBubble(CycleInstanceDefine.BubbleType.IsFinish)
        end
    end

    if self.m_conveyorSystem then
        self:UpdateConveyorBelt()
        self:UpdateConveyorGoods()
        self.m_productEventHandler = function(productID)
            if productID == self.roomConfig.production then
                self:UpdateConveyorGoods()
            end
        end
        --监听产品升级的事件
        EventDispatcher:RegEvent(GameEventDefine.OnCycleProductionModelChange,self.m_productEventHandler)
    elseif roomCfg.room_category == 4 then
        --是商场房间
        self:InitSupermarket()
        --监听产品升级的事件
        self.m_productEventHandler = function(productID)
            self:OnSupermarketProductModelChange(productID)
        end
        EventDispatcher:RegEvent(GameEventDefine.OnCycleProductionModelChange,self.m_productEventHandler)
        --监听产品解锁的事件
        self.m_productUnlockEventHandler = function(productID, callback)
            self:OnSupermarketProductUnlock(productID, callback)
        end
        --监听产品升级的事件
        self.m_productUpgradeEventHandler = function(productID, callback)
            self:OnSupermarketProductUpgrade(productID, callback)
        end
        
        EventDispatcher:RegEvent(GameEventDefine.OnCycleProductionUnlock, self.m_productUnlockEventHandler)
        EventDispatcher:RegEvent(GameEventDefine.OnCycleProductionUpgrade, self.m_productUpgradeEventHandler)
    end

    --初始化动画状态
    local roomAnimator = UIView:GetComp(self.GORoot,"roomModelState","Animator") ---@type UnityEngine.Animator
    if roomAnimator and (not roomAnimator:IsNull()) then
        roomAnimator.enabled = true
        if data.state == 2 then
            roomAnimator:Play("ToyRoomRunning")
        else
            roomAnimator:Play("ToyRoomLocked")
        end
    end
end

---override 将对应房间类型气泡标记为要显示
function CycleToyRoom:ShowBubble(bubbleType)

    self.m_needShowFloatUIList[bubbleType] = true

    self:RefreshFloatUI()
end

---override 将房间气泡标记为不显示
function CycleToyRoom:HideBubble(bubbleType)

    if not self.m_needShowFloatUIList[bubbleType] then
        return
    end

    self.m_needShowFloatUIList[bubbleType] = false

    self:DisableBubble(bubbleType)

    self:RefreshFloatUI()
end

---显示对应类型的房间气泡,真正显示在UI上
function CycleToyRoom:EnableBubble(bubbleType)

    local view = self.m_floatUIHandler and self.m_floatUIHandler.view
    if not view then
        return
    end

    if bubbleType == CycleInstanceDefine.BubbleType.IsBuilding then
        local curRoomConfig = self.roomConfig
        local timePoint = self.roomData.buildTimePoint
        local timeWait = timePoint + curRoomConfig.unlock_times
        view:Invoke("ShowCycleToyRoomIsBuildingBubble", curRoomConfig, timeWait)
    elseif bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        view:Invoke("ShowCycleToyBuildingNeedMatTips", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        view:Invoke("ShowCycleToyBuildingCanUpgradeTips", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsUpgrading then
        view:Invoke("ShowCycleToyRoomIsUpgradingBubble", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsFinish then
        view:Invoke("ShowCycleToyRoomIsFinishTips", self.roomID)
    end
end

---隐藏对应类型的房间气泡,关闭UI显示
function CycleToyRoom:DisableBubble(bubbleType)

    local view = self.m_floatUIHandler.view
    if not view then
        return
    end

    if bubbleType == CycleInstanceDefine.BubbleType.IsBuilding then
        view:Invoke("HideCycleToyRoomIsBuildingBubble")
    elseif bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        view:Invoke("HideCycleToyBuildingNeedMatTips")
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        view:Invoke("HideCycleToyBuildingCanUpgradeTips")
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsUpgrading then
        view:Invoke("HideCycleToyRoomIsUpgradingBubble")
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsFinish then
        view:Invoke("HideCycleToyRoomIsFinishTips")
    end
end

---刷新FloatUI的显示，显示所有应该显示出来的FloatUI，可以计算互斥，可以有多个不互斥的
function CycleToyRoom:RefreshFloatUI()
    for bubbleType,needShow in pairs(self.m_needShowFloatUIList) do
        if needShow then
            if self:IsSortToShowFloatUI(bubbleType) then
                self:EnableBubble(bubbleType)
            else
                self:DisableBubble(bubbleType)
            end
        end
    end
end

---注册的FloatUI
function CycleToyRoom:InitFloatUIView()
    self.m_floatUIHandler = { ["go"] = self.GORoot, m_type = "room"}
    FloatUI:SetObjectCrossCamera(self.m_floatUIHandler, function(view)
        if view then
            self:RefreshFloatUI()
        end
    end, nil, 0)
end

---清除注册的FloatUI
function CycleToyRoom:RemoveFloatUIView()
    FloatUI:RemoveObjectCrossCamera(self.m_floatUIHandler)
end

function CycleToyRoom:OnExit()
    if self.m_transport then
        self.m_transport:OnExit()
        self.m_transport = nil
    end

    self:RemoveFloatUIView()
    self.m_floatUIHandler = nil
    if self.m_productEventHandler then
        EventDispatcher:UnRegEvent(GameEventDefine.OnCycleProductionModelChange,self.m_productEventHandler)
        self.m_productEventHandler = nil
    end

    if self.m_productUnlockEventHandler then
        EventDispatcher:UnRegEvent(GameEventDefine.OnCycleProductionUnlock,self.m_productUnlockEventHandler)
        self.m_productUnlockEventHandler = nil
    end
    
    if self.m_productUpgradeEventHandler then
        EventDispatcher:UnRegEvent(GameEventDefine.OnCycleProductionUpgrade, self.m_productUpgradeEventHandler)
        self.m_productUpgradeEventHandler = nil
    end

    self.super.OnExit(self)
end

function CycleToyRoom:ShowRoom()
    self:getSuper(CycleToyRoom).ShowRoom(self)
    if self.roomData.state == 2 then
        --刷新传送带表现
        if self.m_transport then
            --如果下一个房间修建好
            local nextRoomIsUnlock = self.m_instanceModel:RoomIsUnlock(self.roomID + 1)
            --下个房间没修好,要设为关闭,修好了就不管交给下个房间判断
            if not nextRoomIsUnlock then
                self.m_transport:SetState(false)
            end
        end
        
        -- 刷新场景货架
        if self.roomConfig.production ~= 0 then
            CycleToyAIBlackBoard:RefreshShelf(self.roomData, self.roomConfig.production)
            self.m_instanceModel:RefreshClientLimit()
            self.m_instanceModel:RefreshChildLimit()
        end
    end
end

---override
function CycleToyRoom:OnBuildCompleted()
    --先不要启动生产线，设置产品后再启动
    if self.m_conveyorSystem then
        self.m_conveyorSystem.enabled = false
        self:UpdateConveyorGoods(function()
            self.m_conveyorSystem.enabled = true
        end)
        --EventDispatcher:TriggerEvent(GameEventDefine.OnCycleProductionUnlock,self.roomConfig.production)
    end
    local roomAnimator = UIView:GetComp(self.GORoot,"roomModelState","Animator") ---@type UnityEngine.Animator
    if roomAnimator and (not roomAnimator:IsNull()) then
        roomAnimator.enabled = true
        roomAnimator:Play("ToyRoomUnlocking")
    end
end

function CycleToyRoom:ShowFurPrefab(levelID,index,isBuy)
    -- 显示模型,如果没有就先加载再显示
    local furLevelConfig = self.furLevelConfig[levelID]

    local parentGO = self.roomGO.furList[index]

    local needLoad = true
    local targetGO = nil
    for k,v in pairs(parentGO.transform) do
        if string.find(v.gameObject.name , furLevelConfig.prefab) then
            needLoad = false
            targetGO = v.gameObject
            break
        end
    end
    if not needLoad then
        self:LoadFinishHandle(targetGO, index, levelID, isBuy)
        return
    end


    local path = "Assets/Res/Prefabs/furniture/"..furLevelConfig.prefab..".prefab"
    if self.path == path then
        return
    end
    self.path = path
    local oldGO = parentGO.transform:GetChild(0)

    GameResMgr:AInstantiateObjectAsyncManual(path,self,function(GO)
        if self.path ~= path then
            GameObject.Destroy(oldGO.gameObject)
            return
        end
        GO.transform:SetParent(parentGO.transform)
        GO.transform.position = oldGO.transform.position
        GO.transform.rotation = oldGO.transform.rotation
        GO.transform.localScale = oldGO.transform.localScale
        GameObject.Destroy(oldGO.gameObject)
        GO.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
        GO.name = furLevelConfig.prefab

        self:LoadFinishHandle(GO,index,levelID,isBuy)
    end)

end


---是否需要升级房间 与 钱够不够
---@return boolean,boolean needUpgrade,canUpgrade
function CycleToyRoom:NeedUpgrade()
    if self.roomConfig.room_category == CycleInstanceDefine.RoomType.ROOM_TYPE_FACTORY then
        if self.roomData.state ~= 2 or self.roomData.isUpgrading then
            return false
        end
        local furData = self.roomData.furList["1"]
        if furData.state == 1 then
            local curFurLevelID = furData.id
            local currentFurLevelCfg = self.furLevelConfig[curFurLevelID] --当前选中的家具levelConfig
            local currentFurCfg = self.furConfig[currentFurLevelCfg.furniture_id]
            local currentModel = CycleInstanceDataManager:GetCurrentModel()
            local nextFurLevelCfg = currentModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

            if not nextFurLevelCfg then
                return false
            end

            local roomLevel = self.roomData.level or 1
            --家具下一级没有房间等级需求 或 不需要升级房间
            if not nextFurLevelCfg.room_level or nextFurLevelCfg.room_level <= roomLevel then
                return false
            end
            --判断是否有房间下一级的配置
            local roomNextLevelCfg = currentModel:GetRoomLevelConfig(self.roomID,(self.roomData.level or 1)+1)
            if not roomNextLevelCfg then
                --没有下一级的配置
                return false
            end
            --判断钱够不够
            local haveCoin = currentModel:GetCurInstanceCoin()
            local upgradeCostCoin = currentModel:GetRoomUpgradeCost(self.roomID,(self.roomData.level or 1)+1)
            local isEnoughCoin = not BigNumber:CompareBig(upgradeCostCoin,haveCoin)

            return true,isEnoughCoin
        end
    end
    return false
end

---根据房间气泡优先级，判断是否该显示对应类型的气泡
function CycleToyRoom:IsSortToShowFloatUI(bubbleType)
    --可修建=升级完成=修建完成=修建中>缺原料>可升级
    if bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        if self:IsUpgrading() then
            return false
        end
        return true
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        if self:IsLackOfMaterial() then
            return false
        else
            return true
        end
    else
        return true
    end
end

---获取此房间的流水线系统
function CycleToyRoom:GetConveyorSystem()
    return self.m_conveyorSystem
end

---刷新流水线传送带数量
function CycleToyRoom:UpdateConveyorBelt()
    if self.m_conveyorSystem then
        if self.roomData.state == 2 then
            local curWorker = self.m_instanceModel:GetWorkerNum(self.roomID)
            self.m_conveyorSystem:SetEnableBeltCount(curWorker)
        else
            self.m_conveyorSystem:SetEnableBeltCount(0)
        end
    end
end

---刷新流水线货物Prefab
function CycleToyRoom:UpdateConveyorGoods(onChangeModelCallback)
    if self.m_conveyorSystem then
        if self.roomData.state == 2 then
            local prefabAddress = GameTableDefine.CycleToyBluePrintManager:GetProductLowModelAddress(self.roomConfig.production)
            if self.m_conveyorPrefabAddress ~= prefabAddress then
                self.m_conveyorPrefabAddress = prefabAddress
                GameResMgr:AInstantiateObjectAsyncManual(prefabAddress, self, function(go)
                    self.m_conveyorSystem:SetGoodsPrefab(go)
                    if onChangeModelCallback then
                        onChangeModelCallback()
                    end
                end)
            end
        end
    end
end

---初始化超市房间
function CycleToyRoom:InitSupermarket()
    local shelf = {}
    self.m_shelfGODic = shelf
    local furList = self.roomGO.furList
    local roomID = self.roomID
    for i = 1, #furList do
        local furLevelCfg = self.m_instanceModel:GetFurlevelConfigByRoomFurIndex(roomID, i)
        local productID = furLevelCfg.resource_type
        shelf[productID] = furList[i].transform:GetChild(0).gameObject
        --货架的状态
        local isSelling = self.m_instanceModel:ProductIsSelling(productID)
        -- 初始化解锁状态
        local animator = UIView:GetComp(furList[i].transform:GetChild(0).gameObject, "", "Animator")
        animator:Play(isSelling and "SaleRoom_workspace_unlock" or "SaleRoom_workspace_locked")

        if isSelling then
            self:OnSupermarketProductModelChange(productID)
        end
    end
end

function CycleToyRoom:OnSupermarketProductUpgrade(productID, cb)
    local shelfGO = self.m_shelfGODic[productID]
    local animator = UIView:GetComp(shelfGO, "", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(shelfGO, "ANIM_END", function()
        GameTableDefine.GameUIManager:GetEnableTouch(true)
        if cb then
            cb()
        end
    end) -- 调用的Unity的方法, 一次穿越
    animator:Play("SaleRoom_workspace_unlocking2")
end

---超市货架解锁
function CycleToyRoom:OnSupermarketProductUnlock(productID, cb)
    local shelfGO = self.m_shelfGODic[productID]
    local animator = UIView:GetComp(shelfGO, "", "Animator")
    AnimationUtil.AddKeyFrameEventOnObj(shelfGO, "ANIM_END", function()
        GameTableDefine.GameUIManager:GetEnableTouch(true)
        if cb then
            cb()
        end
    end) -- 调用的Unity的方法, 一次穿越
    animator:Play("SaleRoom_workspace_unlocking")

    self:OnSupermarketProductModelChange(productID)
end

---超市货架商品模型修改
function CycleToyRoom:OnSupermarketProductModelChange(productID)
    --货架的状态
    local isSelling = self.m_instanceModel:ProductIsSelling(productID)
    if not isSelling then
        return
    end
    local shelfGO = self.m_shelfGODic[productID]
    local modelParentGO = UIView:GetGo(shelfGO, "ToyPosition")
    if modelParentGO.transform.childCount > 0 then
        UnityHelper.DestroyGameObject(modelParentGO.transform:GetChild(0).gameObject)
    end

    local prefabAddress = CycleToyBluePrintManager:GetProductLowModelAddress(productID)
    GameResMgr:AInstantiateObjectAsyncManual(prefabAddress, self, function(go)
        UnityHelper.AddChildToParent(modelParentGO.transform,go.transform)
    end)
end

return CycleToyRoom