require("base_ins_r")
---@class PlayAddDarkCameraValueInstruction: BaseInstruction
_class("PlayAddDarkCameraValueInstruction", BaseInstruction)
PlayAddDarkCameraValueInstruction = PlayAddDarkCameraValueInstruction

function PlayAddDarkCameraValueInstruction:Constructor(paramList)
    self._addValue = tonumber(paramList.addValue) or 0
end
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAddDarkCameraValueInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    self._world = world
    ---@type MainCameraComponent
    local mainCameraCmpt = world:MainCamera()
    mainCameraCmpt:AddDarkCameraValue(self._addValue)
    return
end
