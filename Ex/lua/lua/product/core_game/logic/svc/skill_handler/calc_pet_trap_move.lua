--[[
    PetTrapMove = 201, --光灵机关移动
]]
---@class SkillEffectCalc_PetTrapMove : SkillEffectCalc_Base
_class("SkillEffectCalc_PetTrapMove", SkillEffectCalc_Base)
SkillEffectCalc_PetTrapMove = SkillEffectCalc_PetTrapMove

function SkillEffectCalc_PetTrapMove:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---注意这里的排序函数，不同需求应当不同
    ---@type SortedArray
    self.m_nextPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    self.m_nextPosList:AllowDuplicate()
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PetTrapMove:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    ---@type Entity
    self.casterEntity = casterEntity
    local casterPos = casterEntity:GetGridPosition()

    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()
    local targetID
    if table.count(targetIDList) >= 1 then
        targetID = targetIDList[1]
    end
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)

    ---@type SkillEffectParamPetTrapMove
    local skillParam = skillEffectCalcParam.skillEffectParam

    local moveStep = skillParam:GetMoveStep()
    local moveType = skillParam:GetMoveType()
    local moveParam = skillParam:GetMoveParam()
    local canMoveTrapLevel = skillParam:GetCanMoveTrapLevel()

    local targetCenterPos = targetEntity:GetGridPosition()

    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    --除了自己 和  canMoveTrapLevel里的机关   其他都绕开走
    self._needBypassPosList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() then
            ---@type TrapComponent
            local trapCmpt = e:Trap()
            local level = trapCmpt:GetTrapLevel()
            if not table.intable(canMoveTrapLevel, level) and e:GetID() ~= casterEntityID then
                local bodyArea = e:BodyArea():GetArea()
                local gridPos = e:GetGridPosition()
                for _, v in ipairs(bodyArea) do
                    table.insert(self._needBypassPosList, gridPos + v)
                end
            end
        end
    end

    ---@type PetTrapMoveResult[]
    local posWalkResultList = {}
    local isCasterDead = false

    self.m_nextPosList:Clear()

    local resultList = {}
    self._lastPos = casterPos

    if moveType == PetTrapMoveType.CloseToTeam then
        local previewRange = self:_CalcPreviewRange(casterPos, moveStep)
        table.removev(previewRange, casterPos)
        -- ---是否排除自己脚下坐标
        -- local bExcludeSelf = moveParam or 0

        -- for i = 1, moveStep do
        --     local walkRange = self:ComputeWalkRange(self._lastPos, 1, true)

        --     if bExcludeSelf == 0 then
        --         AINewNode.InsertSortedArray(self.m_nextPosList, teamPos, self._lastPos, 0)
        --     end
        --     for i = 1, #walkRange do
        --         ---@type ComputeWalkPos
        --         local posData = walkRange[i]
        --         local posWalk = posData:GetPos()
        --         if self:IsPosAccessible(posWalk) then
        --             if 0 == bExcludeSelf or (bExcludeSelf > 0 and posWalk ~= casterPos) then
        --                 AINewNode.InsertSortedArray(self.m_nextPosList, teamPos, posWalk, i)
        --             end
        --         end
        --     end

        --     local posFind = self:FindPosValid(self.m_nextPosList, self._lastPos)

        --     local posOld = self._lastPos:Clone()
        --     local dirNew = posFind - posOld
        --     local result = SkillEffectResultPetTrapMove:New(casterEntityID, posOld, posFind, dirNew, moveType)
        --     result:SetPreviewRange(previewRange)
        --     self._lastPos = posFind
        --     table.insert(resultList, result)
        -- end

        ----
        for i = 1, #previewRange do
            local posWork = previewRange[i]
            -- if self:IsPosAccessible(posWork) then
            AINewNode.InsertSortedArray(self.m_nextPosList, teamPos, posWork, i)
            -- end
        end

        for i = 1, moveStep do
            ---计算可移动到的目标点
            local posWalk = self:_CalcMovePos(casterEntity, moveStep - i + 1)

            if posWalk == nil and table.count(resultList) == 0 then
                posWalk = self._lastPos
            end

            if posWalk ~= nil then
                local posOld = self._lastPos:Clone()
                local dirNew = posWalk - posOld
                local result = SkillEffectResultPetTrapMove:New(casterEntityID, posOld, posWalk, dirNew, moveType)
                result:SetPreviewRange(previewRange)
                self._lastPos = posWalk
                table.insert(resultList, result)
            end
        end
    elseif moveType == PetTrapMoveType.AwayFromTeam then
        local previewRange = self:_CalcPreviewRange(casterPos, moveStep)
        table.removev(previewRange, casterPos)
        ---是否排除自己脚下坐标
        local bExcludeSelf = moveParam or 0

        ---@type SortedArray
        self.m_nextPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByFar)
        self.m_nextPosList:AllowDuplicate()

        for i = 1, moveStep do
            local walkRange = self:ComputeWalkRange(self._lastPos, 1, true)

            if bExcludeSelf == 0 then
                AINewNode.InsertSortedArray(self.m_nextPosList, teamPos, self._lastPos, 0)
            end
            for i = 1, #walkRange do
                ---@type ComputeWalkPos
                local posData = walkRange[i]
                local posWalk = posData:GetPos()
                if self:IsPosAccessible(posWalk) then
                    if 0 == bExcludeSelf or (bExcludeSelf > 0 and posWalk ~= casterPos) then
                        AINewNode.InsertSortedArray(self.m_nextPosList, teamPos, posWalk, i)
                    end
                end
            end

            local posFind = self:FindPosValid(self.m_nextPosList, self._lastPos)

            local posOld = self._lastPos:Clone()
            local dirNew = posFind - posOld
            local result = SkillEffectResultPetTrapMove:New(casterEntityID, posOld, posFind, dirNew, moveType)
            result:SetPreviewRange(previewRange)
            self._lastPos = posFind
            table.insert(resultList, result)
        end
    elseif moveType == PetTrapMoveType.FixedPos then
        --把固定坐标替换队伍坐标
        local targetPos = Vector2(moveParam[1][1], moveParam[1][2])
        if targetPos == casterPos then
            return
        end

        for i = 1, moveStep do
            local walkRange = self:ComputeWalkRange(self._lastPos, 1, true)
            AINewNode.InsertSortedArray(self.m_nextPosList, targetPos, self._lastPos, 0)

            for i = 1, #walkRange do
                ---@type ComputeWalkPos
                local posData = walkRange[i]
                local posWalk = posData:GetPos()
                if self:IsPosAccessible(posWalk) then
                    -- if 0 == bExcludeSelf or (bExcludeSelf > 0 and posWalk ~= casterPos) then
                    AINewNode.InsertSortedArray(self.m_nextPosList, targetPos, posWalk, i)
                -- end
                end
            end

            local posFind = self:FindPosValid(self.m_nextPosList, self._lastPos)

            local posOld = self._lastPos:Clone()
            local dirNew = posFind - posOld
            local result = SkillEffectResultPetTrapMove:New(casterEntityID, posOld, posFind, dirNew, moveType)
            result:SetPreviewRange(posFind)
            self._lastPos = posFind
            table.insert(resultList, result)
        end
    elseif moveType == PetTrapMoveType.SkillPos then
        local previewRange = self:_CalcPreviewRange(casterPos, moveStep)
        table.removev(previewRange, casterPos)

        -- posWalkResultList, isCasterDead = self:CalMoveResultList(casterEntity, targetEntity, skillParam)

        local skillID = moveParam

        ---@type BodyAreaComponent
        local bodyAreaCmpt = targetEntity:BodyArea()

        local walkRange = self:_ComputeSkillRange(skillID, targetCenterPos, bodyAreaCmpt:GetArea())
        for i = 1, #walkRange do
            local posWork = walkRange[i]
            if self:IsPosAccessible(posWork) then
                AINewNode.InsertSortedArray(self.m_nextPosList, casterPos, posWork, i)
            end
        end

        self._lastPos = casterPos
        local isCasterDead = false

        local posWalkResultList = {}
        for i = 1, moveStep do
            ---计算可移动到的目标点
            local posWalk = self:_CalcMovePos(casterEntity, moveStep - i + 1)

            if posWalk == nil and table.count(resultList) == 0 then
                posWalk = self._lastPos
            end

            if posWalk ~= nil then
                local posOld = self._lastPos:Clone()
                local dirNew = posWalk - posOld
                local result = SkillEffectResultPetTrapMove:New(casterEntityID, posOld, posWalk, dirNew, moveType)
                result:SetPreviewRange(previewRange)
                self._lastPos = posWalk
                table.insert(resultList, result)
            end
        end
    elseif moveType == PetTrapMoveType.Loop then
        local posList = {}
        for _, param in ipairs(moveParam) do
            local pos = Vector2(param[1], param[2])
            table.insert(posList, pos)
        end

        local canMoveSetp = 0
        --结尾可以绕回开始位置
        for i = 1, moveStep do
            local addPos = posList[i]
            table.insert(posList, addPos)
        end

        local calcPosList = {}
        for _, pos in ipairs(posList) do
            if canMoveSetp > 0 then
                canMoveSetp = canMoveSetp - 1
                table.insert(calcPosList, pos)
                if canMoveSetp == 0 then
                    break
                end
            end
            if pos == casterPos then
                canMoveSetp = moveStep
            end
        end

        for _, pos in ipairs(calcPosList) do
            if boardServiceLogic:IsPosBlock(pos, BlockFlag.MonsterLand) or table.intable(self._needBypassPosList, pos) then
                break
            end
            local posOld = self._lastPos:Clone()
            local dirNew = pos - posOld
            local result = SkillEffectResultPetTrapMove:New(casterEntityID, posOld, pos, dirNew, moveType)
            result:SetPreviewRange(pos)
            self._lastPos = pos
            table.insert(resultList, result)
        end
    end

    return resultList
