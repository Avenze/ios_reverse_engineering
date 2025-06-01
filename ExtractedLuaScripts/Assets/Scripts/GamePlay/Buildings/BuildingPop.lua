local BuildingPopView = require "GamePlay.Buildings.BuildingPopView"
local EventManager = require("Framework.Event.Manager")

local BuildingPop = GameTableDefine.BuildingPop
local GameUIManager = GameTableDefine.GameUIManager
local CityMode = GameTableDefine.CityMode

local functionTable = {
    {_functionName = "BUILDING_DETAIL", _buttonName = "btn_detail"},
    {_functionName = "UPGRADE_BUILDING", _buttonName = "btn_upgrade"},
}

function BuildingPop:GetButtonName(functionName)
    for k, v in pairs(functionTable) do
        if v._functionName == functionName then
            return v._buttonName
        end
    end
end
function BuildingPop:GetOpPopView(obj)
    local tran = BuildingPopView:GetTrans(obj, "UIPostion") or obj.transform
    if self.m_OpPopView == nil then
        self.m_OpPopView = BuildingPopView.new()
        GameUIManager:OpenFloatUI(ENUM_GAME_UITYPE.BUILDING_POP, self.m_OpPopView, tran)
    else
        GameUIManager:UpdateFloatUIEntity(self.m_OpPopView, tran)
    end
    return self.m_OpPopView
end

function BuildingPop:ShowOpPop(
    obj,
    localPosID,
    buildingLevel,
    buildingName,
    buttonNumber,
    buttonNames,
    buttonValues,
    buttonStatusList,
    hasHint,
    hintType,
    hintIcon,
    hintContent)
    local functions = {}
    for i = 1, #buttonNames do
        table.insert(
            functions,
            {
                name = self:GetButtonName(buttonNames[i]),
                value = buttonValues[i],
                status = buttonStatusList[i],
                cmd = "FS_CMD_BUILDING_POP_CLICKED",
                params = {
                    functionName = buttonNames[i],
                    localPosID = localPosID
                }
            }
        )
    end

    BuildingPop:GetOpPopView(obj):Invoke("Show", functions, buildingName, buildingLevel, hintType, hintIcon, hintContent)
end

function BuildingPop:CloseOpPopView()
    GameUIManager:CloseFloatUI(ENUM_GAME_UITYPE.BUILDING_POP)
    self.m_OpPopView = nil
end

function BuildingPop:HideOpPopView()
    if self.m_OpPopView then
        self.m_OpPopView:Invoke("Hide")
    end
end

function BuildingPop:OnClickedButton(params)
    local functionName = params.functionName
    local localPosID = params.localPosID
    CityMode:ClickeOperationButton(localPosID, functionName)
end

EventManager:RegEvent("FS_CMD_BUILDING_POP_CLICKED", handler(BuildingPop, BuildingPop.OnClickedButton))
