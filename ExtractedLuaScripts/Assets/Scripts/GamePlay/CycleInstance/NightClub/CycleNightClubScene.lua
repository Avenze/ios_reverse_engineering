local Class = require("Framework.Lua.Class");
local CycleInstanceSceneBase = require("GamePlay.CycleInstance.CycleInstanceSceneBase")
---@class CycleNightClubScene:CycleInstanceSceneBase
---@field super CycleInstanceSceneBase
local CycleNightClubScene = Class("CycleNightClubScene", CycleInstanceSceneBase)

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
local CycleNightClubUnlockUI = GameTableDefine.CycleNightClubUnlockUI
local CycleNightClubBuildingUI = GameTableDefine.CycleNightClubBuildingUI
local CycleNightClubSellUI = GameTableDefine.CycleNightClubSellUI
local UnlockingSkipUI = GameTableDefine.UnlockingSkipUI
local ActorManager = GameTableDefine.ActorManager
local CycleNightClubAIBlackBoard = GameTableDefine.CycleNightClubAIBlackBoard
local GuideManager = GameTableDefine.GuideManager

local CycleNightClubClient = require("GamePlay.CycleInstance.NightClub.AI.CycleNightClubClient")

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

function CycleNightClubScene:ctor()

    self:getSuper(CycleNightClubScene).ctor(self)

    self.m_instanceModel = nil ---@type CycleNightClubModel

    self.floatUI = {}              ---地标 气泡所需结构
    self.m_slotMachineFloatUI = {} ---拉霸机 气泡结构
    self.getMoneyFloatUI = nil --- 桌子气泡结构
    self.tableGOTable = {}
    self.m_landmarkFeel = nil -- 地标动画
    self.m_portWorkplaceGos = {} --码头的对应位置的go
    self.m_isBuyLandmarkClick = nil ---买地标时来标记不要触发Feedback
    self.m_busPrefab = nil ---@type UnityEngine.GameObject
    self.m_busGOPool = {} ---@type UnityEngine.GameObject[]
    self.m_actorGOPool = {} ---@type table<string,UnityEngine.GameObject[]>
    self.m_npcPoolParent = nil ---@type UnityEngine.Transform
end

function CycleNightClubScene:OnEnter()
    self:getSuper(CycleNightClubScene).OnEnter(self)
    --埋点:进入循环副本
    local isFirstEnter = self.m_instanceModel:GetIsFirstEnter()
    GameSDKs:TrackForeign("cyinstance_enter", {first_time = isFirstEnter and 1 or 0})
    self.m_instanceModel:SetIsFirstEnter()
    local npcPoolGO = GameObject("NPCPool")
    npcPoolGO:SetActive(false)
    self.m_npcPoolParent = npcPoolGO.transform

    self:InitGetMoneyBubble()
end

function CycleNightClubScene:Update(dt)
    self:getSuper(CycleNightClubScene).Update(self)
end

function CycleNightClubScene:OnExit()

    self.m_instanceModel = nil
    self.floatUI = nil
    self.m_slotMachineFloatUI = nil
    self.m_landmarkFeel = nil
    self.m_portWorkplaceGos = nil
    self.m_busPrefab = nil
    self.m_busGOPool = nil
    self.m_actorGOPool = nil
    FloatUI:RemoveObjectCrossCamera(self.getMoneyFloatUI)
    self.getMoneyFloatUI = nil

    if self.m_landmarkAnimEventCallback then
        EventDispatcher:UnRegEvent(GameEventDefine.LandMarkAnimEnd,self.m_landmarkAnimEventCallback)
        self.m_landmarkAnimEventCallback = nil
    end

    self:getSuper(CycleNightClubScene).OnExit(self)
    local allClient = ActorManager:GetActorByType("CycleNightClubClient")
    if allClient and Tools:GetTableSize(allClient) > 0 then
        for i = #allClient, 1, -1 do
            ActorManager:DestroyActor(allClient[i].instanceID)
        end  
    end
    local allChild = ActorManager:GetActorByType("CycleNightClubChild")
    if allChild and Tools:GetTableSize(allChild) > 0 then
        for i = #allChild, 1, -1 do
            ActorManager:DestroyActor(allChild[i].instanceID)
        end
    end

    CycleNightClubAIBlackBoard:OnExit()
    --退出场景时回收场景中的气泡
    --for k,v in pairs(self.tableFloatUI) do
    --    FloatUI:RemoveObjectCrossCamera(v)
    --end
    
end

