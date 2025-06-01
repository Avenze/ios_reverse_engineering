---@class WorkShopInfoUI
local WorkShopInfoUI = GameTableDefine.WorkShopInfoUI
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")
local FactoryMode = GameTableDefine.FactoryMode
local TimerMgr = GameTimeManager

function WorkShopInfoUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.WORK_SHOP_INFO_UI, self.m_view, require("GamePlay.Factory.UI.WorkShopInfoUIView"), self, self.CloseView)
    return self.m_view
end

function WorkShopInfoUI:WorkShopInfoInit(WorkShopId)
    self:GetView():Invoke("WorkShopInfoInit", WorkShopId)
end

function WorkShopInfoUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.WORK_SHOP_INFO_UI)
    self.m_view = nil
    collectgarbage("collect")
end
--获取到此工厂的仓库的当前零件存储上限
function WorkShopInfoUI:storageLimit()
    --这里写死了,后面需要再改
    if not FactoryMode:GetWorkShopdata(10005) or not FactoryMode:GetWorkShopdata(10005)["Lv"] then
        return 1
    end
    local wareHouseLv = FactoryMode:GetWorkShopdata(10005)["Lv"]

    self.m_cfgWorkShop = ConfigMgr.config_workshop

    local storageLimit = self.m_cfgWorkShop[10005]["room_storage"][wareHouseLv]

    local currentLimit = storageLimit - self:GetTheTotal()

    if currentLimit < 0 then
        currentLimit = 0
    end
    --当前还有的空间, 总空间
    return currentLimit, storageLimit
end

--判断此零件在此车间能否生产
function WorkShopInfoUI:CanProduce(workShopId, productsId)
    self.m_cfgProducts = ConfigMgr.config_products
    self.m_data = FactoryMode:GetWorkShopdata(workShopId)

    if self.m_data["Lv"] >= self.m_cfgProducts[productsId]["workshop_require"][2] then
    end
end
---获取加密产品数量的统一接口
function WorkShopInfoUI:GetProductNum(type)
    type = tostring(type)
    local productsData = self:GetProductsData()
    return LocalDataManager:DecryptField(productsData,type)
end
---设置加密产品数量的统一接口
function WorkShopInfoUI:SetProductNum(type,num)
    type = tostring(type)
    local productsData = self:GetProductsData()
    LocalDataManager:EncryptField(productsData,type,num)
end

--增加产品
function WorkShopInfoUI:AddProduct(num, type, cb, overload)
    --local productsData = self:GetProductsData()
    local success = true
    --if not productsData[tostring(type)] then
    --    productsData[tostring(type)] = 0
    --end
    if self:storageLimit() == 0 then
        success = false
    end
    local curNum = self:GetProductNum(type)
    if num > self:storageLimit() and not overload then
        self:SetProductNum(type,curNum+self:storageLimit())
        --productsData[tostring(type)] = productsData[tostring(type)] + self:storageLimit()
    else
        self:SetProductNum(type,curNum+num)
        --productsData[tostring(type)] = productsData[tostring(type)] + num
    end

    LocalDataManager:WriteToFile()

    if cb and success then
        cb()
    end
end
-- 消耗产品
function WorkShopInfoUI:SpendProduct(num, type)
    local curNum = self:GetProductNum(type)
    if curNum < num then
        return false
    else
        self:SetProductNum(type,curNum-num)
        LocalDataManager:WriteToFile()
        return true
    end
    --local productsData = self:GetProductsData()
    --if not productsData[tostring(type)] or productsData[tostring(type)] < num then
    --    return false
    --else
    --    productsData[tostring(type)] = productsData[tostring(type)] - num
    --    LocalDataManager:WriteToFile()
    --    return true
    --end
end

--获得产品存档
function WorkShopInfoUI:GetProductsData()
    local productData = LocalDataManager:GetDataByKey("product")    
    return productData
end


--生产中断时返还消耗
function WorkShopInfoUI:Consume(productId)
    self.m_cfgProducts = ConfigMgr.config_products
    for k, v in pairs(self.m_cfgProducts[productId]["need_product"]) do        
        if v["type"] == 0 then            
            return
        else            
            self:AddProduct(v["num"], v["type"])            
        end
    end    
end

--在材料够的时候去消耗材料,成功消耗后才能走 cb
function WorkShopInfoUI:ConsumableMaterialGroup(productId, cb)
    self.m_cfgProducts = ConfigMgr.config_products
    if self:EnoughPartsToProduce(productId) then
        for k, v in pairs(self.m_cfgProducts[productId]["need_product"]) do
            self:SpendProduct(v["num"], v["type"])
        end
        if cb then
            cb()
        end
    end
end

--判断一个零件的配件是否是够的
function WorkShopInfoUI:EnoughPartsToProduce(productId)
    self.m_cfgProducts = ConfigMgr.config_products
    --local productData = self:GetProductsData()
    local bool = true
    for k, v in pairs(self.m_cfgProducts[productId]["need_product"]) do
        if v["type"] == 0 then
            return true
        --elseif v["num"] > productData[tostring(v["type"])] then
        elseif v["num"] > self:GetProductNum(v["type"]) then
            return false
        else
            
        end
    end
    return bool
end

--获得当前能生成的零件的一个列表
function WorkShopInfoUI:GetProductList()
    self.m_cfgWorkShop = ConfigMgr.config_workshop
    local productList = {}
    for k, v in pairs(self.m_cfgWorkShop) do
        local workShopData = FactoryMode:GetWorkShopdata(k)
        if workShopData then
            local workShopLv = workShopData["Lv"]
            if not workShopLv then
                workShopLv = 0
            end
            for i, s in pairs(v["product"]) do
                if workShopLv >= s["LvNeed"] and s["type"] ~= 0 then
                    productList[s["type"]] = s["type"]
                end
            end
        end
    end
    return productList
end

--计算当前一共有多少零件用于计算仓库容量
function WorkShopInfoUI:GetTheTotal()
    local productData = self:GetProductsData()
    local num = 0
    for k, v in pairs(productData) do
        if type(v) == "number" then
            num = num + self:GetProductNum(k)
        end
    end
    return num
    --local productData = self:GetProductsData()
    --local num = 0
    --for k, v in pairs(productData) do
    --    num = num + v
    --end
    --return num
end

--判断是否存在有工厂零件材料不足(用于UI的显示)
function WorkShopInfoUI:HaveInsufficient()
    self.m_cfgWorkShop = ConfigMgr.config_workshop
    local productList = {}    
    for k, v in pairs(self.m_cfgWorkShop) do
        local workShopData = FactoryMode:GetWorkShopdata(k)
        if workShopData and workShopData.state == 2 and not self:EnoughPartsToProduce(workShopData.productId) then            
            return true
        end
    end
    return false
end
--播放buff的动效
function WorkShopInfoUI:PlayBuffAnim()
    self:GetView():Invoke("PlayBuffAnim")
end