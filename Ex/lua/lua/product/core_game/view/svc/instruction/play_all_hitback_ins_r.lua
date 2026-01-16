--[[
    吸收幻象的逻辑，逻辑与表现未分离，需要在表现过程中执行逻辑
]]
_class("PlayAllHitBackInstruction", BaseInstruction)
---@class PlayAllHitBackInstruction:BaseInstruction
PlayAllHitBackInstruction = PlayAllHitBackInstruction

---@param casterEntity Entity
function PlayAllHitBackInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillHitBackEffectResult[]
    local tResults = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.HitBack)
    if (not tResults) or (#tResults == 0) then
        return
    end

    local playSkillService = world:GetService("PlaySkill")

    local taskArray = {}
    for _, result in ipairs(tResults) do
        if not result:GetHadPlay() then
            local beHitbackEntityID = result:GetTargetID()
            local targetEntity = world:GetEntityByID(beHitbackEntityID)
            ---@type RenderEntityService
            local resvc = world:GetService("RenderEntity")
            resvc:TurnToTarget(targetEntity, casterEntity, nil, nil, 1)
            ---处理受击及击退效果
            local processHitTaskID = playSkillService:ProcessHit(casterEntity, targetEntity, result)
            if processHitTaskID then
                table.insert(taskArray, processHitTaskID)
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskArray) do
        YIELD(TT)
    end
end
