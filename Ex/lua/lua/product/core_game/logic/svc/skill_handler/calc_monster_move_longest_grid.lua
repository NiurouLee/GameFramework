--[[
    MonsterMoveLongestGrid = 156, --怪物选择一条最长的路线，可支持多种选法
]]

_class("SkillEffectCalc_MonsterMoveLongestGrid", Object)
---@class SkillEffectCalc_MonsterMoveLongestGrid: Object
SkillEffectCalc_MonsterMoveLongestGrid = SkillEffectCalc_MonsterMoveLongestGrid

function SkillEffectCalc_MonsterMoveLongestGrid:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type table<Vector2,number[]>
    self._arriveTrapIDs = {}
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveLongestGrid:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()
    local targetID = false
    if table.count(targetIDList) >= 1 then
        targetID = targetIDList[1]
    end
    if not targetID or targetID == -1  then
        Log.fatal("Need Target SkillID",skillEffectCalcParam:GetSkillID())
    end
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")

    ---@type SkillEffectMonsterMoveLongestGridParam
    local param = skillEffectCalcParam.skillEffectParam
    self.skillID = skillEffectCalcParam.skillID
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    local movePath = {}
    if not targetEntity:HasDeadMark() then
        ---@type MonsterMoveLongestGridFindType
        local findType = param:GetFindType()
        if findType== MonsterMoveLongestGridFindType.Normal then
            movePath  = utilCalcSvc:FindMonsterLongestGridPath(casterEntity)
        elseif findType == MonsterMoveLongestGridFindType.MoreSpTraps then
            local trapID = param:GetLineNeedTrapID()
            local lineCount = param:GetLineCount()
            movePath = utilCalcSvc:FindMonsterLongestGridPathByTrapID(casterEntity,lineCount,trapID)
        elseif findType == MonsterMoveLongestGridFindType.Spiral then
            local runCountList = param:GetRunCountList()
            movePath = utilCalcSvc:FindMinosMoveGridPath(casterEntity,runCountList)
        end
    end
    local isCasterDead = false
    ---@type MonsterMoveLongestGridResult[]
    local posWalkResultList = {}
    ---@type SkillDamageEffectResult
    local finalAttackResult = nil
    ---@type SkillSummonTrapEffectResult[]
    local summonTrapResultList ={}
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    if #movePath ~=0 then
        local oldPosList = {}
        for i, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MonsterMoveLongestGridResult
            local walkRes = MonsterMoveLongestGridResult:New()

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, pos)
            casterEntity:SetGridPosition(pos)
            casterEntity:SetGridDirection(pos - posSelf)

            local entityID = casterEntity:GetID()
            table.insert(posWalkResultList,walkRes)
            walkRes:SetWalkPos(pos)
            triggerService:Notify(NTEffect156MoveOneGridBegin:New(casterEntity))
            ---处理到达一个格子的处理
            self:_OnArrivePos(casterEntity,walkRes,param,targetEntity)
            triggerService:Notify(NTEffect156MoveOneGridEnd:New(casterEntity))
            table.insert(oldPosList,pos)
            if casterEntity:HasDeadMark() then
                isCasterDead = true
                break
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
        triggerService:Notify(NTEffect156MoveFinishBegin:New(casterEntity,#movePath))
        summonTrapResultList,finalAttackResult=self:_OnFinished(casterEntity,posWalkResultList,param,oldPosList,targetEntity)
        triggerService:Notify(NTEffect156MoveFinishEnd:New(casterEntity))
    end
    local casterPos = casterEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    local dir = targetPos-casterPos
    casterEntity:SetGridDirection(dir)

    triggerService:Notify(NTEffect156MoveFinish:New(casterEntity))
    local result = SkillEffectMonsterMoveLongestGridResult:New(posWalkResultList,isCasterDead,finalAttackResult,summonTrapResultList)
    return { result }
end
---@param walkRes MonsterMoveLongestGridResult
---@param param SkillEffectMonsterMoveLongestGridParam
function SkillEffectCalc_MonsterMoveLongestGrid:_OnArrivePos(casterEntity,walkRes,param,targetEntity)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local pos = casterEntity:GetGridPosition()
    local trapIDsOnPos=  trapServiceLogic:FindTrapByPos(pos)
    local arriveType = param._arrivePosType
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
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type table<number,boolean>
    local flushTrapIDs = param:GetFlushTrapIDs()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local array = utilSvc:GetTrapsAtPos(pos)
    for _, eTrap in ipairs(array) do
        if eTrap then
            ---@type TrapIDComponent
            local trapIDCmpt = eTrap:TrapID()
            if flushTrapIDs[trapIDCmpt:GetTrapID()] then
                eTrap:Attributes():Modify("HP", 0)
                trapServiceLogic:AddTrapDeadMark(eTrap, param:GetDisableDieSkill())
                walkRes:SetFlushTrapID(eTrap:GetID())
                triggerSvc:Notify(NTMinosAbsorbTrap:New(eTrap))
            end
        end
    end
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(NTEffect156MoveOneGrid:New(casterEntity,pos))

    local nTrapCount = table.count(listTrapWork)
    for i, entityID in ipairs(trapIDsOnPos) do
        ---@type Entity
        local trapEntity = self._world:GetEntityByID(entityID)
        local trapID =trapEntity:TrapID():GetTrapID()
        table.insert(self._arriveTrapIDs, trapID)
        if arriveType ==MonsterMoveLongestGridArrivePosType.NormalAndAttackAtSpTraps then
            local attackTrapIDs = param:GetAttackTrapIDs()
            if attackTrapIDs[trapID] then
                local attackResult = self:_Attack(casterEntity,targetEntity,param)
                walkRes:SetAttackResult(attackResult)
            end
        end
    end
end

---@param param SkillEffectMonsterMoveLongestGridParam
---@param casterEntity Entity
---@return SkillSummonTrapEffectResult[]
function SkillEffectCalc_MonsterMoveLongestGrid:_OnFinished(casterEntity,posWalkResultList,param,oldPosList,targetEntity)
    ---@type  MonsterMoveLongestGridMoveFinishType
    local finishType = param:GetFinishType()
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local summonTrapID = param:GetSummonTrapID()
    ---@type SkillSummonTrapEffectResult[]
    local summonTrapResultArray = {}

    local attackResult = nil
    if finishType == MonsterMoveLongestGridMoveFinishType.ResetGridAndSummonTraps then
        ---@type BoardServiceLogic
        local sBoard = self._world:GetService("BoardLogic")
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
        for i, pos in ipairs(oldPosList) do
            if trapServiceLogic:CanSummonTrapOnPos(pos, summonTrapID) then
                local trapEntity = trapServiceLogic:CreateTrap(
                        summonTrapID,
                        pos,
                        Vector2(0, 1),
                        true,
                        nil,
                        casterEntity,
                        param:IsTransferDisabled()
                )
                ---@type SkillSummonTrapEffectResult
                local summonTrapResult =SkillSummonTrapEffectResult:New(summonTrapID,pos)
                summonTrapResult:SetTrapIDList({trapEntity:GetID()})
                table.insert(summonTrapResultArray,summonTrapResult)
            end
        end
        attackResult = self:_Attack(casterEntity,targetEntity,param,param:GetFinalAttackPercent())
    end
    if finishType == MonsterMoveLongestGridMoveFinishType.NoTrapsSummonTraps then
        local casterPos = casterEntity:GetGridPosition()
        local ringCount = param:GetSummonScopeRingCount()
        local rangeList = ComputeScopeRange.ComputeRange_SquareRing(casterPos,1,ringCount)
        local trapCount = param:GetSummonTrapCount()
        if not table.icontains(self._arriveTrapIDs,summonTrapID) then
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            while #rangeList>0 and trapCount >0 do
                local index = randomSvc:LogicRand(1,#rangeList)
                local pos =rangeList[index]
                if trapServiceLogic:CanSummonTrapOnPos(pos, summonTrapID) then
                    local trapEntity = trapServiceLogic:CreateTrap(
                            summonTrapID,
                            pos,
                            Vector2(0, 1),
                            true,
                            nil,
                            casterEntity,
                            param:IsTransferDisabled()
                    )
                    ---@type SkillSummonTrapEffectResult
                    local summonTrapResult =SkillSummonTrapEffectResult:New(summonTrapID,pos)
                    summonTrapResult:SetTrapIDList({trapEntity:GetID()})
                    table.insert(summonTrapResultArray,summonTrapResult)
                    trapCount= trapCount-1
                end
                table.remove(rangeList,index)
            end
        end
    end
    return summonTrapResultArray,attackResult
end
---@param  casterEntity Entity
---@param  targetEntity Entity
---@param param SkillEffectMonsterMoveLongestGridParam
---@return SkillDamageEffectResult
function SkillEffectCalc_MonsterMoveLongestGrid:_Attack(casterEntity,targetEntity,param,finalAttackPercent)
    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local damageStageIndex = param:GetSkillEffectDamageStageIndex()
    local attackPos = casterEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    local percent = param:GetDamagePercent()
    if finalAttackPercent then
        percent = finalAttackPercent
    end
    ---@type SkillDamageEffectParam
    local tmpParam =  SkillDamageEffectParam:New(
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
            self.skillID,
            tmpParam,
            SkillEffectType.MonsterMoveLongestGrid,
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