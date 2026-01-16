---@class UIHauteCoutureGetItemCell : UICustomWidget
_class("UIHauteCoutureGetItemCell", UICustomWidget)
UIHauteCoutureGetItemCell = UIHauteCoutureGetItemCell

function UIHauteCoutureGetItemCell:OnShow(uiParams)
    self._rect = self:GetUIComponent("RectTransform", "rect")
    self._anim = self:GetUIComponent("Animation", "rect")

    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.uiItem:SetClickCallBack(
        function(go)
            self:itemOnClick(go)
        end
    )
end

---@param itemInfo table 物品信息
---@param index number 下标
---@param clickCallback function 回调
---@param nameColor Color 文本颜色ss
function UIHauteCoutureGetItemCell:SetData(itemInfo, clickCallback)
    self._templateData = itemInfo
    self._item_id = self._templateData.item_id

    local text2 = "<color=#847e7e>"..StringTable.Get(self._templateData.item_name).."</color>"
    local quality = self._templateData.color
    self._itemCount = self._templateData.item_count
    local icon = self._templateData.icon
    local tex = self:FormatItemCount(self._itemCount)
    local text1 = tex
    local itemId = self._templateData.item_id
    local des = self._templateData.item_des
    local awardType = self._templateData.award_type
    self._clickCallback = clickCallback

    local activityText = ""
    if awardType then
        if awardType == StageAwardType.Activity then
            activityText = StringTable.Get("str_item_xianshi")
        end
    end
    

    self.uiItem:SetData(
        {
            icon = icon,
            quality = quality,
            text1 = text1,
            text2 = text2,
            itemId = itemId,
            des = des,
            activityText = activityText
        }
    )
end

function UIHauteCoutureGetItemCell:itemOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if not self._templateData then
        return
    end

    if self._clickCallback then
        self._clickCallback(self._item_id, go.transform.position)
    end
end

---@param count number 数量
function UIHauteCoutureGetItemCell:FormatItemCount(count)
    local tex = HelperProxy:GetInstance():FormatItemCount(count)
    return tex
end
