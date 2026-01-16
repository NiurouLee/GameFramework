--[[------------------------------------------------------------------------------------------
    TeamDeadMarkComponent : 玩家专用的死亡标志组件，现在的用法是只有在actor死亡时，挂上此组件
    在对应的阶段清理
]] --------------------------------------------------------------------------------------------

---@class TeamDeadMarkComponent: Object
_class("TeamDeadMarkComponent", Object)

function TeamDeadMarkComponent:Constructor(pos)
    self._deadPos = pos
end

---@return Vector2
function TeamDeadMarkComponent:GetDeadGridPos()
    return self._deadPos
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return TeamDeadMarkComponent
function Entity:TeamDeadMark()
    return self:GetComponent(self.WEComponentsEnum.TeamDeadMark)
end

function Entity:HasTeamDeadMark()
    return self:HasComponent(self.WEComponentsEnum.TeamDeadMark)
end

function Entity:AddTeamDeadMark(pos)
    local index = self.WEComponentsEnum.TeamDeadMark
    local component = TeamDeadMarkComponent:New(pos)
    self:AddComponent(index, component)
end

function Entity:RemoveTeamDeadMark()
    if self:HasDeadFlag() then
        self:RemoveComponent(self.WEComponentsEnum.TeamDeadMark)
    end
end
