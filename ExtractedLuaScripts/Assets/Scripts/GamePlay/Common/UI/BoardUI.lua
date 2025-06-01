--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-11 15:45:43
]]

local BoardUI = GameTableDefine.BoardUI
local GameUIManager = GameTableDefine.GameUIManager
local Application = CS.UnityEngine.Application
local LoadingScreen = GameTableDefine.LoadingScreen
local MainUI = GameTableDefine.MainUI

function BoardUI:GetView()
    self.m_view = GameUIManager:SafeOpenUI(ENUM_GAME_UITYPE.BOARD_UI, self.m_view, require("GamePlay.Common.UI.BoardUIView"), self, self.CloseView)
    return self.m_view
end

function BoardUI:CloseView()
    GameUIManager:CloseUI(ENUM_GAME_UITYPE.BOARD_UI)
    self.m_view = nil
    collectgarbage("collect")
end

function BoardUI:CloseBoardUI(hideFlag)
    if hideFlag then
        local isNotInSave = false
        for _,id in pairs(self.closeBoardIDs) do
            if id == self.currBoardID then
                isNotInSave = true
                break
            end
        end
        if not isNotInSave then
            table.insert(self.closeBoardIDs, self.currBoardID)
            if not LocalDataManager:IsNewPlayerRecord() then
                LocalDataManager:WriteToFile()
            end
        end
    end
    self:CloseView()
    if self.callback then
        self.callback()
    end
end

function BoardUI:InitBoardDisplay(callback)
    self.cacheData = LocalDataManager:GetDataByKey("BoardCache")

    -- LoadingScreen:ShowWaitingEffect();
    self.closeBoardIDs = LocalDataManager:GetDataByKey("NewCloseBoardIDs") or {}
    self.callback = callback
    self.isOverTime = false
    if self.ovetTimeHandler then
        GameTimer:StopTimer(self.ovetTimeHandler)
        self.ovetTimeHandler = nil
    end
    self.ovetTimeHandler = GameTimer:CreateNewTimer(15, handler(BoardUI, BoardUI.BoardGetOverTime))
    if GameConfig:IsWarriorVersion() and not GameDeviceManager:IsEditor() then
        local language = string.upper(GameLanguage:GetCurrentLanguageID())
        GameSDKs:WarriorGetNotice(language, Application.version)
    else
        if self.ovetTimeHandler then
            GameTimer:StopTimer(self.ovetTimeHandler)
            self.ovetTimeHandler = nil
        end
        self.cacheData = {} 
        LocalDataManager:WriteToFile()
        self.cacheData.board = {}
        self.cacheData.unRead = true
        self.thisTime = true
        LocalDataManager:WriteToFile()

        --self:ShowFakeNoticeInEditor()
    end
    -- LoadingScreen:HideWaitingEffect()
    
end

function BoardUI:WarriorNoticeCallback(WarriorNoticeData)
    --TODO记录消息并在主页显示红点提示

    --处理瓦瑞尔的公告返回的相关内容
    --"WarriorNoticeData{instanceID='" + this.instanceID + '\'' + ", title='" + this.title + '\'' + ", content='" + this.content + '\'' + '}'
    -- print("instanceID:"..WarriorNoticeData.instanceID.."content:"..WarriorNoticeData.content)
    if self.isOverTime then
        return
    end
    if self.ovetTimeHandler then
        GameTimer:StopTimer(self.ovetTimeHandler)
        self.ovetTimeHandler = nil
    end
    -- LoadingScreen:HideWaitingEffect()
    if WarriorNoticeData.instanceID and WarriorNoticeData.instanceID ~= "" and
    WarriorNoticeData.content and WarriorNoticeData.content ~= "" and 
    WarriorNoticeData.title and WarriorNoticeData.title ~= "" then
        self.currBoardID = tonumber(WarriorNoticeData.instanceID)
        if self.currBoardID then
            local isInSave = false
            for _, id in pairs(self.closeBoardIDs) do
                if id == self.currBoardID then
                    isInSave = true
                    break
                end
            end
            if not isInSave then
                print("WarriorNoticeCallback:"..WarriorNoticeData.content)
                --不立即显示界面,先缓存公告数据
                self.cacheData = {} 
                LocalDataManager:WriteToFile()

                self.cacheData["board"] = WarriorNoticeData
                self.cacheData["unRead"] = true
                LocalDataManager:WriteToFile()
                self.thisTime = true
                MainUI:RefreshBoardUnread()

                return
            end
        end
    else
        
    end
    print("服务器返回的公告数据无效，直接执行下面流程")
    if self.callback then
        self.callback()
    end
end

function BoardUI:BoardGetOverTime()
    -- LoadingScreen:HideWaitingEffect()
    
    self.isOverTime = true
    if self.ovetTimeHandler then
        GameTimer:StopTimer(self.ovetTimeHandler)
        self.ovetTimeHandler = nil
    end
    self:CloseView() 
    if self.callback then
        self.callback()
    end
end


function BoardUI:ShowView()
    if GameConfig:IsWarriorVersion() and not GameDeviceManager:IsEditor() then
        self.cacheData = self.cacheData or {}
        self.cacheData.board = self.cacheData.board or {}
        self.cacheData.unRead = self.cacheData.unRead or false
        self.cacheData.board.title = self.cacheData.board.title or "Error"
        self.cacheData.board.content = self.cacheData.board.content or "no content"
        self:GetView():Invoke("UpdateContent", self.cacheData.board.title, self.cacheData.board.content)
    else
        self.currBoardID = 1
        local msg = GameTextLoader:ReadText("TXT_HELP_RENT")
        local content = "3.员工心情高兴的时候，还有几率<color=#F2B923><size=150%>爆气</color><size=100%>，极大提升公司发展哦！\\n租金构成:\n公司:<color=#388cff>%s</color>\\n设施:<color=#388cff>%s</color>"
        self:GetView():Invoke("UpdateContent", msg, content)

        print("BoardUI:GetViewToDisplay")
  
    end
end
