--[[
    ----------------------------------------------------------------
    SkillEffectMonsterMoveGridByElementResult 
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")

_class("SkillEffectMonsterMoveGridByElementResult", SkillEffectResultBase)
---@class SkillEffectMonsterMoveGridByElementResult: SkillEffectResultBase
SkillEffectMonsterMoveGridByElementResult = SkillEffectMonsterMoveGridByElementResult

function SkillEffectMonsterMoveGridByElementResult:GetEffectType()
    return SkillEffectType.MonsterMoveGridByMonsterElement
end
---@param walkResultList MonsterMoveGridResult[]
function SkillEffectMonsterMoveGridByElementResult:Constructor(walkResultList,isDead)
    self._walkResultList = walkResultList
    self._isDead = isDead
end
---@return MonsterWalkResult[]
function SkillEffectMonsterMoveGridByElementResult:GetWalkResultList()
    return self._walkResultList
end

function SkillEffectMonsterMoveGridByElementResult:IsCasterDead()
    return self._isDead
end