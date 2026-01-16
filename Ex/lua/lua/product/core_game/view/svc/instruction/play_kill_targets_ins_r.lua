

---@class PlayKillTargetsInstruction:BaseInstruction
_class("PlayKillTargetsInstruction", BaseInstruction)
PlayKillTargetsInstruction = PlayKillTargetsInstruction

function PlayKillTargetsInstruction:Constructor(paramList)

end

---@param casterEntity Entity
function PlayKillTargetsInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectKillTargetsResult[]
    local resultList = resultContainer:GetEffectResultsAsArray(SkillEffectType.KillTargets)
    local deadTaskArray = {}
    ---@type MonsterShowRenderService
    local monsterShowR = self._world:GetService("MonsterShowRender")
    if resultList then
        for i, result in ipairs(resultList) do
            local deadTargetIDs = result:GetTargetList()

            for _, id in ipairs(deadTargetIDs) do
                local e = self._world:GetEntityByID(id)
                local curDeadTaskID = TaskManager:GetInstance():CoreGameStartTask(monsterShowR._DoOneMonsterDead, monsterShowR, e)
                deadTaskArray[#deadTaskArray + 1] = curDeadTaskID
            end
            --while not TaskHelper:GetInstance():IsAllTaskFinished(deadTaskArray) do
            --        YIELD(TT)
            --end
        end
    end

end



