local CommonUtils = GameTableDefine.CommonUtils
local Color = CS.UnityEngine.Color

function CommonUtils:FormatLevelString(level)
    return GameTextLoader:ReadText("LC_WORD_WILD_LV") .. level
end

function CommonUtils:GetMultiplicationSign()
    return "x"
end

function CommonUtils:SetTextStrikeThrough(text, lineColor)
    if lineColor then
        return "<s color=" .. lineColor .. ">" .. text .. "<s>"
    else
        return "<s>" .. text .. "<s>"
    end
end

function CommonUtils:SetTextUnderline(text, lineColor)
    if lineColor then
        return "<u color=" .. lineColor .. ">" .. text .. "<u>"
    else
        return "<u>" .. text .. "<u>"
    end
end

function CommonUtils:FormatCoords(x, y)
    local coordsString = GameTextLoader:ReadText("LC_WORD_XY")
    coordsString = LuaTools:FormatString(coordsString, x, y)
    return coordsString
end
