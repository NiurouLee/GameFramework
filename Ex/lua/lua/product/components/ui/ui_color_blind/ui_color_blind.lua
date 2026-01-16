---@class UIColorBlind:UIController
_class("UIColorBlind", UIController)
UIColorBlind = UIColorBlind

function UIColorBlind:OnShow(uiParam)
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")

    local curIdx = UIPropertyHelper:GetInstance():GetColorBlindStyle()
    self.selectIdx = curIdx
    self.txtDesc:SetText(StringTable.Get("str_set_color_blind_desc_" .. curIdx))
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", "s")
    pool:SpawnObjects("UIColorBlindItem", 3)
    ---@type UIColorBlindItem[]
    self.items = pool:GetAllSpawnList()
    for i, item in ipairs(self.items) do
        item:Flush(
            i,
            function()
                self.selectIdx = i
                self.txtDesc:SetText(StringTable.Get("str_set_color_blind_desc_" .. i))
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ColorBlindSelect, i)
            end
        )
    end
end
function UIColorBlind:OnHide()
end

function UIColorBlind:bgOnClick(go)
    self:CloseDialog()
end

function UIColorBlind:btnConfirmOnClick(go)
    UIPropertyHelper:GetInstance():SetColorBlindStyle(self.selectIdx)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ColorBlindUpdate)
    self:CloseDialog()
end
