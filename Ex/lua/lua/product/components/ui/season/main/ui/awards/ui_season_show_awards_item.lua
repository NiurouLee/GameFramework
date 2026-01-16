---@class UISeasonShowAwardsItem : UICustomWidget
_class("UISeasonShowAwardsItem", UICustomWidget)
UISeasonShowAwardsItem = UISeasonShowAwardsItem

--最大可现实的数字位数
local maxNumCount = 5
--
function UISeasonShowAwardsItem:OnShow(uiParams)
    self._rect = self:GetUIComponent("RectTransform", "rect")
    self._anim = self:GetUIComponent("Animation", "rect")

    self._eff = self:GetGameObject("Effect")
    self._itemAlpha = self:GetUIComponent("CanvasGroup", "uiitem")
    --图集
    self._index = -1
    self._pstid = -1
    self._itemCount = 0
    --- uiitem
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UISeasonItem
    self.uiItem = sop:SpawnObject("UISeasonItem")
end

---@param itemInfo table 物品信息
---@param index number 下标
---@param clickCallback function 回调
---@param nameColor Color 文本颜色ss
---
function UISeasonShowAwardsItem:SetData(itemInfo, index, clickCallback, nameColor, tweenIdx, beforeTime)
    self._eff:SetActive(false)
    self._itemAlpha.alpha = 0

    self._index = index
    self._templateData = itemInfo
    self._item_id = self._templateData.item_id

    if tweenIdx then
        local tweenTime = beforeTime + (tweenIdx - 1) * 100
        if self._tweenEvent then
            GameGlobal.Timer():CancelEvent(self._tweenEvent)
            self._tweenEvent = nil
        end
        self._tweenEvent =
            GameGlobal.Timer():AddEvent(
            tweenTime,
            function()
                self:_PlayAnim()
            end
        )
    end

    self._itemCount = self._templateData.item_count

    local ra = RoleAsset:New()
    ra.assetid = self._item_id
    ra.count = self._itemCount
    self.uiItem:Flush(ra)
end
--
function UISeasonShowAwardsItem:_PlayAnim()
    self._anim:Play("uieff_UIGetItemControllerItem")
end
---@return number
---
function UISeasonShowAwardsItem:GetIndex()
    return self._index
end
--
function UISeasonShowAwardsItem:OnHide()
    if self._tweenEvent then
        GameGlobal.Timer():CancelEvent(self._tweenEvent)
        self._tweenEvent = nil
    end
end

---@param count number 数量
---
function UISeasonShowAwardsItem:FormatItemCount(count)
    local tex = HelperProxy:GetInstance():FormatItemCount(count)
    return tex
end
