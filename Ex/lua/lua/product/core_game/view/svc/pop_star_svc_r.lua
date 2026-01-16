--[[------------------------------------------------------------------------------------------
    PopStarServiceRender: 战棋模式下的各种表现函数
]]
--------------------------------------------------------------------------------------------

_class("PopStarServiceRender", BaseService)
---@class PopStarServiceRender:BaseService
PopStarServiceRender = PopStarServiceRender

--计算消灭星星的联通区
function PopStarServiceRender:CalculatePopStarConnectPieces(gridPos)
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieceType = env:GetPieceType(gridPos)
    local pieces = env:GetAllPieceType()

    local connMap = {}
    for x, _ in pairs(pieces) do
        connMap[x] = {}
    end

    local connectPieces = {}
    table.insert(connectPieces, gridPos)
    connMap[gridPos.x][gridPos.y] = true

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local searchConnectPiece = function(center, next)
        for _, offset in ipairs(Offset4) do
            local pos = Vector2(center.x + offset[1], center.y + offset[2])
            if utilDataSvc:IsValidPiecePos(pos) then
                local connectPieceType = env:GetPieceType(pos)
                local pieceMatch = PopStarCanMatchPieceType(pieceType, connectPieceType)
                if not connMap[pos.x][pos.y] and pieceMatch then
                    table.insert(connectPieces, pos)
                    connMap[pos.x][pos.y] = true
                    next(pos, next)
                end
            end
        end
    end

    searchConnectPiece(gridPos, searchConnectPiece)
    return connectPieces
end

---预览消除区域
function PopStarServiceRender:PreviewPopArea(connectPieces)
    -- ---压暗场景
    -- ---@type MainCameraComponent
    -- local mainCameraCmpt = self._world:MainCamera()
    -- mainCameraCmpt:EnableDarkCamera(true)

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    ---压暗格子
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, pieceEntity in ipairs(pieceGroup:GetEntities()) do
        ---@type GridLocationComponent
        local gridLocationCmpt = pieceEntity:GridLocation()
        local gridPos = gridLocationCmpt.Position
        if not table.icontains(connectPieces, gridPos) then
            pieceService:SetPieceAnimDark(gridPos)
        end
    end
end

---显示消除格子数量
function PopStarServiceRender:ShowPopGridNum(connectPieces)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---获取强化格子数量
    local superGridNum = 0
    for _, pos in ipairs(connectPieces) do
        local trapList = utilDataSvc:FindTrapByTypeAndPos(TrapType.PopStar_Super, pos)
        if trapList and #trapList > 0 then
            superGridNum = superGridNum + 1
        end
    end

    local gridNum = #connectPieces

    ---通知UI显示
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarShowPopNum, true, gridNum, superGridNum)
end

---显示道具提示
function PopStarServiceRender:ShowPreviewTrap(trapEntityID, gridPos, offset)
    ---@type PreviewMonsterTrapService
    local previewSvc = self._world:GetService("PreviewMonsterTrap")
    previewSvc:ShowPreviewTrap(trapEntityID, gridPos, offset)
end

---清理预览表现
function PopStarServiceRender:ClearPreviewPop(connectPieces)
    ---取消压暗场景
    ---@type MainCameraComponent
    local mainCameraCmpt = self._world:MainCamera()
    mainCameraCmpt:EnableDarkCamera(false)

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    ---取消压暗格子
    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, pieceEntity in ipairs(pieceGroup:GetEntities()) do
        ---@type GridLocationComponent
        local gridLocationCmpt = pieceEntity:GridLocation()
        local gridPos = gridLocationCmpt.Position
        if not table.icontains(connectPieces, gridPos) then
            pieceService:SetPieceAnimNormal(gridPos)
        end
    end

    self:_HidePopGridNum()
    self:ClearPreviewTrap()
end

---隐藏消除格子数量
function PopStarServiceRender:_HidePopGridNum()
    ---通知UI隐藏
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarShowPopNum, false)
end

---隐藏道具提示
function PopStarServiceRender:ClearPreviewTrap()
    ---@type PreviewMonsterTrapService
    local previewSvc = self._world:GetService("PreviewMonsterTrap")
    previewSvc:ClearPreviewTrap()