end

function SkillEffectCalc_PetTrapMove:_CalcPreviewRange(casterPos, moveStep)
    local previewRange = {}
    local walkRange = self:ComputeWalkRange(casterPos, moveStep, true)

    for i = 1, #walkRange do
        ---@type ComputeWalkPos
        local posData = walkRange[i]
        local posWalk = posData:GetPos()
        table.insert(previewRange, posWalk)
    end
    return previewRange
end

function SkillEffectCalc_PetTrapMove:_OnArrivePos(casterPos, moveStep)
    local previewRange = {}
    local walkRange = self:ComputeWalkRange(casterPos, moveStep, true)

    for i = 1, #walkRange do
        ---@type ComputeWalkPos
        local posData = walkRange[i]
        local posWalk = posData:GetPos()
        table.insert(previewRange, posWalk)
    end
    return previewRange
end

---@param walkRes PetTrapMoveResult
---@param skillParam SkillEffectParamPetTrapMove
function SkillEffectCalc_PetTrapMove:_OnArrivePos(casterEntity, walkRes, skillParam)
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

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
end

---@param skillParam SkillEffectParamPetTrapMove
---@return Vector2[]
function SkillEffectCalc_PetTrapMove:CalMoveResultList(casterEntity, targetEntity, skillParam)
    local moveStep = skillParam:GetMoveStep()
    local moveType = skillParam:GetMoveType()
    local moveParam = skillParam:GetMoveParam()
    local skillID = moveParam

    ---@type Vector2
    local targetCenterPos = targetEntity:GetGridPosition()
    local casterPos = casterEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = targetEntity:BodyArea()

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")

    local listPosTarget = {targetCenterPos}
    self.m_nextPosList:Clear()

    local walkRange = self:_ComputeSkillRange(skillID, targetCenterPos, bodyAreaCmpt:GetArea())
    for i = 1, #walkRange do
        local posWork = walkRange[i]
        if self:IsPosAccessible(posWork) then
            AINewNode.InsertSortedArray(self.m_nextPosList, casterPos, posWork, i)
        end
    end

    self._lastPos = casterPos
    local isCasterDead = false

    local posWalkResultList = {}
    for i = 1, moveStep do
        ---计算可移动到的目标点
        local posWalk = self:_CalcMovePos(casterEntity, moveStep - i + 1)

        if posWalk ~= nil then
            local posSelf = casterEntity:GetGridPosition()
            self._lastPos = posWalk
            table.insert(posWalkResultList, posWalk)
        end
    end
    return posWalkResultList
