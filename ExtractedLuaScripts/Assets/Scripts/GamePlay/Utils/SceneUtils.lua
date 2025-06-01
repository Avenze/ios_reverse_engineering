local UnityHelper = CS.Common.Utils.UnityHelper;

local SceneUtils = {}

function SceneUtils:FindRootGameObject(scene, name)
    if not scene then return end
    local ret = nil;
    local arr = scene:GetRootGameObjects()
    for i = 0, arr.Length - 1 do
        ret = arr[i];
        local t_name = GameTools:SplitEx(name, "/");
        if t_name[1] == ret.name then
            break
        end
    end
    return ret and ret.gameObject or nil;
end

function SceneUtils:FindGameObject(scene, name)
    if not scene then return end
    local ret = nil;
    local arr = scene:GetRootGameObjects()
    for i = 0, arr.Length - 1 do
        ret = arr[i];

        local t_name = GameTools:SplitEx(name, "/");
        if t_name[1] == ret.name then
            if #t_name == 1 then
                break
            end
            table.remove(t_name, 1);
        end  

        name = table.concat(t_name, "/");
        ret = UnityHelper.FindTheChild(ret, name);
        if ret and t_name[#t_name] == ret.name then break end
    end
    return ret and ret.gameObject or nil;
end

function SceneUtils:FindComponent(scene, name, type)
    if not scene then return end
    local ret = nil;
    local arr = scene:GetRootGameObjects()
    for i = 0, arr.Length - 1 do
        ret = arr[i];
        if name == ret.name then
            local c = ret:GetComponent(type);
            if c then 
                ret = c;
                break;
            end
        end
        
        ret = UnityHelper.GetTheChildComponent(arr[i], name, type);
        if ret then break end
    end
    return ret;
end

return SceneUtils