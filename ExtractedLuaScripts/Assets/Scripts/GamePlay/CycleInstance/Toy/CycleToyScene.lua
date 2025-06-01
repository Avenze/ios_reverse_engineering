local Class = require("Framework.Lua.Class");
local CycleInstanceSceneBase = require("GamePlay.CycleInstance.CycleInstanceSceneBase")
---@class CycleToyScene:CycleInstanceSceneBase
---@field super CycleInstanceSceneBase
local CycleToyScene = Class("CycleToyScene", CycleInstanceSceneBase)

local EventDispatcher = EventDispatcher
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local EventTriggerListener = CS.Common.Utils.EventTriggerListener

local ConfigMgr = GameTableDefine.ConfigMgr
local FloatUI = GameTableDefine.FloatUI
local GameUIManager = GameTableDefine.GameUIManager
local CycleToyUnlockUI = GameTableDefine.CycleToyUnlockUI
local CycleToyBuildingUI = GameTableDefine.CycleToyBuildingUI
local CycleToySellUI = GameTableDefine.CycleToySellUI
local UnlockingSkipUI = GameTableDefine.UnlockingSkipUI
local ActorManager = GameTableDefine.ActorManager
local CycleToyAIBlackBoard = GameTableDefine.CycleToyAIBlackBoard
local GuideManager = GameTableDefine.GuideManager

local Landmark ---场景特殊物品
local SlotBuilding ---拉霸机建筑
local spacialGOPopIsShow = false    ---正在显示特殊物品点击气泡
local clientNavRoot = nil ---客户寻路根节点
local dinningRoom = nil ---餐厅房间根节点

local ChildAnimList = {
    [1] = "cheer1",
    [2] = "cheer2",
    [3] = "cheer3"
}

function CycleToyScene:ctor()

    self:getSuper(CycleToyScene).ctor(self)

    self.m_instanceModel = nil ---@type CycleToyModel

    self.floatUI = {}              ---地标 气泡所需结构
    self.m_slotMachineFloatUI = {} ---拉霸机 气泡结构
    self.getMoneyFloatUI = nil --- 桌子气泡结构
    self.clientFloatUI = nil --- 顾客气泡结构
    self.tableGOTable = {}
    self.m_landmarkFeel = nil -- 地标动画
    self.m_portWorkplaceGos = {} --码头的对应位置的go
    self.m_isBuyLandmarkClick = nil ---买地标时来标记不要触发Feedback
end

function CycleToyScene:OnEnter()
    self:getSuper(CycleToyScene).OnEnter(self)
    self.getMoneyFloatUI = {}
    self.clientFloatUI = {}
    --埋点:进入循环副本
    local isFirstEnter = self.m_instanceModel:GetIsFirstEnter()
    GameSDKs:TrackForeign("cyinstance_enter", {first_time = isFirstEnter and 1 or 0})
    self.m_instanceModel:SetIsFirstEnter()

end

function CycleToyScene:Update(dt)
    self:getSuper(CycleToyScene).Update(self)
end

function CycleToyScene:OnExit()

    self.m_instanceModel = nil
    self.floatUI = nil
    self.m_slotMachineFloatUI = nil
    self.m_landmarkFeel = nil
    self.m_portWorkplaceGos = nil

    if self.m_landmarkAnimEventCallback then
        EventDispatcher:UnRegEvent(GameEventDefine.LandMarkAnimEnd,self.m_landmarkAnimEventCallback)
        self.m_landmarkAnimEventCallback = nil
    end

    self:getSuper(CycleToyScene).OnExit(self)
    local allClient = ActorManager:GetActorByType("CycleToyClient")
    if allClient and Tools:GetTableSize(allClient) > 0 then
        for i = #allClient, 1, -1 do
            ActorManager:DestroyActor(allClient[i].instanceID)
        end  
    end
    local allChild = ActorManager:GetActorByType("CycleToyChild")
    if allChild and Tools:GetTableSize(allChild) > 0 then
        for i = #allChild, 1, -1 do
            ActorManager:DestroyActor(allChild[i].instanceID)
        end
    end

    CycleToyAIBlackBoard:OnExit()
    --退出场景时回收场景中的气泡
    --for k,v in pairs(self.tableFloatUI) do
    --    FloatUI:RemoveObjectCrossCamera(v)
    --end
    --for k,v in pairs(self.clientFloatUI) do
    --    FloatUI:RemoveObjectCrossCamera(v)
    --end
    
