Tools = {
    COLOR_WHITE = "FFFFFF",
    COLOR_RED = "FF0000",
    COLOR_GREEN = "00FF00",
    COLOR_YELLOW = "FFFF00",
    COLOR_BULE = "0000FF",
}
local GameObject = CS.UnityEngine.GameObject
local UnityHelper = CS.Common.Utils.UnityHelper
local UnityDebug = CS.UnityEngine.Debug

function Tools:GetCheat(real, cheat)
    return self.isCheatMode and cheat or real
end

function Tools:SwitchCheatMode()
    if GameDeviceManager:IsDebugVersion() then
        self.isCheatMode = not self.isCheatMode
    else
        self.isCheatMode = nil
    end
    return self.isCheatMode
end

---获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
---@param prefab UnityEngine.GameObject
---@param num number
---@param clearOther boolean
---@param cb function
---最后传cb方法的参数
function Tools:SetTempGo(prefab ,num ,clearOther ,cb ,...)
    local prefab = prefab
    prefab:SetActive(false)
    local parent = prefab.transform.parent.gameObject
    
    local clearList = {}
    if clearOther then
        for k,v in pairs(parent.transform) do
            if v.name ~= prefab.name then
                table.insert(clearList, v)
            end
        end
    end
    for i = #clearList, 1, -1 do 
        local tran = clearList[i]
        GameObject.Destroy(tran.gameObject)
    end

    for i = 1,num do
        local go
        go = GameObject.Instantiate(prefab, parent.transform)
        go:SetActive(true)
        go.name = "temp" .. i
        if cb then
            cb(go, i, ...)            
        end
    end          
end

function Tools:GetTableSize(t)
    local r = 0
    if t == nil then return r end
    for _, _ in pairs(t) do r = r + 1 end
    return r
end

