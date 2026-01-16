--[[
    PetSacrificeSuperGridTraps = 174, ---光灵米洛斯 吸收范围内强化格子机关，并发送通知。
]]

_class("SkillEffectCalc_PetSacrificeSuperGridTraps", Object)
---@class SkillEffectCalc_PetSacrificeSuperGridTraps: Object
SkillEffectCalc_PetSacrificeSuperGridTraps = SkillEffectCalc_PetSacrificeSuperGridTraps

function SkillEffectCalc_PetSacrificeSuperGridTraps:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PetSacrificeSuperGridTraps:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectPetSacrificeSuperGridTrapsParam
    local param = skillEffectCalcParam.skillEffectParam
    local fakeTriggerTrapSkillID = 500202--强化格子触发技能ID 用于模拟通知，触发现有光灵被动
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    local trapID = param:GetTrapID()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger") 
    ---@type number[]
    local traps = {}
    local trapEntitys = {}
    local extraGrids = {}
    for _, pos in ipairs(skillEffectCalcParam.skillRange) do
        local findSuperGrid = false
        ---@type table<number, Entity>
        local entities = utilSvc:GetTrapsAtPos(pos)
        for _, entity in ipairs(entities) do
            local trapComponent = entity:Trap()
            if trapID[trapComponent:GetTrapID()] then
                table.insert(traps, entity:GetID())
                table.insert(trapEntitys,entity)
                findSuperGrid = true
            end
        end
        if not findSuperGrid then
            table.insert(extraGrids,pos)
        end
    end
    for index, entity in ipairs(trapEntitys) do
        triggerSvc:Notify(NTPetMinosAbsorbTrap:New(entity,casterEntity))
        local fakeNt = NTTrapSkillStart:New(entity, fakeTriggerTrapSkillID, teamEntity)
        fakeNt:SetIsActiveSkillFake(true)
        triggerSvc:Notify(fakeNt)
    end
    
    local result =   SkillEffectResultPetSacrificeSuperGridTraps:New(traps)
    result:SetExtraGrids(extraGrids)
    return { result }
end
