local UnityHelper = CS.Common.Utils.UnityHelper
local UIView = require("Framework.UI.View")
local GameArmy = GameTableDefine.GameArmy
local GameExteriorImgManager = GameTableDefine.GameExteriorImgManager
local EventManager = require("Framework.Event.Manager")
local GameResMgr = require("GameUtils.GameResManager")

local ViewUtils = {}

function ViewUtils:SetIconFrame(frameObj, rarity)
    local frameSprites = {
        "IconFrameRankGrey",
        "IconFrameRankGreen",
        "IconFrameRankBlue",
        "IconFrameRankPurple",
        "IconFrameRankOrange",
        "IconFrameRankGold",
        "IconFrameRuneRoundGrey",
        "IconFrameRuneRoundGreen",
        "IconFrameRuneRoundBlue",
        "IconFrameRuneRoundPurple",
        "IconFrameRuneRoundOrange",
        "IconFrameRuneSquareGrey",
        "IconFrameRuneSquareGreen",
        "IconFrameRuneSquareBlue",
        "IconFrameRuneSquarePurple",
        "IconFrameRuneSquareOrange",
        "IconFrameRuneHeroGrey",
        "IconFrameRuneHeroGreen",
        "IconFrameRuneHeroBlue",
        "IconFrameRuneHeroPurple",
        "IconFrameRuneHeroOrange",
        "IconFrameRuneRoundPatternGrey",
        "IconFrameRuneRoundPatternGreen",
        "IconFrameRuneRoundPatternBlue",
        "IconFrameRuneRoundPatternPurple",
        "IconFrameRuneRoundPatternOrange"
    }

    local targetSprite = frameSprites[0]

    if frameSprites[tonumber(rarity)] then
        targetSprite = frameSprites[tonumber(rarity)]
    end

    UIView:SetSprite(frameObj:GetComponent("Image"), "UI_Icons", targetSprite)
end

function ViewUtils:SetIconObj(iconContainer, icon, rarity, amount, enableClick, callback)
    local isRune = tonumber(rarity) and tonumber(rarity) > 6 or false
    local runeFrameTran = UnityHelper.FindTheChild(iconContainer, "FrameRuneFrame"); 
    local runeFrameObj = runeFrameTran and runeFrameTran.gameObject or nil;
    local frameObj = UnityHelper.FindTheChild(iconContainer, "FrameRank").gameObject;
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(iconContainer, "OuterFrame").gameObject, not isRune)
    if runeFrameObj then
        ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(iconContainer, "IconBg").gameObject, not isRune)
    end

    ViewUtils:SetGoVisibility(runeFrameObj, isRune)
    ViewUtils:SetGoVisibility(frameObj, not isRune)

    local enableClick = (nil == enableClick) and false or enableClick
    UnityHelper.GetTheChildComponent(iconContainer, "IconGoodsAll", "FrameGroup"):SetFrameByName(icon)
    if isRune then
        self:SetIconFrame(runeFrameObj, rarity)
    else
        self:SetIconFrame(frameObj, rarity)
    end

    local amount = amount or 1
    local txtNum = UnityHelper.GetTheChildComponent(iconContainer, "TxtNum", "TextMeshProUGUI")
    if txtNum then
        txtNum.gameObject:SetActive(type(amount) == "string" or amount > 1)
        if type(amount) == "string" then
            txtNum.text = amount
        else
            txtNum.text = tostring(amount)
        end
    end

    local btn = UnityHelper.GetTheChildComponent(iconContainer, "BtnIconTap", "Button")
    if enableClick then
        btn.interactable = true
        if not callback and type(enableClick) == "table" then
            callback = function()
                EventManager:DispatchEvent("FS_CHECK_ITEM_DETAIL", enableClick)
            end
        end
        UIView:SetButtonClickHandler(btn, callback)
    else
        btn.interactable = false
    end
end

function ViewUtils:SetBuffObj(iconContainer, icon)
    UnityHelper.GetTheChildComponent(iconContainer, "IconBuffAll", "FrameGroup"):SetFrameByName(icon)
end

