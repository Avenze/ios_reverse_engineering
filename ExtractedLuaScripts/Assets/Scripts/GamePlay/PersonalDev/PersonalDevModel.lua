--[[
    个人发展晋升竞选模块数据控制模块
]]

local PersonalDevModel = GameTableDefine.PersonalDevModel
local CityMode = GameTableDefine.CityMode
local ConfigMgr = GameTableDefine.ConfigMgr
local ResMgr = GameTableDefine.ResourceManger
local EventManager = require("Framework.Event.Manager")
local ResourceMgr = GameTableDefine.ResourceManger
local UnityHelper = CS.Common.Utils.UnityHelper
function PersonalDevModel:Init()
    self.m_IsInit = false
    --该系统当前所有的timer
    self.m_CurTimer = {} 
    self.m_PersonalData = LocalDataManager:GetDataByKey("PersonalDevData")

    --新系统检测，根据玩家当前的场景进行初始化
    if not self.m_PersonalData.m_TitleLevel then
        if self:GetPersonalDevLocked(200) then
            --解锁了2号场景身份变为2级
            self.m_PersonalData.m_TitleLevel = 1
        else
            --初始化身份是1级
            self.m_PersonalData.m_TitleLevel = 2
        end
    end

    if not self.m_PersonalData.m_CurStage then
        self.m_PersonalData.m_CurStage = 1
    end

    --当前购买的事物处理的次数
    if not self.m_PersonalData.m_CurBuyAffairTimes then
        self.m_PersonalData.m_CurBuyAffairTimes = 0
    end

    --当前购买事物处理的时间
    if not self.m_PersonalData.m_CurBuyAffairTime then
        self.m_PersonalData.m_CurBuyAffairTime = GameTimeManager:GetCurrentServerTime(true)
    end

    --阶段奖励领取记录
    if not self.m_PersonalData.m_StageRewards then
        self.m_PersonalData.m_StageRewards = 0
    end
    if not self.m_PersonalData.m_SupportCount then
        self.m_PersonalData.m_SupportCount = ConfigMgr.config_global.player_suppertorcount
    end

    if not self.m_PersonalData.m_AffairsLimit then
        self.m_PersonalData.m_AffairsLimit = 0
        if self.m_PersonalData.m_TitleLevel then
            local curCfg = ConfigMgr.config_develop[self.m_PersonalData.m_TitleLevel]
            if curCfg then
                self.m_PersonalData.m_AffairsLimit = curCfg.affairs_limit
            end
        end
        
    end

    --上一次离线的时间
    if not self.m_PersonalData.m_LastOffTime then
        self.m_PersonalData.m_LastOffTime = GameTimeManager:GetCurrentServerTime(true)
    end

    if not self.m_PersonalData.m_CurAffairsCD then
        self.m_PersonalData.m_CurAffairsCD = ConfigMgr.config_global.affairs_charge * 60
    end
    if self.m_PersonalData.m_CurAffairsCD > 0 then
        if self.m_CurTimer["AffairsCD"] then
            GameTimer:StopTimer(self.m_CurTimer["AffairsCD"])
            self.m_CurTimer["AffairsCD"] = nil
        end
        local offSetTime = GameTimeManager:GetCurrentServerTime(true) - self.m_PersonalData.m_LastOffTime
        if offSetTime > 0 then
            self.m_PersonalData.m_CurAffairsCD  = self.m_PersonalData.m_CurAffairsCD + offSetTime
        end
        --充能的逻辑计算
        local affairReTime = ConfigMgr.config_global.affairs_charge * 60
        local offlineAffairsCount = math.floor(self.m_PersonalData.m_CurAffairsCD / affairReTime)
        self.m_PersonalData.m_CurAffairsCD = self.m_PersonalData.m_CurAffairsCD - (offlineAffairsCount * affairReTime)
        self.m_PersonalData.m_AffairsLimit  = self.m_PersonalData.m_AffairsLimit + offlineAffairsCount
        if self:IsAffairsLimitMax() then
            self.m_PersonalData.m_CurAffairsCD = 0
        else
            self.m_CurTimer["AffairsCD"] = GameTimer:CreateNewTimer(1, function()
                self:AffairsLimitRechargeProcess()
            end, true, false)
        end
    else
        local curLimitMax = 5
        local cfgDev = ConfigMgr.config_develop[self.m_PersonalData.m_TitleLevel]
        if cfgDev then
            curLimitMax = cfgDev.affairs_limit
        end
        if self.m_PersonalData.m_AffairsLimit < curLimitMax then
            self.m_PersonalData.m_CurAffairsCD = ConfigMgr.config_global.affairs_charge * 60
            if self:IsAffairsLimitMax() then
                self.m_PersonalData.m_CurAffairsCD = 0
            else
                self.m_CurTimer["AffairsCD"] = GameTimer:CreateNewTimer(1, function()
                    self:AffairsLimitRechargeProcess()
                end, true, false)
            end
        end
    end

    if not self.m_PersonalData.m_Energy then
        self.m_PersonalData.m_Energy = ConfigMgr.config_global.energy_uplimit
    end

    if not self.m_PersonalData.m_CurEnergyRecoverCD then
        self.m_PersonalData.m_CurEnergyRecoverCD = ConfigMgr.config_global.energy_restore * 60
    end

    if self.m_PersonalData.m_CurEnergyRecoverCD <= 0 and not self:IsEnergyMax() then
        self.m_PersonalData.m_CurEnergyRecoverCD = ConfigMgr.config_global.energy_restore * 60
    end

    if self.m_PersonalData.m_CurEnergyRecoverCD > 0 then
        if self.m_CurTimer["EnergyRecoverCD"] then
            GameTimer:StopTimer(self.m_CurTimer["EnergyRecoverCD"])
            self.m_CurTimer["EnergyRecoverCD"] = nil
        end
        local energyoffSetTime = GameTimeManager:GetCurrentServerTime(true) - self.m_PersonalData.m_LastOffTime
        if energyoffSetTime > 0 then
            self.m_PersonalData.m_CurEnergyRecoverCD  = self.m_PersonalData.m_CurEnergyRecoverCD + energyoffSetTime
        end
        --精力恢复的逻辑计算
        local energyReTime = ConfigMgr.config_global.energy_restore * 60
        local offlineEnergyCount = math.floor(self.m_PersonalData.m_CurEnergyRecoverCD / energyReTime)
        self.m_PersonalData.m_Energy  = self.m_PersonalData.m_Energy + offlineEnergyCount
        self.m_PersonalData.m_CurEnergyRecoverCD = self.m_PersonalData.m_CurEnergyRecoverCD - (offlineEnergyCount * energyReTime)
        if self:IsEnergyMax() then
            self.m_PersonalData.m_CurEnergyRecoverCD = 0
        else
            self.m_CurTimer["EnergyRecoverCD"] = GameTimer:CreateNewTimer(self.m_PersonalData.m_CurEnergyRecoverCD, function()
                self:EnergyRecover()
            end, false, false)
        end
    end
    
    self.m_PersonalData.m_LastOffTime = GameTimeManager:GetCurrentServerTime(true)
    self.m_IsInit = true
