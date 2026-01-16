require("notify_type")

--buff挂载
_class("NTBuffLoad", INotifyBase)
NTBuffLoad = NTBuffLoad
function NTBuffLoad:Constructor(enity, casterEntityID)
    self._enity = enity
    self._casterID = casterEntityID
end

function NTBuffLoad:GetNotifyType()
    return NotifyType.BuffLoad
end

function NTBuffLoad:GetNotifyEntity()
    return self._enity
end

function NTBuffLoad:GetCasterEntityID()
    return self._casterID
end

--buff卸载
_class("NTBuffUnload", INotifyBase)
NTBuffUnload = NTBuffUnload

function NTBuffUnload:Constructor(enity)
    self._enity = enity
end
function NTBuffUnload:GetNotifyType()
    return NotifyType.BuffUnload
end
function NTBuffUnload:GetNotifyEntity()
    return self._enity
end

_class("NTGameStart", INotifyBase)
NTGameStart = NTGameStart
function NTGameStart:Constructor()
end

function NTGameStart:GetNotifyType()
    return NotifyType.GameStart
end

--怪物回合开
_class("NTMonsterTurnStart", INotifyBase)
NTMonsterTurnStart = NTMonsterTurnStart
function NTMonsterTurnStart:Constructor()
end

function NTMonsterTurnStart:GetNotifyType()
    return NotifyType.MonsterTurnStart
end

_class("NTMonsterTurnAfterAddBuffRound", INotifyBase)
NTMonsterTurnAfterAddBuffRound = NTMonsterTurnAfterAddBuffRound
function NTMonsterTurnAfterAddBuffRound:Constructor()
end

function NTMonsterTurnAfterAddBuffRound:GetNotifyType()
    return NotifyType.MonsterTurnAfterAddBuffRound
end

_class("NTMonsterTurnAfterDelayedAddBuffRound", INotifyBase)
NTMonsterTurnAfterDelayedAddBuffRound = NTMonsterTurnAfterDelayedAddBuffRound

function NTMonsterTurnAfterDelayedAddBuffRound:GetNotifyType()
    return NotifyType.MonsterTurnAfterDelayedAddBuffRound
end

--怪物回合结束
_class("NTMonsterTurnEnd", INotifyBase)
NTMonsterTurnEnd = NTMonsterTurnEnd
function NTMonsterTurnEnd:Constructor(entity)
    self._ownerEntity = entity
end

function NTMonsterTurnEnd:GetNotifyType()
    return NotifyType.MonsterTurnEnd
end
function NTMonsterTurnEnd:GetNotifyEntity()
    return self._ownerEntity
end

--怪物生成
_class("NTMonsterShow", INotifyBase)
---@class NTMonsterShow:INotifyBase
NTMonsterShow = NTMonsterShow
function NTMonsterShow:Constructor(monster_entity)
    self.monster_entity = monster_entity
end

function NTMonsterShow:GetNotifyType()
    return NotifyType.MonsterShow
end

function NTMonsterShow:GetNotifyEntity()
    return self.monster_entity
end

--怪物死亡
_class("NTMonsterDead", INotifyBase)
NTMonsterDead = NTMonsterDead
----@param monsterEntity Entity
function NTMonsterDead:Constructor(monsterEntity)
    self._ownerEntity = monsterEntity
end

function NTMonsterDead:GetNotifyType()
    return NotifyType.MonsterDead
end
function NTMonsterDead:GetNotifyEntity()
    return self._ownerEntity
end

--怪物死亡开�?
_class("NTMonsterDeadStart", INotifyBase)
---@class NTMonsterDeadStart : INotifyBase
NTMonsterDeadStart = NTMonsterDeadStart
----@param monsterEntity Entity
function NTMonsterDeadStart:Constructor(monsterEntity)
    self._ownerEntity = monsterEntity
    -- 这是为了兼容部分trigger而做的，不然需要实现大量的重复trigger
    self._defender = monsterEntity
end

function NTMonsterDeadStart:GetNotifyType()
    return NotifyType.MonsterDeadStart
end
function NTMonsterDeadStart:GetNotifyEntity()
    return self._ownerEntity
end

function NTMonsterDeadStart:GetDefenderEntity()
    return self._defender
end

--怪物死亡结束
_class("NTMonsterDeadEnd", INotifyBase)
---@class NTMonsterDeadEnd : INotifyBase
NTMonsterDeadEnd = NTMonsterDeadEnd
----@param monsterEntity Entity
function NTMonsterDeadEnd:Constructor(monsterEntity)
    self._ownerEntity = monsterEntity
    -- 这是为了兼容部分trigger而做的，不然需要实现大量的重复trigger
    self._defender = monsterEntity
end

function NTMonsterDeadEnd:GetNotifyType()
    return NotifyType.MonsterDeadEnd
end
function NTMonsterDeadEnd:GetNotifyEntity()
    return self._ownerEntity
end

function NTMonsterDeadEnd:GetDefenderEntity()
    return self._defender
end
--玩家回合开始
_class("NTPlayerTurnStart", INotifyBase)
NTPlayerTurnStart = NTPlayerTurnStart
function NTPlayerTurnStart:Constructor(teamEntity, formerTeamOrder)
    self._teamEntity = teamEntity
    self._formerTeamOrder = formerTeamOrder
end

function NTPlayerTurnStart:GetNotifyEntity()
    return self._teamEntity
end

function NTPlayerTurnStart:NeedCheckGameTurn()
    return true
end

function NTPlayerTurnStart:GetNotifyType()
    return NotifyType.PlayerTurnStart
end

function NTPlayerTurnStart:GetFormerTeamOrder()
    return self._formerTeamOrder
end

_class("NTPlayerTurnBuffAddRoundEnd", INotifyBase)
NTPlayerTurnBuffAddRoundEnd = NTPlayerTurnBuffAddRoundEnd

function NTPlayerTurnBuffAddRoundEnd:Constructor(teamEntity)
    self._teamEntity = teamEntity
end

function NTPlayerTurnBuffAddRoundEnd:GetNotifyType()
    return NotifyType.PlayerTurnBuffAddRoundEnd
end

function NTPlayerTurnBuffAddRoundEnd:GetNotifyEntity()
    return self._teamEntity
end

function NTPlayerTurnBuffAddRoundEnd:NeedCheckGameTurn()
    return true
end

_class("NTPlayerTurnBuffAddRoundEndAfter", NTPlayerTurnBuffAddRoundEnd)
---@class NTPlayerTurnBuffAddRoundEndAfter : NTPlayerTurnBuffAddRoundEnd
NTPlayerTurnBuffAddRoundEndAfter = NTPlayerTurnBuffAddRoundEndAfter

---
function NTPlayerTurnBuffAddRoundEndAfter:GetNotifyType()
    return NotifyType.PlayerTurnBuffAddRoundEndAfter
end

--玩家回合开始的最后阶段
_class("NTPlayerTurnStartLast", INotifyBase)
NTPlayerTurnStartLast = NTPlayerTurnStartLast
function NTPlayerTurnStartLast:Constructor(teamEntity)
    self._teamEntity = teamEntity
end
function NTPlayerTurnStartLast:GetNotifyType()
    return NotifyType.PlayerTurnStartLast
end

function NTPlayerTurnStartLast:GetNotifyEntity()
    return self._teamEntity
end

function NTPlayerTurnStartLast:NeedCheckGameTurn()
    return true
end

--玩家回合结束
_class("NTPlayerTurnEnd", INotifyBase)
NTPlayerTurnEnd = NTPlayerTurnEnd
function NTPlayerTurnEnd:Constructor(teamEntity)
    self._teamEntity = teamEntity
end

function NTPlayerTurnEnd:GetNotifyType()
    return NotifyType.PlayerTurnEnd
end

function NTPlayerTurnEnd:GetNotifyEntity()
    return self._teamEntity
end

function NTPlayerTurnEnd:NeedCheckGameTurn()
    return true
end

--拾取掉落
_class("NTPlayerPickDrop", INotifyBase)
NTPlayerPickDrop = NTPlayerPickDrop
function NTPlayerPickDrop:Constructor()
end

function NTPlayerPickDrop:GetNotifyType()
    return NotifyType.PlayerPickDrop
end

--超级连锁
_class("NTPlayerSuperChain", INotifyBase)
NTPlayerSuperChain = NTPlayerSuperChain
function NTPlayerSuperChain:Constructor()
end

function NTPlayerSuperChain:GetNotifyType()
    return NotifyType.PlayerSuperChain
end

--怪物技能伤害结算前
_class("NTMonsterSkillDamageStart", INotifyBase)
NTMonsterSkillDamageStart = NTMonsterSkillDamageStart
function NTMonsterSkillDamageStart:Constructor(monster_entity,skillId)
    self._monster_entity = monster_entity
    self._skillId = skillId
end

function NTMonsterSkillDamageStart:GetNotifyType()
    return NotifyType.MonsterSkillDamageStart
end

function NTMonsterSkillDamageStart:GetNotifyEntity()
    return self._monster_entity
end

