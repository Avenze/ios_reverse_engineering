local GameUIManager = GameTableDefine.GameUIManager

---@class StatisticUI
local StatisticUI = GameTableDefine.StatisticUI
local StatisticUIView = require("GamePlay.Statistic.UI.StatisticUIView")

function StatisticUI:ctor()
    self.m_view = nil ---@type StatisticUIView
end

function StatisticUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.STATISTIC_UI, self.m_view, StatisticUIView, self, self.CloseView)
    return self.m_view
end

function StatisticUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.STATISTIC_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--[[
    @desc: 打开自己的名片系统
    author:{author}
    time:2024-10-31 10:44:03
    @return:
]]
function StatisticUI:OpenSelfStatistic()
    self:GetView():Invoke("OpenSelfStatistic")
end

function StatisticUI:OpenOtherPlayerStatistic(bossSkin, playerName, start, contry_id, curMoneyEff, sceneID, sceneName)
    self:GetView():Invoke("OpenOtherPlayerStatistic", bossSkin, playerName, start, contry_id, curMoneyEff, sceneID, sceneName)
end

return StatisticUI