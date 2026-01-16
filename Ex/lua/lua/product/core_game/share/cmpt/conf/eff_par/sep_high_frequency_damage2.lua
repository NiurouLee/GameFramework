require("skill_damage_effect_param")

_class("SkillEffectParam_HighFrequencyDamage2", SkillDamageEffectParam)
---@class SkillEffectParam_HighFrequencyDamage2 : SkillDamageEffectParam
SkillEffectParam_HighFrequencyDamage2 = SkillEffectParam_HighFrequencyDamage2

function SkillEffectParam_HighFrequencyDamage2:Constructor(paramList)
    self._maxAttackTimes = tonumber(paramList.maxAttackTimes)

    if not self._maxAttackTimes then
        Log.exception(self._className, "需要maxAttackTimes参数")
    end

    self._paramList = paramList
    self._tractionOnLastTarget = tonumber(paramList.tractionOnLastTarget) == 1

    self._lastTargetBuffID = tonumber(paramList.lastTargetBuffID)
    if self._lastTargetBuffID and not Cfg.cfg_buff[self._lastTargetBuffID] then
        Log.exception(self._className, "lastTargetBuffID 在buff表中没找到：", tostring(self._lastTargetBuffID))
    end
    --根据周围指定范围的指定格子颜色，增加攻击次数
    --选择范围
    self._serialScopeType = paramList.serialScopeType
    --选择范围中心点类型
    self._serialScopeCenterType = paramList.serialScopeCenterType
    self._serialScopeParam = paramList.serialScopeParam
    --选择格子颜色
    self._pieceType = paramList.pieceType
    --选择一个格子增加的攻击次数
    self._onePieceAddAttackCount = paramList.onePieceAddAttackCount
end

function SkillEffectParam_HighFrequencyDamage2:GetEffectType()
    return SkillEffectType.HighFrequencyDamage2
end

function SkillEffectParam_HighFrequencyDamage2:GetMaxAttackTimes()
    return self._maxAttackTimes
end
function SkillEffectParam_HighFrequencyDamage2:IsTractionOnLastTarget()
    return self._tractionOnLastTarget
end
function SkillEffectParam_HighFrequencyDamage2:GetLastTargetBuffID()
    return self._lastTargetBuffID
end
function SkillEffectParam_HighFrequencyDamage2:GetSerialScopeType()
    return self._serialScopeType
end

function SkillEffectParam_HighFrequencyDamage2:GetSerialScopeCenterType()
    return self._serialScopeCenterType
end

function SkillEffectParam_HighFrequencyDamage2:GetSerialScopeParam()
    return self._serialScopeParam
end

function SkillEffectParam_HighFrequencyDamage2:GetPieceType()
    return self._pieceType
end
function SkillEffectParam_HighFrequencyDamage2:GetOnePieceAddAttackCount()
    return self._onePieceAddAttackCount
end