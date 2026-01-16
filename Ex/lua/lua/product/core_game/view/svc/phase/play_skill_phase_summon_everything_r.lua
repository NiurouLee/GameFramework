require "play_skill_phase_base_r"
--------------------------------
---@class PlaySkillPhase_SummonEverything: PlaySkillPhaseBase
_class("PlaySkillPhase_SummonEverything", PlaySkillPhaseBase)
PlaySkillPhase_SummonEverything = PlaySkillPhase_SummonEverything

--------------------------------
function PlaySkillPhase_SummonEverything:Constructor()
end
---@param phaseParam SkillPhaseParam_SummonEverything
function PlaySkillPhase_SummonEverything:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_SummonEverything
    local resultSummonArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    ---@type PlaySkillInstructionService
    local sPlaySkillInstruction = self._world:GetService("PlaySkillInstruction")
    if nil == resultSummonArray then
        Log.debug("[Phase_Summon] 召唤失败：没有召唤结果数值（可能不需要）")
        return
    end
    local isFxNoRotation = phaseParam:IsFxNoRotation()
    local nSkillID = skillEffectResultContainer:GetSkillID()
    local listWaitTask = {}
    for i = 1, #resultSummonArray do
        ---@type SkillEffectResult_SummonEverything
        local resultSummon = resultSummonArray[i]
        local gridPos = resultSummon:GetGridPos()
        local bFromGrid = 0
        if i > 1 then
            self:_DelayTime(TT, phaseParam:GetGridIntervalTime())
        end
        local posCenter = resultSummon:GetPosCenter()
        self:_PlayEffect(TT, posCenter, gridPos, phaseParam:GetGridEffectID(), phaseParam:GetGridEffectDelayTime(), isFxNoRotation)
        local nTaskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            sPlaySkillInstruction.ShowSummonAction,
            sPlaySkillInstruction,
            self._world,
            resultSummon
        )
        table.insert(listWaitTask, nTaskID)
    end
    local nTimeNow = GameGlobal:GetInstance():GetCurrentTime()
    self:_WaitSonTask(listWaitTask)
    local nShowTimeDelay = phaseParam:GetShowTimeDelay() or 0
    nShowTimeDelay = nShowTimeDelay - (GameGlobal:GetInstance():GetCurrentTime() - nTimeNow)
    self:_DelayTime(TT, nShowTimeDelay)
end
