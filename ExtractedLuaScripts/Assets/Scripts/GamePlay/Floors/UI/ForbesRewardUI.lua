local ForbesRewardUI = GameTableDefine.ForbesRewardUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local mCfg = nil
function ForbesRewardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.FORBES_UI, self.m_view, require("GamePlay.Floors.UI.ForbesRewardUIView"), self, self.CloseView)
    return self.m_view
end

function ForbesRewardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.FORBES_UI)
    self.m_view = nil
    mValue = nil
    collectgarbage("collect")
end

function ForbesRewardUI:Open(value, cb)
    self:GetView():Invoke("Open", value, cb)
end

function ForbesRewardUI:SetCfg(cfg)
    mCfg = cfg
end

function ForbesRewardUI:OpenSimple(cb)
    self:GetView():Invoke("Open", mCfg, cb)
end