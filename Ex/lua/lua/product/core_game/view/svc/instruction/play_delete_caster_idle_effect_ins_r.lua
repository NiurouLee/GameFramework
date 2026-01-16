require("base_ins_r")
---删除待机特效
---@class PlayDeleteCasterIdleEffectInstruction: BaseInstruction
_class("PlayDeleteCasterIdleEffectInstruction", BaseInstruction)
PlayDeleteCasterIdleEffectInstruction = PlayDeleteCasterIdleEffectInstruction

function PlayDeleteCasterIdleEffectInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDeleteCasterIdleEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    self._world = casterEntity:GetOwnerWorld()
    if casterEntity:HasSuperEntity() then
        casterEntity = casterEntity:GetSuperEntity()
    end
    if casterEntity:HasEffectHolder() then
        ---@type EffectHolderComponent
        local effectHolderCmpt = casterEntity:EffectHolder()
        local effectDictList = effectHolderCmpt:GetIdleEffect()
        self:DeleteEffect(effectDictList)
    end
end

function PlayDeleteCasterIdleEffectInstruction:DeleteEffect(effectList)
    for _, entityID in pairs(effectList) do
        local entity = self._world:GetEntityByID(entityID)
        if entity then
            self._world:DestroyEntity(entity)
        end
    end
end
