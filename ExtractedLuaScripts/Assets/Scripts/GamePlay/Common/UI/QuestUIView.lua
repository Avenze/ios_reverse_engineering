local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local GameObject = CS.UnityEngine.GameObject
local Color = CS.UnityEngine.Color

local GameUIManager = GameTableDefine.GameUIManager
local QuestManager = GameTableDefine.QuestManager
local MainUI = GameTableDefine.MainUI
local ConfigMgr = GameTableDefine.ConfigMgr
local DoubleRewardUI = GameTableDefine.DoubleRewardUI
local FloorMode = GameTableDefine.FloorMode
local SceneUnlockUI = GameTableDefine.SceneUnlockUI
local RoomBuildingUI = GameTableDefine.RoomBuildingUI
local RoomUnlockUI = GameTableDefine.RoomUnlockUI
local ResMgr = GameTableDefine.ResourceManger
local QuestUI = GameTableDefine.QuestUI
local CityMapUI = GameTableDefine.CityMapUI
local ChooseUI = GameTableDefine.ChooseUI

local QuestUIView = Class("QuestUIView", UIView)

local HEAD  = 1 -- head
local MEDIUM_VEDIO = 2 -- medium_vedio
local MEDIUM_DIAMOND = 3 -- medium_diamond
local TAIL = 4 --tail

function QuestUIView:ctor()
    self.super:ctor()
    self.container = {}
end

