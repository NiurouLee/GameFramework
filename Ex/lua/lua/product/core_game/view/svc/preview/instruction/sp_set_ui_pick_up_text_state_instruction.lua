require("sp_base_inst")

---指令修改预览时 ui 选格子文本
_class("SkillPreviewSetUiPickUpTextStateInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewSetUiPickUpTextStateInstruction: SkillPreviewBaseInstruction
SkillPreviewSetUiPickUpTextStateInstruction = SkillPreviewSetUiPickUpTextStateInstruction

function SkillPreviewSetUiPickUpTextStateInstruction:Constructor(params)
    self._textState = tonumber(params["TextState"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewSetUiPickUpTextStateInstruction:DoInstruction(TT, casterEntity, previewContext)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangePickUpText, self._textState)
end
