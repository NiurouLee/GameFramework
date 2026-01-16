require("base_ins_r")

---@class PlayTriggerTrapInstruction: BaseInstruction
_class("PlayTriggerTrapInstruction", BaseInstruction)
PlayTriggerTrapInstruction = PlayTriggerTrapInstruction

function PlayTriggerTrapInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTriggerTrapInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()

    if not routineCmpt then
        return
    end

    ---@type SkillEffectResultTriggerTrap[]
    local resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.TriggerTrap)

    if not resultArray then
        return
    end

    local eTrap = {}

    for _, result in ipairs(resultArray) do
        local entity = world:GetEntityByID(result:GetEntityID())
        if entity then
            table.insert(eTrap, entity)
        end
    end

    if table.count(eTrap) == 0 then
        return
    end

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:PlayTrapTriggerSkillTasks(TT, eTrap, false, casterEntity)

    trapServiceRender:DestroyTrapList(TT, eTrap)
end
