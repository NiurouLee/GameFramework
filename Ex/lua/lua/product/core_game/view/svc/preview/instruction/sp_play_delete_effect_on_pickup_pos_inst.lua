require("sp_base_inst")
_class("SkillPreviewPlayDeleteEffectOnPickUpPosInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayDeleteEffectOnPickUpPosInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayDeleteEffectOnPickUpPosInstruction = SkillPreviewPlayDeleteEffectOnPickUpPosInstruction

function SkillPreviewPlayDeleteEffectOnPickUpPosInstruction:Constructor(params)
    self._effectID = tonumber(params.effectID)
    assert(Cfg.cfg_effect[self._effectID], "预览指令PlayEffectOnPickupPos需要有效的effectID")
end

function SkillPreviewPlayDeleteEffectOnPickUpPosInstruction:GetCacheResource()
    return {
        { Cfg.cfg_effect[self._effectID].ResPath, 1 }
    }
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayDeleteEffectOnPickUpPosInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = casterEntity:GetOwnerWorld()
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    if not previewPickUpComponent then
        return
    end

    local entityIDs = previewPickUpComponent:GetPickUpEffectEntityIDArray()
    for _, entityID in pairs(entityIDs) do
        if entityID then
            local entity = world:GetEntityByID(entityID)
            if entity then
                local entityPos = entity:GetRenderGridPosition()
                if entityPos == previewContext:GetPickUpPos() then
                    world:DestroyEntity(entity)
                end
            end
        end
    end
end
