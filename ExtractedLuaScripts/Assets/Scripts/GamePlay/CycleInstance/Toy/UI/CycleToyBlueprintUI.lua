---@class CycleToyBlueprintUI
local CycleToyBlueprintUI = GameTableDefine.CycleToyBlueprintUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local CycleToySellUI = GameTableDefine.CycleToySellUI

function CycleToyBlueprintUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_TOY_BLUE_PRINT_UI, self.m_view, require("GamePlay.CycleInstance.Toy.UI.CycleToyBlueprintUIView"), self, self.CloseView)
    return self.m_view
end

function CycleToyBlueprintUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_TOY_BLUE_PRINT_UI)
    self.m_view = nil
    collectgarbage("collect")

    if CycleToySellUI.m_view then
        local sellsID = CycleInstanceDataManager:GetCurrentModel():GetRoomDataByType(4)
        local sellID = sellsID[1].roomID
        if self.m_upgradeProductID then
            CycleToySellUI:ShowWharfUI(sellID,self.m_upgradeProductID,true)
        else
            CycleToySellUI:ShowWharfUI(sellID,self.m_selectProductID)
        end
    end
end

function CycleToyBlueprintUI:OpenView(productID)
    ---从外部进入时的目标产品 或者 上次升过级的商品
    self.m_selectProductID = productID
    self.m_upgradeProductID = nil
    self:GetView():Invoke("Init",productID)
end

function CycleToyBlueprintUI:OnSelectProduction(productID)
    self.m_selectProductID = productID
end

function CycleToyBlueprintUI:OnUpgradeProduction(productID)
    self.m_upgradeProductID = productID
end