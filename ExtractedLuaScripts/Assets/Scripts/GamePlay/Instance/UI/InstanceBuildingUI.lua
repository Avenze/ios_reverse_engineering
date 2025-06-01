--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-24 10:10:57
]]

local InstanceBuildingUI = GameTableDefine.InstanceBuildingUI

local GameUIManager = GameTableDefine.GameUIManager
local InstanceDataManager = GameTableDefine.InstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local SoundEngine = GameTableDefine.SoundEngine
local EventManager = require("Framework.Event.Manager")
local currentBGM = nil  --当前bgm

function InstanceBuildingUI:GetView()
    print("打开副本建筑UI \n"..debug.traceback())
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_BUILDING_UI, self.m_view, require("GamePlay.Instance.UI.InstanceBuildingUIView"), self, self.CloseView)
    return self.m_view
end

function InstanceBuildingUI:CloseView()
    --停止播放BGM
    SoundEngine:StopSFX(currentBGM)

    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_BUILDING_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--显示工厂UI
function InstanceBuildingUI:ShowFactoryUI(roomID,furIndex)
    self:GetView():Invoke("ShowFactoryUI",roomID,furIndex or 1,true)
    --播放音效
    local roomCfg = InstanceDataManager.config_rooms_instance[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm,false)
end

--显示补给建筑UI
function InstanceBuildingUI:ShowSupplyBuildingUI(roomID,furIndex)
    self:GetView():Invoke("ShowSupplyBuildingUI",roomID,furIndex or 1,true)
    --播放音效
    local roomCfg = InstanceDataManager.config_rooms_instance[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm,false)end

--显示码头UI
function InstanceBuildingUI:ShowWharfUI(roomID,furIndex)
    self:GetView():Invoke("ShowWharfUI",roomID,furIndex or 1,true)
    --播放音效
    local roomCfg = InstanceDataManager.config_rooms_instance[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm,false)
end