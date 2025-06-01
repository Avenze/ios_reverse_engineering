local Class = require("Framework.Lua.Class");
local BaseScene = require("Framework.Scene.BaseScene")
---@class CycleInstanceScene:BaseScene
local CycleInstanceScene = Class("CycleInstanceScene", BaseScene)

local EventManager = require("Framework.Event.Manager")
local ActorDefine = require "CodeRefactoring.Actor.ActorDefine"
local EventInstance = require("CodeRefactoring.Actor.Actors.EventInstanceNew")
local InteractionsManager = require "CodeRefactoring.Interactions.InteractionsManager"
local GameResMgr = require("GameUtils.GameResManager")
local instanceRoom =  require("GamePlay/CycleInstance/Island/CycleInstanceRoom")

local ConfigMgr = GameTableDefine.ConfigMgr
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local Transform = CS.UnityEngine.Transform
local MeshRenderer = CS.UnityEngine.MeshRenderer

local CycleIslandBuildingUI = GameTableDefine.CycleIslandBuildingUI
local CycleIslandSellUI = GameTableDefine.CycleIslandSellUI
local CycleIslandUnlockUI = GameTableDefine.CycleIslandUnlockUI
local FloatUI = GameTableDefine.FloatUI
local TimerMgr = GameTimeManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local LightManager = GameTableDefine.LightManager
local SoundEngine = GameTableDefine.SoundEngine
local GuideManager = GameTableDefine.GuideManager
local GameUIManager = GameTableDefine.GameUIManager

local Landmark --场景特殊物品
local SlotBuilding --拉霸机建筑
local selectFurniture   --被选中的家具
local lastSelectIsPrebuy   --上个被选择的家具是将要买的
local spacialGOPopIsShow = false    --正在显示特殊物品点击气泡
local preBuyMatPath = "Assets/Res/Materials/FX_Materials/PreBuy.mat"

local glintingInterval = 100 -- 家具闪烁变化间隔(ms)
local maxFlash = 0.5 -- 材质flash参数最大值
local deltaV = 0.1 -- 材质参数变化速度


---声明所有变量
function CycleInstanceScene:DeclareVariable()
    self.m_instanceModel = CycleInstanceDataManager:GetCurrentModel() ---@type CycleInstanceModel
    self.roomsConfig = self.m_instanceModel.roomsConfig    --房间配置数据
    self.roomsData = self.m_instanceModel.roomsData   --所有房间存档数据
    self.personList = {}  ---@type table<number,CycleInstanceWorkerClass[]>  --所有员工实例列表
    self.Rooms = {}  ---@type CycleInstanceRoom[] --房间表
    self.m_personRoot = GameObject.Find("NPC").gameObject   --NPC根节点
    self.floatUI = {}   --气泡所需结构
    self.m_nightGos = nil
    self.m_dayGos = nil
    self.m_landmarkFeel = nil -- 地标动画
    self.m_glinting = {} -- 家具闪烁数据
    self.m_portWorkplaceGos = {} --码头的对应位置的go
end

function CycleInstanceScene:OnEnter()
    self.super:OnEnter()
    self:PlayBGM()
    self:InitEventActor()
    
    --埋点:进入循环副本
    local isFirstEnter = self.m_instanceModel:GetIsFirstEnter()
    GameSDKs:TrackForeign("cyinstance_enter", {first_time = isFirstEnter and 1 or 0})
    self.m_instanceModel:SetIsFirstEnter()
    
end

function CycleInstanceScene:OnResume()
end


function CycleInstanceScene:Update(dt)
    self.super:OnUpdate(self)
    local timeType = self.m_instanceModel.timeType
    if self.currTime ~= timeType then
        self.currTime = timeType

        local eatingEntities = InteractionsManager:GetEntities(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_EATING)
        if eatingEntities then
            for k, v in pairs(eatingEntities) do
                v.m_personQueue = {}
            end
        end
        local sleepingEntities = InteractionsManager:GetEntities(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_SLEEPING)
        if sleepingEntities then
            for k, v in pairs(sleepingEntities) do
                v.m_personQueue = {}
            end
        end
    end
    self:RefreshLight()
end

function CycleInstanceScene:OnPouse()
end

function CycleInstanceScene:OnExit()
    self.eventInstance:Destroy()
    self:UnloadWorker()
    self:StopBGM()
    self.m_nightGos = nil
    self.m_dayGos = nil
    selectFurniture = nil
end

function CycleInstanceScene:InitScene()
    Landmark = GameObject.Find("Landmark")
    SlotBuilding = GameObject.Find("Laba")
    GameTableDefine.InstanceAIBlackBoard:ClearSeat()

    self:DeclareVariable()
    self:InitSceneLight()
    self:InitSceneVFX()
    self:InitRooms()
    self:InitSpecialGameObject()
    self:InitWheel()

    --引导
    local guideID = self.m_instanceModel:GetGuideID()
    if not guideID then
        local instanceBind = CycleInstanceDataManager:GetInstanceBind()
        GuideManager.currStep = 13001 -- instanceBind.guideID
        GuideManager:ConditionToStart()
    end
