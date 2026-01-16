_class("PlaySkillPhaseBase", Object)
---@class PlaySkillPhaseBase: Object
PlaySkillPhaseBase = PlaySkillPhaseBase

function PlaySkillPhaseBase:Constructor(skillService, world)
	---@type PlaySkillService
    self._skillService = skillService
    ---@type MainWorld
    self._world = world
    self._startTick = GameGlobal:GetInstance():GetCurrentTime()

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type TimeService
    self._timeService = self._world:GetService("Time")

    ---@type EffectService
    self._effectService = self._world:GetService("Effect")

end

function PlaySkillPhaseBase:PrepareToPlay(TT, casterEntity, phaseParam)    
end

function PlaySkillPhaseBase:BeginPlay(TT, casterEntity, firstPhaseParam)
    self._startTick = GameGlobal:GetInstance():GetCurrentTime()
end
function PlaySkillPhaseBase:PlayFlight(TT, casterEntity, phaseParam)
end
function PlaySkillPhaseBase:EndPlay(TT, casterEntity, phaseParam)
end

function PlaySkillPhaseBase:_GetElapseTick()
    return math.floor(GameGlobal:GetInstance():GetCurrentTime() - self._startTick)
end
---@return PlaySkillService
function PlaySkillPhaseBase:SkillService()
    return self._skillService
end

--------------------------------    ---2019-19-20 韩玉信添加
function PlaySkillPhaseBase:_DelayTime(TT, nTime)
    if nTime and nTime > 0 then
        YIELD(TT, nTime)
    end
end
---@param entityWork Entity
---获取Entity的基准坐标
function PlaySkillPhaseBase:_GetEntityBasePos(entityWork)
    local posTarget = nil --Vector2(0, 0)
    if nil == entityWork then
        return posTarget
    end
    return entityWork:GetGridPosition()
end
function PlaySkillPhaseBase:_GetEntityCenterPos(entityWork)
    local posTarget = nil --Vector2(0, 0)
    if nil == entityWork then
        return posTarget
    end
    return entityWork:GetDamageCenter()
end
function PlaySkillPhaseBase:_GetEntityBasePosByID(nEntityID)
    local entityWork = self._world:GetEntityByID(nEntityID)
    return self:_GetEntityBasePos(entityWork)
end
---在特定位置播放一个特效
function PlaySkillPhaseBase:_PlayEffect(TT, posCast, posTarget, gridEffectID, nEffectDelayTime, fxNoRotation)
    if nil == gridEffectID or gridEffectID <= 0 then
        return
    end
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    local posDirectory = posTarget - posCast
    if fxNoRotation then
        posDirectory = Vector2.zero
    end
    effectService:CreateWorldPositionDirectionEffect(gridEffectID, posTarget, posDirectory)
    self:_DelayTime(TT, nEffectDelayTime)
end
---@param casterEntity Entity
function PlaySkillPhaseBase:_PlayAnimationEffect(TT, casterEntity, stAnimationName, nEffectID, nEffectTime)
    --施法者动作
    if stAnimationName and "" ~= stAnimationName then
        casterEntity:SetAnimatorControllerTriggers({stAnimationName})
        Log.debug("[Animation]: 播放动画[" .. stAnimationName .. "]" )
    end
    --施法者特效
    if nEffectID then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local listEffectID = {}
        if type(nEffectID) == "number" then
            if nEffectID > 0 then    ---2019-12-17增加支持配置为空或者0，来跳过本阶段
                listEffectID[#listEffectID + 1] = nEffectID
            end
        elseif type(nEffectID) == "table" then
            listEffectID = nEffectID
        end
        for i = 1, #listEffectID do
            effectService:CreateEffect(listEffectID[i], casterEntity)
            ---Log.debug("[Animation]: 播放动画[" .. stAnimationName .. "], 特效[".. nEffectID .."], 时长[".. nEffectTime .. "]" )
        end
    end
    self:_DelayTime(TT, nEffectTime );
end
function PlaySkillPhaseBase:_WaitSonTask(listTask)
    if table.count(listTask) > 0 then
        while not TaskHelper:GetInstance():IsAllTaskFinished(listTask) do
            YIELD(TT)
        end
    end
end
---@param posWork Vector2
function PlaySkillPhaseBase:_MakePosString(posWork)
    return GameHelper.MakePosString(posWork)
end
----------------------------------------------------------------
