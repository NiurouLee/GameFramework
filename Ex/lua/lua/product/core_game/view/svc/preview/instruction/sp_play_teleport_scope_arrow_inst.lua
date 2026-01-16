require("sp_base_inst")

local function getSimplifiedV2Direction(v2)
    local v = v2:Clone()
    if v.x > 0 then
        v.x = 1
    elseif v.x < 0 then
        v.x = -1
    end

    if v.y > 0 then
        v.y = 1
    elseif v.y < 0 then
        v.y = -1
    end

    return v
end

_class("SkillPreviewPlayTeleportScopeArrowInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayTeleportScopeArrowInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayTeleportScopeArrowInstruction = SkillPreviewPlayTeleportScopeArrowInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayTeleportScopeArrowInstruction:DoInstruction(TT,casterEntity,previewContext)
    local world = casterEntity:GetOwnerWorld()
    --先移除所有箭头
    ---@type Entity[]
    local arrowEntities = world:GetGroup(world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        world:DestroyEntity(e)
    end

    --再根据当前的范围重新画
    ---@type MainWorld
    world = previewContext:GetWorld()
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    ---@type Vector2[]
    local scopeGridList = previewContext:GetScopeResult()
    local v2CasterPos = casterEntity:GetGridPosition()
    for _, v2Scope in ipairs(scopeGridList) do
        local dir = getSimplifiedV2Direction(v2Scope - v2CasterPos)
        local eArrow = renderEntityService:CreateRenderEntity(EntityConfigIDRender.PickUpArrow)
        eArrow:SetLocation(v2Scope, dir)
    end
end

_class("SkillPreviewRemoveTeleportScopeArrowInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewRemoveTeleportScopeArrowInstruction: SkillPreviewBaseInstruction
SkillPreviewRemoveTeleportScopeArrowInstruction = SkillPreviewRemoveTeleportScopeArrowInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewRemoveTeleportScopeArrowInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type Entity[]
    local arrowEntities = self._world:GetGroup(self._world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        self._world:DestroyEntity(e)
    end
end
