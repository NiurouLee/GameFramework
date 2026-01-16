require("base_ins_r")
---按照召唤位置排序显示召唤出来的东西
---@class ShowSummonThingBySortPosInstruction: BaseInstruction
_class("ShowSummonThingBySortPosInstruction", BaseInstruction)
ShowSummonThingBySortPosInstruction = ShowSummonThingBySortPosInstruction

function ShowSummonThingBySortPosInstruction:Constructor(paramList)
    self._sortType = tonumber(paramList["sortType"])
    self._eachDelayTime = tonumber(paramList["eachDelayTime"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function ShowSummonThingBySortPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("ShowSummonThingBySortPosInstruction has no skill effect result")
        return
    end

    ---@type SkillEffectResult_SummonEverything[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    if not summonResultArray then
        return
    end

    local sortedResultArray = nil
    if self._sortType == GridRangeSortType.XYSmallToLargeSort then
        sortedResultArray = self:_XYSmallToLargeSort(summonResultArray)
    end

    local taskIDs = {}
    for _, summonRes in ipairs(sortedResultArray) do
        if not summonRes then
            Log.fatal("### ShowSummonThingBySortPosInstruction SkillEffectResult_SummonEverything nil")
            return
        end
        ---@type SkillEffectEnum_SummonType
        local summonType = summonRes:GetSummonType()
        if summonType == SkillEffectEnum_SummonType.Monster then
            local summonMonsterData = summonRes:GetMonsterData()
            local summonTransformData = summonRes:GetSummonTransformData()

            ---@type Entity
            local entityWork = world:GetEntityByID(summonMonsterData.m_entityWorkID)
            ---@type MonsterShowRenderService
            local sMonsterShowRender = world:GetService("MonsterShowRender")
            local taskID = TaskManager:GetInstance():CoreGameStartTask(
                function(TT)
                    sMonsterShowRender:ShowSummonMonster(TT, entityWork, summonTransformData, true)
                end
            )
            table.insert(taskIDs, taskID)

            YIELD(TT, self._eachDelayTime)

        elseif summonType == SkillEffectEnum_SummonType.Trap then
            ---暂时不支持
        else
            Log.fatal("### ShowSummonThingBySortPosInstruction summonType=", summonType)
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
end

---@type summonResultArray SkillEffectResult_SummonEverything[]
function ShowSummonThingBySortPosInstruction:_XYSmallToLargeSort(summonResultArray)
    ---@type SkillEffectResult_SummonEverything[]
    local sortedArray = {}
    ---@type SkillEffectResult_SummonEverything[]
    local tmpList = {}
    for _, result in pairs(summonResultArray) do
        table.insert(tmpList, result)
    end

    local sortDicFunc = function(a, b)
        local posA = a:GetSummonPos()
        local posB = b:GetSummonPos()
        local disA = posA.x + posA.y
        local disB = posB.x + posB.y
        if disA == disB then
            return posA.x > posB.x
        else
            return disA < disB
        end
    end
    table.sort(tmpList, sortDicFunc)
    for _, summonRes in ipairs(tmpList) do
        table.insert(sortedArray, summonRes)
    end
    return sortedArray
end
