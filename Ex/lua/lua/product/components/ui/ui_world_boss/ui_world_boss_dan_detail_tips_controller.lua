---@class UIWorldBossDanDetailTipsController:UIController
_class("UIWorldBossDanDetailTipsController", UIController)
UIWorldBossDanDetailTipsController = UIWorldBossDanDetailTipsController

function UIWorldBossDanDetailTipsController:OnShow(uiParams)
    --self.atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self:UnLock("UIWorldBossDanDetailTipsController")

    --self._maskBGCanvas = self:GetGameObject().transform.parent.parent:Find("BGMaskCanvas").gameObject
    --self._maskBGCanvas:SetActive(false)
    --默认偏移
    local offset = {}
    offset.x = 121
    offset.y = -30

    local strToShow = uiParams[1]
    local anchorPos = uiParams[2]

    self._safeArea = self:GetUIComponent("RectTransform", "SafeArea")

    self._rect = self:GetUIComponent("RectTransform", "rect")
    --self:GetOffset()
    ---@type UnityEngine.UI.LayoutElement
    self._rectLayoutElement = self:GetUIComponent("LayoutElement", "rect")
    --self._titleTex = self:GetUIComponent("UILocalizationText", "title")
    self._intrTex = self:GetUIComponent("UILocalizationText", "intr")
    --self._icon = self:GetUIComponent("Image", "icon")
    --self._titleTex:SetText(StringTable.Get(cfg.Title))
    self._intrTex:SetText(strToShow)
    --self._icon.sprite = self.atlas:GetSprite(cfg.Icon)

    --安全区域偏移
    local safeOffset = {}
    safeOffset.x = 0
    safeOffset.y = 0

    --临时位置
    local v2 = Vector2(anchorPos.x + offset.x, offset.y + anchorPos.y)

    --安全区
    local safeRect = self._safeArea.rect

    local layoutElementWidth = self._rectLayoutElement.preferredWidth

    --x
    if v2.x > 0 then
        if v2.x + layoutElementWidth * 0.5 > (safeRect.width * 0.5) then
            safeOffset.x = (safeRect.width * 0.5) - (v2.x + layoutElementWidth * 0.5)
        end
    else
        if math.abs(v2.x) + layoutElementWidth * 0.5 > (safeRect.width * 0.5) then
            safeOffset.x = (math.abs(v2.x) + layoutElementWidth * 0.5) - (safeRect.width * 0.5)
        end
    end
    -- --y
    if v2.y > 0 then
        if v2.y + self._rect.sizeDelta.y * 0.5 > (safeRect.height * 0.5) then
            safeOffset.y = (safeRect.height * 0.5) - (v2.y + self._rect.sizeDelta.y * 0.5)
        end
    else
        if math.abs(v2.y) + self._rect.sizeDelta.y * 0.5 > (safeRect.height * 0.5) then
            safeOffset.y = (math.abs(v2.y) + self._rect.sizeDelta.y * 0.5) - (safeRect.height * 0.5)
        end
    end
    --last
    self._rect.anchoredPosition = Vector2(v2.x + safeOffset.x, safeOffset.y + v2.y)
end
function UIWorldBossDanDetailTipsController:OnHide()
    --self._titleTex = nil
    self._intrTex = nil
    --self._icon = nil
    self._rect = nil
end

function UIWorldBossDanDetailTipsController:bgOnClick()
    self:CloseDialog()
end

function UIWorldBossDanDetailTipsController:Update()
    local mouse = GameGlobal.EngineInput().mousePresent
    if mouse then
        if GameGlobal.EngineInput().GetMouseButtonDown(0) then
            self:CloseDialog()
            --self._maskBGCanvas:SetActive(true)
        end
    else
        local touchCount = GameGlobal.EngineInput().touchCount
        if touchCount > 0 then
            local touch0 = GameGlobal.EngineInput().GetTouch(0)
            if touch0 and touch0.phase == TouchPhase.Began then
                self:CloseDialog()
                --self._maskBGCanvas:SetActive(true)
            end
        end
    end
end
