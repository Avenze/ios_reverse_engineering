local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color
local Application = CS.UnityEngine.Application
local GameObject = CS.UnityEngine.GameObject

local ValueManager = GameTableDefine.ValueManager
local ShopManager = GameTableDefine.ShopManager
local ResourceManger = GameTableDefine.ResourceManger
local ConfigMgr = GameTableDefine.ConfigMgr
local MainUI = GameTableDefine.MainUI
local ActivityRankUI = GameTableDefine.ActivityRankUI
local ActivityRankRewardGetUI = GameTableDefine.ActivityRankRewardGetUI
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local ActivityRankUIView = Class("ActivityRankUIView", UIView)

function ActivityRankUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.rankData = {}
    self.refreshRankTimer = nil
    self.displayLeftTimeTimer = nil
    self.leftTime = 0
end

function ActivityRankUIView:OnEnter()
    self.super:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/QuitBtn", "Button"), function()
        ActivityRankUI:CloseView()
    end)
    self.playerInfoGo = self:GetGo("RootPanel/rank/RankList/player")
    self:SetRankAreaCode()
    --TODO:初始化各个控件
    print("ActivityRankUIView:OnEnter")
    --玩家自己的标签设置
    self:InitList()

    self:RefreshRank()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self:GetComp("RootPanel", "RectTransform"))
    if self.refreshRankTimer then
        GameTimer:StopTimer(self.refreshRankTimer)
        self.refreshRankTimer = nil
    end
    self.refreshRankTimer = GameTimer:CreateNewTimer(120, function()
        self:RefreshRank()
    end, true)

    if self.displayLeftTimeTimer then
        GameTimer:StopTimer(self.displayLeftTimeTimer)
        self.displayLeftTimeTimer = nil
    end
end

function ActivityRankUIView:NewActivityShow()
    self.leftTime = ActivityRankDataManager:GetCurrentLeftTime()
    self:SetText("RootPanel/banner/message/time/txt", GameTimeManager:FormatTimeLength(self.leftTime))
    self:GetGo("RootPanel/banner/message/time"):SetActive(self.leftTime > 0)
    self:GetGo("RootPanel/banner/message/end"):SetActive(self.leftTime <= 0)
    self:GetGo("RootPanel/btnArea"):SetActive(self.leftTime <= 0)
    self:GetGo("RootPanel/QuitBtn"):SetActive(self.leftTime > 0)
    self:SetButtonClickHandler(self:GetComp("RootPanel/btnArea/continueBtn", "Button"), function()
        self:GetRrewardBtnClick()
    end)
    if self.leftTime > 0 then
        self.displayLeftTimeTimer = GameTimer:CreateNewTimer(1, function()
            self:UpdateLeftTimeDisplay()
        end, true)
    end
    local playerData = ActivityRankDataManager:GetPlayerRankData()
    if playerData and playerData.id and playerData.value then
        GameSDKs:TrackForeign("rank_activity", {name = "DingShiHuoYue", operation = "1", rank_new = tonumber(playerData.id) or 0, score_new = tonumber(playerData.value) or 0})
    end
end

function ActivityRankUIView:LastActivityShow()
    self.leftTime = 0
    self:SetText("RootPanel/banner/message/time/txt", GameTimeManager:FormatTimeLength(self.leftTime))
    self:GetGo("RootPanel/banner/message/time"):SetActive(self.leftTime > 0)
    self:GetGo("RootPanel/banner/message/end"):SetActive(self.leftTime <= 0)
    self:GetGo("RootPanel/btnArea"):SetActive(self.leftTime <= 0)
    self:GetGo("RootPanel/QuitBtn"):SetActive(self.leftTime > 0)
    self:SetButtonClickHandler(self:GetComp("RootPanel/btnArea/continueBtn", "Button"), function()
        self:GetRrewardBtnClick()
    end)
    if self.leftTime > 0 then
        self.displayLeftTimeTimer = GameTimer:CreateNewTimer(1, function()
            self:UpdateLeftTimeDisplay()
        end, true)
    end
end

function ActivityRankUIView:OnExit()
    self.super:OnExit(self)
    if self.refreshRankTimer then
        GameTimer:StopTimer(self.refreshRankTimer)
        self.refreshRankTimer = nil
    end
    if self.displayLeftTimeTimer then
        GameTimer:StopTimer(self.displayLeftTimeTimer)
        self.displayLeftTimeTimer = nil
    end
end

