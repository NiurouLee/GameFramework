require("skill_effect_param_base")


---@class TractionCenterType
TractionCenterType = {
    Normal = 0, --正常模式
    PetANaTuoLi = 1 --阿纳托利
}
_enum("TractionCenterType", TractionCenterType)

---@class SkillEffectMultiTractionParam : SkillEffectParamBase
_class("SkillEffectMultiTractionParam", SkillEffectParamBase)
SkillEffectMultiTractionParam = SkillEffectMultiTractionParam

function SkillEffectMultiTractionParam:Constructor(t)
    self._finalDamageIncreaseRate = tonumber(t.finalDamageIncreaseRate)
    self._casterCentered = tonumber(t.casterCentered) == 1
    self._maxMoveStep = tonumber(t.maxMoveStep) or 0
    self._forceMove = (tonumber(t.forceMove) == 1) or false
    self._enableByPickNum = t.enableByPickNum
    self._canMoveToCenter = t.canMoveToCenter
    self._tractionCenterType = t.tractionCenterType or TractionCenterType.Normal
    self._skipTractionByPickNum = t.skipTractionByPickNum
    self._isPreview = t.isPreview
    self._petANaTuoLiCanTractionSelf = t.petANaTuoLiCanTractionSelf--光灵阿纳托利特殊处理，点一个点时可以牵引怪和自己（队伍），低练度不可以牵引自己
end

function SkillEffectMultiTractionParam:GetEffectType()
    return SkillEffectType.MultiTraction
end

function SkillEffectMultiTractionParam:GetFinalDamageIncreaseRate() return self._finalDamageIncreaseRate end
function SkillEffectMultiTractionParam:IsCasterCentered() return self._casterCentered end

function SkillEffectMultiTractionParam:GetMaxMoveStep() return self._maxMoveStep end
function SkillEffectMultiTractionParam:GetEnableByPickNum()
    return self._enableByPickNum
end
function SkillEffectMultiTractionParam:GetForceMove()
    return self._forceMove
end
function SkillEffectMultiTractionParam:GetCanMoveToCenter()
    return self._canMoveToCenter
end
function SkillEffectMultiTractionParam:GetTractionCenterType()
    return self._tractionCenterType
end
function SkillEffectMultiTractionParam:GetSkipTractionByPickNum()
    return self._skipTractionByPickNum
end
function SkillEffectMultiTractionParam:GetIsPreview()
    return (self._isPreview and (self._isPreview == 1) )
end
function SkillEffectMultiTractionParam:GetPetANaTuoLiCanTractionSelf()
    return (self._petANaTuoLiCanTractionSelf and (self._petANaTuoLiCanTractionSelf == 1) )
end