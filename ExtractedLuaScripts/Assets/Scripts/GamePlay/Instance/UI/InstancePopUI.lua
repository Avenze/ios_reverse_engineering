--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-05-16 10:21:16
]]
local InstancePopUI = GameTableDefine.InstancePopUI

local GameUIManager = GameTableDefine.GameUIManager
local ConfigMgr = GameTableDefine.ConfigMgr

function InstancePopUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.INSTANCE_POP_UI, self.m_view, require("GamePlay.Instance.UI.InstancePopUIView"), self, self.CloseView)
    return self.m_view
end

function InstancePopUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.INSTANCE_POP_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function InstancePopUI:ShowGiftPop(shopID)
    -- if not self.m_view then
    --     return
    -- end
    self:GetView():Invoke("ShowGiftPop", shopID)
    self.saveShowID = 0
end

function InstancePopUI:CheckGiftPopShow()
    if self.saveShowID and self.saveShowID > 0 then
        self:ShowGiftPop(self.saveShowID)
    end
end

function InstancePopUI:SetSaveShowID(shopID)
    self.saveShowID = shopID
end

function InstancePopUI:InstanceLevelUpdate(curLvl)

end