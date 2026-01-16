--[[
    使用保存的伤害追加一个伤害
]]
_class("BuffLogicUseSaveDamageAdditionalDamage", BuffLogicBase)
---@class BuffLogicUseSaveDamageAdditionalDamage:BuffLogicBase
BuffLogicUseSaveDamageAdditionalDamage = BuffLogicUseSaveDamageAdditionalDamage

function BuffLogicUseSaveDamageAdditionalDamage:Constructor(buffInstance, logicParam)
    self._mulValue = logicParam.mulValue or 0
    self._addValue = logicParam.addValue or 0
    self._damageType = logicParam.damageType or DamageType.Recover --追加伤害的属性

    self._effectID = logicParam.effectID
end

function BuffLogicUseSaveDamageAdditionalDamage:DoLogic(notify)
    ---@type Entity
    local e = self._buffInstance:Entity()

    --已经死亡不能加血和减血
    if e:HasDeadMark() or e:HasPetDeadMark() then
        return
    end

    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local max_hp = attrCmpt:CalcMaxHp()
    local cur_hp = attrCmpt:GetCurrentHP()
    if cur_hp <= 0 then
        return
    end

    local curSaveSkillDamage = e:BuffComponent():GetBuffValue("SaveSkillDamage") or 0

    if curSaveSkillDamage == 0 then
        return
    end
    --使用后清空
    e:BuffComponent():SetBuffValue("SaveSkillDamage", 0)

    local damageValue = (curSaveSkillDamage * (1 + self._mulValue)) + self._addValue
    local changeHp = math.floor(damageValue)

    --血量截断
    if changeHp + cur_hp > max_hp then
        changeHp = max_hp - cur_hp
    end

    --没有禁疗属性才能回血
    local teamEntity = nil
    if e:HasTeam() then
        teamEntity = e
    elseif e:HasPet() then
        teamEntity = e:Pet():GetOwnerTeamEntity()
    end

    if changeHp > 0 then
        if teamEntity and teamEntity:Attributes():GetAttribute("BuffForbidCure") then
            return
        elseif e:Attributes():GetAttribute("BuffForbidCure") then
            return
        end
    end
    if changeHp < 0 then
        changeHp = -changeHp
    end

    --self._world:GetMatchLogger():BeginBuff(e:GetID(), self._buffInstance:BuffID())

    ---@type CalcDamageService
    local calcDamage = self._world:GetService("CalcDamage")

    ---@type DamageInfo
    local damageInfo = DamageInfo:New(damageValue, self._damageType)
    --实际修改血量
    damageInfo:SetChangeHP(changeHp)

    if self._damageType == DamageType.Recover then
        calcDamage:AddTargetHP(e:GetID(), damageInfo)
    end
    --self._world:GetMatchLogger():EndBuff(e:GetID())

    local result = BuffResultUseSaveDamageAdditionalDamage:New(damageInfo, self._effectID)

    return result
end
