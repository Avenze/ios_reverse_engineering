local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")

local UnityHelper = CS.Common.Utils.UnityHelper

local GameUIManager = GameTableDefine.GameUIManager

---@class CommonRewardUIView:UIBaseView
local CommonRewardUIView = Class("CommonRewardUIView", UIView)
local TimeInterval = 0.18

function CommonRewardUIView:ctor()
    self.super:ctor()
    self.m_rewardDatas = nil
    self.m_itemGOs = {} ---@type UnityEngine.GameObject[]
    self.m_curIndex = 0

    self.m_showRewardTimer = nil
end

function CommonRewardUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("BgCover", "Button"), function()
        self:DestroyModeUIObject()
    end)
    self.m_itemPrefabGO = self:GetGoOrNil("background/MediumPanel/Scroll View/Viewport/Content/item")
    self.m_listRoomGO = self:GetGoOrNil("background/MediumPanel/Scroll View/Viewport/Content")
    --self.m_listContentRectTransform = self:GetComp(self.m_listRoomGO,"","ScrollRect")
    self.m_scrollRect = self:GetComp("background/MediumPanel/Scroll View","ScrollRect")
    self.m_itemGOs[1] = self.m_itemPrefabGO
    self.m_itemPrefabGO:SetActive(false)
end

function CommonRewardUIView:OnExit(view)

    if self.m_showRewardTimer then
        GameTimer:StopTimer(self.m_showRewardTimer)
        self.m_showRewardTimer = nil
    end

    self:getSuper(CommonRewardUIView).OnExit(self,self)
end

function CommonRewardUIView:UpdateRewardItem(index)

    local rewardData = self.m_rewardDatas[index]
    if not rewardData then
        return false
    end

    local itemGO = self.m_itemGOs[index]
    if not itemGO then
        itemGO = UnityHelper.CopyGameByGo(self.m_itemPrefabGO, self.m_listRoomGO)
        self.m_itemGOs[index] = itemGO
    end
    itemGO:SetActive(true)

    self:SetSprite(self:GetComp(itemGO, "icon", "Image"), "UI_Shop", rewardData.icon)
    self:SetText(itemGO, "bg/num", rewardData.num)

    --下一帧划到最下
    GameTimer:CreateNewMilliSecTimer(1,function()
        self.m_scrollRect.verticalNormalizedPosition = 0
    end)
    return true
end

function CommonRewardUIView:ShowRewardsOneByOne(allRewards)
    if not self.m_rewardDatas then
        self.m_rewardDatas = allRewards
        self.m_curIndex = 1
        if self.m_rewardDatas[1] then
            GameUIManager:SetEnableTouch(false,"奖励界面")
            self.m_showRewardTimer = GameTimer:CreateNewTimer(TimeInterval,function()
                if not self:UpdateRewardItem(self.m_curIndex) then
                    GameTimer:StopTimer(self.m_showRewardTimer)
                    self.m_showRewardTimer = nil
                    GameUIManager:SetEnableTouch(true,"奖励界面")
                else
                    self.m_curIndex = self.m_curIndex + 1
                end
            end,true,true)
        end
    else
        --添加进需要显示的列表
        for i,v in ipairs(allRewards) do
            self.m_rewardDatas[#self.m_rewardDatas + 1] = v
        end
    end
end

return CommonRewardUIView
