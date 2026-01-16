require("base_ins_r")
---@class PlayCasterRenderStateInstruction: BaseInstruction
_class("PlayCasterRenderStateInstruction", BaseInstruction)
PlayCasterRenderStateInstruction = PlayCasterRenderStateInstruction

function PlayCasterRenderStateInstruction:Constructor(paramList)
    self._renderState = tonumber(paramList["renderState"]) or 0
    self._caster = paramList["caster"]
end

---@param casterEntity Entity
function PlayCasterRenderStateInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local caster = casterEntity
    if self._caster == "Board" then
        ---@type MainWorld
        local world = casterEntity:GetOwnerWorld()
        caster = world:GetPreviewEntity()
    end

    ---@type RenderStateComponent
    local renderState = caster:RenderState()
    if not renderState then
        caster:AddRenderState()
        renderState = caster:RenderState()
    end

    renderState:SetRenderState(self._renderState)
end
