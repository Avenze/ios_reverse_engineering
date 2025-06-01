---@class LightManager
local LightManager = GameTableDefine.LightManager
local GameClockManager = GameTableDefine.GameClockManager
local InstanceModel = GameTableDefine.InstanceModel
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local ActorEventManger = GameTableDefine.ActorEventManger
local FloorMode = GameTableDefine.FloorMode
local FootballClubScene = GameTableDefine.FootballClubScene
local FootballClubModel = GameTableDefine.FootballClubModel

local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper;
local ActorManager = require("CodeRefactoring.Actor.ActorManager")

function LightManager:Init()
    if not self.lightControl or self.lightControl:IsNull() then
        local lightGO = UnityHelper.FindRootGameObject("Light")
        self.lightControl = UnityHelper.GetObjComponent(lightGO, "LightColorControl")
    end
    self.currProgress = 0
    self.isDay = false
    if GameStateManager.m_currentGameState ~= GameStateManager.GAME_STATE_INSTANCE then
        if GameClockManager:IsDay() then
            self.currProgress = 1
            self.isDay = true
        end
    else
        if InstanceModel:IsDay() then
            self.currProgress = 1
            self.isDay = true
        end
    end
    self.lightControl:setMainLight(self.currProgress)
    FloorMode:SceneSwtichDayOrLight(self.isDay)
    InstanceModel:SceneSwtichDayOrLight(self.isDay)
    ActorManager:InitEventReg()
    ActorManager:SceneSwtichDayOrLight(self.isDay)
    -- if not self.matBuilding then
    --     self:InitMat()
    -- end

    -- self:ChangeMat(not self.isDay)
end

function LightManager:SetBuildingLight(buildingLightGO)
    if buildingLightGO then
        self.buildingLightControl = UnityHelper.GetObjComponent(buildingLightGO, "LightColorControl")
        self.buildingLightControl:setMainLight(self.currProgress)
    else
        self.buildingLightControl = nil
    end
end

function LightManager:InitMat()
    --self.matBuilding = GameResMgr:LoadMaterialSyncFree("Assets/Res/Materials/FX_Materials/BuildingMat.mat").Result
    --self.matWallLight = GameResMgr:LoadMaterialSyncFree("Assets/Res/Materials/OfficeBuilding_Materials/LuDeng.mat").Result
    --self.matGreenLight = GameResMgr:LoadMaterialSyncFree("Assets/Res/Materials/FX_Materials/LightPoleMat.mat").Result

    local envi = GameObject.Find("Environment")
    if envi then
        self.buildingRoot = UnityHelper.FindTheChild(envi,"Building")
        self.wallRoot = UnityHelper.FindTheChild(envi,"WallLight")
        self.lightRoot = UnityHelper.FindTheChild(envi,"LightPole")
    end

    if self.buildingRoot then self.buildingRoot = self.buildingRoot.gameObject end
    if self.wallRoot then self.wallRoot = self.wallRoot.gameObject end
    if self.lightRoot then self.lightRoot = self.lightRoot.gameObject end
end

function LightManager:SetEmission(root)
end

function LightManager:ChangeMat(turnOn)
    if not self.buildingRoot or self.buildingRoot:IsNull() then
        self:InitMat()
    end

    UnityHelper.TurnEmission(self.buildingRoot, turnOn)
    UnityHelper.TurnEmission(self.wallRoot, turnOn)
    UnityHelper.TurnEmission(self.lightRoot, turnOn)
    -- if turnOn then
    --     self.matBuilding:EnableKeyword("_EMISSION")
    --     self.matWallLight:EnableKeyword("_EMISSION")
    --     self.matGreenLight:EnableKeyword("_EMISSION")
    -- else
    --     self.matBuilding:DisableKeyword("_EMISSION")
    --     self.matWallLight:DisableKeyword("_EMISSION")
    --     self.matGreenLight:DisableKeyword("_EMISSION")
    -- end
end

function LightManager:UpdateBuildingLight()
    if self.buildingLightControl and not self.buildingLightControl:IsNull() then
        self.buildingLightControl:setMainLight(self.currProgress)
    end
