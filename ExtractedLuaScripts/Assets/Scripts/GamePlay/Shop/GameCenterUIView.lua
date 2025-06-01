local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local GameCenterUIView = Class("GameCenterUIView", UIView)

function GameCenterUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function GameCenterUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/bg/QuitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function GameCenterUIView:Open(data)
    self.m_list = self:GetComp("RootPanel/bg/frame1/List", "ScrollRectEx")

    self.m_data = {}
    for k, v in pairs(data or {}) do
        table.insert(self.m_data, v)
    end
    
    self:InitList()

    self.m_list:UpdateData()
end

function GameCenterUIView:UpdateListItem(index, tran)
    index = index + 1
    local go = tran.gameObject
    local itemData = self.m_data[index]
    if itemData == nil then
        return
    end

    local gameName = itemData.game_name or ""
    local url = itemData.video_url or ""

    self:SetText(go, "btn/txt", gameName)

    local btn = self:GetComp(go, "btn", "Button")
    self:SetButtonClickHandler(btn, function()
        print("播放的广告位" .. gameName .. " 广告的网址为: " .. url)

        GameSDKs:PlayGameVideo(gameName, url)
    end)
end

function GameCenterUIView:InitList()
    self:SetListItemCountFunc(self.m_list, function()
        return #self.m_data;
    end)

    self:SetListUpdateFunc(self.m_list, handler(self, self.UpdateListItem))
end

function GameCenterUIView:OnExit()
	self.super:OnExit(self)
    self.m_data = nil
    self.m_list = nil
end

return GameCenterUIView