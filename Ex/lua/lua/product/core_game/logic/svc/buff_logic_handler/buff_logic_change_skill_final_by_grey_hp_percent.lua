
--[[
    伤害提高 (当前累计灰血值/(最大生命值*A + B))*C
]]
---@class BuffLogicChangeSkillFinalByGreyHPPercent:BuffLogicBase
_class("BuffLogicChangeSkillFinalByGreyHPPercent", BuffLogicBase)
BuffLogicChangeSkillFinalByGreyHPPercent = BuffLogicChangeSkillFinalByGreyHPPercent

function BuffLogicChangeSkillFinalByGreyHPPercent:Constructor(buffInstance, logicParam)
    --region 线性参数
    self._paramA = logicParam.paramA
    self._paramB = logicParam.paramB
    self._paramC = logicParam.paramC
    --region end
    ---@type ModifySkillParamType[]
    self._effectList = logicParam.effectList ---影响的技能类型 列表

    self._entity = buffInstance._entity --buff持有者
end

---@param notify NotifyAttackBase
function BuffLogicChangeSkillFinalByGreyHPPercent:DoLogic(notify)
    local sourceEntity = self:GetEntity()
    
    local cAttributes = sourceEntity:Attributes()
    local maxHP = cAttributes:CalcMaxHp()
    ---@rype BuffComponent
    local cBuff = sourceEntity:BuffComponent()
    local greyValue = cBuff:GetGreyHPValue(true)
    local promoteRate = (greyValue/(maxHP * self._paramA + self._paramB)) * self._paramC
    if promoteRate == 0 then
        return
    end
    for _, paramType in ipairs(self._effectList) do
        self._buffLogicService:ChangeSkillFinalParam(self._entity, self:GetBuffSeq(), paramType, promoteRate)
    end
end
----------------------------------------------------------------------------------
---@class BuffLogicRemoveSkillFinalByGreyHPPercent:BuffLogicBase
_class("BuffLogicRemoveSkillFinalByGreyHPPercent", BuffLogicBase)
BuffLogicRemoveSkillFinalByGreyHPPercent = BuffLogicRemoveSkillFinalByGreyHPPercent

function BuffLogicRemoveSkillFinalByGreyHPPercent:Constructor(buffInstance, logicParam)
    self._entity = buffInstance._entity
    ---@type ModifySkillParamType[]
    self._effectList = logicParam.effectList
end

function BuffLogicRemoveSkillFinalByGreyHPPercent:DoLogic()
    for _, paramType in ipairs(self._effectList) do
        self._buffLogicService:RemoveSkillFinalParam(self._entity, self:GetBuffSeq(), paramType)
    end
end
