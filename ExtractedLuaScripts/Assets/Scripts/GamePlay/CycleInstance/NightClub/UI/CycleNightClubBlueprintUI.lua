---@class CycleNightClubBlueprintUI
local CycleNightClubBlueprintUI = GameTableDefine.CycleNightClubBlueprintUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

function CycleNightClubBlueprintUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_BLUE_PRINT_UI, self.m_view, require("GamePlay.CycleInstance.NightClub.UI.CycleNightClubBlueprintUIView"), self, self.CloseView)
    return self.m_view
end

function CycleNightClubBlueprintUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_BLUE_PRINT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CycleNightClubBlueprintUI:OpenView(productID)
    ---从外部进入时的目标产品 或者 上次升过级的商品
    self.m_selectProductID = productID
    self:GetView():Invoke("Init",productID)
end