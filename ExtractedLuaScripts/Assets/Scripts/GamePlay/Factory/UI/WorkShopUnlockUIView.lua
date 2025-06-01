local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")
local ResMgr = GameTableDefine.ResourceManger
local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local ConfigMgr = GameTableDefine.ConfigMgr
local FactoryMode = GameTableDefine.FactoryMode
local CfgMgr = GameTableDefine.ConfigMgr
local TimerMgr = GameTimeManager
local MainUI = GameTableDefine.MainUI

local Factory_RECORD = "factory"
local cfg = ConfigMgr.config_workshop

local WorkShopUnlockUIView = Class("WorkShopUnlockUIView", UIView)

function WorkShopUnlockUIView:ctor()
    self.super:ctor()
    self.m_data = {}


end

function WorkShopUnlockUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    self.m_factoryDate = LocalDataManager:GetDataByKey(Factory_RECORD)
    self.m_cfg = CfgMgr.config_workshop
    self.m_workShopData = {}

end


function WorkShopUnlockUIView:Refresh(workShopid)
    local thecfg = cfg[workShopid] 
    -- local Preview = self:GetComp("RootPanel/MidPanel/icon", "Image")
    -- self:SetSprite(Preview, "UI_Shop", thecfg.icon)
    self:SetText("RootPanel/MidPanel/info/room_name", GameTextLoader:ReadText(thecfg.name))
    self:SetText("RootPanel/MidPanel/info/desc", GameTextLoader:ReadText(thecfg.desc))
    self:SetText("RootPanel/MidPanel/requirement/license/num", thecfg.unlock_license[1])
    local timeTxt = GameTimeManager:FormatTimeLength(thecfg.unlock_times)
    self:SetText("RootPanel/MidPanel/requirement/time/num", timeTxt)
    self:SetText("RootPanel/MidPanel/requirement/cash/num", Tools:SeparateNumberWithComma(thecfg.unlock_cash[1]))
    local bulidBtn = self:GetComp("RootPanel/SelectPanel/bulidBtn", "Button")
    local Image = self:GetComp("RootPanel/MidPanel/icon", "Image")
    self:SetSprite(Image, "UI_Common", "icon_workshop_" .. thecfg.room_category[2])

    bulidBtn.interactable = FactoryMode:CanUnlock(workShopid)
    self:SetButtonClickHandler(bulidBtn, function()
        ResMgr:SpendLicense(thecfg.unlock_license[1],nil,function(isEnough)
            ResMgr:SpendCash(thecfg.unlock_cash[1],nil,function(isEnough)
                if isEnough then                                        
                    local theFactoryName = FactoryMode.m_cfg.mode_name
                    -- local workShopName = self.m_cfg[workShopid].object_name
                    local workShopName = tostring(workShopid)
                    self.m_factoryDate[theFactoryName][workShopName] = {}
                    LocalDataManager:WriteToFile() 
                    self.m_workShopData = self.m_factoryDate[theFactoryName][workShopName]
                    
                    --self.m_workShopData = self.m_factoryDate[self.m_cfg.mode_name][workShopid]
                    --记录修建开始时间的时间
                    self.m_workShopData["timePoint"] = TimerMgr:GetCurrentServerTime(true)
                    --将建筑的状态改为修建状态               
                    self.m_workShopData["state"] = 0
                    LocalDataManager:WriteToFile() 
                    --显示修建中的UI
                    
                    --刷新车间状态
                    FactoryMode:RefreshWorkshop(workShopid) 
                    
                    --刷新MainUI显示
                    MainUI:RefreshLicenseState()
                    GameSDKs:TrackForeign("cash_event", {type_new = 1, change_new = 1, amount_new = tonumber(thecfg.unlock_cash[1]) or 0, position = "["..tostring(workShopid).."]号工厂建筑解锁"})
                end
    
            end)
        end)
        self:DestroyModeUIObject()
    end)
end

function WorkShopUnlockUIView:OnExit()
	self.super:OnExit(self)
end

return WorkShopUnlockUIView