function QuestUIView:OnEnter()
    print("QuestUIView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
end

function QuestUIView:OnPause()
    print("QuestUIView:OnPause")
end

function QuestUIView:OnResume()
    print("QuestUIView:OnResume")
end

function QuestUIView:OnExit()
    self.super:OnExit(self)
    print("QuestUIView:OnExit")
end

function QuestUIView:QuestGoto(id, check)
    local data = ConfigMgr.config_task[id]
    if not data then
        return false
    end

    if check then
        if GameStateManager:IsInCity() then
            return false
        end
        if data.detail_facility or data.detail_employee or
            data.room_index_num or data.building_target then
                return true
        elseif data.target_facility or data.target_employee then
            if data.goal_room and data.goal_facility then
                return true
            else
                return false
            end
        end
        
        return false
    end


    local openView = function(room_index, buildingId, buildingLevel)
        --目前只有目标设施,员工需要配置,如果复杂起来,情况就会包括
        --单独的房间,房间加设施,单独的其他.到时具体情况再修改嘛

        local openRoom = function(roomId)
            local state = FloorMode:GetScene():RoomUnlockAble(roomId)
            if state == 2 then--房间解锁中
                EventManager:DispatchEvent("UI_NOTE",GameTextLoader:ReadText("TXT_TIP_WAIT_ROOM"))
            elseif state == 3 then--房间不满足解锁条件
                EventManager:DispatchEvent("UI_NOTE",GameTextLoader:ReadText("TXT_TIP_LACK_ROOM"))
            elseif state == 4 then--星级不足
                EventManager:DispatchEvent("UI_NOTE",GameTextLoader:ReadText("TXT_TIP_LACK_FAME"))
            else--可以打开房间
                RoomUnlockUI:Show(ConfigMgr.config_rooms[roomId])
            end

            return state
        end

        if buildingId == nil then--解锁某一个房间
            local roomId = FloorMode:GetRoomIdByRoomIndex(room_index)
            --同时也将镜头移向相应房间
            FloorMode:GetScene():lookAtRoom(roomId)
            openRoom(roomId)
            return
        end

        --如果房间是数组
        --从房间数组里面寻找一个解锁的房间,并打开该房间的设施界面
        --如果一个都没有,则尝试引导解锁第一个房间

        --如果房间只是单独的配置
        if type(room_index) == "string" then
            local roomId = FloorMode:GetRoomIdByRoomIndex(room_index)
            if not roomId then
                EventManager:DispatchEvent("UI_NOTE",GameTextLoader:ReadText("TXT_TIP_LACK_BUILDING"))
                return
            end
            local state = openRoom(roomId)
            if state == 1 then
                if FloorMode:FurnitureUnlocakable({room_index}, buildingId, buildingLevel) then
                    -- local roomData = FloorMode:GetCurrRoomLocalData(room_index)
                    local roomData = ConfigMgr.config_rooms[roomId]
                    -- local roomGo = FloorMode:GetScene():GetRoomRootGoData(roomId)
                    -- FloorMode:SetCurrentFloorIndex(roomGo.floorNumberIndex)
                    -- FloorMode:SetCurrRoomInfo(roomData.room_index, roomData.id)
                    -- RoomBuildingUI:ShowRoomPanelInfo(roomId)
                    -- RoomBuildingUI:ChooseOne(buildingId, buildingLevel)
                    FloorMode:GetScene():ShowFloorRoom(roomData.id)
                    --RoomBuildingUI:ChooseOne(buildingId, buildingLevel)
                else
                    EventManager:DispatchEvent("UI_NOTE",GameTextLoader:ReadText("TXT_TIP_LACK_BUILDING"))
                end
                --如果有满足条件的设施,打开
                    --roomId房间里,是否有id为buildingId且等级小于level的
                --如果数量不对,就提示换场景
            end
        else--是数组

            local roomId = FloorMode:FurnitureUnlocakable(room_index, buildingId, buildingLevel)

            if not roomId then--没有符合条件的设施,于是去引导解锁房间
                for k, v in pairs(room_index) do
                    if not FloorMode:IsUnlockRoomByIndexNum(k) then
                        roomId = k
                        break
                    end
                end

                if not roomId then
                    EventManager:DispatchEvent("UI_NOTE",GameTextLoader:ReadText("TXT_TIP_LACK_FURNI"))
                    return
                end

                roomId = FloorMode:GetRoomIdByRoomIndex(roomId)
                openRoom(roomId)
            else
                local roomData = ConfigMgr.config_rooms[roomId]
                FloorMode:SetCurrRoomInfo(roomData.room_index, roomData.id)
                RoomBuildingUI:ShowRoomPanelInfo(roomId)
                RoomBuildingUI:ChooseOne(buildingId, buildingLevel)
            end
        end
    end

    if data.target_facility or data.target_employee then
        local currData = data.target_facility or data.target_employee
        openView(data.goal_room, currData[1], currData[2])
    elseif data.detail_facility or data.detail_employee then--某房间的某设施
        local currData = data.detail_facility or data.detail_employee
        openView(currData[1], currData[2], currData[3])
    elseif data.room_index_num then--点击某房间
        openView(data.room_index_num)
    elseif data.building_target then--解锁房间
        --退回主界面
        if GameStateManager:IsInFloor() then
            MainUI:BackToCity(function()
                CityMapUI:LookAtBuilding(data.building_target)
            end)
            --任何吧镜头移动到指定的对象(可能是解锁按钮,也有可能是进度条,或者是大楼)
        end
    end
end

function QuestUIView:ShowProgress(currProgressIndex, value)
    local totalNeed = ConfigMgr.config_global.quest_each_progress
    -- local progress = self:GetComp("RootPanel/TitlePanel/title/prog/progress", "Slider")
    -- progress.value = value / totalNeed
    self:SetText("RootPanel/TitlePanel/title/prog/curr", math.floor(value/ totalNeed * 100) .. '%')

    if value >=  totalNeed then
        local root = nil
        local ani = nil
        QuestUI:GetProgressReward()
        -- AnimationUtil.Play(ani, "xxx", function()
        --     EventManager:DispatchEvent("FLY_ICON", root, 5, 1)
        --     QuestUI:ShowQuestPanel()
        -- end)
        EventManager:DispatchEvent("FLY_ICON", root, 5, 1)
            QuestUI:ShowQuestPanel()
    end
end

function QuestUIView:ShowQuestPanel(questData)
    local currCity = LocalDataManager:GetDataByKey("city_record_data").currBuidlingId
    -- local sceneIndex = 1
    -- if currCity then
    --     sceneIndex = ConfigMgr.config_buildings[currCity].index
    -- end

    for i=1,3 do
        local trans = self:GetTrans("RootPanel/"..i.."Panel")
        local data = questData[i]
        if data ~= nil then
            local go = trans.gameObject
            go:SetActive(true)
            self:GetGo(go, "main/allDone"):SetActive(false)
            self:SetText(go, "main/info/desc", data.desc)
            self:SetText(go, "main/info/progress/text", data.currValue.."/"..data.maxValue)

            local showReward = function(node, dataReward)
                node:SetActive(true)
                self:SetText(node, "num", Tools:SeparateNumberWithComma(dataReward[2]))
                self:SetSprite(self:GetComp(node, "icon", "Image"), "UI_Main", ResMgr:GetResIcon(dataReward[1]), nil, true)
            end

            self:GetGo(go, "main/info/reward/2"):SetActive(false)
            self:GetGo(go, "main/info/reward/3"):SetActive(false)
            if data.reward[1] then
                local rewardNode = self:GetGo(go, "main/info/reward/"..data.reward[1][1])
                showReward(rewardNode, data.reward[1])
            end
            if data.reward[2] then
                local rewardNode = self:GetGo(go, "main/info/reward/"..data.reward[2][1])
                showReward(rewardNode, data.reward[2])
            end

            local progress = self:GetComp(go, "progress", "Slider")
            progress.value = data.currValue / data.maxValue
            local image = self:GetComp(progress.gameObject, "Fill", "Image")
            if progress.value == 1 then        
                image.color = UnityHelper.GetColor("#FFBD3C")
            else
                image.color = UnityHelper.GetColor("#3C9CFF")
            end
        
            local btn = self:GetComp(go, "RewardBtn", "Button")
            btn.interactable = data.currValue >= data.maxValue
            local jumpAble = self:QuestGoto(data.id, true)
            btn.gameObject:SetActive(data.currValue >= data.maxValue or not jumpAble)

            local gotoBtn = self:GetComp(go, "GotoBtn", "Button")
            gotoBtn.gameObject:SetActive(jumpAble and data.currValue < data.maxValue)
            self:SetButtonClickHandler(gotoBtn, function()
                self:QuestGoto(data.id)
                self:DestroyModeUIObject()
            end)

            self:SetButtonClickHandler(btn, function()
                local rewardData = QuestManager:RewardNum(data.id)

                local currRoomId = GameTableDefine.CityMode:GetCurrentBuilding()
                local sign = ConfigMgr.config_buildings[currRoomId].double_reward
                
                local allReward = {}--2:Cash 3:Dia
                allReward[rewardData[1][1]] = rewardData[1][2]
                if rewardData[2] then
                    allReward[rewardData[2][1]] = rewardData[2][2]
                end

                local rewardPos = self:GetTrans(go, "RewardBtn").position
                local callback = function(double)
                    local success = function()
                        local rate = double == true and 2 or 1
                        QuestManager:ClaimReward(data.id, double)

                        if allReward[2] then
                            EventManager:DispatchEvent("FLY_ICON", rewardPos,
                                2, allReward[2] * rate, function()
                            end)
                        end
                        if allReward[3] then
                            EventManager:DispatchEvent("FLY_ICON", rewardPos,
                                3, allReward[3] * rate, function()
                            end)
                        end
                        if allReward[6] then
                            EventManager:DispatchEvent("FLY_ICON", rewardPos,
                            6, allReward[6] * rate, function()
                            end)
                        end
                        MainUI:RefreshQuestHint()
                    end

                    local add = allReward[2] or allReward[6] or 0
                    if allReward[2] or allReward[6] then
                        ChooseUI:EarnCash(add, success)
                    else
                        success()
                    end

                end

                if (allReward[2] and allReward[2] >= sign[1]) or
                    (allReward[3] and allReward[3] >= sign[2])
                    then
                        DoubleRewardUI:Show(callback, allReward)
                        return
                end

                callback(false)
            end)
       --  elseif currCity < 300 then--只是当前阶段完成了
        else
            local go = trans.gameObject
            go:SetActive(true)
            self:GetGo(go, "main/allDone"):SetActive(true)
        -- elseif trans then
        --     trans.gameObject:SetActive(false)
        end
    end
end

return QuestUIView