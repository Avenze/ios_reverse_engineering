local PetInteractUI = GameTableDefine.PetInteractUI
local ShopManager = GameTableDefine.ShopManager
local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local PetListUI = GameTableDefine.PetListUI
local MainUI = GameTableDefine.MainUI
local GreateBuildingMana = GameTableDefine.GreateBuildingMana
local PetMode = GameTableDefine.PetMode
local TimerMgr = GameTimeManager
local CountryMode = GameTableDefine.CountryMode
local EventManager = require("Framework.Event.Manager")

function PetInteractUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.PET_INTERACT_UI, self.m_view, require("GamePlay.Common.UI.PetInteractUIView"), self, self.CloseView)
    return self.m_view
end

function PetInteractUI:OpenUI(cfg, petMod)
    self:GetView():Invoke("OpenUI", cfg, petMod)  
end

function PetInteractUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.PET_INTERACT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

--喂养宠物
function PetInteractUI:FeedPet(petId, petfeedId, cb)
    local cfgSnack = ConfigMgr.config_snack[petfeedId]
    self:SpendPetFeed(petfeedId, 1, function(isSuccess)
        if isSuccess then
            --增加饥饿度
            self:AddPetHungry(petId, cfgSnack.hunger_add)
            --记录喂养的时间和食物类型
            self:AddExBuff(petId,petfeedId)
            PetListUI:RefreshFeed()
            self:RefreshFeedList()            
            if cb then
                cb(isSuccess)
            end
        end
    end)    
end

--消耗零食
function PetInteractUI:SpendPetFeed(petfeedId, num, cb) 
    petfeedId = tostring(petfeedId)
    if not num then
        num = 1
    end
    local isSuccess = true
    --local cfgSnack = ConfigMgr.config_snack[petfeedId]
    local petFeedCount = PetMode:GetPetFeed(petfeedId)
    if petFeedCount < num then
        isSuccess = false
    else
        PetMode:SetPetFeed(petfeedId,petFeedCount-num)
    end
    --local petFeedData = LocalDataManager:GetDataByKey("pet_feed")
    --if not petFeedData[petfeedId] then
    --    petFeedData[petfeedId] = 0
    --    isSuccess = false
    --elseif petFeedData[petfeedId] < num then
    --    isSuccess = false
    --else
    --    petFeedData[petfeedId] = petFeedData[petfeedId] - num
    --end
    if cb then 
        cb(isSuccess)
    end
end
--宠物升级
function PetInteractUI:Upgrade(petId)
    -- 新版本
    PetMode:Upgrade(petId)
    -- end 新版本

    --废弃 -- 为了兼容暂时保留
    --对宠物升级
    local petData = PetMode:GetPetLocalData(petId)
    local cfg = PetMode:GetPetCfgByPetId(petId)
    -- petData.level = petData.level + 1
    -- petData.experience = 0  
    --对宠物加成进行升级 
    local save = ShopManager:GetLocalData()
    local value = cfg.bonus_effect[petData.level] - cfg.bonus_effect[petData.level - 1]
    if cfg.bonus_type == "money_enhance" then
        if not save.pcash then
            save.pcash = 0
        end
        save.pcash = save.pcash + value
    elseif cfg.bonus_type == "mood_improve" then
        if not save.pmood then
            save.pmood = 0
        end
        save.pmood = save.pmood + value
        -- GreateBuildingMana:RefreshImprove()
        -- Actor:RefreshEmployeesMood()
    elseif cfg.bonus_type == "offline_limit"  then
        if not save.ptime then
            save.ptime = 0
        end
        save.ptime = save.ptime + value
    end  
    LocalDataManager:WriteToFile()
end

--增加饥饿度
function PetInteractUI:AddPetHungry(petId, num,cb)    
    local success = false
    local petData = PetMode:GetPetLocalData(petId)
    local cfgPet = ConfigMgr.config_pets    
    local cfg = PetMode:GetPetCfgByPetId(petId)  
    if cfg.max_hungry <= petData.hungry + num then
        local success = true
        petData.hungry = cfg.max_hungry
    else
        petData.hungry = petData.hungry + num
        local success = true
    end
    if cb then
        cb(success)
    end    
    LocalDataManager:WriteToFile()
end

--上经验buff和时间点
function PetInteractUI:AddExBuff(petId, petfeedId)   
    local petData = PetMode:GetPetLocalData(petId)    
    local cfgSnack = ConfigMgr.config_snack[petfeedId]

    -- 新数据结构
    if not petData.expBuff then
        petData.expBuff = {}
    end
    petData.expBuff[tostring(cfgSnack.exp_add)] = (petData.expBuff[tostring(cfgSnack.exp_add)] or 0) + cfgSnack.exp_duration