function NTMonsterSkillDamageStart:GetSkillID()
    return self._skillId
end

--怪物非普攻的技能伤害结算后
_class("NTMonsterSkillDamageEnd", INotifyBase)
NTMonsterSkillDamageEnd = NTMonsterSkillDamageEnd
function NTMonsterSkillDamageEnd:Constructor(monster_entity, skillId)
    self._monster_entity = monster_entity
    self._skillId = skillId
end
function NTMonsterSkillDamageEnd:GetNotifyType()
    return NotifyType.MonsterSkillDamageEnd
end
function NTMonsterSkillDamageEnd:GetNotifyEntity()
    return self._monster_entity
end

function NTMonsterSkillDamageEnd:GetSkillID()
    return self._skillId
end

---回合结束
_class("NTRoundTurnEnd", INotifyBase)
---@class NTRoundTurnEnd :INotifyBase
NTRoundTurnEnd = NTRoundTurnEnd
function NTRoundTurnEnd:Constructor(team)
    self._enemyTeam = team
end

function NTRoundTurnEnd:GetNotifyType()
    return NotifyType.RoundTurnEnd
end

function NTRoundTurnEnd:GetNotifyEntity()
    return self._enemyTeam
end

---进入波次
_class("NTWaveEnter", INotifyBase)
---@class NTWaveEnter :INotifyBase
NTWaveEnter = NTWaveEnter
function NTWaveEnter:Constructor(waveNum)
    self._waveNum = waveNum
end

function NTWaveEnter:GetNotifyType()
    return NotifyType.WaveEnter
end

function NTWaveEnter:GetWaveNum()
    return self._waveNum
end

---波次开始
_class("NTWaveTurnStart", INotifyBase)
---@class NTWaveTurnStart :INotifyBase
NTWaveTurnStart = NTWaveTurnStart
function NTWaveTurnStart:Constructor(waveNum)
    self._waveNum = waveNum
end

function NTWaveTurnStart:GetNotifyType()
    return NotifyType.WaveTurnStart
end

function NTWaveTurnStart:GetWaveNum()
    return self._waveNum
end

---波次结束
_class("NTWaveTurnEnd", INotifyBase)
---@class NTWaveTurnEnd :INotifyBase
NTWaveTurnEnd = NTWaveTurnEnd
function NTWaveTurnEnd:Constructor(waveNum)
    self._waveNum = waveNum
end

function NTWaveTurnEnd:GetNotifyType()
    return NotifyType.WaveTurnEnd
end

function NTWaveTurnEnd:GetWaveNum()
    return self._waveNum
end

--机关技能触发之前
_class("NTTrapSkillStart", INotifyBase)
---@class NTTrapSkillStart : INotifyBase
NTTrapSkillStart = NTTrapSkillStart
----@param trapEntity Entity
function NTTrapSkillStart:Constructor(trapEntity, skillID, triggerEntity)
    self._trapEntity = trapEntity
    self._skillID = skillID
    self._triggerEntity = triggerEntity
    self._isActiveSkillFake = false
end

function NTTrapSkillStart:GetTriggerEntity()
    return self._triggerEntity
end

function NTTrapSkillStart:GetNotifyType()
    return NotifyType.TrapSkillStart
end

function NTTrapSkillStart:GetNotifyEntity()
    return self._trapEntity
end

function NTTrapSkillStart:GetSkillID()
    return self._skillID
end

function NTTrapSkillStart:GetPos()
    return self._trapEntity:GetGridPosition()
end

function NTTrapSkillStart:GetNotifyPos()
    return self._trapEntity:GetGridPosition()
end

function NTTrapSkillStart:GetPosPieceType()
    local boardCmpt = self._trapEntity._world:GetBoardEntity():Board()
    return boardCmpt:GetPieceType(self:GetPos())
end
--光灵 米洛斯 主动技吸收时仿造的通知
function NTTrapSkillStart:SetIsActiveSkillFake(bActiveSkill)
    self._isActiveSkillFake = bActiveSkill
end
function NTTrapSkillStart:GetIsActiveSkillFake()
    return self._isActiveSkillFake
end

--机关技能触发之后
_class("NTTrapSkillEnd", INotifyBase)
---@class NTTrapSkillEnd : INotifyBase
NTTrapSkillEnd = NTTrapSkillEnd
----@param trapEntity Entity
function NTTrapSkillEnd:Constructor(trapEntity, skillID, triggerEntity)
    self._trapEntity = trapEntity
    self._skillID = skillID
    self._triggerEntity = triggerEntity
end

function NTTrapSkillEnd:GetTriggerEntity()
    return self._triggerEntity
end

function NTTrapSkillEnd:GetNotifyType()
    return NotifyType.TrapSkillEnd
end

function NTTrapSkillEnd:GetNotifyEntity()
    return self._trapEntity
end
function NTTrapSkillEnd:GetSkillID()
    return self._skillID
end

--主动技能造成伤害后
_class("NTActiveSkillDamageEnd", INotifyBase)
---@class NTActiveSkillDamageEnd : INotifyBase
NTActiveSkillDamageEnd = NTActiveSkillDamageEnd
----@param attacker Entity
function NTActiveSkillDamageEnd:Constructor(attacker, damage)
    self._attacker = attacker
    self._damage = damage
end

function NTActiveSkillDamageEnd:GetNotifyType()
    return NotifyType.ActiveSkillDamageEnd
end

function NTActiveSkillDamageEnd:GetNotifyEntity()
    return self._attacker
end

function NTActiveSkillDamageEnd:GetDamage()
    return self._damage
end

function NTActiveSkillDamageEnd:NeedCheckGameTurn()
    return true
end

--联锁技造成伤害后
_class("NTChainSkillDamageEnd", INotifyBase)
---@class NTChainSkillDamageEnd : INotifyBase
NTChainSkillDamageEnd = NTChainSkillDamageEnd
----@param attacker Entity
function NTChainSkillDamageEnd:Constructor(attacker, damage, targetMap)
    self._attacker = attacker
    self._damage = damage

    self._targetMap = {}
    if targetMap then
        for _, eid in ipairs(targetMap) do
            self._targetMap[eid] = true
        end
    end
end

function NTChainSkillDamageEnd:GetNotifyType()
    return NotifyType.ChainSkillDamageEnd
end

function NTChainSkillDamageEnd:GetNotifyEntity()
    return self._attacker
end

function NTChainSkillDamageEnd:GetDamage()
    return self._damage
end

function NTChainSkillDamageEnd:GetTargetMap()
    return self._targetMap
end

function NTChainSkillDamageEnd:NeedCheckGameTurn()
    return true
end

--怪物普攻或者技能伤害
_class("NTMonsterAttackOrSkillDamageEnd", INotifyBase)
---@class NTMonsterAttackOrSkillDamageEnd : INotifyBase
NTMonsterAttackOrSkillDamageEnd = NTMonsterAttackOrSkillDamageEnd
----@param attacker Entity
function NTMonsterAttackOrSkillDamageEnd:Constructor(attacker, damage)
    self._attacker = attacker
    self._damage = damage
end

function NTMonsterAttackOrSkillDamageEnd:GetNotifyType()
    return NotifyType.MonsterAttackOrSkillDamageEnd
end

function NTMonsterAttackOrSkillDamageEnd:GetNotifyEntity()
    return self._attacker
end

function NTMonsterAttackOrSkillDamageEnd:GetDamage()
    return self._damage
end

--怪物普攻或者技能伤害
_class("NTBreakHPLock", INotifyBase)
---@class NTBreakHPLock : INotifyBase
NTBreakHPLock = NTBreakHPLock
function NTBreakHPLock:Constructor(notifyEntity, isUnlockHP)
    self._notifyEntity = notifyEntity
    self._isUnlockHP = isUnlockHP
end

function NTBreakHPLock:GetNotifyType()
    return NotifyType.BreakHPLock
end

function NTBreakHPLock:GetNotifyEntity()
    return self._notifyEntity
end

function NTBreakHPLock:GetIsUnlockHP()
    return self._isUnlockHP
end

--能量已满
_class("NTPowerReady", INotifyBase)
---@class NTPowerReady : INotifyBase
NTPowerReady = NTPowerReady
function NTPowerReady:Constructor(petEntity)
    self._petEntity = petEntity
end
function NTPowerReady:GetNotifyEntity()
    return self._petEntity
end

function NTPowerReady:GetNotifyType()
    return NotifyType.PowerReady
end

function NTPowerReady:NeedCheckGameTurn()
    return true
end

--收集灵魂
_class("NTCollectSouls", INotifyBase)
---@class NTCollectSouls : INotifyBase
NTCollectSouls = NTCollectSouls
function NTCollectSouls:Constructor(casterEntity, soulNum, targetEntityList)
    self._soulNum = soulNum
    self._casterEntity = casterEntity
    self._targetEntityList = targetEntityList
end
function NTCollectSouls:GetNotifyType()
    return NotifyType.CollectSouls
end
function NTCollectSouls:GetSoulNum()
    return self._soulNum
end

function NTCollectSouls:GetNotifyEntity()
    return self._casterEntity
