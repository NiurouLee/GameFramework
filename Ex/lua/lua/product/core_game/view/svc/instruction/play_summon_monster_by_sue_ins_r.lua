require("base_ins_r")
---@class PlaySummonMonsterBySummonEveryThingInstruction: BaseInstruction
_class("PlaySummonMonsterBySummonEveryThingInstruction", BaseInstruction)
PlaySummonMonsterBySummonEveryThingInstruction = PlaySummonMonsterBySummonEveryThingInstruction

function PlaySummonMonsterBySummonEveryThingInstruction:Constructor(paramList)
    self._monsterID = tonumber(paramList["monsterID"])
end

function PlaySummonMonsterBySummonEveryThingInstruction:GetCacheResource()
    local t = {}
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySummonMonsterBySummonEveryThingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = world:GetService("PlaySkillInstruction")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillEffectResult_SummonEverything[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    if not summonResultArray then
        return
    end

    local listWaitTask = {}
    for i = 1, #summonResultArray do
        ---@type SkillEffectResult_SummonEverything
        local summonRes = summonResultArray[i]
        ---@type SkillEffectEnum_SummonType
        local summonType = summonRes:GetSummonType()
        local summonMonsterID = summonRes:GetSummonID()
        if summonType == SkillEffectEnum_SummonType.Monster and self._monsterID == summonMonsterID then
            local nTaskID =
                GameGlobal.TaskManager():CoreGameStartTask(
                sPlaySkillInstruction.ShowSummonAction,
                sPlaySkillInstruction,
                world,
                summonRes
            )
            table.insert(listWaitTask, nTaskID)
        end
    end

    --等待召唤技能的表现
    if table.count(listWaitTask) > 0 then
        while not TaskHelper:GetInstance():IsAllTaskFinished(listWaitTask) do
            YIELD(TT)
        end
    end
end
