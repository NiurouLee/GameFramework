--[[
    ----------------------------------------------------------------
    SkillEffectMonsterMoveFrontAttackResult 
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")

_class("SkillEffectMonsterMoveFrontAttackResult", SkillEffectResultBase)
---@class SkillEffectMonsterMoveFrontAttackResult: SkillEffectResultBase
SkillEffectMonsterMoveFrontAttackResult = SkillEffectMonsterMoveFrontAttackResult

function SkillEffectMonsterMoveFrontAttackResult:GetEffectType()
    return SkillEffectType.MonsterMoveFrontAttack
end
---@param walkResultList MonsterMoveGridResult[]
function SkillEffectMonsterMoveFrontAttackResult:Constructor(walkResultList,isDead)
    self._walkResultList = walkResultList
    self._isDead = isDead
end
---@return MonsterWalkResult[]
function SkillEffectMonsterMoveFrontAttackResult:GetWalkResultList()
    return self._walkResultList
end

function SkillEffectMonsterMoveFrontAttackResult:IsCasterDead()
    return self._isDead
end

_class( "MonsterMoveFrontAttackResult", MonsterWalkResult )
---@class MonsterMoveFrontAttackResult: MonsterWalkResult
MonsterMoveFrontAttackResult = MonsterMoveFrontAttackResult

function MonsterMoveFrontAttackResult:Constructor()
    --self._flushTrapID = nil
end

-- function MonsterMoveFrontAttackResult:SetFlushTrapID(trapID)
--     self._flushTrapID = trapID
-- end

-- function MonsterMoveFrontAttackResult:GetFlushTrapID()
--     return self._flushTrapID
-- end