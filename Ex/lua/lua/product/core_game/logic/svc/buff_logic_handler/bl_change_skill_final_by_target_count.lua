--[[
    根绝目标数量增加技能伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillFinalByTargetCount", BuffLogicBase)
---@class BuffLogicChangeSkillFinalByTargetCount:BuffLogicBase
BuffLogicChangeSkillFinalByTargetCount = BuffLogicChangeSkillFinalByTargetCount

function BuffLogicChangeSkillFinalByTargetCount:Constructor(buffInstance, logicParam)
    self._buffInstance._effectList = logicParam.effectList
    self._rates = logicParam.rates or {}
end

function BuffLogicChangeSkillFinalByTargetCount:DoLogic(notify)
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
        self._buffLogicService:ChangeSkillFinalParam(casterEntity, self:GetBuffSeq(), paramType, changeValue)
    end
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillFinalByTargetCount", BuffLogicBase)
---@class BuffLogicRemoveSkillFinalByTargetCount:BuffLogicBase
BuffLogicRemoveSkillFinalByTargetCount = BuffLogicRemoveSkillFinalByTargetCount

function BuffLogicRemoveSkillFinalByTargetCount:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSkillFinalByTargetCount:DoLogic()
    local casterEntity = self._entity
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillFinalParam(casterEntity, self:GetBuffSeq(), paramType)
    end
end
