local Class = require("Framework.Lua.Class")
---@class UIBaseView
local UIBaseView = Class("UIBaseView")
local GameResMgr = require("GameUtils.GameResManager")
local EventManager = require("Framework.Event.Manager")

local User = GameTableDefine.User
local GameInterface = GameTableDefine.GameInterface
local GameExteriorImgManager = GameTableDefine.GameExteriorImgManager
local SoundEngine = GameTableDefine.SoundEngine
local GuideManager = GameTableDefine.GuideManager
local Guide = GameTableDefine.Guide

local AnimationUtil = CS.Common.Utils.AnimationUtil
local ParticleSystemRenderer = CS.UnityEngine.ParticleSystemRenderer
local UnityHelper = CS.Common.Utils.UnityHelper
local EventType = CS.UnityEngine.EventSystems.EventTriggerType
local EventTriggerListener = CS.Common.Utils.EventTriggerListener

local ENUM_STATUS = 
{
    INITIALIZE  = 1,
    LOADING     = 2,
    OPENED      = 3,
    CLOSED      = 4,
}
UIBaseView.ENUM_STATUS = ENUM_STATUS

function UIBaseView:ctor()
    self.m_status = ENUM_STATUS.INITIALIZE
    self.__listeners = self.__listeners or {}
    self.__listeners[self] = {}                -- 设置的监听要在界面关闭时消除
    self.__extends = self.__extends or {}
    self.__extends[self] = {}                  -- 界面的所有扩展
    self.__buttons = self.__buttons or {}
    self.__buttons[self] = {}
    self.__toggles = self.__toggles or {}
    self.__toggles[self] = {}
    self.__dropdowns = self.__dropdowns or {}
    self.__dropdowns[self] = {}
    self.__inputs = self.__inputs or {}
    self.__inputs[self] = {}
    self.__sliders = self.__sliders or {}
    self.__sliders[self] = {}
    self.__lists = self.__lists or {}
    self.__timers = self.__timers or {}
    self.__timers[self] = nil
    self.__cmd_pool = {}                        -- 等待执行的命令列表
    self.__cmd_pool[self] = {}
    self.__dialogues = self.__dialogues or {}
    self.__animations = self.__animations or {}
    self.__chanageLanguageCompleteCallback = self.__chanageLanguageCompleteCallback or {}
end

function UIBaseView:SetStatus(status)
    self.m_status = status
end

function UIBaseView:IsValid()
    return self.m_status ~= ENUM_STATUS.CLOSED
end

function UIBaseView:IsLoaded()
    return self.m_status == ENUM_STATUS.OPENED
end

function UIBaseView:IsLoading()
    return self.m_status == ENUM_STATUS.LOADING
end

function UIBaseView:SetUIType(uiType)
    self.m_uiType = uiType
end

function UIBaseView:GetUIType()
    return self.m_uiType
end

function UIBaseView:SetUIObj(uiObj)
    self.m_uiObj = uiObj ---@type UnityEngine.GameObject
end

function UIBaseView:GetUIObj()
    return self.m_uiObj
end

function UIBaseView:Preoad()
    --print("UIBaseView:Preoad")
end

function UIBaseView:OnEnter()
    --print("UIBaseView:OnEnter")
end

function UIBaseView:OnPause()
    --print("UIBaseView:OnPause")
end

function UIBaseView:OnResume()
    --print("UIBaseView:OnResume")
end

