local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ChatUI = GameTableDefine.ChatUI
local GameClockManager = GameTableDefine.GameClockManager
local BankUI = GameTableDefine.BankUI

local PhoneUIView = Class("PhoneUIView", UIView)

function PhoneUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function PhoneUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("down/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    self:CreateTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/head/time", currH..":"..currM)
    end, true, true)

    self:InitList()
end

function PhoneUIView:Refresh(data, downId)
    self.mData = data
    -- 加一个写死的，判断玩家是否开启欧洲场景来显示汇率按钮的判断2022-10-26
    local cityData = LocalDataManager:GetDataByKey("city_record_dataEurope")
    if not cityData or not cityData.district then
        if not cityData.district or not cityData.district.currId or cityData.district.currId < 1007 then
            if #self.mData >= 3 then
                table.remove(self.mData, 3)
            end
        end
    end 
    self.downApp = downId
    self.mList:UpdateData()
end

function PhoneUIView:OnExit()
    self.super:OnExit(self)
    self:StopTimer()
end

function PhoneUIView:InitList()
    self.mList = self:GetComp("RootPanel/AppList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.mData
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
end

function PhoneUIView:UpdateListItem(index, tran)
    local imageName = {"icon_app_chat", "icon_app_bank", "icon_app_exchange"}
    local itemTxt = {"CHAT", "BANK", "EXCHANGE"}
    local tempData = {
        {name = "互动事件", openView = "ChatUI"},
        {name = "银行", openView = "BankUI"},
        {name = "汇率兑换", openView = "ExchangeUI"},
    }
    index = index + 1
    local go = tran.gameObject
    local currAppId = self.mData[index]
    local currData = tempData[currAppId]
    if currAppId then
        local itemName = "TXT_APP_"..itemTxt[currAppId]
        itemName = GameTextLoader:ReadText(itemName)
        self:SetText(go, "name", itemName)

        local iconImage = self:GetComp(go, "selected/icon", "Image")
        self:SetSprite(iconImage, "UI_Common", imageName[currAppId])

        local button = self:GetComp(go, "selected", "Button")
        self:SetButtonClickHandler(button, function()
            GameTableDefine[currData.openView]:GetView()
        end)

        if currAppId == self.downApp then
            local ani = self:GetComp(go, "", "Animation")
            AnimationUtil.Play(ani, "AppDownLoad")
        end

        local hit = self:GetGo(go, "selected/level")
        hit:SetActive(currAppId == 1)
        if currAppId == 1 then--chat需要显示红点
            local activeNum = ChatUI:GetActiveChatNum()
            hit:SetActive(activeNum > 0)
            self:SetText(hit, "num", activeNum)
        elseif currAppId == 2 then
            local activeNum = BankUI:GetBankNum() + BankUI:GetRankNum()
            hit:SetActive(activeNum > 0)
            self:SetText(hit, "num", activeNum)
        end
        
    end
end

return PhoneUIView