--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-11 15:45:57
]]
local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local GameObject = CS.UnityEngine.GameObject
local BoardUI = GameTableDefine.BoardUI
local ConfigMgr = GameTableDefine.ConfigMgr
local ResourceManger = GameTableDefine.ResourceManger
local MainUI = GameTableDefine.MainUI
local BoardUIView = Class("BoardUIView", UIView)


local boardCache = nil
function BoardUIView:ctor()
    self.super:ctor()
    boardCache = BoardUI.cacheData
end

function BoardUIView:OnEnter()
    self.super:OnEnter()

    local Toggle = self:GetComp("background/check", "Toggle")
    Toggle.isOn = false

    local confirmBtnGO = self:GetGo("background/confirmBtn")
    --local rewardBtnGO = self:GetGo("background/rewardBtn")
    local rewardShow = self:GetGo("background/reward")
    
    local diamondCount = ConfigMgr.config_global.notify_reward
    self:SetText("background/reward/num", diamondCount)
    if boardCache["unRead"] then
        confirmBtnGO:SetActive(true)
        --rewardBtnGO:SetActive(true)
        self:SetText("background/confirmBtn/txt", GameTextLoader:ReadText("TXT_BTN_CLAIM"))
        --rewardShow:SetActive(true)
        self:GetGo("background/reward/claimed"):SetActive(false)
        self:SetButtonClickHandler(self:GetComp("background/confirmBtn", "Button"), function()
            local isToggled = false
            if Toggle and Toggle.isOn then
                isToggled = true;
            end
            boardCache["unRead"] = false
            BoardUI:CloseBoardUI(true)
            LocalDataManager:WriteToFile()
            --最后一个参数 true 控制 是在动画完成是再增加  
            ResourceManger:AddDiamond(diamondCount, nil, function()
                EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
                GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "公告板领取", behaviour = 1, num_new = tonumber(diamondCount)})
            end,true)
            MainUI:RefreshBoardUnread()
        end)
    else
        confirmBtnGO:SetActive(true)
        --rewardBtnGO:SetActive(false)
        self:SetText("background/confirmBtn/txt", GameTextLoader:ReadText("TXT_BTN_CONFIRM"))
        --rewardShow:SetActive(false)
        self:GetGo("background/reward/claimed"):SetActive(true)
        self:SetButtonClickHandler(self:GetComp("background/confirmBtn", "Button"), function()
            local isToggled = false
            if Toggle and Toggle.isOn then
                isToggled = true;
            end
            BoardUI:CloseBoardUI(isToggled)
        end)
       
    end
    --self:SetText(rewardBtnGO,"num",diamondCount)
    --self:SetButtonClickHandler(self:GetComp("background/confirmBtn", "Button"), function()
    --    
    --    local isToggled = false
    --    if Toggle and Toggle.isOn then
    --        isToggled = true;
    --    end
    --    BoardUI:CloseBoardUI(isToggled)
    --end)

    --self:SetButtonClickHandler(self:GetComp("background/rewardBtn", "Button"), function()
    --    local isToggled = false
    --    if Toggle and Toggle.isOn then
    --        isToggled = true;
    --    end
    --    boardCache["unRead"] = false
    --    BoardUI:CloseBoardUI(true)
    --    LocalDataManager:WriteToFile()
    --    --最后一个参数 true 控制 是在动画完成是再增加  
    --    ResourceManger:AddDiamond(diamondCount, nil, function()                                                       
    --            EventManager:DispatchEvent("FLY_ICON", nil, 3, nil)
    --        end,true) 
    --    MainUI:RefreshBoardUnread()
    --end)


end

function BoardUIView:OnExit()
    self.super:OnExit(self)
end

function BoardUIView:UpdateContent(title, msg)
    print("BoardUIView:UpdateContent:"..msg)
    local useTitle = string.gsub(title, "\\n", "\n");
    local useContent = string.gsub(msg, "\\n", "\n")
    self:SetText("background/data/Viewport/Content/desc", useContent)
    self:SetText("background/data/title/txt", useTitle)
end



return BoardUIView