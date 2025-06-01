--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-24 10:10:57
]]
---@class CycleToyBuildingUI
local CycleToyBuildingUI = GameTableDefine.CycleToyBuildingUI

local GameUIManager = GameTableDefine.GameUIManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local SoundEngine = GameTableDefine.SoundEngine
local EventManager = require("Framework.Event.Manager")
local currentBGM = nil  --当前bgm
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")
local AnimationUtil = CS.Common.Utils.AnimationUtil ---@type Common.Utils.AnimationUtil

function CycleToyBuildingUI:GetView()
    --print("打开副本建筑UI \n"..debug.traceback())
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_BUILDING_UI, self.m_view, require("GamePlay.CycleInstance.Toy.UI.CycleToyBuildingUIView"), self, self.CloseView)
    return self.m_view
end

function CycleToyBuildingUI:CloseView()
    --停止播放BGM
    SoundEngine:StopSFX(currentBGM)

    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_BUILDING_UI)
    self.m_view = nil
    collectgarbage("collect")
end

---房间升级流程
function CycleToyBuildingUI:DoFactoryUpgradeProcess(roomID,furIndex)

    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local currentScene = currentModel:GetScene()
    local roomData = currentModel:GetCurRoomData(roomID)
    local room = currentScene:GetRoomByID(roomID)

    GameUIManager:SetEnableTouch(false,"建筑升级")
    --1.隐藏主界面
    GameTableDefine.CycleToyMainViewUI:GuideTimeUIState(false)
    local decorationFurID = roomData.upgradeNodeFurID
    if decorationFurID then
        --有家具节点
        local decorationGO = room:GetDecorationFurnitureGoByFurID(decorationFurID)
        if decorationGO then
            GameTimer:CreateNewTimer(0.5,function()
                --2.在0.5s后,视角锁定到装饰
                local cameraFocus = GameTableDefine.CycleToyMainViewUI.m_view:GetComp("RoomLevel_SceneRange","CameraFocus")
                currentScene:LookAtGameObject(room.roomGO.roomBox,cameraFocus,false,function()
                    GameUIManager:SetEnableTouch(false,"建筑升级")
                    --3.播放装饰出现的动画
                    currentModel:DoRoomUpgradeAnim(roomID)
                    --获取动画时长.
                    local length = 2
                    local anim =  decorationGO.transform:GetChild(0):GetComponent("Animation")
                    if anim and not anim:IsNull() then
                        local done,animName = AnimationUtil.GetFirstClipName(anim)
                        if done then
                            local state = AnimationUtil.GetAnimationState(anim,animName)
                            length = state.length
                        end
                    end
                    GameTimer:CreateNewTimer(length,function()
                        --4.播放房间升级特效
                        room:PlayLevelUpVfx()
                        GameTimer:CreateNewTimer(1.2,function()
                            --5.从新显示MainViewUI,BuildingUI
                            GameTableDefine.CycleToyMainViewUI:GuideTimeUIState(true)
                            GameUIManager:SetEnableTouch(true,"建筑升级")
                            self:ShowFactoryUI(roomID,furIndex)
                        end)
                    end)
                end)
            end)
        else
            printError("升级流程出错,找不到装饰节点")
            GameTimer:CreateNewTimer(0.5,function()
                --2.在0.5s后,显示房间升级特效
                local cameraFocus = GameTableDefine.CycleToyMainViewUI.m_view:GetComp("RoomLevel_SceneRange","CameraFocus")
                currentScene:LookAtGameObject(room.roomGO.roomBox,cameraFocus,false,function()
                    GameUIManager:SetEnableTouch(false,"建筑升级")
                    --3.播放装饰出现的动画和特效
                    currentModel:DoRoomUpgradeAnim(roomID)
                    room:PlayLevelUpVfx()
                    GameTimer:CreateNewTimer(1.2,function()
                        --4.从新显示MainViewUI,BuildingUI
                        GameTableDefine.CycleToyMainViewUI:GuideTimeUIState(true)
                        GameUIManager:SetEnableTouch(true,"建筑升级")
                        self:ShowFactoryUI(roomID,furIndex)
                    end)
                end)
            end)
        end
    else
        --没有家具节点
        GameTimer:CreateNewTimer(0.5,function()
            --2.在0.5s后,显示房间升级特效
            local cameraFocus = GameTableDefine.CycleToyMainViewUI.m_view:GetComp("RoomLevel_SceneRange","CameraFocus")
            currentScene:LookAtGameObject(room.roomGO.roomBox,cameraFocus,false,function()
                GameUIManager:SetEnableTouch(false,"建筑升级")
                --3.播放装饰出现的动画和特效
                currentModel:DoRoomUpgradeAnim(roomID)
                room:PlayLevelUpVfx()
                GameTimer:CreateNewTimer(1.2,function()
                    --4.从新显示MainViewUI,BuildingUI
                    GameTableDefine.CycleToyMainViewUI:GuideTimeUIState(true)
                    GameUIManager:SetEnableTouch(true,"建筑升级")
                    self:ShowFactoryUI(roomID,furIndex)
                end)
            end)
        end)
    end
end

---显示工厂UI
---@return boolean 是否要播放升级表现
function CycleToyBuildingUI:ShowFactoryUI(roomID, furIndex)

    --判断房间是否升级
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local roomData = currentModel:GetCurRoomData(roomID)
    if roomData.isUpgrading then
        local curTime = GameTimeManager:GetCurrentServerTime()
        local remainingTime = roomData.completeTime - curTime
        if remainingTime <= 0 then
            --通知Model更新
            currentModel:UpgradeRoomComplete(roomID)
            local room = currentModel:GetScene():GetRoomByID(roomID)
            room:HideBubble(CycleInstanceDefine.BubbleType.IsFinish)
            --升级后 家具不管有没有变化都要走升级流程
            if roomData.needShowUpgradeAnim then
                self:DoFactoryUpgradeProcess(roomID, furIndex)
                return true
            else
                --走普通流程
            end
        else
            --走普通流程
        end
    end

    self:GetView():Invoke("ShowFactoryUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = CycleInstanceDataManager:GetCurrentModel().roomsConfig[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)
    self.roomID = roomID
    self.furIndex = furIndex
end

function CycleToyBuildingUI:RefreshView()
    if self.m_view then
        if self.m_view.UItype == 1 then
            self.m_view:Invoke("ShowFactoryUI", self.roomID, self.furIndex)
        end
    end
end

--显示补给建筑UI
function CycleToyBuildingUI:ShowSupplyBuildingUI(roomID, furIndex)
    self:GetView():Invoke("ShowSupplyBuildingUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = CycleInstanceDataManager:GetCurrentModel().roomsConfig[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)end

--显示码头UI
function CycleToyBuildingUI:ShowWharfUI(roomID, furIndex)
    self:GetView():Invoke("ShowWharfUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = CycleInstanceDataManager:GetCurrentModel().roomsConfig[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)
end