end

function NTCollectSouls:GetTargetEntityList()
    return self._targetEntityList
end

function NTCollectSouls:NeedCheckGameTurn()
    return true
end

--锁血
_class("NTHPLock", INotifyBase)
---@class NTHPLock : INotifyBase
NTHPLock = NTHPLock
function NTHPLock:Constructor(index, percent, notifyEntity)
    self._lockPercent = percent
    self._index = index
    self._notifyEntity = notifyEntity
end
function NTHPLock:GetNotifyType()
    return NotifyType.HPLock
end
function NTHPLock:GetLockPercent()
    return self._lockPercent
end

function NTHPLock:GetIndex()
    return self._index
end

function NTHPLock:GetNotifyEntity()
    return self._notifyEntity
end

function NTHPLock:SetNotifyEntity(notifyEntity)
    self._notifyEntity = notifyEntity
end

--通知触发buff
_class("NTNotifyTriggerBuff", INotifyBase)
---@class NTNotifyTriggerBuff : INotifyBase
NTNotifyTriggerBuff = NTNotifyTriggerBuff
function NTNotifyTriggerBuff:Constructor(entity)
    self._entity = entity
end
function NTNotifyTriggerBuff:GetNotifyType()
    return NotifyType.NotifyTriggerBuff
end

function NTNotifyTriggerBuff:GetNotifyEntity()
    return self._entity
end

_class("NTNotifyTrainFirstRowPos", INotifyBase)
---@class NTNotifyTrainFirstRowPos : INotifyBase
NTNotifyTrainFirstRowPos = NTNotifyTrainFirstRowPos
function NTNotifyTrainFirstRowPos:Constructor(firstRowPosList, entity)
    self._entity = entity
    self._firstRowPosList = firstRowPosList
end
function NTNotifyTrainFirstRowPos:GetNotifyType()
    return NotifyType.NotifyTrainFirstRowPos
end

function NTNotifyTrainFirstRowPos:GetData()
    return self._firstRowPosList
end

function NTNotifyTrainFirstRowPos:GetNotifyEntity()
    return self._entity
end

function NTNotifyTrainFirstRowPos:NeedCheckGameTurn()
    return true
end

_class("NTEachAddBuff", INotifyBase)
---@class NTEachAddBuff : INotifyBase
NTEachAddBuff = NTEachAddBuff
function NTEachAddBuff:Constructor(skillId, attacker, defender, attackRange)
    self._skillId = skillId
    self._attacker = attacker
    self._defender = defender
    self._attackRange = attackRange
end

function NTEachAddBuff:GetAttackerEntity()
    return self._attacker
end

---@return Entity
function NTEachAddBuff:GetDefenderEntity()
    return self._defender
end
---@return Vector2[]
function NTEachAddBuff:GetAttackRange()
    return self._attackRange
end

function NTEachAddBuff:GetNotifyEntity()
    return self._attacker
end

function NTEachAddBuff:GetSkillID()
    return self._skillId
end

function NTEachAddBuff:NeedCheckGameTurn()
    return true
end

_class("NTEachAddBuffStart", NTEachAddBuff)
---@class NTEachAddBuffStart : NTEachAddBuff
NTEachAddBuffStart = NTEachAddBuffStart

function NTEachAddBuffStart:GetNotifyType()
    return NotifyType.EachAddBuffStart
end

_class("NTEachAddBuffEnd", NTEachAddBuff)
---@class NTEachAddBuffEnd : NTEachAddBuff
NTEachAddBuffEnd = NTEachAddBuffEnd

function NTEachAddBuffEnd:Constructor(skillId, attacker, defender, attackRange, buffID, seqID)
    self._buffID = buffID
    self._seqID = seqID
end

function NTEachAddBuffEnd:GetNotifyType()
    return NotifyType.EachAddBuffEnd
end

function NTEachAddBuffEnd:GetBuffID()
    return self._buffID
end

function NTEachAddBuffEnd:GetBuffSeqID()
    return self._seqID
end

--灵魂冲击计算
_class("NTRandAttackBegin", NotifyAttackBase)
---@class NTRandAttackBegin : NotifyAttackBase
NTRandAttackBegin = NTRandAttackBegin

function NTRandAttackBegin:Constructor(entity)
    self.entity = entity
end

function NTRandAttackBegin:GetNotifyEntity()
    return self.entity
end

function NTRandAttackBegin:NeedCheckGameTurn()
    return true
end

function NTRandAttackBegin:GetNotifyType()
    return NotifyType.RandAttackBegin
end

--灵魂冲击计算后
_class("NTRandAttackEnd", NotifyAttackBase)
---@class NTRandAttackEnd : NotifyAttackBase
NTRandAttackEnd = NTRandAttackEnd

function NTRandAttackEnd:Constructor(entity)
    self._entity = entity
end

function NTRandAttackEnd:GetNotifyEntity()
    return self._entity
end

function NTRandAttackEnd:NeedCheckGameTurn()
    return true
end

function NTRandAttackEnd:GetNotifyType()
    return NotifyType.RandAttackEnd
end

--炸弹爆炸
_class("NTTrapAction", INotifyBase)
---@class NTTrapAction :INotifyBase
NTTrapAction = NTTrapAction
----@param entity Entity
function NTTrapAction:Constructor(entity, posAction)
    self._ownerEntity = entity
    self._posAction = posAction
end

function NTTrapAction:GetNotifyType()
    return NotifyType.TrapAction
end

function NTTrapAction:GetNotifyEntity()
    return self._ownerEntity
end
function NTTrapAction:GetPosAction()
    return self._posAction
end
----------------------------------------------------------------

_class("NTGridConvert_ConvertInfo", Object)
---@class NTGridConvert_ConvertInfo : Object
NTGridConvert_ConvertInfo = NTGridConvert_ConvertInfo

function NTGridConvert_ConvertInfo:Constructor(pos, before, after)
    self._pos = pos
    self._beforePieceType = before
    self._afterPieceType = after
end

function NTGridConvert_ConvertInfo:GetPos()
    return self._pos
end
function NTGridConvert_ConvertInfo:GetBeforePieceType()
    return self._beforePieceType
end
function NTGridConvert_ConvertInfo:GetAfterPieceType()
    return self._afterPieceType
end

_class("NTGridConvert", INotifyBase)
---@class NTGridConvert : INotifyBase
NTGridConvert = NTGridConvert

---@param entity Entity
---@param convertInfoArray NTGridConvert_ConvertInfo[]
function NTGridConvert:Constructor(entity, convertInfoArray)
    self._entity = entity
    self._convertInfoArray = convertInfoArray
    self._convertPosInfoMap = {}
    if convertInfoArray then
        for _, convertInfo in ipairs(convertInfoArray) do
            local pos = convertInfo:GetPos()
            local x = pos.x
            local y = pos.y
            if not self._convertPosInfoMap[x] then
                self._convertPosInfoMap[x] = {}
            end
            self._convertPosInfoMap[x][y] = convertInfo
        end
    end
end
----@param skillType SkillType
function NTGridConvert:SetSkillType(skillType)
   self._skillType = skillType
end
----@return SkillType
function NTGridConvert:GetSkillType()
    return self._skillType
end

function NTGridConvert:GetNotifyType()
    return NotifyType.GridConvert
end

function NTGridConvert:GetNotifyEntity()
    if self._entity then
        if self._entity:HasSuperEntity() and self._entity:EntityType():IsSkillHolder() then
            return self._entity:GetSuperEntity()
        end
    end
    return self._entity
end

---@return NTGridConvert_ConvertInfo|nil
function NTGridConvert:GetConvertInfoAt(pos)
    return self._convertPosInfoMap[pos.x] and self._convertPosInfoMap[pos.x][pos.y] or nil
end
---@return NTGridConvert_ConvertInfo[]
function NTGridConvert:GetConvertInfoArray()
    return self._convertInfoArray
end

function NTGridConvert:NeedCheckGameTurn()
    return true
end

function NTGridConvert:SetConvertEffectType(val)
    self._convertEffectType = val
end

function NTGridConvert:GetConvertEffectType()
    return self._convertEffectType
end

function NTGridConvert:SetConvertWaterCount(val)
    self._convertWaterCount = val
end

function NTGridConvert:GetConvertWaterCount()
    return self._convertWaterCount
end

--进入极光时刻
_class("NTEnterAuroraTime", INotifyBase)
NTEnterAuroraTime = NTEnterAuroraTime
----@param pos Vector2
function NTEnterAuroraTime:Constructor(chainPathStartPos, teamEntity)
    self._chainPathStartPos = chainPathStartPos
    self._teamEntity = teamEntity
end

function NTEnterAuroraTime:GetNotifyType()
    return NotifyType.EnterAuroraTime
end
function NTEnterAuroraTime:GetNotifyPos()
    return self._chainPathStartPos
end

function NTEnterAuroraTime:GetNotifyEntity()
    return self._teamEntity
end

function NTEnterAuroraTime:NeedCheckGameTurn()
    return true
end

