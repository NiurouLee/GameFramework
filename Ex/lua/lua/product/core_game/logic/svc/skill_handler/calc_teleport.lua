--[[
    Teleport = 8, ---瞬移    
]]
---@class SkillEffectCalc_Teleport: Object
_class("SkillEffectCalc_Teleport", Object)
SkillEffectCalc_Teleport = SkillEffectCalc_Teleport

function SkillEffectCalc_Teleport:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type number
    self._needDelTrapEntityID = 0

    ---@type Vector2
    self._extraTeleportPos = Vector2.zero

    ---@type number[]
    self._needDelTrapEntityIDs = {}
    ---@type Vector2[]
    self._renderTeleportPath = {}--耶利亚，表现上需要依次跳过这些点
    self._posCalcState = nil--夜王三阶段 记录计算阶段，后续技能范围会根据这个阶段修改
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Teleport:DoSkillEffectCalculator(skillEffectCalcParam)
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
function SkillEffectCalc_Teleport:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillEffectParam_Teleport
    local teleportParam = skillEffectCalcParam.skillEffectParam
    ---@type BaseWorld
    local world = self._world
    ---@type Entity
    local entityWork = world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local posNew = entityWork:GetGridPosition():Clone()
    local dirNew = entityWork:GetGridDirection() -- 逻辑上(0, 0)不应该是有效的角色朝向
    local nTeleportType = skillEffectCalcParam.skillEffectParam:GetTeleportType()
    local userData = skillEffectCalcParam.skillEffectParam:GetUserPoint()
    local checkBlock = skillEffectCalcParam.skillEffectParam:GetCheckBlock()
    local isOnylDeleteBlock = false
    ---计算新位置
    if EnumSkillEffectParam_Teleport.PickUp == nTeleportType then
        posNew = self:_FindTeleportPos_PickUp(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
        ---检查点选的位置是否可以瞬移
        ---@type SkillEffectParam_Teleport
        local telportSEParam = skillEffectCalcParam.skillEffectParam
        if not self:CanTeleport(posNew, telportSEParam, skillEffectCalcParam.casterEntityID) then
            return
        end
    elseif EnumSkillEffectParam_Teleport.User == nTeleportType then
        local point = skillEffectCalcParam.skillEffectParam:GetUserPoint()
        local dir = skillEffectCalcParam.skillEffectParam:GetUserDir()
        posNew = Vector2(point[1], point[2])
        dirNew = Vector2(dir[1], dir[2])
    elseif EnumSkillEffectParam_Teleport.CrossFarest == nTeleportType then
        ---@type SkillEffectCalc_CalEdgePos
        local skillEffectCalc = SkillEffectCalc_CalEdgePos:New(self._world)
        ---@type SkillEffectResultCalEdgePos[]
        local tCalEdgePos = skillEffectCalc:DoSkillEffectCalculator(skillEffectCalcParam)
        local calEdgePos = tCalEdgePos[1]
        local idx = calEdgePos:GetFarestIdx()
        local posArr = calEdgePos:GetPosArr()
        local dirArr = calEdgePos:GetDirArr()
        posNew = posArr[idx]
        dirNew = dirArr[idx]
    elseif EnumSkillEffectParam_Teleport.Forward == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        posNew = self:CalcEndPos(entityWork, eTarget)
        dirNew = Vector2(entityWork:GridLocation().Direction.x, entityWork:GridLocation().Direction.y)
    elseif EnumSkillEffectParam_Teleport.UserPointArray == nTeleportType then
        local posArr = skillEffectCalcParam.skillEffectParam:GetUserPoint()
        local dirArr = skillEffectCalcParam.skillEffectParam:GetUserDir()
        local area = entityWork:BodyArea():GetArea()
        local location = entityWork:GridLocation().Position
        --寻找第一个可以使用的位置
        for i = 1, #posArr do
            local pos = posArr[i]
            local canUse = true
            for i, p in ipairs(area) do
                if location.x + p.x == pos.x and location.y + p.y == pos.y then
                    canUse = false
                    break
                end
            end
            if canUse then
                ---@type Vector2
                posNew = Vector2(pos.x, pos.y)
                local dir = dirArr[i]
                dirNew = Vector2(dir.x, dir.y)
                break
            end
        end
    elseif EnumSkillEffectParam_Teleport.SkillRange_Far == nTeleportType then
        posNew = self:_FindTeleportPos_FarFromPlayer(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
    elseif EnumSkillEffectParam_Teleport.SkillRange_Near == nTeleportType then
        posNew = self:_FindTeleportPos_NearFromPlayer(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
    elseif EnumSkillEffectParam_Teleport.SkillScopePos == nTeleportType then
        if skillEffectCalcParam.skillRange._className and skillEffectCalcParam.skillRange._className == "Vector2" then
            posNew = skillEffectCalcParam.skillRange
        else
            posNew = skillEffectCalcParam.skillRange[1]
        end
        ---容错处理：技能范围可能为空（技能ID29010032中雷雨夜被阻挡的十字范围）
        if not posNew then
            Log.debug("Teleport：pos err，SkillID = ", skillEffectCalcParam.skillID)
            return
        end
    elseif EnumSkillEffectParam_Teleport.TeleportTargetToCasterPos == nTeleportType then
        posNew = skillEffectCalcParam.attackPos
        skillEffectCalcParam.casterEntityID = defenderEntityID
        entityWork = self._world:GetEntityByID(defenderEntityID)
    elseif EnumSkillEffectParam_Teleport.TeleportTargetToPickPos == nTeleportType then
        if defenderEntityID == -1 then
            return
        end
        if skillEffectCalcParam.skillRange[2] then
            posNew = skillEffectCalcParam.skillRange[2]
        else
            return nil
        end

        entityWork = self._world:GetEntityByID(defenderEntityID)
        skillEffectCalcParam.casterEntityID = defenderEntityID
    elseif EnumSkillEffectParam_Teleport.TeleportTargetToFirstPickPos == nTeleportType then
        if defenderEntityID == -1 then
            return
        end
        if skillEffectCalcParam.skillRange[1] then
            posNew = skillEffectCalcParam.skillRange[1]
        else
            return nil
        end

        entityWork = self._world:GetEntityByID(defenderEntityID)
        skillEffectCalcParam.casterEntityID = defenderEntityID
    elseif EnumSkillEffectParam_Teleport.TeleportTargetToSquareRing == nTeleportType then
        posNew = self:FindValidBySquareRing(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
    elseif EnumSkillEffectParam_Teleport.HostOriginalPosSquareRing == nTeleportType then
        local centerPos = skillEffectCalcParam.gridPos
        ---@type BuffComponent
        local buffCmpt = entityWork:BuffComponent()
        if buffCmpt then
            local hostOriPos = buffCmpt:GetBuffValue("HostOriginalPos")
            if hostOriPos then
                centerPos = Vector2(hostOriPos.x, hostOriPos.y)
            end
            buffCmpt:SetBuffValue("HostOriginalPos", nil)
        end
        posNew = self:FindValidBySquareRing(
            skillEffectCalcParam.skillEffectParam,
            entityWork,
            centerPos
        )
    elseif EnumSkillEffectParam_Teleport.TeleportExitBoard == nTeleportType then
        posNew = Vector2(skillEffectCalcParam.gridPos.x + BattleConst.TeleportExitBoardOffsetX, skillEffectCalcParam.gridPos.y + BattleConst.TeleportExitBoardOffsetY)
        isOnylDeleteBlock = true
    elseif EnumSkillEffectParam_Teleport.CurPosBeforeSkillRangeNearest == nTeleportType then
        posNew = self:_FindTeleportPos_CurPosBeforeSkillRangeNearest(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
    elseif EnumSkillEffectParam_Teleport.SkillScopePosFirst == nTeleportType then
        posNew = skillEffectCalcParam.skillRange[1]
    elseif EnumSkillEffectParam_Teleport.TargetPos == nTeleportType then
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(skillEffectCalcParam.targetEntityIDs[1])
        posNew = targetEntity:GetGridPosition()
    elseif EnumSkillEffectParam_Teleport.UseTeleportAndSummonTrapLastResult == nTeleportType then
        ---@type SkillEffectResultContainer
        local routineComponent = entityWork:SkillContext():GetResultContainer()
        ---@type table<number, SkillEffectTeleportAndSummonTrapResult>
        local resultsArray = routineComponent:GetEffectResultsAsArray(SkillEffectType.TeleportAndSummonTrap)
        ---@type  SkillEffectTeleportAndSummonTrapResult
        local result = resultsArray[#resultsArray]
        posNew = result:GetTeleportPos()
    elseif EnumSkillEffectParam_Teleport.SkillScopeRandPos == nTeleportType then
        posNew = self:_FindTeleportPos_Random(entityWork, skillEffectCalcParam.skillRange)
    elseif EnumSkillEffectParam_Teleport.RoninKenshiStep == nTeleportType then
        posNew = self:_RoninKenshiStepPos(entityWork, posNew)
    elseif EnumSkillEffectParam_Teleport.NingKingJump == nTeleportType then
        posNew, dirNew = self:_NightKingJump(entityWork)
    elseif EnumSkillEffectParam_Teleport.TeleportMountForward == nTeleportType then
        posNew, dirNew = self:_FindTeleportPos_MountForward(skillEffectCalcParam, entityWork)
        if not posNew then
            return
        end
    elseif EnumSkillEffectParam_Teleport.UseMountTeleportExtraPos == nTeleportType then
        ---@type SkillEffectResultContainer
        local routineComponent = entityWork:SkillContext():GetResultContainer()
        ---@type table<number, SkillEffectResult_Teleport>
        local resultsArray = routineComponent:GetEffectResultsAsArray(SkillEffectType.Teleport)
        if #resultsArray == 0 then
            return
        end
        ---@type  SkillEffectResult_Teleport
        local result = resultsArray[#resultsArray]
        posNew = result:GetExtraTeleportPos()
        if posNew == Vector2.zero then
            return
        end
    elseif EnumSkillEffectParam_Teleport.CasterGridDirectionForward == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        posNew = self:CalcEndPos(entityWork, eTarget, true, 1)
        dirNew = Vector2(entityWork:GridLocation().Direction.x, entityWork:GridLocation().Direction.y)
    elseif EnumSkillEffectParam_Teleport.TeleportPosByTargetPos == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        dirNew, posNew = self:CalcCasterPosAndDirByTargetPos(entityWork, eTarget)
    elseif EnumSkillEffectParam_Teleport.TeleportTargetToCasterPosValid == nTeleportType then
        skillEffectCalcParam.casterEntityID = defenderEntityID
        entityWork = self._world:GetEntityByID(defenderEntityID)
        if not entityWork then
            Log.fatal("[blink] TeleportTargetToCasterPosValid,no target entity,id: ", defenderEntityID)
            return
        end
        local bIncludeCenter = true
        local bExcludeMovePathEndPos = true
        local bExcludeTeamPos = true
        --local excludeTraps = {2002100,20021001,20021002}
        local excludeTraps = {}
        posNew = self:FindValidBySquareRing(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.attackPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange,
                bIncludeCenter,
                bExcludeMovePathEndPos,
                bExcludeTeamPos,
                excludeTraps
        )
    elseif EnumSkillEffectParam_Teleport.Boss2904001 == nTeleportType then
        posNew = self:CalcBoss2904001Pos(entityWork, skillEffectCalcParam.skillEffectParam)
    elseif EnumSkillEffectParam_Teleport.TargetAroundNearestCaster == nTeleportType then
        posNew = self:_CalcTargetAroundNearestCaster(entityWork, defenderEntityID)
    elseif EnumSkillEffectParam_Teleport.TargetPosWithCasterBody == nTeleportType then
        posNew = self:_CalcTargetPosWithCasterBody(entityWork, defenderEntityID)
    elseif EnumSkillEffectParam_Teleport.PickUpWithPath == nTeleportType then
        posNew = self:_FindTeleportPos_PickUpWithPath(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
        if self._renderTeleportPath and #self._renderTeleportPath > 0 then
            if #self._renderTeleportPath > 1 then
                local finalIndex = #self._renderTeleportPath
                local fromIndex = #self._renderTeleportPath - 1
                dirNew = self._renderTeleportPath[finalIndex] - self._renderTeleportPath[fromIndex]
            else
                local fromPos = entityWork:GetGridPosition()
                dirNew = self._renderTeleportPath[#self._renderTeleportPath] - fromPos
            end
        end
        ---检查点选的位置是否可以瞬移
        ---@type SkillEffectParam_Teleport
        local telportSEParam = skillEffectCalcParam.skillEffectParam
        if not self:CanTeleport(posNew, telportSEParam, skillEffectCalcParam.casterEntityID) then
            return
        end
    elseif EnumSkillEffectParam_Teleport.TargetAroundTrap == nTeleportType then
        posNew = self:_FindTeleportPos_TargetAroundTrap(skillEffectCalcParam, defenderEntityID)
    elseif EnumSkillEffectParam_Teleport.TargetAroundCalcCurBodyAreaAndDirCanDiffusion == nTeleportType then
    elseif EnumSkillEffectParam_Teleport.TrunToTargetOnSite == nTeleportType then
    elseif EnumSkillEffectParam_Teleport.TeleportWithScopeAndTrunToTarget == nTeleportType then
    elseif EnumSkillEffectParam_Teleport.FourHorsemenApproachPlayer == nTeleportType then
        posNew = self:_FindTeleportPos_FourHorsemenApproachPlayer(skillEffectCalcParam, entityWork)
    elseif EnumSkillEffectParam_Teleport.FourHorsemenAvoidPlayer == nTeleportType then
        posNew = self:_FindTeleportPos_FourHorsemenAvoidPlayer(skillEffectCalcParam, entityWork)
    elseif EnumSkillEffectParam_Teleport.BossDriller == nTeleportType then
        posNew,dirNew = self:_FindTeleportPos_BossDriller(skillEffectCalcParam, entityWork)
    elseif EnumSkillEffectParam_Teleport.NightKingTeleportRecordCalcState == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        posNew, dirNew = self:_FindTeleportPos_NightKingTeleportRecordCalcState(skillEffectCalcParam, entityWork,eTarget)
    elseif EnumSkillEffectParam_Teleport.NightKingDoubleCrossTeleport == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        posNew, dirNew = self:_FindTeleportPos_NightKingDoubleCrossTeleport(skillEffectCalcParam, entityWork,eTarget)
    elseif EnumSkillEffectParam_Teleport.NightKingTeleportWithPath == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        posNew, dirNew = self:_FindTeleportPos_NightKingTeleportWithPath(skillEffectCalcParam, entityWork,eTarget)
    elseif EnumSkillEffectParam_Teleport.TargetTeleportSelectPos == nTeleportType then
        ---@type Entity
        local eTarget = self._world:GetEntityByID(defenderEntityID)
        if not eTarget then
            return
        end
        posNew, dirNew = self:_FindTeleportPos_TargetTeleportSelectPos(skillEffectCalcParam, eTarget)
    elseif EnumSkillEffectParam_Teleport.PickUpAndSetDir == nTeleportType then
            posNew = self:_FindTeleportPos_PickUp(
                    skillEffectCalcParam.skillEffectParam,
                    entityWork,
                    skillEffectCalcParam.gridPos,
                    skillEffectCalcParam.skillID,
                    skillEffectCalcParam.skillRange
            )
            ---检查点选的位置是否可以瞬移
            ---@type SkillEffectParam_Teleport
            local telportSEParam = skillEffectCalcParam.skillEffectParam
            if not self:CanTeleport(posNew, telportSEParam, skillEffectCalcParam.casterEntityID) then
                return
            end
            if posNew ~= entityWork:GetGridPosition()then
                dirNew = posNew - entityWork:GetGridPosition()
            end
    elseif EnumSkillEffectParam_Teleport.Boss2905701Move == nTeleportType then
        posNew = self:_FindTeleportPos_Boss2905701Move(entityWork, teleportParam)
    elseif EnumSkillEffectParam_Teleport.Boss2905701BackToPos == nTeleportType then
        posNew = self:_FindTeleportPos_Boss2905701BackToPos(entityWork, teleportParam)
    elseif EnumSkillEffectParam_Teleport.Boss2905701MovePlayerToTrap == nTeleportType then
        posNew = self:_FindTeleportPos_Boss2905701MovePlayerToTrap(entityWork, teleportParam)
    elseif EnumSkillEffectParam_Teleport.SkillRange_FarAndDir == nTeleportType then
        posNew = self:_FindTeleportPos_FarFromPlayer(
                skillEffectCalcParam.skillEffectParam,
                entityWork,
                skillEffectCalcParam.gridPos,
                skillEffectCalcParam.skillID,
                skillEffectCalcParam.skillRange
        )
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = entityWork:ActiveSkillPickUpComponent()
        local pickUpPos = posNew
        if activeSkillPickUpComponent then
            pickUpPos = activeSkillPickUpComponent:GetLastPickUpGridPos()
        end
        ---@type Vector2
        local dir = pickUpPos - entityWork:GetGridPosition()
        dirNew = dir
        if dirNew.x > 0 then
            dirNew.x = 1
        elseif dirNew.x < 0 then
            dirNew.x = -1
        end
        if dirNew.y > 0 then
            dirNew.y = 1
        elseif dirNew.y < 0 then
            dirNew.y = -1
        end
    else
        posNew = skillEffectCalcParam.gridPos
    end

    ---脚下格子
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type BoardServiceLogic
    local boardServiceLogic = world:GetService("BoardLogic")
    ---@type UtilDataServiceShare PlayRoleTeleport
    local utilData = self._world:GetService("UtilData")
    local sourcePos = entityWork:GetGridPosition()
	
    if checkBlock == 1 then
        local isBlock = utilData:IsPosBlock(posNew, BlockFlag.LinkLine)
        if isBlock then
            return
        end
    end

    local isResetDir = skillEffectCalcParam.skillEffectParam:IsResetDirection()
    if isResetDir then
        dirNew = posNew - sourcePos
        if dirNew.x > 0 then
            dirNew.x = 1
        elseif dirNew.x < 0 then
            dirNew.x = -1
        end

        if dirNew.y > 0 then
            dirNew.y = 1
        elseif dirNew.y < 0 then
            dirNew.y = -1
        end
    end

    local colorOld = nil
    if casterEntity:HasPetPstID() or casterEntity:HasTeam() then
        local curSt = self._world:GameFSM():CurStateID()
        if curSt ~= GameStateID.PreviewActiveSkill and curSt ~= GameStateID.PickUpActiveSkillTarget then
            boardServiceLogic:RemoveEntityBlockFlag(casterEntity, sourcePos)
        end
        colorOld = boardServiceLogic:SupplyPieceList({ sourcePos })[1].color
    else
        if sourcePos then
            colorOld = utilData:FindPieceElement(sourcePos)
        end
    end

    local stageIndex = skillEffectCalcParam.skillEffectParam:GetSkillEffectDamageStageIndex()

    ---@type SkillEffectResult_Teleport
    local result = SkillEffectResult_Teleport:New(
            skillEffectCalcParam.casterEntityID,
            sourcePos,
            colorOld,
            posNew,
            dirNew,
            stageIndex
    )
    if self._needDelTrapEntityID ~= 0 then
        result:SetNeedDelTrapEntityID(self._needDelTrapEntityID)
    end

    if self._extraTeleportPos ~= Vector2.zero then
        result:SetExtraTeleportPos(self._extraTeleportPos)
    end

    if #self._needDelTrapEntityIDs > 0 then
        result:SetNeedDelTrapEntityIDs(self._needDelTrapEntityIDs)
    end

    if casterEntity:HasPet() then
        ---@type ConfigService
        local configSvc = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configSvc:GetSkillConfigData(skillEffectCalcParam.skillID)
        if skillConfigData:GetSkillType() == SkillType.Active then
            result:SetTeleportResult_IsPetActiveSkill(true)
        end
    end
    if self._renderTeleportPath and #self._renderTeleportPath > 0 then
        result:SetRenderTeleportPath(self._renderTeleportPath)
    end
    if self._posCalcState then
        result:SetTeleportPosCalcState(self._posCalcState)
    end

    return result
end

---从PickUp组件内获取瞬移位置
---@param skillEffectParam SkillEffectParam_Teleport
---@param entityCaster Entity
---@param posCaster Vector2 技能发起人的位置
---@param nSkillID number 发起的技能ID
---@param skillRangePos Vector2[]  技能范围
function SkillEffectCalc_Teleport:_FindTeleportPos_PickUp(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos)
    local listTargetPos = skillRangePos

    local posReturn = nil
    if #listTargetPos < 1 then
        Log.fatal("[blink] target error")
        posReturn = posCaster
    else
        posReturn = listTargetPos[1]
    end
    return posReturn
end

---通过 nSkillID 来计算瞬移位置，距离目标最远
---@param skillEffectParam SkillEffectParam_Teleport
---@param entityCaster Entity
---@param posCaster Vector2 技能发起人的位置
---@param nSkillID number 发起的技能ID
---@param skillRangePos Vector2[]  技能范围
function SkillEffectCalc_Teleport:_FindTeleportPos_FarFromPlayer(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos)
    local posWork = self:_FindTeleportPos_Comparer(
            skillEffectParam,
            entityCaster,
            posCaster,
            nSkillID,
            skillRangePos,
            AiSortByDistance._ComparerByFar
    )
    return posWork
end

---通过 nSkillID 来计算瞬移位置，距离目标最近
---@param skillEffectParam SkillEffectParam_Teleport
---@param entityCaster Entity
---@param posCaster Vector2 技能发起人的位置
---@param nSkillID number 发起的技能ID
---@param skillRangePos Vector2[] 技能范围
function SkillEffectCalc_Teleport:_FindTeleportPos_NearFromPlayer(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos)
    local posWork = self:_FindTeleportPos_Comparer(
            skillEffectParam,
            entityCaster,
            posCaster,
            nSkillID,
            skillRangePos,
            AiSortByDistance._ComparerByNear
    )
    return posWork
end

function SkillEffectCalc_Teleport:_FindTeleportPos_Comparer(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos,
        comparer,
        onlyEmpty)
    if nil == skillRangePos then
        return posCaster
    end
    local listRangeInPlan = skillRangePos
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posMain = teamEntity:GetGridPosition()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type SortedArray    注意这里的排序函数，不同需求应当不同
    local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, comparer)
    sortPosList:AllowDuplicate()
    for i = 1, #skillRangePos do
        AINewNode.InsertSortedArray(sortPosList, posMain, skillRangePos[i], i)
    end

    local bodyArea = entityCaster:BodyArea():GetArea()
    local nRaceType
    if entityCaster:HasMonsterID() then
        nRaceType = entityCaster:MonsterID():GetMonsterRaceType()
    end

    ---@type BlockFlag
    local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)
    if not nRaceType then
        nBlockRaceType = BlockFlag.LinkLine
    end
    for i = 1, sortPosList:Size() do
        ---@type AiSortByDistance
        local sortPosData = sortPosList:GetAt(i)
        local posWork = sortPosData.data
        if onlyEmpty then
            if boardServiceLogic:IsPosEmptyExceptConveyor(posWork) then
                return posWork
            end
        else
            ---@type Vector2
            local bPosBlock = boardServiceLogic:IsPosBlockByArea(posWork, nBlockRaceType, bodyArea, entityCaster)
            if not bPosBlock then
                return posWork
            end
        end
    end
    return posCaster
end

---计算撞空最终位置
---@param isHit boolean 是否撞击成功
---@param eCaster Entity
---@param eTarget Entity
function SkillEffectCalc_Teleport:CalcEndPos(eCaster, eTarget, dontMoveLR, frontOffset)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local casterEndPos = Vector2.zero
    local cGridLocation = eCaster:GridLocation()
    casterEndPos.x = cGridLocation.Position.x
    casterEndPos.y = cGridLocation.Position.y
    -- ---确定朝向
    local preDashDir = { Vector2(0, -1), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 0) } --上右下左位置时的方向
    local casterDir = cGridLocation.Direction
    local idx = 1
    for i, v in ipairs(preDashDir) do
        if v.x == casterDir.x and v.y == casterDir.y then
            idx = i
            break
        end
    end
    local isHit = false
    if eTarget then
        --有目标表示撞击
        isHit = true
    end
    if isHit and (not dontMoveLR) then
        --这玩意儿叫调整LRPos，但其实他是计算施法者最终位置的逻辑步骤，即使不"adjust left/right pos"
        self:AdjustLRPos(idx, casterEndPos, eTarget:GridLocation().Position, eCaster)
    end
    local boardMaxX = boardServiceLogic:GetCurBoardMaxX()
    local boardMaxY = boardServiceLogic:GetCurBoardMaxY()

    --这里原先写死成2是为了2x2的boss？
    frontOffset = frontOffset or 2
    if idx == 1 then
        if isHit then
            casterEndPos.y = eTarget:GridLocation().Position.y + 1
        else
            casterEndPos.y = 1
        end
    elseif idx == 2 then
        if isHit then
            casterEndPos.x = eTarget:GridLocation().Position.x + 1
        else
            casterEndPos.x = 1
        end
    elseif idx == 3 then
        if isHit then
            casterEndPos.y = eTarget:GridLocation().Position.y - frontOffset
        else
            casterEndPos.y = boardMaxY - 1
        end
    else
        if isHit then
            casterEndPos.x = eTarget:GridLocation().Position.x - frontOffset
        else
            casterEndPos.x = boardMaxX - 1
        end
    end
    return casterEndPos
end

---@private
---调整左右位置
---@param casterEntity Entity
function SkillEffectCalc_Teleport:AdjustLRPos(idx, casterEndPos, targetPos, casterEntity)
    local offset = 1

    if casterEntity:HasBodyArea() then
        local bodyAreaComponent = casterEntity:BodyArea()
        local bodyAreaArray = bodyAreaComponent:GetArea()
        local firstRowBodyArea = {}
        for _, areaPos in ipairs(bodyAreaArray) do
            if 0 == areaPos.x then
                table.insert(firstRowBodyArea, areaPos)
            end
        end

        offset = #firstRowBodyArea
    end

    -- 这里直接令施法者等宽位移，因功能需求为“到达面前”，而没有“行进最少格数”的要求
    if idx == 1 or idx == 3 then
        if targetPos.x < casterEndPos.x then
            casterEndPos.x = casterEndPos.x - offset
        elseif targetPos.x >= casterEndPos.x + offset then
            casterEndPos.x = casterEndPos.x + offset
        end
    else
        if targetPos.y < casterEndPos.y then
            casterEndPos.y = casterEndPos.y - offset
        elseif targetPos.y >= casterEndPos.y + offset then
            casterEndPos.y = casterEndPos.y + offset
        end
    end
end

---通过 nSkillID 来计算瞬移位置，距离目标最近
---@param skillEffectParam SkillEffectParam_Teleport
---@param entityCaster Entity
---@param posCaster Vector2 技能发起人的位置
---@param nSkillID number 发起的技能ID
---@param skillRangePos Vector2[] 技能范围
function SkillEffectCalc_Teleport:FindValidBySquareRing(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos,
        bIncludeCenter,
        excludeMovePathEndPos,
        bExcludeTeamPos,
        excludeTraps
)
    local findRoundCount = 8
    local offset = { 1, 0, -1 }
    ---@type BodyAreaComponent
    local bodyCmpt = entityCaster:BodyArea()
    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    local excludePosList = {}
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if excludeMovePathEndPos then
        ---@type LogicChainPathComponent
        local logicChainPathCmpt = teamEntity:LogicChainPath()
        local logicPath = logicChainPathCmpt:GetLogicChainPath()
        if logicPath then
            local endPos = logicPath[#logicPath]
            table.insert(excludePosList, endPos)
        end
    end
    if bExcludeTeamPos then
        ---@type LogicChainPathComponent
        local logicChainPathCmpt = teamEntity:LogicChainPath()
        local logicPath = logicChainPathCmpt:GetLogicChainPath()
        local bLinkMove = false
        if logicPath then
            if #logicPath > 0 then
                bLinkMove = true
            end
        end
        if not bLinkMove then
            local teamPos = teamEntity:GetGridPosition()
            table.insert(excludePosList, teamPos)
        end
    end
    if excludeTraps then
        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        for _, trapID in ipairs(excludeTraps) do
            local trapPosList = trapSvc:FindTrapPosByTrapID(trapID)
            if #trapPosList > 0 then
                table.appendArray(excludePosList, trapPosList)
            end
        end
    end

    if bIncludeCenter then
        if (not table.icontains(excludePosList, posCaster)) and utilDataService:IsValidPiecePos(posCaster) and utilDataService:IsMonsterCanTel2TargetPos(entityCaster, posCaster) then
            return posCaster
        end
    end
    for i = 1, findRoundCount do
        ---@type Vector2[]
        local posList = ComputeScopeRange.ComputeRange_SquareRing(posCaster, bodyCmpt:GetAreaCount(), i)
        for _, pos in ipairs(posList) do
            if (not table.icontains(excludePosList, pos)) and utilDataService:IsValidPiecePos(pos) and utilDataService:IsMonsterCanTel2TargetPos(entityCaster, pos) then
                return pos
            end
        end
    end
    return nil
end

---技能范围内距离玩家最近的目标（顺时针查找），如果自己当前位置与目标的距离等于选出来最近的坐标，优先自己当前位置。6基础上改的
---@param skillEffectParam SkillEffectParam_Teleport
---@param entityCaster Entity
---@param posCaster Vector2 技能发起人的位置
---@param nSkillID number 发起的技能ID
---@param skillRangePos Vector2[] 技能范围
function SkillEffectCalc_Teleport:_FindTeleportPos_CurPosBeforeSkillRangeNearest(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos)
    local posWork = self:_FindTeleportPos_Comparer(
            skillEffectParam,
            entityCaster,
            posCaster,
            nSkillID,
            skillRangePos,
            AiSortByDistance._ComparerByNear
    )

    --默认目标是队伍
    ---@type Entity
    local entityTeam = self._world:Player():GetLocalTeamEntity()
    local posTeam = entityTeam:GetGridPosition()

    local curPos = entityCaster:GetGridPosition()
    local curPosToTargetPosDistance = Vector2.Distance(curPos, posTeam)
    local workPosToTargetPosDistance = Vector2.Distance(posWork, posTeam)
    --如果当前位置距离目标的距离和移动以后距离目标的距离想等，那么不移动
    if curPosToTargetPosDistance <= workPosToTargetPosDistance then
        return curPos
    end

    return posWork
end

function SkillEffectCalc_Teleport:_FindTeleportPos_Random(entityCaster, skillRangePos)
    ---@type UtilDataServiceShare
    local utilDataService = self._world:GetService("UtilData")
    local ret = skillRangePos[1]
    local range = {}
    for i, pos in ipairs(skillRangePos) do
        if utilDataService:IsMonsterCanTel2TargetPos(entityCaster, pos) then
            range[#range + 1] = pos
        end
    end
    if #range > 0 then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        ret = range[randomSvc:LogicRand(1, #range)]
    end
    return ret
end

---@param pos Vector2
---@param teleportSEParam SkillEffectParam_Teleport
---@param casterEntityID number
function SkillEffectCalc_Teleport:CanTeleport(pos, teleportSEParam, casterEntityID)
    local trapID = teleportSEParam:GetTrapID()
    --若没配置机关ID，则不检测，直接返回可瞬移
    if trapID == 0 then
        return true
    end

    --检测配置的机关ID，是否和点选格子上的机关ID相同，若相同则可瞬移
    local boardCmpt = self._world:GetBoardEntity():Board()
    local traps = boardCmpt:GetPieceEntities(
            pos,
            function(e)
                local isOwner = false
                --配置上保证了被选中的机关一定有SummonerComponent，因此不考虑没有该组件的机关
                --注：这里没有SummonerComponent时的结果与SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget不一致
                if e:HasSummoner() then
                    if e:Summoner():GetSummonerEntityID() == casterEntityID then
                        isOwner = true
                    else
                        --[[
                            修改前代码是只判断机关是不是施法者自己的
                            但N24加入的阿克希亚也可以召唤别人的机关，并需要被认为是施法者的
                            考虑到该判断原先的目的是防止吸收【被世界boss化的光灵】和【黑拳赛的对方光灵】所属机关
                            这里添加判断：当施法者是光灵时，自己队伍内的其他光灵召唤的机关，也视为施法者自己召唤的
                        ]]
                        local summonerID = e:Summoner():GetSummonerEntityID()
                        local casterEntity = self._world:GetEntityByID(casterEntityID)
                        if casterEntity:HasPet() then
                            local cTeam = casterEntity:Pet():GetOwnerTeamEntity():Team()
                            local entities = cTeam:GetTeamPetEntities()
                            for _, petEntity in ipairs(entities) do
                                if summonerID == petEntity:GetID() then
                                    isOwner = true
                                    break
                                end
                            end
                        end
                    end
                else
                    isOwner = true
                end
                return isOwner and e:HasTrap() and e:Trap():GetTrapID() == trapID and not e:HasDeadMark()
            end
    )
    if #traps > 0 then
        ---@type Entity
        local entity = traps[1]
        self._needDelTrapEntityID = entity:GetID()
        return true
    end

    return false
end

function SkillEffectCalc_Teleport:_RoninKenshiStepPos(entityWork, posNew)
    --[[
            浪人剑客专属逻辑，配合下图阅读（@为自身当前位置）

            O O X O O
            O ! X ! O   如果玩家在O位置上，瞬移至与O最近的!位置
            X X @ X X   其他情况不发生瞬移
            O ! X ! O
            O O X O O

            该需求保证落点一定是合法位置，关卡内不会出现挡住自己的东西
            程序保底处理为落点无法行进则原地
        ]]
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local v2TeamPos = teamEntity:GetGridPosition()

    local v2CasterPos = entityWork:GetGridPosition()
    local rangeLT = {
        Vector2.New(v2CasterPos.x - 2, v2CasterPos.y + 2),
        Vector2.New(v2CasterPos.x - 2, v2CasterPos.y + 1),
        Vector2.New(v2CasterPos.x - 1, v2CasterPos.y + 2)
    }
    local rangeRT = {
        Vector2.New(v2CasterPos.x + 2, v2CasterPos.y + 2),
        Vector2.New(v2CasterPos.x + 2, v2CasterPos.y + 1),
        Vector2.New(v2CasterPos.x + 1, v2CasterPos.y + 2)
    }
    local rangeLB = {
        Vector2.New(v2CasterPos.x - 2, v2CasterPos.y - 2),
        Vector2.New(v2CasterPos.x - 2, v2CasterPos.y - 1),
        Vector2.New(v2CasterPos.x - 1, v2CasterPos.y - 2)
    }
    local rangeRB = {
        Vector2.New(v2CasterPos.x + 2, v2CasterPos.y - 2),
        Vector2.New(v2CasterPos.x + 2, v2CasterPos.y - 1),
        Vector2.New(v2CasterPos.x + 1, v2CasterPos.y - 2)
    }
    -- 先确定理论位置，然后判断合法性，如果不合法置为nil
    local v2Pos = posNew
    if table.icontains(rangeLT, v2TeamPos) then
        v2Pos = Vector2.New(v2CasterPos.x - 1, v2CasterPos.y + 1)
    elseif table.icontains(rangeRT, v2TeamPos) then
        v2Pos = Vector2.New(v2CasterPos.x + 1, v2CasterPos.y + 1)
    elseif table.icontains(rangeLB, v2TeamPos) then
        v2Pos = Vector2.New(v2CasterPos.x - 1, v2CasterPos.y - 1)
    elseif table.icontains(rangeRB, v2TeamPos) then
        v2Pos = Vector2.New(v2CasterPos.x + 1, v2CasterPos.y - 1)
    end

    if v2Pos ~= posNew then
        local nRaceType = MonsterRaceType.Land
        if entityWork:HasMonsterID() then
            nRaceType = entityWork:MonsterID():GetMonsterRaceType()
        end
        local bodyArea = entityWork:BodyArea():GetArea()
        ---@type BlockFlag
        local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)
        ---@type BoardServiceLogic
        local boardServiceLogic = self._world:GetService("BoardLogic")
        local bPosBlock = boardServiceLogic:IsPosBlockByArea(v2Pos, nBlockRaceType, bodyArea, entityWork)
        if not bPosBlock then
            posNew = v2Pos
        end
    end
    return posNew
end

---@return Vector2,Vector2
function SkillEffectCalc_Teleport:_NightKingJump(casterEntity)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type Vector2
    local teamPos = teamEntity:GetGridPosition()
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ----@type UtilScopeCalcServiceShare
    local utilScopeCalcSvc = self._world:GetService("UtilScopeCalc")
    local nearPos = nil
    local nearDis = 10000
    local dir
    local dirList = { DirectionType.Up, DirectionType.Left, DirectionType.Down, DirectionType.Right }
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local bodyArea, blockFlag = sBoard:RemoveEntityBlockFlag(casterEntity, casterPos)
    for x = 1, 10 do
        ---@type Vector2[]
        local posList = utilScopeCalcSvc:GetTargetSquareRing(teamEntity:GetID(), x)
        for i, newPos in ipairs(posList) do
            local dis = Vector2.Distance(newPos, casterPos)
            if dis <= nearDis and not utilDataSvc:IsPosBlock(newPos, BlockFlag.MonsterLand) then
                local bFind = false
                for _, dirType in ipairs(dirList) do
                    local rangList = utilScopeCalcSvc:GetNightKing_Skill1A(casterEntity, newPos, dirType)
                    if table.Vector2Include(rangList, teamPos) and utilScopeCalcSvc:IsNewBodyAreaPosValidByDirType(newPos, dirType) then
                        dir = utilScopeCalcSvc:GetDirByDirType(dirType)
                        bFind = true
                        break
                    end
                end
                if bFind then
                    nearPos = newPos
                    nearDis = dis
                end
            end
        end
        if nearPos ~= nil then
            break
        end
    end
    sBoard:SetEntityBlockFlag(casterEntity, casterPos, blockFlag)
    return nearPos, dir
end

---@param entityWork Entity
function SkillEffectCalc_Teleport:_FindTeleportPos_MountForward(skillEffectCalcParam, entityWork)
    if not entityWork:HasRide() then
        return
    end

    ---@type RideComponent
    local rideCmpt = entityWork:Ride()
    local mountID = rideCmpt:GetMountID()
    ---@type Entity
    local mountEntity = self._world:GetEntityByID(mountID)

    --移除骑乘
    ---@type RideServiceLogic
    local rideSvc = self._world:GetService("RideLogic")
    rideSvc:ResetBodyArea(entityWork)
    rideSvc:RemoveRide(entityWork:GetID(), mountID)

    --计算位置
    local endPos, dir = self:_CalcMountEndPos(mountEntity)

    --检测阿尔法是否需要瞬移到其他位置
    self:_CheckAlphaPos(entityWork, mountEntity, endPos)

    --更换瞬移对象
    skillEffectCalcParam.casterEntityID = mountID
    entityWork = mountEntity

    --获取冲锋路径上的机关ID
    local trapID = skillEffectCalcParam.skillEffectParam:GetTrapID()
    self:_FindTrapEntityIDInTeleportRange(mountEntity, endPos, trapID)

    return endPos, dir
end

---@param mountEntity Entity
---@param ringCount number
function SkillEffectCalc_Teleport:GetPosListAroundBodyArea(entity, ringCount)
    local v2SelfGridPos = entity:GetGridPosition()
    local bodyArea = entity:BodyArea():GetArea()
    local v2SelfDir = entity:GetGridDirection()

    ---@type UtilScopeCalcServiceShare
    local scopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(scopeSvc)
    local scopeResult = scopeCalc:ComputeScopeRange(
            SkillScopeType.AroundBodyArea,
            { 0, ringCount },
            v2SelfGridPos,
            bodyArea,
            v2SelfDir,
            SkillTargetType.Monster,
            v2SelfGridPos
    )

    return scopeResult:GetAttackRange()
end

---@param rideEntity Entity
---@param mountEntity Entity
function SkillEffectCalc_Teleport:_FindRideTeleportPos(rideEntity, mountEntity)
    local posRide = rideEntity:GetGridPosition()
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")

    --十字范围
    local pos = mountEntity:GetGridPosition()
    local bodyArea = mountEntity:BodyArea():GetArea()
    local skillRangePos = ComputeScopeRange.ComputeRange_CrossScope(pos, #bodyArea, 1)
    local posWork = self:_FindTeleportPos_Comparer(
            nil,
            rideEntity,
            posRide,
            nil,
            skillRangePos,
            AiSortByDistance._ComparerByFar,
            true
    )
    if posWork ~= posRide then
        return posWork
    end

    --方形圈
    local maxLen = boardSvc:GetCurBoardMaxLen()
    for i = 1, maxLen do
        local skillRangePos = self:GetPosListAroundBodyArea(mountEntity, i)
        local posWork = self:_FindTeleportPos_Comparer(
                nil,
                rideEntity,
                posRide,
                nil,
                skillRangePos,
                AiSortByDistance._ComparerByFar,
                true
        )
        if posWork ~= posRide then
            return posWork
        end
    end

    return posRide
end

---@param mountEntity Entity
---@param petEntity Entity
function SkillEffectCalc_Teleport:_CalcMountDir(mountEntity, petEntity)
    local posMain = petEntity:GetGridPosition()
    local endPos = mountEntity:GetGridPosition()
    local bodyArea = mountEntity:BodyArea():GetArea()
    local posList = {}
    for _, v in ipairs(bodyArea) do
        table.insert(posList, endPos + v)
    end
    --确定朝向
    local idx = 1
    local preDashDir = { Vector2(0, -1), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 0) } --上右下左位置时的方向
    for _, pos in ipairs(posList) do
        local mountDir = Vector2.Normalize(posMain - pos)
        for i, v in ipairs(preDashDir) do
            if v.x == mountDir.x and v.y == mountDir.y then
                return i
            end
        end
    end
    return idx
end

---@param mountEntity Entity
function SkillEffectCalc_Teleport:_CalcMountEndPos(mountEntity)
    ---@type Entity
    local petEntity = self._world:Player():GetCurrentTeamEntity()
    local posMain = petEntity:GetGridPosition()

    --计算位置
    ---@type Vector2
    local endPos = Vector2.zero
    endPos.x = mountEntity:GetGridPosition().x
    endPos.y = mountEntity:GetGridPosition().y
    local dir = GameHelper.ComputeLogicDir(posMain - endPos)
    local idx = self:_CalcMountDir(mountEntity, petEntity)

    local petBodySqure = 1 --光灵身形大小的开方
    local mountBodySqure = 2 --贝塔身形大小的开方，此处骑乘贝塔为四格怪，故直接用2
    if idx == 1 then
        endPos.y = posMain.y + petBodySqure
    elseif idx == 2 then
        endPos.x = posMain.x + petBodySqure
    elseif idx == 3 then
        endPos.y = posMain.y - mountBodySqure
    else
        endPos.x = posMain.x - mountBodySqure
    end
    return endPos, dir
end

function SkillEffectCalc_Teleport:_CheckAlphaPos(entityWork, mountEntity, endPos)
    local oriPos = entityWork:GetGridPosition()
    local needTeleport = false
    local bodyArea = mountEntity:BodyArea():GetArea()
    for _, v in ipairs(bodyArea) do
        local curPos = endPos + v
        if curPos == oriPos then
            needTeleport = true
            break
        end
    end
    if not needTeleport then
        self._extraTeleportPos = oriPos
        return
    end

    self._extraTeleportPos = self:_FindRideTeleportPos(entityWork, mountEntity)
end

---@param mountEntity Entity
---@param endPos Vector2
---@param trapID number
function SkillEffectCalc_Teleport:_FindTrapEntityIDInTeleportRange(mountEntity, endPos, trapID)
    ---@type Vector2
    local startPos = Vector2.zero
    startPos.x = mountEntity:GetGridPosition().x
    startPos.y = mountEntity:GetGridPosition().y

    if startPos == endPos then
        return
    end

    local bodyAreaArray = mountEntity:BodyArea():GetArea()

    local expandArea = {}
    for i, v in ipairs(bodyAreaArray) do
        local p = startPos + v
        table.insert(expandArea, p)
    end

    local casterDirX = endPos.x - startPos.x
    local casterDirY = endPos.y - startPos.y
    local length = math.max(math.abs(casterDirX), math.abs(casterDirY))
    if casterDirX ~= 0 then
        casterDirX = casterDirX / math.abs(casterDirX)
    end
    if casterDirY ~= 0 then
        casterDirY = casterDirY / math.abs(casterDirY)
    end

    local teleportRange = {}
    for _, p in ipairs(bodyAreaArray) do
        local center_x = startPos.x + p.x
        local center_y = startPos.y + p.y
        for index = 1, length do
            local curPos = Vector2(center_x + casterDirX * index, center_y + casterDirY * index)
            table.insert(teleportRange, curPos)
        end
    end
    teleportRange = table.unique(teleportRange)

    for _, pos in ipairs(teleportRange) do
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local trapEntityID = utilDataSvc:GetTrapAtPosByTrapID(pos, trapID)
        table.insert(self._needDelTrapEntityIDs, trapEntityID)
    end
end

---@param casterEntity Entity
---@param targetEntity Entity
function SkillEffectCalc_Teleport:CalcCasterPosAndDirByTargetPos(casterEntity, targetEntity)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local targetPos = targetEntity:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local dirTypeList = { DirectionType.Up, DirectionType.Down, DirectionType.Left, DirectionType.Right }

    local targetDir
    for i, dirType in ipairs(dirTypeList) do
        local range = utilScopeSvc:Monster2903501FindPlayer(dirType, casterPos, casterBodyArea)
        if table.Vector2Include(range, targetPos) then
            targetDir = dirType
            break
        end
    end
    local pos, dir
    if targetDir == DirectionType.Down then
        dir = Vector2(0, -1)
        if casterPos.x >= targetPos.x then
            pos = Vector2(targetPos.x, targetPos.y + 1)
        else
            pos = Vector2(targetPos.x - 1, targetPos.y + 1)
        end
    elseif targetDir == DirectionType.Up then
        dir = Vector2(0, 1)
        if casterPos.x >= targetPos.x then
            pos = Vector2(targetPos.x, targetPos.y - 2)
        else
            pos = Vector2(targetPos.x - 1, targetPos.y - 2)
        end
    elseif targetDir == DirectionType.Left then
        dir = Vector2(-1, 0)
        if casterPos.y < targetPos.y then
            pos = Vector2(targetPos.x + 1, targetPos.y - 1)
        else
            pos = Vector2(targetPos.x + 1, targetPos.y)
        end
    elseif targetDir == DirectionType.Right then
        dir = Vector2(1, 0)
        if casterPos.y < targetPos.y then
            pos = Vector2(targetPos.x - 2, targetPos.y - 1)
        else
            pos = Vector2(targetPos.x - 2, targetPos.y)
        end
    end
    return dir, pos
end

---@param entityCaster Entity
---@param skillEffectParam SkillEffectParam_Teleport
function SkillEffectCalc_Teleport:CalcBoss2904001Pos(entityCaster, skillEffectParam)
    --场上肯定是有队伍的，且黑拳赛肯定是没boss的
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local v2TeamPos = eLocalTeam:GetGridPosition()
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScope:GetSkillScopeCalc()
    local scopeParamParser = SkillScopeParamParser:New()
    local skipRangeParam = scopeParamParser:ParseScopeParam(SkillScopeType.SquareRing, { 1 })
    local skipRangeScope = scopeCalc:ComputeScopeRange(
            SkillScopeType.SquareRing,
            skipRangeParam,
            entityCaster:GetGridPosition(),
            entityCaster:BodyArea():GetArea(),
            entityCaster:GetGridPosition(),
            SkillTargetType.Team,
            entityCaster:GetGridPosition(),
            entityCaster
    )

    --local targetSelector = SkillScopeTargetSelector:New(self._world)
    --local targetArray = targetSelector:DoSelectSkillTarget(entityCaster, SkillTargetType.Team, skipRangeScope)
    --如果Team在skipRangeScope以内，返回结果为不瞬移
    if table.Vector2Include(skipRangeScope:GetAttackRange() or {}, v2TeamPos) then
        return entityCaster:GetGridPosition()
    end
    --反之，计算一个四格十字的范围，判断是否以正方向接近玩家，这个范围暂时是不可配的
    local aroundBodyAmplifyCrossParam = scopeParamParser:ParseScopeParam(SkillScopeType.AroundBodyAmplifyCross, { 2, 9 })
    local aroundBodyAmplifyCrossScope = scopeCalc:ComputeScopeRange(
            SkillScopeType.AroundBodyAmplifyCross,
            aroundBodyAmplifyCrossParam,
            entityCaster:GetGridPosition(),
            entityCaster:BodyArea():GetArea(),
            entityCaster:GetGridPosition(),
            SkillTargetType.Team,
            entityCaster:GetGridPosition(),
            entityCaster
    )

    local v2NearestGridPos = entityCaster:GetGridPosition()
    local v2CasterCenterPos = entityCaster:GetGridPosition()
    local distance = Vector2.Distance(v2NearestGridPos, v2TeamPos)
    for _, v2Body in ipairs(entityCaster:BodyArea():GetArea()) do
        local v2 = v2Body + v2CasterCenterPos
        local dis = Vector2.Distance(v2, v2TeamPos)
        if dis < distance then
            v2NearestGridPos = v2
            distance = dis
        end
    end

    local dir = v2TeamPos - v2NearestGridPos
    if dir.x > 0 then
        dir.x = 1
    end
    if dir.x < 0 then
        dir.x = -1
    end
    if dir.y > 0 then
        dir.y = 1
    end
    if dir.y < 0 then
        dir.y = -1
    end

    if table.Vector2Include(aroundBodyAmplifyCrossScope:GetAttackRange() or {}, v2TeamPos) then
        return self:_CalcBoss2904001NearestTeleportPos(entityCaster, dir, v2TeamPos, skillEffectParam:GetBoss2904001CrossMaxLength())
    else
        return self:_CalcBoss2904001NearestTeleportPos(entityCaster, dir, v2TeamPos, skillEffectParam:GetBoss2904001RotatedCrossMaxLength())
    end
end

---@param entityCaster Entity
---@param dir Vector2
---@param targetPos Vector2
---@param maxLength number
---@return Vector2
function SkillEffectCalc_Teleport:_CalcBoss2904001NearestTeleportPos(entityCaster, dir, targetPos, maxLength)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local nRaceType = MonsterRaceType.Land
    if entityCaster:HasMonsterID() then
        nRaceType = entityCaster:MonsterID():GetMonsterRaceType()
    end
    ---@type BlockFlag
    local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)
    local casterCenterPos = entityCaster:GetGridPosition()
    local bodyArea = entityCaster:BodyArea():GetArea()
    local minDistance = Vector2.Distance(casterCenterPos, targetPos)
    local minDisPos = casterCenterPos
    for offset = 1, maxLength do
        local centerPos = casterCenterPos + dir * offset
        local dis = self:_CalcNearestDistance(centerPos, bodyArea, targetPos)
        if dis < minDistance then
            local bPosBlock = self:_IsPosBlockByArea(centerPos, nBlockRaceType, bodyArea, entityCaster)
            if not bPosBlock then
                minDistance = dis
                minDisPos = centerPos
            end
        end
    end

    return minDisPos
end

---@param centerPos Vector2
---@param bodyArea Vector2[]
---@param targetPos Vector2
function SkillEffectCalc_Teleport:_CalcNearestDistance(centerPos, bodyArea, targetPos)
    local distance = Vector2.Distance(targetPos, centerPos)
    for _, v2Body in ipairs(bodyArea) do
        local v2 = centerPos + v2Body
        local dis = Vector2.Distance(targetPos, v2)
        distance = math.min(distance, dis)
    end
    return distance
end

---BoardServiceLogic:IsPosBlockByArea在一个位置有自己但没有机关时，返回的是该位置被阻挡，这里复制之后改了一下
function SkillEffectCalc_Teleport:_IsPosBlockByArea(pos, blockFlag, listArea, entityExcept)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local ret = false
    for i = 1, #listArea do
        local posWork = pos + listArea[i]
        if not utilDataSvc:IsValidPiecePos(posWork) then
            return true
        end
        if utilDataSvc:IsPosBlock(posWork, blockFlag) then
            if not entityExcept then
                return true
            end
            local playerBlock = false
            if #(utilDataSvc:FindEntityByPosAndType(posWork, EnumTargetEntity.Pet)) > 0 and (not entityExcept:HasPet()) then
                playerBlock = true
            end
            local monsterBlock = false
            local entityMonster = utilDataSvc:GetMonsterAtPos(posWork)
            if entityMonster and (entityMonster ~= entityExcept) then
                monsterBlock = true
            end
            local trapBlock = false
            local entityTrap = utilDataSvc:GetTrapsAtPos(posWork)
            if #entityTrap ~= 0 and (not table.icontains(entityTrap, entityExcept)) then
                trapBlock = true
            end

            local isBlock = playerBlock or monsterBlock or trapBlock
            if isBlock then
                return true
            end
        end
    end
    return false
end

function SkillEffectCalc_Teleport:_CalcTargetAroundNearestCaster(entityWork, defenderEntityID)
    local posNew
    ---@type Entity
    local eTarget = self._world:GetEntityByID(defenderEntityID)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local maxLen = boardServiceLogic:GetCurBoardMaxLen()
    local casterPos = entityWork:GetGridPosition()
    local casterBodyArea = entityWork:BodyArea():GetArea()
    local targetPos = eTarget:GetGridPosition()
    local bodyArea = eTarget:BodyArea():GetArea()
    local block = BlockFlag.LinkLine

    local bodyX = {}
    local bodyY = {}
    for _, area in ipairs(bodyArea) do
        local workPos = targetPos + area
        if not table.intable(bodyX, workPos.x) then
            table.insert(bodyX, workPos.x)
        end
        if not table.intable(bodyY, workPos.y) then
            table.insert(bodyY, workPos.y)
        end
    end

    for i = 1, maxLen do
        local skillRangePos = self:GetPosListAroundBodyArea(eTarget, i)
        -- local posList = {}
        local crossPosList = {} --十字优先
        local xPosList = {} --x位置

        for _, pos in ipairs(skillRangePos) do
            ---@type Vector2
            local bPosBlock = boardServiceLogic:IsPosBlockByArea(pos, block, casterBodyArea, entityWork)
            if not bPosBlock then
                --table.insert(posList, pos)
                if table.intable(bodyX, pos.x) or table.intable(bodyY, pos.y) then
                    table.insert(crossPosList, pos)
                else
                    table.insert(xPosList, pos)
                end
            end
        end
        if table.count(crossPosList) > 0 then
            table.sort(
                crossPosList,
                function(a, b)
                    local disA = Vector2.Distance(casterPos, a)
                    local disB = Vector2.Distance(casterPos, b)
                    return disA < disB
                end
            )
            posNew = crossPosList[1]
            break
        end
        if table.count(xPosList) > 0 then
            table.sort(
                xPosList,
                function(a, b)
                    local disA = Vector2.Distance(casterPos, a)
                    local disB = Vector2.Distance(casterPos, b)
                    return disA < disB
                end
            )
            posNew = xPosList[1]
            break
        end
    end
    return posNew
end

function SkillEffectCalc_Teleport:_CalcTargetPosWithCasterBody(entityWork, defenderEntityID)
    local posNew
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    ---@type Entity
    local targetEntity = self._world:GetEntityByID(defenderEntityID)
    local targetPos = targetEntity:GetGridPosition()

    local casterPos = entityWork:GetGridPosition()
    local bodyArea = entityWork:BodyArea():GetArea()
    local casterBodyPosList = {}
    for _, area in ipairs(bodyArea) do
        local workPos = area + casterPos
        table.insert(casterBodyPosList, workPos)
    end

    local block = BlockFlag.MonsterLand
    local posList = {}
    --优先判断施法者中心
    local notBlockPosCount = 0
    for _, area in ipairs(bodyArea) do
        local workPos = area + targetPos
        --自己会阻挡自己
        -- if workPos ~= targetPos and not utilDataSvc:IsPosBlock(workPos, BlockFlag.MonsterLand) then
        --IsPosBlockByArea的判断也有问题  entityWork原地会被自己判断为阻挡
        -- if workPos ~= targetPos and not boardServiceLogic:IsPosBlockByArea(workPos, block, bodyArea, entityWork) then
        --阻挡=该位置不在自己的身形内 and 施法者在该位置被阻挡
        local isCasterBodyPos = table.intable(casterBodyPosList, workPos)
        local isBlock = utilDataSvc:IsPosBlock(workPos, BlockFlag.MonsterLand)
        if isBlock and utilDataSvc:IsPosHasSpTrap(workPos, TrapType.BadGrid) then
            isBlock = false
        end
        if isCasterBodyPos or (workPos ~= targetPos and not isBlock) then
            notBlockPosCount = notBlockPosCount + 1
        end
    end
    if notBlockPosCount == table.count(bodyArea) - 1 then
        posNew = targetPos
        return posNew
    end

    --第二判断施法者身形的每一个在目标位置是否可以瞬移
    posList = {}
    for _, area in ipairs(bodyArea) do
        local workPosCenter = targetPos - area

        --以每个点位中心再计算一次阻挡
        notBlockPosCount = 0
        for i, v in ipairs(bodyArea) do
            local workPos = v + workPosCenter
            --if workPos ~= targetPos and not boardServiceLogic:IsPosBlockByArea(workPos, block, bodyArea, entityWork) then
            local isCasterBodyPos = table.intable(casterBodyPosList, workPos)
            local isBlock = utilDataSvc:IsPosBlock(workPos, BlockFlag.MonsterLand)
            if isBlock and utilDataSvc:IsPosHasSpTrap(workPos, TrapType.BadGrid) then
                isBlock = false
            end
            if isCasterBodyPos or (workPos ~= targetPos and not isBlock) then
                notBlockPosCount = notBlockPosCount + 1
            end
        end

        if notBlockPosCount == table.count(bodyArea) - 1 then
            table.insert(posList, workPosCenter)
            break
        end
    end

    posNew = posList[1]
    return posNew
end

---从PickUp组件内获取瞬移位置
---@param skillEffectParam SkillEffectParam_Teleport
---@param entityCaster Entity
---@param posCaster Vector2 技能发起人的位置
---@param nSkillID number 发起的技能ID
---@param skillRangePos Vector2[]  技能范围
function SkillEffectCalc_Teleport:_FindTeleportPos_PickUpWithPath(
        skillEffectParam,
        entityCaster,
        posCaster,
        nSkillID,
        skillRangePos)
    local listTargetPos = skillRangePos

    local posReturn = nil
    local pathReturn = {}
    if #listTargetPos < 1 then
        Log.fatal("[blink] target error")
        posReturn = posCaster
        table.insert(pathReturn,posCaster)
    else
        for index, pathPos in ipairs(listTargetPos) do
            table.insert(pathReturn,pathPos)
        end
        posReturn = listTargetPos[#listTargetPos]
    end
    self._renderTeleportPath = pathReturn
    return posReturn
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Teleport:_FindTeleportPos_TargetAroundTrap(skillEffectCalcParam, defenderEntityID)
    ---@type SkillEffectParam_Teleport
    local telportSkillEffectParam = skillEffectCalcParam.skillEffectParam
    ---脚下格子
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local posNew = casterEntity:GetGridPosition()
    --参数
    local trapID = skillEffectCalcParam.skillEffectParam:GetTrapID()

    ---@type Entity
    local eTarget = self._world:GetEntityByID(defenderEntityID)
    --目标周围1圈
    local skillRangePos = self:GetPosListAroundBodyArea(eTarget, 1)

    local validPosList = {}

    --检查范围内是否有指定机关
    ---@type TrapServiceLogic
    local trapServerLogic = self._world:GetService("TrapLogic")
    local tarpPosList = trapServerLogic:FindTrapPosByTrapID(trapID)
    for _, pos in ipairs(tarpPosList) do
        if table.intable(skillRangePos, pos) then
            table.insert(validPosList, pos)
        end
    end

    if table.intable(validPosList, posNew) then
        --当前位置就在范围内，原地不动
    else
        --有效范围还需要判断是否阻挡
        local canTeleportPosList = {}
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        for _, pos in ipairs(validPosList) do
            if not utilDataSvc:IsPosBlock(pos, BlockFlag.MonsterLand) then
                table.insert(canTeleportPosList, pos)
            end
        end

        if table.count(canTeleportPosList) == 0 then
            --没有空位置 原地不动
        else
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            local randomIndex = randomSvc:LogicRand(1, #canTeleportPosList)
            local randomPos = canTeleportPosList[randomIndex]
            posNew = randomPos
        end
    end

    return posNew
end

---@class SkillEffectCalc_Teleport_HorsemenInfo
---@field entity Entity
---@field sortIndex number
---@field distance number

---@param skillEffectCalcParam SkillEffectCalcParam
---@return SkillEffectCalc_Teleport_HorsemenInfo[]
function SkillEffectCalc_Teleport:_FourHorsemen_GetAllHorsemenInfo(skillEffectCalcParam, ignoreCaster)
    local casterEntityID = skillEffectCalcParam.casterEntityID

    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local v2LocalTeamPos = eLocalTeam:GetGridPosition()
    ---@type SkillEffectParam_Teleport
    local effectParam = skillEffectCalcParam.skillEffectParam
    local teMonster = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)

    ---@type SkillEffectCalc_Teleport_HorsemenInfo[]
    local teHorsemenInfo = {}
    for index, e in ipairs(teMonster) do
        local monsterClassID = e:MonsterID():GetMonsterClassID()
        if table.icontains(effectParam:GetHorsemenMonsterClassID(), monsterClassID) then
            if not e:HasDeadMark() then
                local pos = e:GetGridPosition()
                local distance = Vector2.Distance(pos, v2LocalTeamPos)
                if (not ignoreCaster) or (e:GetID() ~= casterEntityID) then
                    table.insert(teHorsemenInfo, {
                        entity = e,
                        sortIndex = #teHorsemenInfo,
                        distance = distance
                    })
                end
            end
        end
    end

    return teHorsemenInfo
end

---输入已经根据距离排序的数据，获得距离排序第一的所有entity(最远或最近)
---@param teHorsemenInfo SkillEffectCalc_Teleport_HorsemenInfo[]
---@return Entity[]
function SkillEffectCalc_Teleport:_FourHorsemen_GetFirstDistanceHorsemenEntities(teHorsemenInfo)
    ---@type Entity[]
    local tNearestHorsemenEntity = {}
    local distance = teHorsemenInfo[1].distance
    for _, info in ipairs(teHorsemenInfo) do
        if info.distance == distance then
            table.insert(tNearestHorsemenEntity, info.entity)
        end
    end
    return tNearestHorsemenEntity
end

---@param center Vector2
function SkillEffectCalc_Teleport:_FourHorsemen_GetFirstValidTeleportPosAround(teleportEntity, center)
    local nRaceType = MonsterRaceType.Land
    if teleportEntity:HasMonsterID() then
        nRaceType = teleportEntity:MonsterID():GetMonsterRaceType()
    end
    ---@type BlockFlag
    local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")
    local ringMax = lsvcBoard:GetCurBoardRingMax()
    for _, v in ipairs(ringMax) do
        local pos = center + Vector2.New(v[1], v[2])
        if utilData:IsValidPiecePos(pos) and (not lsvcBoard:IsPosBlockByArea(pos, nBlockRaceType, teleportEntity:BodyArea():GetArea())) then
            return pos
        end
    end
end

function SkillEffectCalc_Teleport:_FindTeleportPos_FourHorsemenApproachPlayer(skillEffectCalcParam, teleportEntity)
    ---@type Vector2
    local posNew
    local teHorsemenInfo = self:_FourHorsemen_GetAllHorsemenInfo(skillEffectCalcParam)
    if #teHorsemenInfo == 0 then
        posNew = teleportEntity:GetGridPosition():Clone()
        return posNew
    end
    table.sort(teHorsemenInfo, function (a, b)
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end

        return a.sortIndex < b.sortIndex
    end)
    ---@type Entity[]
    local tNearestHorsemenEntity = self:_FourHorsemen_GetFirstDistanceHorsemenEntities(teHorsemenInfo)
    -- 纯防护：没有任何骑士
    if #tNearestHorsemenEntity == 0 then
        posNew = teleportEntity:GetGridPosition():Clone()
        return posNew
    end
    -- 若距离玩家最近的骑士只有自己，则原地位移
    if (tNearestHorsemenEntity[1]:GetID() == teleportEntity:GetID()) and (#tNearestHorsemenEntity == 1) then
        posNew = teleportEntity:GetGridPosition():Clone()
        return posNew
    end

    -- 对每一个距离相等的其他骑士计算一个最佳位置，从这些位置中选择距离玩家最近的点执行瞬移
    -- 保证实际执行时尽可能包围玩家
    local tNonSelfNearestHorsemenEntity = {}
    for _, e in ipairs(tNearestHorsemenEntity) do
        if e:GetID() ~= teleportEntity:GetID() then
            table.insert(tNonSelfNearestHorsemenEntity, e)
        end
    end

    local tFreeCandidatePos = {}
    local tBlockedCandidatePos = {}
    for _, targetHorseman in ipairs(tNonSelfNearestHorsemenEntity) do
        local tFreePos = {}
        local tBlockPos = {}

        local centerPos = targetHorseman:GetGridPosition()
        local dir = { Vector2.New(-1, 1), Vector2.New(-1, -1), Vector2.New(1, 1), Vector2.New(1, -1), }
        local nRaceType = MonsterRaceType.Land
        if teleportEntity:HasMonsterID() then
            nRaceType = teleportEntity:MonsterID():GetMonsterRaceType()
        end
        ---@type BlockFlag
        local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)
        ---@type BoardServiceLogic
        local boardServiceLogic = self._world:GetService("BoardLogic")
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        ---@type Entity
        local eLocalTeam = self._world:Player():GetLocalTeamEntity()
        local v2LocalTeamPos = eLocalTeam:GetGridPosition()
        for _, v2 in ipairs(dir) do
            local pos = centerPos + v2
            local isValidPos = utilData:IsValidPiecePos(pos)
            local isBlocked = self:_IsPosBlockByArea(pos, nBlockRaceType, teleportEntity:BodyArea():GetArea())
            if isValidPos then
                if isBlocked then
                    table.insert(tBlockPos, { pos = pos, sortIndex = #tBlockPos, distance = Vector2.Distance(pos, v2LocalTeamPos)})
                else
                    table.insert(tFreePos, { pos = pos, sortIndex = #tFreePos, distance = Vector2.Distance(pos, v2LocalTeamPos)})
                end
            end
        end

        if #tFreePos > 0 then
            --table.appendArray(tFreeCandidatePos, tFreePos)
            for _, info in ipairs(tFreePos) do
                if not table.Vector2Include(tFreeCandidatePos, info) then
                    table.insert(tFreeCandidatePos, info)
                end
            end
        elseif #tBlockPos > 0 then
            for _, info in ipairs(tBlockPos) do
                if not table.Vector2Include(tBlockedCandidatePos, info) then
                    table.insert(tBlockedCandidatePos, info)
                end
            end
        end
    end

    table.sort(tFreeCandidatePos, function (a, b)
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end

        return a.sortIndex < b.sortIndex
    end)

    table.sort(tBlockedCandidatePos, function (a, b)
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end

        return a.sortIndex < b.sortIndex
    end)

    if #tFreeCandidatePos > 0 then
        posNew = tFreeCandidatePos[1].pos
    elseif #tBlockedCandidatePos > 0 then
        local center = tBlockedCandidatePos[1].pos
        local nearestPos = self:_FourHorsemen_GetFirstValidTeleportPosAround(teleportEntity, center)
        posNew = nearestPos
    end

    return posNew or teleportEntity:GetGridPosition():Clone()
end

local function fourHorsemenAvoidPlayerGenTheoryEdgeGrid(a, b, calcByX)
    local v2 = Vector2.zero
    v2.x = calcByX and a or b
    v2.y = calcByX and b or a

    return v2
end

function SkillEffectCalc_Teleport:_FindTeleportPos_FourHorsemenAvoidPlayer(skillEffectCalcParam, teleportEntity)
    ---@type Vector2
    local posNew = teleportEntity:GetGridPosition():Clone()
    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local v2LocalTeamPos = eLocalTeam:GetGridPosition()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local dir = { Vector2.up, Vector2.down, Vector2.left, Vector2.right, }
    local destPosCandidates = {}

    local teHorsemenInfo = self:_FourHorsemen_GetAllHorsemenInfo(skillEffectCalcParam)
    local tHorsemenGridPosition = {}
    for _, info in ipairs(teHorsemenInfo) do
        table.insert(tHorsemenGridPosition, info.entity:GetGridPosition())
    end
    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")
    local maxLen = math.max(lsvcBoard:GetCurBoardMaxX(), lsvcBoard:GetCurBoardMaxY())
    for _, v2 in ipairs(dir) do
        local pos = v2LocalTeamPos
        for i = 1, maxLen do
            local p = v2LocalTeamPos + v2 * i
            if utilData:IsValidPiecePos(p) then
                pos = p
            else
                break
            end
        end
        table.insert(destPosCandidates, pos)
    end

    if table.Vector2Include(destPosCandidates, teleportEntity:GetGridPosition()) then
        -- 特殊情况：自己已经站在了四个位置之一，原地结束
    else
        local nRaceType = MonsterRaceType.Land
        if teleportEntity:HasMonsterID() then
            nRaceType = teleportEntity:MonsterID():GetMonsterRaceType()
        end
        ---@type BlockFlag
        local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)
        local bodyArea = teleportEntity:BodyArea():GetArea()
        local blockedDestPosCandidates = {}
        -- 优先找到没有四骑士占据且未阻挡的位置，直接站上去
        for _, candidatePos in ipairs(destPosCandidates) do
            if (not table.Vector2Include(tHorsemenGridPosition, candidatePos)) then
                if (not lsvcBoard:IsPosBlockByArea(candidatePos, nBlockRaceType, bodyArea, teleportEntity)) then
                    posNew = candidatePos
                    break
                else
                    table.insert(blockedDestPosCandidates, candidatePos)
                end
            end
        end

        -- 特殊情况：所有没有四骑士占据的位置都有其他阻挡
        -- 首先尝试从版边寻找一个位置
        -- 注：判断阻挡时有一个例外：阻挡者是自己时视为位置有效
        local currentPosSatisfying = false
        if (posNew == teleportEntity:GetGridPosition()) then
            ---@type UtilScopeCalcServiceShare
            local utilScope = self._world:GetService("UtilScopeCalc")
            local edgeMax = 0
            local calcByX = false
            local currentMaxX = lsvcBoard:GetCurBoardMaxX()
            local currentMaxY = lsvcBoard:GetCurBoardMaxY()
            if currentMaxX > currentMaxY then
                edgeMax = currentMaxX
                calcByX = true
            else
                edgeMax = currentMaxY
                calcByX = false
            end
            local tEdgeGridInfo = {}
            local tEdgeGrids = {}
            for i = 1, currentMaxX do
                local data = utilScope:GetMinMaxGridYByGridX(i)
                local min = data.min
                local max = data.max
                if min then
                    local v2 = fourHorsemenAvoidPlayerGenTheoryEdgeGrid(i, min, true)

                    if utilData:IsValidPiecePos(v2) and (not self:_IsPosBlockByArea(v2, nBlockRaceType, bodyArea, teleportEntity)) then
                        table.insert(tEdgeGridInfo, {sortIndex = #tEdgeGridInfo, v2 = v2, distance = Vector2.Distance(v2, v2LocalTeamPos)})
                        table.insert(tEdgeGrids, v2)
                    end
                end
                if max then
                    local v2 = fourHorsemenAvoidPlayerGenTheoryEdgeGrid(i, max, true)

                    if utilData:IsValidPiecePos(v2) and (not self:_IsPosBlockByArea(v2, nBlockRaceType, bodyArea, teleportEntity)) then
                        table.insert(tEdgeGridInfo, {sortIndex = #tEdgeGridInfo, v2 = v2, distance = Vector2.Distance(v2, v2LocalTeamPos)})
                        table.insert(tEdgeGrids, v2)
                    end
                end
            end
            for i = 1, currentMaxY do
                local data = utilScope:GetMinMaxGridXByGridY(i)
                local min = data.min
                local max = data.max
                if min then
                    local v2 = fourHorsemenAvoidPlayerGenTheoryEdgeGrid(i, min, false)

                    if utilData:IsValidPiecePos(v2) and (not self:_IsPosBlockByArea(v2, nBlockRaceType, bodyArea, teleportEntity)) then
                        table.insert(tEdgeGridInfo, {sortIndex = #tEdgeGridInfo, v2 = v2, distance = Vector2.Distance(v2, v2LocalTeamPos)})
                        table.insert(tEdgeGrids, v2)
                    end
                end
                if max then
                    local v2 = fourHorsemenAvoidPlayerGenTheoryEdgeGrid(i, max, false)

                    if utilData:IsValidPiecePos(v2) and (not self:_IsPosBlockByArea(v2, nBlockRaceType, bodyArea, teleportEntity)) then
                        table.insert(tEdgeGridInfo, {sortIndex = #tEdgeGridInfo, v2 = v2, distance = Vector2.Distance(v2, v2LocalTeamPos)})
                        table.insert(tEdgeGrids, v2)
                    end
                end
            end

            if #tEdgeGridInfo > 0 then
                table.sort(tEdgeGridInfo, function (a, b)
                    if a.distance ~= b.distance then
                        return a.distance < b.distance
                    end

                    return a.sortIndex < b.sortIndex
                end)

                posNew = tEdgeGridInfo[1].v2 or posNew
            else
                -- 如果整个版面的所有版边格都不可用，这段逻辑作为最终的保底——逆时针选取有效格
                -- 关卡配置上保证最终一定不会没格子，程序兜底是原地瞬移
                if (#blockedDestPosCandidates > 0) then
                    local centerPos = blockedDestPosCandidates[1]
                    local aroundPos = self:_FourHorsemen_GetFirstValidTeleportPosAround(teleportEntity, centerPos)
                    posNew = aroundPos or posNew
                end
            end
        end
    end

    return posNew or teleportEntity:GetGridPosition():Clone()
end

function SkillEffectCalc_Teleport:_FindTeleportPos_BossDriller(skillEffectCalcParam, teleportEntity)
    ---@type Vector2
    local posNew = teleportEntity:GetGridPosition():Clone()
    ---@type Vector2
    local dirNew = teleportEntity:GetGridDirection():Clone()

    --钻探者专用，在角落时需要移动，简单处理
    local movePosDic = {
        {pos = Vector2(1,1),toPos = Vector2(2,1)},
        {pos = Vector2(9,1),toPos = Vector2(8,1)},
        {pos = Vector2(1,9),toPos = Vector2(2,9)},
        {pos = Vector2(9,9),toPos = Vector2(8,9)},
    }
    for index, movePosInfo in ipairs(movePosDic) do
        if posNew == movePosInfo.pos then
            posNew = movePosInfo.toPos
            break
        end
    end
    --朝向
    local boardCenter = Vector2(5,5)
    if posNew == boardCenter then
        ---@type Entity
        local entityTeam = self._world:Player():GetLocalTeamEntity()
        local targetPos = entityTeam:GetGridPosition()
        dirNew = self:_BossDriller_CalcDir(targetPos,posNew,dirNew)
    else
        dirNew = self:_BossDriller_CalcDir(boardCenter,posNew,dirNew)
    end

    return posNew,dirNew
end
function SkillEffectCalc_Teleport:_BossDriller_CalcDir(targetPos,casterPos,oriDir)
    local dirNew = oriDir:Clone()
    if casterPos == targetPos then
    else
        local posOff = targetPos - casterPos
        local xDis = math.abs(posOff.x)
        local yDis = math.abs(posOff.y)
        if xDis > yDis then
            if posOff.x > 0 then
                dirNew = Vector2.right
            else
                dirNew = Vector2.left
            end
        elseif xDis < yDis then
            if posOff.y > 0 then
                dirNew = Vector2.up
            else
                dirNew = Vector2.down
            end
        else
            if posOff.y > 0 then
                dirNew = Vector2.up
            elseif posOff.y < 0 then
                dirNew = Vector2.down
            elseif posOff.x > 0 then
                dirNew = Vector2.right
            elseif posOff.x < 0 then
                dirNew = Vector2.left
            end
        end
    end
    return dirNew
end

function SkillEffectCalc_Teleport:_FindTeleportPos_NightKingTeleportRecordCalcState(skillEffectCalcParam, teleportEntity,targetEntity)
    ---@type UtilDataServiceShare PlayRoleTeleport
    local utilDataService = self._world:GetService("UtilData")
    ---@type Vector2
    local posNew = teleportEntity:GetGridPosition():Clone()
    ---@type Vector2
    local dirNew = teleportEntity:GetGridDirection():Clone()
    local casterPos = teleportEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    self._posCalcState = 0
    local bodyAreaCount = 1
    local onlyMaxRing = true--先只在第二圈找
    local secondRingPosList = ComputeScopeRange.ComputeRange_SquareRing(casterPos, bodyAreaCount, 2,onlyMaxRing)

    ---@type SortedArray
    local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    sortPosList:AllowDuplicate()
    for i = 1, #secondRingPosList do
        AINewNode.InsertSortedArray(sortPosList, targetPos, secondRingPosList[i], i)--boss两圈上距离目标（队伍）最近的格子为理想终点
    end
    ---@type AiSortByDistance
    local nearestPosData = sortPosList:GetAt(1)
    if nearestPosData then
        local nearestPos = nearestPosData:GetPosData()
        --看理想终点是否可用
        if utilDataService:IsValidPiecePos(nearestPos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, nearestPos) then
            posNew = nearestPos
            self._posCalcState = 1--第一种情况，理想终点 boss第二圈上里玩家最近的点
        else
            local secondValidPosList = {}
            for index, secondRingPos in ipairs(secondRingPosList) do
                local crossDis = math.abs(secondRingPos.x - nearestPos.x) + math.abs(secondRingPos.y - nearestPos.y)
                if crossDis == 1 then
                    if utilDataService:IsValidPiecePos(secondRingPos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, secondRingPos) then
                        table.insert(secondValidPosList,secondRingPos)
                    end
                end
            end
            if #secondValidPosList > 0 then
                posNew = secondValidPosList[1]
                self._posCalcState = 2--第二种情况，在boss第二圈中，且在理想终点周围十字四格上的可用格子
            else
                local firstRingPosList = ComputeScopeRange.ComputeRange_SquareRing(casterPos, bodyAreaCount, 1,onlyMaxRing)
                ---@type SortedArray
                local firstRingSortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
                firstRingSortPosList:AllowDuplicate()
                for i = 1, #firstRingPosList do
                    AINewNode.InsertSortedArray(firstRingSortPosList, targetPos, firstRingPosList[i], i)
                end
                ---@type AiSortByDistance
                local firstRingNearestPosData = sortPosList:GetAt(1)
                if firstRingNearestPosData then
                    local firstRingNearestPos = firstRingNearestPosData:GetPosData()
                    if utilDataService:IsValidPiecePos(firstRingNearestPos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, firstRingNearestPos) then
                        posNew = firstRingNearestPos
                        self._posCalcState = 3--第三种情况 第一圈内，距离玩家最近的格子
                    else
                        self._posCalcState = 4--第四种情况 原地
                    end
                else
                    --
                end
            end
        end
    else
        --
    end
    if posNew ~= teleportEntity:GetGridPosition()then
        dirNew = posNew - teleportEntity:GetGridPosition()
    end
    return posNew,dirNew
end
function SkillEffectCalc_Teleport:_FindTeleportPos_NightKingDoubleCrossTeleport(skillEffectCalcParam, teleportEntity,targetEntity)
    ---@type UtilDataServiceShare PlayRoleTeleport
    local utilDataService = self._world:GetService("UtilData")
    ---@type Vector2
    local posNew = teleportEntity:GetGridPosition():Clone()
    ---@type Vector2
    local dirNew = teleportEntity:GetGridDirection():Clone()
    local targetPos = targetEntity:GetGridPosition()
    --目标与施法者连线上，目标身前一格 （米字型范围内才放该技能，所以连线是八方向上的直线）
    local relateDir = posNew - targetPos
    if relateDir.x > 0 then
        relateDir.x = 1
    elseif relateDir.x < 0 then
        relateDir.x = -1
    end
    if relateDir.y > 0 then
        relateDir.y = 1
    elseif relateDir.y < 0 then
        relateDir.y = -1
    end
    local telPos = targetPos + relateDir
    if utilDataService:IsValidPiecePos(telPos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, telPos) then
        posNew = telPos
    else
        --如果身前一格不可用，则以该位置为中心，逆时针逐圈寻找一个合法点
        ---@type BoardServiceLogic
        local lsvcBoard = self._world:GetService("BoardLogic")
        local ringMax = lsvcBoard:GetCurBoardRingMax()
        for _, v in ipairs(ringMax) do
            local pos = telPos + Vector2.New(v[1], v[2])
            if utilDataService:IsValidPiecePos(pos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, pos) then
                posNew = pos
                break
            end
        end
    end
    if posNew ~= teleportEntity:GetGridPosition()then
        dirNew = posNew - teleportEntity:GetGridPosition()
    end
    return posNew,dirNew
end

function SkillEffectCalc_Teleport:_FindTeleportPos_NightKingTeleportWithPath(skillEffectCalcParam, teleportEntity,targetEntity)
    ---@type UtilDataServiceShare PlayRoleTeleport
    local utilDataService = self._world:GetService("UtilData")
    local bodyAreaCount = 1
    local onlyMaxRing = true--先只在第二圈找
    local pathReturn = {}
    ---@type Vector2
    local posNew = teleportEntity:GetGridPosition():Clone()
    ---@type Vector2
    local dirNew = teleportEntity:GetGridDirection():Clone()
    local targetPos = targetEntity:GetGridPosition()
    local finalPrePos = posNew
    ---@type SkillEffectParam_Teleport
    local telportSEParam = skillEffectCalcParam.skillEffectParam
    local pathTrapID = telportSEParam:GetBossNightKingPathTrapID()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local trapEntityIDList = utilDataSvc:GetSummonMeantimeLimitEntityID(pathTrapID)
    local finalTrapPos = nil
    if trapEntityIDList and #trapEntityIDList > 0 then
        for index, trapEntityID in ipairs(trapEntityIDList) do
            ---@type Entity
            local trapEntity = self._world:GetEntityByID(trapEntityID)
            if trapEntity then
                local trapPos = trapEntity:GetGridPosition()
                finalTrapPos = trapPos
                table.insert(pathReturn,trapPos)
            end
        end
    end
    if finalTrapPos then
        finalPrePos = finalTrapPos
    end
    --目标十字四格
    local finalTargetPosList = {targetPos + Vector2.up,targetPos + Vector2.down,targetPos + Vector2.left,targetPos + Vector2.right}
    ---@type SortedArray
    local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    sortPosList:AllowDuplicate()
    for i = 1, #finalTargetPosList do
        AINewNode.InsertSortedArray(sortPosList, finalPrePos, finalTargetPosList[i], i)
    end
    local targetCrossValidPos = nil
    for i = 1, sortPosList:Size() do
        ---@type AiSortByDistance
        local sortPosData = sortPosList:GetAt(i)
        local sortPos = sortPosData:GetPosData()
        if utilDataService:IsValidPiecePos(sortPos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, sortPos) then
            targetCrossValidPos = sortPos
            break
        end
    end
    if targetCrossValidPos then
        posNew = targetCrossValidPos
        table.insert(pathReturn,posNew)
    else
        ---@type SortedArray
        local targetFirstRingSortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
        targetFirstRingSortPosList:AllowDuplicate()
        --目标周围一圈中可用的点
        local targetFirstRingValidPosList = {}
        local targetFirstRingPosList = ComputeScopeRange.ComputeRange_SquareRing(targetPos, bodyAreaCount, 1,onlyMaxRing)
        for i = 1, #targetFirstRingPosList do
            AINewNode.InsertSortedArray(targetFirstRingSortPosList, finalPrePos, targetFirstRingPosList[i], i)
            local pos = targetFirstRingPosList[i]
            if utilDataService:IsValidPiecePos(pos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, pos) then
                table.insert(targetFirstRingValidPosList,pos)
            end
        end
        if #targetFirstRingValidPosList > 0 then
            --目标一圈中有可用的 则随机一个
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            local randIndex = randomSvc:LogicRand(1, #targetFirstRingValidPosList)
            posNew = targetFirstRingValidPosList[randIndex]
            table.insert(pathReturn,posNew)
        else
            --以目标一圈中最近的点逆时针逐圈找空位置
            ---@type AiSortByDistance
            local sortPosData = targetFirstRingSortPosList:GetAt(1)
            local targetFirstRingNearestPos = sortPosData:GetPosData()
            ---@type BoardServiceLogic
            local lsvcBoard = self._world:GetService("BoardLogic")
            local ringMax = lsvcBoard:GetCurBoardRingMax()
            for _, v in ipairs(ringMax) do
                local pos = targetFirstRingNearestPos + Vector2.New(v[1], v[2])
                if utilDataService:IsValidPiecePos(pos) and utilDataService:IsMonsterCanTel2TargetPos(teleportEntity, pos) then
                    posNew = pos
                    table.insert(pathReturn,posNew)
                    break
                end
            end
        end
    end
    self._renderTeleportPath = pathReturn
    return posNew
end

function SkillEffectCalc_Teleport:_FindTeleportPos_TargetTeleportSelectPos(skillEffectCalcParam, targetEntity)
    ---@type SkillEffectParam_Teleport
    local skillEffectParam_Teleport = skillEffectCalcParam.skillEffectParam

    local point = skillEffectParam_Teleport:GetUserPoint()
    local dir = skillEffectParam_Teleport:GetUserDir() or {0, 0}

    local posNew = Vector2(point[1], point[2])
    local dirNew = Vector2(dir[1], dir[2])

    local nRaceType = MonsterRaceType.Land
    if targetEntity:HasMonsterID() then
        nRaceType = targetEntity:MonsterID():GetMonsterRaceType()
    end
    local bodyArea = targetEntity:BodyArea():GetArea()
    local targetEntityOldPos = targetEntity:GetGridPosition()

    ---@type BlockFlag
    local nBlockRaceType = self._skillEffectService:_TransBlockByRaceType(nRaceType)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local bPosBlock = boardServiceLogic:IsPosBlockByArea(posNew, nBlockRaceType, bodyArea, targetEntity)
    if not bPosBlock then
        return posNew, dirNew
    end

    ---@type Vector2[]
    local posList = ComputeScopeRange.ComputeRange_SquareRing(posNew, table.count(bodyArea), 1)
    table.sort(
        posList,
        function(a, b)
            local disA = Vector2.Distance(targetEntityOldPos, a)
            local disB = Vector2.Distance(targetEntityOldPos, b)
            return disA < disB
        end
    )

    for _, pos in ipairs(posList) do
        local curPosBlock = boardServiceLogic:IsPosBlockByArea(pos, nBlockRaceType, bodyArea, targetEntity)
        if not curPosBlock then
            return posNew, dirNew
        end
    end

    return posNew, dirNew
end

---定制的无视阻挡的逻辑，关卡保证瞬移有效区域内没有重叠怪物。该特性不可修改。
---@param teleportEntity Entity
---@param teleportParam SkillEffectParam_Teleport
function SkillEffectCalc_Teleport:_FindTeleportPos_Boss2905701Move(teleportEntity, teleportParam)
    local posNew

    local trapID = teleportParam:GetBoss2905701MoveTrapID()
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    ---@type Entity|nil
    local trapEntity
    for _, e in ipairs(globalTrapEntities) do
        if e:Trap():GetTrapID() == trapID then
            trapEntity = e
            break
        end
    end

    if trapEntity then
        local trapGridPos = trapEntity:GetGridPosition()
        local trapBodyArea = trapEntity:BodyArea():GetArea()
        ---@type Entity
        local playerTeamEntity = self._world:Player():GetLocalTeamEntity()
        local playerTeamPos = playerTeamEntity:GetGridPosition()

        local teleportEntityBodyArea = teleportEntity:BodyArea():GetArea()

        local lowestDistance = 999 --足够大的数就行，最后要的是最小距离
        local lowestDistancePosArray = {}
        for _, trapBodyPos in ipairs(trapBodyArea) do
            local testPos = trapGridPos + trapBodyPos
            local dis = 999
            --local isQualified = true
            ----被传送单位与玩家队伍的最小距离计算
            for _, teleportBodyPos in ipairs(teleportEntityBodyArea) do
                local v2 = testPos + teleportBodyPos
                dis = math.min(dis, Vector2.Distance(v2, playerTeamPos))
            end

            if (lowestDistance > dis) then
                lowestDistancePosArray = {testPos}
                lowestDistance = dis
            elseif (lowestDistance == dis) then
                table.insert(lowestDistancePosArray, testPos)
            end
        end

        if #lowestDistancePosArray <= 0 then
            posNew = nil
        else
            local teleportEntityGridPos = teleportEntity:GetGridPosition()
            if table.Vector2Include(lowestDistancePosArray, teleportEntityGridPos) then
                posNew = nil
            else
                if #lowestDistancePosArray == 1 then
                    posNew = lowestDistancePosArray[1]
                else
                    ---@type RandomServiceLogic
                    local randsvc = self._world:GetService("RandomLogic")
                    local luckyNum = randsvc:LogicRand(1, #lowestDistancePosArray)
                    posNew = lowestDistancePosArray[luckyNum]
                end
            end
        end
    else
        posNew = nil
    end

    return posNew
end

---定制的无视阻挡的逻辑，关卡保证瞬移有效区域内没有重叠怪物。该特性不可修改。
---@param teleportEntity Entity
---@param teleportParam SkillEffectParam_Teleport
function SkillEffectCalc_Teleport:_FindTeleportPos_Boss2905701BackToPos(teleportEntity, teleportParam)
    return teleportParam:GetBoss2905701BackToPos()
end

---@param teleportEntity Entity
---@param teleportParam SkillEffectParam_Teleport
function SkillEffectCalc_Teleport:_FindTeleportPos_Boss2905701MovePlayerToTrap(teleportEntity, teleportParam)
    local posNew

    local trapIDArray = teleportParam:GetBoss2905701MovePlayerToTrapIDArray()

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    ---@type Entity[]
    local trapEntityArray = {}
    for _, e in ipairs(globalTrapEntities) do
        if table.icontains(trapIDArray, e:Trap():GetTrapID()) then
            if not utilData:IsPosBlock(e:GetGridPosition(), BlockFlag.LinkLine) then
                table.insert(trapEntityArray, e)
            end
        end
    end

    if #trapEntityArray > 0 then
        if #trapEntityArray > 1 then
            ---@type RandomServiceLogic
            local randsvc = self._world:GetService("RandomLogic")
            local luckyNum = randsvc:LogicRand(1, #trapEntityArray)
            posNew = trapEntityArray[luckyNum]:GetGridPosition()
        else
            posNew = trapEntityArray[1]:GetGridPosition()
        end
    else
        ---@type UtilScopeCalcServiceShare
        local utilScope = self._world:GetService("UtilScopeCalc")
        local emptyPiecesArray = utilScope:GetEmptyPieces()
        if #emptyPiecesArray ~= 0 then
            if #emptyPiecesArray > 1 then
                ---@type RandomServiceLogic
                local randsvc = self._world:GetService("RandomLogic")
                local luckyNum = randsvc:LogicRand(1, #emptyPiecesArray)
                posNew = emptyPiecesArray[luckyNum]
            else
                posNew = emptyPiecesArray[1]
            end
        --else posNew = nil
        end
    end

    return posNew
end
