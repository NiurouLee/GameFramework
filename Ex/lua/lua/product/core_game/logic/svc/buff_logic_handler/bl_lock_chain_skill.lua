_class("BuffLogicLockChainSkill", BuffLogicBase)
---@class BuffLogicLockChainSkill: BuffLogicBase
BuffLogicLockChainSkill = BuffLogicLockChainSkill

function BuffLogicLockChainSkill:Constructor(buffInstance, logicParam)
    self._lockIndex = tonumber(logicParam.index)
end

function BuffLogicLockChainSkill:DoLogic()
    local e = self:GetEntity()
    if not e:HasSkillInfo() then
        return
    end

    local cSkillInfo = e:SkillInfo()
    cSkillInfo:LockChainSkillIndex(self._lockIndex)

    return {index = self._lockIndex}
end

_class("BuffLogicUnlockChainSkill", BuffLogicBase)
---@class BuffLogicUnlockChainSkill: BuffLogicBase
BuffLogicUnlockChainSkill = BuffLogicUnlockChainSkill

function BuffLogicUnlockChainSkill:Constructor(buffInstance, logicParam)
    self._unlockIndex = tonumber(logicParam.index)

    if not self._unlockIndex then
        self._unlockAll = true
    end
end

function BuffLogicUnlockChainSkill:DoLogic()
    local e = self:GetEntity()
    if not e:HasSkillInfo() then
        return
    end

    local cSkillInfo = e:SkillInfo()
    if self._unlockAll then
        cSkillInfo:UnlockAllChainSkill()
    else
        cSkillInfo:UnlockChainSkillIndex(self._unlockIndex)
    end

    return {index = self._unlockIndex, isAll = self._unlockAll}
end
