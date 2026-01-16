require "play_skill_phase_base_r"
---@class PlaySkillPlayEffectPhase: PlaySkillPhaseBase
_class("PlaySkillPlayEffectPhase", PlaySkillPhaseBase)
PlaySkillPlayEffectPhase = PlaySkillPlayEffectPhase

---@param casterEntity Entity
---@param phaseParam SkillPhasePlayEffectParam
function PlaySkillPlayEffectPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---@type SkillPlayEffectType
    local effectType = phaseParam:GetPlayEffectType()
    if effectType == SkillPlayEffectType.Grid then
        local effectID = tonumber(phaseParam:GetEffectID())
        local effectPosParam = phaseParam:GetEffectPosition()
        local x = tonumber(effectPosParam[1])
        local y = tonumber(effectPosParam[2])
        local effectPos = Vector2(x, y)
        effectService:CreateWorldPositionEffect(effectID, effectPos)
    elseif effectType == SkillPlayEffectType.CasterTransform then
        self:PlayEffectCasterTransform(casterEntity, phaseParam)
    end
end

---@param casterEntity Entity
---@param phaseParam SkillPhasePlayEffectParam
function PlaySkillPlayEffectPhase:PlayEffectCasterTransform(casterEntity, phaseParam)
    local quaternionDir = phaseParam:GetQuaternionDir()
    local translationQuaternion = phaseParam:GetTranslationQuaternion()
    local translationOffset = phaseParam:GetTranslationOffset()
    ---@type GridLocationComponent
    local gridLocation = casterEntity:GridLocation()
    local center = gridLocation:Center()
    local casterDir = Vector2(gridLocation.Direction.x, gridLocation.Direction.y)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local rot = translationQuaternion * casterDir
    local offset = rot * translationOffset
    local pos = center + offset
    local dir = quaternionDir * casterDir
    effectService:CreateWorldPositionDirectionEffect(phaseParam:GetEffectID(), pos, dir)
end
