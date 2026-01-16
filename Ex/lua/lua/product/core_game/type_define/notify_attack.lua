require("notify_type")

--接口
_class("NotifyAttackBase", INotifyBase)
---@class NotifyAttackBase:INotifyBase
NotifyAttackBase = NotifyAttackBase

function NotifyAttackBase:Constructor(attacker, defender, attackPos, targetPos)
    self._defender = defender
    self._attacker = attacker
    self._attackPos = attackPos
    self._targetPos = targetPos
end
function NotifyAttackBase:GetNotifyEntity()
    return self._attacker
end

function NotifyAttackBase:NeedCheckGameTurn()
    return true
end

function NotifyAttackBase:GetAttackerEntity()
    return self._attacker
end
---@return Entity
function NotifyAttackBase:GetDefenderEntity()
    return self._defender
end
function NotifyAttackBase:GetAttackPos()
    return self._attackPos
end
---@return Vector2
function NotifyAttackBase:GetTargetPos()
    return self._targetPos
end
function NotifyAttackBase:GetNotifyPos()
    return self._attackPos
end

function NotifyAttackBase:SetDamageValue(damage)
    self._damage = damage
end

function NotifyAttackBase:GetDamageValue()
    return self._damage
end

function NotifyAttackBase:SetDamageType(damageType)
    self._damageType = damageType
end

function NotifyAttackBase:GetDamageType()
    return self._damageType
end

function NotifyAttackBase:SetSkillID(skillID)
    self._skillID = skillID
end

function NotifyAttackBase:GetSkillID()
    return self._skillID
end

function NotifyAttackBase:SetSkillType(skillType)
    self._skillType = skillType
end

function NotifyAttackBase:GetSkillType()
    return self._skillType
end

function NotifyAttackBase:SetEffectType(effectType)
    self._effectType = effectType
end

function NotifyAttackBase:GetEffectType()
    return self._effectType
end

---技能阶段
function NotifyAttackBase:SetSkillStageIndex(stageIndex)
    self._stageIndex = stageIndex
end
function NotifyAttackBase:GetSkillStageIndex()
    return self._stageIndex
end

function NotifyAttackBase:GetDefenderEntityIDList()
    return {self._defender:GetID()}
end

--region NotifyChainAttackBase
---@class NotifyChainAttackBase:INotifyBase
_class("NotifyChainAttackBase", INotifyBase)
NotifyChainAttackBase = NotifyChainAttackBase

function NotifyChainAttackBase:Constructor()
    self._chainCount = 0 --连锁技的连锁数
end
function NotifyChainAttackBase:SetChainCount(chainCount)
    self._chainCount = chainCount
end
function NotifyChainAttackBase:GetChainCount()
    return self._chainCount
end
--endregion

---------------------------------------------------------------------------
---从NotifyAttackBase继承的通知
---------------------------------------------------------------------------

--每次普攻之前
_class("NTNormalEachAttackStart", NotifyAttackBase)
---@class NTNormalEachAttackStart : NotifyAttackBase
NTNormalEachAttackStart = NTNormalEachAttackStart

function NTNormalEachAttackStart:GetNotifyType()
    return NotifyType.NormalEachAttackStart
end

--每次普攻之后
_class("NTNormalEachAttackEnd", NotifyAttackBase)
---@class NTNormalEachAttackEnd : NotifyAttackBase
NTNormalEachAttackEnd = NTNormalEachAttackEnd

function NTNormalEachAttackEnd:GetNotifyType()
    return NotifyType.NormalEachAttackEnd
end

---@class NTNormalAttackCalcStart : INotifyBase
_class("NTNormalAttackCalcStart", INotifyBase)
function NTNormalAttackCalcStart:Constructor(entity, attackGridData)
    self._notifier = entity
    ---@type AttackGridData
    self._attackGridData = attackGridData
end

function NTNormalAttackCalcStart:GetNotifyType()
    return NotifyType.NormalAttackCalcStart
end

function NTNormalAttackCalcStart:GetTargetCount()
    return #(self._attackGridData:GetTargetIdList())
end

function NTNormalAttackCalcStart:GetNotifyEntity()
    return self._notifier
end

--计算普通结束
_class("NTNormalAttackCalcEnd", NotifyAttackBase)
---@class NTNormalAttackCalcEnd :NotifyAttackBase
NTNormalAttackCalcEnd = NTNormalAttackCalcEnd

function NTNormalAttackCalcEnd:GetNotifyType()
    return NotifyType.NormalAttackCalcEnd
end

