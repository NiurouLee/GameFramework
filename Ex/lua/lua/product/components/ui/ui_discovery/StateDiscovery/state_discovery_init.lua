---只有该状态允许触控、点击等玩家交互
---@class StateDiscoveryInit : StateDiscoveryBase
_class("StateDiscoveryInit", StateDiscoveryBase)
StateDiscoveryInit = StateDiscoveryInit

function StateDiscoveryInit:OnEnter(TT, ...)
    StateDiscoveryInit.super:OnEnter(TT, ...)
    self:Init()

    self._imgSR.raycastTarget = true --可触控
    -- --点击
    -- self._ui:SetUIEventTrigger(
    --     self._sr.gameObject,
    --     UIEventTriggerType.Click,
    --     function(go)
    --         self._ui:CloseUIStage()
    --     end
    -- )
    --拖拽
    -- ---@type UIEventTriggerListener
    -- self._etl = UICustomUIEventListener.Get(self._sr.gameObject)
    -- self:AddUICustomEventListener(
    --     self._etl,
    --     UIEvent.BeginDrag,
    --     function(ped)
    --         -- if self._cameraTweener then --开始拖动时，打断相机移动
    --         --     self._cameraTweener:Kill()
    --         -- end
    --     end
    -- )
    -- self:AddUICustomEventListener(
    --     self._etl,
    --     UIEvent.EndDrag,
    --     function(ped) --不能删除，删除后会导致UIEventTriggerListener.IsDragging不会置false导致单击失效
    --     end
    -- )
end

function StateDiscoveryInit:OnExit(TT)
    self._imgSR.raycastTarget = false --不可触控
    --点击
    -- self:RemoveUIEventTrigger(self._sr.gameObject, UIEventTriggerType.Click)
    -- self._etl.onBeginDrag = nil
    -- self._etl.onDrag = nil
    -- self._etl.onEndDrag = nil
end
