--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-24 10:10:57
]]
---@class CycleCastleSellUI
local CycleCastleSellUI = GameTableDefine.CycleCastleSellUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local SoundEngine = GameTableDefine.SoundEngine
local EventManager = require("Framework.Event.Manager")
local currentBGM = nil  --当前bgm
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

function CycleCastleSellUI:GetView()
    print("打开副本码头UI \n"..debug.traceback())
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_SELL_UI, self.m_view, require("GamePlay/CycleInstance/Castle/UI/CycleCastleSellUIView"), self, self.CloseView)
    return self.m_view
end

function CycleCastleSellUI:CloseView()
    --停止播放BGM
    SoundEngine:StopSFX(currentBGM)

    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_CASTLE_SELL_UI)
    self.m_view = nil
    collectgarbage("collect")
end


--显示码头UI
function CycleCastleSellUI:ShowWharfUI(roomID, furIndex)
    self:GetView():Invoke("ShowWharfUI", roomID, furIndex or 1, true)
    --播放音效
    local roomCfg = CycleInstanceDataManager:GetCurrentModel().roomsConfig[roomID]
    local bgm = SoundEngine[roomCfg.room_audio]
    currentBGM = SoundEngine:PlaySFX(bgm, false)
end
