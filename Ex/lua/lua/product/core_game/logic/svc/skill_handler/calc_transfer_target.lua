--[[
    TransferTarget = 151, --将目标数据传递给表现
]]
_class("SkillEffectCalc_TransferTarget", Object)
---@class SkillEffectCalc_TransferTarget: Object
SkillEffectCalc_TransferTarget = SkillEffectCalc_TransferTarget

---
function SkillEffectCalc_TransferTarget:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TransferTarget:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    local gridPos = skillEffectCalcParam.gridPos
    for _, targetID in ipairs(targets) do
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(targetID)
        if targetEntity then
            ---@type SkillEffectResultTransferTarget
            local result = SkillEffectResultTransferTarget:New(targetID, gridPos)
            if result then
                table.insert(results, result)
            end
        end
    end

    return results
end