end

--计算buff增加经验的效果  bool 为 true 表示消耗 buff 的 cd, cID 为cityID
function PetInteractUI:ExpSpeed(petId , bool, cId)    
    local petData = PetMode:GetPetLocalData(petId, cId)
    local cfgGlobal = ConfigMgr.config_global
    local buff = petData.expBuff
    local expSpeed = ConfigMgr.config_global.pet_exp_basespeed
    local cfgSnack = ConfigMgr.config_snack
    if not buff then
        return expSpeed
    end
    for k,v in pairs(buff) do
        if v > 0 then
            expSpeed = (k * cfgGlobal.pet_exp_basespeed / 100) + expSpeed
            if bool then
                buff[tostring(k)] = v - 1
            end
        end
    end    
    LocalDataManager:WriteToFile()
    return expSpeed
end

-- 获取经验加成剩余时间, 经验加成的效果都相同, 两个buff叠加时事件叠加, 效果不变
function PetInteractUI:GetExpBuffRemain(petId)
    local petData = PetMode:GetPetLocalData(petId)
    local buff = petData and petData.expBuff
    if buff then
        for k,v in pairs(buff) do
            if tonumber(k) > 0 then
                return v    -- 目前只会有一种加成效果, 如果出现了两种不同的效果找策划
            end
        end
    end
end

--计算所有宠物的成长
function PetInteractUI:AllPetGrowth()
    local hungryCd = 30
    local data = PetMode:GetPetsdata(nil, CountryMode:GetWordSize())
    if self.updata == nil then
        GameTimer:CreateNewMilliSecTimer(1000, function()
            local growth = false
            for k,v in pairs(data or {}) do
                if v.buff and v.hungry then
                    growth = PetInteractUI:NewPetGrowth(k, hungryCd, CountryMode:GetWordSize())
                end
            end
            if growth then
                MainUI:RefreshPetHint()
                LocalDataManager:WriteToFile()
            end
            hungryCd = hungryCd -1 
            if hungryCd < 0 then
                hungryCd = 30
            end        
        end, true, true)
    end    
end

--宠物1秒的成长
-- function PetInteractUI:PetGrowth(petId)    
--     local cfgGlobal = ConfigMgr.config_global
--     local expSpeed = self:ExpSpeed(petId, true)   
--     local petData = PetMode:GetPetLocalData(petId)
--     local cfgPets = ConfigMgr.config_pets
--     local cfg = PetMode:GetPetCfgByPetId(petId)
--     if petData.level -1 >= #cfg.exp_limit then
--         return
--     end    
--     if petData.hungry <= 0 then --饥饿度不足
        
--     else     
--         if petData.hungry < cfgGlobal.hungry_speed then
--             petData.hungry = 0
--         else                
--             petData.hungry = petData.hungry - cfgGlobal.hungry_speed         
--             if petData.experience + expSpeed >= cfg.exp_limit[petData.level] then
--                 petData.experience = cfg.exp_limit[petData.level]
--             else
--                 petData.experience = petData.experience + expSpeed
--             end           
--         end
--     end
--     --红点的检测刷新
--     MainUI:RefreshPetHint()
--     LocalDataManager:WriteToFile()
-- end

--宠物1秒的成长,需要传入 hungryCd 用于判断是否削减饥饿值
function PetInteractUI:NewPetGrowth(petId, hungryCd, cid)
    local cfg = PetMode:GetPetCfgByPetId(petId)
    if not cfg then 
        return false
    end

    local cfgGlobal = ConfigMgr.config_global
    local expSpeed = self:ExpSpeed(petId, true, cid)   
    local petData = PetMode:GetPetLocalData(petId, cid)
    --local cfgPets = ConfigMgr.config_pets

    if petData.level -1 >= #cfg.exp_limit then
        return false
    else
        local growth = false
        --经验的增长
        if petData.hungry > 0 then                                           
            if cfg.exp_limit[petData.level] and petData.experience + expSpeed >= cfg.exp_limit[petData.level] then
                petData.experience = cfg.exp_limit[petData.level]
            else
                if not cfg.exp_limit[petData.level] then
                    petData.experience = petData.experience
                else
                    petData.experience = petData.experience + expSpeed
                end
            end
            growth = true
        end
        --饱腹感的削减
        if hungryCd <= 0 then
            if petData.hungry < cfgGlobal.hungry_speed then
                petData.hungry = 0
            else
                petData.hungry = petData.hungry - cfgGlobal.hungry_speed
            end
        end
        --红点的检测刷新
        --MainUI:RefreshPetHint()
        --LocalDataManager:WriteToFile()
        return true
    end
