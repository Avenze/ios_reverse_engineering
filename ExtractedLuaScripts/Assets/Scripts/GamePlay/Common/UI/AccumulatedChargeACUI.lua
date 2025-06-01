--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-12-22 11:43:22
]]
---@class AccumulatedChargeACUI
local AccumulatedChargeACUI = GameTableDefine.AccumulatedChargeACUI
local ValueManager = GameTableDefine.ValueManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ShopManager = GameTableDefine.ShopManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local AccumulatedChargeActivityDataManager = GameTableDefine.AccumulatedChargeActivityDataManager
local GameLauncher = CS.Game.GameLauncher
local StarMode = GameTableDefine.StarMode
local UIPopManager = GameTableDefine.UIPopupManager

function AccumulatedChargeACUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI, self.m_view, require("GamePlay.Common.UI.AccumulatedChargeACUIView"), self, self.CloseView)
    return self.m_view
end

function AccumulatedChargeACUI:OpenView()
    self:GetView()
end

function AccumulatedChargeACUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI)
    self.m_view = nil
    collectgarbage("collect")
    UIPopManager:DequeuePopView(self)
end

function AccumulatedChargeACUI:RefreshAllItems()
    if self.m_view then
        self.m_view:RefreshAllItems();
    end
end

function AccumulatedChargeACUI:AfterBuyCallback(itemID, isSuccess)
    if self.m_view then
        self.m_view:AfterBuyCallback(itemID, isSuccess)
    end
end

function AccumulatedChargeACUI:OpenPanel()
    local AccumulatedChargeData = AccumulatedChargeActivityDataManager.m_accChargeACData
    local enterDay = AccumulatedChargeActivityDataManager:CheckIsFirstEnterAccCharge()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not AccumulatedChargeData or (enterDay == day) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if self.waitOpenTimer then
        return
    end
    if StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
            GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI) then
        self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(1000,function()
            --GameTimer:StopTimer(self.waitOpenTimer)
            self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(100,function()
                if not (StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
                        GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI)) then
                    if enterDay ~= day then
                        self:OpenView()
                    end
                    GameTimer:StopTimer(self.waitOpenTimer)
                    self.waitOpenTimer = nil
                end
            end, true)
        end)
        return
    end
    if enterDay ~= day and not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI) then
        self:OpenView()
    end

end

function AccumulatedChargeACUI:CheckCanOpen()
    if not GameTableDefine.ActivityRemoteConfigManager:CheckPackEnable(GameTableDefine.TimeLimitedActivitiesManager.GiftPackType.AccumulatedCharge) then
        return false
    end
    local AccumulatedChargeData = AccumulatedChargeActivityDataManager.m_accChargeACData
    local enterDay = AccumulatedChargeActivityDataManager:CheckIsFirstEnterAccCharge()
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if not AccumulatedChargeData or (enterDay == day) then
        return false
    end
    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return false
    end
    if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI) then
        return false
    end
    
    return true
end