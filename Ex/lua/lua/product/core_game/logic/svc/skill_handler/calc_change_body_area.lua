--[[
    ChangeBodyArea = 165, --修改BodyArea
]]
---@class SkillEffectCalc_ChangeBodyArea: Object
_class("SkillEffectCalc_ChangeBodyArea", Object)
SkillEffectCalc_ChangeBodyArea = SkillEffectCalc_ChangeBodyArea

function SkillEffectCalc_ChangeBodyArea:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ChangeBodyArea:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamChangeBodyArea
    local skillEffectParam = skillEffectCalcParam.skillEffectParam

    local bodyArea = skillEffectParam:GetBodyArea()
    local newBodyArea = {}
    for i, v in ipairs(bodyArea) do
        local pos = Vector2(v[1], v[2])
        table.insert(newBodyArea, pos)
    end

    local results = {}
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        ---@type SkillEffectResultChangeBodyArea
        local result = SkillEffectResultChangeBodyArea:New(targetID, newBodyArea)
        if result then
            table.insert(results, result)
        end
    end

    return results
end
