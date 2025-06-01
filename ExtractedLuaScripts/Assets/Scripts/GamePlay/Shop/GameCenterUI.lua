local GameCenterUI = GameTableDefine.GameCenterUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local UnityHelper = CS.Common.Utils.UnityHelper

function GameCenterUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.GAME_CENTER_UI, self.m_view, require("GamePlay.Shop.GameCenterUIView"), self, self.CloseView)
    return self.m_view
end

function GameCenterUI:Open()
    local data = GameSDKs:GetGameVideo()
    -- data = {
    --     {
    --         ["game_name"] = "修路",
    --         ["video_url"] = "http://1"
    --     },
    --     {
    --         ["game_name"] = "过山车",
    --         ["video_url"] = "http://2"
    --     },
    --     {
    --         ["game_name"] = "修桥",
    --         ["video_url"] = "http://3"
    --     }
    -- }

    if data == nil then
        --做提示,让玩家稍后尝试
        print("互动视频数据为空, 请稍后再尝试")
        return
    end
    self:GetView():Invoke("Open",data)
end

function GameCenterUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.GAME_CENTER__UI)
    self.m_view = nil
    collectgarbage("collect")
end