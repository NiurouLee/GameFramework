require("base_ins_r")

---@class PlayMonsterMoveGridByEleInstruction: BaseInstruction
_class("PlayMonsterMoveGridByEleInstruction", BaseInstruction)
PlayMonsterMoveGridByEleInstruction = PlayMonsterMoveGridByEleInstruction

function PlayMonsterMoveGridByEleInstruction:Constructor(paramList)
    --self._hitAnimName = paramList["hitAnimName"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMonsterMoveGridByEleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectMonsterMoveGridByElementResult[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MonsterMoveGridByMonsterElement)

    if not results then
        Log.fatal("no results")
        return
    end
    ---@type PieceType
    local element = casterEntity:Element():GetPrimaryType()
    ---@type SkillEffectMonsterMoveGridByElementResult
    local result =results[1]

    self._world = casterEntity:GetOwnerWorld()
    ---@type MonsterMoveGridResult[]
    local walkResultList = result:GetWalkResultList()
    local casterIsDead = result:IsCasterDead()
    self:_ShowLinkLine(TT,walkResultList,element)
    self:_DoWalk(TT,casterEntity,walkResultList,casterIsDead)
end
---@param walkResultList MonsterMoveGridResult[]
function PlayMonsterMoveGridByEleInstruction:_ShowLinkLine(TT,walkResultList,element)
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")

    --先清空
    linkageRenderService:DestroyAllLinkLine()

    for i, v in ipairs(walkResultList) do
        if i ~= 1 then
            ---@type MonsterMoveGridResult
            local resultBegin =walkResultList[i - 1]
            local beginPos = resultBegin:GetWalkPos()
            local curPos = v:GetWalkPos()
            local dir = beginPos - curPos
            --新版linerender
            linkageRenderService:CreateLineRender(beginPos, curPos, i, curPos, dir, element)
        end
    end
end

function PlayMonsterMoveGridByEleInstruction:_DestroyLinkLine(moveInPos)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chain_path = previewChainPathCmpt:GetPreviewChainPath()

    local remove_list = {}
    local exist_pos = {}
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    for _, link_line_entity in ipairs(allEntities) do
        local pos = boardServiceRender:GetRealEntityGridPos(link_line_entity)
        if pos == moveInPos then
            table.insert(remove_list, link_line_entity)
            --Log.fatal("destroy link line entity>>>>>>>>>>>>>>",pos.x," ",pos.y)
        end


    end

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    for _, e in ipairs(remove_list) do
        ---Log.fatal("RemoveLinkLineEntity ID:",e:GetID(),"RefreshLinkLine")
        linkageRenderService:DestroyLinkLine(e)
    end
end

---@param walkResultList MonsterMoveGridResult[]
---@param monsterEntity Entity 怪物Entity
function PlayMonsterMoveGridByEleInstruction:_DoWalk(TT, monsterEntity, walkResultList, casterIsDead)
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
        --boardServiceRender:ReCreateGridEntity(newGridType,walkPos,false,false,true)

        while monsterEntity:HasGridMove() do
            YIELD(TT)
        end

        self:_PlayArrivePos(TT, monsterEntity, walkRes)
        --pieceSvc:SetPieceAnimMoveDone(walkPos)
    end

    --for _, v in ipairs(walkResultList) do
    --    local walkRes = v
    --    ---@type Vector2
    --    local walkPos = walkRes:GetWalkPos()
    --    local newGridType = walkRes:GetNewGridType()
    --    local gridEntity =  boardServiceRender:ReCreateGridEntity(newGridType,walkPos,false,false,true)
    --    pieceSvc:SetPieceEntityAnimNormal(gridEntity)
    --    pieceSvc:SetPieceEntityBirth(gridEntity)
    --end

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
function PlayMonsterMoveGridByEleInstruction:_PlayArrivePos(TT, monsterEntity, walkRes)
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

    self:_DestroyLinkLine(walkRes:GetWalkPos())
end

---@param casterEntity Entity
function PlayMonsterMoveGridByEleInstruction:_GetMoveSpeed(casterEntity)
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
function PlayMonsterMoveGridByEleInstruction:StartMoveAnimation(targetEntity, isMove)
    local curVal = targetEntity:GetAnimatorControllerBoolsData("Move")
    if curVal ~= isMove then
        targetEntity:SetAnimatorControllerBools({Move = isMove})
    end
end
