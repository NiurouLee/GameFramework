require("calc_base")

---@class SkillEffectCalc_TriggerTrap
_class("SkillEffectCalc_TriggerTrap", SkillEffectCalc_Base)
SkillEffectCalc_TriggerTrap = SkillEffectCalc_TriggerTrap

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TriggerTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamTriggerTrap
    local effectParam = skillEffectCalcParam.skillEffectParam
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    local entity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local triggerType = effectParam:GetTriggerType()
    ---@type Group
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    ---@type Entity[]
    local trapEntities = trapGroup:GetEntities()
    local resultArray = {}
    if triggerType == SkillEffectTriggerTrapType.Range then
        local range = skillEffectCalcParam.skillRange or {}
        for _, pos in ipairs(range) do
            local array = utilSvc:GetTrapsAtPos(pos)
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                local trapID = cTrap:GetTrapID()
                local trapType = cTrap:GetTrapType()
                if cTrap and not eTrap:HasDeadMark() and effectParam:IsTriggerTrap(trapID, trapType) then
                    local entityID = eTrap:GetID()
                    table.insert(resultArray, SkillEffectResultTriggerTrap:New(entityID, trapID))
                end
            end
        end
    elseif triggerType == SkillEffectTriggerTrapType.Self then
        if entity:HasTrap() then
            table.insert(resultArray, SkillEffectResultTriggerTrap:New(entity:GetID(), entity:Trap():GetTrapID()))
        end
    end

    return resultArray
end