--移动走过的格子
_class("NTRefreshGridOnPetMoveDone", INotifyBase)
---@class NTRefreshGridOnPetMoveDone:INotifyBase
NTRefreshGridOnPetMoveDone = NTRefreshGridOnPetMoveDone
----@param oldChainPathGrid table<Vector2,PieceType>
----@param newChainPathGrid table<number,Vector2,PieceType>
function NTRefreshGridOnPetMoveDone:Constructor(oldChainPathGrid, newChainPathGrid, teamEntity)
    self._oldChainPathGrid = oldChainPathGrid
    self._newChainPathGrid = newChainPathGrid
    self._teamEntity = teamEntity
end

function NTRefreshGridOnPetMoveDone:GetNotifyType()
    return NotifyType.RefreshGridOnPetMoveDone
end
---@return table<Vector2,PieceType>
function NTRefreshGridOnPetMoveDone:GetOldChainPathGrid()
    return self._oldChainPathGrid
end
---@return table<number,Vector2,PieceType>
function NTRefreshGridOnPetMoveDone:GetNewChainPathGrid()
    return self._newChainPathGrid
end

function NTRefreshGridOnPetMoveDone:GetNotifyEntity()
    return self._teamEntity
end

function NTRefreshGridOnPetMoveDone:NeedCheckGameTurn()
    return true
end

_class("NTResetGridElement", INotifyBase)
---@class NTResetGridElement:INotifyBase
NTResetGridElement = NTResetGridElement
----@param resetGridDataList SkillEffectResult_ResetGridData[]
function NTResetGridElement:Constructor(resetGridDataList, notifyEntity)
    self._resetGridDataList = resetGridDataList
    self._notifyEntity = notifyEntity
end

function NTResetGridElement:GetNotifyType()
    return NotifyType.ResetGridElement
end
function NTResetGridElement:GetNotifyEntity()
    return self._notifyEntity
end

function NTResetGridElement:GetResetGridDataList()
    return self._resetGridDataList
end

function NTResetGridElement:NeedCheckGameTurn()
    return true
end

--战斗结束
_class("NTGameOver", INotifyBase)
NTGameOver = NTGameOver
----@param entity Entity
---@param defeatType PlayerDefeatType
function NTGameOver:Constructor(victory, defeatType)
    self.victory = victory
    self.defeatType = defeatType
end

function NTGameOver:GetNotifyType()
    return NotifyType.GameOver
end

function NTGameOver:GetVictory()
    return self.victory
end

function NTGameOver:GetDefeatType()
    return self.defeatType
end

--战斗结束
_class("NTNotifyLayerChange", INotifyBase)
---@class NTNotifyLayerChange:INotifyBase
NTNotifyLayerChange = NTNotifyLayerChange
----@param layerName string
function NTNotifyLayerChange:Constructor(layerName, layer, count, notifyPos, entity, layerType, casterEntity)
    self.layerName = layerName
    self._layer = layer
    self._totalCount = count
    self._notifyPos = notifyPos
    self._entity = entity
    self._layerType = layerType
    self._casterEntity = casterEntity
end

function NTNotifyLayerChange:GetNotifyType()
    return NotifyType.NotifyLayerChange
end

function NTNotifyLayerChange:GetLayerName()
    return self.layerName
end

function NTNotifyLayerChange:GetLayer()
    return self._layer
end

function NTNotifyLayerChange:GetTotalCount()
    return self._totalCount
end

function NTNotifyLayerChange:GetNotifyPos()
    return self._notifyPos
end

function NTNotifyLayerChange:GetNotifyEntity()
    return self._entity
end

function NTNotifyLayerChange:SetChangeLayer(change)
    self._changeLayer = change
end

function NTNotifyLayerChange:GetChangeLayer()
    return self._changeLayer
end

function NTNotifyLayerChange:NeedCheckGameTurn()
    return false
end

function NTNotifyLayerChange:GetLayerType()
    return self._layerType
end

function NTNotifyLayerChange:GetCasterEntity()
    return self._casterEntity
end

--Pet主属性和阵营等信息
_class("NTPetCreate", INotifyBase)
---@class NTPetCreate:INotifyBase
NTPetCreate = NTPetCreate
----@param element number 主属性
----@param campID number 阵营
function NTPetCreate:Constructor(element, campID, entity)
    self.element = element
    self.campID = campID
    self._entity = entity
end

function NTPetCreate:GetNotifyType()
    return NotifyType.PetCreate
end

function NTPetCreate:GetNotifyEntity()
    return self._entity
end

-- function NTPetCreate:NeedCheckGameTurn()
--     return true
-- end

function NTPetCreate:GetElement()
    return self.element
end

function NTPetCreate:GetCampID()
    return self.campID
end

_class("NTPetActiveSkillPreviousReady", INotifyBase)
---@class NTPetActiveSkillPreviousReady : INotifyBase
NTPetActiveSkillPreviousReady = NTPetActiveSkillPreviousReady

function NTPetActiveSkillPreviousReady:GetNotifyType()
    return NotifyType.PetActiveSkillPreviousReady
end

function NTPetActiveSkillPreviousReady:Constructor(casterEntity)
    self._owner = casterEntity
end

function NTPetActiveSkillPreviousReady:GetNotifyEntity()
    return self._owner
end

function NTPetActiveSkillPreviousReady:NeedCheckGameTurn()
    return true
end

--删除护盾层数
_class("NTReduceShieldLayer", INotifyBase)
NTReduceShieldLayer = NTReduceShieldLayer
function NTReduceShieldLayer:Constructor(entity, layer)
    self._notifyEntity = entity
    self._layer = layer
end

function NTReduceShieldLayer:GetNotifyType()
    return NotifyType.ReduceShieldLayer
end
function NTReduceShieldLayer:GetNotifyEntity()
    return self._notifyEntity
end

function NTReduceShieldLayer:GetNotifyLayer()
    return self._layer
end

_class("NTEachPetChainSkillFinish", INotifyBase)
---@class NTEachPetChainSkillFinish : INotifyBase
NTEachPetChainSkillFinish = NTEachPetChainSkillFinish

function NTEachPetChainSkillFinish:Constructor()
end
function NTEachPetChainSkillFinish:GetNotifyType()
    return NotifyType.EachPetChainSkillFinish
end
---@return Entity
function NTEachPetChainSkillFinish:GetNotifyEntity()
    return self._notifyEntity
end
---@param entity Entity
function NTEachPetChainSkillFinish:SetNotifyEntity(entity)
    self._notifyEntity = entity
end

function NTEachPetChainSkillFinish:SetChainCount(cnt)
    self._chainCount = cnt
end

function NTEachPetChainSkillFinish:GetChainCount()
    return self._chainCount
end

function NTEachPetChainSkillFinish:NeedCheckGameTurn()
    return true
end

---@class NTChainPathSelectTarget : INotifyBase
_class("NTChainPathSelectTarget", INotifyBase)
NTChainPathSelectTarget = NTChainPathSelectTarget

function NTChainPathSelectTarget:Constructor()
end
function NTChainPathSelectTarget:GetNotifyType()
    return NotifyType.ChainPathSelectTarget
end
---@return Entity
function NTChainPathSelectTarget:GetNotifyEntity()
    return self._notifyEntity
end
---@param entity Entity
function NTChainPathSelectTarget:SetNotifyEntity(entity)
    self._notifyEntity = entity
end

function NTChainPathSelectTarget:SetChainCount(cnt)
    self._chainCount = cnt
end

function NTChainPathSelectTarget:GetChainCount()
    return self._chainCount
end

function NTChainPathSelectTarget:NeedCheckGameTurn()
    return true
end

---@class NTWaitInput : INotifyBase
_class("NTWaitInput", INotifyBase)
NTWaitInput = NTWaitInput

function NTWaitInput:Constructor()
end
function NTWaitInput:GetNotifyType()
    return NotifyType.WaitInput
end

---@class NTAttachMonster : INotifyBase
_class("NTAttachMonster", INotifyBase)
function NTAttachMonster:Constructor(casterEntity, targetEntity)
    self._casterEntity = casterEntity
    self._targetEntity = targetEntity
end

function NTAttachMonster:GetNotifyType()
    return NotifyType.AttachMonster
end

function NTAttachMonster:GetNotifyEntity()
    return self._casterEntity
end

function NTAttachMonster:GetDefenderEntity()
    return self._targetEntity
end

---@class NTChangeTeamLeader : INotifyBase
_class("NTChangeTeamLeader", INotifyBase)
function NTChangeTeamLeader:Constructor(teamLeader, oldTeamLeader)
    self._teamLeader = teamLeader
    self._oldTeamLeader = oldTeamLeader
end

function NTChangeTeamLeader:GetTeamLeaderPetPstID()
    return self._teamLeader:PetPstID():GetPetPstID()
end

function NTChangeTeamLeader:GetNotifyType()
    return NotifyType.ChangeTeamLeader
end

function NTChangeTeamLeader:GetNotifyEntity()
    return self._teamLeader
end

function NTChangeTeamLeader:NeedCheckGameTurn()
    return true
end

