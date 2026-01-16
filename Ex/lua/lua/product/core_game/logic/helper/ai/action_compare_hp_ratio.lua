--[[
    判断血量比例是否满足某种比较，是返回success，否返回failure
    eq  equal                   等于
    ne  not equal               不等于
    gt  greater than            大于
    ge  greater than or equal   大于等于
    lt  less than               小于
    le  less than or equal      小于等于
]]
---@class ActionCompareHPRatio:AINewNode
_class("ActionCompareHPRatio", AINewNode)
ActionCompareHPRatio = ActionCompareHPRatio

function ActionCompareHPRatio:Constructor()
end

function ActionCompareHPRatio:OnUpdate()
    if self.m_entityOwn:HasCrazyMode() then --已经狂暴
        return AINewNodeStatus.Failure
    end
    local compareMode = self:GetLogicData(-1)
    local percent = self:GetLogicData(-2)
    ---@type AttributesComponent
    local cAttributes = self.m_entityOwn:Attributes()
    local hp = cAttributes:GetCurrentHP()
    local maxHp = cAttributes:CalcMaxHp()
    local ratio = hp / maxHp
    local res = false
    if compareMode == "eq" then
        res = ratio == percent
    elseif compareMode == "ne" then
        res = ratio ~= percent
    elseif compareMode == "gt" then
        res = ratio > percent
    elseif compareMode == "ge" then
        res = ratio >= percent
    elseif compareMode == "lt" then
        res = ratio < percent
    elseif compareMode == "le" then
        res = ratio <= percent
    end
    if res then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