function UIBaseView:OnExit(view)
    -- print("UIBaseView:OnExit", view)
    -- Tools:DumpTable(self.__listeners, "UIBaseView:OnExit __listeners")

    self:StopTimerByView(view)
    
    -- 清理扩展
    for class, extend in pairs(self.__extends[view] or {}) do
        view:RemoveExtend(class)
    end
    
    for go, t in pairs(self.__listeners[view] or {}) do
        for eventType in pairs(t) do
            if not go:IsNull() then
                --print("Remove EventHandle", go.name, eventType)
                EventTriggerListener.Get(go):SetEventHandle(eventType, nil)
            end
        end
    end
    self.__listeners[view] = nil

    for button, handler in pairs(self.__buttons[view] or {}) do
        if not button:IsNull() then
            --print("Remove Button Handle", button.name)
            button.onClick:RemoveAllListeners()
            button.onClick = nil
            if button.onHold then
                --button.onHold:RemoveAllListeners()
                button.onHold = nil
            end
        end
    end
    self.__buttons[view] = nil

    -- print("Remove Toggles")
    for toggle, handler in pairs(self.__toggles[view] or {}) do
        if not toggle:IsNull() then
            --print("Remove Toggle Handle", toggle.name)
            toggle.onValueChanged:RemoveAllListeners()
            toggle.onValueChanged = nil
        end
    end
    self.__toggles[view] = nil

    for input, handler in pairs(self.__inputs[view] or {}) do
        if not input:IsNull() then
            --print("Remove TMP_InputField Handle", input.name)
            input.onValueChanged:RemoveAllListeners()
            input.onValueChanged = nil
            
            input.onEndEdit:RemoveAllListeners()
            input.onEndEdit = nil
        end
    end
    self.__inputs[view] = nil

    for slider, handler in pairs(self.__sliders[view] or {}) do
        if not slider:IsNull() then
            --print("Remove Slider Handle", slider.name)
            slider.onValueChanged:RemoveAllListeners()
            slider.onValueChanged = nil
        end
    end
    self.__sliders[view] = nil

    for helper, handler in pairs(self.__dialogues[view] or {}) do
        helper(handler, true)
    end
    self.__dialogues[view] = nil

    for animKeyFrame, v in pairs(self.__animations[view] or {}) do
        if not animKeyFrame:IsNull() then
            animKeyFrame:OnDestroy()
        end
    end
    self.__animations[view] = nil
    
    for dropdown, handler in pairs(self.__dropdowns[view] or {}) do
        if not dropdown:IsNull() then
            --print("Remove Dropdown Handle", dropdown.name)
            dropdown.onValueChanged:RemoveAllListeners()
            dropdown.onValueChanged = nil
        end
    end
    self.__dropdowns[view] = nil

    for list, handler in pairs(self.__lists[view] or {}) do
        if not list:IsNull() then
            --print("Remove list Handle", list.name)
            list:SetItemCountFunc(nil)
            list:SetItemNameFunc(nil)
            list:SetItemSizeFunc(nil)
            list:SetUpdateFunc(nil)
            list:SetSnapMoveDoneFunc(nil)
            list:SetLayoutFunc(nil)
            list:SetOnScrollFunc(nil)
        end
    end
    self.__lists[view] = nil

    self.__chanageLanguageCompleteCallback[view] = nil

    view.m_modeObj = nil
    view.m_modeCloseFunction = nil
    view.m_androidKeyBackEventButon = nil
    view:SendGuideEvent(GuideManager.EVENT_VIEW_CLOSED)
    -- 释放界面持有资源
    GameResMgr:Unload(view)
end

local function _clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function UIBaseView:InsertExtend(class)
    if not class then return end
    
    self.__extends[self] = self.__extends[self] or {}
    local extends = self.__extends[self]

    if extends[class] then
        --lprintf("Already exist extend! name is %s!", class)
        return
    end

    local extend = require(class)
    if not extend then return end
    extends[class] = extend
    for k, v in pairs(extend) do
        if not self[k] 
                and k ~= "OnInsertExtend" 
                and k ~= "OnRemoveExtend" then
            self[k] = _clone(v)
        end
    end
    extend.OnInsertExtend(self)
end

function UIBaseView:RemoveExtend(class)
    if not class then return end

    self.__extends[self] = self.__extends[self] or {}
    local extends = self.__extends[self]

    if not extends[class] then
        --lprintf("Not exist extend! name is %s!", class)
        return
    end

    local extend = require(class)
    if not extend then return end

    extend.OnRemoveExtend(self)
    for k, v in pairs(extend) do
        self[k] = nil
    end
    extends[class] = nil
end

function UIBaseView:UpdateAllParticle(isActive)
    if not self.m_uiObj then return end
    if isActive and not self.m_orderParticle then return end

    local arr = self.m_uiObj.transform:GetComponentsInChildren(typeof(ParticleSystemRenderer))
    --print("UpdateAllParticle", isActive, arr.Length)
    local orderParticle = self.m_orderParticle or {}
    for i = 0, arr.Length-1 do
        local psr = arr[i]
        if isActive then
            psr.sortingOrder = orderParticle[psr] or 1
        else
            orderParticle[psr] = psr.sortingOrder
            psr.sortingOrder = 0
        end
    end

    self.m_orderParticle = orderParticle