function NTChangeTeamLeader:GetNewTeamLeader()
    return self._teamLeader
end

function NTChangeTeamLeader:GetOldTeamLeader()
    return self._oldTeamLeader
end

_class("NTAddBuffEnd", INotifyBase)
NTAddBuffEnd = NTAddBuffEnd

function NTAddBuffEnd:Constructor(entity, buffseq, buffid, buffeff)
    self.entity = entity
    self.buffseq = buffseq
    self.buffid = buffid
    self.buffeff = buffeff
end

function NTAddBuffEnd:GetNotifyType()
    return NotifyType.AddBuffEnd
end

function NTAddBuffEnd:GetNotifyEntity()
    return self.entity
end

function NTAddBuffEnd:GetBuffSeq()
    return self.buffseq
end

function NTAddBuffEnd:GetBuffEffectType()
    return self.buffeff
end

function NTAddBuffEnd:GetBuffID()
    return self.buffid
end

function NTAddBuffEnd:NeedCheckGameTurn()
    return true
end

_class("NTRemoveBuffEnd", INotifyBase)
NTRemoveBuffEnd = NTRemoveBuffEnd

function NTRemoveBuffEnd:Constructor(entity, buffseq, buffid, buffeff)
    self.entity = entity
    self.buffseq = buffseq
    self.buffid = buffid
    self.buffeff = buffeff
end

function NTRemoveBuffEnd:GetNotifyType()
    return NotifyType.RemoveBuffEnd
end

function NTRemoveBuffEnd:GetNotifyEntity()
    return self._entity
end

function NTRemoveBuffEnd:GetBuffSeq()
    return self.buffseq
end

function NTRemoveBuffEnd:GetBuffEffectType()
    return self.buffeff
end

function NTRemoveBuffEnd:GetBuffID()
    return self.buffid
end

function NTRemoveBuffEnd:NeedCheckGameTurn()
    return true
end

_class("NTAddMatchLog", INotifyBase)
NTAddMatchLog = NTAddMatchLog

function NTAddMatchLog:Constructor(info)
    self._info = info
end

function NTAddMatchLog:GetNotifyType()
    return NotifyType.AddMatchLog
end

function NTAddMatchLog:GetMatchLogInfo()
    return self._info
end

_class("NTBeforeHighFrequencyDamageHit", INotifyBase)
---@class NTBeforeHighFrequencyDamageHit: INotifyBase
NTBeforeHighFrequencyDamageHit = NTBeforeHighFrequencyDamageHit

function NTBeforeHighFrequencyDamageHit:Constructor(entity, hitIndex)
    self._ownerEntity = entity
    self._hitIndex = hitIndex
end

function NTBeforeHighFrequencyDamageHit:GetNotifyType()
    return NotifyType.BeforeHighFrequencyDamageHit
end

---@return Entity
function NTBeforeHighFrequencyDamageHit:GetNotifyEntity()
    return self._ownerEntity
end

function NTBeforeHighFrequencyDamageHit:GetHitIndex()
    return self._hitIndex
end

function NTBeforeHighFrequencyDamageHit:NeedCheckGameTurn()
    return true
end

_class("NTAfterHighFrequencyDamageHit", INotifyBase)
---@class NTAfterHighFrequencyDamageHit: INotifyBase
NTAfterHighFrequencyDamageHit = NTAfterHighFrequencyDamageHit

function NTAfterHighFrequencyDamageHit:Constructor(entity, hitIndex)
    self._ownerEntity = entity
    self._hitIndex = hitIndex
end

function NTAfterHighFrequencyDamageHit:GetNotifyType()
    return NotifyType.AfterHighFrequencyDamageHit
end

---@return Entity
function NTAfterHighFrequencyDamageHit:GetNotifyEntity()
    return self._ownerEntity
end

function NTAfterHighFrequencyDamageHit:GetHitIndex()
    return self._hitIndex
end

function NTAfterHighFrequencyDamageHit:NeedCheckGameTurn()
    return true
end

_class("NTBeforeMazeTeamLeaderSucceed", INotifyBase)
---@class NTBeforeMazeTeamLeaderSucceed: INotifyBase
NTBeforeMazeTeamLeaderSucceed = NTBeforeMazeTeamLeaderSucceed

function NTBeforeMazeTeamLeaderSucceed:GetNotifyType()
    return NotifyType.BeforeMazeTeamLeaderSucceed
end

function NTBeforeMazeTeamLeaderSucceed:Constructor(e)
    self._entity = e
end

function NTBeforeMazeTeamLeaderSucceed:GetNotifyEntity()
    return self._entity
end

function NTBeforeMazeTeamLeaderSucceed:NeedCheckGameTurn()
    return true
end

---波次结束
_class("NTWaveSwitch", INotifyBase)
---@class NTWaveSwitch :INotifyBase
NTWaveSwitch = NTWaveSwitch
function NTWaveSwitch:Constructor(waveNum)
    self._waveNum = waveNum
end

function NTWaveSwitch:GetNotifyType()
    return NotifyType.WaveSwitch
end

function NTWaveSwitch:GetWaveNum()
    return self._waveNum
end

---世界Boss阶段切换
_class("NTWorldBossStageSwitch", INotifyBase)
---@class NTWorldBossStageSwitch :INotifyBase
NTWorldBossStageSwitch = NTWorldBossStageSwitch
function NTWorldBossStageSwitch:Constructor(stage)
    self._stage = stage
end

function NTWorldBossStageSwitch:GetNotifyType()
    return NotifyType.WorldBossStageSwitch
end

---世界Boss阶段切换
_class("NTResetGridFlushTrap", INotifyBase)
---@class NTResetGridFlushTrap :INotifyBase
NTResetGridFlushTrap = NTResetGridFlushTrap
function NTResetGridFlushTrap:Constructor(trapList)
    self._trapList = trapList
end

function NTResetGridFlushTrap:GetNotifyType()
    return NotifyType.ResetGridFlushTrap
end

function NTResetGridFlushTrap:GetFlushTrapList()
    return self._trapList
end
--主动技反制
_class("NTActiveSkillAntiAttack", INotifyBase)
---@class NTActiveSkillAntiAttack : INotifyBase
NTActiveSkillAntiAttack = NTActiveSkillAntiAttack
----@param attacker Entity
function NTActiveSkillAntiAttack:Constructor(attacker)
    self._attacker = attacker
end

function NTActiveSkillAntiAttack:GetNotifyType()
    return NotifyType.ActiveSkillAntiAttack
end

function NTActiveSkillAntiAttack:GetNotifyEntity()
    return self._attacker
end
--敌我双方触发都通知
function NTActiveSkillAntiAttack:NeedCheckGameTurn()
    return false
end

--主动技反制
_class("NTMonsterPostAntiAttack", INotifyBase)
---@class NTMonsterPostAntiAttack : INotifyBase
NTMonsterPostAntiAttack = NTMonsterPostAntiAttack
----@param e Entity
function NTMonsterPostAntiAttack:Constructor(e)
    self._entity = e
end

function NTMonsterPostAntiAttack:GetNotifyType()
    return NotifyType.MonsterPostAntiAttack
end

function NTMonsterPostAntiAttack:GetNotifyEntity()
    return self._entity
end

_class("NTExitAuroraTime", INotifyBase)
---@class NTExitAuroraTime : INotifyBase
NTExitAuroraTime = NTExitAuroraTime

function NTExitAuroraTime:GetNotifyType()
    return NotifyType.ExitAuroraTime
end

_class("NTTrapDead", INotifyBase)
---@class NTTrapDead : INotifyBase
NTTrapDead = NTTrapDead

----@param e Entity
function NTTrapDead:Constructor(e,trapID)
    self._entity = e
    self._trapID = trapID
end

function NTTrapDead:SetOwnerEntity(entity)
    self._ownerEntity = entity
end

function NTTrapDead:GetOwnerEntity()
    return self._ownerEntity
end

function NTTrapDead:GetTrapID()
    return self._trapID
end

function NTTrapDead:GetNotifyType()
    return NotifyType.TrapDead
end

function NTTrapDead:GetNotifyEntity()
    return self._entity
end

_class("NTTrapDeadStart", INotifyBase)
---@class NTTrapDeadStart : INotifyBase
NTTrapDeadStart = NTTrapDeadStart

----@param e Entity
function NTTrapDeadStart:Constructor(e)
    self._entity = e
end

function NTTrapDeadStart:GetNotifyType()
    return NotifyType.TrapDeadStart
end

function NTTrapDeadStart:GetNotifyEntity()
    return self._entity
end

function NTTrapDeadStart:SetOwnerEntity(entity)
    self._ownerEntity = entity
end

function NTTrapDeadStart:GetOwnerEntity()
    return self._ownerEntity
end

_class("NTTrapShow", INotifyBase)
---@class NTTrapShow : INotifyBase
NTTrapShow = NTTrapShow

----@param e Entity
function NTTrapShow:Constructor(e, summoner)
    self._entity = e
    self._summoner = summoner
    self._isFirstSummon = false
end

function NTTrapShow:GetNotifyType()
    return NotifyType.TrapShow
