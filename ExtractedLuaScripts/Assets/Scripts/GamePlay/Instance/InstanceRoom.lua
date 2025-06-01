--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-03-30 17:29:04
]]

local Class = require("Framework.Lua.Class")
local BaseScene = require("GamePlay.Instance.InstnaceRoomBase")
local InstanceRoom = Class("InstanceRoom",BaseScene)
local UIView = require("Framework.UI.View")
local GameResMgr = require("GameUtils.GameResManager")

local AnimationUtil = CS.Common.Utils.AnimationUtil
local GameObject = CS.UnityEngine.GameObject
local SkodeGlinting = CS.UnityEngine.Skode_Glinting

local InstanceModel = GameTableDefine.InstanceModel
local ConfigMgr = GameTableDefine.ConfigMgr
local FloatUI = GameTableDefine.FloatUI

--[[
    @desc: 声明所有变量
    author:{author}
    time:2023-03-31 11:36:28
    @return:
]]
function InstanceRoom:DeclareVariable()
    self.roomType = {
        ROOM_TYPE_FACTORY = 1,  --工厂类型
        ROOM_TYPE_DORMITORY = 2, --宿舍
        ROOM_TYPE_CANTEEN = 3,  --食堂
        ROOM_TYPE_PORT = 4,  --港口
    }
    self.GORoot = nil --房间GameObject根节点
    self.roomGO = {}    --GameObject表
    self.roomID = 0
    self.curRoomType = 0    --当前房间类型
    self.roomData = nil     --房间存档数据
    self.roomConfig = nil  --房间配置数据
    self.furConfig = nil   --家具配置数据
    self.furLevelConfig = nil  --家具等级配置数据
    self.workers = {}    --员工初始化标记列表
    self.CreateFurEndCallback = nil  --创建家具结束回调
    self.furFindIndex = {} --只是作为查找场景物体的临时变量使用
    self.unlockFloat = nil --解锁放假的FloatUI
    
end

function InstanceRoom:Init(roomType,data,roomCfg,GO,cb)
    self:DeclareVariable()
    self.curRoomType = roomType
    self.roomID = data.roomID
    self.roomData = data
    self.roomConfig = roomCfg
    self.GORoot = GO
    self.CreateFurEndCallback = cb
    self.furConfig = ConfigMgr.config_furniture_instance
    self.furLevelConfig = ConfigMgr.config_furniture_level_instance
    self:InitRoomGO()
    self:InitFurnitureGo()
end

function InstanceRoom:OnEnter()
end

function InstanceRoom:OnExit()
end

function InstanceRoom:Update(dt)
end

function InstanceRoom:OnPouse()
end

function InstanceRoom:OnResume()
end

function InstanceRoom:InitRoomGO()
    --构造物体索引表
    local furRoot = UIView:GetGo(self.GORoot,"furniture")
    local UIPos = UIView:GetGo(self.GORoot,"UIPosition")
    local modelRoot = UIView:GetGo(self.GORoot,"model")
    local roomBox = UIView:GetGo(self.GORoot,"roombox")
    local locked = UIView:GetGo(self.GORoot,"locked")
    local unlock = UIView:GetGo(self.GORoot,"unlock")
    local furList = {}
    local subFurList = {}
    for k,v in pairs(self.roomConfig.furniture) do
        local furID = v.id
        local furConfig = InstanceModel:GetFurConfigByID(furID)
        local findIndex = 1
        if not self.furFindIndex[furConfig.object_name] then
            self.furFindIndex[furConfig.object_name] = findIndex
        else    
            self.furFindIndex[furConfig.object_name] = self.furFindIndex[furConfig.object_name] + 1
            findIndex = self.furFindIndex[furConfig.object_name]
        end
        local goName = furConfig.object_name.."_"..findIndex
        local furGO = UIView:GetGo(furRoot,goName)
        furList[k] = furGO

        if furConfig.type == 2 then --如果是有子节点的家具
            local subCount = InstanceModel:GetAllFurSeatCount(furID)
            subFurList[k] = {}
            for i=1,subCount do
                local subFurName = k.."workPos"
                local subIndex = 1
                if not self.furFindIndex[subFurName] then
                    self.furFindIndex[subFurName] = findIndex
                else    
                    self.furFindIndex[subFurName] = self.furFindIndex[subFurName] + 1
                    findIndex = self.furFindIndex[subFurName]
                end
                local subGOName = "workPos".."_"..i
                local subGO = UIView:GetGo(furGO,subGOName)
                subFurList[k][i] = {
                    GO = subGO,
                    isUsed = false
                } 
            end
           
        end
    end
    self.roomGO = {
        ["furRoot"] = furRoot,
        ["UIPos"] = UIPos,
        ["modelRoot"] = modelRoot,
        ["furList"] = furList,
        ["subFurList"] = subFurList,
        ["roomBox"] = roomBox,
        ["locked"] = locked,
        ["unlock"] = unlock,
    }

    self:ShowRoom()
    self:InitPortState()

