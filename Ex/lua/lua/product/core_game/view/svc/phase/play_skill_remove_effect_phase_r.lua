require "play_skill_phase_base_r"
---@class PlaySkillRemoveEffectPhase: PlaySkillPhaseBase
_class("PlaySkillRemoveEffectPhase", PlaySkillPhaseBase)
PlaySkillRemoveEffectPhase = PlaySkillRemoveEffectPhase

---@param casterEntity Entity
---@param phaseParam SkillPhaseRemoveEffectParam
---移除特效表现
function PlaySkillRemoveEffectPhase:PlayFlight(TT, casterEntity, phaseParam)
    local e = casterEntity
    if casterEntity:HasSuperEntity() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end
    ---@type EffectHolderComponent
    local holderCmp = e:EffectHolder()
    if not holderCmp then
        return
    end
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local effIds = phaseParam:GetEffectIDList()
    local idDic = holderCmp:GetEffectIDEntityDic()
    if effIds then
        for _, id in pairs(effIds) do
            local entityList = idDic[id]
            if entityList then
                for k, entityID in pairs(entityList) do
                    if entityID then
                        local entity = self._world:GetEntityByID(entityID)
                        if entity then
                            self._world:DestroyEntity(entity)
                        end
                    end
                end
                idDic[id] = nil
            end
        end
    end
end