end

function CycleToyScene:InitScene(model)
    self:InitAIBlackBoardData()
    self:getSuper(CycleToyScene).InitScene(self,model)
    self:InitAIBlackBoardData()

    Landmark = GameObject.Find("Landmark")
    SlotBuilding = GameObject.Find("Laba")

    self:InitSpecialGameObject()

end

function CycleToyScene:InitRooms()
    self:getSuper(CycleToyScene).InitRooms(self)
    --TODO 新港口
end

function CycleToyScene:InitAIBlackBoardData()
    -- 进入节点
    local inPos = nil
    local inPos1 = GameObject.Find("Customer_pos/in/random_pos_1")
    local inPos2 = GameObject.Find("Customer_pos/in/random_pos_2")
    local inPos3 = GameObject.Find("Customer_pos/in/random_pos_3")
    inPos = {
        [1] = inPos1,
        [2] = inPos2,
        [3] = inPos3,
    }
    
    -- 退出节点
    local outPos = nil
    local outPos1 = GameObject.Find("Customer_pos/out/random_pos_1")
    local outPos2 = GameObject.Find("Customer_pos/out/random_pos_2")
    local outPos3 = GameObject.Find("Customer_pos/out/random_pos_3")
    outPos = {
        [1] = outPos1,
        [2] = outPos2,
        [3] = outPos3,
    }
    
    -- 大门
    local gateData = nil
    local gatePos = GameObject.Find("Customer_pos/Gate/GatePos")
    local outGate = GameObject.Find("Customer_pos/Gate/GatePos_Out")
    gateData = {
        pos = gatePos,
        outPos = outGate
    }
    
    -- 结账柜台
    local payPos = nil
    --local payPos1 = GameObject.Find("Customer_pos/Pay/PayPos_1")
    local payPos2 = GameObject.Find("Customer_pos/Pay/PayPos_2")
    --local character1 = self:GetGo(payPos1, "CY3_Cashier_01")
    local character2 = self:GetGo(payPos2, "CY3_Cashier_02")
    --local animator1 = self:GetComp(character1, "", "Animator")
    local animator2 = self:GetComp(character2, "", "Animator")
    payPos = {
        --[1] = {
        --    pos = payPos1,
        --    character = character1,
        --    animator = animator1
        --},
        [1] = {
            pos = payPos2,
            character = character2,
            animator = animator2
        }
    }
    
    -- 闲逛点
    local strollPos = nil
    local parent = GameObject.Find("Customer_pos/Walk")
    local roomPosArray = UnityHelper.GetAllChilds(parent)
    strollPos = {}
    for i = 0, roomPosArray.Length - 1 do
        local roomID = tonumber(roomPosArray[i].name)
        strollPos[roomID] = {}
        local posList = UnityHelper.GetAllChilds(roomPosArray[i])
        for k = 0, posList.Length - 1 do
            table.insert(strollPos[roomID], posList[k])
        end
    end

    -- 气氛组寻路点
    local kids = GameObject.Find("Customer_pos/Kid_pos")
    local kidPosArray = UnityHelper.GetAllChilds(kids)
    local kidPos = {}
    for i = 0, kidPosArray.Length - 1 do
        local roomID = tonumber(kidPosArray[i].name)
        kidPos[roomID] = {}
        local posList = UnityHelper.GetAllChilds(kidPosArray[i])
        for k = 0, posList.Length - 1 do
            table.insert(kidPos[roomID], posList[k])
        end
    end

    -- 货架
    local roomData = self:GetRoomByID(1043)
    local shelf = {}
    if roomData then
        for i = 1, #roomData.roomGO.furList do
            local workPos = self:GetGo(roomData.roomGO.furList[i], "workPos_1")
            local furLevelCfg = self.m_instanceModel:GetFurlevelConfigByRoomFurIndex(roomData.roomID, i)
            shelf[furLevelCfg.resource_type] = workPos
        end
    end
    
    CycleToyAIBlackBoard:Init(inPos, outPos, gateData, payPos, strollPos, shelf, kidPos)
end

