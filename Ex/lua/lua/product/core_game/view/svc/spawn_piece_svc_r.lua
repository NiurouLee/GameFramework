--[[------------------------------------------------------------------------------------------
    SpawnPieceServiceRender 棋盘刷新格子
]] --------------------------------------------------------------------------------------------
require("base_service")

_class("SpawnPieceServiceRender", BaseService)
---@class SpawnPieceServiceRender:BaseService
SpawnPieceServiceRender = SpawnPieceServiceRender

function SpawnPieceServiceRender:Constructor(world)
end

function SpawnPieceServiceRender:PlayBoardShow(TT, waveBoard)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local isMultiBoardLevel = levelConfigData:IsMultiBoardLevel()
    local isSpliceBoardLevel = levelConfigData:IsSpliceBoardLevel()

    if not waveBoard then
        self:_OnClipBoard(TT)
    end

    local spreadTaskID =
        GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            if isMultiBoardLevel then
                --常规棋盘位置 无动画
                self:_PlayPieceSpreadEffectNoAnim(TT)
                --多面棋盘，不考虑waveBoard
                self:_PlayMultiPieceSpreadEffect(TT)
            elseif isSpliceBoardLevel then
                --常规棋盘位置 无动画
                self:_PlayPieceSpreadEffectNoAnim(TT)
                self:_PlayPieceFakeSpreadEffectNoAnim(TT)
            else
                --棋盘线特效
                self:_PlayBoardLineEffect(TT)
                --常规棋盘刷新 有动画
                self:_PlayPieceSpreadEffect(TT, waveBoard)
            end
        end
    )

    while not TaskHelper:GetInstance():IsTaskFinished(spreadTaskID) do
        YIELD(TT)
    end
end

--切割棋盘显示范围
function SpawnPieceServiceRender:_OnClipBoard(TT)
    local configService = self._world:GetService("Config")
    ---@type LevelConfigData
    local levelConfigData = configService:GetLevelConfigData()
    local gridGenID = levelConfigData:GetGridGenID()
    local boardConfig = Cfg.cfg_board[gridGenID]
    if boardConfig.CellClip then
        UnityEngine.Shader.EnableKeyword("_CELL_CLIP")
        local H3DGZ_ClipParam = UnityEngine.Shader.PropertyToID("_H3DGZ_ClipParams")
        local clipParam =
            Vector4(
            boardConfig.CellClip[1],
            boardConfig.CellClip[2] * -1,
            boardConfig.CellClip[3],
            boardConfig.CellClip[4] * -1
        )
        UnityEngine.Shader.SetGlobalVector(H3DGZ_ClipParam, clipParam)

    -- UnityEngine.Shader.DisableKeyword("_CELL_CLIP")
    end
end

function SpawnPieceServiceRender:_PlayBoardLineEffect(TT)
    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local posCenter = utilDataSvc:GetBoardCenterPos()
    sEffect:CreateWorldPositionEffect(GameResourceConst.EffBoardShowLine, posCenter, true)
end

