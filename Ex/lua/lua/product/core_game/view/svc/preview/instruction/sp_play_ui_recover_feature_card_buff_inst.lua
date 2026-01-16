require("sp_base_inst")
---选卡模块 预览 光灵头像 恢复卡牌buff图标
_class("SkillPreviewPlayUIRecoverFeatureCardBuffInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayUIRecoverFeatureCardBuffInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayUIRecoverFeatureCardBuffInstruction = SkillPreviewPlayUIRecoverFeatureCardBuffInstruction

function SkillPreviewPlayUIRecoverFeatureCardBuffInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayUIRecoverFeatureCardBuffInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type MainWorld
	self._world = previewContext:GetWorld()
	---@type MainWorld
    local world = self._world
    world:EventDispatcher():Dispatch(GameEventType.FeaturePetUIPreviewRecoverCardBuff)
end