---override 播放完开场TimeLine后触发
function CycleToyScene:OnOpeningTimeLineOver()
    GameTableDefine.CycleToyOfflineRewardUI:GetView()
    local guideID = self.m_instanceModel:GetGuideID()
    if not guideID then
        GuideManager.currStep = CycleInstanceDefine.GuideDefine.Toy.Opening -- instanceBind.guideID
        GuideManager:ConditionToStart()
    else
        GameTableDefine.CycleToyPopUI:PackTrigger(4)
    end
end

---获取房间对象
---@overload
---@return CycleToyRoom
function CycleToyScene:GetRoomByID(roomID)
    return self.Rooms[roomID]
end

function CycleToyScene:InitSpecialGameObject()
    self:ShowSpecialGameObject(not self.m_instanceModel:GetLandMarkCanPurchas())

    --绑定场景特殊物品点击事件
    local specialGOBox = GameObject.Find("Miscellaneous/Environment/Landmark/roombox")
    self.floatUI.Landmark = { ["go"] = Landmark ,m_type = "Landmark"}
    FloatUI:SetObjectCrossCamera(self.floatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowCycleToySpacialGOPop", false)
            --没买的提示
            if self.m_instanceModel:GetLandMarkCanPurchas() then
                view:Invoke("ShowCycleToySpacialGOBuyTipPop", true)
            end
        end
    end, nil, "roombox")

    self.m_landmarkAnimator = self:GetComp(Landmark,"bought/SF_Prop_OptimusPrime","Animator")

    self:SetButtonClickHandler(specialGOBox, function()
        if not self.m_instanceModel:GetLandMarkCanPurchas() then --买了1.5
            if not spacialGOPopIsShow then
                if self.floatUI.Landmark.view then
                    self.floatUI.Landmark.view:ShowCycleToySpacialGOPop(true)
                end

                spacialGOPopIsShow = true

                GameTimer:CreateNewTimer(3, function()
                    spacialGOPopIsShow = false
                    if self.floatUI.Landmark.view then
                        self.floatUI.Landmark.view:ShowCycleToySpacialGOPop(false)
                    end
                    --FloatUI:DestroyFloatUIView(self.floatUI.Landmark.guid)
                end)
            end

            --买地标触发一次Click,这次不播放Feedback,与动画切换
            if self.m_isBuyLandmarkClick then
                self.m_isBuyLandmarkClick = false
                return
            end

            --切换地标动画，click
            if self.m_landmarkAnimator then
                if self.m_landmarkAnimator:GetCurrentAnimatorStateInfo(0):IsName("idle2") then
                    self.m_landmarkAnimator:Play("click2")
                elseif self.m_landmarkAnimator:GetCurrentAnimatorStateInfo(0):IsName("idle") then
                    self.m_landmarkAnimator:Play("click")
                end
            end
            if not self.m_landmarkFeel then
                self.m_landmarkFeel = self:GetComp(Landmark, "bought/Statue/clickFB", "MMFeedbacks")
            end
            if not self.m_landmarkFeel then
                return
            end
            self.m_landmarkFeel:PlayFeedbacks()
        else
            --local landMarkShopID = CycleInstanceDataManager:GetInstanceBind().landmark_id
            if self.m_instanceModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.Toy.UnlockMilestone) then
                GameTableDefine.CycleToyShopUI:OpenBuyLandmark()
            end
        end
    end)

    local slotRoomBox = GameObject.Find("Miscellaneous/Environment/Laba/roombox")
    self:SetButtonClickHandler(slotRoomBox, function()
        if self.m_instanceModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.Toy.UnlockMilestone) then
            GameTableDefine.CycleToySlotMachineUI:OpenView()
            -- GameSDKs:TrackForeign("button_event", { slot_bld = 1})
        end
    end)

    self.m_slotMachineFloatUI.Landmark = { ["go"] = SlotBuilding ,m_type = "SlotBuilding"}
    FloatUI:SetObjectCrossCamera(self.m_slotMachineFloatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowCycleToySlotBuildingBubble")
        end
    end, nil, "roombox")

    --播放 小孩欢呼的动画
    local childAnimators = {}
    local animatorRootTrans = self:GetTrans(Landmark,"bought/kid")
    local childCount = animatorRootTrans.childCount
    for i = 1, childCount do
        local childAnimGO = animatorRootTrans:GetChild(i-1).gameObject
        local animator = self:GetComp(childAnimGO,"","Animator")
        if animator then
            childAnimators[#childAnimators+1] = animator
        end
    end

    local animatorCount = #childAnimators

    self.m_landmarkAnimEventCallback = function()
        for i = 1, animatorCount do
            GameTimer:CreateNewTimer(0.1 * math.random(0,5),function()
                if not childAnimators[i]:IsNull() then
                    childAnimators[i]:Play(ChildAnimList[math.random(1,3)])
                end
            end)
        end
    end

    EventDispatcher:RegEvent(GameEventDefine.LandMarkAnimEnd,self.m_landmarkAnimEventCallback)
end

---检查是否需要新增员工
function CycleToyScene:CreateWorkers(furnitureGo, roomGo, furIndex, isBuy, roomID,personList)
    self:getSuper(CycleToyScene).CreateWorkers(self,furnitureGo, roomGo, furIndex, isBuy, roomID,personList)
end

---override 员工数量变化后调用
---@param room CycleToyRoom
function CycleToyScene:OnWorkerCountChange(room)
    room:UpdateConveyorBelt()
end

local ActorPath = "GamePlay.CycleInstance.Toy.AI."

---override 创建Actor
function CycleToyScene:NewCreateWorker(furnitureGo, roomGo, index, isBuy, roomId)

    local spawnPosTr = self:GetTrans(roomGo, "spawnPos")  -- 出生点

    local workPosTr = self:GetTrans(furnitureGo, "workPos_"..index) --工位点

    local facePosTr = self:GetTrans(workPosTr.gameObject, "face") --工位点朝向

    local actionPosTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index) or workPosTr --工作点

    local faceTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index .. "/face") or facePosTr

    local pfbName = ConfigMgr.config_character[tonumber(self.roomsData[roomId].furList[tostring(1)].worker.prefab[index])].prefab

    local spawnPos = actionPosTr.position

    --重构测试调用
    local ActorManager = GameTableDefine.ActorManager

    local furData = self.roomsData[roomId].furList[tostring(1)]
    local data = {
        buildID = "instance", --所属建筑ID,这里把副本场景也看成一个building
        roomID = roomId, --所属房间ID
        furnitureID = furData.id, --所属家具ID
        furnitureIndex = 1 --所属家具位置索引
    }
    local prefabPath = "Assets/Res/Prefabs/character/Instance/" .. pfbName .. ".prefab"

    local worker = ActorManager:CreateActorSync("CycleToyWorker", data, ActorPath)  ---@type CycleToyWorker
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, worker, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        worker:Init(worker.instanceID,go,{
            roomID = roomId,
            furnitureIndex = index,
            workPosTr = workPosTr,
            workFaceTr = facePosTr,
            actPosTr = actionPosTr,
            actFaceTr = faceTr,
            roomGO = roomGo,
            furGo = furnitureGo,
            spawnPos = spawnPos,
        },spawnPosTr.position,spawnPosTr.rotation,isBuy)
    end)

    return worker
