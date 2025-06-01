---@class PiggyBankUI
local PiggyBankUI = GameTableDefine.PiggyBankUI
local MainUI = GameTableDefine.MainUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local ResourceManger = GameTableDefine.ResourceManger
local CfgMgr = GameTableDefine.ConfigMgr
local StarMode = GameTableDefine.StarMode
local UIPopManager = GameTableDefine.UIPopupManager
local GameTimeManager = GameTimeManager

local GameLauncher = CS.Game.GameLauncher

local Earnings



function PiggyBankUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PIGGY_BANK_UI, self.m_view, require("GamePlay.Common.UI.PiggyBankUIView"), self, self.CloseView)
    return self.m_view
end

function PiggyBankUI:OpenView()
    self:GetView()
    self:SetEnterDay()

end

function PiggyBankUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PIGGY_BANK_UI)
    self.m_view = nil
    collectgarbage("collect")
    UIPopManager:DequeuePopView(self)
end

---检查是否满级[全部购买]
function PiggyBankUI:CheckIsLvFull()
    return self.PiggyBankData.level > Tools:GetTableSize(self.cfgPiggyBank)
end

---检查是否有里程碑奖励可领
function PiggyBankUI:CheckMileRewardEnable()
    for i, v in pairs(self:GetMileRewardConf()) do
        if self.PiggyBankData.level + 1000 >= v.id and not Tools:CheckContain(v.id, self.PiggyBankData.draw_history or {}) then
            return true
        end
    end

    return false
end

---检查是否满级[全部购买]且领取全部里程碑奖励
function PiggyBankUI:CheckIsFullAndClaimAll()
    local hadClaimAll = true
    for i, v in pairs(self:GetMileRewardConf()) do
        local hadClaim = Tools:CheckContain(v.id, self.PiggyBankData.draw_history or {})
        if not hadClaim then
            hadClaimAll = false
            break
        end
    end

    if self.PiggyBankData.level > Tools:GetTableSize(self.cfgPiggyBank) and hadClaimAll then
        return true
    end

    return false
end

--获取存钱罐的存档数据
function PiggyBankUI:GetPiggyBankData()
    local piggyBankData = LocalDataManager:GetDataByKey("piggy_bank")
    if not piggyBankData.draw_history then
        piggyBankData.draw_history = {}
    end
    
    if not piggyBankData.show_history then
        piggyBankData.show_history = {}
    end

    if not piggyBankData.show_history[tostring(piggyBankData.level)] then
        piggyBankData.show_history[tostring(piggyBankData.level)] = 0
    end
    
    return piggyBankData
end

--判断存钱罐是否开启
function PiggyBankUI:GetPiggyBankEnable()
    self.PiggyBankData = self:GetPiggyBankData()
    if not self.PiggyBankData.level then
        self.PiggyBankData.level = 1
    end
    self.cfgPiggyBank = CfgMgr.config_piggybank
    if self:CheckIsFullAndClaimAll() then
        return false
    end
    if self.PiggyBankData.level > 1 then
        return true
    end

    local fame = 0
    if self.cfgPiggyBank[self.PiggyBankData.level + 1000] then
        fame = self.cfgPiggyBank[self.PiggyBankData.level + 1000].fame
    end

    return StarMode:GetStar() >= fame
end

--判断存钱罐是否工作
function PiggyBankUI:CheckUsefor()
    self.PiggyBankData = self:GetPiggyBankData()
    self.cfgPiggyBank = CfgMgr.config_piggybank
    if not self.PiggyBankData.level then
        self.PiggyBankData.level = 1
    end
    ---K115改为只要没全部购买就一直显示，只是打开界面不满足知名度时不能购买
    if self:CheckIsFullAndClaimAll() then
        return false
    end
    --local fame
    --if self.cfgPiggyBank[self.PiggyBankData.level + 1000] then
    --    fame = self.cfgPiggyBank[self.PiggyBankData.level + 1000].fame
    --else
    --    fame = 0
    --end
    --local bool = fame > StarMode:GetStar()
    --if self:CheckIsFullAndClaimAll() or bool then
    --    return false
    --end
    return true
end

