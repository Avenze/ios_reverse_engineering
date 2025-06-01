local Class = require("Framework.Lua.Class")
local UIViwe = require("Framework.UI.View")


local FootballClubManagerInfoUIView = Class("FootballClubManagerInfoUIView",UIViwe)



function FootballClubManagerInfoUIView:ctor()
    self.super:ctor()
    self.m_data = {}
end

function FootballClubManagerInfoUIView:OnEnter()
    self:InitView()
end 

function FootballClubManagerInfoUIView:OnExit()
    self.super:OnExit(self)
end

function FootballClubManagerInfoUIView:InitView()
    self:RefreshCurrentLeagueList()
    self:RefreshLeagueList()
end


return FootballClubManagerInfoUIView