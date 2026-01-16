--[[
    判断机关数量是否满足某种比较，是返回success，否返回failure
    eq  equal                   等于
    ne  not equal               不等于
    gt  greater than            大于
    ge  greater than or equal   大于等于
    lt  less than               小于
    le  less than or equal      小于等于
]]
---@class ActionCompareTrapCount:AINewNode
_class("ActionCompareTrapCount", AINewNode)
ActionCompareTrapCount = ActionCompareTrapCount

function ActionCompareTrapCount:OnUpdate()
    local trapId = self:GetLogicData(-1)
    local compareMode = self:GetLogicData(-2)
    local count = self:GetLogicData(-3)
    local gTrap = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local traps = gTrap:GetEntities()
    local trapCount = 0
    for _, trap in ipairs(traps) do
        if not trap:HasDeadMark() and trap:Trap():GetTrapID() == trapId then
            trapCount = trapCount + 1
        end
    end
    local res = false
    if compareMode == "eq" then
        res = trapCount == count
    elseif compareMode == "ne" then
        res = trapCount ~= count
    elseif compareMode == "gt" then
        res = trapCount > count
    elseif compareMode == "ge" then
        res = trapCount >= count
    elseif compareMode == "lt" then
        res = trapCount < count
    elseif compareMode == "le" then
        res = trapCount <= count
    end
    if res then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