--计算普通结束 被击位置在溅射攻击时也是用原被击位置
_class("NTNormalAttackCalcEndUseOriPos", NotifyAttackBase)
---@class NTNormalAttackCalcEndUseOriPos :NotifyAttackBase
NTNormalAttackCalcEndUseOriPos = NTNormalAttackCalcEndUseOriPos

function NTNormalAttackCalcEndUseOriPos:GetNotifyType()
    return NotifyType.NormalAttackCalcEndUseOriPos
end

_class("NTNormalAttackChangeBefore", INotifyBase)
---@class NTNormalAttackChangeBefore : INotifyBase
function NTNormalAttackChangeBefore:Constructor(entity, attackPos, beAttackPos)
    self._entity = entity
    self._attackPos = attackPos
    self._beAttackPos = beAttackPos
end

function NTNormalAttackChangeBefore:GetNotifyType()
    return NotifyType.NormalAttackChangeBefore
end

function NTNormalAttackChangeBefore:GetNotifyEntity()
    return self._entity
end
function NTNormalAttackChangeBefore:GetAttackPos()
    return self._attackPos
end
---@return Vector2
function NTNormalAttackChangeBefore:GetTargetPos()
    return self._beAttackPos
end
function NTNormalAttackChangeBefore:GetNotifyPos()
    return self._attackPos
end

--怪物普攻前
_class("NTMonsterEachAttackStart", NotifyAttackBase)
NTMonsterEachAttackStart = NTMonsterEachAttackStart

function NTMonsterEachAttackStart:GetNotifyType()
    return NotifyType.MonsterEachAttackStart
end

--怪物普攻伤害命中后
_class("NTMonsterEachAttackEnd", NotifyAttackBase)
NTMonsterEachAttackEnd = NTMonsterEachAttackEnd

function NTMonsterEachAttackEnd:GetNotifyType()
    return NotifyType.MonsterEachAttackEnd
end

--怪物伤害命中后
_class("NTMonsterEachDamageEnd", NotifyAttackBase)
NTMonsterEachDamageEnd = NTMonsterEachDamageEnd

function NTMonsterEachDamageEnd:GetNotifyType()
    return NotifyType.MonsterEachDamageEnd
end

--region 机关攻击
---@class NTTrapEachAttackStart:NotifyAttackBase
_class("NTTrapEachAttackStart", NotifyAttackBase)
NTTrapEachAttackStart = NTTrapEachAttackStart

function NTTrapEachAttackStart:GetNotifyType()
    return NotifyType.TrapEachAttackStart --机关攻击前
end
---@class NTTrapEachAttackEnd:NotifyAttackBase
_class("NTTrapEachAttackEnd", NotifyAttackBase)
NTTrapEachAttackEnd = NTTrapEachAttackEnd

function NTTrapEachAttackEnd:GetNotifyType()
    return NotifyType.TrapEachAttackEnd --机关攻击后
end
--endregion

--连锁技每次攻击之前
_class("NTChainSkillEachAttackStart", NotifyAttackBase)
---@class NTChainSkillEachAttackStart : NotifyAttackBase
NTChainSkillEachAttackStart = NTChainSkillEachAttackStart

function NTChainSkillEachAttackStart:GetNotifyType()
    return NotifyType.ChainSkillEachAttackStart
end
function NTChainSkillEachAttackStart:SetChainSkillIndex(idx)
    self._chainIndex = idx
end

function NTChainSkillEachAttackStart:GetChainSkillIndex()
    return self._chainIndex
end
--SkillEffectCalcRandDamageSameHalf 可能对单个敌人造成多次伤害 处理buffview
function NTChainSkillEachAttackStart:SetRandHalfDamageIndex(idx)
    self._randHalfDamageIndex = idx
end

function NTChainSkillEachAttackStart:GetRandHalfDamageIndex()
    return self._randHalfDamageIndex
end

--连锁技每次攻击之后
_class("NTChainSkillEachAttackEnd", NotifyAttackBase)
---@class NTChainSkillEachAttackEnd : NotifyAttackBase
NTChainSkillEachAttackEnd = NTChainSkillEachAttackEnd

function NTChainSkillEachAttackEnd:GetNotifyType()
    return NotifyType.ChainSkillEachAttackEnd
end

function NTChainSkillEachAttackEnd:SetDamageValue(val)
    self._damageValue = val
end

function NTChainSkillEachAttackEnd:GetDamageValue()
    return self._damageValue
end
function NTChainSkillEachAttackEnd:SetChainSkillIndex(idx)
    self._chainIndex = idx
end