end

function UIBaseView:SetEventHandler(go, eventType, eventHandler)
    --print("SetEventHandle", go.name, eventType)
    EventTriggerListener.Get(go):SetEventHandle(eventType, eventHandler)
    self.__listeners = self.__listeners or {}
    self.__listeners[self] = self.__listeners[self] or {}
    self.__listeners[self][go] = self.__listeners[self][go] or {}
    self.__listeners[self][go][eventType] = eventHandler
end

function UIBaseView:SetClickHandler(widget, handler, sfxURL)
    if not widget then
        error(debug.traceback("widget is nil"))
    end
    local cb = handler
    if sfxURL ~= "" then -- widget.GetType and widget:GetType().Name == "Button" and
        sfxURL = sfxURL or SoundEngine.BUTTON_CLICK_SFX
        cb = function( ... )
            SoundEngine:PlaySFX(sfxURL)
            handler(...)
        end
    end
    self:SetEventHandler(widget.gameObject, EventType.PointerClick, cb)
end

function UIBaseView:InvokeClickHandler(widget)
    if not widget then
        error(debug.traceback("widget is nil"))
    end
    EventTriggerListener.Get(widget.gameObject):OnPointerClick()
end

function UIBaseView:SetButtonClickHandler(button, handler, sfxURL, ...)
    
    if not button or not button.GetType or (button:GetType().Name ~= "Button" and button:GetType().Name ~= "ButtonEx") then
        --print("button field must be 'Button' type!")
        return
    end
    
    local cb = handler
    if sfxURL ~= "" then
        local defaultAudio = button:GetType().Name == "Button" and SoundEngine.BUTTON_CLICK_SFX or SoundEngine.BUTTONEX_CLICK_SFX
        sfxURL = sfxURL or defaultAudio
        local arg = {...}
        cb = function()
            if UnityHelper.ProccessButtonCoolDown(button) then
                return
            end
            SoundEngine:PlaySFX(sfxURL)
            handler(arg)
        end
    end
    UnityHelper.SetButtonClickHandler(button, cb)
    -- button.onClick:RemoveAllListeners()
    -- button.onClick:AddListener(cb)
    self.__buttons = self.__buttons or {}
    self.__buttons[self] = self.__buttons[self] or {}
    self.__buttons[self][button] = cb
end

function UIBaseView:SetButtonHoldHandler(buttonEx, handler, sfxURL, holdTime, interval, ...)
    
    if not buttonEx or not buttonEx.GetType or (buttonEx:GetType().Name ~= "Button" and buttonEx:GetType().Name ~= "ButtonEx") then
        --print("button field must be 'Button' type!")
        return
    end

    holdTime = holdTime or 1
    interval = interval or 0.2

    local cb = handler
    if sfxURL ~= "" then
        sfxURL = sfxURL or SoundEngine.BUTTONEX_CLICK_SFX
        local arg = {...}
        cb = function()
            SoundEngine:PlaySFX(sfxURL)
            handler(arg)
        end
    end
    UnityHelper.SetButtonHoldHandler(buttonEx, cb, holdTime, interval)
    -- button.onClick:RemoveAllListeners()
    -- button.onClick:AddListener(cb)
    self.__buttons = self.__buttons or {}
    self.__buttons[self] = self.__buttons[self] or {}
    self.__buttons[self][buttonEx] = cb
end

function UIBaseView:SetToggleValueChangeHandler(toggle, handler)
    if not toggle or not toggle.GetType or toggle:GetType().Name ~= "Toggle" then
        --print("toggle field must be 'Toggle' type!")
        return
    end

    UnityHelper.SetToggleValueChangeHandler(toggle, handler)

    self.__toggles = self.__toggles or {}
    self.__toggles[self] = self.__toggles[self] or {}
    self.__toggles[self][toggle] = handler
end

