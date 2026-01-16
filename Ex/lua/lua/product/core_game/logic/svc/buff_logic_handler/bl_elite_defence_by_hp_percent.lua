--[[
    精英化怪物：受伤增防

    使用指定公式，根据生命值百分比增加防御。重复执行将重新计算。
    公式：def = monster.def * argument[配置常量] * (2 - (HP / MAXHP))

    注意：我们没有实时动态的buff重新计算流程，因此该buff的时间
]]

---@class BuffLogicChangeEliteDefenceByHPPercent : BuffLogicBase
_class("BuffLogicChangeEliteDefenceByHPPercent", BuffLogicBase)
BuffLogicChangeEliteDefenceByHPPercent = BuffLogicChangeEliteDefenceByHPPercent

function BuffLogicChangeEliteDefenceByHPPercent:Constructor(_buffIns, logicParam)
    self._defArgument = tonumber(logicParam.defArgument)
    self._hpPercentFix = tonumber(logicParam.hpPercentFix)
    assert(self._defArgument, "ChangeEliteDefenceByHPPercent: parameter[defArgument] is required. ")
    assert(self._hpPercentFix, "ChangeEliteDefenceByHPPercent: parameter[hpPercentFix] is required. ")
end

function BuffLogicChangeEliteDefenceByHPPercent:DoLogic()
    -- 该逻辑的计算使用了单位【当前防御力】，所以计算前需要把本逻辑的效果移除掉
    self:GetBuffLogicService():RemoveBaseDefence(self:GetEntity(), self:GetBuffSeq(), ModifyBaseDefenceType.DefenceConstantFix)

    ---@type AttributesComponent
    local cAttr = self:GetEntity():Attributes()

    local currentDef = cAttr:GetDefence()
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    local hp, maxHP = battleSvc:GetCasterHP(self:GetEntity())
    local newDef = currentDef * self._defArgument * (self._hpPercentFix - (hp / maxHP))
    local def = newDef - currentDef

    self:GetBuffLogicService():ChangeBaseDefence(self:GetEntity(), self:GetBuffSeq(), ModifyBaseDefenceType.DefenceConstantFix, def)

    return true
end

function BuffLogicChangeEliteDefenceByHPPercent:DoOverlap(logicParam, context)
    return self:DoLogic()
end

---@class BuffLogicRevertEliteDefenceByHPPercent : BuffLogicBase
_class("BuffLogicRevertEliteDefenceByHPPercent", BuffLogicBase)
BuffLogicRevertEliteDefenceByHPPercent = BuffLogicRevertEliteDefenceByHPPercent

function BuffLogicRevertEliteDefenceByHPPercent:DoLogic()
    self:GetBuffLogicService():RemoveBaseDefence(self:GetEntity(), self:GetBuffSeq(), ModifyBaseDefenceType.DefenceConstantFix)

    return true
end