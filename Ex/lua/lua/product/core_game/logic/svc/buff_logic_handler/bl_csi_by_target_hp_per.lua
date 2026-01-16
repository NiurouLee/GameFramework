--[[
    增加技能伤害 （增加的百分比为目标当前已损失生命值的百分比）
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillIncreaseByTargetHPPercent", BuffLogicBase)
---@class BuffLogicChangeSkillIncreaseByTargetHPPercent:BuffLogicBase
BuffLogicChangeSkillIncreaseByTargetHPPercent = BuffLogicChangeSkillIncreaseByTargetHPPercent

function BuffLogicChangeSkillIncreaseByTargetHPPercent:Constructor(buffInstance, logicParam)
    self._changeValue = logicParam.changeValue or 0
    ---影响的技能类型 列表
    self._buffInstance._effectList = logicParam.effectList
    self._maxHpPercent = logicParam.maxHpPercent
    self._entity = buffInstance._entity

    self._targetIsTeam = logicParam.targetIsTeam or 0
end

function BuffLogicChangeSkillIncreaseByTargetHPPercent:DoLogic(notify)
    if not notify.GetDefenderEntity then
        return
    end

    local e = notify:GetDefenderEntity()
    if self._targetIsTeam == 1 then 
        ---@type Entity
        e = self._world:Player():GetCurrentTeamEntity()
    end

    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()

    local cur_hp = e:Attributes():GetCurrentHP()
    local losePercent = 1 - (cur_hp / max_hp)
    local changeValue = 0
    if losePercent ~= 0 then
        if self._maxHpPercent then--最大值限制
            if losePercent > self._maxHpPercent then
                losePercent = self._maxHpPercent
            end
        end
        changeValue = losePercent * self._changeValue
    end

    for _, paramType in ipairs(self._buffInstance._effectList) do
        --self._buffLogicService:RemoveSkillIncrease(self._entity, self._buffInstance._buffSeq, paramType)

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
_class("BuffLogicRemoveSkillIncreaseByTargetHPPercent", BuffLogicBase)
BuffLogicRemoveSkillIncreaseByTargetHPPercent = BuffLogicRemoveSkillIncreaseByTargetHPPercent

function BuffLogicRemoveSkillIncreaseByTargetHPPercent:Constructor(buffInstance, logicParam)
    self._entity = buffInstance._entity
end

function BuffLogicRemoveSkillIncreaseByTargetHPPercent:DoLogic()
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(self._entity, self._buffInstance:BuffSeq(), paramType)
    end
end
