require("base_ins_r")

---@class PlayMonsterMoveGridInstruction: BaseInstruction
_class("PlayMonsterMoveGridInstruction", BaseInstruction)
PlayMonsterMoveGridInstruction = PlayMonsterMoveGridInstruction

function PlayMonsterMoveGridInstruction:Constructor(paramList)
    --self._hitAnimName = paramList["hitAnimName"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMonsterMoveGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectMonsterMoveGridResult[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MonsterMoveGrid)

    if not results then
        Log.fatal("no results")
        return
    end
    ---@type SkillEffectMonsterMoveGridResult
    local result =results[1]

    self._world = casterEntity:GetOwnerWorld()
    ---@type MonsterMoveGridResult[]
    local walkResultList = result:GetWalkResultList()
    local casterIsDead = result:IsCasterDead()
    self:_DoWalk(TT,casterEntity,walkResultList,casterIsDead)
end

---@param walkResultList MonsterMoveGridResult[]
---@param monsterEntity Entity 怪物Entity
function PlayMonsterMoveGridInstruction:_DoWalk(TT, monsterEntity, walkResultList, casterIsDead)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local moveSpeed = self:_GetMoveSpeed(monsterEntity)
    ---走格子
    local hasWalkPoint = false
    if #walkResultList > 0 then
        hasWalkPoint = true
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, true)
        boardServiceRender:RefreshPiece(monsterEntity, true, true)
    end
    ---@type PieceServiceRender
    local pieceSvc =  self._world:GetService("Piece")
    for _, v in ipairs(walkResultList) do
        local walkRes = v
        local walkPos = walkRes:GetWalkPos()

        ---取当前的渲染坐标
        ---@type BoardServiceRender
        local boardServiceRender = self._world:GetService("BoardRender")
        local curPos = boardServiceRender:GetRealEntityGridPos(monsterEntity)

        monsterEntity:AddGridMove(moveSpeed, walkPos, curPos)

        local walkDir = walkPos - curPos
        ---@type BodyAreaComponent
        local bodyAreaCmpt = monsterEntity:BodyArea()
        local areaCount = bodyAreaCmpt:GetAreaCount()
        ---普攻阶段多格的只有四格，以后如果有别的，再处理
        if areaCount == 4 then
            ---取左下位置坐标
            local leftDownPos = Vector2(curPos.x - 0.5, curPos.y - 0.5)
            walkDir = walkPos - leftDownPos
        end

        monsterEntity:SetDirection(walkDir)
        local newGridType = walkRes:GetNewGridType()
        --boardServiceRender:ReCreateGridEntity(newGridType,walkPos,false,false,true)

        while monsterEntity:HasGridMove() do
            YIELD(TT)
        end

        self:_PlayArrivePos(TT, monsterEntity, walkRes)
        pieceSvc:SetPieceAnimMoveDone(walkPos)
    end

    for _, v in ipairs(walkResultList) do
        local walkRes = v
        ---@type Vector2
        local walkPos = walkRes:GetWalkPos()
        local newGridType = walkRes:GetNewGridType()
        local gridEntity =  boardServiceRender:ReCreateGridEntity(newGridType,walkPos,false,false,true)
        pieceSvc:SetPieceEntityAnimNormal(gridEntity)
        pieceSvc:SetPieceEntityBirth(gridEntity)
    end

    if hasWalkPoint then
        self:StartMoveAnimation(monsterEntity, false)
        boardServiceRender:RefreshPiece(monsterEntity, false, true)
    end
    if casterIsDead then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = self._world:GetService("MonsterShowRender")
        sMonsterShowRender:_DoOneMonsterDead(TT, monsterEntity)
    end

end

---@param monsterEntity Entity
---@param walkRes MonsterWalkResult
function PlayMonsterMoveGridInstruction:_PlayArrivePos(TT, monsterEntity, walkRes)
    ---触发机关的表现
    local trapResList = walkRes:GetWalkTrapResultList()
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
                walkRes:GetWalkPos(),
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

---@param casterEntity Entity
function PlayMonsterMoveGridInstruction:_GetMoveSpeed(casterEntity)
    ---@type ConfigService
    local cfgSvc = self._world:GetService("Config")
    ---@type MonsterConfigData 怪物配置数据
    local configData = cfgSvc:GetMonsterConfigData()

    ---@type MonsterIDComponent
    local monsterIDCmpt = casterEntity:MonsterID()
    local monsterID = monsterIDCmpt:GetMonsterID()

    local speed = configData:GetMonsterSpeed(monsterID)
    speed = speed or 1

    return speed
end

---@param targetEntity Entity
function PlayMonsterMoveGridInstruction:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({Move = isMove})
    end
end
