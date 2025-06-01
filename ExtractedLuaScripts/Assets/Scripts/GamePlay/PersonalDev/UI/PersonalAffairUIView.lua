--[[
    个人事务处理的UIView
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-24 10:10:33
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local ConfigMgr = GameTableDefine.ConfigMgr
local PersonalDevModel = GameTableDefine.PersonalDevModel
local GameResMgr = require("GameUtils.GameResManager")
local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper
local EventManager = require("Framework.Event.Manager")
local ResourceManger = GameTableDefine.ResourceManger
local FlyIconsUI = GameTableDefine.FlyIconsUI
local PersonalAffairUIView = Class("PersonalAffairUIView", UIView)


function PersonalAffairUIView:ctor()
    self.super:ctor()
end

function PersonalAffairUIView:OnEnter()
    print("PersonalAffairUIView:OnEnter")
    self:SetButtonClickHandler(self:GetComp("RootPanel/title/bg/quit_btn/icon", "Button"), function()      
        GameTableDefine.PersonalAffairUI:CloseView()
    end)
    EventManager:RegEvent(GameEventDefine.PersonalDev_AffairCanUse, function()
        GameTableDefine.PersonalAffairUI:PlayTimeline("WorkTimeline")
        self:CheckAffairLimitDisplay()
        self:RefreshPersonalInfo()
        self:SetAnswerDisplay(PersonalDevModel:GetAffairsQueue())
    end)
    EventManager:RegEvent(GameEventDefine.PersonalDev_AffairRecover, function()
        self:RefreshPersonalInfo()
        self:SetAnswerDisplay(PersonalDevModel:GetAffairsQueue())
    end)
    --个人信息和资产的相关内容
    self:RefreshPersonalInfo()
end

function PersonalAffairUIView:OpenAffairUI(questionID)
    local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    if not devCfg then
        self:DestroyModeUIObject()
        return 
    end
    self:CheckAffairLimitDisplay()
    self:SetAnswerDisplay(questionID)
end

function PersonalAffairUIView:SetAnswerDisplay(questionID)
    local questCfg = ConfigMgr.config_affair[questionID]
    local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    if not questCfg or not devCfg then
        self:DestroyModeUIObject()
        return
    end
    local questionTitle = GameTextLoader:ReadText(questCfg.topic_desc)
    local answerTxts = {}
    for i = 1, questCfg.opion do
        table.insert(answerTxts, questCfg.opion_txt[i])
    end
    --初始化显示的内容
    --1TODO:当前支持率
    --2事务处理的次数和最大次数
    self:SetText("RootPanel/topic/title/num1", PersonalDevModel:GetCurAffairLimit())
    self:SetText("RootPanel/topic/title/num2", devCfg.affairs_limit)
    --3答题的标题
    self:SetText("RootPanel/topic/bg/txt", questionTitle)
    if not self.opionGos then
        self.opionGos = {}
        table.insert(self.opionGos, self:GetGo("RootPanel/topic/bg/opion/item"))
        table.insert(self.opionGos, self:GetGo("RootPanel/topic/bg/opion/item (1)"))
        table.insert(self.opionGos, self:GetGo("RootPanel/topic/bg/opion/item (2)"))
    end
    local questCfg = ConfigMgr.config_affair[questionID]
    local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    if not questCfg or not devCfg then
        self:DestroyModeUIObject()
        return
    end
    if questCfg.opion > 3 then
        local addGo = CS.UnityEngine.GameObject.Instantiate(self.opionGos[1])
        table.insert(self.opionGos, addGo)
    end

    for i = 1, Tools:GetTableSize(self.opionGos) do
        if i <= questCfg.opion then
            local answerTxt = GameTextLoader:ReadText(questCfg.opion_txt[i])
            self:SetText(self.opionGos[i], "txt", answerTxt)
            local costEnough = true
            --判断消耗是否足够
            if Tools:GetTableSize(questCfg.option_cost[i]) > 1 then
                if not PersonalDevModel:CheckAffairProcessResEnough(questCfg.option_cost[i][1], questCfg.option_cost[i][2]) then
                    costEnough = false
                    break
                end
            end
            ---TODO需要做对应的亲密度的检测
            local SubBtn = self:GetComp(self.opionGos[i], "", "Button")
            if SubBtn then
                SubBtn.interactable = costEnough and PersonalDevModel:GetCurAffairLimit() > 0
                if costEnough then
                    self:SetButtonClickHandler(SubBtn, function()
                        print("Process Affair submit answerIndex is:"..i)
                        PersonalDevModel:ComplateCurAffair(i)
                        SubBtn.interactable = false
                        self:RefreshPersonalInfo()
                        self:SetAnswerDisplay(PersonalDevModel:GetAffairsQueue())
                        self:CheckAffairLimitDisplay()
                        if PersonalDevModel:GetCurAffairLimit() <= 0 then
                            GameTableDefine.PersonalAffairUI:PlayTimeline("RestTimeline")
                        end
                    end)
                end
            end
            --消耗、收益和名人好感度显示
            local costGo = self:GetGoOrNil(self.opionGos[i], "effect/cost")
            local rewardsGo = self:GetGoOrNil(self.opionGos[i], "effect/rewards")
            local needGo = self:GetGoOrNil(self.opionGos[i], "effect/need")
            costGo:SetActive(Tools:GetTableSize(questCfg.option_cost[i]) > 1)
            rewardsGo:SetActive(Tools:GetTableSize(questCfg.option_rewards[i]) > 1)
            needGo:SetActive(Tools:GetTableSize(questCfg.option_need[i]) > 1)
            if Tools:GetTableSize(questCfg.option_cost[i]) > 1 then
                --设置消耗的数值
                local tmpStr = "-" .. tostring(questCfg.option_cost[i][2])
                self:SetText(self.opionGos[i], "effect/cost/num1", tmpStr)
            end
            if Tools:GetTableSize(questCfg.option_rewards[i]) > 1 then
                --显示获取奖励的数值
                local tmpStr = "+" .. tostring(questCfg.option_rewards[i][2])
                self:SetText(self.opionGos[i], "effect/rewards/num1", tmpStr)
            end
            if Tools:GetTableSize(questCfg.option_need[i]) > 1 then
                --显示需要的条件，人物亲密度
                self:SetText(self.opionGos[i], "effect/need/num1", tostring(questCfg.option_need[i][2]))
            end
        else
            self.opionGos[i]:SetActive(false)
        end
    end

end

function PersonalAffairUIView:RefreshPersonalInfo()
    --头像
    local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    if not devCfg then
        self:DestroyModeUIObject()
        return
    end
    self:SetSprite(self:GetComp("RootPanel/res/CurrStarFrame/head/mask/icon", "Image"), "UI_Shop", PersonalDevModel:GetCurrHeadIconStr())
    --星级
    self:SetText("RootPanel/res/CurrStarFrame/star/lvl", GameTableDefine.StarMode:GetStar())
    --钞票
    local curCashIcon = "icon_UI_greenback"
    local curCahsNum = GameTableDefine.ResourceManger:GetCash()
    local diamondNum = GameTableDefine.ResourceManger:GetDiamond()
    if GameTableDefine.CountryMode:GetCurrCountry() == 2 then
        curCashIcon = "icon_UI_euro"
        curCahsNum = GameTableDefine.ResourceManger:GetEuro()
    end
    self:SetSprite(self:GetComp("RootPanel/res/MoneyInterface/icon", "Image"), "UI_Main", GameTableDefine.CountryMode.cash_icon)
    self:SetText("RootPanel/res/MoneyInterface/num", Tools:SeparateNumberWithComma(curCahsNum))
    self:SetText("RootPanel/res/DiamondInterface/num", Tools:SeparateNumberWithComma(diamondNum))
    local supportSlider = self:GetComp("RootPanel/prog/Slider", "Slider")
    local supportValue = PersonalDevModel:GetSupportCount()
        local nextDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle() + 1]
        local levelStageCfg = ConfigMgr.config_stage[PersonalDevModel:GetTitle() + 1]
        if nextDevCfg and levelStageCfg then
            --如果有stage配置的设置方式
            local curStageCfg = levelStageCfg[PersonalDevModel:GetStage()]
            if not curStageCfg then
                curStageCfg = levelStageCfg[PersonalDevModel:GetStage() - 1]
            end
            if curStageCfg and nextDevCfg.stage > 0 and nextDevCfg.stage == Tools:GetTableSize(levelStageCfg) then
                local supportMax = curStageCfg.suppertorcount_limit
                local progressValue = supportValue / supportMax
                if progressValue > 1 then
                    progressValue = 1
                end
                supportSlider.value = progressValue
                self:SetText("RootPanel/prog/Slider/txt/num1", supportValue)
                self:SetText("RootPanel/prog/Slider/txt/num2", supportMax)
                --设置相关的Stage显示和按钮内容
            else
                supportSlider.value = 0
                self:SetText("RootPanel/prog/Slider/txt/num1", 0)
                self:SetText("RootPanel/prog/Slider/txt/num2", 0)
            end
        else
            self:SetText("RootPanel/prog/Slider/txt/num1", supportValue)
            self:SetText("RootPanel/prog/Slider/txt/num2", supportValue)
            supportSlider.value = 1
        end
end

function PersonalAffairUIView:OnExit()
    self.super:OnExit(self)
    if self.m_recoverTimer then
        GameTimer:StopTimer(self.m_recoverTimer)
        self.m_recoverTimer = nil
    end
    EventManager:UnregEvent(GameEventDefine.PersonalDev_AffairCanUse)
    EventManager:UnregEvent(GameEventDefine.PersonalDev_AffairRecover)
    GameTableDefine.PersonalInfoUI:OpenPersonalInfoUI()
end

function PersonalAffairUIView:TimeHeartRecover()
    local timeRemaining = PersonalDevModel:GetAffairsCD()
    local timeStr = tostring(GameTimeManager:FormatTimeLength(timeRemaining))
    if PersonalDevModel:GetCurAffairLimit() <= 0 then
        self:SetText("RootPanel/topic/empty/txt2/num", timeStr)
    end
end

function PersonalAffairUIView:CheckAffairLimitDisplay()
    PersonalDevModel:RefreshAffairBuyData()
    self:GetGo("RootPanel/energyPanel"):SetActive(false)
    local isHaveAffairLimit = PersonalDevModel:GetCurAffairLimit() > 0
    self:GetGo("RootPanel/topic/bg"):SetActive(isHaveAffairLimit)
    self:GetGo("empty"):SetActive(not isHaveAffairLimit)
    self:GetGo("RootPanel/topic/title/empty"):SetActive(not isHaveAffairLimit)
    self:GetGo("RootPanel/topic/empty"):SetActive(not isHaveAffairLimit)
    if not self.m_recoverTimer then
        self.m_recoverTimer = GameTimer:CreateNewTimer(1, handler(self,self.TimeHeartRecover), true, true)
    end
    local buyBtn = self:GetComp("RootPanel/topic/empty/purchase/btn", "Button")
    buyBtn.interactable = PersonalDevModel:CheckAffairCanBuy(1)
    self:SetButtonClickHandler(self:GetComp("RootPanel/topic/empty/purchase/btn", "Button"), function()
        self:OpenAffairLimitBuy()
    end)
    self:GetGo("RootPanel/topic/empty/purchase/txt/buy"):SetActive(PersonalDevModel:CheckAffairCanBuy(1))
    self:GetGo("RootPanel/topic/empty/purchase/txt/dissabled"):SetActive(not PersonalDevModel:CheckAffairCanBuy(1))
end

function PersonalAffairUIView:OpenAffairLimitBuy()
    self:GetGo("RootPanel/energyPanel"):SetActive(true)
    self:SetText("RootPanel/energyPanel/info/content/bg/income/limit/num1", PersonalDevModel:GetCurBuyAffairTimes())
    self:SetText("RootPanel/energyPanel/info/content/bg/income/limit/num2", ConfigMgr.config_global.affairs_property.buyMaxLimit)
    self:SetButtonClickHandler(self:GetComp("RootPanel/energyPanel/bg", "Button"), function()
        self:GetGo("RootPanel/energyPanel"):SetActive(false)
    end)
    local curDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    local curMaxAffairs = 3
    if curDevCfg then
        curMaxAffairs = curDevCfg.affairs_limit
    end
    local curAffairs = PersonalDevModel:GetCurAffairLimit()
    local buyTimeTxt = self:GetComp("RootPanel/energyPanel/info/content/bg/income/BtnArea/times/num", "TextMeshProUGUI")
    local curBuyTimes = 1
    local isCanBuy = (curMaxAffairs - curAffairs + curBuyTimes) > 0 and PersonalDevModel:CheckAffairCanBuy(curBuyTimes)
    local costDiamond = curBuyTimes * ConfigMgr.config_global.affairs_property.diamond
    self:SetText("RootPanel/energyPanel/info/content/bg/income/BtnArea/BuyBtn/text", tostring(costDiamond))
    local addBtn = self:GetComp("RootPanel/energyPanel/info/content/bg/income/BtnArea/times/btn2", "Button")
    local subBtn = self:GetComp("RootPanel/energyPanel/info/content/bg/income/BtnArea/times/btn1", "Button")
    local buyBtn = self:GetComp("RootPanel/energyPanel/info/content/bg/income/BtnArea/BuyBtn", "Button")
    buyBtn.interactable = isCanBuy and costDiamond <= ResourceManger:GetDiamond()
    self:SetButtonClickHandler(addBtn, function()
        curBuyTimes = curBuyTimes + 1
        if curBuyTimes > curMaxAffairs then
            curBuyTimes = curMaxAffairs
        end
        if not PersonalDevModel:CheckAffairCanBuy(curBuyTimes) then
            local leftTimes = ConfigMgr.config_global.affairs_property.buyMaxLimit - PersonalDevModel:GetCurBuyAffairTimes()
            if curBuyTimes > leftTimes then
                curBuyTimes = leftTimes
            end
        end
        RefreshBuyInfoDisp()
    end) 
    
    self:SetButtonClickHandler(subBtn, function()
        curBuyTimes = curBuyTimes - 1
        if curBuyTimes < 1 then
            curBuyTimes = 1
        end
        if not PersonalDevModel:CheckAffairCanBuy(curBuyTimes) then
            local leftTimes = ConfigMgr.config_global.affairs_property.buyMaxLimit - PersonalDevModel:GetCurBuyAffairTimes()
            if curBuyTimes > leftTimes then
                curBuyTimes = leftTimes
            end
        end
        RefreshBuyInfoDisp()
    end)
    
    self:SetButtonClickHandler(buyBtn, function()
        if costDiamond <= ResourceManger:GetDiamond() and PersonalDevModel:CheckAffairCanBuy(curBuyTimes) then
            ResourceManger:SpendDiamond(costDiamond)
            PersonalDevModel:BuyAffairTimes(curBuyTimes)
            self:GetGo("RootPanel/energyPanel"):SetActive(false)
        end
    end)

    function RefreshBuyInfoDisp()
        buyTimeTxt.text = tostring(curBuyTimes)
        isCanBuy = (curMaxAffairs - curAffairs + curBuyTimes) > 0
        costDiamond = curBuyTimes * ConfigMgr.config_global.affairs_property.diamond
        self:SetText("RootPanel/energyPanel/info/content/bg/income/BtnArea/BuyBtn/text", tostring(costDiamond))
        buyBtn.interactable = isCanBuy and costDiamond <= ResourceManger:GetDiamond()
    end
end

return PersonalAffairUIView