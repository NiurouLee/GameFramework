---@class UIBlackFightPaperElementReview : UICustomWidget
_class("UIBlackFightPaperElementReview", UICustomWidget)
UIBlackFightPaperElementReview = UIBlackFightPaperElementReview

function UIBlackFightPaperElementReview:OnShow()
    ---@type UnityEngine.GameObject
    self.goTypes = {}
    for k, t in pairs(BlackFightPaperElementType) do
        local go = self:GetGameObject("type" .. t)
        self.goTypes[t] = go
    end
    self.go0 = self:GetGameObject("go0")
    ---@type UILocalizationText
    self.txt1 = self:GetUIComponent("UILocalizationText", "txt1")
    ---@type RawImageLoader
    self.img2 = self:GetUIComponent("RawImageLoader", "img2")
    ---@type UnityEngine.UI.Image
    self.img3 = self:GetUIComponent("Image", "img3")
    ---@type RawImageLoader
    self.img4 = self:GetUIComponent("RawImageLoader", "img4")
    ---@type UILocalizationText
    self.txt4 = self:GetUIComponent("UILocalizationText", "txt4")
    ---@type RawImageLoader
    self.img5 = self:GetUIComponent("RawImageLoader", "img5")
    ---@type UILocalizationText
    self.txt5 = self:GetUIComponent("UILocalizationText", "txt5")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIN7.spriteatlas", LoadType.SpriteAtlas)
end

function UIBlackFightPaperElementReview:OnHide()
    self.img2:DestoryLastImage()
    self.img4:DestoryLastImage()
    self.img5:DestoryLastImage()
end

---@param e BlackFightPaperElement
function UIBlackFightPaperElementReview:Flush(e)
    if not e then
        return
    end
    for k, go in pairs(self.goTypes) do
        go:SetActive(k == e.type)
    end
    if e.type == BlackFightPaperElementType.Empty then
        self.go0:GetComponent("RectTransform").sizeDelta = e.whImg
    elseif e.type == BlackFightPaperElementType.Text then
        self:FlushText(e, self.txt1)
    elseif e.type == BlackFightPaperElementType.RawImage then
        self:FlushRawImage(e, self.img2)
    elseif e.type == BlackFightPaperElementType.Image then
        self.img3:GetComponent("RectTransform").sizeDelta = e.whImg
        self.img3.sprite = self.atlas:GetSprite(e.name)
    elseif e.type == BlackFightPaperElementType.RawImageText then
        self:FlushRawImage(e, self.img4)
        self:FlushText(e, self.txt4)
    elseif e.type == BlackFightPaperElementType.FloatRawImageText then
        self:FlushText(e, self.txt5)
        self:FlushRawImage(e, self.img5)
    else
        Log.fatal("### invalid type. type=", e.type)
    end
end

---@param e BlackFightPaperElement
---@param txt UILocalizationText
function UIBlackFightPaperElementReview:FlushText(e, txt)
    txt:GetComponent("RectTransform").sizeDelta = e.whText
    if not string.isnullorempty(e.font) then
        txt:SwitchFont(e.font)
    end
    txt:SetText(StringTable.Get(e.text))
end

---@param e BlackFightPaperElement
---@param txt RawImageLoader
function UIBlackFightPaperElementReview:FlushRawImage(e, img)
    img:GetComponent("RectTransform").sizeDelta = e.whImg
    img:DestoryLastImage()
    img:LoadImage(e.name)
end