function ViewUtils:SetHeroObj(heroObj, icon, rarity, level, star, name)
    local iconObj = UnityHelper.FindTheChild(heroObj, "HeroFramesAll").gameObject
    local levelObj = UnityHelper.FindTheChild(heroObj, "LevelBg")
    local frameObj = UnityHelper.FindTheChild(heroObj, "FrameRank").gameObject
    local noHeroObj = UnityHelper.FindTheChild(heroObj, "NoHero")

    if noHeroObj then
        noHeroObj = noHeroObj.gameObject
    end

    if not icon then
        ViewUtils:SetGoVisibility(noHeroObj, true)
        ViewUtils:SetGoVisibility(iconObj, false)
        ViewUtils:SetGoVisibility(levelObj.gameObject, false)
        ViewUtils:SetStar(heroObj, 0)
        ViewUtils:SetIconFrame(frameObj, 1)
    else
        ViewUtils:SetIconFrame(frameObj, rarity or 1)
        ViewUtils:SetGoVisibility(noHeroObj, false)
        ViewUtils:SetGoVisibility(iconObj, true)

        iconObj:GetComponent("FrameGroup"):SetFrameByName(icon)
        ViewUtils:SetStar(heroObj, star)

        if levelObj then
            ViewUtils:SetGoVisibility(levelObj.gameObject, level and level ~= "")
            if tonumber(level) ~= nil then
                UnityHelper.GetTheChildComponent(levelObj.gameObject, "TxtLevel", "TextMeshProUGUI").text = "Lv."..level
            else
                UnityHelper.GetTheChildComponent(levelObj.gameObject, "TxtLevel", "TextMeshProUGUI").text = level
            end
        end
        local txtLevelObj = UnityHelper.FindTheChild(heroObj, "TxtLevel")
        if txtLevelObj then
            if tonumber(level) ~= nil then
                txtLevelObj:GetComponent("TextMeshProUGUI").text = "Lv."..level
            else
                txtLevelObj:GetComponent("TextMeshProUGUI").text = level
            end
        end
        local txtNameObj = UnityHelper.FindTheChild(heroObj, "TxtName")
        if txtNameObj then
            txtNameObj:GetComponent("TextMeshProUGUI").text = name or ""
        end
    end
end

function ViewUtils:SetGuardianObj(obj, icon, star)

    local iconGO = UnityHelper.FindTheChild(obj, "IconGuardianAll").gameObject

    if icon == nil or icon == "" then
        ViewUtils:SetGoVisibility(iconGO, false)
    else
        ViewUtils:SetGoVisibility(iconGO, true)
        UnityHelper.GetTheChildComponent(obj, "IconGuardianAll", "FrameGroup"):SetFrameByName(icon)
    end
    ViewUtils:SetStar(obj, star)
    local lockGo = UnityHelper.FindTheChild(obj, "IconLock")
    if lockGo ~= nil then
        lockGo.gameObject:SetActive(icon == nil or icon == "")
    end
end

function ViewUtils:SetStar(parentObj, star)
    local starSprites = {"HeroIconStarGrey", "HeroIconStarBlue", "HeroIconStarGold"}
    local star = tonumber(star)
    local MAX_STAR_ICON = 5
    for i = 1, MAX_STAR_ICON, 1 do
        local curStar = UnityHelper.FindTheChild(parentObj, "Star" .. i)
        if curStar then
            curStar = curStar.gameObject

            if star and star >= 0 then
                curStar:SetActive(true)
                local targetSprite = starSprites[1]
                if star - MAX_STAR_ICON >= i then
                    targetSprite = starSprites[3]
                elseif star >= i then
                    targetSprite = starSprites[2]
                end
                UIView:SetSprite(curStar:GetComponent("Image"), "UI_Hero", targetSprite)
            else
                curStar:SetActive(false)
            end
        end
    end
end

function ViewUtils:SetHeroPortrait(parentObj, icon, onSetHandler)
    local portrait = UnityHelper.FindTheChild(parentObj, "HeroFramesAll").gameObject
    local fg = portrait:GetComponent("FrameGroup")
    fg:SetFrameChangeFunc(onSetHandler)
    fg:SetFrameByName(icon)
end

-- function ViewUtils:SetRuneIcon(runeObj, icon, rarity)
--     self:SetIconFrame(runeObj, rarity)
--     --local iconImg = UnityHelper.GetTheChildComponent(runeObj, "IconRune", "Image")
--     --UIView:SetSprite(iconImg, "UI_Icons", icon)
--     local iconFG = UnityHelper.GetTheChildComponent(runeObj, "IconGoodsAll", "FrameGroup")
--     iconFG:SetFrameByName(icon)
-- end

function ViewUtils:SetItemOriginIcon(obj, icon)
    obj:GetComponent("FrameGroup"):SetFrameByName(icon)
end

function ViewUtils:SetResIcon(iconObj, icon)
    iconObj:GetComponent("FrameGroup"):SetFrameByName(icon)
end

function ViewUtils:SetChestIcon(widget, icon, rarity)
    if not widget then
        return
    end
    widget:SetFrameByName(icon)
end

