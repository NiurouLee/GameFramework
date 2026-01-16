---@class UIAircraftSmeltCurrency : UICustomWidget
_class("UIAircraftSmeltCurrency", UICustomWidget)
UIAircraftSmeltCurrency = UIAircraftSmeltCurrency
function UIAircraftSmeltCurrency:OnShow(uiParams)
    self:InitWidget()
    self.atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._waitTime = Cfg.cfg_global["shakeWaitTime"].IntValue or 2000
    self._shakeX = Cfg.cfg_global["shakeOffsetX"].IntValue or 10
    self._shakeY = Cfg.cfg_global["shakeOffsetY"].IntValue or 10
    self._color = Color(250 / 255, 237 / 255, 92 / 255)
    self._shakeColor = Color(249 / 255, 54 / 255, 54 / 255)
end
function UIAircraftSmeltCurrency:InitWidget()
    --generated--
    ---@type UnityEngine.UI.Image
    self.icon = self:GetUIComponent("Image", "icon")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "count")
    --generated end--
    self.root = self:GetUIComponent("RectTransform", "root")
    ---@type UnityEngine.UI.LayoutElement
    self.item = self:GetUIComponent("LayoutElement", "item")

    self.tip = self:GetGameObject("tip")
end

function UIAircraftSmeltCurrency:SetCountStr(str)
    self.count:SetText(str)
end

function UIAircraftSmeltCurrency:OnHide()
    if self.shakeTweener then
        self.shakeTweener:Kill()
        self.shakeTweener = nil
    end
    if self._waitTimer then
        GameGlobal.Timer():CancelEvent(self._waitTimer)
        self._waitTimer = nil
    end
end

function UIAircraftSmeltCurrency:SetData(id, count, tipCB)
    local cfg = Cfg.cfg_top_tips[id]
    self.icon.sprite = self.atlas:GetSprite(cfg.Icon)
    self.count:SetText(count)
    self.count.color = self._color

    if id == RoleAssetID.RoleAssetAtom then
        self.item.preferredWidth = 261
        self.tip:SetActive(true)
        self._tipCB = tipCB
    else
        self.item.preferredWidth = 214
        self.tip:SetActive(false)
        self._tipCB = nil
    end
end
function UIAircraftSmeltCurrency:Shake()
    if self.shakeTweener then
        self.shakeTweener:Kill()
        --停止时复位，避免再次抖动后偏移
        self.root.anchoredPosition = Vector2(0, 0)
    end

    if self._waitTimer then
        GameGlobal.Timer():CancelEvent(self._waitTimer)
        self._waitTimer = nil
    end

    self.count.color = self._shakeColor
    self.shakeTweener =
        self.root:DOShakePosition(1, Vector3(self._shakeX, self._shakeY, 0)):OnComplete(
        function()
            self.shakeTweener = nil
            self._waitTimer =
                GameGlobal.Timer():AddEvent(
                self._waitTime,
                function()
                    self.count.color = self._color
                    self._waitTimer = nil
                end
            )
        end
    )
end

function UIAircraftSmeltCurrency:tipOnClick(go)
    self._tipCB(go.transform.position)
end

function UIAircraftSmeltCurrency:Reset()
    if self.shakeTweener then
        self.shakeTweener:Kill()
        --停止时复位，避免再次抖动后偏移
        self.root.anchoredPosition = Vector2(0, 0)
        self.shakeTweener = nil
    end

    if self._waitTimer then
        GameGlobal.Timer():CancelEvent(self._waitTimer)
        self._waitTimer = nil
    end
    self.count.color = self._color
end