function NTChainSkillEachAttackEnd:GetChainSkillIndex()
    return self._chainIndex
end
--SkillEffectCalcRandDamageSameHalf 可能对单个敌人造成多次伤害 处理buffview
function NTChainSkillEachAttackEnd:SetRandHalfDamageIndex(idx)
    self._randHalfDamageIndex = idx
end

function NTChainSkillEachAttackEnd:GetRandHalfDamageIndex()
    return self._randHalfDamageIndex
end

--导表检查工具对接口的要求是与，所以函数名必须是一致的
function NTChainSkillEachAttackEnd:GetDamage()
    return self._damageValue
end
--主动技每次攻击之前
_class("NTActiveSkillEachAttackStart", NotifyAttackBase)
---@class NTActiveSkillEachAttackStart : NotifyAttackBase
NTActiveSkillEachAttackStart = NTActiveSkillEachAttackStart

function NTActiveSkillEachAttackStart:GetNotifyType()
    return NotifyType.ActiveSkillEachAttackStart
end

--主动技每次攻击之后
_class("NTActiveSkillEachAttackEnd", NotifyAttackBase)
---@class NTActiveSkillEachAttackEnd : NotifyAttackBase
NTActiveSkillEachAttackEnd = NTActiveSkillEachAttackEnd

function NTActiveSkillEachAttackEnd:GetNotifyType()
    return NotifyType.ActiveSkillEachAttackEnd
end

function NTActiveSkillEachAttackEnd:SetChainSkillIndex(idx)
    self._chainIndex = idx
end

function NTActiveSkillEachAttackEnd:GetChainSkillIndex()
    return self._chainIndex
end

--玩家受击
_class("NTPlayerBeHit", NotifyAttackBase)
NTPlayerBeHit = NTPlayerBeHit

function NTPlayerBeHit:GetNotifyType()
    return NotifyType.PlayerBeHit
end
function NTPlayerBeHit:NeedCheckGameTurn()
    return false
end
function NTPlayerBeHit:GetNotifyEntity()
    return self._defender
end

function NTPlayerBeHit:SetDamageIndex(idx)
    self._damageIndex = idx
end

function NTPlayerBeHit:GetDamageIndex()
    return self._damageIndex
end

--怪物受击
_class("NTMonsterBeHit", NotifyAttackBase)
NTMonsterBeHit = NTMonsterBeHit

function NTMonsterBeHit:GetNotifyType()
    return NotifyType.MonsterBeHit
end
function NTMonsterBeHit:NeedCheckGameTurn()
    return false
end

function NTMonsterBeHit:GetNotifyEntity()
    return self._defender
end

function NTMonsterBeHit:SetDamageStageIndex(idx)
    self._damageStageIndex = idx
end

function NTMonsterBeHit:GetDamageStageIndex()
    return self._damageStageIndex
end

function NTMonsterBeHit:SetCurSkillDamageIndex(val)
    self._curSkillDamageIndex = val
end

function NTMonsterBeHit:GetCurSkillDamageIndex()
    return self._curSkillDamageIndex
end

function NTMonsterBeHit:SetMatchBuffViewLayer(layer, buffID)
    --self._matchBuffViewLayer = layer
    if not self._matchBuffViewLayer then
        self._matchBuffViewLayer = {}
    end
    self._matchBuffViewLayer[buffID] = layer
end

function NTMonsterBeHit:GetMatchBuffViewLayer(buffID)
    if not self._matchBuffViewLayer then
        return nil
    end

    return self._matchBuffViewLayer[buffID]
end

--玩家受击前
_class("NTPlayerBeHitStart", NotifyAttackBase)
NTPlayerBeHitStart = NTPlayerBeHitStart

function NTPlayerBeHitStart:GetNotifyType()
    return NotifyType.PlayerBeHitStart
end
function NTPlayerBeHitStart:NeedCheckGameTurn()
    return false
end
function NTPlayerBeHitStart:GetNotifyEntity()
    return self._defender
end

function NTPlayerBeHitStart:SetDamageIndex(idx)
    self._damageIndex = idx
end

function NTPlayerBeHitStart:GetDamageIndex()
    return self._damageIndex
end

--怪物受击
_class("NTMonsterBeHitStart", NotifyAttackBase)
NTMonsterBeHitStart = NTMonsterBeHitStart

function NTMonsterBeHitStart:GetNotifyType()
    return NotifyType.MonsterBeHitStart
end
function NTMonsterBeHitStart:NeedCheckGameTurn()
    return false
end

function NTMonsterBeHitStart:GetNotifyEntity()
    return self._defender