function ViewUtils:SetSoldierIcon(iconObj, icon, amount, name, enableClick, callback)
    local enableClick = (nil == enableClick) and false or enableClick

    UnityHelper.GetTheChildComponent(iconObj, "IconSoldierAll", "FrameGroup"):SetFrameByName(icon)
    local txtName = UnityHelper.GetTheChildComponent(iconObj, "TxtName", "TextMeshProUGUI")
    local txtNum = UnityHelper.GetTheChildComponent(iconObj, "TxtNum", "TextMeshProUGUI")
    if txtName then
        txtName.text = name
    end
    if txtNum then
        amount = amount or 1
        if type(amount) == "string" then
            txtNum.text = amount
        else
            txtNum.text = amount > 1 and LuaTools:SeparateNumberWithComma(amount) or ""
        end
    end

    local btn = UnityHelper.GetTheChildComponent(iconObj, "BtnTouch", "Button")
    if btn then
        if enableClick then
            btn.interactable = true
            UIView:SetButtonClickHandler(btn, callback)
        else
            btn.interactable = false
        end
    end
end

function ViewUtils:SetLeagueBanner(widget, banner)
    if not banner then
        return
    end

    if widget and widget.GetType then
        local typeName = widget:GetType().Name
        if "Image" == typeName then
            UIView:SetSprite(widget, "UI_Player", "IconAllianceFlag" .. banner)
        elseif "FrameGroup" == typeName then
            widget:SetFrameByName("icon_banner_" .. banner)
        end
    end
end

function ViewUtils:SetLeagueLogo(widget, logo)
    if not logo then
        return
    end

    if widget and widget.GetType then
        local typeName = widget:GetType().Name
        if "Image" == typeName then
            UIView:SetSprite(widget, "UI_Player", "IconAllianceFlagPattern" .. logo)
        elseif "FrameGroup" == typeName then
            widget:SetFrameByName("icon_logo_" .. logo)
        end
    end
end

function ViewUtils:SetWidgetHint(widget, hint, isGreen, hideText)
    if not widget or not hint then
        return
    end

    local go = widget.gameObject
    local hintDot = UnityHelper.GetTheChildComponent(go, "HintDot", "Image")
    if not hintDot then return end

    local show = hint > 0
    hintDot.gameObject:SetActive(show)
    if not show then
        return
    end

    local txtNum = UnityHelper.GetTheChildComponent(hintDot.gameObject, "TxtNum", "TextMeshProUGUI")
    if txtNum then
        txtNum.gameObject:SetActive(not hideText)
        txtNum.text = tostring(hint)
    end

    if hintDot.sprite and hintDot.sprite.name == (isGreen and "HintDotGreen" or "HintDotRed") then
        return
    end

    UIView:SetSprite(hintDot, "UI_Common", isGreen and "HintDotGreen" or "HintDotRed")
end

function ViewUtils:SetButtonLocked(widget, enabled)
    if not widget then
        return
    end
    local enabled = (nil == enabled) and false or enabled

    local go = widget.gameObject
    local imgLocked = UnityHelper.GetTheChildComponent(go, "ImgLocked", "Image")
    imgLocked.gameObject:SetActive(enabled)
end

function ViewUtils:SetSignDone(gameObject, isDone)
    if not gameObject then
        return
    end
    local isDone = (nil == isDone) and false or isDone

    local beDone = UnityHelper.GetTheChildComponent(gameObject, "SignDone", "Image")
    local notDone = UnityHelper.GetTheChildComponent(gameObject, "SignNotDone", "Image")

    beDone.gameObject:SetActive(isDone)
    notDone.gameObject:SetActive(not isDone)
end

function ViewUtils:SetUserTitle(widget, title, rarity, fullTitle)
    if not widget then
        return
    end
    widget.text = fullTitle
end


function ViewUtils:SetPlayerGird(view, obj, data, cb)
    if not view or not obj then
        return
    end

    local isNull = data == nil
    local btn = obj:GetComponent("Button")
    local imgAdd = UnityHelper.GetTheChildComponent(obj, "IconAdd", "Image")
    local imgHead = UnityHelper.GetTheChildComponent(obj, "PlayerAvatar", "Image")
    local fgAvatar = UnityHelper.GetTheChildComponent(obj, "PlayerFrame", "FrameGroup")

    imgAdd.gameObject:SetActive(isNull)
    imgHead.gameObject:SetActive(not isNull)

    if not isNull then
        data.head = data.head or data.logid
        view:SetHead(imgHead, data)
    end

    if cb then
        view:SetButtonClickHandler(
            btn,
            function()
                cb(isNull and "add" or "head")
            end
        )
    end
end

function ViewUtils:SetGoVisibility(obj, isVisible)
    if obj then
        obj:SetActive(isVisible)
    end
end

function ViewUtils:SetPlayerPortrait(image, builtinAvatar, customizedAvatarInfo)
    UIView:SetHead(
        image,
        {
            head = builtinAvatar,
            avatar = customizedAvatarInfo
        }
    )
end

