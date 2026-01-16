require "state"

---@class N28StateAVGGraphBase : State
_class("N28StateAVGGraphBase", State)
N28StateAVGGraphBase = N28StateAVGGraphBase

function N28StateAVGGraphBase:Init()
    self.fsm = self:GetFsm()
    ---@type U28AVGGraph
    self.ui = self.fsm:GetData()
    ---@type N28AVGData
    self.data = self.ui.data
end

function N28StateAVGGraphBase:Destroy()
    N28StateAVGGraphBase.super.Destroy(self)
    self.ui = nil
end

---@return UnityEngine.RectTransform
function N28StateAVGGraphBase:GetScrollView()
    return self.ui.rtSV
end

---@return UnityEngine.RectTransform
function N28StateAVGGraphBase:GetContent()
    return self.ui.rtContent
end
