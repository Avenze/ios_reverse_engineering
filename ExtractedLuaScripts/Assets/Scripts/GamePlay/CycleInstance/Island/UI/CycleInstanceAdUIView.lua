--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-07-09 14:27:30
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local UI = GameTableDefine.CycleInstanceAdUI
local ChooseUI = GameTableDefine.ChooseUI
local CycleInstanceMainViewUI = GameTableDefine.CycleInstanceMainViewUI
local CityModel = GameTableDefine.CityMode
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager


local CycleInstnaceAdUIView = Class("CycleInstnaceAdUIView", UIView)

function CycleInstnaceAdUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function CycleInstnaceAdUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/btn/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    local adBtn = self:GetComp("RootPanel/MidPanel/btn/ConfirmBtn/Button","Button")
    self:SetButtonClickHandler(adBtn,function()
        UI:ClaimResource(function()
            --通知npc回去
            local currentModel = CycleInstanceDataManager:GetCurrentModel()
            currentModel:EventInstanceBack()
            GameTableDefine.CycleIslandMainViewUI:SetEventIAAActive(false)
            GameTableDefine.CycleIslandMainViewUI:Refresh()
            self:DestroyModeUIObject()
        end,
        function()
            if adBtn then
                adBtn.interactable = true
            end
        end,
        function()
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_AD"))
            if adBtn then
                adBtn.interactable = true
            end
        end,CityModel:GetCurrentBuilding())

    end)
    
    self.m_model = UI:GetUIModel()
    self:ShowView()
end

function CycleInstnaceAdUIView:ShowView()
    -- 显示资源item
    --local itme = self:GetGo("RootPanel/MidPanel/reward/item")
    --local res = {}
    --for i,v in pairs(self.m_model.resReward)  do
    --    if self.m_model.resReward[i] > 0 then
    --        res[#res + 1] = i
    --    end
    --end
    --Tools:SetTempGo(itme , #res ,true ,function (go, index)
    --    local resID =  res[index] 
    --    local num = self.m_model.resReward[resID]
    --    local resCfg = self.m_model.resConfig[resID]
    --    self:SetSprite(self:GetComp(go, "icon", "Image"), "UI_Common", resCfg.icon)
    --    self:SetText(go,"num",Tools:SeparateNumberWithComma(math.floor(num)))
    --end )
    
    -- 显示副本货币奖励
    local itme = self:GetGo("RootPanel/MidPanel/reward/item")

    Tools:SetTempGo(itme , 1 ,true ,function (go, index)
        --local money = 0
        --local resFormat = {}
        --for i,v in pairs(self.m_model.resReward) do
        --    resFormat[i] = {[i] = self.m_model.resReward[i]}
        --    money = money + self.m_model.resConfig[i].price * self.m_model.resReward[i]
        --end

        local instanceBind = GameTableDefine.CycleInstanceDataManager:GetInstanceBind()
        self:SetSprite(self:GetComp(go, "icon", "Image"), "UI_Common", instanceBind.cashIcon)
        self:SetText(go,"num",BigNumber:FormatBigNumber(self.m_model.money))
    end )
end

function CycleInstnaceAdUIView:OnExit()
	self.super:OnExit(self)
end

return CycleInstnaceAdUIView