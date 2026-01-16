--[[
    传递伤害效果
]]
_class("BuffLogicTransmitDamage", BuffLogicBase)
BuffLogicTransmitDamage = BuffLogicTransmitDamage

function BuffLogicTransmitDamage:Constructor(buffInstance, logicParam)
    self._percent = logicParam.percent
    self._notifyType = logicParam.notifyType
    self._formulaID = logicParam.formulaID or 126
    self._targetBuffID = logicParam.targetBuffID
end

function BuffLogicTransmitDamage:GetBuffTargetIDLsit()
    --获取场上所有光灵和怪物
    local team1 = self._world:Player():GetLocalTeamEntity()
    local es = { team1 }
    local team2 = self._world:Player():GetRemoteTeamEntity()
    if team2 then
        es[#es + 1] = team2
    end
    local monsters = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    table.appendArray(es, monsters)

    --获取有Buff的光灵和怪物
    local idList = {}
    for i, e in ipairs(es) do
        if e:BuffComponent():HasBuffEffect(self._targetBuffID) and not e:HasDeadMark() then
            idList[#idList + 1] = e:GetID()
        end
    end

    return idList
end

function BuffLogicTransmitDamage:DoLogic(notify)
    --检查是否是自己关心的通知类型
    local notifyType = notify:GetNotifyType()
    local isMatch = false
    if self._notifyType then
        for _, v in pairs(self._notifyType) do
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
    if notify:GetChangeHP() >= 0 then
        return
    end
    local damageType = notify:GetDamageType()
    if damageType == DamageType.RealReflexive then
        return
    end

    local transerID = self._entity:GetID()

    local attackerID = notify:GetDamageSrcEntityID()
    if attackerID == transerID then
        -- 攻击者与传递者ID一致，则认为技能是自爆
        return
    end
    ---@type Entity
    local attacker = self._world:GetEntityByID(attackerID)
    --如果是星灵，则查找队伍
    if attacker:HasPetPstID() then
        attacker = attacker:Pet():GetOwnerTeamEntity()
    end

    --传递伤害的目标对象是附加buff的对象
    local defenderIDs = self:GetBuffTargetIDLsit()
    if not defenderIDs then
        return
    end

    local damageInfos = {}
    for _, ID in pairs(defenderIDs) do
        ---@type Entity
        local defender = self._world:GetEntityByID(ID)
        --如果是星灵，则查找队伍
        if defender:HasPetPstID() then
            defender = defender:Pet():GetOwnerTeamEntity()
        end

        ---@type BuffLogicService
        local blsvc = self._world:GetService("BuffLogic")
        local damageInfo =
            blsvc:DoBuffDamage(
                self._buffInstance:BuffID(),
                attacker,
                defender,
                {
                    percent = self._percent,
                    formulaID = self._formulaID,
                    changeHp = notify:GetChangeHP(),
                    attackPos = notify:GetAttackPos()
                }
            )
        table.insert(damageInfos, damageInfo)
    end

    local buffResult = BuffResultTransmitDamage:New(attackerID, transerID, defenderIDs, damageInfos)
    buffResult:SetAttackPos(notify:GetAttackPos())

    return buffResult
end
