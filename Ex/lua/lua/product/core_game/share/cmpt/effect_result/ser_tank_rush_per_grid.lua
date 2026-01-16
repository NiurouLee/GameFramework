require("skill_effect_result_base")

_class("SkillEffectResult_TankRushPerGrid", SkillEffectResultBase)
---@class SkillEffectResult_TankRushPerGrid: SkillEffectResultBase
---@field New fun(walkResArray: MonsterMoveGridResult[], damageResultArray: SkillDamageEffectResult[], hitbackResultArray: SkillHitBackEffectResult[], isCasterDead:boolean):SkillEffectResult_TankRushPerGrid
SkillEffectResult_TankRushPerGrid = SkillEffectResult_TankRushPerGrid

function SkillEffectResult_TankRushPerGrid:GetEffectType()
    return SkillEffectType.TankRushPerGrid
end

---@param walkResArray MonsterMoveGridResult[]
---@param damageResultArray SkillDamageEffectResult[]
---@param hitbackResultArray SkillHitBackEffectResult[]
---@param isCasterDead boolean
function SkillEffectResult_TankRushPerGrid:Constructor(walkResArray, damageResultArray, hitbackResultArray, isCasterDead)
    self._walkResArray = walkResArray
    self._damageResultArray = damageResultArray
    self._hitbackResultArray = hitbackResultArray
    self._isCasterDead = isCasterDead
end

function SkillEffectResult_TankRushPerGrid:GetWalkResArray()
    return self._walkResArray
end

function SkillEffectResult_TankRushPerGrid:GetDamageResultArray()
    return self._damageResultArray
end

function SkillEffectResult_TankRushPerGrid:GetHitBackResultArray()
    return self._hitbackResultArray
end

function SkillEffectResult_TankRushPerGrid:IsCasterDead()
    return self._isCasterDead
end
