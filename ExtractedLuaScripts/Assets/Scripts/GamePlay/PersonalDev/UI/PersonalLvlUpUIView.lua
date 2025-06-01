--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-20 10:12:47
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local ConfigMgr = GameTableDefine.ConfigMgr
local PersonalDevModel = GameTableDefine.PersonalDevModel

local PersonalLvlUpUIView = Class("PersonalLvlUpUIView", UIView)

function PersonalLvlUpUIView:ctor()
    self.super:ctor()
end

function PersonalLvlUpUIView:OnEnter()
    self.super:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/btn", "Button"), function()
        self:DestroyModeUIObject()
    end)
    local curDevCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    if not curDevCfg then
        self:DestroyModeUIObject()
        return
    end
    --新的名人称号、图标、处理的最大事务数
    self:SetText("RootPanel/info_area/title/txt", GameTextLoader:ReadText(curDevCfg.name))
    self:SetSprite(self:GetComp("RootPanel/info_area/title/level/icon", "Image"), "UI_Common", curDevCfg.title_icon)
    self:SetText("RootPanel/info_area/affair/num1", curDevCfg.affairs_limit)
    --TODO:后期需要添加解锁豪宅，车店，名人的显示

end

function PersonalLvlUpUIView:OnExit()
    self.super:OnExit(self)
end

return PersonalLvlUpUIView