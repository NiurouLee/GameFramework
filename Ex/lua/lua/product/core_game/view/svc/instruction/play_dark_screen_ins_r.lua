require("base_ins_r")
---暗屏的开启与关闭
---@class PlayDarkScreenInstruction: BaseInstruction
_class("PlayDarkScreenInstruction", BaseInstruction)
PlayDarkScreenInstruction = PlayDarkScreenInstruction

function PlayDarkScreenInstruction:Constructor(paramList)
    local param = tonumber(paramList["enable"])
    if param == 1 then
        self._enable = true
    else
        self._enable = false
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDarkScreenInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type MainCameraComponent
    local mainCameraCmpt = world:MainCamera()
    mainCameraCmpt:EnableDarkCamera(self._enable)
end
