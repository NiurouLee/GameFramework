require("skill_damage_effect_param")

---@class MovePathType
local MovePathType = {
    Far = 1, --远离目标
    NearCross = 2, --靠近目标并绕目标十字四格攻击
    NearAround = 3, --靠近目标并绕目标周围一圈攻击
}
_enum("MovePathType", MovePathType)

_class("SkillEffectParam_MonsterMoveGridByParam", SkillDamageEffectParam)
---@class SkillEffectParam_MonsterMoveGridByParam: SkillDamageEffectParam
SkillEffectParam_MonsterMoveGridByParam = SkillEffectParam_MonsterMoveGridByParam

function SkillEffectParam_MonsterMoveGridByParam:Constructor(t)
    self._moveType = t.moveType or MovePathType.Far
    self._resetGrid = t.resetGrid or 1
    self._partnerMonsterClassIDList = t.partnerID or {}
    self._attackSkillID = t.attackSkillID or 0
end

function SkillEffectParam_MonsterMoveGridByParam:GetEffectType()
    return SkillEffectType.MonsterMoveGridByParam
end

function SkillEffectParam_MonsterMoveGridByParam:GetMoveType()
    return self._moveType
end

function SkillEffectParam_MonsterMoveGridByParam:GetAttackSkillID()
    return self._attackSkillID
end

function SkillEffectParam_MonsterMoveGridByParam:GetPartnerIDList()
    return self._partnerMonsterClassIDList
end

function SkillEffectParam_MonsterMoveGridByParam:IsResetGrid()
    return self._resetGrid == 1
end
