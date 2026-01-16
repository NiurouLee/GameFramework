--[[
    根据Layer增加血量
]]
_class("BuffLogicAddHPByLayer", BuffLogicBase)
---@class BuffLogicAddHPByLayer:BuffLogicBase
BuffLogicAddHPByLayer = BuffLogicAddHPByLayer

function BuffLogicAddHPByLayer:Constructor(buffInstance, logicParam)
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._costLayer = logicParam.costLayer
    self._perLayer = logicParam.perLayer
    self._attrType = logicParam.attrType
end

function BuffLogicAddHPByLayer:DoLogic(notify)
    ---@type Entity
    local casterEntity = self._buffInstance:Entity()

    ---@type Entity
    local e = casterEntity
    local rate = e:Attributes():GetAttribute("AddBloodRate") or 0
    local defenderRate = 0
    Log.info("BuffLogicAddHPByLayer:DoLogic CasterRate = ", rate)
    --如果是一个星灵，则对队长加血
    if casterEntity:PetPstID() then
        e = casterEntity:Pet():GetOwnerTeamEntity()
        defenderRate = e:Attributes():GetAttribute("AddBloodRate") or 0
        Log.info("BuffLogicAddHPByLayer:DoLogic TeamEntity = ", rate)
        rate = rate + defenderRate
    end
    ---@type BattleService
    local  battleSvc = self._world:GetService("Battle")
    local curHP,maxHP = battleSvc:GetCasterHP(casterEntity)
    --死亡不加血
    if curHP <= 0 then
        return
    end

    --没有禁疗属性才能回血
    if e:Attributes():GetAttribute("BuffForbidCure") then
        return
    end
    ---@type AttributesComponent
    local attrCmpt = casterEntity:Attributes()
    --获取层数
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local curMarkLayer = svc:GetBuffLayer(self._entity, self._layerType)
    local add_value = 0
    local value
    local count = 0
    local sourceLayer =curMarkLayer
    while self._costLayer <=curMarkLayer and
            curHP <maxHP  do
        value = self:_CalcAddBlood(casterEntity, self._attrType, self._perLayer,0)
        curHP = curHP + value
        add_value =add_value + value
        curMarkLayer = curMarkLayer- self._costLayer
        count = count +1
    end
    local damageType = DamageType.Recover
    Log.info("BuffLogicAddHPByLayer:DoLogic FinalRage = ", rate,"SourceValue = ",add_value,"FinalValue = ",add_value * (1 + rate))
    local final_value = add_value * (1 + rate)
    
    --local logger = self._world:GetMatchLogger()
    --logger:BeginDamageLog(casterEntity:GetID())
    --logger:AddDamageLog(
    --        casterEntity:GetID(),
    --        {
    --            key = "BuffLogicAddHPByLayer",
    --            desc = "施法者[caster] 被击者[defender] 伤害[val] = 基础值[base] * 次数[count] *(1+施法者治疗加成[casterRate]+被治疗者治疗加成[defenderRate])  参数值：初始层数[sourceLayer] 当前层数[curLayer] 每x层[costLayer] 加x%血量[perLayer] LayerType[layerType]",
    --            caster = casterEntity:GetID(),
    --            defender = e:GetID(),
    --            val =final_value ,
    --            base = value,
    --            count = count,
    --            casterRate = rate-defenderRate,
    --            defenderRate = defenderRate,
    --            sourceLayer = sourceLayer,
    --            curLayer = curMarkLayer,
    --            costLayer = self._costLayer,
    --            perLayer = self._perLayer,
    --            layerType = self._layerType,
    --        }
    --)
    --logger:EndDamageLog(casterEntity:GetID())

    ---@type CalcDamageService
    local calcDamageSvc = self._world:GetService("CalcDamage")
    ---@type DamageInfo
    local damageInfo = DamageInfo:New(final_value, damageType)
    calcDamageSvc:AddTargetHP(e:GetID(), damageInfo)
    Log.fatal("AddHPByLayer addValue:",final_value,"NewLayer:",curMarkLayer)
    local tmp,buffinst=svc:SetBuffLayer(self._entity, self._layerType, curMarkLayer)
    local layerName = svc:GetBuffLayerName(self._layerType)
    local totalLayerCount = svc:GetBuffTotalLayer(self._entity, layerName)
    ---@type BuffResultAddHPByLayer
    local res = BuffResultAddHPByLayer:New(damageInfo, e:GetID(),curMarkLayer,totalLayerCount,buffinst:BuffSeq())
    res:SetLayerName(layerName)
    return res
end

function BuffLogicAddHPByLayer:_CalcAddBlood(casterEntity, nByAttribute, nAddPercent, nConfigData)
    local nByAttributeVal = 0
    if casterEntity then
        if nByAttribute == AddBlood_Attribute.Attack then
            nByAttributeVal = casterEntity:Attributes():GetAttack() or 0
        elseif nByAttribute == AddBlood_Attribute.Defense then
            nByAttributeVal = casterEntity:Attributes():GetDefence() or 0
        elseif nByAttribute == AddBlood_Attribute.MaxHP then
            nByAttributeVal = casterEntity:Attributes():CalcMaxHp() or 0
        end
    end
    local nAddData = nConfigData + (nByAttributeVal * nAddPercent)
    return nAddData
end