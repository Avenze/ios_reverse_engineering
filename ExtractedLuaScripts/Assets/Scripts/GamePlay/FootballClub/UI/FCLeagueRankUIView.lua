local Class = require("Framework.Lua.Class")
local UIViwe = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")

local UI = GameTableDefine.FCLeagueRankUI
local dataManager = GameTableDefine.FootballClubLeagueRankDataManager
local FootballClubModel = GameTableDefine.FootballClubModel
local FootballClubController = GameTableDefine.FootballClubController
local ChooseUI = GameTableDefine.ChooseUI
local FCLeagueUpUI = GameTableDefine.FCLeagueUpUI
local MainUI = GameTableDefine.MainUI

local FCLeagueRankUIView = Class("FCLeagueRankUIView", UIViwe)

FCLeagueRankUIView.curView = nil
FCLeagueRankUIView.panels = {
    LeaguePanel = 1,
    RankPanel = 2,
}

function FCLeagueRankUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FCLeagueRankUIView:OnEnter()
    self.Model = UI:GetUIModel()
    self:InitView()
end

function FCLeagueRankUIView:OnExit()
    self.super:OnExit(self)
end

function FCLeagueRankUIView:InitView()
    self:SetButtonClickHandler(self:GetComp("RootPanel/title/closebtn", "Button"), function()
        self:DestroyModeUIObject()
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/panel_btn/page1","Button"),function()
        self:ShowLeagueList()
    end)

    self:SetButtonClickHandler(self:GetComp("RootPanel/panel_btn/page2","Button"),function()
        self:ShowRankList()
    end)

    --红点
    self:GetGo("RootPanel/panel_btn/page1/icon"):SetActive( self.Model.unlockable )
    self:GetGo("RootPanel/panel_btn/page1/dissabled/icon"):SetActive( self.Model.unlockable )
end

-- ********************************联赛列表************************************

