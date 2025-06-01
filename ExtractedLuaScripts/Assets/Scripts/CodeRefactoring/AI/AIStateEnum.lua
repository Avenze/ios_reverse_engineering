--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author: gxy
    time:2023-8-7 11:58:41
    description: AI状态枚举,AIStateEnum 赋值给一个本地变量后使用,防止重复查找lua的全局表
]]
local AIStateEnum = {
    ----------------副本相关----------------
    Instance_Idle = 1,
    Instance_Init = 2,
    Instance_Work = 3,
    Instance_Eat = 4,
    Instance_Sleep = 5,
    Instance_WorkSet = 6,
    Instance_RunToWorkSet = 7,
    Instance_RunToEatLine = 8,
    Instance_RunToSleepLine = 9,
    Instance_WalkToWorkPos = 10,
    Instance_WalkToEat = 11,
    Instance_WalkToSleep = 12,
    Instance_LineUp = 13,
    ----------------办公室相关----------------
    Offic_Idle = 1001,
} 
return AIStateEnum