end

function NTTrapShow:GetNotifyEntity()
    return self._entity
end

function NTTrapShow:SetIsFirstSummon(b)
    self._isFirstSummon = b
end

function NTTrapShow:IsFirstSummon()
    return self._isFirstSummon
end

function NTTrapShow:GetOwnerEntity()
    return self._summoner
end

--敌方回合开始
_class("NTEnemyTurnStart", INotifyBase)
NTEnemyTurnStart = NTEnemyTurnStart
function NTEnemyTurnStart:Constructor(entity)
    self._enemyTeam = entity
end

function NTEnemyTurnStart:GetNotifyType()
    return NotifyType.EnemyTurnStart
end
function NTEnemyTurnStart:GetNotifyEntity()
    return self._enemyTeam
end
function NTEnemyTurnStart:NeedCheckGameTurn()
    return true
end
--敌方回合结束
_class("NTEnemyTurnEnd", INotifyBase)
NTEnemyTurnEnd = NTEnemyTurnEnd
function NTEnemyTurnEnd:Constructor(entity)
    self._enemyTeam = entity
end

function NTEnemyTurnEnd:GetNotifyType()
    return NotifyType.EnemyTurnEnd
end

function NTEnemyTurnEnd:GetNotifyEntity()
    return self._enemyTeam
end

function NTEnemyTurnEnd:NeedCheckGameTurn()
    return true
end

_class("NTMonsterBuffDamageEnd", INotifyBase)
NTMonsterBuffDamageEnd = NTMonsterBuffDamageEnd

function NTMonsterBuffDamageEnd:Constructor(attacker, defender)
    self._attacker = attacker
    self._defender = defender
end

function NTMonsterBuffDamageEnd:GetNotifyType()
    return NotifyType.MonsterBuffDamageEnd
end

function NTMonsterBuffDamageEnd:GetNotifyEntity()
    return self._defender
end
function NTMonsterBuffDamageEnd:NeedCheckGameTurn()
    return false
end
_class("NTBeforeEntityAddBuff", INotifyBase)
---@class NTBeforeEntityAddBuff : INotifyBase
NTBeforeEntityAddBuff = NTBeforeEntityAddBuff
function NTBeforeEntityAddBuff:Constructor(entity, buffId, buffEffectType)
    self._entity = entity
    self._buffId = buffId
    self._buffEffectType = buffEffectType
end
function NTBeforeEntityAddBuff:GetNotifyType()
    return NotifyType.BeforeEntityAddBuff
end
function NTBeforeEntityAddBuff:GetNotifyEntity()
    return self._entity
end
function NTBeforeEntityAddBuff:GetBuffId()
    return self._buffId
end
function NTBeforeEntityAddBuff:GetBuffEffectType()
    return self._buffEffectType
end

_class("NTTeamOrderChange", INotifyBase)
---@class NTTeamOrderChange : INotifyBase
NTTeamOrderChange = NTTeamOrderChange
function NTTeamOrderChange:Constructor(teamEntity,oldTeamOrder,newTeamOrder)
    self._teamEntity = teamEntity
    self._oldTeamOrder = oldTeamOrder
    self._newTeamOrder = newTeamOrder
end
function NTTeamOrderChange:GetNotifyType()
    return NotifyType.TeamOrderChange
end
function NTTeamOrderChange:GetNotifyEntity()
    return self._teamEntity
end

function NTTeamOrderChange:GetOldTeamOrder() return self._oldTeamOrder end
function NTTeamOrderChange:GetNewTeamOrder() return self._newTeamOrder end

--机关主动技后
_class("NTTrapActiveSkillEnd", INotifyBase)
---@class NTTrapActiveSkillEnd : INotifyBase
NTTrapActiveSkillEnd = NTTrapActiveSkillEnd
----@param trapEntity Entity
function NTTrapActiveSkillEnd:Constructor(trapEntity, skillID)
    self._trapEntity = trapEntity
    self._skillID = skillID
end

function NTTrapActiveSkillEnd:GetNotifyType()
    return NotifyType.TrapActiveSkillEnd
end

function NTTrapActiveSkillEnd:GetNotifyEntity()
    return self._trapEntity
end
function NTTrapActiveSkillEnd:GetSkillID()
    return self._skillID
end

--San值变化
_class("NTSanValueChange", INotifyBase)
---@class NTSanValueChange : INotifyBase
NTSanValueChange = NTSanValueChange

function NTSanValueChange:Constructor(curValue, oldValue,debtValue,modifyTimes)
    self._curValue = curValue
    self._oldValue = oldValue
    self._debtValue = debtValue--san降低时 到0后还欠多少san
    self._modifyTimes = modifyTimes--记录的san修改次数
end

function NTSanValueChange:GetNotifyType()
    return NotifyType.SanValueChange
end

function NTSanValueChange:GetCurValue()
    return self._curValue
end
function NTSanValueChange:GetOldValue()
    return self._oldValue
end
function NTSanValueChange:GetDebtValue()
    return self._debtValue
end
function NTSanValueChange:GetModifyTimes()
    return self._modifyTimes
end
--昼夜切换
_class("NTDayNightStateChange", INotifyBase)
---@class NTDayNightStateChange : INotifyBase
NTDayNightStateChange = NTDayNightStateChange

function NTDayNightStateChange:Constructor(curState, oldState)
    self._curState = curState
    self._oldState = oldState
end

function NTDayNightStateChange:GetNotifyType()
    return NotifyType.DayNightStateChange
end

function NTDayNightStateChange:GetCurState()
    return self._curState
end
function NTDayNightStateChange:GetOldState()
    return self._oldState
end

_class("NTRideStateChange", INotifyBase)
---@class NTRideStateChange : INotifyBase
NTRideStateChange = NTRideStateChange

function NTRideStateChange:Constructor(entity, isRide)
    self._entity = entity
    self._isRide = isRide
end

function NTRideStateChange:GetNotifyType()
    return NotifyType.RideStateChange
end

function NTRideStateChange:GetNotifyEntity()
    return self._entity
end

function NTRideStateChange:GetRideState()
    return self._isRide
end

_class("NTSaveRoundBeginPlayerPosEnd", INotifyBase)
---@class NTSaveRoundBeginPlayerPosEnd : INotifyBase
NTSaveRoundBeginPlayerPosEnd = NTSaveRoundBeginPlayerPosEnd
function NTSaveRoundBeginPlayerPosEnd:Constructor(teamEntity)
    self._teamEntity = teamEntity
end

function NTSaveRoundBeginPlayerPosEnd:GetNotifyEntity()
    return self._teamEntity
end

function NTSaveRoundBeginPlayerPosEnd:NeedCheckGameTurn()
    return true
end

function NTSaveRoundBeginPlayerPosEnd:GetNotifyType()
    return NotifyType.SaveRoundBeginPlayerPosEnd
end

_class("NTEffect156MoveOneGrid", INotifyBase)
---@class NTEffect156MoveOneGrid : INotifyBase
NTEffect156MoveOneGrid = NTEffect156MoveOneGrid

function NTEffect156MoveOneGrid:Constructor(entity,pos)
    self._entity = entity
    self._pos = pos
end

function NTEffect156MoveOneGrid:GetNotifyType()
    return NotifyType.Effect156MoveOneGrid
end

function NTEffect156MoveOneGrid:GetNotifyEntity()
    return self._entity
end
function NTEffect156MoveOneGrid:GetPos()
    return self._pos
end


_class("NTEffect156MoveFinish", INotifyBase)
---@class NTEffect156MoveFinish : INotifyBase
NTEffect156MoveFinish = NTEffect156MoveFinish

function NTEffect156MoveFinish:Constructor(entity)
    self._entity = entity
end

function NTEffect156MoveFinish:GetNotifyType()
    return NotifyType.Effect156MoveFinish
end

function NTEffect156MoveFinish:GetNotifyEntity()
    return self._entity
end

_class("NTEffect156MoveFinishBegin", INotifyBase)
---@class NTEffect156MoveFinishBegin : INotifyBase
NTEffect156MoveFinishBegin = NTEffect156MoveFinishBegin

function NTEffect156MoveFinishBegin:Constructor(entity,walkGridCount)
    self._entity = entity
    self._walkGridCount = walkGridCount
end

function NTEffect156MoveFinishBegin:GetNotifyType()
    return NotifyType.Effect156MoveFinishBegin
end

function NTEffect156MoveFinishBegin:GetNotifyEntity()
    return self._entity
end

function NTEffect156MoveFinishBegin:GetWalkGridCount()
    return self._walkGridCount
end


_class("NTEffect156MoveFinishEnd", INotifyBase)
---@class NTEffect156MoveFinishEnd : INotifyBase
NTEffect156MoveFinishEnd = NTEffect156MoveFinishEnd

function NTEffect156MoveFinishEnd:Constructor(entity)
    self._entity = entity
end

function NTEffect156MoveFinishEnd:GetNotifyType()
    return NotifyType.Effect156MoveFinishEnd
end

function NTEffect156MoveFinishEnd:GetNotifyEntity()
    return self._entity
