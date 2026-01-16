require("sp_base_inst")

---暗屏效果
_class("SkillPreviewSetHudBgAlphaInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewSetHudBgAlphaInstruction: SkillPreviewBaseInstruction
SkillPreviewSetHudBgAlphaInstruction = SkillPreviewSetHudBgAlphaInstruction

function SkillPreviewSetHudBgAlphaInstruction:Constructor(params)
    self._alpha = tonumber(params["alpha"])
    self._isDark = params["isDark"]
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewSetHudBgAlphaInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    local cMainCamera = world:MainCamera()
    if self._isDark then
        cMainCamera:EnableDarkCamera(true)
        cMainCamera:SetHudBgAlpha(self._alpha)
    else
        cMainCamera:EnableDarkCamera(false) ---关闭相机暗屏机制
        cMainCamera:SetHudBgAlpha(0) ---将hud bg设置为0
    end
end
