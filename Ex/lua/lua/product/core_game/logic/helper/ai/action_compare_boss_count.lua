--[[
    判断Boss数量是否满足某种比较，是返回success，否返回failure
    eq  equal                   等于
    ne  not equal               不等于
    gt  greater than            大于
    ge  greater than or equal   大于等于
    lt  less than               小于
    le  less than or equal      小于等于
]]
---@class ActionCompareBossCount:AINewNode
_class("ActionCompareBossCount", AINewNode)
ActionCompareBossCount = ActionCompareBossCount

function ActionCompareBossCount:OnUpdate()
    local compareMode = self:GetLogicData(-1)
    local count = self:GetLogicData(-2)
    local gBoss = self._world:GetGroup(self._world.BW_WEMatchers.Boss)
    local bosses = gBoss:GetEntities()
    local bossCount = table.count(bosses)
    local res = false
    if compareMode == "eq" then
        res = bossCount == count
    elseif compareMode == "ne" then
        res = bossCount ~= count
    elseif compareMode == "gt" then
        res = bossCount > count
    elseif compareMode == "ge" then
        res = bossCount >= count
    elseif compareMode == "lt" then
        res = bossCount < count
    elseif compareMode == "le" then
        res = bossCount <= count
    end
    if res then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