end

function CycleInstanceScene:InitRooms()
    local Environment = GameObject.Find("Environment")
    local clickArg = {} --点击房间对应的参数表

    for k, v in pairs(self.roomsConfig) do
        local newRoom = instanceRoom:new()
        local roomGO = self:GetGo(Environment, v.object_name)
        local roomData = self.roomsData[v.id]
        self.Rooms[v.id] = newRoom
        newRoom:Init(v.room_category, roomData, v, roomGO, function(GO, roomID, index, isBuy)
            if not self.Rooms[v.id].existence then
                GameTimer:CreateNewTimer(1, function()
                    self:InitInteractionRoomData(v.id)
                end)
            else
                if self.Rooms[v.id].reTimer then
                    GameTimer:StopTimer(self.Rooms[v.id].reTimer)
                    self.Rooms[v.id].reTimer = nil
                end
                self.Rooms[v.id].reTimer = GameTimer:CreateNewTimer(1, function()
                    self.Rooms[v.id].reTimer = nil
                    self:RefreshInteractionRoomData(v.id)
                end)
            end
            self.Rooms[v.id].existence = true
            --index应该始终等于1
            local levelID = roomData.furList[tostring(index)].id
            if newRoom.furLevelConfig[levelID].isPresonFurniture then
                --是工人家具
                if not self.personList[roomID] then
                    self.personList[roomID] = {}
                end
                if not self.personList[roomID][index] then
                    self.personList[roomID][index] = {}
                end
                self:CreateWorkers(GO, roomGO,index, isBuy, v.id,self.personList[roomID][index])
            else
                --不是工人家具
                if newRoom.furLevelConfig[levelID].shipCD > 0 then   -- 船
                    local trans = GO:GetComponentsInChildren(typeof(Transform))
                    for i=0,trans.Length-1 do
                        if trans[i].gameObject.tag == "TAG_DAY_OBJ" then
                            self.m_dayGos[#self.m_dayGos + 1] = trans[i].gameObject
                        elseif trans[i].gameObject.tag == "TAG_NIGHT_OBJ" then
                            self.m_nightGos[#self.m_dayGos + 1] = trans[i].gameObject
                        end
                    end
                end
            end
        end)
        newRoom:OnEnter()
        --绑定房间点击事件
        local roomBox = self:GetGo(Environment, v.object_name .. "/roombox")
        local tempArg = { [1] = v.id, [2] = roomBox }
        table.insert(clickArg, tempArg)
        self:SetButtonClickHandler(roomBox, function()
            local arg = nil
            for k, v in pairs(clickArg) do
                if v[2] == roomBox then
                    arg = v
                    break
                end
            end
            local curRoomData = self.roomsData[arg[1]]
            local curRoomCfg = self.roomsConfig[arg[1]]
            if curRoomData.state == 0 then
                --未解锁,点击显示解锁界面
                CycleIslandUnlockUI:ShowUI(arg[1])
            elseif curRoomData.state == 1 then
                --在解锁中,显示悬浮进度

            elseif curRoomData.state == 2 then
                --已解锁,点击显示RoomUI
                if curRoomCfg.room_category == 1 then
                    CycleIslandBuildingUI:ShowFactoryUI(arg[1])
                elseif curRoomCfg.room_category == 2 or curRoomCfg.room_category == 3 then
                    CycleIslandBuildingUI:ShowSupplyBuildingUI(arg[1])
                else
                    CycleIslandSellUI:ShowWharfUI(arg[1])
                end
            end
        end)
        self:RefreshRoom(v.id)
    end

    --2024-7-11 fy添加，获取到港口的工作go
    self.m_portWorkplaceGos = {}
    --找到当前开启的售卖index
    local curSellingIndex = self.m_instanceModel:GetSellingIndex()
    for i = 1, 6 do
        -- Port_1/furniture/Port2_workspace_1/Port2_workspace_1
        local tmpStr = "Port_1/furniture/Port"..i.."_workspace_1/".."Port"..i.."_workspace_1"
        local portGo = GameObject.Find(tmpStr)
        if portGo then
            table.insert(self.m_portWorkplaceGos, portGo)
            local animator = portGo:GetComponent("Animator")
            if animator then
                animator:SetInteger("state", 2)
            end
            --初始化都关闭状态，然后找到对应的售卖的index进行港口开启
        end
    end
    local isHigh = false
    if curSellingIndex > 6 then
        curSellingIndex = curSellingIndex - 6 
        isHigh = true
    end
    if self.m_portWorkplaceGos[curSellingIndex] then
        local animator = self.m_portWorkplaceGos[curSellingIndex]:GetComponent("Animator")
        if animator then
            if isHigh then
                animator:SetInteger("state", 3)
            else
                animator:SetInteger("state", 1)
            end
        end
    end
end

---初始化场景光照
function CycleInstanceScene:InitSceneLight()
    LightManager:Init()
end

function CycleInstanceScene:PlayBGM()
    local instanceBind = CycleInstanceDataManager:GetInstanceBind()
    local bgm = instanceBind.bgm
    local bgmPlay = SoundEngine[bgm]
    SoundEngine:PlayBackgroundMusic(bgmPlay, true)
end

function CycleInstanceScene:StopBGM()
    SoundEngine:StopBackgroundMusic(true)
end

function CycleInstanceScene:InitSceneVFX()
    
end


function CycleInstanceScene:InitSpecialGameObject()
    self:ShowSpecialGameObject(not self.m_instanceModel:GetLandMarkCanPurchas())

    --绑定场景特殊物品点击事件
    local specialGOBox = GameObject.Find("Miscellaneous/Environment/Landmark/roombox")
    self.floatUI.Landmark = { ["go"] = Landmark ,m_type = "Landmark"}
    FloatUI:SetObjectCrossCamera(self.floatUI.Landmark, function(view)
        if view then
            view:Invoke("ShowInstanceSpacialGOPop", false)
            --没买的提示
            if self.m_instanceModel:GetLandMarkCanPurchas() then
                view:Invoke("ShowInstanceSpacialGOBuyTipPop", true)
            end
        end
    end, nil, "roombox")

    self:SetButtonClickHandler(specialGOBox, function()
        if not self.m_instanceModel:GetLandMarkCanPurchas() then --买了1.5
            if not spacialGOPopIsShow then
                if self.floatUI.Landmark.view then
                    self.floatUI.Landmark.view:ShowInstanceSpacialGOPop(true)
                end

                spacialGOPopIsShow = true

                GameTimer:CreateNewTimer(3, function()
                    spacialGOPopIsShow = false
                    if self.floatUI.Landmark.view then
                        self.floatUI.Landmark.view:ShowInstanceSpacialGOPop(false)
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
            local landMarkShopID = CycleInstanceDataManager:GetInstanceBind().landmark_id
            GameTableDefine.CycleInstanceShopUI:OpenBuyLandmark()
        end
    end)

    local slotRoomBox = GameObject.Find("Miscellaneous/Environment/Laba/roombox")
    self:SetButtonClickHandler(slotRoomBox, function()
        GameTableDefine.SlotMachineUI:OpenView(self.m_instanceModel.instance_id or 1)
    end)
end

function CycleInstanceScene:InitWheel()
    
    
end


---刷新副本房间
function CycleInstanceScene:RefreshScene(roomID)
    for k, v in pairs(self.roomsData) do
        self:RefreshRoom(v.roomID)
    end
end

---刷新房子的相关表现
function CycleInstanceScene:RefreshRoom(roomID, index,isBuy)
    local roomData = self.roomsData[roomID]
    if roomData.state == 1 then
        --如果是修建状态,判断当前是否修建完成,如果完成则刷新显示并修改存档
        local currentTP = TimerMgr:GetCurrentServerTime(true)
        if currentTP >= self.m_instanceModel:GetRoomUnlockTime(roomID) then
            self.m_instanceModel:SetRoomData(roomID, roomData.buildTimePoint, 2)
            self.Rooms[roomID]:HideBubble() 
        else
            --显示房屋悬浮图标
            self.Rooms[roomID]:ShowBubble(1)
        end
    elseif roomData.state == 2 then
        self.Rooms[roomID]:ShowBubble(2)
        
    end
    self.Rooms[roomID]:ShowRoom()
    if index then
        self.Rooms[roomID]:ShowFurniture(index, isBuy)
    else
        self.Rooms[roomID]:ShowFurniture(nil, isBuy)
    end
end

---初始化IAA演员
function CycleInstanceScene:InitEventActor()
    local IAA = GameObject.Find("IAA")
    local go = self:GetGo(IAA,"AdNPC").gameObject
    local start = GameObject.Find("IAA/StartPos")
    local dstPos = GameObject.Find("IAA/DstPos")
    local facePos = GameObject.Find("IAA/DstPos/face")
    self.eventInstance = EventInstance:CreateActor() ---@type EventInstanceNew
    self.eventInstance.m_tempGo = go
    --self.eventInstance.m_rootGo = go.transform.parent.gameObject
    --self.eventInstance:CreateGo()
    -- local trempGo = GameObject.Instantiate(go)
    self.eventInstance:Init(IAA,go,start.transform.position, dstPos.transform.position,facePos.transform.position, 101)

end


--[[
    @desc: 初始化功能房间的相关数据，宿舍和食堂
    author:{author}
    time:2023-04-15 14:55:47
    --@roomID: 
    @return:
]]
function CycleInstanceScene:InitInteractionRoomData(roomID)
    local roomConfig = self.m_instanceModel:GetRoomConfigByID(roomID)
    local localData = {
        unlock = true,
        furnitures = {},
    }
    local roomData = {
        go = self:GetRoomGameObjectByID(roomID),
        config = roomConfig,
        employee = {},

        furnituresGo = {},
        drakFlag = {},
    }
    for k, v in pairs(self.Rooms[roomID].roomGO.furList) do
        local go
        -- for i,o in pairs(v.transform) do
        --     go = o.gameObject
        --     break
        -- end
        local workPos1 = self:GetGoOrNul(v, "workPos" .. "_" .. 1)
        if workPos1 then
            roomData.furnituresGo[k] = workPos1.transform.parent.gameObject
        end
    end
    for k, v in pairs(roomData.furnituresGo) do
        local state = self.roomsData[roomID].furList[tostring(k)].state
        if not localData.furnitures[k] then
            localData.furnitures[k] = {}
        end
        localData.furnitures[k].level = state
    end
    local SetData = function(interactions)
        if interactions then
            interactions:SetData(roomConfig, localData, roomData)
        end
    end
    if not self.Rooms[roomID].interactionsRoomData then
        self.Rooms[roomID].interactionsRoomData = roomData
    end
    --餐厅    
    if roomConfig.room_category == 3 then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_EATING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
    --宿舍
    if roomConfig.room_category == 2 then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_SLEEPING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
end


--刷新互动的物体的数据状态
function CycleInstanceScene:RefreshInteractionRoomData(roomID)
    local roomConfig = self.roomsConfig[roomID]
    local localData = {
        unlock = true,
        furnitures = {},
    }
    local roomData = {
        go = self:GetRoomGameObjectByID(roomID),
        config = roomConfig,
        employee = {},
        furnituresGo = {},
        drakFlag = {},
    }
    for k, v in pairs(self.Rooms[roomID].roomGO.furList) do
        local go
        -- for i,o in pairs(v.transform) do
        --     go = o.gameObject
        --     break
        -- end
        local workPos1 = self:GetGoOrNul(v, "workPos" .. "_" .. 1)
        if workPos1 then
            roomData.furnituresGo[k] = workPos1.transform.parent.gameObject
        end
    end
    for k, v in pairs(roomData.furnituresGo) do
        local state = self.roomsData[roomID].furList[tostring(k)].state
        if not localData.furnitures[k] then
            localData.furnitures[k] = {}
        end
        localData.furnitures[k].level = state
    end
    local RefreshData = function(interactions)
        if interactions then
            interactions.m_localData = localData
            interactions.m_sceneProcessData = roomData
            interactions.m_furnitureChanged = 1
        end
    end
    --餐厅    
    if roomConfig.room_category == 3 then
        RefreshData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_EATING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
    --宿舍
    if roomConfig.room_category == 2 then
        RefreshData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_INSTANCEWORKER_ON_SLEEPING, self.Rooms[roomID].GORoot:GetInstanceID()))
    end
end


---获取某个房间的根节点
function CycleInstanceScene:GetRoomGameObjectByID(roomID)
    return self.Rooms[roomID].GORoot
end

local ActorPath = "GamePlay.CycleInstance.Island.AI."


---检查是否需要新增员工
function CycleInstanceScene:CreateWorkers(furnitureGo, roomGo, furIndex, isBuy, roomID,personList)
    local roomData = self.roomsData[roomID]
    local room = self.Rooms[roomID]
    local levelID = roomData.furList[tostring(furIndex)].id
    local furConfig = self.m_instanceModel.furnitureLevelConfig[levelID]
    local workerCount = furConfig.worker
    local curFurnitureWorkers = room.workers[furIndex]
    local curWorkCount = 0
    if not curFurnitureWorkers then
        curFurnitureWorkers = {}
        room.workers[furIndex] = curFurnitureWorkers
    else
        curWorkCount = Tools:GetTableSize(curFurnitureWorkers)
    end
    if workerCount > curWorkCount then
        for workPosIndex = curWorkCount+1, workerCount do
            local newWorker = self:NewCreateWorker(furnitureGo, roomGo, workPosIndex, isBuy, roomID)
            curFurnitureWorkers[workPosIndex] = newWorker
            table.insert(personList,newWorker)
        end
    end
end

function CycleInstanceScene:NewCreateWorker(furnitureGo, roomGo, index, isBuy, roomId)

    local spawnPosTr = self:GetTrans(roomGo, "spawnPos")  -- 出生点

    local workPosTr = self:GetTrans(furnitureGo, "workPos_"..index) --工位点

    local facePosTr = self:GetTrans(workPosTr.gameObject, "face") --工位点朝向

    local actionPosTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index) or workPosTr --工作点

    local faceTr = self:GetTrans(roomGo, "actionPos/actionPos_" .. index .. "/face") or facePosTr

    local timeType = self.m_instanceModel:GetCurInstanceTimeType()

    local ChoiceSpawnPos = function()
        if isBuy then
            return spawnPosTr.position
        elseif timeType == self.m_instanceModel.TimeTypeEnum.work then
            return actionPosTr.position
        elseif timeType == self.m_instanceModel.TimeTypeEnum.eat then
            --需要根据房间情况选择
            return workPosTr.position
        elseif timeType == self.m_instanceModel.TimeTypeEnum.sleep then
            --需要根据房间情况选择
            return workPosTr.position
        end
    end

    local pfbName = ConfigMgr.config_character[tonumber(self.roomsData[roomId].furList[tostring(1)].worker.prefab[index])].prefab
    local roomData = {
        roomId = roomId,
        index = index
    }
    local spawnPos = ChoiceSpawnPos()
    local targetPos = workPosTr.position
    local targetRotation = faceTr.position
    local dismissPositon = nil
    local personID = 0
    local rootGo = self.m_personRoot

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

    local worker = ActorManager:CreateActorSync("CycleInstanceWorker",data,ActorPath)  ---@type CycleInstanceWorkerClass
    GameResMgr:AInstantiateObjectAsyncManual(prefabPath, worker, function(go)
        UnityHelper.AddChildToParent(self.m_personRoot.transform, go.transform)
        worker:Init(worker.instanceID,go,{
            roomId = roomId,
            furIndex = index,
            workPosTr = workPosTr,
            workFaceTr =  facePosTr,
            actPosTr = actionPosTr,
            actFaceTr = faceTr,
            roomGO = roomGo,
            furGo = furnitureGo,
            spawnPos = spawnPos,
        },spawnPosTr.position,spawnPosTr.rotation,isBuy)
    end)

    return worker
