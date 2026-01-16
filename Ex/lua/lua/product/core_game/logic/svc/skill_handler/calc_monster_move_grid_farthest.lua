---与156类似，不计算技能范围，优先远离玩家，因为急着用所以复制了
---已提待优化项，参考https://wiki.h3d.com.cn/pages/viewpage.action?pageId=34837587的第87项

_class("SkillEffectCalc_MonsterMoveGridFarthest", Object)
---@class SkillEffectCalc_MonsterMoveGridFarthest: Object
SkillEffectCalc_MonsterMoveGridFarthest = SkillEffectCalc_MonsterMoveGridFarthest

function SkillEffectCalc_MonsterMoveGridFarthest:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveGridFarthest:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_MonsterMoveGridFarthest
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
    --local checkSkillID = skillParam:GetCheckSkillID()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    local movePath = {}
    if not targetEntity:HasDeadMark() then
        --movePath  = utilCalcSvc:GetMonster2TargetNearestPathByElement(casterEntity,targetID,element)
        movePath  = self:CalMovPath(casterEntity, targetEntity, preferElement --[[,checkSkillID]])
    end
    local isCasterDead = false
    ---@type MonsterWalkResult[]
    local posWalkResultList = {}
    if #movePath ~=0 then
        local oldPosList = {}
        for i, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MonsterWalkResult
            local walkRes = MonsterWalkResult:New()

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, pos)
            casterEntity:SetGridPosition(pos)
            casterEntity:SetGridDirection(pos - posSelf)

            local entityID = casterEntity:GetID()
            table.insert(posWalkResultList,walkRes)
            walkRes:SetWalkPos(pos)
            ---处理到达一个格子的处理
            self:_OnArrivePos(casterEntity,walkRes)
            table.insert(oldPosList,pos)
            if casterEntity:HasDeadMark() then
                isCasterDead = true
                break
            end
        end
    end
    local result = SkillEffectResult_MonsterMoveGridFarthest:New(posWalkResultList,isCasterDead)
    return { result }
end
---@param walkRes MonsterWalkResult
function SkillEffectCalc_MonsterMoveGridFarthest:_OnArrivePos(casterEntity,walkRes)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local pos = casterEntity:GetGridPosition()


    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(casterEntity, TrapTriggerOrigin.MonsterGridMove)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)
        walkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    local nTrapCount = table.count(listTrapWork)

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
---@param casterEntity Entity
---@return Vector2[]
function SkillEffectCalc_MonsterMoveGridFarthest:CalMovPath(casterEntity,targetEntity,preferElement,checkSkillID)
    ---@type Vector2
    local targetCenterPos = targetEntity:GetGridPosition()
    local casterPos = casterEntity:GetGridPosition()
    local bodyArea = casterEntity:BodyArea():GetArea()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = targetEntity:BodyArea()
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    --首先从boss位置出发，八方向延伸，找到所有可到达的点，保存
    ---@type table<int,Vector2>
    local posCanLink = utilCalcSvc:MonsterFindAllPosCanLink(casterPos)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local platformScopeResult = scopeCalc:ComputeScopeRange(
            SkillScopeType.FullScreen,
            1,
            casterPos,
            bodyArea,
            casterDir,
            nTargetType,
            casterPos,
            casterEntity
    )
    --筛选技能范围，需要在可到达范围内
    local validSkillRange = self:FilterSkillRangePos(platformScopeResult:GetAttackRange(), posCanLink)
    local tarMovePos = self:FindFarestPosToTarget(targetCenterPos,validSkillRange,preferElement)
    local movPath = {}
    if tarMovePos then
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
---@param skillRange Vector2[]
---@param posCanLink table<int,Vector2>
function SkillEffectCalc_MonsterMoveGridFarthest:FilterSkillRangePos(skillRange,posCanLink)
    local retRange = {}
    for _,pos in ipairs(skillRange) do
        local posIndex = Vector2.Pos2Index(pos)
        if posCanLink[posIndex] then
            table.insert(retRange,pos)
        end
    end
    return retRange
end

---注意：函数名拼写有问题，且该函数与monster_move_grid_to_skill_range是类似的
---@param targetCenterPos Vector2
---@param validSkillRange Vector2[]
function SkillEffectCalc_MonsterMoveGridFarthest:FindFarestPosToTarget(targetCenterPos,validRange,preferElement)
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

---@param sortedArray SortedArray
---@param centerPos Vector2 圆心
---@param workPos Vector2
function SkillEffectCalc_MonsterMoveGridFarthest:InsertSortedArray(sortedArray, centerPos, workPos, nIndex,elementVal)
    ---@type SortByDistanceAndPreferElement
    local posData = SortByDistanceAndPreferElement:New(centerPos, workPos, nIndex, elementVal)
    sortedArray:Insert(posData)
end

