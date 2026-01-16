--[[----------------------------------------------------------
    渲染连通区system
]] ------------------------------------------------------------
---@class ConnectAreaRenderSystem_Render:ReactiveSystem
_class("ConnectAreaRenderSystem_Render", ReactiveSystem)
ConnectAreaRenderSystem_Render = ConnectAreaRenderSystem_Render

---@param world MainWorld
function ConnectAreaRenderSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function ConnectAreaRenderSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.ConnectPieces)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function ConnectAreaRenderSystem_Render:Filter(entity)
    return entity:HasConnectPieces()
end

function ConnectAreaRenderSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        self:HandleConnectArea(entities[i])
    end
end

---@param e Entity
function ConnectAreaRenderSystem_Render:HandleConnectArea(e)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if utilDataSvc:GetCurMainStateID() ~= GameStateID.WaitInput then
        return
    end

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chain_grid_list = previewChainPathCmpt:GetPreviewChainPath()

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    local connect_piece_grid_list = e:ConnectPieces():GetConnectPieces()
    local count = #connect_piece_grid_list

    ---连线格子大于0 先把所有变暗,然后将联通区域的变为正常,连线内保持连线状态
    if count > 0 then
        self:HandleNoneConnectAreaDark(chain_grid_list, connect_piece_grid_list)
    elseif count == 0 then ---回到原点，联通区为零，所有格子除了怪物脚底下的，其余恢复正常显示
        ---Bug：MSG67692
        ---判定连线路径格子数量：当路径只有万色时，联通区格子数量为0
        ---但有连线路径，路径中的点不恢复Normal动画
        self:HandleNoChainPoint(chain_grid_list)
    end
end

---联通区保持正常颜色，联通区外需要压暗效果
---@param connectGridList Array 联通区数组
function ConnectAreaRenderSystem_Render:HandleNoneConnectAreaDark(chain_grid_list, connectGridList)
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, pieceEntity in ipairs(pieceGroup:GetEntities()) do
        if not pieceEntity:HasOutsideRegion() then
            ---@type GridLocationComponent
            local gridLocationCmpt = pieceEntity:GridLocation()
            local gridPos = gridLocationCmpt.Position
            local inConnectArea = table.icontains(connectGridList, gridPos)
            if inConnectArea == false then
                local isDown = pieceService:ShouldPosPlayDownAim(gridPos)
                if isDown then
                    pieceService:SetPieceAnimDown(gridPos)
                else
                    pieceService:SetPieceAnimDark(gridPos)
                end
            else
                ---检查是否在chainpath里
                if not table.icontains(chain_grid_list, gridPos) then
                    local animName = pieceService:GetPieceAnimation(gridPos)
                    if animName ~= "Normal" then
                        pieceService:SetPieceEntityAnimNormal(pieceEntity)
                    end
                end
            end
        end
    end
end

---处理连线点数量变为0的格子效果
---有两个时机会触发，需要分别处理
---1.连线过程中回退
---2.抬手后，刷新格子时
function ConnectAreaRenderSystem_Render:HandleNoChainPoint(chain_grid_list)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curStateID = utilDataSvc:GetCurMainStateID()

    local pieceGroup = self._world:GetGroup(self._world.BW_WEMatchers.Piece)
    for _, pieceEntity in ipairs(pieceGroup:GetEntities()) do
        if not pieceEntity:HasOutsideRegion() then
            local gridPos = pieceEntity:GetGridPosition()
            ---检查是否在chainpath里
            if not table.icontains(chain_grid_list, gridPos) then
                if curStateID == GameStateID.PieceRefresh then
                    self:HandlePieceAnimForPieceRefresh(pieceEntity)
                else
                    self:HandlePieceAnimForOther(pieceEntity)
                end
            end
        end
    end

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local renderChainPathComponent = renderBoardEntity:RenderChainPath()
    renderChainPathComponent:SetConnectAreaRenderCantRefresh(false)
end

---为输入状态处理格子动画
---@param pieceEntity Entity
function ConnectAreaRenderSystem_Render:HandlePieceAnimForOther(pieceEntity)
    ---@type GridLocationComponent
    local gridLocationCmpt = pieceEntity:GridLocation()
    local gridPos = gridLocationCmpt.Position
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    local is_blocked = utilDataSvc:IsPosListHaveMonster({gridPos})
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local renderChainPathComponent = renderBoardEntity:RenderChainPath()
    local chainAcrossMonster = renderChainPathComponent:GetChainAcrossMonster()
    local cantRefresh = renderChainPathComponent:GetConnectAreaRenderCantRefresh()
    --1 划出去一个格子然后退回来
    --2 原地按住然后抬起结束
    --怪物脚下刷新成normal的条件：连锁可以穿怪 and 可以刷新（第一次进入子弹时间的时候设置为true，结束刷新联通区域后设置为false）
    local refresh = chainAcrossMonster and not cantRefresh

    if not is_blocked or refresh then
        local animName = pieceService:GetPieceAnimation(gridPos)
        if animName ~= "Normal" then
            pieceService:SetPieceEntityAnimNormal(pieceEntity)
        end
    end
end

---为非输入状态处理格子动画
---@param pieceEntity Entity
function ConnectAreaRenderSystem_Render:HandlePieceAnimForPieceRefresh(pieceEntity)
    ---@type Entity
    local playerEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type GridLocationComponent
    local playerLocCmpt = playerEntity:GridLocation()
    local playerPos = playerLocCmpt:GetGridPos()

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type GridLocationComponent
    local gridLocationCmpt = pieceEntity:GridLocation()
    local gridPos = gridLocationCmpt.Position
    local is_blocked = utilDataSvc:IsPosListHaveMonster({gridPos})
    local isDark = pieceService:IsPieceAnimDark(gridPos)
    local isPlayerPos = gridPos == playerPos

    ---玩家划线走过的格子是dark，这种情况才应该改
    if not is_blocked and isDark then
        pieceService:SetPieceEntityAnimNormal(pieceEntity)
    elseif isPlayerPos then
        pieceService:SetPieceEntityAnimNormal(pieceEntity)
    end
end
