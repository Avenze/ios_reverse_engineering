---大数字库
BigNumber = {}
local precision = 9

-- 设置全局精度和舍入模式
function BigNumber:SetPrecision(int)
    precision = int or 9  -- 设置精度为9位十进制数字
end

---将数字转为科学计数法表示
function BigNumber:ToScientificNotation(input)
    local base, exponent = string.match(input, "([%-]?[%d%.]+)[eE]([%+%-]?%d+)")
    if base and exponent then
        return tonumber(base), tonumber(exponent)
    else
        local num = tonumber(input)
        if not num then
            error("Invalid number format")
        end

        local isNegative = num < 0
        num = math.abs(num)

        if num == 0 then
            return 0, 0
        end

        local exponent = math.log10(num)
        local base = num / (10 ^ exponent)

        -- 处理负号
        if isNegative then
            base = -base
        end

        return base, exponent
    end
end


function math.log10(num)
    if num <= 0 then
        error("log10 is undefined for non-positive values")
    end

    local exponent = 0
    while num >= 10 do
        num = num / 10
        exponent = exponent + 1
    end
    while num < 1 do
        num = num * 10
        exponent = exponent - 1
    end
    return exponent
end

--- 加法
function BigNumber:Add(a, b)
    local base1, exponent1 = BigNumber:ToScientificNotation(a)
    local base2, exponent2 = BigNumber:ToScientificNotation(b)

    -- 对齐指数
    if exponent1 > exponent2 then
        base2 = base2 / (10 ^ (exponent1 - exponent2))
    elseif exponent2 > exponent1 then
        base1 = base1 / (10 ^ (exponent2 - exponent1))
        exponent1 = exponent2
    end

    local resultBase = base1 + base2
    local resultExponent = exponent1

    -- 处理负数的情况
    local isNegative = false
    if resultBase < 0 then
        resultBase = -resultBase
        isNegative = true
    end

    -- 规范化结果
    if resultBase >= 10 then
        while resultBase >= 10 do
            resultBase = resultBase / 10
            resultExponent = resultExponent + 1
        end
    elseif resultBase < 1 and resultBase ~= 0 then
        while resultBase < 1 do
            resultBase = resultBase * 10
            resultExponent = resultExponent - 1
        end
    end

    local result = string.format("%.15f", resultBase) .. "E" .. string.format("%+d", resultExponent)

    if isNegative then
        result = "-" .. result
    end

    return result
end


--- 减法
function BigNumber:Subtract(a, b)
    local base1, exponent1 = BigNumber:ToScientificNotation(a)
    local base2, exponent2 = BigNumber:ToScientificNotation(b)

    -- 对齐指数
    if exponent1 > exponent2 then
        base2 = base2 / (10 ^ (exponent1 - exponent2))
    elseif exponent2 > exponent1 then
        base1 = base1 / (10 ^ (exponent2 - exponent1))
        exponent1 = exponent2
    end

    local resultBase = base1 - base2
    local resultExponent = exponent1

    -- 处理负数的情况
    local isNegative = false
    if resultBase < 0 then
        resultBase = -resultBase
        isNegative = true
    end

    -- 规范化结果
    if resultBase >= 10 then
        while resultBase >= 10 do
            resultBase = resultBase / 10
            resultExponent = resultExponent + 1
        end
    elseif resultBase < 1 and resultBase ~= 0 then
        while resultBase < 1 do
            resultBase = resultBase * 10
            resultExponent = resultExponent - 1
        end
    end

    local result = string.format("%.15f", resultBase) .. "E" .. string.format("%+d", resultExponent)

    if isNegative then
        result = "-" .. result
    end

    return result
end


--- 乘法
function BigNumber:Multiply(a, b)
    local base1, exponent1 = BigNumber:ToScientificNotation(a)
    local base2, exponent2 = BigNumber:ToScientificNotation(b)

    local resultBase = base1 * base2
    local resultExponent = exponent1 + exponent2

    if resultBase >= 10 then
        while resultBase >= 10 do
            resultBase = resultBase / 10
            resultExponent = resultExponent + 1
        end
    elseif resultBase < 1 and resultBase ~= 0 then
        while resultBase < 1 do
            resultBase = resultBase * 10
            resultExponent = resultExponent - 1
        end
    end

    -- 返回以科学计数法格式的结果
    return string.format("%.15f", resultBase) .. "E" .. string.format("%+d", resultExponent)
end