--判断存钱罐是否可以购买
function PiggyBankUI:CheckCanBuy()
    self.PiggyBankData = self:GetPiggyBankData()
    self.cfgPiggyBank = CfgMgr.config_piggybank
    if not self.PiggyBankData.level then
        self.PiggyBankData.level = 1
    end
    if self.PiggyBankData.level > Tools:GetTableSize(self.cfgPiggyBank) then
        return false,0
    end
    local fame = 0
    local piggyConfig = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    if piggyConfig then
        fame = piggyConfig.fame
        local curStar = StarMode:GetStar()
        --条件1 知名度
        if fame>curStar then
            return false,2,fame
        end
        local threhold = piggyConfig.threhold[1]
        --条件2 进度过半
        local canBuy = (self.PiggyBankData.value or 0) >= threhold*0.5
        return canBuy, 1
    else
        return false,0
    end
end

---检查是否应该弹窗提示，1.进度达到一半，2.进度满
function PiggyBankUI:CheckPopup(preValue,curValue)
    local cfg = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    if not cfg then
        return false
    end
    --0代表没有奖励，1代表中段奖励，2代表全满的奖励
    local preState = 0
    local curState = 0
    for k,v in pairs(cfg.threhold) do
        local thresholdHalf = v*0.5
        local thresholdFull = v
        if preValue>=thresholdFull then
            preState = 2
        elseif preValue>=thresholdHalf then
            preState = 1
        end
        if curValue>=thresholdFull then
            curState = 2
        elseif curValue>=thresholdHalf then
            curState = 1
        end
        break
    end
    return curState>preState
end

--增加累计值
function PiggyBankUI:AddValue(type)
    self.PiggyBankData = self:GetPiggyBankData()
    self.cfgPiggyBank = CfgMgr.config_piggybank
    local cfg = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    --if not cfg or cfg.fame > StarMode:GetStar() then
    --    return
    --end
    --K115改为不论是否达到了知名度需求，都可以为当前等级的存钱罐提供充能
    if not cfg then
        return
    end
    local needShowPopup = false
    for k,v in pairs(cfg.behavior) do
        if v.type == type then
            if not self.PiggyBankData.value then
                self.PiggyBankData.value = 0
            end
            local preValue = self.PiggyBankData.value
            self.PiggyBankData.value =  self.PiggyBankData.value + v.num
            local curValue = self.PiggyBankData.value

            --判断是否该弹窗
            needShowPopup = self:CheckPopup(preValue,curValue)
            break
        end
    end
    LocalDataManager:WriteToFile()
    --刷新     
    if type ~= 1 then
        MainUI:RefreshPiggyBankBtn()
    end

    if needShowPopup and self:GetPiggyBankEnable() then
        --self:OpenView()
        return true -- 关闭界面后, 飞钻石动效结束, 才弹出存钱罐界面; 还有公司升级时，type为2时，没有处理，没有配置为2的，暂不处理
    end
end

function PiggyBankUI:GMAddPiggyBankValue(num)
    self.PiggyBankData = self:GetPiggyBankData()
    local preValue = self.PiggyBankData.value
    self.PiggyBankData.value = (self.PiggyBankData.value or 0) + num
    local curValue = self.PiggyBankData.value
    LocalDataManager:WriteToFile()
    --刷新
    MainUI:RefreshPiggyBankBtn()
    --判断是否该弹窗
    self.cfgPiggyBank = CfgMgr.config_piggybank
    if self:CheckIsFullAndClaimAll() then
        return false
    end
    local needShowPopup = self:CheckPopup(preValue,curValue)
    if needShowPopup then
        self:OpenView()
    end
end

