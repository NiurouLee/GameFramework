_class("DegressiveDirectionalDamageCalculator", Object)
---@class DegressiveDirectionalDamageCalculator
DegressiveDirectionalDamageCalculator = DegressiveDirectionalDamageCalculator

---@param world MainWorld
function DegressiveDirectionalDamageCalculator:Constructor(world)
    self._world = world
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_DegressiveDirectionalDamage
function DegressiveDirectionalDamageCalculator:GetNewScopeCenter(casterEntity, effectParam)
    ---@type ActiveSkillPickUpComponent
    local pickupComponent = casterEntity:ActiveSkillPickUpComponent()
    if not pickupComponent then
        Log.error(self._className, "施法者没有ActiveSkillPickupComponent")
        return
    end

    local pickupPosArray = pickupComponent:GetAllValidPickUpGridPos()
    if #pickupPosArray == 0 then
        Log.error(self._className, "没有点选位置记录")
        return
    end
    local selectedPickupPos = pickupPosArray[1]

    local v2CasterPos = casterEntity:GetGridPosition()
    local directionType = effectParam:GetDirection()

    local v2Dir = selectedPickupPos - v2CasterPos
    if v2Dir.x > 0 then
        v2Dir.x = 1
    elseif v2Dir.x < 0 then
        v2Dir.x = -1
    end
    if v2Dir.y > 0 then
        v2Dir.y = 1
    elseif v2Dir.y < 0 then
        v2Dir.y = -1
    end

    local v2 = Vector2.zero
    if directionType == DegressiveDamageDirection.PICKUP_POS then
    elseif directionType == DegressiveDamageDirection.PICKUP_LEFT_CORNER then
        if v2Dir == Vector2.up then
            v2 = Vector2.New(-1, 1)
        elseif v2Dir == Vector2.down then
            v2 = Vector2.New(1, -1)
        elseif v2Dir == Vector2.left then
            v2 = Vector2.New(-1, -1)
        elseif v2Dir == Vector2.right then
            v2 = Vector2.New(1, 1)
        end
    elseif directionType == DegressiveDamageDirection.PICKUP_RIGHT_CORNER then
        if v2Dir == Vector2.up then
            v2 = Vector2.New(1, 1)
        elseif v2Dir == Vector2.down then
            v2 = Vector2.New(-1, -1)
        elseif v2Dir == Vector2.left then
            v2 = Vector2.New(-1, 1)
        elseif v2Dir == Vector2.right then
            v2 = Vector2.New(1, -1)
        end
    elseif directionType == DegressiveDamageDirection.PICKUP_FRONT_LEFT then
        if v2Dir == Vector2.up then
            v2 = Vector2.New(-1, 0)
        elseif v2Dir == Vector2.down then
            v2 = Vector2.New(1, 0)
        elseif v2Dir == Vector2.left then
            v2 = Vector2.New(0, -1)
        elseif v2Dir == Vector2.right then
            v2 = Vector2.New(0, 1)
        end
    elseif directionType == DegressiveDamageDirection.PICKUP_FRONT_RIGHT then
        if v2Dir == Vector2.up then
            v2 = Vector2.New(1, 0)
        elseif v2Dir == Vector2.down then
            v2 = Vector2.New(-1, 0)
        elseif v2Dir == Vector2.left then
            v2 = Vector2.New(0, 1)
        elseif v2Dir == Vector2.right then
            v2 = Vector2.New(0, -1)
        end
    end

    v2 = v2 + v2CasterPos

    return v2
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_DegressiveDirectionalDamage
function DegressiveDirectionalDamageCalculator:Calculate(casterEntity, effectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillEffectParam_DegressiveDirectionalDamage
    local sep = effectParam
    local scopeType = sep:GetSkillEffectScopeType()
    local scopeParamRaw = sep:GetSkillEffectScopeParam()
    local targetType = sep:GetSkillEffectTargetType()

    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigHelper
    local helper = configSvc._skillConfigHelper
    ---@type SkillScopeParamParser
    local parser = helper._scopeParamParser

    local scopeParam = parser:ParseScopeParam(scopeType, scopeParamRaw)

    if scopeType == nil or scopeParam == nil or targetType == nil then
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData 主动技配置数据
        local skillConfigData = configService:GetSkillConfigData(skillID)
        scopeType = skillConfigData:GetSkillScopeType()
        scopeParam = skillConfigData:GetSkillScopeParam()
        targetType = skillConfigData:GetSkillTargetType()
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScopeSvc:GetSkillScopeCalc()

    local v2CenterPos = self:GetNewScopeCenter(casterEntity, effectParam)

    local scopeResult =
        scopeCalc:ComputeScopeRange(
        scopeType,
        scopeParam,
        v2CenterPos,
        casterEntity:BodyArea():GetArea(),
        casterEntity:GetGridDirection(),
        targetType,
        casterEntity:GetGridPosition()
    )

    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local targetIDArray = targetSelector:DoSelectSkillTarget(casterEntity, targetType, scopeResult, skillID)

    local dicTargetIDPos = {}
    local selectEntityIDByPosIndex = {}
    for _, id in ipairs(targetIDArray) do
        local e = self._world:GetEntityByID(id)
        local bodyArea = e:BodyArea():GetArea()
        for __, v2Relative in ipairs(bodyArea) do
            local v2 = v2Relative + e:GetGridPosition()
            local posIndex = Vector2.Pos2Index(v2)
            if table.icontains(scopeResult:GetAttackRange(), v2) and (not selectEntityIDByPosIndex[posIndex]) then
                ---一个格子多个单位，只选中一个单位，算作造成一次伤害，这里按需求只处理了乘骑状态，如果出其他需求，需要在这个位置处理
                local selectedID = id
                if e:HasRide() then
                    ---@type RideComponent
                    local cRide = e:Ride()
                    local mountID = cRide:GetMountID()
                    --目前给的需求是，打被骑着的单位，且一个格子上不会出现重叠的乘骑单位
                    --如果一个单位有RideComponent，要么它是mount，要么它是rider
                    selectedID = mountID
                end

                if not dicTargetIDPos[selectedID] then
                    dicTargetIDPos[selectedID] = {}
                end
                table.insert(dicTargetIDPos[selectedID], v2)
                selectEntityIDByPosIndex[posIndex] = selectedID
            end
        end
    end
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")

    local v2CasterGridPos = casterEntity:GetGridPosition()
    local tTargetDistanceInfo = utilScope:GetEntityDistanceInfoArrayByPosDic(targetIDArray, v2CasterGridPos, dicTargetIDPos)

    local damageStageIndex = effectParam:GetSkillEffectDamageStageIndex()

    ---@type SkillContextComponent
    local cSkillContext = casterEntity:SkillContext()

    ---@type SkillDamageEffectResult[]
    local tDamageResults = {}

    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    ---@type SkillEffectCalcService
    local effectCalcSvc = self._world:GetService("SkillEffectCalc")

    local tResults = {}
    local damageRates = effectParam:GetDegressiveRates()
    for i = 1, #damageRates do
        local index = i
        local damageRate = damageRates[i]

        local targetDistanceInfo = tTargetDistanceInfo[index]
        if not targetDistanceInfo then
            break
        end
        local eTargetID = targetDistanceInfo.targetID
        local eTarget = self._world:GetEntityByID(eTargetID)
        cSkillContext:SetDegressiveDamageParam(damageRate)
        local nTotalDamage, listDamageInfo =
            effectCalcSvc:ComputeSkillDamage(
            casterEntity,
            v2CasterGridPos,
            eTarget,
            targetDistanceInfo.gridPos,
            skillID,
            effectParam,
            SkillEffectType.Damage,
            damageStageIndex
        )

        local skillResult =
            effectCalcSvc:NewSkillDamageEffectResult(
            targetDistanceInfo.gridPos,
            targetDistanceInfo.targetID,
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
        )

        skillResult:SetSkillEffectScopeResult(scopeResult)

        if eTarget:HasMonsterID() then
            local currentHP = eTarget:Attributes():GetCurrentHP()
            if currentHP <= 0 then
                sMonsterShowLogic:AddMonsterDeadMark(eTarget)
            end
        end

        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
        skillEffectResultContainer:AddEffectResult(skillResult)

        table.insert(tResults, skillResult)
    end

    return tResults
end
