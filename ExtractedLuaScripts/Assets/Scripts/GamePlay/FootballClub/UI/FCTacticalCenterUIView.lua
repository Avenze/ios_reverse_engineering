local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local FootballClubModel = GameTableDefine.FootballClubModel
local FCTacticalCenterUI= GameTableDefine.FCTacticalCenterUI
local ResourceManger = GameTableDefine.ResourceManger

local FCTacticalCenterUIView = Class("FCTacticalCenterUIView", UIView)
function FCTacticalCenterUIView:ctor()
   self.super:ctor()
   self.m_data = {}
end
function FCTacticalCenterUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)
    local model = FCTacticalCenterUI:GetUIModel()
    self:SetText("RootPanel/title/bg/level", model.LV)    

    local selectedGo = self:GetGo("RootPanel/TranningPanel/levelup/selected")
    self:SetText(selectedGo, "req/cash/num", model.upgradeCash)
    self:SetText(selectedGo, "req/leagueLV/level", "联赛等级")
    self:SetText(selectedGo, "effect/num", "458%")
    self:SetButtonClickHandler(self:GetComp(selectedGo, "btnArea/useBtn", "Button"), function()
        ResourceManger:SpendLocalMoney(model.upgradeCash, nil, function(success)
            if success then
                FootballClubModel:RoomUpgrade(FCTacticalCenterUI.ROOM_NUM, function(success)            
                    if success then
                        FCTacticalCenterUI:RefreshUIModel()
                        self:OnEnter()  
                    end                  
                end)  
            end                    
        end) 
    end)
    
    self.m_list = self:GetComp("RootPanel/TranningPanel/product/scrollrect", "ScrollRectEx")
    self:SetListItemCountFunc(self.m_list, function()
        return #model.skillList
    end)
    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateSkillList))
    self:SetListItemNameFunc(self.m_list, function(index)       
        return "Item1"
    end) 
    self.m_list:UpdateData()
end 

function FCTacticalCenterUIView:UpdateSkillList(index, tran)
    index = index + 1
    local go = tran.gameObject
    self:SetText(go ,"bg/title/name", "战术名")
    self:SetText(go ,"bg/txt", "战术描述")
    self:SetText(go ,"bg/buff", "具体效果")
    self:SetSprite(self:GetComp(go ,"bg/iconbg/icon", "Button"), "UI_Common", "")                        
end    

function FCTacticalCenterUIView:OnExit()
   self.super:OnExit(self)
end

return FCTacticalCenterUIView
