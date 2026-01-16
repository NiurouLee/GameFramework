_class("BuffResultRemoveBuff", BuffResultBase)
---@class BuffResultRemoveBuff : BuffResultBase
BuffResultRemoveBuff = BuffResultRemoveBuff

function BuffResultRemoveBuff:Constructor()
    self._removedInfo = {}
end

function BuffResultRemoveBuff:AddRemovedInfo(eid, tSeqID)
    table.insert(
        self._removedInfo,
        {
            eid = eid,
            tSeqID = tSeqID
        }
    )
end

function BuffResultRemoveBuff:GetBuffArray()
    return self._removedInfo
end
--SkillEffectCalcRandDamageSameHalf 可能对单个敌人造成多次伤害 处理buffview
function BuffResultRemoveBuff:SetRandHalfDamageIndex(val)
    self._randHalfDamageIndex = val
end

function BuffResultRemoveBuff:GetRandHalfDamageIndex()
    return self._randHalfDamageIndex
end

function BuffResultRemoveBuff:GetWalkPos()
    return self._walkPos
end

function BuffResultRemoveBuff:SetWalkPos(walkPos)
    self._walkPos = walkPos
end

function BuffResultRemoveBuff:SetBlack(black)
    self._black = black
end

function BuffResultRemoveBuff:GetBlack()
    return self._black
end

function BuffResultRemoveBuff:SetNotifyEntityID(id)
    self._notifyEntityID = id
end

function BuffResultRemoveBuff:GetNotifyEntityID()
    return self._notifyEntityID
end

function BuffResultRemoveBuff:SetNotifyChainSkillId(v)
    self._notifyChainSkillId = v
end

function BuffResultRemoveBuff:GetNotifyChainSkillId()
    return self._notifyChainSkillId
end

function BuffResultRemoveBuff:SetNotifyChainSkillIndex(v)
    self._notifyChainSkillIndex = v
end

function BuffResultRemoveBuff:GetNotifyChainSkillIndex()
    return self._notifyChainSkillIndex
end
