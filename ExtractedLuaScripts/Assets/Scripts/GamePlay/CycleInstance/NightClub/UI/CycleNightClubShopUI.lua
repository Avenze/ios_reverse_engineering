--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-06-27 17:13:32
]]
---@class CycleNightClubShopUI
local CycleNightClubShopUI = GameTableDefine.CycleNightClubShopUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleNightClubModel = nil
local EventManager = require("Framework.Event.Manager")

function CycleNightClubShopUI:GetView()
    -- self:ShopId2Index()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SHOP_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubShopUIView"), self, self.CloseView)
    return self.m_view
end

-- function CycleNightClubShopUI:EnterToSpecial()
--     self:GetView()
--     if self.scrollToSpecialTimer then
--         GameTimer:StopTimer(self.scrollToSpecialTimer)
--         self.scrollToSpecialTimer = nil
--     end
--     self.scrollToSpecialTimer = GameTimer:CreateNewMilliSecTimer(400, function()
--         if self.scrollToSpecialTimer then
--             GameTimer:StopTimer(self.scrollToSpecialTimer)
--             self.scrollToSpecialTimer = nil
--         end
--         if self.m_view then
--             self.m_view:Invoke("EnterToSpecial")
--         end
--     end, false, false)
-- end

function CycleNightClubShopUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SHOP_UI)
    if self.scrollToSpecialTimer then
        GameTimer:StopTimer(self.scrollToSpecialTimer)
        self.scrollToSpecialTimer = nil
    end
    self.m_view = nil
    collectgarbage("collect")
end

function CycleNightClubShopUI:OpenBuyLandmark()
    -- if refresh then
    --     self:EnterShop(true)
    -- else
    --     self:EnterShop()
    -- end
    self:GetView()
    if self.m_view then
        self.m_view:Invoke("TurnPage", 1)
    end
    
end

function CycleNightClubShopUI:OpenAndTurnPage(index)
    self:GetView():Invoke("TurnPage", index)
end

-- function CycleNightClubShopUI:ShopId2Index()
--     self.shopidToIndex = {} 
--     local startIndex = nil
--     for k,v in pairs(CycleNightClubModel.config_shop_frame_instance) do
--         if not startIndex then
--             startIndex = k - 1
--         end
--         for i=1,#v.content do
--             local shopID = v.content[i].shopID
--             self.shopidToIndex[shopID] = k - startIndex + 1 -- +1是将lua表索引转为C#表索引
--         end
--     end
-- end