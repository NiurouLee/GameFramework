---乔瑟里预览使用
require("sp_base_inst")
_class("SkillPreviewPlayJocelyneCreateCasterGhostInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayJocelyneCreateCasterGhostInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayJocelyneCreateCasterGhostInstruction = SkillPreviewPlayJocelyneCreateCasterGhostInstruction

function SkillPreviewPlayJocelyneCreateCasterGhostInstruction:Constructor(params)
    self._type = params["Type"]
    self._prefab = params["Prefab"]
    self._anim = params["Anim"] or "AtkUltPreview"
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayJocelyneCreateCasterGhostInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")

    --用 Teleport.TargetAroundNearestCaster = 26, --目标周围，距离施法者(单格)最近的格子。优先十字，再一圈内的X位置。一圈都没有再扩大一圈的十字
    ---@type SkillEffectCalc_Teleport
    local SkillEffectCalc_Teleport = SkillEffectCalc_Teleport:New(world)
    local posNew = SkillEffectCalc_Teleport:_FindTeleportPos_Comparer(nil,casterEntity,nil,nil,previewContext:GetScopeResult(),AiSortByDistance._ComparerByFar)
    posNew = posNew or casterEntity:GetGridPosition()
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")
    entitySvc:CreateGhost(posNew, casterEntity, self._anim, self._prefab)
end