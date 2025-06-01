

local DiamondShopUI = GameTableDefine.DiamondShopUI
local DiamondRewardUI = GameTableDefine.DiamondRewardUI
local ResMgr = GameTableDefine.ResourceManger
local GameUIManager = GameTableDefine.GameUIManager
local FloorMode = GameTableDefine.FloorMode
local CfgMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI

local UIView = require("GamePlay.Common.UI.DiamondShopUIView")
local EventManager = require("Framework.Event.Manager")

function DiamondShopUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.DIAMOND_SHOP_UI, self.m_view, UIView, self, self.CloseView)
    return self.m_view
end

function DiamondShopUI:CloseView()
    GameSDKs:ClearRewardAd()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.DIAMOND_SHOP_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function DiamondShopUI:CheckFreeDiamond()
    local lcoalData = DiamondRewardUI:GetLocalData()
    local curData = DiamondRewardUI:GetDate()
    return lcoalData.free_reward_date ~= curData
end

function DiamondShopUI:CanWatchAd()
    local lcoalData = DiamondRewardUI:GetLocalData()
    local cdTime = math.max((lcoalData.video_diamond_time or 0) - GameTimeManager:GetCurrentServerTime(true), 0)
    return cdTime <= 0
end

function DiamondShopUI:ShowShopPanel()
    local lcoalData = DiamondRewardUI:GetLocalData()
    local diamondNumber = CfgMgr.config_global.free_diamond or 10
    local diamondTxt = "x "
    local ticketNumber = CfgMgr.config_global.ticket_number or 3
    local ticketTxt = "x "
    local ticketPrice = CfgMgr.config_global.ticket_price or 50
    local cdTime = math.max((lcoalData.video_diamond_time or 0) - GameTimeManager:GetCurrentServerTime(true), 0)
    local isFree = self:CheckFreeDiamond()
    if isFree then
        diamondNumber = CfgMgr.config_global.video_diamond or 10
    end
    self:GetView():Invoke("SetShopInfo", diamondTxt .. diamondNumber, ticketTxt .. ticketNumber, ticketPrice, isFree, cdTime)
end
function DiamondShopUI:RewardNum(isFree)
    --local isFree = self:CheckFreeDiamond()
    if isFree then
        return CfgMgr.config_global.free_diamond or 10
    end
    
    return CfgMgr.config_global.video_diamond or 10
end

function DiamondShopUI:ClaimDiamond(cb, onSuccess, onFail)
    local lcoalData = DiamondRewardUI:GetLocalData()
    local isFree = self:CheckFreeDiamond()
    if isFree then
        local diamondNumber = CfgMgr.config_global.free_diamond or 10
        ResMgr:AddDiamond(diamondNumber, ResMgr.EVENT_COLLECTION_DAILY_REWARDS, function(success)
            if success then
                if cb then cb() end
                -- GameSDKs:Track("get_diamond", {get = diamondNumber, left = ResMgr:GetDiamond(), get_way = "钻石商城"})
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石商城", behaviour = 1, num_new = tonumber(diamondNumber)})
                lcoalData.free_reward_date = DiamondRewardUI:GetDate()
                MainUI:RefreshDiamondShop()
                self:ShowShopPanel()
            end
        end, true)
    else
        local callback = function()
            local diamondNumber = CfgMgr.config_global.video_diamond or 10
            ResMgr:AddDiamond(diamondNumber, ResMgr.EVENT_COLLECTION_AD_REWARDS, function(success)
                if success then
                    if cb then cb() end
                    -- GameSDKs:Track("get_diamond", {get = diamondNumber, left = ResMgr:GetDiamond(), get_way = "钻石商城"})
                    GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "钻石商城", behaviour = 1, num_new = tonumber(diamondNumber)})
                    lcoalData.video_diamond_time = GameTimeManager:GetCurrentServerTime(true) + (CfgMgr.config_global.diamond_cooltime * Tools:GetCheat(3600, 1))
                    --lcoalData.current_level = math.min(#CfgMgr.config_global.diamond_layout, lcoalData.current_level + 1)
                    MainUI:RefreshDiamondShop()
                    self:ShowShopPanel()
                    --GameSDKs:Track("end_video", {ad_type = "奖励视频",video_id = 10002,name = GameSDKs:GetAdName(10002), current_money = ResMgr:GetCash()})
                end
            end, true)
        end
        GameSDKs:PlayRewardAd(callback, onSuccess, onFail, 10002)
    end
end

function DiamondShopUI:BuyTicket()
    --local lcoalData = DiamondRewardUI:GetLocalData()
    ResMgr:SpendDiamond(CfgMgr.config_global.ticket_price, ResMgr.EVENT_BUY_TICKET, function(success)
        if success then
            ResMgr:AddTicket(CfgMgr.config_global.ticket_number, ResMgr.EVENT_BUY_TICKET)
            -- GameSDKs:Track("cost_diamond", {cost = CfgMgr.config_global.ticket_price, left = ResMgr:GetDiamond(), cost_way = "购买广告券"})
            GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "购买广告券", behaviour = 2, num_new = tonumber(CfgMgr.config_global.ticket_price)})
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_BUY_SUCCESS"))
            MainUI:RefreshDiamondShop()
            self:ShowShopPanel()
        else
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_DIAMOND_LACK"))
        end
    end)
end
