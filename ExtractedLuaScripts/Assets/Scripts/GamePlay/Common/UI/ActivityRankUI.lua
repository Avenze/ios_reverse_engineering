local ActivityRankUI = GameTableDefine.ActivityRankUI
local ValueManager = GameTableDefine.ValueManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ShopManager = GameTableDefine.ShopManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager

function ActivityRankUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ACTIVITY_RANK_UI, self.m_view, require("GamePlay.Common.UI.ActivityRankUIView"), self, self.CloseView)
    return self.m_view
end

function ActivityRankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ACTIVITY_RANK_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function ActivityRankUI:Refresh()
end

function ActivityRankUI:ValueToShow(value)
    -- local valueShow = ""
    -- local valueNow = value
    -- if valueNow > 1000 then
    --     valueShow = "K"
    --     valueNow = valueNow / 1000
    -- end
    -- if valueNow > 1000 then
    --     valueShow = "M"
    --     valueNow = valueNow / 1000
    -- end
    -- if valueNow > 1000 then
    --     valueShow = "B"
    --     valueNow = valueNow / 1000
    -- end
    -- valueNow = math.modf(valueNow * 10) / 10
    -- valueNow = string.format("%.1f", valueNow)
    -- return valueNow .. valueShow
    local valueShow = Tools:SeparateNumberWithComma(math.ceil(value))
    return valueShow
end

--获取到(购买)限时活动奖励
function ActivityRankUI:GetTimeLimitedActivityRewards(shopId)
    ShopManager:Buy(shopId, false, function()           
    end,function()                        
        --self:refresh()   
        PurchaseSuccessUI:SuccessBuy(shopId)                        
    end)    
end

function ActivityRankUI:NewActivityShow()
    self:GetView():Invoke("NewActivityShow")
end

function ActivityRankUI:LastActivityShow()
    ActivityRankDataManager:RefreshLastRankData()
    self:GetView():Invoke("LastActivityShow")
end