end

--function CycleToyScene:CreateClients(roomID, level, tableIndex)
--    local roomLevelCfg = self.m_instanceModel:GetRoomLevelConfig(roomID, level)
--    local clientCount = math.random(roomLevelCfg.roll_num[1], roomLevelCfg.roll_num[2])
--    local clientList = {}
--    for i = 1, clientCount do
--        local curCount = math.random(1, #roomLevelCfg.character_id)
--        clientList[#clientList + 1] = roomLevelCfg.character_id[curCount]
--    end
--
--    local actorID = clientList[1]
--    local leader = nil
--    --生成带头大哥
--    leader = self:CreateClient(actorID, tableIndex, nil, nil, function(client, go)
--        if clientCount > 1 then
--            local posNum = clientCount - 1
--            local followPosTrans = self:GetTrans(go, "Follow_pos")
--            local childsCount = followPosTrans.childCount
--            local childs = {}
--            for i = 1, childsCount do
--                childs[#childs + 1] = followPosTrans:GetChild(i - 1)
--            end
--            Tools:ShuffleArray(childs)
--            for i = 1, posNum do
--                --生成跟随小弟
--                actorID = clientList[i + 1]
--                local curFollowPos = childs[i].transform
--                self:CreateClient(actorID, tableIndex, client, curFollowPos)
--            end
--        end
--    end)
--    
--end

function CycleToyScene:CreateClient(actorID)
    local actorType = "CycleToyClient"
    local data = {
        buildID = "instance", --所属建筑ID,这里把副本场景也看成一个building
        roomID = "DinningRoom", --所属房间ID
        furnitureID = "table", --所属家具ID
        furnitureIndex = 1 --所属家具位置索引
    }
    local pfbName = ConfigMgr.config_character[tonumber(actorID)].prefab
    local prefabPath = "Assets/Res/Prefabs/character/Instance/V04/" .. pfbName .. ".prefab"
    local actorPath = "GamePlay.CycleInstance.Toy.AI."

    local client = ActorManager:CreateActorSync(actorType, data, actorPath) ---@type CycleToyClient
    
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, client, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        client:Init(client.instanceID, go, {})
    end)
    return client
end

function CycleToyScene:CreateChild(actorID)
    local actorType = "CycleToyChild"
    local data = {
        buildID = "instance", --所属建筑ID,这里把副本场景也看成一个building
        roomID = "DinningRoom", --所属房间ID
        furnitureID = "table", --所属家具ID
        furnitureIndex = 1 --所属家具位置索引
    }
    local pfbName = ConfigMgr.config_character[tonumber(actorID)].prefab
    local prefabPath = "Assets/Res/Prefabs/character/Instance/V04/" .. pfbName .. ".prefab"
    local actorPath = "GamePlay.CycleInstance.Toy.AI."

    local client = ActorManager:CreateActorSync(actorType, data, actorPath) ---@type CycleToyClient

    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, client, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        client:Init(client.instanceID, go, {})
    end)

    return client
end

function CycleToyScene:ShowSpecialGameObject(active)
    if active then
        self:GetGo(Landmark, "bought"):SetActive(true)
        self:GetGo(Landmark, "broken"):SetActive(false)
    else
        self:GetGo(Landmark, "bought"):SetActive(false)
        self:GetGo(Landmark, "broken"):SetActive(true)
    end
end

function CycleToyScene:BuySpecialGameObjectAnimationPlay()
    --设置当前摄像机到对应的节点
    if Landmark then
        self:LocatePosition(Landmark.transform.position, false, function()
            local onEndCallback
            onEndCallback = function(go)
                self:ShowSpecialGameObject(true)
                EventDispatcher:UnRegEvent("CY1_LANDMARK_TIMELINE_END",onEndCallback)
                GameUIManager:SetEnableTouch(true)
                --显示地标属性气泡
                local specialGOBox = GameObject.Find("Miscellaneous/Environment/Landmark/roombox")
                local event = EventTriggerListener.Get(specialGOBox)
                if event then
                    self.m_isBuyLandmarkClick = true
                    event:OnPointerClick()
                end
            end
            EventDispatcher:RegEvent("CY1_LANDMARK_TIMELINE_END", onEndCallback)
            --地标动画动画播放
            local landmarkPlayable = self:GetComp(Landmark,"","PlayableDirector")
            if landmarkPlayable and not landmarkPlayable:IsNull() then
                landmarkPlayable.time = 0
                landmarkPlayable:Play()
                GameUIManager:SetEnableTouch(false)
            end
        end)
    end
end

---override 房间被点击后
function CycleToyScene:OnRoomBeClicked(clickRoomID)
    local curRoomData = self.roomsData[clickRoomID]
    local curRoomCfg = self.roomsConfig[clickRoomID]
    if curRoomData.state == 0 then
        --未解锁,点击显示解锁界面
        CycleToyUnlockUI:ShowUI(clickRoomID)
    elseif curRoomData.state == 1 then
        --在解锁中,是否花钻石快速完成
        local room = self:GetRoomByID(clickRoomID)
        local timePoint = curRoomData.buildTimePoint
        local timeWait = timePoint + curRoomCfg.unlock_times
        UnlockingSkipUI:ShowCycleIslandBuildingSkipUI(curRoomCfg, timeWait,room.m_floatUIHandler)
    elseif curRoomData.state == 2 then
        --已解锁,点击显示RoomUI
        if curRoomCfg.room_category == 1 then
            CycleToyBuildingUI:ShowFactoryUI(clickRoomID)
        elseif curRoomCfg.room_category == 2 or curRoomCfg.room_category == 3 then
            CycleToyBuildingUI:ShowSupplyBuildingUI(clickRoomID)
        else
            CycleToySellUI:ShowWharfUI(clickRoomID)
        end
    end
end

---将房间标记为是否缺少材料,开关[原料房间]的传送带
function CycleToyScene:SetRoomEnoughMaterial(roomID, isRunning)
    local room = self:GetRoomByID(roomID)
    if room then
        --目前 原料房间ID = roomID-1
        local preRoom = self:GetRoomByID(roomID-1)
        if preRoom and preRoom.m_transport then
            preRoom.m_transport:SetState(isRunning)
        end

        room:SetIsLackOfMaterial(not isRunning)
        if isRunning then
            room:HideBubble(CycleInstanceDefine.BubbleType.LackOfRawMaterials)
        else
            room:ShowBubble(CycleInstanceDefine.BubbleType.LackOfRawMaterials)
        end
    end
end


function CycleToyScene:ChangeSellingLogo(old, new)
    --TODO 替换新的场景表现 
    if true then
        return
    end
    local partGO = GameObject.Find("Port_1")
    local oldGO = nil
    local newGO = nil
    if old then
        oldGO = self:GetGo(partGO, old)
    end
    if oldGO then
        oldGO:SetActive(false)
    end

    if new then
        newGO = self:GetGo(partGO, new)
    end
    if newGO then
        newGO:SetActive(true)
    end
end

function CycleToyScene:ShowCashierBubble(actor, resID, income)
    if not self.clientFloatUI[actor] then
        self.clientFloatUI[actor] = { ["go"] = actor.gameObject, m_type = "Cashier" }
    end
    
    local startTime = GameTimeManager:GetCurrentServerTimeInMilliSec()
    FloatUI:SetObjectCrossCamera(self.clientFloatUI[actor], function(view)
        if view and self.clientFloatUI[actor] then
            --local now = GameTimeManager:GetCurrentServerTime(true)
            --if self.clientFloatUI[actor].time and math.abs((now - self.clientFloatUI[actor].time) % self.m_instanceModel.config_global.cycle_instance_ship_loadtime) < 10 then
            --end
            local resCfd = self.m_instanceModel.resourceConfig[resID]
            view:Invoke("ShowCycleToyCashierWork", actor, startTime, resCfd, income)
        end
    end, nil, "UIPosition")
    return
end

function CycleToyScene:RemoveCashierBubble(actor)
    if actor and self.clientFloatUI[actor] then
        FloatUI:FreeFloatUIView(self.clientFloatUI[actor])
        self.clientFloatUI[actor] = nil
    end
end

function CycleToyScene:ShowGetMoneyBubble(actor, money)
    if not self.getMoneyFloatUI[actor] then
        self.getMoneyFloatUI[actor] = { ["go"] = actor.gameObject, m_type = "GetMoney" }
    end
    --local now = GameTimeManager:GetCurrentServerTime(true)
    --self.getMoneyFloatUI[actor].time = now
    FloatUI:SetObjectCrossCamera(self.getMoneyFloatUI[actor], function(view)
        if view then
            --local now = GameTimeManager:GetCurrentServerTime(true)
            --if self.getMoneyFloatUI[actor].time and math.abs((now - self.getMoneyFloatUI[actor].time) % self.m_instanceModel.config_global.cycle_instance_ship_loadtime) < 0.1 then
            --end
            view:Invoke("ShowCycleToyGetMoneyBubble", money)
        end
    end, function()
        FloatUI:RemoveObjectCrossCamera(self.getMoneyFloatUI[actor])
    end, "UIPosition")
end


---检查是否需要触发蓝图引导
function CycleToyScene:CheckBlueprintGuide(slotMachineStar)
    --1.是否是3星
    if slotMachineStar ~= 3 then
        return false
    end
    --2.是否触发过引导
    if self.m_instanceModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.Toy.UnlockBluePrint) then
        return false
    end
    --3.开启引导
    GuideManager.currStep = CycleInstanceDefine.GuideDefine.Toy.UnlockBluePrint
    GuideManager:ConditionToStart()
    self.m_instanceModel:SetGuideCompleted(CycleInstanceDefine.GuideDefine.Toy.UnlockBluePrint)
    --GameTableDefine.CycleToyMainViewUI:RefreshBlueprintButton()
    return true
end

return CycleToyScene