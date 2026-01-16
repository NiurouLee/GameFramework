--[[
    Escape = 9, ---逃跑
]]
---@class SkillEffectCalc_Escape: SkillEffectCalc_Base
_class("SkillEffectCalc_Escape", SkillEffectCalc_Base)
SkillEffectCalc_Escape = SkillEffectCalc_Escape

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Escape:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Escape:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    local targetEntity = self._world:GetEntityByID(targetID)
    if not targetEntity then
        return
    end
    if targetEntity:HasDeadMark() then
        return
    end

    ---@type SkillEffectParam_Escape
    local param = skillEffectCalcParam:GetSkillEffectParam()

    local escapeType = param:GetEscapeType()
    local escapeParam = param:GetEscapeParam()

    local disappear = false --默认不立刻消失
    local addNum = true
    if escapeType == EscapeType.Chess then
        disappear = true

        --有指定逃脱目标的
        if escapeParam then
            ---@type ChessPetComponent
            local chessPetCmpt = targetEntity:ChessPet()
            local chessPetClassID = chessPetCmpt:GetChessPetClassID()
            if table.intable(escapeParam, chessPetClassID) then
            else
                --不是目标也可以逃脱，但是不计数
                addNum = false
            end
        end
    end

    return SkillEffectResult_Escape:New(targetID, skillEffectCalcParam.gridPos, disappear, addNum)
end
