---@class CoinPusherManager
local CoinPusherManager = GameTableDefine.CoinPusherManager
local SeasonPassManager = GameTableDefine.SeasonPassManager
local shopManager = GameTableDefine.ShopManager
local ConfigMgr = GameTableDefine.ConfigMgr

local gameType = GameTableDefine.SeasonPassManager.MiniGameType["tuibiji"]
local saveData = nil    ---saveData.Game

local tuibijiConfig = nil
local tuibijiByIDConfig = nil
local PointRewardConfig = nil

local awardTable = {}   ---@type number[][]
local canUse = {}
local necessary = {}


function CoinPusherManager:Init()
    self.mapData = nil
    local passData = SeasonPassManager:GetCurrentPassData()
    if not passData.game then
        passData.game = {}
    end

    tuibijiConfig = ConfigMgr.config_pass_game_tuibiji
    tuibijiByIDConfig = ConfigMgr.config_pass_game_tuibiji_byID
    PointRewardConfig = ConfigMgr.config_pass_point_reward
    
    saveData = passData.game
    awardTable = {}
    canUse = {}
    necessary = {}
    self:GetMapData()
    self.mapData = saveData.map

    
    
end

--region 初始化推币机奖励内容

function CoinPusherManager:InitCoinPusher()
    -- 初始化前两行格子
    local firstTwoRowsCfg = tuibijiConfig[2]
    for i = 1, #firstTwoRowsCfg do
        local cfg = firstTwoRowsCfg[i]
        local row, column = self:GetGeneratPos(cfg)
        if not awardTable[row] then
            awardTable[row] = {}
        end
        awardTable[row][column] = cfg.id
    end

    -- 初始化第3行到第5行可用表
    self:InitCanUseTable()
    -- 生成格子内容, 先生成必须的奖励, 再生成剩余格子的奖励
    necessary = table.Shuffle(necessary)
    for i = #necessary, 1, -1 do
        local curAward = necessary[i]
        local row, column = self:GetGeneratPos(curAward)
        if not awardTable[row] then
            awardTable[row] = {}
        end
        if not awardTable[row][column] then
            awardTable[row][column] = curAward.id
        else
            while awardTable[row][column] do
                row, column = self:GetGeneratPos(curAward)
                if not awardTable[row] then
                    awardTable[row] = {}
                end
                if not awardTable[row][column] then
                    awardTable[row][column] = curAward.id
                    break
                end
            end
            --if not awardTable[row] then
            --    awardTable[row] = {}
            --end
            --awardTable[row][column] = curAward.id

        end

    end
    
    for rowIndex = 3, 5 do
        if not awardTable[rowIndex] then
            awardTable[rowIndex] = {}
        end
        local curRow = awardTable[rowIndex]
        for columnIndex = 1, 5 do
            if not curRow[columnIndex] then
                curRow[columnIndex] = self:GetARandomCanUse().id
            end
        end
    end
    return awardTable
end

function CoinPusherManager:InitCanUseTable()
    local randomRowsCfg = tuibijiConfig[1]
    canUse = Tools:CopyTable(randomRowsCfg)
    for i = #canUse, 1, -1 do
        canUse[i].used = 0
        if canUse[i].min_num > 0 then
            canUse[i].used = canUse[i].min_num
        end
        -- 如果有最小数量限制, 先全部找出来并在生成时优先生成
        for k = 1, canUse[i].min_num do
            table.insert(necessary, canUse[i])
        end
        if canUse[i].used >= canUse[i].max_num then
            table.remove(canUse, i)
        end
    end
end

function CoinPusherManager:GetARandomCanUse()
    local i, randomValue = table.GetRandomKeyValue(canUse)
    if randomValue.used < randomValue.max_num then
        randomValue.used = randomValue.used + 1
        if randomValue.used >= randomValue.max_num then
            table.remove(canUse, i)
        end
        return randomValue
    end
end

