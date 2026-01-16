---@class UISeasonStageAwardItem:UICustomWidget
_class("UISeasonStageAwardItem", UICustomWidget)
UISeasonStageAwardItem = UISeasonStageAwardItem

function UISeasonStageAwardItem:OnShow()
    self._trans = self:GetGameObject()
    self:GetComponents()
end
function UISeasonStageAwardItem:GetComponents()
    self._trans = self:GetGameObject()
    --normal
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
    self._iconRawImg = self:GetUIComponent("RawImage", "icon")
    self._iconRect = self:GetUIComponent("RectTransform", "icon")
    self._iconRectDefaultSize = Vector2(self._iconRect.sizeDelta.x, self._iconRect.sizeDelta.y)
    self._iconGO = self:GetGameObject("icon")
    self._quality = self:GetUIComponent("Image", "quality")
    self._qualityRect = self:GetUIComponent("RectTransform", "quality")
    self._qualityGO = self:GetGameObject("quality")
    self._text1 = self:GetUIComponent("UILocalizationText", "txt1")
    self._text1GO = self:GetGameObject("txt1")
    self._text1BgGO = self:GetGameObject("diban")

    --self._uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIS1Main.spriteatlas", LoadType.SpriteAtlas)
    --award
    self._awardTxt = self:GetUIComponent("UILocalizationText", "txt3Star")
    self._typeBgImg = self:GetUIComponent("Image", "imgbg")
    self._typeMainBgImg = self:GetUIComponent("Image", "TypeMainBg")
    --top
    self._topText = self:GetUIComponent("UILocalizationText", "topText")
    self._topGo = self:GetGameObject("g_topaward")
    --act
    self._actGo = self:GetGameObject("g_activity")
    self._actText = self:GetUIComponent("UILocalizationText", "actText")
    self._anim = self:GetUIComponent("Animation", "Base")
    self._rootGo = self:GetGameObject("root")
end
---@public
---@param v Award
function UISeasonStageAwardItem:Flush(v,levelDiff)
    if not v then
        return
    end
    self._v = v
    local icon = v.icon
    local quality = v.color
    local text1 = v.count
    local strKey = ""
    local typeBg = "exp_s1_map_di25"
    local typeMainBg = "exp_s1_map_sedi2"
    self._activityText = ""
    self._topTextStr = UIEnum.ItemRandomStr(v.randomType)
    local awardType = v.type
    local itemId = v.id
    if awardType == StageAwardType.First then
        strKey = "str_season_first_award"
        typeBg = "exp_s1_map_di26"
    elseif awardType == StageAwardType.Star then
        strKey = "str_season_3star_award"
        typeBg = "exp_s1_map_di25"
    elseif awardType == StageAwardType.Activity then
        strKey = "str_season_activity_award"
        self._activityText = StringTable.Get("str_item_xianshi")
        typeBg = "exp_s1_map_di27"
    elseif awardType == StageAwardType.HasGen then
        strKey = "str_season_already_collect"
        typeBg = "exp_s1_map_di27"
    else
        strKey = "str_season_normal_award"
        typeBg = "exp_s1_map_di27"
    end
    if levelDiff then
        if levelDiff == UISeasonLevelDiff.Normal then
            typeMainBg = "exp_s1_map_sedi2"
        elseif levelDiff == UISeasonLevelDiff.Hard then
            typeMainBg = "exp_s1_map_sedi3"
        end
    end

    self:SetText1(text1)
    self:SetQuality(quality)
    self:SetIcon(icon, itemId)
    self:SetAwardText(StringTable.Get(strKey))
    self:SetTypeBg(typeBg)
    self:SetTypeMainBg(typeMainBg)
    self:SetTopAward()
    self:SetAct()
end
--region 旧的uiitem的逻辑放在这里，没有时间细分了，快上车
--icon
function UISeasonStageAwardItem:SetIcon(name, itemId)
    if not string.isnullorempty(name) then
        self:ShowIcon(true, itemId)
        self._icon:LoadImage(name)

        local isHead = false
        if itemId >= 3750000 and itemId <= 3759999 then
            isHead = true
        end
        if isHead then
            local whRate = 1
            --MSG23427	【必现】（测试_朱文科）累计签到查看头像和邮件发送头像时会有变形，附截图	4	新缺陷	李学森, 1958	05/22/2021
            --没有资源接口临时处理
            if itemId >= 3751000 and itemId <= 3751999 then
                whRate = 160 / 190
            elseif itemId >= 3752000 and itemId <= 3752999 then
                whRate = 138 / 216
            elseif itemId >= 3753000 and itemId <= 3753999 then
                whRate = 138 / 216
            end

            self._iconRect.sizeDelta = Vector2(self._iconRect.sizeDelta.x, self._iconRect.sizeDelta.x * whRate)
        else
            self._iconRect.sizeDelta = self._iconRectDefaultSize
        end
    else
        self:ShowIcon(false)
    end
