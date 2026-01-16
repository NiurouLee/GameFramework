--[[
    增加技能伤害 （增加的百分比为当前已损失生命值的百分比）
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillIncreaseWithHpPercent", BuffLogicBase)
---@class BuffLogicChangeSkillIncreaseWithHpPercent:BuffLogicBase
BuffLogicChangeSkillIncreaseWithHpPercent = BuffLogicChangeSkillIncreaseWithHpPercent

function BuffLogicChangeSkillIncreaseWithHpPercent:Constructor(buffInstance, logicParam)
    self._changeValue = logicParam.changeValue or 0
    ---影响的技能类型 列表
    self._buffInstance._effectList = logicParam.effectList
    self._entity = buffInstance._entity
end

function BuffLogicChangeSkillIncreaseWithHpPercent:DoLogic()
    local e = self._buffInstance:Entity()
    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()
    
    local cur_hp = e:Attributes():GetCurrentHP()
    local losePercent = 1 - (cur_hp / max_hp)
    local changeValue = 0
    if losePercent ~= 0 then
        changeValue = changeValue + (losePercent * self._changeValue)
    end

    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(self._entity, self._buffInstance._buffSeq, paramType)

        if changeValue ~= 0 then
            self._buffLogicService:ChangeSkillIncrease(
                self._entity,
                self._buffInstance._buffSeq,
                paramType,
                changeValue
            )
        end
    end
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillIncreaseWithHpPercent", BuffLogicBase)
BuffLogicRemoveSkillIncreaseWithHpPercent = BuffLogicRemoveSkillIncreaseWithHpPercent

function BuffLogicRemoveSkillIncreaseWithHpPercent:Constructor(buffInstance, logicParam)
    self._entity = buffInstance._entity
end

function BuffLogicRemoveSkillIncreaseWithHpPercent:DoLogic()
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(self._entity, self._buffInstance:BuffSeq(), paramType)
    end
end
