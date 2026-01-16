--[[-------------------------------------
    ActionRotateBodyArea 旋转BodyArea
--]] -------------------------------------
require "ai_node_new"

---@class ActionRotateBodyArea : AINewNode
_class("ActionRotateBodyArea", AINewNode)
ActionRotateBodyArea = ActionRotateBodyArea

function ActionRotateBodyArea:OnBegin()
    ---@type GridLocationComponent
    local cGridLocation = self.m_entityOwn:GridLocation()
    local pos = cGridLocation.Position
    local cBodyArea = self.m_entityOwn:BodyArea()
    local area = cBodyArea:GetArea()
    local newArea = {}
    local isClockwise = self:GetLogicData(-1)
    for i, v in ipairs(area) do
        if isClockwise then --顺时针
            table.insert(newArea, Vector2(v.y, -v.x))
        else
            table.insert(newArea, Vector2(-v.y, v.x))
        end
    end
    self.m_entityOwn:ReplaceBodyArea(newArea)
    --Offset
    if isClockwise then --顺时针
        cGridLocation.Offset = Vector2(cGridLocation.Offset.y, -cGridLocation.Offset.x)
    else
        cGridLocation.Offset = Vector2(-cGridLocation.Offset.y, cGridLocation.Offset.x)
    end
end

function ActionRotateBodyArea:OnUpdate()
    return AINewNodeStatus.Success
end
