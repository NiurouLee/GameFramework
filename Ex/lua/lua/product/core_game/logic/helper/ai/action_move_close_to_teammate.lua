require "action_move_base"

_class("ActionMoveCloseToTeammate", ActionMoveBase)
---@class ActionMoveCloseToTeammate : ActionMoveBase
ActionMoveCloseToTeammate = ActionMoveCloseToTeammate

_class("ActionMoveCloseToTeammate_SortedPosElement", Object)
---@class ActionMoveCloseToTeammate_SortedPosElement : Object
ActionMoveCloseToTeammate_SortedPosElement = ActionMoveCloseToTeammate_SortedPosElement

function ActionMoveCloseToTeammate_SortedPosElement:Constructor(teammateCount, centerPos, distance, pieceIndex)
    self._teammateCount = teammateCount
    self._centerPos = centerPos
    self._distance = distance
    self._pieceIndex = pieceIndex
end

function ActionMoveCloseToTeammate_SortedPosElement:GetTeammateCount()
    return self._teammateCount
end
function ActionMoveCloseToTeammate_SortedPosElement:GetCenterPos()
    return self._centerPos
end
function ActionMoveCloseToTeammate_SortedPosElement:GetDistance()
    return self._distance
end
function ActionMoveCloseToTeammate_SortedPosElement:GetPieceIndex()
    return self._pieceIndex
end

---@param a ActionMoveCloseToTeammate_SortedPosElement
---@param b ActionMoveCloseToTeammate_SortedPosElement
function ActionMoveCloseToTeammate_SortedPosElement.ComparerByTeammateCount(a, b)
    local teammateCountA = a:GetTeammateCount()
    local teammateCountB = b:GetTeammateCount()

    if teammateCountA > teammateCountB then
        return 1
    elseif teammateCountA < teammateCountB then
        return -1
    else
        local distanceA = a:GetDistance()
        local distanceB = b:GetDistance()
        if distanceA < distanceB then
            return 1
        elseif distanceA > distanceB then
            return -1
        else
            local indexA = a:GetPieceIndex()
            local indexB = b:GetPieceIndex()
            return indexB - indexA
        end
    end
end

function ActionMoveCloseToTeammate:FindNewTargetPos()
    local targetType = SkillTargetType.Monster --TODO

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScopeSvc:GetSkillScopeCalc()
    local nSkillID = self:GetLogicData(1)

    ---@type ConfigService
    local svcCfg = self._world:GetService("Config")
    local cfgSkill = svcCfg:GetSkillConfigData(nSkillID)

    local testBlockFlag = BlockFlag.MonsterLand
    if self.m_entityOwn:HasMonsterID() then
        local cMonsterID = self.m_entityOwn:MonsterID()
        testBlockFlag = cMonsterID:GetMonsterBlockData()
    end

    local casterGridPos = self.m_entityOwn:GetGridPosition()
    local casterDir = self.m_entityOwn:GetGridDirection()
    local bodyAreaArray = self.m_entityOwn:BodyArea():GetArea()

    local targetSelector = self._world:GetSkillScopeTargetSelector()

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local sortedArray =
        SortedArray:New(Algorithm.COMPARE_CUSTOM, ActionMoveCloseToTeammate_SortedPosElement.ComparerByTeammateCount)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    local boardPosList = boardCmpt:CloneBoardPosList()

    for index, gridPos in ipairs(boardPosList) do
        local isPosGoodToGo = true
        for _, relativeBodyPos in ipairs(bodyAreaArray) do
            if isPosGoodToGo == false then
                break
            end

            local absBodyPos = gridPos + relativeBodyPos
            if not utilData:IsValidPiecePos(absBodyPos) then
                isPosGoodToGo = false
                break
            end

            local pieceBlock = utilData:FindBlockByPos(absBodyPos)
            -- 此处不需要保证顺序
            if pieceBlock then
                for entityID, blockData in pairs(pieceBlock.m_listBlock) do
                    if (entityID ~= self.m_entityOwn:GetID()) and (blockData & testBlockFlag ~= 0) then
                        isPosGoodToGo = false
                        break
                    end
                end
            else
                isPosGoodToGo = false
            end
        end

        if isPosGoodToGo then
            local scopeResult = scopeCalc:CalcSkillScope(cfgSkill, gridPos, casterDir, bodyAreaArray)
            local targetArray =
                targetSelector:DoSelectSkillTarget(self.m_entityOwn, targetType, scopeResult, nSkillID) or {}
            local tids = {}
            for _, targetID in ipairs(targetArray) do
                if targetID ~= self.m_entityOwn:GetID() and (not table.icontains(tids, targetID)) then
                    table.insert(tids, targetID)
                end
            end
            local targetCount = #tids
            local distance = Vector2.Distance(gridPos, casterGridPos)
            local element = ActionMoveCloseToTeammate_SortedPosElement:New(targetCount, gridPos, distance, index)
            sortedArray:Insert(element)
        end
    end

    ---@type ActionMoveCloseToTeammate_SortedPosElement
    local first = sortedArray:GetAt(1)
    ---@type ActionMoveCloseToTeammate_SortedPosElement
    local second = sortedArray:GetAt(2)

    -- 就算达不到目标那他也得走一格
    if first:GetDistance() == 0 and first:GetTeammateCount() == 0 then
        first = second
    end
    local mobility = self.m_entityOwn:AI():GetMobilityValid()
    -- 优先选择自己行动力以内最佳的点
    ---@type ActionMoveCloseToTeammate_SortedPosElement
    local elementInMobility = nil
    for i = 1, sortedArray:Size() do
        local element = sortedArray:GetAt(i)
        --移动终点坐标
        local targetPos = first:GetCenterPos()
        local curPosToTargetDis = Vector2.Distance(casterGridPos, targetPos)
        local workPosToTargetDis = Vector2.Distance(element:GetCenterPos(), targetPos)
        --本次移动目标点距离当前坐标距离是1 and 该点距离终点比当前点距离终点要近
        if element:GetDistance() == 1 and workPosToTargetDis <= curPosToTargetDis then
            elementInMobility = element
            break
        end
    end

    if elementInMobility == nil then
        return casterGridPos
    end

    return elementInMobility:GetCenterPos()
end

function ActionMoveCloseToTeammate:FindNewWalkPos(posWalkList, posTarget, posSelf)
    -- return table.icontains(posWalkList, posTarget) and posTarget or posSelf
    return posTarget
end
