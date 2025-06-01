local Class = require("Framework.Lua.Class");
local CycleInstanceSceneBase = require("GamePlay.CycleInstance.CycleInstanceSceneBase")
---@class CycleCastleScene:CycleInstanceSceneBase
---@field super CycleInstanceSceneBase
local CycleCastleScene = Class("CycleCastleScene", CycleInstanceSceneBase)

local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")

local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject

local ConfigMgr = GameTableDefine.ConfigMgr
local FloatUI = GameTableDefine.FloatUI
local GameUIManager = GameTableDefine.GameUIManager
local CycleCastleUnlockUI = GameTableDefine.CycleCastleUnlockUI
local CycleCastleBuildingUI = GameTableDefine.CycleCastleBuildingUI
local CycleCastleSellUI = GameTableDefine.CycleCastleSellUI
local UnlockingSkipUI = GameTableDefine.UnlockingSkipUI
local ActorManager = GameTableDefine.ActorManager
local CycleCastleAIBlackBoard = GameTableDefine.CycleCastleAIBlackBoard

local Landmark ---场景特殊物品
local SlotBuilding ---拉霸机建筑
local spacialGOPopIsShow = false    ---正在显示特殊物品点击气泡
local clientNavRoot = nil ---客户寻路根节点
local dinningRoom = nil ---餐厅房间根节点   

function CycleCastleScene:ctor()

    self:getSuper(CycleCastleScene).ctor(self)

    self.m_instanceModel = nil ---@type CycleCastleModel

    self.floatUI = {}              ---地标 气泡所需结构
    self.m_slotMachineFloatUI = {} ---拉霸机 气泡结构
    self.tableFloatUI = nil --- 桌子气泡结构
    self.clientFloatUI = nil --- 顾客气泡结构
    self.tableGOTable = {}
    self.m_landmarkFeel = nil -- 地标动画
    self.m_portWorkplaceGos = {} --码头的对应位置的go
end

function CycleCastleScene:OnEnter()
    self:getSuper(CycleCastleScene).OnEnter(self)
    self.tableFloatUI = {}
    self.clientFloatUI = {}
    --埋点:进入循环副本
    local isFirstEnter = self.m_instanceModel:GetIsFirstEnter()
    GameSDKs:TrackForeign("cyinstance_enter", {first_time = isFirstEnter and 1 or 0})
    self.m_instanceModel:SetIsFirstEnter()

    local dinningRoom = GameObject.Find("DinningRoom_1")
    self.tableGOTable = {}
    for i = 1, 8 do
        local tableGO = self:GetGo(dinningRoom, "table_" .. i)
        self.tableGOTable[i] = {
            tableRoot = tableGO,
            UIPosition = self:GetGo(tableGO, "UIPosition"),
            GO = self:GetGo(tableGO, "SF_Props_Hall_board_01")
        }
    end

    local curSelling = self.m_instanceModel:GetCurSellingProduct()
    local sellingResCfg = self.m_instanceModel.resourceConfig[curSelling]
    CycleCastleScene:ChangeSellingLogo(nil, sellingResCfg.prefab)
    
end

function CycleCastleScene:Update(dt)
    self:getSuper(CycleCastleScene).Update(self)
end

function CycleCastleScene:OnExit()

    self.m_instanceModel = nil
    self.floatUI = nil
    self.m_slotMachineFloatUI = nil
    self.m_landmarkFeel = nil
    self.m_portWorkplaceGos = nil

    self:getSuper(CycleCastleScene).OnExit(self)
    --退出场景时回收场景中的气泡
    --for k,v in pairs(self.tableFloatUI) do
    --    FloatUI:RemoveObjectCrossCamera(v)
    --end
    --for k,v in pairs(self.clientFloatUI) do
    --    FloatUI:RemoveObjectCrossCamera(v)
    --end
    
end

