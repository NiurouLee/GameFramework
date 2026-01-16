--向指定的机关移动 有多个机关时取最近的
require("action_move_base")
---@class ActionMoveToSpecificTrap:ActionMoveBase
_class("ActionMoveToSpecificTrap", ActionMoveBase)
ActionMoveToSpecificTrap = ActionMoveToSpecificTrap

function ActionMoveToSpecificTrap:FindNewTargetPos()
    local posSelf = self.m_entityOwn:GetGridPosition()
    local targetPos = Vector2.New(posSelf.x, posSelf.y)
    local trapID = tonumber(self.m_configData[1])
    if trapID then
        ---@type TrapServiceLogic
        local trapLogicSvc = self._world:GetService("TrapLogic")
        local trapPosList = trapLogicSvc:FindTrapPosByTrapID(trapID)
        if #trapPosList >0 then
            local posListNearSelf = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
            posListNearSelf:AllowDuplicate()
            for index, trapPos in ipairs(trapPosList) do
                AINewNode.InsertSortedArray(posListNearSelf, posSelf, trapPos, index)
            end
            ---@type AiSortByDistance
            local aiSortByDistance = posListNearSelf:GetAt(1)
            targetPos = aiSortByDistance.data
        end
    end
    return targetPos
end
