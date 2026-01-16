require "play_skill_phase_base_r"
--------------------------------
---@class PlaySkillPhase_AddBlood: PlaySkillPhaseBase
_class("PlaySkillPhase_AddBlood", PlaySkillPhaseBase)
PlaySkillPhase_AddBlood = PlaySkillPhase_AddBlood

--------------------------------
function PlaySkillPhase_AddBlood:Constructor()
    ---加血表现执行函数
end
---@param phaseParam SkillPhaseParam_AddBlood
function PlaySkillPhase_AddBlood:PlayFlight(TT, casterEntity, phaseParam)
    -- ---@type EffectService
    -- local effectService = self._world:GetService("Effect")
    self:_PlayFlightAll(TT, casterEntity, phaseParam)

    self:_DelayTime(TT, phaseParam:GetShowTimeDelay())
end
---@param paramWork SkillPhaseParam_AddBlood
function PlaySkillPhase_AddBlood:_PlayFlightAll(TT, casterEntity, paramWork)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_AddBlood[]
    local skillResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBlood)
    if nil == skillResultArray then
        Log.error("加血表现里，给[", casterEntity:GetID(), "]加血时没有找到逻辑数据")
        return
    end

    local posCast = self:_GetEntityBasePos(casterEntity)
    local nIntervalTime = paramWork:GetGridIntervalTime()
    for i = 1, #skillResultArray do
        ---@type SkillEffectResult_AddBlood
        local skillResult = skillResultArray[i]

        local nTargetID = skillResult:GetTargetID()
        local nAddValue = skillResult:GetAddValue()
        local damageInfo = skillResult:GetDamageInfo()
        local targetEntity = self._world:GetEntityByID(nTargetID)

        GameGlobal.TaskManager():CoreGameStartTask(
            self._PlayFlightOne,
            self,
            casterEntity,
            targetEntity,
            paramWork:GetGridEffectID(),
            paramWork:GetGridEffectDelayTime(),
            damageInfo
        )
        self:_DelayTime(TT, nIntervalTime)
    end
end
---@param paramWork SkillPhaseParam_AddBlood
function PlaySkillPhase_AddBlood:_PlayFlightOne(TT, casterEntity, entityWork, nEffectID, nEffectTime, damageInfo)
    local posCast = self:_GetEntityBasePos(casterEntity)
    local posTarget = entityWork:GetDamageCenter() -- gridPos
    self:_PlayEffect(TT, posCast, posTarget, nEffectID, nEffectTime)

    --加血飘字
    if entityWork then
        ---@type PlayDamageService
        local playDamageService = self._world:GetService("PlayDamage")
        damageInfo:SetShowType(DamageShowType.Single)
        playDamageService:AsyncUpdateHPAndDisplayDamage(entityWork, damageInfo)
    end
end
