local RouletteUI = GameTableDefine.RouletteUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local TimerMgr = GameTimeManager
local MainUI = GameTableDefine.MainUI
local ShopManager = GameTableDefine.ShopManager

local WHEEL = "wheel"

local burstTime = nil

function RouletteUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ROULETTE_UI, self.m_view, require("GamePlay.Shop.RouletteUIView"), self, self.CloseView)
    return self.m_view
end

function RouletteUI:AlreadyGet()
    local cfg = ConfigMgr.config_wheel
    local result = {}
    for k,v in pairs(cfg) do
        if v.num == 1 and ShopManager:BoughtBefor(v.shopId[1]) then
            table.insert(result, v.shopId[1])
        end
    end

    return result
end

function RouletteUI:GoalBurstTime()
    if burstTime then
        return burstTime
    end

    burstTime = ConfigMgr.config_global.wheel_burst

    return burstTime
end

function RouletteUI:SaveBurstTime(check, value)--积攒次数,自动免费再转一次,必出好东西
    local data = LocalDataManager:GetDataByKey(WHEEL)
    if data["burst"] == nil then
        data["burst"] = 0
    end

    if check then
        return data["burst"]
    end

    data["burst"] = value

    LocalDataManager:WriteToFile()
end

function RouletteUI:UpdateWheelCDTime(check)
    local data = LocalDataManager:GetDataByKey(WHEEL)
    local timeNeed = ConfigMgr.config_global.wheel_free * 3600--单位转换成秒

    local nowTime = TimerMgr:GetCurrentServerTime(true)
    if data["last"] == nil then
        data["last"] = nowTime - timeNeed--让CD一定可以过
    end

    local timePass = nowTime - data["last"]
    local timeExit = timeNeed - timePass
    if check then
        return timeExit > 0 and timeExit or 0
    end

    data["last"] = nowTime

    MainUI:RefreshWheelHint()

    LocalDataManager:WriteToFile()
end

function RouletteUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ROULETTE_UI)
    self.m_view = nil
    collectgarbage("collect")
end