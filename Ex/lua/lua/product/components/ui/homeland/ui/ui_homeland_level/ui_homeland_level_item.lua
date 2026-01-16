---@class UIHomelandLevelItem:UICustomWidget
_class("UIHomelandLevelItem", UICustomWidget)
UIHomelandLevelItem = UIHomelandLevelItem

function UIHomelandLevelItem:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetHomelandLevelData()
end

function UIHomelandLevelItem:OnShow()
    ---@type UILocalizationText
    self.txtLevel = self:GetUIComponent("UILocalizationText", "txtLevel")
    self.canGet = self:GetGameObject("canGet")
    self.btnImage = self:GetUIComponent("Image", "BG")
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIHomelandLevel.spriteatlas", LoadType.SpriteAtlas)

    self.unselectedTxtColor = Color(43/255, 43/255, 43/255)
end

function UIHomelandLevelItem:Flush(level)
    self.level = level
    local item = self.data:GetHomelandLevelItemDataByLevel(level)
    self.txtLevel:SetText("Lv."..item.level)
    self.canGet:SetActive(item.state == HomelandLevelItemDataState.CanGet)
end

function UIHomelandLevelItem:FlushSelect(level)
    if self.level == level then
        self.btnImage.sprite = self.atlas:GetSprite("n17_level_btn3")
        self.txtLevel.color = Color.white
    else
        self.btnImage.sprite = self.atlas:GetSprite("n17_level_btn4")
        self.txtLevel.color = self.unselectedTxtColor
    end
end

function UIHomelandLevelItem:BGOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandLevelClickLevelItem, self.level)
end
