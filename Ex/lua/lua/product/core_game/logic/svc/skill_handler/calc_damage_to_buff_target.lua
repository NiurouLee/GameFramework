--[[
    1601161 弗劳尔主动技需求
    对具有特定buff的敌人造成伤害

    因纯用buff配置比较复杂且仍然需要额外开发，征求意见后决定做成单独的技能效果
]]

require("calc_damage")

_class("SkillEffectCalc_DamageToBuffTarget", SkillEffectCalc_Damage)
---@class SkillEffectCalc_DamageToBuffTarget : SkillEffectCalc_Damage
SkillEffectCalc_DamageToBuffTarget = SkillEffectCalc_DamageToBuffTarget

---@param calcParam SkillEffectCalcParam
function SkillEffectCalc_DamageToBuffTarget:DoSkillEffectCalculator(calcParam)
    local results = {}

    ---@type SkillEffectParam_DamageToBufferTarget
    local effectParam = calcParam:GetSkillEffectParam()
    local specificBuffEffectType = effectParam:GetSpecificBuffEffectType()

    ---@type BuffLogicService
    local lbuffsvc = self._world:GetService("BuffLogic")

    local targets = calcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local e = self._world:GetEntityByID(targetID) 
        local cBuff = e:BuffComponent()
        local tBuff = cBuff:GetBuffArrayByBuffEffect(specificBuffEffectType)
        if #tBuff > 0 then
            local result = self:_CalculateSingleTarget(calcParam, targetID)
            if result then
                table.appendArray(results, result)
            end
        end
    end

    return results
end