end

function InstanceRoom:InitPortState()
    if self.curRoomType == 4 and self.roomData.state == 2 then
        for furIndex,furData in pairs(self.roomData.furList) do
            local furConfig = self.furLevelConfig[furData.id]
            if furData.state == 1 and furConfig.storage > 0 then
                -- local doorPathHead = "Miscellaneous/Environment/Port_1/model/Easter_Men_0"
                -- local doorPath = doorPathHead..furData.index
                local doorGO = UIView:GetGo(self.roomGO.furList[furData.index],"Door")
                if not furData.isOpen then
                    --关
                    local feel = UIView:GetComp(doorGO,"closeFB","MMFeedbacks")
                    feel:PlayFeedbacks()
                else
                    --开
                    local feel = UIView:GetComp(doorGO,"openFB","MMFeedbacks")
                    feel:PlayFeedbacks()
                end
            end
        end
    end
end

function InstanceRoom:ShowRoom()
    if self.roomData.state == 0 then -- 未解锁
        local unlock_room = self.roomConfig.unlock_room
        if InstanceModel:RoomIsUnlock(unlock_room) then
            self.GORoot:SetActive(true)
            self.roomGO.UIPos:SetActive(true)
            self.roomGO.furRoot:SetActive(false)
            self.roomGO.modelRoot:SetActive(false)
            self.roomGO.roomBox:SetActive(true)
            self.roomGO.unlock:SetActive(true)
            self.roomGO.locked:SetActive(false)
        else
            self.GORoot:SetActive(true)
            self.roomGO.UIPos:SetActive(false)
            self.roomGO.furRoot:SetActive(false)
            self.roomGO.modelRoot:SetActive(false)
            self.roomGO.roomBox:SetActive(false)
            self.roomGO.unlock:SetActive(false)
            self.roomGO.locked:SetActive(true)
        end
    elseif self.roomData.state == 1 then -- 修建中
        self:ShowBubble()

        self.GORoot:SetActive(true)
        self.roomGO.UIPos:SetActive(true)
        self.roomGO.furRoot:SetActive(false)
        self.roomGO.modelRoot:SetActive(false)
        self.roomGO.roomBox:SetActive(false)
        self.roomGO.unlock:SetActive(true)
        self.roomGO.locked:SetActive(false)
    elseif self.roomData.state == 2 then -- 修建完成

        self.GORoot:SetActive(true)
        self.roomGO.UIPos:SetActive(false)
        self.roomGO.furRoot:SetActive(true)
        self.roomGO.modelRoot:SetActive(true)
        self.roomGO.roomBox:SetActive(true)
        self.roomGO.unlock:SetActive(false)
        self.roomGO.locked:SetActive(false)
    end
end

function InstanceRoom:InitFurnitureGo()
    if self.roomData.state ==2 then
        self:ShowFurniture(nil,false)
    end
end

function InstanceRoom:ShowFurniture(index,isBuy)
    if self.roomData.state ==2 then
        if index then
            local furData = self.roomData.furList[tostring(index)]
            if furData.state == 1 then
                self.roomGO.furList[index]:SetActive(true)
                self:ShowFurPrefab(furData.id,furData.index,isBuy)
            else
                self.roomGO.furList[index]:SetActive(false)
            end
        else
            for k,v in pairs(self.roomData.furList) do
                if v.state == 1 then
                    self.roomGO.furList[tonumber(k)]:SetActive(true)
                    self:ShowFurPrefab(v.id,v.index,isBuy)
                else
                    self.roomGO.furList[tonumber(k)]:SetActive(false)
                end
            end
        end

    end
end

function InstanceRoom:ShowFurPrefab(levelID,index,isBuy)
    -- 显示模型,如果没有就先加载再显示
    local furLevelConfig = self.furLevelConfig[levelID]
    local furConfig = self.furConfig[furLevelConfig.furniture_id]
    local prefabLevel = furLevelConfig.level
    --Assets/Res/Prefabs/furniture/ShowerRoom_2.prefab
    --local targetName = furConfig.object_name.."_"..prefabLevel
    local parentGO = self.roomGO.furList[index]
    
    local needLoad = true
    local targetGO = nil
    for k,v in pairs(parentGO.transform) do
        if string.find(v.gameObject.name , furLevelConfig.prefab) then
            needLoad = false
            targetGO = v.gameObject
            break
        end
    end
    if not needLoad then
        self:LoadFinishHandle(targetGO,index,levelID,isBuy)
        return
    end
    
    
    local path = "Assets/Res/Prefabs/furniture/"..furLevelConfig.prefab..".prefab"
    GameResMgr:AInstantiateObjectAsyncManual(path,self,function(GO)
        local oldGO = parentGO.transform:GetChild(0)
        GO.transform:SetParent(parentGO.transform)
        GO.transform.position = oldGO.transform.position
        GO.transform.rotation = oldGO.transform.rotation
        GO.transform.localScale = oldGO.transform.localScale
        GameObject.Destroy(oldGO.gameObject)
        GO.transform:SetAsFirstSibling()    --将该节点移到父物体的第一个子节点位置
        GO.name = furLevelConfig.prefab
        
        self:LoadFinishHandle(GO,index,levelID,isBuy)
    end)

