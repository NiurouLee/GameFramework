require("base_ins_r")
---选择一个buff結果
---@class DataSelectBuffInstruction: BaseInstruction
_class("DataSelectBuffInstruction", BaseInstruction)
DataSelectBuffInstruction = DataSelectBuffInstruction

function DataSelectBuffInstruction:Constructor(paramList)
    self._buffIndex = tonumber(paramList["buffIndex"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectBuffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --local skillViewID = self:GetSkillViewID(casterEntity)

    local buffResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBuff)
    if buffResultArray == nil then
        Log.warn("[ins] caster has no buff:",  tostring(casterEntity:GridLocation().Position))
        return InstructionConst.HeightWise
    end

    ---@type SkillBuffEffectResult
    local buffResult = buffResultArray[self._buffIndex]
    if buffResult == nil or next(buffResult._newBuffArray) == nil then
        phaseContext:SetCurBuffResultIndex(self._buffIndex)
        phaseContext:SetCurTargetEntityID(-1)
        return
    end

    local targetEntityID = buffResult:GetEntityID()
    phaseContext:SetCurBuffResultIndex(self._buffIndex)
    phaseContext:SetCurTargetEntityID(targetEntityID)
end