end

--标记人物可以成功执行接下来的任务
function CycleInstanceScene:TagPeopleCanDo(roomId, index, interactionRoomId)
    if not self.personList[roomId] or not self.personList[roomId][1] or not self.personList[roomId][1][index] then
        return
    end
    local person = self.personList[roomId][1][index]
    person.canSuccessDo = self.m_instanceModel:GetCurInstanceTimeType()
    person.interactionRoomId = interactionRoomId
    print(Tools:ChangeTextColor("roomId:" .. roomId .. ",index:" .. index .. ",interactionRoomId:" .. interactionRoomId .. ",TYPE:" .. person.canSuccessDo, "00ff00"))
end

--[[
    @desc: 获取家具GameObject
    author:{author}
    time:2023-04-27 10:25:34
    --@roomID:
	--@furnitureIndex:
    @return:
]]
function CycleInstanceScene:GetSceneRoomFurnitureGo(roomID, furnitureIndex, index)
    if not self.Rooms[roomID] then
        return nil
    end
    if index then
        local subFurGO = self.Rooms[roomID]:GetSubFurnitureGoByIndex(index)
        if not subFurGO then
            error("找不到家具roomID="..roomID..",subIndex="..index)
        end
        return subFurGO
    end

    return self.Rooms[roomID]:GetFurnitureGoByIndex(furnitureIndex)
