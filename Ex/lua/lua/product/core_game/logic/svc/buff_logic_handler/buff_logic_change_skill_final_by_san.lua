--[[
    增加技能伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillFinalBySan", BuffLogicBase)
---@class BuffLogicChangeSkillFinalBySan:BuffLogicBase
BuffLogicChangeSkillFinalBySan = BuffLogicChangeSkillFinalBySan
---
function BuffLogicChangeSkillFinalBySan:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._baseSan = logicParam.baseSan or 100 --以这个san值为基础计算

    self._minValue = logicParam.minValue --最小值，不写不判断
    self._maxValue = logicParam.maxValue --最大值，不写不判断

    ---影响的技能类型 列表
    self._buffInstance._effectList = logicParam.effectList
end
---
function BuffLogicChangeSkillFinalBySan:DoLogic()
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if not featureLogicSvc then
        return
    end

    if not featureLogicSvc:HasFeatureType(FeatureType.Sanity) then
        return
    end

    local curSanValue = featureLogicSvc:GetSanValue()
    local entity = self._buffInstance:Entity()

    local changeSan = curSanValue - self._baseSan
    local newChangeValue = changeSan * self._mulValue

    if self._minValue then
        newChangeValue = math.max(newChangeValue, self._minValue)
    end
    if self._maxValue then
        newChangeValue = math.min(newChangeValue, self._maxValue)
    end

    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:ChangeSkillFinalParam(entity, self:GetBuffSeq(), paramType, newChangeValue)
    end
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillFinalBySan", BuffLogicBase)
BuffLogicRemoveSkillFinalBySan = BuffLogicRemoveSkillFinalBySan
---
function BuffLogicRemoveSkillFinalBySan:Constructor(buffInstance, logicParam)
end
---
function BuffLogicRemoveSkillFinalBySan:DoLogic()
    local entity = self._buffInstance:Entity()
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillFinalParam(entity, self:GetBuffSeq(), paramType)
    end
end
