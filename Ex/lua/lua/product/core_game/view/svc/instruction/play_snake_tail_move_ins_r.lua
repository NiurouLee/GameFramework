
---@class PlaySnakeTailMoveInstruction:BaseInstruction
_class("PlaySnakeTailMoveInstruction", BaseInstruction)
PlaySnakeTailMoveInstruction = PlaySnakeTailMoveInstruction

function PlaySnakeTailMoveInstruction:Constructor(paramList)
    self._moveAnim = paramList["MoveAnim"]
end

function PlaySnakeTailMoveInstruction:GetCacheResource()
    --local t = {}
    --table.insert(t, {self.effectName, 1})
    --return t
end
---@param casterEntity Entity
function PlaySnakeTailMoveInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectSnakeTailMoveResult[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SnakeTailMove)
    if not resultArray then
        return
    end
    ---@type SkillEffectSnakeTailMoveResult
    local result = resultArray[#resultArray]
    if result:IsCasterDead() then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = world:GetService("MonsterShowRender")
        sMonsterShowRender:_DoOneMonsterDead(TT, casterEntity)
        return
    end
    if not result:GetNewPos() then
        return
    end
    local oldPos = casterEntity:GetRenderGridPosition()
    local newPos = result:GetNewPos()
    ---@type PlaySkillInstructionService
    local playSkillInstructionSvc = world:GetService("PlaySkillInstruction")
    local trapResList = result:GetTriggerTrapResult()
    local moveSpeed = playSkillInstructionSvc:GetMoveSpeed(casterEntity)
    playSkillInstructionSvc:PlayEntityMove(TT,casterEntity,oldPos,newPos,moveSpeed)
    local bodyPos = result:GetLastBodyPos()
    local dir = bodyPos - newPos
    casterEntity:SetDirection(dir)
    playSkillInstructionSvc:PlayArrivePosTriggerTrap(TT,casterEntity,newPos,trapResList)
    world:GetService("PlayBuff"):PlayBuffView(TT, NTSnakeTailMoved:New(casterEntity,newPos,oldPos))
end