function CycleNightClubScene:InitScene(model)
    self:getSuper(CycleNightClubScene).InitScene(self, model)
    self:InitAIBlackBoardData()

    Landmark = GameObject.Find("Landmark")
    SlotBuilding = GameObject.Find("Laba")
    self.m_busPrefab = UnityHelper.FindRootGameObject("taxiAnimation_cy4")

    self:InitSpecialGameObject()
    self.m_instanceModel:PreloadChild()
end

function CycleNightClubScene:InitRooms()
    self:getSuper(CycleNightClubScene).InitRooms(self)
    --TODO 新港口
end

function CycleNightClubScene:InitAIBlackBoardData()
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
    outPos = {
        [1] = outPos1,
        [2] = outPos2,
    }
    
    -- 大门
    local gateData = nil
    local outGate = GameObject.Find("Customer_pos/Queue/GatePos_Out")
    local queueStart = GameObject.Find("Customer_pos/Queue/QueueStart")
    local queuePoint = GameObject.Find("Customer_pos/Queue/QueuePoint")
    local payPos = GameObject.Find("Customer_pos/Pay/PayPos")
    gateData = {
        outPos = outGate,
        queueStart = queueStart,
        queuePoint = queuePoint,
        payPos = payPos,
    }

    -- PlayPos
    local playData = {}
    local playRoot = GameObject.Find("Customer_pos/Play")
    for k, v in pairs(playRoot.transform) do
        local groupTrans = playRoot.transform
        if v ~= groupTrans then
            playData[v.name] = playData[v.name] or {}
            for i = 1, v.childCount do
                local pos = v:GetChild(i - 1)
                local rot = pos:GetChild(0)
                playData[v.name][i] = {
                    positionGO = pos,
                    rotationGO = rot
                }
            end
        end
    end
    
    CycleNightClubAIBlackBoard:Init(self.m_instanceModel, inPos, outPos, gateData, playData)
end

---override 播放完开场TimeLine后触发
function CycleNightClubScene:OnOpeningTimeLineOver()
    GameTableDefine.CycleNightClubOfflineRewardUI:GetView()
    local guideID = self.m_instanceModel:GetGuideID()
    if not guideID then
        GuideManager.currStep = CycleInstanceDefine.GuideDefine.NightClub.Opening -- instanceBind.guideID
        GuideManager:ConditionToStart()
    else
        GameTableDefine.CycleNightClubPopUI:PackTrigger(4)
    end
end

---获取房间对象
---@overload
---@return CycleNightClubRoom
function CycleNightClubScene:GetRoomByID(roomID)
    return self.Rooms[roomID]
end

