require("base_ins_r")

---@class PlayTargetFallToDeathInstruction: BaseInstruction
_class("PlayTargetFallToDeathInstruction", BaseInstruction)
PlayTargetFallToDeathInstruction = PlayTargetFallToDeathInstruction

function PlayTargetFallToDeathInstruction:Constructor(paramList)
    self._fallTime = tonumber(paramList["fallTime"]) --摔落的时间
    self._fallDistance = tonumber(paramList["fallDistance"]) --摔落的距离
    self._finishWaitTime = tonumber(paramList["finishWaitTime"]) or 500 --结束后的等待的时间
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetFallToDeathInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillDamageEffectResult[]
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    if damageResultArray == nil then
        return
    end
    local damageResCount = #damageResultArray
    if damageResCount <= 0 then
        return
    end

    local targetEntityID = damageResultArray[1]:GetTargetID()
    if targetEntityID == nil or targetEntityID < 0 then
        return
    end

    ---@type DamageInfo
    local damageInfo = damageResultArray[1]:GetDamageInfo(1)

    local targetEntity = world:GetEntityByID(targetEntityID)

    if not targetEntity then
        return
    end

    local targetObject = targetEntity:View():GetGameObject()

    ---@type UnityEngine.Transform
    local targetTransform = targetObject.transform

    local curPos = targetTransform.position
    local targetPos = curPos + Vector3(0, -self._fallDistance, 0)

    local dotween = targetTransform:DOMove(targetPos, self._fallTime / 1000, false)

    YIELD(TT, self._fallTime)

    --刷新UI血条
    ---@type PlayDamageService
    local playDamageSvc = world:GetService("PlayDamage")
    playDamageSvc:UpdateTargetHPBar(TT, targetEntity, damageInfo)

    YIELD(TT, self._finishWaitTime)
end