end

---------------------------------------------------------------------------
---不从NotifyAttackBase继承的攻击通知
---------------------------------------------------------------------------
--普攻之前 (在划线后 必定通知所有星灵 可能没有攻击数据)
_class("NTNormalAttackStart", INotifyBase)
---@class NTNormalAttackStart : INotifyBase
NTNormalAttackStart = NTNormalAttackStart
----@param attacker Entity
function NTNormalAttackStart:Constructor(attacker, chainPathType, chainPath)
    self._attacker = attacker
    self._chainPathType = chainPathType
    self._chainPath = chainPath
end

function NTNormalAttackStart:GetNotifyType()
    return NotifyType.NormalAttackStart
end

function NTNormalAttackStart:GetNotifyEntity()
    return self._attacker
end
function NTNormalAttackStart:GetAttackerEntity()
    return self._attacker
end

function NTNormalAttackStart:GetChainPathType()
    return self._chainPathType
end

function NTNormalAttackStart:GetChainPath()
    return self._chainPath
end

--普攻之后
_class("NTNormalAttackEnd", INotifyBase)
---@class NTNormalAttackEnd : INotifyBase
NTNormalAttackEnd = NTNormalAttackEnd
----@param attacker Entity
function NTNormalAttackEnd:Constructor(attacker)
    self._attacker = attacker
end

function NTNormalAttackEnd:GetNotifyType()
    return NotifyType.NormalAttackEnd
end

function NTNormalAttackEnd:GetNotifyEntity()
    return self._attacker
end
function NTNormalAttackEnd:GetAttackerEntity()
    return self._attacker
end

_class("NTBeforeCalcChainSkill", INotifyBase)
---@class NTBeforeCalcChainSkill : INotifyBase
NTBeforeCalcChainSkill = NTBeforeCalcChainSkill

function NTBeforeCalcChainSkill:Constructor()
end
function NTBeforeCalcChainSkill:GetNotifyType()
    return NotifyType.BeforeCalcChainSkill
end
function NTBeforeCalcChainSkill:SetChainCount(chainCount)
    self._chainCount = chainCount
end
function NTBeforeCalcChainSkill:GetChainCount()
    return self._chainCount
end

--一个星灵连锁技开始前
_class("NTChainSkillAttackStart", INotifyBase)
NTChainSkillAttackStart = NTChainSkillAttackStart

function NTChainSkillAttackStart:Constructor(attacker, defenderList, attackPos, defenerPosList, defendMonsterList)
    self._attacker = attacker
    self._defenderList = defenderList
    self._attackPos = attackPos
    self._defenderPosList = defenerPosList
    self._defendMonsterList = defendMonsterList
end

function NTChainSkillAttackStart:GetNotifyType()
    return NotifyType.ChainSkillAttackStart
end

function NTChainSkillAttackStart:GetNotifyEntity()
    return self._attacker
end
function NTChainSkillAttackStart:GetAttackerEntity()
    return self._attacker
end

function NTChainSkillAttackStart:GetAttackerPos()
    return self._attackPos
end
function NTChainSkillAttackStart:GetDefenderEntityIDList()
    return self._defenderList
end

function NTChainSkillAttackStart:GetDefenderPosList()
    return self._defenderPosList
end

function NTChainSkillAttackStart:GetTargetCount()
    local count = 0
    local t = {}
    for _, id in ipairs(self._defendMonsterList) do
        if not t[id] then
            count = count + 1
            t[id] = true
        end
    end
    return count
end

function NTChainSkillAttackStart:SetChainSkillIndex(idx)
    self._chainSkillIndex = idx
end

function NTChainSkillAttackStart:GetChainSkillIndex()
    return self._chainSkillIndex
end

function NTChainSkillAttackStart:SetChainSkillId(chainSkillId)
    self._chainSkillId = chainSkillId
end

function NTChainSkillAttackStart:GetChainSkillId()
    return self._chainSkillId
end

function NTChainSkillAttackStart:SetChainSkillStage(chainSkillStage)
    self._chainSkillStage = chainSkillStage
end

function NTChainSkillAttackStart:GetChainSkillStage()
    return self._chainSkillStage
end

function NTChainSkillAttackStart:GetSkillID()
    return self._chainSkillId
end

--一个星灵第二次连锁技开始前
_class("NTSecondChainSkillAttackStart", INotifyBase)
NTSecondChainSkillAttackStart = NTSecondChainSkillAttackStart