function Tools:SplitString(str, sep, isNumber)
    assert(str and sep and #sep > 0)
    if #str == 0 then return {} end
    local reg = string.format('[%s]', sep)
    local r = {}
    local _begin = 1
    while _begin <= #str do
        local _end = string.find(str, reg, _begin) or #str + 1
        local v = string.sub(str, _begin, _end - 1)
        if isNumber and tonumber(v) then v = tonumber(v) end
        table.insert(r, v)
        _begin = _end + 1
    end
    if string.match(string.sub(str, #str, #str), reg) then table.insert(r, '') end
    return r
end

function Tools:CopyTable(st)
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

--- 洗牌算法,将表乱序并返回结果
function Tools:ShuffleArray(array)
    local n = #array
    for i = n, 2, -1 do
        local j = math.random(i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

function Tools:ChangeTextColor(sourceStr, color)
    local color = color or "ffffff"
    local newStr = "<color=#" .. color .. ">" .. sourceStr .. "</color>"
    return newStr
end

function Tools:HEX2RGB(hex)
	-- 每次截取两个字符 转换成十进制
	local colorlist = {}
	local index = 1
	while index < string.len(hex) do
		local tempstr = string.sub(hex, index, index + 1)
		table.insert(colorlist, tonumber(tempstr, 16)/255)
		index = index + 2
    end
	return colorlist[1] or 0, colorlist[2] or 0, colorlist[3] or 0, 1
end

function Tools:RemoveSpaceInString(str)
    local rslt = string.gsub(str, " ", "")
    return rslt
end

function Tools:SeparateNumberWithComma(number, isDecimal)
    if not number then
        error(debug.traceback("invalid params"))
    end
    if not isDecimal then
        number = math.floor(tonumber(number))
    end
    if number < 1000 then
        return number
    end
    local hasMinusSign = false
    if number < 0 then
        hasMinusSign = true
    end
    local numberString = tostring(math.abs(number))
    local stringLength = string.len(numberString)
    local lackedLength = 0
    if stringLength % 3 ~= 0 then
        lackedLength = 3 - stringLength % 3
    end
    local resultString = ""
    for i = 1, lackedLength do
        numberString = " " .. numberString
        stringLength = stringLength + 1
    end

    for i = 1, stringLength / 3 do
        local currentIndex = (i - 1) * 3 + 1
        local subString = string.sub(numberString, currentIndex, currentIndex + 2)
        if resultString == "" then
            if i == 0 then
                resultString = resultString .. tonumber(subString)
            else
                resultString = resultString .. (subString)
            end
        else
            if i == 0 then
                resultString = resultString .. "," .. tonumber(subString)
            else
                resultString = resultString .. "," .. (subString)
            end
        end
    end

    resultString = self:RemoveSpaceInString(resultString)

    if hasMinusSign then
        resultString = "-" .. resultString
    end
    return resultString
end

--[[
    @desc:返回千分符号为空格，现在针对卢布的显示上
    author:{author}
    time:2023-11-03 09:49:19
    --@number: 
    @return:
]]
function Tools:SeparateNumberWithSpace(number)
    if not number then
        error(debug.traceback("invalid params"))
    end
    if number < 1000 then
        return number
    end
    number = math.floor(tonumber(number))
    local hasMinusSign = false
    if number < 0 then
        hasMinusSign = true
    end
    local numberString = tostring(math.abs(number))
    local stringLength = string.len(numberString)
    local lackedLength = 0
    if stringLength % 3 ~= 0 then
        lackedLength = 3 - stringLength % 3
    end
    local resultString = ""
    for i = 1, lackedLength do
        numberString = " " .. numberString
        stringLength = stringLength + 1
    end

    for i = 1, stringLength / 3 do
        local currentIndex = (i - 1) * 3 + 1
        local subString = string.sub(numberString, currentIndex, currentIndex + 2)
        if resultString == "" then
            if i == 0 then
                resultString = resultString .. tonumber(subString)
            else
                resultString = resultString .. (subString)
            end
        else
            if i == 0 then
                resultString = resultString .. " " .. tonumber(subString)
            else
                resultString = resultString .. " " .. (subString)
            end
        end
    end

    if hasMinusSign then
        resultString = "-" .. resultString
    end
    return resultString
end

function Tools:SplitEx(s, delim)
    local split = {};
    local pattern = "[^".. delim .."]+";
    string.gsub(s, pattern, function(v) table.insert(split, v) end);
    return split;
end

function string:split(str, sep, is_force_number)--Tool复制来的
    assert(str and sep and #sep > 0)
    if #str == 0 then return {} end
    local reg = string.format('[%s]', sep)
    local r = {}
    local _begin = 1
    while _begin <= #str do
        local _end = string.find(str, reg, _begin) or #str + 1
        local i_words = string.sub(str, _begin, _end - 1)
        if is_force_number then
            i_words = tonumber(i_words)
        end
        table.insert(r, i_words)
        _begin = _end + 1
    end
    if string.match(string.sub(str, #str, #str), reg) then table.insert(r, '') end
    return r
end

function Tools:TrimEx(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function Tools:DumpTable(value, desc, nesting, bShowStack)
	if not GameConfig:IsDebugMode() then return end
	-- if true then return end
	
    if type(nesting) ~= "number" then
        nesting = 15;
	end
	
	local function dump_value_(v)
		if type(v) == "string" then
			v = "\"" .. v .. "\""
		end
		return tostring(v)
	end

    local lookupTable = {}
    local result = {}

	local traceback = self:SplitEx(debug.traceback("", 3), "\n")
	local resultStr;
    if bShowStack then
        resultStr = "- stack info: ";
        for i=2, #traceback, 1 do
            resultStr = resultStr .. "\n- " .. traceback[i];
        end
    elseif traceback and #traceback > 0 then
		resultStr = "- dump from: " .. self:TrimEx(traceback[2]);
	else 
		resultStr = "- GameConfig.enableDbgTrace is false, can not find dump from";
    end
    
    local function dump_(value, desc, indent, nest, keylen)
        desc = desc or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desc)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s[%s]%s = %s,", indent, dump_value_(desc), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s[%s]%s = *REF*", indent, dump_value_(desc), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s[%s] = *MAX NESTING*", indent, dump_value_(desc))
            else
                result[#result +1 ] = string.format("%s[%s] = {", indent, dump_value_(desc))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s},", indent)
            end
        end
    end
    dump_(value, desc, "- ", 1)

	local result = table.concat(result, "\n");
	if luaIdePrintWarn then luaIdePrintWarn(resultStr.. "\n" .. result) else print(resultStr.. "\n" .. result) end
end


function Tools:IsTableEmpty(t)
    return not next(t)
end


-- 判断utf8字符byte长度
-- 0xxxxxxx - 1 byte
-- 110yxxxx - 192, 2 byte
-- 1110yyyy - 225, 3 byte
-- 11110zzz - 240, 4 byte
function Tools:Chsize(char)
    if not char then
        print("not char")
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

-- 计算utf8字符串字符数, 各种字符都按一个字符计算
-- 例如utf8len("1你好") => 3
function Tools:Utf8len(str)
    local len = 0
    local currentIndex = 1
    while currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + self:Chsize(char)
        len = len +1
    end
    return len
end

-- 截取utf8 字符串
-- str:            要截取的字符串
-- startChar:    开始字符下标,从1开始
-- numChars:    要截取的字符长度
function Tools:Utf8sub(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + self:Chsize(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex

    while numChars > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + self:Chsize(char)
        numChars = numChars -1
    end
    return str:sub(startIndex, currentIndex - 1)
end

function Tools:MergeTable(dest, src)
    for k, v in pairs(src) do
        table.insert(dest, v)
    end
    return dest
end

--比较低效，在特殊场合使用，不同语言需要替换的字符顺序不同。
function Tools:FormatString(src, ...)
    if string.find(src,"{0}") and UnityHelper.StringFormat then
        return UnityHelper.StringFormat(src, ...)
    end
    return string.format(src, ...)
end

function Tools:FindObjectInAllScenes(type)
    local SceneManager = CS.UnityEngine.SceneManagement.SceneManager
    for i = 0, SceneManager.sceneCount - 1 do
        local scene = SceneManager.GetSceneAt(i)
        if scene.isLoaded then
            local childs = scene:GetRootGameObjects()
            for childIndex = 0, childs.Length - 1 do
                local curGO = childs[childIndex]
                local component = curGO:GetComponentInChildren(type, true)
                if component ~= nil then
                    printf("Found component: ", type, "in scene " .. scene.name)
                    return component
                end
            end
        end
    end

end

-- 判断是否为活跃用户, 默认判断两周内是否登陆过
function Tools:IsActiveUser(day)
    local userData = LocalDataManager:GetDataByKey("user_data")
    local lastSaveTime = userData.save_time or 0
    local now = GameTimeManager:GetCurrentServerTimeInMilliSec()
    local exitTime = (now - lastSaveTime) / 1000
    return exitTime < 86400 * (day or 14) * 1000
end


function table.RemoveValue(t,value)
    for i,v in ipairs(t) do
        if v == value then
            table.remove(t,i)
            return true
        end
    end
    return false
end

---获取一个随机的键值对
function table.GetRandomKeyValue(t)
    local count = Tools:GetTableSize(t)
    if count < 1 then
        return
    end
    local random = math.random(1, count)
    local i = 1
    local key, value
    while true do
        key, value = next(t, key)
        --print(key, value)
        i = i + 1
        if i > random then break end
    end
    return key, value
end

---将表打乱顺序
function table.Shuffle(t)
    return Tools:Shuffle(t)
end


---获取一个只读表
function GetReadOnlyTable(t)
    local meta = {
        __index = t,
        __newindex = function ()
            error("Cannot modify read-only table!")
        end
    }
    local newTable = {}
    setmetatable(newTable, meta)
    return newTable
end

--输出堆栈信息
function printf(...)
    if GameConfig:IsDebugMode() and GameConfig:IsEnableDebugTrace() then
        local arg = {...}
        local traceStr = debug.traceback()
        local startIndex,endIndex = string.find(traceStr,"printf")
        traceStr = string.sub(traceStr,endIndex+2)
        table.insert(arg,"\n traceback:"..traceStr)
        print(table.unpack(arg))
    end
end

--输出堆栈信息
function printError(...)
    if GameConfig:IsDebugMode() and GameConfig:IsEnableDebugTrace() then
        local arg = {...}
        local traceStr = debug.traceback()
        local startIndex,endIndex = string.find(traceStr,"printError")
        traceStr = string.sub(traceStr,endIndex+2)
        table.insert(arg,"\n traceback:"..traceStr)
        table.insert(arg,1,"LUA: Error ")
        local strResult = table.concat(arg)
        if GameDeviceManager:IsEditor() then
            local str = CS.LuaStackModify.AddPathToLuaLog(strResult)
            UnityDebug.LogError(str)
        else
            UnityDebug.LogError(strResult)
        end
    end
end

-- 定义一个 dump 函数，输出table中的内容
function dump(value, indent, try_tostring)
    -- 如果没有指定缩进，就默认为 2
    indent = indent or 2
    -- 如果没有指定是否尝试 tostring，就默认为 false
    try_tostring = try_tostring or false
    -- 定义一个字符串缓冲区，用于存储输出结果
    local buffer = {}
    -- 定义一个函数，用于递归地遍历 table
    local function inner_dump(value, level)
        -- 如果值是一个 table，就遍历它的键值对
        if type(value) == "table" then
            -- 如果尝试 tostring，就先尝试调用 value 的 __tostring 元方法
            if try_tostring then
                local mt = getmetatable(value)
                if mt and mt.__tostring then
                    local s = tostring(value)
                    -- 如果成功转换为字符串，就直接返回
                    if s then
                        return s
                    end
                end
            end
            -- 否则，就按照 table 的格式输出
            buffer[#buffer + 1] = "{\n"
            -- 计算下一层的缩进
            local next_indent = level + indent
            -- 遍历 table 的键值对
            for k, v in pairs(value) do
                -- 输出键，根据类型加上合适的符号
                buffer[#buffer + 1] = string.rep(" ", next_indent)
                if type(k) == "string" then
                    buffer[#buffer + 1] = string.format("%q", k)
                elseif type(k) == "number" then
                    buffer[#buffer + 1] = string.format("[%d]", k)
                else
                    inner_dump(k, next_indent)
                end
                buffer[#buffer + 1] = " = "
                -- 输出值，递归调用 inner_dump
                inner_dump(v, next_indent)
                buffer[#buffer + 1] = ",\n"
            end
            -- 输出结尾的大括号
            buffer[#buffer + 1] = string.rep(" ", level)
            buffer[#buffer + 1] = "}"
        else
            -- 如果值不是一个 table，就直接转换为字符串
            buffer[#buffer + 1] = tostring(value) or "<nil>"
        end
    end
    -- 调用 inner_dump，从 0 层开始
    inner_dump(value, 0)
    -- 返回拼接后的字符串
    return table.concat(buffer)
end

function Tools:FormatTime(sec)
    local d = sec // (24* 60 * 60)
    local h = sec % (24* 60 * 60) // (60* 60) + d * 24
    local m = sec % (60* 60) // 60
    local s = sec % 60
    
    if h < 10 then h = "0"..h end
    if m < 10 then m = "0"..m end
    if s < 10 then s = "0"..s end
    
    return string.format("%s:%s:%s",h,m,s)
end

function Tools:Calc(calcString, replaceTable)
    if replaceTable then
        for key, val in pairs(replaceTable) do
            calcString = string.gsub(calcString, key, val)
        end
    end

    local func, err = load("return function(t) return " .. calcString .. " end")
    if not err then
        return func()()
    end

    return nil
end

function Tools:Shuffle(t)
    local n = #t
    if n <= 0 then
        return t
    end
    local tab = {}
    local index = 1
    while n > 0 do
        local tmp = math.random(1, n)
        tab[index] = t[tmp]
        table.remove(t, tmp)
        index = index + 1
        n = #t
    end
    return tab
end

function Tools:CheckContain(e, t)
    if not t or #t == 0 then
        return false
    end

    for i, v in pairs(t) do
        if v == e then
            return true
        end
    end
    
    return false
end 