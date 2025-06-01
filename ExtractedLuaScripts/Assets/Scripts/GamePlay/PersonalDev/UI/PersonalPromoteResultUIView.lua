--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-13 14:55:22
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local ConfigMgr = GameTableDefine.ConfigMgr
local PersonalDevModel = GameTableDefine.PersonalDevModel
local PersonalPromoteResultUIView = Class("PersonalPromoteResultUIView", UIView)

function PersonalPromoteResultUIView:ctor()
    self.super:ctor()
end

function PersonalPromoteResultUIView:OnEnter()
    self.super:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/Panel_2/info_area/btn_area/conf_btn", "Button"), function()
        self:DestroyModeUIObject()
        GameTableDefine.PersonalPromoteUI:Exit()
        GameTableDefine.PersonalInfoUI:OpenPersonalInfoUI()
    end)
end

function PersonalPromoteResultUIView:OpenPromoteResult(enemyID, playerSupport, enemySupport)
    local enemyCfg = ConfigMgr.config_opponent[enemyID]
    if not enemyCfg then
        self:DestroyModeUIObject()
        return
    end
    local isWin = playerSupport >= enemySupport
    local totalSupport = playerSupport + enemySupport
    local playerSupportPer = math.ceil((playerSupport/totalSupport)*100)
    local enemySupportPer = 100 - playerSupportPer
    local silder = self:GetComp("RootPanel/Panel_2/info_area/support_line/bg/slider", "Image")
    --设置对手信息
    self:SetText("RootPanel/Panel_2/info_area/name/enemy", GameTextLoader:ReadText(enemyCfg.name))
    self:SetText("RootPanel/Panel_2/info_area/support_line/bg/icon_enemy/num", tostring(enemySupport))
    self:GetGo("RootPanel/Panel_2/info_area/result/enemy/lose"):SetActive(isWin)
    self:GetGo("RootPanel/Panel_2/info_area/result/enemy/win"):SetActive(not isWin)
    self:SetSprite(self:GetComp("RootPanel/Panel_2/info_area/character/enemy_pos/icon", "Image"), "UI_Shop", enemyCfg.icon)
    self:SetText("RootPanel/Panel_2/info_area/info_area/enemy/rate/bg/txt/num", tostring(enemySupport))
    self:SetText("RootPanel/Panel_2/info_area/info_area/enemy/count/bg/txt/num/num", tostring(enemySupportPer))
    --设置玩家信息
    self:SetText("RootPanel/Panel_2/info_area/name/player", LocalDataManager:GetBossName())
    self:SetText("RootPanel/Panel_2/info_area/support_line/bg/icon_player/num", playerSupport)
    self:GetGo("RootPanel/Panel_2/info_area/result/player/win"):SetActive(isWin)
    self:GetGo("RootPanel/Panel_2/info_area/result/player/lose"):SetActive(not isWin)
    -- local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    self:SetSprite(self:GetComp("RootPanel/Panel_2/info_area/character/player_pos/icon", "Image"), "UI_Shop", PersonalDevModel:GetCurrHeadIconStr())
    self:SetText("RootPanel/Panel_2/info_area/info_area/player/rate/bg/txt/num", tostring(playerSupport))
    self:SetText("RootPanel/Panel_2/info_area/info_area/player/count/bg/txt/num/num", tostring(playerSupportPer))
    --设置票数的显示
    --step1.玩家的
    self:GetGo("RootPanel/Panel_2/info_area/info_area/player/pass/bad"):SetActive(playerSupportPer > 0 and playerSupportPer <= 40)
    self:GetGo("RootPanel/Panel_2/info_area/info_area/player/pass/normal_lose"):SetActive(playerSupportPer > 40 and playerSupportPer <= 50)
    self:GetGo("RootPanel/Panel_2/info_area/info_area/player/pass/normal_win"):SetActive(playerSupportPer > 50 and playerSupportPer <= 60)
    self:GetGo("RootPanel/Panel_2/info_area/info_area/player/pass/good"):SetActive(playerSupportPer > 60)
    
    --step2.对手的
    self:GetGo("RootPanel/Panel_2/info_area/info_area/enemy/pass/bad"):SetActive(enemySupportPer > 0 and enemySupportPer <= 40)
    self:GetGo("RootPanel/Panel_2/info_area/info_area/enemy/pass/normal_lose"):SetActive(enemySupportPer > 40 and enemySupportPer <= 50)
    self:GetGo("RootPanel/Panel_2/info_area/info_area/enemy/pass/normal_win"):SetActive(enemySupportPer > 50 and enemySupportPer <= 60)
    self:GetGo("RootPanel/Panel_2/info_area/info_area/enemy/pass/good"):SetActive(enemySupportPer > 60)

    silder.fillAmount = playerSupport/totalSupport
end

function PersonalPromoteResultUIView:OnExit()
    self.super:OnExit(self)
end
return PersonalPromoteResultUIView