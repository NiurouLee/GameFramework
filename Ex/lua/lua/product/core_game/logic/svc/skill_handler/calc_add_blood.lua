--[[
    AddBlood = 36, ---治疗回血
]]
---@class SkillEffectCalc_AddBlood: Object
_class("SkillEffectCalc_AddBlood", Object)
SkillEffectCalc_AddBlood = SkillEffectCalc_AddBlood

function SkillEffectCalc_AddBlood:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBlood:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
---
function SkillEffectCalc_AddBlood:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local posCaster = casterEntity:GridLocation().Position

    local defenderEntityID = targetID
    local entityDefender = self._world:GetEntityByID(defenderEntityID)
    if entityDefender == nil then
        Log.fatal("SkillEffectCalc_AddBlood defender is null ", defenderEntityID)
        return
    end
    if entityDefender:HasPetPstID() and self._world:MatchType() ~= MatchType.MT_Maze then
        Log.fatal("SkillEffectCalc_AddBlood YOU CANNOT ADD BLOOD TO A PET!")
        return
    end

    local posTarget = entityDefender:GridLocation():GetGridPos()

    ---@type SkillEffectParam_AddBlood
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    local stageIndex = skillEffectParam:GetSkillEffectDamageStageIndex()
    local skillResult =
        SkillEffectResult_AddBlood:New(skillEffectParam:GetType(), skillEffectParam:GetData(), posTarget, stageIndex)

    local teamEntity
    if entityDefender:HasTeam() then
        teamEntity = entityDefender
    elseif entityDefender:HasPet() then
        teamEntity = entityDefender:Pet():GetOwnerTeamEntity()
    end

    --死亡是不会恢复
    if teamEntity and teamEntity:HasTeamDeadMark() then
        return
    end

    --禁疗是恢复0
    if teamEntity and teamEntity:Attributes():GetAttribute("BuffForbidCure") then
        skillResult:SetAddData(defenderEntityID, 0)
        return skillResult
    end

    local nAddData = 0
    local nConfigType = skillEffectParam:GetType()
    local nConfigData = skillEffectParam:GetData()
    if AddBlood_Type.Percent == nConfigType then --目标血量百分比
        ---@type AttributesComponent
        local attrCmpt = entityDefender:Attributes()
        local nMaxHp = attrCmpt:CalcMaxHp()
        nAddData = nMaxHp * nConfigData
    elseif AddBlood_Type.AbsData == nConfigType then --配置绝对值
        nAddData = nConfigData
    elseif AddBlood_Type.Attribute == nConfigType then --施法者属性百分比
        local nByAttribute = skillEffectParam:GetAttribute()
        local nAddPercent = skillEffectParam:GetAttributePer()

        nAddData = self:_CalcAddBlood(casterEntity, nByAttribute, nAddPercent, nConfigData)
    elseif AddBlood_Type.HighestHPOfBoss == nConfigType then --boss最高血量
        nAddData = self:HighestHPOfBoss(casterEntity, nConfigData)
    elseif AddBlood_Type.AttributeList == nConfigType then --施法者属性百分比-数组形态
        local attributeList = skillEffectParam:GetAttributeList()
        local attributePerList = skillEffectParam:GetAttributePerList()
        local dataList = skillEffectParam:GetDataList()
        for i = 1, table.count(attributeList) do
            local curByAttribute = attributeList[i]
            local curAddPercent = attributePerList[i]
            local curConfigData = dataList[i]

            local curAddData = self:_CalcAddBlood(casterEntity, curByAttribute, curAddPercent, curConfigData)
            nAddData = nAddData + curAddData
        end
    elseif AddBlood_Type.LastCastActiveSkillPet == nConfigType then --使用上一个释放主动技的光灵的基础攻击力计算
        if not teamEntity then
            teamEntity = self._world:Player():GetCurrentTeamEntity()
        end
        local activeSkillCmpt = teamEntity:ActiveSkill()
        ---@type Entity
        local lastCastSkillEntity = self._world:GetEntityByID(activeSkillCmpt:GetActiveSkillCasterEntityID())
        ---@type BattleService
        local battleSvc = self._world:GetService("Battle")
        local baseAttack = lastCastSkillEntity:MatchPet():GetMatchPet():GetPetAttack()
        local nAddPercent = nConfigData
        nAddData = baseAttack * nAddPercent
    elseif AddBlood_Type.AttributeAndTargetBodyAreaInSkillRangeCount == nConfigType then --施法者属性百分比 + 目标身形在技能范围内的数量
        local nByAttribute = skillEffectParam:GetAttribute()
        local nAddPercent = skillEffectParam:GetAttributePer()
        local targetBodyAreaInSkillRangeCount = 0
        local scopeList = skillEffectCalcParam.skillRange
        local defenderBodyArea = entityDefender:BodyArea():GetArea()
        for i, v in ipairs(defenderBodyArea) do
            local workPos = v + posTarget
            if table.intable(scopeList, workPos) then
                targetBodyAreaInSkillRangeCount = targetBodyAreaInSkillRangeCount + 1
            end
        end
        local newAddPercent = (nAddPercent * targetBodyAreaInSkillRangeCount)
        nAddData = self:_CalcAddBlood(casterEntity, nByAttribute, newAddPercent, nConfigData)
    elseif AddBlood_Type.ByLayerAndAttr == nConfigType then
        local nByAttribute = skillEffectParam:GetAttribute()
        local nAddPercent = skillEffectParam:GetAttributePer()
        local layerType = skillEffectParam:GetBuffLayerType()
        local costLayer = skillEffectParam:GetCostLayer()
        ---@type BuffLogicService
        local buffSvc = self._world:GetService("BuffLogic")
        local layerCount = buffSvc:GetBuffLayer(casterEntity,layerType)
        while layerCount >costLayer do
            nAddData = nAddData + self:_CalcAddBlood(casterEntity, nByAttribute, nAddPercent, 0)
            layerCount = layerCount-costLayer
        end
        buffSvc:SetBuffLayer(casterEntity,layerType,layerCount)
    elseif AddBlood_Type.LostHPPercent == nConfigType then
        ---@type AttributesComponent
        local cAttributes = entityDefender:Attributes()
        local maxHP = cAttributes:CalcMaxHp()
        local currentHP = cAttributes:GetCurrentHP()
        local lostHP = maxHP - currentHP

        nAddData = lostHP * nConfigData
    else
        Log.fatal("### invalid AddBlood_Type: ", nConfigType)
    end
    --回血加成系数
    local rate = 0
    if nAddData ~= 0 then
        rate = casterEntity:Attributes():GetAttribute("AddBloodRate") or 0
        rate = rate + (entityDefender:Attributes():GetAttribute("AddBloodRate") or 0)
        nAddData = nAddData * (1 + rate)
    end
    nAddData = math.floor(nAddData)

    local logger = self._world:GetMatchLogger()
    logger:AddBloodLog(
        casterEntity:GetID(),
        {
            key = "CalcAddBlood",
            desc = "技能加血 攻击者[attacker] 被击者[defender] 加血类型[addtype] 加血量[blood] 回血系数[rate]",
            attacker = casterEntity:GetID(),
            defender = targetID,
            blood = nAddData,
            addtype = GetEnumKey("AddBlood_Type", nConfigType),
            rate = rate
        }
    )
    skillResult:SetAddData(defenderEntityID, nAddData)
    Log.debug("SkillEffectCalc_AddBlood add blood=", nAddData, " defender=", entityDefender:GetID())
    return skillResult
