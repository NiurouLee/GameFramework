---@class UIGetItemControllerItem : UICustomWidget
_class("UIGetItemControllerItem", UICustomWidget)
UIGetItemControllerItem = UIGetItemControllerItem

--最大可现实的数字位数
local maxNumCount = 5
function UIGetItemControllerItem:OnShow(uiParams)
    self._rect = self:GetUIComponent("RectTransform", "rect")
    self._anim = self:GetUIComponent("Animation", "rect")

    self._eff = self:GetGameObject("Effect")
    self._itemAlpha = self:GetUIComponent("CanvasGroup", "uiitem")
    --图集
    self._index = -1
    self._pstid = -1
    self._itemCount = 0

    --- uiitem
    self:GetUIItem()
    self.uiItem:SetClickCallBack(
        function(go)
            self:itemOnClick(go)
        end
    )

    self._outeffect = self:GetGameObject( "Outeffect")
end

function UIGetItemControllerItem:GetUIItem()
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
end

---@param itemInfo table 物品信息
---@param index number 下标
---@param clickCallback function 回调
---@param nameColor Color 文本颜色ss
function UIGetItemControllerItem:SetData(itemInfo, index, clickCallback, nameColor, tweenIdx, beforeTime)
    self._eff:SetActive(false)
    self._itemAlpha.alpha = 0

    self._index = index
    self._templateData = itemInfo
    self._clickCallback = clickCallback

    self._item_id = self._templateData.item_id
    self._itemCount = self._templateData.item_count

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
    
    self:_SetUIItemData(nameColor)
end

function UIGetItemControllerItem:_SetUIItemData(nameColor)
    local text2Color = nameColor
    local text2 = StringTable.Get(self._templateData.item_name)
    local quality = self._templateData.color
    local icon = self._templateData.icon
    local tex = self:FormatItemCount(self._itemCount)
    local text1 = tex
    local itemId = self._templateData.item_id
    local des = self._templateData.item_des
    local awardType = self._templateData.award_type

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
            text2Color = text2Color,
            itemId = itemId,
            des = des,
            activityText = activityText
        }
    )
end

function UIGetItemControllerItem:_PlayAnim()
    self._outeffect:SetActive(self._templateData.outeffect ~= nil and self._templateData.outeffect)
    self._anim:Play("uieff_UIGetItemControllerItem")
end

function UIGetItemControllerItem:itemOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if not self._templateData then
        return
    end

    if self._clickCallback then
        self._rect:DOPunchScale(Vector3(0.1, 0.1, 0.1), 0.2)
        self:_DoClickCallback(go)
    end
end

function UIGetItemControllerItem:_DoClickCallback(go)
    self._clickCallback(self._item_id, go.transform.position)
end

---@return number
function UIGetItemControllerItem:GetIndex()
    return self._index
end

function UIGetItemControllerItem:OnHide()
    if self._tweenEvent then
        GameGlobal.Timer():CancelEvent(self._tweenEvent)
        self._tweenEvent = nil
    end
end

---@param count number 数量
function UIGetItemControllerItem:FormatItemCount(count)
    local tex = HelperProxy:GetInstance():FormatItemCount(count)
    return tex
end
