require("base_ins_r")
---@class PlayClearDarkCameraValueInstruction: BaseInstruction
_class("PlayClearDarkCameraValueInstruction", BaseInstruction)
PlayClearDarkCameraValueInstruction = PlayClearDarkCameraValueInstruction

function PlayClearDarkCameraValueInstruction:Constructor(paramList)

end
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayClearDarkCameraValueInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    self._world = world
    ---@type MainCameraComponent
    local mainCameraCmpt = world:MainCamera()
    mainCameraCmpt:ClearDarkCameraValue()
    return
end
