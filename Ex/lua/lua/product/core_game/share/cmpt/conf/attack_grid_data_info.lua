--[[------------------------------------------------------------------------------------------
    AttackGridData : 格子任务数据
]] --------------------------------------------------------------------------------------------
require("skill_effect_result_container")

_class("AttackGridData", SkillEffectResultContainer)
---@class AttackGridData: SkillEffectResultContainer
AttackGridData = AttackGridData

function AttackGridData:Constructor(targetid, damagevalue, pos, skillId)
    self._targetIdArray = {}
    self._damageValueArray = {}
    self._gridPosArray = {}
    self._gridSkillId = skillId
    self:AddTargetId(targetid)
    self:AddDamageValue(targetid, damagevalue)
    self:AddAttackPos(pos)
    --治疗
    -- self:AddBloodValue()
end

function AttackGridData:AddTargetId(targetId)
    if targetId ~= nil and targetId > 0 then
        self._targetIdArray[#self._targetIdArray + 1] = targetId
    end
end

function AttackGridData:AddDamageValue(targetId, damage)
    if damage ~= nil then
        self._damageValueArray[targetId] = damage
    end
end

function AttackGridData:AddAttackPos(pos)
    if pos ~= nil then
        self._gridPosArray[#self._gridPosArray + 1] = pos
    end
end

--治疗量
function AttackGridData:AddBloodValue(targetId, bloodValue)
    if bloodValue ~= nil then
        self._bloodValueArray[targetId] = bloodValue
    end
end

function AttackGridData:GetTargetIdList()
    return self._targetIdArray
end

function AttackGridData:SetTargetIdList(targetIdArray)
    self._targetIdArray = targetIdArray
end

function AttackGridData:ClearTargetIdList()
    self._targetIdArray = {}
end

function AttackGridData:GetDamageList()
    return self._damageValueArray
end

function AttackGridData:GetAttackPosList()
    return self._gridPosArray
end

function AttackGridData:SetAttackPosList(gridPosArray)
    self._gridPosArray = gridPosArray
end

function AttackGridData:ClearAttackPosList()
    self._gridPosArray = {}
end

function AttackGridData:GetAttackGridSkillId()
    return self._gridSkillId
end

function AttackGridData:SetAttackGridSkillID(skillID)
    self._gridSkillId = skillID
end

--治疗量
function AttackGridData:GetBloodList()
    return self._bloodValueArray
end

----------------------------------------------------------------
---策划自动测试统计信息使用
---@class CH_AttackData : Object
_class("CH_AttackData", Object)
CH_AttackData = CH_AttackData

function CH_AttackData:Constructor(nSkillID, nTargetID, posAttack, nDamageValue)
    self.m_nSkillID = nSkillID
    self.m_nTargetID = nTargetID or 0
    self.m_posAttack = posAttack or Vector2.New(0, 0)
    self.m_nDamageValue = nDamageValue or 0
end
----------------------------------------------------------------
