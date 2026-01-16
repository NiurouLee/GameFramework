--------------------------------------------------------------------
---逻辑应该是用队伍的血量百分比跟目标比，秘境中用自己的血量百分比，用自己的血量最大值算吸血值
--------------------------------------------------------------------
_class("BuffLogicAddHPByTargetBuffEffectType", BuffLogicBase)
---@class BuffLogicAddHPByTargetBuffEffectType:BuffLogicBase
BuffLogicAddHPByTargetBuffEffectType = BuffLogicAddHPByTargetBuffEffectType

function BuffLogicAddHPByTargetBuffEffectType:Constructor(buffInstance, logicParam)
    self._baseType = 2 --针对星灵，百分比的类型，1表示是基于队长的百分比，2表示是基于petData的血量的百分比
    if logicParam.baseType then
        self._baseType = logicParam.baseType
    end
    self._buffEffectType = logicParam.buffEffectType
    self._mulValue = logicParam.mulValue
    self._mulValueHigh = logicParam.mulValueHigh
end

function BuffLogicAddHPByTargetBuffEffectType:DoLogic(notify)
    -- if notify:GetNotifyType() ~= NotifyType.ChainSkillAttack then
    --     return
    -- end
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type AttributesComponent
    local attrCmpt = e:Attributes()
    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local calcPercentHp, calcPercentMaxHp = battleService:GetCasterHP(e)

    local calcValueMaxHP = calcPercentMaxHp
    if self._entity:PetPstID() then --是星灵
        if self._baseType == 2 then --是基于petdata的血量百分比
            local pstId = self._entity:PetPstID():GetPstID()
            ---@type Pet
            local petData = self._world.BW_WorldInfo:GetPetData(pstId)
            calcValueMaxHP = petData:GetPetHealth()
        end
    end

    local hpPercent = 1
    if calcPercentMaxHp and calcPercentMaxHp > 0 and calcPercentHp then
        hpPercent = calcPercentHp / calcPercentMaxHp
    end

    --有禁疗属性不能能回血
    local teamEntity = nil
    if e:HasTeam() then
        teamEntity = e
    elseif e:HasPetPstID()  then
        teamEntity = e:Pet():GetOwnerTeamEntity()
    end
    if teamEntity and teamEntity:Attributes():GetAttribute("BuffForbidCure") then
        return
    end

    local recoverHp = 0
    local targetEntityList = notify:GetDefenderEntityIDList()
    local entityList = {}

    local isContainEntityFunc = function(list, entity)
        local entityId = entity:GetID()
        for _, v in ipairs(list) do
            if v:GetID() == entityId then
                return true
            end
        end
        return false
    end

    for _, entityid in ipairs(targetEntityList) do
        local entity = self._world:GetEntityByID(entityid)
        --目标不能是机关
        if not isContainEntityFunc(entityList, entity) and not entity:Trap() then
            entityList[#entityList + 1] = entity
        end
    end

    local addHPRateByTargetHP = e:BuffComponent():GetBuffValue("AddHPRateByTargetHP") or 1
    for _, targetEntity in ipairs(entityList) do
        local layer = buffSvc:GetBuffLayer(targetEntity, self._buffEffectType)
        if layer and layer > 0 then
            local targetHp = targetEntity:Attributes():GetCurrentHP()
            local targetMaxHp = targetEntity:Attributes():CalcMaxHp()
            local p = targetHp / targetMaxHp
            local mulValue = self._mulValue
            if p > hpPercent then
                mulValue = mulValue * addHPRateByTargetHP
            end
            recoverHp = recoverHp + calcValueMaxHP * mulValue * layer
        end
    end

    local rate = e:Attributes():GetAttribute("AddBloodRate") or 0
    --如果是一个星灵，则对队长加血
    if e:PetPstID() then
        e = teamEntity
    end
    --已经死亡不加血
    if e:Attributes():GetCurrentHP() == 0 then
        return
    end

    recoverHp = recoverHp * (1 + rate)
    recoverHp = math.ceil(recoverHp)
    ---@type CalcDamageService
    local svc = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(recoverHp, DamageType.Recover)
    svc:AddTargetHP(e:GetID(), damageInfo)

    local result = BuffResultAddHPByTargetBuffEffectType:New(recoverHp, damageInfo)
    return result
end
