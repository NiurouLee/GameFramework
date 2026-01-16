require("base_ins_r")
---@class PlayTeleportAsMovingInstruction: BaseInstruction
_class("PlayTeleportAsMovingInstruction", BaseInstruction)
PlayTeleportAsMovingInstruction = PlayTeleportAsMovingInstruction

function PlayTeleportAsMovingInstruction:Constructor(paramList)
    self._time = tonumber(paramList.time)
    self._speed = tonumber(paramList.speed)
    self._stageIndex = tonumber(paramList.stageIndex) or 1
    assert(self._time or self._speed, "PlayTeleportAsMoving指令需要配置time参数")
    self._notifyBuff = tonumber(paramList.notifyBuff) or 1
    self._leftAnimName = paramList.leftAnimName
    self._rightAnimName = paramList.rightAnimName
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTeleportAsMovingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportResult = routineComponent:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)

    if not teleportResult then
        return
    end

    local world = casterEntity:GetOwnerWorld()
    local teleportedEntityID = teleportResult:GetTargetID()
    local teleportedEntity = world:GetEntityByID(teleportedEntityID)

    if not teleportedEntity then
        return
    end

    local posOld = teleportResult:GetPosOld()
    local posNew = teleportResult:GetPosNew()

    if posOld == posNew then
        if self._notifyBuff == 1 then
            world:GetService("PlayBuff"):PlayBuffView(TT, NTTeleport:New(casterEntity, posOld, posNew))
        end
        return
    end

    local animName = nil
    if posOld.x < posNew.x then
        animName = self._leftAnimName
    elseif posOld.x > posNew.x then
        animName = self._rightAnimName
    end
    if animName then
        casterEntity:SetAnimatorControllerTriggers({ animName })
    end

    -- GridMoveSystem的起始位置是从GridLocation取的
    -- Teleport逻辑是立刻将GridLocation更新的
    -- GridLocation和GridMove之间还有点其他的关系
    -- 牵扯的东西实在太多了，为了能顺利完成演出，这里会临时绕一下这个逻辑
    --teleportedEntity:SetGridPosition(posOld)
    if casterEntity:HasPetPstID() then
        local boardService = world:GetService("BoardRender")
        local oldPos = teleportResult:GetPosOld()
        local oldColor = teleportResult:GetColorOld()
        boardService:ReCreateGridEntity(oldColor, oldPos)
    end
    --teleportedEntity:SetPosition(posOld)
    YIELD(TT)

    local distance = Vector2.Distance(posNew, posOld)
    local speed = self._speed
    if self._time then
        speed = distance / self._time * 1000
    end

    if casterEntity:HasMonsterID() then
        ---@type RenderEntityService
        local renderEntityService = world:GetService("RenderEntity")
        renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
    end
    self:_PlayCasterControlGridDown(casterEntity, 0)

    while (teleportedEntity:HasGridMove()) do
        local gridMoveComponent = teleportedEntity:GridMove()
        YIELD(TT)
    end
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local gridPos = boardServiceRender:GetRealEntityGridPos(teleportedEntity)
    teleportedEntity:AddGridMove(speed, posNew, gridPos)

    while (teleportedEntity:HasGridMove()) do
        YIELD(TT)
    end

    local viewPos = posNew:Clone()
    local offset = teleportedEntity:GetGridOffset()
    if offset then
        viewPos = viewPos + offset
    end
    teleportedEntity:SetPosition(viewPos)
    local dir = teleportResult:GetDirNew() --[[teleportedEntity:GetDirection()]]
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    if casterEntity:HasPetPstID() then
        local boardService = world:GetService("BoardRender")
        local newColor = teleportResult:GetColorNew()
        local newPos = teleportResult:GetPosNew()
        boardService:ReCreateGridEntity(newColor, newPos)
        trapServiceRender:ShowHideTrapAtPos(newPos, false)
        --处理棱镜格
        ---@type Entity
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        local teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
        local pets = teamEntity:Team():GetTeamPetEntities()
        ---@param petEntity Entity
        for i, petEntity in ipairs(pets) do
            petEntity:SetPosition(posNew, dir)
        end
        teamEntity:SetLocation(posNew, dir)
        teamLeaderEntity:SetLocation(posNew, dir)

        pieceService:RemovePrismAt(newPos)
    elseif casterEntity:HasMonsterID() then
        local trapIDList = teleportResult:GetTriggerTrapIDList()
        local trapEntityList = {}
        for _, v in ipairs(trapIDList) do
            local trapEntity = world:GetEntityByID(v)
            trapEntityList[#trapEntityList + 1] = trapEntity
        end
        ---@type PlaySkillInstructionService
        local sPlaySkillInstruction = world:GetService("PlaySkillInstruction")
        sPlaySkillInstruction:PlayTrapTrigger(TT, casterEntity, trapEntityList)

        ---@type RenderEntityService
        local renderEntityService = world:GetService("RenderEntity")
        renderEntityService:DestroyMonsterAreaOutLineEntity(casterEntity)
        renderEntityService:CreateMonsterAreaOutlineEntity(casterEntity)
    elseif casterEntity:HasTrapID() then
        if casterEntity:HasTrapRoundInfoRender() then
            local eid = casterEntity:TrapRoundInfoRender():GetRoundInfoEntityID()
            if eid then
                local eff = world:GetEntityByID(eid)
                eff:AddGridMove(self._speed, posNew, posOld)
            end
        end
    end
    self:_PlayCasterControlGridDown(casterEntity, 1)

    if self._notifyBuff == 1 then
        world:GetService("PlayBuff"):PlayBuffView(TT, NTTeleport:New(casterEntity, posOld, posNew))
    end
end

function PlayTeleportAsMovingInstruction:_PlayCasterControlGridDown(casterEntity, enable)
    if casterEntity:MonsterID() then
        ---@type MonsterIDComponent
        local monsterIDCmpt = casterEntity:MonsterID()
        monsterIDCmpt:SetNeedGridDownEnable(enable == 1)
    elseif casterEntity:HasTrapID() then
        ---@type TrapRenderComponent
        local trapRender = casterEntity:TrapRender()
        trapRender:SetNeedGridDownEnable(enable == 1)
    else
        return
    end
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = casterEntity:BodyArea()
    local areaArray = bodyAreaCmpt:GetArea()
    ---@type PieceServiceRender
    local pieceSvc = world:GetService("Piece")
    local monsterGridPos = casterEntity:GetRenderGridPosition()
    for i = 1, #areaArray do
        local curAreaPos = areaArray[i]
        local pos = Vector2(curAreaPos.x + monsterGridPos.x, curAreaPos.y + monsterGridPos.y)
        if enable == 1 then
            pieceSvc:SetPieceAnimDark(pos)
        else
            pieceSvc:SetPieceAnimNormal(pos)
        end
    end
end
