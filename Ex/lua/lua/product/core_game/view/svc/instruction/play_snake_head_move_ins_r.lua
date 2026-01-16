
---@class PlaySnakeHeadMoveInstruction:BaseInstruction
_class("PlaySnakeHeadMoveInstruction", BaseInstruction)
PlaySnakeHeadMoveInstruction = PlaySnakeHeadMoveInstruction

function PlaySnakeHeadMoveInstruction:Constructor(paramList)
    self._moveAnim = paramList["MoveAnim"]
end

function PlaySnakeHeadMoveInstruction:GetCacheResource()
    --local t = {}
    --table.insert(t, {self.effectName, 1})
    --return t
end
---@param casterEntity Entity
function PlaySnakeHeadMoveInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectSnakeHeadMoveResult
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SnakeHeadMove)
    if not resultArray then
        return
    end
    ---@type SkillEffectSnakeHeadMoveResult
    local result = resultArray[#resultArray]
    local oldPos = result:GetOldPos()
    local newPos = result:GetNewPos()
    ---@type PlaySkillInstructionService
    local playSkillInstructionSvc = world:GetService("PlaySkillInstruction")
    local casterIsDead = result:GetCasterIsDead()
    if  casterIsDead then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = world:GetService("MonsterShowRender")
        sMonsterShowRender:_DoOneMonsterDead(TT, casterEntity)
    else
        local trapResList = result:GetTriggerTrapResult()
        local moveSpeed = playSkillInstructionSvc:GetMoveSpeed(casterEntity)
        playSkillInstructionSvc:PlayEntityMove(TT,casterEntity,oldPos,newPos,moveSpeed)
        playSkillInstructionSvc:PlayArrivePosTriggerTrap(TT,casterEntity,newPos,trapResList)
        world:GetService("PlayBuff"):PlayBuffView(TT, NTSnakeHeadMoved:New(casterEntity,newPos,oldPos))
    end
end

---@param monsterEntity Entity
---@param trapResList WalkTriggerTrapResult[]
function PlaySnakeHeadMoveInstruction:_PlayArrivePosTriggerTrap(TT, monsterEntity,pos, trapResList)
    ---触发机关的表现
    for _, v in ipairs(trapResList) do
        ---@type WalkTriggerTrapResult
        local walkTrapRes = v
        local trapEntityID = walkTrapRes:GetTrapEntityID()
        local trapEntity = self._world:GetEntityByID(trapEntityID)
        ---@type AISkillResult
        local trapSkillRes = walkTrapRes:GetTrapResult()
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = trapSkillRes:GetResultContainer()
        trapEntity:SkillRoutine():SetResultContainer(skillEffectResultContainer)

        Log.debug(
                "[AIMove] PlayArrivePos() monster=",
                monsterEntity:GetID(),
                " pos=",
                pos,
                " play trapid=",
                trapEntity:GetID(),
                " defender=",
                skillEffectResultContainer:GetScopeResult():GetTargetIDs()[1]
        )

        ---@type TrapServiceRender
        local trapSvc = self._world:GetService("TrapRender")
        trapSvc:PlayTrapTriggerSkill(TT, trapEntity, false, monsterEntity)
    end
end
