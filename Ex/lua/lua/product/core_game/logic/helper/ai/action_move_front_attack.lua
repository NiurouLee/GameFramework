--[[-------------------------------------
    ActionMoveFrontAttack 向靠近玩家方向移动至进攻位置的AI节点
--]] -------------------------------------
require "action_move_base"
---@class ActionMoveFrontAttack:ActionMoveBase
_class("ActionMoveFrontAttack", ActionMoveBase)
ActionMoveFrontAttack = ActionMoveFrontAttack

--------------------------------
function ActionMoveFrontAttack:Constructor()
    self.m_nextPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
    self.m_nextPosList:AllowDuplicate()
end
function ActionMoveFrontAttack:Reset()
    ActionMoveFrontAttack.super.Reset(self)
    ---@type SortedArray
    self.m_nextPosList:Clear()
end
--------------------------------    ---派生类可能要实现的三个函数
---@param listPosTarget Vector2[]
function ActionMoveFrontAttack:InitTargetPosList(listPosTarget)
    --在目标的周围查找
    local posSelf = self.m_entityOwn:GetGridPosition()
    local nSkillID = self:GetLogicData(1)
    local cSkillID = self:GetLogicData(-1)
    if cSkillID then
        nSkillID = cSkillID
    end
    local selfBodyArea = self.m_entityOwn:BodyArea():GetArea()
    if nSkillID <= 0 then
        return
    end
    local range = {}
    ---注意这里的排序函数，不同需求应当不同
    self.m_nextPosList:Clear()
    ---AINewNode.InsertSortedArray( sortPosList, posSelf, targetPos, 0);
    for _, targetPos in ipairs(listPosTarget) do
        local walkRange = self:_ComputeSkillRange(nSkillID, targetPos, selfBodyArea)
        for i = 1, #walkRange do
            local posWork = walkRange[i]
            if self:IsPosAccessible(posWork) then
                range[#range+1]=Vector2.Pos2Index(posWork)
                AINewNode.InsertSortedArray(self.m_nextPosList, posSelf, posWork, i)
            end
        end
    end
    self:PrintDebugLog("MoveRange=",table.concat(range,' '))
end
---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function ActionMoveFrontAttack:FindNewTargetPos()
    local posDefault = self.m_entityOwn:AI():GetTargetPos()
    return self:FindPosValid(self.m_nextPosList, posDefault)
end
--------------------------------
