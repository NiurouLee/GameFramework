require "play_skill_phase_base_r"
--@class PlaySkillSquareRingPhase: Object
_class("PlaySkillSquareRingPhase", PlaySkillPhaseBase)
PlaySkillSquareRingPhase = PlaySkillSquareRingPhase

function PlaySkillSquareRingPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseSquareRingParam
    local squareRingParam = phaseParam
    local gridEffectID = squareRingParam:GetGridEffectID()
    local bestEffectTime = squareRingParam:GetBestEffectTime()
    local ringInternalTime = squareRingParam:GetRingInternalTime()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ConvertGridElement)
    local ringGridData = result:GetTargetGridArray()
    local targetGridType = result:GetTargetElementType()

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    --遍历选中的格子，一圈圈播放特效
    for circleIndex, gridPosArray in pairs(ringGridData) do
        --Log.fatal("Circle ",circleIndex," grid effect")
        for _, gridPos in ipairs(gridPosArray) do
            GameGlobal.TaskManager():CoreGameStartTask(
                self:SkillService()._SingleGridEffect,
                self:SkillService(),
                gridEffectID,
                gridPos,
                bestEffectTime,
                targetGridType
            )
        end
        YIELD(TT, ringInternalTime)
    end
    local finishDelayTime = squareRingParam:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)
end