end

--[[
    @desc: 获取当前的头衔等级
    author:{author}
    time:2023-08-18 10:20:57
    @return:
]]
function PersonalDevModel:GetTitle()
    if not self.m_IsInit then
        return 0
    end
    if self.m_PersonalData.m_TitleLevel then
        return self.m_PersonalData.m_TitleLevel
    end

end

--[[
    @desc: 设置当前头衔，新的头衔带来的相关逻辑改变
    author:{author}
    time:2023-08-18 17:34:54
    --@titleID: 
    @return:
]]
function PersonalDevModel:SetTitle(titleID)
    local oldTitleID = self.m_PersonalData.m_TitleLevel
    self.m_PersonalData.m_TitleLevel = titleID
    self.m_PersonalData.m_CurStage = 1  --头衔升级后stage又到当前头衔的第一步了
    local oldCfg = ConfigMgr.config_develop[oldTitleID]
    local curCfg = ConfigMgr.config_develop[titleID]
    --1、事务处理次数的增加，因为最大值增加了，所以当前事务处理的次数也增加对应的次数
    if oldCfg and curCfg then
        self.m_PersonalData.m_AffairsLimit  = self.m_PersonalData.m_AffairsLimit + (curCfg.affairs_limit - oldCfg.affairs_limit)
    end
    LocalDataManager:WriteToFile()
end

function PersonalDevModel:GetCurAffairLimit()
    return self.m_PersonalData.m_AffairsLimit or 0
end