function UIBaseView:SetTMPInputValueChangeHandler(input, handler)
    if not input or not input.GetType or input:GetType().Name ~= "TMP_InputField" then
        --print("input field must be 'TMP_InputField' type!")
        return
    end

    UnityHelper.SetTMPInputValueChangeHandler(input, handler)

    self.__inputs = self.__inputs or {}
    self.__inputs[self] = self.__inputs[self] or {}
    self.__inputs[self][input] = handler
end

function UIBaseView:SetTMPInputEndEditHandler(input, handler)
    if not input or not input.GetType or input:GetType().Name ~= "TMP_InputField" then
        --print("input field must be 'TMP_InputField' type!")
        return
    end

    UnityHelper.SetTMPInputEndEditHandler(input, handler)

    self.__inputs = self.__inputs or {}
    self.__inputs[self] = self.__inputs[self] or {}
    self.__inputs[self][input] = handler
end

function UIBaseView:SetSliderValueChangeHandler(slider, handler)
    if not slider or not slider.GetType or slider:GetType().Name ~= "Slider" then
        --print("slider field must be 'Slider' type!")
        return
    end

    UnityHelper.SetSliderValueChangeHandler(slider, handler)

    self.__sliders = self.__sliders or {}
    self.__sliders[self] = self.__sliders[self] or {}
    self.__sliders[self][slider] = handler
end

function UIBaseView:SetDialogueStartedHandler(handler)
    self.__dialogues[self] = self.__dialogues[self] or {}
    if not self.__dialogues[self][UnityHelper.OnDialogueStarted] then
        self.__dialogues[self][UnityHelper.OnDialogueStarted] = handler
        UnityHelper.OnDialogueStarted(handler)
    end
end

function UIBaseView:SetDialoguePausedHandler(handler)
    self.__dialogues[self] = self.__dialogues[self] or {}
    if not self.__dialogues[self][UnityHelper.OnDialoguePaused] then
        self.__dialogues[self][UnityHelper.OnDialoguePaused] = handler
        UnityHelper.OnDialoguePaused(handler)
    end
end

function UIBaseView:SetDialogueFinishedHandler(handler)
    self.__dialogues[self] = self.__dialogues[self] or {}
    if not self.__dialogues[self][UnityHelper.OnDialogueFinished] then
        self.__dialogues[self][UnityHelper.OnDialogueFinished] = handler
        UnityHelper.OnDialogueFinished(handler)
    end
end

function UIBaseView:SetDialogueSubtitlesRequestHandler(handler)
    self.__dialogues[self] = self.__dialogues[self] or {}
    if not self.__dialogues[self][UnityHelper.OnSubtitlesRequest] then
        self.__dialogues[self][UnityHelper.OnSubtitlesRequest] = handler
        UnityHelper.OnSubtitlesRequest(handler)
    end
end

function UIBaseView:SetDialogueMultipleChoiceRequestHandler(handler)
    self.__dialogues[self] = self.__dialogues[self] or {}
    if not self.__dialogues[self][UnityHelper.OnMultipleChoiceRequest] then
        self.__dialogues[self][UnityHelper.OnMultipleChoiceRequest] = handler
        UnityHelper.OnMultipleChoiceRequest(handler)
    end
end

-- function UIBaseView:CloseDialogueTree()
--     if self.__dialogues[1] then
--         UnityHelper.OnDialoguePaused(self.__dialogues[1], true)
--         self.__dialogues[1] = nil
--     end
--     if self.__dialogues[2] then
--         UnityHelper.OnDialogueFinished(self.__dialogues[2], true)
--         self.__dialogues[2] = nil
--     end
--     if self.__dialogues[3] then
--         UnityHelper.OnSubtitlesRequest(self.__dialogues[3], true)
--         self.__dialogues[3] = nil
--     end
--     if self.__dialogues[4] then
--         UnityHelper.OnMultipleChoiceRequest(self.__dialogues[4], true)
--         self.__dialogues[4] = nil
--     end
--     if self.__dialogues[5] then
--         UnityHelper.OnDialogueStarted(self.__dialogues[5], true)
--         self.__dialogues[5] = nil
--     end
--     self.__dialogues = {}
-- end

