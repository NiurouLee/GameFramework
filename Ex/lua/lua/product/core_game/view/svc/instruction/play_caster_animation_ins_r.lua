require("base_ins_r")
---@class PlayCasterAnimationInstruction: BaseInstruction
_class("PlayCasterAnimationInstruction", BaseInstruction)
PlayCasterAnimationInstruction = PlayCasterAnimationInstruction

function PlayCasterAnimationInstruction:Constructor(paramList)
    self._animName = paramList["animName"]
    self._forcePlayOnSkillHolder = tonumber(paramList.forcePlayOnSkillHolder) == 1
end

---@param casterEntity Entity
function PlayCasterAnimationInstruction:DoInstruction(TT,casterEntity,phaseContext)
    local e = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() and (not self._forcePlayOnSkillHolder) then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end
    e:SetAnimatorControllerTriggers({self._animName})
end