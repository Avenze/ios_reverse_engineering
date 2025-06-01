local OrderUI = GameTableDefine.OrderUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local FactoryMode = GameTableDefine.FactoryMode
local EventManager = require("Framework.Event.Manager")
local TimerMgr = GameTimeManager
function OrderUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.ORDER_UI, self.m_view, require("GamePlay.Factory.UI.OrderUIView"), self, self.CloseView)
    return self.m_view
end

function OrderUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.ORDER_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--获取订单存档
function OrderUI:GetOrderData()
    self.m_orderData = LocalDataManager:GetDataByKey("order")
    --if not self.m_orderData then
        --self.m_orderData = {}
    --end
    -- LocalDataManager:WriteToFile()
    return self.m_orderData
end

--对能创建的但是没的创建的进行创建
function  OrderUI:GenerateOrders()
    self.m_orderCfg = ConfigMgr.config_order
    local orderData = self:GetOrderData()
    for k,v in pairs(self.m_orderCfg) do
        if v.default == 1 and not orderData[tostring(v.id)] then
            self:GenerateOrder(v.id)
        end
    end
end

--根据订单的编号生成一个订单
function OrderUI:GenerateOrder(orderNum)
    self.m_orderCfg = ConfigMgr.config_order
    self.m_workShopCfg = ConfigMgr.config_workshop
    local h_list = WorkShopInfoUI:GetProductList()  
    local orderData = self:GetOrderData()
    local cfg = self.m_orderCfg[orderNum]
    if #h_list == 0 then
        return {}
    end
    local prohibitList = self:GetProductProhibit(orderNum)
    for k,v in pairs(prohibitList) do
        for i,o in pairs(h_list) do
            if o == v then
                h_list[i] = nil
            end
        end
    end
    local max = Tools:GetTableSize(h_list)
    local num = math.random(1, max)
    local index = 0
    local productsId
    for k,v in pairs(h_list) do
        index = index + 1     
        if index == num then               
            productsId = v
            break
        end
    end    
    local needNum = self:CalculateQantity(productsId)
    if not orderData[tostring(cfg.id)] then
        orderData[tostring(cfg.id)] = {} 
    end                                                    
    orderData[tostring(cfg.id)]["productsId"] = productsId
    orderData[tostring(cfg.id)]["num"] = needNum
    orderData[tostring(cfg.id)]["timePoint"] = TimerMgr:GetCurrentServerTime(true)      
    LocalDataManager:WriteToFile()
end

--计算获得许可证奖励的触发上限
function OrderUI:CalculateUpperLimit()
    self.m_orderData = self:GetOrderData()
    self.m_order_reward = ConfigMgr.config_global.order_reward[1]
    --总累加值,用于计算许可证发放            
    if not self.m_orderData["total"] then
        self.m_orderData["total"] = 0
    end
    local total = self.m_orderData["total"]
    local result
    for k,v in ipairs(self.m_order_reward) do        
        if v[2] - 1 >= total then
            result = v[1]
            return result                   
        end        
    end
    if result == nil then
        result = self.m_order_reward[ Tools:GetTableSize(self.m_order_reward)][1]
    end
    return result 
end
--订单是否能完成
function OrderUI:AnyOrderCanFinish()
    local data = self:GetOrderData()
    for k, v in pairs(data or {}) do
        if type(v) == "table" and self:CheckOrderFinish(v) then
            return true
        end
    end
    return false
end

function OrderUI:CheckOrderFinish(data)
    --local productsData = WorkShopInfoUI:GetProductsData()
    if data.timePoint <= TimerMgr:GetCurrentServerTime(true) then
        --仓库有的数量
        local storehouseNum = WorkShopInfoUI:GetProductNum(data.productsId)
        --local storehouseNum = productsData[tostring(data.productsId)]
        --if not storehouseNum then
        --    storehouseNum = 0
        --end
        local canFinish = storehouseNum >= data.num
        return canFinish
    end
end

--计算订单中物品需求数量
function OrderUI:CalculateQantity(productsId)
    local valueTime = ConfigMgr.config_global.order_time
    local orNum = (valueTime[2] - valueTime[1]) / (Tools:GetTableSize(self.m_orderCfg) + 1)
    local times = math.random(1, Tools:GetTableSize(self.m_orderCfg) + 1)
    
    local base_time = ConfigMgr.config_products[productsId].base_time
    local num = valueTime[1] + (times * orNum)
    num = math.floor(num / base_time)    
    return num
end

--判断一个订单是不是完成了CD中
function OrderUI:CheckOrderComCD(orderNum)
    if not self.m_orderData then
        self.m_orderData  = self:GetOrderData()
    end  
    if self.m_orderData[orderNum].timePoint <= TimerMgr:GetCurrentServerTime(true) then
        return true
    end 

    return false
end

--将一个零件Id放入禁止刷新的table中
function OrderUI:AddProductInProhibit(index, product)
    local orderData = self:GetOrderData()
    local cur_Data = orderData[tostring(index)]
    if not cur_Data then
        return
    end    
    local h_list = WorkShopInfoUI:GetProductList()
    if not cur_Data.prohibit then
        cur_Data.prohibit = {}
    end    
    --当禁表超出总表时
    if Tools:GetTableSize(cur_Data.prohibit) + 1 >= Tools:GetTableSize(h_list) then
        cur_Data.prohibit = nil
    else
        table.insert(cur_Data.prohibit, product)
    end
    LocalDataManager:WriteToFile()
end

--获取一个订单栏位的禁表
function OrderUI:GetProductProhibit(index)
    local orderData = self:GetOrderData()
    local cur_Data = orderData[tostring(index)]
    if not cur_Data then
        return {}
    end
    return cur_Data.prohibit or {}
end