function ViewUtils:SetPlayerPortraitObj(obj, builtinAvatar, customizedAvatarInfo, avatarFrame)
    local avatarImage = UnityHelper.GetTheChildComponent(obj, "PlayerAvatar", "Image")
    UIView:SetSprite(avatarImage, "UI_Player", builtinAvatar, function()
        if customizedAvatarInfo then
            GameExteriorImgManager:GetExteriorImage(
                customizedAvatarInfo,
                function()
                    if not avatarImage or avatarImage:IsNull() then return end
                    local sprite = UnityHelper.LoadSpriteByExternFile(customizedAvatarInfo, 72, 72)
                    avatarImage.sprite = sprite
                end
            )
        end
    end)
    
    local avatarFrameFG = UnityHelper.GetTheChildComponent(obj, "AvatarFramesAll", "FrameGroup")
    avatarFrameFG:SetFrameByName(avatarFrame)
end

function ViewUtils:SetButtonPrice(button, resType, resAmount)
    if not button then
        return
    end
    local go = button.gameObject

    if resAmount then
        UnityHelper.GetTheChildComponent(go, "TxtPrice", "TextMeshProUGUI").text = resAmount
    end

    if resType then
        self:SetResIcon(UnityHelper.FindTheChild(go, "IconResourcesAll").gameObject, resType)
    end
end

function ViewUtils:SetButtonName(button, name)
    if not button or not name then
        return
    end
    local go = button.gameObject
    UIView:SetText("TxtBtn", name, go)
end


function ViewUtils:SetExp(barObj, curValue, maxValue)
    UnityHelper.GetTheChildComponent(barObj, "TxtExp", "TMPLocalization").text = curValue .. "/" .. maxValue
    local expPct = curValue / maxValue
    barObj:GetComponent("Slider").value = expPct
end

function ViewUtils:SetGuardianSkillIcon(parentObj, icon, showLock, showAdd)
    UnityHelper.GetTheChildComponent(parentObj, "IconGuardianAll", "FrameGroup"):SetFrameByName(icon)
    local stateLock = UnityHelper.FindTheChild(parentObj, "StateLock")
    if stateLock then
        stateLock.gameObject:SetActive(showLock and true or false)
    end
    local stateAddGuardian = UnityHelper.FindTheChild(parentObj, "StateAddGuardian")
    if stateAddGuardian then
        stateAddGuardian.gameObject:SetActive(showAdd and true or false)
    end
end

function ViewUtils:SetGuardianIcon(parentObj, icon)
    UnityHelper.GetTheChildComponent(parentObj, "IconGuardianAll", "FrameGroup"):SetFrameByName(icon)
end

function ViewUtils:SetItemHeroIconFrame(frameObj, heroID)
    UIView:SetSprite(frameObj:GetComponent("Image"), "UI_Icons", "RuneIconHero" .. (heroID - 30000))
end

function ViewUtils:SetHeroSkillIcon(iconGO, icon)
    UIView:SetSprite(iconGO:GetComponent("Image"), "UI_Icons", icon)
end

function ViewUtils:SetScienceIcon(view, obj, data, cb)
    if not obj or not data then
        return
    end
    -- print("SetScienceIcon", obj.name, data.sciName);
    UnityHelper.GetTheChildComponent(obj, "IconGoodsAll", "FrameGroup"):SetFrameByName(data.sciIcon)

    local curLevel = data.curLevel or 0
    local maxLevel = data.maxLevel or 0

    local color = data.isMatched and "FFFFFF" or "E79999"
    color = curLevel >= maxLevel and "97B396" or color
    color = data.isLocked and "676767" or color

    -- print("color->", color, data.isMatched, curLevel, maxLevel, data.isLocked);

    local txtName = UnityHelper.GetTheChildComponent(obj, "TxtName1", "TextMeshProUGUI")
    txtName.text = LuaTools:ChangeTextColor(data.sciName or "", color)
    local txtNum = UnityHelper.GetTheChildComponent(obj, "TxtNum", "TextMeshProUGUI")
    txtNum.text = LuaTools:ChangeTextColor(curLevel .. "/" .. maxLevel, color)

    local objDark = UnityHelper.FindTheChild(obj, "Dark").gameObject
    self:SetGoVisibility(objDark, data.isLocked)

    if cb then
       if GameTableDefine.Guide:IsGuiding() then
            view:SetButtonClickHandler(UnityHelper.GetTheChildComponent(obj, "BtnSciencesAll", "Button"), cb) -- 引导\
       else
            view:SetButtonClickHandler(UnityHelper.GetTheChildComponent(obj, "BtnItem", "Button"), cb)
        end
    end
end

function ViewUtils:ChangeImageShader(image, shaderPath)
    if shaderPath then
        GameResMgr:ALoadAsync(
            shaderPath,
            nil,
            function(handler)
                if handler.Result then
                    if image then
                        image.material = handler.Result
                    end
                end
            end
        )
    else
        image.material = nil
    end
