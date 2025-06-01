---@class CycleNightClubPiggyBankUIView

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local CycleNightClubRankManager = GameTableDefine.CycleNightClubRankManager

local CycleNightClubPiggyBankUIView = Class("CycleNightClubPiggyBankUIView", UIView)
local ShopManager = GameTableDefine.ShopManager
local ConfigMgr = GameTableDefine.ConfigMgr
local AnimationUtil = CS.Common.Utils.AnimationUtil

function CycleNightClubPiggyBankUIView:ctor()
    self.super:ctor()

    self.m_piggyBankPriceText = nil ---小猪价格
    self.m_piggyBankOffsetValueText = nil ---小猪折扣
    self.m_piggyBankSlider = nil ---小猪进度条
    self.m_piggyBankSliderText1 = nil ---小猪进度条数值
    self.m_piggyBankSliderText2 = nil ---小猪进度条数值
    self.m_piggyBankCurValueText1 = nil ---小猪进度当前数值
    self.m_piggyBankCurValueText2 = nil ---小猪进度当前数值
    self.m_piggyBankCurValueText3 = nil ---小猪进度当前数值
    self.m_piggyBankMaxValueText1 = nil ---小猪进度达标数值
    self.m_piggyBankMaxValueText2 = nil ---小猪进度达标数值
end

function CycleNightClubPiggyBankUIView:OnEnter()
    self.super:OnEnter()

    self.m_piggyAnimation = self:GetComp("RootPanel/info/buff", "Animation")
    ShopManager:refreshBuySuccess(function(shopId)
        local curValue, maxValue, piggyBankInfo, piggyBankConf = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetPiggyBankValue()
        local award = piggyBankConf.reward

        self:GetComp("RootPanel/info/buff/vfx/num", "TMPLocalization").text = "+" .. tostring(award)
        AnimationUtil.Play(self.m_piggyAnimation, "cy_piggybank_open", function()
            ShopManager:Buy(shopId, false, function()
                --2025-4-29修正放到购买shopmanager里面，不放在UI上发放
                -- GameTableDefine.CycleInstanceDataManager:GetCurrentModel():BuySlotPiggyBank()
                GameTableDefine.CycleNightClubSlotMachineUI:RefreshPiggyBank()
                GameTableDefine.CycleNightClubMainViewUI:RefreshPiggyBank()

                -- 购买后，关闭界面，暂无需刷新其它数据
                --self:DestroyModeUIObject()
                self:InitPanelButton()
                self:RefreshPanelDisplay()
            end, function()

            end)
        end)
    end)
    
    ShopManager:refreshBuyFail(function(shopId)
        self.claimBtn.interactable = true
    end)

    self.m_piggyBankPriceText = self:GetComp("RootPanel/info/btn/buyBtn/text", "TMPLocalization")
    self.m_piggyBankOffsetValueText = self:GetComp("RootPanel/info/title/offvalue/num", "TMPLocalization")
    self.m_piggyBankSlider = self:GetComp("RootPanel/info/buff/Slider", "Slider")
    self.m_piggyBankSliderText1 = self:GetComp("RootPanel/info/buff/Slider/txt/txt1", "TMPLocalization")
    self.m_piggyBankSliderText2 = self:GetComp("RootPanel/info/buff/Slider/txt/txt3", "TMPLocalization")
    self.m_piggyBankCurValueText1 = self:GetComp("RootPanel/info/buff/bg/num/num_1", "TMPLocalization")
    self.m_piggyBankCurValueText2 = self:GetComp("RootPanel/info/buff/bg/num/num_2", "TMPLocalization")
    self.m_piggyBankCurValueText3 = self:GetComp("RootPanel/info/buff/bg/num/num_3", "TMPLocalization")
    self.m_piggyBankMaxValueText1 = self:GetComp("RootPanel/info/tip_txt/txt_1", "TMPLocalization")
    self.m_piggyBankMaxValueText2 = self:GetComp("RootPanel/info/tip_txt/txt_2", "TMPLocalization")

    self.claimBtn = self:GetComp("RootPanel/info/btn/buyBtn", "Button")

    self:SetButtonClickHandler(self:GetComp("RootPanel/bg", "Button"), function()
        self:DestroyModeUIObject()
    end)
    
    self:InitPanelButton()
    self:RefreshPanelDisplay(true)
    self.init = true
