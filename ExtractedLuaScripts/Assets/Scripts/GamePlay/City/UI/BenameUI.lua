local BenameUI = GameTableDefine.BenameUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local CityMode = GameTableDefine.CityMode
local FloorMode = GameTableDefine.FloorMode
local EventManager = require("Framework.Event.Manager")

function BenameUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.BENAME_UI, self.m_view, require("GamePlay.City.UI.BenameUIView"), self, self.CloseView)
    return self.m_view
end

function BenameUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.BENAME_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function BenameUI:BuildingName()
    self:GetView():Invoke("SetBuildingName")
end

function BenameUI:SaveName(name, isBuildingName)
    if isBuildingName then
        FloorMode:GetScene():BenameFinish(name)
        GameSDKs:TrackForeign("init", {init_id = 20, init_desc = "公司命名成功"})
    else
        CityMode:BenameFinish(name)
    end
end

function BenameUI:ReName()
    self:BuildingName()
    self:GetView():Invoke("ReName")
end

function BenameUI:RePetName(petId, cb)
    self:GetView():Invoke("RePetName", petId, cb)
end

function BenameUI:ReClubName(cb)
    self:GetView():Invoke("ReClubName", cb)
end

function BenameUI:ReBossName(cb)
    self:GetView():Invoke("ReBossName", cb)
end

function BenameUI:SetCurBossSkinID(skinID)
    self.curBossSkinID = skinID
end

function BenameUI:GetCurBossSkinID()
    if not self.curBossSkinID then
        self.curBossSkinID = 1
    end
    return self.curBossSkinID
end