function PersonalDevModel:GetSupportCount()
    return self.m_PersonalData.m_SupportCount or 0
end

function PersonalDevModel:SetSupportCount(num)
    if self.m_PersonalData.m_SupportCount then
        self.m_PersonalData.m_SupportCount  = self.m_PersonalData.m_SupportCount + num
    else
        self.m_PersonalData.m_SupportCount = num
    end
end

function PersonalDevModel:GetStage()
    return self.m_PersonalData.m_CurStage
end

function PersonalDevModel:SetStage(stage)
    self.m_PersonalData.m_CurStage = stage
end
--[[
    @desc: 获取当前事务充能的的冷却时间
    author:{author}
    time:2023-08-18 17:42:01
    @return:int(按秒算的)
]]
function PersonalDevModel:GetAffairsCD()
    return self.m_PersonalData.m_CurAffairsCD
end

--[[
    @desc: 获取当前事务ID，用于处理当前事务
    author:{author}
    time:2023-08-18 17:43:53
    @return:
]]
function PersonalDevModel:GetAffairsQueue()
    if not self:IsCanProcessAffair() then
        return 0
    end
    if not self.m_PersonalData.m_CurAffairID or self.m_PersonalData.m_CurAffairID == 0 then
        --给当前事务进行赋值事务ID
        --step1获取当前配置的事务id池
        local cfgAffairIDs = {}
        local curDevCfg = ConfigMgr.config_develop[self.m_PersonalData.m_TitleLevel]
        if not curDevCfg then
            return 0
        end
        for _, id in ipairs(curDevCfg.affairs) do
            if self:CheckAffairIDCanUse(id) then
                table.insert(cfgAffairIDs, id)
            end
        end
        local randomIndex = math.random(1, Tools:GetTableSize(cfgAffairIDs))
        self.m_PersonalData.m_CurAffairID = cfgAffairIDs[randomIndex]
    end
    return self.m_PersonalData.m_CurAffairID
end

--[[
    @desc: 能否处理事务
    author:{author}
    time:2023-08-25 14:57:21
    @return:
]]
function PersonalDevModel:IsCanProcessAffair()
    if not self.m_PersonalData.m_TitleLevel then
        return false
    end
    local curCfg = ConfigMgr.config_develop[self.m_PersonalData.m_TitleLevel]
    if not curCfg or curCfg.affairs_limit <= 0 then
        return false
    end
    return true
end
--[[
    @desc: 获取已经完成且不能再被抽取的事务ID
    author:{author}
    time:2023-08-18 17:50:25
    @return:
]]
function PersonalDevModel:GetNotUseAffairIDs()
    return self.m_PersonalData.m_curNotUseAffairIDs or {}
end

function PersonalDevModel:GetPersonalDevLocked(sceneID)
    return not CityMode:CheckBuildingSatisfy(sceneID)
end 

function PersonalDevModel:UnLockBuiding(sceneID)
    if sceneID >= 200 then
        if self.m_PersonalData.m_TitleLevel == 1 then
            --解锁2号场景身份直接到2级
            self:SetTitle(2)
            --TODO:测试直接到社区代表，用于开始测试事务处理逻辑
            -- self:SetTitle(3)
        end
    end
end

--[[
    @desc: 检测当前的事务对应的答案消耗的资源是否足够
    author:{author}
    time:2023-08-25 17:28:46
    --@answerIndex: 
    @return:bool
]]
function PersonalDevModel:CheckCurAffairAnswerResEnough(answerIndex)
    if not self.m_PersonalData.m_CurAffairID or self.m_PersonalData.m_CurAffairID <= 0 then
        return false
    end
    local curAffairCfg = ConfigMgr.config_affair[self.m_PersonalData.m_CurAffairID]
    if not curAffairCfg then
        return false
    end

    if Tools:GetTableSize(curAffairCfg.option_cost[answerIndex]) > 1 then
        if not self:CheckAffairProcessResEnough(curAffairCfg.option_cost[answerIndex][1], curAffairCfg.option_cost[answerIndex][2]) then
            return false
        end
    end
    return true
end

