local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local GameObject = CS.UnityEngine.GameObject
local ConfigMgr = GameTableDefine.ConfigMgr
local ActivityRankDataManager = GameTableDefine.ActivityRankDataManager
local ShopManager = GameTableDefine.ShopManager
local ActivityRankRewardGetUIView = Class("ActivityRankUIView", UIView)

function ActivityRankRewardGetUIView:ctor()
    self.super:ctor()
end

function ActivityRankRewardGetUIView:OnEnter()
    self:GetGo("RootPanel/reward"):SetActive(false)
    self:GetGo("RootPanel/noreward"):SetActive(false)
    self:SetButtonClickHandler(self:GetComp("RootPanel/claimBtn", "Button"), function()
        ActivityRankDataManager:ReallyGetRankReward()
    end)
end

function ActivityRankRewardGetUIView:ShowRewardItem(giftID)
    self:GetGo("RootPanel/reward"):SetActive(true)
    self:GetGo("RootPanel/noreward"):SetActive(false)
    self:SetTempGo("RootPanel/reward/item1", function(index, go, cfg)
        self:SetTemp(index, go, cfg)
    end, ConfigMgr.config_shop[giftID])
end

function ActivityRankRewardGetUIView:ShowNoRewardInfo()
    self:GetGo("RootPanel/reward"):SetActive(false)
    self:GetGo("RootPanel/noreward"):SetActive(true)
end


--获得节点组件并复制多个生成,通过cb对其内容进行特殊的设置
function ActivityRankRewardGetUIView:SetTempGo(path , cb, cfgGiftBag)
    if not cfgGiftBag then
        return
    end
    local temp = self:GetGo(path)
    temp:SetActive(false)
    local parent = temp.transform.parent.gameObject
    
    for i=1, 5 do
        local go
        if self:GetGoOrNil(parent, "item" .. i ) then
            go = self:GetGo(parent, "item" .. i )
        else
            go = GameObject.Instantiate(temp, parent.transform)
        end
        if cfgGiftBag.param then
            local cfg = ConfigMgr.config_shop[cfgGiftBag.param[i]]
            go.name = "temp" .. i
            go:SetActive(true)
            if not cfg then
                go:SetActive(false)
            else
                cb(i, go, cfg)
            end 
        end                                     
    end          
end

--对单个temp进行设置
function ActivityRankRewardGetUIView:SetTemp(index, go, cfg)    
    local value = ShopManager:GetValue(cfg)
    local icon = self:GetComp(go, "icon", "Image")
    if  type(value) == "number" then
        self:SetText(go, "num", Tools:SeparateNumberWithComma(value))
    else
        self:SetText(go, "num", "1")
    end        
    self:SetSprite(icon, "UI_Shop", cfg.icon, nil, true) 
end



function ActivityRankRewardGetUIView:OnExit()

end




return ActivityRankRewardGetUIView