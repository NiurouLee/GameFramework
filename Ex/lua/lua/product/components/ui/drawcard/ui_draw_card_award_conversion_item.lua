---@class UIDrawCardAwardConversionItem:UICustomWidget
_class("UIDrawCardAwardConversionItem", UICustomWidget)
UIDrawCardAwardConversionItem = UIDrawCardAwardConversionItem

function UIDrawCardAwardConversionItem:OnShow()
    -- self.title = self:GetUIComponent("UILocalizationText", "title")
    -- self.detail = self:GetUIComponent("UILocalizationText", "detail")
    -- self.content = self:GetGameObject("content")
    self.ConversionItem = self:GetUIComponent("UISelectObjectPath","ConversionItem")
    self.ConversionItem:SpawnObjects("UIDrawCardAwardConversionOneItem",5)
end

function UIDrawCardAwardConversionItem:SetData(idx,callback)

    local conversecfg = Cfg.cfg_drawcard_conversion_data[idx]
    local items = self.ConversionItem:GetAllSpawnList()

    for index, value in ipairs(items) do
            value:SetData(conversecfg,index)
    end


end

function UIDrawCardAwardConversionItem:OnHide()
end
