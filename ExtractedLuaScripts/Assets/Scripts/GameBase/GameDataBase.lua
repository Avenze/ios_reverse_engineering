-- require("ConfigData.configFuntions")

local User = GameTableDefine.User
local Guide = GameTableDefine.Guide
local GameInterface = GameTableDefine.GameInterface
local GameInterfaceChat = GameTableDefine.GameInterfaceChat

GameDataBase = {
    GameData = {},
    unhandledPushMsg = {},
}

function GameDataBase:ClearDataBase()
    GameDataBase.GameData = {}
    GameDataBase.unhandledPushMsg = {}
end

--有uid的情况下，如果uid存在，把uid作为key重建表，否则维持原状
function GameDataBase:CreateTableUseUidAsKey(dest, content)
    for k, v in pairs(content) do
        if type(v) == 'table' then
            if v.uid ~= nil and v.uid ~= '' then
                if dest[v.uid] == nil then
                    dest[v.uid] = {}
                end
                
                for tk, tv in pairs(v) do
                    if type(tv) == "table" then
                        if tv.uid ~= nil and tv.uid ~= '' then
                            dest[v.uid][tv.uid] = {}
                            self:CreateTableUseUidAsKey(dest[v.uid][tv.uid], tv)
                        else
                            dest[v.uid][tk] = {}
                            self:CreateTableUseUidAsKey(dest[v.uid][tk], tv)
                        end
                    else
                        dest[v.uid][tk] = tv
                    end
                end
            else
                if dest[k] == nil then
                    dest[k] = {}
                end
                for tk, tv in pairs(v) do
                    if type(tv) == "table" then
                        if tv.uid ~= nil and tv.uid ~= '' then
                            dest[k][tv.uid] = {}
                            self:CreateTableUseUidAsKey(dest[k][tv.uid], tv)
                        else
                            dest[k][tk] = {}
                            self:CreateTableUseUidAsKey(dest[k][tk], tv)
                        end
                    else
                        dest[k][tk] = tv
                    end
                end
            end
        else
            dest[k] = v
        end
    end
end

function GameDataBase:RefreshGlobalData(content)
    if not type(content) == "table" then return end
    
    local newTable = {}
    self:CreateTableUseUidAsKey(newTable, content)
    self:MergeTableUseUidAsKey(self.GameData, newTable)
end

function GameDataBase:DelayRefreshGlobalData(content)
    if content.quests then
        GameTableDefine.Quest:RefreshQuestIndexMaping()
    end
end

function GameDataBase:MergeTableUseUidAsKey(dest, source)
    if dest == nil then
        return
    end
    
    for _, rKey in pairs(source._replace_keys or {}) do
        dest[rKey] = nil
    end
    source._replace_keys = nil
    
    for k, v in pairs(source) do
        if type(v) == "table" and dest[k] ~= nil then --target table exist
            if v._replace then
                local key = (v.uid and v.uid ~= '') and v.uid or k
                dest[key] = v
            elseif v.uid ~= nil and v.uid ~= '' then -- source subtable has uid
                local uidExist = false
                for tk, tv in pairs(dest) do
                    if type(tv) == "table" then
                        if tv.uid == v.uid then-- dest table has subtable with same uid
                            if v._del == true then
                                dest[tk] = nil
                            else
                                self:MergeTableUseUidAsKey(dest[tk], v)
                            end
                            uidExist = true
                        end
                    end
                end
                
                if not uidExist then -- dest table doesnt have subtable with same uid
                    if v._del == true then
                        dest[k] = nil
                    else
                        self:MergeTableUseUidAsKey(dest[k], v)
                    end
                end
            else --source subtable has no uid
                if type(dest[k]) == "table" then
                    if v._del == true then
                        dest[k] = nil
                    else
                        self:MergeTableUseUidAsKey(dest[k], v)
                    end
                else -- target is not table, so it means source MUST NOT be a table?
                    if v._del == true then
                        dest[k] = nil
                    else
                        self:MergeTableUseUidAsKey(dest, v)
                    end
                end
            end
        elseif type(v) == "table" then -- target table doesn't exist, create it
            if v._del == true then
                --do nothing
            else
                dest[k] = v
            end
        else
            dest[k] = v
        end
    end
end

function GameDataBase:FindGameData(path, func)
    local t = self.GameData[path]
    if not t then return {} end
    return LuaTools:GetTableValues(
    LuaTools:FilterTable(t, func))
end