function CycleCastleScene:InitScene(model)
    self:getSuper(CycleCastleScene).InitScene(self,model)
    
    clientNavRoot = GameObject.Find("Customer_pos")
    dinningRoom = GameObject.Find("DinningRoom_1")
    CycleCastleAIBlackBoard:Init(clientNavRoot, dinningRoom)

    Landmark = GameObject.Find("Landmark")
    SlotBuilding = GameObject.Find("Laba")

    self:InitSpecialGameObject()
end

function CycleCastleScene:InitRooms()
    self:getSuper(CycleCastleScene).InitRooms(self)
    --TODO 新港口
end

---override 播放完开场TimeLine后触发
function CycleCastleScene:OnOpeningTimeLineOver()
    GameTableDefine.CycleCastleOfflineRewardUI:GetView()
    local guideID = self.m_instanceModel:GetGuideID()
    if not guideID then
        GameTableDefine.GuideManager.currStep = 14001 -- instanceBind.guideID
        GameTableDefine.GuideManager:ConditionToStart()
    else
        GameTableDefine.CycleCastlePopUI:PackTrigger(4)
    end
end

---获取房间对象
---@overload
---@return CycleCastleRoom
function CycleInstanceSceneBase:GetRoomByID(roomID)
    return self.Rooms[roomID]
end

function CycleCastleScene:InitSpecialGameObject()
    self:ShowSpecialGameObject(not self.m_instanceModel:GetLandMarkCanPurchas())

    --绑定场景特殊物品点击事件
    local specialGOBox = GameObject.Find("Miscellaneous/Environment/Landmark/roombox")
    self.floatUI.Landmark = { ["go"] = Landmark ,m_type = "Landmark"}
    FloatUI:SetObjectCrossCamera(self.floatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowCycleCastleSpacialGOPop", false)
            --没买的提示
            if self.m_instanceModel:GetLandMarkCanPurchas() then
                view:Invoke("ShowCycleCastleSpacialGOBuyTipPop", true)
            end
        end
    end, nil, "roombox")

    self:SetButtonClickHandler(specialGOBox, function()
        if not self.m_instanceModel:GetLandMarkCanPurchas() then --买了1.5
            if not spacialGOPopIsShow then
                if self.floatUI.Landmark.view then
                    self.floatUI.Landmark.view:ShowCycleCastleSpacialGOPop(true)
                end

                spacialGOPopIsShow = true

                GameTimer:CreateNewTimer(3, function()
                    spacialGOPopIsShow = false
                    if self.floatUI.Landmark.view then
                        self.floatUI.Landmark.view:ShowCycleCastleSpacialGOPop(false)
                    end
                    --FloatUI:DestroyFloatUIView(self.floatUI.Landmark.guid)
                end)
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
            if self.m_instanceModel:IsGuideCompleted(14020) then
                GameTableDefine.CycleCastleShopUI:OpenBuyLandmark()
            end
        end
    end)

    local slotRoomBox = GameObject.Find("Miscellaneous/Environment/Laba/roombox")
    self:SetButtonClickHandler(slotRoomBox, function()
        if self.m_instanceModel:IsGuideCompleted(14020) then
            GameTableDefine.CycleCastleSlotMachineUI:OpenView()
        end
    end)

    self.m_slotMachineFloatUI.Landmark = { ["go"] = SlotBuilding ,m_type = "SlotBuilding"}
    FloatUI:SetObjectCrossCamera(self.m_slotMachineFloatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowCycleCastleSlotBuildingBubble")
        end
    end, nil, "roombox")
end

---检查是否需要新增员工
function CycleCastleScene:CreateWorkers(furnitureGo, roomGo, furIndex, isBuy, roomID,personList)
    self:getSuper(CycleCastleScene).CreateWorkers(self,furnitureGo, roomGo, furIndex, isBuy, roomID,personList)
end


local ActorPath = "GamePlay.CycleInstance.Castle.AI."

