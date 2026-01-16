--[[
    MonsterMoveGridByParam = 189, --怪物按配置的参数连线移动
]]

_class("SkillEffectCalc_MonsterMoveGridByParam", Object)
---@class SkillEffectCalc_MonsterMoveGridByParam: Object
SkillEffectCalc_MonsterMoveGridByParam = SkillEffectCalc_MonsterMoveGridByParam

function SkillEffectCalc_MonsterMoveGridByParam:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type UtilCalcServiceShare
    self._utilCalcSvc = self._world:GetService("UtilCalc")

    ---@type TriggerService
    self._triggerSvc = self._world:GetService("Trigger")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveGridByParam:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())

    --获取目标
    local targetID = nil
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()
    if table.count(targetIDList) >= 1 then
        --怪物移动的目标只有一个（Team）
        targetID = targetIDList[1]
    end
    if not targetID or targetID == -1 then
        Log.fatal("Need Target SkillID", skillEffectCalcParam:GetSkillID())
    end

    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")

    ---@type SkillEffectParam_MonsterMoveGridByParam
    local param = skillEffectCalcParam.skillEffectParam
    self.skillID = skillEffectCalcParam.skillID
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    local movePath = self:_FindMovePath(casterEntity, targetEntity, param)

    ---@type MoveGridByParamResult[]
    local posWalkResultList = {}

    local isCasterDead = false
    if #movePath ~= 0 then
        local oldPosList = {}
        for _, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MoveGridByParamResult
            local walkRes = MoveGridByParamResult:New()

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, pos)
            casterEntity:SetGridPosition(pos)
            casterEntity:SetGridDirection(pos - posSelf)

            table.insert(posWalkResultList, walkRes)
            walkRes:SetWalkPos(pos)
            --self._triggerSvc:Notify(NTEffect156MoveOneGridBegin:New(casterEntity))
            ---处理到达一个格子的处理
            self:_OnArrivePos(casterEntity, walkRes, param, targetEntity)
            --self._triggerSvc:Notify(NTEffect156MoveOneGridEnd:New(casterEntity))
            table.insert(oldPosList, pos)
            if casterEntity:HasDeadMark() then
                isCasterDead = true
                break
            end
        end
        if param:IsResetGrid() then
            local newPosList = sBoard:SupplyPieceList(oldPosList)
            ---@type Entity
            local boardEntity = self._world:GetBoardEntity()
            ---@type BoardComponent
            local boardCmpt = boardEntity:Board()
            boardCmpt:FillPieces(newPosList)
            for i, walkRes in ipairs(posWalkResultList) do
                local newPos = newPosList[i]
                walkRes:SetNewGridType(newPos.color)
            end
        end
    end
    local casterPos = casterEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    local dir = targetPos - casterPos
    casterEntity:SetGridDirection(dir)

    local result = SkillEffectMonsterMoveGridByParamResult:New(posWalkResultList, isCasterDead)
    return { result }
end

---@param casterEntity Entity
---@param targetEntity Entity
---@param param SkillEffectParam_MonsterMoveGridByParam
function SkillEffectCalc_MonsterMoveGridByParam:_FindMovePath(casterEntity, targetEntity, param)
    local movePath = {}

    local pieceTypeList = {}
    local casterPieceType = casterEntity:Element():GetPrimaryType()
    table.insert(pieceTypeList, casterPieceType)

    local partnerIDList = param:GetPartnerIDList()
    local monsterEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, entity in ipairs(monsterEntityList) do
        ---@type MonsterIDComponent
        local monsterIDCmpt = entity:MonsterID()
        local monsterClassID = monsterIDCmpt:GetMonsterClassID()
        if not entity:HasDeadMark() and table.icontains(partnerIDList, monsterClassID) then
            local pieceType = entity:Element():GetPrimaryType()
            table.insert(pieceTypeList, pieceType)
        end
    end

    local moveType = param:GetMoveType()

    if not targetEntity:HasDeadMark() then
        movePath = self._utilCalcSvc:FindPath_MonsterMoveGridByParam2(casterEntity, targetEntity, pieceTypeList, moveType)
    end

    return movePath
end

---@param casterEntity Entity
---@param targetEntity Entity
---@param attackSkillID number
---@return boolean
function SkillEffectCalc_MonsterMoveGridByParam:_CheckCanAttack(casterEntity, targetEntity, attackSkillID)
    if attackSkillID == 0 then
        return false
    end
    local pos = targetEntity:GetGridPosition()

    local bodyArea = casterEntity:BodyArea():GetArea()
    local centerPos = casterEntity:GetGridPosition()
    local casterDir = casterEntity:GetGridDirection()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfig = configSvc:GetSkillConfigData(attackSkillID)
    ---@type SkillScopeCalculator
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local result = skillCalculater:CalcSkillScope(skillConfig, centerPos, casterDir, bodyArea, casterEntity)
    local attackRange = result:GetAttackRange()
    return table.Vector2Include(attackRange, pos)
end

---@param walkRes MoveGridByParamResult
---@param param SkillEffectParam_MonsterMoveGridByParam
function SkillEffectCalc_MonsterMoveGridByParam:_OnArrivePos(casterEntity, walkRes, param, targetEntity)
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    --触发机关
    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(casterEntity, TrapTriggerOrigin.Move)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)
        walkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    --普攻
    local isAttack = self:_CheckCanAttack(casterEntity, targetEntity, param:GetAttackSkillID())
    if isAttack then
        local attackResult = self:_Attack(casterEntity, targetEntity, param)
        walkRes:SetAttackResult(attackResult)
        --普攻伤害完毕，通知叠加buff层数（镇魂座）
        self._triggerSvc:Notify(NTSE189NormalEachAttackEnd:New(casterEntity))
    end

end

---@param casterEntity Entity
---@param targetEntity Entity
---@param param SkillEffectParam_MonsterMoveGridByParam
---@return SkillDamageEffectResult
function SkillEffectCalc_MonsterMoveGridByParam:_Attack(casterEntity, targetEntity, param)
    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local damageStageIndex = param:GetSkillEffectDamageStageIndex()
    local attackPos = casterEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    local percent = param:GetDamagePercent()

    ---@type SkillDamageEffectParam
    local tmpParam = SkillDamageEffectParam:New(
        {
            percent = percent,
            formulaID = param:GetDamageFormulaID(),
            damageStageIndex = damageStageIndex
        }
    )

    local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
        casterEntity,
        attackPos,
        targetEntity,
        targetPos,
        param:GetAttackSkillID(),
        tmpParam,
        SkillEffectType.MonsterMoveGridByParam,
        damageStageIndex
    )

    local skillResult = effectCalcSvc:NewSkillDamageEffectResult(
        targetPos,
        targetEntity:GetID(),
        nTotalDamage,
        listDamageInfo,
        damageStageIndex
    )
    return skillResult
end
