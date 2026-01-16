require("base_ins_r")

---@class PlayTransportInstruction: BaseInstruction
_class("PlayTransportInstruction", BaseInstruction)
PlayTransportInstruction = PlayTransportInstruction

function PlayTransportInstruction:Constructor(paramList)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTransportInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectTransportResult[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Transport)
    if resultArray == nil then
        Log.fatal("PlayTransportInstruction, result is nil.")
        return
    end
    ---@type PlaySkillInstructionService
    local playSkillInstructionService = world:GetService("PlaySkillInstruction")
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type TrapServiceRender
    local trapSvc = world:GetService("TrapRender")
    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")
    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardComponent = renderBoardEntity:RenderBoard()
    ---@param v SkillEffectTransportResult
    for _, v in ipairs(resultArray) do
        --实体分类
        local arrPiece = {}
        local allEntity = {}
        local arrMovers = {}
        --移动一步
        local entityResult = v:GetTransportEntities()
        local pieceResult = v:GetTransportPieceResult()
        local prismResult = v:GetTransportPrisms()
        local convertResult = v:GetConvertColors()
        local trapResult = v:GetTrapSkillResults()
        local isLoop = v:IsLoop()

        for i, r in ipairs(pieceResult) do
            local oldPos, newPos = r[1], r[2]
            local pieceEntity = pieceService:FindPieceEntity(oldPos)
            if pieceEntity then
                local t = { pieceEntity, oldPos, newPos }
                allEntity[#allEntity + 1] = t
                arrPiece[#arrPiece + 1] = t
            end
        end

        for i, r in ipairs(entityResult) do
            local eid, oldPos, newPos = table.unpack(r)
            local e = world:GetEntityByID(eid)
            if e then
                local t = { e, oldPos, newPos }
                allEntity[#allEntity + 1] = t
                arrMovers[#arrMovers + 1] = t
            end
        end

        --不循环传送
        ---@type Entity
        local tempEntity = nil
        ---@type Entity
        local lastPieceEntity = nil
        if isLoop == 0 then
            --在第一个位置上创建新的实体，并设置第一点的高度，避免穿模
            local firstPieceRes = pieceResult[1]
            local firstPiecePos = firstPieceRes[1]
            ---@type Entity
            local oriFirstPieceEntity = pieceService:FindPieceEntity(firstPiecePos)
            local pieceType = oriFirstPieceEntity:Piece():GetPieceType()
            for _, v in ipairs(convertResult) do
                if firstPiecePos == v[1] then
                    pieceType = v[3]
                    break
                end
            end
            tempEntity = self:_CreatePieceEntity(world, pieceType, firstPiecePos)
            pieceService:SetPieceEntityAnimNormal(tempEntity)

            --最后一个点的实体，也需要设置第一点的高度，避免穿模
            local lastPieceRes = pieceResult[#pieceResult]
            local lastPiecePos = lastPieceRes[2]
            lastPieceEntity = pieceService:FindPieceEntity(lastPiecePos)
            if lastPieceEntity then
                lastPieceEntity:SetLocationHeight(-0.001)
            end
        end

        --移动实体
        for i, v in ipairs(allEntity) do
            ---@type Entity
            local e = v[1]
            local posTarget = v[3]
            local gridPos = boardServiceRender:GetRealEntityGridPos(e)
            if not e:HasTeam() then
                e:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                if e:HasTrapRoundInfoRender() then
                    local eid = e:TrapRoundInfoRender():GetRoundInfoEntityID()
                    if eid then
                        local eff = world:GetEntityByID(eid)
                        eff:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                    end
                end
            end
            if e:HasTeam() then
                e:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                local entityList = e:Team():GetTeamPetEntities()
                for k, entity in pairs(entityList) do
                    entity:AddGridMove(BattleConst.ConveySpeed, posTarget, gridPos)
                end
            end
        end

        while self:IsMoving(allEntity) do
            YIELD(TT)
        end

        --转色但是不刷新棱镜
        local notRefreshPrism = true
        if isLoop == 0 then
            --删除第一个位置创建用来显示的临时实体对象
            if tempEntity then
                world:DestroyEntity(tempEntity)
            end
            --恢复最后一个格子的高度
            if lastPieceEntity then
                lastPieceEntity:SetLocationHeight(0)
            end

            --格子动画播完之后重置位置
            for _, t in ipairs(arrPiece) do
                local e = t[1]
                local oldPos = t[2]
                ---@type GridLocationComponent
                local gridLocationCmp = e:GridLocation()
                if gridLocationCmp then
                    e:SetGridPosition(oldPos)
                    e:SetLocation(oldPos, e:GetGridDirection())
                end
            end

            --转色
            for _, v in ipairs(convertResult) do
                local pos = v[1]
                local elementType = v[3]
                playSkillInstructionService:GridConvert(TT, casterEntity, pos, 0, elementType, notRefreshPrism)
            end
        else
            for _, t in ipairs(arrPiece) do
                local e = t[1]
                local newPos = t[3]
                renderBoardComponent:SetGridRenderEntityData(newPos, e)
                pieceService:SetPieceAnimation(newPos, "Normal")
                pieceService:_PlayGridAnimation(e, "Normal")
                --逻辑位置
                e:SetGridPosition(newPos)
            end

            --转色
            for _, v in ipairs(convertResult) do
                local pos = v[1]
                local elementType = v[3]
                local gridEntity = pieceService:FindPieceEntity(pos)
                if gridEntity:Piece():GetPieceType() ~= elementType then
                    playSkillInstructionService:GridConvert(TT, casterEntity, pos, 0, elementType, notRefreshPrism)
                end
            end
        end

        --触发的机关表现
        for _, v in ipairs(trapResult) do
            local eId = v[1]
            local e = world:GetEntityByID(eId)
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = v[2]
            local triggerEid = v[3]
            local triggerEntity = world:GetEntityByID(triggerEid)
            e:SkillRoutine():SetResultContainer(skillEffectResultContainer)
            trapSvc:PlayTrapTriggerSkill(TT, e, false, triggerEntity)
        end

        --棱镜
        for _, v in pairs(prismResult) do
            local oldPos = v[1]
            --删除旧棱镜
            pieceService:SetPieceRenderEffect(oldPos, PieceEffectType.Normal)
        end
        for _, v in pairs(prismResult) do
            local newPos = v[2]
            if newPos then
                --添加新棱镜
                pieceService:SetPieceRenderEffect(newPos, PieceEffectType.Prism)
            end
        end
        --设置怪物脚底暗色
        pieceService:RefreshPieceAnim()
        --传送移动通知
        for _, v in ipairs(arrMovers) do
            playBuffService:PlayBuffView(TT, NTTransportEachMoveEnd:New(v[1], v[2], v[3]))
        end
        YIELD(TT)
    end
end

function PlayTransportInstruction:IsMoving(es)
    for _, t in ipairs(es) do
        local e = t[1]
        if e:HasGridMove() then
            return true
        end
    end
end

---@param world MainWorld
---@param pieceType PieceType
---@param pos Vector2
---@return Entity
function PlayTransportInstruction:_CreatePieceEntity(world, pieceType, pos)
    ---@type RenderEntityService
    local sEntity = world:GetService("RenderEntity")
    local pieceEntity = sEntity:CreateRenderEntity(EntityConfigIDRender.Grid)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local gridPrefabPath = boardServiceRender:_GetGridPrefabPath(pieceType)
    pieceEntity:ReplaceAsset(NativeUnityPrefabAsset:New(gridPrefabPath, true))
    pieceEntity:ReplacePiece(pieceType)
    pieceEntity:SetGridPosition(pos)
    pieceEntity:SetPosition(pos)
    pieceEntity:SetLocationHeight(-0.001)
    pieceEntity:RemoveOutsideRegion()
    ---@type Entity
    local renderBoardEntity = world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    pieceEntity:AddReplaceMaterialComponent(gridMatPath)

    return pieceEntity
end
