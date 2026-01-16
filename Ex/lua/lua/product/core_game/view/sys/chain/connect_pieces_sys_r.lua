--[[----------------------------------------------------------
    ConnectPiecesSystem_Render 联通区
]] ------------------------------------------------------------
---@class ConnectPiecesSystem_Render:ReactiveSystem
_class("ConnectPiecesSystem_Render", ReactiveSystem)
ConnectPiecesSystem_Render = ConnectPiecesSystem_Render

---@param world World
function ConnectPiecesSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function ConnectPiecesSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PreviewChainPath)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function ConnectPiecesSystem_Render:Filter(entity)
    ---@type AutoFightService
    local autoSvc = self._world:GetService("AutoFight")
    return entity:HasPreviewChainPath() and not autoSvc:IsRunning()
end

function ConnectPiecesSystem_Render:ExecuteEntities(entities)
    for _, e in ipairs(entities) do
        ---@type Entity
        local entity = e
        ---@type PreviewChainPathComponent
        local chainPathCmp = entity:PreviewChainPath()
        local chain_path = chainPathCmp:GetPreviewChainPath()
        local piece_type = chainPathCmp:GetPreviewPieceType()

        if chain_path and #chain_path >= 2 then --连接第一个格子的时候计算联通区
            local connect_pieces = self:_CalcConnectPieces(e,chain_path,chainPathCmp,piece_type)
            e:ReplaceConnectPieces(connect_pieces, piece_type)
        elseif chain_path and #chain_path <= 1 then --退回起始位置后清除联通区
            e:ReplaceConnectPieces({}, PieceType.None)
        end
    end
end

---@param chainPathCmp PreviewChainPathComponent
function ConnectPiecesSystem_Render:_CalcConnectPieces(e,chain_path,chainPathCmp,piece_type)
    local connect_pieces = {}

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    ---@type Entity
    local viewDataEntity = self._world:GetRenderBoardEntity()
    ---@type WaveDataComponent
    local waveDataCmpt = viewDataEntity:WaveData()
    local isExitWave = waveDataCmpt:IsExitWave()
    local exitPos = waveDataCmpt:GetExitWavePos()

    ---@type LinkLineService
    local linkLineSvc = self._world:GetService("LinkLine")
    local isTwoChain = linkLineSvc:IsTwoColorChain()

    local firstElementType,firstElementIndex = chainPathCmp:GetFirstElementData()

    local isSecondColor = false
    if isTwoChain then 
        isSecondColor = linkLineSvc:IsSecondColorForTwoColorChain(chain_path)
    end

    if isTwoChain and isSecondColor then 
        ---双色队伍，并且最后一个点是第一个非万色连线点，此时，不需要计算联通区，只需要周围一圈亮
        local lastPos = chain_path[#chain_path]
        connect_pieces = self:_CalcSurrondCanLinkList(lastPos,chain_path)
    else
        if isExitWave and exitPos == chain_path[table.count(chain_path)] then
            connect_pieces = chain_path --划到出口，联通区为已连的路径
        else
            connect_pieces = boardServiceRender:CalcConnectPieces(chain_path, piece_type, chainPathCmp:GetMoveBack(), e )
            -- local s=''
            -- for i,v in ipairs(connect_pieces) do
            --     s=s..' '.. Vector2.Pos2Index(v)
            -- end
            -- Log.error("connect_pieces=[",s,']')
        end

        if firstElementIndex > 0 then 
            ---双色连线情况下，需要判断连线上的格子是否都放在可联通区域内
            for checkIndex = 2,#chain_path do 
                local curPoint = chain_path[checkIndex]
                local isContain = table.icontains(connect_pieces,curPoint)
                if not isContain then 
                    table.insert(connect_pieces,curPoint)
                end
            end
        end
    end

    return connect_pieces
end

function ConnectPiecesSystem_Render:_CalcSurrondCanLinkList(center,chainPath)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local connect_pieces = {}
    for i = -1, 1 do
        for j = -1, 1 do
            local pos = Vector2(center.x + i, center.y + j)
            if utilDataSvc:IsValidPiecePos(pos) then
                local piece_type = env:GetPieceType(pos)
                local canLinkLine = boardServiceRender:IsPosCanLinkLine(pos, chainPath) and
                    not utilDataSvc:IsPosBlockLinkLineForChain(pos) --pos是否可连线
                if canLinkLine then
                    table.insert(connect_pieces, pos)
                end
            end
        end
    end

    for index = 2,#chainPath do 
        local curPoint = chainPath[index]
        local hasPoint = table.icontains(connect_pieces,curPoint)
        if not hasPoint then 
            table.insert(connect_pieces, curPoint)
        end
    end

    return connect_pieces
end

---检查是否需要更新联通区
---@param entity Entity
function ConnectPiecesSystem_Render:_CheckNeedUpdateConnectPieces(entity)
    ---@type PreviewChainPathComponent
    local chainPathCmp = entity:PreviewChainPath()
    local chainPath = chainPathCmp:GetPreviewChainPath()
    local chainCount = #chainPath
    local lastPos = chainPath[chainCount]

    ---玩家起始点坐标的话，不用更新
    if chainCount <= 1 then 
        return false
    end
    
    ---如果最后一个点是逃脱格子，需要更新
    local isExitPos = self:_IsCurrentChainExitPos(lastPos)
    if isExitPos then 
        return true
    end

    local isDimensionDoor = self:_IsCurrentChainDimensionDoor(lastPos)
    if isDimensionDoor then 
        return true
    end

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewEnvComponent
    local envCmpt = previewEntity:PreviewEnv()
    if envCmpt:GetNeedUpdateConnectPieces() then
        envCmpt:SetNeedUpdateConnectPieces(false)
        return true
    end

    local lastPosPieceType = envCmpt:GetPieceType(lastPos)

    ---如果最后一个点的颜色不是万色，并且之前队列里的颜色都是万色，就需要更新
    if lastPosPieceType ~= PieceType.Any then 
        local isAllAny = self:_IsPreChainPathAllAny(chainPath)
        if isAllAny then 
            return true
        end
    end
    
    return false
end

---检查从当前点之前的点是否都是万色
function ConnectPiecesSystem_Render:_IsPreChainPathAllAny(chainPath)
    local chainCount = #chainPath

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewEnvComponent
    local envCmpt = previewEntity:PreviewEnv()
    
    for index = 2,chainCount -1 do 
        local curChainPos = chainPath[index]
        ---@type PieceType
        local curPointType = envCmpt:GetPieceType(curChainPos)
        if curPointType ~= PieceType.Any then 
            return false
        end
    end

    return true
end

function ConnectPiecesSystem_Render:_IsCurrentChainExitPos(lastPos)
    ---@type Entity
    local viewDataEntity = self._world:GetRenderBoardEntity()
    ---@type WaveDataComponent
    local waveDataCmpt = viewDataEntity:WaveData()
    local isExitWave = waveDataCmpt:IsExitWave()
    local exitPos = waveDataCmpt:GetExitWavePos()

    ---检查最后一个点是不是逃脱格子，如果是，需要更新
    if isExitWave and exitPos == lastPos then
        return true
    end

    return false
end

function ConnectPiecesSystem_Render:_IsCurrentChainDimensionDoor(lastPos)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    return utilData:IsPosDimensionDoor(lastPos)
end