function CycleNightClubScene:InitSpecialGameObject()
    self:ShowSpecialGameObject(not self.m_instanceModel:GetLandMarkCanPurchas())

    --绑定场景特殊物品点击事件
    local specialGOBox = GameObject.Find("Miscellaneous/Environment/Landmark/roombox")
    self.floatUI.Landmark = { ["go"] = Landmark ,m_type = "Landmark"}
    FloatUI:SetObjectCrossCamera(self.floatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowCycleNightClubSpacialGOPop", false)
            --没买的提示
            if self.m_instanceModel:GetLandMarkCanPurchas() then
                view:Invoke("ShowCycleNightClubSpacialGOBuyTipPop", true)
            end
        end
    end, nil, "roombox")

    self.m_landmarkAnimator = self:GetComp(Landmark,"bought/SF_Prop_OptimusPrime","Animator")

    self:SetButtonClickHandler(specialGOBox, function()
        if not self.m_instanceModel:GetLandMarkCanPurchas() then --买了1.5
            if not spacialGOPopIsShow then
                if self.floatUI.Landmark.view then
                    self.floatUI.Landmark.view:ShowCycleNightClubSpacialGOPop(true)
                end

                spacialGOPopIsShow = true

                GameTimer:CreateNewTimer(3, function()
                    spacialGOPopIsShow = false
                    if self.floatUI.Landmark.view then
                        self.floatUI.Landmark.view:ShowCycleNightClubSpacialGOPop(false)
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
            if self.m_instanceModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.NightClub.UnlockMilestone) then
                GameTableDefine.CycleNightClubShopUI:OpenBuyLandmark()
            end
        end
    end)

    local slotRoomBox = GameObject.Find("Miscellaneous/Environment/Laba/roombox")
    self:SetButtonClickHandler(slotRoomBox, function()
        if self.m_instanceModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.NightClub.UnlockMilestone) then
            GameTableDefine.CycleNightClubSlotMachineUI:OpenView()
            -- GameSDKs:TrackForeign("button_event", { slot_bld = 1})
        end
    end)

    self.m_slotMachineFloatUI.Landmark = { ["go"] = SlotBuilding ,m_type = "SlotBuilding"}
    FloatUI:SetObjectCrossCamera(self.m_slotMachineFloatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowCycleNightClubSlotBuildingBubble")
        end
    end, nil, "roombox")

    --播放 小孩欢呼的动画
    --local childAnimators = {}
    --local animatorRootTrans = self:GetTrans(Landmark,"bought/kid")
    --local childCount = animatorRootTrans.childCount
    --for i = 1, childCount do
    --    local childAnimGO = animatorRootTrans:GetChild(i-1).gameObject
    --    local animator = self:GetComp(childAnimGO,"","Animator")
    --    if animator then
    --        childAnimators[#childAnimators+1] = animator
    --    end
    --end

    --local animatorCount = #childAnimators
    --
    --self.m_landmarkAnimEventCallback = function()
    --    for i = 1, animatorCount do
    --        GameTimer:CreateNewTimer(0.1 * math.random(0,5),function()
    --            if not childAnimators[i]:IsNull() then
    --                childAnimators[i]:Play(ChildAnimList[math.random(1,3)])
    --            end
    --        end)
    --    end
    --end

    --EventDispatcher:RegEvent(GameEventDefine.LandMarkAnimEnd,self.m_landmarkAnimEventCallback)
end

---检查是否需要新增员工
function CycleNightClubScene:CreateWorkers(furnitureGo, roomGo, furIndex, isBuy, roomID,personList)

end

local ActorPath = "GamePlay.CycleInstance.NightClub.AI."

--function CycleNightClubScene:CreateClients(roomID, level, tableIndex)
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

function CycleNightClubScene:CreateClient(actorID, isPreload)
    local actorCfg = ConfigMgr.config_character[tonumber(actorID)]
    if not actorCfg then
        printError("找不到对应的config_character,id = "..tonumber(actorID))
        return nil
    end
    local pfbName = actorCfg.prefab

    local client = ActorManager:CreateActorSync(CycleNightClubClient) ---@type CycleNightClubClient

    local actorData = client.m_data or {isPreload = isPreload, prefabName = pfbName}
    local actorGO = self:GetActorFromPool(pfbName)
    if actorGO then
        UnityHelper.AddChildToParent(self.m_personRoot.transform, actorGO.transform)
        client:Init(client.instanceID, actorGO, actorData)
    else
        local prefabPath = "Assets/Res/Prefabs/character/Instance/nightClub/" .. pfbName .. ".prefab"
        GameResMgr:AInstantiateObjectAsyncManual(prefabPath, client, function(go)
            UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
            client:Init(client.instanceID, go, actorData)
        end)
    end
    return client
end

--function CycleNightClubScene:CreateChild(actorID)
--    local actorType = "CycleNightClubChild"
--    local data = {
--        buildID = "instance", --所属建筑ID,这里把副本场景也看成一个building
--        roomID = "DinningRoom", --所属房间ID
--        furnitureID = "table", --所属家具ID
--        furnitureIndex = 1 --所属家具位置索引
--    }
--    local pfbName = ConfigMgr.config_character[tonumber(actorID)].prefab
--    local prefabPath = "Assets/Res/Prefabs/character/Instance/V04/" .. pfbName .. ".prefab"
--    local actorPath = "GamePlay.CycleInstance.NightClub.AI."
--
--    local client = ActorManager:CreateActorSync(actorType, data, actorPath) ---@type CycleNightClubClient
--
--    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, client, function(go)
--        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
--        client:Init(client.instanceID, go, {})
--    end)
--
--    return client
--end

function CycleNightClubScene:ShowSpecialGameObject(active)  
    if active then
        self:GetGo(Landmark, "bought"):SetActive(true)
        self:GetGo(Landmark, "broken"):SetActive(false)
    else
        self:GetGo(Landmark, "bought"):SetActive(false)
        self:GetGo(Landmark, "broken"):SetActive(true)
    end
end

