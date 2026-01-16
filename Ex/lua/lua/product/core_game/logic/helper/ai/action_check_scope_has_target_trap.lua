--[[-------------------------------------
    ActionCheckScopeHasTargetTrap 检查范围内是否有指定机关
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckScopeHasTargetTrap : AINewNode
_class("ActionCheckScopeHasTargetTrap", AINewNode)
ActionCheckScopeHasTargetTrap = ActionCheckScopeHasTargetTrap

function ActionCheckScopeHasTargetTrap:OnUpdate()
    local skillID = self:GetLogicData(-1)
    local trapID = self:GetLogicData(-2)

    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    if nil == aiComponent then
        return false
    end
    local selfPos = entityCaster:GetGridPosition()
    local dir = entityCaster:GridLocation().Direction
    local selfBodyArea = entityCaster:BodyArea():GetArea()

    --使用技能ID 寻找攻击发起点
    local skillRangeData = self:CalculateSkillRange(skillID, selfPos, dir, selfBodyArea)

    --检查范围内是否有指定机关
    ---@type TrapServiceLogic
    local trapServerLogic = self._world:GetService("TrapLogic")
    local tarpPosList = trapServerLogic:FindTrapPosByTrapID(trapID)
    for _, pos in ipairs(skillRangeData) do
        if table.intable(tarpPosList, pos) then
            return AINewNodeStatus.Success
        end
    end

    return AINewNodeStatus.Failure
end
