--[[-------------------------------------
    ActionUpdateBlockFlag 移除或更新脚下阻挡信息
--]] -------------------------------------
require "ai_node_new"

---@class ActionUpdateBlockFlag : AINewNode
_class("ActionUpdateBlockFlag", AINewNode)
ActionUpdateBlockFlag = ActionUpdateBlockFlag

function ActionUpdateBlockFlag:OnBegin()
    ---@type GridLocationComponent
    local cGridLocation = self.m_entityOwn:GridLocation()
    local pos = cGridLocation.Position
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local isRemove = self:GetLogicData(-1)
    if isRemove then
        sBoard:RemoveEntityBlockFlag(self.m_entityOwn, pos)
    else
        sBoard:UpdateEntityBlockFlag(self.m_entityOwn, pos, pos)
    end
end

function ActionUpdateBlockFlag:OnUpdate()
    return AINewNodeStatus.Success
end
