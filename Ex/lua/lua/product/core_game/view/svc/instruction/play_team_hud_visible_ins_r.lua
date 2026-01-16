require("base_ins_r")
---显隐HUD上的对象
---@class PlayTeamHUDVisibleInstruction: BaseInstruction
_class("PlayTeamHUDVisibleInstruction", BaseInstruction)
PlayTeamHUDVisibleInstruction = PlayTeamHUDVisibleInstruction

function PlayTeamHUDVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTeamHUDVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type Entity
    local teamEntity = world:Player():GetCurrentTeamEntity()

    ---@type HPComponent
    local hpComponent = teamEntity:HP()

    if not hpComponent then
        return
    end

    local sliderEntityId = hpComponent:GetHPSliderEntityID()
    local sliderEntity = world:GetEntityByID(sliderEntityId)

    if not sliderEntity then
        return
    end

    -- sliderEntity:SetViewVisible(self._visible == 1)
    hpComponent:SetHPBarTempHide(self._visible == 0)
    hpComponent:SetHPPosDirty(true)
end
