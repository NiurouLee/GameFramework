--[[
    单位诅咒血池状态维护

    EnableCurseHP 表示启用诅咒血池积累
    DisableCurseHP 表示停止诅咒血池的积累，且清除之前累积的数值
]]
require("buff_logic_base")

_class("BuffLogicEnableCurseHPCharge", BuffLogicBase)
---@class BuffLogicEnableCurseHPCharge : BuffLogicBase
BuffLogicEnableCurseHPCharge = BuffLogicEnableCurseHPCharge

---
function BuffLogicEnableCurseHPCharge:DoLogic(_)
    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    --世界boss不被诅咒
    if e:HasMonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = e:MonsterID()
        if monsterIDCmpt:IsWorldBoss() then
            return
        end
    end
    
    ---@rype BuffComponent
    local cBuff = e:BuffComponent()
    if cBuff:IsCurseHPEnabled() then
        return
    end
    cBuff:SetCurseHPEnable(true)
    local casterEntity = self._buffInstance:Context() and self._buffInstance:Context().casterEntity or nil
    if casterEntity then
        cBuff:SetCurseHPSourceEntityID(casterEntity:GetID())
    end
    return {}
end

_class("BuffLogicDisableCurseHPCharge", BuffLogicBase)
---@class BuffLogicDisableCurseHPCharge : BuffLogicBase
BuffLogicDisableCurseHPCharge = BuffLogicDisableCurseHPCharge

---
function BuffLogicDisableCurseHPCharge:DoLogic(_)
    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    ---@rype BuffComponent
    local cBuff = e:BuffComponent()
    cBuff:SetCurseHPEnable(false)
    cBuff:ClearCurseHPValue()
    return {}
end

---@class ChargeCurseHpPercentSourceType
local ChargeCurseHpPercentSourceType = {
    CasterMaxHP = 1, --buff施法者的血量百分比
    OwnerMaxHP = 2, --buff宿主最大血量的百分比
    CasterAttack = 3, --buff施法者攻击力百分比
    OwnerAttack = 4, --buff宿主攻击力百分比
}
_enum("ChargeCurseHpPercentSourceType", ChargeCurseHpPercentSourceType)

_class("BuffLogicChargeCurseHP", BuffLogicBase)
---@class BuffLogicChargeCurseHP : BuffLogicBase
BuffLogicChargeCurseHP = BuffLogicChargeCurseHP

function BuffLogicChargeCurseHP:Constructor(_, logicParam)
    self._basePercent = logicParam.basePercent
    self._basePercentSourceType = logicParam.basePercentSourceType
    self._extraPercent = logicParam.extraPercent
    self._extraPercentSourceType = logicParam.extraPercentSourceType
    self._extraMinPercent = logicParam.extraMinPercent
    self._extraMinPercentSourceType = logicParam.extraMinPercentSourceType
    self._showDamage = false
    if logicParam.showDamage and logicParam.showDamage == 1 then
        self._showDamage = true
    end
    self._showDamageElementType = logicParam.showDamageElementType  or ElementType.ElementType_None
end

local BuffLogicChargeCurseHPTag = "BuffLogicChargeCurseHP: "
---
function BuffLogicChargeCurseHP:DoLogic(notify)
    local entity = self:GetEntity()
    if entity:HasSuperEntity() then
        entity = entity:GetSuperEntity()
    end
    --世界boss不被诅咒
    if entity:HasMonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = entity:MonsterID()
        if monsterIDCmpt:IsWorldBoss() then
            return
        end
    end
    ---@type Entity
    local buffResultEntity = entity
    if entity:HasPet() then
		local eTeam = entity:Pet():GetOwnerTeamEntity()
        entity = eTeam
        buffResultEntity = eTeam--黑拳赛 挂给队伍
    end
    local casterEntity = self._buffInstance:Context().casterEntity
    local basePercentParamValue = 0
    local extraPercentParamValue = 0
    local extraMinPercentParamValue = 0
    local baseValue = 0
    local extraValue = 0
    local extraMinValue = 0
    basePercentParamValue = self:_CalcSourceParamValue(self._basePercentSourceType,entity,casterEntity)
    extraPercentParamValue = self:_CalcSourceParamValue(self._extraPercentSourceType,entity,casterEntity)
    extraMinPercentParamValue = self:_CalcSourceParamValue(self._extraMinPercentSourceType,entity,casterEntity)
    if self._basePercent then
        baseValue = math.ceil(basePercentParamValue * tonumber(self._basePercent))
    end
    if self._extraPercent then
        extraValue = math.ceil(extraPercentParamValue * tonumber(self._extraPercent))
    end
    if self._extraMinPercent then
        extraMinValue = math.ceil(extraMinPercentParamValue * tonumber(self._extraMinPercent))
    end
    if extraValue < extraMinValue then
        extraValue = extraMinValue
    end
    local val = baseValue + extraValue
    local currentVal = self._buffLogicService:ChangeCurseHP(buffResultEntity, val)

    local result = BuffResultChargeCurseHP:New(buffResultEntity:GetID(), currentVal, val,self._showDamage,self._showDamageElementType)

    return result
end
function BuffLogicChargeCurseHP:_CalcSourceParamValue(sourceType,ownerEntity,casterEntity)
    local value = 0
    if sourceType then
        if sourceType == ChargeCurseHpPercentSourceType.CasterMaxHP then
            if casterEntity then
                value = casterEntity:Attributes():CalcMaxHp()
            end
        elseif sourceType == ChargeCurseHpPercentSourceType.OwnerMaxHP then
            value = ownerEntity:Attributes():CalcMaxHp()
        elseif sourceType == ChargeCurseHpPercentSourceType.CasterAttack then
            if casterEntity then
                value = casterEntity:Attributes():GetAttack()
            end
        elseif sourceType == ChargeCurseHpPercentSourceType.OwnerAttack then
            value = ownerEntity:Attributes():GetAttack()
        end
    end
    return value
end

_class("BuffLogicSetTransDamageToCurseHp", BuffLogicBase)
---@class BuffLogicSetTransDamageToCurseHp : BuffLogicBase
BuffLogicSetTransDamageToCurseHp = BuffLogicSetTransDamageToCurseHp

---
function BuffLogicSetTransDamageToCurseHp:Constructor(_, logicParam)
    self._set = logicParam.isSet or 1
    self._transPercent = tonumber(logicParam.transPercent)
end
function BuffLogicSetTransDamageToCurseHp:DoLogic(_)
    local e = self:GetEntity()
    if e:HasSuperEntity() then
        e = e:GetSuperEntity()
    end
    ---@rype BuffComponent
    local cBuff = e:BuffComponent()
    if cBuff then
        local key = "TransDamageToCurseHp"
        if self._set == 1 then
            cBuff:SetBuffValue(key,self._transPercent)
        else
            cBuff:SetBuffValue(key,nil)
        end
    end
end