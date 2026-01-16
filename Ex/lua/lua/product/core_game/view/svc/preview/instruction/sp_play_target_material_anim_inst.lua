require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewPlayTargetMaterialAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayTargetMaterialAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayTargetMaterialAnimInstruction = SkillPreviewPlayTargetMaterialAnimInstruction

function SkillPreviewPlayTargetMaterialAnimInstruction:Constructor(params)
    self._anim = params["Anim"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayTargetMaterialAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    local targetIDList = previewContext:GetTargetEntityIDList()
    targetIDList = table.unique(targetIDList)
    for _, id in pairs(targetIDList) do
        local entity = world:GetEntityByID(id)
        if entity and entity:HasTeam() then
            entity = entity:GetTeamLeaderPetEntity()
        end
        if
            entity and entity:HasMaterialAnimationComponent() and
                not entity:BuffView():HasBuffEffect(BuffEffectType.NotPlayMaterialAnimation)
         then
            if self._anim == "Flash" then
                entity:NewEnableFlash()
            elseif self._anim == "Transparent" then
                entity:NewEnableTransparent()
            elseif self._anim == "Ghost" then
                entity:NewEnableGhost()
            elseif self._anim == "FlashAlpha" then
                entity:NewEnableFlashAlpha()
            elseif self._anim == "N15Cure" then
                entity:PlayN15CureMaterialAnim()
            end
        end
    end
end
