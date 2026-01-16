---@class UIN31SecondAnniversaryAwardItem : UICustomWidget
_class("UIN31SecondAnniversaryAwardItem", UICustomWidget)
UIN31SecondAnniversaryAwardItem = UIN31SecondAnniversaryAwardItem

--初始化
function UIN31SecondAnniversaryAwardItem:OnShow(uiParams)
    self._atlas = self:GetAsset("N31Anniversary.spriteatlas", LoadType.SpriteAtlas)
    self:_GetComponents()
end

--获取ui组件
function UIN31SecondAnniversaryAwardItem:_GetComponents()
    self._background = self:GetUIComponent("Image", "Background")
    self._icon = self:GetUIComponent("RawImageLoader", "Icon")
    self._count = self:GetUIComponent("UILocalizationText", "Count")
end

--设置数据
function UIN31SecondAnniversaryAwardItem:SetData(data, callBack, bigAwardItem)
    self._data = data
    self._callback = callBack
    if bigAwardItem then
        self._background.sprite = self._atlas:GetSprite("hdzx_2znqd_icondi")
    else
        self._background.sprite = self._atlas:GetSprite("hdzx_2znqd_icondi")
    end
    local cfg = Cfg.cfg_item[self._data.assetid]
    if cfg == nil then
        Log.fatal("cfg_item is nil." .. self._data.assetid)
        return
    end
    self._icon:LoadImage(cfg.Icon)
    self._count:SetText(self._data.count)
end

function UIN31SecondAnniversaryAwardItem:IconOnClick(go)
    self._callback(self._data.assetid, go.transform.position)
end