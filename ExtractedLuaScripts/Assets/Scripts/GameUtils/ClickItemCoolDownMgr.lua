--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-02-28 09:57:39
    desc:用于管理点击控件的冷却，用于UI控件上
]]

ClickItemCoolDownMgr = 
{
    cdItems = {},
    TIME_OFFSET = 300
}

function ClickItemCoolDownMgr:CheckItemIsCoolDown(uiClassName, buttonObj)
    -- if self.cdItems[uiClassName] then
    --     for _, v in ipairs(self.cdItems[uiClassName]) do
    --         if buttonObj == v[1] then
    --             return true
    --         end
    --     end
    -- end
    return false
end

function ClickItemCoolDownMgr:AddItemCoolDown(uiClassName, buttonObj)
    -- if self.cdItems[uiClassName] == nil then
    --     self.cdItems[uiClassName] = {}
    --     local newItem = {buttonObj, GameTimeManager:GetDeviceTimeInMilliSec()}
    -- else
    --     local isIn = false
    --     for _, v in ipairs(self.cdItems[uiClassName]) do
    --         if v[1] == buttonObj then
    --             isIn = true
    --             break
    --         end
    --     end
    --     if not isIn then
    --         local newItem = {buttonObj, GameTimeManager:GetDeviceTimeInMilliSec()}
    --         table.insert(self.cdItems[uiClassName], newItem)
    --     end
    -- end

    -- if Tools:GetTableSize(self.cdItems) > 0 and self.processTimeHandler == nil then
    --     self.processTimeHandler = GameTimer:CreateNewMilliSecTimer(100, handler(ClickItemCoolDownMgr, ClickItemCoolDownMgr.ProcessCoolDown), true, false)
    -- end
end

function ClickItemCoolDownMgr:OnExit()
    if self.processTimeHandler then
        GameTimer:StopTimer(self.processTimeHandler)
        self.processTimeHandler = nil
    end
end

function ClickItemCoolDownMgr:ProcessCoolDown()
    -- print("ClickItemCoolDownMgr:ProcessCoolDown"..Tools:GetTableSize(self.cdItems))
    -- for _, value in pairs(self.cdItems) do
    --     if Tools:GetTableSize(value) > 0 then
    --         for index, v in ipairs(value) do 
    --             if GameTimeManager:GetDeviceTimeInMilliSec() - v[2] >= self.TIME_OFFSET then
    --                 value[index] = nil
    --             end
    --         end
    --     end
    -- end
end