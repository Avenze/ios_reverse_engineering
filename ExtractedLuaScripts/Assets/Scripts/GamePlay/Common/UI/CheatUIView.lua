local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local GameUIManager = GameTableDefine.GameUIManager

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local CheatUI = GameTableDefine.CheatUI
---@class CheatUIView:UIBaseView
local CheatUIView = Class("CheatUIView", UIView)
local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode

function CheatUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CheatUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/closeBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    GameConfig.showfps = true
    UnityHelper.ShowFps(GameUIManager.canvasObj)
    if GameDeviceManager:IsiOSDevice() then
        GameSDKs:Track("debug_info")
    end
    self.infoList = CheatUI:GetInfoList()
    self.m_list = self:GetComp("RootPanel/HeadPanel/ScrollRectEx", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return Tools:GetTableSize(self.infoList)
    end)
    self:SetListItemNameFunc(self.m_list, function(index)
        return "item"
    end)
    -- local witeTmie = GameTimer:CreateNewMilliSecTimer(1000,function()
    --     self.m_list:UpdateData()
    -- end, false, false)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateList))
    local inputBox = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    self.m_inputBox = inputBox
    local confirmButton = self:GetComp("RootPanel/MidPanel/ConfirmBtn", "Button")
    self:SetButtonClickHandler(confirmButton, function()
        local inputInfo = inputBox.text
        CheatUI:Implement(CheatUI:ProcessingOutputInformation(inputInfo))
        self.infoList = CheatUI:GetInfoList()
        self.m_list:UpdateData(true)
    end)
    --0self.m_list:UpdateData()

    --提示
    if GameDeviceManager:IsEditor() then
        self:SetTMPInputValueChangeHandler(inputBox,handler(self,self.MatchConsole))
        self.m_consoleList = self:GetComp("RootPanel/MidPanel/input/ConsoleList","ScrollRectEx")
        self:SetListUpdateFunc(self.m_consoleList,handler(self,self.UpdateConsoleList))
        self:SetListItemNameFunc(self.m_consoleList, function(index)
            return "item"
        end)
        self:SetListItemCountFunc(self.m_consoleList, handler(self,self.GetConsoleListCount))
        self.m_updateTimer = GameTimer:CreateNewTimer(0.01,handler(self,self.Update),true)
    end
end

function CheatUIView:UpdateList(index, tran)
    index = index + 1
    local go = tran.gameObject
    self:SetText(go, "", self.infoList[index])
end

function CheatUIView:MatchConsole(str)
    if #str > 0 then
        self.m_matchContents = CheatUI:GetMatchContent(str)
        self.m_consoleList.gameObject:SetActive(true)
        self.m_consoleList:UpdateData()
    else
        self.m_consoleList.gameObject:SetActive(false)
    end
end

function CheatUIView:GetConsoleListCount()
    return self.m_matchContents and #self.m_matchContents or 0
end

function CheatUIView:UpdateConsoleList(index, tran)
    index = index + 1
    local go = tran.gameObject
    local command = CheatUI:GetCheatingCommand(self.m_matchContents[index])
    self:SetText(go, "Bg/Description", command.type..","..command.Info)
    self:SetText(go, "Bg/Content", self.m_matchContents[index])
    self:SetButtonClickHandler(self:GetComp(go,"","Button"),function()
        self.m_inputBox.text = self.m_matchContents[index]
        self.m_selectCommand = nil
        self.m_consoleList:UpdateData(true)
        --self.m_inputBox:Select()
        --self.m_inputBox:MoveToEndOfLine()
        self.m_moveToEnd = true
    end)
    self:GetGo(go,"Bg/IsSelect"):SetActive(self.m_selectCommand == self.m_matchContents[index])
end

function CheatUIView:FindCommandIndex(command)
    if command then
        local len = #self.m_matchContents
        for i = 1,len do
            if command == self.m_matchContents[i] then
                return i
            end
        end
    end
    return 0
end

function CheatUIView:Update()

    if self.m_moveToEnd then
        self.m_inputBox:Select()
        --self.m_inputBox:ReleaseSelection()
        self.m_inputBox.caretPosition = 1000
        self.m_inputBox:ForceLabelUpdate()
        self.m_moveToEnd = false
    end

    if Input.GetKeyDown(KeyCode.DownArrow) then
        local index = 1
        if self.m_selectCommand then
            index = self:FindCommandIndex(self.m_selectCommand) + 1
        end
        if index<=#self.m_matchContents then
            self.m_selectCommand = self.m_matchContents[index]
            self.m_consoleList:UpdateData(true)
        end
    elseif Input.GetKeyDown(KeyCode.UpArrow) then
        local index = 0
        if self.m_selectCommand then
            index = self:FindCommandIndex(self.m_selectCommand) - 1
        end
        if index>0 and index<=#self.m_matchContents then
            self.m_selectCommand = self.m_matchContents[index]
            self.m_consoleList:UpdateData(true)
        elseif self.m_selectCommand and index == 0 then
            self.m_selectCommand = nil
            self.m_consoleList:UpdateData(true)
        end
    elseif Input.GetKeyUp(KeyCode.Return) or Input.GetKeyUp(KeyCode.KeypadEnter)then
        local index = 0
        if self.m_selectCommand then
            index = self:FindCommandIndex(self.m_selectCommand)
            if index > 0 then
                self.m_inputBox.text = self.m_selectCommand
                --self.m_inputBox:Select()
                self.m_inputBox:ActivateInputField()
                self.m_selectCommand = nil
                self.m_consoleList:UpdateData(true)
                --self.m_inputBox:MoveToEndOfLine()
                self.m_moveToEnd = true
            end
        end
    end
end

function CheatUIView:OnExit()
    self.super:OnExit(self)
    GameConfig.showfps = false
    if self.m_updateTimer then
        GameTimer:StopTimer(self.m_updateTimer)
        self.m_updateTimer = nil
    end
end

return CheatUIView