function NTSecondChainSkillAttackStart:Constructor(attacker, defenderList, attackPos, defenerPosList, defendMonsterList)
    self._attacker = attacker
    self._defenderList = defenderList
    self._attackPos = attackPos
    self._defenderPosList = defenerPosList
    self._defendMonsterList = defendMonsterList
end

function NTSecondChainSkillAttackStart:GetNotifyType()
    return NotifyType.SecondChainSkillAttackStart
end

function NTSecondChainSkillAttackStart:GetNotifyEntity()
    return self._attacker
end
function NTSecondChainSkillAttackStart:GetAttackerEntity()
    return self._attacker
end

function NTSecondChainSkillAttackStart:GetAttackerPos()
    return self._attackPos
end
function NTSecondChainSkillAttackStart:GetDefenderEntityIDList()
    return self._defenderList
end

function NTSecondChainSkillAttackStart:GetDefenderPosList()
    return self._defenderPosList
end

function NTSecondChainSkillAttackStart:GetTargetCount()
    local count = 0
    local t = {}
    for _, id in ipairs(self._defendMonsterList) do
        if not t[id] then
            count = count + 1
            t[id] = true
        end
    end
    return count
end

--一个星灵连锁技释放
_class("NTChainSkillAttack", INotifyBase)
NTChainSkillAttack = NTChainSkillAttack

function NTChainSkillAttack:Constructor(attacker, defenderList, attackPos, defenerPosList)
    self._attacker = attacker
    self._defenderList = defenderList
    self._attackPos = attackPos
    self._defenerPosList = defenerPosList
end

function NTChainSkillAttack:GetNotifyType()
    return NotifyType.ChainSkillAttack
end

function NTChainSkillAttack:GetNotifyEntity()
    return self._attacker
end
function NTChainSkillAttack:GetAttackerEntity()
    return self._attacker
end

function NTChainSkillAttack:GetAttackerPos()
    return self._attackPos
end
function NTChainSkillAttack:GetDefenderEntityIDList()
    return self._defenderList
end

function NTChainSkillAttack:GetDefenderPosList()
    return self._defenderPosList
end

--一个星灵连锁技结束
---@class NTChainSkillAttackEnd:NotifyChainAttackBase
_class("NTChainSkillAttackEnd", NotifyChainAttackBase)
NTChainSkillAttackEnd = NTChainSkillAttackEnd

function NTChainSkillAttackEnd:Constructor(attacker, defenderList, attackPos, defenerPosList)
    self._attacker = attacker
    self._defenderList = defenderList
    self._attackPos = attackPos
    self._defenerPosList = defenerPosList
end

function NTChainSkillAttackEnd:GetNotifyType()
    return NotifyType.ChainSkillAttackEnd
end

function NTChainSkillAttackEnd:GetNotifyEntity()
    return self._attacker
end

function NTChainSkillAttackEnd:GetAttackerEntity()
    return self._attacker
end

function NTChainSkillAttackEnd:GetAttackerPos()
    return self._attackPos
end

function NTChainSkillAttackEnd:GetDefenderEntityIDList()
    return self._defenderList
end

function NTChainSkillAttackEnd:GetDefenderPosList()
    return self._defenderPosList
end

function NTChainSkillAttackEnd:GetTargetMap()
    if not self._defenderList then
        return {}
    end

    local map = {}
    for _, eid in ipairs(self._defenderList) do
        if not table.icontains(map, eid) then
            map[eid] = true
        end
    end

    return map
end

function NTChainSkillAttackEnd:SetChainSkillIndex(idx)
    self._chainSkillIndex = idx
end

function NTChainSkillAttackEnd:GetChainSkillIndex()
    return self._chainSkillIndex
end

function NTChainSkillAttackEnd:SetChainSkillId(chainSkillId)
    self._chainSkillId = chainSkillId
end

function NTChainSkillAttackEnd:GetChainSkillId()
    return self._chainSkillId
end

function NTChainSkillAttackEnd:SetChainSkillStage(chainSkillStage)
    self._chainSkillStage = chainSkillStage
end

function NTChainSkillAttackEnd:GetChainSkillStage()
    return self._chainSkillStage
end

--接口兼容：trigger 242
function NTChainSkillAttackEnd:GetSkillID()
    return self._chainSkillId
end

--一个星灵第二次连锁技结束
---@class NTSecondChainSkillAttackEnd:INotifyBase
_class("NTSecondChainSkillAttackEnd", INotifyBase)
NTSecondChainSkillAttackEnd = NTSecondChainSkillAttackEnd

function NTSecondChainSkillAttackEnd:Constructor(attacker)
    self._attacker = attacker
