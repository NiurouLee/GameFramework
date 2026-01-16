require("skill_effect_param_base")
_class("SkillSerialKillerEffectParam", SkillEffectParamBase)
---@class SkillSerialKillerEffectParam: SkillEffectParamBase
SkillSerialKillerEffectParam = SkillSerialKillerEffectParam

function SkillSerialKillerEffectParam:Constructor(t)
    self._percent = t.percent
    self._formulaID = t.formulaID
    self._killCount = t.count
    --选择范围
    self._serialScopeType = t.serialScopeType
    --选择半径
    self._radius = t.radius
    --选择格子颜色
    self._pieceType = t.pieceType
    --选择一个格子增加的攻击次数
    self._onePieceAddAttackCount = t.onePieceAddAttackCount
    self._pureDamage = t.pureDamage or 0

    --目标首次伤害的倍率
    self._multiple = t.multiple or 1
end

function SkillSerialKillerEffectParam:GetSerialScopeType()
    return self._serialScopeType
end

function SkillSerialKillerEffectParam:GetRadius()
    return self._radius
end

function SkillSerialKillerEffectParam:GetPieceType()
    return self._pieceType
end

function SkillSerialKillerEffectParam:GetOnePieceAddAttackCount()
    return self._onePieceAddAttackCount
end

function SkillSerialKillerEffectParam:GetEffectType()
    return SkillEffectType.SerialKiller
end

function SkillSerialKillerEffectParam:GetPercent()
    return self._percent
end

function SkillSerialKillerEffectParam:GetFormulaID()
    return self._formulaID
end

function SkillSerialKillerEffectParam:GetKillCount()
    return self._killCount
end
----
function SkillSerialKillerEffectParam:GetPureDamage()
    return self._pureDamage
end

function SkillSerialKillerEffectParam:GetMultiple()
    return self._multiple
end
