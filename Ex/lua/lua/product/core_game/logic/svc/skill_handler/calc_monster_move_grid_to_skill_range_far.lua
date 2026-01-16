--[[
    MonsterMoveGridToSkillRangeFar = 156, --怪物按连线移动，向技能能攻击到目标的最远位置移动。会触发机关。（N18 世界boss克娜莉)
]]

_class("SkillEffectCalc_MonsterMoveGridToSkillRangeFar", Object)
---@class SkillEffectCalc_MonsterMoveGridToSkillRangeFar: Object
SkillEffectCalc_MonsterMoveGridToSkillRangeFar = SkillEffectCalc_MonsterMoveGridToSkillRangeFar

function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectMonsterMoveGridToSkillRangeFar
    local skillParam = skillEffectCalcParam:GetSkillEffectParam()
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
    local preferElement = skillParam:GetPreferElement()--casterEntity:Element():GetPrimaryType()
    local checkSkillID = skillParam:GetCheckSkillID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    local movePath = {}
    if not targetEntity:HasDeadMark() then
        --movePath  = utilCalcSvc:GetMonster2TargetNearestPathByElement(casterEntity,targetID,element)
        movePath  = self:CalMovPath(casterEntity,targetEntity,preferElement,checkSkillID)
    end
    local isCasterDead = false
    ---@type MonsterMoveSkillRangeFarResult[]
    local posWalkResultList = {}
    if #movePath ~=0 then
        local oldPosList = {}
        for i, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MonsterMoveSkillRangeFarResult
            local walkRes = MonsterMoveSkillRangeFarResult:New()

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, pos)
            casterEntity:SetGridPosition(pos)
            casterEntity:SetGridDirection(pos - posSelf)

            local entityID = casterEntity:GetID()
            table.insert(posWalkResultList,walkRes)
            walkRes:SetWalkPos(pos)
            ---处理到达一个格子的处理
            self:_OnArrivePos(casterEntity,walkRes,skillParam)
            table.insert(oldPosList,pos)
            if casterEntity:HasDeadMark() then
                isCasterDead = true
                break
            end
        end
    end
    local result = SkillEffectMonsterMoveGridToSkillRangeFarResult:New(posWalkResultList,isCasterDead)
    return { result }
