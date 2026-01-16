--[[
    判断被控的Boss数量是否满足某种比较，是返回success，否返回failure
    eq  equal                   等于
    ne  not equal               不等于
    gt  greater than            大于
    ge  greater than or equal   大于等于
    lt  less than               小于
    le  less than or equal      小于等于
]]
---@class ActionCompareBossControlledCount:AINewNode
_class("ActionCompareBossControlledCount", AINewNode)
ActionCompareBossControlledCount = ActionCompareBossControlledCount

function ActionCompareBossControlledCount:OnUpdate()
    local compareMode = self:GetLogicData(-1)
    local count = self:GetLogicData(-2)
    ---@type BuffLogicService
    local sBuffLogic = self._world:GetService("BuffLogic")
    local gBoss = self._world:GetGroup(self._world.BW_WEMatchers.Boss)
    local bosses = gBoss:GetEntities()
    local controlledCount = 0
    for _, e in ipairs(bosses) do
        local isControlled = sBuffLogic:CheckControlled(e)
        if isControlled then
            controlledCount = controlledCount + 1
        end
    end
    local res = false
    if compareMode == "eq" then
        res = controlledCount == count
    elseif compareMode == "ne" then
        res = controlledCount ~= count
    elseif compareMode == "gt" then
        res = controlledCount > count
    elseif compareMode == "ge" then
        res = controlledCount >= count
    elseif compareMode == "lt" then
        res = controlledCount < count
    elseif compareMode == "le" then
        res = controlledCount <= count
    end
    if res then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
