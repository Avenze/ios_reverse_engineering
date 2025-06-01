local CompanyLvUpUI = GameTableDefine.CompanyLvUpUI
local MainUI = GameTableDefine.MainUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CompanyMode = GameTableDefine.CompanyMode
local FloorMode = GameTableDefine.FloorMode
local ResMgr = GameTableDefine.ResourceManger
local StarMode = GameTableDefine.StarMode

local EventManager = require("Framework.Event.Manager")

function CompanyLvUpUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.COMPANY_LVUP_UI, self.m_view, require("GamePlay.Floors.UI.CompanyLvUpUIView"), self, self.CloseView)
    return self.m_view
end

function CompanyLvUpUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.COMPANY_LVUP_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CompanyLvUpUI:CheckClose(companyId)
    if GameUIManager:IsUIOpen(28) then
        self:GetView():Invoke("CheckClose", companyId)
    end
end

function CompanyLvUpUI:Refresh(companyId)
    self:GetView():Invoke("Refresh", companyId)
end

function CompanyLvUpUI:GetReward(companyId, lv, cb)
    local data = ConfigMgr.config_company[companyId]
    local reward = data["lvReward"][lv]

    -- if reward[1] and reward[1] == 5 then
    --     StarMode:StarRaise(reward[2], true)
    -- end

    -- if reward[3] then
    --     ResMgr:Add(reward[3], reward[4], nil, nil, true)
    -- end

    -- if reward[5] then
    --     ResMgr:Add(reward[5], reward[6], nil, nil, true)
    -- end
    MainUI:AddMultiple(reward, true)

    CompanyMode:CompanyLvUp(companyId)
    local roomIndex = CompanyMode:GetRoomIndexByCompanyId(companyId)
    local roomId = FloorMode:GetRoomIdByRoomIndex(roomIndex)
    FloorMode:GetScene():InitRoomGo(roomId)
    if cb then cb() end
end