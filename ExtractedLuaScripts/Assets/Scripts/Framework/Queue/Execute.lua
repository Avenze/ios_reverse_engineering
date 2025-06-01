local Execute = {
}

local main = coroutine.running();

-- 所有的队列
local queues = {};
-- 所有的子线程
local threads = {};
-- 所有的回调
local cbs = {};
-- 所有的返回值
local rets = {};

local table_insert = table.insert;
local table_remove = table.remove;

function Execute:Async(queue, cb)
    table_insert(queues, queue);
    cbs[queue] = cb;
end

function Execute:IsMain()
    return main == coroutine.running();
end

function Execute:Yield()
    if not self:IsMain() then
        coroutine.yield()
    end
end

local function GetThread(handler)
    local thread = threads[handler];
    if not thread then
        thread = coroutine.create(handler);
        threads[handler] = thread;
    end
    return thread;
end

local function ClearThread(handler)
    threads[handler] = nil;
end

function Execute:Update()
    local queue = queues[1];
    if not queue then return end;

    local handler = queue[1];
    if handler then
        local status, value = coroutine.resume(GetThread(handler));
        if status then
            rets[queue] = value;
        else
            table_remove(queue, 1);
            ClearThread(handler);
        end
    else
        -- 没有handler，这个队列执行完成了
        table_remove(queues, 1);
        local cb = cbs[queue];
        local ret = rets[queue];
        cbs[queue] = nil;
        rets[queue] = nil;
        if cb then cb() end
    end
end

return Execute
