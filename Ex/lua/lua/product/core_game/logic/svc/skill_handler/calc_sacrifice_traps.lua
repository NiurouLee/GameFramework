--[[
    SacrificeTraps = 157, --吸收机关
]]

_class("SkillEffectCalc_SacrificeTraps", Object)
---@class SkillEffectCalc_SacrificeTraps: Object
SkillEffectCalc_SacrificeTraps = SkillEffectCalc_SacrificeTraps

function SkillEffectCalc_SacrificeTraps:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SacrificeTraps:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectSacrificeTrapsParam
    local param = skillEffectCalcParam.skillEffectParam

    local trapID = param:GetTrapID()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger") 
    ---@type number[]
    local traps = {}
    for _, pos in ipairs(skillEffectCalcParam.skillRange) do
        ---@type table<number, Entity>
        local entities = utilSvc:GetTrapsAtPos(pos)
        for _, entity in ipairs(entities) do

            local trapComponent = entity:Trap()
            if trapID[trapComponent:GetTrapID()] then
                triggerSvc:Notify(NTMinosAbsorbTrap:New(entity))
                table.insert(traps, entity:GetID())
            end
        end
    end
    local result =   SkillEffectResultSacrificeTraps:New(traps)
    return { result }
end
