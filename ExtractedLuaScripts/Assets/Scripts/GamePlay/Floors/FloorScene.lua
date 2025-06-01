local Class = require("Framework.Lua.Class");
local BaseScene = require("Framework.Scene.BaseScene")
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")
local PropertyWorker = require("CodeRefactoring.Actor.Actors.PropertyWorker")
local CEOActor = require("CodeRefactoring.Actor.Actors.CEOActor")
local CompanyEmployeeNew = require "CodeRefactoring.Actor.Actors.CompanyEmployeeNew"
local InteractionsManager = require "CodeRefactoring.Interactions.InteractionsManager"
local Bus = require "CodeRefactoring.Actor.Actors.BusNew"
local UIView = require("Framework.UI.View")
local ActorDefine = require("CodeRefactoring.Actor.ActorDefine")
local PersonStateMachine = require("CodeRefactoring.AI.StateMachines.PersonStateMachine")

local FloorMode = GameTableDefine.FloorMode
local CountryMode = GameTableDefine.CountryMode
local ConfigMgr = GameTableDefine.ConfigMgr
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local GameUIManager = GameTableDefine.GameUIManager
local CompanyMode = GameTableDefine.CompanyMode
local FloatUI = GameTableDefine.FloatUI
local TimerMgr = GameTimeManager
local MainUI = GameTableDefine.MainUI
local SoundEngine = GameTableDefine.SoundEngine
local GameClockManager = GameTableDefine.GameClockManager
local BuyCarManager = GameTableDefine.BuyCarManager
local StarMode = GameTableDefine.StarMode
local BenameUI = GameTableDefine.BenameUI
local GuideManager = GameTableDefine.GuideManager
local TalkUI = GameTableDefine.TalkUI
local CityMode = GameTableDefine.CityMode
local HouseMode = GameTableDefine.HouseMode
local FactoryMode = GameTableDefine.FactoryMode
local ShopAfterPerson = GameTableDefine.ShopAfterPerson
local ShopManager = GameTableDefine.ShopManager
local ForbesRewardUI = GameTableDefine.ForbesRewardUI
local IntroduceUI = GameTableDefine.IntroduceUI
local FootballClubModel = GameTableDefine.FootballClubModel
local CEODataManager = GameTableDefine.CEODataManager
local CEODeskUI = GameTableDefine.CEODeskUI

local TweenUtil = CS.Common.Utils.DotweenUtil
local AnimationUtil = CS.Common.Utils.AnimationUtil
local SkodeGlinting = CS.UnityEngine.Skode_Glinting
local UnityHelper = CS.Common.Utils.UnityHelper ---@type Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local FeelUtil = CS.Common.Utils.FeelUtil
local GameLanucher = CS.Game.GameLauncher.Instance
local EventDispatcher = EventDispatcher
---@class FloorScene:BaseScene
local FloorScene = Class("FloorScene", BaseScene)
local ActorManager = require("CodeRefactoring.Actor.ActorManager")

local AllowedCompanyFloatUICount = 2

FloorScene.FLAG_DARK_LOCKED    = 1
FloorScene.FLAG_DARK_OFFDUTY   = 2
FloorScene.FLAG_DARK_BROKEN    = 3
FloorScene.FLAG_DARK_START     = 4

---@class RoomRootData
---@field go UnityEngine.GameObject
---@field config table
---@field employee CompanyEmployeeNew[]
---@field furnituresGo UnityEngine.GameObject[]
---@field unlock UnityEngine.GameObject
---@field locked UnityEngine.GameObject
---@field VFX_fault UnityEngine.GameObject
---@field UIPosition UnityEngine.GameObject
---@field PowerOff UnityEngine.GameObject
---@field ceoFurnituresGo UnityEngine.GameObject
---@field ceoActor CEOActor
---@field ceoBoxFloatUI table
local RoomRootData = {}

---@class CEOFurnitureInfo
---@field ceoID number
---@field level number
local CEOFurnitureInfo = {}

---@class CEOFurnitureConfig
---@field id number
---@field table_ceo_limit number
---@field table_cost number
---@field table_debuff number
---@field table_desc string
---@field table_icon string
---@field table_level number
---@field table_name string
---@field table_prefab string
---@field table_reward number
local CEOFurnitureConfig = {}

function FloorScene:ctor()
    self.super:ctor()
    self.roomRootGo = {} ---@type RoomRootData[]
    self.furnitureLoadCallback = {}
    self.furnitureBuff = {}
    self.m_floorTransList = {}
    self.m_floorsNumberIndex = {}
    self.m_unsatisfiedStarRooms = {}
    self.selectFurniturePositionGo = nil
    self.treeHander = {}
    self.bossActorEntity = nil
end

function FloorScene:OnEnter(defaultRoomCategory)
    self.m_personRoot = {GameObject.Find("NPC").gameObject}
    --新的场景白天黑夜的特效节点
    self.m_vfxDayGo = GameObject.Find("vfx_day")
    self.m_vfxNightGo = GameObject.Find("vfx_night")
    self.m_nightGos = UnityHelper.GetGameObjectsByTagToLuaTable("TAG_NIGHT_OBJ")
    self.m_dayGos = UnityHelper.GetGameObjectsByTagToLuaTable("TAG_DAY_OBJ")
    --转盘上的字
    self.m_WheelTxtGo = GameObject.Find("wheel_num") 
    self.m_ConstructTriggerGo = GameObject.Find("ContrusctTrigger")
    --后处理节点
    self.m_GlobalVolumeGo = GameObject.Find("Global Volume")
    if FloorMode:GetCurrFloorConfig().floor_count > 1 then
        self.m_personRoot[1] = GameObject.Find("GNPC").gameObject
        for i = 1, FloorMode:GetCurrFloorConfig().floor_count do
            self.m_personRoot[i + 1] = GameObject.Find(i .. "F/NPC").gameObject
        end
    end
    self.m_personSpawnPostion = {GameObject.Find("SpawnPos/SpawnPos_1").transform.position, 
                                 GameObject.Find("SpawnPos/SpawnPos_2").transform.position, 
                                 GameObject.Find("SpawnPos/SpawnPos_3").transform.position}
    self.super:OnEnter()
    self:InitRoomsGo(defaultRoomCategory)
    MainUI:InitCameraScale("IndoorScale")
    MainUI:SetFloorIndex(FloorMode:GetCurrentFloorIndex(), FloorMode)
    GameTableDefine.LightManager:Init()--初始化室内的灯光
    Bus:GetCarEntity(BuyCarManager:GetDrivingCar())

    local renameBlock = GameObject.Find("GongSiZhaoPai_1").gameObject
    local currLanguage = GameLanguage:GetCurrentLanguageID()
    local isCrosswiseName = currLanguage == "cn" or currLanguage == "tc"
    self:GetGo(renameBlock, "Name"):SetActive(isCrosswiseName)
    self:GetGo(renameBlock, "Name_en"):SetActive(not isCrosswiseName)
    if not isCrosswiseName then
        UIView:SetText(renameBlock, "Name_en", LocalDataManager:GetBuildingName() or "", nil, nil, true)
    else
        UIView:SetText(renameBlock, "Name", LocalDataManager:GetBuildingName() or "", nil, nil, true)
    end

    UIView:SetClickHandler(renameBlock, function()
        BenameUI:ReName()
        FeelUtil.PlayFeel(self:GetGo(renameBlock, "ClickFeedback"))
        --UIView:GetComp(renameBlock, "ClickFeedback", "MMFeedbacks"):PlayFeedbacks()
    end)
    
    self.wheelNode = GameObject.Find("Wheel")
    if self.wheelNode then
        self.wheelNode = self.wheelNode.gameObject
        self.wheelNode:SetActive(ConfigMgr.config_global.wheel_switch == 1 and StarMode:GetStar() >= ConfigMgr.config_global.wheel_condition)
        UIView:SetClickHandler(self.wheelNode, function()
            GameTableDefine.RouletteUI:GetView()
        end)
        local uglyCode = {}
        uglyCode.go = self.wheelNode
        EventManager:RegEvent("WHEEL_NOTE", function(cdTime)
            if cdTime <= 0 then
                FloatUI:SetObjectCrossCamera(uglyCode, function(view)
                    if view then
                        view:Invoke("WheelNote", function()
                            GameTableDefine.RouletteUI:GetView()
                        end)
                    end
                end, nil, "decoration/SM_Prop_Rug_01 1")
            else
                FloatUI:RemoveObjectCrossCamera(uglyCode)
            end
        end)
        -- 2024-5-31 gxy 策划说去掉这个功能
        --EventManager:RegEvent("WHEEL_SPECIAL", function()
        --    if self.wheelNode then
        --        local alreadyHaveIds = GameTableDefine.RouletteUI:AlreadyGet()
        --        --实际上它只能关闭,转盘表上,已经拥有的
        --        for k,v in pairs(alreadyHaveIds) do
        --            local go = self:GetGo(self.wheelNode, v .. "")
        --            if go then
        --                go:SetActive(false)
        --            end
        --        end
        --    end
        --end)
        EventManager:DispatchEvent("WHEEL_SPECIAL")
        --如果可以看广告旋转,则显示对话框,没有则关闭
        --XU_TODO
        
    else
        MainUI:SetWheelBtnActive(false)
    end
    ---boss雕像显示---
    self.bossStatues = GameObject.Find("Statue")
    if self.bossStatues then
        for k,v in pairs(self.bossStatues.transform) do
            v.gameObject:SetActive(false)
        end
        local bossNum = LocalDataManager:GetDataByKey("boss_skin") or "Boss_001"
        local bossSkin = self:GetGo(self.bossStatues, bossNum)       
        if bossSkin then
            bossSkin:SetActive(true)
        end        
    end
    ----------------
    if GameConfig:IsChristmas() then--点击圣诞树下雪,变音乐,树动画,时间到之后恢复
        local christmasObj = GameObject.Find("Christmas")
        
        if christmasObj then
            christmasObj = christmasObj.gameObject

            local snow = self:GetGo(christmasObj, "SnowDown")
            local snowParticle = self:GetComp(snow, "ParticleSystem", "ParticleSystem")
            local musicClio = SoundEngine["Christmas_BGM"]

            local backToNormal = function()
                if SoundEngine:CurrBackgroundMusic() == musicClio then
                    CityMode:PlayDefaultSound()
                end
                snowParticle:Stop()

                for k,v in pairs(self.treeHander or {}) do
                    v(k)
                end

            end

            local goToChristmas = function()
                SoundEngine:PlayBackgroundMusic(musicClio, false)
                snow:SetActive(true)
                snowParticle:Play()
            end

            local normalTree = function(tree)
                local shiningFeel = self:GetGo(tree, "ClickFeedback")
                local backNormalFeel = self:GetGo(tree, "StopFeedback")
                FeelUtil.StopFeel(shiningFeel)
                FeelUtil.PlayFeel(backNormalFeel)
            end

            local shiningTree = function(tree)
                local shiningFeel = self:GetGo(tree, "ClickFeedback")

                local lastTree = #self.treeHander + 1
                if not self.treeHander[lastTree] then
                    shiningFeel:SetActive(true)
                    FeelUtil.PlayFeel(shiningFeel)
                    table.insert(self.treeHander, function(k)--时间到后的回调
                        normalTree(tree)
                        self.treeHander[k] = nil
                    end)
                end
                
                if lastTree == 1 then--第一次点击圣诞树
                    goToChristmas()

                    self:StopTimer()
                    self:CreateTimer(36 * 1000, function()
                        backToNormal()
                    end)
                end
            end

            local currTree = GameObject.Find("Tree_1")
            if currTree then currTree = currTree.gameObject end
            if currTree then
                UIView:SetClickHandler(currTree, function()
                    shiningTree(currTree)
                end)
            end

            local currTree2 = GameObject.Find("Tree_2")
            if currTree2 then currTree2 = currTree2.gameObject end
            if currTree2 then
                UIView:SetClickHandler(currTree2, function()
                    shiningTree(currTree2)
                end)
            end

            EventManager:RegEvent("BACK_TO_SCENE", function()
                backToNormal()
            end)

        end
    end

    --如果第一次进初始,则播放...
    local currScene = CityMode:GetCurrentBuilding()
    if currScene > 100 and FloorMode:FirstCome(currScene, true) then
        self:ActiveTimeLine(currScene)
    end

    GameSDKs:TrackForeign("init", {init_id = 11, init_desc = "进入游戏场景"})
    GameTableDefine.LoadingScreen:SetLoadingMsg("TXT_LOG_LOADING_10")
    GameLanucher:SetNewProgressMsg(GameTextLoader:ReadText("TXT_LOG_LOADING_3"))
    EventManager:RegEvent("EVENT_SHOP_PEOPLE", function()
        if GameStateManager:IsInFloor() then
            FloorMode:GetScene():RefreshManagerRoomPeople()
        end
    end)

    --工厂新手引导
    self:CheckIfNeededFactoryGuide()

    --足球俱乐部引导
    self:CheckIfNeededFootballClubGuide(50001)

    if self.m_WheelTxtGo then
        self:SetSceneWheelNum(GameTableDefine.RouletteUI:SaveBurstTime(true).."/"..GameTableDefine.RouletteUI:GoalBurstTime())
    end
    FloorMode:ResetPostProcessing()
    self:ControlGlobalVolumeDisp(not self:IsProcessDayNightScene())

    self.m_changeCEOActorHandler = handler(self,self.OnCEOActorChanged)
    EventDispatcher:RegEvent(GameEventDefine.ChangeCEOActor,self.m_changeCEOActorHandler)
end

function FloorScene:OnPause()
end

function FloorScene:OnResume()
end

