    --[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-08 19:59:20
    description:{description}
]]

--UIView
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local UI = GameTableDefine.InstanceAdUI
local ChooseUI = GameTableDefine.ChooseUI
local InstanceMainViewUI = GameTableDefine.InstanceMainViewUI
local CityModel = GameTableDefine.CityMode
local InstanceModel = GameTableDefine.InstanceModel


local InstnaceAdUIView = Class("InstnaceAdUIView", UIView)

function InstnaceAdUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function InstnaceAdUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/MidPanel/btn/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)

    local adBtn = self:GetComp("RootPanel/MidPanel/btn/ConfirmBtn/Button","Button")
    self:SetButtonClickHandler(adBtn,function()
        UI:ClaimResource(function()
            --通知npc回去
            InstanceModel:EventInstanceBack()
            InstanceMainViewUI:SetEventIAAActive(false)

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

function InstnaceAdUIView:ShowView()
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

        local instanceBind = GameTableDefine.InstanceDataManager:GetInstanceBind()
        self:SetSprite(self:GetComp(go, "icon", "Image"), "UI_Common", instanceBind.cashIcon)
        self:SetText(go,"num",Tools:SeparateNumberWithComma(math.floor(self.m_model.money)))
    end )
end

function InstnaceAdUIView:OnExit()
	self.super:OnExit(self)
end

return InstnaceAdUIView