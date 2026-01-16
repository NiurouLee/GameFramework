--[[
    中毒buff，最大血量
]]
_class("BuffLogicAddPoison", BuffLogicBase)
BuffLogicAddPoison = BuffLogicAddPoison

function BuffLogicAddPoison:Constructor(buffInstance, logicParam)
    self._damagePercent = logicParam.damagePercent
end

function BuffLogicAddPoison:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type AttributesComponent
    local attrCmpt = e:Attributes()

    local maxHp = attrCmpt:CalcMaxHp()
    if maxHp <= 0 then
        return
    end

    --每回合只有一个buff逻辑会执行
    local turn = e:BuffComponent():GetBuffValue("PoisonTurn")
    local round = self._world:BattleStat():GetLevelTotalRoundCount()
    if turn == round then
        return
    end

    e:BuffComponent():SetBuffValue("PoisonTurn", round)

    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    local curHP = attrCmpt:GetCurrentHP()
    local layer = self._buffInstance:GetLayerCount()

    --MSG62022 层数为0时应认为DOT无效，而不是造成1点伤害
    if layer == 0 then
        return
    end

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    Log.debug("Buff AddPoison, beforeCalcDmg,entityID: ",e:GetID())
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), e, e, {
        percent = self._damagePercent,
        layer = layer,
        formulaID = 15
    })

    if damageInfo:GetDamageType() == DamageType.Real then
        damageInfo:SetDamageType(DamageType.Poison)
    end

    ---@type CalcDamageService
    local calcDamageSvc = self._world:GetService("CalcDamage")

    ---@type DamageInfo[]
    local recoverDamageInfos={}
    --毒性萤火 中毒状态敌人每次毒伤触发时为玩家恢复毒伤量20%的生命值
    if e:HasMonsterID() then
        local teamEntity = self._world:Player():GetLocalTeamEntity()
        --词缀，无光之夜，玩家在本场战斗内无法获得治疗效果（只能给队长挂）
        local buffForbidCure = teamEntity:Attributes():GetAttribute("BuffForbidCure")
        if not buffForbidCure then
            local es = teamEntity:Team():GetTeamPetEntities() 
            for i, petEntity in ipairs(es) do
                local poisonVampire = petEntity:BuffComponent():GetBuffValue("PoisonVampire") or 0
                local vampireVal = math.floor(damageInfo:GetDamageValue() * poisonVampire)
                if vampireVal > 0 then
                    local recoverDamageInfo = DamageInfo:New(vampireVal, DamageType.Recover)
                    recoverDamageInfo:SetTargetEntityID(petEntity:GetID())
                    calcDamageSvc:AddTargetHP(petEntity:GetID(), recoverDamageInfo)
                    table.insert(recoverDamageInfos,recoverDamageInfo)
                end
            end
        end
    end

    local buffResult = BuffResultAddPoison:New(damageInfo,recoverDamageInfos)
    return buffResult
end