end

_class("NTEffect156MoveOneGridBegin", INotifyBase)
---@class NTEffect156MoveOneGridBegin : INotifyBase
NTEffect156MoveOneGridBegin = NTEffect156MoveOneGridBegin

function NTEffect156MoveOneGridBegin:Constructor(entity)
    self._entity = entity
end

function NTEffect156MoveOneGridBegin:GetNotifyType()
    return NotifyType.Effect156MoveOneGridBegin
end

function NTEffect156MoveOneGridBegin:GetNotifyEntity()
    return self._entity
end


_class("NTEffect156MoveOneGridEnd", INotifyBase)
---@class NTEffect156MoveOneGridEnd : INotifyBase
NTEffect156MoveOneGridEnd = NTEffect156MoveOneGridEnd

function NTEffect156MoveOneGridEnd:Constructor(entity)
    self._entity = entity
end

function NTEffect156MoveOneGridEnd:GetNotifyType()
    return NotifyType.Effect156MoveOneGridEnd
end

function NTEffect156MoveOneGridEnd:GetNotifyEntity()
    return self._entity
end

_class("NTEffect158AttackBegin", INotifyBase)
---@class NTEffect158AttackBegin : INotifyBase
NTEffect158AttackBegin = NTEffect158AttackBegin

function NTEffect158AttackBegin:Constructor(entity)
    self._entity = entity
end

function NTEffect158AttackBegin:GetNotifyType()
    return NotifyType.Effect158AttackBegin
end

function NTEffect158AttackBegin:GetNotifyEntity()
    return self._entity
end

_class("NTEffect158AttackEnd", INotifyBase)
---@class NTEffect158AttackEnd : INotifyBase
NTEffect158AttackEnd = NTEffect158AttackEnd

function NTEffect158AttackEnd:Constructor(entity)
    self._entity = entity
end

function NTEffect158AttackEnd:GetNotifyType()
    return NotifyType.Effect158AttackEnd
end

function NTEffect158AttackEnd:GetNotifyEntity()
    return self._entity
end


_class("NTMinosAbsorbTrap", INotifyBase)
---@class NTMinosAbsorbTrap : INotifyBase
NTMinosAbsorbTrap = NTMinosAbsorbTrap

----@param e Entity
function NTMinosAbsorbTrap:Constructor(e)
    self._entity = e
end
function NTMinosAbsorbTrap:GetTrapID()
    ---@type TrapComponent
    local trapCmpt = self._entity:Trap()
    if not trapCmpt then
        return nil
    end

    local trapID = trapCmpt:GetTrapID()
    return trapID
end

function NTMinosAbsorbTrap:GetNotifyType()
    return NotifyType.MinosAbsorbTrap
end

function NTMinosAbsorbTrap:GetNotifyEntity()
    return self._entity
end

_class("NTSuperGridTriggerEnd", INotifyBase)
---@class NTSuperGridTriggerEnd:INotifyBase
---@field New function<NTSuperGridTriggerEnd>
NTSuperGridTriggerEnd = NTSuperGridTriggerEnd

function NTSuperGridTriggerEnd:Constructor(v2Pos)
    self._pos = v2Pos
end

function NTSuperGridTriggerEnd:GetTriggerPos()
    return self._pos
end

function NTSuperGridTriggerEnd:GetNotifyType()
    return NotifyType.SuperGridTriggerEnd
end

_class("NTPoorGridTriggerEnd", INotifyBase)
---@class NTPoorGridTriggerEnd:INotifyBase
---@field New function<NTPoorGridTriggerEnd>
NTPoorGridTriggerEnd = NTPoorGridTriggerEnd

function NTPoorGridTriggerEnd:Constructor(v2Pos)
    self._pos = v2Pos
end

function NTPoorGridTriggerEnd:GetTriggerPos()
    return self._pos
end

function NTPoorGridTriggerEnd:GetNotifyType()
    return NotifyType.PoorGridTriggerEnd
end

_class("NTSelectRoundTeamNormalBefore", INotifyBase)
---@class NTSelectRoundTeamNormalBefore:INotifyBase
NTSelectRoundTeamNormalBefore = NTSelectRoundTeamNormalBefore
function NTSelectRoundTeamNormalBefore:Constructor(elementType, chainPath)
    self._elementType = elementType
    self._chainPath = chainPath
end
function NTSelectRoundTeamNormalBefore:GetNotifyType()
    return NotifyType.SelectRoundTeamNormalBefore
end
function NTSelectRoundTeamNormalBefore:GetChainPathType()
    return self._elementType
end
function NTSelectRoundTeamNormalBefore:GetChainPath()
    return self._chainPath
end

_class("NTPetMinosAbsorbTrap", INotifyBase)
---@class NTPetMinosAbsorbTrap : INotifyBase
NTPetMinosAbsorbTrap = NTPetMinosAbsorbTrap

function NTPetMinosAbsorbTrap:Constructor(trapEntity, triggerEntity)
    self._trapEntity = trapEntity
    self._triggerEntity = triggerEntity
end
function NTPetMinosAbsorbTrap:GetTrapID()
    ---@type TrapComponent
    local trapCmpt = self._trapEntity:Trap()
    if not trapCmpt then
        return nil
    end

    local trapID = trapCmpt:GetTrapID()
    return trapID
end

function NTPetMinosAbsorbTrap:GetNotifyType()
    return NotifyType.PetMinosAbsorbTrap
end

function NTPetMinosAbsorbTrap:GetNotifyEntity()
    return self._trapEntity
end
function NTPetMinosAbsorbTrap:GetTriggerEntity()
    return self._triggerEntity
end
function NTPetMinosAbsorbTrap:GetNotifyPos()
    return self._trapEntity:GetGridPosition()
end
function NTPetMinosAbsorbTrap:GetPos()
    return self._trapEntity:GetGridPosition()
end

_class("NTCoffinMusumeSkillChangeLight", INotifyBase)
---@class NTCoffinMusumeSkillChangeLight : INotifyBase
NTCoffinMusumeSkillChangeLight = NTCoffinMusumeSkillChangeLight

function NTCoffinMusumeSkillChangeLight:Constructor(selectedLightID)
    self._selectedLightID = selectedLightID
end

function NTCoffinMusumeSkillChangeLight:GetSelectLightID()
    return self._selectedLightID
end

function NTCoffinMusumeSkillChangeLight:GetNotifyType()
    return NotifyType.CoffinMusumeSkillChangeLight
end

_class("NTCoffinMusumeLightChanged", INotifyBase)
---@class NTCoffinMusumeLightChanged : INotifyBase
NTCoffinMusumeLightChanged = NTCoffinMusumeLightChanged

function NTCoffinMusumeLightChanged:GetNotifyType()
    return NotifyType.CoffinMusumeLightChanged
end



_class("NTExChangeGridColor", INotifyBase)
---@class NTExChangeGridColor : INotifyBase
NTExChangeGridColor = NTExChangeGridColor

function NTExChangeGridColor:Constructor(gridPosList)
    self._gridPosList = gridPosList
end

function NTExChangeGridColor:GetConvertInfoAt(pos)
    for gridPos, gridType in pairs(self._gridPosList) do
        if gridPos.x == pos.x and gridPos.y == pos.y then
            return true
        end
    end
    return false
end

function NTExChangeGridColor:GetNotifyType()
    return NotifyType.ExChangeGridColor
end

_class("NTPet1601781SkillHolderBase", INotifyBase)
---@class NTPet1601781SkillHolderBase : INotifyBase
NTPet1601781SkillHolderBase = NTPet1601781SkillHolderBase

function NTPet1601781SkillHolderBase:GetNotifyType()
    return self.__NotifyType
end

function NTPet1601781SkillHolderBase:Constructor(skillType, casterPos, multiCastCount)
    self._triggerSkillType = skillType
    self._casterPos = casterPos
    self._multiCastCount = multiCastCount
end

function NTPet1601781SkillHolderBase:GetSkillType()
    return self._triggerSkillType
end

function NTPet1601781SkillHolderBase:GetCasterPos()
    return self._casterPos
end

---@return number|nil Count of chain skill multi-casting(**nullable** if not chain skill) [copying from @SkillEffectResult_WeikeNotify]
function NTPet1601781SkillHolderBase:GetMultiCastCount()
    return self._multiCastCount
end

_class("NTPet1601781SkillHolder1", NTPet1601781SkillHolderBase)
---@class NTPet1601781SkillHolder1 : NTPet1601781SkillHolderBase
NTPet1601781SkillHolder1 = NTPet1601781SkillHolder1

NTPet1601781SkillHolder1.__NotifyType = NotifyType.Pet1601781SkillHolder1

_class("NTPet1601781SkillHolder2", NTPet1601781SkillHolderBase)
---@class NTPet1601781SkillHolder2 : NTPet1601781SkillHolderBase
NTPet1601781SkillHolder2 = NTPet1601781SkillHolder2

NTPet1601781SkillHolder2.__NotifyType = NotifyType.Pet1601781SkillHolder2