end

function NTSecondChainSkillAttackEnd:GetNotifyType()
    return NotifyType.SecondChainSkillAttackEnd
end

---@return Entity
function NTSecondChainSkillAttackEnd:GetNotifyEntity()
    return self._attacker
end

--主动技之前
_class("NTActiveSkillAttackStart", INotifyBase)
---@class NTActiveSkillAttackStart : INotifyBase
NTActiveSkillAttackStart = NTActiveSkillAttackStart
----@param attacker Entity
function NTActiveSkillAttackStart:Constructor(attacker)
    self._attacker = attacker
    self.m_nSkillID = nil
    ---@type SkillScopeResult
    self.m_scopeResult = nil
end

function NTActiveSkillAttackStart:GetNotifyType()
    return NotifyType.ActiveSkillAttackStart
end

function NTActiveSkillAttackStart:GetNotifyEntity()
    return self._attacker
end

function NTActiveSkillAttackStart:GetAttackerEntity()
    return self._attacker
end
---@param scopeResult SkillScopeResult
function NTActiveSkillAttackStart:InitSkillResult(nSkillID, scopeResult)
    self.m_nSkillID = nSkillID
    self.m_scopeResult = scopeResult
end
---@return  SkillScopeResult
function NTActiveSkillAttackStart:GetScopeResult()
    return self.m_scopeResult
end

function NTActiveSkillAttackStart:GetDefenderEntityIDList()
    return self.m_scopeResult:GetTargetIDs()
end
function NTActiveSkillAttackStart:GetTargetCount()
    if not self.m_scopeResult then
        return 0
    end

    local targetIDs = self.m_scopeResult:GetTargetIDs()
    if not targetIDs then
        return 0
    end

    ---@type MainWorld
    local world = self._attacker:GetOwnerWorld()

    local targetCount = 0
    --攻击目标可能有机关，去掉机关
    for i = 1, #targetIDs do
        local targetEntity = world:GetEntityByID(targetIDs[i])
        if targetEntity and not targetEntity:HasTrapID() then
            targetCount = targetCount + 1
        end
    end

    return targetCount
end
function NTActiveSkillAttackStart:GetSkillID()
    return self.m_nSkillID
end

--主动技之后
_class("NTActiveSkillAttackEnd", INotifyBase)
---@class NTActiveSkillAttackEnd : INotifyBase
NTActiveSkillAttackEnd = NTActiveSkillAttackEnd
----@param attacker Entity
function NTActiveSkillAttackEnd:Constructor(attacker, skillID)
    self._attacker = attacker
    self._skillID = skillID
end

function NTActiveSkillAttackEnd:GetNotifyType()
    return NotifyType.ActiveSkillAttackEnd
end

function NTActiveSkillAttackEnd:GetNotifyEntity()
    return self._attacker
end

function NTActiveSkillAttackEnd:GetAttackerEntity()
    return self._attacker
end
function NTActiveSkillAttackEnd:SetSkillID(skillID)
    self._skillID = skillID
end
function NTActiveSkillAttackEnd:GetSkillID()
    return self._skillID
end

---@param scopeResult SkillScopeResult
function NTActiveSkillAttackEnd:InitSkillResult(nSkillID, scopeResult)
    self._skillID = nSkillID
    self.m_scopeResult = scopeResult
end
---@return  SkillScopeResult
function NTActiveSkillAttackEnd:GetScopeResult()
    return self.m_scopeResult
end

function NTActiveSkillAttackEnd:GetDefenderEntityIDList()
    return self.m_scopeResult:GetTargetIDs()
end

--------------------------------

--主动技开始前
_class("NTBeforeActiveSkillAttackStart", INotifyBase)
---@class NTBeforeActiveSkillAttackStart : INotifyBase
NTBeforeActiveSkillAttackStart = NTBeforeActiveSkillAttackStart
----@param attacker Entity
function NTBeforeActiveSkillAttackStart:Constructor(attacker)
    self._attacker = attacker
end
---
function NTBeforeActiveSkillAttackStart:GetNotifyType()
    return NotifyType.BeforeActiveSkillAttackStart
end
---
function NTBeforeActiveSkillAttackStart:GetNotifyEntity()
    return self._attacker
end

----------------------------------------------------------------
_class("NTChainSkillTurnStart", INotifyBase)
---@class NTChainSkillTurnStart :INotifyBase
NTChainSkillTurnStart = NTChainSkillTurnStart
----@param entity Entity
function NTChainSkillTurnStart:Constructor(teamEntity)
    self._teamEntity = teamEntity