--[[
    @desc: 处理当前事务
    author:{author}
    time:2023-08-22 16:31:44
    --@answerIndex: 
    @return:true 处理成功，false处理失败
]]
function PersonalDevModel:ComplateCurAffair(answerIndex)
    if self.m_PersonalData.m_AffairsLimit < 1 then
        return false
    end
    --step1.获取当前事务id对应的配置
    local curAffairCfg = ConfigMgr.config_affair[self.m_PersonalData.m_CurAffairID]
    if not curAffairCfg then
        return false
    end
    self.m_PersonalData.m_AffairsLimit  = self.m_PersonalData.m_AffairsLimit - 1
    if self.m_PersonalData.m_CurAffairsCD <= 0 then
        self.m_PersonalData.m_CurAffairsCD = ConfigMgr.config_global.affairs_charge * 60
    end
    if not self.m_CurTimer["AffairsCD"] then
        self.m_CurTimer["AffairsCD"] = GameTimer:CreateNewTimer(1, function()
            self:AffairsLimitRechargeProcess()
        end, true, false)
    end
    --TODO:根据当前处理的事务id进行相关的逻辑处理
    --step2.扣除当前事务对应要消耗的资源
    if Tools:GetTableSize(curAffairCfg.option_cost[answerIndex]) > 1 then
        if not self:AffairProcessCostRes(curAffairCfg.option_cost[answerIndex][1], curAffairCfg.option_cost[answerIndex][2]) then
            return false
        end
    end
    --step3.根据答案获取对应的奖励
    if Tools:GetTableSize(curAffairCfg.option_rewards[answerIndex]) > 1 then
        self:GetAffairReward(curAffairCfg.option_rewards[answerIndex][1], curAffairCfg.option_rewards[answerIndex][2])
    end
    --step4.事务ID置0
    self.m_PersonalData.m_CurAffairID = 0
    return true
end

--是否已经达到了最大的事物数
function PersonalDevModel:IsAffairsLimitMax()
    if self.m_PersonalData.m_AffairsLimit then
        local curLimitMax = 5
        local cfgDev = ConfigMgr.config_develop[self.m_PersonalData.m_TitleLevel]
        if cfgDev then
            curLimitMax = cfgDev.affairs_limit
        end
        if self.m_PersonalData.m_AffairsLimit > curLimitMax then
            self.m_PersonalData.m_AffairsLimit = curLimitMax
        end
        return self.m_PersonalData.m_AffairsLimit >= curLimitMax
    end
    return false
end

--[[
    @desc: 精力值达到当前最大值检测
    author:{author}
    time:2023-08-18 15:22:30
    @return:
]]
function PersonalDevModel:IsEnergyMax()
    if self.m_PersonalData.m_Energy then
        local curEnergyMax = ConfigMgr.config_global.energy_uplimit
        if self.m_PersonalData.m_Energy > curEnergyMax then
            self.m_PersonalData.m_Energy = curEnergyMax
        end
        return self.m_PersonalData.m_Energy >= curEnergyMax
    end
    return false
end

--[[
    @desc: 事务次数心跳充能执行
    author:{author}
    time:2023-08-18 13:55:37
    @return:
]]
function PersonalDevModel:AffairsLimitRechargeProcess()
    if self:IsAffairsLimitMax() then
        return
    end
    self.m_PersonalData.m_CurAffairsCD  = self.m_PersonalData.m_CurAffairsCD - 1
    if self.m_PersonalData.m_CurAffairsCD <= 0 then
        self.m_PersonalData.m_AffairsLimit  = self.m_PersonalData.m_AffairsLimit + 1
        if self.m_PersonalData.m_AffairsLimit == 1 then
            EventManager:DispatchEvent(GameEventDefine.PersonalDev_AffairCanUse)
        else
            EventManager:DispatchEvent(GameEventDefine.PersonalDev_AffairRecover)
        end
        if self:IsAffairsLimitMax() then
            self.m_PersonalData.m_CurAffairsCD = 0
        else
            self.m_PersonalData.m_CurAffairsCD = ConfigMgr.config_global.affairs_charge * 60
        end
    end
end

--[[
    @desc: 恢复精力的逻辑处理
    author:{author}
    time:2023-08-18 16:43:16
    @return:
]]
function PersonalDevModel:EnergyRecover()
    self.m_PersonalData.m_Energy  = self.m_PersonalData.m_Energy + 1
    if not self:IsEnergyMax() then
        self.m_PersonalData.m_CurEnergyRecoverCD = ConfigMgr.config_global.energy_restore * 60
        self.m_CurTimer["EnergyRecoverCD"] = GameTimer:CreateNewTimer(self.m_PersonalData.m_CurEnergyRecoverCD, function()
            self:EnergyRecover()
        end, false, false)
    else
        self.m_CurTimer["EnergyRecoverCD"] = nil
    end
    EventManager:DispatchEvent(GameEventDefine.PersonalDev_EnergyCover)