end

---计算本次要移动到的目标位置
---@param entityWork Entity
function SkillEffectCalc_PetTrapMove:_CalcMovePos(entityWork, nWalkTotal)
    -- local posSelf = entityWork:GridLocation().Position
    local posSelf = self._lastPos
    ---找到距离自己最远的移动目标格子
    local posTarget = self:FindNewTargetPos(posSelf)

    ---已经到目标点了
    if posSelf == posTarget then
        return nil
    end

    --找到最近的可停留的攻击格子 *此处如果所有攻击格子都不可用 则直接返回目标位置
    local posWalkList = self:ComputeWalkRange(posSelf, nWalkTotal, true)
    local posWalk = self:FindNewWalkPos(posWalkList, posTarget, posSelf)
    ---最近可移动点是自己的位置，不需要移动
    if posWalk and posWalk == posSelf then
        return nil
    end
    return posWalk
end
---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function SkillEffectCalc_PetTrapMove:FindNewTargetPos(posDefault)
    return self:FindPosValid(self.m_nextPosList, posDefault)
end
---@param planPosList SortedArray   候选位置列表内部元素是 ---@type AiSortByDistance
---@param defPos Vector2    找不到的情况下，返回的默认值：一般是entity的当前位置
function SkillEffectCalc_PetTrapMove:FindPosValid(planPosList, defPos)
    if nil == planPosList or planPosList:Size() <= 0 then
        return defPos
    end
    local posSelf = defPos
    local posReturn = posSelf
    local nPosCount = planPosList:Size()
    for i = 1, nPosCount do
        ---@type AiSortByDistance
        local posWork = planPosList:GetAt(i)
        local bAccessible = self:IsPosAccessible(posWork.data)
        if true == bAccessible then
            posReturn = posWork.data
            break
        -- else
        --     if posWork.data == posSelf then     --遇到自己也是地图障碍物
        --         posReturn = posWork.data;
        --         break;
        --     end
        end
    end
    return posReturn
