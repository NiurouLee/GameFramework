require "play_skill_phase_base_r"
---@class PlaySkillPlayAudioPhase: PlaySkillPhaseBase
_class("PlaySkillPlayAudioPhase", PlaySkillPhaseBase)
PlaySkillPlayAudioPhase = PlaySkillPlayAudioPhase

---@param casterEntity Entity
---@param phaseParam SkillPhasePlayAudioParam
---播放音效语音表现
function PlaySkillPlayAudioPhase:PlayFlight(TT, casterEntity, phaseParam)
    local audioType = phaseParam:GetAudioType()

    if audioType == SkillAudioType.Cast then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

        --如果配置了斜向普攻的表现 and 本次攻击是斜向的
        local isSlantAttack
        if phaseParam:GetSlantAudioID() then
            local attackPos = casterEntity:GetRenderGridPosition()
            local damageResult = skillEffectResultContainer:GetEffectResultsByType(SkillEffectType.Damage)
            if damageResult and #damageResult.array > 0 then
                local damage = damageResult.array[1]
                local damagePos = damage:GetGridPos()
                if attackPos.x ~= damagePos.x and attackPos.y ~= damagePos.y then
                    isSlantAttack = true
                end
            end
        end

        local delayTime =
            phaseParam:GetSoundDelay(skillEffectResultContainer:IsLastNormalAttackAtOnGrid(), isSlantAttack)
        if delayTime > 0 then
            YIELD(TT, delayTime)
        end
        AudioHelperController.PlayInnerGameSfx(phaseParam:GetAudioID(isSlantAttack))
    elseif audioType == SkillAudioType.Hit then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
        ---@type SkillDamageEffectResult
        local damageResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Damage)

        if not damageResult then
            return
        end

        ---@type DamageInfo
        local damageInfo = damageResult:GetDamageInfo(1)
        if damageInfo and damageInfo:GetDamageType() == DamageType.Guard then
            local beAttackEntityID = damageResult:GetTargetID()
            local targetEntity = self._world:GetEntityByID(beAttackEntityID)
            local hitSoundID = 2002 --TODO 删除这个类
            AudioHelperController.PlayInnerGameSfx(hitSoundID)
        elseif damageInfo and damageInfo:GetDamageType() == DamageType.Miss then
        else
            AudioHelperController.PlayInnerGameSfx(phaseParam:GetAudioID())
        end
    elseif audioType == SkillAudioType.Voice then
        AudioHelperController.PlayInnerGameVoiceByAudioId(phaseParam:GetAudioID())
    end
end
