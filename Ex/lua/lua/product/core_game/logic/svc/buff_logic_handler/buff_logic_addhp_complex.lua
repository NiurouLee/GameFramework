--[[
    水天使被动，按最大生命值百分比、绝对值加血
]]
_class("BuffLogicAddHPComplex", BuffLogicBase)
---@class BuffLogicAddHPComplex:BuffLogicBase
BuffLogicAddHPComplex = BuffLogicAddHPComplex

function BuffLogicAddHPComplex:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._addValue = logicParam.addValue or 0
    self._headOut = (logicParam.headout == 1)
    self._baseType = logicParam.baseType or 1
    self._delay = logicParam.delay or 0
end

function BuffLogicAddHPComplex:DoLogic(notify)
    ---@type Entity
    local e = self._buffInstance:Entity()

    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()

    --是星灵[用星灵的血量算最大值]
    if e:PetPstID() then
        if self._baseType == 2 then --是基于petdata的血量百分比
            local pstId = e:PetPstID():GetPstID()
            ---@type Pet
            local petData = self._world.BW_WorldInfo:GetPetData(pstId)
            max_hp = petData:GetPetHealth()
        elseif self._baseType == 3 then
            local pstId = e:PetPstID():GetPstID()
            ---@type Pet
            local petData = self._world.BW_WorldInfo:GetPetData(pstId)
            max_hp = petData:GetPetAttack()
        elseif self._baseType == 4 then
            max_hp = attrCmpt:GetAttack()
        end
    end

    --如果是一个星灵，则对队长加血
    if e:PetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end

    local cur_hp = e:Attributes():GetCurrentHP()
    if cur_hp <= 0 then
        return
    end

    --没有禁疗属性才能回血
    if e:Attributes():GetAttribute("BuffForbidCure") then
        return
    end

    --水属性格子转色
    local times = 1
    if notify ~= nil and notify:GetNotifyType() == NotifyType.GridConvert and notify.GetConvertWaterCount then
        local bluePieceNum = notify:GetConvertWaterCount()
        if bluePieceNum and bluePieceNum >0 then
            times = bluePieceNum
        end
    end

    local rate = e:Attributes():GetAttribute("AddBloodRate") or 0

    --回血
    local add_value = 0
    add_value = max_hp * self._mulValue + self._addValue
    add_value = add_value * times
    add_value = add_value * (1 + rate)
    add_value = math.floor(add_value)

    local damageType = DamageType.Recover
    ---@type CalcDamageService
    local svc = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(add_value, damageType)
    local curHp = svc:AddTargetHP(e:GetID(), damageInfo)

    local res = BuffResultAddHPComplex:New(damageInfo, self._headOut, self._delay)
    return res
end