end
---判断entity是否可以走到pos位置
---@return boolean
---@param pos Vector2
function SkillEffectCalc_PetTrapMove:IsPosAccessible(pos)
    if false == self.casterEntity:HasBodyArea() then
        return true
    end

    if table.intable(self._needBypassPosList, pos) then
        return false
    end

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local blockFlag = BlockFlag.MonsterLand
    local coverList = self.casterEntity:GetCoverAreaList(pos)
    -- local coverListSelf = self.casterEntity:GetCoverAreaList(self.casterEntity:GetGridPosition())
    local coverListSelf = self.casterEntity:GetCoverAreaList(self._lastPos)
    for i = 1, #coverList do
        local posWork = coverList[i]
        if not table.icontains(coverListSelf, posWork) then ---确保不被自己堵上
            if boardServiceLogic:IsPosBlock(posWork, blockFlag) then
                return false
            end
        end
    end
    return true
end
---计算移动范围：所有怪物的移动轨迹都是十字（ 从centerPos 出发nWalkStep步以内 ）
---@return ComputeWalkPos[]
function SkillEffectCalc_PetTrapMove:ComputeWalkRange(centerPos, nWalkStep, bFilter)
    bFilter = bFilter or false
    ---@type Callback
    local cbFilter = nil
    if bFilter then
        cbFilter = Callback:New(1, self.IsPosAccessible, self)
    end
    return ComputeScopeRange.ComputeRange_WalkMathPos(centerPos, 1, nWalkStep, cbFilter)
end
---查找战术行动坐标：返回距离战略目标最近的点，找不到会返回自己的位置（不移动）
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
function SkillEffectCalc_PetTrapMove:FindNewWalkPos(walkRange, posCenter, posDef)
    return self:FindPosByNearCenter(walkRange, posCenter, posDef, 1)
