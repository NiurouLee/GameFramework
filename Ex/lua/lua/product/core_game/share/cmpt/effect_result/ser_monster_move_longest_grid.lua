--[[
    ----------------------------------------------------------------
    SkillEffectMonsterMoveLongestGridResult 
    ----------------------------------------------------------------
]]
require("skill_effect_result_base")

_class("SkillEffectMonsterMoveLongestGridResult", SkillEffectResultBase)
---@class SkillEffectMonsterMoveLongestGridResult: SkillEffectResultBase
SkillEffectMonsterMoveLongestGridResult = SkillEffectMonsterMoveLongestGridResult

function SkillEffectMonsterMoveLongestGridResult:GetEffectType()
    return SkillEffectType.MonsterMoveLongestGrid
end
---@param walkResultList MonsterMoveLongestGridResult[]
---@param summonTrapResult SkillSummonTrapEffectResult[]
---@param finalAttackResult SkillDamageEffectResult
function SkillEffectMonsterMoveLongestGridResult:Constructor(walkResultList,isDead,finalAttackResult,summonTrapResult)
    self._walkResultList = walkResultList
    self._isDead = isDead
    self._summonTrapResultList = summonTrapResult
    self._finalAttackResult = finalAttackResult
end
---@return MonsterWalkResult[]
function SkillEffectMonsterMoveLongestGridResult:GetWalkResultList()
    return self._walkResultList
end

function SkillEffectMonsterMoveLongestGridResult:IsCasterDead()
    return self._isDead
end
---@return SkillDamageEffectResult
function SkillEffectMonsterMoveLongestGridResult:GetFinalAttackResult()
    return self._finalAttackResult
end
---@return SkillSummonTrapEffectResult[]
function SkillEffectMonsterMoveLongestGridResult:GetSummonTrapResultList()
    return self._summonTrapResultList
end

_class( "MonsterMoveLongestGridResult", MonsterWalkResult )
---@class MonsterMoveLongestGridResult: MonsterWalkResult
MonsterMoveLongestGridResult = MonsterMoveLongestGridResult

function MonsterMoveLongestGridResult:Constructor()
    self._newPieceType = nil
    ---@type SkillDamageEffectResult
    self._attackResult = nil
    self._flushTrapID = nil
end

function MonsterMoveLongestGridResult:SetNewGridType(pieceType)
    self._newPieceType = pieceType
end

function MonsterMoveLongestGridResult:SetAttackResult(attackResult)
    self._attackResult = attackResult
end

function MonsterMoveLongestGridResult:SetFlushTrapID(trapID)
    self._flushTrapID = trapID
end

function MonsterMoveLongestGridResult:GetNewGridType()
    return self._newPieceType
end

function MonsterMoveLongestGridResult:GetAttackResult()
    return self._attackResult
end

function MonsterMoveLongestGridResult:GetFlushTrapID()
    return self._flushTrapID
end