function UIBaseView:SetDropdownValueChangeHandler(dropdown, handler)
    if not dropdown or not dropdown.GetType or dropdown:GetType().Name ~= "TMP_Dropdown" then
        --print("dropdown field must be 'Dropdown' type!")
        return
    end

    UnityHelper.SetDropdownValueChangeHandler(dropdown, handler)

    self.__dropdowns = self.__dropdowns or {}
    self.__dropdowns[self] = self.__dropdowns[self] or {}
    self.__dropdowns[self][dropdown] = handler
end

function UIBaseView:SetDropdownText(dropdown, index, Text)
    if not dropdown or not dropdown.GetType or dropdown:GetType().Name ~= "TMP_Dropdown" then
        --print("dropdown field must be 'Dropdown' type!")
        return
    end

    dropdown.options[index-1].text = Text
    dropdown:RefreshShownValue()
end

function UIBaseView:SetListItemCountFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'ScrollRectEx' type!", list:GetType().Name)
        return
    end

    list:SetItemCountFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._countFunc = handler
end

function UIBaseView:SetListItemNameFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:SetItemNameFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._nameFunc = handler
end

function UIBaseView:SetListItemSizeFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:SetItemSizeFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._sizeFunc = handler
end

function UIBaseView:SetListLayoutFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:SetLayoutFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._layoutFunc = handler
end

function UIBaseView:SetListScrollFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:SetOnScrollFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._ListScrollFunc = handler
end

function UIBaseView:ScrollTo(list, index)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:ScrollTo(index)
end

function UIBaseView:SetListUpdateFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:SetUpdateFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._updateFunc = handler
end

function UIBaseView:SetSnapMoveDoneFunc(list, handler)
    if not list or not list.GetType or list:GetType().Name ~= "ScrollRectEx" then
        --print("list field must be 'List' type!")
        return
    end

    list:SetSnapMoveDoneFunc(handler)

    self.__lists = self.__lists or {}
    self.__lists[self] = self.__lists[self] or {}
    self.__lists[self][list] = self.__lists[self][list] or {}
    self.__lists[self][list]._snapMoveDone = handler
end

function UIBaseView:PreloadSpriteAltas(atlas, isSync, cb)
    GameResMgr:PreloadSpriteAltas(atlas, isSync, self, cb)
end

function UIBaseView:SetSprite(image, atlas, name, cb, isSync,hideBeforeLoad)
    if not image or not image.GetType or image:GetType().Name ~= "Image" then
        --print("image field must be 'Image' type!")
        return
    end

    if not atlas or not name then
        --print("atlas and name fields must be string!")
        return
    end
    if image.sprite and not image.sprite:IsNull() and image.sprite.name == name then
        return
    end

    local address = string.format("Assets/Res/SpriteAltas/%s.spriteatlas", atlas)
    if hideBeforeLoad then
        image.enabled = false
    end
    local callback = function(handler)
        if hideBeforeLoad then
            image.enabled = true
        end
        if image:IsNull() then return end
        
        local sprite = handler.Result:GetSprite(name)
        if not sprite then return end
        
        --print("SetSprite", image, sprite, handler.Status)
        image.sprite = sprite
        sprite.name = name
        if not cb then return end
        cb()
    end

    if isSync then
        local handler = GameResMgr:LoadSpriteSyncFree(address, self)
        callback(handler)
    else
        GameResMgr:ALoadAsync(address, self, callback)
    end
end

function UIBaseView:SetHead(image, data)
    if not image or not image.GetType or image:GetType().Name ~= "Image" then
        --print("image field must be 'Image' type!")
        return
    end
    if not data then return end

    local headIcon = User:GetHeadIcon(data.head)
    local useCustom, imgName = User:GetCustomPortrait(data)
    
    self:SetSprite(image, "UI_Player", headIcon, function()
        --print("useCustom", useCustom, imgName, data.head)
        if not useCustom then return end
        GameExteriorImgManager:GetExteriorImage(imgName, function()
            if not image or image:IsNull() then return end
            local sprite = UnityHelper.LoadSpriteByExternFile(imgName, 72, 72)
            image.sprite = sprite
        end)
    end)

    -- 附带设置头像框
    self:SetAvatar(UnityHelper.GetTheChildComponent(image.transform.parent.gameObject, "AvatarFramesAll", "FrameGroup"), data)
