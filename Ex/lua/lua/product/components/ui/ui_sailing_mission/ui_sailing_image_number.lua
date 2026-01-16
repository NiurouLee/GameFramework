---@class UISailingImageNumber:Object
_class("UISailingImageNumber", Object)
UISailingImageNumber = UISailingImageNumber

function UISailingImageNumber:Constructor(uiController, spriteFormat)
    ---@type UIController
    self._uiController = uiController
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlasNumber = uiController:GetAsset("UISailing.spriteatlas", LoadType.SpriteAtlas)
    self._spriteFormat = spriteFormat

    self._imgList = {}
    self._displayValue = 0
end

---创建接口
---[1] = 个位
---[2] = 十位
---[3] = 百位
function UISailingImageNumber:AddDigitImage(inImage)
    table.insert(self._imgList, inImage)
end

function UISailingImageNumber:SetValue(inNumber)
    local count = #self._imgList
    for i = 1, count, 1 do
        local bit = math.floor(inNumber) % 10
        inNumber = inNumber / 10

        local spriteName = string.format(self._spriteFormat, bit)

        local img = self._imgList[i]
        img.sprite = self._atlasNumber:GetSprite(spriteName)
    end

    self._displayValue = inNumber
end

