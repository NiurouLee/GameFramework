local e = require("ui_n30_entrust_event")

---@class N30EntrustEventInteract:N30EntrustEvent
e:Class("N30EntrustEventInteract", N30EntrustEvent, EntrustEventType.EntrustEventType_Interact)

function N30EntrustEventInteract:Constructor()

end

-- test case
function N30EntrustEventInteract:DebugName()
    return "Interact"
end

function N30EntrustEventInteract:GetIconName()
    -- 锁定的路点图标，目前设计上只有高难战斗点和互动点需要
    if self._isPass then
        return "n30_wt_ld_icon15"
    elseif self._isLocked then
        return "n30_wt_ld_icon16"
    else
        return "n30_wt_ld_icon10"
    end
end

function N30EntrustEventInteract:GetWidgetName()
    return "UIN30EntrustEventInteract"
end

function N30EntrustEventInteract:OnArrived(ui)
    local cfg = self:Cfg()
    local interactionTeam = ui:GetStepOnTeam(cfg.InteractionID)

    if self:IsPass() then
        ui:ShowDialog("UIN30EntrustEvent", self)
    elseif interactionTeam == nil then
        ui:ShowDialog("UIN30EntrustEvent", self)
    else
        -- 互动点：发一个就行，另一个自动完成
        ui:CallUIMethod("UIN30EntrustLine", "CompleteEvent", self:ID(), function()
            local txtPopup = StringTable.Get("str_n30_entrust_event_interact_finish")
            ToastManager.ShowToast(txtPopup)

            ui:CallUIMethod("UIN30EntrustLine", "OnInteractFinish", {self:ID(), cfg.InteractionID})
        end)
    end
end


---@class UIN30EntrustEventInteract:UIN30EntrustEventWidget
_class("UIN30EntrustEventInteract", UIN30EntrustEventWidget)
UIN30EntrustEventInteract = UIN30EntrustEventInteract

function UIN30EntrustEventInteract:Constructor()

end

function UIN30EntrustEventInteract:OnShow(uiParams)
    self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
end

function UIN30EntrustEventInteract:OnHide()

end

function UIN30EntrustEventInteract:GetIcon()
    return "n30_wt_icon09"
end

function UIN30EntrustEventInteract:Refresh()
    local descKey = self._event:ParamDesc()
    if descKey ~= nil then
        self._txtDesc.gameObject:SetActive(true)
        self._txtDesc:SetText(StringTable.Get(descKey))
    else
        self._txtDesc.gameObject:SetActive(false)
    end
end
