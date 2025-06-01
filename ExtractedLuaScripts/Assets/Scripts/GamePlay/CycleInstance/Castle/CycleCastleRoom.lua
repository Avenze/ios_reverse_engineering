local Class = require("Framework.Lua.Class")
local CycleInstanceRoomBase = require("GamePlay.CycleInstance.CycleInstanceRoomBase")
---@class CycleCastleRoom:CycleInstanceRoomBase
---@field super CycleInstanceRoomBase
local CycleCastleRoom = Class("CycleCastleRoom",CycleInstanceRoomBase)
local FloatUI = GameTableDefine.FloatUI
local UIView = require("Framework.UI.View")
local Transport = require("GamePlay.CycleInstance.Castle.Module.FactoryTransport")
local CycleInstanceDefine = require("GamePlay.CycleInstance.CycleInstanceDefine")
local CycleInstanceDataManager = GameTableDefine.CycleInstanceDataManager
local TimerMgr = GameTimeManager

local transportGOName = "tranport"

function CycleCastleRoom:ctor()
    self.super.ctor(self)
    self.m_transport = nil ---@type FactoryTransport -传送带

    self.m_floatUIHandler = nil
    self.m_needShowFloatUIList = {} ---@type table<number,boolean> -所有需要显示的FloatUI
end

function CycleCastleRoom:Init(roomType,data,roomCfg,GO,cb,model)
    self.super.Init(self,roomType,data,roomCfg,GO,cb,model)

    local transportGO = UIView:GetGoOrNil(self.GORoot,transportGOName)
    if transportGO then
        self.m_transport = Transport.new()
        self.m_transport:Init(transportGO)
    end

    self:InitFloatUIView()

    if self:NeedUpgrade() then
        --房间是否能升级的气泡
        self:ShowBubble(CycleInstanceDefine.BubbleType.CanUpgrade)
    elseif self:IsUpgrading() then
        local curTime = TimerMgr:GetCurrentServerTime()
        local remainingTime = self.roomData.completeTime - curTime
        if remainingTime >0 then
            --房间升级中的气泡
            self:ShowBubble(CycleInstanceDefine.BubbleType.IsUpgrading)
        else
            --房间升级完成的气泡
            self:ShowBubble(CycleInstanceDefine.BubbleType.IsFinish)
        end
    end
end

---override 将对应房间类型气泡标记为要显示
function CycleCastleRoom:ShowBubble(bubbleType)

    self.m_needShowFloatUIList[bubbleType] = true

    self:RefreshFloatUI()
end

---override 将房间气泡标记为不显示
function CycleCastleRoom:HideBubble(bubbleType)

    if not self.m_needShowFloatUIList[bubbleType] then
        return
    end

    self.m_needShowFloatUIList[bubbleType] = false

    self:DisableBubble(bubbleType)

    self:RefreshFloatUI()
end

