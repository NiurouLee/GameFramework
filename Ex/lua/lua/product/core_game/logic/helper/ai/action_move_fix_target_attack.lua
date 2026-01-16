--[[-------------------------------------
    ActionMoveFixTargetAttack 向固定位置移动并攻击节点:
        优先选择可攻击玩家范围内并且与固定目标点位置最近的点为行动目标点
        若不能攻击到玩家，则直接向玩家位置移动，会判断是否连通
--]] -------------------------------------
require "action_move_base"

---@class ActionMoveFixTargetAttack:ActionMoveBase
_class("ActionMoveFixTargetAttack", ActionMoveBase)
ActionMoveFixTargetAttack = ActionMoveFixTargetAttack

function ActionMoveFixTargetAttack:Constructor()
    --固定点对应的位置列表；排序方式：与配置坐标距离优先，距离相同则按上左下右的方位优先级
    ---@type SortedArray
    self.m_posListFixTarget = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistanceAndDir._ComparerByNearAndDir)
    self.m_posListFixTarget:AllowDuplicate()
    --靠近玩家对应的位置列表；排序方式：朝玩家靠近
    ---@type SortedArray
    self.m_posListFrontTarget = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    self.m_posListFrontTarget:AllowDuplicate()
end

function ActionMoveFixTargetAttack:Reset()
    ActionMoveFixTargetAttack.super.Reset(self)
    ---@type SortedArray
    self.m_posListFixTarget:Clear()
    ---@type SortedArray
    self.m_posListFrontTarget:Clear()
end

--------------------------------    ---派生类可能要实现的三个函数
--初始化战略目标候选列表
---@param listPosTarget Vector2[]
function ActionMoveFixTargetAttack:InitTargetPosList(listPosTarget)
    --获取技能ID
    local nSkillID = self:GetLogicData(1)
    if nSkillID == 0 then
        return
    end

    self.m_posListFixTarget:Clear()
    self.m_posListFrontTarget:Clear()
    local posSelf = self.m_entityOwn:GridLocation().Position
    local bodyArea = self.m_entityOwn:BodyArea():GetArea()
    local posFix = Vector2.New(self:GetLogicData(-1), self:GetLogicData(-2))

    --获取可移动的位置列表
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    local nWalkTotalStep = aiComponent:GetMobilityValid()
    local walkComputeRange = self:ComputeWalkRange(posSelf, nWalkTotalStep, true)
    local walkRange = {}
    for i = 1, #walkComputeRange do
        ---@type ComputeWalkPos
        local posData = walkComputeRange[i]
        local posWalk = posData:GetPos()
        if self:IsPosAccessible(posWalk) then
            table.insert(walkRange, posWalk)
        end
    end

    for _, targetPos in ipairs(listPosTarget) do
        --获取可释放技能攻击到目标点的位置列表
        local skillRangeUp = self:_ComputeSkillRange(nSkillID, targetPos, bodyArea, Vector2.up)
        local skillRangeRight = self:_ComputeSkillRange(nSkillID, targetPos, bodyArea, Vector2.right)
        local skillRangeDown = self:_ComputeSkillRange(nSkillID, targetPos, bodyArea, Vector2.down)
        local skillRangeLeft = self:_ComputeSkillRange(nSkillID, targetPos, bodyArea, Vector2.left)
        local skillRange = {}
        table.appendArray(skillRange, skillRangeUp)
        table.appendArray(skillRange, skillRangeRight)
        table.appendArray(skillRange, skillRangeDown)
        table.appendArray(skillRange, skillRangeLeft)

        --获取可移动范围和技能攻击范围的交集
        local workRange = table.union(walkRange, skillRange)
        for i = 1, #workRange do
            local posWork = workRange[i]
            if self:IsPosAccessible(posWork) then
                AINewNode.InsertSortedArrayDisAndDir(self.m_posListFixTarget, posFix, posWork, posSelf, i)
            end
        end

        for j = 1, #skillRange do
            local posSkill = skillRange[j]
            if self:IsPosAccessible(posSkill) then
                AINewNode.InsertSortedArray(self.m_posListFrontTarget, targetPos, posSkill, j)
            end
        end
    end
end

---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function ActionMoveFixTargetAttack:FindNewTargetPos()
    local posReturn = nil

    --1 向可以攻击范围中距离配置目标点最近的方向移动
    if self.m_posListFixTarget and self.m_posListFixTarget:Size() > 0 then
        ---@type AiSortByDistanceAndDir
        local target = self.m_posListFixTarget:GetAt(1)
        posReturn = target:GetPosData()
        self:PrintLog("选择可以靠近配置目标点且可攻击的位置，坐标(", posReturn.x, ",", posReturn.y, ")")
        return posReturn
    end

    --2 向可以攻击的范围移动
    if self.m_posListFrontTarget and self.m_posListFrontTarget:Size() > 0 then
        ---@type AiSortByDistance
        local target = self.m_posListFrontTarget:GetAt(1)
        posReturn = target:GetPosData()
        self:PrintLog("选择可攻击且距离攻击目标最近的位置，坐标(", posReturn.x, ",", posReturn.y, ")")
        return posReturn
    end

    --3 向目标对象移动
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    posReturn = aiComponent:GetTargetPos()
    self:PrintLog("没有有效攻击位置，选择目标对象的坐标(", posReturn.x, ",", posReturn.y, ")")
    return posReturn
end
