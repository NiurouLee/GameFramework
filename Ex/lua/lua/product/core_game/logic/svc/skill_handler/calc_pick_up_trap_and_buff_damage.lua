--[[
    PickUpTrapAndBuffDamage = 169, --根据选中地点指定机关上的指定buff层数来释放不同的伤害
]]
---@class SkillEffectCalc_PickUpTrapAndBuffDamage: SkillEffectCalc_Base
_class("SkillEffectCalc_PickUpTrapAndBuffDamage", SkillEffectCalc_Base)
SkillEffectCalc_PickUpTrapAndBuffDamage = SkillEffectCalc_PickUpTrapAndBuffDamage

function SkillEffectCalc_PickUpTrapAndBuffDamage:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PickUpTrapAndBuffDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamPickUpTrapAndBuffDamage
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())

    ---@type ActiveSkillPickUpComponent
    local pickupComponent = casterEntity:ActiveSkillPickUpComponent()
    if not pickupComponent then
        Log.error(self._className, "施法者没有ActiveSkillPickupComponent")
        return
    end

    local damageStageIndex = skillEffectParam:GetSkillEffectDamageStageIndex()
    local trapIDList = skillEffectParam:GetTrapIDList()
    local buffID = skillEffectParam:GetBuffID()
    local formulaID = skillEffectParam:GetFormulaID()
    local percentList = skillEffectParam:GetPercentList()
    local skillList = skillEffectParam:GetSkillList()

    --攻击的坐标是点选的坐标
    local pickupPosArray = pickupComponent:GetAllValidPickUpGridPos()
    if #pickupPosArray == 0 then
        Log.error(self._className, "没有点选位置记录")
        return
    end
    local attackPos = pickupPosArray[1]
    local state = 0

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local traps = utilSvc:GetTrapsAtPos(attackPos)
    for _, e in ipairs(traps) do
        local cTrapID = e:Trap():GetTrapID()
        if table.icontains(trapIDList,cTrapID) then
            local buffLayer = buffLogicService:GetBuffLayer(e, buffID)
            state = buffLayer
            break
        end
    end

    if state == 0 then
        return {}
    end

    if state > table.count(skillList) then
        state = table.count(skillList)
    end

    local curPercent = percentList[state]
    local skillID = skillList[state]

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local skillConfigData = configService:GetSkillConfigData(skillID)
    local scopeType = skillConfigData:GetSkillScopeType()
    local scopeParam = skillConfigData:GetSkillScopeParam()
    local centerType = skillConfigData:GetSkillScopeCenterType()
    local targetType = skillConfigData:GetSkillTargetType()

    --
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local casterDirection = casterEntity:GetGridDirection()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local casterDirection = casterEntity:GetGridDirection()

    local scopeResult =
        scopeCalculator:ComputeScopeRange(
        scopeType,
        scopeParam,
        attackPos,
        casterBodyArea,
        casterDirection,
        targetType,
        attackPos,
        casterEntity
    )
    local targetEntityIDArray = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, scopeResult, skillEffectCalcParam.skillID)
    local attackRange = scopeResult:GetAttackRange()
    if targetEntityIDArray then
        local pos2ID = {}
        for _, targetEntityID in ipairs(targetEntityIDArray) do
            scopeResult:AddTargetID(targetEntityID)
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            if targetEntity:HasBodyArea() and targetEntity:HasGridLocation() then
                ---@type GridLocationComponent
                local gridLocationCmpt = targetEntity:GridLocation()
                ---@type BodyAreaComponent
                local bodyAreaCmpt = targetEntity:BodyArea()
                local bodyAreaList = bodyAreaCmpt:GetArea()

                for i, bodyArea in ipairs(bodyAreaList) do
                    local curBodyPos =
                    Vector2(gridLocationCmpt.Position.x + bodyArea.x, gridLocationCmpt.Position.y + bodyArea.y)
                    local posIdx = Vector2.Pos2Index(curBodyPos)
                    if not pos2ID[posIdx] then
                        pos2ID[posIdx] = {}
                    end
                    table.insert(pos2ID[posIdx], targetEntityID)
                end
            end
        end
        for _, gridPos in ipairs(scopeResult:GetAttackRange()) do
            if gridPos._className == 'Vector2' then
                local targetEntityIDs = pos2ID[Vector2.Pos2Index(gridPos)]
                if targetEntityIDs then
                    for _, targetEntityID in ipairs(targetEntityIDs) do
                        scopeResult:AddTargetIDAndPos(targetEntityID, gridPos)
                    end
                end
            end
        end
    end
    ---@type SkillEffectCalcService
    local skillEffectService = self._world:GetService("SkillEffectCalc")

    --计算伤害用的新的
    local damageParam =
        SkillDamageEffectParam:New(
        {
            percent = {curPercent},
            formulaID = formulaID
        }
    )

    local results = {}
    for i = 1, #attackRange do
        local gridPos = attackRange[i]

        --怪物有一个格子在范围内就攻击一次
        local targetID = scopeResult:GetTargetIDByPos(gridPos)
        if targetID then
            local target = self._world:GetEntityByID(targetID)

            local nTotalDamage, listDamageInfo =
                skillEffectService:ComputeSkillDamage(
                casterEntity,
                attackPos,
                target,
                gridPos,
                skillEffectCalcParam:GetSkillID(),
                damageParam,
                SkillEffectType.Damage,
                damageStageIndex
            )

            local skillResult =
                skillEffectService:NewSkillDamageEffectResult(
                gridPos,
                target:GetID(),
                nTotalDamage,
                listDamageInfo,
                damageStageIndex
            )

            table.insert(results, skillResult)
        end
    end
    local transferResult = SkillEffectPickUpTrapAndBuffDamageResult:New(state)
    table.insert(results,transferResult) --results里有伤害结果和这个传递给表现的结果 都不需要执行
    return results
end
