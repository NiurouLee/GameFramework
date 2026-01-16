require("base_ins_r")

---@class PlaySummonOnFixPosLimitInstruction: BaseInstruction
_class("PlaySummonOnFixPosLimitInstruction", BaseInstruction)
PlaySummonOnFixPosLimitInstruction = PlaySummonOnFixPosLimitInstruction

function PlaySummonOnFixPosLimitInstruction:Constructor(paramList)
    self._isDestroy = tonumber(paramList["isDestroy"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySummonOnFixPosLimitInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")

    if self._isDestroy ~= 1 then
        --显示当前选中的机关
        local targetEntityID = phaseContext:GetCurTargetEntityID()
        local trapEntity = world:GetEntityByID(targetEntityID)
        trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
        return
    end

    --删除机关
    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultSummonOnFixPosLimit[]
    local resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.SummonOnFixPosLimit)
    if not resultArray then
        return
    end

    for _, result in ipairs(resultArray) do
        local destroyEntityIDList = result:GetDestroyEntityIDList()
        for i, entityID in ipairs(destroyEntityIDList) do
            local entity = world:GetEntityByID(entityID)
            if entity then
                --注意 没有死亡技能，这里是直接死亡
                trapServiceRender:PlayTrapDieSkill(TT, {entity})
            end
        end
    end
end
