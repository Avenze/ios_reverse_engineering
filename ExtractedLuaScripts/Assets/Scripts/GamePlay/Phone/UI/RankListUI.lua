local RankListUI = GameTableDefine.RankListUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function RankListUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.APP_RANK_UI, self.m_view, require("GamePlay.Phone.UI.RankListUIView"), self, self.CloseView)
    return self.m_view
end

function RankListUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.APP_RANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end