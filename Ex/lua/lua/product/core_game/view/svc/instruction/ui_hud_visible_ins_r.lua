require("base_ins_r")
---@class UiHudVisibleInstruction: BaseInstruction
_class("UiHudVisibleInstruction", BaseInstruction)
UiHudVisibleInstruction = UiHudVisibleInstruction

function UiHudVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function UiHudVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local hudCamera = world:MainCamera():HUDCamera()
    hudCamera.enabled = self._visible == 1 and true or false
end
