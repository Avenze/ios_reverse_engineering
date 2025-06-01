
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local FloatUI = GameTableDefine.FloatUI
local GameUIManager = GameTableDefine.GameUIManager

local CycleToyUnlockUIView = Class("CycleToyUnlockUIView", UIView)

function CycleToyUnlockUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.m_roomID = nil
end

function CycleToyUnlockUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    GameTableDefine.CycleToyMainViewUI:SetEventActive(false)
end

function CycleToyUnlockUIView:OnExit()
    self.super:OnExit(self)
    GameTableDefine.CycleToyMainViewUI:SetEventActive(true)
    local currentModel = CycleInstanceDataManager:GetCurrentModel() ---@type CycleToyModel
    --还原摄像机位置
    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    currentModel:LookAtSceneGO(self.m_roomID, 1, cameraFocus, true)
end

function CycleToyUnlockUIView:InitView(id)

    self.m_roomID = id
    local currentModel = CycleInstanceDataManager:GetCurrentModel() ---@type CycleToyModel
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
    end,SoundConst.instance_3_Build_sfx)

    --将相机焦点移动至所选设备位置
    local cameraFocus = self:GetComp("SceneObjectRange", "CameraFocus")
    currentModel:LookAtSceneGO(id, 1, cameraFocus)
end


return CycleToyUnlockUIView