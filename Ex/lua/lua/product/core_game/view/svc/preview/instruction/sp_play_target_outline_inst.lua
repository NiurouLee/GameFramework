require("sp_base_inst")
---范围内目标OutlineComponent
_class("SkillPreviewPlayTargetOutlineInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayTargetOutlineInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayTargetOutlineInstruction = SkillPreviewPlayTargetOutlineInstruction

function SkillPreviewPlayTargetOutlineInstruction:Constructor(params)
    self._downSample = params["DownSample"]
    self._blurNum = params["BlurNum"]
    self._intensity = params["Intensity"]
    self._outlineSize = params["OutlineSize"]
    self._blendType = params["BlendType"]
    self._outlinColorR = params["OutlinColorR"]
    self._outlinColorG = params["OutlinColorG"]
    self._outlinColorB = params["OutlinColorB"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayTargetOutlineInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    local targetIDList = previewContext:GetTargetEntityIDList()
    targetIDList = table.unique(targetIDList)
    for _, id in pairs(targetIDList) do
        ---@type Entity
        local entity = world:GetEntityByID(id)

        if
        entity and entity:HasView() then
            ---@type ViewComponent
            local view = entity:View()
            ---@type UnityEngine.GameObject
            local go = view:GetGameObject()
            ---@type OutlineComponent
            local outlineCmpt = go:GetComponent(typeof(OutlineComponent))
            if not outlineCmpt then
                outlineCmpt = go:AddComponent(typeof(OutlineComponent))
            end
            outlineCmpt.enabled = true
            outlineCmpt.outlinColor = Color(self._outlinColorR / 255, self._outlinColorG / 255, self._outlinColorB / 255)
            outlineCmpt.downSample = tonumber(self._downSample)
            outlineCmpt.blurNum = tonumber(self._blurNum)
            outlineCmpt.intensity = tonumber(self._intensity)
            outlineCmpt.outlineSize = tonumber(self._outlineSize)

            if self._blendType == "Add" then
                outlineCmpt.blendType = OutlineComponent.BlendType.Add
            elseif self._blendType == "Blend" then
                outlineCmpt.blendType = OutlineComponent.BlendType.Blend
            end
        end
    end
end
