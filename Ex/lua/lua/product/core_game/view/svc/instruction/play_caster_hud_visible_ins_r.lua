require("base_ins_r")
---显隐HUD上的对象
---@class PlayCasterHUDVisibleInstruction: BaseInstruction
_class("PlayCasterHUDVisibleInstruction", BaseInstruction)
PlayCasterHUDVisibleInstruction = PlayCasterHUDVisibleInstruction

function PlayCasterHUDVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterHUDVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type HPComponent
    local hpComponent = casterEntity:HP()

    if not hpComponent then
        return
    end

    local sliderEntityId = hpComponent:GetHPSliderEntityID()
    local sliderEntity = world:GetEntityByID(sliderEntityId)

    if not sliderEntity then
        return
    end

    local isHide = self._visible == 0

    -- sliderEntity:SetViewVisible(self._visible == 1)
    hpComponent:SetHPBarTempHide(isHide)
    hpComponent:SetHPPosDirty(true)

    --很抱歉写得这么绕，把上面的变量提出来的时候，直接保持了原来的exp，导致这里看上去充满了N重否定的感觉
    if not isHide then
        casterEntity:ReplaceHPComponent()
    end
end
