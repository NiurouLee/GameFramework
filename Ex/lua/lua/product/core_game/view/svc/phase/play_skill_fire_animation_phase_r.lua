require "play_skill_phase_base_r"

---@class PlaySkillFireAnimationPhase: PlaySkillPhaseBase
_class("PlaySkillFireAnimationPhase", PlaySkillPhaseBase)
PlaySkillFireAnimationPhase = PlaySkillFireAnimationPhase

---@param casterEntity Entity
function PlaySkillFireAnimationPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseFireAnimationParam
    local phaseParam = phaseParam
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local attackAnimName = phaseParam:GetAnimationName()
    casterEntity:SetAnimatorControllerTriggers({attackAnimName})
    --手持火焰
    local effFire = phaseParam:GetEffectFireID()
    effectService:CreateEffect(effFire, casterEntity)
    --爆炸
    local effBomb = phaseParam:GetEffectBombID()
    effectService:CreateEffect(effBomb, casterEntity)
    ---@type GridLocationComponent
    local castGridLocation = casterEntity:GridLocation()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local posArr = {}
    ---@type SkillEffectResult_SummonEverything[]
    local resultSummonArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    for i, v in ipairs(resultSummonArray) do
        local pos = v:GetGridPos()
        table.insert(posArr, pos)
    end
    ---@type Entity[]
    local effFire = {}
    for i, v in ipairs(posArr) do
        local e = effectService:CreateWorldPositionEffect(32, castGridLocation.Position, false)
        table.insert(effFire, e)
    end

    local delay = phaseParam:GetBombDelayMS()
    if delay > 0 then
        YIELD(TT, delay) --爆炸延迟
    end

    local attackEffectCount = phaseParam:GetCastEffectCount()
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    YIELD(TT)
    local flyTime = phaseParam:GetFlyTime()
    for i, v in ipairs(posArr) do
        local eff = effFire[i]
        eff:SetViewVisible(true)
        ---@type ViewComponent
        local view = eff:View()
        local go = view:GetGameObject()
        ---@type UnityEngine.Transform
        local tran = go.transform
        tran.position = tran.position + Vector3.up * 2
        local startPos = tran.position
        local endPos = boardServiceRender:GridPos2RenderPos(v)
        tran:DOJump(endPos, 10, 1, flyTime * 0.001):SetEase(DG.Tweening.Ease.InOutSine)
    end
    YIELD(TT, flyTime)
    for i, v in ipairs(effFire) do
        self._world:DestroyEntity(v)
    end
end