function FloorScene:OnExit()
    self.super:OnExit(self)
    self.bossActorEntity = nil
    self:StopTimer()
    self:CleanAllRoomsGoUIView()
    --Actor:DestroyAllActor()
    FloatUI:DestroyFloatUIView()
    EventDispatcher:UnRegEvent(GameEventDefine.ChangeCEOActor,self.m_changeCEOActorHandler)
end

function FloorScene:Update(dt)
    self.super:OnUpdate(self)
    --Actor:UpdateActorList(dt)
    self:ExecuteFurnitureLoadCallback()
end

function FloorScene:InitRoomsGo(defaultRoomCategory)
    local floorConfig = FloorMode:GetCurrFloorConfig() or {}
    for k,roomId in ipairs(floorConfig.room_list or {}) do
        local roomConfig = ConfigMgr.config_rooms[roomId]
        local go = GameObject.Find(roomConfig.room_index).gameObject
        self.roomRootGo[roomId] = self.roomRootGo[roomId] or {}
        self.roomRootGo[roomId].go = go
        self.roomRootGo[roomId].config = roomConfig
        self.roomRootGo[roomId].employee = {}
        self.roomRootGo[roomId].furnituresGo = {}
        self.roomRootGo[roomId].unlock = self:GetGoOrNul(go, "unlock")
        self.roomRootGo[roomId].locked = self:GetGoOrNul(go, "locked")
        self.roomRootGo[roomId].VFX_fault = self:GetGoOrNul(go, "VFX_fault")
        self.roomRootGo[roomId].UIPosition = self:GetGoOrNul(go, "UIPosition/unlock3dButton")
        self.roomRootGo[roomId].PowerOff = self:GetGoOrNul(go, "PowerOff")
        self.roomRootGo[roomId].drakFlag = 0
        -- self.roomRootGo[roomId].lockGo = self:GetGo(self.roomRootGo[roomId].go, "locked")
        self:InitRoomFloorsNUmberIndex(go)
    end
    self:InitFloorInfo()
    for k,roomId in ipairs(floorConfig.room_list or {}) do
        self.roomRootGo[roomId].floorNumberIndex = self:GetRoomFloorNumberIndex(self.roomRootGo[roomId].go)
        self:InitRoomGo(roomId, defaultRoomCategory)
    end
    LocalDataManager:WriteToFile()
end

function FloorScene:lookAtRoom(roomId)
    if self.roomRootGo and self.roomRootGo[roomId] then
        self:LocatePosition(self.roomRootGo[roomId].go.transform.position)
    end
end

function FloorScene:GetRoomRootGoData(roomId)
    return self.roomRootGo[roomId]
end

function FloorScene:InitRoomGo(roomId, defaultRoomCategory)
    local roomConfig = ConfigMgr.config_rooms[roomId]
    local localData = FloorMode:GetCurrRoomLocalData(roomConfig.room_index)
    local companyData = CompanyMode:CompanyExist(roomConfig.room_index)
    -- self.roomRootGo[roomId].lockGo:SetActive(false)
    self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_LOCKED, false)

    if localData.toUnlock and localData.unlockTime <= TimerMgr:GetCurrentServerTime() then--房间刚解锁
        localData.unlock = localData.toUnlock
        localData.toUnlock = false
        localData.unlockTime = 0
        if self.roomRootGo[roomId].accessory_room_id then
            for k,v in ipairs(self.roomRootGo[roomId].accessory_room_id) do
                self:InitRoomGo(v)
            end
            self.roomRootGo[roomId].accessory_room_id = nil
        end
        -- GameSDKs:Track("gt_extend", {room_id = roomId, current_money = ResMgr:GetCash()})
        GameSDKs:TrackForeign("build_upgrade", {build_id = roomId, build_level_new = 1, operation_type = 2, scene_id = CityMode:GetCurrentBuilding()})
        --2024-5-29 gxy 新增解锁休息室的新事件打点
        if roomConfig.category[2] == 8 then
            GameSDKs:TrackControl("af", "af,unlock_restroom", {af_buildingID = 0})
        end
        
        MainUI:RefreshQuestHint()
        self.roomRootGo[roomId].unlock:SetActive(false)
        self.roomRootGo[roomId].locked:SetActive(false)
        self.roomRootGo[roomId].UIPosition:SetActive(false)
    end

    if localData.unlock and localData.unlockTime <= TimerMgr:GetCurrentServerTime() then--正常点击打开房间
        self:SetButtonClickHandler(self:GetGo(self.roomRootGo[roomId].go, "roombox"), function()
            --K133 因为和CEO引导冲突 所以续约功能只在3D图标中生效
            --local canLevelUp = CompanyMode:CompanyLvUp(companyData and companyData.company_id or nil, true)
            --if localData.leaveCompany and not canLevelUp then--公司刚要离开,但还不能升级(因为说升级优先...)
            --    RenewUI:Refresh(localData.leaveCompany, roomConfig.room_index, roomId)
            --    return
            --end

            GameUIManager:SetEnableTouch(false, "scene1")
            FloorMode:SetCurrRoomInfo(roomConfig.room_index, roomId)
            RoomBuildingUI:ShowRoomPanelInfo(roomId)
        end)
        --K133 点击CEO家具
        local ceoBox = self:GetGoOrNul(self.roomRootGo[roomId].go, "ceobox")
        if ceoBox then
            self:SetButtonClickHandler(ceoBox, function()
                if CEODataManager:GetGuideTriggered() then
                    GameSDKs:TrackForeign("ceo_manage", {source = "ceoBox"})
                    CEODeskUI:Show(roomConfig.room_index, CountryMode:GetCurrCountry())
                end
            end)
            local ceoUIPosition = self:GetGoOrNul(ceoBox,"UIPosition")
            if ceoUIPosition then
                self.roomRootGo[roomId].ceoBoxFloatUI = {["go"] = ceoBox, m_type = "ceoDesk"}
                FloatUI:SetObjectCrossCamera(self.roomRootGo[roomId].ceoBoxFloatUI, function(view)
                    if view then
                        view:Invoke("ShowRoomCEOInfo",roomConfig.room_index)
                    end
                end,nil,"UIPosition")
            end
        end
        if defaultRoomCategory and roomConfig.category[2] == defaultRoomCategory then--???什么用
            FloorMode:SetCurrRoomInfo(roomConfig.room_index, roomId)
            RoomBuildingUI:ShowRoomPanelInfo(roomId)
        end
        self.roomRootGo[roomId].unlock:SetActive(false)
        self.roomRootGo[roomId].locked:SetActive(false)
        self.roomRootGo[roomId].UIPosition:SetActive(false)
    elseif not localData.unlock and not self:CheckUnlockCondition(self.roomRootGo[roomId]) then--可以解锁该房间
        if StarMode:GetStar() >= (self.roomRootGo[roomId].config.star or 0) then
            self:SetButtonClickHandler(self:GetGo(self.roomRootGo[roomId].go, "roombox"), function()
                if localData.unlockTime > TimerMgr:GetCurrentServerTime() then--解锁中
                    return
                end
                GameTableDefine.RoomUnlockUI:Show(self.roomRootGo[roomId].config)--打开解锁界面
            end)
            self.roomRootGo[roomId].unlock:SetActive(true)
            self.roomRootGo[roomId].locked:SetActive(false)
            self.roomRootGo[roomId].UIPosition:SetActive(true)
            if localData.unlockTime and localData.unlockTime > TimerMgr:GetCurrentServerTime() then
                self.roomRootGo[roomId].UIPosition:SetActive(false)
            end
        else
            table.insert(self.m_unsatisfiedStarRooms, roomId)
            self.roomRootGo[roomId].unlock:SetActive(false)
            self.roomRootGo[roomId].locked:SetActive(true)
            self.roomRootGo[roomId].UIPosition:SetActive(false)
            local lockedTextGO = self:GetGoOrNul(self.roomRootGo[roomId].locked, "text")
            if lockedTextGO then
                lockedTextGO:SetActive(false)
            end
        end
    else--无法解锁
        -- self.roomRootGo[roomId].lockGo:SetActive(true)
        self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_LOCKED, true)
        self.roomRootGo[roomId].unlock:SetActive(false)
        self.roomRootGo[roomId].locked:SetActive(true)
        self.roomRootGo[roomId].UIPosition:SetActive(false)
    end

    local gameH, gameM, gameD = GameClockManager:GetCurrGameTime() 
    local isOffice = FloorMode:IsTypeOffice(self.roomRootGo[roomId].config.category)
    if isOffice then
        local offGo = self:GetGo(self.roomRootGo[roomId].go, "offduty")
        if companyData then
            self.roomRootGo[roomId].isWork = CompanyMode:CheckCompanyWorkState(gameH, gameM, companyData.company_id)
            ---- offGo:SetActive(not self.roomRootGo[roomId].isWork)
            self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_OFFDUTY, not self.roomRootGo[roomId].isWork)
        else
            ---- offGo:SetActive(false)
            self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_OFFDUTY, false)
        end
    elseif FloorMode:IsTypeManager(self.roomRootGo[roomId].config.category) or FloorMode:IsTypeProperty(self.roomRootGo[roomId].config.category) then
        self.roomRootGo[roomId].isWork = CompanyMode:CheckManagerRoomOnWork(true, roomId)
        if nil ~= self.roomRootGo[roomId].isWork then
            self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_OFFDUTY, not self.roomRootGo[roomId].isWork)
        end
        
    end
    self:InitInteractionRoomData(self.roomRootGo[roomId])
    self:InitRoomGoUIView(self.roomRootGo[roomId])
    if not FloorMode:IsTypeManager(self.roomRootGo[roomId].config.category) then
        self:InitFurnitures(self.roomRootGo[roomId])
    else
        self:InitFurnitures(self.roomRootGo[roomId])
    end
    self:InitCEOFurniture(self.roomRootGo[roomId])
    self:InitRoomCompanyLogo(self.roomRootGo[roomId])
end

function FloorScene:InitInteractionRoomData(roomData)
    local roomConfig = roomData.config
    local localData = FloorMode:GetCurrRoomLocalData(roomConfig.room_index)
    ---@param interactions InteractionsNew
    local SetData = function(interactions)
        if not interactions then
            return
        end
        interactions:SetData(roomConfig, localData, roomData)
    end

    if FloorMode:IsTypeToile(roomConfig.category) then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_EMPLOYEE_ON_TOILET, roomData.go:GetInstanceID()))
    end
    if FloorMode:IsTypeRest(roomConfig.category) then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_EMPLOYEE_ON_REST, roomData.go:GetInstanceID()))
    end
    if FloorMode:IsTypeMeeting(roomConfig.category) then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_EMPLOYEE_ON_MEETING, roomData.go:GetInstanceID()))
    end
    if FloorMode:IsTypeEntertainment(roomConfig.category) then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ENTERTAINMENT, roomData.go:GetInstanceID()))
    end
    if FloorMode:IsTypeGym(roomConfig.category) then
        SetData(InteractionsManager:GetEntity(ActorDefine.Flag.FLAG_EMPLOYEE_ON_GYM, roomData.go:GetInstanceID()))
    end
end

function FloorScene:ifRoomUnlocked(roomIndex)
    local localData = FloorMode:GetCurrRoomLocalData(roomIndex)
    return localData.unlock == true
end

function FloorScene:ifRoomToUnlocked(roomIndex)
    local localData = FloorMode:GetCurrRoomLocalData(roomIndex)
    return localData.toUnlock == true
end

function FloorScene:RoomUnlockAble(roomId)--b不写在mode主要是因为这个checkUnlockCondition
    local roomConfig = ConfigMgr.config_rooms[roomId]
    local localData = FloorMode:GetCurrRoomLocalData(roomConfig.room_index)
    if localData.unlock then--已解锁
        return 1
    end

    if localData.toUnlock then--解锁中
        return 2
    end

    local data = self.roomRootGo[roomId]
    local lackCondition = self:CheckUnlockCondition(data)
    if lackCondition then
        return 3
    end

    if StarMode:GetStar() < (roomConfig.star or 0 ) then
        return 4
    end

    return 5
end

function FloorScene:InitRoomGoUIView(roomRootData)
    local localData = FloorMode:GetCurrRoomLocalData(roomRootData.config.room_index)
    local isOffice = FloorMode:IsTypeOffice(roomRootData.config.category)
    local companyId = CompanyMode:CompIdByRoomIndex(roomRootData.config.room_index)
    local gameH, gameM = GameClockManager:GetCurrGameTime() 
    local isOnWork = companyId ~= nil and CompanyMode:CheckCompanyWorkState(gameH, gameM, companyId)
    local needCompany = isOffice == true and companyId == nil
    local offWork = isOffice == true and not isOnWork
    local canLevelUp = CompanyMode:CompanyLvUp(companyId, true)
    local brokenCfg = ConfigMgr.config_emergency[localData.room_broken_cfg_id]

    if localData.unlock 
        and localData.unlockTime <= TimerMgr:GetCurrentServerTime() 
        --and localData.companyReward == 0 
        and not localData.leaveCompany
        and not needCompany 
        and not offWork 
        and not brokenCfg
        and not canLevelUp
    then
        FloatUI:RemoveObjectCrossCamera(roomRootData)
        return
    end
    if self:CheckUnlockCondition(roomRootData, true) then--黑色的,不满足房间解锁条件的
        return
    end

    -- if brokenCfg then
    --     -- self:CheckRoomBrokenHint(roomRootData.config.room_index, roomRootData.idleService == nil and localData.room_broken_cfg_id or nil, roomRootData) --特殊事件 UI表现
    --     self:GetGo(roomRootData.go, brokenCfg.room_node[roomRootData.config.category[2]]):SetActive(true) --特殊事件 模型表现显示
    -- end

    if brokenCfg or canLevelUp or needCompany then--出现其他图标的时候,不显示下班图标
        if isOffice then
            ---- self:GetGo(roomRootData.go, "offduty"):SetActive(false)
            self:SetRoom3dHintVisible(roomRootData.config.id, self.FLAG_DARK_OFFDUTY, false)
        end
        if brokenCfg then
            self:PlayRoomBrokenVFX(roomRootData.config.id, true)
        end
    end

    FloatUI:SetObjectCrossCamera(roomRootData, function(view)
        if view then
            isOffice = FloorMode:IsTypeOffice(roomRootData.config.category)
            companyId = CompanyMode:CompIdByRoomIndex(roomRootData.config.room_index)
            gameH, gameM = GameClockManager:GetCurrGameTime() 
            isOnWork = companyId ~= nil and CompanyMode:CheckCompanyWorkState(gameH, gameM, companyId)
            local deskNum = FloorMode:GetFurnitureNum(10001, 1, roomRootData.config.room_index)
            needCompany = isOffice == true and companyId == nil and (deskNum >= 4)
            offWork = isOffice == true and not isOnWork
            canLevelUp = CompanyMode:CompanyLvUp(companyId, true)
            brokenCfg = ConfigMgr.config_emergency[localData.room_broken_cfg_id] --特殊事件 浮动UI表现显示

            roomRootData.view:Invoke("ShowRoomUnlockButtton",
            localData.unlock, localData.toUnlock,
            roomRootData.config.unlock_require,
            localData.unlockTime, localData.leaveCompany,
            roomRootData.config, needCompany, offWork, brokenCfg,
            canLevelUp, companyId
        )
        end
    end)
