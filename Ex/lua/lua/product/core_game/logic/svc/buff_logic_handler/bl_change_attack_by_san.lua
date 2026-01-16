--[[BuffLogic, ChangeAttack, BySan, that's it]]
_class("BuffLogicChangeAttackBySan", BuffLogicBase)
---@class BuffLogicChangeAttackBySan:BuffLogicBase
BuffLogicChangeAttackBySan = BuffLogicChangeAttackBySan
---
function BuffLogicChangeAttackBySan:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._baseSan = logicParam.baseSan or 100 --以这个san值为基础计算

    self._minValue = logicParam.minValue --最小值，不写不判断
    self._maxValue = logicParam.maxValue --最大值，不写不判断

    self._attackSourceType = logicParam.attackSourceType ---指定取攻击力的来源类型
    self._attackSourceParam = logicParam.attackSourceParam ---指定攻击力的来源参数，不同的攻击力来源类型可以指定不同的参数
end

---
function BuffLogicChangeAttackBySan:DoLogic()
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

    local baseAttack = self:ChangeAttackBySan_CalcBaseAttack()

    local changeSan = curSanValue - self._baseSan
    local newChangeValue = changeSan * self._mulValue

    if self._minValue then
        newChangeValue = math.max(newChangeValue, self._minValue)
    end
    if self._maxValue then
        newChangeValue = math.min(newChangeValue, self._maxValue)
    end

    local attack = math.floor(baseAttack * newChangeValue)

    Log.debug(
        "CalcChangeAttackBySan entity=",
        entity:GetID(),
        " baseAttack=",
        baseAttack,
        " curSanValue=",
        curSanValue,
        " newChangeValue=",
        newChangeValue,
        " deltaAttack=",
        attack
    )

    self._buffLogicService:ChangeBaseAttack(entity, self:GetBuffSeq(), ModifyBaseAttackType.AttackConstantFix, attack)
end

---计算攻击力来源类型
function BuffLogicChangeAttackBySan:ChangeAttackBySan_CalcBaseAttack()
    local sourceEntity = self._buffInstance:Entity()
    if self._attackSourceType == 1 then 
        local specialPetTemplateID = self._attackSourceParam

        local petPstIDGroup = self._world:GetGroup(self._world.BW_WEMatchers.PetPstID)
        for i, e in ipairs(petPstIDGroup:GetEntities()) do
            ---@type PetPstIDComponent
            local petPstIDCmpt = e:PetPstID()
            local tmplateID = petPstIDCmpt:GetTemplateID()
            if specialPetTemplateID == tmplateID then
                sourceEntity = e
                break
            end
        end
    end

    ---@type FormulaService
    local lsvcFormula = self._world:GetService("Formula")
    local baseAttack = lsvcFormula:CalcAttack(sourceEntity)

    return baseAttack
end

--remove effect of a BuffLogicChangeAttackBySan
_class("BuffLogicRemoveAttackBySan", BuffLogicBase)
BuffLogicRemoveAttackBySan = BuffLogicRemoveAttackBySan

---
function BuffLogicRemoveAttackBySan:DoLogic()
    local entity = self._buffInstance:Entity()
    self._buffLogicService:RemoveBaseAttack(entity, self:GetBuffSeq(), ModifyBaseAttackType.AttackConstantFix)
end
