---@class UIRelicInfoController:UIController
_class("UIRelicInfoController", UIController)
UIRelicInfoController = UIRelicInfoController

function UIRelicInfoController:OnShow(uiParam)
    self._atlas = self:GetAsset("UIMazeChoose.spriteatlas", LoadType.SpriteAtlas)

    self.ItemColorToTextColor = {
        [ItemColor.ItemColor_White] = Color(207 / 255, 207 / 255, 207 / 255, 1),
        [ItemColor.ItemColor_Green] = Color(32 / 255, 216 / 255, 165 / 255, 1),
        [ItemColor.ItemColor_Blue] = Color(55 / 255, 168 / 255, 255 / 255, 1),
        [ItemColor.ItemColor_Purple] = Color(178 / 255, 137 / 255, 250 / 255, 1),
        [ItemColor.ItemColor_Yellow] = Color(255 / 255, 243 / 255, 55 / 255, 1),
        [ItemColor.ItemColor_Golden] = Color(255 / 255, 142 / 255, 0 / 255, 1)
    }

    self._relicID = uiParam[1]

    if not self._relicID then
        Log.fatal("###error --> maze relic info controller - the uiParam is nil !")
        return
    end

    self:GetComponents()
end

function UIRelicInfoController:GetComponents()
    local relicPool = self:GetUIComponent("UISelectObjectPath", "relicPool")

    local item = relicPool:SpawnObject("UIRugueLikeBackpackItem")

    item:SetData(
        1,
        self._relicID,
        function(tIndex)
        end,
        false
    )

    local nameTex = self:GetUIComponent("UILocalizationText", "name")
    local descTex = self:GetUIComponent("UILocalizationText", "desc")
    local colorBg = self:GetUIComponent("Image", "colorDown")
    local cfg = Cfg.cfg_item[self._relicID]
    if cfg then
        nameTex:SetText(StringTable.Get(cfg.Name))
        descTex:SetText(StringTable.Get(cfg.RpIntro))
        colorBg.sprite = self._atlas:GetSprite("map_shengwu_xian" .. cfg.Color)
        local c = Color(1, 1, 1, 1)

        c = self.ItemColorToTextColor[cfg.Color]
        nameTex.color = c
    else
        Log.fatal("###error --> maze relic info controller - the cfg_item is nil ! id --> ", self._relicID)
    end
end

function UIRelicInfoController:bgOnClick()
    self:CloseDialog()
end
