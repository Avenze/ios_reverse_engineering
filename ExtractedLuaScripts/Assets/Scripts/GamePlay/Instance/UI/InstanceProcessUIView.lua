--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-19 13:47:01
]]

local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local FileHelper = CS.Common.Utils.FileHelper
local AnimationUtil = CS.Common.Utils.AnimationUtil
local UnityHelper = CS.Common.Utils.UnityHelper
local Color = CS.UnityEngine.Color

local InstanceDataManager = GameTableDefine.InstanceDataManager
local ConfigMgr = GameTableDefine.ConfigMgr
local InstanceModel = GameTableDefine.InstanceModel

local InstanceProcessUIView = Class("InstanceProcessUIView", UIView)

function InstanceProcessUIView:ctor()
    self.super:ctor()
    self.m_data = {}
    self.resources = {}
end

function InstanceProcessUIView:OnEnter()
    self:SetButtonClickHandler(self:GetComp("RootPanel/RootPanel/HeadPanel/quitBtn","Button"), function()
        self:DestroyModeUIObject()
    end)
    
    self:InitView()
end

function InstanceProcessUIView:OnExit()
    self.super:OnExit(self)
    if self.timer then
        GameTimer:_RemoveTimer(self.timer)
    end
end

function InstanceProcessUIView:InitView()
    local content = self:GetGo("RootPanel/RootPanel/MidPanel/Viewport/Content")
    local resTable = {}
    for k,v in pairs(InstanceDataManager.config_resource_instance) do
        resTable[#resTable + 1] = v
    end
    table.sort(resTable,function (a,b)
        return a.id < b.id
    end)
    local index = 1
    for k,v in pairs(resTable) do
        self.resources[v.id] = self:GetGo(content, tostring(index))
        index = index + 1
    end


    self.productions =  InstanceDataManager:GetProdutionsData()

    self.timer = GameTimer:CreateNewTimer(1,function ()
        self:ShowView()
    end,true,true)
end

function InstanceProcessUIView:ShowView()
    local timeType = InstanceDataManager:GetCurInstanceTimeType()
    for k,v in pairs(self.resources) do
        if k % 6 == 1 or k % 6 == 4 then
            self:GetGo(v,"lineLevel"):SetActive(false)
        end
        for i=1,1 do    --continue
            local issur = self:GetGo(v,"product/issue")
            local locked = self:GetGo(v,"product/locked")
            local producing = self:GetGo(v,"product/producing")
            local lineIssur = self:GetGo(v,"lineLevel/issue")
            local lineLocked = self:GetGo(v,"lineLevel/locked")
            local lineProducing = self:GetGo(v,"lineLevel/producing")
            if InstanceModel:GetResIsUnlock(k) then
                locked:SetActive(false)
                lineLocked:SetActive(false)
            else
                locked:SetActive(true)
                lineLocked:SetActive(true)
                break
            end
            --local material,count = InstanceModel:GetProductionMaterial(k)
            local Production,Consumption = InstanceModel:GetProductionAndConsumptionPerMin(k)
            local shipCD = InstanceModel:GetShipCD(k + 6)
            local portStorage = InstanceModel:GetPortStorage(k)
            local sellRate = portStorage / (shipCD + InstanceDataManager.config_global.instance_ship_loadtime) * 60 -- shipLoadTime是装货需要的固定时间
            Consumption = Consumption + sellRate 
            
            if not InstanceModel:GetLandMarkCanPurchas() then --买了1.5
                local instanceBind = InstanceDataManager:GetInstanceBind()
                local landmarkID = instanceBind.landmark_id
                local shopCfg = ConfigMgr.config_shop[landmarkID]
                local resAdd, timeAdd = shopCfg.param[1], shopCfg.param2[1]
                Production = Production * (1 + resAdd/100)
            end
            local curRoot = nil
            if Production < Consumption then
                issur:SetActive(true)
                lineIssur:SetActive(true)
                producing:SetActive(false)
                lineProducing:SetActive(false)
                curRoot = issur
            else
                issur:SetActive(false)
                lineIssur:SetActive(false)
                producing:SetActive(true)
                lineProducing:SetActive(true)
                curRoot = producing
            end
            local storage = self.productions[tostring(k)] or 0
            --显示界面
            storage = math.floor( storage )
            Production = math.floor( Production )
            Consumption = math.floor( Consumption )
            local storageStr = Tools:SeparateNumberWithComma(storage)
            local productStr = "+"..Tools:SeparateNumberWithComma(Production)
            local consumeStr = "-"..Tools:SeparateNumberWithComma(Consumption)

            local work = self:GetGo(curRoot,"bg/bg/time/work")
            local sleep = self:GetGo(curRoot,"bg/bg/time/sleep")
            local eat = self:GetGo(curRoot,"bg/bg/time/eat")

            if timeType == InstanceDataManager.timeType.sleep then
                self:SetText(curRoot,"bg/title/storage", storageStr)
                self:SetText(curRoot,"bg/state/prodoct/num", "--")
                self:SetText(curRoot,"bg/state/consume/num", consumeStr)
                work:SetActive(false)
                sleep:SetActive(true)
                eat:SetActive(false)
            elseif timeType == InstanceDataManager.timeType.eat then
                self:SetText(curRoot,"bg/title/storage", storageStr)
                self:SetText(curRoot,"bg/state/prodoct/num", "--")
                self:SetText(curRoot,"bg/state/consume/num", consumeStr)
                work:SetActive(false)
                sleep:SetActive(false)
                eat:SetActive(true) 
            elseif timeType == InstanceDataManager.timeType.work then
                self:SetText(curRoot,"bg/title/storage", storageStr)
                self:SetText(curRoot,"bg/state/prodoct/num", productStr)
                self:SetText(curRoot,"bg/state/consume/num", consumeStr)
                work:SetActive(true)
                sleep:SetActive(false)
                eat:SetActive(false)
            end
        end
    end
end


return InstanceProcessUIView
