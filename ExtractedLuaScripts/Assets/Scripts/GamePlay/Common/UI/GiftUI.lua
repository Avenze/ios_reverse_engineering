local GiftUI = GameTableDefine.GiftUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local ShopManager = GameTableDefine.ShopManager
local PurchaseSuccessUI = GameTableDefine.PurchaseSuccessUI
local EventManager = require("Framework.Event.Manager")
local ResMgr = GameTableDefine.ResourceManger

local json = require("rapidjson")

local GIFT_RECORD = "gift_record"
function GiftUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.GIFT_UI, self.m_view, require("GamePlay.Common.UI.GiftUIView"), self, self.CloseView)
    return self.m_view
end

function GiftUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.GIFT_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function GiftUI:GetReward(input)
    if not input or input == "" then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_NO_INPUT"))
        return false
    end
    
    -- 备用功能
    if GameConfig:IsDebugMode() and tonumber(input) == nil then
        xpcall(function()
            local AES = CS.Common.Utils.AES
            local rapidjson = require("rapidjson")
            local md5 = UnityHelper.GetMD5(input)
            local str = AES.Decrypt(input)
            local data = rapidjson.decode(str)
            -- Tools:DumpTable(data, "data")
            -- print(GameTimeManager:GetCurrentServerTime(),  data.time)
            local save = LocalDataManager:GetDataByKey(GIFT_RECORD)
            if save[input] and data[input] >= (data.count or 0) then
                EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_REPEAT_INPUT"))
                return
            end

            if data.cash and data.cash > 0 then
                ResMgr:AddCash(data.cash)
            end
            if data.diamand and data.diamand > 0 then
                ResMgr:AddDiamand(data.diamand)
            end
            if data.star and data.star > 0 then
                GameTableDefine.StarMode:StarRaise(data.star)
            end
            save[md5] = (save[md5] or 0) + 1
        end,function()
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_INCORRECT_INPUT"))
        end)
        return
    end

    local data = ConfigMgr.config_gift[tonumber(input)]
    if not data then--没有改礼包
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_INCORRECT_INPUT"))
        return false
    end

    local save = LocalDataManager:GetDataByKey(GIFT_RECORD)
    if save[input] then--领取过了
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_REPEAT_INPUT"))
        return false
    end

    save[input] = 1
    local reward = data.gift_reward

    ResMgr:Add(reward[1], reward[2], nil, function(success)
        if not success then
            return
        end
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_ACTIVE_INPUT"))
    end, true)

    return true
end

function GiftUI:giftReward(input)
    local data = ConfigMgr.config_gift[tonumber(input)]
    if not data then
        return nil
    end

    return data.gift_reward
end

function GiftUI:VerifyGiftCode(code)
    local save = LocalDataManager:GetDataByKey(GIFT_RECORD)
    if save[code] then
        EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_REPEAT_INPUT"))
        return true
    end
end

function GiftUI:SendGift(items)
    --调整礼包码发放的方式2024-8-5 fy
    --在配置表中查看是否是限时活动要补的东西
    --0不是限时活动要补的东西，1-累充活动，2-限时礼包，3-限时副本
     local rewardsData = {}
    for i, v in ipairs(items or {}) do
        if type(v) == 'table' then
            local shopID = tonumber(v[1]) or 0
            if shopID > 0 and ConfigMgr.config_shop[shopID] then
                if not rewardsData[shopID] then
                    rewardsData[shopID] = tonumber(v[2]) or 0
                else
                    rewardsData[shopID]  = rewardsData[shopID] + (tonumber(v[2]) or 0)
                end
            end
        else
            local shopID = tonumber(items[1]) or 0
            if shopID > 0 and ConfigMgr.config_shop[shopID] then
                if not rewardsData[shopID] then
                    rewardsData[shopID] = tonumber(items[2]) or 0
                else
                    rewardsData[shopID]  = rewardsData[shopID] + (tonumber(items[2]) or 0)
                end
                break
            end
        end
    end
    --检测是否有不能用礼包码兑换的东西，如果有直接返回，并提示不能对话
    for k, v in pairs(rewardsData) do
        if not ShopManager:CheckShopItemCanUseInGiftCode(k, v) then
            EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_INCORRECT_INPUT"))
            if self.curCode then
                local log = tostring(k).."号商品兑换码异常"
                GameSDKs:TrackForeign("gift_code", {codenum = tostring(self.curCode), state = "失败", faillog = log})
            end
            return
        end
    end
    --如果是礼包还需要拆解下礼包还原为商品
    for k, v in pairs(rewardsData) do
        local shopCfg = ConfigMgr.config_shop[k]
        if shopCfg and shopCfg.type == 12 then
            for _, id in pairs(shopCfg.param or {}) do
                rewardsData[id] = 1
            end
            rewardsData[k] = nil
        end
    end
    --发放实际奖励，并返回调用实际的奖励显示的内容
    ShopManager:BuyByGiftCode(rewardsData, function(realRewardDatas)
        --realRewardDatas = {{icon1, num1}, {icon2, num2}}
        --这里显示UI奖励内容
        GameTableDefine.CycleInstanceRewardUI:ShowGiftCodeGetRewards(realRewardDatas, true)
        if self.curCode then
            GameSDKs:TrackForeign("gift_code", {codenum = tostring(self.curCode), state = "成功", faillog = "无"})
        end
    end)
    ---老的礼包码发放已经失效，2024-8-5后调整为新的礼包码发放方式
    --==============老的注释掉=start==============
    -- local setCode = function(shopId , num)
    --     for i=1,num do
    --         ShopManager:Buy(shopId, false, nil, function()
    --             PurchaseSuccessUI:SuccessBuy(shopId, nil, true)                
    --         end, true)
    --     end
    -- end
    
    -- for i,v in ipairs(items or {}) do
    --     if type(v) == 'table' then
    --         setCode(v[1], v[2])
    --     else
    --         setCode(items[1], items[2])
    --         break
    --     end
    -- end
    --==============老的注释掉=end==============
