--[[
    addbuff结果
]]
_class("BuffResultAddBuff", BuffResultBase)
BuffResultAddBuff = BuffResultAddBuff

function BuffResultAddBuff:Constructor()
    self._buffArray = {}
end

function BuffResultAddBuff:AddBuffData(eid, buffseq)
    --Log.debug("AddBuffResult entityid=",eid, "buffseq=",buffseq)
    table.insert(self._buffArray, {eid, buffseq})
end

function BuffResultAddBuff:GetBuffArray()
    return self._buffArray
end

function BuffResultAddBuff:SetLight(v)
    self._light = v
end

function BuffResultAddBuff:GetLight()
    return self._light
end

function BuffResultAddBuff:SetAttackPos(pos)
    self._atkPos = pos
end

function BuffResultAddBuff:GetAttackPos()
    return self._atkPos
end

function BuffResultAddBuff:SetTargetPos(pos)
    self._tarPos = pos
end

function BuffResultAddBuff:GetTargetPos()
    return self._tarPos
end
--SkillEffectCalcRandDamageSameHalf 可能对单个敌人造成多次伤害 处理buffview
function BuffResultAddBuff:SetRandHalfDamageIndex(val)
    self._randHalfDamageIndex = val
end

function BuffResultAddBuff:GetRandHalfDamageIndex()
    return self._randHalfDamageIndex
end

function BuffResultAddBuff:GetWalkPos()
    return self._walkPos
end

function BuffResultAddBuff:SetWalkPos(walkPos)
    self._walkPos = walkPos
end

function BuffResultAddBuff:SetNotifyLayerChange_Entity(e)
    self._setNotifyLayerChange_entity = e
end

function BuffResultAddBuff:SetNotifyLayerChange_TotalLayer(n)
    self._setNotifyLayerChange_totalLayer = n
end

function BuffResultAddBuff:GetNotifyLayerChange_Entity()
    return self._setNotifyLayerChange_entity
end

function BuffResultAddBuff:GetNotifyLayerChange_TotalLayer()
    return self._setNotifyLayerChange_totalLayer
end