end

---卸载场景中的所有员工
function CycleInstanceScene:UnloadWorker()
    for k,v in pairs(self.personList) do
        for _,workers in pairs(v) do
            for _,worker in pairs(workers) do
                GameTableDefine.ActorManager:DestroyActor(worker.instanceID)
            end
        end
    end 
end

---显示所选的家具
function CycleInstanceScene:ShowSelectFurniture(furGO, preBuy)
    -- 先还原上次操作的对象
    if selectFurniture then
        if lastSelectIsPrebuy then
            -- 将材质还原
            self:RevertMeshRendererMaterial()
            selectFurniture:SetActive(false)
        else
            self:StopFurnitureGlinting(selectFurniture)
        end
    end
    if not furGO then
        return
    end
    local blink = self:GetGo(furGO,"blink")
    local skin = self:GetGo(furGO,"skin")

    lastSelectIsPrebuy = preBuy
    selectFurniture = furGO
    furGO:SetActive(true)
    if preBuy then
        -- 替换Prebuy材质
        skin:SetActive(false)
        blink:SetActive(true)
        local meshRenderers = blink.gameObject:GetComponentsInChildren(typeof(MeshRenderer))
        local count = meshRenderers.Length
        for i=0,count-1 do
            local go = meshRenderers[i].gameObject
            if go.name ~= "shadow" then
                self:AddMeshRendererMaterial(go, preBuyMatPath)
            end
        end

    else
        self:StartFurnitureGlinting(furGO)
        return
    end

