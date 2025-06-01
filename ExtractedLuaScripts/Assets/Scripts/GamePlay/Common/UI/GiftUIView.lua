local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local ResourceManger = GameTableDefine.ResourceManger
local GiftUI = GameTableDefine.GiftUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local GiftUIView = Class("GiftUIView", UIView)



function GiftUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.configGift = ConfigMgr.config_gift
end

function GiftUIView:OnEnter()
    -- self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
    --     self:DestroyModeUIObject()
    -- end)

    self:SetButtonClickHandler(self:GetComp("BgCover","Button"), function()
        self:DestroyModeUIObject()
    end)

    self.input = self:GetComp("RootPanel/MidPanel/input", "TMP_InputField")
    local btn = self:GetComp("RootPanel/SelectPanel/ConfirmBtn", "Button")
    self:SetButtonClickHandler(btn, function()
        if ConfigMgr.config_global.enable_iap == 1 then
            btn.interactable = false
            if GameConfig:IsWarriorVersion() then
                GiftUI:GetCodeAward(self.input.text, function()
                    btn.interactable = true
                end)
            else
                GiftUI:HKGetCodeAward(self.input.text, function()
                   btn.interactable = true
                end)
            end
            -- GiftUI:GetCodeAward(self.input.text, function(successful)
            --     print(successful)
            --     -- if not successful then
            --     --     EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_REPEAT_INPUT"))
            --     --     return
            --     -- end                
            --     -- 如果这个码没被使用过
            --     if GiftUI:GetReward(self.input.text) then
            --         -- 发放道具
            --         local reward = GiftUI:giftReward(self.input.text)
            --             if reward[1] == 2  then --为 2 表示增加现金 
            --                 ResourceManger:AddDiamond(reward[2], nil, function()                                                       
            --                     EventManager:DispatchEvent("FLY_ICON", nil, 2, nil)
            --                     end,
            --                 true)                                     
            --             elseif reward[1] == 3 then --为 3 表示增加钻石
            --                 ResourceManger:AddDiamond(reward[2], nil, function()                                                       
            --                     EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
            --                     end,
            --                 true)                                                     
            --             elseif reward[1] == 4 then -- 为 4 表示获的商城中的某个商品
            --                 ShopManager:Buy(reward[2], false, nil,function()
            --                 PurchaseSuccessUI:SuccessBuy(reward[2])                    
            --             end)                               
            --         end
            --     end
                
            --     -- 消耗礼包码

            --     GiftUI:CostCodeAward(self.input.text)
            -- end)
        else
            local success = GiftUI:GetReward(self.input.text)
            if success then
                local reward = GiftUI:giftReward(self.input.text)
                EventManager:DispatchEvent("FLY_ICON", self:GetTrans("RootPanel/SelectPanel/ConfirmBtn").position,
                reward[1], reward[2])
            end
        end
    end)
end

function GiftUIView:OnExit()
    self.super:OnExit(self)
end

return GiftUIView