end

function ViewUtils:SetMailIcon(obj, icon)
    if not obj then
        return
    end
    UnityHelper.GetTheChildComponent(obj, "FGIconMailType", "FrameGroup"):SetFrameByName(icon)
end

function ViewUtils:SetArtifactIcon(image, icon)
    UIView:SetSprite(image, "UI_Icons", icon)
end

function ViewUtils:SetReplayPlayerInfo(obj, data)
    if not obj or not data then
        return
    end
    -- 头像
    UIView:SetHead(UnityHelper.GetTheChildComponent(obj, "PlayerAvatar", "Image"), data)
    local color = data.isWin and "82EA92" or "C76B6B"

    if data.name then
        UIView:SetText("TxtName", LuaTools:ChangeTextColor(data.name, color), obj)
    end

    if data.level then
        UIView:SetText("TxtLevel", data.level, obj)
    end

    if data.isWin then
        local str = data.isWin and "Win" or "Lose"
        UIView:SetText("TxtResult", LuaTools:ChangeTextColor(str, color), obj)
    end

    if data.might then
        local might = GameTextLoader:ReadText("LC_WORD_MIGHT_1") .. LuaTools:FormatNumber(data.might or 0)
        UIView:SetText("TxtMight", might, obj)
    end
end

function ViewUtils:SetQuestIcon(iconObj, icon)
    iconObj:GetComponent("FrameGroup"):SetFrameByName(icon)
end

function ViewUtils:SetVipCrown(iconObj, icon, num)
    UnityHelper.GetTheChildComponent(iconObj, "IconVipCrownAll", "FrameGroup"):SetFrameByName(icon)
    local txtNum = UnityHelper.GetTheChildComponent(iconObj, "TxtNum", "TextMeshProUGUI")
    if txtNum then
        txtNum.text = num or ""
    end
end

function ViewUtils:SetDragonBall(image, star)
    local ballImage = {
        "Item672",
        "Item673",
        "Item674",
        "Item675",
        "Item676",
        "Item677",
        "Item678"
    }

    local targetImageName = ballImage[star or 1]
    print("targetImageName = ", image, targetImageName)
    UIView:SetSprite(image, "UI_Icons", targetImageName)
end

function ViewUtils:InitShopGoodsObj(obj)
    local child;
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "HintEventPack").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "SoldOut").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "PackItemRandom").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "PackItemNormal").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "TxtItemTotal").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "PackLeft").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "LimitLeft").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "StateFreeClaim").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "TxtOnceOnly").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "BtnPrice").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "BtnPriceCoin").gameObject, false)
    child = UnityHelper.FindTheChild(obj, "CouponAvailable");
    if child then ViewUtils:SetGoVisibility(child.gameObject, false) end
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "PackTime").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "MoreWillCome").gameObject, false)
    ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(obj, "FlagDiscount").gameObject, false)
end

function ViewUtils:SetTitleBg(obj, bgIndex)
    local titleBgObj = UnityHelper.FindTheChild(obj, "TitleBgAll").gameObject

    for i = 1, 5 do
        local bgObj = UnityHelper.FindTheChild(titleBgObj, "Bg" .. i).gameObject
        ViewUtils:SetGoVisibility(bgObj, i == bgIndex)
    end
end

