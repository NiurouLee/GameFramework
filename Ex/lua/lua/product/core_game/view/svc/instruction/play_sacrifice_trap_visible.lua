require("base_ins_r")
---@class PlaySacrificeTrapVisibleInstruction: BaseInstruction
_class("PlaySacrificeTrapVisibleInstruction", BaseInstruction)
PlaySacrificeTrapVisibleInstruction = PlaySacrificeTrapVisibleInstruction

function PlaySacrificeTrapVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
end

---@param casterEntity Entity
function PlaySacrificeTrapVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    self._world =world
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResultSacrificeTraps[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SacrificeTraps)
    ---@type SkillEffectResultSacrificeTraps
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
        playBuffSvc:PlayBuffView(TT, NTMinosAbsorbTrap:New(trapEntity))
    end
end