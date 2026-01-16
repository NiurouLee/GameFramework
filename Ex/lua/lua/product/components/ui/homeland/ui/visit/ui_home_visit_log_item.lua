--
---@class UIHomeVisitLogItem : UICustomWidget
_class("UIHomeVisitLogItem", UICustomWidget)
UIHomeVisitLogItem = UIHomeVisitLogItem
--初始化
function UIHomeVisitLogItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIHomeVisitLogItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.content = self:GetUIComponent("UILocalizationText", "content")
    ---@type UILocalizationText
    self.time = self:GetUIComponent("UILocalizationText", "time")
    --generated end--
end
--设置数据
---@param data UIHomeVisitLog
function UIHomeVisitLogItem:SetData(data)
    self.content:SetText(data:Content())
    local tb = os.date("*t", data:Time())
    self.time:SetText(tb["year"] .. "." .. tb["month"] .. "." .. tb["day"])
end
