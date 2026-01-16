require("base_ins_r")
---@class PlayDeadEffectInstruction: BaseInstruction
_class("PlayDeadEffectInstruction", BaseInstruction)
PlayDeadEffectInstruction = PlayDeadEffectInstruction

function PlayDeadEffectInstruction:Constructor(paramList)
    self._deadType = tonumber(paramList["deadType"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDeadEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type DeathShowType
    local monsterDeadType = self._deadType
    local deathEffectID = nil
    if self._deadType == DeathShowType.DissolveLight then
        casterEntity:NewPlayDeadLight()
        deathEffectID = BattleConst.MonsterDeadEffectLight
    elseif monsterDeadType == DeathShowType.DissolveDark then
        casterEntity:NewPlayDeadDark()
        deathEffectID = BattleConst.MonsterDeadEffectDark
    end
    if deathEffectID then
        ---@type EffectService
        local effectService = world:GetService("Effect")
        if type(deathEffectID) == "number" then
            deathEffectID = {deathEffectID}
        end
        for i, effID in ipairs(deathEffectID) do
            local effectEntity = effectService:CreateEffect(effID, casterEntity)
        end
    end
end

function PlayDeadEffectInstruction:GetCacheResource()
    local t = {}
    if BattleConst.MonsterDeadEffectLight and BattleConst.MonsterDeadEffectLight > 0 then
        table.insert(t, {Cfg.cfg_effect[BattleConst.MonsterDeadEffectLight].ResPath, 1})
    end
    if BattleConst.MonsterDeadEffectDark and BattleConst.MonsterDeadEffectDark > 0 then
        table.insert(t, {Cfg.cfg_effect[BattleConst.MonsterDeadEffectDark].ResPath, 1})
    end
    return t
end