end

---@param casterEntity Entity
function SkillEffectCalc_AddBlood:_CalcAddBlood(casterEntity, nByAttribute, nAddPercent, nConfigData)
    local nByAttributeVal = 0
    if casterEntity then
        if nByAttribute == AddBlood_Attribute.Attack then
            nByAttributeVal = casterEntity:Attributes():GetAttack() or 0
        elseif nByAttribute == AddBlood_Attribute.Defense then
            nByAttributeVal = casterEntity:Attributes():GetDefence() or 0
        elseif nByAttribute == AddBlood_Attribute.MaxHP then
            nByAttributeVal = casterEntity:Attributes():CalcMaxHp() or 0
        elseif nByAttribute == AddBlood_Attribute.TeamLoseHp then
            ---@type CalcDamageService
            local calcDamageService = self._world:GetService("CalcDamage")
            local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
            local curHp, maxHp = calcDamageService:GetTeamLogicHP(teamEntity)
            nByAttributeVal = maxHp - curHp
        end
    end
    local nAddData = nConfigData + (nByAttributeVal * nAddPercent)
    return nAddData
end

--【场上Boss里的最高血量-自身血量差值】，和【怪物总血量的n%】两者间较低的数值为实际回血数值
---@param casterEntity Entity
function SkillEffectCalc_AddBlood:HighestHPOfBoss(casterEntity, rate)
    local nAddData = 0
    local gBoss = self._world:GetGroup(self._world.BW_WEMatchers.Boss)
    local eBossList = gBoss:GetEntities()
    if eBossList and table.count(eBossList) > 0 then
        local highestHP = 0
        for i, e in ipairs(eBossList) do
            local hp = e:Attributes():GetCurrentHP()
            if highestHP < hp then
                highestHP = hp
            end
        end
        local casterHP = casterEntity:Attributes():GetCurrentHP()
        local casterMaxHP = casterEntity:Attributes():CalcMaxHp()
        if highestHP > casterHP then
            nAddData = math.min(highestHP - casterHP, math.floor(casterMaxHP * rate))
        end
    end
    return nAddData
end