end

function FloorScene:CheckUnlockCondition(roomRootData, bindAction)
    local isNotRequirement = true
    for k, v in pairs(roomRootData.config.unlock_room or {}) do
        if v == 0 then
            return false
        end
        local confg = ConfigMgr.config_rooms[v] or {}
        local localData = FloorMode:GetCurrRoomLocalData(confg.room_index)
        if not localData.unlock then
            if bindAction then
                if not self.roomRootGo[confg.id].accessory_room_id then
                    self.roomRootGo[confg.id].accessory_room_id = {}
                end
                table.insert(self.roomRootGo[confg.id].accessory_room_id, roomRootData.config.id)
            end
        end
        isNotRequirement = isNotRequirement and (not localData.unlock)
    end
    return isNotRequirement
end

function FloorScene:CleanAllRoomsGoUIView()
    for k, room in pairs(self.roomRootGo or {}) do
        FloatUI:RemoveObjectCrossCamera(room)
        room.guid = nil
        room.view = nil
        if room.ceoBoxFloatUI then
            FloatUI:RemoveObjectCrossCamera(room.ceoBoxFloatUI)
            room.ceoBoxFloatUI = nil
        end
    end
    self.roomRootGo = nil
    self.furnitureBuff = nil
    self.furnitureLoadCallback = nil
    self.m_personRoot = nil
    self.m_personSpawnPostion = nil
    self.m_floorsNumberIndex = nil
    self.m_unsatisfiedStarRooms = nil
    self.wheelNode = nil
end

function FloorScene:InitFurnitures(roomRootData, selectFurnitureIndex)
    local furnitureConfig = roomRootData.config.furniture or {}
    local roomIndex = roomRootData.config.room_index
    local localData = FloorMode:GetCurrRoomLocalData(roomRootData.config.room_index)
    local roomGo = roomRootData.go

    if not localData.unlock then
        return
    end
    local bonus = {}
    local isRoomExist = CompanyMode:CompanyExist(roomIndex)
    for i, v in ipairs(furnitureConfig) do
        local cfg = ConfigMgr.config_furnitures[v.id]
        -- print("XU_DATA:  " .. cfg.object_name .. "  " .. v.index)
        local furniturePositionGo = self:GetTrans(roomGo, cfg.object_name .. "_" .. v.index)
        if furniturePositionGo then
            furniturePositionGo = furniturePositionGo.gameObject
            if i == selectFurnitureIndex then
                self.selectFurniturePositionGo = furniturePositionGo
            end
            local furnitureInfo = localData.furnitures[i]
            --K133 CEO版本 不在经理室生成阿珍
            local isNotAZen = true
            local accessoryInfo = furnitureInfo.accessory_info or {}
            if accessoryInfo and accessoryInfo[FloorMode.F_TYPE_AUX_PERSON] then
                for k,v in pairs(accessoryInfo[FloorMode.F_TYPE_AUX_PERSON]) do
                    if v.id == 10050 or v.id == 11050 then
                        isNotAZen = false
                        break
                    end
                end
            end
            if furnitureInfo.level > 0 and isNotAZen then
                self:InstantiateFurniture(i, roomRootData, localData, furniturePositionGo)
                -- if not roomRootData.employee[i] and (CompanyMode:CompanyExist(roomIndex) or accessoryInfo[FloorMode.F_TYPE_AUX_PERSON]) then -- v.id == 10001  v.id == 10004 
                --     self:CreateEmployee(i, roomRootData, localData, furniturePositionGo)
                -- end
                if not roomRootData.employee[i] then
                    if isRoomExist or accessoryInfo[FloorMode.F_TYPE_AUX_PERSON] then
                        self:CreateEmployee(i, roomRootData, localData, furniturePositionGo)
                    elseif tostring(cfg.type) == FloorMode.F_TYPE_SHOP_PERSON then
                        --FloorScene:RefreshManagerRoomPeople()
                        self:RefreshShopPerson(roomRootData.config.id, i)
                    end
                end

                if not (isRoomExist or accessoryInfo[FloorMode.F_TYPE_AUX_PERSON]) and furnitureInfo.employee_info then
                    furnitureInfo.employee_info = nil
                end
                if accessoryInfo[FloorMode.F_TYPE_AUX_CONDITION] then -- 重置打印机位置
                    local _,accessory = next(accessoryInfo[FloorMode.F_TYPE_AUX_CONDITION])
                     -- 修复游戏机不能购买的问题，原因一个游戏机占用了2台桌子导致的。
                    local hasErrorData = nil
                    for idx,___ in ipairs(furnitureConfig or {}) do
                        if localData.furnitures[idx].id == accessory.id and localData.furnitures[idx].index == accessory.index and localData.furnitures[idx].level_id ~= accessory.lvId then
                            furnitureInfo.accessory_info = nil
                            hasErrorData = true
                            break
                        end
                    end
                    if not hasErrorData then
                        self:ResetCashRegistersPosition(roomGo, furniturePositionGo, accessory)
                    end
                end
            else
                for k,v in pairs(furniturePositionGo.transform or {}) do
                    self:RecycleFurnitureToBuff(v.gameObject)
                end
            end
        end
    end
end

function FloorScene:InitRoomCompanyLogo(roomRootData)
    local roomConfig = roomRootData.config
    local isOffice = FloorMode:IsTypeOffice(roomConfig.category)
    if not isOffice then
        return
    end

    local localData = FloorMode:GetCurrRoomLocalData(roomConfig.room_index)
    local companyData = CompanyMode:CompanyExist(roomConfig.room_index)
    local CompId = CompanyMode:CompIdByRoomIndex(roomConfig.room_index)
    local companyDecorationGo =  self:GetGo(roomRootData.go, "companyDecoration")
    companyDecorationGo:SetActive(companyData ~= nil)

    if companyData then
        -- local companyCfg = ConfigMgr.config_company[CompId]
        -- local R,G,B,A = Tools:HEX2RGB(companyCfg["company_spray"..GameConfig:GetLangageFileSuffix()])
        -- for k,trans in pairs(self:GetTrans(companyDecorationGo, "Sprays") or {}) do
        --     local meshRenderer = trans.gameObject:GetComponent("MeshRenderer")
        --     if meshRenderer then
        --         MaterialUtil.SetRendererPropertyColor(meshRenderer, "_BaseColor", Color(R,G,B,A))
        --     end
        -- end

        -- local address = string.format("Assets/Res/Icons/UI/%s%s.png", companyCfg["company_logo"], GameConfig:GetLangageFileSuffix())
        -- local handler = GameResMgr:LoadTextureSyncFree(address, self)
        -- if handler.Status == AsyncOperationStatus.Failed then
        --     return
        -- end
        -- for k,trans in pairs(self:GetTrans(companyDecorationGo, "Logos") or {}) do
        --     local meshRenderer = trans.gameObject:GetComponent("MeshRenderer")
        --     if meshRenderer then
        --         MaterialUtil.SetRendererPropertyTexture(meshRenderer, "_BaseMap", handler.Result)
        --     end
        -- end
    end
end

function FloorScene:ResetCashRegistersPosition(roomGo, positionGo, targetInfo)
    local lvCfg = ConfigMgr.config_furnitures_levels[targetInfo.lvId]
    local tFurnitureId = lvCfg.furniture_id
    local tFurnitureName = ConfigMgr.config_furnitures[tFurnitureId].object_name
    local tIndex = targetInfo.index
    local tGoName = tFurnitureName .. "_" .. tIndex

    local tans = self:GetTrans(positionGo, "CashRegisterPos")
    if not tans then
        self:RegisterFurnitureLoadCallback(positionGo, function()
            local tans = self:GetTrans(positionGo, "CashRegisterPos")
            if not tans or tans:IsNull() then
                return
            end
            local furniturePositionGo = self:GetTrans(roomGo, tGoName)
            if furniturePositionGo and not furniturePositionGo:IsNull() then
                furniturePositionGo.position = tans.position
            end
        end)
        return
    end

    local furniturePositionGo = self:GetTrans(roomGo, tGoName)
    if furniturePositionGo and not furniturePositionGo:IsNull() then
        furniturePositionGo.position = tans.position
    end
end


function FloorScene:GetRandomPosition()
    local n = math.random(1, #self.m_personSpawnPostion)
    if n ~= self.curRandomNum then
        self.curRandomNum = n
        return self.m_personSpawnPostion[self.curRandomNum]
    end
    return self:GetRandomPosition()
end

function FloorScene:CreateEmployeeGO(index, roomRootData, localData, furniturePositionGo)

    if roomRootData.employee[index] then
        return
    end

    local tans = self:GetTrans(furniturePositionGo, "workPos")
    if not tans then
        return
    end

    local skin = nil
    local accessoryInfo = localData.furnitures[index].accessory_info or {}
    local accessoryId = accessoryInfo[FloorMode.F_TYPE_AUX_PERSON] -- type 1 才需要创建雇员
    local isProperty = accessoryId ~= nil
    local lvCfg = nil
    local accessoryData = nil
    local saveSkin = (localData.furnitures[index].employee_info or {}).skin
    if accessoryId then
        local _,accessory = next(accessoryId)
        lvCfg = ConfigMgr.config_furnitures_levels[accessory.lvId]
        saveSkin = saveSkin or (ConfigMgr.config_furnitures[lvCfg.furniture_id].object_name .. "_00" .. lvCfg.level)
        skin = "Assets/Res/Prefabs/character/" .. saveSkin .. ".prefab"
        for k,v in pairs(localData.furnitures) do
            if v.id == accessory.id and accessory.index == v.index then
                accessoryData = v
                break
            end
        end
    else
        if not CompanyMode:CompanyExist(roomRootData.config.room_index) then
            return
        end
        saveSkin = saveSkin or CompanyMode:GetCompanyemployee_skin(roomRootData.config.room_index, index)
        skin = "Assets/Res/Prefabs/character/" .. saveSkin .. ".prefab"
    end
    if not skin then
        return
    end
    if not localData.furnitures[index].employee_info then
        localData.furnitures[index].employee_info = {}
    end

    local employee_skin = localData.furnitures[index].employee_info.employee_skin or skin
    local targetPos = self:GetTrans(furniturePositionGo, "workPos").position
    local initPos = self:GetRandomPosition()
    local targetDir = self:GetTrans(furniturePositionGo, "face").position
    local dismissPositon = self:GetRandomPosition()
    local isOldEmployee = localData.furnitures[index].employee_info.employee_skin or localData.furnitures[index].employee_info.skin
    local isOnOffice = isOldEmployee and (roomRootData.isWork)-- or isProperty
    local rootGo = self.m_personRoot[1] --isOnOffice and self.m_personRoot[(roomRootData.floorNumberIndex or 0) + 1] or self.m_personRoot[1]
    local isBoss = roomRootData.config.furniture[index].id == 10022 or roomRootData.config.furniture[index].id == 11022
    if FloorMode:IsTypeManager(roomRootData.config.category) and isBoss then
        if self.m_GuideTimeLine then
            return
        end
        local bossSkin = LocalDataManager:GetBossSkin()
        if bossSkin then
            employee_skin = "Assets/Res/Prefabs/character/" .. bossSkin .. ".prefab"
        end
        isOldEmployee = true
    end
    local isOfficeRoom = FloorMode:IsOfficeRoom(roomRootData.config.category)
    if isProperty then
        roomRootData.employee[index] = PropertyWorker:CreateActor(isOfficeRoom, roomRootData.config.room_index)
    else
        roomRootData.employee[index] = CompanyEmployeeNew:CreateActor(isOfficeRoom, roomRootData.config.room_index)
    end
    local employee = roomRootData.employee[index]
    local personID = 0
    if isBoss then
        personID = 1
        --2023.8.31添加用于获取当前的boss的Entity对象 fengyu
        self.bossActorEntity = roomRootData.employee[index]
    elseif string.find(employee_skin, "Secretary_001") then
        personID = 2
        self.secretaryEntity = roomRootData.employee[index]
    end
    employee:Init(rootGo, employee_skin, initPos, targetPos, targetDir, dismissPositon, roomRootData, index, personID)
    if isProperty then
        employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_PROPERTY)
        if FloorMode:IsTypeProperty(roomRootData.config.category) then
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_PROPERTY_WORKER)
            employee:SetPropertyLevelLocalData(accessoryData)
        elseif FloorMode:IsTypeManager(roomRootData.config.category) and isBoss then -- 仅仅经理
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_MANAGER_WORKER)
            employee:SetPropertyLevelLocalData(accessoryData)
        end
    end
    if isOldEmployee then
        if roomRootData.isWork == false then
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
        else
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
        end
    else
        if roomRootData.isWork == false then
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
        else
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_BY_BUS)
        end
    end
    localData.furnitures[index].employee_info.skin = saveSkin
    localData.furnitures[index].employee_info.employee_skin = nil
    --roomRootData.employee[index].__id = roomRootData.config.room_index.."_" ..index