end

--[[
    @desc: 获取当前的精力值
    author:{author}
    time:2023-08-30 14:03:22
    @return:
]]
function PersonalDevModel:GetCurEnergy()
    return self.m_PersonalData.m_Energy or 0
end

--[[
    @desc: 扣除消耗的精力值
    author:{author}
    time:2023-08-30 14:03:36
    --@consum: 
    @return:
]]
function PersonalDevModel:ConsumEnergy(consum)
    if self.m_PersonalData.m_Energy and self.m_PersonalData.m_Energy >= consum then
        self.m_PersonalData.m_Energy  = self.m_PersonalData.m_Energy - consum
        if not self:IsEnergyMax() and not self.m_CurTimer["EnergyRecoverCD"]then
            self.m_PersonalData.m_CurEnergyRecoverCD = ConfigMgr.config_global.energy_restore * 60
            self.m_CurTimer["EnergyRecoverCD"] = GameTimer:CreateNewTimer(self.m_PersonalData.m_CurEnergyRecoverCD, function()
                self:EnergyRecover()
            end)
        end
        return true
    end
    return false
end

function PersonalDevModel:AddEnergy(addsum)
    if self.m_PersonalData.m_Energy then
        self.m_PersonalData.m_Energy  = self.m_PersonalData.m_Energy + addsum
    else
        self.m_PersonalData.m_Energy = addsum
    end
    if not self:IsEnergyMax() and not self.m_CurTimer["EnergyRecoverCD"] then
        self.m_PersonalData.m_CurEnergyRecoverCD = ConfigMgr.config_global.energy_restore * 60
        self.m_CurTimer["EnergyRecoverCD"] = GameTimer:CreateNewTimer(self.m_PersonalData.m_CurEnergyRecoverCD, function()
            self:EnergyRecover()
        end)
    else
        if self.m_CurTimer["EnergyRecoverCD"] then
            GameTimer:StopTimer(self.m_CurTimer["EnergyRecoverCD"])
            self.m_CurTimer["EnergyRecoverCD"] = nil
        end
    end
    EventManager:DispatchEvent(GameEventDefine.PersonalDev_EnergyCover)
end

--[[
    @desc: 购买使用添加事务数
    author:{author}
    time:2023-09-22 17:55:48
    --@addNum: 
    @return:
]]
function PersonalDevModel:AddAffairLimit(addNum)
    local oldLimit = self.m_PersonalData.m_AffairsLimit or 0
    if self.m_PersonalData.m_AffairsLimit then
        self.m_PersonalData.m_AffairsLimit  = self.m_PersonalData.m_AffairsLimit + addNum
    else
        self.m_PersonalData.m_AffairsLimit = addNum
    end
    if not self:IsAffairsLimitMax() then
        if oldLimit == 0 then
            EventManager:DispatchEvent(GameEventDefine.PersonalDev_AffairCanUse)
        else
            EventManager:DispatchEvent(GameEventDefine.PersonalDev_AffairRecover)
        end
    else
        if oldLimit == 0 then
            EventManager:DispatchEvent(GameEventDefine.PersonalDev_AffairCanUse)
        else
            EventManager:DispatchEvent(GameEventDefine.PersonalDev_AffairRecover)
        end
        if self.m_CurTimer["AffairsCD"] then
            GameTimer:StopTimer(self.m_CurTimer["AffairsCD"])
            self.m_CurTimer["AffairsCD"] = nil
        end
    end
end

function PersonalDevModel:OnPause()
    self.m_PersonalData.m_LastOffTime = GameTimeManager:GetCurrentServerTime(true)
end

