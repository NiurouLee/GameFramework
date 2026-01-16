require("base_ins_r")
---@class DataSelectScopeGridRangeLastInstruction: BaseInstruction
_class("DataSelectScopeGridRangeLastInstruction", BaseInstruction)
DataSelectScopeGridRangeLastInstruction = DataSelectScopeGridRangeLastInstruction

function DataSelectScopeGridRangeLastInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectScopeGridRangeLastInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local scopeGridRange = phaseContext:GetScopeGridRange()
    if not scopeGridRange then
        return InstructionConst.PhaseEnd
    end
    if #scopeGridRange > 0 and #scopeGridRange[1] > 0 then
        phaseContext:SetCurScopeGridRangeIndex(#scopeGridRange[1])
    end
end
