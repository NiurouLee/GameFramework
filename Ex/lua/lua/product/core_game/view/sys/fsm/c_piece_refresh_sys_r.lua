--[[------------------------------------------------------------------------------------------
    ClientPieceRefreshSystem_Render：客户端实现格子刷新表现
]] --------------------------------------------------------------------------------------------

require "piece_refresh_state_system"

---@class ClientPieceRefreshSystem_Render:PieceRefreshSystem
_class("ClientPieceRefreshSystem_Render", PieceRefreshSystem)
ClientPieceRefreshSystem_Render = ClientPieceRefreshSystem_Render

function ClientPieceRefreshSystem_Render:_DoRenderFillPiece(TT, result)
    if not result then
        return
    end
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    if result.pieceRefreshType == PieceRefreshType.Inplace then
        boardRenderSvc:FillChainPathPieces(result.inplaceResult)
    elseif result.pieceRefreshType == PieceRefreshType.FallingDown then
        self:FallingDownPieces(TT, result)
    elseif result.pieceRefreshType == PieceRefreshType.Destroy then
        self:RefreshPieceByDestroy(TT, result)
    end

    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    if result.ntRefreshGridOnPetMoveDone then
        playBuffSvc:PlayBuffView(TT, result.ntRefreshGridOnPetMoveDone)
    end
    if result.ntGridConvert then
        playBuffSvc:PlayBuffView(TT, result.ntGridConvert)
    end
end

