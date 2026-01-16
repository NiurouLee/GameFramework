--[[-------------------------------------
    ActionCWOrCCW 判断顺时针还是逆时针旋转
--]] -------------------------------------
require "ai_node_new"

---@class ActionCWOrCCW : AINewNode
_class("ActionCWOrCCW", AINewNode)
ActionCWOrCCW = ActionCWOrCCW

function ActionCWOrCCW:OnUpdate()
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local cGridLocation = self.m_entityOwn:GridLocation()
    local dir = cGridLocation:GetGridDir()
    local clockwiseDir = Vector2(dir.y, -dir.x) --dir的垂向（顺时针旋转90度）
    local clockwiseDirPos = cGridLocation.Position + clockwiseDir
    local aiNewNodeStatus = AINewNodeStatus.Failure
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if utilData:IsValidPiecePos(clockwiseDirPos) then
        aiNewNodeStatus = AINewNodeStatus.Success
    end
    return aiNewNodeStatus
end
