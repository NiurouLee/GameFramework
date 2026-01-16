--[[-------------------------------------
    ActionMoveBackEscape 后退逃跑AI节点: 选择距离玩家最远的移动点作为战略目标
    支持两个参数： 第一个，是否排除自己坐标；第二个，是否放弃第一次选的战略目标作为行动目标（每次都重新选）
--]]-------------------------------------
require "action_move_base"

_class("ActionMoveBackEscape", ActionMoveBase)
---@class ActionMoveBackEscape:ActionMoveBase
ActionMoveBackEscape=ActionMoveBackEscape


function ActionMoveBackEscape:Constructor()
    self.m_posFirst = nil       ---第一目标点
    self.m_nextPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByFar);
    self.m_nextPosList:AllowDuplicate();
end
function ActionMoveBackEscape:Reset()
    ActionMoveBackEscape.super.Reset(self)
    ---@type SortedArray
    self.m_nextPosList:Clear()
end

--派生类可能要实现的三个函数
---初始化战略目标候选列表：  ActionMoveBackEscape 排序规则是：距离目标最远的行动位置排在最前面
---@param listPosTarget Vector2[]
function ActionMoveBackEscape:InitTargetPosList(listPosTarget)
    --在自己的周围查找
    local posSelf = self.m_entityOwn:GridLocation().Position
    local nSkillID = self:GetLogicData(1)
    local nBodyAreaCount = self.m_entityOwn:BodyArea():GetAreaCount()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI();
    local nWalkTotal = aiComponent:GetMobilityValid()
    if nWalkTotal == aiComponent:GetMobilityConfig() then
        self.m_posFirst = nil
    end
    local walkRange = self:ComputeWalkRange(posSelf, nWalkTotal, true )
    ---是否排除自己脚下坐标
    local bExcludeSelf = self:GetLogicData(-1) or 0
    ---注意这里的排序函数，不同需求应当不同
    self.m_nextPosList:Clear()
    for _, targetPos in ipairs(listPosTarget) do
        if bExcludeSelf <= 0 then
            AINewNode.InsertSortedArray( self.m_nextPosList, targetPos, posSelf, 0)
        end
        for i = 1, #walkRange do
            ---@type ComputeWalkPos
            local posData = walkRange[i]
            local posWalk = posData:GetPos()
            if self:IsPosAccessible( posWalk ) then
                if 0 == bExcludeSelf or (bExcludeSelf > 0 and posWalk ~= posSelf) then
                    AINewNode.InsertSortedArray(self.m_nextPosList, targetPos, posWalk, i)
                end
            end
        end
    end
end
---返回目标位置：self.m_nextPosList 内是按距离排序的数组并且包含了自己
function ActionMoveBackEscape:FindNewTargetPos()
    local posFind = nil
    local bForgetFirstPos = self:GetLogicData(-2) or 0
    if bForgetFirstPos > 0 then
        local posDefault = self.m_entityOwn:GetGridPosition()
        posFind = self:FindPosValid( self.m_nextPosList, posDefault)
    else
        if self.m_posFirst then
            if self:IsPosAccessible(self.m_posFirst) then
                posFind = self.m_posFirst
            end
        end
        if nil == posFind then
            local posDefault = self.m_entityOwn:GetGridPosition()
            posFind = self:FindPosValid( self.m_nextPosList, posDefault)
            self.m_posFirst = posFind
        end
    end
    return posFind
end