end

---标记为是否加载中
function FloorScene:MarkEmployeeIsLoading(roomData,employeeIndex,isLoading)
    roomData.loadingEmployee[employeeIndex] = isLoading
end

function FloorScene:CreateEmployee(index, roomRootData, localData, furniturePositionGo)
    if roomRootData.employee[index] then
        return
    end

    if not roomRootData.loadingEmployee then
        roomRootData.loadingEmployee = {}
    end
    if roomRootData.loadingEmployee[index] then
        --printf("重复加载Employee")
        return
    else
        self:MarkEmployeeIsLoading(roomRootData,index,true)
    end

    local tans = self:GetTrans(furniturePositionGo, "workPos")
    if not tans then
        local createEmployInfo = {index = index,roomRootData=roomRootData,localData=localData,furniturePositionGo=furniturePositionGo}
        self:RegisterFurnitureLoadCallback(furniturePositionGo, function()
            local actor = self:CreateEmployeeGO(createEmployInfo.index, createEmployInfo.roomRootData, createEmployInfo.localData, createEmployInfo.furniturePositionGo)
            self:MarkEmployeeIsLoading(roomRootData,index,false)
        end)
    else
        self:CreateEmployeeGO(index, roomRootData, localData, furniturePositionGo)
        self:MarkEmployeeIsLoading(roomRootData,index,false)
    end
end

function FloorScene:RefreshManagerRoomPeople()
    local managerRoom = FloorMode:GetRoomLocalData("ManagerRoom_104")
    local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")

    local cfg = ConfigMgr.config_furnitures
    local currData = nil
    for k,v in pairs(managerRoom.furnitures or {}) do
        if v.level > 0 then
            currData = cfg[v.id]
            if currData and currData.type == 4 then
                self:RefreshShopPerson(roomId, k)
            end
        end
    end
end

function FloorScene:CreateShopPerson(roomId, index,roomData,shopType,tans,furGo)
    local employee_skin,shopId, npcIndex = ShopAfterPerson:GetSkin(shopType)
    if ShopAfterPerson:LastPerson(shopType, shopId, true) then--已经有了
        return
    end

    local targetPos = tans.position
    local rootGo = self.m_personRoot[1]
    local targetDir = self:GetTrans(furGo, "face").position
    local initPos = self:GetRandomPosition()
    local dismissPosition = self:GetRandomPosition()

    local skinRoot = "Assets/Res/Prefabs/character/"

    if not employee_skin then
        return
    end

    local currEmpyee = roomData.employee[index]
    if currEmpyee then
        currEmpyee:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION)
        currEmpyee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_DISMISS)
        currEmpyee:Event(ActorDefine.Event.EVENT_EMPLOYEE_DISMISS)
        roomData.employee[index] = nil
    end

    local personID = nil
    -- 2022-12-6添加用于换装使用的属性
    for k, v in pairs(ConfigMgr.config_employees) do
        if v.shopId == shopId then
            personID = v.id
            break
        end
    end
    roomData.employee[index] = PropertyWorker:CreateActor()
    roomData.employee[index]:Init(rootGo, skinRoot .. employee_skin .. ".prefab", initPos, targetPos, targetDir, dismissPosition, roomData, index, personID)

    ShopAfterPerson:LastPerson(shopType, shopId)

    local currEmplyee = roomData.employee[index]
    currEmplyee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_PROPERTY)

    ShopAfterPerson:SetPerson(shopType, currEmplyee)
    ShopAfterPerson:BindTalkMessage(shopType, shopId, npcIndex)

    local comeBefor = ShopAfterPerson:ComeBefor(shopType, shopId)
    local isWork = roomData.isWork
    if isWork == false then
        currEmplyee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
    else
        if comeBefor then
            currEmplyee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
        else
            currEmplyee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_BY_BUS)
        end
    end

end

function FloorScene:RefreshShopPerson(roomId, index)--调用比较频繁,看看如何设置
    local roomData = self:GetRoomRootGoData(roomId)
    local furData = roomData.config.furniture[index]

    if not roomData or not furData then
        return
    end
    if not roomData.loadingEmployee then
        roomData.loadingEmployee = {}
    end
    if roomData.loadingEmployee[index] then
        --printf("重复加载ShopPerson")
        return
    else
        roomData.loadingEmployee[index] = true
    end
    if not furData.id then
        return
    end
    local cfgFur = ConfigMgr.config_furnitures[furData.id]
    local need = {[10052] = true, [10053] = true}
    if not need[furData.id] then
        return
    end

    local shopType = nil
    local buyBefor = nil
    if furData.id == 10052 then--收益
        shopType = 6
        buyBefor = ShopManager:GetCashImprove() > 0
    elseif furData.id == 10053 then--离线
        shopType = 7
        buyBefor = ShopManager:GetOfflineAdd() > 0
    end

    if not buyBefor then
        return
    end

    local furGo = self:GetTrans(roomData.go, cfgFur.object_name .. "_1")
    if not furGo then
        return
    end
    furGo = furGo.gameObject
    local tans = self:GetTrans(furGo, "workPos")
    if not tans then
        self:RegisterFurnitureLoadCallback(furGo, function()
            tans = self:GetTrans(furGo, "workPos")
            self:CreateShopPerson(roomId, index,roomData,shopType,tans,furGo)
        end)
        return
    else
        self:CreateShopPerson(roomId, index,roomData,shopType,tans,furGo)
    end
end

function FloorScene:LevelUpFurniture(roomId, index, level)
    local roomRootData = self.roomRootGo[roomId]
    if roomRootData.furnituresGo[index] then
        self.selectFurniturePositionGo = nil
        self:StopFurnitureSkodeGlinting(roomRootData.furnituresGo[index])
        self:RecycleFurnitureToBuff(roomRootData.furnituresGo[index])
        roomRootData.furnituresGo[index] = nil
    end
    if roomRootData.employee then
        for k,p in pairs(roomRootData.employee) do
            if p.UpdateFurnitureMood then --只有公司员工有心情相关方法
                p:UpdateFurnitureMood()
            end
        end
    end
    GameTimer:CreateNewMilliSecTimer(300, function()
        self:RefreshInteraction(roomId, level)
    end)
end

function FloorScene:RefreshInteraction(roomId, level)
    if level < 1 then
        return
    end
    local roomRootData = self.roomRootGo[roomId]
    if roomRootData.interactionsActor then 
        roomRootData.interactionsActor.m_furnitureChanged = level
        if level == 1 then
            roomRootData.interactionsActor:SetPersonUpdateInteractionTag()
        end
    end
end

function FloorScene:InstantiateFurniture(index, roomRootData, localData, furniturePositionGo)
    local config = roomRootData.config.furniture[index] or {}
    local isWorker = ConfigMgr.config_furnitures[config.id].type == 1
    if roomRootData.furnituresGo[index] or isWorker then --物业雇员没有静态外形
        return
    end
    for k,v in pairs(furniturePositionGo.transform or {}) do
        self:RecycleFurnitureToBuff(v.gameObject)
    end

    local prefabName = ConfigMgr.config_furnitures[config.id].object_name .. "_00" .. localData.furnitures[index].level
    local childTrans = self:GetTrans(furniturePositionGo, prefabName)
    if childTrans then
        roomRootData.furnituresGo[index] = childTrans.gameObject
        self:MarkFurnitureLoadCallback(furniturePositionGo, childTrans.gameObject)
        --self:RefreshAStarBlock(childTrans.gameObject) -- 局部更新a星地图
        return
    end

    roomRootData.furnituresGo[index] = -1
    self:GetFurnitureFromBuff(prefabName, function(childGo)
        UnityHelper.AddChildToParent(furniturePositionGo.transform, childGo.transform)
        roomRootData.furnituresGo[index] = childGo
        local go = self:GetGoOrNul(roomRootData.go, "struct/DiTan")
        if go then
            UnityHelper.IgnoreRendererByObject(go, childGo)
        end
    end)
end

function FloorScene:RegisterFurnitureLoadCallback(furniturePositionGo, callback)
    if not self.furnitureLoadCallback[furniturePositionGo] then
        self.furnitureLoadCallback[furniturePositionGo] = {callbacks = {}}
    end
    table.insert(self.furnitureLoadCallback[furniturePositionGo].callbacks, callback)
end

function FloorScene:MarkFurnitureLoadCallback(furniturePositionGo, childGo)
    if self.furnitureLoadCallback and self.furnitureLoadCallback[furniturePositionGo] then
        self.furnitureLoadCallback[furniturePositionGo].arg = childGo
    end
end

function FloorScene:ExecuteFurnitureLoadCallback()

    if self.furnitureLoadCallback then
        for furniturePositionGo,callbackInfo in pairs(self.furnitureLoadCallback) do
            if PersonStateMachine.IsLoadingState then
                return
            end
            if callbackInfo.arg then
                local arg = callbackInfo.arg
                for _, v in pairs(callbackInfo.callbacks) do
                    v(arg)
                end
                self.furnitureLoadCallback[furniturePositionGo] = nil
                LocalDataManager:WriteToFile()
            end
        end
    end
end

function FloorScene:RecycleFurnitureToBuff(furnitureGo)
    if not furnitureGo or furnitureGo == -1 then
        return
    end

    local name = furnitureGo.name
    if not self.furnitureBuff[name]  then
        self.furnitureBuff[name] = {}
    end
    table.insert(self.furnitureBuff[name], furnitureGo)
    UnityHelper.AddChildToParent(GameObject.Find("FurnitureBuff").gameObject.transform, furnitureGo.transform)
    furnitureGo:SetActive(false)
end

function FloorScene:GetFurnitureFromBuff(prefabName, cb)
    if not self.furnitureBuff[prefabName]  then
        self.furnitureBuff[prefabName] = {}
    end
    local furnitureGo = table.remove(self.furnitureBuff[prefabName], 1)
    if furnitureGo then
        furnitureGo:SetActive(true)
        local isSelection = cb(furnitureGo)
        --if not isSelection then
        --    --self:RefreshAStarBlock(furnitureGo) -- 局部更新a星地图
        --end
        return
    end

    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/Prefabs/furniture/" .. prefabName .. ".prefab", self, function(childGo)
        if cb then
            childGo.name = prefabName
            self:SetFurnitureSkodeGlinting(childGo)
            local isSelection = cb(childGo)

            local furniturePositionGo = childGo.transform.parent.gameObject
            --if not isSelection then
            --    --self:RegisterFurnitureLoadCallback(furniturePositionGo, function()
            --        --self:RefreshAStarBlock(childGo) -- 局部更新a星地图
            --    --end)
            --end
            self:MarkFurnitureLoadCallback(furniturePositionGo, childGo)
        else
            UnityHelper.DestroyGameObject(childGo)
        end
    end)
end

function FloorScene:SetFurnitureSkodeGlinting(furnitureGo)
    if not furnitureGo or furnitureGo == -1 or not furnitureGo.activeInHierarchy then
        return
    end
    for i,trans in pairs(self:GetTrans(furnitureGo.gameObject, "model") or {}) do
        local renderer = self:GetComp(trans.gameObject,"","Renderer")
        if renderer and not renderer:IsNull() then
            trans.gameObject:AddComponent(typeof(SkodeGlinting))
        end
    end
end

function FloorScene:StartFurnitureSkodeGlinting(furnitureGo)
    if not furnitureGo or furnitureGo == -1 or not furnitureGo.activeInHierarchy then
        return
    end
    for i,trans in pairs(self:GetTrans(furnitureGo.gameObject, "model") or {}) do
        local SkodeGlinting = trans.gameObject:GetComponent("Skode_Glinting")
        if SkodeGlinting then
            SkodeGlinting:StartGlinting()
        end
    end
end

function FloorScene:StopFurnitureSkodeGlinting(furnitureGo)
    if not furnitureGo or furnitureGo == -1 then
        return
    end

    for i,trans in pairs(self:GetTrans(furnitureGo.gameObject, "model") or {}) do
        local SkodeGlinting = trans.gameObject:GetComponent("Skode_Glinting")
        if SkodeGlinting then
            SkodeGlinting:StopGlinting()
        end
    end
end

