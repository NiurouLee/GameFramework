
--[[
    伤害提高 x(基础值)*（1 + y（盾值占血条百分比）+ z（当前血量百分比加成）） sp米娅 --改成x + y + z
]]
---@class BuffLogicChangeSkillFinalByHPShield:BuffLogicBase
_class("BuffLogicChangeSkillFinalByHPShield", BuffLogicBase)
BuffLogicChangeSkillFinalByHPShield = BuffLogicChangeSkillFinalByHPShield

function BuffLogicChangeSkillFinalByHPShield:Constructor(buffInstance, logicParam)
    --region 线性参数
    self._baseValue = logicParam.baseValue
    self._shieldParamMax = logicParam.shieldParamMax--参数y的最大值
    self._shieldPercentMax = logicParam.shieldPercentMax--护盾占总血量多少百分比时达到最高
    self._curHpParamMax = logicParam.curHpParamMax--参数z的最大值（从满血到0血线性变化）
    --region end
    ---@type ModifySkillParamType[]
    self._effectList = logicParam.effectList ---影响的技能类型 列表

    self._entity = buffInstance._entity --buff持有者
end

---@param notify NotifyAttackBase
function BuffLogicChangeSkillFinalByHPShield:DoLogic(notify)
    local sourceEntity = self:GetEntity()
    if sourceEntity:HasPet() then
        sourceEntity = sourceEntity:Pet():GetOwnerTeamEntity()
    end
    local cAttributes = sourceEntity:Attributes()
    local maxHP = cAttributes:CalcMaxHp()
    local curHP = cAttributes:GetCurrentHP()
    ---@rype BuffComponent
    local cBuff = sourceEntity:BuffComponent()
    local curShieldValue = cBuff:GetBuffValue("HPShield") or 0
    if curShieldValue == 0 then
        return
    end
    if maxHP == 0 then
        return
    end
    local shieldParam = 0
    local curShieldPercent = curShieldValue / maxHP
    if curShieldPercent >= self._shieldPercentMax then
        shieldParam = self._shieldParamMax
    else
        shieldParam = curShieldPercent / self._shieldPercentMax * self._shieldParamMax
    end
    local hpParam = (1 - (curHP / maxHP)) * self._curHpParamMax
    --local promoteRate = self._baseValue * (1 + shieldParam + hpParam)
    local promoteRate = self._baseValue + shieldParam + hpParam --改成 x + y + z
    if promoteRate == 0 then
        return
    end
    for _, paramType in ipairs(self._effectList) do
        self._buffLogicService:ChangeSkillFinalParam(self._entity, self:GetBuffSeq(), paramType, promoteRate)
    end
end
----------------------------------------------------------------------------------
---@class BuffLogicRemoveSkillFinalByHPShield:BuffLogicBase
_class("BuffLogicRemoveSkillFinalByHPShield", BuffLogicBase)
BuffLogicRemoveSkillFinalByHPShield = BuffLogicRemoveSkillFinalByHPShield

function BuffLogicRemoveSkillFinalByHPShield:Constructor(buffInstance, logicParam)
    self._entity = buffInstance._entity
    ---@type ModifySkillParamType[]
    self._effectList = logicParam.effectList
end

function BuffLogicRemoveSkillFinalByHPShield:DoLogic()
    for _, paramType in ipairs(self._effectList) do
        self._buffLogicService:RemoveSkillFinalParam(self._entity, self:GetBuffSeq(), paramType)
    end
end
