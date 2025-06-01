LuaTools = {
    uidNumber = 10000,
    m_TimingValue = 0,
    m_orgServerTime = 0,

    COLOR_WHITE = "FFFFFF",
    COLOR_RED = "FF0000",
    COLOR_GREEN = "00FF00",
    COLOR_YELLOW = "FFFF00",
    COLOR_BULE = "0000FF",

    COLOR_GREEN_NORMAL = "82ea92",

    COLOR_TITLE_RARITY = {
       -- "474747", --gray
        "3a7404", --green
        "004f95", --blue
        "900085", --purple
        "975100", --orange
        "edd882" -- red
    },

    COLOR_TITLE_RARITY_DARK = {
       -- "bfbfbf", --gray
        "77ca00", --green
        "4da5ff", --blue
        "cb4dff", --purple
        "ff834d", --orange
        "edd882" -- red
    },
}

local io = io;
local os = os;

-- similar with python's repr
function LuaTools:repr(val)
    if type(val) == 'string' then
        return string.format('"%s"', val)
    else
        return tostring(val)
    end
end

function LuaTools:NewTable(parent)
    local instance = {}
    setmetatable(instance, {
        __index = function(t, key)
            if parent[key] ~= nil then
                return parent[key]
            end
            error("can't find the variable " .. key)
        end,
        __newindex = function(t, key, value)
            if parent[key] ~= nil then
                rawset(t, key, value)
            else
                error("can't add the variable " .. key)
            end
        end
    })
    return instance
end