_class("NTPet1601781SkillHolder3", NTPet1601781SkillHolderBase)
---@class NTPet1601781SkillHolder3 : NTPet1601781SkillHolderBase
NTPet1601781SkillHolder3 = NTPet1601781SkillHolder3

NTPet1601781SkillHolder3.__NotifyType = NotifyType.Pet1601781SkillHolder3

--只用于189的每次普攻结束后，通知镇魂座加Buff层数，无攻击数据，故不继承NotifyAttackBase
_class("NTSE189NormalEachAttackEnd", INotifyBase)
---@class NTSE189NormalEachAttackEnd : INotifyBase
NTSE189NormalEachAttackEnd = NTSE189NormalEachAttackEnd

function NTSE189NormalEachAttackEnd:Constructor(entity)
    self._entity = entity
end

function NTSE189NormalEachAttackEnd:GetNotifyType()
    return NotifyType.SE189NormalEachAttackEnd
end

function NTSE189NormalEachAttackEnd:GetNotifyEntity()
    return self._entity
end

_class("NTBenumbed", INotifyBase)
---@class NTBenumbed : INotifyBase
NTBenumbed = NTBenumbed

function NTBenumbed:Constructor(entity)
    self._entity = entity
end

function NTBenumbed:GetNotifyType()
    return NotifyType.Benumbed
end

function NTBenumbed:GetNotifyEntity()
    return self._entity
end


_class("NTCovCrystalPrism", INotifyBase)
---@class NTCovCrystalPrism : INotifyBase
NTCovCrystalPrism = NTCovCrystalPrism

function NTCovCrystalPrism:Constructor(tTargetPieces)
    self.tTargetPieces = tTargetPieces
    self._convertPosInfoMap = {}
    if tTargetPieces then
        for _, data in ipairs(tTargetPieces) do
            local pos =data.pos
            local x = pos.x
            local y = pos.y
            if not self._convertPosInfoMap[x] then
                self._convertPosInfoMap[x] = {}
            end
            self._convertPosInfoMap[x][y] = data.pieceType
        end
    end
end

function NTCovCrystalPrism:GetNotifyType()
    return NotifyType.CovCrystalPrism
end

---@return PieceType
function NTCovCrystalPrism:GetConvertInfoAt(pos)
    return self._convertPosInfoMap[pos.x] and self._convertPosInfoMap[pos.x][pos.y] or nil
end

---@class NTEquipRefineUIStateChange : INotifyBase
_class("NTEquipRefineUIStateChange", INotifyBase)
NTEquipRefineUIStateChange = NTEquipRefineUIStateChange

function NTEquipRefineUIStateChange:Constructor(entity, state)
    self._entity = entity
    self._state = state
end

function NTEquipRefineUIStateChange:GetNotifyType()
    return NotifyType.EquipRefineUIStateChange
end

function NTEquipRefineUIStateChange:GetNotifyEntity()
    return self._entity
end

function NTEquipRefineUIStateChange:GetRefineUIState()
    return self._state
end

---@class NTAddControlBuffEnd : INotifyBase
_class("NTAddControlBuffEnd", INotifyBase)
NTAddControlBuffEnd = NTAddControlBuffEnd

function NTAddControlBuffEnd:Constructor(entity, buffSeq, buffID, buffEffType)
    self._entity = entity
    self._buffSeq = buffSeq
    self._buffID = buffID
    self._buffEffType = buffEffType
end

function NTAddControlBuffEnd:GetNotifyType()
    return NotifyType.AddControlBuffEnd
end

function NTAddControlBuffEnd:GetNotifyEntity()
    return self._entity
end

function NTAddControlBuffEnd:GetBuffSeq()
    return self._buffSeq
end

function NTAddControlBuffEnd:GetBuffID()
    return self._buffID
end

function NTAddControlBuffEnd:GetBuffEffectType()
    return self._buffEffType
end

function NTAddControlBuffEnd:NeedCheckGameTurn()
    return true
end

--主动技能 对自己造成伤害后（技能效果85）
_class("NTActiveSkillCostCasterHPEnd", INotifyBase)
---@class NTActiveSkillCostCasterHPEnd : INotifyBase
NTActiveSkillCostCasterHPEnd = NTActiveSkillCostCasterHPEnd
----@param attacker Entity
function NTActiveSkillCostCasterHPEnd:Constructor(attacker, damage)
    self._attacker = attacker
    self._damage = damage
end

function NTActiveSkillCostCasterHPEnd:GetNotifyType()
    return NotifyType.ActiveSkillCostCasterHPEnd
end

function NTActiveSkillCostCasterHPEnd:GetNotifyEntity()
    return self._attacker
end

function NTActiveSkillCostCasterHPEnd:GetDamage()
    return self._damage
end

function NTActiveSkillCostCasterHPEnd:NeedCheckGameTurn()
    return true
end

--region SpliceBoard
_class("NTSpliceBoardBegin", INotifyBase)
---@class NTSpliceBoardBegin : INotifyBase
NTSpliceBoardBegin = NTSpliceBoardBegin
----@param attacker Entity
function NTSpliceBoardBegin:Constructor(trapEntity)
    self._trapEntity = trapEntity
end

function NTSpliceBoardBegin:GetNotifyType()
    return NotifyType.SpliceBoardBegin
end

function NTSpliceBoardBegin:GetNotifyEntity()
    return self._trapEntity
end

_class("NTSpliceBoardEnd", INotifyBase)
---@class NTSpliceBoardEnd : INotifyBase
NTSpliceBoardEnd = NTSpliceBoardEnd
----@param attacker Entity
function NTSpliceBoardEnd:Constructor(trapEntity)
    self._trapEntity = trapEntity
end

function NTSpliceBoardEnd:GetNotifyType()
    return NotifyType.SpliceBoardEnd
end

function NTSpliceBoardEnd:GetNotifyEntity()
    return self._trapEntity
end
--endregion SpliceBoard


_class("NTTrapShowEnd", INotifyBase)
---@class NTTrapShowEnd : INotifyBase
NTTrapShowEnd = NTTrapShowEnd

----@param e Entity
function NTTrapShowEnd:Constructor(e, summoner,pos,bodyArea)
    self._entity = e
    self._summoner = summoner
    self._isFirstSummon = false
    self._pos = pos
    self._bodyArea = bodyArea
end

function NTTrapShowEnd:GetNotifyBodyArea()
    return self._bodyArea
end

function NTTrapShowEnd:GetNotifyPos()
    return self._pos
end

function NTTrapShowEnd:GetNotifyType()
    return NotifyType.TrapShowEnd
end

function NTTrapShowEnd:GetNotifyEntity()
    return self._entity
end

function NTTrapShowEnd:SetIsFirstSummon(b)
    self._isFirstSummon = b
end

function NTTrapShowEnd:IsFirstSummon()
    return self._isFirstSummon
end

function NTTrapShowEnd:GetOwnerEntity()
    return self._summoner
end

---@class NTPopStarScoreChange : INotifyBase
_class("NTPopStarScoreChange", INotifyBase)
NTPopStarScoreChange = NTPopStarScoreChange

function NTPopStarScoreChange:Constructor()
end

function NTPopStarScoreChange:GetNotifyType()
    return NotifyType.PopStarScoreChange
end

---@class NTPopStarEnd : INotifyBase
_class("NTPopStarEnd", INotifyBase)
NTPopStarEnd = NTPopStarEnd

function NTPopStarEnd:Constructor(popNum)
    self._popNum = popNum
end

function NTPopStarEnd:GetNotifyType()
    return NotifyType.PopStarEnd
end

function NTPopStarEnd:GetPopNum()
    return self._popNum
end

_class("NTMoveTrap", INotifyBase)
---@class NTMoveTrap : INotifyBase
NTMoveTrap = NTMoveTrap

----@param e Entity
function NTMoveTrap:Constructor(e, summoner,pos,bodyArea)
    self._entity = e
    self._summoner = summoner
    self._pos = pos
    self._bodyArea = bodyArea
end

function NTMoveTrap:GetNotifyBodyArea()
    return self._bodyArea
end

function NTMoveTrap:GetNotifyPos()
    return self._pos
end

function NTMoveTrap:GetNotifyType()
    return NotifyType.MoveTrap
end

function NTMoveTrap:GetNotifyEntity()
    return self._entity
end

function NTMoveTrap:IsFirstSummon()
    return false
end

function NTMoveTrap:GetOwnerEntity()
    return self._summoner
end

---@class NTRoleTurnResultState : INotifyBase
_class("NTRoleTurnResultState", INotifyBase)
NTRoleTurnResultState = NTRoleTurnResultState

function NTRoleTurnResultState:Constructor()
end
function NTRoleTurnResultState:GetNotifyType()
    return NotifyType.RoleTurnResultState
end

_class("NTMonsterRoundBeforeTrapRoundCount", INotifyBase)
NTMonsterRoundBeforeTrapRoundCount = NTMonsterRoundBeforeTrapRoundCount
function NTMonsterRoundBeforeTrapRoundCount:GetNotifyType()
    return NotifyType.MonsterRoundBeforeTrapRoundCount
end
