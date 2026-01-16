require("base_ins_r")

---@class PlayAllGridPurifyInstruction: BaseInstruction
_class("PlayAllGridPurifyInstruction", BaseInstruction)
PlayAllGridPurifyInstruction = PlayAllGridPurifyInstruction

---@param casterEntity Entity 施法者
---@param phaseContext SkillPhaseContext 当前指令集合的上下文，用于存储数据
function PlayAllGridPurifyInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local container = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_GridPurify[]
    local results = container:GetEffectResultsAsArray(SkillEffectType.GridPurify)

    if (not results) or (#results == 0) then
        return
    end

    local traps = {}
    for _, result in ipairs(results) do
        local ids = result:GetPurifiedTrapIDs()
        for __, id in ipairs(ids) do
            local e = world:GetEntityByID(id)
            if e then
                table.insert(traps, e)
            end
        end
    end

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    -- 净化格子的需求是【被净化的格子不释放死亡技能】，逻辑上也不会计算死亡技能
    trapServiceRender:PlayTrapDieSkill(TT, traps, true)
end