function PersonalDevModel:OnResume()

    --切到后台或者退出游戏都会执行这块的相关计算
    if self.m_PersonalData.m_CurAffairsCD > 0 then
        if self.m_CurTimer["AffairsCD"] then
            GameTimer:StopTimer(self.m_CurTimer["AffairsCD"])
            self.m_CurTimer["AffairsCD"] = nil
        end
        local offSetTime = GameTimeManager:GetCurrentServerTime(true) - self.m_PersonalData.m_LastOffTime
        if offSetTime > 0 then
            self.m_PersonalData.m_CurAffairsCD  = self.m_PersonalData.m_CurAffairsCD + offSetTime
        end
        --充能的逻辑计算
        local affairReTime = ConfigMgr.config_global.affairs_charge * 60
        local offlineAffairsCount = math.floor(self.m_PersonalData.m_CurAffairsCD / affairReTime)
        self.m_PersonalData.m_CurAffairsCD = self.m_PersonalData.m_CurAffairsCD - offlineAffairsCount * affairReTime
        self.m_PersonalData.m_AffairsLimit  = self.m_PersonalData.m_AffairsLimit + offlineAffairsCount
        if self:IsAffairsLimitMax() then
            self.m_PersonalData.m_CurAffairsCD = 0
        else
            self.m_CurTimer["AffairsCD"] = GameTimer:CreateNewTimer(1, function()
                self:AffairsLimitRechargeProcess()
            end, true, false)
        end
        -- self.m_CurTimer["AffairsCD"] =
    end
end

--[[
    @desc: 事务处理消耗扣除
    author:{author}
    time:2023-08-25 17:13:12
    --@resID:资源id
	--@count: 数量
    @return:bool
]]
function PersonalDevModel:AffairProcessCostRes(resID, count)
    -- 1 绿钞
    -- 2 欧元
    -- 3 钻石
    -- 4 支持者人数
    if 1 == resID then
        if ResMgr:GetCash() >= count then
            ResMgr:SpendCash(count)
            return true
        end
    elseif 2 == resID then
        if ResMgr:GetEuro() >= count then
            ResMgr:SpendEuro(count)
            return true
        end
    elseif 3 == resID then
        if ResMgr:GetDiamond() >= count then
            ResMgr:SpendDiamond(count)
            return true
        end
    elseif 4 == resID then
        if self.m_PersonalData.m_SupportCount and self.m_PersonalData.m_SupportCount >= count then
            self.m_PersonalData.m_SupportCount  = self.m_PersonalData.m_SupportCount - count
            return true
        end
    end

    return false
end 

--[[
    @desc: 查看当前消耗资源是否足够
    author:{author}
    time:2023-08-25 17:12:44
    --@resID:资源id
	--@count: 数量
    @return:bool
]]
function PersonalDevModel:CheckAffairProcessResEnough(resID, count)
    if 1 == resID then
        return ResMgr:GetCash() >= count
    elseif 2 == resID then
        return ResMgr:GetEuro() >= count
    elseif 3 == resID then
        return ResMgr:GetDiamond() >= count
    elseif 4 == resID then
        return self.m_PersonalData.m_SupportCount and self.m_PersonalData.m_SupportCount >= count
    end
    return false
end

--[[
    @desc: 获取事务处理奖励
    author:{author}
    time:2023-08-25 17:17:54
    --@resID:
	--@count: 
    @return:
]]
function PersonalDevModel:GetAffairReward(resID, count)
    -- 1 绿钞
    -- 2 欧元
    -- 3 钻石
    -- 4 支持者人数
    if 1 == resID then
        ResMgr:AddCash(count)
    elseif 2 == resID then
        ResMgr:AddEuro(count)
    elseif 3 == resID then
        ResMgr:AddDiamond(count)
    elseif 4 == resID then
        if self.m_PersonalData.m_SupportCount then
            self.m_PersonalData.m_SupportCount  = self.m_PersonalData.m_SupportCount + count
        else
            self.m_PersonalData.m_SupportCount = count
        end
        EventManager:DispatchEvent("FLY_ICON", nil, 8, nil)
    end
end

--[[
    @desc: 检查存档是否有已经处理过并且不能再被处理的事务id
    author:{author}
    time:2023-08-28 11:49:43
    --@affairID: 
    @return:
]]
function PersonalDevModel:CheckAffairIDCanUse(affairID)
    for _, id in ipairs(self.m_PersonalData.m_curNotUseAffairIDs or {}) do
        if id == affairID then
            return false
        end
    end
    return true
end

--[[
    @desc: 获取当前精力罐数量
    author:{author}
    time:2023-08-30 15:16:09
    @return:
]]
function PersonalDevModel:GetCurEnergyTanks()
    if not self.m_PersonalData.m_EnergyTanks then
        self.m_PersonalData.m_EnergyTanks = 0
    end
    return self.m_PersonalData.m_EnergyTanks