--string extension
function LuaTools:SplitString(str, sep)
    assert(str and sep and #sep > 0)
    if #str == 0 then return {} end
    local reg = string.format('[%s]', sep)
    local r = {}
    local _begin = 1
    while _begin <= #str do
        local _end = string.find(str, reg, _begin) or #str + 1
        table.insert(r, string.sub(str, _begin, _end - 1))
        _begin = _end + 1
    end
    if string.match(string.sub(str, #str, #str), reg) then table.insert(r, '') end
    return r
end

function LuaTools:ConcatString(dest, src, sep)
    if dest ~= "" then
        dest = dest .. sep .. src
    else
        dest = dest .. src
    end

    return dest
end

function LuaTools:split_item_spec(item_string)
    local r = {}
    if item_string == 0 then return r end
    local info = self:SplitString(tostring(item_string), ",")
    for k, v in pairs(info) do
        local i = self:SplitString(v, ":")
        table.insert(r, {item_id = tonumber(i[1]), amount = tonumber(i[2])})
    end
    return r
end

function LuaTools:IsStringStartWith(str, prefix)
    return string.find(str, prefix) == 1
end

function LuaTools:IsStringEndWith(str, suffix)
    return self:IsStringStartWith(string.reverse(str), string.reverse(suffix))
end

function LuaTools:TrimString(s)
    local first = string.find(s, '%S')
    if not first then return '' end
    local last = string.find(string.reverse(s), '%S')
    return string.sub(s, first, #s + 1 - last)
end

function LuaTools:IsSubString(src, dest)
    local _start, _end = string.find(src, dest)

    if _start and _end then
        return true
    else
        return false
    end
end

-- table.xxx extention
-- unrecursive version
function LuaTools:MergeTable(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
    return dest
end

function LuaTools:ConcatTable(dest, src)
    local newTable = {}
    for k, v in pairs(dest) do
        table.insert(newTable, v)
    end

    for k, v in pairs(src) do
        table.insert(newTable, v)
    end

    return newTable
end

function LuaTools:IsArrayEqual(t, t2)
    for i, v in ipairs(t) do
        if v ~= t2[i] then return false end
    end
    return true
end

function LuaTools:array_new(len, val)
    local r = {}
    for i = 1, len do 
        table.insert(r, val)
    end
    return r
end

function LuaTools:FindInArray(t, val)
    for i, v in ipairs(t) do
        if val == v then return i end
    end
    return -1
end

function Tools:GetTableSize(t)
    local r = 0
    if t == nil then return r end
    for _, _ in pairs(t) do r = r + 1 end
    return r
end


function LuaTools:IsTableEqual(t, t2)
    if not t or not t2 then
        if not t and not t2 then -- both nil
            return true
        else
            return false
        end
    end

    local n = 0
    for k, v in pairs(t) do
        if type(v) ~= "table" then
            if v ~= t2[k] then return false end
        else
            if not self:IsTableEqual(v, t2[k]) then
                return false
            end
        end

        n = n + 1
    end

    return n == self:GetTableSize(t2)
end

--function LuaTools:CopyTable(t)
--    return self:MergeTable({}, t)
--end

function LuaTools:CopyTable(st)
    local tab = {}  
    for k, v in pairs(st or {}) do  
        if type(v) ~= "table" then  
            tab[k] = v  
        else  
            tab[k] = self:CopyTable(v)  
        end  
    end  
    return tab  
end  

function LuaTools:GetTableKeys(t)
    local r = {}
    for k, _ in pairs(t) do
        table.insert(r, k)
    end
    return r
end

function LuaTools:GetTableValues(t)
    local r = {}
    for _, v in pairs(t) do
        table.insert(r, v)
    end
    return r
end

function LuaTools:FilterTable(t, func)
    local r = {}
    for k, v in pairs(t) do
        if func(k, v) then r[k] = v end
    end
    return r
end

function LuaTools:FindInTable(t, func)
    if not t then return {} end
    return LuaTools:GetTableValues(
                LuaTools:FilterTable(t, func))
end

-- table.xxx extention
-- recursive version
function LuaTools:RequalTable(t, t2)
    local n = 0
    for k, v in pairs(t) do
        if type(v) == 'table' then
            local v2 = t2[k]
            if type(v2) ~= 'table' then return false end
            if not self:RequalTable(v, v2) then return false end
        else
            if v ~= t2[k] then return false end
        end
        n = n + 1
    end
    return n == self:GetTableSize(t2)
end

function LuaTools:RcopyTable(t)
    local r = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            r[k] = self:RcopyTable(v)
        else
            r[k] = v
        end
    end
    return r
end

function LuaTools:SumTableValues(t)
    local sum = 0
    for k, v in pairs(t) do
        sum = sum + v
    end
    return sum
end

function LuaTools:GetMutilRandomTargetTable(srcTable, randomNum, randomFunc)
  local new_table = {}
  if not next(srcTable) then
    return new_table
  end
  local tableSize = #srcTable
  if randomNum > tableSize then
    local count = 1
    while count <= randomNum do
      if count <= tableSize then
        table.insert(new_table, srcTable[count])
      else
        local newcount = count%tableSize
        if newcount == 0 then newcount = 1 end
        table.insert(new_table, srcTable[newcount]) 
      end
      count = count + 1
    end
  else
    local random_seed = {}
    for i = 1, tableSize, 1 do
        table.insert(random_seed, 1)
    end
    local cur_random = 1
    local result = {}
    local random_number = math.ceil(tableSize * randomFunc())
    while cur_random <= randomNum do
        if random_seed[random_number] == 1 then
            random_seed[random_number] = 0
            table.insert(new_table, srcTable[random_number])
            cur_random = cur_random + 1
        end
        random_number = random_number + 1
        if random_number > tableSize then
            random_number = 1
        end
    end
  end
  return new_table
end 

-- randomCount must less than randomNumber
function LuaTools:getMutilRandomNumber(randomNumber, randomCount)
    math.randomseed(os.time())  
    local random_seed = {}
    for i = 1, randomNumber, 1 do
        table.insert(random_seed, 1)
    end
    local cur_random = 1
    local result = {}
    while cur_random <= randomCount do
        local random_number = math.random(1, randomNumber)
        if random_seed[random_number] == 1 then
            random_seed[random_number] = 0
            table.insert(result, random_number)
            cur_random = cur_random + 1
        end
    end

    return result
end
function LuaTools:Math_cos(radian)
    local re = math.cos(radian)
    return LuaTools:Math_toDecimal1(re)
end

function LuaTools:Math_sin(radian)
    local re = math.sin(radian)
    return LuaTools:Math_toDecimal1(re)
end
function LuaTools:Math_toDecimal1(number)
    local fNum = tonumber(string.format("%.1f", number))
    if fNum == math.ceil(number) then
        return math.ceil(number)
    end
    return fNum
end

function LuaTools:Math_toDecimal2(number)
    local fNum = tonumber(string.format("%.2f", number))
    if fNum == math.ceil(number) then
        return math.ceil(number)
    end
    return fNum
end

--保留小数点后一位小数，无条件进位
--比如1.03--> 1.1
function LuaTools:Math_RoundOffTo1DecimalPlace(number)
    local num = math.ceil(number * 10)
    num = num / 10
    return num
end

--This func will return new Point Which old Point around axis point rote radian.
--radian is the increase value
function LuaTools:GetPointRotateByAxisAndAngle(radian, axisX, axisY, pointx, pointy)
    local tX = pointx - axisX
    local tY = pointy - axisY
    local cosa = LuaTools:Math_cos(radian)
    local sina = LuaTools:Math_sin(radian)
    pointx = tX * cosa - tY * sina + axisX
    pointy = tX * sina + tY * cosa + axisY
    return math.floor(pointx), math.floor(pointy)
end

function LuaTools:serialize(obj)  
    local lua = ""  
    local t = type(obj)  
    if t == "number" then  
        lua = lua .. obj  
    elseif t == "boolean" then  
        lua = lua .. tostring(obj)  
    elseif t == "string" then  
        lua = lua .. string.format("%q", obj)  
    elseif t == "table" then  
        lua = lua .. "{\n"  
    for k, v in pairs(obj) do  
        lua = lua .. "[" .. self:serialize(k) .. "]=" .. self:serialize(v) .. ",\n"  
    end  
    local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
        for k, v in pairs(metatable.__index) do  
            lua = lua .. "[" .. self:serialize(k) .. "]=" .. self:serialize(v) .. ",\n"  
        end  
    end  
        lua = lua .. "}"  
    elseif t == "nil" then  
        return nil  
    else  
        error("can not serialize a " .. t .. " type.")  
    end  
    return lua  
end  
  
function LuaTools:unserialize(lua)  
    local t = type(lua)  
    if t == "nil" or lua == "" then  
        return nil  
    elseif t == "number" or t == "string" or t == "boolean" then  
        lua = tostring(lua)  
    else  
        error("can not unserialize a " .. t .. " type.")  
    end  
    lua = "return " .. lua  
    local func = loadstring(lua)  
    if func == nil then  
        return nil  
    end  
    return func()  
end 

-------------------------------Math point 2d func-----------------------
function LuaTools:IsObjInList(obj, list)
    local is_in = false
    for k, v in pairs(list) do
        if obj == v then
            is_in = true
        end
    end
    return is_in
end
function LuaTools:P2D_MoveToTarget(m_x, m_y, targetX, targetY, moveSpeedx, moveSpeedy)
    local dx = targetX - m_x
    local dy = targetY - m_y
     
    local newX = m_x
    local newY = m_y

    if math.abs(dx) > math.abs(moveSpeedx) then
        m_x = m_x + moveSpeedx
    else
        m_x = targetX
    end

    if math.abs(dy) > math.abs(moveSpeedy) then
        m_y = m_y + moveSpeedy
    else
        m_y = targetY
    end

    return m_x, m_y
end

function LuaTools:P2D_IsPointInRect(x, y, rect)
    if (x < rect.x1) then return false end
    if (x > rect.x2) then return false end
    if (y < rect.y1) then return false end
    if (y > rect.y2) then return false end
    return true
end

function LuaTools:P2D_IsPointInRectCoord(x, y, x1, y1, x2, y2)
    if (x < x1) then return false end
    if (x > x2) then return false end
    if (y < y1) then return false end
    if (y > y2) then return false end
    return true
end
--rect = {x1, y1, x2, y2}
function LuaTools:P2D_IsRectCrossing(rect1, rect2)
    if rect1.x1 > rect2.x2
        or rect1.x2 < rect2.x1 
        or rect1.y1 > rect2.y2
        or rect1.y2 < rect2.y1
    then
         return false
    end
        
    return true;
end

function LuaTools:GetOneUidInGame()
    local uid = self.uidNumber
    self.uidNumber = self.uidNumber + 1
    return uid
end

function  LuaTools:PairsByKeys(t)  
    local a = {}  
    for n in pairs(t) do  
        a[#a+1] = n  
    end  
    table.sort(a)  
    local i = 0  
    return function()  
        i = i + 1  
        return a[i], t[a[i]]  
    end  
end

-------------------------line func-----------------
function LuaTools:Math_GetTwoPointDisTance(x1, y1, x2, y2)
    local deltX = math.abs(x1 - x2)
    local delty = math.abs(y1 - y2)
    return math.sqrt(deltX * deltX + delty * delty)
end

--from internet
--  已知两点的坐标(x1, y1); (x2, y2) 
--  另外一个点的坐标是(x0, y0); 
--  求(x0, y0)到经过(x1, y1); (x2, y2)直线的距离。
--  直线方程中 
--  A = y2 - y1,
--  B = x1- x2,
--  C = x2 * y1 - x1 * y2;
--  点的直线的距离公式为: 
--  double d = (fabs((y2 - y1) * x0 +(x1 - x2) * y0 + ((x2 * y1) -(x1 * y2)))) / (sqrt(pow(y2 - y1, 2) + pow(x1 - x2, 2)));
function LuaTools:Math_GetDistanceBetweenPointAndLine(pointX, pointY, 
                                                        linePointX1, linePointY1, 
                                                        linePointX2, linePointY2)
    
    local distance = (math.abs((linePointY2 - linePointY1) * pointX + (linePointX1 - linePointX2) * pointY + ((linePointX2 * linePointY1) - (linePointX1 * linePointY2)))) 
                    / (math.sqrt((linePointY2 - linePointY1) ^ 2 + (linePointX1 - linePointX2) ^ 2))
    return distance
end


-------------------angle------------------------------
function LuaTools:Math_GetAngleReal(x1, y1, x2, y2)
    local Dx = x1 - x2
    local Dy = y1 - y2
    return math.atan(Dy/Dx)
end

function LuaTools:Math_GetAngle(x1, y1, x2, y2)
    local radian
    if y2 == y1 then
        if x1 > x2 then 
            radian = math.pi
        else
            radian = 0
        end
    elseif x1 == x2 then
        if y1 > y2 then
            radian = -math.pi * 0.5
        elseif y2 > y1 then 
            radian = math.pi * 0.5
        else
            radian = 0
        end
    else
        radian = math.atan((y2 - y1) / (x2 - x1)) 

        --in the second quadrant
        if y2 > y1 and x2 < x1 then
            radian = math.pi + radian
        end

        --in the third quadrant
        if x2 < x1 and y2 < y1 then
            radian = radian + math.pi
        end

        --in the forth quadrant
        if y2 < y1 and x2 > x1 then 
            radian = math.pi * 2 + radian
        end
    end
    return radian
end

function LuaTools:Math_GetAngleRain(x1, y1, x2, y2, radianOld)
    local radian
    if y2 == y1 then
        if x1 > x2 then 
            radian = math.pi
        else
            radian = 0
        end
    elseif x1 == x2 then
        if y1 > y2 then
            radian = -math.pi * 0.5
        elseif y2 > y1 then 
            radian = math.pi * 0.5
        else
            radian = 0
        end
    else
        radian = radianOld 

        --in the second quadrant
        if y2 > y1 and x2 < x1 then
            radian = math.pi + radian
        end

        --in the third quadrant
        if x2 < x1 and y2 < y1 then
            radian = radian + math.pi
        end

        --in the forth quadrant
        if y2 < y1 and x2 > x1 then 
            radian = math.pi * 2 + radian
        end
    end
    return radian
end
function LuaTools:Deg2Rad(deg)
    return deg * 3.14159265359/180
end

function LuaTools:Rad2Deg(rad)
    return rad * 180/3.14159265359
end
----------------------rect func-------------------------
function LuaTools:IsTouchInRect(x, y, rect)
    -- print("can we run here!!!move"..x..","..rect.x..","..rect.w)
    if x < rect.x or y < rect.y then return false end
    if y > (rect.y + rect.h) then return false end
    if x > (rect.x + rect.w) then return false end
    return true
end

function LuaTools:IsRectCollision(rect1, rect2)
    if math.abs(rect1.lx) > math.abs(rect2.rx) then return false end
    if math.abs(rect1.rx) < math.abs(rect2.lx) then return false end
    if math.abs(rect1.ly) > math.abs(rect2.ry) then return false end
    if math.abs(rect1.ry) < math.abs(rect2.ly) then return false end
    return true
end

function LuaTools:IsMailAddress(s)
    local prefix = string.find(s, '@')
    local suffix = string.find(string.reverse(s), '%.')

    if prefix and suffix then
        if prefix ~= 1 and suffix ~= 1 and (prefix+suffix) < #s then
            return true
        end
    end

    return false
end

function  LuaTools:PairsByKeys(t)  
    local a = {}  
    for n in pairs(t) do  
        a[#a+1] = n  
    end  
    table.sort(a)  
    local i = 0  
    return function()  
        i = i + 1  
        return a[i], t[a[i]]  
    end  
end

----------------------- number funcs ------------------------
function LuaTools:FormatNumber(number)
    number = tonumber(number)
    local units = {GameConfig._B, GameConfig._M, GameConfig._K, ""}
    local factor = {1000 * 1000 * 1000, 
                    1000 * 1000, 
                    1000, 
                    1}
    local phase = { 1000 * 1000 * 1000, 
                    1000 * 1000, 
                    1000, 
                    0}

    local resultString = "";
    local origin = tonumber(number)
    local sign = 1
    if origin < 0 then
        sign = -1
        origin = 0 - origin
    end
    if origin == 0 then
        resultString = "0";
    else
        local phaseSize = self:GetTableSize(phase)
        for i = 1, phaseSize do
            if origin >= phase[i] then
                local theValue = math.floor(origin / factor[i] * 10) / 10;
                if theValue == origin then 
                    return origin 
                end
                resultString = theValue .. units[i];
                break
            end
        end
    end
    if sign == 1 then
        return resultString;
    else
        return "-" .. resultString;
    end
end
function LuaTools:FormatResNumber(number)
    if number >= 10*1000 then
        return LuaTools:FormatNumber(number)
    else
        return number
    end
end
function LuaTools:NewFormatNumber(number,max)
    if number > max then
        return LuaTools:FormatNumber(number)
    else
        return number
    end
end


function LuaTools:GetSignedNumber(origin)
    local number = tonumber(origin)
    local result = ""
    if number >= 0 then
        result = "+" .. number
    else
        result = number
    end

    return result
end

function LuaTools:ChangeTextColor(sourceStr, color)
    local color = color or "ffffff"
    local newStr = "<color=#" .. color .. ">" .. sourceStr .. "</color>"
    return newStr
end

function LuaTools:RemoveSpaceInString(str)
    local rslt = string.gsub(str, " ", "")
    return rslt
end

function LuaTools:RemoveCharInString(str, targetChar, rep)
    local rslt = string.gsub(str, targetChar, rep)
    return rslt
end

function LuaTools:ShuffleTable(array)
    local result = {}
    while self:GetTableSize(array) > 0 do
        local tableSize = self:GetTableSize(array)
        local index = math.random(1, tableSize)
        local ele = table.remove(array, index)
        table.insert(result, ele)
    end

    return result
end

function LuaTools:FormatString(format, ...)
    local result, r1 = pcall(string.format, format, ...)

    if result then
        return r1
    else
        if GameNetwork:IsCurrentServerInDebugMode() then
            return "bad string"
        else
            return "......"
        end
    end
end

function LuaTools:FileExists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
end

function LuaTools:DeleteFile(path)
    return os.remove(path)
end

function LuaTools:LimitValue(value,limit)
    if math.abs(value) > math.abs(limit) then
       return (value > 0 and 1 or -1) * math.abs(limit)
    else
        return value
    end
end

function LuaTools:utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                ------ debug---- 所有宽度大于1的字符都宽度都处理成2
                if i> 1 then
                    cnt = cnt + 1
                end
                ------ debug end--------
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function LuaTools:ConcatStringByTable(sep, ...)
    local strArray = {}
    for i, v in ipairs{...} do
        if v ~= "" then
            table.insert(strArray, v)
        end
    end

    if #strArray <= 1 then
        return tostring(strArray[1])
    end

    return table.concat(strArray, sep)
end

function LuaTools:CheckFunctionExecTime(func, desc, timeThreshold, no_condition)
    local time1 = GameTimeManager:GetDeviceTimeInMilliSec()
    func()
    local time2 = GameTimeManager:GetDeviceTimeInMilliSec()
    local timeLength = time2 - time1
    if no_condition or timeLength > (timeThreshold or 20) then
        print(desc, timeLength)
    end

    return timeLength
end

function LuaTools:GetItemColorName(name, rarity, isDark)
    local isDark = nil == isDark and true or isDark;
    local rarity = tonumber(rarity);
    return LuaTools:ChangeTextColor(name, isDark and LuaTools.COLOR_TITLE_RARITY_DARK[rarity] or LuaTools.COLOR_TITLE_RARITY[rarity])
end

function LuaTools:Clamp(num, min, max)
    return math.max(math.min(num, max), min);
end
