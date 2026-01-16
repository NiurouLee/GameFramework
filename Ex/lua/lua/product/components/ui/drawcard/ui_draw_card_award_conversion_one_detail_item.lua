---@class UIDrawCardAwardConversionOneDetailItem:UICustomWidget
_class("UIDrawCardAwardConversionOneDetailItem", UICustomWidget)
UIDrawCardAwardConversionOneDetailItem = UIDrawCardAwardConversionOneDetailItem

function UIDrawCardAwardConversionOneDetailItem:OnShow()
    self.count = self:GetUIComponent("UILocalizationText", "count")
    self.item = self:GetUIComponent("RawImageLoader", "item")
    self.itemObject = self:GetGameObject("item")
    self.pop = self:GetUIComponent("UISelectObjectPath", "item")
end

function UIDrawCardAwardConversionOneDetailItem:SetData(data)
    local cfg = Cfg.cfg_item
    self.itemData = data
    if self.itemData[1]==0 then
        self.item:LoadImage("icon_item_3000020")
        self.count.color = Color(222/255 , 198/255 , 98/255)
    else
        self.item:LoadImage(cfg[self.itemData[1]].Icon)
        self.count.color = Color(213/255 , 213/255 , 213/255)
    end
    
    self.count:SetText(self.itemData[2])


end

function UIDrawCardAwardConversionOneDetailItem:ItemOnClick(go)

    if self.itemData[1]~=0 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowItemTips, self.itemData[1], self.itemObject.transform.position)
    end

    
end


function UIDrawCardAwardConversionOneDetailItem:OnHide()
end