end

function CycleInstanceScene:StopFurnitureGlinting(furnitureGo)
    if self.m_glinting and self.m_glinting.meshRenderers then
        GameTimer:StopTimer(self.m_glinting.timer)
        for i=1,#self.m_glinting.materials do
            local mat = self.m_glinting.materials[i]
            --if mat:HasProperty("flash") then
            --    mat:SetFloat("flash", 0);
            --end
            if mat:HasProperty("DoFlash") then
                mat:SetFloat("DoFlash", 0);
            end
        end
        local blink = self:GetGo(furnitureGo,"blink")
        local skin = self:GetGo(furnitureGo,"skin")

        blink:SetActive(false)
        skin:SetActive(true)

        -- MaterialPropertyBlock 方案因在手机上有功能异常所以弃用
        --for i=0,self.m_glinting.meshRenderers.Length -1  do
        --    UnityHelper.SetBlockToMaterial(self.m_glinting.meshRenderers[i],false)
        --end
        self.m_glinting = nil
    end
end

function CycleInstanceScene:StartFurnitureGlinting(furnitureGo)
    if not furnitureGo then
        return
    end
    --self:StopFurnitureGlinting()

    local blink = self:GetGo(furnitureGo,"blink")
    local skin = self:GetGo(furnitureGo,"skin")
    blink:SetActive(true)
    skin:SetActive(false)
    local meshRenderers = blink:GetComponentsInChildren(typeof(MeshRenderer))
    local MaterialPropertyBlock = nil
    for i=0,meshRenderers.Length -1  do
        MaterialPropertyBlock = UnityHelper.SetBlockToMaterial(meshRenderers[i],true)
    end
    local materials = {}
    for i=0,meshRenderers.Length -1  do
        local meshRenderer = meshRenderers[i]
        for k=0,meshRenderer.materials.Length-1 do
            materials[#materials + 1] = meshRenderer.materials[k]
        end
    end


    local count = #materials

    self.m_glinting = {
        ["materials"] = materials,
        ["meshRenderers"] = meshRenderers,
        --["MaterialPropertyBlock"] = MaterialPropertyBlock,
        ["timer"] = nil,
        ["time"] = 0,
        ["deltaV"] = deltaV
    }

    for i=1,count do
        local mat = materials[i]
        if mat:HasProperty("DoFlash") then
            mat:SetFloat("DoFlash", 1);
        end
    end

end


function CycleInstanceScene:AddMeshRendererMaterial(go, address, index)
    if not go then
        return
    end
    if not self.revertMaterialData then
        self.revertMaterialData = {}
    end

    local meshRenderer = go:GetComponent("MeshRenderer")
    if meshRenderer then
        local materials = meshRenderer.materials
        if not index then
            for i = 1, materials.Length do
                self:AddMeshRendererMaterial(go, address, i)
            end
            return
        end

        local index = materials.Length - index
        if index < 0 then
            return
        end
        local material = self:LoadMaterials(address)
        if not material then
            return
        end
        if not self.revertMaterialData[meshRenderer] then
            self.revertMaterialData[meshRenderer] = {}
        end
        table.insert(self.revertMaterialData[meshRenderer], { index = index, oldMaterial = materials[index] })
        UnityHelper.SetMeshRendererMaterial(meshRenderer, material, index)

        -- MaterialPropertyBlock 方案因在手机上有功能异常所以弃用
        -- materials[index] = material
        -- meshRenderer.materials = materials
    end
end


function CycleInstanceScene:RevertMeshRendererMaterial()
    for meshRenderer,v in pairs(self.revertMaterialData or {}) do
        -- local materials = meshRenderer.materials
        -- materials[v.index] = v.oldMaterial
        -- meshRenderer.materials = materials
        for k,data in pairs(v) do
            UnityHelper.SetMeshRendererMaterial(meshRenderer, data.oldMaterial, data.index)
        end
        local SkodeGlinting = meshRenderer.gameObject:GetComponent("Skode_Glinting")
        if SkodeGlinting then
            SkodeGlinting:ResetMaterials()
        end
    end
    self.revertMaterialData = {}
end


--[[
    @desc: 播放船的动画
    author:{author}
    time:2023-04-27 10:09:57
    @return:
]]
function CycleInstanceScene:PlayShipAnim(shipFurIndex, isGO)
    for k, v in pairs(self.roomsData) do
        local roomID = v.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 4 and v.state == 2 then
            for furIndex, furData in pairs(v.furList) do
                if shipFurIndex == furData.index and furData.state == 1 then
                    local shipParent = self:GetSceneRoomFurnitureGo(roomID, furData.index)
                    local shipGO = shipParent.transform:GetChild(0).gameObject
                    local startPos = self:GetGo(shipParent, "startPos")
                    local middlePos = self:GetGo(shipParent, "middlePos")
                    local endPos = self:GetGo(shipParent, "endPos")
                    if isGO then
                        --print(string.format("船[%d]离港", shipFurIndex-6))
                        local goFeed = self:GetComp(shipGO, "goFB", "MMFeedbacks")
                        -- goFeed.Feedbacks[0].InitialPositionTransform = startPos.transform
                        -- goFeed.Feedbacks[0].DestinationPositionTransform = middlePos.transform
                        -- goFeed.Feedbacks[6].InitialPositionTransform = middlePos.transform
                        -- goFeed.Feedbacks[6].DestinationPositionTransform = endPos.transform
                        goFeed:PlayFeedbacks()
                    else
                        --print(string.format("船[%d]靠港", shipFurIndex-6))
                        local backFB = self:GetComp(shipGO, "backFB", "MMFeedbacks")
                        -- backFB.Feedbacks[1].InitialPositionTransform = endPos.transform
                        -- backFB.Feedbacks[1].DestinationPositionTransform = startPos.transform
                        backFB:PlayFeedbacks()
                    end
                end
            end
        end
    end
end

function CycleInstanceScene:PlayPortAnimation(closeIndex, openIndex)
    if closeIndex == openIndex then
        return
    end
    local closeHighPro = false
    local openHighPro = false
    if closeIndex > 6 then
        closeHighPro = true
        closeIndex = closeIndex - 6
    end
    if openIndex > 6 then
        openHighPro = true
        openIndex = openIndex - 6
    end
    --找到对应的节点
    --需要找到对应关闭的船的节点关闭其上的FloatUI
    local curIndex = closeIndex + 12
    if closeHighPro then
        curIndex = curIndex + 6
    end
    if self.shipHanders and self.shipHanders[curIndex] then
        FloatUI:RemoveObjectCrossCamera(self.shipHanders[curIndex])
        self.shipHanders[curIndex] = nil
    end
    local closeGo = self.m_portWorkplaceGos[closeIndex]
    local openGo = self.m_portWorkplaceGos[openIndex]
    -- self:LocatePosition(furGO.transform.position, true,callback)
    -- Port_1/furniture/Port1_workspace_1/Port1_workspace_1/model/Door/SF_Easter_Men_01
    -- local doorGo = self:GetGo(openGo, "model/Door/SF_Easter_Men_01")
    self:LocatePosition(openGo.transform.parent.position, false)
    if openIndex == closeIndex then
        if openGo then
            local animator = openGo:GetComponent("Animator")
            if animator then
                if openHighPro then
                    animator:SetInteger("state", 3)
                else
                    animator:SetInteger("state", 1)
                end
            end
        end
        return
    end
    if closeGo then
        local animator = closeGo:GetComponent("Animator")
        if animator then
            if closeHighPro then
                animator:SetInteger("state", 4)
            else
                animator:SetInteger("state", 2)
            end
        end
    end
    if openGo then
        local animator = openGo:GetComponent("Animator")
        if animator then
            if openHighPro then
                animator:SetInteger("state", 3)
            else
                animator:SetInteger("state", 1)
            end
        end
    end   
end

--设置船的气泡的状态
function CycleInstanceScene:SetShipBubbles(shipFurIndex, isLeave, isOpen, income)
    if not self.shipHanders then
        self.shipHanders = {}
    end
    local loadtime = self.m_instanceModel.config_global.instance_ship_loadtime

    if not self.shipHanders[shipFurIndex] then
        self.shipHanders[shipFurIndex] = {
            loadValue = 0,
            loadtime = loadtime,
            iconId = 1,
            m_type = "ship"
        }
    end
    self.shipHanders[shipFurIndex].isLeave = isLeave
    self.shipHanders[shipFurIndex].isOpen = isOpen
    if isLeave then
        self.shipHanders[shipFurIndex].loadValue = 0
    end
    for k, v in pairs(self.roomsData) do
        local roomID = v.roomID
        local roomCfg = self.roomsConfig[roomID]
        if roomCfg.room_category == 4 and v.state == 2 then
            for furIndex, furData in pairs(v.furList) do
                if shipFurIndex == furData.index and furData.state == 1 then
                    self.shipHanders[shipFurIndex].iconId = self.m_instanceModel.furnitureLevelConfig[furData.id].resource_type or 1
                    if not self.shipHanders[shipFurIndex].go then
                        local shipParent = self:GetSceneRoomFurnitureGo(roomID, furData.index)
                        self.shipHanders[shipFurIndex].go = shipParent
                    end
                    -- loadValue, isLeave, isOpen, iconId, income
                    self.shipHanders[shipFurIndex].tmpincom = income
                    if self.shipHanders[shipFurIndex].view then
                        local resCfg = self.m_instanceModel.resourceConfig[self.shipHanders[shipFurIndex].iconId]
                        local icon = ""
                        if resCfg then
                            icon = resCfg.icon
                        end
                        self.shipHanders[shipFurIndex].view:Invoke("RefreshCycShipBubbles", self.shipHanders[shipFurIndex].loadValue, self.shipHanders[shipFurIndex].isLeave, self.shipHanders[shipFurIndex].isOpen, icon, self.shipHanders[shipFurIndex].tmpincom)
                    else
                        FloatUI:SetObjectCrossCamera(self.shipHanders[shipFurIndex], function(view)
                            if not self.shipHanders[shipFurIndex].view then
                                return
                            end
                            -- self.shipHanders[shipFurIndex].view:Invoke("RefreshCycShipBubbles", self.shipHanders[shipFurIndex].loadValue, self.shipHanders[shipFurIndex].isLeave, self.shipHanders[shipFurIndex].isOpen, self.shipHanders[shipFurIndex].iconId, nil)
                        end, function()
                        end, 0)
                    end
                end
            end
        end
    end
end

function CycleInstanceScene:SetCurSellCoin(coin)
    if not self.curSellCoin then
        self.curSellCoin = coin
    end
end

function CycleInstanceScene:GetCurSellCoin()
    local result = 0
    if self.curSellCoin then
        result = self.curSellCoin
        self.curSellCoin = nil
    end
    return result
end

---刷新场景光照
function CycleInstanceScene:RefreshLight()
    local curInstanceTime = self.m_instanceModel:GetCurInstanceTime()
    if curInstanceTime.Hour ~= self.m_instanceModel.lastTime.Hour then
        if curInstanceTime.Hour == tonumber(self.m_instanceModel.config_global.cycle_instance_timenode[1]) then
            EventManager:DispatchEvent("DAY_COME")
        elseif tonumber(curInstanceTime.Hour) == tonumber(self.m_instanceModel.config_global.cycle_instance_timenode[2]) then
            EventManager:DispatchEvent("NIGHT_COME")
        end
    end
    self.lastTime = curInstanceTime
end


--[[
    @desc: 切换相机lookat目标
    author:{author}
    time:2023-04-03 15:11:13
    @return:
]]
function CycleInstanceScene:LookAtSceneGO(roomID, furIndex, cameraFocus, isBack,callback)
    if not furIndex then
        local roomGO = self:GetRoomGameObjectByID(roomID)
        self:LocatePosition(roomGO.transform.position, true,callback)
    elseif not cameraFocus then
        local furGO = self:GetSceneRoomFurnitureGo(roomID, furIndex)
        self:LocatePosition(furGO.transform.position, true,callback)
    else
        local furGO = self:GetSceneRoomFurnitureGo(roomID, furIndex)
        local size = cameraFocus.m_cameraSize
        local speed = cameraFocus.m_cameraMoveSpeed
        local target2DPosition = cameraFocus.transform.position
        local cb = nil
        if isBack then
            local data = self:GetSetCameraLocateRecordData() or {}
            data.isBack = true
            size = data.offset or size
            target2DPosition = data.offset2dPosition
            furGO = data.go3d
            cb = callback
        elseif not self:GetSetCameraLocateRecordData() then
            cb = function()
                if callback then
                    callback()
                end
            end
        end
        if not furGO or furGO:IsNull() then
            return
        end
        self:Locate3DPositionByScreenPosition(furGO, target2DPosition, size, speed, cb)
    end
end

function CycleInstanceScene:ShowSpecialGameObject(active)
    if active then
        self:GetGo(Landmark, "bought"):SetActive(true)
        self:GetGo(Landmark, "broken"):SetActive(false)
    else
        self:GetGo(Landmark, "bought"):SetActive(false)
        self:GetGo(Landmark, "broken"):SetActive(true)
    end
end

function CycleInstanceScene:BuySpecialGameObjectAnimationPlay()
    --设置当前摄像机到对应的节点
    if Landmark then
        self:LocatePosition(Landmark.transform.position, false, function()   
            EventManager:RegEvent("CY1_LANDMARK_TIMELINE_END", function(go)
                self:ShowSpecialGameObject(true)
                EventManager:UnregEvent("CY1_LANDMARK_TIMELINE_END")
                GameUIManager:SetEnableTouch(true)
            end)
            --地标动画动画播放
            local landmarkPlayable = Landmark:GetComponent("PlayableDirector")
            landmarkPlayable.time = 0
            landmarkPlayable:Play()
            GameUIManager:SetEnableTouch(false)
        end)

    end
end

function CycleInstanceScene:GoToCurSellingPortPosition(index)

end

--[[
    @desc: 事件角色切换到返回状态
    author:{author}
    time:2023-09-12 13:52:38
    --@state: 
    @return:
]]
function CycleInstanceScene:EventInstanceBack()
    if self.eventInstance then
        self.eventInstance.m_stateMachine:ChangeState(ActorDefine.State.EventInstanceLeaving)
    end
end

---获取房间对象
---@overload
---@return CycleCastleRoom
function CycleInstanceScene:GetRoomByID(roomID)
    return self.Rooms[roomID]
end

return CycleInstanceScene




