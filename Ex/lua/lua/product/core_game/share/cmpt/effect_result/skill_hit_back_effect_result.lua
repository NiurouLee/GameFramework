--[[------------------------------------------------------------------------------------------
    SkillHitBackEffectResult : 技能击退效果结果
]] --------------------------------------------------------------------------------------------

_class("SkillHitBackEffectResult", SkillEffectResultBase)
---@class SkillHitBackEffectResult: SkillEffectResultBase
SkillHitBackEffectResult = SkillHitBackEffectResult

function SkillHitBackEffectResult:Constructor(
    targetId,
    startPos,
    targetPos,
    gridElementChangeTable,
    calcType,
    hitDir,
    colorNew)
    self._effectType = SkillEffectType.HitBack
    self._targetId = targetId
    --添加startPos字段，用于绕开GridPosition做表现 -jince
    self._startPos = startPos
    self._targetPos = targetPos
    self._gridElementChangeTable = gridElementChangeTable
    self._hitbackCalcType = calcType
    ---击退发起人的击退方向：为nil标识是没有击退的
    self._hitDir = hitDir
    self._colorNew = colorNew

    --表现参数，一个击退结果如果表现过就不再表现。用于同一个目标有多个伤害爆点，第一爆点的击退已经击退完成，第二爆点会再次播放击退的问题。
    self._hadPlay = false

    --击退过程中是否被阻挡（击退至版边或撞到机关怪物等）
    self._isBlocked = false
    --击退过程中，阻挡击退的怪物ID
    self._blockMonsterID = nil
end

function SkillHitBackEffectResult:GetEffectType()
    return SkillEffectType.HitBack
end

function SkillHitBackEffectResult:GetStartPos()
    return self._startPos
end

function SkillHitBackEffectResult:GetGridPos()
    return self._targetPos
end

function SkillHitBackEffectResult:GetPosTarget()
    return self._targetPos
end

function SkillHitBackEffectResult:GetHitDir()
    return self._hitDir
end

function SkillHitBackEffectResult:ClearHitDir()
    self._hitDir = nil
end

function SkillHitBackEffectResult:IsHaveMoveDir()
    local dirMove = self._targetPos - self._startPos
    return dirMove.x ~= 0 or dirMove.y ~= 0
end

function SkillHitBackEffectResult:GetGridElementChangeTable()
    return self._gridElementChangeTable
end

function SkillHitBackEffectResult:GetCalcType()
    return self._hitbackCalcType
end

function SkillHitBackEffectResult:GetTargetID()
    return self._targetId
end

function SkillHitBackEffectResult:SetTriggerTrapIds(triggerTraps)
    self._triggerTraps = triggerTraps
end

function SkillHitBackEffectResult:GetTriggerTrapIds()
    return self._triggerTraps
end

function SkillHitBackEffectResult:GetColorNew()
    return self._colorNew
end

function SkillHitBackEffectResult:GetHadPlay()
    return self._hadPlay
end

function SkillHitBackEffectResult:SetHadPlay(hadPlay)
    self._hadPlay = hadPlay
end

function SkillHitBackEffectResult:SetBombTrapEntityID(bombTrapEntity)
    self._bombTrapEntityID = bombTrapEntity
end

function SkillHitBackEffectResult:GetBombTrapEntityID()
    return self._bombTrapEntityID
end

function SkillHitBackEffectResult:SetIsBlocked(isBlocked)
    self._isBlocked = isBlocked
end

function SkillHitBackEffectResult:GetIsBlocked()
    return self._isBlocked
end

function SkillHitBackEffectResult:SetBlockMonsterID(monsterID)
    self._blockMonsterID = monsterID
end

function SkillHitBackEffectResult:GetBlockMonsterID()
    return self._blockMonsterID
end