end

---消除表现
function PopStarServiceRender:PopConnectPieces(connectPieces)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---消除表现
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    for _, gridPos in ipairs(connectPieces) do
        local trapList = utilDataSvc:FindTrapByTypeAndPos(TrapType.PopStar_Lock, gridPos)
        if trapList and #trapList > 0 then
        else
            pieceService:SetPieceAnimMoveDone(gridPos)
        end
    end
end

---@param result DataPopStarResult
function PopStarServiceRender:PlayPopStarResult(TT, result)
    if not result then
        return
    end

    local isIndexChange = result:IsIndexChange()
    if isIndexChange then
        ---通知UI更改阶段信息
        self._world:EventDispatcher():Dispatch(GameEventType.PopStarRefreshStageInfo)
    end

    ---发送分数变化通知
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT, NTPopStarScoreChange:New())

    ---通知UI显示
    if not isIndexChange then
        self._world:EventDispatcher():Dispatch(GameEventType.PopStarRefreshProgressInfo, result:GetPopNum())
    end

    ---表现待调整
    YIELD(TT, BattleConst.PopStarPopWaitTime)

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    ---删除格子隐藏，放到池里
    local pool = {}
    for i, v in ipairs(result:GetDelSet()) do
        local pieceEntity = renderBoardCmpt:GetGridRenderEntity(v.pos)
        pieceEntity:SetViewVisible(false)
        renderBoardCmpt:RemoveGridRenderEntityData(v.pos)
        pool[i] = pieceEntity
    end

    ---删除机关
    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")
    trapSvc:PlayTrapDieSkill(TT, result:GetDelTrapList())

    local moveEntities = {}

    ---下落格子表现
    local movePieces = {}
    for i, v in ipairs(result:GetMoveSet()) do
        local gridEntity = renderBoardCmpt:GetGridRenderEntity(v.from)
        local distance = math.abs(v.to.x - v.from.x) + math.abs(v.to.y - v.from.y)
        local speed = distance / BattleConst.FallGridTime
        gridEntity:AddGridMove(speed, v.to, v.from)
        moveEntities[#moveEntities + 1] = gridEntity
        movePieces[i] = { gridEntity, v.to }
    end
    for i, v in ipairs(movePieces) do
        local gridEntity = v[1]
        local pos = v[2]
        gridEntity:SetGridPosition(pos)
        renderBoardCmpt:SetGridRenderEntityData(pos, gridEntity)
    end

    ---新格子出现
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    ---设置格子移动时的高度，避免重叠--没有分列
    local newSetCount = #result:GetNewSet()
    local hPerGrid = 0.01
    local waitRestHeightGrids = {}
    for i, v in ipairs(result:GetNewSet()) do
        local gridEntity = pool[i]
        local gridPrefabPath = boardServiceR:_GetGridPrefabPath(v.color)
        gridEntity:ReplaceAsset(NativeUnityPrefabAsset:New(gridPrefabPath, true))
        gridEntity:ReplacePiece(v.color)
        gridEntity:SetGridPosition(v.pos)
        gridEntity:SetPosition(v.from)
        gridEntity:SetViewVisible(true)
        gridEntity:AddReplaceMaterialComponent(gridMatPath)

        local traps = self:_GetNewTrapByPos(v.pos, result)
        ---新机关的创建
        for _, trap in ipairs(traps) do
            trapSvc:CreateSingleTrapRender(TT, trap, true)
            trap:SetPosition(v.from)
            trap:SetViewVisible(true)
            renderBoardCmpt:SetGridRenderEntityData(v.pos, trap)
        end

        local tmpHeight = hPerGrid * (newSetCount - i + 1)
        if v.pos ~= v.from then
            local distance = math.abs(v.pos.x - v.from.x) + math.abs(v.pos.y - v.from.y)
            local speed = distance / BattleConst.FallGridTime
            ---@type GridMoveComponent
            local gridMoveCmpt = gridEntity:AddGridMove(speed, v.pos, v.from)
            if gridMoveCmpt then
                gridMoveCmpt:SetMovingHeight(tmpHeight)
            end
            moveEntities[#moveEntities + 1] = gridEntity

            ---新机关的创建移动
            for _, trap in ipairs(traps) do
                ---@type GridMoveComponent
                local gridMoveCmpt = trap:AddGridMove(speed, v.pos, v.from)
                if gridMoveCmpt then
                    gridMoveCmpt:SetMovingHeight(tmpHeight)
                end
                moveEntities[#moveEntities + 1] = trap
            end
        else
            --边界格子 先升高一点，格子移动完后落下，避免重叠
            local localPosition = boardServiceR:GridPos2RenderPos(v.pos)
            local tmpPos
            if tmpHeight then
                tmpPos = Vector3(localPosition.x, tmpHeight, localPosition.z)
            end
            gridEntity:SetPosition(tmpPos)
            table.insert(waitRestHeightGrids, gridEntity)

            for _, trap in ipairs(traps) do
                gridEntity:SetPosition(trap)
                table.insert(waitRestHeightGrids, trap)
            end
        end
        renderBoardCmpt:SetGridRenderEntityData(v.pos, gridEntity)
    end

    --移动机关
    for i, v in ipairs(result:GetMoveTrapList()) do
        local trapEntity = v.entity
        local distance = math.abs(v.to.x - v.from.x) + math.abs(v.to.y - v.from.y)
        local speed = distance / BattleConst.FallGridTime
        trapEntity:AddGridMove(speed, v.to, v.from)
        moveEntities[#moveEntities + 1] = trapEntity

        if trapEntity:HasTrapRoundInfoRender() then
            local eid = trapEntity:TrapRoundInfoRender():GetRoundInfoEntityID()
            if eid then
                local eff = self._world:GetEntityByID(eid)
                eff:AddGridMove(speed, v.to, v.from)
            end
        end
        local cEffectHolder = trapEntity:EffectHolder()
        if cEffectHolder then
            local effectList = cEffectHolder:GetIdleEffect()
            if table.count(effectList) > 0 then
                for i, eff in ipairs(effectList) do
                    local effectEntity = self._world:GetEntityByID(eff)
                    if effectEntity and effectEntity:HasView() then
                        local curGridPos = boardServiceR:GetRealEntityGridPos(effectEntity)
                        local newGridPos = curGridPos + Vector2(v.to.x - v.from.x, v.to.y - v.from.y)
                        effectEntity:AddGridMove(speed, newGridPos, curGridPos)
                    end
                end
            end
        end
    end

    while self:IsMoving(moveEntities) do
        YIELD(TT)
    end

    ---消除格子结束的通知
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    playBuffSvc:PlayBuffView(TT, NTPopStarEnd:New(result:GetPopNum()))

    --重置边界上提高了的格子和机关
    for _, gridEntity in ipairs(waitRestHeightGrids) do
        local gridPostion = gridEntity:GetGridPosition()
        gridEntity:SetPosition(gridPostion)
    end
end

function PopStarServiceRender:IsMoving(es)
    for _, e in ipairs(es) do
        if e:HasGridMove() then
            return true
        end
    end
end

function PopStarServiceRender:_GetNewTrapByPos(pos, result)
    local traps = {}
    for i, v in ipairs(result:GetNewTrapList()) do
        if v.pos == pos then
            traps[#traps + 1] = v.entity
        end
    end

    return traps
end

function PopStarServiceRender:PopStarShowCasterEntity(petPstID)
    if self._world:MatchType() ~= MatchType.MT_PopStar then
        return
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(petEntityID)

    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local pets = teamEntity:Team():GetTeamPetEntities()
    for _, e in ipairs(pets) do
        if casterEntity and casterEntity:GetID() == e:GetID() then
            e:SetViewVisible(true)
        else
            e:SetViewVisible(false)
        end
    end
end

function PopStarServiceRender:StopPreviewPopStar()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PopStarPickUpResultComponent
    local pickUpResCmpt = renderBoardEntity:PopStarPickUpResult()
    if not pickUpResCmpt then
        return
    end

    ---连通区域
    local connectPieces = pickUpResCmpt:GetPopStarConnectPieces()

    ---清除点击表现
    self:ClearPreviewPop(connectPieces)

    ---重置
    pickUpResCmpt:ResetPopStarPickUp()
end