end

--宠物的离线成长计算
function PetInteractUI:OfflineGrowingUp(hungryCd)
    --local notUse, difference =  GameTableDefine.OfflineRewardUI:OffTimePassSecond()
    local notUse, difference = nil, GameTableDefine.OfflineManager.m_offline
    if not difference then
        difference = GameTableDefine.OfflineManager:GetOffline()
    end
    local cfgSnack = ConfigMgr.config_snack
    local cfgGlobal = ConfigMgr.config_global
    for k,v in pairs(PetMode:GetPetsdata()) do        
        local cfg = PetMode:GetPetCfgByPetId(k)
        if cfg then 
            local isAddExp = v.hungry > 0
            if v.level -1 >= #cfg.exp_limit then
                
            else
                local rellyDifference = difference
                local addExp = 0
                --饥饿值消耗
                local value = math.floor(difference / hungryCd)
                if v.hungry - value < 0 then
                    rellyDifference = math.floor(v.hungry * hungryCd)
                    addExp = rellyDifference * cfgGlobal.pet_exp_basespeed
                    v.hungry = 0
                else
                    v.hungry = v.hungry - value
                    addExp = difference * cfgGlobal.pet_exp_basespeed
                end
                -- 经验buff替换数据
                if not v.expBuff then
                    v.expBuff = {}
                    for i,j in pairs(v.buff) do
                        v.expBuff[tostring(cfgSnack[tonumber(i)].exp_add)] = j
                    end
                end
   
                --buff的消耗
                for i,j in pairs(v.expBuff) do
                    if j - rellyDifference <= 0 then
                        v.expBuff[i] = 0
                        addExp = addExp + j * (i * cfgGlobal.pet_exp_basespeed / 100)
                    else
                        v.expBuff[i] = j - rellyDifference
                        addExp = addExp + rellyDifference * (i * cfgGlobal.pet_exp_basespeed / 100)
                    end
                end 
                --经验的增涨
                if isAddExp and addExp > 0 then                   
                    if cfg.exp_limit[v.level] and v.experience + addExp >= cfg.exp_limit[v.level] then
                        v.experience = cfg.exp_limit[v.level]
                    else
                        if cfg.exp_limit[v.level] then
                            v.experience = v.experience + addExp
                        else
                            v.experience = v.experience
                        end
                    end                    
                end
                if v.experience < 0 then 
                    v.experience = 0
                end
                LocalDataManager:WriteToFile()
            end  
        end       
    end    
end

-- --通过宠物Id获得宠物配置
-- function PetInteractUI:GetPetCfgByPetId(petId)
--     local cfg 
--     PetListUI:InitPetdata()
--     local cfgPets = ConfigMgr.config_pets
--     for k,v in pairs(cfgPets) do
--         if v.shopId == tonumber(petId) then
--             cfg = v
--             break
--         end
--     end
--     return cfg
-- end

--播放动画
function PetInteractUI:PlayPetAnimation(petMod, type)
    self:GetView():Invoke("PlayPetAnimation", petMod, type)
end

--修改宠物的名字
function PetInteractUI:RePetName(petId ,newName)
    local petData = PetMode:GetPetLocalData(petId)
    petData.name = newName 
    LocalDataManager:WriteToFile()
    self:GetView():Invoke("Refresh")
end

--检测是否有宠物处于饥饿或者可以升级(仅用于入口处红点的刷新)
function PetInteractUI:DetectStarvationOrUpgrade()
    local petDatas = PetMode:GetPetsdata()
    local value = false
    for k,v in pairs(petDatas) do
        local cfg = PetMode:GetPetCfgByPetId(k)
        if cfg and v.level <= #cfg.exp_limit then                                
            if v.hungry == 0  then
                if cfg.exp_limit[v.level] and v.experience >= cfg.exp_limit[v.level] then
                    value = true 
                    return value
                end
            end 
        end
    end
end

function PetInteractUI:DetectOnePet(petId)
    local petData = PetMode:GetPetLocalData(petId)
    local value = false
    local cfg = PetMode:GetPetCfgByPetId(petId)
    if petData.level <= #cfg.exp_limit then                                
        if petData.hungry == 0  or petData.experience >= cfg.exp_limit[petData.level] then
            value = true            
        end 
    end
    return value
end
--刷新零食的数量显示
function PetInteractUI:RefreshFeedList()
    if GameUIManager:IsUIOpenComplete(ENUM_GAME_UITYPE.PET_INTERACT_UI) then
        self:GetView():Invoke("RefshList")
        self:GetView():Invoke("Refresh")
    end
end