local GameObject = CS.UnityEngine.GameObject
local Transform = CS.UnityEngine.Transform
local FootballClubScene = GameTableDefine.FootballClubScene
local MainUI = GameTableDefine.MainUI
local FloorMode = GameTableDefine.FloorMode
local FloatUI = GameTableDefine.FloatUI
local HouseContractUI = GameTableDefine.HouseContractUI
local ResMgr = GameTableDefine.ResourceManger
local CfgMgr = GameTableDefine.ConfigMgr
local GameUIManager = GameTableDefine.GameUIManager
local ChatEventManager = GameTableDefine.ChatEventManager
local SoundEngine = GameTableDefine.SoundEngine
local GuideUI = GameTableDefine.GuideUI
local GuideManager = GameTableDefine.GuideManager
local TimerMgr = GameTimeManager
local FootballClubModel = GameTableDefine.FootballClubModel
local SoundEngine = GameTableDefine.SoundEngine
local LightManager = GameTableDefine.LightManager


--初始化
function FootballClubScene:Init(footballClubData ,go)
    --场景中的gameObject
    self.m_SceneGo = {}
    for k,v in pairs(CfgMgr.config_football_club[footballClubData.id]) do
        self.m_SceneGo[v.objName] = {}
        self.m_SceneGo[v.objName].root = self:GetGo(go, v.objName)
        self.m_SceneGo[v.objName].model = self:GetGo(self.m_SceneGo[v.objName].root,"model") or nil
        self.m_SceneGo[v.objName].roomBox = self:GetGo(self.m_SceneGo[v.objName].root,"roombox") or nil 
        self.m_SceneGo[v.objName].UIPosition = self:GetGo(self.m_SceneGo[v.objName].root,"UIPosition") or nil
        self.m_SceneGo[v.objName].buildingFB = self:GetGo(self.m_SceneGo[v.objName].root,"buildingFB") or nil
        self.m_SceneGo[v.objName].night = self:GetGo(self.m_SceneGo[v.objName].root,"model/night") or nil
    end      
    self.rootGO = go 
    self:OnEnter(footballClubData)
end

--进入时
function FootballClubScene:OnEnter(footballClubData)
    --设置阴影
    LightManager:UseNoShadow()
    --初始化场景控制
    require("GamePlay.FootballClub.FootballClubController"):Init(self.m_SceneGo, footballClubData)
    MainUI:EnterFootballClubSetUI()
    --设置相机参数
    local cameraFollow = FloorMode:GetScene():CameraFollow()
    cameraFollow:EnterFC(80,110,-200,400)
    local cameraMove = FloorMode:GetScene():CameraMove()
    cameraMove.Speed = cameraMove.Speed * 2
    --播放BGM
    self.bgm = SoundEngine:PlayBackgroundMusic(SoundEngine.FOOTBALL_BGM,true)
    
    --关闭后处理
    local lightGO = self:GetLight()
    if lightGO then
        FloorMode:GetScene():ControlGlobalVolumeDisp(false)
        GameTableDefine.LightManager:SetBuildingLight(lightGO)
    end

end

--退出时
function FootballClubScene:OnExit()
    --设置阴影
    LightManager:UseDefaultShadow()
    --设置相机参数
    local cameraFollow = FloorMode:GetScene():CameraFollow()
    cameraFollow:ExitFC()
    local cameraMove = FloorMode:GetScene():CameraMove()
    cameraMove.Speed = cameraMove.Speed / 2

    --停止播放BGM
    if self.bgm then
        SoundEngine:StopBackgroundMusic()
    end
    --打开后处理
    local lightGO = self:GetLight()
    if lightGO then
        GameTableDefine.LightManager:SetBuildingLight()
    end
    
    self.night = nil
    self.bgm = nil
    self.treeMaterial = nil
    self.globalVolume = nil
end

function FootballClubScene:PlayFCBGM()
    self.bgm = SoundEngine:PlayBackgroundMusic(SoundEngine.FOOTBALL_BGM,true)
end

--获取gameObjiect
function FootballClubScene:GetGo(go, child)
   return FloorMode:GetScene():GetGo(go, child)
end

--获取gameObjiect 可以为Nil
function FootballClubScene:GetGoOrNil(go, child)
    return FloorMode:GetScene():GetGoOrNul(go, child)
end

function FootballClubScene:GetComp(go, child, uiType)
    if not go or not child or not FloorMode:GetScene() then
        return nil
    end
    return FloorMode:GetScene():GetComp(go, child, uiType)
end

function FootballClubScene:SetTreeSharedMaterialAttr(value)
    if not self.treeMaterial or self.treeMaterial:IsNull() then
        local go = GameObject.Find("tree01")
        local mr = self:GetComp(go,"","MeshRenderer")
        if mr and mr.sharedMaterial then
            self.treeMaterial = mr.sharedMaterial
        end
    end
    if self.treeMaterial then
        self.treeMaterial:SetFloat("Time",value)
    end
end

function FootballClubScene:SetRoomOnCenter(cameraFocus, isBack,roomID)
    local roomName = CfgMgr.config_football_club[FootballClubModel.m_cfg.id][roomID].objName
    local scene = FloorMode:GetScene()
    local go =  self.m_SceneGo[roomName].model
    local size = cameraFocus.m_cameraSize
    local speed = cameraFocus.m_cameraMoveSpeed
    local target2DPosition = cameraFocus.position
    local cb = nil
    -- if isBack then
    --     local data = scene:GetSetCameraLocateRecordData() or {}
    --     data.isBack = true
    --     size = data.offset or size
    --     target2DPosition = data.offset2dPosition
    --     go = data.go3d
    -- end 
    if not go then
        return
    end
    --start2DPositon.z = 0
    scene:Locate3DPositionByScreenPosition(go, target2DPosition, size, speed, cb)
end

--设置night开关
function FootballClubScene:SwitchNightPoint(active)
    if not self.night or self.night:IsNull() then
        local FCGO = GameObject.Find("FootballClub_1(Clone)")
        self.night = self:GetGo(FCGO,"night")
    end
    self.night:SetActive(active)
    for k,v in pairs(CfgMgr.config_football_club[FootballClubModel.m_cfg.id]) do
        local roomData = FootballClubModel:GetRoomDataById(k)
        self.m_SceneGo[v.objName].night:SetActive(roomData.state == 2 and active)
    end   

end


---获取Light节点
function FootballClubScene:GetLight()
    return self:GetGo(self.rootGO, "Light")
end

return FootballClubScene