-- RemoveRecords !
function GameDataBase:RemoveGameData(path, func)
    -- local t = assert(loadstring("return GameDataBase.GameData." .. path))()
    local t = self.GameData[path]
    if not t then return end
    for k, v in pairs(t) do
        if func(k, v) then
            t[k] = nil
        end
    end
end


function GameDataBase:CalcPriceofTime(workType, timeLength)
    local priceTable = require("ConfigData.configTimeWorths2")
    if not config_time_worths2.funcs then
        function config_time_worths2.funcs()
            if config_time_worths2.__funcs then
                return config_time_worths2.__funcs
            end
            config_time_worths2.__funcs = {}
            for k, v in pairs(config_time_worths2[1]) do
                config_time_worths2.__funcs[k] = loadstring("return function (n) return math.ceil("..v..") ; end")()
            end
            return config_time_worths2.__funcs
        end
    end
    
    local timeInSeconds = tonumber(timeLength)
    if workType and workType == "build" then
        timeInSeconds = math.max(0, timeInSeconds - GameBuildings:GetFreeAccelarationThresh())
    end
    return config_time_worths2.funcs()[workType](timeInSeconds)
end


function GameDataBase:IsFunctionOpen(functionName)
    local functionStatusData = self.GameData.funcs or {}
    
    for k, v in pairs(functionStatusData) do
        if tostring(v.uid) == tostring(functionName) then
            return not v.lock
        end
    end
    
    return true
end

function GameDataBase:PreRefreshGlobalData(content)
    -- print("PreRefreshGlobalData :", type(content))
    -- if not type(content) == "table" then return end
    
    -- if content.vip then
    --     if self.GameData.vip and content.vip.level and self.GameData.vip.level and content.vip.level > self.GameData.vip.level and not GameTableDefine.Vip:IsSvip(content.vip.level) then
    --         GameTableDefine.VipMain:ShowVipLevelUpMenu(content.vip)
    --     end
    --     GameInterface:RefreshInterfaceVip(content.vip)
    -- end
    
    -- if content.quests then
    --     GameTableDefine.Quest:PreQuestData(content.quests)
    -- end
    
    -- if content.buffs then
    --     GameTableDefine.BuffMain:PreBuffData(content.buffs)
    -- end
    
    -- if content.once_pop_gift then
    --     GameDataBase.GameData.once_pop_gift = nil
    -- end
    
    -- if content.cost_ruby then
    --     GameSDKs:SetEvent_SpendCoin(content.cost_ruby.amount, content.cost_ruby.item_id, content.cost_ruby.reason)
    --     GameDataBase.GameData.cost_ruby = nil
    -- end
    
    -- if content.rank_lists then
    --     self.GameData.rank_lists = nil
    -- end
    
    -- if content.union_member_coordinates then
    --     self.GameData.union_member_coordinates = nil
    -- end
    
    -- if content.my_troops then
    --     GameDataBase.GameData.my_troops = nil
    -- end
    
    -- if content.arena_base_troops then
    --     GameDataBase.GameData.arena_base_troops = nil
    -- end
    -- if content.union_month_card then
    --     GameDataBase.GameData.union_month_card = nil
    -- end
    -- if content.acc_check_in_gifts then
    --     GameDataBase.GameData.acc_check_in_gifts = nil
    -- end
    -- --if content.start_event_quests then
    -- --GameInterface:HandleLeonRewardUpdate(content.start_event_quests)
    -- --end
    
    -- if content.union_treasure then
    --     GameDataBase.GameData.union_treasure = nil
    -- end
    -- if content.tech and content.tech.recommend_ids and GameDataBase.GameData.tech then
    --     GameDataBase.GameData.tech.recommend_ids = nil
    -- end
    -- if content.ladder_tournament and GameDataBase.GameData.ladder_tournament then
    --     if content.ladder_tournament.players then GameDataBase.GameData.ladder_tournament.players = nil end
    --     if content.ladder_tournament.defense_team then GameDataBase.GameData.ladder_tournament.defense_team = nil end
    --     if content.ladder_tournament.shop then GameDataBase.GameData.ladder_tournament.shop = nil end
    --     if content.ladder_tournament.rank_rewards then GameDataBase.GameData.ladder_tournament.rank_rewards = nil end
    --     if content.ladder_tournament.daily_rewards then GameDataBase.GameData.ladder_tournament.daily_rewards = nil end
    --     if content.ladder_tournament.best_rank_rewards then GameDataBase.GameData.ladder_tournament.best_rank_rewards = nil end
    -- end
    -- if content.dice and GameDataBase.GameData.dice then
    --     if content.dice._id ~= GameDataBase.GameData.dice._id then
    --         GameDataBase.GameData.dice = nil
    --     else
    --         GameDataBase.GameData.dice.winners = nil
    --     end
    -- end
    -- if content.runes and GameDataBase.GameData.runes then
    --     --TODO:
    --     --GameTableDefine.GameElement:AddElementHint(content.runes)
    -- end
    
    -- if content.soul_skill_result and GameDataBase.GameData.soul_skill_result then
    --     GameDataBase.GameData.soul_skill_result = nil
    -- end
    -- if content.union_strongholds and GameDataBase.GameData.union_strongholds then
    --     GameDataBase.GameData.union_strongholds = nil
    -- end
    
    -- if content.mini_game then
    --     if content.mini_game.round_info then
    --         GameTableDefine.BlackJack:CheckPlayerLife(true)
    --         GameDataBase.GameData.mini_game.round_info = nil
    --     end
    --     if content.mini_game.round_result then
    --         GameDataBase.GameData.mini_game.round_result = nil
    --     end
    --     if content.room_id == "" then
    --         GameDataBase.GameData.mini_game.chair_id = nil
    --         GameDataBase.GameData.mini_game.game_chip = nil
    --     end
    -- end
    -- if content.colossi then
    --     GameDataBase.GameData.colossi = nil
    -- end
    -- if content.newbie_welfare_num 
    --     and GameDataBase.GameData.newbie_welfare_num 
    --     and content.newbie_welfare_num ~= GameDataBase.GameData.newbie_welfare_num then
    --     GameDataBase.GameData.newbie_welfare_num = content.newbie_welfare_num
    --     GameInterface:RefreshLeftsideIcons()
    -- end

    -- if content.adventure then
    --     GameTableDefine.AdventureData:ResetDataOnPush(content.adventure);
    -- end

    -- if content.lottery then
    --     GameDataBase.GameData.lottery = nil
    -- end