end
---查找距离圆心最近的位置
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
---@param posDef Vector2 默认的返回值
function SkillEffectCalc_PetTrapMove:FindPosByNearCenter(listPlanPos, posCenter, posDef, nCheckStep)
    if nil == listPlanPos or table.count(listPlanPos) <= 0 then
        return posDef
    end
    local listWalk = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    listWalk:AllowDuplicate()
    local lastMovePos = self._lastPos
    for i = 1, #listPlanPos do
        ---@type ComputeWalkPos
        local posData = listPlanPos[i]
        local posWalk = posData:GetPos()
        if posWalk ~= posDef and (nil == nCheckStep or nCheckStep == posData:GetStep()) then
            if posWalk ~= lastMovePos then
                AINewNode.InsertSortedArray(listWalk, posCenter, posWalk, i)
            else
                --Log.fatal("this pos is last move pos:",posWalk)
            end
        end
    end
    return self:FindPosValid(listWalk, posDef)
end
--------------------------------
--region from ActionMoveBackAttack
---@return Vector2[]
function SkillEffectCalc_PetTrapMove:ComputeSkillRange(skillID, centerPos, bodyArea, dir)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    local scopeType = skillConfigData:GetSkillScopeType()
    if scopeType == SkillScopeType.DirectLineExpand then
        local ret1 = self:_ComputeSkillRange(skillID, centerPos, bodyArea, Vector2(0, 1))
        local ret2 = self:_ComputeSkillRange(skillID, centerPos, bodyArea, Vector2(0, -1))
        local ret3 = self:_ComputeSkillRange(skillID, centerPos, bodyArea, Vector2(1, 0))
        local ret4 = self:_ComputeSkillRange(skillID, centerPos, bodyArea, Vector2(-1, 0))
        local ret = {}
        table.appendArray(ret, ret1)
        table.appendArray(ret, ret2)
        table.appendArray(ret, ret3)
        table.appendArray(ret, ret4)
        return ret
    else
        return self:_ComputeSkillRange(skillID, centerPos, bodyArea, dir)
    end
end

---返回使用nSkillID能打到posCenter的所有坐标点
---@param nSkillID number    注意这里的排序函数，不同需求应当不同
---@param posCenter Vector2
------@return Vector2[]
function SkillEffectCalc_PetTrapMove:_ComputeSkillRange(nSkillID, posCenter, bodyArea, dir)
    if nSkillID == 0 then
        return {}
    end
    --在目标的周围查找
    local workCenter = posCenter
    --多格怪要求把目标坐标移动到多格的左下角：posCenter被作为右上角坐标计算
    if 4 == #bodyArea then
        workCenter = workCenter + Vector2(-1, -1)
    elseif 9 == #bodyArea then
        workCenter = workCenter + Vector2(-2, -2)
    end
    return self:CalculateSkillRange(nSkillID, workCenter, dir, bodyArea)
end
---@return Vector2[]
---计算技能的相对范围
function SkillEffectCalc_PetTrapMove:CalculateSkillRange(skillID, centerPos, dir, bodyAreaList)
    ---@type SkillScopeResult
    local skillResult = self:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList)

    if not skillResult then
        return {}
    end

    ---数据去重
    local skillRange = skillResult:GetAttackRange()
    local listReturn = {}
    for i = 1, #skillRange do
        local posWork = skillRange[i]
        if false == table.icontains(listReturn, posWork) then
            table.insert(listReturn, posWork)
        end
    end
    return listReturn
end
---@return SkillScopeResult
function SkillEffectCalc_PetTrapMove:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList, entityCaster)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalculater = utilScopeSvc:GetSkillScopeCalc()
    dir = dir or Vector2(0, 1) --不传方向默认朝上
    ---@type SkillScopeResult
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, centerPos, dir, bodyAreaList, entityCaster)
    return skillResult
end
--endregion from ActionMoveBackAttack

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
-- function SkillEffectCalc_PetTrapMove:InsertSortedArray(sortedArray, centerPos, workPos, nIndex,elementVal)
--     ---@type SortByDistanceAndPreferElement
--     local posData = SortByDistanceAndPreferElement:New(centerPos, workPos, nIndex, elementVal)
--     sortedArray:Insert(posData)
-- end
------------------
