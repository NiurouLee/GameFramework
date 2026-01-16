--[[
    反伤效果
]]
--添加护盾buff
_class("BuffLogicReflexiveDamage", BuffLogicBase)
BuffLogicReflexiveDamage = BuffLogicReflexiveDamage

function BuffLogicReflexiveDamage:Constructor(buffInstance, logicParam)
    self._percent = logicParam.percent
    self._notifyType = logicParam.notifyType
    self._formulaID = logicParam.formulaID or 18
end

function BuffLogicReflexiveDamage:DoLogic(notify)
    --检查是否是自己关心的通知类型
    local notifyType = notify:GetNotifyType()
    local isMatch = false
    if self._notifyType then
        for _, v in ipairs(self._notifyType) do
            if v == notifyType then
                isMatch = true
                break
            end
        end
    else
        isMatch = true
    end
    if not isMatch then
        return
    end

    local buffCom = self._entity:BuffComponent()
    --下面是真正的逻辑
    local layerKey = "ReflexiveDamageLayer"
    local layer = buffCom:GetBuffValue(layerKey)
    if not layer or layer <= 0 then
        return
    end
    local damage = notify:GetDamageValue()
    if damage <= 0 then
        return
    end
    local damageType = notify:GetDamageType()
    if damageType == DamageType.RealReflexive then
        return
    end
	
    if damageType == DamageType.RealTransmit then
        return
    end

    ---@type Entity
    local attacker = notify:GetAttackerEntity()
    local attackerID = attacker:GetID()
    local attackPos = notify:GetAttackPos()
    --如果是星灵发动攻击被反伤，因为星灵没有血量，所以反伤给队伍
    if attacker:HasPetPstID() then
        attacker = attacker:Pet():GetOwnerTeamEntity()
    end

    local skillHolderID = nil
    ---如果是SkillHolder施放的技能，需要取skillHolder的宿主
    if attacker:HasSuperEntity() then 
        skillHolderID = attackerID
        attacker = attacker:GetSuperEntity()
        attackerID = attacker:GetID()
        attackPos = attacker:GridLocation().Position
    end

    -- P5联动合击技-施法者没有HP属性，导致反伤计算出错
    if (not attacker:HasAttributes()) or (not attacker:Attributes():GetCurrentHP()) then
        return
    end

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), self._entity, attacker, {
        percent = self._percent,
        formulaID = self._formulaID,
        baseDamage = damage
    })

    --减少层数
    layer = layer - 1
    buffCom:SetBuffValue(layerKey, layer)

    ---@type BuffResultReflexiveDamage
    local buffResult = BuffResultReflexiveDamage:New(attackerID,attackPos,damageInfo,layer)
    if skillHolderID then 
        buffResult:SetSkillHolderID(skillHolderID)
    end
    
    return buffResult
end
