require "action_move_base"
---@class ActionMoveToSkillPos : ActionMoveBase
_class("ActionMoveToSkillPos", ActionMoveBase)

ActionMoveToSkillPos = ActionMoveToSkillPos

function ActionMoveToSkillPos:Constructor()
    ---@type SortedArray
    self.m_nextPosList = nil
end

function ActionMoveToSkillPos:Reset()
    ActionMoveToSkillPos.super.Reset(self)

    self.m_nextPosList = nil
end

---@param listPosTarget Vector2[]
function ActionMoveToSkillPos:InitTargetPosList(listPosTarget)
    local nSkillID = self:GetLogicData(1)
    if nSkillID == nil or nSkillID <= 0 then 
        self:PrintLog("[ActionMoveToSkillPos] Can not find skill,move failed",self.m_entityOwn:GetID())
        self:PrintDebugLog(" Can not find skill,move failed")
        return
    end
    
    local posSelf = self.m_entityOwn:GetGridPosition()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI();
    local nWalkTotal = aiComponent:GetMobilityValid()
    local selfBodyArea = self.m_entityOwn:BodyArea():GetArea()
    ---@type table<number, ComputeWalkPos>
    local cbFilter = Callback:New(1, self.IsPosAccessible, self)
    local walkRange = ComputeScopeRange.ComputeRange_WalkMathPos(posSelf, #selfBodyArea, nWalkTotal, cbFilter)

    -- bodyArea都是从<0, 0>向右上配置的，扩充范围时只考虑左和下即可
    local surroundArea = {}
    local surroundMap = {}
    for _, pos in ipairs(selfBodyArea) do
        self:_NonRepeatableInsertVector2(surroundArea, surroundMap, pos)
        self:_NonRepeatableInsertVector2(surroundArea, surroundMap, Vector2.New(pos.x * (-1), pos.y))
        self:_NonRepeatableInsertVector2(surroundArea, surroundMap, Vector2.New(pos.x, pos.y * (-1)))
        self:_NonRepeatableInsertVector2(surroundArea, surroundMap, pos * (-1))
    end

    ---@type table<number, Vector2>
    local movementVectors = {}
    local movePosIndexs={}
    for _, walkPos in ipairs(walkRange) do
        table.insert(movementVectors, walkPos:GetPos())
        movePosIndexs[#movePosIndexs+1]=Vector2.Pos2Index(walkPos:GetPos())
    end
    self:PrintLog('[ActionMoveToSkillPos] entityID=',self.m_entityOwn:GetID(),' walkRange=',table.concat(movePosIndexs,' '))
    self:PrintDebugLog( "entityID=",self.m_entityOwn:GetID()," walkRange=",table.concat(movePosIndexs,' '))
    -- 在怪物初始位置计算所有方向的技能范围
    -- 如果(玩家位置+反向移动向量)落在技能范围内，则表示怪物走到该点时，可以释放技能
    local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    sortPosList:AllowDuplicate()

    local playerRange = {Vector2.zero}
    local targetPos = listPosTarget[1]
    local reverseRange = {}
    for _, bodyGrid in ipairs(surroundArea) do
        local centerPos = targetPos + bodyGrid
        local reverseRangeUp = self:CalculateSkillRange(nSkillID, centerPos, Vector2.up, playerRange)
        local reverseRangeDown = self:CalculateSkillRange(nSkillID, centerPos, Vector2.down, playerRange)
        local reverseRangeLeft = self:CalculateSkillRange(nSkillID, centerPos, Vector2.left, playerRange)
        local reverseRangeRight = self:CalculateSkillRange(nSkillID, centerPos, Vector2.right, playerRange)
        table.appendArray(reverseRange, reverseRangeUp)
        table.appendArray(reverseRange, reverseRangeDown)
        table.appendArray(reverseRange, reverseRangeLeft)
        table.appendArray(reverseRange, reverseRangeRight)
    end

    local playerBeHitRange={}
    for i,v in ipairs(reverseRange) do
        playerBeHitRange[#playerBeHitRange+1]=Vector2.Pos2Index(v)
    end
    self:PrintLog('[ActionMoveToSkillPos] entityID=',self.m_entityOwn:GetID(),' playerBeHitRange=',table.concat(playerBeHitRange,' '))
    self:PrintDebugLog('entityID=',self.m_entityOwn:GetID(),' playerBeHitRange=',table.concat(playerBeHitRange,' '))
    for _, vec in ipairs(movementVectors) do
        local wholeBodyIn = true
        for __, bodyGrid in ipairs(selfBodyArea) do
            local absBodyGrid = bodyGrid + vec
            wholeBodyIn = wholeBodyIn and table.icontains(reverseRange, absBodyGrid)
        end

        if wholeBodyIn then
            AINewNode.InsertSortedArray(sortPosList, posSelf, vec, sortPosList:Size())
        end
    end

    self.m_nextPosList = sortPosList

    return sortPosList
end

function ActionMoveToSkillPos:FindNewTargetPos()
    local posDefault = self.m_entityOwn:AI():GetTargetPos()
    return self:FindPosValid( self.m_nextPosList, posDefault);
end

function ActionMoveToSkillPos:_NonRepeatableInsertVector2(t, map, val)
    local x = val.x
    local y = val.y
    if not map[x] then map[x] = {} end
    if not map[x][y] then
        map[x][y] = true
        table.insert(t, val)
    end
end