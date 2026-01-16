---@class UIOpenGiftGetMatItem : UICustomWidget
_class("UIOpenGiftGetMatItem", UICustomWidget)
UIOpenGiftGetMatItem = UIOpenGiftGetMatItem

--最大可现实的数字位数
local maxNumCount = 5
function UIOpenGiftGetMatItem:OnShow(uiParams)
    self._rect = self:GetUIComponent("RectTransform", "rect")

    self._index = -1
    --- uiitem
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
function UIOpenGiftGetMatItem:SetData(index, itemid,itemcount, clickCallback)
    self._index = index
    local itemCount = itemcount
    self._itemId = itemid

    local cfg = Cfg.cfg_item[self._itemId]
    if not cfg then
        Log.error("###[UIOpenGiftGetMatItem] cfg is nil ! id --> ",self._itemId)
    end

    local text2 = StringTable.Get(cfg.Name)
    local quality = cfg.Color
    local icon = cfg.Icon
    local text1 = self:FormatItemCount(itemCount)
    local des = cfg.Des

    self._clickCallback = clickCallback

    self.uiItem:SetData(
        {
            icon = icon,
            quality = quality,
            text1 = text1,
            text2 = text2,
            itemId = self._itemId,
            des = des
        }
    )
end


function UIOpenGiftGetMatItem:itemOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
    if self._clickCallback then
        self._rect:DOPunchScale(Vector3(0.1, 0.1, 0.1), 0.2)
        self._clickCallback(self._itemId, go.transform.position)
    end
end

---@param count number 数量
function UIOpenGiftGetMatItem:FormatItemCount(count)
    local tex = HelperProxy:GetInstance():FormatItemCount(count)
    return tex
end