end
function NTChainSkillTurnStart:GetNotifyType()
    return NotifyType.ChainSkillTurnStart
end
function NTChainSkillTurnStart:GetNotifyEntity()
    return self._teamEntity
end
_class("NTChainSkillTurnStartSkipped", INotifyBase)
---@class NTChainSkillTurnStartSkipped :INotifyBase
NTChainSkillTurnStartSkipped = NTChainSkillTurnStartSkipped
----@param entity Entity
function NTChainSkillTurnStartSkipped:Constructor(teamEntity)
    self._teamEntity = teamEntity
end
function NTChainSkillTurnStartSkipped:GetNotifyType()
    return NotifyType.ChainSkillTurnStartSkipped
end
function NTChainSkillTurnStartSkipped:GetNotifyEntity()
    return self._teamEntity
end
--------------------------------
_class("NTChainSkillTurnEnd", INotifyBase)
---@class NTChainSkillTurnEnd :INotifyBase
NTChainSkillTurnEnd = NTChainSkillTurnEnd
----@param entity Entity
function NTChainSkillTurnEnd:Constructor(chainSkillCount)
    self._cnt = chainSkillCount
end
function NTChainSkillTurnEnd:GetNotifyType()
    return NotifyType.ChainSkillTurnEnd
end

function NTChainSkillTurnEnd:GetChainSkillCount()
    return self._cnt
end
----------------------------------------------------------------

---@class NTBuffCastSkillEachAttackBegin : NotifyAttackBase
_class("NTBuffCastSkillEachAttackBegin", NotifyAttackBase)
NTBuffCastSkillEachAttackBegin = NTBuffCastSkillEachAttackBegin

function NTBuffCastSkillEachAttackBegin:Constructor()
end
function NTBuffCastSkillEachAttackBegin:GetNotifyType()
    return NotifyType.BuffCastSkillEachAttackBegin
end

function NTBuffCastSkillEachAttackBegin:GetCastSkillID()
    return self._skillID
end

---@class NTBuffCastSkillEachAttackEnd : NotifyAttackBase
_class("NTBuffCastSkillEachAttackEnd", NotifyAttackBase)
NTBuffCastSkillEachAttackEnd = NTBuffCastSkillEachAttackEnd

function NTBuffCastSkillEachAttackEnd:Constructor()
end
function NTBuffCastSkillEachAttackEnd:GetNotifyType()
    return NotifyType.BuffCastSkillEachAttackEnd
end

function NTBuffCastSkillEachAttackEnd:GetCastSkillID()
    return self._skillID
end

---@class NTActiveSkillAttackEndBeforeMonsterDead : NTActiveSkillAttackEnd
_class("NTActiveSkillAttackEndBeforeMonsterDead", NTActiveSkillAttackEnd)

function NTActiveSkillAttackEndBeforeMonsterDead:GetNotifyType()
    return NotifyType.ActiveSkillAttackEndBeforeMonsterDead
end

function NTActiveSkillAttackEndBeforeMonsterDead:NeedCheckGameTurn()
    return true
end

--region 棋子

--棋子主动技释放之前
_class("NTChessPetSkillAttackStart", INotifyBase)
---@class NTChessPetSkillAttackStart : INotifyBase
NTChessPetSkillAttackStart = NTChessPetSkillAttackStart
----@param attacker Entity
---
function NTChessPetSkillAttackStart:Constructor(attacker, skillID)
    self._attacker = attacker
    self._skillID = skillID
end
---
function NTChessPetSkillAttackStart:GetNotifyType()
    return NotifyType.ChessPetSkillAttackStart
end
---
function NTChessPetSkillAttackStart:GetNotifyEntity()
    return self._attacker
end
---
function NTChessPetSkillAttackStart:GetAttackerEntity()
    return self._attacker
end
---
function NTChessPetSkillAttackStart:GetSkillID()
    return self._skillID
end

--棋子主动技释放之后
_class("NTChessPetSkillAttackEnd", INotifyBase)
---@class NTChessPetSkillAttackEnd : INotifyBase
NTChessPetSkillAttackEnd = NTChessPetSkillAttackEnd
----@param attacker Entity
---
function NTChessPetSkillAttackEnd:Constructor(attacker, skillID)
    self._attacker = attacker
    self._skillID = skillID
end
---
function NTChessPetSkillAttackEnd:GetNotifyType()
    return NotifyType.ChessPetSkillAttackEnd
end
---
function NTChessPetSkillAttackEnd:GetNotifyEntity()
    return self._attacker
