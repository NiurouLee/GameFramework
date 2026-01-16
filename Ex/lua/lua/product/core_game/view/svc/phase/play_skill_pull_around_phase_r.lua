require "play_skill_phase_base_r"
---@class PlaySkillPullAroundPhase: PlaySkillPhaseBase
_class("PlaySkillPullAroundPhase", PlaySkillPhaseBase)
PlaySkillPullAroundPhase = PlaySkillPullAroundPhase

function PlaySkillPullAroundPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhasePullAroundParam
    local pullAroundParam = phaseParam
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.PullAround)
    local beHitbackEntityID = result:GetTargetID()
    local targetPos = result:GetGridPos()
    local pieceChangeTable = result:GetGridElementChangeTable()

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    local targetEntity = self._world:GetEntityByID(beHitbackEntityID)
    local emptyGrids = {}
    for pos, pieceType in pairs(pieceChangeTable) do
        emptyGrids[#emptyGrids + 1] = boardServiceRender:CreateEmptyGridEffectEntity(pos)
    end

    ---@type SkillDamageEffectResult
    local damageResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Damage)
    local skillID = skillEffectResultContainer:GetSkillID()
    if damageResult then
        ---调用统一处理被击的逻辑
        local beHitParam = HandleBeHitParam:New()
            :SetHandleBeHitParam_CasterEntity(casterEntity)
            :SetHandleBeHitParam_TargetEntity(targetEntity)
            :SetHandleBeHitParam_HitAnimName(pullAroundParam:GetHitAnimationName())
            :SetHandleBeHitParam_DamageInfo(damageResult:GetDamageInfo(1))
            :SetHandleBeHitParam_DamagePos(damageResult:GetGridPos())
            :SetHandleBeHitParam_DeathClear(false)
            :SetHandleBeHitParam_IsFinalHit(false)
            :SetHandleBeHitParam_SkillID(skillID)

        self:SkillService():HandleBeHit(TT, beHitParam)
    else
        targetEntity:SetAnimatorControllerTriggers({pullAroundParam:GetHitAnimationName()})
    end

    local gridPos = boardServiceRender:GetRealEntityGridPos(targetEntity)
    targetEntity:AddGridMove(pullAroundParam:GetMoveSpeed(), targetPos, gridPos)
    while targetEntity:GridMove() do
        YIELD(TT)
    end

    ---销毁星空格子
    for i = 1, #emptyGrids do
        self._world:DestroyEntity(emptyGrids[i])
    end
    for pos, pieceType in pairs(pieceChangeTable) do
        boardServiceRender:ReCreateGridEntity(pieceType, pos, false)
    end
    ---玩家脚下格子变为灰格子
    boardServiceRender:ReCreateGridEntity(PieceType.None, targetEntity:GridLocation().Position)
end