function CycleNightClubScene:BuySpecialGameObjectAnimationPlay()
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
function CycleNightClubScene:OnRoomBeClicked(clickRoomID)
    local curRoomData = self.roomsData[clickRoomID]
    local curRoomCfg = self.roomsConfig[clickRoomID]
    if curRoomData.state == 0 then
        --未解锁,点击显示解锁界面
        CycleNightClubUnlockUI:ShowUI(clickRoomID)
    elseif curRoomData.state == 1 then
        --在解锁中,是否花钻石快速完成
        local room = self:GetRoomByID(clickRoomID)
        local timePoint = curRoomData.buildTimePoint
        local timeWait = timePoint + curRoomCfg.unlock_times
        UnlockingSkipUI:ShowCycleIslandBuildingSkipUI(curRoomCfg, timeWait,room.m_floatUIHandler)
    elseif curRoomData.state == 2 then
        --已解锁,点击显示RoomUI
        if curRoomCfg.room_category == 1 then
            CycleNightClubBuildingUI:ShowFactoryUI(clickRoomID)
        elseif curRoomCfg.room_category == 2 or curRoomCfg.room_category == 3 then
            CycleNightClubBuildingUI:ShowSupplyBuildingUI(clickRoomID)
        else
            CycleNightClubSellUI:ShowWharfUI(clickRoomID)
        end
    end
end

---将房间标记为是否缺少材料,开关[原料房间]的传送带
function CycleNightClubScene:SetRoomEnoughMaterial(roomID, isRunning)
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


function CycleNightClubScene:ChangeSellingLogo(old, new)
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

function CycleNightClubScene:InitGetMoneyBubble()
    self.getMoneyFloatUI = {}
    local cashier = GameObject.Find("Miscellaneous/SF_Char_bodyguard_1")
    self.getMoneyFloatUI = { ["go"] = cashier.gameObject, m_type = "GetMoney" }
    FloatUI:SetObjectCrossCamera(self.getMoneyFloatUI,function()

    end)
end

function CycleNightClubScene:ShowGetMoneyBubble(money)
    if self.getMoneyFloatUI.view then
        self.getMoneyFloatUI.view:Invoke("ShowCycleNightClubGetMoneyBubble",money)
    end
end

---检查是否需要触发蓝图引导
function CycleNightClubScene:CheckBlueprintGuide(slotMachineStar)
    --1.是否是3星
    if slotMachineStar ~= 3 then
        return false
    end
    --2.是否触发过引导
    if self.m_instanceModel:IsGuideCompleted(CycleInstanceDefine.GuideDefine.NightClub.UnlockBluePrint) then
        return false
    end
    --3.开启引导
    GuideManager.currStep = CycleInstanceDefine.GuideDefine.NightClub.UnlockBluePrint
    GuideManager:ConditionToStart()
    self.m_instanceModel:SetGuideCompleted(CycleInstanceDefine.GuideDefine.NightClub.UnlockBluePrint)
    GameTableDefine.CycleNightClubMainViewUI:RefreshBlueprintButton()
    return true
end

function CycleNightClubScene:GetBusGOFromPool()
    local busCount = #self.m_busGOPool
    local busGO
    if busCount>0 then
        busGO = self.m_busGOPool[busCount]
        self.m_busGOPool[busCount] = nil
    else
        busGO = GameObject.Instantiate(self.m_busPrefab)
    end

    --随机一辆车
    local busIndex = math.random(1,5)
    local busChildParent = busGO.transform:Find("car")
    local childCount = busChildParent.childCount
    for i = 1, childCount do
        busChildParent:GetChild(i-1).gameObject:SetActive(i == busIndex)
    end

    busGO:SetActive(true)

    return busGO
end

function CycleNightClubScene:RecycleBusGOToPool(busGO)
    if self.m_busGOPool then
        table.insert(self.m_busGOPool,busGO)
        busGO:SetActive(false)
    end
end

---@param actorGO UnityEngine.GameObject
function CycleNightClubScene:RecycleActorGOToPool(actorGO,name)
    if self.m_actorGOPool then
        local actorArray = self.m_actorGOPool[name]
        if not actorArray then
            actorArray = {}
            self.m_actorGOPool[name] = actorArray
        end
        table.insert(actorArray,actorGO)
        UnityHelper.AddChildToParent(self.m_npcPoolParent,actorGO.transform)
    end
end

---@return UnityEngine.GameObject
function CycleNightClubScene:GetActorFromPool(name)
    if self.m_actorGOPool then
        local actorArray = self.m_actorGOPool[name]
        if actorArray then
            local count = #actorArray
            if count>0 then
                local actorGO = table.remove(actorArray,count)
                actorGO.name = name
                return actorGO
            end
        end
    end
    return nil
end

return CycleNightClubScene