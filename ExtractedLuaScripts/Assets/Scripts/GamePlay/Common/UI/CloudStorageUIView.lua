local Class = require("Framework.Lua.Class")
local UIView = require("Framework.UI.View")
local EventManager = require("Framework.Event.Manager")
local ViewUtils = require("GamePlay.Utils.ViewUtils")
local GameResMgr = require("GameUtils.GameResManager")

local CloudStorageUI = GameTableDefine.CloudStorageUI

local CloudStorageUIView = Class("CloudStorageUIView", UIView)

function CloudStorageUIView:ctor()
    self.super:ctor()
end

function CloudStorageUIView:OnEnter()
    self.upLoadBtn = self:GetComp("background/BottomPanel/UploadBtn","Button")
    self:SetButtonClickHandler(self.upLoadBtn, function()
        self:SetUploadButtonEnable(false)
        CloudStorageUI:Upload();
    end)

    self.downloadBtn = self:GetComp("background/BottomPanel/LoadBtn","Button")
    self:SetButtonClickHandler(self.downloadBtn, function()
        GameTableDefine.ChooseUI:ShowCloudConfirm("TXT_CLOUDSTORAGE_COMFIRM", function()
            self:SetDownloadButtonEnable(false)
            CloudStorageUI.Download();
        end)
    end)

    self:SetButtonClickHandler(self:GetComp("Bgcover","Button"), function()
        self:DestroyModeUIObject()
    end)
end

function CloudStorageUIView:OnExit()
    self.super:OnExit(self)
end


function CloudStorageUIView:ShowPanel(timeInfo, enableUpLoadBtn, enbleDownloadBtn)
    self:SetText("background/MiddlePanel/time", timeInfo)
    self:SetUploadButtonEnable(enableUpLoadBtn)
    self:SetDownloadButtonEnable(enbleDownloadBtn)
end

function CloudStorageUIView:SetUploadButtonEnable(enable)
    self.upLoadBtn.interactable = enable
end

function CloudStorageUIView:SetDownloadButtonEnable(enable)
    self.downloadBtn.interactable = enable
end

return CloudStorageUIView