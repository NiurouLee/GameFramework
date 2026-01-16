--[[
    MonsterMoveFrontAttack = 167, --怪向目标（队伍）移动 行为同ai moveFrontAttack 用于反制技能
]]

_class("SkillEffectCalc_MonsterMoveFrontAttack", Object)
---@class SkillEffectCalc_MonsterMoveFrontAttack: Object
SkillEffectCalc_MonsterMoveFrontAttack = SkillEffectCalc_MonsterMoveFrontAttack

function SkillEffectCalc_MonsterMoveFrontAttack:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---注意这里的排序函数，不同需求应当不同
    ---@type SortedArray
    self.m_nextPosList =  SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    self.m_nextPosList:AllowDuplicate()
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveFrontAttack:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectMonsterMoveFrontAttack
    local skillParam = skillEffectCalcParam:GetSkillEffectParam()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    self.casterEntity = casterEntity
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
    local checkSkillID = skillParam:GetCheckSkillID()
    local moveStep = skillParam:GetMoveStep()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    ---@type MonsterMoveFrontAttackResult[]
    local posWalkResultList = {}
    local isCasterDead = false
    if not targetEntity:HasDeadMark() then
        --movePath  = utilCalcSvc:GetMonster2TargetNearestPathByElement(casterEntity,targetID,element)
        posWalkResultList,isCasterDead  = self:CalMoveResultList(casterEntity,targetEntity,checkSkillID,moveStep)
    end
    local result = SkillEffectMonsterMoveFrontAttackResult:New(posWalkResultList,isCasterDead)
    return { result }
end
---@param walkRes MonsterMoveFrontAttackResult
---@param skillParam SkillEffectMonsterMoveFrontAttack
function SkillEffectCalc_MonsterMoveFrontAttack:_OnArrivePos(casterEntity,walkRes,skillParam)
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
---@return Vector2[]
function SkillEffectCalc_MonsterMoveFrontAttack:CalMoveResultList(casterEntity,targetEntity,checkSkillID,moveStep)
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
    for _, targetPos in ipairs(listPosTarget) do
        local walkRange = self:_ComputeSkillRange(checkSkillID, targetPos, bodyAreaCmpt:GetArea())
        for i = 1, #walkRange do
            local posWork = walkRange[i]
            if self:IsPosAccessible(posWork) then
                AINewNode.InsertSortedArray(self.m_nextPosList, casterPos, posWork, i)
            end
        end
    end
    self._lastPos = casterPos
    local isCasterDead = false
    ---@type MonsterMoveFrontAttackResult[]
    local posWalkResultList = {}
    for i = 1, moveStep do
        ---计算可移动到的目标点
        local posWalk = self:_CalcMovePos(casterEntity,moveStep - i + 1)

        ---@type AIRecorderComponent
        local aiRecorderCmpt = self._world:GetBoardEntity():AIRecorder()
        ---@type MonsterMoveFrontAttackResult
        local walkRes = MonsterMoveFrontAttackResult:New()
        if posWalk ~= nil then
            local posSelf = casterEntity:GetGridPosition()
            self._lastPos = posWalk

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, posWalk)
            casterEntity:SetGridPosition(posWalk)
            casterEntity:SetGridDirection(posWalk - posSelf)

            local entityID = casterEntity:GetID()
            table.insert(posWalkResultList,walkRes)
            walkRes:SetWalkPos(posWalk)
            aiRecorderCmpt:AddWalkResult(entityID, walkRes)
            ---处理到达一个格子的处理
            self:_OnArrivePos(casterEntity,walkRes)
            if casterEntity:HasDeadMark() then
                isCasterDead = true
                break
            end
        end
    end
    return posWalkResultList,isCasterDead
end
---计算本次要移动到的目标位置
---@param entityWork Entity
function SkillEffectCalc_MonsterMoveFrontAttack:_CalcMovePos(entityWork,nWalkTotal)
    local posSelf = entityWork:GridLocation().Position
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
function SkillEffectCalc_MonsterMoveFrontAttack:FindNewTargetPos(posDefault)
    return self:FindPosValid(self.m_nextPosList, posDefault)
end
---@param planPosList SortedArray   候选位置列表内部元素是 ---@type AiSortByDistance
---@param defPos Vector2    找不到的情况下，返回的默认值：一般是entity的当前位置
function SkillEffectCalc_MonsterMoveFrontAttack:FindPosValid(planPosList, defPos)
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
function SkillEffectCalc_MonsterMoveFrontAttack:IsPosAccessible(pos)
    if false == self.casterEntity:HasBodyArea() then
        return true
    end
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local monsterIDCmpt = self.casterEntity:MonsterID()
    local nMonsterBlockData = monsterIDCmpt:GetMonsterBlockData() --陆行/飞行
    local coverList = self.casterEntity:GetCoverAreaList(pos)
    local coverListSelf = self.casterEntity:GetCoverAreaList(self.casterEntity:GetGridPosition())
    for i = 1, #coverList do
        local posWork = coverList[i]
        if not table.icontains(coverListSelf, posWork) then ---确保不被自己堵上
            if boardServiceLogic:IsPosBlock(posWork, nMonsterBlockData) then
                return false
            end
        end
    end
    return true
end
---计算移动范围：所有怪物的移动轨迹都是十字（ 从centerPos 出发nWalkStep步以内 ）
---@return ComputeWalkPos[]
function SkillEffectCalc_MonsterMoveFrontAttack:ComputeWalkRange(centerPos, nWalkStep, bFilter)
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
function SkillEffectCalc_MonsterMoveFrontAttack:FindNewWalkPos(walkRange, posCenter, posDef)
    return self:FindPosByNearCenter(walkRange, posCenter, posDef, 1)
end
---查找距离圆心最近的位置
---@param walkRange Table <Vector2>
---@param posCenter Vector2 排序基准坐标
---@param posDef Vector2 默认的返回值
function SkillEffectCalc_MonsterMoveFrontAttack:FindPosByNearCenter(listPlanPos, posCenter, posDef, nCheckStep)
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
function SkillEffectCalc_MonsterMoveFrontAttack:ComputeSkillRange(skillID, centerPos, bodyArea, dir)
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
function SkillEffectCalc_MonsterMoveFrontAttack:_ComputeSkillRange(nSkillID, posCenter, bodyArea, dir)
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
function SkillEffectCalc_MonsterMoveFrontAttack:CalculateSkillRange(skillID, centerPos, dir, bodyAreaList)
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
function SkillEffectCalc_MonsterMoveFrontAttack:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList,entityCaster)
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
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, centerPos, dir, bodyAreaList,entityCaster)
    return skillResult
end
--endregion from ActionMoveBackAttack

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
-- function SkillEffectCalc_MonsterMoveFrontAttack:InsertSortedArray(sortedArray, centerPos, workPos, nIndex,elementVal)
--     ---@type SortByDistanceAndPreferElement
--     local posData = SortByDistanceAndPreferElement:New(centerPos, workPos, nIndex, elementVal)
--     sortedArray:Insert(posData)
-- end
------------------
