--[[
    增加技能伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillIncrease", BuffLogicBase)
---@class BuffLogicChangeSkillIncrease:BuffLogicBase
BuffLogicChangeSkillIncrease = BuffLogicChangeSkillIncrease

function BuffLogicChangeSkillIncrease:Constructor(buffInstance, logicParam)
    self._changeValue = logicParam.changeValue or 0
    ---影响的技能类型 列表
    self._buffInstance._effectList = logicParam.effectList
    self._layer = logicParam.layer or 0
    ---@type Entity
    self._entity = buffInstance._entity
    self._light = logicParam.light
    self._buffInstance.BuffLogicChangeSkillIncrease_RunCount = 0
end

function BuffLogicChangeSkillIncrease:DoLogic()
    self._buffInstance.BuffLogicChangeSkillIncrease_RunCount = self._buffInstance.BuffLogicChangeSkillIncrease_RunCount + 1
    --没有层数直接添加
    if self._layer > 0 then
        --有层数设定的 先给自己加层  修改以前注册的数值
        self._buffInstance:AddLayerCount(self._layer)
    end
    local newChangeValue = self._buffInstance.BuffLogicChangeSkillIncrease_RunCount * self._changeValue

    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:ChangeSkillIncrease(self._entity, self:GetBuffSeq(), paramType, newChangeValue)
    end

    if not self._light then
        return
    end

    local ret = BuffResultChangeSkillIncrease:New(self._light)
    return ret
end

function BuffLogicChangeSkillIncrease:DoOverlap()
    return self:DoLogic()
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillIncrease", BuffLogicBase)
BuffLogicRemoveSkillIncrease = BuffLogicRemoveSkillIncrease

function BuffLogicRemoveSkillIncrease:Constructor(buffInstance, logicParam)
    self._entity = buffInstance._entity
    self._black = (logicParam.black ~= nil)
end

function BuffLogicRemoveSkillIncrease:DoLogic()
    self._buffInstance.BuffLogicChangeSkillIncrease_RunCount = 0
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(self._entity, self:GetBuffSeq(), paramType)
    end
    if not self._black then
        return
    end
    local ret = BuffResultRemoveSkillIncrease:New(self._black)
    return ret
end

function BuffLogicRemoveSkillIncrease:DoOverlap()
end