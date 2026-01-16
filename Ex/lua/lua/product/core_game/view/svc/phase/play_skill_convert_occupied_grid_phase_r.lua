require "play_skill_phase_base_r"

_class("PlaySkillConvertOccupiedGrid", PlaySkillPhaseBase)
PlaySkillConvertOccupiedGrid = PlaySkillConvertOccupiedGrid

function PlaySkillConvertOccupiedGrid:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.ConvertOccupiedGridElement)

    -- 该效果逻辑可能会不创建任何result（比如没有选中任何目标）
    if not resultArray then
        return
    end

    local gridEffectID = phaseParam:GetGridEffectID()
    local bestEffectTime = phaseParam:GetBestEffectTime()

    local taskIds = {}
    --格子转色
    for _, result in ipairs(resultArray) do
        local gridPosArray = result:GetTargetGridArray()
        local targetGridType = result:GetTargetElementType()
        for _, gridPos in ipairs(gridPosArray) do
            local id =
                GameGlobal.TaskManager():CoreGameStartTask(
                self:SkillService()._SingleGridEffect,
                self:SkillService(),
                gridEffectID,
                gridPos, --特殊处理，否则报错
                bestEffectTime,
                targetGridType
            )
            taskIds[#taskIds + 1] = id
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIds) do
        YIELD(TT)
    end
end