end

function LightManager:DayCome()
    if self.__timer then
        return
    end

    --self:ChangeMat(false)
    
    self.currProgress = 0
    self.isDay = true
    FloorMode:SceneSwtichDayOrLight(self.isDay)
    InstanceModel:SceneSwtichDayOrLight(self.isDay)

    ActorManager:SceneSwtichDayOrLight(self.isDay)
    self.__timer = GameTimer:CreateNewMilliSecTimer(
        100,
        function()

            if not self.lightControl or self.lightControl:IsNull() then
                GameTimer:StopTimer(self.__timer)
                self.__timer = nil
                return
            end

            self.lightControl:setMainLight(self.currProgress)
            --K117
            self:UpdateBuildingLight()
            if FloorMode:IsInFootballClub() and FootballClubModel:IsInitialized() and FootballClubScene then
                if FootballClubScene.SetTreeSharedMaterialAttr and self.currProgress then
                    FootballClubScene:SetTreeSharedMaterialAttr(self.currProgress)
                end
            end
            self.currProgress = self.currProgress + 0.025
            if self.currProgress >= 0.95 then
                self.currProgress = 1
                self.lightControl:setMainLight(self.currProgress)
                --K117
                self:UpdateBuildingLight()
                if FloorMode:IsInFootballClub() and FootballClubModel:IsInitialized() and FootballClubScene then
                    FootballClubScene:SetTreeSharedMaterialAttr(self.currProgress)
                end
                GameTimer:StopTimer(self.__timer)
                self.__timer = nil
            end
        end,
    true)
    if FloorMode:IsInFootballClub() and FootballClubModel:IsInitialized() and FootballClubScene then
        FootballClubScene:SwitchNightPoint(false)
    end
end

function LightManager:NightCome()
    if self.__timer then
        return
    end

    --self:ChangeMat(true)

    self.currProgress = 1
    self.isDay = false
    FloorMode:SceneSwtichDayOrLight(self.isDay)
    InstanceModel:SceneSwtichDayOrLight(self.isDay)

    ActorManager:SceneSwtichDayOrLight(self.isDay)
    self.__timer = GameTimer:CreateNewMilliSecTimer(
        100,
        function()
                if not self.lightControl or self.lightControl:IsNull() then
                    GameTimer:StopTimer(self.__timer)
                    self.__timer = nil
                    return
                end

                self.lightControl:setMainLight(self.currProgress)
                --K117
                self:UpdateBuildingLight()
                if FloorMode:IsInFootballClub() and FootballClubModel:IsInitialized() and FootballClubScene then
                    if FootballClubScene.SetTreeSharedMaterialAttr then
                        FootballClubScene:SetTreeSharedMaterialAttr(self.currProgress)
                    end
                end
                self.currProgress = self.currProgress - 0.025
                if self.currProgress <= 0.05 then
                    self.currProgress = 0
                    self.lightControl:setMainLight(self.currProgress)
                    --K117
                    self:UpdateBuildingLight()
                    if FloorMode:IsInFootballClub() and FootballClubModel:IsInitialized() and FootballClubScene then
                        if FootballClubScene.SetTreeSharedMaterialAttr then
                            FootballClubScene:SetTreeSharedMaterialAttr(self.currProgress)
                        end
                    end
                    GameTimer:StopTimer(self.__timer)
                    self.__timer = nil
                end
        end,
    true)
    if FloorMode:IsInFootballClub() and FootballClubModel:IsInitialized() and FootballClubScene then
        FootballClubScene:SwitchNightPoint(true)
    end
end

function LightManager:IsDayOrNight()
    return self.isDay
end

function LightManager:UseNoShadow()
    self.lightControl:UseNoShadow()
end

function LightManager:UseDefaultShadow()
    self.lightControl:UseDefaultShadow()
end

EventManager:RegEvent("DAY_COME", function()
    if not LightManager.isDay then
        LightManager:DayCome()
    end
end)

EventManager:RegEvent("NIGHT_COME", function()
    if LightManager.isDay then
        LightManager:NightCome()
    end
end)
