require("base_ins_r")
---选择一个伤害结果
---@class DataSelectDamageInfoInstruction: BaseInstruction
_class("DataSelectDamageInfoInstruction", BaseInstruction)
DataSelectDamageInfoInstruction = DataSelectDamageInfoInstruction

function DataSelectDamageInfoInstruction:Constructor(paramList)
    self._damageInfoIndex = tonumber(paramList["damageInfoIndex"])
    self._damageStageIndex = tonumber(paramList["damageStageIndex"]) or 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectDamageInfoInstruction:DoInstruction(TT, casterEntity, phaseContext)
    phaseContext:SetCurDamageInfoIndex(self._damageInfoIndex)
end
