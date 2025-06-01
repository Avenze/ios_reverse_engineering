local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")


local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local MainUI = GameTableDefine.MainUI
local StarMode = GameTableDefine.StarMode
local ConfigMgr = GameTableDefine.ConfigMgr
local CountryMode = GameTableDefine.CountryMode
local CityMode = GameTableDefine.CityMode
local ResourceManger = GameTableDefine.ResourceManger
local CityMapUI = GameTableDefine.CityMapUI

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local GameObject = CS.UnityEngine.GameObject


local WorldListUIView = Class("WorldListUIView", UIView)

function WorldListUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function WorldListUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/HeadPanel/btn_close","Button"), function() 
        self:DestroyModeUIObject()
    end)
    self:InitCfg()
    self:refresh()

end

function WorldListUIView:OnExit()
	self.super:OnExit(self)
end

function WorldListUIView:InitCfg()
    self.m_countryCfg = ConfigMgr.config_country
end

function WorldListUIView:refresh()
    self:SetTempGo("RootPanel/MidPanel/country", Tools:GetTableSize(self.m_countryCfg), function(index, go)
        self:SetTemp(index, go)
    end)
    self:SetSprite(self:GetComp("RootPanel/res/c/icon", "Image"), "UI_Main", CountryMode.cash_icon, nil, true)
    self:SetText("RootPanel/res/lvl/num", StarMode:GetStar())
    self:SetText("RootPanel/res/c/num", Tools:SeparateNumberWithComma(ResourceManger:GetLocalMoney()))
    self:SetText("RootPanel/res/d/num", Tools:SeparateNumberWithComma(ResourceManger:GetDiamond()))
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function WorldListUIView:SetTempGo(path ,num, cb)    
    local temp = self:GetGo(path)
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    for i = 1,num do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        go:SetActive(true)
        go.name = "temp" .. i
        cb(i, go)        
    end          
end

--对单个temp进行设置
function WorldListUIView:SetTemp(index, go)
    local cfg = self.m_countryCfg[index]
    local current = self:GetGo(go,"state/current")
    --local unlocked = self:GetGo(go,"state/unlocked")
    local locked = self:GetGo(go,"state/locked")    
    local gotoBtn = self:GetComp(go, "gotoBtn", "Button")       
    local countryName = GameTextLoader:ReadText(cfg.name)
    local isCurrCountry = CountryMode:GetCurrCountry() == index
    local starEnough = cfg.starNeed <= StarMode:GetStar()
    local countryImage = self:GetComp(go, "icon", "Image")
    self:SetSprite(countryImage, "UI_Common", cfg.icon)
    self:SetText(go, "name", countryName)
    self:SetText(go, "desc", GameTextLoader:ReadText(cfg.desc))
    self:SetText(go, "state/locked/icon/lvl",cfg.starNeed)
    gotoBtn.interactable = starEnough and not isCurrCountry
    current:SetActive(isCurrCountry)
    gotoBtn.gameObject:SetActive(not isCurrCountry)
    --unlocked:SetActive(starEnough and not isCurrCountry)
    --unlocked:SetActive(false)
    locked:SetActive(not starEnough and not isCurrCountry)
    --切换到新的区域的主房间里
    if index == 1 then --因为之前没有考虑扩展新地区所以做的处理
        countryName = ""
    end
    self:SetButtonClickHandler(gotoBtn, function()
        self:DestroyModeUIObject()        
        CountryMode:SetCurrCountry(index)            
        GreateBuildingMana:RefreshImprove()                                             
        CityMapUI:ToggleCountryMap()                    
    end)    
end

return WorldListUIView