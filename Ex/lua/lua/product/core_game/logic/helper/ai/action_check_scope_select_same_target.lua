--[[-------------------------------------
    ActionCheckScopeSelectSameTarget 检查2个范围
--]] -------------------------------------
require "ai_node_new"

---@class ActionCheckScopeSelectSameTarget : AINewNode
_class("ActionCheckScopeSelectSameTarget", AINewNode)
ActionCheckScopeSelectSameTarget = ActionCheckScopeSelectSameTarget

function ActionCheckScopeSelectSameTarget:OnUpdate()
    local skill = self:GetLogicData(-1)

    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    if nil == aiComponent then
        return false
    end
    local selfPos = entityCaster:GetGridPosition()
    local dir = entityCaster:GridLocation().Direction
    local selfBodyArea = entityCaster:BodyArea():GetArea()

    --使用技能ID 寻找攻击发起点
    local skillRangeData = self:CalculateSkillRange(skill, selfPos, dir, selfBodyArea)
    --攻击发起点
    local targetPos = skillRangeData[1]

    local skillScope = {}

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, entity in ipairs(monsterGroup:GetEntities()) do
        local bodyAreaList = entity:BodyArea():GetArea()
        local gridPos = entity:GridLocation():GetGridPos()

        local monsterArea = {}
        for _, bodyArea in ipairs(bodyAreaList) do
            local workPos = gridPos + bodyArea
            table.insert(monsterArea, workPos)
        end
        --自己的坐标在 怪物的身形范围内  使用这个范围
        if table.intable(monsterArea, selfPos) then
            table.appendArray(skillScope, monsterArea)
            break
        end
    end

    if table.intable(skillScope, targetPos) then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