--进度
function PiggyBankUI:CalculationValue(isMin)
    self.cfgPiggyBank = CfgMgr.config_piggybank
    local cfg = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
    if not cfg then
        if self:CheckIsLvFull() then
            cfg = self.cfgPiggyBank[Tools:GetTableSize(self.cfgPiggyBank) + 1000]
        else
            return
        end
    end
    local threhold
    if isMin then
        threhold = cfg.threhold[1]
    else
        threhold = cfg.threhold[#cfg.threhold]
    end
    if not self.PiggyBankData.value then
        self.PiggyBankData.value = 0
    end
    return self.PiggyBankData.value / threhold
end

----检查当前能获得多少资源
--function PiggyBankUI:CalculateEarnings()
--    local cfg = self.cfgPiggyBank[self.PiggyBankData.level + 1000] or {}
--    self.PiggyBankData = self:GetPiggyBankData()
--    local value = self.PiggyBankData.value
--    for k,v in pairs(cfg.threhold) do
--        if v <= value then
--            return cfg.reward[k]
--        end
--    end
--    return {
--        ["num"] = 0,
--        ["type"] = 2,
--    }
--end

--检查当前能获得多少资源
function PiggyBankUI:CalculateEarnings()
    self.PiggyBankData = self:GetPiggyBankData()
    self.cfgPiggyBank = CfgMgr.config_piggybank
    local cfg = self.cfgPiggyBank[math.min(self.PiggyBankData.level, Tools:GetTableSize(self.cfgPiggyBank)) + 1000]
    if not cfg then
        return
    end

    local value = self.PiggyBankData.value or 0
    for k,v in pairs(cfg.threhold) do
        local startPoint = 0
        local endPoint = 0
        local max = 0
        local min = 0
        local rewardConfig = cfg.reward[k]
        if v*0.5 <= value then
            max = rewardConfig.num
            min = rewardConfig.num * 0.25
            startPoint = v * 0.5
            endPoint = v
        else
            max = rewardConfig.num * 0.25
            min = 0
            startPoint = 0
            endPoint = v * 0.5
        end
        local length = endPoint - startPoint
        local final = min + (max - min) * math.min(1,(value - startPoint)/length)
        final = math.floor(final)
        --printf("存钱罐奖励"..final)
        return {
            ["num"] = final,
            ["type"] = cfg.reward[k].type,
        }
    end
    return {
        ["num"] = 0,
        ["type"] = 2,
    }
end

-- 获取里程碑奖励配置数量
function PiggyBankUI:GetMileRewardConf()
    local extraReward = {}
    for _, piggyBankConf in pairs(CfgMgr.config_piggybank) do
        if piggyBankConf.mile_reward and piggyBankConf.mile_reward > 0 then
            table.insert(extraReward, piggyBankConf)
        end
    end

    table.sort(extraReward, function(a,b) return a.id < b.id end)

    return extraReward
end

function PiggyBankUI:AfterGetMileReward(mile_reward_id)
    table.insert(self.PiggyBankData.draw_history, mile_reward_id)
    LocalDataManager:WriteToFile()
    self:GetView():refresh(true, false)

    MainUI:UpdateResourceUI()
    MainUI:RefreshPiggyBankBtn()
end

--- 领取里程碑奖励
function PiggyBankUI:GetMileReward(mile_reward_id)
    local cfg = self.cfgPiggyBank[mile_reward_id]
    local hadGot = Tools:CheckContain(mile_reward_id, self.PiggyBankData.draw_history or {})

    if cfg and cfg.mile_reward > 0 and not hadGot then
        local shopConf = CfgMgr.config_shop[cfg.mile_reward]
        if shopConf.type == 3 then
            self:GetView():PlayDiamondFly(function()
                ResourceManger:Add(shopConf.type, shopConf.amount, nil, function()
                    PiggyBankUI:AfterGetMileReward(mile_reward_id)
                end, false)
            end)
        elseif shopConf.type == 13 then
            GameTableDefine.ShopManager:Buy(cfg.mile_reward, false, nil, function()
                GameTableDefine.PurchaseSuccessUI:SuccessBuy(cfg.mile_reward, function()
                    PiggyBankUI:AfterGetMileReward(mile_reward_id)
                end)
            end)
        else
            print("未知里程碑奖励类型")
        end
        
        
        
        
        --GameTableDefine.ShopManager:Buy(cfg.mile_reward, false, function()
        --    print("领取里程碑奖励 Buy: " .. cfg.mile_reward)
        --    table.insert(self.PiggyBankData.draw_history, mile_reward_id)
        --    LocalDataManager:WriteToFile()
        --    self:GetView():RefreshMilePart()
        --    self:GetView():RefreshDiamondText()
        --
        --    MainUI:UpdateResourceUI()
        --    MainUI:RefreshPiggyBankBtn()
        --end)
    end
end

--获取奖励
function PiggyBankUI:GetReward()
    self.cfgPiggyBank = CfgMgr.config_piggybank
    self.PiggyBankData = self:GetPiggyBankData()
    local cfg = self.PiggyBankData and self.cfgPiggyBank[self.PiggyBankData.level + 1000] or nil
    local shopId = cfg and cfg.shopId or ""

    GameSDKs:TrackForeign("money_box", {id = tostring(shopId), order_state = 7, order_state_desc = "进入发放小猪奖励"})

    Earnings = self:CalculateEarnings()
    ResourceManger:Add(Earnings.type, Earnings.num, nil, function()
        GameSDKs:TrackForeign("money_box", {id = tostring(shopId), order_state = 8, order_state_desc = "发放小猪奖励成功"})

        self.PiggyBankData.level = self.PiggyBankData.level + 1
        self.PiggyBankData.value = 0

        -- 重置各阶段show次数
        self.PiggyBankData.show_history[tostring(self.PiggyBankData.level)] = 0
        --self.cfgPiggyBank = CfgMgr.config_piggybank
        --local cfg = self.cfgPiggyBank[self.PiggyBankData.level + 1000]
        --if cfg then
        --    -- 存满后，领取不重置为0，继续存  -- 这一版暂时不做这个逻辑 2025.01.06 K131
        --    if self.PiggyBankData.value < cfg.threhold[1] then
        --        self.PiggyBankData.value = math.max(0, self.PiggyBankData.value - cfg.threhold[1] * 0.5)
        --    else
        --        self.PiggyBankData.value = math.max(0, self.PiggyBankData.value - cfg.threhold[1])
        --    end
        --else
        --    self.PiggyBankData.value = 0
        --end
        
        -- 补单回调时，UI已经打开的情况下，才刷新UI界面，否则会报错（节点、数据 找不到等等）
        if GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.PIGGY_BANK_UI) then
            self:GetView():refresh(true, true)
        end
    end, false)

    MainUI:RefreshPiggyBankBtn()

    if Earnings.type == 3 then
        GameSDKs:TrackForeign("virtual_currency", {currency_type = 1, pos = "存钱罐", behaviour = 1, num_new = tonumber(Earnings.num)})
    end
    LocalDataManager:WriteToFile()
