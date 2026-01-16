require("base_ins_r")
---@class PlayTrapAsMovingInstruction: BaseInstruction
_class("PlayTrapAsMovingInstruction", BaseInstruction)
PlayTrapAsMovingInstruction = PlayTrapAsMovingInstruction

function PlayTrapAsMovingInstruction:Constructor(paramList)
    self._time = tonumber(paramList.time)
    self._speed = tonumber(paramList.speed)
    self._stageIndex = tonumber(paramList.stageIndex) or 1
    assert(self._time or self._speed, "PlayTrapAsMoving指令需要配置time参数")

    self._summonOffset = tonumber(paramList.summonOffset)
    self._moveAni = paramList.moveAni
    self._moveEffID = tonumber(paramList.moveEffID)
    self._jumpAni = paramList.jumpAni
    self._jumpEffID = tonumber(paramList.jumpEffID)
    self._jumpTime = tonumber(paramList.jumpTime)
    self._fallAni = paramList.fallAni
    self._fallEffID = tonumber(paramList.fallEffID)
    self._fallTime = tonumber(paramList.fallTime)
end

function PlayTrapAsMovingInstruction:GetCacheResource()
    local t = {}
    if self._moveEffID and self._moveEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._moveEffID].ResPath, 1 })
    end
    if self._jumpEffID and self._jumpEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._jumpEffID].ResPath, 1 })
    end
    if self._fallEffID and self._fallEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._fallEffID].ResPath, 1 })
    end
    return t
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTrapAsMovingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillSummonTrapEffectResult
    local summonResult = routineComponent:GetEffectResultByArray(SkillEffectType.SummonTrap, self._stageIndex)
    ---@type SkillEffectResultMoveTrap
    local moveResult = routineComponent:GetEffectResultByArray(SkillEffectType.MoveTrap, self._stageIndex)
    ---@type SkillEffectDestroyTrapResult
    local destroyResult = routineComponent:GetEffectResultByArray(SkillEffectType.DestroyTrap, self._stageIndex)
    ---@type EffectService
    local effectService = world:GetService("Effect")

    local posOld = Vector2.zero
    local posNew = Vector2.zero
    local casterPos = casterEntity:GetRenderGridPosition()
    local casterDir = casterEntity:GetRenderGridDirection()
    ---@type Entity
    local trapEntity = nil
    if summonResult then
        posOld = casterPos + casterDir:SetNormalize() * self._summonOffset
        posNew = summonResult:GetPos()
        local entityIDList = summonResult:GetTrapIDList()
        if #entityIDList == 0 then
            return
        end
        trapEntity = world:GetEntityByID(entityIDList[1])
        --召出
        self:_ShowTrap(TT, world, trapEntity, posOld)
        YIELD(TT)
    elseif moveResult then
        posOld = moveResult:GetPosOld()
        posNew = moveResult:GetPosNew()
        local entityID = moveResult:GetEntityID()
        trapEntity = world:GetEntityByID(entityID)
        casterDir = (posNew - posOld):SetNormalize()
    elseif destroyResult then
        local entityID = destroyResult:GetEntityID()
        trapEntity = world:GetEntityByID(entityID)
        posOld = trapEntity:GetRenderGridPosition()
        posNew = casterPos
    end

    if not trapEntity then
        return
    end

    if posOld == posNew then
        return
    end

    local distance = Vector2.Distance(posNew, posOld)
    local speed = self._speed
    if self._time then
        speed = distance / self._time * 1000
    end

    while (trapEntity:HasGridMove()) do
        YIELD(TT)
    end

    --起跳动作及特效
    trapEntity:SetAnimatorControllerTriggers({ self._jumpAni })
    if self._jumpEffID and self._jumpEffID ~= 0 then
        effectService:CreateEffect(self._jumpEffID, trapEntity)
    end
    YIELD(TT, self._jumpTime)

    --瞬移动作及特效
    trapEntity:SetAnimatorControllerTriggers({ self._moveAni })
    if self._moveEffID and self._moveEffID ~= 0 then
        effectService:CreateEffect(self._moveEffID, trapEntity)
    end

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local gridPos = boardServiceRender:GetRealEntityGridPos(trapEntity)
    trapEntity:AddGridMove(speed, posNew, gridPos)
    while (trapEntity:HasGridMove()) do
        YIELD(TT)
    end

    --下落动作及特效
    trapEntity:SetAnimatorControllerTriggers({ self._fallAni })
    if self._fallEffID and self._fallEffID ~= 0 then
        effectService:CreateEffect(self._fallEffID, trapEntity)
    end
    YIELD(TT, self._fallTime)

    --设置位置
    local viewPos = posNew:Clone()
    local offset = trapEntity:GetGridOffset()
    if offset then
        viewPos = viewPos + offset
    end
    trapEntity:SetLocation(viewPos, casterDir)

    if destroyResult then
        ---@type TrapServiceRender
        local trapServiceRender = world:GetService("TrapRender")
        trapServiceRender:PlayTrapDieSkill(TT, { trapEntity }, 1)
    end
    if moveResult then
        ---@type PlayBuffService
        local playBuffSvc = world:GetService("PlayBuff")
        ---@type NTMoveTrap
        local NTMoveTrap = NTMoveTrap:New()
        playBuffSvc:PlayBuffView(TT, NTMoveTrap)
    end
end

---@param world MainWorld
---@param trapEntity Entity
---@param posSummon Vector2
function PlayTrapAsMovingInstruction:_ShowTrap(TT, world, trapEntity, posSummon)
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)

    trapEntity:SetPosition(posSummon)
end
