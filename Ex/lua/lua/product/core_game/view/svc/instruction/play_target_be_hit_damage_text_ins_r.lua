require("base_ins_r")
---@class PlayTargetBeHitDamageTextInstruction: BaseInstruction
_class("PlayTargetBeHitDamageTextInstruction", BaseInstruction)
PlayTargetBeHitDamageTextInstruction = PlayTargetBeHitDamageTextInstruction

function PlayTargetBeHitDamageTextInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetBeHitDamageTextInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local curDamageIndex = phaseContext:GetCurDamageResultIndex()
    local curDamageInfoIndex = phaseContext:GetCurDamageInfoIndex()
    local curDamageResultStageIndex = phaseContext:GetCurDamageResultStageIndex()

    local damageResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, curDamageResultStageIndex)

    ---@type SkillDamageEffectResult
    local damageResult = damageResultArray[curDamageIndex]
    ---@type DamageInfo
    local damageInfo = damageResult:GetDamageInfo(curDamageInfoIndex)

    if not damageInfo then
        return
    end

    local damageGridPos = damageResult:GetGridPos()

    local skillID = skillEffectResultContainer:GetSkillID()
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    if not targetEntity then
        return
    end

    local damageShowType = playDamageService:SingleOrGrid(skillID)
    damageInfo:SetShowType(damageShowType)
    damageInfo:SetRenderGridPos(damageGridPos)
    --伤害飘字
    playDamageService:AsyncUpdateHPAndDisplayDamage(targetEntity, damageInfo)

    --闪白效果
    ---@type MaterialAnimationComponent
    local mtrAni = targetEntity:MaterialAnimationComponent()
    if mtrAni then
        mtrAni:PlayHit()
    end
end
