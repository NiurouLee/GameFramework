require("base_ins_r")
---@class PlayPetSacrificeTrapVisibleInstruction: BaseInstruction
_class("PlayPetSacrificeTrapVisibleInstruction", BaseInstruction)
PlayPetSacrificeTrapVisibleInstruction = PlayPetSacrificeTrapVisibleInstruction

function PlayPetSacrificeTrapVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
    self._fakeTriggerTrapSkillID = 500202--强化格子触发技能ID 用于模拟通知，触发现有光灵被动
end

---@param casterEntity Entity
function PlayPetSacrificeTrapVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    self._world =world
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultPetSacrificeSuperGridTraps[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.PetSacrificeSuperGridTraps)
    if not results then
        return
    end
    ---@type SkillEffectResultPetSacrificeSuperGridTraps
    local result = results[1]
    if not result then
        Log.fatal("NoResult ")
        return
    end
    local isShow = self._visible == 1
    local trapIDs = result:GetTrapIDs()
    local playBuffSvc = self._world:GetService("PlayBuff")
    for i, id in ipairs(trapIDs) do
        ---@type Entity
        local trapEntity = world:GetEntityByID(id)
        trapEntity:SetViewVisible(isShow)
        playBuffSvc:PlayBuffView(TT, NTPetMinosAbsorbTrap:New(trapEntity,casterEntity))
        local fakeNt = NTTrapSkillStart:New(trapEntity, self._fakeTriggerTrapSkillID, teamEntity)
        fakeNt:SetIsActiveSkillFake(true)
        playBuffSvc:PlayBuffView(TT, fakeNt)
    end
end