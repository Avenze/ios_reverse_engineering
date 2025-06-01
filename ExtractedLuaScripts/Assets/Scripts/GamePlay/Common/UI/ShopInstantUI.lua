--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-06-14 16:40:52
]]

---@class ShopInstantUI
local ShopInstantUI = GameTableDefine.ShopInstantUI

local GameUIManager = GameTableDefine.GameUIManager

local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

function ShopInstantUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.SHOP_INSTANT_UI, self.m_view, require("GamePlay.Common.UI.ShopInstantUIView"), self, self.CloseView)
    return self.m_view
end

---@param popup string 弹窗来源
function ShopInstantUI:EnterToDiamondBuy(buyCallback,popup)
    self:GetView()
    if not self.m_view then
        return
    end
    self.m_popup = popup
    self.m_buyCallback = buyCallback
    self.m_view:Invoke("EnterToDiamondBuy")
end

---@param popup string 弹窗来源
function ShopInstantUI:EnterToCashBuy(buyCallback,popup)
    --添加一个检测如果计算的现金产出为0的话就不显示购买
    local curEarn = GameTableDefine.FloorMode:GetTotalRent(nil, GameTableDefine.CountryMode:GetCurrCountry()) - GameTableDefine.FloorMode:GetEmployeePay()
    if curEarn <= 0 then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_CASH"))
        return
    end
    self:GetView()
    if not self.m_view then
        return
    end
    self.m_popup = popup
    self.m_buyCallback = buyCallback
    self.m_view:Invoke("EnterToCashBuy")
end

function ShopInstantUI:EnterToPesoBuy(buyCallback,popup)
    --添加一个检测如果计算的现金产出为0的话就不显示购买
    -- local curEarn = GameTableDefine.FloorMode:GetTotalRent(nil, GameTableDefine.CountryMode:GetCurrCountry()) - GameTableDefine.FloorMode:GetEmployeePay()
    -- if curEarn <= 0 then
    --     EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_CASH"))
    --     return
    -- end
    -- print("========================",GameTimeManager:GetCurrentServerTimeInMilliSec())
    self:GetView()
    if not self.m_view then
        return
    end
    self.m_popup = popup
    self.m_buyCallback = buyCallback
    self.m_view:Invoke("EnterToPesoBuy")
    -- print("========================",GameTimeManager:GetCurrentServerTimeInMilliSec())

end

function ShopInstantUI:SuccessBuy()
    if self.m_buyCallback then
        self.m_buyCallback()
    end
end

function ShopInstantUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.SHOP_INSTANT_UI)

    self.m_view = nil

    if self.m_buyCallback then
        self.m_buyCallback = nil
    end
    collectgarbage("collect")
end