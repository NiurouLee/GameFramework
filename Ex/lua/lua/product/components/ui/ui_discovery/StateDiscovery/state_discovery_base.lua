---@class StateDiscoveryBase : State
_class("StateDiscoveryBase", State)
StateDiscoveryBase = StateDiscoveryBase

function StateDiscoveryBase:Init()
    self.fsm = self:GetFsm()
    ---@type UIDiscovery
    self._ui = self.fsm:GetData()

    ---@type DiscoveryData
    self._data = self._ui._data

    ---@type ScalableScrollRect
    self._sr = self._ui._sr
    ---@type UnityEngine.UI.Image
    self._imgSR = self._ui._imgSR
    self._cg = self._ui._cg

    self._scaleStep = self._ui._scaleStep
    self._scaleMin = self._ui._scaleMin
    self._scaleMax = self._ui._scaleMax
end

function StateDiscoveryBase:Destroy()
    StateDiscoveryBase.super:Destroy()
    self._ui = nil
end