---显示对应类型的房间气泡,真正显示在UI上
function CycleCastleRoom:EnableBubble(bubbleType)

    local view = self.m_floatUIHandler and self.m_floatUIHandler.view
    if not view then
        return
    end

    if bubbleType == CycleInstanceDefine.BubbleType.IsBuilding then
        local curRoomConfig = self.roomConfig
        local timePoint = self.roomData.buildTimePoint
        local timeWait = timePoint + curRoomConfig.unlock_times
        view:Invoke("ShowCycleCastleRoomIsBuildingBubble", curRoomConfig, timeWait)
    elseif bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        view:Invoke("ShowCycleCastleBuildingNeedMatTips", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        view:Invoke("ShowCycleCastleBuildingCanUpgradeTips", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsUpgrading then
        view:Invoke("ShowCycleCastleRoomIsUpgradingBubble", self.roomID)
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsFinish then
        view:Invoke("ShowCycleCastleRoomIsFinishTips", self.roomID)
    end
end

---隐藏对应类型的房间气泡,关闭UI显示
function CycleCastleRoom:DisableBubble(bubbleType)

    local view = self.m_floatUIHandler.view
    if not view then
        return
    end

    if bubbleType == CycleInstanceDefine.BubbleType.IsBuilding then
        view:Invoke("HideCycleCastleRoomIsBuildingBubble")
    elseif bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        view:Invoke("HideCycleCastleBuildingNeedMatTips")
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        view:Invoke("HideCycleCastleBuildingCanUpgradeTips")
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsUpgrading then
        view:Invoke("HideCycleCastleRoomIsUpgradingBubble")
    elseif bubbleType == CycleInstanceDefine.BubbleType.IsFinish then
        view:Invoke("HideCycleCastleRoomIsFinishTips")
    end
end

---刷新FloatUI的显示，显示所有应该显示出来的FloatUI，可以计算互斥，可以有多个不互斥的
function CycleCastleRoom:RefreshFloatUI()
    for bubbleType,needShow in pairs(self.m_needShowFloatUIList) do
        if needShow then
            if self:IsSortToShowFloatUI(bubbleType) then
                self:EnableBubble(bubbleType)
            else
                self:DisableBubble(bubbleType)
            end
        end
    end
end

---注册的FloatUI
function CycleCastleRoom:InitFloatUIView()
    self.m_floatUIHandler = { ["go"] = self.GORoot, m_type = "room"}
    FloatUI:SetObjectCrossCamera(self.m_floatUIHandler, function(view)
        if view then
            self:RefreshFloatUI()
        end
    end, nil, 0)
end

---清除注册的FloatUI
function CycleCastleRoom:RemoveFloatUIView()
    FloatUI:RemoveObjectCrossCamera(self.m_floatUIHandler)
end

function CycleCastleRoom:OnExit()
    if self.m_transport then
        self.m_transport:OnExit()
        self.m_transport = nil
    end

    self:RemoveFloatUIView()
    self.m_floatUIHandler = nil

    self.super.OnExit(self)
end

function CycleCastleRoom:ShowRoom()
    self:getSuper(CycleCastleRoom).ShowRoom(self)
    if self.roomData.state == 2 then
        if self.m_transport then
            --如果下一个房间修建好
            local nextRoomIsUnlock = self.m_instanceModel:RoomIsUnlock(self.roomID + 1)
            --下个房间没修好,要设为关闭,修好了就不管交给下个房间判断
            if not nextRoomIsUnlock then
                self.m_transport:SetState(false)
            end
        end
    end
end

---是否需要升级房间 与 钱够不够
---@return boolean,boolean needUpgrade,canUpgrade
function CycleCastleRoom:NeedUpgrade()
    if self.roomConfig.room_category == CycleInstanceDefine.RoomType.ROOM_TYPE_FACTORY then
        if self.roomData.state ~= 2 or self.roomData.isUpgrading then
            return false
        end
        local furData = self.roomData.furList["1"]
        if furData.state == 1 then
            local curFurLevelID = furData.id
            local currentFurLevelCfg = self.furLevelConfig[curFurLevelID] --当前选中的家具levelConfig
            local currentFurCfg = self.furConfig[currentFurLevelCfg.furniture_id]
            local currentModel = CycleInstanceDataManager:GetCurrentModel()
            local nextFurLevelCfg = currentModel:GetFurlevelConfig(currentFurCfg.id, currentFurLevelCfg.level + 1)

            if not nextFurLevelCfg then
                return false
            end

            local roomLevel = self.roomData.level or 1
            --家具下一级没有房间等级需求 或 不需要升级房间
            if not nextFurLevelCfg.room_level or nextFurLevelCfg.room_level <= roomLevel then
                return false
            end
            --判断是否有房间下一级的配置
            local roomNextLevelCfg = currentModel:GetRoomLevelConfig(self.roomID,(self.roomData.level or 1)+1)
            if not roomNextLevelCfg then
                --没有下一级的配置
                return false
            end
            --判断钱够不够
            local haveCoin = currentModel:GetCurInstanceCoin()
            local upgradeCostCoin = currentModel:GetRoomUpgradeCost(self.roomID,(self.roomData.level or 1)+1)
            local isEnoughCoin = not BigNumber:CompareBig(upgradeCostCoin,haveCoin)

            return true,isEnoughCoin
        end
    end
    return false
end



---根据房间气泡优先级，判断是否该显示对应类型的气泡
function CycleCastleRoom:IsSortToShowFloatUI(bubbleType)
    --可修建=升级完成=修建完成=修建中>缺原料>可升级
    if bubbleType == CycleInstanceDefine.BubbleType.LackOfRawMaterials then
        if self:IsUpgrading() then
            return false
        end
        return true
    elseif bubbleType == CycleInstanceDefine.BubbleType.CanUpgrade then
        if self:IsLackOfMaterial() then
            return false
        else
            return true
        end
    else
        return true
    end
end

return CycleCastleRoom