function FloorScene:SelectFurniture(furnitureIndex)
    if self.selectFurniturePositionGo then
        for i,trans in pairs(self.selectFurniturePositionGo.transform or {}) do
            self:StopFurnitureSkodeGlinting(trans)
        end
    end
    self.selectFurniturePositionGo = nil
    self:RevertMeshRendererMaterial()

    local roomData = self.roomRootGo[FloorMode.m_curRoomId]
    self:InitFurnitures(roomData, furnitureIndex)
    if self.selectFurniturePositionGo then
        local furnitureId = ConfigMgr.config_rooms[FloorMode.m_curRoomId].furniture[furnitureIndex].id
        local isNeedDesk = ConfigMgr.config_furnitures[furnitureId].type == 2 -- 点钞机必须有可放置的桌子才能显示
        local tGo = nil
        if isNeedDesk then
            local lvCfg = ConfigMgr.config_furnitures_levels[furnitureId][1]
            local tFurnitureId = ConfigMgr.config_furnitures_levels[lvCfg.hire_condition].furniture_id
            for i, v in ipairs(FloorMode:GetCurrRoomLocalData().furnitures or {}) do
                local accessoryInfo = v.accessory_info or {}
                local index = ConfigMgr.config_rooms[FloorMode.m_curRoomId].furniture[furnitureIndex].index
                local accessoryIndex = furnitureId .. "_" .. index
                local accessory = (accessoryInfo[FloorMode.F_TYPE_AUX_CONDITION] or {})[accessoryIndex]
                if v.id == tFurnitureId 
                    and v.level > 0 
                    and (not accessoryInfo[FloorMode.F_TYPE_AUX_CONDITION] or not accessory or (accessory.lvId == lvCfg.id and accessory.index == index)) 
                then
                    tGo = roomData.furnituresGo[i]
                end
            end
            if not tGo then
                return
            end
        end

        local localData = FloorMode:GetCurrRoomLocalData(roomData.config.room_index)
        local curLevel = math.max(localData.furnitures[furnitureIndex].level, 1)
        local prefabName = ConfigMgr.config_furnitures[furnitureId].object_name .."_00"..curLevel
        local trans = self:GetTrans(self.selectFurniturePositionGo, prefabName)
        local cb = function(child)
            if localData.furnitures[furnitureIndex].level > 0 then
                self:StartFurnitureSkodeGlinting(child)
                return
            end
            for i,trans in pairs(self:GetTrans(child, "model") or {}) do
                self:AddMeshRendererMaterial(trans.gameObject, "Assets/Res/Materials/FX_Materials/PreBuy.mat")
            end
            if tGo and tGo ~= -1 then
                local lvId = ConfigMgr.config_furnitures_levels[furnitureId][1].id
                local index = ConfigMgr.config_rooms[FloorMode.m_curRoomId].furniture[furnitureIndex].index
                self:ResetCashRegistersPosition(roomData.go, tGo, {lvId = lvId, index = index})
            end
        end
        if not trans then
            if roomData.furnituresGo[furnitureIndex] == -1 then
                self:RegisterFurnitureLoadCallback(self.selectFurniturePositionGo, function(tempGo)
                    cb(tempGo)
                end)
            else
                self:GetFurnitureFromBuff(prefabName, function(tempGo)
                    if not self.selectFurniturePositionGo then
                        self:RecycleFurnitureToBuff(tempGo)
                        return
                    end
                    UnityHelper.AddChildToParent(self.selectFurniturePositionGo.transform, tempGo.transform)
                    cb(tempGo)
                    return true
                end)
            end
        else
            cb(trans.gameObject)
        end
        return true
    end
end

function FloorScene:AddMeshRendererMaterial(go, address, index)
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
            for i=1,materials.Length do
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
        table.insert(self.revertMaterialData[meshRenderer], {index = index, oldMaterial = materials[index]})
        UnityHelper.SetMeshRendererMaterial(meshRenderer, material, index)
        -- materials[index] = material
        -- meshRenderer.materials = materials
    end
end

function FloorScene:RevertMeshRendererMaterial()
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

function FloorScene:OneGoToliet()
    local room = self.roomRootGo[1001]
    local employee = room.employee[1] ---@type CompanyEmployeeNew
    if employee and employee.m_stateMachine:IsState("EmployeeWorkState") then
        employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_TOILET)
        return employee.m_go
    end
    return nil
end

function FloorScene:DismissEmployee(roomId)
    local room = self.roomRootGo[roomId]
    if not room then
        return
    end
    local localData = FloorMode:GetCurrRoomLocalData(room.config.room_index)
    local furnitureConfig = room.config.furniture or {}
    for i, v in pairs(room.employee) do
        local employee = room.employee[i]
        if employee then
            employee:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_ACTION)
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_DISMISS)
            employee:Event(ActorDefine.Event.EVENT_EMPLOYEE_DISMISS)
            room.employee[i] = nil
            room.isWork = nil
            localData.furnitures[i].employee_info = nil
        end
    end
    room.isWork = nil
    return true
end

function FloorScene:ShowEnergyRoom()
    local floorConfig = FloorMode:GetCurrFloorConfig() or {}
    for k,roomId in ipairs(floorConfig.room_list or {}) do
        local roomConfig = ConfigMgr.config_rooms[roomId]
        if roomConfig.category[2] == 5 then
            local roomGo = self:GetRoomRootGoData(roomId)
            local  floorCount = FloorMode:GetCurrFloorConfig().floor_count
            if roomGo.floorNumberIndex ~= FloorMode:GetCurrentFloorIndex() and floorCount ~= 1 then
                FloorMode:SetCurrentFloorIndex(roomGo.floorNumberIndex, nil, function()
                    FloorMode:SetCurrRoomInfo(roomConfig.room_index, roomId)
                    RoomBuildingUI:ShowRoomPanelInfo(roomId)
                end)
            else
                FloorMode:SetCurrRoomInfo(roomConfig.room_index, roomId)
                RoomBuildingUI:ShowRoomPanelInfo(roomId)
            end
            return
        end
    end
end
-- (后面加的,仿写的ShowEnergyRoom)在复数的楼层中跳转到指定的房间中
function FloorScene:ShowFloorRoom(roomId)
    local floorConfig = FloorMode:GetCurrFloorConfig() or {}
    local roomConfig = ConfigMgr.config_rooms[roomId]
    if roomConfig then
        local roomGo = self:GetRoomRootGoData(roomId)
        local  floorCount = FloorMode:GetCurrFloorConfig().floor_count
        if roomGo.floorNumberIndex ~= FloorMode:GetCurrentFloorIndex() and floorCount ~= 1 then
            FloorMode:SetCurrentFloorIndex(roomGo.floorNumberIndex, nil, function()
                FloorMode:SetCurrRoomInfo(roomConfig.room_index, roomId)
                RoomBuildingUI:ShowRoomPanelInfo(roomId)
            end)
        else
            FloorMode:SetCurrRoomInfo(roomConfig.room_index, roomId)
            RoomBuildingUI:ShowRoomPanelInfo(roomId)
        end
        return
    end
end

---获取房间所在楼层
function FloorScene:GetRoomFloor(roomId)
    local roomConfig = ConfigMgr.config_rooms[roomId]
    if roomConfig then
        local roomGo = self:GetRoomRootGoData(roomId)
        local  floorCount = FloorMode:GetCurrFloorConfig().floor_count
        if floorCount ~= 1 then
            return roomGo.floorNumberIndex
        else
            return 1
        end
    else
        return 1
    end
end

-- function FloorScene:ActiveCompanyMeeting(roomId, day)
--     local room = self.roomRootGo[roomId] or {}
--     if room.isMet == day then
--         return
--     end
--     for i, v in pairs(room.employee or {}) do
--         local employee = v
--         if employee and not employee:HasFlag(employee.FLAG_EMPLOYEE_ON_TOILET | employee.FLAG_EMPLOYEE_ON_REST) and employee:HasFlag(employee.FLAG_EMPLOYEE_ON_WORKING) then
--             employee:AddFlag(employee.FLAG_EMPLOYEE_ON_MEETING)
--         end
--     end
--     room.isMet = day
--     Meeting:GetMeetingEntity():SetRoomId(roomId)
-- end

function FloorScene:SetCompanyStartWork(roomId, force)
    -- local room = self.roomRootGo[roomId] or {}
    -- local localData = FloorMode:GetRoomLocalData(room.config.room_index)
    -- if not localData.unlock then
    --     return
    -- end
    -- if room.isWork == true then
    --     return room.isWork
    -- end
   
    -- self:GetGo(room.go, "offduty"):SetActive(false)
    -- room.isWork = true
    -- if isRequest then
    --     return room.isWork
    -- end
    -- for i, employee in pairs(room.employee or {}) do
    --     if employee and employee:HasFlag(employee.FLAG_EMPLOYEE_OFF_WORKING) then
    --         employee:RemoveFlag(employee.FLAG_EMPLOYEE_OFF_WORKING)
    --         local bus = Bus:GetBusEntity()
    --         if employee:HasFlag(employee.FLAG_EMPLOYEE_MANAGER_WORKER) then
    --             bus = Bus:GetCarEntity(BuyCarManager:GetDrivingCar()) or bus
    --         end 
    --         bus:Event(bus.EVENT_NEW_PASSENGER, employee)
    --         employee:ResetTriggerCounter()
    --     end
    -- end

    local room = self.roomRootGo[roomId] or {}
    if room.isWork == true and not force then
        return
    end

    --if room.config then
        -- FloorMode:GetScene():InitRoomGo(room.config.id)--关闭下班图标
        -- self:GetGo(room.go, "offduty"):SetActive(false)
        self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_OFFDUTY, false)
    --end

    local bus = Bus:GetBusEntity()
    for i, employee in pairs(room.employee or {}) do
        if employee and employee:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) then
            if not employee:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_MANAGER_WORKER) then
                employee:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
                bus:AddWaitingPassenger( employee)
                employee:ResetTriggerCounter()
            end
        end
    end
    --K133 通知对应房间的CEO上班
    EventDispatcher:TriggerEvent(GameEventDefine.CEOGoToWork,roomId)

    room.isWork = true
end

function FloorScene:SetCompanyEndWork(roomId, force)
    -- local room = self.roomRootGo[roomId] or {}
    -- local localData = FloorMode:GetRoomLocalData(room.config.room_index)
    -- if room.isWork == false or not localData.unlock then
    --     return
    -- end

    -- self:GetGo(room.go, "offduty"):SetActive(true)
    -- room.isWork = false
    -- if isRequest then
    --     return room.isWork
    -- end
    -- for i, employee in pairs(room.employee or {}) do
    --     if employee 
    --         and not employee:HasFlag(employee.FLAG_EMPLOYEE_OFF_WORKING) 
    --         and employee:HasFlag(employee.FLAG_EMPLOYEE_ON_WORKING) 
    --     then
    --         employee:AddFlag(employee.FLAG_EMPLOYEE_OFF_WORKING)
    --         employee:RemoveFlag(employee.FLAG_EMPLOYEE_ON_WORKING)
    --         local bus = Bus:GetBusEntity()
    --         if employee:HasFlag(employee.FLAG_EMPLOYEE_MANAGER_WORKER) then
    --             bus = Bus:GetCarEntity() or bus
    --         end 
    --         bus:Event(bus.EVENT_NEW_PASSENGER, employee)
    --     end
    -- end

    local room = self.roomRootGo[roomId] or {}
    if room.isWork == false and not force then
        return
    end

    --if room.config then
        -- FloorMode:GetScene():InitRoomGo(room.config.id)--打开下班图标
        -- self:GetGo(room.go, "offduty"):SetActive(true)
        self:SetRoom3dHintVisible(roomId, self.FLAG_DARK_OFFDUTY, true)
        --self:SetRoomWorkable(false, room.go)--关闭房间灯光
    --end

    local bus = Bus:GetBusEntity()
    local setPersonOffWorking = function(employee)
        if not employee:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_MANAGER_WORKER) then
            employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
            employee:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
            bus:AddWaitingPassenger(employee)
        end
    end

    if room.onSpecialBuilding then
        --for i, employee in pairs(room.employee or {}) do
        --    if employee:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_MANAGER_WORKER) then -- 买车下班，秘书除外
        --        employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
        --        employee:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
        --        employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_MANAGER_LEAVE)
        --        employee.m_sceneGroundGo = nil
        --        local scene = FloorMode:GetScene()
        --        UnityHelper.AddChildToParent(scene.m_personRoot[1].transform, employee.m_go.transform, true)
        --        UnityHelper.IgnoreRenderer(employee.m_go, false)
        --        employee.m_stateMachine:ChangeState(ActorDefine.State.PropertyInBusState)
        --        --car:AddWaitingPassenger(employee)
        --        break
        --    end
        --end
    else
        for i, employee in pairs(room.employee or {}) do
            if employee 
                and not employee:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
                and employee:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
            then
                setPersonOffWorking(employee)
            end
        end
        --通知CEO下班
        EventDispatcher:TriggerEvent(GameEventDefine.CEOOffWorkWithCompany,roomId)
    end
    -- for i, employee in pairs(room.employee or {}) do
    --     if employee 
    --         and not employee:HasFlag(employee.FLAG_EMPLOYEE_OFF_WORKING) 
    --         and employee:HasFlag(employee.FLAG_EMPLOYEE_ON_WORKING) 
    --     then
    --         if room.onSpecialBuilding then
    --             if not employee:HasFlag(employee.FLAG_EMPLOYEE_MANAGER_WORKER) then
    --                 return -- 买车下班，秘书除外
    --             end
    --             employee:AddFlag(employee.FLAG_EMPLOYEE_MANAGER_LEAVE)
    --         end
    --         employee:AddFlag(employee.FLAG_EMPLOYEE_OFF_WORKING)
    --         employee:RemoveFlag(employee.FLAG_EMPLOYEE_ON_WORKING)
    --         local bus = Bus:GetBusEntity()
    --         if employee:HasFlag(employee.FLAG_EMPLOYEE_MANAGER_WORKER) then
    --             bus = Bus:GetCarEntity() or bus
    --         end 
    --         bus:Event(bus.EVENT_NEW_PASSENGER, employee)
    --     end
    -- end
    room.isWork = false
end


---通知BOSS上班
---@param force boolean 是否强制boss坐车来上班
function FloorScene:SetBossStartWork(force)
    local boss = ActorManager:GetFloorBossEntity()
    if boss then
        if force then
            boss:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
            if not boss.m_stateMachine:IsState("PropertyInBusState") then
                --隐藏BOSS 防止穿帮
                boss.m_stateMachine:ChangeState(ActorDefine.State.PropertyInBusState)
            end
            boss.m_sceneGroundGo = nil
            local scene = FloorMode:GetScene()
            UnityHelper.AddChildToParent(scene.m_personRoot[1].transform, boss.m_go.transform, true)
            UnityHelper.IgnoreRenderer(boss.m_go, false)

            local car = Bus:GetCarEntity(BuyCarManager:GetDrivingCar()) or Bus:GetBusEntity()
            car:AddWaitingPassenger(boss)
        else
            if boss:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) then
                boss:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
                if boss.m_stateMachine:IsState("PropertyInBusState") then
                    local car = Bus:GetCarEntity(BuyCarManager:GetDrivingCar()) or Bus:GetBusEntity()
                    car:AddWaitingPassenger(boss)
                end
            end
        end
    end