end

function PiggyBankUI:GetEarnings()
    return Earnings
end

function PiggyBankUI:SetEnterDay()
    local piggyBankData = self:GetPiggyBankData()
    if piggyBankData then
        local now = GameTimeManager:GetCurrentServerTime(true)
        local day = GameTimeManager:FormatTimeToD(now)
        piggyBankData.enterDay = day
    end
end

---判断是否需要当天第一次打开
function PiggyBankUI:OpenPanelTodayFirst()

    if not self:CheckUsefor() then
        return
    end
    local piggyBankData = self:GetPiggyBankData()
    local enterDay = piggyBankData.enterDay
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if (enterDay == day) then
        return
    end
    --用于当天第一次判断
    if not self:CheckPopup(0,piggyBankData.value) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if self.waitOpenTimer then
        return
    end
    if StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
            GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI) then
        self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(1000,function()
            --GameTimer:StopTimer(self.waitOpenTimer)
            self.waitOpenTimer = GameTimer:CreateNewMilliSecTimer(100,function()
                if not (StarMode:GetStar() < 3 or not GameLauncher.Instance:IsHide() or GameTableDefine.CutScreenUI.m_view or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.OFFLINE_REWARD_UI) or
                        GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.INTRODUCE_UI) or GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MONTH_CARD_UI)) then
                    if enterDay ~= day then
                        self:OpenView()
                    end
                    GameTimer:StopTimer(self.waitOpenTimer)
                    self.waitOpenTimer = nil
                end
            end, true)
        end)
        return
    end
    if enterDay ~= day and not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.ACCUMULATED_CHARGE_UI) then
        self:OpenView()
    end

end

function PiggyBankUI:CheckCanOpen()
    if not self:CheckUsefor() then
        return
    end

    if not self.PiggyBankData then
        self.PiggyBankData = self:GetPiggyBankData()
    end

    local enterDay = self.PiggyBankData.enterDay
    local now = GameTimeManager:GetCurrentServerTime(true)
    local day = GameTimeManager:FormatTimeToD(now)
    if (enterDay == day) then
        return
    end
    --用于当天第一次判断
    if not self:CheckPopup(0, self.PiggyBankData.value) then
        return
    end

    if not GameUIManager:IsUIOpen(ENUM_GAME_UITYPE.MAIN_UI) then
        return
    end
    if self.waitOpenTimer then
        return
    end
    if StarMode:GetStar() < 3 then
        return
    end

    -- 各阶段主动show次数判断
    if self.PiggyBankData.show_history[tostring(self.PiggyBankData.level)] >= 5 then
        return false
    end

    self.PiggyBankData.show_history[tostring(self.PiggyBankData.level)] = self.PiggyBankData.show_history[tostring(self.PiggyBankData.level)] + 1
    --LocalDataManager:WriteToFile()
    return true
end