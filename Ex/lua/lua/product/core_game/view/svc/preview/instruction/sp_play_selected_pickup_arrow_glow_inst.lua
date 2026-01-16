require("sp_base_inst")

_class("SkillPreviewPlaySelectedPickupArrowGlowInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlaySelectedPickupArrowGlowInstruction: SkillPreviewBaseInstruction
SkillPreviewPlaySelectedPickupArrowGlowInstruction = SkillPreviewPlaySelectedPickupArrowGlowInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlaySelectedPickupArrowGlowInstruction:DoInstruction(TT,casterEntity,previewContext)
    local world = casterEntity:GetOwnerWorld()

    local pickUpPos = previewContext:GetPickUpPos()

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type Entity[]
    local arrowEntities = world:GetGroup(world.BW_WEMatchers.PickUpArrow):GetEntities()
    for _, e in ipairs(arrowEntities) do
        local v3Pos = e:Location():GetPosition()
        local v2Pos = boardServiceRender:BoardRenderPos2GridPos(v3Pos)
        local statTable = {select = false, idle = true}
        if v2Pos == pickUpPos then
            statTable = {select = true, idle = false}
        end
        e:SetAnimatorControllerBools(statTable)
    end
end