end
function UISeasonStageAwardItem:ShowIcon(show, itemId)
    self._iconGO:SetActive(show)
    self:SetIconOffset(itemId)
end
function UISeasonStageAwardItem:SetIconOffset(itemId)
    if self:_IsPet(itemId) then
        self._iconRect.anchoredPosition = Vector2(0, 14)
    else
        self._iconRect.anchoredPosition = Vector2(0, 19)
    end
end
function UISeasonStageAwardItem:_IsPet(id)
    local cfg = Cfg.cfg_pet {ID = id}
    return cfg and true or false
end
--color
function UISeasonStageAwardItem:SetQuality(quality)
    if quality <= 0 then
        --self:ShowQuality(false)
        --return
        quality = 1
    end
    local qualityName = "exp_s1_map_se"..tostring(quality)--UIEnum.ItemColorFrame(quality)
    if qualityName ~= "" then
        self:ShowQuality(true)
        self._quality.sprite = self.atlas:GetSprite(qualityName)
    else
        self:ShowQuality(false)
    end
end
function UISeasonStageAwardItem:ShowQuality(show)
    self._qualityGO:SetActive(show)
end
--text1
function UISeasonStageAwardItem:SetText1(text, showNumber)
    if text ~= nil then
        local show = false
        if type(text) == "number" then
            local num = text
            show = num > 0 or showNumber
            self._text1:SetText(HelperProxy:GetInstance():FormatItemCount(num))
        elseif type(text) == "string" then
            show = not string.isnullorempty(text)
            self._text1:SetText(text)
        end
        self:ShowText1(show)
    else
        self:ShowText1(false)
    end
end
function UISeasonStageAwardItem:ShowText1(show)
    self._text1GO:SetActive(show)
    --self._text1BgGO:SetActive(show)
    self:SetOffset(show)
end
function UISeasonStageAwardItem:SetOffset(showText1)
    -- if showText1 then
    --     self._qualityRect.anchoredPosition = Vector2(0, 0)
    -- else
    --     self._qualityRect.anchoredPosition = Vector2(0, -20)
    -- end
end
--awardtext
function UISeasonStageAwardItem:SetAwardText(awardText)
    self._awardTxt:SetText(awardText)
end
function UISeasonStageAwardItem:SetTypeBg(typeBgName)
    self._typeBgImg.sprite = self.atlas:GetSprite(typeBgName)
end
function UISeasonStageAwardItem:SetTypeMainBg(typeBgName)
    self._typeMainBgImg.sprite = self.atlas:GetSprite(typeBgName)
end
--topaward
function UISeasonStageAwardItem:SetTopAward()
    self:SetTopText(self._topTextStr)
end
function UISeasonStageAwardItem:SetTopText(text)
    if not string.isnullorempty(text) then
        self:ShowTopText(true)
        self._topText:SetText(text)
    else
        self:ShowTopText(false)
    end
end
function UISeasonStageAwardItem:ShowTopText(show)
    self._topGo:SetActive(show)
end
--act
function UISeasonStageAwardItem:SetAct()
    if not string.isnullorempty(self._activityText) then
        self:ShowText(true)
        self._actText:SetText(self._activityText)
    else
        self:ShowText(false)
    end
end
function UISeasonStageAwardItem:ShowText(show)
    self._actGo:SetActive(show)
end
--endregion
function UISeasonStageAwardItem:BtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if self._v then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowItemTips, self._v.id, self._trans.transform.position)
    end
end
function UISeasonStageAwardItem:PlayAnim(totalDelay)
    local curAnimDelay = 0
    if totalDelay then
        curAnimDelay = totalDelay
    end
    if self._animTimer then
        GameGlobal.Timer():CancelEvent(self._animTimer)
        self._animTimer = nil
    end
    self._animTimer = GameGlobal.Timer():AddEvent(
            curAnimDelay,
        function()
            self:_PlayInAnim()
        end
    )
end
function UISeasonStageAwardItem:_PlayInAnim()
    if self._anim then
        self._anim:Play("uieff_UISeasonAwardItem_3Star_in")
        if self._rootGo then
            self._rootGo:SetActive(true)
        end
    end
end
function UISeasonStageAwardItem:OnHide()
    if self._animTimer then
        GameGlobal.Timer():CancelEvent(self._animTimer)
        self._animTimer = nil
    end
end
function UISeasonStageAwardItem:SetWaitAnim()
    if self._rootGo then
        self._rootGo:SetActive(false)
    end
end