end

--加载完成后的处理
function InstanceRoom:LoadFinishHandle(GO,index,levelID,isBuy)
    local parent = self.roomGO.furList[index]

    local furLevelConfig = self.furLevelConfig[levelID]
    local furConfig = self.furConfig[furLevelConfig.furniture_id]
    --特殊处理 显示家具下的子节点(椅子/床)
    if furConfig.type == 2 then
        local subFurCount = InstanceModel:GetAllFurSeatCount(furConfig.id)
        self.roomGO.subFurList[index] = {}
        for i=1,subFurCount do
            local subFurName = index.."workPos"
            local subIndex = 1
            if not self.furFindIndex[subFurName] then
                self.furFindIndex[subFurName] = subIndex
            else    
                self.furFindIndex[subFurName] = self.furFindIndex[subFurName] + 1
                subIndex = self.furFindIndex[subFurName]
            end
            local subGOName = "workPos".."_"..i
            local subGO = UIView:GetGo(GO,subGOName)
            self.roomGO.subFurList[index][i] = {
                GO = subGO,
                isUsed = false
            } 
        end
        for i=1,#self.roomGO.subFurList[index] do
            self.roomGO.subFurList[index][i].GO:SetActive(i <= furLevelConfig.level)
        end
    end

    --为模型添加SkodeGlinting组件
    -- local trans = UIView:GetTrans(GO, "model") or {}
    -- for i,trans in pairs(trans) do
    --     local MeshRenderer = trans.gameObject:GetComponent("MeshRenderer")
    --     local Skode_Glinting = trans.gameObject:GetComponent("Skode_Glinting")
    --     if not MeshRenderer:IsNull() and not Skode_Glinting then
    --         trans.gameObject:AddComponent(typeof(SkodeGlinting))
    --     end
    -- end

    if isBuy then
        InstanceModel:ShowSelectFurniture(parent,false)
        --播放物品购买动画
        local anim = GO:GetComponent("Animation")
        local find, name = AnimationUtil.GetFirstClipName(anim)
        AnimationUtil.Play(anim,name)
         --AnimationUtil.Play(anim, "UiEffWildPopIn", function()
         --    anim:Stop()
         --    if isFirstShow then
         --        self:SendGuideEvent(GameTableDefine.Guide.EVENT_VIEW_OPEND, self.m_guid, functionList[1].params.localPosID)
         --    end
         --end)
    end

    --实例化家具GO后的回调
    if self.CreateFurEndCallback then
        self.CreateFurEndCallback(GO,self.roomID,index,isBuy)
        if not self.workers[index] and self.furLevelConfig[levelID].isPresonFurniture then
            self.workers[index] = true 
        end
    end
end



function InstanceRoom:ShowBubble()
    --生成悬浮UI
    local curRoomConfig = self.roomConfig
    local timePoint = self.roomData.buildTimePoint
    local timeWait = timePoint + curRoomConfig.unlock_times
    local go = self.GORoot
    if self.unlockFloat == nil then
        self.unlockFloat = {["go"] = go}
        FloatUI:SetObjectCrossCamera(self.unlockFloat, function(view)
            if view then
                --print("显示修建房屋FLoatUI",self.unlockFloat.guid)
                view:Invoke("ShowIntanceBuildingUnlockButtton", curRoomConfig, timeWait, self.unlockFloat)
            end
        end, nil, 0)
    else
        print("刷新修建房屋FLoatUI",self.unlockFloat.guid)
        --self.unlockFloat.view:Invoke("ShowIntanceBuildingUnlockButtton", curRoomConfig, timeWait, self.unlockFloat)
    end
end

function InstanceRoom:HideBubble()
end

function InstanceRoom:GetFurnitureGoByIndex(index)
    if self.roomGO.furList then
        return self.roomGO.furList[index]
    end
    return nil
end

function InstanceRoom:GetSubFurnitureGoByIndex(index)
    if self.roomGO.subFurList then
        return self.roomGO.subFurList[index].GO
    end
    return nil
end

return InstanceRoom