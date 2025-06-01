local proto = {}

local types = [[

# 用户行为
.player_action {
    uid                 0 : integer


]]

local c2s = [[
    heartbeat 3 {
        request {
        }
        response {
            success 0 : boolean
        }
    }
]]

local s2c = [[
    heartbeat 1 {
    }
    
    skynet_push 302 {
        request {
            tguide              0 : string
        }
    }
]]

proto.c2s = types .. c2s
proto.s2c = types .. s2c

return proto