end

function UIBaseView:SetAvatar(frameGroup, data)
    if not frameGroup or not frameGroup.GetType or frameGroup:GetType().Name ~= "FrameGroup" then
        --print("frameGroup field must be 'FrameGroup' type!")
        return
    end
    if not data then return end
    local avatar = User:GetAvatarFrameIcon(data.avatar_frame, data.is_gm)
    -- print("SetAvatar", frameGroup, data.avatar_frame, avatar)
    frameGroup:SetFrameByName(avatar)
end

function UIBaseView:GetWidgetSize(widget)   
    if not widget then return end
    local typeName = widget:GetType().Name
    local size = {}
    if "Text" == typeName then
        size.width = widget.transform.rect.width
        size.height = widget.preferredHeight
    elseif "TextMeshProUGUI" == typeName or "TMPLocalization" == typeName then
        local crt = widget.gameObject.transform
        local real = widget:GetPreferredValues(widget.text, crt.rect.width, crt.rect.height)
        size.width = math.min(real.x, widget.transform.rect.width)
        size.height = real.y
    else
        local rect = widget.transform.rect
        size.width = rect.width
        size.height = rect.height
    end
    return size
end

function UIBaseView:ArrangeWidget(widgets, horizonal, padding)
    if "table" ~= type(widgets) or #widgets < 1 then return end
    local horizonal = (nil == horizonal) and true or horizonal
    local padding = padding or 0

    local first = widgets[1]
    local pos = first.transform.anchoredPosition
    local pivot = first.transform.pivot
    
    --print("ArrangeWidget", 1, pos)
    --print("ArrangeWidget", horizonal)
    local offset = {x = 0, y = 0}
    for i, widget in ipairs(widgets) do
        local size = self:GetWidgetSize(widget)
        local rect = widget.transform.rect
        --print("ArrangeWidget size", i, size.width, size.height,rect.width)
        if i > 1 then
            if horizonal then
                pos.x = pos.x + rect.width * pivot.x + offset.x
            else
                pos.y = pos.y - rect.height * pivot.y - offset.y
            end

            local _pivot = widget.transform.pivot
            local fixed = {
                x = pos.x + (pivot.x - _pivot.x) * rect.width,
                y = pos.y - (pivot.y - _pivot.y) * rect.height
            }
            -- print("ArrangeWidget offset", i, offset.x, offset.y)
            -- print("ArrangeWidget fixed", i, fixed.x, fixed.y)
            widget.transform.anchoredPosition = fixed
        end
        
        if horizonal then
            pos.x = pos.x + rect.width * (1 - pivot.x) + padding
            offset.x = size.width - rect.width
        else
            pos.y = pos.y - rect.height * (1 - pivot.y) - padding
            offset.y = size.height - rect.height
        end
    end
end

    function UIBaseView:Invoke(cmd, ...)
    if self.m_uiObj then
        if self.m_uiObj:IsNull() then --uiObj 已经被删除了
            return
        end
        if not self[cmd] then
            printError(self.__cname..",找不到方法:"..cmd)
            return
        end
        self[cmd](self, ...)
    else
         local args = {...}
        local max = 0
        for k, v in pairs(args) do
            if k > max then
                max = k
            end
        end
        self.__cmd_pool = self.__cmd_pool or {}
        self.__cmd_pool[self] = self.__cmd_pool[self] or {}
        table.insert(self.__cmd_pool[self], {cmd = cmd, args = {...}, cnt = max})
    end
end

function UIBaseView:ClearCmdPool()
    for _, v in ipairs(self.__cmd_pool[self] or {}) do
        local f = self[v.cmd]
        local a = v.args
        assert(f, "try to invoke not exsit function name is ".. v.cmd)
        f(self, table.unpack(a, 1, v.cnt))
    end
    self.__cmd_pool[self] = nil
end

function UIBaseView:CreateTimer(intervalInMilliSec, func, isLoop, execImmediately, isRestart)
    if self.__timers[self] then
        if isRestart then
            self:StopTimer()
        else
            return
        end
    end
    if isLoop then
        self.__timers[self] = GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, isLoop, execImmediately)
    else
        GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, false, execImmediately)
    end
