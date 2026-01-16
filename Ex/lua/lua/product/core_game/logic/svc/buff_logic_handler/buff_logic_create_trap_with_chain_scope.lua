---@class BuffLogicCreateTrapWithChainScope:BuffLogicBase 创建陷阱的buff
_class("BuffLogicCreateTrapWithChainScope", BuffLogicBase)
BuffLogicCreateTrapWithChainScope = BuffLogicCreateTrapWithChainScope

function BuffLogicCreateTrapWithChainScope:Constructor(buffInstance, logicParam)
    self._trapID = logicParam.trapID
    self._useScopeType = logicParam.useScopeType or 0
    self._useScopeParam = logicParam.useScopeParam or {}

    self._addMulAttackPercent = logicParam.addMulAttackPercent or 0
    self._addMulAttackStart = logicParam.addMulAttackStart or 0
    self._addMulAttackEnd = logicParam.addMulAttackEnd or 0

    self._useCfgScope = logicParam.useCfgScope or {}
    self._useOwnerElement = logicParam.useOwnerElement or 0
end

function BuffLogicCreateTrapWithChainScope:DoLogic(notify)
    ---@type Entity
    local ownerEntity = self._buffInstance:Entity()
    local petEntity
    if ownerEntity:HasPet() then
        petEntity = ownerEntity
    elseif ownerEntity:HasSummoner() then
        --这里是buff
        local buffSkillHolder = ownerEntity:GetSummonerEntity()
        --这个是buff的super,才是pet
        if buffSkillHolder and buffSkillHolder:HasSuperEntity() then
            petEntity = buffSkillHolder:SuperEntityComponent():GetSuperEntity()
        end
    end

    if not petEntity then
        Log.error('BuffLogicCreateTrapWithChainScope not find petEntity, ownerEntity')
        return
    end

    ---@type BuffComponent
    local buffComponent = petEntity:BuffComponent()
    local saveChainSkillID = buffComponent:GetBuffValue("SavePetChainScope")
    --如果没有连锁技范围  就不召唤机关
    if not saveChainSkillID or saveChainSkillID == 0 then
        return
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    local scopeFinalList = {}
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    --不使用连锁的范围计算，使用挂载者当前坐标和配置的范围类型计算
    if self._useScopeType ~= 0 then
        local curPos = ownerEntity:GetGridPosition()
        local curBodyArea = ownerEntity:BodyArea():GetArea()

        ---@type SkillScopeCalculator
        local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
        --获取怪物 周围一圈
        -- local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.SquareRing, {1, 0}, curPos, curBodyArea)
        local scopeResult =
            scopeCalculator:ComputeScopeRange(self._useScopeType, self._useScopeParam, curPos, curBodyArea)
        local attackRange = scopeResult:GetAttackRange()
        table.appendArray(scopeFinalList, attackRange)
    elseif table.count(self._useCfgScope) > 0 then
        local curPos = ownerEntity:GetGridPosition()
        local curBodyArea = ownerEntity:BodyArea():GetArea()
        ---获取范围类型和范围参数
        local scopeType = 0
        local scopeParam = {}
        local cfgScope = self._useCfgScope[saveChainSkillID]
        if cfgScope then
            scopeType = cfgScope.scopeType
            scopeParam = cfgScope.scopeParam
        else
            ---容错：若配置中没有对应的ID，则去连锁技本身的范围
            ---@type ConfigService
            local configService = self._world:GetService("Config")
            ---@type SkillConfigData
            local skillConfigData = configService:GetSkillConfigData(saveChainSkillID)
            scopeType = skillConfigData:GetSkillScopeType()
            scopeParam = skillConfigData:GetSkillScopeParam()
        end

        ---计算范围
        ---@type SkillScopeCalculator
        local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
        local scopeResult = scopeCalculator:ComputeScopeRange(scopeType, scopeParam, curPos, curBodyArea)
        local attackRange = scopeResult:GetAttackRange()
        table.appendArray(scopeFinalList, attackRange)
    else
        local curPos = ownerEntity:GetGridPosition()

        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(saveChainSkillID)

        ---计算范围
        ---@type SkillScopeResult
        local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, curPos, ownerEntity)
        local chainScope = scopeResult:GetAttackRange()

        for _, grid in ipairs(chainScope) do
            if utilData:IsValidPiecePos(grid) then
                table.insert(scopeFinalList, grid)
            end
        end
    end

    ---@type AttributesComponent
    local attrCmpt = petEntity:Attributes()
    --使用星灵的攻击赋值
    local petAttack = attrCmpt:GetAttribute("Attack")
    local exElementParam = attrCmpt:GetAttribute("ExElementParam")
    local boardCmpt = self._world:GetBoardEntity():Board()

    if self._addMulAttackPercent > 0 then
        local saveFinalChainRate = buffComponent:GetBuffValue("SaveFinalChainRate")
        if saveFinalChainRate > self._addMulAttackEnd then
            saveFinalChainRate = self._addMulAttackEnd
        end

        local addMul = (saveFinalChainRate - self._addMulAttackStart) * self._addMulAttackPercent
        if addMul > 0 then
            petAttack = (addMul + 1) * petAttack
        end
    end

    local initAttributes = {}
    if self._useOwnerElement == 1 then
        initAttributes["Element"] = attrCmpt:GetAttribute("Element")
    end

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local eIds = {}
    local result = BuffResultCreateTrapWithChainScope:New(eIds)
    for _, grid in ipairs(scopeFinalList) do
        local trapEntity = trapServiceLogic:CreateTrap(self._trapID, grid, Vector2(0, 0), false, initAttributes,
            ownerEntity)
        if trapEntity then
            ---@type AttributesComponent
            local attributeComponent = trapEntity:Attributes()
            attributeComponent:Modify("Attack", petAttack)
            attributeComponent:Modify("ExElementParam", exElementParam)
            table.insert(eIds, trapEntity:GetID())

            --检查格子上的单位如果可以触发机关就立即触发
            local es =
                boardCmpt:GetPieceEntities(
                    grid,
                    function(e)
                        return e:HasMonsterID() or e:Team()
                    end
                )
            for _, target in ipairs(es) do
                local triggerTraps, triggerResults = trapServiceLogic:CalcTrapTriggerSkill(trapEntity, target)
                if triggerTraps then
                    for i, trap in ipairs(triggerTraps) do
                        local skillResult = triggerResults[i]
                        result:AddTrapSkillResult(trap:GetID(), skillResult, target:GetID())
                    end
                end
            end
        end
    end

    return result
end