end

--[[
    @desc: 获取精力罐
    author:{author}
    time:2023-08-30 15:19:13
    --@num: 
    @return:
]]
function PersonalDevModel:AddEnergyTanks(num)
    if not self.m_PersonalData.m_EnergyTanks then
        self.m_PersonalData.m_EnergyTanks = 0
    end
    self.m_PersonalData.m_EnergyTanks  = self.m_PersonalData.m_EnergyTanks + num
end

--使用精力罐恢复精力
function PersonalDevModel:ConsumEnergyTank(num)
    if num > self:GetCurEnergyTanks() then
        return false
    end
    self.m_PersonalData.m_EnergyTanks  = self.m_PersonalData.m_EnergyTanks - num
    -- local recoverEnergy = num * ConfigMgr.config_global.energy_restore
    -- if self.m_PersonalData.m_Energy then
    --     self.m_PersonalData.m_Energy  = self.m_PersonalData.m_Energy + recoverEnergy
    -- else
    --     self.m_PersonalData.m_Energy = recoverEnergy
    -- end
    self.m_PersonalData.m_Energy = ConfigMgr.config_global.energy_uplimit
    if self.m_CurTimer["EnergyRecoverCD"] then
        GameTimer:StopTimer(self.m_CurTimer["EnergyRecoverCD"])
        self.m_CurTimer["EnergyRecoverCD"] = nil
    end
    EventManager:DispatchEvent(GameEventDefine.PersonalDev_EnergyCover)
    return true
end

--[[
    @desc: 完成一次竞选的结果计算，比如stage+1什么的
    author:{author}
    time:2023-09-19 14:40:19
    --@isWin: 
    @return:
]]
function PersonalDevModel:WinOneCampaignTurn()
    
    if self.m_PersonalData.m_StageRewards == 0 then
        self.m_PersonalData.m_StageRewards = self.m_PersonalData.m_CurStage
    end
    self.m_PersonalData.m_CurStage  = self.m_PersonalData.m_CurStage + 1
end

--[[
    @desc: 获取当前需要领取的竞选阶段奖励，如果不为0就是有奖励领取，并且对应到哪个阶段
    author:{author}
    time:2023-09-19 15:06:28
    @return:
]]
function PersonalDevModel:GetCurStageRewardsInfo()
    return self.m_PersonalData.m_StageRewards
end

function PersonalDevModel:ClaimCurStageRewards()
    local isTitleLvlUp = false
    local nextDevCfg = ConfigMgr.config_develop[self.m_PersonalData.m_TitleLevel + 1]
    if not nextDevCfg then
        return false
    end 
    --给予奖励
    local stageCfgLvl = ConfigMgr.config_stage[self.m_PersonalData.m_TitleLevel + 1]
    if stageCfgLvl then
        if not self.m_PersonalData.m_CurClaimedRewards then
            self.m_PersonalData.m_CurClaimedRewards = {}
        end
        table.insert(self.m_PersonalData.m_CurClaimedRewards, self.m_PersonalData.m_StageRewards)
        local rewards = stageCfgLvl[self.m_PersonalData.m_StageRewards].rewards
        self.m_PersonalData.m_StageRewards = 0
        -- local rewards = {}
        -- rewards[1] = 3
        -- rewards[2] = 4
        -- rewards[3] = 5
        -- rewards[4] = 6
        -- rewards[5] = 1112
        local isShowLvlUp = false
        if self.m_PersonalData.m_CurStage > nextDevCfg.stage then
            self:SetTitle(self.m_PersonalData.m_TitleLevel + 1)
            self.m_PersonalData.m_CurClaimedRewards = {}
            isShowLvlUp = true
        end
        self:GiveStageRewards(rewards, function()
            if isShowLvlUp then
                --弹出升级面板
                GameTableDefine.PersonalLvlUpUI:GetView()
            end
        end)
    end
    return true
end

function PersonalDevModel:GetCurrHeadIconStr()
    local devCfg = ConfigMgr.config_develop[PersonalDevModel:GetTitle()]
    local iconStr = "icon_boss_001_01"
    if devCfg then
        local bossNum = string.gsub(LocalDataManager:GetDataByKey("boss_skin"), "Boss_", "")
        iconStr = string.gsub(devCfg.boss_icon, "num", bossNum)
    end
    return iconStr
