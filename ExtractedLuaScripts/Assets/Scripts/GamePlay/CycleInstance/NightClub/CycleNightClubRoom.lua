local Class = require("Framework.Lua.Class")
local CycleInstanceRoomBase = require("GamePlay.CycleInstance.CycleInstanceRoomBase")
---@class CycleNightClubRoom:CycleInstanceRoomBase
---@field super CycleInstanceRoomBase
local CycleNightClubRoom = Class("CycleNightClubRoom",CycleInstanceRoomBase)
local FloatUI = GameTableDefine.FloatUI
local UIView = require("Framework.UI.View")
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")
local GameResMgr = require("GameUtils.GameResManager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local TimerMgr = GameTimeManager
local CycleNightClubAIBlackBoard = GameTableDefine.CycleNightClubAIBlackBoard
local EventDispatcher = EventDispatcher
local CycleNightClubBluePrintManager = GameTableDefine.CycleNightClubBluePrintManager
local AnimationUtil = CS.Common.Utils.AnimationUtil
local GameObject = CS.UnityEngine.GameObject

local UnityHelper = CS.Common.Utils.UnityHelper
local GameTimeManager = GameTimeManager

function CycleNightClubRoom:ctor()
    self.super.ctor(self)

    self.m_floatUIHandler = nil
    self.m_needShowFloatUIList = {} ---@type table<number,boolean> -所有需要显示的FloatUI

    self.m_instanceModel = nil ---@type CycleNightClubModel

    self.m_productEventHandler = nil
    self.m_productUnlockEventHandler = nil
    self.m_productUpgradeEventHandler = nil
    self.m_shelfGODic = nil ---@type table<number,UnityEngine.GameObject> -商品ID对应的货架
    self.m_employeeUIPosition = nil ---@type UnityEngine.Transform
    self.m_employeeBubbleTimer = nil
end

function CycleNightClubRoom:Init(roomType,data,roomCfg,GO,cb,model)

    self.super.Init(self,roomType,data,roomCfg,GO,cb,model)

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

    if roomCfg.room_category == 4 then
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
    --local roomAnimator = UIView:GetComp(self.GORoot,"roomModelState","Animator") ---@type UnityEngine.Animator
    --if roomAnimator and (not roomAnimator:IsNull()) and roomAnimator.isActiveAndEnabled then
    --    roomAnimator.enabled = true
    --    if data.state == 2 then
    --        roomAnimator:Play("NightClubRoomRunning")
    --    else
    --        roomAnimator:Play("NightClubRoomLocked")
    --    end
    --end
end

---override 将对应房间类型气泡标记为要显示
function CycleNightClubRoom:ShowBubble(bubbleType)

    self.m_needShowFloatUIList[bubbleType] = true

    self:RefreshFloatUI()
end

---override 将房间气泡标记为不显示
function CycleNightClubRoom:HideBubble(bubbleType)

    if not self.m_needShowFloatUIList[bubbleType] then
        return
    end

    self.m_needShowFloatUIList[bubbleType] = false

    self:DisableBubble(bubbleType)

    self:RefreshFloatUI()
end

---显示对应类型的房间气泡,真正显示在UI上
function CycleNightClubRoom:EnableBubble(bubbleType)

    local view = self.m_floatUIHandler and self.m_floatUIHandler.view
    if not view then
        return
    end

    if bubbleType == CycleInstanceDefine.BubbleType.IsBuilding then
        local curRoomConfig = self.roomConfig
        local timePoint = self.roomData.buildTimePoint
        local timeWait = timePoint + curRoomConfig.unlock_times
        view:Invoke("ShowCycleNightClubRoomIsBuildingBubble", curRoomConfig, timeWait)
    elseif bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        view:Invoke("ShowCycleNightClubBuildingNeedMatTips", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        view:Invoke("ShowCycleNightClubBuildingCanUpgradeTips", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsUpgrading then
        view:Invoke("ShowCycleNightClubRoomIsUpgradingBubble", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsFinish then
        view:Invoke("ShowCycleNightClubRoomIsFinishTips", self.roomID)
    end
end

---隐藏对应类型的房间气泡,关闭UI显示
function CycleNightClubRoom:DisableBubble(bubbleType)

    local view = self.m_floatUIHandler.view
    if not view then
        return
    end

    if bubbleType == CycleInstanceDefine.BubbleType.IsBuilding then
        view:Invoke("HideCycleNightClubRoomIsBuildingBubble")
    elseif bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        view:Invoke("HideCycleNightClubBuildingNeedMatTips")
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        view:Invoke("HideCycleNightClubBuildingCanUpgradeTips")
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsUpgrading then
        view:Invoke("HideCycleNightClubRoomIsUpgradingBubble")
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsFinish then
        view:Invoke("HideCycleNightClubRoomIsFinishTips")
    end
end

---刷新FloatUI的显示，显示所有应该显示出来的FloatUI，可以计算互斥，可以有多个不互斥的
function CycleNightClubRoom:RefreshFloatUI()
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
function CycleNightClubRoom:InitFloatUIView()
    self.m_floatUIHandler = { ["go"] = self.GORoot, m_type = "room",nextEmployeePlayTime = 0}
    FloatUI:SetObjectCrossCamera(self.m_floatUIHandler, function(view)
        if view then
            self:RefreshFloatUI()
            self:ShowEmployeeBubble()
        end
    end, nil, 0)
end

---清除注册的FloatUI
function CycleNightClubRoom:RemoveFloatUIView()
    FloatUI:RemoveObjectCrossCamera(self.m_floatUIHandler)
end

function CycleNightClubRoom:OnExit()

    if self.m_employeeBubbleTimer then
        GameTimer:StopTimer(self.m_employeeBubbleTimer)
        self.m_employeeBubbleTimer = nil
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
    self.m_employeeUIPosition = nil
    self.super.OnExit(self)

end

function CycleNightClubRoom:ShowRoom()
    self:getSuper(CycleNightClubRoom).ShowRoom(self)
    if self.roomData.state == 2 then
        -- 刷新场景货架
        if self.roomConfig.production ~= 0 then
            --CycleNightClubAIBlackBoard:RefreshShelf(self.roomData, self.roomConfig.production)
            self.m_instanceModel:RefreshClientLimit()
            self.m_instanceModel:RefreshDurationOfStayLimit()
        end
        self:ShowEmployeeBubble()
    end
end

---员工气泡
function CycleNightClubRoom:ShowEmployeeBubble()
    if not self.m_employeeUIPosition then
        local uiPosition
        local modelTrans = self.roomGO.modelRoot.transform:GetChild(0)
        if modelTrans and not modelTrans:IsNull() then
            uiPosition = UIView:GetTrans(modelTrans.gameObject,"UIPosition")
        end
        if not uiPosition or uiPosition:IsNull() then
            uiPosition = self.roomGO.modelRoot.transform
        end
        self.m_employeeUIPosition = uiPosition
    end
    if  self.roomConfig.room_category == 1 and self.roomData.state == 2 then

        if not self.m_employeeBubbleTimer then

            local currentModel = self.m_instanceModel
            local cdData = currentModel.config_global.cy4_bubble_employee_cd
            local randomLeft = cdData[1] or 15
            local randomRight = cdData[2] or 30

            self.m_employeeBubbleTimer = GameTimer:CreateNewTimer(1,function()
                local now = GameTimeManager:GetCurLocalTime(true)
                if now >= self.m_floatUIHandler.nextEmployeePlayTime then
                    self.m_floatUIHandler.nextEmployeePlayTime = now + math.random(randomLeft,randomRight)

                    local view = self.m_floatUIHandler and self.m_floatUIHandler.view
                    if view then
                        view:Invoke("ShowCycleNightClubEmployeeBubble",self.roomConfig.object_name,self.m_employeeUIPosition)
                    end
                end
            end,true)
        end
    end
end

---override
--function CycleNightClubRoom:OnBuildCompleted()
--    local roomAnimator = UIView:GetComp(self.GORoot,"roomModelState","Animator") ---@type UnityEngine.Animator
--    if roomAnimator and (not roomAnimator:IsNull()) then
--        roomAnimator.enabled = true
--        roomAnimator:Play("NightClubRoomUnlocking")
--    end
--end

function CycleNightClubRoom:ShowFurPrefab(levelID,index,isBuy)
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
function CycleNightClubRoom:NeedUpgrade()
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
function CycleNightClubRoom:IsSortToShowFloatUI(bubbleType)
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

---初始化超市房间
function CycleNightClubRoom:InitSupermarket()
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

function CycleNightClubRoom:OnSupermarketProductUpgrade(productID, cb)
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
function CycleNightClubRoom:OnSupermarketProductUnlock(productID, cb)
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
function CycleNightClubRoom:OnSupermarketProductModelChange(productID)
    --货架的状态
    local isSelling = self.m_instanceModel:ProductIsSelling(productID)
    if not isSelling then
        return
    end
    local shelfGO = self.m_shelfGODic[productID]
    local modelParentGO = UIView:GetGo(shelfGO, "NightClubPosition")
    if modelParentGO.transform.childCount > 0 then
        UnityHelper.DestroyGameObject(modelParentGO.transform:GetChild(0).gameObject)
    end

    local prefabAddress = CycleNightClubBluePrintManager:GetProductLowModelAddress(productID)
    GameResMgr:AInstantiateObjectAsyncManual(prefabAddress, self, function(go)
        UnityHelper.AddChildToParent(modelParentGO.transform,go.transform)
    end)
end

return CycleNightClubRoom