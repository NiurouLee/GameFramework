--[[-------------------------------------
    ActionMoveBackAttack 后退AI节点: 选择距离玩家最远的移动点作为战略目标
    会判断是否连通
--]] -------------------------------------
require "action_move_base"

---@class ActionMoveBackAttackSimple:ActionMoveBase
_class("ActionMoveBackAttackSimple", ActionMoveBase)
ActionMoveBackAttackSimple = ActionMoveBackAttackSimple

function ActionMoveBackAttackSimple:Constructor()
    ---攻击位置列表：距离目标最远的靠前
    ---@type SortedArray
    self.m_posListFarTarget = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByFar)
    self.m_posListFarTarget:AllowDuplicate()
end
function ActionMoveBackAttackSimple:Reset()
    ActionMoveBackAttackSimple.super.Reset(self)
    ---@type SortedArray
    self.m_posListFarTarget:Clear()
end
--------------------------------    ---派生类可能要实现的三个函数
---初始化战略目标候选列表： ActionMoveBackAttackSimple 排序规则是： 距离目标最远的攻击位置在最前面
---@param listPosTarget Vector2[]
function ActionMoveBackAttackSimple:InitTargetPosList(listPosTarget)
    --在自己的周围查找
    local posSelf = self.m_entityOwn:GridLocation().Position
    local nSkillID = self:GetLogicData(1)
    local bodyArea = self.m_entityOwn:BodyArea():GetArea()
    if nSkillID == 0 then
        return
    end
    ---注意这里的排序函数，不同需求应当不同
    self.m_posListFarTarget:Clear()

    for _, targetPos in ipairs(listPosTarget) do
        local dir = posSelf - targetPos
        local skillRange = self:_ComputeSkillRange(nSkillID, targetPos, bodyArea, dir)
        for i = 1, #skillRange do
            local posSkill = skillRange[i]
            if self:IsPosAccessible(posSkill) then
                if self:IsPosConnected(targetPos, posSkill) then
                    AINewNode.InsertSortedArray(self.m_posListFarTarget, targetPos, posSkill, i)
                end
            end
        end
    end
end
---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function ActionMoveBackAttackSimple:FindNewTargetPos()
    local aiComponent = self.m_entityOwn:AI()
    local posTarget = aiComponent:GetTargetPos()
    local posSelf = self.m_entityOwn:GridLocation().Position
    ---当前位置在攻击范围外：找最近的攻击发起点
    if not self:_IsPosInSortedArray(posSelf, self.m_posListFarTarget) then
        return posSelf
    end
    return self:FindPosValidAndConnected(self.m_posListFarTarget, posTarget, posSelf) ---距离玩家最远的可攻击点
end
--------------------------------
---@param targetPos Vector2
---@param posList SortedArray
function ActionMoveBackAttackSimple:_IsPosInSortedArray(posWork, posList)
    local nListCount = posList:Size()
    for i = 1, nListCount do
        ---@type AiSortByDistance
        local actionData = posList:GetAt(i)
        if actionData and posWork == actionData.data then
            return true
        end
    end
    return false
end
--------------------------------
