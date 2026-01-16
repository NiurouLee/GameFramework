--[[-------------------------------------
    ActionMoveBackAttack 后退AI节点: 风筝怪使用 选择距离玩家最远的移动点作为战略目标
--]] -------------------------------------
require "action_move_base"

---@class ActionMoveBackAttack:ActionMoveBase
_class("ActionMoveBackAttack", ActionMoveBase)
ActionMoveBackAttack = ActionMoveBackAttack

function ActionMoveBackAttack:Constructor()
    ---攻击位置列表：距离自己最近的靠前
    self.m_posListNearSelf = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    self.m_posListNearSelf:AllowDuplicate()
    ---可以移动到的攻击位置：可能为空
    self.m_posListMoveAttack = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByFar)
    self.m_posListMoveAttack:AllowDuplicate()
end
function ActionMoveBackAttack:Reset()
    ActionMoveBackAttack.super.Reset(self)
    self.m_posListNearSelf:Clear()
    self.m_posListMoveAttack:Clear()
end
--------------------------------    ---派生类可能要实现的三个函数
---初始化战略目标候选列表： ActionMoveBackAttack 排序规则是： 距离目标最远的攻击位置在最前面
---@param listPosTarget Vector2[]
---@param targetEntityPosCenter Vector2
function ActionMoveBackAttack:InitTargetPosList(listPosTarget, targetEntityPosCenter)
    --在自己的周围查找
    local posSelf = self.m_entityOwn:GridLocation().Position
    local dirSelf = self.m_entityOwn:GridLocation().Direction
    local nSkillID = self:GetLogicData(1)
    local bodyArea = self.m_entityOwn:BodyArea():GetArea()
    if nSkillID == 0 then
        return
    end
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    local nWalkTotal = aiComponent:GetMobilityValid()
    local walkRange = self:ComputeWalkRange(posSelf, nWalkTotal, true)

    ---注意这里的排序函数，不同需求应当不同
    self.m_posListNearSelf:Clear()
    self.m_posListMoveAttack:Clear()
    for key, targetPos in ipairs(listPosTarget) do
        local skillRange = self:ComputeSkillRange(nSkillID, targetPos, bodyArea, dirSelf)
        ---统计所有可以到达的有效攻击点
        local bCheckObstacle = self:GetLogicData(-1) or 0 ---Action.Data参数控制是否启动障碍物检查
        for i = 1, #skillRange do
            local posAttack = skillRange[i]
            local bValidPos = self:IsPosAccessible(posAttack)
            local bValidAttackPos = true
            if bCheckObstacle > 0 and bValidPos then
                bValidAttackPos = self:IsPosConnected(targetPos, posAttack)
            end
            AINewNode.InsertSortedArray(self.m_posListNearSelf, posSelf, posAttack, i)
            if bValidPos and bValidAttackPos then
                for j = 1, #walkRange do
                    ---@type ComputeWalkPos
                    local posData = walkRange[j]
                    local posWalk = posData:GetPos()
                    if posWalk == posAttack then
                        AINewNode.InsertSortedArray(self.m_posListMoveAttack, targetEntityPosCenter, posWalk, j)
                    end
                end
            end
        end
    end
end

function ActionMoveBackAttack:ComputeSkillRange(skillID, centerPos, bodyArea, dir)
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

---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function ActionMoveBackAttack:FindNewTargetPos()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    local posTarget = aiComponent:GetTargetPosCenter()
    local posSelf = self.m_entityOwn:GridLocation().Position
    local posReturn = nil
    --1 向可以攻击范围中最远的点移动
    if self.m_posListMoveAttack and self.m_posListMoveAttack:Size() > 0 then
        -- posReturn = self:FindPosValidAndConnected(self.m_posListMoveAttack, posTarget, nil)
        ---@type AiSortByDistance
        local aiSortByDistance = self.m_posListMoveAttack:GetAt(1)
        posReturn = aiSortByDistance.data
    end
    if nil ~= posReturn then
        self:PrintLog("选择可以到达的有效进攻出发点，坐标(", posReturn.x, ",", posReturn.y, ")")
        return posReturn
    end
    --2 向可以移动范围中，距离目标中心最近的点移动
    posReturn = self:FindPosValidAndConnected(self.m_posListNearSelf, posTarget, nil)
    if nil ~= posReturn then
        self:PrintLog("选择距离自己最近的有效进攻出发点，坐标(", posReturn.x, ",", posReturn.y, ")")
        return posReturn
    end
    --3 选择目标身形中距离自己最近的点
    posReturn = aiComponent:GetTargetPos()
    self:PrintLog("没有有效进攻出发点，选择玩家坐标(", posReturn.x, ",", posReturn.y, ")")
    return posReturn
end
--------------------------------
---@param targetPos Vector2
---@param posList table
function ActionMoveBackAttack:_IsPosInList(posWork, posList)
    local nListCount = table.count(posList)
    for i = 1, nListCount do
        if posWork == posList[i] then
            return true
        end
    end
    return false
end
--------------------------------