end

function GiftUI:GetCodeAward(code, cb)
    local data = LocalDataManager:GetDataByKey("user_data")
    self.curCode = code
	local requestTable = {
		url = GameNetwork.AWARD_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
            code = code,
		},
		callback = function(response)
            -- if tonumber(response.errorCode) == 200 then
            --     -- 本地验证
            --     if self:VerifyGiftCode(code) then
            --         GiftUI:CostCodeAward(code)
            --         return
            --     end
                -- 发送礼物
                self:SendGift(json.decode(response.data or response))
                print("--------> IAP GetCodeAward")
            --     -- 网络端消耗礼包码
            --     GiftUI:CostCodeAward(code)
            -- else
            --     EventManager:DispatchEvent("UI_NOTE", GameTextLoader:ReadText("TXT_TIP_INCORRECT_INPUT"))
            -- end
            if cb then cb() end
		end,
        errorCallback = function(error)
            local txt = GameTextLoader:ReadText("TXT_TIP_INCORRECT_INPUT")
            if error then
                txt = txt .."["..error.."]"
            end
            EventManager:DispatchEvent("UI_NOTE", txt)
            local log = "服务器返回异常代码:"..error
            if tostring(error) == "301" then
                log = error..":没有该兑换码"
            elseif tostring(error) == "302" then
                log = error..":兑换码未激活"
            elseif tostring(error) == "303" then
                log = error..":兑换码已过期"
            elseif tostring(error) == "304" then
                log = error..":兑换码已达使用上限"
            elseif tostring(error) == "305" then
                log = error..":此兑换码为指定玩家的兑换码，但与目前请求使用的玩家id不匹配"
            elseif tostring(error) == "306" then
                log = error..":兑换码已使用过"
            end
            if self.curCode then
                -- local log = tostring(k).."号商品兑换码异常"
                GameSDKs:TrackForeign("gift_code", {codenum = tostring(self.curCode), state = "失败", faillog = log})
            end
            if cb then cb() end
        end,
	}
    local token = "eyJhbGciOiJIUzI1NiJ9.eyJjb2RlIjoiMC5nb29nbGVwbGF5LmJjMWUyNDc2ODFkYTRjZTdiOTBkNzk0NzEzYjMyNDY0IiwiZXhwIjoxNjU1NTE3ODU2LCJ1c2VySWQiOiI0ODE0ODM2NiJ9.hfa5AZct1YcT1mX0rh7Vi2ObOfO5LYFm6s9PadT2588"
    -- 48148366
    if not GameDeviceManager:IsEditor() then
        token = data.token
    end
    if GameConfig:UseWarriorOldAPI() then
        GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)
    else
        requestTable.url = GameSDKs.AWARD_URL
        requestTable.msg = nil
        requestTable.code = code
        GameSDKs:Warrior_request(requestTable) -- [[1067,1],[1077,1]][1077,1]]
    end
end

function GiftUI:CostCodeAward(code)
     -- 网络端消耗礼包码
    local data = LocalDataManager:GetDataByKey("user_data")
	local requestTable = {
		url = GameNetwork.COST_CODE_URL,
        isLoading = true,
        fullMsgTalbe = true,
		msg = {
            code = code,
		},
		callback = function(response)
            if response.errorMessage == 200 then
                print("--------> IAP GetCodeAward")
            end
		end
	}
    local token = "eyJhbGciOiJIUzI1NiJ9.eyJjb2RlIjoiMC5nb29nbGVwbGF5LmJjMWUyNDc2ODFkYTRjZTdiOTBkNzk0NzEzYjMyNDY0IiwiZXhwIjoxNjU1NTE3ODU2LCJ1c2VySWQiOiI0ODE0ODM2NiJ9.hfa5AZct1YcT1mX0rh7Vi2ObOfO5LYFm6s9PadT2588"
    -- 48148366
    if not GameDeviceManager:IsEditor() then
        token = data.token
    end
    -- GameNetwork.HEADR["X-WRE-TOKEN"] = token
    GameNetwork:HTTP_PublicSendRequest(requestTable.url, requestTable, nil, nil, nil, GameNetwork.HEADR)

     -- 本地端消耗礼包码
    local save = LocalDataManager:GetDataByKey(GIFT_RECORD)
    save[code] = 1
    LocalDataManager:WriteToFile()
end

--HK
function GiftUI:HKGetCodeAward(code, cb)
    local data = LocalDataManager:GetDataByKey("user_data")
    local requestTable = {
        url = "hk_claim_gift",
        isLoading = true,
        msg = {
            id = code,
            wxId = GameSDKs:GetThirdAccountInfo()
        },
        callback = function(response)
            self:SendGift(response.data)
            if cb then cb() end
        end,
        errorCallback = function(error)
            local txt = GameTextLoader:ReadText("TXT_TIP_INCORRECT_INPUT")
            EventManager:DispatchEvent("UI_NOTE", txt)
            if cb then cb() end
        end
    }
    GameNetwork:HTTP_SendRequest(requestTable)
end