end

function UIBaseView:StopTimerByView(view)
    if self.__timers[view] then
        GameTimer:StopTimer(self.__timers[view])
        self.__timers[view] = nil
    end
end

function UIBaseView:StopTimer()
    if self.__timers[self] then
        GameTimer:StopTimer(self.__timers[self])
        self.__timers[self] = nil
    end
end

---@return UnityEngine.Transform
function UIBaseView:GetTrans(obj, child)
    if type(obj) == "string" then
        child = obj
        obj = self.m_uiObj
    end

    if not child then
        error(debug.traceback("parms is nil"))
    end
    if type(obj) ~= "userdata" then
        error(debug.traceback("obj type is not userdata"))
    end
    return UnityHelper.FindTheChild(obj, child)
end

---@return UnityEngine.GameObject
function UIBaseView:GetGo(obj, child)
    local tran = self:GetTrans(obj, child)
    if not tran then
        child = child or "nil"
        error(debug.traceback("Object transform:[".. (obj.name or "nil").."]   child:["..child.."]  is nil"))
    else
        return tran.gameObject
    end
end

---@return UnityEngine.GameObject
function UIBaseView:GetGoOrNil(obj, child)
    local tran = self:GetTrans(obj, child)
    if not tran then
        return nil
    else
        return tran.gameObject
    end
end

---@param obj UnityEngine.GameObject|string
function UIBaseView:GetComp(obj, child, uiType)
    if type(obj) == "string" then
        uiType = child
        child = obj
        obj = self.m_uiObj
    end

    if not child or not uiType then
        error(debug.traceback("parms is nil"))
    end
    if type(obj) ~= "userdata" then
        error(debug.traceback("obj type is not userdata"))
    end
    return UnityHelper.GetTheChildComponent(obj, child, uiType)
end

function UIBaseView:SetText(go, child, text, color, material, is3d)
    if type(go) == "string" then
        material = color
        color = text
        text = child
        child = go
        go = self.m_uiObj
    end

    assert(child ~= nil, "parms is nil")
    local component = self:GetComp(go, child, is3d and "TextMeshPro" or "TextMeshProUGUI")
    if component then
        if color and color ~= "" then
            text = Tools:ChangeTextColor(text, color)
        end
        if material and material ~= "" then
            material = "Assets/Res/Fonts/" .. material ..".mat"
            local mat = GameResMgr:LoadMaterialSyncFree(material, self)
            component.fontMaterial = mat.Result
        end
        component.text = text
        return component
    end
end

function UIBaseView:SetSlider(child, max, min, current, obj)
    assert(child ~= nil, "parms is nil")
    local component = self:GetComp(child, "Slider", obj)
    if component then
        component.maxValue = max
        component.minValue = min
        component.value = current
        return component
    end
end

function UIBaseView:SendGuideEvent(uiType, arg, localPosID)
    --解决需要等待未刷新的ui刷新完成在执行
    GameTimer:CreateNewMilliSecTimer(300, function()
        if LocalDataManager:IsNewPlayerRecord() then
            return
        end
        GuideManager:OnEvent(uiType or Guide.EVENT_VIEW_OPEND, {uiType = self:GetUIType()})
    end)
end

function UIBaseView:SetFloatGuid(guid)
    self.m_guid = guid
end

function UIBaseView:GetItemGo(index, scrollList, name)
    scrollList = scrollList or UnityHelper.GetTheChildComponent(self.m_uiObj, name or "List", "ScrollRectEx")
    if scrollList and index > 0 then
        return scrollList:GetScrollItem(index - 1)
    end
end

function UIBaseView:SetModeObj(obj, modeCloseFunction)
    if not self.m_modeObj then
        self.m_modeObj = obj
        self.m_modeObj.SetDynamicLocalizeText = function(this, key, func)
            self.m_modeObj:GetView():Invoke("SetDynamicLocalizeText", key, func)
        end
    end

    if not self.m_modeCloseFunction then
        self.m_modeCloseFunction = modeCloseFunction
    end
end

function UIBaseView:DispatchModeEvent(cmd, ...)
    if self.m_modeObj then
        self.m_modeObj:OnFscommand(cmd, ...)
    end
