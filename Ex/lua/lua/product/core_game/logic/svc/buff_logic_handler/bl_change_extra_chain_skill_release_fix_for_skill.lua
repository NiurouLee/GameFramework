require("buff_logic_base")

local buffValueKey = "ChangeExtraChainSkillReleaseFixForSkill"

_class("BuffLogicChangeExtraChainSkillReleaseFixForSkill", BuffLogicBase)
---@class BuffLogicChangeExtraChainSkillReleaseFixForSkill : BuffLogicBase
BuffLogicChangeExtraChainSkillReleaseFixForSkill = BuffLogicChangeExtraChainSkillReleaseFixForSkill

function BuffLogicChangeExtraChainSkillReleaseFixForSkill:Constructor(buffInstance, logicParam)
    self._skillID = logicParam.skillID
    self._fixVal = logicParam.val
end

function BuffLogicChangeExtraChainSkillReleaseFixForSkill:DoLogic(notify)
    --写入BuffValue的数据是没有历史记录的，只能彻底清空，不可以单步revert
    --在做这个功能之前已经告知策划了
    local cBuff = self._entity:BuffComponent()
    local nul = cBuff:GetBuffValue(buffValueKey) or cBuff:SetBuffValue(buffValueKey, {})
    local data = cBuff:GetBuffValue(buffValueKey)
    if data[self._skillID] then
        data[self._skillID] = data[self._skillID] + self._fixVal
    else
        data[self._skillID] = self._fixVal
    end

    return {currentExtraFix = data[self._skillID]}
end

function BuffLogicChangeExtraChainSkillReleaseFixForSkill:DoOverlap(logicParam, context)
    return self:DoLogic()
end

_class("BuffLogicRemoveChangeExtraChainSkillReleaseFixForSkill", BuffLogicBase)
---@class BuffLogicRemoveChangeExtraChainSkillReleaseFixForSkill : BuffLogicBase
BuffLogicRemoveChangeExtraChainSkillReleaseFixForSkill = BuffLogicRemoveChangeExtraChainSkillReleaseFixForSkill

function BuffLogicRemoveChangeExtraChainSkillReleaseFixForSkill:Constructor(buffInstance, logicParam)
    self._skillID = logicParam.skillID
end

function BuffLogicRemoveChangeExtraChainSkillReleaseFixForSkill:DoLogic(notify)
    --写入BuffValue的数据是没有历史记录的，只能彻底清空，不可以单步revert
    --在做这个功能之前已经告知策划了
    local cBuff = self._entity:BuffComponent()
    local data = cBuff:GetBuffValue(buffValueKey)
    if not data then
        return
    end

    if not (data[self._skillID]) then
        return
    end

    data[self._skillID] = nil
end
