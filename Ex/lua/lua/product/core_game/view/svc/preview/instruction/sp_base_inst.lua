_class("SkillPreviewBaseInstruction", Object)
---@class SkillPreviewBaseInstruction: Object
SkillPreviewBaseInstruction = SkillPreviewBaseInstruction

function SkillPreviewBaseInstruction:Constructor(params)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewBaseInstruction:DoInstruction(TT, casterEntity, previewContext)
end

---提取指令需要缓存的资源
function SkillPreviewBaseInstruction:GetCacheResource()
end

---提取指令需要缓存的音效资源
function SkillPreviewBaseInstruction:GetCacheAudio()
end

---提取指令需要缓存的语音资源
function SkillPreviewBaseInstruction:GetCacheVoice()
end

