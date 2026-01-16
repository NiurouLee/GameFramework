require "buff_logic_base"

_class("BuffLogicRecoveryOnLostHP", BuffLogicBase)
---@class BuffLogicRecoveryOnLostHP : BuffLogicBase
BuffLogicRecoveryOnLostHP = BuffLogicRecoveryOnLostHP

function BuffLogicRecoveryOnLostHP:Constructor(instance, param)
    self._mulValue = param.mulValue or 0
    self._maxRate = param.maxRate or 0
end

function BuffLogicRecoveryOnLostHP:DoLogic()
    --修改谁的属性，默认修改buff宿主
    local e = self._buffInstance:Entity()
    local matchType = self._world:MatchType()

    --这个逻辑对怪物没有意义（目前）
    if not e:HasPetPstID() then
        return
    end

    ---@type Entity
    local teamEntity = e:Pet():GetOwnerTeamEntity()
    if not self._buffInstance:Context().casterEntity then
        return
    end

    local casterEntity = self._buffInstance:Context().casterEntity
    --没有禁疗属性才能回血
    if teamEntity and teamEntity:Attributes():GetAttribute("BuffForbidCure") then
        return
    elseif e:Attributes():GetAttribute("BuffForbidCure") then
        return
    end
 
    local add_value = 0
    if matchType ~= MatchType.MT_Maze then
        e = teamEntity
        ---@type AttributesComponent
        local attrCmpt = teamEntity:Attributes()

        local max_hp = attrCmpt:CalcMaxHp()
        local cur_hp = teamEntity:Attributes():GetCurrentHP()
        add_value = math.floor((max_hp - cur_hp) * self._mulValue)
    else
        local globalPetEntities = teamEntity:Team():GetTeamPetEntities()
        for _, pet in ipairs(globalPetEntities) do
            ---@type AttributesComponent
            local cAttribute = pet:Attributes()
            local max_hp = cAttribute:CalcMaxHp()
            local cur_hp = cAttribute:GetCurrentHP()
            add_value = add_value + math.floor((max_hp - cur_hp) * self._mulValue)
        end
    end

    local max = math.floor(casterEntity:Attributes():CalcMaxHp() * self._maxRate)
    add_value = math.min(max, add_value)

    ---@type CalcDamageService
    local calcDamage = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(add_value, DamageType.Recover)
    damageInfo:SetSinglePet(self._singlePet)
    calcDamage:AddTargetHP(e:GetID(), damageInfo)

    local res = BuffResultRecoveryOnLostHP:New(damageInfo)
    return res
end