end

function PersonalDevModel:GetDefineHeadIconStr(title)
    local devCfg = ConfigMgr.config_develop[title]
    local iconStr = "icon_boss_001_01"
    if devCfg then
        local bossNum = string.gsub(LocalDataManager:GetDataByKey("boss_skin"), "Boss_", "")
        iconStr = string.gsub(devCfg.boss_icon, "num", bossNum)
    end
    return iconStr
end

function PersonalDevModel:GiveStageRewards(rewards, cb)
    -- 1 知名度
    -- 2 绿钞
    -- 3 欧元
    -- 4 钻石
    -- 5 装备
    local purchaseID = 0
    for k, v in pairs(rewards) do
        if k == 1 then
            GameTableDefine.StarMode:StarRaise(v)
        elseif k == 2 then
            ResourceMgr:AddCash(v)
        elseif k == 3 then
            ResourceMgr:AddEuro(v)
        elseif k == 4 then
            ResourceMgr:AddDiamond(v)
        elseif k == 5 then
            purchaseID = v
        end
    end
    if purchaseID > 0 then
        --做弹窗奖励了
        GameTableDefine.ShopManager:Buy(purchaseID, false, function()           
        end,function()                        
            --self:refresh()   
            GameTableDefine.PurchaseSuccessUI:SuccessBuy(purchaseID, cb)                        
        end)
    else
        if cb then
            cb()
        end
    end
end

function PersonalDevModel:ClearCopyGameObjectStage(EnGo)
    UnityHelper.IgnoreRenderer(EnGo, false)
    local tmpGo = UnityHelper.FindTheChildByGo(EnGo, "WorkState")
    if tmpGo then
        tmpGo:SetActive(false)
    end
end

--[[
    @desc: 刷新事物购买的相关数据
    author:{author}
    time:2023-09-26 16:58:01
    @return:
]]
function PersonalDevModel:RefreshAffairBuyData()
    if not self.m_PersonalData.m_CurBuyAffairTime then
        self.m_PersonalData.m_CurBuyAffairTime =  GameTimeManager:GetCurrentServerTime(true)
    end
    local buyTimeData = GameTimeManager:GetTimeLengthDate(self.m_PersonalData.m_CurBuyAffairTime)
    local nowTimeData = GameTimeManager:GetTimeLengthDate(GameTimeManager:GetCurrentServerTime(true))
    if buyTimeData and nowTimeData then
        if nowTimeData.d - buyTimeData.d >= 1 then
            self.m_PersonalData.m_CurBuyAffairTimes = 0
        end
    end
end

function PersonalDevModel:CheckAffairCanBuy(times)
    -- if not self.m_PersonalData.m_CurBuyAffairTime then
    --     self.m_PersonalData.m_CurBuyAffairTime =  GameTimeManager:GetCurrentServerTime(true)
    -- end
    -- local buyTimeData = GameTimeManager:GetTimeLengthDate(self.m_PersonalData.m_CurBuyAffairTime)
    -- local nowTimeData = GameTimeManager:GetTimeLengthDate(GameTimeManager:GetCurrentServerTime(true))
    -- if buyTimeData and nowTimeData then
    --     if nowTimeData.d - buyTimeData.d >= 1 then
    --         self.m_PersonalData.m_CurBuyAffairTimes = 0
    --     end
    -- end
    self:RefreshAffairBuyData()
    return self.m_PersonalData.m_CurBuyAffairTimes + times <= ConfigMgr.config_global.affairs_property.buyMaxLimit
end

function PersonalDevModel:BuyAffairTimes(num)
    self:AddAffairLimit(num)
    if not self.m_PersonalData.m_CurBuyAffairTimes then
        self.m_PersonalData.m_CurBuyAffairTimes = 0
    end
    self.m_PersonalData.m_CurBuyAffairTimes  = self.m_PersonalData.m_CurBuyAffairTimes + num
    self.m_PersonalData.m_CurBuyAffairTime = GameTimeManager:GetCurrentServerTime(true)
end

function PersonalDevModel:GetCurBuyAffairTimes()
    return self.m_PersonalData.m_CurBuyAffairTimes or 0
end

function PersonalDevModel:GetCurClaimedStageRewards()
    return self.m_PersonalData.m_CurClaimedRewards or {}
end
