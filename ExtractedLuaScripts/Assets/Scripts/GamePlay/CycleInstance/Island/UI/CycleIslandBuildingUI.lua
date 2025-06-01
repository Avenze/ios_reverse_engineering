--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-24 10:10:57
]]
---@class CycleIslandBuildingUI
local CycleIslandBuildingUI = GameTableDefine.CycleIslandBuildingUI

local GameUIManager = GameTableDefine.GameUIManager
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local SoundEngine = GameTableDefine.SoundEngine
local EventManager = require("Framework.Event.Manager")
local currentBGM = nil  --当前bgm

function CycleIslandBuildingUI:GetView()
    self.m_model = {}
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_BUILDING_UI, self.m_view, require("GamePlay/CycleInstance/Island/UI/CycleIslandBuildingUIView"), self, self.CloseView)
    return self.m_view
end

function CycleIslandBuildingUI:CloseView()
    --停止播放BGM
    SoundEngine:StopSFX(currentBGM)

    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_ISLAND_BUILDING_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--显示工厂UI
function CycleIslandBuildingUI:ShowFactoryUI(roomID, furIndex)
    self:GetView():Invoke("ShowFactoryUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = CycleInstanceDataManager:GetCurrentModel().roomsConfig[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)
    self.roomID = roomID
    self.furIndex = furIndex
end

function CycleIslandBuildingUI:RefreshView()
    if self.m_view then
        if self.m_view.UItype == 1 then
            self.m_view:Invoke("ShowFactoryUI", self.roomID, self.furIndex)
        end
    end
end

--显示补给建筑UI
function CycleIslandBuildingUI:ShowSupplyBuildingUI(roomID, furIndex)
    self:GetView():Invoke("ShowSupplyBuildingUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = InstanceDataManager.config_rooms_instance[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)end

--显示码头UI
function CycleIslandBuildingUI:ShowWharfUI(roomID, furIndex)
    self:GetView():Invoke("ShowWharfUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = InstanceDataManager.config_rooms_instance[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)
end