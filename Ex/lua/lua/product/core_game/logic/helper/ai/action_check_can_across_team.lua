--[[-------------------------------------

--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckCanAcrossTeam : AINewNode
_class("ActionCheckCanAcrossTeam", AINewNode)
ActionCheckCanAcrossTeam = ActionCheckCanAcrossTeam

function ActionCheckCanAcrossTeam:OnUpdate()
    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    if nil == aiComponent then
        return false
    end
    local selfPos = entityCaster:GetGridPosition()

    ---@type Entity
    local entityPlayer = aiComponent:GetTargetDefault()
    local targetPos = entityPlayer:GetGridPosition()

    local dir = targetPos - selfPos

    --目标坐标
    local checkPos = targetPos + dir

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    if not boardServiceLogic:IsPosBlock(checkPos, BlockFlag.MonsterLand) then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