---override 创建Actor
function CycleCastleScene:NewCreateWorker(furnitureGo, roomGo, index, isBuy, roomId)

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

    local worker = ActorManager:CreateActorSync("CycleCastleWorker", data, ActorPath)  ---@type CycleCastleWorker
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, worker, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        worker:Init(worker.instanceID,go,{
            roomID = roomId,
            furIndex = index,
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

function CycleCastleScene:CreateClients(roomID, level, tableIndex)
    local roomLevelCfg = self.m_instanceModel:GetRoomLevelConfig(roomID, level)
    local clientCount = math.random(roomLevelCfg.roll_num[1], roomLevelCfg.roll_num[2])
    local clientList = {}
    for i = 1, clientCount do
        local curCount = math.random(1, #roomLevelCfg.character_id)
        clientList[#clientList + 1] = roomLevelCfg.character_id[curCount]
    end

    local actorID = clientList[1]
    local leader = nil
    --生成带头大哥
    leader = self:CreateClient(actorID, tableIndex, nil, nil, function(client, go)
        if clientCount > 1 then
            local posNum = clientCount - 1
            local followPosTrans = self:GetTrans(go, "Follow_pos")
            local childsCount = followPosTrans.childCount
            local childs = {}
            for i = 1, childsCount do
                childs[#childs + 1] = followPosTrans:GetChild(i - 1)
            end
            Tools:ShuffleArray(childs)
            for i = 1, posNum do
                --生成跟随小弟
                actorID = clientList[i + 1]
                local curFollowPos = childs[i].transform
                self:CreateClient(actorID, tableIndex, client, curFollowPos)
            end
        end
    end)
    
end

function CycleCastleScene:CreateClient(actorID, tableIndex, leader, followTrans, cb)
    local actorType = "CycleCastleClient"
    local data = {
        buildID = "instance", --所属建筑ID,这里把副本场景也看成一个building
        roomID = "DinningRoom", --所属房间ID
        furnitureID = "table", --所属家具ID
        furnitureIndex = 1 --所属家具位置索引
    }
    local pfbName = ConfigMgr.config_character[tonumber(actorID)].prefab
    local prefabPath = "Assets/Res/Prefabs/character/Instance/V03/" .. pfbName .. ".prefab"
    local actorPath = "GamePlay.CycleInstance.Castle.AI."

    local client = ActorManager:CreateActorSync(actorType, data, actorPath) ---@type CycleCastleClient
    
    -- TODO 角色用对象池控制
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, client, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        client:Init(client.instanceID, go, {
            tableIndex = tableIndex,
            leader = leader,
            followTrans = followTrans,
        })
        local seatGo = nil
        if not leader then  --如果是leader
            seatGo = CycleCastleAIBlackBoard:OccupySeat(client, client)
        else
            seatGo = CycleCastleAIBlackBoard:OccupySeat(leader, client)
            if not leader.data.followers then
                leader.data.followers = {}
            end
            table.insert(leader.data.followers, client)
        end
        client.data.seatGo = seatGo
        
        if cb then
            cb(client, go)
        end
    end)

    return client
end


function CycleCastleScene:ShowSpecialGameObject(active)
    if active then
        self:GetGo(Landmark, "bought"):SetActive(true)
        self:GetGo(Landmark, "broken"):SetActive(false)
    else
        self:GetGo(Landmark, "bought"):SetActive(false)
        self:GetGo(Landmark, "broken"):SetActive(true)
    end
end

function CycleCastleScene:BuySpecialGameObjectAnimationPlay()
    --设置当前摄像机到对应的节点
    if Landmark then
        self:LocatePosition(Landmark.transform.position, false, function()   
            EventManager:RegEvent("CY1_LANDMARK_TIMELINE_END", function(go)
                self:ShowSpecialGameObject(true)
                EventManager:UnregEvent("CY1_LANDMARK_TIMELINE_END")
                GameUIManager:SetEnableTouch(true)
            end)
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
function CycleCastleScene:OnRoomBeClicked(clickRoomID)
    local curRoomData = self.roomsData[clickRoomID]
    local curRoomCfg = self.roomsConfig[clickRoomID]
    if curRoomData.state == 0 then
        --未解锁,点击显示解锁界面
        CycleCastleUnlockUI:ShowUI(clickRoomID)
    elseif curRoomData.state == 1 then
        --在解锁中,是否花钻石快速完成
        local room = self:GetRoomByID(clickRoomID)
        local timePoint = curRoomData.buildTimePoint
        local timeWait = timePoint + curRoomCfg.unlock_times
        UnlockingSkipUI:ShowCycleIslandBuildingSkipUI(curRoomCfg, timeWait,room.m_floatUIHandler)
    elseif curRoomData.state == 2 then
        --已解锁,点击显示RoomUI
        if curRoomCfg.room_category == 1 then
            CycleCastleBuildingUI:ShowFactoryUI(clickRoomID)
        elseif curRoomCfg.room_category == 2 or curRoomCfg.room_category == 3 then
            CycleCastleBuildingUI:ShowSupplyBuildingUI(clickRoomID)
        else
            CycleCastleSellUI:ShowWharfUI(clickRoomID)
        end
    end
end

---将房间标记为是否缺少材料,开关[原料房间]的传送带
function CycleCastleScene:SetRoomEnoughMaterial(roomID, isRunning)
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

function CycleCastleScene:ShowGetMoneyBubble(index, money)
    local table = self.tableGOTable[index]
    if not self.tableFloatUI[table] then
        self.tableFloatUI[table] = { ["go"] = table.tableRoot, m_type = "Table" }
    end
    local now = GameTimeManager:GetCurrentServerTime(true)
    self.tableFloatUI[table].time = now
    FloatUI:SetObjectCrossCamera(self.tableFloatUI[table], function(view)
        if view then
            local now = GameTimeManager:GetCurrentServerTime(true)
            if self.tableFloatUI[table].time and math.abs((now - self.tableFloatUI[table].time) % self.m_instanceModel.config_global.cycle_instance_ship_loadtime) < 0.1 then
                view:Invoke("ShowCycleCastleGetMoneyBubble", money)
            end
        end
    end, nil, "UIPosition")
end

function CycleCastleScene:ShowEatingBubble(actor)
    local income, roomID, bestResID = self.m_instanceModel:GetCurHighestProfit()
    local resID = self.m_instanceModel:GetCurSellingProduct()
    if not self.clientFloatUI[actor] then
        self.clientFloatUI[actor] = { ["go"] = actor.gameObject, m_type = "Client" }
    end
    local now = GameTimeManager:GetCurrentServerTime(true)
    self.clientFloatUI[actor].time = now
    if resID ~= bestResID then
        FloatUI:SetObjectCrossCamera(self.clientFloatUI[actor], function(view)
            if view and self.clientFloatUI[actor] then
                local now = GameTimeManager:GetCurrentServerTime(true)
                if self.clientFloatUI[actor].time and math.abs((now - self.clientFloatUI[actor].time) % self.m_instanceModel.config_global.cycle_instance_ship_loadtime) < 10 then
                    local resCfd = self.m_instanceModel.resourceConfig[bestResID]
                    view:Invoke("ShowCycleCastleEatingNeedBubble", resCfd)
                end
            end
        end, nil, "UIPosition")
        return
    end
    
    FloatUI:SetObjectCrossCamera(self.clientFloatUI[actor], function(view)
        if view and self.clientFloatUI[actor] then
            local now = GameTimeManager:GetCurrentServerTime(true)
            if self.clientFloatUI[actor].time and math.abs((now - self.clientFloatUI[actor].time) % self.m_instanceModel.config_global.cycle_instance_ship_loadtime) < 10 then
                view:Invoke("ShowCycleCastleEatingHappyBubble")
            end
        end
    end, nil, "UIPosition")
    
end

function CycleCastleScene:RemoveEatingBubble(actor)
    if actor and self.clientFloatUI[actor] then
        FloatUI:FreeFloatUIView(self.clientFloatUI[actor])
        self.clientFloatUI[actor] = nil
    end
end

function CycleCastleScene:ChangeSellingLogo(old, new)
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


return CycleCastleScene