end
---@param walkRes MonsterMoveSkillRangeFarResult
---@param skillParam SkillEffectMonsterMoveGridToSkillRangeFar
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:_OnArrivePos(casterEntity,walkRes,skillParam)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local pos = casterEntity:GetGridPosition()


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
    ---@type table<number,boolean>
    local flushTrapIDs = skillParam:GetFlushTrapIDs()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local array = utilSvc:GetTrapsAtPos(pos)
    for _, eTrap in ipairs(array) do
        if eTrap then
            ---@type TrapIDComponent
            local trapIDCmpt = eTrap:TrapID()
            if flushTrapIDs[trapIDCmpt:GetTrapID()] then
                eTrap:Attributes():Modify("HP", 0)
                trapServiceLogic:AddTrapDeadMark(eTrap, skillParam:GetDisableDieSkill())
                walkRes:SetFlushTrapID(eTrap:GetID())
            end
        end
    end

    --local nTrapCount = table.count(listTrapWork)

    ----本次移动经过的格子
    --local passGrids = {}
    --local isDuplicate = function(pos)
    --    for _, value in ipairs(passGrids) do
    --        if value.x == pos.x and value.y == pos.y then
    --            return true
    --        end
    --    end
    --    return false
    --end
    --local bodyArea = casterEntity:BodyArea():GetArea()
    --local dir = casterEntity:GridLocation():GetGridDir()
    --local curPos = casterEntity:GetGridPosition()
    --for _, value in ipairs(bodyArea) do
    --    local pos = curPos + value - dir
    --    if not isDuplicate(pos) then
    --        passGrids[#passGrids + 1] = pos
    --    end
    --end
    --
    --
    --walkRes:SetWalkPassedGrid(passGrids)
end
---@return Vector2[]
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:CalMovPath(casterEntity,targetEntity,preferElement,checkSkillID)
    ---@type Vector2
    local targetCenterPos = targetEntity:GetGridPosition()
    local casterPos = casterEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = targetEntity:BodyArea()
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    --首先从boss位置出发，八方向延伸，找到所有可到达的点，保存
    ---@type table<int,Vector2>
    local posCanLink = utilCalcSvc:MonsterFindAllPosCanLink(casterPos)
    --以目标（队伍）为 中心，计算技能范围
    local skillRange = self:ComputeSkillRange(checkSkillID,targetCenterPos,bodyAreaCmpt:GetArea())
    --筛选技能范围，需要在可到达范围内
    local validSkillRange = self:FilterSkillRangePos(skillRange,posCanLink)
    local tarMovePos
    --可用的技能范围位置列表
    if #validSkillRange > 0 then
        --技能范围位置列表不为空，则选中距离玩家最远的点作为目标位置
        tarMovePos = self:FindFarestPosToTarget(targetCenterPos,validSkillRange,preferElement)
    else
        --技能范围位置列表列表为空（说明走不到可放技能的位置），则试图移动到距离玩家最近的点
        tarMovePos = self:FindNearestPosToTarget(targetCenterPos,posCanLink,preferElement)
    end
    local movPath = {}
    if tarMovePos then
        ---@type UtilCalcServiceShare
        local utilCalcSvc = self._world:GetService("UtilCalc")
        ---@type BoardComponent
        local board = self._world:GetBoardEntity():Board()
        local pieceType = board:GetPieceType(tarMovePos)
        if pieceType == PieceType.Any then--选中的位置是个万色格子 则先试一下某颜色，之后再各颜色试一下
            movPath = utilCalcSvc:GetMonster2PosByLink(casterPos,tarMovePos,preferElement)
            if movPath and #movPath > 0 then
            else
                for checkPieceType = PieceType.Blue,PieceType.Yellow do
                    if checkPieceType ~= preferElement then
                        movPath = utilCalcSvc:GetMonster2PosByLink(casterPos,tarMovePos,preferElement)
                        if movPath and #movPath > 0 then
                            break
                        end
                    end
                end
            end
        else
            movPath = utilCalcSvc:GetMonster2PosByLink(casterPos,tarMovePos,pieceType)
        end
    end
    return movPath
end
--------------------------------
--region from ActionMoveBackAttack
---@return Vector2[]
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:ComputeSkillRange(skillID, centerPos, bodyArea, dir)
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
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:_ComputeSkillRange(nSkillID, posCenter, bodyArea, dir)
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
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:CalculateSkillRange(skillID, centerPos, dir, bodyAreaList)
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
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:_CalculateSkillScope(skillID, centerPos, dir, bodyAreaList,entityCaster)
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
---@param skillRange Vector2[]
---@param posCanLink table<int,Vector2>
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:FilterSkillRangePos(skillRange,posCanLink)
    local retRange = {}
    for _,pos in ipairs(skillRange) do
        local posIndex = Vector2.Pos2Index(pos)
        if posCanLink[posIndex] then
            table.insert(retRange,pos)
        end
    end
    return retRange
end
---@param targetCenterPos Vector2
---@param validSkillRange Vector2[]
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:FindFarestPosToTarget(targetCenterPos,validRange,preferElement)
    local posReturn
    ---攻击位置列表：距离目标最远的靠前
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    ---@type SortedArray
    local posListFarTarget = SortedArray:New(Algorithm.COMPARE_CUSTOM, SortByDistanceAndPreferElement._ComparerByFarWithElement)
    posListFarTarget:AllowDuplicate()
    ---注意这里的排序函数，不同需求应当不同
    posListFarTarget:Clear()
    for index, validPos in ipairs(validRange) do
        local pieceType = board:GetPieceType(validPos)
        local elementVal = 0
        if pieceType and pieceType == preferElement then--优先选某个颜色 万色不算
            elementVal = 1
        end
        self:InsertSortedArray(posListFarTarget, targetCenterPos, validPos, index, elementVal)
    end
    if posListFarTarget and posListFarTarget:Size() > 0 then
        ---@type SortByDistanceAndPreferElement
        local sortData = posListFarTarget:GetAt(1)
        posReturn = sortData.data
    end
    return posReturn
end
---@param targetCenterPos Vector2
---@param validSkillRange Vector2[]
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:FindNearestPosToTarget(targetCenterPos,validRange,preferElement)
    local posReturn
    ---攻击位置列表：距离目标最近的靠前
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    ---@type SortedArray
    local posListFarTarget = SortedArray:New(Algorithm.COMPARE_CUSTOM, SortByDistanceAndPreferElement._ComparerByNearWithElement)
    posListFarTarget:AllowDuplicate()
    ---注意这里的排序函数，不同需求应当不同
    posListFarTarget:Clear()
    for index, validPos in ipairs(validRange) do
        local pieceType = board:GetPieceType(validPos)
        local elementVal = 0
        if pieceType and pieceType == preferElement then--优先选某个颜色 万色不算
            elementVal = 1
        end
        self:InsertSortedArray(posListFarTarget, targetCenterPos, validPos, index, elementVal)
    end
    if posListFarTarget and posListFarTarget:Size() > 0 then
        ---@type SortByDistanceAndPreferElement
        local sortData = posListFarTarget:GetAt(1)
        posReturn = sortData.data
    end
    return posReturn
end

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
function SkillEffectCalc_MonsterMoveGridToSkillRangeFar:InsertSortedArray(sortedArray, centerPos, workPos, nIndex,elementVal)
    ---@type SortByDistanceAndPreferElement
    local posData = SortByDistanceAndPreferElement:New(centerPos, workPos, nIndex, elementVal)
    sortedArray:Insert(posData)
end
------------------
--region 排序

---用于移动判断距离的“排序单元”
---@class SortByDistanceAndPreferElement : Object
_class("SortByDistanceAndPreferElement", Object)
SortByDistanceAndPreferElement = SortByDistanceAndPreferElement
function SortByDistanceAndPreferElement:Constructor(centrePos, dataPos, nIndex, elementVal)
    self.centre = centrePos
    self.data = dataPos
    self.m_nIndex = nIndex or 0
    self.m_elementVal = elementVal or 0
    self.m_nDistance = self:Distance()
end
function SortByDistanceAndPreferElement:GetDistance()
    return self.m_nDistance
end
function SortByDistanceAndPreferElement:GetElementVal()
    return self.m_elementVal
end
function SortByDistanceAndPreferElement:GetPosData()
    return self.data
end
function SortByDistanceAndPreferElement:Distance()
    return GameHelper.ComputeLogicDistance(self.centre, self.data)
end
---@param dataA SortByDistanceAndPreferElement
---@param dataB SortByDistanceAndPreferElement
SortByDistanceAndPreferElement._ComparerByFarWithElement = function(dataA, dataB)
    local nDistanceA = dataA:GetDistance()
    local nDistanceB = dataB:GetDistance()
    if nDistanceA > nDistanceB then
        return 1
    elseif nDistanceA < nDistanceB then
        return -1
    else
        --优先选某属性的
        local nEleValA = dataA:GetElementVal()
        local nEleValB = dataB:GetElementVal()
        if nEleValA > nEleValB then
            return 1
        elseif nEleValA < nEleValB then
            return -1
        else
            return dataB.m_nIndex - dataA.m_nIndex
        end
    end
end
---@param dataNew SortByDistanceAndPreferElement
---@param dataOld SortByDistanceAndPreferElement
SortByDistanceAndPreferElement._ComparerByNearWithElement = function(dataA, dataB)
    local nDistanceA = dataA:GetDistance()
    local nDistanceB = dataB:GetDistance()
    if nDistanceA > nDistanceB then
        return -1
    elseif nDistanceA < nDistanceB then
        return 1    ---返回值为正表示A排在B前面
    else
        --优先选某属性的
        local nEleValA = dataA:GetElementVal()
        local nEleValB = dataB:GetElementVal()
        if nEleValA > nEleValB then
            return 1
        elseif nEleValA < nEleValB then
            return -1
        else
            ---m_nIndex小的在前面
            return dataB.m_nIndex - dataA.m_nIndex
        end
    end
end

----------------------------------------------------------------


--endregion 排序