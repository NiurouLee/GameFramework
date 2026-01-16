require("base_ins_r")
---@class DataSelectScopeGridRangePickUpInstruction: BaseInstruction
_class("DataSelectScopeGridRangePickUpInstruction", BaseInstruction)
DataSelectScopeGridRangePickUpInstruction = DataSelectScopeGridRangePickUpInstruction

function DataSelectScopeGridRangePickUpInstruction:Constructor(paramList)
    self._pickUpIndex = tonumber(paramList["pickUpIndex"])

    self._noPhaseEnd = paramList["noPhaseEnd"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectScopeGridRangePickUpInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type ActiveSkillPickUpComponent
    local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
    if not activeSkillPickUpComponent then
        return (not self._noPhaseEnd) and InstructionConst.PhaseEnd or nil
    end
    local pickUpGridArray = activeSkillPickUpComponent:GetAllValidPickUpGridPos()
    local v2PickupPos = pickUpGridArray[self._pickUpIndex]

    if v2PickupPos == nil then
        return (not self._noPhaseEnd) and InstructionConst.PhaseEnd or nil
    end

    --设置效果作用的范围
    phaseContext:SetScopeGridList({v2PickupPos})
end
