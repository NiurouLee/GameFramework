require("sp_base_inst")

---回收连锁预览框，仅适用于施法者释放连锁技的情况
_class("SkillPreviewDestroyOutlineRangeInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewDestroyOutlineRangeInstruction: SkillPreviewBaseInstruction
SkillPreviewDestroyOutlineRangeInstruction = SkillPreviewDestroyOutlineRangeInstruction

function SkillPreviewDestroyOutlineRangeInstruction:Constructor(params)
end

---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewDestroyOutlineRangeInstruction:DoInstruction(TT, casterEntity, previewContext)
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    local g = self._world:GetGroup(self._world.BW_WEMatchers.SkillRangeOutline)
    local es = {}
    for _, e in ipairs(g:GetEntities()) do
        if e and e:HasSkillRangeOutline() and e:SkillRangeOutline():IsDestroy() then
            table.insert(es, e)
        end
    end
    for _, e in pairs(es) do
        self._world:DestroyEntity(e)
    end
end