--- 除法
function BigNumber:Divide(a, b)
    local base1, exponent1 = BigNumber:ToScientificNotation(a)
    local base2, exponent2 = BigNumber:ToScientificNotation(b)

    -- 对齐指数
    -- if exponent1 > exponent2 then
    --     base2 = base2 / (10 ^ (exponent1 - exponent2))
    -- elseif exponent2 > exponent1 then
    --     base1 = base1 / (10 ^ (exponent2 - exponent1))
    --     exponent1 = exponent2
    -- end

    local resultBase = base1 / base2
    local resultExponent = exponent1 - exponent2

    -- 处理负数的情况
    local isNegative = false
    if resultBase < 0 then
        resultBase = -resultBase
        isNegative = true
    end

    -- 规范化结果
    if resultBase >= 10 then
        while resultBase >= 10 do
            resultBase = resultBase / 10
            resultExponent = resultExponent + 1
        end
    elseif resultBase < 1 and resultBase ~= 0 then
        while resultBase < 1 do
            resultBase = resultBase * 10
            resultExponent = resultExponent - 1
        end
    end

    local result = string.format("%.15f", resultBase) .. "E" .. string.format("%+d", resultExponent)

    if isNegative then
        result = "-" .. result
    end

    return result
end

---比较两个参数的大小, 返回 a > b 的结果
function BigNumber:CompareBig(a, b)
    local base1, exponent1 = BigNumber:ToScientificNotation(a)
    local base2, exponent2 = BigNumber:ToScientificNotation(b)

    -- 处理 0 的情况
    if base1 == 0 and base2 == 0 then
        return false
    elseif base1 == 0 then
        return base2 < 0
    elseif base2 == 0 then
        return base1 > 0
    end

    -- 如果基数是负数，改变比较逻辑
    local isNegative1 = base1 < 0
    local isNegative2 = base2 < 0

    -- 正负数直接比较
    if isNegative1 and not isNegative2 then
        return false
    elseif not isNegative1 and isNegative2 then
        return true
    end

    -- 同为负数或同为正数
    if exponent1 > exponent2 then
        return not isNegative1  -- 如果是负数，则更大的指数反而是较小的值
    elseif exponent1 < exponent2 then
        return isNegative1  -- 如果是负数，则较小的指数反而是较大的值
    else
        if isNegative1 then
            return base1 > base2  -- 同为负数时，基数较大的反而是较小的值
        else
            return base1 > base2  -- 同为正数时，基数较大的就是较大的值
        end
    end
end

---比较两个参数的大小, 返回 a == b 的结果
function BigNumber:CompareEqual(a, b)
    local base1, exponent1 = BigNumber:ToScientificNotation(a)
    local base2, exponent2 = BigNumber:ToScientificNotation(b)

    -- 首先比较指数，如果指数不同，数字不相等
    if exponent1 ~= exponent2 then
        return false
    end

    -- 如果指数相同，比较基数
    return base1 == base2
end


local units = { 
    "", "K", "M", "B", "T",
    "aa", "bb", "cc", "dd", "ee", "ff", "gg", "hh", "ii", "jj", "kk", "ll", "mm", "nn",
    "AA", "BB", "CC", "DD", "EE", "FF", "GG", "HH", "II", "JJ", "KK", "LL", "MM", "NN" 
}

---大数字字符串格式化
--- 各计量单位之间差距为一个千分符，顺序如下
---  1. K, M, B, T
---  2. aa, bb, cc, dd, ee, ff, gg, hh, ii, jj, kk, ll, mm, nn
---  3. AA,BB,CC,DD,EE,FF,GG,HH,II,JJ,KK,LL,MM,NN
---
---最多保留两位小数，例：12.34aa
function BigNumber:FormatBigNumber(number)
    number = tonumber(number)
    if number < 1000 then
        return tostring(math.floor(number))
    end

    local exponent = 0
    while number >= 999.999 and exponent < #units - 1 do
        number = number / 1000
        exponent = exponent + 1
    end

    -- 去掉小数部分无效的0
    local formattedNumber = string.format("%.2f", number):gsub("0+$", ""):gsub("%.$", "")

    return formattedNumber .. units[exponent + 1]
end

function BigNumber:FormatBigNumberSmall(number)
    number = tonumber(number)

    local exponent = 0
    while number >= 999.999 and exponent < #units - 1 do
        number = number / 1000
        exponent = exponent + 1
    end

    -- 去掉小数部分无效的0
    local formattedNumber = string.format("%.2f", number):gsub("0+$", ""):gsub("%.$", "")

    return formattedNumber .. units[exponent + 1]
end