end

function CycleNightClubPiggyBankUIView:OnResume()
    if not self.init then
        return
    end
    
    self:RefreshPanelDisplay()
    self:InitPanelButton()
end

function CycleNightClubPiggyBankUIView:RefreshPanelDisplay(open_page)
    local curValue, maxValue, piggyBankInfo, piggyBankConf = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetPiggyBankValue()
    if not curValue or not maxValue or curValue < 0 then
        self:DestroyModeUIObject()
        return
    end

    -- 存满，未弹
    if curValue == maxValue and not piggyBankInfo.show_time[tostring(piggyBankInfo.lv)] then
        GameTableDefine.CycleInstanceDataManager:GetCurrentModel():ShowPiggyBankFirst()
    end
    
    self.m_piggyBankPriceText.text = GameTableDefine.Shop:GetShopItemPrice(piggyBankConf.shop_id)
    self.m_piggyBankOffsetValueText.text = piggyBankConf.disNum
    self.m_piggyBankSlider.value = math.min(1, curValue / maxValue)
    self.m_piggyBankCurValueText1.text = piggyBankConf.reward
    self.m_piggyBankCurValueText2.text = piggyBankConf.reward
    self.m_piggyBankCurValueText3.text = piggyBankConf.reward
    
    self.m_piggyBankSliderText1.text = curValue
    self.m_piggyBankSliderText2.text = maxValue

    --self.m_piggyBankMaxValueText1.text = string.format(self.m_piggyBankMaxValueText1.text, tostring(maxValue))
    --self.m_piggyBankMaxValueText2.text = string.format(self.m_piggyBankMaxValueText2.text, tostring(maxValue))
    self.m_piggyBankMaxValueText1.text = string.format(GameTextLoader:ReadText("TXT_INSTANCE_CY4_PIGGYBANK_DESC"), tostring(maxValue))
    self.m_piggyBankMaxValueText2.text = string.format(GameTextLoader:ReadText("TXT_INSTANCE_CY4_PIGGYBANK_DESC"), tostring(maxValue))

    AnimationUtil.Play(self.m_piggyAnimation, "cy_piggybank_init", function()
        self:GetGo("RootPanel/info/buff/bg"):SetActive(true)
    end)
    
    -- 打开界面时上报
    if open_page then
        GameSDKs:TrackForeign("cy_piggy", { id = piggyBankConf.id, state = curValue >= maxValue and 2 or 1, prog = curValue })
    end
end

function CycleNightClubPiggyBankUIView:InitPanelButton()
    local curValue, maxValue, piggyBankInfo, piggyBankConf = GameTableDefine.CycleInstanceDataManager:GetCurrentModel():GetPiggyBankValue()
    if not curValue or not maxValue or curValue < 0 then
        self:DestroyModeUIObject()
        return
    end

    self.claimBtn.interactable = curValue >= maxValue
    self:SetButtonClickHandler(self.claimBtn, function()
        GameTableDefine.Shop:CreateShopItemOrder(piggyBankConf.shop_id, self.claimBtn)
        self.claimBtn.interactable = false
    end)

    local slotBtn = self:GetComp("RootPanel/info/btn/skipBtn", "Button")
    self:SetButtonClickHandler(slotBtn, function()
        GameTableDefine.CycleNightClubSlotMachineUI:OpenView()
        GameTableDefine.GameUIManager:SetUITop(ENUM_GAME_UITYPE.CYCLE_NIGHT_CLUB_SLOT_MACHINE, true)
        GameTableDefine.GameUIManager:SetUITop(ENUM_GAME_UITYPE.FLY_ICONS_UI, true)
    end)
end

function CycleNightClubPiggyBankUIView:OnExit()
    --购买成功事件 反注册
    ShopManager:refreshBuySuccess()
    --购买失败事件 反注册
    ShopManager:refreshBuyFail()
    
    self.super:OnExit(self)
end

return CycleNightClubPiggyBankUIView