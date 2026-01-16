--[[
    根绝目标数量增加技能伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillIncreaseByTargetCount", BuffLogicBase)
---@class BuffLogicChangeSkillIncreaseByTargetCount:BuffLogicBase
BuffLogicChangeSkillIncreaseByTargetCount = BuffLogicChangeSkillIncreaseByTargetCount

function BuffLogicChangeSkillIncreaseByTargetCount:Constructor(buffInstance, logicParam)
    self._buffInstance._effectList = logicParam.effectList
    self._rates = logicParam.rates or {}
end

function BuffLogicChangeSkillIncreaseByTargetCount:DoLogic(notify)
    local targetCount = notify:GetTargetCount()
    if targetCount == 0 then
        return
    end

    --获取增加的数值
    local changeValue = self._rates[targetCount]
    if not changeValue then
        changeValue = self._rates[table.count(self._rates)]
    end

    local casterEntity = self._entity

    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:ChangeSkillIncrease(casterEntity, self:GetBuffSeq(), paramType, changeValue)
    end
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillIncreaseByTargetCount", BuffLogicBase)
---@class BuffLogicRemoveSkillIncreaseByTargetCount:BuffLogicBase
BuffLogicRemoveSkillIncreaseByTargetCount = BuffLogicRemoveSkillIncreaseByTargetCount

function BuffLogicRemoveSkillIncreaseByTargetCount:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSkillIncreaseByTargetCount:DoLogic()
    local casterEntity = self._entity
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(casterEntity, self:GetBuffSeq(), paramType)
    end
end