end

---通知BOSS下班
function FloorScene:SetBossEndWork()
    local boss = ActorManager:GetFloorBossEntity()
    if boss then
        if not boss:HasFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING) then
            boss:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
            boss:RemoveFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
            local car = Bus:GetCarEntity(BuyCarManager:GetDrivingCar()) or Bus:GetBusEntity()
            car:AddWaitingPassenger(boss)
        end
    end
end

function FloorScene:SetRoomWorkable(onWork, roomRoot)
    local targetLayer = onWork and "RoomLight" or "RoomDark"
    UnityHelper.ChangeLayer(roomRoot, targetLayer)
end

function FloorScene:CheckRoomBrokenHint(roomIndex, brokenId, roomGo)
    local cfg = ConfigMgr.config_emergency[brokenId]
    local enabled = cfg ~= nil
    local type = nil
    if cfg then
        local roomcfg = ConfigMgr.config_rooms[FloorMode:GetRoomIdByRoomIndex(roomIndex)]
        type = cfg.emergency_ui[roomcfg.category[2]]
    end
    MainUI:SetEventRoomBrokenHint(roomIndex, type, roomGo, enabled, brokenId)
end

function FloorScene:SwitchFloorIndex(lastFloorIndex, cb)
    if lastFloorIndex then
        local floorDefGo = GameObject.Find(lastFloorIndex.."F").gameObject
        UnityHelper.IgnoreRenderer(floorDefGo, true)
    end
    local index = FloorMode:GetCurrentFloorIndex()
    local floorDefGo = GameObject.Find(index.."F").gameObject
    UnityHelper.IgnoreRenderer(floorDefGo, false)
    MainUI:SetFloorIndex(FloorMode:GetCurrentFloorIndex(), FloorMode)
    self:SetCameraCapsule(floorDefGo.transform.position, cb)
end

---@param go UnityEngine.GameObject
function FloorScene:InitRoomFloorsNUmberIndex(go)
    if not go or go:IsNull() then
        return
    end

    local floorRoot = go.transform.root
    if floorRoot and floorRoot ~= go.transform then
        if not self.m_floorTransList[floorRoot] then
            local floorInfo = {}
            floorInfo.m_trans = floorRoot
            floorInfo.m_posY = floorRoot.position.y
            self.m_floorTransList[floorRoot] = floorInfo
        end
    end
    --local goY = math.ceil(go.transform.position.y)
    --if #self.m_floorsNumberIndex == 0 then
    --    table.insert(self.m_floorsNumberIndex, goY)
    --else
    --    for i, v in ipairs(self.m_floorsNumberIndex) do
    --        if v == goY then
    --            break
    --        elseif goY < v then
    --            table.insert(self.m_floorsNumberIndex, i, goY)
    --            break
    --        elseif i == #self.m_floorsNumberIndex and goY > v then
    --            table.insert(self.m_floorsNumberIndex, goY)
    --        end
    --    end
    --end
end

function FloorScene:InitFloorInfo()
    if Tools:GetTableSize(self.m_floorTransList) > 0 then
        local sortList = {}
        for trans,info in pairs(self.m_floorTransList) do
            if sortList[1] == nil then
                sortList[1] = {m_trans=info.m_trans,m_posY = info.m_posY}
            else
                for i,v in ipairs(sortList) do
                    if trans == v.m_trans then
                        break
                    end
                    if info.m_posY<v.m_posY then
                        table.insert(sortList, i, {m_trans=info.m_trans,m_posY = info.m_posY})
                        break
                    elseif i == #sortList then
                        table.insert(sortList, i+1, {m_trans=info.m_trans,m_posY = info.m_posY})
                    end
                end
            end
        end
        for i,v in ipairs(sortList) do
            self.m_floorsNumberIndex[v.m_trans] = i
        end
    end
end

---@param go UnityEngine.GameObject
function FloorScene:GetRoomFloorNumberIndex(go)
    if not go or go:IsNull() then
        return
    end

    local rootTrans = go.transform.root

    if rootTrans == go.transform then
        return 1
    else
        return self.m_floorsNumberIndex[rootTrans] or 1
    end
end

function FloorScene:CheckRoomsStarEnough()
    local ownStar = StarMode:GetStar()
    for k,v in pairs(self.m_unsatisfiedStarRooms or {}) do
        local data = self:GetRoomRootGoData(v)
        if data and ownStar >= (data.config.star or 0) then
            self:InitRoomGo(v)
            self.m_unsatisfiedStarRooms[k] = nil
        elseif data then
            self:InitRoomGoUIView(data)
        end
    end
end

function FloorScene:GetManagerMode()
    local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")
    local data = self:GetRoomRootGoData(roomId) or {}
    if data.employee then
        return data.employee[1]
    end
    -- for k, v in pairs(data.furniture or {}) do
    --     if v.id == 10022 then
    --         return data.employee[k]
    --     end
    -- end
end

function FloorScene:GetAZhenMode()
    local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")
    local data = self:GetRoomRootGoData(roomId) or {}

    local index = nil

    for k,v in pairs(data.employee) do--还有其他方法吗
        if v.m_prefab == "Assets/Res/Prefabs/character/Secretary_001.prefab" then
            return data.employee[k]
        end
    end
end

function FloorScene:ActiveTimeLine(currScene)
    if currScene then
        local starCEOGuide
        --K133 CEO版本引导
        if currScene == 200 then
            starCEOGuide = function()
                if not CEODataManager:GetGuideTriggered() then
                    GameTableDefine.ResourceManger:AddDiamond(20, nil, function()
                        CEODataManager:SetGuideTriggered()
                        GuideManager.currStep = 2100
                        GuideManager:ConditionToStart()
                        --给10把钥匙
                        CEODataManager:AddCEOKey("normal",10,true)
                    end, true)
                end
            end
        end
        self:InitGuideTimeLine("CutsceneTimeline_" .. currScene,starCEOGuide)
    end
end

---是否正在TimeLine中
function FloorScene:IsPlayingTimeLine()
    return self.m_GuideTimeGo and true or false
end

function FloorScene:InitGuideTimeLine(timelineName,cb_OnEnd)
    MainUI:GuideTimeUIState()
    -- EventManager:RegEvent("CMD_OPENING_SCENE_DIALOG", function(go, args)
    --     self.m_dialogId = tonumber(args[1])
    --     self:CheckGuideTimelineDialog(0)
    --     GameTimer:CreateNewMilliSecTimer(200, function() -- 防止界面没有完全打开点穿动画
    --         GameUIManager:SetEnableTouch(true)
    --     end)
    -- end)
    EventManager:RegEvent("START_TALK", function(go, args)
        GameSDKs:TrackForeign("opening_timeline", {type = 2, keyframe = "START_TALK", extend_param = tostring(args[1])})
        TalkUI:OpenTalk("cutscene" .. tonumber(args[1]), {bossName = LocalDataManager:GetBossName()}, function()
            GameUIManager:SetEnableTouch(false)
            UnityHelper.PlayTimeLine(self.m_GuideTimeLine)
            if self.m_GuideTimeLine then
                self.m_GuideTimeLine:Play()
            end
            -- GameSDKs:TrackForeign("opening_timeline",{start_state = "success", end_state = "failed"})
        end, function()
            GameUIManager:SetEnableTouch(true)
            -- GameSDKs:TrackForeign("opening_timeline",{start_state = "failed", end_state = "success"})
        end, self.m_GuideTimeGo)
    end)

    EventManager:RegEvent("EVENT_BUILDING_NAME", function(go)
        GameSDKs:TrackForeign("opening_timeline", {type = 2, keyframe = "EVENT_BUILDING_NAME"})
        BenameUI:BuildingName()
        GameTimer:CreateNewMilliSecTimer(200, function() -- 防止界面没有完全打开点穿动画
            GameUIManager:SetEnableTouch(true)
        end)
    end)

    EventManager:RegEvent("EVENT_GUIDE_TIMELINE_END", function(go)
        --2025-02-07 wy 场景解锁，等timeline结束再进行活动条件检查，否则弹窗会与timeline重叠
        GameTableDefine.ActivityRemoteConfigManager:CheckActivityCondition()
        
        GameSDKs:TrackForeign("opening_timeline", {type = 2, keyframe = "EVENT_GUIDE_TIMELINE_END"})
        GameUIManager:SetEnableTouch(true)
        GameObject.Destroy(self.m_GuideTimeGo)
        self.m_GuideTimeGo = nil
        self.m_GuideTimeLine = nil
        local roomId = FloorMode:GetRoomIdByRoomIndex("ManagerRoom_104")
        local data = self:GetRoomRootGoData(roomId) or {}
        self:InitFurnitures(data)
        UnityHelper.RemoveCameraFromCameraStack(GameUIManager:GetSceneCamera(), self.m_storyCamera)
        --GuideManager:SetTimeLineDialogCompleteHander(nil)
        GuideManager.timeLineDone = true
        --GuideManager:ConditionToEnd()
        MainUI:GuideTimeUIState(true)
        
        IntroduceUI:SceneNeed()
        --从新播放场景BGM
        SoundEngine:UnCatchAndStopSceneBGM()
        LocalDataManager:WriteToFileInmmediately()
        if cb_OnEnd then
            cb_OnEnd()
        end
    end)

    EventManager:RegEvent("EVENT_OPENING2", function(go)
        GameSDKs:TrackForeign("opening_timeline", {type = 2, keyframe = "EVENT_OPENING2"})
    end)
    self.m_GuideTimeLine = -1
    GameResMgr:AInstantiateObjectAsyncManual("Assets/Res/Prefabs/Timeline/" .. timelineName .. ".prefab", self, function(childGo)
        --childGo.transform.position = Vector3.zero
        --缓存并暂停当前BGM
        --SoundEngine:CatchAndStopSceneBGM()
        local skinGo = self:GetGo(childGo, "People/Boss/"..LocalDataManager:GetBossSkin())
        skinGo:SetActive(true)
        --2022-12-9 timeline播放和装扮系统整合的功能
        GameTableDefine.DressUpDataManager:ChangeTimelineActorDressUp(childGo)
        self.m_GuideTimeGo = childGo
        self.m_GuideTimeLine = childGo:GetComponent("PlayableDirector")
        self.m_storyCamera = UnityHelper.GetTheChildComponent(childGo, "CameraCG", "Camera")
        if self.m_storyCamera then
            UnityHelper.SetCameraRenderType(self.m_storyCamera, 1)
            UnityHelper.AddCameraToCameraStack(GameUIManager:GetSceneCamera(), self.m_storyCamera, 0)
        end
        GameUIManager:SetEnableTouch(false)
    end)
    -- GuideManager:SetTimeLineDialogCompleteHander(function(v)
    --     self:CheckGuideTimelineDialog(v)
    -- end)
end

-- function FloorScene:CheckGuideTimelineDialog(v)
--     if not self.m_dialogId then
--         return
--     end
--     self.m_dialogId =  self.m_dialogId + v
--     if ConfigMgr.config_guide[self.m_dialogId] then
--         GuideUI:Show(ConfigMgr.config_guide[self.m_dialogId])
--     else
--         GuideUI:CloseView()
--         if not self.m_GuideTimeLine or self.m_GuideTimeLine == -1 then
--             return
--         end
--         UnityHelper.PlayTimeLine(self.m_GuideTimeLine)
--         self.m_GuideTimeLine:Play()
--         GameUIManager:SetEnableTouch(false)
--     end
-- end

function FloorScene:BenameFinish(name)
    if self.m_GuideTimeLine or self.m_GuideTimeLine == -1 then
        UnityHelper.PlayTimeLine(self.m_GuideTimeLine)
        self.m_GuideTimeLine:Play()
        GameUIManager:SetEnableTouch(false)
    end
    LocalDataManager:SaveBuildingName(name)

    local renameBlock = GameObject.Find("GongSiZhaoPai_1").gameObject
    local currLanguage = GameLanguage:GetCurrentLanguageID()
    local isCrosswiseName = currLanguage == "cn" or currLanguage == "tc"
    self:GetGo(renameBlock, "Name"):SetActive(isCrosswiseName)
    self:GetGo(renameBlock, "Name_en"):SetActive(not isCrosswiseName)
    if not isCrosswiseName then
        UIView:SetText(renameBlock, "Name_en", LocalDataManager:GetBuildingName() or "", nil, nil, true)
    else
        UIView:SetText(renameBlock, "Name", LocalDataManager:GetBuildingName() or "", nil, nil, true)
    end
end

function FloorScene:SetRoom3dHintVisible(roomId, flag, visible)
    if nil == visible then
        return
    end

    local room = self.roomRootGo[roomId] or {}
    local roomGo = room.go
    if not room.go or room.go:IsNull() then
        return
    end
    if flag == self.FLAG_DARK_OFFDUTY then
        self:GetGo(roomGo, "offduty"):SetActive(visible)
    elseif flag == self.FLAG_DARK_LOCKED then
        self.roomRootGo[roomId].locked:SetActive(visible)
    elseif flag == self.FLAG_DARK_START then
        self.roomRootGo[roomId].locked:SetActive(visible)
        self:GetGo(roomGo, "locked/SuoTou"):SetActive(false)
    end

    local oldFlag = room.drakFlag
    if visible then
        room.drakFlag = UnityHelper.AddFlag(room.drakFlag, 1 << flag)
    else
        room.drakFlag = UnityHelper.RemoveFlag(room.drakFlag, 1 << flag)
    end
    -- print("SetRoom3dHintVisible------------>", roomGo.name, flag, visible, oldFlag, room.drakFlag)
    -- 2024-4-12 12:26:35 gxy 去掉DarkState相关功能 
    --if (oldFlag == 0 and room.drakFlag ~= 0) or (oldFlag ~= 0 and room.drakFlag == 0) then
    --    self:GetGo(roomGo, "DarkState"):SetActive(room.drakFlag ~= 0)
    --end
