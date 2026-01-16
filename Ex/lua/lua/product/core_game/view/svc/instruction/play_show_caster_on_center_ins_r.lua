_class("PlayShowCasterOnCenterInstruction", BaseInstruction)
---@class PlayShowCasterOnCenterInstruction : BaseInstruction
PlayShowCasterOnCenterInstruction = PlayShowCasterOnCenterInstruction

function PlayShowCasterOnCenterInstruction:Constructor(paramList)
    self._reset = paramList.reset ~= nil
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayShowCasterOnCenterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    local baseCenterPos = utilDataSvc:GetCurBoardCenterPos()
    local targetGridPos = self._reset and casterEntity:GetGridPosition() or baseCenterPos
    casterEntity:SetPosition(targetGridPos)

    YIELD(TT)
end
