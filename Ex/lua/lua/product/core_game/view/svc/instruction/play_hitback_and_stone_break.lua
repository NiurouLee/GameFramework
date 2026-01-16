
---@class PlayHitBackAndStoneBreakInstruction:BaseInstruction
_class("PlayHitBackAndStoneBreakInstruction", BaseInstruction)
PlayHitBackAndStoneBreakInstruction = PlayHitBackAndStoneBreakInstruction

function PlayHitBackAndStoneBreakInstruction:Constructor(paramList)

end

function PlayHitBackAndStoneBreakInstruction:GetCacheResource()
    local t = {}
    return t
end
---@param casterEntity Entity
function PlayHitBackAndStoneBreakInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    self._world = casterEntity:GetOwnerWorld()
    local bodyArea = casterEntity:BodyArea():GetArea()
    local casterPos = casterEntity:GetRenderGridPosition()
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ----@type SkillHitBackEffectResult[1]
    local resultList = resultContainer:GetEffectResultsAsArray(SkillEffectType.HitBack)
    ---@type SkillHitBackEffectResult
    local hitBackResult =resultList[1]
    local targetID = hitBackResult:GetTargetID()
    local hitBackDir = hitBackResult:GetHitDir()
    local newPos = hitBackResult:GetPosTarget()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)


    ---@type SkillEffectDestroyTrapResult[]
    local resultList2 = resultContainer:GetEffectResultsAsArray(SkillEffectType.DestroyTrap, 2)
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    self._taskID ={}

    local targetRealPos = targetEntity:GetRenderGridPosition()
    while targetRealPos.x ~= newPos.x or
            targetRealPos.y ~= newPos.y do
        self:PlayDestroyTrap(TT, resultList2, targetEntity, hitBackDir, trapServiceRender)
        targetRealPos = targetEntity:GetRenderGridPosition()
        YIELD(TT)
    end
    self:PlayDestroyTrap(TT,resultList2,targetEntity,hitBackDir,trapServiceRender)
    while not TaskHelper:GetInstance():IsAllTaskFinished(self._taskID) do
        YIELD(TT)
    end
end


function PlayHitBackAndStoneBreakInstruction:PlayDestroyTrap(TT,resultList,casterEntity,teleportDir,trapServiceRender)
    if not resultList then
        return
    end
    for i, v in ipairs(resultList) do
        local pos = v:GetTrapPos()
        local entityID=  v:GetEntityID()
        local entity = self._world:GetEntityByID(entityID)
        ---@type TrapRenderComponent
        local trapRenderCmpt = entity:TrapRender()
        local hadPlayDead = trapRenderCmpt:GetHadPlayDead()
        if self:NeedPlayDead(casterEntity,pos,teleportDir) and not hadPlayDead then
            local id= GameGlobal.TaskManager():CoreGameStartTask(trapServiceRender.PlayTrapDieSkill,
                    trapServiceRender,{entity})
            table.insert(self._taskID,id)
        end
    end
end
function PlayHitBackAndStoneBreakInstruction:NeedPlayDead(casterEntity,pos,teleportDir)
    local casterRealPos = casterEntity:GetRenderGridPosition()
    if teleportDir == Vector2(0,1) then
        if pos.y<= casterRealPos.y then
            return true
        end
    elseif teleportDir == Vector2(0,-1) then
        if pos.y>= casterRealPos.y then
            return true
        end
    elseif teleportDir == Vector2(1,0) then
        if pos.y>= casterRealPos.y then
            return true
        end
    elseif teleportDir == Vector2(-1,0) then
        if pos.y>= casterRealPos.y then
            return true
        end
    end
    return false
end