end

function FloorScene:CreateSpecialHouse(id, cb)
    if not id then return end
    local cfg = ConfigMgr.config_buildings[id]
    if not cfg then return end

    local path = "Assets/Res/Prefabs/Buildings/" .. cfg.mode_name .. ".prefab"
    GameResMgr:AInstantiateObjectAsyncManual(path, self, function(go)
        -- UnityHelper.AddChildToParent(GameObject.Find("House").transform, go.transform)
        self.m_speciaBuildingGo = go
        self.m_speciaBuildingCfg = cfg

        local bc = self:GetComp(go, "MoveBounds", "BoxCollider") -- go:GetComponent("BoxCollider")
        local lookAt = self:GetTrans(go, "CameraLocation")
        -- 2022-12-9添加用于timelie整合换装的功能实现
        GameTableDefine.DressUpDataManager:ChangeTimelineActorDressUp(go)
        self:SetCameraCapsule(lookAt.position, function()
            --如果是进入汽车商城的界面
            if cb then cb() end

            --K117 老建筑开启相机后处理
            FloorMode:ResetPostProcessing(id)

            if FloorMode:IsInCarShop() then
                self:EnterCarshop(go, id)
            elseif FloorMode:IsInFactory() then
                FactoryMode:OnEnter(cfg, go)
                MainUI:UpdateHint()
                self:ControlGlobalVolumeDisp(true)
            elseif FloorMode:IsInFootballClub() then
                --足球俱乐部入口
                FootballClubModel:Init(cfg, go)
                --俱乐部实时计算
                FootballClubModel:CalculateFCData()
                FootballClubModel:OnEnter()
                --self:ControlGlobalVolumeDisp(true)
            else
                HouseMode:OnEnter(cfg, go)
            end
        end, bc)
    end)
end

function FloorScene:LeaveSpecialBuilding(cb)
    if not self.m_speciaBuildingGo or self.m_speciaBuildingGo:IsNull() then
        return
    end

    local bc = GameObject.Find("MoveBounds"):GetComponent("BoxCollider")
    self:SetCameraCapsule(bc.transform.position, cb, bc)
    --K117 老建筑开启相机后处理
    FloorMode:ResetPostProcessing()
    --K117 汽车商店出来恢复Light todo 汽车商店改为UI界面了
    if self.currShopId then
        local lightGO = self:GetCarShopLight(self.m_speciaBuildingGo)
        if lightGO then
            GameTableDefine.LightManager:SetBuildingLight(nil)
        end
    end
    GameObject.Destroy(self.m_speciaBuildingGo)
    self.m_speciaBuildingGo = nil
    --if self.carGo then
    --    for k,v in pairs(self.carGo) do
    --        if v.view then
    --            FloatUI:RemoveObjectCrossCamera(v)
    --        end
    --    end
    --end
    --self.carGo = nil
    self.currShopId = nil
    if FloorMode:IsInHouse() then
        HouseMode:OnExit()
    elseif FloorMode:IsInFactory() then
        FactoryMode:OnExit()
    else
        CompanyMode:ManagerLeaveSpecialBuilding()
    end
    MainUI:SetFloorIndex(FloorMode:GetCurrentFloorIndex(), FloorMode)
    self:ControlGlobalVolumeDisp(not self:IsProcessDayNightScene())
end

function FloorScene:LeaveCarShop(cb)
    local bc = GameObject.Find("MoveBounds"):GetComponent("BoxCollider")
    self:SetCameraCapsule(bc.transform.position, cb, bc)
    local bossCar = Bus:GetCarEntity(BuyCarManager:GetDrivingCar())
    bossCar:AddFlag(ActorDefine.Flag.FLAG_CAMERA_FOLLOW_CAR)
    MainUI:SetFloorIndex(FloorMode:GetCurrentFloorIndex(), FloorMode)
    self:ControlGlobalVolumeDisp(not self:IsProcessDayNightScene())
end

function FloorScene:LocateSpecialBuildingTarget(targetPosition)
    if not targetPosition or not self.capsuleGO or self.capsuleGO:IsNull() then
        return
    end

    local endTarget = MainUI:GetView():GetTrans("IndoorScale")
    if endTarget and not endTarget:IsNull() then
        local succ, position = self:GetSceneGroundPosition(endTarget.position)
        self:LocatePosition(self.capsuleGO.transform.position - (position - targetPosition), true)
    end
end

--carshop
function FloorScene:EnterCarshop(root, id)
    local data = ConfigMgr.config_carshop[id]
    local cfgCar = ConfigMgr.config_car

    self.currShopId = id

    --K117 进入汽车商店后，去掉Open Tip
    CityMode:MarkComeToBuilding(id)

    TalkUI:OpenTalk("enter_carshop", 
    {firstCome = BuyCarManager:FirstCome(id),
    placeName = GameTextLoader:ReadText("TXT_BUILDING_B"..id.."_NAME"),
    carHold = self:GetTrans(root, "GuideLocation")})

    local allCar = data.cars
    local carData = {}
    for k,v in pairs(allCar) do
        table.insert(carData, v)
    end

    table.sort(carData, function(a,b)
        return a.id < b.id
    end)

    local carRoot = self:GetGo(root, "Cars")
    -- local lookAt = self:GetGo(root, "CameraLocation")
    local ground = self:GetGo(root, "GuideLocation")

    local player = self:GetGo(root, "Boss/"..LocalDataManager:GetBossSkin())
    player:SetActive(true)

    self:SetButtonClickHandler(ground, function()
        self:ResetChooseCar()
    end)
    
    -- self:LocatePosition(lookAt.transform.position)

    -- self.carTimeLine = self:GetComp(root, "TimeLine", "PlayableDirector")
    local childNum = carRoot.transform.childCount
    -- for index,v in pairs(carData) do
    --     local currRoot = self:GetGo(carRoot, "pos"..index)
    --     self:InitCar(currRoot, v)
    -- end
    for k = 1, childNum do
        local currRoot = self:GetGo(carRoot, "pos"..k)
        self:InitCar(currRoot, carData[k])
    end

    self:SetCarAnimation()
    --K117
    local lightGO = self:GetCarShopLight(root)
    if lightGO then
        FloorMode:GetScene():ControlGlobalVolumeDisp(false)

        GameTableDefine.LightManager:SetBuildingLight(lightGO)
    end
end

function FloorScene:InitCar(carRoot, car)
    carRoot:SetActive(car ~= nil)
    if not car then
        return
    end

    local data = {id = car.id, num = car.num, price = car.price}
    local carData = ConfigMgr.config_car[data.id]
    data["value"] = carData.wealth_buff

    local root = self:GetTrans(carRoot, "car")
    if not BuyCarManager:CheckShopExit(data.id, self.currShopId) then
        --库存不足
        return
    end

    local bindClick = function()
        self:ResetChooseCar(data.id)
        --self:LocateSpecialBuildingTarget(self.carGo[data.id].go.transform.position)
    end

    local buyCar = function(check)
        local result = BuyCarManager:Buy(data.id, self.currShopId, true)

        if check then
            return result == 1 or result == -2--有钱就可以点击
        end

        if result == -2 then
            TalkUI:OpenTalk("car_lackPlace", { noHouse = HouseMode:noHouse()})
            return
        end

        GameUIManager:SetEnableTouch(false)

        MainUI:Hideing(false)
        ForbesRewardUI:SetCfg(carData)

        BuyCarManager:Buy(data.id, self.currShopId)
        self.carGo[data.id].set("buy")
        TweenUtil.PlayDoPath(root.gameObject, "", "stop_car_wheel", "", data.id .. "")

        self:SetCameraFollowGo(root.gameObject)
        self:ResetChooseCar(nil)
        BuyCarManager:GetDrivingCar(car.id)
        CompanyMode:ManagerOnSpecialBuilding("bid")
    end

    self.carGo = self.carGo or {}
    self.carGo[data.id] = {}
    self.carGo[data.id].go = carRoot
    self.carGo[data.id].carState = 0 --0表示起始 1表示终点 2表示红毯
    self.carGo[data.id].name = carData.pfb
    self.carGo[data.id].set = nil--设置汽车及车辆状态的方法, 包括 buy(购买),show(点击),hide(非点击)

    local path = "Assets/Res/Prefabs/Vehicles/"
    GameResMgr:AInstantiateObjectAsyncManual(path .. carData.pfb ..".prefab", self, function(go)
        UnityHelper.AddChildToParent(root, go.transform)
        go.name = carData.pfb
        FloatUI:SetObjectCrossCamera(self.carGo[data.id], function(view)
            if view then
                --self.carGo[data.id].view:Invoke("InitBuyCar", data, buyCar)
                view:Invoke("InitBuyCar", data, buyCar)
            end
        end, nil, carData.pfb.."/car", false)

        self:SetButtonClickHandler(carRoot, bindClick)
    end)
end

function FloorScene:AfterBuyCar()
    local driveBack = function()--回到办公场景,如果还在上班,则开车回去
        FloorMode:ExitSpecialBuilding(nil, true)
    end
    GameUIManager:SetEnableTouch(true)

    --if GameConfig.IsIAP() then
        ForbesRewardUI:OpenSimple(function()
            IntroduceUI:ValueImprove(function()
                TalkUI:OpenTalk("car_bought", nil, driveBack)
            end)
        end)
    -- else
    --     driveBack()
    -- end
end

function FloorScene:SetCarWheelAni(carId, play, playBack)
    if not self.carGo[carId] then
        return
    end

    local aniWheel = self:GetComp(self.carGo[carId].go, "car/" .. self.carGo[carId].name, "Animation")
    if play then
        if not playBack then
            AnimationUtil.Play(aniWheel, "Car_wheel", nil)
        else
            AnimationUtil.Play(aniWheel, "Car_wheel", nil, -1, "ANI_END")
        end
    else
        AnimationUtil.GotoAndStop(aniWheel, "Car_wheel")
    end
end

function FloorScene:SetCarAnimation()
    local forwardSpeed = 1 --汽车前进速度
    local backSpeed = -0.3--汽车回退的速度

    for k,v in pairs(self.carGo or {}) do

        local aniCar = self:GetComp(v.go, "", "Animation")
        local aniWheel = self:GetComp(v.go, "car/".. v.name, "Animation")
        v.aniCar = aniCar
        v.aniWheel = aniWheel
        
        v.set = function(setState)--一种状态机,控制车和车轮的移动 0表示起始 1表示终点 2表示红毯
            if not v.aniWheel then
                v.aniWheel = self:GetComp(v.go, "car/" .. v.name, "Animation")
            end
            
            if setState == "show" then
                if v.carState == 0 then
                    self:LocateSpecialBuildingTarget(v.go.transform.position)

                    v.carState = 3
                    AnimationUtil.Play(v.aniCar, "Car_showoff", function()
                        if v.carState == 3 then
                            v.carState = 1
                            AnimationUtil.GotoAndStop(v.aniWheel, "Car_wheel")
                        end
                    end, forwardSpeed)

                    if v.view then
                        v.view:Invoke("ShowInfo", k, self.currShopId)
                    end
    
                    AnimationUtil.Play(v.aniWheel, "Car_wheel")
                elseif v.carState == 1 then
                    v.carState = 4
                    AnimationUtil.Play(v.aniCar, "Car_showoff", function()
                        if v.carState == 4 then
                            v.carState = 0
                            AnimationUtil.GotoAndStop(v.aniWheel, "Car_wheel")
                        end
                    end, backSpeed, "ANI_END")

                    if v.view then
                        v.view:Invoke("ResetBuyCar")
                    end

                    AnimationUtil.Play(v.aniWheel, "Car_wheel", nil, -1, "ANI_END")
                end
            elseif setState == "hide" then
                if v.carState == 1 or v.carState == 3 then
                    v.carState = 4
                    AnimationUtil.Play(v.aniCar, "Car_showoff", function()
                        if v.carState == 4 then
                            v.carState = 0
                            AnimationUtil.GotoAndStop(v.aniWheel, "Car_wheel")
                        end
                    end, backSpeed, "ANI_END")

                    if v.view then
                        v.view:Invoke("ResetBuyCar")
                    end
    
                    AnimationUtil.Play(v.aniWheel, "Car_wheel", nil, -1, "ANI_END")
                end
            elseif setState == "buy" then
                v.carState = 5
                AnimationUtil.Play(v.aniWheel, "Car_wheel")

                if v.view then
                    v.view:Invoke("ResetBuyCar")
                end
            end
        end
    end
end

function FloorScene:ResetChooseCar(carId)
    for k,v in pairs(self.carGo or {}) do
        if k ~= carId then
            v.set("hide")
        else
            v.set("show")
        end
    end
end

