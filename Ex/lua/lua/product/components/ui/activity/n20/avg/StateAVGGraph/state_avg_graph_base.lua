---@class StateAVGGraphBase : State
_class("StateAVGGraphBase", State)
StateAVGGraphBase = StateAVGGraphBase

function StateAVGGraphBase:Init()
    self.fsm = self:GetFsm()
    ---@type UIN20AVGGraph
    self.ui = self.fsm:GetData()
    ---@type N20AVGData
    self.data = self.ui.data
end

function StateAVGGraphBase:Destroy()
    StateAVGGraphBase.super.Destroy(self)
    self.ui = nil
end

---@return UnityEngine.RectTransform
function StateAVGGraphBase:GetScrollView()
    return self.ui.rtSV
end

---@return UnityEngine.RectTransform
function StateAVGGraphBase:GetContent()
    return self.ui.rtContent
end