---播放格子展开特效
function SpawnPieceServiceRender:_PlayPieceSpreadEffect(TT, waveBoard)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local posCenter = Vector2(4, 2)
    if teamEntity then
        local teamLeader = teamEntity:GetTeamLeaderPetEntity()
        posCenter = boardServiceRender:GetRealEntityGridPos(teamLeader)
    end
    local internal = 0.1

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local posList = utilDataSvc:GetCloneBoardGridPos()
    if posList == nil then
        return
    end

    local arrPos = {}
    for _, pos in ipairs(posList) do
        local dis = Vector2.Distance(posCenter, pos)
        dis = math.floor(dis + 0.4) + 1
        if not arrPos[dis] then
            arrPos[dis] = {}
        end
        table.insert(arrPos[dis], pos)
    end

    ---@type EffectService
    local sEffect = self._world:GetService("Effect")
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    --buff
    local tConvertInfo = {}

    local taskIDList = {}
    for dis, arrDis in pairs(arrPos) do
        local randomSortArr = self:_Shuffle(arrDis)
        for _, pos in ipairs(randomSortArr) do
            local ePiece = pieceSvc:FindPieceEntity(pos)
            if ePiece then
                --播放动画gezi_birth01
                local internal = 0
                if dis > 1 then
                    internal =
                        math.random(
                        BattleConst.BoardShowPieceRandomRange.min,
                        BattleConst.BoardShowPieceRandomRange.max
                    )
                end

                --刷新格子颜色
                local pieceType
                local playBirth = false
                if waveBoard and waveBoard[pos.x] and waveBoard[pos.x][pos.y] then
                    pieceType = waveBoard[pos.x][pos.y]
                    ePiece = boardServiceRender:ReCreateGridEntity(pieceType, pos)

                    --buff
                    local oldColor = utilDataSvc:FindPieceElement(pos)
                    local convertInfo = NTGridConvert_ConvertInfo:New(pos, oldColor, pieceType)
                    table.insert(tConvertInfo, convertInfo)
                    playBirth = true
                elseif not waveBoard then
                    playBirth = true
                end

                if playBirth then
                    local go = ePiece:View():GetGameObject()
                    local taskID =
                        GameGlobal.TaskManager():CoreGameStartTask(self._PlayBirthAnimation, self, go, internal)
                    taskIDList[#taskIDList + 1] = taskID
                end
            end
        end
        YIELD(TT, BattleConst.BoardShowPieceGroupInternal)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end

    if waveBoard then
        ---@type PlayBuffService
        local svcPlayBuff = self._world:GetService("PlayBuff")
        if #tConvertInfo > 0 then
            --施法者传的boardEntity
            local renderBoardEntity = self._world:GetRenderBoardEntity()
            local notify = NTGridConvert:New(renderBoardEntity, tConvertInfo)
            notify.__attackPosMatchRequired = true
            svcPlayBuff:PlayBuffView(TT, notify)
        end
    else
        ---只有刚进局的时候初始化一次
        self:_PlayBrillantGridLine()
    end
end

function SpawnPieceServiceRender:_PlayBirthNoAnimation(TT, go)
    local tran = GameObjectHelper.FindChild(go.transform, "gezi")
    local curPos = go.transform.position
    curPos.y = 0
    go.transform.position = curPos
end

function SpawnPieceServiceRender:_PlayBirthAnimation(TT, go, internal)
    local tran = GameObjectHelper.FindChild(go.transform, "gezi")
    ---@type UnityEngine.Animation
    local anim = tran.gameObject:GetComponent("Animation")
    YIELD(TT, internal)
    --把格子放下来
    local curPos = go.transform.position
    curPos.y = 0
    go.transform.position = curPos
    if anim then
        anim:Play("gezi_birth01")
    end
    if tran.transform.position.y==  BattleConst.CacheHeight then
        Log.exception("位置:("..tran.transform.position.x..","..tran.transform.position.y..","..tran.transform.position.z..") 播放动画名称:".."gezi_birth01", Log.traceback())
    end

end

function SpawnPieceServiceRender:_Shuffle(t)
    if type(t) ~= "table" then
        return
    end
    local tab = {}
    local index = 1
    while #t ~= 0 do
        local n = math.random(0, #t)
        if t[n] ~= nil then
            tab[index] = t[n]
            table.remove(t, n)
            index = index + 1
        end
    end
    return tab
end

function SpawnPieceServiceRender:_PlayBrillantGridLine()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderBoardComponent
    local renderBoardCmpt = renderBoardEntity:RenderBoard()
    local brillantLineObj = renderBoardCmpt:GetBrillantGridObj()
    local lineExtendParam = renderBoardCmpt:GetBrillantGridLineExtendParam()
    if brillantLineObj == nil then
        return
    end
    brillantLineObj:SetActive(true)

    local levelID = self._world.BW_WorldInfo.level_id
    local levelConfig = Cfg.cfg_level[levelID]
    local themeID = levelConfig.Theme
    local cfgThemeData = Cfg.cfg_theme[themeID]

    local lineParam = cfgThemeData.BrillantWhiteLineParam

    local widthMin = lineParam and lineParam["WidthMin"] or BattleConst.Wangge_WidthMin
    local widthMax = lineParam and lineParam["WidthMax"] or BattleConst.Wangge_WidthMax
    local globalWidth = lineParam and lineParam["GlobalWidth"] or BattleConst.Wangge_GlobalWidth
    local heightMin = lineParam and lineParam["HeightMin"] or BattleConst.Wangge_HeightMin
    local heightMax = lineParam and lineParam["HeightMax"] or BattleConst.Wangge_HeightMax
    local globalHeight = lineParam and lineParam["GlobalHeight"] or BattleConst.Wangge_GlobalHeight
    
    ---修改网格材质的参数
    local renderTransform = GameObjectHelper.FindChild(brillantLineObj.transform, "gezi_wangge")
    ---@type UnityEngine.MeshRenderer
    local meshRenderCmpt = renderTransform.gameObject:GetComponent(typeof(UnityEngine.MeshRenderer))
    ---@type UnityEngine.Material
    local wanggeMaterial = meshRenderCmpt.material
    wanggeMaterial:SetFloat("_WidthMin", widthMin)
    wanggeMaterial:SetFloat("_WidthMax", widthMax)
    wanggeMaterial:SetFloat("_GlobalWidth", globalWidth)
    wanggeMaterial:SetFloat("_HeightMin", heightMin)
    wanggeMaterial:SetFloat("_HeightMax", heightMax)
    wanggeMaterial:SetFloat("_GlobalHeight", globalHeight)
end

function SpawnPieceServiceRender:InitializeCellRender()
    local piecePosList = {}

    ---@type BoardServiceRender
    local boardRenderService = self._world:GetService("BoardRender")

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local gridEntityData = utilData:GetReplicaGridEntityData()
    if gridEntityData then
        for pos, pieceType in pairs(gridEntityData) do
            if pos.x > 9 or pos.y > 9 then
                local renderPos = boardRenderService:GridPos2RenderPos(pos)
                table.insert(piecePosList, renderPos)
            else
                local renderPos = boardRenderService:GridPos2RenderPos(pos)
                table.insert(piecePosList, renderPos)
            end
        end
    end

    CellRenderManager.DrawRangeImmediate(piecePosList)
end
---多面棋盘的关卡，主棋盘面不播放动画的刷新
function SpawnPieceServiceRender:_PlayPieceSpreadEffectNoAnim(TT)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local posList = utilDataSvc:GetCloneBoardGridPos()
    if posList == nil then
        return
    end

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    local taskIDList = {}
    for _, pos in ipairs(posList) do
        local ePiece = pieceSvc:FindPieceEntity(pos)
        if ePiece then
            local go = ePiece:View():GetGameObject()
            local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._PlayBirthNoAnimation, self, go)
            taskIDList[#taskIDList + 1] = taskID
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

---多面棋盘的关卡，主棋盘面不播放动画的刷新
function SpawnPieceServiceRender:_PlayPieceFakeSpreadEffectNoAnim(TT)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local posList = utilDataSvc:GetCloneBoardSpliceGridPos()
    if posList == nil or table.count(posList) == 0 then
        return
    end

    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")

    local taskIDList = {}
    for _, pos in ipairs(posList) do
        local ePiece = pieceSvc:FindPieceFakeEntity(pos)
        if ePiece then
            local go = ePiece:View():GetGameObject()
            local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._PlayBirthNoAnimation, self, go)
            taskIDList[#taskIDList + 1] = taskID
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end

---多面棋盘
function SpawnPieceServiceRender:_PlayMultiPieceSpreadEffect(TT)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local multiBoardPieceList = utilDataSvc:GetCloneMultiBoardGridPos()
    if multiBoardPieceList == nil then
        return
    end

    ---@type PieceMultiServiceRender
    local pieceSvc = self._world:GetService("PieceMulti")

    local taskIDList = {}
    for boardIndex, posList in pairs(multiBoardPieceList) do
        for _, pos in ipairs(posList) do
            local ePiece = pieceSvc:FindPieceEntity(boardIndex, pos)
            local go = ePiece:View():GetGameObject()
            ePiece:SetDirection(Vector3(0, 0, 0))
            local taskID = GameGlobal.TaskManager():CoreGameStartTask(self._PlayMultiBoardShow, self, go)

            taskIDList[#taskIDList + 1] = taskID
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDList) do
        YIELD(TT)
    end
end
---
function SpawnPieceServiceRender:_PlayMultiBoardShow(TT, go)
    local tran = GameObjectHelper.FindChild(go.transform, "gezi")
    go.transform.localEulerAngles = Vector3(0, 0, 0)
end