function ViewUtils:SetShopGoodsObj(itemObj, itemData)
    Tools:DumpTable(itemData, "itemData", 6);
    if not itemData then return end
    self:InitShopGoodsObj(itemObj)

    local Shop = GameTableDefine.Shop;

    -- common things
    self:SetTitleBg(itemObj, itemData.bgIndex)
    UnityHelper.GetTheChildComponent(itemObj, "TxtTitle", "TMPLocalization").text = itemData.name

    local itemTypeTotalObj = UnityHelper.FindTheChild(itemObj, "TxtItemTotal").gameObject
    ViewUtils:SetGoVisibility(itemTypeTotalObj, true)
    itemTypeTotalObj:GetComponent("TMPLocalization").text = itemData.itemTypeTotalString

    local discountInfoObj = UnityHelper.FindTheChild(itemObj, "FlagDiscount").gameObject
    ViewUtils:SetGoVisibility(discountInfoObj, true)
    UnityHelper.GetTheChildComponent(discountInfoObj, "TxtDiscount", "TMPLocalization").text = itemData.discountString

    ViewUtils:SetGoVisibility(
        UnityHelper.FindTheChild(itemObj, "HintEventPack").gameObject,
        itemData.isEventPack
    )

    UIView:SetButtonClickHandler(
        UnityHelper.GetTheChildComponent(itemObj, "BtnCheck", "Button"),
        function()
            EventManager:DispatchEvent(itemData.checkCmd or "FS_CMD_SHOP_CHECK_ITEM_DETAIL", itemData.configID)
        end
    )

    if #(itemData.randomItems or {}) > 0 then
        local randomItemsObj = UnityHelper.FindTheChild(itemObj, "PackItemRandom").gameObject
        ViewUtils:SetGoVisibility(randomItemsObj, true)

        for i = 1, 4 do
            local obj = UnityHelper.FindTheChild(randomItemsObj, "PackItem" .. i).gameObject
            local data = itemData.randomItems[i]
            if data then
                ViewUtils:SetGoVisibility(obj, true)
                if i == 1 then
                    ViewUtils:SetIconObj(obj, data.icon, data.rarity, data.amount, false)
                else
                    ViewUtils:SetIconObj(
                        UnityHelper.FindTheChild(obj, "IconGoods").gameObject,
                        data.icon,
                        data.rarity,
                        0,
                        false
                    )
                    UnityHelper.GetTheChildComponent(obj, "TxtItemName", "TMPLocalization").text = data.name
                    UnityHelper.GetTheChildComponent(obj, "TxtItemNum", "TMPLocalization").text = data.amount
                end
            else
                ViewUtils:SetGoVisibility(obj, false)
            end
        end
    else
        local normalItemsObj = UnityHelper.FindTheChild(itemObj, "PackItemNormal").gameObject
        ViewUtils:SetGoVisibility(normalItemsObj, true)
        local rssObj = UnityHelper.FindTheChild(normalItemsObj, "ItemGem").gameObject
        ViewUtils:SetGoVisibility(rssObj, false)

        for i = 1, 5 do
            local tran = UnityHelper.FindTheChild(normalItemsObj, "PackItem" .. i);
            if not tran then break end

            local obj = tran.gameObject;
            local data = itemData.normalItems[i]

            if data then
                if i == 1 and data.isRss then
                    ViewUtils:SetGoVisibility(obj, false)
                    ViewUtils:SetGoVisibility(rssObj, true)
                    ViewUtils:SetResIcon(UnityHelper.FindTheChild(rssObj, "IconResourcesAll").gameObject, data.icon)
                    UnityHelper.GetTheChildComponent(rssObj, "TxtGem", "TMPLocalization").text = data.amount
                else
                    ViewUtils:SetGoVisibility(obj, true)
                    ViewUtils:SetIconObj(
                        UnityHelper.FindTheChild(obj, "IconGoods").gameObject,
                        data.icon,
                        data.rarity,
                        0,
                        false
                    )
                    UnityHelper.GetTheChildComponent(obj, "TxtItemName", "TMPLocalization").text = data.name
                    UnityHelper.GetTheChildComponent(obj, "TxtItemNum", "TMPLocalization").text = data.amount
                end
            else
                ViewUtils:SetGoVisibility(obj, false)
            end
        end
    end

    -- differences
    local goodsType = itemData.type

    function ShowOnceOnly()
        ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(itemObj, "TxtOnceOnly").gameObject, true)
    end

    function ShowRemainingTime()
        local remainingTimeObj = UnityHelper.FindTheChild(itemObj, "PackTime").gameObject
        ViewUtils:SetGoVisibility(remainingTimeObj, true)
        local refreshRemainingTime = GameTimeManager:GetRemainingTime(itemData.nextRefreshTime)
        UnityHelper.GetTheChildComponent(remainingTimeObj, "TxtTime", "TMPLocalization").text =
            GameTimeManager:FormatTimeLength(refreshRemainingTime)
    end

    function SetCoupon()
        local child = UnityHelper.FindTheChild(itemObj, "CouponAvailable");
        if not child then return end

        local couponObj = child.gameObject;
        ViewUtils:SetGoVisibility(couponObj, itemData.hasAvailableCoupon)
        if itemData.hasAvailableCoupon then
            UnityHelper.GetTheChildComponent(couponObj, "TxtNum", "TMPLocalization").text = itemData.highestCouponValue
        end
    end

    function SetLeftPack()
        local packLeftObj = UnityHelper.FindTheChild(itemObj, "PackLeft").gameObject
        ViewUtils:SetGoVisibility(packLeftObj, true)
        local totalLeftObj = UnityHelper.FindTheChild(packLeftObj, "PackLeft1").gameObject
        local personalLeftObj = UnityHelper.FindTheChild(packLeftObj, "PackLeft2").gameObject
        ViewUtils:SetGoVisibility(personalLeftObj, itemData.personalLeftNumber ~= nil)
        local totalLeft = LuaTools:FormatString(GameTextLoader:ReadText("LC_WORD_HD_GN_LB_QUANFU"), itemData.leftNumber)
        UnityHelper.GetTheChildComponent(totalLeftObj, "TxtLeft", "TMPLocalization").text = totalLeft

        if itemData.personalLeftNumber then
            local personalLeft = LuaTools:FormatString(GameTextLoader:ReadText("LC_WORD_HD_GN_LB_GEREN"), itemData.personalLeftNumber)
            UnityHelper.GetTheChildComponent(personalLeftObj, "TxtLeft", "TMPLocalization").text = personalLeft
        end
    end

    function SetSoldout()
        ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(itemObj, "SoldOut").gameObject, true)
    end

    function SetMoreWillComeRemainingTime()
        local moreWillComeObj = UnityHelper.FindTheChild(itemObj, "MoreWillCome").gameObject
        ViewUtils:SetGoVisibility(moreWillComeObj, true)
        ViewUtils:SetGoVisibility(
            UnityHelper.FindTheChild(moreWillComeObj, "TxtMoreWillComeIn").gameObject,
            true
        )
        ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(moreWillComeObj, "TxtTime").gameObject, true)
        ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(moreWillComeObj, "TxtRequiresVip").gameObject, false)
        local refreshRemainingTime = GameTimeManager:GetRemainingTime(itemData.nextRefreshTime)
        UnityHelper.GetTheChildComponent(moreWillComeObj, "TxtTime", "TMPLocalization").text =
            GameTimeManager:FormatTimeLength(refreshRemainingTime)
    end

    function SetPrice(isVipRequired, isCashOnly)
        SetCoupon()
        local isAble2Buy = true

        if isVipRequired and itemData and itemData.vipLevel < itemData.vipRequired then
            local moreWillComeObj = UnityHelper.FindTheChild(itemObj, "MoreWillCome").gameObject
            ViewUtils:SetGoVisibility(moreWillComeObj, true)
            ViewUtils:SetGoVisibility(
                UnityHelper.FindTheChild(moreWillComeObj, "TxtMoreWillComeIn").gameObject,
                false
            )
            ViewUtils:SetGoVisibility(UnityHelper.FindTheChild(moreWillComeObj, "TxtTime").gameObject, false)
            ViewUtils:SetGoVisibility(
                UnityHelper.FindTheChild(moreWillComeObj, "TxtRequiresVip").gameObject,
                true
            )
            UnityHelper.GetTheChildComponent(moreWillComeObj, "TxtRequiresVip", "TMPLocalization").text =
                itemData.vipRequired
            isAble2Buy = false
        end

        if itemData.isFree then
            local freeClaimStateObj = UnityHelper.FindTheChild(itemObj, "StateFreeClaim").gameObject
            ViewUtils:SetGoVisibility(freeClaimStateObj, true)
            UIView:SetButtonClickHandler(
                UnityHelper.GetTheChildComponent(freeClaimStateObj, "BtnClaim", "Button"),
                function()
                    -- EventManager:DispatchEvent("FS_DISCOUNT_PACK_FREE_CLAIM", itemData.configID)
                    Shop:OnBuyNormalGoodsWithRss(itemData.configID)
                end
            )
            return
        end

        if itemData.isCashAvailable then
            local btnPriceObj = UnityHelper.FindTheChild(itemObj, "BtnPrice").gameObject
            ViewUtils:SetGoVisibility(btnPriceObj, true)

            local btnRssObj = UnityHelper.FindTheChild(btnPriceObj, "BtnPriceCoin").gameObject
            local btnCashObj = UnityHelper.FindTheChild(btnPriceObj, "BtnPrice").gameObject

            if isCashOnly then
                ViewUtils:SetGoVisibility(btnRssObj, false)
            else
                ViewUtils:SetGoVisibility(btnRssObj, true)
                UnityHelper.GetTheChildComponent(btnRssObj, "TxtBtn", "TMPLocalization").text = itemData.priceValue
                UnityHelper.GetTheChildComponent(btnRssObj, "TxtPrice", "TMPLocalization").text =
                    itemData.originalPriceValue
                ViewUtils:SetResIcon(
                    UnityHelper.FindTheChild(btnRssObj, "IconResourcesAll").gameObject,
                    itemData.priceIcon
                )

                btnRssObj:GetComponent("Button").interactable = isAble2Buy

                UIView:SetButtonClickHandler(
                    btnRssObj:GetComponent("Button"),
                    function()
                        EventManager:DispatchEvent(itemData.buyCmd or "FS_CMD_SHOP_BUY_GOODS_WITH_RSS", itemData.configID)
                    end
                )
            end

            UnityHelper.GetTheChildComponent(btnCashObj, "TxtBtn", "TMPLocalization").text = itemData.cashPriceValue
            UnityHelper.GetTheChildComponent(btnCashObj, "TxtPrice", "TMPLocalization").text =
                itemData.originalCashPriceValue

            UIView:SetButtonClickHandler(
                btnCashObj:GetComponent("Button"),
                function()
                    EventManager:DispatchEvent("FS_CMD_SHOP_BUY_GOODS_WITH_CASH", itemData.configID)
                end
            )
        else
            local btnRssObj = UnityHelper.FindTheChild(itemObj, "BtnPriceCoin").gameObject
            ViewUtils:SetGoVisibility(btnRssObj, true)
            UnityHelper.GetTheChildComponent(btnRssObj, "TxtBtn", "TMPLocalization").text = itemData.priceValue
            UnityHelper.GetTheChildComponent(btnRssObj, "TxtPrice", "TMPLocalization").text =
                itemData.originalPriceValue
            ViewUtils:SetResIcon(UnityHelper.FindTheChild(btnRssObj, "IconResourcesAll").gameObject, itemData.priceIcon)
            btnRssObj:GetComponent("Button").interactable = isAble2Buy
            UIView:SetButtonClickHandler(
                btnRssObj:GetComponent("Button"),
                function()
                    EventManager:DispatchEvent(itemData.buyCmd or "FS_CMD_SHOP_BUY_GOODS_WITH_RSS", itemData.configID)
                end
            )
        end
    end

    if goodsType == Shop.PACK_TYPE_NEWBIE then
        ShowOnceOnly()
        ShowRemainingTime()
        SetPrice(false)
    elseif goodsType == Shop.PACK_TYPE_NORMAL_PACK or packType == Shop.PACK_TYPE_ACHIEVEMENT_PACK then
        SetLeftPack()
        ShowRemainingTime()
        SetPrice(false)
    elseif goodsType == Shop.PACK_TYPE_LIMITED_PACK then
        SetLeftPack()

        if itemData.leftNumber > 0 then
            SetPrice(false)
        else
            SetSoldout()
            SetMoreWillComeRemainingTime()
        end
    elseif goodsType == Shop.PACK_TYPE_VIP_DAILY then
        SetLeftPack()

        if itemData.leftNumber > 0 then
            SetPrice(true)
        else
            SetSoldout()
            SetMoreWillComeRemainingTime()
        end
    elseif goodsType == Shop.PACK_TYPE_VIP_LEVEL then
        SetPrice(true)
    elseif goodsType == Shop.PACK_TYPE_VIP_EXP_1 then
        ShowOnceOnly()
        SetPrice(true)
    elseif goodsType == Shop.PACK_TYPE_VIP_EXP_2 then
        SetPrice(true)
    elseif goodsType == Shop.PACK_TYPE_DAILY_AMAZEMENT then
        ShowRemainingTime()
        SetLeftPack()

        local isLastPack = false

        if extraParam and itemData.leftNumber > 0 then
            if tonumber(extraParam[1]) == 2 and tonumber(extraParam[1]) == 2 then
                isLastPack = true
            end
        end

        if itemData.leftNumber > 0 and isLastPack then
            SetPrice(false)
        else
            SetSoldout()
        end
    elseif goodsType == Shop.PACK_TYPE_DAILY_AMAZEMENT_GEM then
        ShowRemainingTime()
        SetLeftPack()
        if itemData.leftNumber > 0 then
            SetPrice(false)
        else
            SetSoldout()
        end
    elseif goodsType == Shop.PACK_TYPE_GEM_WELFARE then
        ShowRemainingTime()
        SetLeftPack()
        if itemData.leftNumber > 0 then
            SetPrice(false)
        else
            SetSoldout()
        end
    elseif goodsType == Shop.PACK_TYPE_CONDITION then
        ShowRemainingTime()
        SetLeftPack()
        if itemData.leftNumber > 0 then
            SetPrice(false, true)
        else
            SetSoldout()
        end
    elseif goodsType == Shop.PACK_TYPE_DAILY_LIMIT then
        if itemData.leftNumber > 0 then
            ShowOnceOnly()
            SetPrice(false, true)
        else
            SetSoldout()
            SetMoreWillComeRemainingTime()
        end
    end
end

function ViewUtils:ReseTextSize(txtContent)
    if not txtContent then
        return
    end
    local txtSize = UIView:GetWidgetSize(txtContent)
    txtContent.transform.sizeDelta = {
        x = txtSize.width,
        y = txtSize.height
    }
end

function ViewUtils:SetScale(widget, x, y, z)
    if not widget then return end
    widget.transform.localScale = {
        x = x,
        y = y,
        z = z,
    };
end

function ViewUtils:SetVisibleWithoutAffectLogic(widget, visible)
    if not widget then return end
    if visible then
        self:SetScale(widget, 1, 1, 1);
    else
        self:SetScale(widget, 0, 0, 0);
    end
end

return ViewUtils
