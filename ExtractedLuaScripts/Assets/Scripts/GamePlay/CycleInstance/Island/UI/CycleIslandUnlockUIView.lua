
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager

local CycleIslandUnlockUIView = Class("CycleIslandUnlockUIView", UIView)

function CycleIslandUnlockUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CycleIslandUnlockUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CycleIslandUnlockUIView:OnExit()
    self.super:OnExit(self)
end

function CycleIslandUnlockUIView:InitView(id)
    local currentModel = CycleInstanceDataManager:GetCurrentModel()
    local roomData = currentModel:GetCurRoomData(id)
    local roomConfig = currentModel:GetRoomConfigByID(id)

    self:SetImageSprite("RootPanel/MidPanel/icon",roomConfig.icon,nil)
    self:SetText("RootPanel/MidPanel/info/name",GameTextLoader:ReadText(roomConfig.name))
    self:SetText("RootPanel/MidPanel/info/desc",GameTextLoader:ReadText(roomConfig.desc))
    -- self.timer = GameTimer:CreateNewTimer(1,function()

    -- end,true,true)
    local timeStr = GameTimeManager:FormatTimeLength(roomConfig.unlock_times,false)
    self:SetText("RootPanel/MidPanel/requirement/time/num",timeStr)
    local cost = tonumber(roomConfig.unlock_require)
    local buffID = currentModel:GetSkillIDByType(currentModel.SkillTypeEnum.ReduceUpgradeCosts)
    local buffValue = currentModel:GetSkillBufferValueBySkillID(buffID)
    cost = cost / buffValue
    self:SetText("RootPanel/MidPanel/requirement/cash/num", BigNumber:FormatBigNumber(cost))

    local button = self:GetComp("RootPanel/SelectPanel/bulidBtn","Button")
    if currentModel:CheckRoomCondition(id) then
        button.interactable = true
    else
        button.interactable = false
    end

    self:SetButtonClickHandler(button,function()
        currentModel:BuyRoom(id)
        self:DestroyModeUIObject()
    end)

end


return CycleIslandUnlockUIView