end

-- for adnroid key back
function UIBaseView:DestroyModeUIObject(immediately,onClosedCB)
    local callback = function()
        if self.m_androidKeyBackEventButon then
            if self.m_androidKeyBackEventButon.onClick then
                self.m_androidKeyBackEventButon.onClick:Invoke()
                if onClosedCB then
                    onClosedCB()
                end
                return true
            end
        end

        if self.m_modeObj and self.m_modeCloseFunction then
            self.m_modeCloseFunction(self.m_modeObj)
            if onClosedCB then
                onClosedCB()
            end
            return true
        end
    end
    if not self.m_uiObj or self.m_uiObj:IsNull() then
        return callback()
    end
    local animation = self.m_uiObj:GetComponent("Animation")
    if not animation or animation:IsNull() or immediately then
        return callback()
    end

    local closeAnim = {
        "UI_scale_close_background",
        "UI_scale_close_root",
        "UI_scale_close_special",
        "UI_slide_close",
        "UI_phone_close",
        "Chat_close",
        "UI_position_close_LimitChooseUI",
    }
    for i, v in ipairs(closeAnim) do
        if AnimationUtil.GetAnimationState(animation, v) then
            self:PlayAnimation(animation, v, function()
                callback()
            end)
            return true
        end
    end
    return callback()
end



-- 
function UIBaseView:SetOnEnterCallback(callback)
    if callback then
        callback()
    end   
end

UIBaseView.HINT_GREEN = 0
UIBaseView.HINT_RED = 1
UIBaseView.HINT_BLUE = 2
function UIBaseView:SetWidgetHint(widget, hint, color, hideText)
    if not widget or not hint then
        return
    end

    local go = widget.gameObject
    local hintDot = UnityHelper.GetTheChildComponent(go, "HintDot", "Image")
    if not hintDot then return end

    local show = hint > 0
    if not show then
        hintDot.gameObject:SetActive(false)
        return
    end

    local txtNum = UnityHelper.GetTheChildComponent(hintDot.gameObject, "TxtNum", "TextMeshProUGUI")
    if txtNum then
        txtNum.gameObject:SetActive(not hideText)
        txtNum.text = tostring(hint)
    end

    local colorName = "HintDotRed"
    if color == self.HINT_GREEN then
        colorName = "HintDotGreen"
    elseif color == self.HINT_RED then
        colorName = "HintDotRed"
    elseif color == self.HINT_BLUE then
        colorName = "HintDotBlue"
    end

    if hintDot.sprite and hintDot.sprite.name == colorName then
        return
    end

    self:SetSprite(hintDot, "UI_Common", colorName, function()
        hintDot.gameObject:SetActive(true)
    end, true)
end


function UIBaseView:SetImageSprite(child, name, cb)
    local image = self:GetComp(child, "Image")
    if not image then
        error(debug.traceback("image is nil"))
        return
    end
    self:SetSprite(image, "UI_Common", name, cb, true)
end

function UIBaseView:AddAnimationHander(anim)
    if not anim or anim:IsNull() then
        return
    end
    local event = anim.gameObject:GetComponent("AnimaitonKeyFrameEvents")
    if not event or event:IsNull() then
        return
    end

    self.__animations[self] = self.__animations[self] or {}
    self.__animations[self][event] = true
end

function UIBaseView:PlayAnimation(animation, clip, cb, speed, keyFrameName)
    self:AddAnimationHander(animation)
    if speed and keyFrameName then
        AnimationUtil.Play(animation, clip, cb, speed, keyFrameName)
    else
        AnimationUtil.Play(animation, clip, cb)
    end
end
function UIBaseView:SetDynamicLocalizeText(key, cb)
    self.__chanageLanguageCompleteCallback[self] = self.__chanageLanguageCompleteCallback[self] or {}
    self.__chanageLanguageCompleteCallback[self][key] = cb
    if cb then cb() end
end

function UIBaseView:UpdateDynamicLocalizeText()
	for k, v in pairs(self.__chanageLanguageCompleteCallback or {}) do
		for _, sv in pairs(v or {}) do
			sv()
		end
	end
end

return UIBaseView
