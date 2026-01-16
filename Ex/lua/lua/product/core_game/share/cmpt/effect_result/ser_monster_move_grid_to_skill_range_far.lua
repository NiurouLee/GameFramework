--[[
    ----------------------------------------------------------------
    SkillEffectMonsterMoveGridToSkillRangeFarResult 
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")

_class("SkillEffectMonsterMoveGridToSkillRangeFarResult", SkillEffectResultBase)
---@class SkillEffectMonsterMoveGridToSkillRangeFarResult: SkillEffectResultBase
SkillEffectMonsterMoveGridToSkillRangeFarResult = SkillEffectMonsterMoveGridToSkillRangeFarResult

function SkillEffectMonsterMoveGridToSkillRangeFarResult:GetEffectType()
    return SkillEffectType.MonsterMoveGridToSkillRangeFar
end
---@param walkResultList MonsterMoveGridResult[]
function SkillEffectMonsterMoveGridToSkillRangeFarResult:Constructor(walkResultList,isDead)
    self._walkResultList = walkResultList
    self._isDead = isDead
end
---@return MonsterWalkResult[]
function SkillEffectMonsterMoveGridToSkillRangeFarResult:GetWalkResultList()
    return self._walkResultList
end

function SkillEffectMonsterMoveGridToSkillRangeFarResult:IsCasterDead()
    return self._isDead
end

_class( "MonsterMoveSkillRangeFarResult", MonsterWalkResult )
---@class MonsterMoveSkillRangeFarResult: MonsterWalkResult
MonsterMoveSkillRangeFarResult = MonsterMoveSkillRangeFarResult

function MonsterMoveSkillRangeFarResult:Constructor()
    self._flushTrapID = nil
end

function MonsterMoveSkillRangeFarResult:SetFlushTrapID(trapID)
    self._flushTrapID = trapID
end

function MonsterMoveSkillRangeFarResult:GetFlushTrapID()
    return self._flushTrapID
end