 require("auto_fight_service")

--移动
function AutoFightService:_AutoMovePath(TT)
    local tmpSpeed
    ---如果当前是四倍速要恢复成二倍速
    if HelperProxy:GetInstance():GetGameTimeScale() > BattleConst.TimeSpeedList[BattleConst.Speed2Index] then
        Log.fatal("AutoFight SetTimeSpeed ",BattleConst.TimeSpeedList[BattleConst.Speed2Index]," ")
        tmpSpeed = HelperProxy:GetInstance():GetGameTimeScale()
        HelperProxy:GetInstance():SetGameTimeScale(BattleConst.TimeSpeedList[BattleConst.Speed2Index])
    end
    --只要移动了就不考虑转色了
    self._lastConvertColor = 0
    self._randPieceColor = false
    self._lastCastSkillPetIds = {}
    local env = self._env
    ---@type Entity
    local teamEntity = env.TeamEntity
    --自动连线
    local chainPath, pieceType = self:GetAutoChainPath(TT, teamEntity)

    ---服务端自动连线逻辑
    if self._world:RunAtServer() then
        local cmd = MovePathDoneCommand:New()
        cmd.EntityID = teamEntity:GetID()
        cmd:SetChainPath(chainPath)
        cmd:SetElementType(pieceType)
        teamEntity:ReceiveCommand(cmd)
        return
    end

    --以下是客户端自动连线逻辑
    ---隐藏箭头
    ---@type CanMoveArrowService
    local canMoveArrowService = self._world:GetService("CanMoveArrow")
    if canMoveArrowService then
        canMoveArrowService:ShowCanMoveArrow(false)
    end

    ---原地攻击未移动
    if #chainPath == 1 then
        self:ClearChainPathGhost()
        local cmd = MovePathDoneCommand:New()
        cmd:SetChainPath(chainPath)
        cmd:SetElementType(PieceType.None)
        --teamEntity:PushCommand(cmd)
        self._world:Player():SendCommand(cmd)

        --等待输入状态结束[不等待会导致立即下一次自动战斗]
        ---@type GameFSMComponent
        local gameFsmCmpt = self._world:GameFSM()
        while gameFsmCmpt:CurStateID() == GameStateID.WaitInput do
            YIELD(TT, 100)
        end
        if tmpSpeed then
            Log.fatal("AutoFight ResumeSpeed")
            HelperProxy:GetInstance():SetGameTimeScale(tmpSpeed)
        end
        return
    end

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()

    ---客户端的自动连线
    local linklineService = self._world:GetService("LinkLine")

    --处理连线过程中映射颜色
    linklineService:ShowBoardPieceMap()

    local leaderId = teamEntity:Team():GetTeamLeaderEntityID()
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    local showPath = {}
    for _, pos in ipairs(chainPath) do
        table.insert(showPath, pos)
        linklineService:_OnPieceInsertIntoChain(showPath)
        ---本地立即更新连线
        previewEntity:ReplacePreviewChainPath(showPath, pieceType, PieceType.None)
        linkageRenderService:ShowLinkageInfo(showPath, pieceType)
        linkageRenderService:ShowChainSkillIcon(leaderId)--避免白图
        YIELD(TT, 100)
    end

    local isLocal = self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn
    self._world:EventDispatcher():Dispatch(GameEventType.FlushPetChainSkillItem, isLocal, #chainPath, pieceType)

    linklineService:ShowChainPathCancelArea(false)

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")

    pieceService:RefreshPieceAnim()
    self:ClearChainPathGhost()
    local cmd = MovePathDoneCommand:New()
    cmd:SetChainPath(chainPath)
    cmd:SetElementType(pieceType)
    --teamEntity:PushCommand(cmd)
    self._world:Player():SendCommand(cmd)

    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:ClearLinkRender()

    if tmpSpeed then
        Log.fatal("AutoFight ResumeSpeed")
        HelperProxy:GetInstance():SetGameTimeScale(tmpSpeed)
    end

    --等待输入状态结束
    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    while gameFsmCmpt:CurStateID() == GameStateID.WaitInput do
        YIELD(TT, 100)
    end
end
---早苗 连线时 会有机关的虚影
function AutoFightService:ClearChainPathGhost()
    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    if syncMoveServiceRender then
        syncMoveServiceRender:ClearPreview()
    end
end
---获取自动最优连线
function AutoFightService:GetAutoChainPath(TT, teamEntity)
    --防止缓存导致的引导连线错误
    if not self._env or not self._autoMoving then
        self:_BuildMoveEnv(teamEntity)
    end

    local env = self._env

    --技能预计算的路径
    if env.MVP then
        return table.unpack(env.MVP)
    end

    --计算连线方式
    if env.LevelPolicy == LevelPosPolicy.GotoExitPos and env.ExitPos then
        self:_MoveToExit(TT)
    elseif env.LevelPolicy == LevelPosPolicy.GotoTrapPos and env.UnlockPos then
        self:_MoveToUnlockPos(TT)
    else
        self:_CalcMVP2(TT)
    end

    if not env.MVP then
        Log.debug("自动连线无路可走，原地爆炸。")
        env.MVP = {{env.PlayerPos}, PieceType.None, 1}
    end

    return table.unpack(env.MVP)
end

function AutoFightService:_CalcMVP(TT)
    local t1 = os.clock()
    self:_CalcAllMovePath()
    local t2 = os.clock()

    local env = self._env
    Log.debug("[AutoFight] _CalcAllMovePath() path count=", #env.ChainPaths, " use time =", (t2 - t1) * 1000)

    if #env.ChainPaths == 0 then
        return
    end

    t1 = os.clock()
    local startTime = t1
    local deltaTime = 0
    --计算带连锁技的评估值
    local maxEvalue = 0
    local maxEvalueNormal = 0
    local maxEvalueChain = 0
    local MVP = {}
    for i = 1, #env.ChainPaths do
        local chainPath = env.ChainPaths[i][1]
        local pieceType = env.ChainPaths[i][2]
        local _maxEvalueNormal = env.ChainPaths[i][3]

        --统计普攻连锁技攻击目标数量
        local _maxChainCnt = #chainPath
        local _maxChainAttCnt = self:_CalcChainAttackCount(chainPath[_maxChainCnt], _maxChainCnt, pieceType)
        local _maxEvalueChain = _maxChainAttCnt * BattleConst.AutoFightChainAttackValue
        local _maxEvalue = _maxEvalueNormal + _maxEvalueChain

        deltaTime = os.clock() - startTime
        if TT and deltaTime > BattleConst.LogicYieldTime then
            YIELD(TT)
            Log.debug("[AutoFight] calcMVP path i=", i, " use time=", deltaTime * 1000)
            deltaTime = 0
            startTime = os.clock()
        end

        local len = #chainPath - math.min(#chainPath // 2, 5)
        for n = #chainPath - 1, len, -1 do
            local chainAttCnt = self:_CalcChainAttackCount(chainPath[n], n, pieceType)
            local evalChain = chainAttCnt * BattleConst.AutoFightChainAttackValue

            --重新计算评估值
            local evalNormal = self:_CalcChainPathValue(chainPath, n, pieceType, env)
            local evalue = evalNormal + evalChain

            if evalue > _maxEvalue then
                _maxEvalue = evalue
                _maxEvalueChain = evalChain
                _maxEvalueNormal = evalNormal
                _maxChainCnt = n
            end

            deltaTime = os.clock() - startTime
            if TT and deltaTime > BattleConst.LogicYieldTime then
                YIELD(TT)
                Log.debug("[AutoFight] calcMVP path i=", i, " use time=", deltaTime * 1000)
                deltaTime = 0
                startTime = os.clock()
            end
        end

        if _maxChainCnt > 0 then
            for i = _maxChainCnt + 1, #chainPath do
                chainPath[i] = nil
            end
        end
        if _maxEvalue > maxEvalue then
            maxEvalue = _maxEvalue
            maxEvalueChain = _maxEvalueChain
            maxEvalueNormal = _maxEvalueNormal
            MVP = {chainPath, pieceType, maxEvalue}
            if TT and DEBUG_AUTO_FIGHT then
                self:ShowLinkLine(TT, chainPath, pieceType)
            end
        end
    end
    env.MVP = MVP

    --如果路线评估值<=无伤害无机关路线的评估值，需要靠近怪物
    local baseValue = self:_CalcChainPathBaseValue(MVP[1], MVP[2])

    if MVP[3] <= baseValue then
        self:_MoveToMonster()
        maxEvalueNormal = 1
        maxEvalueChain = 0
    end

    --UI显示
    self._world:EventDispatcher():Dispatch(
        GameEventType.RefreshMVPText,
        string.format("V[%d]=N[%d]+C[%d]", maxEvalue, maxEvalueNormal, maxEvalueChain)
    )

    local st = {}
    for i, pos in ipairs(env.MVP[1]) do
        st[#st + 1] = Vector2.Pos2Index(pos)
    end
    local s = table.concat(st, " ")
    t2 = os.clock()
    Log.debug(
        "[AutoFight] calcMVP use time=",
        (t2 - t1) * 1000,
        " chainPath=[",
        s,
        "] pieceType=",
        env.MVP[2],
        " evalue=",
        env.MVP[3]
    )
end

function AutoFightService:_CalcMVP2(TT)
    local t1 = os.clock()
    self:_CalcAllMovePath(TT)
    local t2 = os.clock()

    local env = self._env
    Log.debug("[AutoFight] _CalcAllMovePath() path count=", #env.ChainPaths, " use time =", (t2 - t1) * 1000)

    if #env.ChainPaths == 0 then
        return
    end

    local MVP = env.ChainPaths[1]
    env.MVP = MVP

    --如果路线评估值<=无伤害无机关路线的评估值，需要靠近怪物
    local baseValue = self:_CalcChainPathBaseValue(MVP[1], MVP[2])
    if MVP[3] <= baseValue then
        self:_MoveToMonster()
    end

    local st = {}
    for i, pos in ipairs(env.MVP[1]) do
        st[#st + 1] = Vector2.Pos2Index(pos)
    end
    local s = table.concat(st, " ")
    local usetime = os.clock() - t2
    Log.debug("[AutoFight] calcMVP2  chainPath=[", s, "] pieceType=", MVP[2], " evalue=", MVP[3], " use time=", usetime)
    
    --UI显示
    self._world:EventDispatcher():Dispatch(GameEventType.RefreshMVPText, 'MVP='..MVP[3])
end

--计算所有连线情况
function AutoFightService:_CalcAllMovePath(TT)
    local startPosIndex = self:_Pos2Index(self._env.PlayerPos)
    local chainPathIdx = {startPosIndex}
    local depth = 100
    if self._env.Benumb then
        depth = 1
    end
    self._env.ThinkStartTime = os.clock()
    self:_NextMove(TT, chainPathIdx, PieceType.Any, depth)
end

--传piecetype是为了处理脚下格子和万色格子
function AutoFightService:_NextMove(TT, chainPathIdx, prevPieceType, depth)
    local env = self._env
    if depth == 0 then
        return
    end

    local startPosIdx = chainPathIdx[#chainPathIdx]
    --不能联通则回退
    local ct = env.ConnectMap[startPosIdx]
    if not ct then
        return
    end

    --遇到任意门就停下[不能是起始格子]
    if #chainPathIdx > 1 and env.DimensionDoorPos[startPosIdx] then
        return
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    --颜色计算
    if #chainPathIdx > 1 then
        local startPieceType = env.BoardPosPieces[startPosIdx]
        if #chainPathIdx == 2 then
            local mapForFirstChainPath = utilData:GetMapForFirstChainPath()
            if mapForFirstChainPath then
                startPieceType = mapForFirstChainPath
            end
        end
        if prevPieceType == PieceType.Any then
            prevPieceType = startPieceType
        end
    end

    --棱镜格子重建联通地图
    if table.icontains(env.PrismPos, startPosIdx) and #chainPathIdx > 1 then
        local prevPosIdx = chainPathIdx[#chainPathIdx - 1]
        self:_DoPrismChange(startPosIdx, prevPosIdx)
    end

    for i = 1, 8 do
        --长度优化导致裁剪了部分路径，不尝试这部分了
        if startPosIdx ~= chainPathIdx[#chainPathIdx] then
            return
        end
        local posIdx = ct[i]
        if posIdx then
            --格子颜色
            local posPieceType = env.BoardPosPieces[posIdx]
            local isFirstStepUseMapPiece = false
            if #chainPathIdx == 1 then
                local mapForFirstChainPath = utilData:GetMapForFirstChainPath()
                if mapForFirstChainPath then
                    posPieceType = mapForFirstChainPath
                    isFirstStepUseMapPiece = true
                end
            end
            local canMatchMapPieceType = false
            if not isFirstStepUseMapPiece then
                --映射颜色
                local mapPieceType = env.MapByPosition[posIdx]
                if mapPieceType and (mapPieceType == PieceType.Any or CanMatchPieceType(mapPieceType, prevPieceType)) then
                    canMatchMapPieceType = true
                    --如果映射成功，那么使用的格子颜色是映射的颜色，否则会导致如果这个格子是最后一个格子cmd的颜色就是这个颜色，而不是前面连线的颜色
                    posPieceType = prevPieceType
                end
            end
            
            if
                (CanMatchPieceType(posPieceType, prevPieceType) or canMatchMapPieceType) and
                    not table.icontains(chainPathIdx, posIdx)
             then
                chainPathIdx[#chainPathIdx + 1] = posIdx
                env.forward = true
                if posPieceType == PieceType.Any then
                    posPieceType = prevPieceType
                end
                self:_NextMove(TT, chainPathIdx, posPieceType, depth - 1)

                if env.forward and #chainPathIdx > 1 then
                    env.forward = false
                    --结果
                    local chainPath = {}
                    for n = 1, #chainPathIdx do
                        chainPath[#chainPath + 1] = self:_Index2Pos(chainPathIdx[n])
                    end
                    local pathPieceType = posPieceType
					
                    --如果自动连线可以穿怪，把怪物脚下设置为可以走的点了，这里要判断一下路径终点是否可以移动，如果不能去掉最后一个点
                    for i = #chainPath, 1, -1 do
                        local calcBlockChainPos = chainPath[i]
                        if not utilData:IsPosBlockLinkLineForChainChainEnd(calcBlockChainPos) then
                            break
                        else
                            chainPath[i] = nil
                            chainPathIdx[i] = nil
                        end
                    end

                    --路径评估值
                    local val = self:_CalcChainPathValue(chainPath, #chainPath, pathPieceType, env)
                    self:_InsertChainPath(chainPath, pathPieceType, val)

                    if DEBUG_AUTO_FIGHT then
                        self:ShowLinkLine(TT, chainPath, pathPieceType)
                    end

                    --计算裁剪路径
                    env.maxlen = #chainPathIdx
                    env.cutlen = self:_CalcChainPathComplexityLen(chainPathIdx)
                    --Log.debug("[AutoFight] _CalcChainPathComplexityLen() len=",len)

                    local useTime = os.clock() - env.ThinkStartTime
                    if TT and useTime > BattleConst.LogicYieldTime then
                        YIELD(TT)
                        env.ThinkStartTime = os.clock()
                    end
                end

                --逐步撤回，由于裁剪了一部分路径，这里要检查回退的pos匹配
                if startPosIdx == chainPathIdx[#chainPathIdx - 1] then
                    self:_PopChainPath(chainPathIdx)
                end
                --无论如何回溯最后4步
                if env.maxlen - #chainPathIdx == 4 then
                    for n = #chainPathIdx, env.cutlen, -1 do
                        self:_PopChainPath(chainPathIdx)
                    end
                end
            end
        end
    end
end

--回退格子
function AutoFightService:_PopChainPath(chainPathIdx)
    local len = #chainPathIdx
    --回退棱镜格子重建联通地图
    if table.icontains(self._env.PrismPos, chainPathIdx[len]) then
        local prevPosIdx = chainPathIdx[len - 1]
        self:_UndoPrismChange(chainPathIdx[len], prevPosIdx)
    end
    chainPathIdx[len] = nil
end

--插入排序
function AutoFightService:_InsertChainPath(chainPath, pieceType, val)
    local env = self._env
    --回退测试连锁技
    local checklen = #chainPath - math.min(#chainPath // 2, 5)
    local maxChainCnt = #chainPath
    for n = #chainPath - 1, checklen, -1 do
        --重新计算评估值
        local evalue = self:_CalcChainPathValue(chainPath, n, pieceType, env)
        if evalue > val then
            val = evalue
            maxChainCnt = n
        end
    end

    if maxChainCnt > 0 then
        for i = maxChainCnt + 1, #chainPath do
            chainPath[i] = nil
        end
    end
	
    --不理解为什么要在这里剪切路径，要算完全部路径以后再做这一步。而且这里剪切了传的chainPath，但是没改chainPathIdx啊？
    --虽然不理解，但是也要加
    --如果自动连线可以穿怪，把怪物脚下设置为可以走的点了，这里要判断一下路径终点是否可以移动，如果不能去掉最后一个点
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for i = #chainPath, 1, -1 do
        local calcBlockChainPos = chainPath[i]
        if not utilData:IsPosBlockLinkLineForChainChainEnd(calcBlockChainPos) then
            break
        else
            chainPath[i] = nil
        end
    end

    local doInsert = false
    for idx, result in ipairs(env.ChainPaths) do
        if val > result[3] then
            table.insert(env.ChainPaths, idx, {chainPath, pieceType, val})
            doInsert = true
            break
        end
    end
    if not doInsert and #env.ChainPaths < BattleConst.AutoFightPathCountCut then
        table.insert(env.ChainPaths, {chainPath, pieceType, val})
    end
    if doInsert and #env.ChainPaths > BattleConst.AutoFightPathCountCut then
        env.ChainPaths[#env.ChainPaths] = nil
    end
end

function AutoFightService:_CalcChainPathComplexityLen(chainPathIdx)
    if self._env.HighConnectRateCutLen > 0 then
        return self._env.HighConnectRateCutLen
    end
    local m = BattleConst.AutoFightMoveEnhanced and 2 or 1
    local cc = 1
    local len = #chainPathIdx
    for i, idx in ipairs(chainPathIdx) do
        cc = cc * table.count(self._env.ConnectMap[idx])
        if cc > BattleConst.AutoFightPathComplexity[m] then
            len = i - 1
            break
        end
    end
    return len
end

--连线评估
function AutoFightService:_CalcChainPathValue(chainPath, len, pieceType, env)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local superChainCount = utilData:GetCurrentTeamSuperChainCount()--只影响是否进超级连线，不影响普攻等倍率的计算

    local val = 0
    local petCnt = 1
    local moveEntities = env.PieceTypeMovePets[pieceType]
    if moveEntities then
        petCnt = #moveEntities
    end

    local trapPosVal = 0
    for i, pos in ipairs(chainPath) do
        if i > len then
            break
        end
        local posIdx = self:_Pos2Index(pos)
        --格子权值
        local posVal = env.BoardPosEvalue[posIdx]
        if not posVal then
            Log.info("[AutoFight] error _CalcChainPathValue posVal nil , pos: ",pos.x," ", pos.y," posIdx:",posIdx)--冒烟 日志
        end

        if posVal then 
            val = val + posVal
        end

        --普攻权值
        if env.BoardPosCanAttack[posIdx] then
            local chainParam = math.min(i, BattleConst.SuperChainCount)
            local attackVal =
                BattleConst.AutoFightNormalAttackPosValue *
                (1 + BattleConst.AutoFightNormalAttackChainParam * chainParam)
            val = val + attackVal
        end

        --机关权值
        local posVal = env.TrapPosEvalue[posIdx]
        if posVal then
            trapPosVal = trapPosVal + posVal
        end

        --属性强化buff怪物权值
        local posInfo = env.ElementBuffPos[posIdx]
        if posInfo and posInfo[pieceType] then
            val = val + posInfo[pieceType]
        end
    end

    --出战星灵数量
    val = val * petCnt + trapPosVal

    --超级连锁
    if len > superChainCount then
        val = val + BattleConst.AutoFightSuperChainAddPathValue
    end

    --连锁技权值
    local chainAttackCnt = self:_CalcChainAttackCount2(chainPath[len], len, pieceType)
    local chainParam = math.min(len, BattleConst.SuperChainCount)
    val =
        val +
        chainAttackCnt * BattleConst.AutoFightChainAttackValue *
            (1 + BattleConst.AutoFightChainAttackChainParam * chainParam)

    --评估值至少为1，避免无路可走的情况
    if val <= 0 then
        val = 1
    end
    return val
end

--路径无攻击的评估值
function AutoFightService:_CalcChainPathBaseValue(chainPath, pieceType)
    local env = self._env
    local petCnt = 1
    local moveEntities = env.PieceTypeMovePets[pieceType]
    if moveEntities then
        petCnt = #moveEntities
    end
    local val = #chainPath * BattleConst.AutoFightNoAttackPosValue * petCnt
    return val
end

--计算出战星灵
function AutoFightService:_CalcMoveEntities(pieceType)
    ---@type Entity
    local teamEntity = self._env.TeamEntity
    local leaderId = teamEntity:Team():GetTeamLeaderEntityID()
    local moveEntities = {}
    for _, e in ipairs(teamEntity:Team():GetTeamPetEntities()) do
        ---@type ElementComponent
        local elementCmpt = e:Element()
        local primaryType = elementCmpt:GetPrimaryType()
        local sencondardType = elementCmpt:GetSecondaryType()

        local primaryMatch = CanMatchPieceType(primaryType, pieceType)
        local secondaryMatch = CanMatchPieceType(sencondardType, pieceType)
        if e:GetID() == leaderId or primaryMatch or secondaryMatch then
            moveEntities[#moveEntities + 1] = e
        end
    end

    return moveEntities
end

--根据颜色和连锁数计算连锁技攻击怪物数量
---@param skillEntities Entity[]
function AutoFightService:_CalcChainAttackCount(skillPos, chainCount, pieceType)
    local skillEntities = self._env.PieceTypeMovePets[pieceType]
    if skillEntities == nil or #skillEntities == 0 then
        return 0
    end

    local t1 = os.clock()
    local configSvc = self._configService
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeTargetSelector
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    if affixService:HasAddChainPathNum() then
        chainCount = affixService:ProcessAddChainPathNum(chainCount)
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local attackCnt = 0
    for _, e in ipairs(skillEntities) do
        local chainCountFix = e:Attributes():GetAttribute("ChainSkillReleaseFix")
        local finalChainCount = chainCount + chainCountFix
        local chainExtraFix = utilData:GetEntityBuffValue(e, "ChangeExtraChainSkillReleaseFixForSkill")
        ---@type SkillInfoComponent
        local skillInfoCmpt = e:SkillInfo()
        --GetChainSkillConfigID 用的finalChainCount 似乎应该减1，待确认 --sjs_todo
        local chainSkillID = skillInfoCmpt:GetChainSkillConfigID(finalChainCount, chainExtraFix)
        if chainSkillID > 0 then
            ---@type SkillConfigData 普通攻击的技能数据
            local skillConfigData = configSvc:GetSkillConfigData(chainSkillID)
            local skillTargetType = skillConfigData:GetSkillTargetType()
            ---计算连锁技范围
            ---@type SkillScopeResult
            local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, skillPos, e)

            ---计算范围内目标
            local targetEntityIDArray =
                targetSelector:DoSelectSkillTarget(e, skillTargetType, scopeResult, chainSkillID)
            --排除魔免怪物
            local hitCnt = 0
            for _, targetID in ipairs(targetEntityIDArray) do
                local targetEntity = self._world:GetEntityByID(targetID)
                if targetEntity and targetEntity:HasBuff() and buffLogicSvc:CheckCanBeMagicAttack(e, targetEntity) then
                    hitCnt = hitCnt + 1
                end
            end
            attackCnt = attackCnt + hitCnt
        end
    end

    local t2 = os.clock()
    Log.debug("[AutoFight] _CalcChainAttackCount() pos=", Vector2.Pos2Index(skillPos), " use time=", (t2 - t1) * 1000)
    return attackCnt
end

function AutoFightService:_CalcChainAttackCount2(skillPos, chainCount, pieceType)
    local chainSkillAttackOffset = self._env.ChainSkillAttackOffset
    local chainSkillAttackCount = self._env.ChainSkillAttackCount
    local skillEntities = self._env.PieceTypeMovePets[pieceType]
    if skillEntities == nil or #skillEntities == 0 then
        return 0
    end
    local skillPosIdx = self:_Pos2Index(skillPos)
    local t1 = os.clock()
    local configSvc = self._configService
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeTargetSelector
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    if affixService:HasAddChainPathNum() then
        chainCount = affixService:ProcessAddChainPathNum(chainCount)
    end
    local attackCnt = 0
    for _, e in ipairs(skillEntities) do
        local chainCountFix = e:Attributes():GetAttribute("ChainSkillReleaseFix")
        local finalChainCount = chainCount + chainCountFix
        ---@type SkillInfoComponent
        local skillInfoCmpt = e:SkillInfo()
        local chainExtraFix = utilData:GetEntityBuffValue(e, "ChangeExtraChainSkillReleaseFixForSkill")
        --GetChainSkillConfigID 用的finalChainCount 似乎应该减1，待确认 --sjs_todo
        local chainSkillID = skillInfoCmpt:GetChainSkillConfigID(finalChainCount, chainExtraFix)
        if chainSkillID > 0 then
            local hitCnt = 0
            local cache = chainSkillAttackCount[chainSkillID]
            if cache and cache[skillPosIdx] then
                hitCnt = cache[skillPosIdx]
            else
                local offset = chainSkillAttackOffset[chainSkillID]
                local range = {}
                if not offset then
                    offset = {}
                    ---@type SkillConfigData
                    local skillConfigData = configSvc:GetSkillConfigData(chainSkillID)
                    local chainSkillTag = skillConfigData:GetAutoFightChainSkillTag()
                    if chainSkillTag == 1 then
                        ---@type SkillScopeResult
                        local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, skillPos, e)
                        range = scopeResult:GetAttackRange()
                        for _, pos in ipairs(range) do
                            offset[#offset + 1] = pos - skillPos
                        end
                    end
                    chainSkillAttackOffset[chainSkillID] = offset
                    chainSkillAttackCount[chainSkillID] = {}
                else
                    for _, diff in ipairs(offset) do
                        range[#range + 1] = skillPos + diff
                    end
                end

                for i, pos in ipairs(range) do
                    local monster = self._env.MonsterDict[self:_Pos2Index(pos)]
                    --排除魔免怪物
                    if monster and buffLogicSvc:CheckCanBeMagicAttack(e, monster) then
                        hitCnt = hitCnt + 1
                    end
                end
                chainSkillAttackCount[chainSkillID][skillPosIdx] = hitCnt
            end

            attackCnt = attackCnt + hitCnt
        end
    end

    local t2 = os.clock()
    --Log.debug("[AutoFight] _CalcChainAttackCount2() pos=", Vector2.Pos2Index(skillPos), " use time=", (t2 - t1) * 1000)
    return attackCnt
end

function AutoFightService:ShowLinkLine(TT, chainPath, pieceType)
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    linkageRenderService:ClearLinkRender()
    linkageRenderService:DestroyAllLinkedNum()
    linkageRenderService:DestroyAllLinkLine()
    linkageRenderService:DestroyLinkedGridEffect()
    local chain_path = chainPath
    for i, v in ipairs(chain_path) do
        if i ~= 1 then
            local dir = chain_path[i - 1] - chain_path[i]
            --新版linerender
            linkageRenderService:CreateLineRender(chain_path[i - 1], chain_path[i], i, v, dir, pieceType)
        end
    end
    linkageRenderService:ShowLinkageInfo(chainPath, pieceType)

    YIELD(TT, 1000)
end

function AutoFightService:_MoveToExit(TT)
    local startPosIndex = self:_Pos2Index(self._env.PlayerPos)
    local exitPosIndex = self:_Pos2Index(self._env.ExitPos)

    local endPosIdx = self:_FindPosIndexNeareastExit(exitPosIndex, startPosIndex)
    local pieceType = self._env.BoardPosPieces[endPosIdx]
    if endPosIdx == startPosIndex then
        return
    end

    --其他位置
    local chainPathIdx = {endPosIdx}
    local ret = self:_FindPosTraceBackToStart(chainPathIdx, startPosIndex, pieceType)
    --防止寻路有bug
    if chainPathIdx[1] ~= startPosIndex then
        return
    end

    --加晴 首格视为某颜色 处理 从后向前找路径时，没有处理加晴主动技的情况，在计算出路径后做容错处理
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local mapForFirstChainPath = utilData:GetMapForFirstChainPath()

    local chainPath = {}
    pieceType = PieceType.Any --路线可能被机关打断，需要重新算颜色
    local log = ""
    for i, posIdx in ipairs(chainPathIdx) do
        local piece = self._env.BoardPosPieces[posIdx]
        if mapForFirstChainPath and (i == 2) then
            piece = mapForFirstChainPath
        end
        --如果目标格子颜色是万色需要重新寻找颜色
        if piece ~= PieceType.None and pieceType == PieceType.Any then
            pieceType = piece
        else
            --如果发现路径颜色不一致，则不继续 处理加晴时增加的判断
            if piece ~= PieceType.None and piece ~= PieceType.Any 
                and pieceType ~= PieceType.Any and piece ~= pieceType then
                break
            end
        end
        --麻痹只能走一步
        if self._env.Benumb and i > 1 then
            break
        end
        --遇到任意门就停下
        if i > 1 and self._env.DimensionDoorPos[posIdx] then
            break
        end
        table.insert(chainPath, self:_Index2Pos(posIdx))
        log = log .. posIdx .. " "
    end
    self._env.MVP = {chainPath, pieceType, 1}
    Log.debug("[AutoFight] MoveToExit path=", log, " pieceType=", pieceType)
end

--从出口开始找到里出口最近的且在连接图中的点
function AutoFightService:_FindPosIndexNeareastExit(exitPosIndex, startPosIndex)
    if self._env.ConnectMap[exitPosIndex] then
        return exitPosIndex
    end
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    for i, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(exitPosIndex, off)
        if posIdx ~= startPosIndex and self._env.ConnectMap[posIdx] then
            return posIdx
        end
    end
    --运行到此处不是bug：可能会被怪围住，这时候只能原地双击
    --Log.exception("运行至此处是bug")
    return startPosIndex
end

--从后往前寻找离起始点最近的连接点
function AutoFightService:_FindPosTraceBackToStart(chainPathIdx, startPosIdx, pieceType)
    local posIdx = chainPathIdx[1]
    local ct = self._env.ConnectMap[posIdx]

    for i = 1, 8 do
        local nextPosIdx = ct[i]
        if nextPosIdx == startPosIdx then
            table.insert(chainPathIdx, 1, startPosIdx)
            return true
        end
        local nextPieceType = self._env.BoardPosPieces[nextPosIdx]
        if nextPosIdx and not table.icontains(chainPathIdx, nextPosIdx) and CanMatchPieceType(pieceType, nextPieceType) then
            table.insert(chainPathIdx, 1, nextPosIdx)
            if pieceType == PieceType.Any then
                pieceType = nextPieceType
            end
            local ret = self:_FindPosTraceBackToStart(chainPathIdx, startPosIdx, pieceType)
            if ret then
                return true
            else
                --尝试其他方向
                table.remove(chainPathIdx, 1)
            end
        end
    end
    return false
end

function AutoFightService:_MoveToUnlockPos(TT)
    local startPosIndex = self:_Pos2Index(self._env.PlayerPos)
    local unlockPos = self._env.UnlockPos
    --最近的开锁机关
    local exitPosIndex = 0
    local nearDistance = 200
    for i, posIdx in ipairs(unlockPos) do
        local dis = self:_PosIndexDistance(posIdx, startPosIndex)
        if dis < nearDistance then
            exitPosIndex = posIdx
            nearDistance = dis
        end
    end

    local endPosIdx = self:_FindPosIndexNeareastExit(exitPosIndex, startPosIndex)
    local pieceType = self._env.BoardPosPieces[endPosIdx]
    if endPosIdx == startPosIndex then
        return
    end
    --加晴 首格视为某颜色 处理 从后向前找路径时，没有处理加晴主动技的情况，在计算出路径后做容错处理
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local mapForFirstChainPath = utilData:GetMapForFirstChainPath()
    --其他位置
    local chainPathIdx = {endPosIdx} --TODO 正向计算路径，否则会算出起始点错误的路径
    local ret = self:_FindPosTraceBackToStart(chainPathIdx, startPosIndex, pieceType)
    Log.debug("[AutoFight] _MoveToUnlockPos trace back path:", table.concat(chainPathIdx, " "))
    --防止寻路有bug
    if chainPathIdx[1] ~= startPosIndex then
        return
    end

    local chainPath = {}
    pieceType = PieceType.Any --路线可能被机关打断，需要重新算颜色
    local log = ""
    for i, posIdx in ipairs(chainPathIdx) do
        local piece = self._env.BoardPosPieces[posIdx]
        if mapForFirstChainPath and (i == 2) then
            piece = mapForFirstChainPath
        end
        --如果目标格子颜色是万色需要重新寻找颜色
        if piece ~= PieceType.None and pieceType == PieceType.Any then
            pieceType = piece
        else
            --如果发现路径颜色不一致，则不继续 处理加晴时增加的判断
            if piece ~= PieceType.None and piece ~= PieceType.Any 
                and pieceType ~= PieceType.Any and piece ~= pieceType then
                break
            end
        end
        --麻痹只能走一步
        if self._env.Benumb and i > 1 then
            break
        end
        --遇到任意门就停下
        if i > 1 and self._env.DimensionDoorPos[posIdx] then
            break
        end
        table.insert(chainPath, self:_Index2Pos(posIdx))
        log = log .. posIdx .. " "
    end
    self._env.MVP = {chainPath, pieceType, 1}
    Log.debug("[AutoFight] _MoveToUnlockPos path=", log)
end

function AutoFightService:_MoveToMonster()
    local startPosIndex = self:_Pos2Index(self._env.PlayerPos)
    --最近的怪物
    local exitPosIndex = 0
    local nearDistance = 200
    if #self._env.BossPos > 0 then
        for i, posIdx in ipairs(self._env.BossPos) do
            local dis = self:_PosIndexDistance(posIdx, startPosIndex)
            if dis < nearDistance then
                exitPosIndex = posIdx
                nearDistance = dis
            end
        end
    else
        for i, posIdx in ipairs(self._env.MonsterPos) do
            local dis = self:_PosIndexDistance(posIdx, startPosIndex)
            if dis < nearDistance then
                exitPosIndex = posIdx
                nearDistance = dis
            end
        end
    end

    if exitPosIndex == 0 then
        return
    end

    local endPosIdx = self:_FindPosIndexNeareastExit(exitPosIndex, startPosIndex)
    local pieceType = self._env.BoardPosPieces[endPosIdx]
    if endPosIdx == startPosIndex then
        return
    end

    --其他位置
    local chainPathIdx = {endPosIdx}
    local ret = self:_FindPosTraceBackToStart(chainPathIdx, startPosIndex, pieceType)
    --防止寻路有bug
    if chainPathIdx[1] ~= startPosIndex then
        return
    end

    --加晴 首格视为某颜色 处理 从后向前找路径时，没有处理加晴主动技的情况，在计算出路径后做容错处理
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local mapForFirstChainPath = utilData:GetMapForFirstChainPath()
    local chainPath = {}
    pieceType = PieceType.Any --路线可能被机关打断，需要重新算颜色
    local log = ""
    for i, posIdx in ipairs(chainPathIdx) do
        local piece = self._env.BoardPosPieces[posIdx]
        if mapForFirstChainPath and (i == 2) then
            piece = mapForFirstChainPath
        end
        --如果目标格子颜色是万色需要重新寻找颜色
        if piece ~= PieceType.None and pieceType == PieceType.Any then
            pieceType = piece
        else
            --如果发现路径颜色不一致，则不继续 处理加晴时增加的判断
            if piece ~= PieceType.None and piece ~= PieceType.Any 
                and pieceType ~= PieceType.Any and piece ~= pieceType then
                break
            end
        end
        --麻痹只能走一步
        if self._env.Benumb and i > 1 then
            break
        end
        --遇到任意门就停下
        if i > 1 and self._env.DimensionDoorPos[posIdx] then
            break
        end
        table.insert(chainPath, self:_Index2Pos(posIdx))
        log = log .. posIdx .. " "
    end

    self._env.MVP = {chainPath, pieceType, 1}
    Log.debug("[AutoFight] _MoveToMonster path=", log)
end