end
---
function NTChessPetSkillAttackEnd:GetAttackerEntity()
    return self._attacker
end
---
function NTChessPetSkillAttackEnd:GetSkillID()
    return self._skillID
end

--endregion 棋子

--一个星灵连锁技完成（包含本体、投影、代理）
---@class NTSingleChainSkillAttackFinish:INotifyBase
_class("NTSingleChainSkillAttackFinish", INotifyBase)
NTSingleChainSkillAttackFinish = NTSingleChainSkillAttackFinish

function NTSingleChainSkillAttackFinish:Constructor(attacker, chainIndex)
    self._attacker = attacker
    self._chainSkillIndex = chainIndex
end

function NTSingleChainSkillAttackFinish:GetNotifyType()
    return NotifyType.SingleChainSkillAttackFinish
end

function NTSingleChainSkillAttackFinish:GetNotifyEntity()
    return self._attacker
end

function NTSingleChainSkillAttackFinish:GetAttackerEntity()
    return self._attacker
end

function NTSingleChainSkillAttackFinish:GetChainSkillIndex()
    return self._chainSkillIndex
end
--region 模块技能
--模块技之后
_class("NTFeatureSkillAttackEnd", INotifyBase)
---@class NTFeatureSkillAttackEnd : INotifyBase
NTFeatureSkillAttackEnd = NTFeatureSkillAttackEnd
----@param attacker Entity
function NTFeatureSkillAttackEnd:Constructor(featureType,featureSkillID)
    self.m_nFeatureType = featureType 
    self.m_nSkillID = featureSkillID
end
function NTFeatureSkillAttackEnd:GetNotifyType()
    return NotifyType.FeatureSkillAttackEnd
end
function NTFeatureSkillAttackEnd:GetFeatureType()
    return self.m_nFeatureType
end
function NTFeatureSkillAttackEnd:GetSkillID()
    return self.m_nSkillID
end
--endregion

--通过Buff释放技能结束
_class("NTBuffCastSkillAttackEnd", INotifyBase)
---@class NTBuffCastSkillAttackEnd : INotifyBase
NTBuffCastSkillAttackEnd = NTBuffCastSkillAttackEnd

---@param attacker Entity
---@param skillID number
function NTBuffCastSkillAttackEnd:Constructor(attacker, skillID)
    self._attacker = attacker
    self._skillID = skillID
end

function NTBuffCastSkillAttackEnd:GetNotifyType()
    return NotifyType.BuffCastSkillAttackEnd
end

function NTBuffCastSkillAttackEnd:GetNotifyEntity()
    return self._attacker
end

function NTBuffCastSkillAttackEnd:GetAttackerEntity()
    return self._attacker
end

function NTBuffCastSkillAttackEnd:GetSkillID()
    return self._skillID
end

--通过Buff释放技能结束
_class("NTBuffCastSkillAttackBegin", INotifyBase)
---@class NTBuffCastSkillAttackBegin : INotifyBase
NTBuffCastSkillAttackBegin = NTBuffCastSkillAttackBegin

---@param attacker Entity
---@param skillID number
function NTBuffCastSkillAttackBegin:Constructor(attacker, skillID)
    self._attacker = attacker
    self._skillID = skillID
end

function NTBuffCastSkillAttackBegin:GetNotifyType()
    return NotifyType.BuffCastSkillAttackBegin
end

function NTBuffCastSkillAttackBegin:GetNotifyEntity()
    return self._attacker
end

function NTBuffCastSkillAttackBegin:GetAttackerEntity()
    return self._attacker
end

function NTBuffCastSkillAttackBegin:GetSkillID()
    return self._skillID
end

---------------------------------------------------------------------------
---不从NotifyAttackBase继承的攻击通知
---------------------------------------------------------------------------
--普攻之前 (在划线后 必定通知所有星灵 可能没有攻击数据)
_class("NTTeamNormalAttackStart", INotifyBase)
---@class NTTeamNormalAttackStart : INotifyBase
NTTeamNormalAttackStart = NTTeamNormalAttackStart
----@param chainPath Vector2[]
----@param chainPathType PieceType
function NTTeamNormalAttackStart:Constructor(chainPathType, chainPath)
    self._chainPathType = chainPathType
    self._chainPath = chainPath
end

function NTTeamNormalAttackStart:GetNotifyType()
    return NotifyType.TeamNormalAttackStart
end

function NTTeamNormalAttackStart:GetChainPathType()
    return self._chainPathType
end

function NTTeamNormalAttackStart:GetChainPath()
    return self._chainPath
end

