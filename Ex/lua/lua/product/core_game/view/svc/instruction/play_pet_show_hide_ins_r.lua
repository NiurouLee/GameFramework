require("base_ins_r")

---@class PlayPetShowHideInstruction: BaseInstruction
_class("PlayPetShowHideInstruction", BaseInstruction)
PlayPetShowHideInstruction = PlayPetShowHideInstruction

function PlayPetShowHideInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
    self._forcePlayOnSkillHolder = tonumber(paramList.forcePlayOnSkillHolder) == 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayPetShowHideInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local realCaster = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() and (not self._forcePlayOnSkillHolder) then
        realCaster = casterEntity:GetSuperEntity()
    end

    if not realCaster:HasPet() then
        return
    end

    -- 模型显示时血条显示，这是需求
    local isShow = self._visible == 1

    local eTeam = realCaster:Pet():GetOwnerTeamEntity()
    local cTeam = eTeam:Team()

    local eTeamLeader = cTeam:GetTeamLeaderEntity()
    if eTeamLeader:GetID() == realCaster:GetID() then
        return
    end

    realCaster:SetViewVisible(isShow)
    eTeamLeader:SetViewVisible(not isShow)
end