---获取随机的生成位置
---@return number,number 行, 列
function CoinPusherManager:GetGeneratPos(tuibijiCfg)
    if not tuibijiCfg then
        return
    end
    local row = tuibijiCfg.row_num and tuibijiCfg.row_num[math.random(1, #tuibijiCfg.row_num)] or math.random(3, 5)
    local column = tuibijiCfg.column_num and tuibijiCfg.column_num[math.random(1, #tuibijiCfg.column_num)] or math.random(1, 5)
    return row, column
end


--endregion

function CoinPusherManager:GetMapData()
    if not saveData then
        return 
    end
    if not saveData.map then
        saveData.map = {}
        local initAwardTable = self:InitCoinPusher()
        for row = 1, #initAwardTable do
            for column = 1, #initAwardTable[row] do
                if not saveData.map[row] then
                    saveData.map[row] = {}
                end

                local awardID = initAwardTable[row][column]
                saveData.map[row][column] = {
                    awardID = awardID,
                    double = false,
                    removed = false
                }
            end
        end
    end
    if not saveData.resetMapTimes then
        saveData.resetMapTimes = 0
    end
    return saveData.map
end

---获取某个格子的奖励信息
---@return table,table 奖励配置, 商品配置
function CoinPusherManager:GetTheAwardCfd(row, column)
    if not row or not column then
        return  
    end
    local mapData = self:GetMapData()
    local data = mapData[row][column]
    local awardCfg = self:GetTuibijiCfgByID(data.awardID)
    return awardCfg, shopManager:GetCfg(awardCfg.shop_id)
end

function CoinPusherManager:GetTuibijiCfgByID(id)
    return tuibijiByIDConfig[id]
end

---返回每一列的位置
---*注意: mapData是以每一行的数据为单位保存的*
function CoinPusherManager:GetCurMapPos()
    local map = self:GetMapData()
    local result = { 0, 0, 0, 0, 0 }
    for r = #map, 1, -1 do
        for c = 1, #map[r] do
            local cellData = map[r][c]
            if cellData.removed then
                result[c] = 5 - r + 1
            end
        end
    end
    return result
end


function CoinPusherManager:WeightedRandom(weights)
    local total_weight = 0
    for _, weight in ipairs(weights) do
        total_weight = total_weight + weight
    end

    local random_value = math.random(1, total_weight)
    local cumulative_weight = 0

    for i, weight in ipairs(weights) do
        cumulative_weight = cumulative_weight + weight
        if random_value <= cumulative_weight then
            return i
        end
    end

    -- Fallback, should not reach here if weights are valid
    return #weights
end

--- 获取随机数量的推币的柱子
---@type number[] 柱子id数组
function CoinPusherManager:GetRandomPushColumn()
    local mapPos = CoinPusherManager:GetCurMapPos()
    local pushWeight = ConfigMgr.config_global.pass_game_pushWeight
    local pushCount = CoinPusherManager:WeightedRandom(pushWeight)
    local columnIndexTable = { 1, 2, 3, 4, 5 }
    local randomColumn = table.Shuffle(columnIndexTable)
    local selected = {}
    for i = 1, pushCount do
        table.insert(selected, randomColumn[i])
    end
    local invalid = {}
    for i = #selected, 1, -1 do
        if mapPos[selected[i]] >= 5 then
            invalid[i] = selected[i]
        end
    end
    if #selected <= Tools:GetTableSize(invalid) then
        for i = #selected + 1, #randomColumn do
            if mapPos[randomColumn[i]] < 5 then
                return { randomColumn[i] }
            end
        end
    else
        for i = #selected, 1, -1 do
            if invalid[i] then
                table.remove(selected, i)
            end
        end
        return selected
    end

end

function CoinPusherManager:PushCoin(index)
    local mapData = self:GetMapData()
    for r = #mapData, 1, -1 do
        for c = 1, #mapData[r] do
            if c == index then
                if mapData[r][c].removed == false then
                    mapData[r][c].removed = true
                    return
                end
            end
        end
    end
end

function CoinPusherManager:ResetMap()
    if not saveData then
        return
    end
    --2025-1-2fy添加统计当局消耗的门票总数充值
    if saveData.lastTimeCostTickets then
        saveData.lastTimeCostTickets = 0
    end
    saveData.map = nil
    if not saveData.resetMapTimes then
        saveData.resetMapTimes = 1
    else
        saveData.resetMapTimes  = saveData.resetMapTimes + 1
    end
    
    awardTable = {}
    canUse = {}
    necessary = {}
    self:GetMapData()
end

function CoinPusherManager:AddPlayTime()
    if not saveData then
        return
    end
    --2024-12-31 fy添加存储小游戏玩的总数量
    if not saveData.totalPlayTime then
        saveData.totalPlayTime = 1
    else
        saveData.totalPlayTime  = saveData.totalPlayTime + 1
    end
    saveData.playTime = saveData.playTime and saveData.playTime + 1 or 1
end

--[[
    @desc: fy添加获取小游戏总次数
    author:{author}
    time:2024-12-31 11:34:38
    @return:
]]
function CoinPusherManager:GetTotalPlayTime()
    if not saveData or not saveData.totalPlayTime then
        return 0
    end
    return saveData.totalPlayTime
end

function CoinPusherManager:ResetPlayTime()
    if not saveData then
        return
    end
    saveData.playTime = 0
end 

function CoinPusherManager:GetPlayTime()
    if not saveData then
        return
    end
    return saveData.playTime or 0
end

function CoinPusherManager:CanPush()
    local haveCanPushCell = false
    local curPos = self:GetCurMapPos()
    for i = 1, #curPos do
        if curPos[i] < 5 then
            haveCanPushCell = true
            break
        end
    end
    return haveCanPushCell
end

function CoinPusherManager:AddTicket(num)
    if not saveData then
        return
    end
    --2024-12-31 fy添加统计获取的总的门票数
    if not saveData.ticketTotal then
        saveData.ticketTotal = num
    else
        saveData.ticketTotal  = saveData.ticketTotal + num
    end
    saveData.ticket = saveData.ticket and saveData.ticket + (num or 1) or num
    EventDispatcher:TriggerEvent("SEASON_PASS_REFRESH_GAME_HINT_POINT")
end

--[[
    @desc: fy获取门票拥有的总数
    author:{author}
    time:2024-12-31 11:24:29
    @return:
]]
function CoinPusherManager:GetTotalTicket()
    if not saveData or not saveData.ticketTotal then
        return 0
    end
    return saveData.ticketTotal
end

function CoinPusherManager:UseTicket(num)
    if not saveData then
        return
    end
    if not saveData.lastTimeCostTickets then
        saveData.lastTimeCostTickets = num
    else
        saveData.lastTimeCostTickets = saveData.lastTimeCostTickets + num
    end
    
    saveData.ticket = saveData.ticket and saveData.ticket - (num or 1) or 0
    saveData.ticket = math.max(saveData.ticket, 0)

    self:AddPoint(num)

    --2024-12-27fy添加完成通行证任务的相关内容
    GameTableDefine.SeasonPassTaskManager:GetWeekTaskProgress(2,num)
    EventDispatcher:TriggerEvent("SEASON_PASS_REFRESH_GAME_HINT_POINT")

    --通行证小游戏票数量变化埋点
    local leftTicket = saveData.ticket
    GameSDKs:TrackForeign("pass_ticket", {behavior = 2,num = num,left = leftTicket})

end

--[[
    @desc: fy 获取上一次游戏消耗的门票数
    author:{author}
    time:2024-12-31 10:41:42
    @return:
]]
function CoinPusherManager:GetLastTimeCostTickets()
    if not saveData or not saveData.lastTimeCostTickets then
        return 0
    end
    return saveData.lastTimeCostTickets
end

--[[
    @desc: fy 获取重置奖池的总次数
    author:{author}
    time:2024-12-31 10:45:09
    @return:
]]
function CoinPusherManager:GetTotalResetMapTimes()
    if not saveData or not saveData.resetMapTimes then
        return 0
    end
    return saveData.resetMapTimes
end

function CoinPusherManager:GetTicketNum()
    if not saveData then
        return
    end
    return saveData.ticket or 0
end

function CoinPusherManager:CanReset()
    local mapPos = self:GetCurMapPos()
    local sum = 0
    for i = 1, #mapPos do
        sum = sum + 5 - mapPos[i]
    end
    if sum <= ConfigMgr.config_global.pass_game_resetPrize then
        return true
    else
        return false
    end
end

function CoinPusherManager:GetNeedTicket()
    if not saveData then
        return 0
    end
    local playTime = self:GetPlayTime()
    if not ConfigMgr.config_global.pass_game_ticket[playTime + 1] then
        return 0
    end
    local curPlayTime = ConfigMgr.config_global.pass_game_ticket[playTime + 1]  
    return curPlayTime
end

function CoinPusherManager:AddPoint(num)
    if not saveData then
        return 
    end
    saveData.point = (saveData.point or 0) + num

    repeat
        local curPoint, curLevel = self:GetPointAndLevel()
        local curMax = nil
        if PointRewardConfig[curLevel + 1] then
            curMax = PointRewardConfig[curLevel + 1].point
            if saveData.point >= curMax then
                self:SetPointLevel(curLevel + 1)
                --saveData.point = saveData.point - curMax
                printf("游戏积分等级: ", saveData.point, saveData.pointLevel)
            end
        end
        curPoint, curLevel = self:GetPointAndLevel()
        if not PointRewardConfig[curLevel + 1] then
            break
        end
        curMax = PointRewardConfig[curLevel + 1].point
    until not PointRewardConfig[curLevel + 1] or saveData.point < curMax
        
end

function CoinPusherManager:SetPointLevel(num)
    if not saveData then
        return
    end
    saveData.pointLevel = num
    EventDispatcher:TriggerEvent("SEASON_PASS_REFRESH_GAME_HINT_POINT")
    
end

function CoinPusherManager:GetPointAndLevel()
    if not saveData then
        return
    end
    return saveData.point or 0, saveData.pointLevel or 0
end

function CoinPusherManager:ChooseADoubleAward(cb)
    local randomRow, randomColumn
    local mapData = self:GetMapData()
    repeat
        local weight = ConfigMgr.config_global.pass_game_doubleWeight
        randomRow = self:WeightedRandom(weight)
        randomColumn = math.random(1, 5)
    until mapData[randomRow][randomColumn].double == false and mapData[randomRow][randomColumn].removed == false 
            and mapData[randomRow][randomColumn].awardID ~= 6 -- 双倍球不能被翻倍
    
    mapData[randomRow][randomColumn].double = true
    if cb then
        cb(randomRow, randomColumn)
    end
end

function CoinPusherManager:PrintMap()
    local mapData = self:GetMapData()
    local mapStr = "\n"
    for k = 1, 5 do
        for r = 1, #mapData do
            for c = 1, #mapData[r] do
                if k == r then
                    mapStr = mapStr .. tostring(mapData[r][c].removed) .. "\t"
                end
            end
        end
        mapStr = mapStr .. "\n"
    end

    print(mapStr)
end

function CoinPusherManager:GetPointAward(level)
    if not saveData then
        return
    end
    if not saveData.claim then
        saveData.claim = {}
    end
    saveData.claim[tostring(level)] = true
    EventDispatcher:TriggerEvent("SEASON_PASS_REFRESH_GAME_HINT_POINT")
    
    return PointRewardConfig[level]
end

function CoinPusherManager:CheckCanClaim(level)
    if not saveData then
        return false
    end
    local point, curLevel = self:GetPointAndLevel()
    curLevel = level == 0 and 1 or level
    if not saveData.claim or not saveData.claim[tostring(curLevel)] then
        return point >= PointRewardConfig[curLevel].point
    else 
        return false
    end
    local result = (not saveData.claim[tostring(level)]) and point > PointRewardConfig[curLevel].point
    return result
end


---设置可选奖励
---@param row number 行
---@param column number 列
---@param rewardCfg table 奖励id *不是shopID*
---@param multiple
function CoinPusherManager:SetChoosableAward(row, column, rewardID, multiple)
    local mapData = self:GetMapData()
    -- 确保 row 在 1 到 5 之间
    if row < 1 then
        row = 1
    elseif row > 5 then
        row = 5
    end

    -- 确保 column 在 1 到 5 之间
    if column < 1 then
        column = 1
    elseif column > 5 then
        column = 5
    end
    mapData[row][column].awardID = rewardID
    mapData[row][column].multiple = multiple
end

--[[
    @desc: fy设置自选成功的总次数
    author:{author}
    time:2024-12-31 11:03:14
    --@num: 
    @return:
]]
function CoinPusherManager:AddChooseAwardTimes(num)
    if not saveData then
        return
    end
    if not saveData.chooseAwardTimes then
        saveData.chooseAwardTimes = num
    else
        saveData.chooseAwardTimes = saveData.chooseAwardTimes + num
    end
end

--[[
    @desc: fy获取自选奖励设置成功的总次数
    author:{author}
    time:2024-12-31 11:02:54
    @return:
]]
function CoinPusherManager:GetChooseAwardTimes()
    if not saveData or not saveData.chooseAwardTimes then
        return 0
    end
    return saveData.chooseAwardTimes
end
---还原可选奖励
------@param row number 行
-----@param column number 列
function CoinPusherManager:ResetTheChoosableAward(row, column)
    -- 确保 row 在 1 到 5 之间
    if row < 1 then
        row = 1
    elseif row > 5 then
        row = 5
    end

    -- 确保 column 在 1 到 5 之间
    if column < 1 then
        column = 1
    elseif column > 5 then
        column = 5
    end
    local choosableConfig = tuibijiConfig[3]
    local cfg = nil
    for k, v in pairs(choosableConfig) do
        if v.row_num[1] == row and v.column_num[1] == column then
            cfg = v
            break
        end
    end
    local mapData = self:GetMapData()
    mapData[row][column].awardID = cfg.id
    mapData[row][column].multiple = nil
end

function CoinPusherManager:GetTheMapDataMultiple(row, column)
    local mapData = self:GetMapData()
    local theData = mapData[row][column]
    local result = (theData.double and 2 or 1) * (theData.multiple and theData.multiple or 1)
    return result
end

function CoinPusherManager:GetBiggestAvailable()
    local point, curLevel = self:GetPointAndLevel()
    local result = 0
    for i = 1, curLevel do
        if self:CheckCanClaim(i) then
            result = i
        end
    end
    if result == 0 then
        result = curLevel
    end
    return result
end

function CoinPusherManager:GetSmallestAvailable()
    local point, curLevel = self:GetPointAndLevel()
    local result = 0
    for i = 1, curLevel do
        if self:CheckCanClaim(i) then
            result = i
            break
        end
    end
    if result == 0 then
        result = curLevel
    end
    return result
end


function CoinPusherManager:IsNeedShowGameHintPoint()
    local canPush = self:CanPush()
    local needNum = self:GetNeedTicket()
    local ticketEnough = self:GetTicketNum() >= needNum
    local canPlay = canPush and ticketEnough
    local point, level = self:GetPointAndLevel()
    local available = false
    for i = 1, level do
        if self:CheckCanClaim(i) then
            available = true
            break
        end
    end
    if canPlay or available then
        return true
    end
    return false
end

function CoinPusherManager:OpenChooseView()
    if not saveData then
        return
    end
    saveData.OpenChooseView = true
end

function CoinPusherManager:CheckHaveOpenChooseView()
    if not saveData then
        return
    end
    return saveData.OpenChooseView
end


return CoinPusherManager
