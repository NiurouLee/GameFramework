require("calc_base")

_class("SkillEffectCalc_ChangeElement", SkillEffectCalc_Base)
---@class SkillEffectCalc_ChangeElement:SkillEffectCalc_Base
SkillEffectCalc_ChangeElement = SkillEffectCalc_ChangeElement

function SkillEffectCalc_ChangeElement:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ChangeElement:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectChangeElementParam
    local skillParam = skillEffectCalcParam.skillEffectParam
    local type = skillParam:GetType()
    local targetElement = skillParam:GetElement()
    local targetID = skillEffectCalcParam.casterEntityID
    if type == EffectChangeElementType.ByCurrentTeamLeader then
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        ---@type Entity
        local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
        ---@type ElementComponent
        local elementCmpt = teamLeaderEntity:Element()
        targetElement = elementCmpt:GetPrimaryType()
        targetID = skillEffectCalcParam:GetTargetEntityIDs()[1]
    elseif type == EffectChangeElementType.RestoreMonsterCfgElement then
        local entity = self._world:GetEntityByID(targetID)
        if entity:HasMonsterID() then
            local monsterID = entity:MonsterID():GetMonsterID()
            local configService = self._world:GetService("Config")
            ---@type MonsterConfigData
            local monsterConfigData = configService:GetMonsterConfigData()
            targetElement = monsterConfigData:GetMonsterElementType(monsterID)
        end
    end

    ---使用SkillHolder释放此效果 [KZY:SkillHolder去Self]
    if skillParam:IsChangeSuperElement() then
        ---@type Entity
        local entity = self._world:GetEntityByID(targetID)
        ---@type Entity
        local superEntity = entity:GetSuperEntity()
        if superEntity then
            targetID = superEntity:GetID()
        end
    end

    local result = SkillEffectResultChangeElement:New(targetID, targetElement)
    return result
end
