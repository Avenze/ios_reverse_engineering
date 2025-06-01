--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-10-13 17:21:33
]]
local ActivityRankRewardGetUI = GameTableDefine.ActivityRankRewardGetUI
local GameUIManager = GameTableDefine.GameUIManager


function ActivityRankRewardGetUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ACTIVITY_RANK_REWARD_GET_UI, self.m_view, require("GamePlay.Common.UI.ActivityRankRewardGetUIView"), self, self.CloseView)
    return self.m_view
end

function ActivityRankRewardGetUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ACTIVITY_RANK_REWARD_GET_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--需要做物品显示相关内容了
function ActivityRankRewardGetUI:ShowRewardItem(giftID)
	self:GetView():Invoke("ShowRewardItem", giftID)
end

function ActivityRankRewardGetUI:ShowNoRewardInfo()
    self:GetView():Invoke("ShowNoRewardInfo")
end

