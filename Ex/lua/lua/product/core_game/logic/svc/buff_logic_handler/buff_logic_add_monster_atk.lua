--[[
    怪物加攻击
]]

---@class BuffLogicAddMonsterAtk:BuffLogicBase 百分比加攻击力
_class("BuffLogicAddMonsterAtk", BuffLogicBase)
BuffLogicAddMonsterAtk = BuffLogicAddMonsterAtk

---@param  buffInstance BuffInstance
---@param logicParam BuffEffectAddAtkByRoundParam
function BuffLogicAddMonsterAtk:Constructor(buffInstance, logicParam)
    self._atkPercent = logicParam.addValue
    self._entity = buffInstance._entity
    ---@type BuffLogicService
    self._buffLogicSvc = buffInstance._world:GetService("BuffLogic")
    self._buffSeq = buffInstance._buffSeq
end

function BuffLogicAddMonsterAtk:DoLogic()
    self._buffLogicSvc:ChangeSkillIncrease(
        self._entity,
        self._buffSeq,
        ModifySkillIncreaseParamType.MonsterDamage,
        self._atkPercent
    )
end
