--[[
    更改星灵的攻防血
]]
require("buff_type")
require("buff_logic_base")
_class("BuffLogicAddPetHpAtkDef", BuffLogicBase)
---@class BuffLogicAddPetHpAtkDef:BuffLogicBase
BuffLogicAddPetHpAtkDef = BuffLogicAddPetHpAtkDef

function BuffLogicAddPetHpAtkDef:Constructor(buffInstance, logicParam)
    self._addedHPPercent = logicParam.addedHPPercent or 0
    self._addedAtkPercent = logicParam.addedAtkPercent or 0
    self._addedDefPercent = logicParam.addedDefPercent or 0
    ---@type Entity
    self._entity = buffInstance:Entity()
end

--buff伤害结算
function BuffLogicAddPetHpAtkDef:DoLogic()
    --获得星灵的血量
    local pstId = self._entity:PetPstID():GetPstID()
    ---@type Pet
    local petData = self._world.BW_WorldInfo:GetPetData(pstId)
    local hp = petData:GetPetHealth()
    local atk = petData:GetPetAttack()
    local def = petData:GetPetDefence()
    --计算增加的属性
    local hpAdded = math.floor(self._addedHPPercent * hp)
    local atkAdded = math.floor(self._addedAtkPercent * atk)
    local defAdded = math.floor(self._addedDefPercent * def)

    local teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    local attributeComponent = self._entity:Attributes()
    local targetEntity = self._entity

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")

    local buffSeqID = self:GetBuffSeq()

    buffLogicService:ChangeBaseAttack(
        targetEntity,
        buffSeqID,
        ModifyBaseAttackType.AttackPercentage,
        self._addedAtkPercent
    )
    buffLogicService:ChangeBaseDefence(
        targetEntity,
        buffSeqID,
        ModifyBaseDefenceType.DefencePercentage,
        self._addedDefPercent
    )
    attributeComponent:Modify("MaxHPConstantFix", hpAdded, buffSeqID)

    local damageInfo = DamageInfo:New(hpAdded, DamageType.Recover)
    ---@type CalcDamageService
    local svc = self._world:GetService("CalcDamage")
    svc:AddTargetHP(self._entity, damageInfo)
    
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    battleService:UpdateTeamHPLogic(teamEntity)
    battleService:UpdateTeamDefenceLogic(teamEntity)
    
    --将计算结果设置到result中
    local buffResult = BuffResultAddPetHpAtkDef:New(hpAdded,atkAdded,defAdded,damageInfo)
    return buffResult
end
