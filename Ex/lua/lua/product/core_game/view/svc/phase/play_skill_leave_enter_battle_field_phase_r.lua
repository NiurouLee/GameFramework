require "play_skill_phase_base_r"

---@class PlaySkillLeaveEnterBattleFieldPhase: PlaySkillPhaseBase
_class("PlaySkillLeaveEnterBattleFieldPhase", PlaySkillPhaseBase)
PlaySkillLeaveEnterBattleFieldPhase = PlaySkillLeaveEnterBattleFieldPhase

---@param casterEntity Entity
---@param phaseParam SkillPhaseLeaveEnterBattleFieldParam
---离场进场表现
function PlaySkillLeaveEnterBattleFieldPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillLeaveEnterBattleFieldResult
    local leaveEnterBattleFieldResult =
        skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.LeaveEnterBattleField)
    if not leaveEnterBattleFieldResult then
        return
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local gridPos = boardServiceRender:GetRealEntityGridPos(casterEntity)
    local isLeave = leaveEnterBattleFieldResult:IsLeave()
    if isLeave then
        casterEntity:AddGridMove(100000, Vector2(5, 100), gridPos) ---暂定写死的离场位置
    else
        --casterEntity:SetGridDirection(dir)
        local pos = leaveEnterBattleFieldResult:EnterPos() or Vector2(5, 8)
        local dir = leaveEnterBattleFieldResult:EnterDir() or Vector2(0, -1)
        casterEntity:AddGridMove(100000, pos, gridPos)
        casterEntity:SetDirection(dir)
    end
end