function ActivityRankUIView:RefreshRank()
    -- print("ActivityRankUIView:RefreshRank:Refresh the ActiviRankUIVieow display")
    -- local cfg = ConfigMgr.config_wealthrank
    -- local data = {}
    -- for k, v in pairs(cfg) do
    --     table.insert(data, {id = v.id, value = v.value})
    -- end
    -- local playerValue = ValueManager:GetValue()
    -- if playerValue > data[1].value then
    --     table.insert(data, {id = 9999, value = playerValue, isPlayer = true})
    -- end
    -- table.sort(data, function(a, b)
    --     if a.value ~= b.value then
    --         return a.value > b.value
    --     else
    --         return a.id > b.id
    --     end
    -- end)
    self.rankData = ActivityRankDataManager:GetRankData()
    self.mList:UpdateData()
    local playerData = ActivityRankDataManager:GetPlayerRankData()
    if self.playerInfoGo and playerData then
        self:GetGo(self.playerInfoGo, "bg/rank/1"):SetActive(playerData.id == 1)
        self:GetGo(self.playerInfoGo, "bg/rank/2"):SetActive(playerData.id == 2)
        self:GetGo(self.playerInfoGo, "bg/rank/3"):SetActive(playerData.id == 3)
        self:GetGo(self.playerInfoGo, "bg/rank/other"):SetActive(playerData.id > 3)
        self:SetText(self.playerInfoGo, "bg/rank/other", playerData.id)
        local currImage = self:GetComp(self.playerInfoGo, "bg/head", "Image")
        local head = "head_"..LocalDataManager:GetBossSkin()
        local playername = LocalDataManager:GetBossName()
        self:SetSprite(currImage, "UI_BG", head)
        self:SetText(self.playerInfoGo, "bg/name", playername)
        self:SetText(self.playerInfoGo, "bg/num", ActivityRankUI:ValueToShow(playerData.value))
        if ConfigMgr.config_activityrank[playerData.id] and ConfigMgr.config_activityrank[playerData.id].reward > 0 and tostring(ConfigMgr.config_activityrank[playerData.id].reward_icon) ~= "0" then
            local image = self:GetComp(self.playerInfoGo, "bg/reward", "Image")
            self:GetGo(self.playerInfoGo, "bg/reward"):SetActive(true)
            if tostring(ConfigMgr.config_activityrank[playerData.id].reward_icon) ~= "0" then
                if image then
                    self:SetSprite(image, "UI_Common", ConfigMgr.config_activityrank[playerData.id].reward_icon)
                end
            else
                if image then
                    self:SetSprite(image, "UI_Common", "icon_activity_gift_1")
                end
            end
            
        else
            self:GetGo(self.playerInfoGo, "bg/reward"):SetActive(false)
        end
        self:SetButtonClickHandler(self:GetComp(self.playerInfoGo, "reward", "Button"), function()
            local cfgGiftBag = ConfigMgr.config_shop[ConfigMgr.config_activityrank[playerData.id].reward]
            self:SetTempGo("preview/frame/reward/item", function(index, go, cfg)
                self:SetTemp(index, go, cfg)
            end, cfgGiftBag)
        end)
    end
end

--设置玩家所在排行区域ID
function ActivityRankUIView:SetRankAreaCode()
    local userId = GameSDKs:GetThirdAccountInfo()
    -- if userId ~= nil and string.len(userId) > 6 then
    --     userId = string.sub(userId, string.len(userId) - 6, string.len(userId))
    -- end
    local disID = 10086
    if tonumber(userId) then
        disID = tonumber(userId) + 10086
    end
    
    local disStr = string.format(GameTextLoader:ReadText("TXT_FESTIVAL_GROUP"),tostring(disID))
    self:SetText("RootPanel/groupid", disStr)
end

function ActivityRankUIView:InitList()
    self.mList = self:GetComp("RootPanel/rank/RankList", "ScrollRectEx")
    self:SetListItemCountFunc(self.mList, function()
        return #self.rankData
    end)
    self:SetListUpdateFunc(self.mList, handler(self, self.UpdateListItem))
end

function ActivityRankUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local bgStr = "bg1"
    
    local currData = self.rankData[index]
    if currData.isPlayer then
       bgStr = "bg2"
        currData.head = "head_"..LocalDataManager:GetBossSkin()
        currData.name = LocalDataManager:GetBossName()
    end
    -- self:GetGo(go, "bg2"):SetActive(false)
    -- self:GetGo(go, "bg1"):SetActive(false)
    if currData then
        self:GetGo(go, "bg1/rank/1"):SetActive(index == 1)
        self:GetGo(go, "bg1/rank/2"):SetActive(index == 2)
        self:GetGo(go, "bg1/rank/3"):SetActive(index == 3)
        self:GetGo(go, "bg1/rank/other"):SetActive(index > 3)
        self:SetText(go, "bg1/rank/other", index)
        if ConfigMgr.config_activityrank[index] and ConfigMgr.config_activityrank[index].reward > 0 and tostring(ConfigMgr.config_activityrank[index].reward_icon) ~= "0" then
            local image = self:GetComp(go, bgStr.."/reward", "Image")
           
            self:GetGo(go, "bg1/reward"):SetActive(true)
            if tostring(ConfigMgr.config_activityrank[index].reward_icon) ~= "0" then
                if image then
                    self:SetSprite(image, "UI_Common", ConfigMgr.config_activityrank[index].reward_icon)
                end
            else
                if image then
                    self:SetSprite(image, "UI_Common", "icon_activity_gift_1")
                end
            end
        else
            self:GetGo(go, "bg1/reward"):SetActive(false)
        end
        local head = self:GetComp(go, "bg1/head", "Image")
        self:SetSprite(head, "UI_BG", currData.head)
        self:SetText(go, "bg1/name", currData.name)

        local valueShow = ActivityRankUI:ValueToShow(currData.value)
        self:SetText(go, "bg1/num", valueShow)
        self:GetGo(go, "bg2/rank/1"):SetActive(index == 1)
        self:GetGo(go, "bg2/rank/2"):SetActive(index == 2)
        self:GetGo(go, "bg2/rank/3"):SetActive(index == 3)
        self:GetGo(go, "bg2/rank/other"):SetActive(index > 3)
        self:SetText(go, "bg2/rank/other", index)
        if ConfigMgr.config_activityrank[index] and ConfigMgr.config_activityrank[index].reward > 0 and tostring(ConfigMgr.config_activityrank[index].reward_icon) ~= "0"then
            local image = self:GetComp(go, "bg2/reward", "Image")
            self:GetGo(go, "bg2/reward"):SetActive(true)
            if tostring(ConfigMgr.config_activityrank[index].reward_icon) ~= "0" then
                if image then
                    self:SetSprite(image, "UI_Common", ConfigMgr.config_activityrank[index].reward_icon)
                end
            else
                if image then
                    self:SetSprite(image, "UI_Common", "icon_activity_gift_1")
                end
            end
        else
            self:GetGo(go, "bg2/reward"):SetActive(false)
        end
        local head = self:GetComp(go, "bg2/head", "Image")
        self:SetSprite(head, "UI_BG", currData.head)
        self:SetText(go, "bg2/name", currData.name)

        local valueShow = ActivityRankUI:ValueToShow(currData.value)
        self:SetText(go, "bg2/num", valueShow)
        self:GetGo(go, "bg2"):SetActive(currData.isPlayer)
        self:GetGo(go, "bg1"):SetActive(not currData.isPlayer)
        self:SetButtonClickHandler(self:GetComp(go, "bg1/reward", "Button"), function()
            local cfgGiftBag = ConfigMgr.config_shop[ConfigMgr.config_activityrank[index].reward]
            self:SetSprite(self:GetComp("preview/frame/icon", "Image"), "UI_Common", ConfigMgr.config_activityrank[index].reward_icon)
            self:SetTempGo("preview/frame/reward/item", function(index, go, cfg)
                self:SetTemp(index, go, cfg)
            end, cfgGiftBag)
        end)

        self:SetButtonClickHandler(self:GetComp(go, "bg2/reward", "Button"), function()
            local cfgGiftBag = ConfigMgr.config_shop[ConfigMgr.config_activityrank[index].reward]
            self:SetSprite(self:GetComp("preview/frame/icon", "Image"), "UI_Common", ConfigMgr.config_activityrank[index].reward_icon)
            self:SetTempGo("preview/frame/reward/item", function(index, go, cfg)
                self:SetTemp(index, go, cfg)
            end, cfgGiftBag)
        end)
    end
end

--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function ActivityRankUIView:SetTempGo(path , cb, cfgGiftBag)    
    local temp = self:GetGo(path)
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    
    for i=1, 5 do
        local go
        if self:GetGoOrNil(parent, "temp" .. i ) then
            go = self:GetGo(parent, "temp" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        local cfg = ConfigMgr.config_shop[cfgGiftBag.param[i]]
        go.name = "temp" .. i
        go:SetActive(true)
        if not cfg then
            go:SetActive(false)
        else
            cb(i, go, cfg)
        end                                      
    end          
end

--对单个temp进行设置
function ActivityRankUIView:SetTemp(index, go, cfg)    
    local value = ShopManager:GetValue(cfg)
    local icon = self:GetComp(go, "icon", "Image")
    if  type(value) == "number" then
        self:SetText(go, "num", Tools:SeparateNumberWithComma(value))
    else
        self:SetText(go, "num", "1")
    end        
    self:SetSprite(icon, "UI_Shop", cfg.icon, nil, true) 
end

function ActivityRankUIView:UpdateLeftTimeDisplay()
    self.leftTime = ActivityRankDataManager:GetCurrentLeftTime()
    if self.leftTime <= 0 then
        self.leftTime = 0
        if self.displayLeftTimeTimer then
            GameTimer:StopTimer(self.displayLeftTimeTimer)
            self.displayLeftTimeTimer = nil
        end
        if self.refreshRankTimer then
            GameTimer:StopTimer(self.refreshRankTimer)
            self.refreshRankTimer = nil
        end
        ActivityRankDataManager:RefreshLastRankData()
        self:RefreshRank()
    end
    self:SetText("RootPanel/banner/message/time/txt", GameTimeManager:FormatTimeLength(self.leftTime))
    self:GetGo("RootPanel/banner/message/time"):SetActive(self.leftTime > 0)
    self:GetGo("RootPanel/banner/message/end"):SetActive(self.leftTime <= 0)
    self:GetGo("RootPanel/btnArea"):SetActive(self.leftTime <= 0)
    self:GetGo("RootPanel/QuitBtn"):SetActive(self.leftTime > 0)
    
end

function ActivityRankUIView:GetRrewardBtnClick()
    ActivityRankDataManager:GetActivityRankReward(true)
    MainUI:HideButton("PackPanel/rank")
    self:DestroyModeUIObject()
end

return ActivityRankUIView
