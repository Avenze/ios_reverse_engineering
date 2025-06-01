local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local ValueManager = GameTableDefine.ValueManager
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local PhoneUI = GameTableDefine.PhoneUI
local BankUI = GameTableDefine.BankUI
local MainUI = GameTableDefine.MainUI
local GameClockManager = GameTableDefine.GameClockManager
local BankUIView = Class("BankUIView", UIView)

function BankUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.rankData = {}
    self.dropDownValue = 1
end

function BankUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/bottom/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    self:CreateTimer(1000, function()
        local currH,currM = GameClockManager:GetCurrGameTime()
        local currM = string.format("%02d", currM)
        self:SetText("RootPanel/bottom/time", currH..":"..currM)
    end, true, true)
    local bankRoot = self:GetGo("RootPanel/panel/panel_cash")
    local rankRoot = self:GetGo("RootPanel/panel/panel_rank")
    local mineRoot = self:GetGo("RootPanel/panel/panel_mine")

    local btnBank = self:GetComp("RootPanel/head/tab_cash", "Button")
    local btnRank = self:GetComp("RootPanel/head/tab_rank", "Button")
    local btnMine = self:GetComp("RootPanel/head/tab_mine", "Button")

    self:RefreshCanLevelUp()
    self.dropDown = self:GetComp("RootPanel/panel/panel_cash/top/Dropdown", "Toggle")
    local dropDownList = self:GetGo("RootPanel/panel/panel_cash/Template")
    local dropDownItem = self:GetGo("RootPanel/panel/panel_cash/Template/Viewport/Content/Item")
    self:SetToggleValueChangeHandler(self.dropDown, function(isOn)
        dropDownList:SetActive(isOn)
        if isOn then
            local moneyConfig = ConfigMgr.config_money
            Tools:SetTempGo(dropDownItem, #moneyConfig, true, function(go, index)
                local moneyIcon = ResourceManger:GetResIcon(moneyConfig[index].resourceId)
                self:SetSprite(self:GetComp(go, "Item_Icon", "Image"), "UI_Shop", moneyIcon)
                self:GetGo(go, "notify"):SetActive(BankUI:CanLevelUpDepositLimit(index))
                self:SetButtonClickHandler(self:GetComp(go, "", "Button"), function()
                    self.dropDownValue = index
                    self:RefreshPersonInto()
                    self:RefreshBank(true)
                    self:InitRank()
                    self:RefreshRank()
                    self.dropDown.isOn = false
                    self:SetSprite(self:GetComp("RootPanel/panel/panel_cash/top/Dropdown/Image", "Image"), "UI_Shop", moneyIcon)
                end)
            end)
        else
            
        end
       
    end)
    
    --UnityHelper.SetDropdownValueChangeHandler(self.dropDown, function()        
    --    self:RefreshPersonInto()
    --    self:RefreshBank(true)
    --    self:InitRank()
    --    self:RefreshRank()
    --end)

    self:RefreshTabMineNotify()

    local skinName = "head_" .. LocalDataManager:GetBossSkin()
    local bossName = LocalDataManager:GetBossName() or ""
    
    local currImage = nil    
    currImage = self:GetComp(bankRoot, "top/head/inner", "Image")
    self:SetSprite(currImage, "UI_BG", skinName)
    self:SetText(bankRoot, "top/frame/name", bossName)

    currImage = self:GetComp(rankRoot, "info_player/head", "Image")
    self:SetSprite(currImage, "UI_BG", skinName)
    self:SetText(rankRoot, "info_player/name", bossName)

    currImage = self:GetComp(mineRoot, "top/head_player/inner", "Image")
    self:SetSprite(currImage, "UI_BG", skinName)
    self:SetText(mineRoot, "top/frame/name", bossName)

    local currRank = ValueManager:GetPlayerRank()
    local currValue = ValueManager:GetValue()
    local personRoot = self:GetGo(rankRoot.gameObject,"info_player")
    self:GetGo(personRoot, "rank"):SetActive(true)
    -- self:GetGo(personRoot, "notify"):SetActive(ValueManager:GetRankReward(true))
    self:SetText(personRoot, "wealth", BankUI:ValueToShow(currValue))
    if currRank ~= nil then
        self:GetGo(personRoot, "rank/1"):SetActive(currRank == 1)
        self:GetGo(personRoot, "rank/2"):SetActive(currRank == 2)
        self:GetGo(personRoot, "rank/3"):SetActive(currRank == 3)
        self:GetGo(personRoot, "rank/other"):SetActive(currRank ~= 1 and currRank ~= 2 and currRank ~= 3)
        self:SetText(personRoot, "rank/other", currRank)

        local imageLooser = self:GetComp(mineRoot, "frame/bottom/npc/head", "Image")
        local cfg = ConfigMgr.config_wealthrank
        local index = #cfg - currRank + 1
        local data = cfg[#cfg - currRank + 1]
        self:SetSprite(imageLooser, "UI_BG", data.head)

        local talk = GameTextLoader:ReadText(data.talk)
        talk = string.format(talk, GameTextLoader:ReadText(data.name))
        self:SetText(mineRoot, "frame/bottom/npc/dialog/txt", talk)
    else
        self:GetGo(personRoot, "rank/other"):SetActive(true)
        self:SetText(personRoot, "rank/other", "-")
    end

    --local btnPerson = self:GetComp(personRoot, "", "Button")
    -- if currRank ~= nil then
    --     local openFeed = self:GetComp(mineRoot.gameObject, "openFeedback", "MMFeedbacks")
    --     local closeFeed = self:GetComp(mineRoot.gameObject, "closeFeedback", "MMFeedbacks")
    --     openFeed:Initialization()
    --     closeFeed:Initialization()
    --     local btnBg = self:GetComp(mineRoot.gameObject, "bg", "Button")
    --     self:SetButtonClickHandler(btnPerson, function()
    --         --infoRoot:SetActive(true)
    --         btnBg.gameObject:SetActive(true)
    --         openFeed:PlayFeedbacks()
    --     end)

    --     self:SetButtonClickHandler(btnBg, function()
    --         --infoRoot:SetActive(false)
    --         btnBg.gameObject:SetActive(false)
    --         closeFeed:PlayFeedbacks()
    --     end)
    -- end

    self.bankFeed = self:GetComp("RootPanel/panel/panel_cash/applyFeedback", "MMFeedbacks")

    self.bankFeed:Initialization()

    self:RefreshPersonInto()
    self:RefreshBank(true)
    self:InitRank()
    self:RefreshRank()
end

---依据是否领取福布斯排行奖励来显示 Mine Notify.
function BankUIView:RefreshTabMineNotify()
    self:GetGo("RootPanel/head/tab_mine/notify"):SetActive(ValueManager:GetRankReward(true))
end

function BankUIView:OnExit()
	self.super:OnExit(self)
    self.bankFeed = nil
    self:StopTimer()
end

function BankUIView:RefreshPersonInto()
    local personRoot = self:GetGo("RootPanel/panel/panel_mine")
    local playerRank,defeat = ValueManager:GetPlayerRank()
    local totalValu, houValu, carValue = ValueManager:GetValue()
    if defeat == nil then
        playerRank = "-"
    end          
    self:SetText(personRoot, "top/cur_rank/num", playerRank)
    self:SetText(personRoot, "top/cur_wealth/num", BankUI:ValueToShow(totalValu))
                            
    self:SetText(personRoot, "mid/info_wealth/house/data/num", BankUI:ValueToShow(houValu))
    self:SetText(personRoot, "mid/info_wealth/car/data/num", BankUI:ValueToShow(carValue))

    if defeat ~= nil then
        local data = ConfigMgr.config_wealthrank[defeat]
        self:GetGo(personRoot, "down"):SetActive(true)
        if data then
            self:SetText(personRoot, "down/npc/dialog/txt", GameTextLoader:ReadText(data.talk))
            local head = self:GetComp(personRoot, "down/npc/head", "Image")
            self:SetSprite(head, "UI_BG", data.head)

            local txtRank = GameTextLoader:ReadText("TXT_TIP_RANK_CHANGE")
            txtRank = string.format(txtRank, GameTextLoader:ReadText(data.name))
            self:SetText(personRoot, "down/desc", txtRank)           
        end
    else
        self:GetGo(personRoot, "down"):SetActive(false)
    end
    local btnReward = self:GetComp(personRoot, "down/Button", "Button")
    local canReward,reward = ValueManager:GetRankReward(true)
    btnReward.gameObject:SetActive(canReward)
    if reward[5] and reward[5] > 0 then
        self:GetGo(btnReward.gameObject, "star"):SetActive(true)
        self:SetText(btnReward.gameObject, "star/lvl", reward[5])
    elseif reward[3] and reward[3] > 0 then
        self:GetGo(btnReward.gameObject, "d"):SetActive(true)
        self:SetText(btnReward.gameObject, "d/num", reward[3])
    end
    self:SetButtonClickHandler(btnReward, function()
        ValueManager:GetRankReward()
        btnReward.gameObject:SetActive(false)
        PhoneUI:Refresh()
        self:RefreshTabMineNotify()
    end)
end

function BankUIView:RefreshBank(open)
    local cashLv, currData, nextData = ValueManager:GetCashLevelData(self.dropDownValue)
    local cashRoot = self:GetGo("RootPanel/panel/panel_cash")
    local isMax,nextMax = false,false
    local showMax = false
    self:GetGo(cashRoot, "bottom/next/text2"):SetActive(true)
    self:GetGo(cashRoot, "bottom/requirement/star"):SetActive(true)
    self:GetGo(cashRoot, "bottom/requirement/text3"):SetActive(true)
    self:GetGo(cashRoot, "bottom/next/num2"):SetActive(true)
    if nextData == nil or nextData[ValueManager.limitKey[self.dropDownValue]] == nil then--满级
        nextData = {[ValueManager.limitKey[self.dropDownValue]] = "Max", fame = 1}
        --currData.cashLimit = "Max"
        isMax,nextMax = true,true
        showMax = isMax and currData[ValueManager.limitKey[self.dropDownValue]] == 0
        self:GetGo(cashRoot, "bottom/next/text2"):SetActive(false)
        self:GetGo(cashRoot, "bottom/requirement/star"):SetActive(false)
        self:GetGo(cashRoot, "bottom/requirement/text3"):SetActive(false)
        self:GetGo(cashRoot, "bottom/next/num2"):SetActive(false)
    elseif cashLv + 1 == Tools:GetTableSize(ConfigMgr.config_bank) then--下级就满级
        --nextData.cashLimit = "Max"
        nextMax = true
    end

    local currCash = ResourceManger:Get(ConfigMgr.config_money[self.dropDownValue].resourceId)
    self:SetText(cashRoot, "bottom/current/num1", showMax and "Max" or Tools:SeparateNumberWithComma(currData[ValueManager.limitKey[self.dropDownValue]]))
    self:SetText(cashRoot, "bottom/next/num2", isMax and "Max" or Tools:SeparateNumberWithComma(nextData[ValueManager.limitKey[self.dropDownValue]]))
    self:SetText(cashRoot, "bottom/requirement/star/lvl", nextData.fame)
    self:SetText(cashRoot, "mid/num", Tools:SeparateNumberWithComma(currCash))
    self:GetGo(cashRoot, "bottom/btn"):SetActive(isMax == false)
    self:GetGo(cashRoot, "bottom/max"):SetActive(isMax == true)

    local currCashImage = self:GetComp(cashRoot, "mid/cash_current", "Image")
    local currValue = 1
    if not showMax then
        currValue = currCash / (currData[ValueManager.limitKey[self.dropDownValue]] or 1)
    end
    if currValue > 1 then
        currValue = 1
    elseif currValue < 0.1 then
        currValue = 0.1
    end

    if open then
        currCashImage.fillAmount = currValue
    end

    local raiseAble = ValueManager:RaiseCashLevel(true, self.dropDownValue)
    local btnRaise = self:GetComp(cashRoot, "bottom/btn", "Button")
    btnRaise.interactable = raiseAble
    --self:GetGo("RootPanel/head/tab_cash/notify"):SetActive(ValueManager:RaiseCashLevel(true, self.dropDownValue))
    self:GetGo("RootPanel/head/tab_cash/notify"):SetActive(BankUI:GetBankNum() > 0)
    self:SetButtonClickHandler(btnRaise, function()
        ValueManager:RaiseCashLevel(nil, self.dropDownValue)

        if not ValueManager:RaiseCashLevel(true) then
            PhoneUI:Refresh()
            MainUI:SetPhoneNum()
        end

        self:RefreshBank()

        local nextValue = 1
        local showTxt = ""
        local cashLv, currData, nextData = ValueManager:GetCashLevelData()
        if nextData == nil then--满级
            isMax = true
            showMax = isMax and currData[ValueManager.limitKey[self.dropDownValue]] == 0
        end
        if not showMax then
            nextValue = currCash / (currData[ValueManager.limitKey[self.dropDownValue]] or 1)
        end
        if currValue < 0.1 then
            currValue = 0.1
        end
        showTxt = showMax and "Max" or Tools:SeparateNumberWithComma(currData[ValueManager.limitKey[self.dropDownValue]])
        self:SetFeelData(currValue, nextValue, showTxt)
        self.bankFeed:PlayFeedbacks()
        self:RefreshCanLevelUp()
    end)
end

function BankUIView:SetFeelData(from, to, nextText)
    if self.bankFeed == nil then
        return
    end

    local allFeels = self.bankFeed.Feedbacks
    local currFeel = allFeels[4]
    currFeel.RemapLevelZero = from
    currFeel.RemapLevelOne = to

    currFeel = allFeels[5]
    currFeel.NewText = nextText
end

function BankUIView:InitRank()
    self.rankList = self:GetComp("RootPanel/panel/panel_rank/RankList", "ScrollRectEx")
    self:SetListItemCountFunc(self.rankList, function()
        return #self.rankData
    end)
    self:SetListUpdateFunc(self.rankList, handler(self, self.UpdateRankItem))

end

function BankUIView:UpdateRankItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local currData = self.rankData[index]
    local data = ConfigMgr.config_wealthrank[currData.id]
    if data then
        self:GetGo(go, "bg/rank/1"):SetActive(index == 1)
        self:GetGo(go, "bg/rank/2"):SetActive(index == 2)
        self:GetGo(go, "bg/rank/3"):SetActive(index == 3)
        self:GetGo(go, "bg/rank/other"):SetActive(index ~= 1 and index ~= 2 and index ~= 3)
        self:SetText(go, "bg/rank/other", index)

        local head = self:GetComp(go, "bg/head", "Image")
        self:SetSprite(head, "UI_BG", data.head)
        self:SetText(go, "bg/name", GameTextLoader:ReadText(data.name))

        local valueShow = BankUI:ValueToShow(data.value)
        self:SetText(go, "bg/wealth", valueShow)
    elseif currData.isPlayer then--是玩家
        self:GetGo(go, "bg/rank/1"):SetActive(index == 1)
        self:GetGo(go, "bg/rank/2"):SetActive(index == 2)
        self:GetGo(go, "bg/rank/3"):SetActive(index == 3)
        self:GetGo(go, "bg/rank/other"):SetActive(index ~= 1 and index ~= 2 and index ~= 3)
        self:SetText(go, "bg/rank/other", index)

        local skinName = "head_" .. LocalDataManager:GetBossSkin()
        local bossName = LocalDataManager:GetBossName() or ""
        local currImage = self:GetComp(go, "bg/head", "Image")
        local currValue = ValueManager:GetValue()
        self:SetSprite(currImage, "UI_BG", skinName)
        self:SetText(go, "bg/name", bossName)
        self:SetText(go, "bg/wealth", BankUI:ValueToShow(currValue))
    end
end

function BankUIView:RefreshRank()
    local rankRoot = self:GetGo("RootPanel/panel/panel_rank")

    local cfg = ConfigMgr.config_wealthrank
    local data = {}
    for k,v in pairs(cfg) do
        table.insert(data, {id = v.id, value = v.value})
    end

    local playerValue = ValueManager:GetValue()
    if playerValue > data[1].value then
        table.insert(data, {id = 9999, value = playerValue, isPlayer = true})
    end

    table.sort(data, function(a,b)
        if a.value ~= b.value then
            return a.value > b.value
        else
            return a.id > b.id
        end
    end)

    self.rankData = data
    self.rankList:UpdateData()
end

function BankUIView:RefreshCanLevelUp()
    self:GetGo("RootPanel/panel/panel_cash/top/Dropdown/notify"):SetActive(BankUI:GetBankNum() > 0)
end

return BankUIView