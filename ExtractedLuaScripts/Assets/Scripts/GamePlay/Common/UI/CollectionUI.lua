local CollectionUI = GameTableDefine.CollectionUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr
local EventManager = require("Framework.Event.Manager")

local COLLECTION_DATA = "collection_data"
local COMPANY_INVITE_SAVE = "company_invite_save"

local ResMgr = GameTableDefine.ResourceManger
local CompanyMapInfoUI = GameTableDefine.CompanyMapInfoUI
local MainUI = GameTableDefine.MainUI

function CollectionUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.COLLECTION_UI, self.m_view, require("GamePlay.Common.UI.CollectionUIView"), self, self.CloseView)
    return self.m_view
end

function CollectionUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.COLLECTION_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function CollectionUI:Refresh()
    local companyConfig = ConfigMgr.config_company
    local data,unlockNum,rewardAble = self:CalculateData()

    self:GetView():Invoke("RefreshTitle", unlockNum, #companyConfig)
    self:GetView():Invoke("Refresh", data)
    
    -- self:GetView():Invoke("RefreshEmployee")
    self:GetView():Invoke("RefreshPet")
    -- if GameConfig:IsIAP() then
    --     self:GetView():Invoke("RefreshEmployee")
    --     self:GetView():Invoke("RefreshPet")
    -- else
    --     self:GetView():Invoke("CloseIAP")
    -- end
    return rewardAble
end

function CollectionUI:CalculateData(companyId)
    local data = {}
    local unlockNum = 0
    local collectionHint = false--是否红点
    local companyConfig = ConfigMgr.config_company
    local needSave = false
    
    if not self.save then
        self.save = LocalDataManager:GetDataByKey(COLLECTION_DATA)
    end
    if not self.save.reward then
        self.save.reward = {}
    end

    if not self.inviteData then
        self.inviteData = LocalDataManager:GetDataByKey(COMPANY_INVITE_SAVE)
    end
    if not self.inviteData.companyLv then
        self.inviteData.companyLv = {}
    end

    local getDataByCompanyId = function(companyId)
        local cfg = companyConfig[companyId]
        local getRewardTo = self.save.reward["ID"..companyId] or 0
        local lastLv = self.inviteData.companyLv["ID"..companyId] or 0--只要是招募了的,就是1级

        local realRewardTo = getRewardTo
        local canReward = false

        for i = getRewardTo + 1, lastLv do
            if cfg.unlockReward[i] and cfg.unlockReward[i] ~= 0 then
                --self.save.reward["ID"..companyId] = i
                realRewardTo = i
                canReward = true
                break
            end
        end

        return {id = companyId, lv = lastLv, rewardTo = realRewardTo, rewardAble = canReward}
    end

    if not companyId then
        for companyId, value in pairs(companyConfig) do
            local result = getDataByCompanyId(companyId)
            table.insert(data, result)
            
            if result.lv > 0 then
                unlockNum = unlockNum + 1
            end

            if result.rewardAble and not collectionHint then
                collectionHint = true
            end
        end
    else
        local result = getDataByCompanyId(companyId)
        return result
    end

    return data,unlockNum,collectionHint
end

function CollectionUI:GetReward(companyId, rewardIndex, callback)
    local lastLv = self.inviteData.companyLv["ID"..companyId] or 0
    --local getRewardTo = self.save.reward["ID"..companyId] or 0
    if lastLv < rewardIndex then--不能够领取
        return false
    end

    local cfg = ConfigMgr.config_company[companyId]
    local unlock = cfg.unlockReward[rewardIndex]
    ResMgr:Add(unlock[1], unlock[2], nil, function()
        self.save.reward["ID"..companyId] = rewardIndex
        LocalDataManager:WriteToFile()

        if callback then callback() end

        local data = self:CalculateData(companyId)

        CompanyMapInfoUI:Refresh(data, cfg)--领奖界面刷新
        local rewardAble = self:Refresh()--图鉴界面刷新,如果可以局部刷新就更好了,但好像只可以整个update
        MainUI:RefreshCollectionHint(rewardAble)

    end, true)
    if unlock[3] then
        ResMgr:Add(unlock[3], unlock[4], nil, nil, true)
    end

end

function CollectionUI:Hideing(reverse)
    self:GetView():Invoke("Hideing",reverse)
end