function FloorScene:GetOnePlace()--宠物随机获取一个位置
    local data = self.roomRootGo
    local totalNum = {}
    for k,v in pairs(data or {}) do
        if FloorMode:IsUnlockRoomById(k) then
            if v.config.category[2] ~= 4 and v.config.category[2] ~= 5 then
                table.insert(totalNum, k)
            end
        end
    end

    local choose = math.random(1, #totalNum)
    local roomId = totalNum[choose]
    local roomChoose = data[roomId].go.transform.position
    roomChoose.x = roomChoose.x + math.random(-9,9)
    roomChoose.z = roomChoose.z + math.random(-9,9)
    return roomChoose
end
--进来时检查一次是否需要开启工厂新手引导
function FloorScene:CheckIfNeededFactoryGuide(bool)
    local FactoryNpc = GameObject.Find("Factory_Guide")
    if not FactoryNpc then
        return
    end
    local GuideNpc = self:GetGo(FactoryNpc, "GuideNpc")
    --是否有数据(是否买过)
    local factorydata = LocalDataManager:GetCurrentRecord()["factory"]                        
    local bought = factorydata and factorydata["Factory_1"]
    if not bought and not bool then
        if StarMode:GetStar() >= 100 and CityMode:GetCurrentBuilding() >= 300 then                
            if GuideNpc.activeSelf then
                return
            end
            self:PlayFactoryGuideNpc()       
        end
    else
        MainUI:RefreshFactoryGuideUI(false)                
        GuideNpc:SetActive(false)   
    end 
end
--触发工厂新手引导Npc事件
function FloorScene:PlayFactoryGuideNpc()
    local FactoryNpc = GameObject.Find("Factory_Guide")
    local GuideNpc = self:GetGo(FactoryNpc, "GuideNpc")
    GuideNpc:SetActive(true)
    --DoTween onComplete 事件
    local DoTween = self:GetComp(FactoryNpc, "GuideNpc", "DOTweenPath")    
    DoTween.onComplete:AddListener(function()
        local uglyCode = {}
        uglyCode.go = GuideNpc        
        MainUI:RefreshFactoryGuideUI(true)
        FloatUI:SetObjectCrossCamera(uglyCode, function(view)
            if view then
                view:Invoke("ShowEventBumble",1,function(view)
                    GuideManager.currStep = 500
                    GuideManager:OpenGuideView()
                end)
            end
        end)
    end)
    local feel = self:GetComp(FactoryNpc, "startFB", "MMFeedbacks")
    feel:PlayFeedbacks()
end
--转盘的场景的物体显示的刷新
function FloorScene:RefreshRoulette()
    if self.wheelNode then
        self.wheelNode:SetActive(ConfigMgr.config_global.wheel_switch == 1 and StarMode:GetStar() >= ConfigMgr.config_global.wheel_condition)
    end    
end

---K117 获取汽车上商店的Light节点
function FloorScene:GetCarShopLight(carShopRoot)
    return self:GetGoOrNul(carShopRoot,"Light")
end

EventManager:RegEvent("BUY_CAR_END", function()
    FloorMode:GetScene():SetCameraFollowGo(nil)
    FloorMode:GetScene():AfterBuyCar()
end)
--end carshop
EventManager:RegEvent("stop_car_wheel", function(carId)
    FloorMode:GetScene():SetCarWheelAni(tonumber(carId), false)
end)

--进来时检查一次是否需要开启足球俱乐部新手引导
function FloorScene:CheckIfNeededFootballClubGuide(id)
    --是否有数据(是否买过)
    local FCData = FootballClubModel:CheckFCData(id)       
    local buildingCfg = ConfigMgr.config_buildings[id]             
    if not FCData then
        --if StarMode:GetStar() >= buildingCfg.starNeed and not CityMode:IsHaveBuilding(id) then
        if StarMode:GetStar() >= buildingCfg.starNeed and CityMode:GetCurrentBuilding() >= 700 then
            if not FootballClubModel:GetUnlockFCData() then
                self:PlayFootballClubGuide()       
            end
        end
    end 
end

function FloorScene:CloseFootballClubGuideEntrance()
    MainUI:RefreshFootballClubGuideUI(false)                
    local FactoryNpc = GameObject.Find("FBClub_Guide")
    if FactoryNpc then
        local GuideNpc = self:GetGo(FactoryNpc, "GuideNpc")
        GuideNpc:SetActive(false)
        ActorManager:OutActorChange(GuideNpc, false)
    end

end

--触发足球俱乐部新手引导事件
function FloorScene:PlayFootballClubGuide()
    local FBClubNpc = GameObject.Find("FBClub_Guide")
    local GuideNpc = self:GetGo(FBClubNpc, "GuideNpc")
    GuideNpc:SetActive(true)
    ActorManager:OutActorChange(GuideNpc, true)
    --DoTween onComplete 事件
    local DoTween = self:GetComp(FBClubNpc, "GuideNpc", "DOTweenPath")    
    DoTween.onComplete:AddListener(function()
        local uglyCode = {}
        uglyCode.go = GuideNpc        
        MainUI:RefreshFootballClubGuideUI(true)
        FloatUI:SetObjectCrossCamera(uglyCode, function(view)
            if view then
                view:Invoke("AZhenTalk",function(view)
                    GuideManager.currStep = 20001
                    GuideManager:OpenGuideView()
                end)
            end
        end)
    end)
    local feel = self:GetComp(FBClubNpc, "startFB", "MMFeedbacks")
    feel:PlayFeedbacks()
end

function FloorScene:GetCurBossEntity()
    return self.bossActorEntity
end

function FloorScene:GetCurSecretaryEntity()
    return self.secretaryEntity
end

function FloorScene:SceneSwtichDayOrLight(isDay)
    if self.m_vfxDayGo then
        self.m_vfxDayGo:SetActive(isDay)
    end
    if self.m_vfxNightGo then
        self.m_vfxNightGo:SetActive(not isDay)
    end 
    -- UnityHelper.SetGameObejctsActiveByTag("TAG_NIGHT_OBJ", not isDay)
    for name, go in pairs(self.m_nightGos or {}) do
        go:SetActive(not isDay)
    end
    for name, go in pairs(self.m_dayGos or {}) do
        go:SetActive(isDay)
    end

end

function FloorScene:SetSceneWheelNum(num)
    if self.m_WheelTxtGo then
        UIView:SetText(self.m_WheelTxtGo.gameObject, "txt", num, nil, nil, true)
    end
end

--[[
    @desc: 返回是不是需要处理室内外光照的接口，通过场景中是否有室内外的trigger来判断
    author:{author}
    time:2023-09-05 15:59:36
    @return:
]]
function FloorScene:IsProcessDayNightScene()
    return self.m_ConstructTriggerGo ~= nil
end

function FloorScene:ControlGlobalVolumeDisp(isDips)
    local isOpen = isDips
    if self.m_GlobalVolumeGo then
        self.m_GlobalVolumeGo:SetActive(isOpen)
    end
end

function FloorScene:PlayRoomBrokenVFX(roomID, isPlay)
    local vfx = self.roomRootGo[roomID].VFX_fault
    if vfx then
        vfx:SetActive(isPlay)
    end
    if self.roomRootGo[roomID].PowerOff then
        self.roomRootGo[roomID].PowerOff:SetActive(isPlay)
    end
end

---region CEO系统



---@param roomRootData RoomRootData
function FloorScene:InitCEOFurniture(roomRootData)
    local defaultCeoFurnitureID = roomRootData.config.ceo_workspace
    --local roomIndex = roomRootData.config.room_index
    local localData = FloorMode:GetCurrRoomLocalData(roomRootData.config.room_index)
    local roomGo = roomRootData.go

    if not localData.unlock or not defaultCeoFurnitureID then
        return
    end

    --存档中添加CEO家具数据
    if not localData.ceoFurnitureInfo then
        localData.ceoFurnitureInfo = {level = 0}
    end

    --local isRoomExist = CompanyMode:CompanyExist(roomIndex)
    --local ceoFurnitureID = defaultCeoFurnitureID
    --local ceoFurLevelConfig = ConfigMgr.config_ceo_furniture_level[ceoFurnitureID]
    local furniturePositionGo = self:GetTrans(roomGo, "CeoWorkspace_1")
    if furniturePositionGo then
        furniturePositionGo = furniturePositionGo.gameObject
        local furnitureInfo = localData.ceoFurnitureInfo
        if not furnitureInfo.level then
            furnitureInfo.level = 0
        end
        if furnitureInfo.level > 0 then
            self:InstantiateCEOFurniture(roomRootData, localData, furniturePositionGo)
            local ceoID = furnitureInfo.ceoID
            if ceoID and not roomRootData.ceoActor then
                self:CreateCEOActor(roomRootData, localData, furniturePositionGo)
            end
        else
            for k,v in pairs(furniturePositionGo.transform or {}) do
                self:RecycleFurnitureToBuff(v.gameObject)
            end
        end
    end
end

---@param roomRootData RoomRootData
function FloorScene:InstantiateCEOFurniture(roomRootData, localData, furniturePositionGo)
    local furLevelID = roomRootData.config.ceo_workspace - 1 + localData.ceoFurnitureInfo.level
    if furLevelID <= 0 then
        return
    end
    for k,v in pairs(furniturePositionGo.transform or {}) do
        self:RecycleFurnitureToBuff(v.gameObject)
    end

    local prefabName = ConfigMgr.config_ceo_furniture_level[furLevelID].table_prefab
    local childTrans = self:GetTrans(furniturePositionGo, prefabName)
    if childTrans then
        roomRootData.ceoFurnituresGo = childTrans.gameObject
        --self:MarkFurnitureLoadCallback(furniturePositionGo, childTrans.gameObject)
        return
    end

    roomRootData.ceoFurnituresGo = -1
    self:GetFurnitureFromBuff(prefabName, function(childGo)
        UnityHelper.AddChildToParent(furniturePositionGo.transform, childGo.transform)
        roomRootData.ceoFurnituresGo = childGo
        local go = self:GetGoOrNul(roomRootData.go, "struct/DiTan")
        if go then
            UnityHelper.IgnoreRendererByObject(go, childGo)
        end
    end)
end

---@param roomRootData RoomRootData
function FloorScene:CreateCEOActor(roomRootData, localData, furniturePositionGo)
    if roomRootData.ceoActor then
        return
    end

    if roomRootData.loadingCEO then
        return
    else
        roomRootData.loadingCEO = true
    end

    local tans = self:GetTrans(furniturePositionGo, "workPos")
    if not tans then
        self:RegisterFurnitureLoadCallback(furniturePositionGo, function()
            self:CreateCEOGO( roomRootData, localData, furniturePositionGo)
            roomRootData.loadingCEO = false
        end)
    else
        self:CreateCEOGO(roomRootData, localData, furniturePositionGo)
        roomRootData.loadingCEO = false
    end
end

---@param roomRootData RoomRootData
function FloorScene:CreateCEOGO(roomRootData, localData, furniturePositionGo)

    if roomRootData.ceoActor then
        return
    end

    local tans = self:GetTrans(furniturePositionGo, "workPos")
    if not tans then
        return
    end

    local ceoID = localData.ceoFurnitureInfo.ceoID
    local ceoConfig = ConfigMgr.config_ceo[ceoID]

    local employee_skin = "Assets/Res/Prefabs/character/" .. ceoConfig.ceo_prefab .. ".prefab"

    local targetPos = self:GetTrans(furniturePositionGo, "workPos").position
    local initPos = self:GetRandomPosition()
    local targetDir = self:GetTrans(furniturePositionGo, "face").position
    local rootGo = self.m_personRoot[1] --isOnOffice and self.m_personRoot[(roomRootData.floorNumberIndex or 0) + 1] or self.m_personRoot[1]

    local employee = CEOActor:CreateActor()
    roomRootData.ceoActor = employee
    employee:Init(rootGo, employee_skin, initPos, targetPos, targetDir, roomRootData)

    if roomRootData.isWork == false then
        employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_OFF_WORKING)
    else
        employee:AddFlag(ActorDefine.Flag.FLAG_EMPLOYEE_ON_WORKING)
    end
end

function FloorScene:OnCEOActorChanged(roomIndex, countryId)
    local localData = FloorMode:GetRoomLocalData(roomIndex, countryId)
    local isCurCountry = true
    if countryId and CountryMode:GetCurrCountry() ~= countryId then
        isCurCountry = false
    end
    if isCurCountry then
        local roomID = FloorMode:GetRoomIdByRoomIndex(roomIndex)
        local roomRootData = self:GetRoomRootGoData(roomID)

        if roomRootData.ceoActor then
            roomRootData.ceoActor:Destroy()
            roomRootData.ceoActor = nil
        end
        --刷新房间CEO桌子的3D Icons
        if roomRootData.ceoBoxFloatUI then
            if roomRootData.ceoBoxFloatUI.view then
                roomRootData.ceoBoxFloatUI.view:Invoke("ShowRoomCEOInfo",roomIndex)
            end
        end
        if localData.ceoFurnitureInfo.ceoID then
            local roomGo = roomRootData.go
            local ceoFurnitureID = localData.ceoFurnitureInfo.level
            local ceoFurLevelConfig = ConfigMgr.config_ceo_furniture_level[ceoFurnitureID]
            local furniturePositionGo = self:GetGo(roomGo, ceoFurLevelConfig.table_prefab)
            self:CreateCEOActor(roomRootData, localData, furniturePositionGo)
        end
    end
end

---引导开启后显示所有CEO的3DIcon
function FloorScene:ShowAllCEO3DIcons()
    for roomID,roomRootData in pairs(self.roomRootGo)  do
        if roomRootData.ceoBoxFloatUI then
            if roomRootData.ceoBoxFloatUI.view then
                roomRootData.ceoBoxFloatUI.view:Invoke("ShowRoomCEOInfo",roomRootData.config.room_index)
            end
        end
    end
end

---endregion

---占用某房间的FloatUI,成功返回True,失败返回False
function FloorScene:UseRoomFloatUI(roomIndex)
    if not self.m_companyFloatUIInfo then
        self.m_companyFloatUIInfo = {}
    end
    local floatUIInfo = self.m_companyFloatUIInfo[roomIndex]
    if not floatUIInfo then
        floatUIInfo = {}
        self.m_companyFloatUIInfo[roomIndex] = floatUIInfo
    end
    local now = TimerMgr:GetCurLocalTime(true)
    for i = 1, AllowedCompanyFloatUICount do
        --过期时间
        if not floatUIInfo[i] or floatUIInfo[i] < now then
            floatUIInfo[i] = now + 4
            return true
        end
    end
    return false
end

return FloorScene