function FCLeagueRankUIView:ShowLeagueList()
    UI:RefreshModel()
    self.curView = self.panels.LeaguePanel
    self:GetGo("RootPanel/LeaguePanel"):SetActive(true)
    self:GetGo("RootPanel/RankPanel"):SetActive(false)
    self:GetComp("RootPanel/panel_btn/page1","Button").interactable = false
    self:GetComp("RootPanel/panel_btn/page2","Button").interactable = true
    self:GetGo("RootPanel/panel_btn/page1/dissabled"):SetActive(true)
    self:GetGo("RootPanel/panel_btn/page2/dissabled"):SetActive(false)

    local feel = self:GetComp("RootPanel/panel_btn/page1/dissabled/openFB","MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end

    local m_list = self:GetComp("RootPanel/LeaguePanel/ScrollRectEx", "ScrollRectEx")
    self:SetListItemCountFunc(m_list, function()
        local num = #self.Model.leagueList 
        return num
    end)
    self:SetListUpdateFunc(m_list, handler(self, self.ShowLeagueListItem))
    m_list:UpdateData()
end

function FCLeagueRankUIView:ShowLeagueListItem(index, trans)
    index = index + 1
    local go = trans.gameObject
    local num = #self.Model.leagueList - index + 1
    local leagueCfg = dataManager:GetFootballLeagueCfgByID(num)

    --联赛logo
    local leagueLogo = self:GetComp(go, "other/icon", "Image") 
    self:SetSprite(leagueLogo, "UI_Common", leagueCfg.icon)
    --联赛名称
    self:SetText(go, "other/name", GameTextLoader:ReadText(leagueCfg.name))
    --奖池
    local poolNum = leagueCfg.pool 
    local poolNumStr = Tools:SeparateNumberWithComma(poolNum)
    self:SetText(go, "other/jackpot/reward/num", poolNumStr)
    --刷新按钮状态
    local btnRoot = self:GetGo(go, "other/btn") 
    local buttonArray = {
        nowBtn = self:GetComp(go, "now", "Transform"),
        goBtn = self:GetComp(go, "other/btn/go", "Button"),
        unlockable = self:GetComp(go, "other/btn/unlock", "Button"),
        lockedBtn = self:GetComp(go, "other/btn/locked", "Transform")
    }
    --前往按钮点击事件
    self:SetButtonClickHandler(buttonArray.goBtn,function()
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        if FCData.activation then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_LEAGUE_DESC_3"))
            return
        end
        if self.Model.curLeagueLevel > leagueCfg.level then
            local txt = GameTextLoader:ReadText("TXT_LEAGUE_BTN_8")
            txt = Tools:FormatString(txt,  GameTextLoader:ReadText(leagueCfg.name))
            ChooseUI:CommonChoose(txt, function()
                FootballClubModel:SwitchLeague(leagueCfg.level)
                self:DestroyModeUIObject()
                MainUI:RefreshLeagueLevel()
            end, true, nil)
        else
            FootballClubModel:SwitchLeague(leagueCfg.level)
            MainUI:RefreshLeagueLevel()
            self:DestroyModeUIObject()
        end
    end)
    --解锁按钮点击事件
    self:SetButtonClickHandler(buttonArray.unlockable,function()
        local FCData = FootballClubModel:GetFCDataById(FootballClubModel.m_cfg.id)
        if FCData.activation then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_LEAGUE_DESC_3"))
        else    
            FootballClubModel:SwitchLeague(leagueCfg.level)
            MainUI:RefreshLeagueLevel()
            --打开联赛晋级弹窗
            FCLeagueUpUI:GetView()
            self:DestroyModeUIObject()
            FootballClubController:RefreshCupShow()
            --埋点
            GameSDKs:TrackForeign("fbclub", {league_level_new = tonumber(leagueCfg.level) or 0})
        end
    end)

    local leagueState = dataManager:GetLeagueState(num)
    --左边的点线表现
    self:GetGo(go,"other/point/locked"):SetActive(leagueState == dataManager.ELeagueState.locked)
    self:GetGo(go,"now/point/line"):SetActive(index ~= #self.Model.leagueList )
    self:GetGo(go,"other/point/line"):SetActive(index ~= #self.Model.leagueList )

    self:ShwoButton(buttonArray, leagueState)

    if leagueState == dataManager.ELeagueState.currentLeague then
        --联赛logo
        local leagueLogo = self:GetComp(go, "now/icon", "Image")
        self:SetSprite(leagueLogo, "UI_Common", leagueCfg.icon)
        --联赛名称
        self:SetText(go, "now/name", GameTextLoader:ReadText(leagueCfg.name))
        --奖池
        local poolNum = leagueCfg.pool 
        local poolNumStr = Tools:SeparateNumberWithComma(poolNum)
        self:SetText(go, "now/jackpot/reward/num", poolNumStr)
    end

end

function FCLeagueRankUIView:ShwoButton(buttonArray, leagueState)
    for k, v in pairs(buttonArray) do
        v.gameObject:SetActive(false)
    end
    if leagueState == dataManager.ELeagueState.locked then
        buttonArray.lockedBtn.gameObject:SetActive(true)
    elseif leagueState == dataManager.ELeagueState.unlockable then
        buttonArray.unlockable.gameObject:SetActive(true)
    elseif leagueState == dataManager.ELeagueState.currentLeague then
        buttonArray.nowBtn.gameObject:SetActive(true)
    elseif leagueState == dataManager.ELeagueState.accessible then
        buttonArray.goBtn.gameObject:SetActive(true)
    end
end


-- ********************************联赛排位************************************

function FCLeagueRankUIView:ShowRankList()
    UI:RefreshModel()
    self.curView = self.panels.RankPanel
    self:GetGo("RootPanel/LeaguePanel"):SetActive(false)
    self:GetGo("RootPanel/RankPanel"):SetActive(true)
    self:GetComp("RootPanel/panel_btn/page1","Button").interactable = true
    self:GetComp("RootPanel/panel_btn/page2","Button").interactable = false
    self:GetGo("RootPanel/panel_btn/page1/dissabled"):SetActive(false)
    self:GetGo("RootPanel/panel_btn/page2/dissabled"):SetActive(true)

    local feel = self:GetComp("RootPanel/panel_btn/page2/dissabled/openFB","MMFeedbacks")
    if feel then
        feel:PlayFeedbacks()
    end

    self:SetImageSprite("RootPanel/RankPanel/title/title/league",self.Model.leagueCfg.icon)
    self:SetText("RootPanel/RankPanel/title/title/txt/num/num1",self.Model.frequency)
    self:SetText("RootPanel/RankPanel/title/title/txt/num/num2",self.Model.totalFrequency)

    self:ShowCurrentLeagueEarnings()
    self:RefreshLeagueTeamsList()
end

function FCLeagueRankUIView:RefreshLeagueTeamsList()
    local teamList = dataManager.leagueRankSorted
    local m_list = self:GetComp("RootPanel/RankPanel/rank", "ScrollRectEx")
    self:SetListItemCountFunc(
        m_list,
        function()
            local num = #teamList --Tools:GetTableSize(dataManager.leagueListCfg)
            return num
        end
    )
    self:SetListUpdateFunc(m_list, handler(self, self.ShowRankListItem))
    m_list:UpdateData()
end

function FCLeagueRankUIView:ShowRankListItem(index,trans)
    index = index + 1
    local go = trans.gameObject
    local team = dataManager:GetCurrnetLeagueTeamArchivedDataByRanking(index)
    --前两名修改背景图片
    self:GetGo(go,"bg/first"):SetActive(index == 1)
    self:GetGo(go,"bg/second"):SetActive(index == 2)
    self:GetGo(go,"bg/other"):SetActive(index > 2)
    --设置队伍排名
    if index <= 2 then
        self:SetText(go,"rank/num",Tools:ChangeTextColor(tostring(index),"ffffff"))
    else
        self:SetText(go,"rank/num",Tools:ChangeTextColor(tostring(index),"5e616e"))
    end
    --设置队伍头像
    self:SetSprite(self:GetComp(go,"team/bg/icon","Image"), "UI_Common", team.cfg.icon)
    self:SetSprite(self:GetComp(go,"team/bg","Image"), "UI_Common", team.cfg.iconBG)
    --设置队伍名称
    if team.cfg.id == 0 then
        local playerTeam = FootballClubModel:GetPlayerTeamData()
        self:SetText(go,"team/name",playerTeam.name)
    else
        self:SetText(go,"team/name",GameTextLoader:ReadText(team.cfg.name))
    end
    --能力值
    local teamData = FootballClubModel:GetTeamDataByID(team.cfg.id)
    self:SetText(go,"team/value/bg/num",Tools:SeparateNumberWithComma(math.floor(teamData.synthesize)))
    --联赛积分
    self:SetText(go,"point/num",team.point)

end

function FCLeagueRankUIView:ShowCurrentLeagueEarnings()
    --banner
    local rank = dataManager:GetLeagueRanking()
    self:GetGo("RootPanel/RankPanel/player/item/bg/first"):SetActive(rank == 1)
    self:GetGo("RootPanel/RankPanel/player/item/bg/second"):SetActive(rank == 2)
    self:GetGo("RootPanel/RankPanel/player/item/bg/other"):SetActive(rank > 2)
    --奖金
    local prize = dataManager:GetCurrentLeaguePrize()
    self:SetText("RootPanel/RankPanel/reward/price/num",Tools:SeparateNumberWithComma(prize))
    --排名
    if rank <= 2 then
        self:SetText("RootPanel/RankPanel/player/item/rank/num",Tools:ChangeTextColor(tostring(rank),"ffffff"))
    else
        self:SetText("RootPanel/RankPanel/player/item/rank/num",Tools:ChangeTextColor(tostring(rank),"5e616e"))
    end
    --球队logo
    self:SetImageSprite("RootPanel/RankPanel/player/item/team/bg",self.Model.teamData.iconBG)
    self:SetImageSprite("RootPanel/RankPanel/player/item/team/bg/icon",self.Model.teamData.icon)
    --球队名
    self:SetText("RootPanel/RankPanel/player/item/team/name",self.Model.teamData.name)
    --能力值
    local teamData = FootballClubModel:GetTeamDataByID(self.Model.teamData.id)
    self:SetText("RootPanel/RankPanel/player/item/team/value/bg/num",Tools:SeparateNumberWithComma(math.floor(teamData.synthesize)))
    --得分
    local team = dataManager:GetCurrnetLeagueTeamArchivedDataByRanking(self.Model.rank)
    self:SetText("RootPanel/RankPanel/player/item/point/num",team.point)
end

return FCLeagueRankUIView
