--[[------------------------------------------------------------------------------------------
    ClientRoleMovementSystem_Render：只执行客户端的表现，禁止逻辑相关
]] --------------------------------------------------------------------------------------------
require "role_movement_system"

---@class ClientRoleMovementSystem_Render:RoleMovementSystem
_class("ClientRoleMovementSystem_Render", RoleMovementSystem)
ClientRoleMovementSystem_Render = ClientRoleMovementSystem_Render

function ClientRoleMovementSystem_Render:_DoRenderPetHeadShow(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()

    for i, eId in ipairs(petRoundTeam) do
        local pet = self._world:GetEntityByID(eId)
        local cPetPstId = pet:PetPstID()
        self._world:EventDispatcher():Dispatch(GameEventType.InOutQueue, cPetPstId:GetPstID(), true)
    end

    ---@type ChainPreviewMonsterBehaviorComponent
    local chainPreviewMonsterBehaviorCmpt = renderBoardEntity:ChainPreviewMonsterBehavior()
    chainPreviewMonsterBehaviorCmpt:SetChainPath({})
end

---@param team Entity
function ClientRoleMovementSystem_Render:_DoRendererMove(TT, team)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local chain_path = renderBoardEntity:RenderChainPath():GetRenderChainPath()

    local teamLeaderEntity = team:GetTeamLeaderPetEntity()
    if not teamLeaderEntity:HasChainMove() then
        local petRoundTeam = self:_GetRoleTurnPetRoundTeam()
        if #petRoundTeam > 0 then
            local startPos = teamLeaderEntity:GetRenderGridPosition()
            local startDir = teamLeaderEntity:GetRenderGridDirection()
            for i, petEntityID in ipairs(petRoundTeam) do
                local petEntity = self._world:GetEntityByID(petEntityID)
                petEntity:AddChainMove({}, 0, 0, 0) --刚开始给所有行动角色都加上ChainMove组件，以防止第一个成员结束之后因为第二个成员还未出现导致判定都执行完了
            end
            team:ReplacePlayerMovingFlag()
            TaskManager:GetInstance():CoreGameStartTask(self._PetMoveTask, self, chain_path, startPos, startDir)
        end
    end
    while team:HasPlayerMovingFlag() do
        YIELD(TT, 100)
    end
end

---@param chain_path Vector2[] 链式路径
---@param startPos Vector2 起点
---@param startDir Vector2 起始朝向
function ClientRoleMovementSystem_Render:_PetMoveTask(TT, chain_path, startPos, startDir)
    local petRoundTeam = self:_GetRoleTurnPetRoundTeam()
    for i, petEntityID in ipairs(petRoundTeam) do
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)

        petEntity:SetLocation(startPos, startDir)

        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type L2R_NormalAttackResult
        local normalAtkRes = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)
        --出发延时
        local startWaitTime = normalAtkRes:GetPathMoveStartWaitTime() * 1000

        --等前一个成员不在起始位了再走，以免显示成员后同时出现在起始位（只是保险 基本不会等）
        if i > 1 then
            while self:IsPrevPetsAtStartPos(i, startPos, petRoundTeam) do
                YIELD(TT)
            end
        end

        local timeService = self._world:GetService("Time")
        local curtime = timeService:GetCurrentTimeMs()
        petEntity:ReplaceChainMove(chain_path, 1, curtime, BattleConst.MoveSpeed)
        self._world:EventDispatcher():Dispatch(GameEventType.IdleEnd, 1, petEntity:GetID())

        YIELD(TT, startWaitTime)
    end
end

---@param curIdx number 当前宠物在es中的索引
---@param startPos Vector2 起始位置
---@param es number[] 宠物实体ID数组
---当前宠物之前的宠物在不在起始位
function ClientRoleMovementSystem_Render:IsPrevPetsAtStartPos(curIdx, startPos, es)
    if not es then
        return
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local nCount = math.min(#es, curIdx - 1)
    for i = 1, nCount, 1 do
        ---@type Entity
        local e = self._world:GetEntityByID(es[i])
        local posWork = boardServiceRender:GetRealEntityGridPos(e)
        if posWork == startPos then
            ---@type ChainMoveComponent
            local chainMoveCmp = e:ChainMove()
            if chainMoveCmp and chainMoveCmp:GetPathIndex() == 1 then
                return true
            end
        end
    end
end

function ClientRoleMovementSystem_Render:_GetRoleTurnPetRoundTeam()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()
    return petRoundTeam
end

function ClientRoleMovementSystem_Render:_DoRenderNotifyBuff(TT, elementType, teamEntity)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT,NTTeamNormalAttackStart:New())
    ---@type NTPlayerMoveStart
    local ntPlayerMoveStart = NTPlayerMoveStart:New()
    ntPlayerMoveStart:SetChainPathType(elementType)
    ntPlayerMoveStart:SetTeamEntity(teamEntity)
    playBuffSvc:PlayBuffView(TT, ntPlayerMoveStart)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()
    local chain_path = renderBoardEntity:RenderChainPath():GetRenderChainPath()
    for i, eId in ipairs(petRoundTeam) do
        local petEntity = self._world:GetEntityByID(eId)
        playBuffSvc:PlayBuffView(TT, NTNormalAttackStart:New(petEntity, elementType, chain_path))
    end
end

function ClientRoleMovementSystem_Render:_DoRenderNotifyBuffNormalAttackEnd(TT)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()
    for i, eId in ipairs(petRoundTeam) do
        local petEntity = self._world:GetEntityByID(eId)
        playBuffSvc:PlayBuffView(TT, NTNormalAttackEnd:New(petEntity))
    end
end

function ClientRoleMovementSystem_Render:_DoRenderResetPieceAnim(TT)
    --格子刷新一次材质
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:RefreshPieceAnim()
    pieceService:RefreshMonsterAreaOutLine(TT)
end

function ClientRoleMovementSystem_Render:_SendPrismNotify(TT)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTCovCrystalPrism:New())
end