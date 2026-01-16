require("sp_base_inst")

---专门为脚下格子做的转色预览指令

_class("SkillPreviewPlayCasterDirToPickInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCasterDirToPickInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCasterDirToPickInstruction = SkillPreviewPlayCasterDirToPickInstruction

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCasterDirToPickInstruction:DoInstruction(TT,casterEntity,previewContext)
    ---@type MainWorld
    self._world = previewContext:GetWorld()

    local gridPos = casterEntity:GetGridPosition()
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()

    local tv2Pick = previewPickUpComponent:GetAllValidPickUpGridPos()
    local v2Pickup = tv2Pick[1] or casterEntity:GetGridPosition()

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")

    local dirNew = v2Pickup - gridPos
    if dirNew.x > 0 then
        dirNew.x = 1
    elseif dirNew.x < 0 then
        dirNew.x = -1
    end

    if dirNew.y > 0 then
        dirNew.y = 1
    elseif dirNew.y < 0 then
        dirNew.y = -1
    end

    casterEntity:SetDirection(dirNew)
end
