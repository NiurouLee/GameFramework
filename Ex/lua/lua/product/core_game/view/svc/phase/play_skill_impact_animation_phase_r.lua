require "play_skill_phase_base_r"

---@class PlaySkillImpactAnimationPhase:PlaySkillPhaseBase
_class("PlaySkillImpactAnimationPhase", PlaySkillPhaseBase)
PlaySkillImpactAnimationPhase = PlaySkillImpactAnimationPhase

---@param casterEntity Entity
---@param phaseParam SkillPhaseImpactAnimationParam
function PlaySkillImpactAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type PlaySkillService
    local skillService = self:SkillService()
    ---@type GridLocationComponent
    local gridLocation = casterEntity:GridLocation()
    local center = gridLocation:Center()
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local res = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Damage)
    self:HideArmEffect(casterEntity)
    YIELD(TT, phaseParam:GetShowDelay()) --延迟
    if res then
        effectService:ShowIdleEffect(casterEntity, true)
    else
        ---@type EffectHolderComponent
        local effectHolderCmpt = casterEntity:EffectHolder() --虚弱特效，这两个特效未来也许应该跟着buff走
        if effectHolderCmpt ~= nil then
            local weakEffectIDLeft = 36
            local weakEffectIDRight = 37
            local weakEffectEntity = effectService:CreateEffect(weakEffectIDLeft, casterEntity)
            effectHolderCmpt:AttachWeakEffect(weakEffectEntity:GetID())
            weakEffectEntity = effectService:CreateEffect(weakEffectIDRight, casterEntity)
            effectHolderCmpt:AttachWeakEffect(weakEffectEntity:GetID())
        end
    end
end

---隐藏蓄力特效
function PlaySkillImpactAnimationPhase:HideArmEffect(casterEntity)
    ---@type EffectHolderComponent
    local cEffectHolder = casterEntity:EffectHolder()
    local dict = cEffectHolder:GetEffectIDEntityDic()
    local lEff, rEff = 24, 25
    local lIdList, rIdList = dict[lEff], dict[rEff]
    self:DestroyEntity(lIdList)
    self:DestroyEntity(rIdList)
    dict[lEff] = nil
    dict[rEff] = nil
end

function PlaySkillImpactAnimationPhase:DestroyEntity(eIdList)
    if eIdList then
        for i, v in ipairs(eIdList) do
            local e = self._world:GetEntityByID(v)
            if e then
                self._world:DestroyEntity(e)
            end
        end
    end
end