--掉落格子
function ClientPieceRefreshSystem_Render:FallingDownPieces(TT, result)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type BoardServiceRender
    local boardServiceR = self._world:GetService("BoardRender")
    --删除格子隐藏，放到池里
    local pool = {}
    for i, v in ipairs(result.delset) do
        local pieceEntity = renderBoardCmpt:GetGridRenderEntity(v.pos)
        pieceEntity:SetViewVisible(false)
        renderBoardCmpt:RemoveGridRenderEntityData(v.pos)
        pool[i] = pieceEntity
    end

    local moveEntities = {}

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    --所有格子包括机关下落到目标位置
    local movePieces = {}
    for i, v in ipairs(result.movset) do
        local gridEntity = renderBoardCmpt:GetGridRenderEntity(v.from)

        --pieceService:SetPieceAnimNormal(v.from)
        local is_blocked = utilDataSvc:IsPosListHaveMonster({v.to})
        if not is_blocked then
            local animName = pieceService:GetPieceAnimation(v.from)
            if animName ~= "Normal" then
                pieceService:SetPieceEntityAnimNormal(gridEntity)
            end
        end
        --Log.error('move piece from ',v.from:PosIndex(),' to',v.to:PosIndex(),' color=',gridEntity:Piece():GetPieceType())
        local distance = math.abs(v.to.x - v.from.x) + math.abs(v.to.y - v.from.y)
        local speed = distance / BattleConst.FallGridTime
        gridEntity:AddGridMove(speed, v.to, v.from)
        moveEntities[#moveEntities + 1] = gridEntity
        movePieces[i] = {gridEntity, v.to}
    end
    for i, v in ipairs(movePieces) do
        local gridEntity = v[1]
        local pos = v[2]
        gridEntity:SetGridPosition(pos)
        renderBoardCmpt:SetGridRenderEntityData(pos, gridEntity)
    end
    --新格子出现
    local gridMatPath = renderBoardCmpt:GetGridMaterialPath()
    --设置格子移动时的高度，避免重叠--没有分列
    local newsetCount = #result.newset
    local hPerGrid = 0.01
    local totalHeight = hPerGrid * newsetCount
    local waitRestHeightGrids = {}
    for i, v in ipairs(result.newset) do
        local gridEntity = pool[i]
        local gridPrefabPath = boardServiceR:_GetGridPrefabPath(v.color)
        gridEntity:ReplaceAsset(NativeUnityPrefabAsset:New(gridPrefabPath, true))
        gridEntity:ReplacePiece(v.color)
        gridEntity:SetGridPosition(v.pos)
        gridEntity:SetPosition(v.from)
        gridEntity:SetViewVisible(true)
        gridEntity:AddReplaceMaterialComponent(gridMatPath)
        if v.pos ~= v.from then
            local distance = math.abs(v.pos.x - v.from.x) + math.abs(v.pos.y - v.from.y)
            local speed = distance / BattleConst.FallGridTime
            ---@type GridMoveComponent
            local gridMoveCmpt = gridEntity:AddGridMove(speed, v.pos, v.from)
            if gridMoveCmpt then
                local movHeight = hPerGrid * (newsetCount - i + 1)
                gridMoveCmpt:SetMovingHeight(movHeight)
            end
            moveEntities[#moveEntities + 1] = gridEntity
        else
            --边界格子 先升高一点，格子移动完后落下，避免重叠
            local tmpHeight = hPerGrid * (newsetCount - i + 1)
            local localPosition = boardServiceR:GridPos2RenderPos(v.pos)
            local tmpPos
            if tmpHeight then
                tmpPos = Vector3(localPosition.x, tmpHeight, localPosition.z)
            end
            gridEntity:SetPosition(tmpPos)
            table.insert(waitRestHeightGrids, gridEntity)
        end
        renderBoardCmpt:SetGridRenderEntityData(v.pos, gridEntity)

        Log.debug("_ReplaceGridRes gridPos=", Vector2.Pos2Index(v.pos), " pieceType=", v.color)
    end
    --移动机关
    for i, v in ipairs(result.moveTraps) do
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

    --重置边界上提高了的格子
    for index, gridEntity in ipairs(waitRestHeightGrids) do
        local gridPostion = gridEntity:GetGridPosition()
        gridEntity:SetPosition(gridPostion)
        --重置高度
    end

    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")

    --触发的机关表现
    for _, v in ipairs(result.triggerTraps) do
        local e = v[1]
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = v[2]
        local triggerEntity = v[3]
        e:SkillRoutine():SetResultContainer(skillEffectResultContainer)
        trapSvc:PlayTrapTriggerSkill(TT, e, false, triggerEntity)
    end

    --棱镜
    for _, v in pairs(result.movePrisms) do
        local oldPos = v.from
        --删除旧棱镜
        pieceService:SetPieceRenderEffect(oldPos, PieceEffectType.Normal)
    end
    for _, v in pairs(result.movePrisms) do
        local newPos = v.to
        if newPos then
            --添加新棱镜
            pieceService:SetPieceRenderEffect(newPos, PieceEffectType.Prism)
        end
    end
    --设置怪物脚底暗色
    pieceService:RefreshPieceAnim()
end
function ClientPieceRefreshSystem_Render:IsMoving(es)
    for _, e in ipairs(es) do
        if e:HasGridMove() then
            return true
        end
    end
end

function ClientPieceRefreshSystem_Render:_DoRenderShowStoryTips(TT)
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:ShowLinkageInfo({})
    GameGlobal.TaskManager():CoreGameStartTask(self.ShowStoryTips, self)
end

function ClientPieceRefreshSystem_Render:ShowStoryTips(TT)
    YIELD(TT, BattleConst.RefreshPieceTick)
    ---@type InnerStoryService
    local innerStoryService = self._world:GetService("InnerStory")
    if innerStoryService:CheckStoryBanner(StoryShowType.WaveAndRoundAfterPlayerRound) then
        InnerGameHelperRender:GetInstance():IsUIBannerComplete(TT)
    end
    innerStoryService:CheckStoryTips(StoryShowType.WaveAndRoundAfterPlayerRound)
end

---销毁格子：隐藏格子实体，创建特殊机关
function ClientPieceRefreshSystem_Render:RefreshPieceByDestroy(TT, result)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    ---@type TrapServiceRender
    local trapSvc = self._world:GetService("TrapRender")
    ---@type EffectService
    local effectSvc = self._world:GetService("Effect")

    ---刷新格子
    local fillPieceTable = result.inplaceResult 
    if fillPieceTable and #fillPieceTable > 0 then
        boardRenderSvc:FillChainPathPieces(fillPieceTable)
    end

    ---删除机关
    if result.destroyTrapIDList then
        local destroyTrapList = {}
        for _, entityID in ipairs(result.destroyTrapIDList) do
            local entity = self._world:GetEntityByID(entityID)
            if entity then
                destroyTrapList[#destroyTrapList + 1] = entity
            end
        end
        --死亡的机关表现 不播放死亡技能
        local donotPlayDie = true
        trapSvc:PlayTrapDieSkill(TT, destroyTrapList, donotPlayDie)
    end
    
    ---创建机关并隐藏格子
    if result.newTrapIDList then
        local trapList = {}
        local posList = {}
        for _, entityID in ipairs(result.newTrapIDList) do
            local entity = self._world:GetEntityByID(entityID)
            if entity then
                trapList[#trapList + 1] = entity
                posList[#posList + 1] = entity:GetGridPosition()
            end
        end
        trapSvc:ShowTraps(TT, trapList, true)
        for _, pos in ipairs(posList) do
            local pieceEntity = renderBoardCmpt:GetGridRenderEntity(pos)
            pieceEntity:SetViewVisible(false)
        end

        ---播放格子碎裂特效
        for index, pos in ipairs(posList) do
            if index ~= 1 then
                YIELD(TT, BattleConst.DestroyPieceEffectPlayInterval)
            end
            local effEntityID = renderBoardCmpt:GetGridEffectEntityID(pos)
            local effectEntity = self._world:GetEntityByID(effEntityID)
            if effectEntity then
                self._world:DestroyEntity(effectEntity)
                renderBoardCmpt:RemoveGridEffectEntityID(pos)
            end

            effectSvc:CreateWorldPositionEffect(BattleConst.DestroyPieceEffectID, pos)
        end
        
        ---通知UI更新
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIUpdateBossCastSkillTipInfo, #trapList)
    end
end
