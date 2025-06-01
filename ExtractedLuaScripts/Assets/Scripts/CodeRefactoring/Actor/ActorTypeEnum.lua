--[[
    author: gxy
    time:2023-08-07 11:37:07
    description: 演员类型枚举,使用时将ActorTypeEnum 赋值给一个本地变量后使用,防止重复查找lua的全局表
]]

local ActorTypeEnum = {
    InstanceWorker = 1, --副本工人
    Bus = 2,    --公交车
    Employees = 3,  --公司员工
}

return ActorTypeEnum