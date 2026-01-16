--[[
    链接伤害，传递伤害/恢复
    队伍/怪物，怪物/怪物
]]
_class("BuffLogicChainDamage", BuffLogicBase)
---@class BuffLogicChainDamage: BuffLogicBase
BuffLogicChainDamage = BuffLogicChainDamage

function BuffLogicChainDamage:Constructor(buffInstance, logicParam)
    --如果是伤害用这个伤害公式
    self._formulaID = logicParam.formulaID or 141
end

function BuffLogicChainDamage:DoLogic(notify)
    ---@type Entity
    local entity = self._buffInstance:Entity()
    local entityID = entity:GetID()

    local context = self._buffInstance:Context()
    if not context then
        return
    end
    local casterEntity = context.casterEntity
    if not casterEntity then
        return
    end

    ---@type LogicChainDamageComponent
    local logicChainDamage = entity:LogicChainDamage()
    if not logicChainDamage then
        return
    end

    if not notify.GetChangeHP or not notify.GetDamageInfo then
        return
    end

    -- if notify:GetChangeHP() >= 0 then
    --     return
    -- end

    local damageType = notify:GetDamageType()
    local originalAttackID = notify:GetDamageSrcEntityID()
    local attackerID = notify:GetDamageSrcEntityID()
    ---@type DamageInfo
    local notifyDamageInfo = notify:GetDamageInfo()
    local hpAndShieldChangeValue = notifyDamageInfo:GetHpAndShieldChangeValue()
    if hpAndShieldChangeValue == 0 then
        return
    end

    if damageType == DamageType.Miss or damageType == DamageType.Guard then
        return
    end

    local transerID = self._entity:GetID()

    -- if attackerID == transerID then
    --     -- 攻击者与传递者ID一致，则认为技能是自爆
    --     return
    -- end

    ---@type Entity
    local attacker = self._world:GetEntityByID(attackerID)

    --有攻击者的数据都是计算伤害的
    if attacker then
        --如果是星灵，则查找队伍
        if attacker:HasPetPstID() then
            attacker = attacker:Pet():GetOwnerTeamEntity()
            attackerID = attacker:GetID()
        end
    else
        --没有攻击者的damageInfo 默认是加血或者buff产生的，攻击者就是挂载者
        attacker = entity
        attackerID = attacker:GetID()
    end

    --有组件的
    local defenderIDs = {}
    local percents = {}

    -- local entityGroup = self._world:GetGroup(self._world.BW_WEMatchers.LogicChainDamage)
    -- --查找传递伤害的时候只找本体可以链接到的人
    -- for _, e in ipairs(entityGroup:GetEntities()) do
    --     --如果本次伤害是传递的真伤 or 传递的加血，那么计算传递的时候不计算来源
    --     -- if damageType == DamageType.RealTransmit and e:GetID() == attackerID then
    --     --     goto CONTINUE
    --     -- end

    --     --不会自己传递给自己
    --     if e:GetID() == entity:GetID() then
    --         goto CONTINUE
    --     end

    --     ---@type LogicChainDamageComponent
    --     local logicChainDamageComponent = e:LogicChainDamage()
    --     local isEnable = logicChainDamageComponent:GetChainDamageEnable()

    --     --查找的是对方身上
    --     local percent = 0
    --     if damageType == DamageType.Recover then
    --         percent = logicChainDamageComponent:GetChainRecoverEntityID(entityID)
    --     else
    --         percent = logicChainDamageComponent:GetChainDamageEntityID(entityID)
    --     end

    --     if not e:HasDeadMark() and isEnable then
    --         table.insert(defenderIDs, e:GetID())
    --         table.insert(percents, percent)
    --     end

    --     ::CONTINUE::
    -- end

    -- local percent = 0
    local chainList = {}
    if damageType == DamageType.Recover or damageType == DamageType.RecoverTransmit then
        chainList = logicChainDamage:GetChainRecoverList()
    else
        chainList = logicChainDamage:GetChainDamageList()
    end

    if table.count(chainList) == 0 then
        return
    end

    --这里获取的是所有与挂载者链接的
    for chainEntityID, percent in pairs(chainList) do
        local isTransmit = (damageType == DamageType.RealTransmit or damageType == DamageType.RecoverTransmit)
        --不会自己传递给传递源
        if chainEntityID == attackerID and isTransmit then
            goto CONTINUE
        end

        ---@type Entity
        local chainEntity = self._world:GetEntityByID(chainEntityID)
        if not chainEntity or (chainEntity and chainEntity:HasDeadMark()) then
            goto CONTINUE
        end

        table.insert(defenderIDs, chainEntityID)
        table.insert(percents, percent)

        ::CONTINUE::
    end

    --挂载者收到的伤害为链接以外的伤害 都可以链接给攻击者
    --受到的是链接伤害 不可以链接给攻击者

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    ---@type CalcDamageService
    local calcDamage = self._world:GetService("CalcDamage")

    local damageInfos = {}
    for i, ID in pairs(defenderIDs) do
        ---@type Entity
        local defender = self._world:GetEntityByID(ID)
        --如果是星灵，则查找队伍
        if defender:HasPetPstID() then
            defender = defender:Pet():GetOwnerTeamEntity()
        end

        local percent = percents[i]
        ---@type DamageInfo
        local damageInfo = nil
        if damageType == DamageType.Recover or damageType == DamageType.RecoverTransmit then
            ---@type AttributesComponent
            local attrCmpt = defender:Attributes()
            local max_hp = attrCmpt:CalcMaxHp()
            local cur_hp = attrCmpt:GetCurrentHP()

            local add_value = math.floor(hpAndShieldChangeValue * percent)
            --血量截断
            if add_value + cur_hp > max_hp then
                add_value = max_hp - cur_hp
            end

            damageInfo = DamageInfo:New(add_value, DamageType.RecoverTransmit)
            damageInfo:SetAttackerEntityID(entity:GetID())
            calcDamage:AddTargetHP(defender:GetID(), damageInfo)
        else
            -- calcDamage:_DoDamageModifyHP(e, e, damageInfo)

            --buff的挂载者是攻击者
            damageInfo =
                blsvc:DoBuffDamage(
                self._buffInstance:BuffID(),
                entity,
                defender,
                {
                    percent = percent,
                    formulaID = self._formulaID,
                    changeHp = hpAndShieldChangeValue,
                    attackPos = notify:GetAttackPos()
                }
            )
        end

        if damageInfo then
            table.insert(damageInfos, damageInfo)
        end
    end

    if table.count(damageInfos) == 0 then
        return
    end

    --实际攻击的人（光灵转成队伍前的ID）
    --挂载buff的人/被打的人/发动链接伤害的人
    --被链接的
    local buffResult = BuffResultChainDamage:New(originalAttackID, entityID, defenderIDs, damageInfos)
    buffResult:SetAttackPos(notify:GetAttackPos())
    buffResult:SetNotifyHp(notify:GetChangeHP())

    return buffResult
end
