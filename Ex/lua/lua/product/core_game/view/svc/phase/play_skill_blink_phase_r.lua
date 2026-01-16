require "play_skill_phase_base_r"

---@class PlaySkillBlinkPhase: PlaySkillPhaseBase
_class("PlaySkillBlinkPhase", PlaySkillPhaseBase)
PlaySkillBlinkPhase = PlaySkillBlinkPhase

---@param phaseParam SkillPhaseBlinkParam
---@param casterEntity Entity
function PlaySkillBlinkPhase:PlayFlight(TT, casterEntity, phaseParam, phaseIndex, phaseAdapter)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    --前摇
    casterEntity:SetAnimatorControllerTriggers({phaseParam.castAnimation})
    if (phaseParam.castEffectID) and (phaseParam.castEffectID ~= 0) then
        effectService:CreateEffect(phaseParam.castEffectID, casterEntity)
    end
    YIELD(TT, phaseParam.castDuration)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local skillResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport)

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")

    --消失
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportHide, false, skillResult)
    ---瞬移
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportMove, false, skillResult)
    ---延时
    YIELD(TT, phaseParam.stealthDuration)
    ---出现
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.TeleportShow, false, skillResult)
    ---buff
    playSkillInstructionService:Teleport(TT, casterEntity, RoleShowType.BuffNotify, false, skillResult)
    ---显示动作和特效
    casterEntity:SetAnimatorControllerTriggers({phaseParam.appearAnimation})
    if (phaseParam.appearEffectID) and (phaseParam.appearEffectID ~= 0) then
        effectService:CreateEffect(phaseParam.appearEffectID, casterEntity)
    end

    YIELD(TT, phaseParam.appearDuration)

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RemovePrismAt(skillResult:GetPosNew())
end
