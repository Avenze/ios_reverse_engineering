local UnlockingSkipUI = GameTableDefine.UnlockingSkipUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function UnlockingSkipUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.UNLOCKING_SKIP_UI, self.m_view, require("GamePlay.Floors.UI.UnlockingSkipUIView"), self, self.CloseView)
    return self.m_view
end

function UnlockingSkipUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.UNLOCKING_SKIP_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function UnlockingSkipUI:Show(config, timeWait)
    self:GetView():Invoke("Refresh", config, timeWait)
end

function UnlockingSkipUI:ShowBuildingSkipUI(config, timeWait)
    self:GetView():Invoke("RefreshBuildingSkip", config, timeWait)
end

function UnlockingSkipUI:ShowWorkShopSkipSkipUI(config, timeWait)
    self:GetView():Invoke("RefreshWorkShopSkip", config, timeWait)
end

function UnlockingSkipUI:ShowFootballClubSkipUI(config, timeWait)
    self:GetView():Invoke("RefreshFootballClubSkip", config, timeWait)
end

function UnlockingSkipUI:ShowInstanceBuildingSkipUI(config, timeWait, handler)
    self:GetView():Invoke("RefreshInstanceBuildingSkip", config, timeWait, handler)
end

function UnlockingSkipUI:ShowCycleIslandBuildingSkipUI(config, timeWait, handler)
    self:GetView():Invoke("RefreshCycleIslandBuildingSkip", config, timeWait, handler)
end


