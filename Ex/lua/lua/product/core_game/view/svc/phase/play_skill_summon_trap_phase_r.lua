require "play_skill_phase_base_r"

---@class PlaySkillSummonTrapPhase: PlaySkillPhaseBase
_class("PlaySkillSummonTrapPhase", PlaySkillPhaseBase)
PlaySkillSummonTrapPhase = PlaySkillSummonTrapPhase

function PlaySkillSummonTrapPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseSummonTrapParam
    local summonTrapParam = phaseParam
    local showTime = summonTrapParam:GetShowTimeDelay()
    if showTime > 0 then
        YIELD(TT, showTime)
    end
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillSummonTrapEffectResult[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonTrap)
    if not resultArray then
        Log.fatal("### PlaySkillSummonTrapPhase SummonTrap result nil")
        return
    end
    for _, result in ipairs(resultArray) do
        local trapIDList = result:GetTrapIDList()
        for i = 1, #trapIDList do
            ---@type Entity
            local trapEntity = self._world:GetEntityByID(trapIDList[i])
            trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
            trapEntity:SetPosition(Vector2(result:GetPos().x, result:GetPos().y))
        end
    end
end
