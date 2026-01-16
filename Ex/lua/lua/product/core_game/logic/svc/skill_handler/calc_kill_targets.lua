--[[
    杀死目标
]]
---@class SkillEffectCalc_KillTargets: Object
_class("SkillEffectCalc_KillTargets", Object)
SkillEffectCalc_KillTargets = SkillEffectCalc_KillTargets

function SkillEffectCalc_KillTargets:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type MonsterShowLogicService
    self._monsterShowLogic = self._world:GetService("MonsterShowLogic")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_KillTargets:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterID = skillEffectCalcParam.casterEntityID
    local targetIDs = skillEffectCalcParam.targetEntityIDs
    ---@type  SkillEffectKillTargetsResult
    local result = SkillEffectKillTargetsResult:New()
    ---@type CalcDamageService
    local calcDamageService = self._world:GetService("CalcDamage")
    for i, targetID in ipairs(targetIDs) do
        if targetID ~= -1 then
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(targetID)
            targetEntity:Attributes():Modify("HP",0)
            if targetEntity:HasMonsterID() then

                calcDamageService:_DisableMonsterAI(targetEntity)
                self._monsterShowLogic:AddMonsterDeadMark(targetEntity)

                result:AddTargetID(targetID)
            end
        end
    end

    return result

end