end

function GameDataBase:ProcUnhandledPushMsg()
    while true do
        local msgNumber = Tools:GetTableSize(self.unhandledPushMsg)
        if msgNumber > 0 then
            local curMsg = table.remove(self.unhandledPushMsg)
            self:FollowRefreshGlobalData(curMsg)
        else
            break
        end
    end
end

function GameDataBase:IsNaverCafeSDKAvailable()
    --disable naver cafe sdk
    return GameConfig:IsKoreaVersion()--GameLanguage:IsCurrentLanguageKorean()
end

function GameDataBase:IsUserQualifiedforGVoice()
    local userLevel = User:GetUserLevel()
    return userLevel >= 5
end

function GameDataBase:FollowRefreshGlobalData(responseTable)
    if not GameStateManager:CanHandlePushMsg() then
        table.insert(GameDataBase.unhandledPushMsg, responseTable)
        return
    end
    for k, v in pairs(responseTable) do
        -- if GameInterfaceChat.IsChatTableKey(k) then
        --     GameInterfaceChat:OnGetChatMessage()
        --     GameTableDefine.GameTopPopupMenu:SetRunningHorse(v)
        --     GameTableDefine.KingdomMap:RefreshStrongholdBattleBroadcast()
        -- elseif k == "quests" then
        --     GameTableDefine.Quest:RefreshPushQuestData()
        --     GameInterface:SetQuestStatus()
        -- elseif k == "r_quest_id" then
        --     GameInterface:SetQuestStatus()
        -- elseif k == "buffs" then
        --     GameTableDefine.BuffMain:RefreshPushData()
        -- elseif k == "incr_ac" then
        --     GameTableDefine.GameTopPopupMenu:ShowEnergyChange(v)
        -- elseif k == "items" then
        --     GameInterface:RefreshDownIconHint()
        --     BuildingsBarrack:CheckGodFetePanel(v)
        -- elseif k == "union_nums" then
        --     -- if v.help then
        --     --     --GameTableDefine.GameLeague:CheckRefreshHelp(true)
        --     --     GameInterface:RefreshRightIconHint()
        --     -- end
        --     GameInterface:RefreshUnionAllHints()
        --     GameTableDefine.GameLeague:RefreshUnionNums()
        --     GameInterfaceChat:RefreshChatGuildWarHint()
        -- elseif k == "attack_warnings" or k == "rally_wait" or k == "aihelp_hint" or k == "show_newbie_packs" then
        --     GameInterface:RefreshRightIconHint()
        --     if k == "attack_warnings" then
        --         GameInterface:RefreshWarning()
        --     end
        -- elseif k == "city_events" then
        --     GameTableDefine.GameMainCity:CheckEvents()
        -- elseif k == "new_avatar_frame" then
        --     GameInterface:RefreshInterfaceUserInfo()
        -- elseif k == "reward" then
        --     GameTableDefine.GameTopPopupMenu:ShowRewardsAnim(v)
        -- -- elseif k == "tguide" or k == "guide" then
        -- --     Guide:OnEvent(Guide.EVENT_NEW_GUIDE_COMING)
        -- elseif k == "helped_me" then
        --     GameTableDefine.GameLeague:ShowHelpedHint(v);
        -- elseif k == "users" then
        --     GameInterface:ShowInterface()
        --     local user = v[1]
        --     if GameStateManager:IsInWild() then
                
        --         if user and (user.cave_pos or user.x) then
        --             --TODO: uncommment
        --             --GameTableDefine.WildMap:UpdateCursor();
        --         end
                
        --         if user.can_attack_monster_level then
        --             GameTableDefine.WildMap:SetMonsterChallenge(user.can_attack_monster_level)
        --         end
        --     end
        -- elseif k == "mail_notice" then --k == "new_mail_num" or k == "is_new_mail" or k == "mail_notice" then
        --     GameTableDefine.Mail:HandleNewMail()
        -- elseif k == "hero_skill_trigger" then
        --     GameTableDefine.GameTopPopupMenu:ShowSoulSkillActivation(v)
        -- elseif k == "incr_vip_exp" then
        --     GameTableDefine.GameTopPopupMenu:ShowVipPointIncreasingHint(v)
        -- elseif k == "reset_account" then
        --     GameStateManager:UpdateUserID(v)
        -- elseif k == "resources" then
        --     GameInterface:RefreshInterfaceResource()
        -- elseif k == "city_broken" then
        --     if v.show == false then
        --         GameInterface:RefreshRightIconHint()
        --     else
        --         GameInterface:ShowCityDestoryWindow()
        --     end
        -- elseif k == "show_rating_pop" then
        --     GameTableDefine.GameTopPopupMenu:ShowAskLikeGame()
        -- elseif k == "orders" then
        --     GameInterface:ShowGemsBox()
        -- elseif k == "union_level_up" then
        --     GameTableDefine.GameLeague:ShowLevelUpHint(v);
        -- elseif k == "unions" then
        --     if GameTableDefine.GameLeague:GetTopLayerName() == GameTableDefine.GameLeague.LAYER_MAIN then
        --         GameTableDefine.GameLeague:InitMain();
        --     elseif GameTableDefine.GameLeague:GetTopLayerName() == GameTableDefine.GameLeague.LAYER_JOIN then
        --         GameTableDefine.GameLeague:NET_GetJoinData(GameTableDefine.GameLeague.m_listType, true)
        --         GameTableDefine.GameLeaguePop:LeagueHasInvalid(v[1])
        --     end
        -- elseif k == "server_war" then
        --     GameTableDefine.GameServerBattle:ShowServerBattleNews(v[1])
        -- elseif k == "server_battle" then
        --     GameTableDefine.GameServerBattle:SetServerBattleOverall()
        -- elseif k == "union_war" then
        --     GameTableDefine.GameTopPopupMenu:ShowLeagueBattleNews(v[1])       
        -- elseif k == "question" then
        --     GameTableDefine.GameMainCity:HandleQuizUpdating()
        -- elseif k == "break_protect" then
        --     GameInterface:HandleLevel6DataUpdating()
        -- elseif k == "gve_teams" then
        --     GameTableDefine.Wild:Cave_CheckPushRefresh(v)
        -- elseif k == "gve_actions" then
        --     GameTableDefine.Wild:ShowCavePushTips(v)
        --     GameDataBase.GameData.gve_actions = nil
        -- elseif k == "union_invitation" then
        --     GameTableDefine.GameTopPopupMenu:CheckPushInviteJoinUnion()
        -- elseif k == "quest_group" then
        --     GameInterface:ShowInterface()
        -- elseif k == "event_center" then
        --     GameTableDefine.EventCenter:LocalizeEventCenterData()
        --     GameInterface:RefreshDownIconHint()
        --     GameTableDefine.EventCenter:CheckDaySurpriseEventHint()
        -- elseif k == "haowan123_order" then
        --     GameTableDefine.GameActivity:FuncellSDK_BuyCallback()
        -- elseif k == "seven_balls" then
        --     GameTableDefine.GameEvent7balls:RefreshEventCenter(v)
        -- elseif k == "event_seven_ball" then
        --     GameTableDefine.GameEvent7balls:CheckEventEnd(v)
        -- elseif k == "user_ball_msg" then
        --     GameTableDefine.GameEvent7balls:CheckBallPersonalDynamic(v)
        -- elseif k == "shop_promotion" then
        --     if v.max == v.cur and v.max ~= 0 and GameTableDefine.Item._saleEndCallBack then
        --         GameTableDefine.Item._saleEndCallBack()
        --     end
        -- elseif k == "evil_atk" then
        --     GameInterface:HandleDevilAttackUpdateInGuide(v)
        -- elseif k == "notice_killall_evil" then
        --     GameTableDefine.GameLeonTask:HandleAllDemonDefeatedMsg()
        -- elseif k == "taiwan_coin_amount" then
        --     GameTableDefine.GameActivity:ShowBuyThirdCoinSuccess(v)
        -- elseif k == "refresh_shop" then
        --     --GameTableDefine.GameActivity:RefreshShop()
        --     GameTableDefine.Shop:ThirdPayCallback()
        -- elseif k == "stronghold_popup" then
        --     GameTableDefine.GameWildMenu:ShowAllianceFortOwnershipChangePop(v)
        -- elseif k == "strongholds" then
        --     if GameStateManager:IsInWild() then
        --         GameTableDefine.GameWildMenu:RefreshMapStronghold(v)
        --     end
        -- elseif k == "union_strongholds" then
        --     GameEventProcessor:OnEvent(GameEventProcessor.EVENT_REFRESH_ALLIANCE_FORT_DEFENCE_INFO)
        -- elseif k == "city_broken" then
        --     GameInterface:ShowCityDestoryWindow(v);
        -- elseif k == "union_treasure" then
        --     GameTableDefine.GameLeague:RefreshTreasureForPush(v);
        -- elseif k == "start_event_quests" then
        --     GameInterface:HandleLeonRewardUpdate()
        -- elseif k == "union_treasure_helped_info" then
        --     GameTableDefine.GameLeague:ShowTreasureHelpedHint(v)
        -- elseif k == "new_reward_event_id" then
        --     GameTableDefine.EventCenter:CompleteEventHint(v)
        -- elseif k == "event_round_start" then
        --     local eventcenter = GameTableDefine.GameMainCity:GetEventCenter()
        --     eventcenter:OnNewEventNotificationReceived(v)
        --     --GameInterface:RefreshNewEventButton(true)
        -- elseif k == "new_item" then
        --     GameTableDefine.EventCenter:CollectedMagicStone(responseTable.new_item)
        -- elseif k == "synthetic_new_item" then
        --     GameTableDefine.EventCenter:ShowComplexFindAwards(responseTable.synthetic_new_item)
        -- elseif k == "last_replay" then
        --     GameInterface:CheckBattleReplayNoti(v)
        -- elseif k == "last_at_msgs" then
        --     GameInterfaceChat:HandleNewAtMessage()
        -- elseif k == "ladder_msg" then
        --     --GameTableDefine.GameLadder:SetNoticeData(v)
        -- elseif k == "banner_packs" then
        --     GameDataBase.GameData.banner_packs = {}
        --     GameDataBase:RefreshGlobalData({["banner_packs"] = v})
        -- elseif k == "packs_stauts" then
        --     GameInterface:RefreshDownIconHint()
        -- elseif k == "float_text" then
        --     GameTableDefine.GameWildMenu:HandleStrongholdSubstitutionNoti(v)
        -- elseif k == "throne_status" then
        --     GameInterface:RefreshThroneStatu()
        -- elseif k == "notice_king_policy" or k == "notice_throne_officer" then
        --     GameInterface:CheckThronPostPush()
        -- elseif k == "new_server_name" then
        --     LocalDataManager:UpdateServerName(v)
        -- elseif k == "union_announcement" then
        --     GameInterfaceChat:RefreshAllianceBulletinContent()
        -- elseif k == "union_push_msgs" then
        --     GameInterfaceChat:RefreshChatGuildEventHint()
        -- elseif k == "cs_notice" then
        --     GameInterfaceCustomerService:PushMessage(k)
        -- elseif k == "notices" then
        --     GameInterface:SetServerNoticeInfo(v)
        -- elseif k == "show_notice" then
        --     if GameInterface._noticeGoldenFinger then
        --         GameInterface._noticeGoldenFinger()
        --     end
        -- elseif k == "yunbu_order" then
        --     if GameConfig:IsYunbuVersion()then
        --         GameTableDefine.GameActivity.Yunbu_RecordPay()
        --     end
        -- elseif k == "refresh_time_limited_pack" and v then
        --     GameTableDefine.GameActivity:CheckRefreshDiscountPackList()
        -- elseif k == "dice" then
        --     GameInterfaceChat:Dice_CheckPush(v)
        -- elseif k == "artifacts" then
        --     GameTableDefine.Artifacts:RefreshAll()
        -- elseif k == "mini_game" then
        --     GameTableDefine.BlackJack:PushBlackJackData(v)
        -- elseif k == "city_transferred" then
        --     GameTableDefine.GameEventServerBattle:EventEndTeleport()
        -- elseif k == "server_war_battle_result" then
        --     GameTableDefine.GameEventServerBattle:ShowBattleNews(v)    
        -- elseif k == "shopping_bonus" then
        --     GameTableDefine.EventCenter:ShowSupriseItem(v)
        -- elseif k == "last_order" then
        --     GameTableDefine.GameActivity:Push_EventPurchase(v.item_id,v.channel) 
        -- elseif k == "hud_hint" then
        --     GameTableDefine.GameTopPopupMenu:ShowServerPushMsg(v)
        --     GameDataBase.GameData.hud_hint = nil
        -- elseif k == "pappas_defence" then
        --     GameTableDefine.PapasDefend:StartTimer()
        -- elseif k == "live_messages" then
        --     GameTableDefine.EventCenter:SetDamageTips(v)
        -- elseif k == "event_server_boss"  then
        --     if v.boss_skill then
        --         GameTableDefine.CrossBossData:DelayPlayBossSkill(v.boss_skill)
        --     end
        --     if v.live_messages then
        --         GameTableDefine.EventCenter:SetCrossBossBattleTips()   
        --     end
        --     if v.players then
        --         GameTableDefine.EventCenter:SetCrossBossDamageRank()   
        --     end
        -- elseif k == "round_end_user"  then            
        --     GameTableDefine.CrossBossData:CheckRoundEnd(v)
        -- elseif k == "war_events" then
        --     Guide:BattleEvents(v)
        -- elseif k == "sw_hospital" then 
        --     if not GameStateManager:IsInMainCity() then
        --         return
        --     end
        --     local buidling = GameTableDefine.GameMainCity:GetBuildingObjectByName("angelStatue")
        --     if buidling then
        --         buidling:FX_RefreshBuildingOnCityMap(true)
        --     end
        -- elseif k == "researches" then
        --     GameTableDefine.GameMainCity:FX_RefreshBuildingsDecoration()
        -- elseif k == "buildings" then
        --     GameTableDefine.GameMainCity:RefreshCityByBuildings(v) --wenhao bug #1445
        -- elseif k == "new_soul_item" then
        --     GameTableDefine.GameTopPopupMenu:CheckNewHeroShard() --xjh bug #3152
        -- elseif k == "guide_towers" then
        --     Guide:SetNpcTowerMapData()
        -- elseif k == "action_quests" then
        --     GameSDKs:CheckPlayerAction()
        -- elseif k == "guide" then
        --     Guide:CheckUpdateGuideState()
        -- end     
    end
end

function GameDataBase:IsEquipmentForgedInFactory()
    local server_config = GameDataBase.GameData.server_config
    return tonumber(server_config.army_equip_type or 0) == 1
end

function GameDataBase:AssembleStringWithParams(format, paramTable)
    local result = format
    if GameTextLoader:IsTextID(result) then
        result = GameTextLoader:ReadText(result)
    end
    
    local params = LuaTools:CopyTable(paramTable)
    
    for k, v in pairs(params or {}) do
        if GameTextLoader:IsTextID(v) then
            params[k] = GameTextLoader:ReadText(v)
        end
    end
    
    result = LuaTools:FormatString(result, params[1] or "", params[2] or "", params[3] or "",
    params[4] or "", params[5] or "", params[6] or "")
    
    return result
end