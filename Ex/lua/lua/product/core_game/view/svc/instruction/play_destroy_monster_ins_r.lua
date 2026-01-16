require("base_ins_r")
---@class PlayDestroyMonsterInstruction: BaseInstruction
_class("PlayDestroyMonsterInstruction", BaseInstruction)
PlayDestroyMonsterInstruction = PlayDestroyMonsterInstruction

function PlayDestroyMonsterInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDestroyMonsterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyMonster)
    if not resultArray then
        return
    end
    local index = phaseContext:GetCurResultIndexByType(SkillEffectType.DestroyMonster)
    local result = resultArray[index]
    if not result then
        return
    end

    local eID = result:GetEntityID()
    local eMonster = world:GetEntityByID(eID)
    if not eMonster then
        return
    end

    ---@type MonsterShowRenderService
    local svc = world:GetService("MonsterShowRender")
    TaskManager:GetInstance():CoreGameStartTask(function(TT)
        svc:_DoOneMonsterDead(TT, eMonster)
    end)
end
