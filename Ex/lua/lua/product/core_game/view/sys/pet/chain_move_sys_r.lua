--[[-------------------------------------
    ChainMoveSystem_Render 基于逻辑坐标的移动流程
--]] -------------------------------------

---@class ChainMoveSystem_Render:Object
_class("ChainMoveSystem_Render", Object)
ChainMoveSystem_Render = ChainMoveSystem_Render

function ChainMoveSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    self.group = world:GetGroup(world.BW_WEMatchers.ChainMove)

    ---@type ConfigService
    self._configService = world:GetService("Config")
    self._listTrapTask = nil

    self._chainMoveTaskIDs = {}
end

function ChainMoveSystem_Render:Execute()
    if self.group ~= nil then
        self.group:HandleForeach(self, self.UpdateChainMove)
    end
end

---@param e Entity
function ChainMoveSystem_Render:UpdateChainMove(e)
    -- 判断移动状态
    if e:MoveFSM():GetMoveFSMCurStateID() ~= PlayerActionStateID.Move then
        return
    end

    local move_cmpt = e:ChainMove()
    local chain_path = move_cmpt:GetChainPath()
    local path_index = move_cmpt:GetPathIndex()

    if path_index > #chain_path then
        --当前宝宝移动结束
        e:RemoveChainMove()
        self:_HandlePetMoveEnd(e)
    else
        self:_HandlePetMove(e)
    end
end

function ChainMoveSystem_Render:_HandlePetMoveEnd(e)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    effectService:ShowChainMoveEffect(e, false)
    e:SetAnimatorControllerBools({Move = false})
    e:SetAnimatorControllerBools({MoveSpecial = false})
    --走完所有格子的宝宝，可以进入Idle状态
    self._world:EventDispatcher():Dispatch(GameEventType.MoveFinish, 2, e:GetID())
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    if #self.group:GetEntities() == 0 then
        --所有人的 移动+普攻 结束，主状态机切到连锁攻击阶段
        ---@type Entity
        local teamEntity = e:Pet():GetOwnerTeamEntity()
        ---@type Entity
        local teamLeader = teamEntity:Team():GetTeamLeaderEntity()
        ---@type Vector2
        local position = boardServiceRender:GetRealEntityGridPos(teamLeader)
        ---@type Vector2
        local direction = teamLeader:GetDirection()
        local es = teamEntity:Team():GetTeamPetEntities()
        for i, petEntity in ipairs(es) do
            if petEntity:GetID() ~= teamLeader:GetID() then
                petEntity:SetLocation(position, direction)
                petEntity:SetViewVisible(false) --为了防止队员站在出口上全部可见
            end
        end
        ---把队伍也挪过去
        teamEntity:SetLocation(position, direction)
        --把实际连线路径格子动画重置
        self:RemoveCutChainPath()
        --结束
        teamEntity:RemovePlayerMovingFlag()
    else
        Log.notice("_HandlePetMoveEnd chain path not null")
    end
end
---@param e Entity
function ChainMoveSystem_Render:_HandlePetMove(e)
    ---@type ChainMoveComponent
    local move_cmpt = e:ChainMove()
    local chain_path = move_cmpt:GetChainPath()
    local path_index = move_cmpt:GetPathIndex()
    local start_time = move_cmpt:GetStartTime()
    local speed = move_cmpt:GetSpeed()
    move_cmpt:SetCurGridPathIndex(path_index)
    local dest_pos = chain_path[path_index]

    ---@type TimeService
    local timeService = self._world:GetService("Time")
    local curtime = timeService:GetCurrentTimeMs()
    if curtime < start_time then
        return
    end

    --有gridmove说明正在移动中
    if e:HasGridMove() then
        return
    end

    --开始移动，显示模型
    if e:HasViewExtension() then
        e:SetViewVisible(true)
    end

    ---@type Entity
    local teamEntity = e:Pet():GetOwnerTeamEntity()
    --队长
    local teamLeader = teamEntity:Team():GetTeamLeaderEntity()
    --如果不是队长，需要判断前面的格子，有人就不能继续移动，等待
    if teamLeader:GetID() ~= e:GetID() and self:_AfterFrontPet(path_index, e) then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        effectService:ShowChainMoveEffect(e, false)
        e:SetAnimatorControllerBools({Move = false})
        e:SetAnimatorControllerBools({MoveSpecial = false})
        --Log.fatal("Wait EntityID:",e:GetID()," Index:",path_index," Frame: ",GameGlobal:GetInstance():GetCurrentFrameCount()," Time:",timeService:GetCurrentTimeMs())
        return
    end
    --Log.fatal("Run EntityID:",e:GetID()," Index:",path_index," Frame: ",GameGlobal:GetInstance():GetCurrentFrameCount()," Time:",timeService:GetCurrentTimeMs())

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type SyncMoveServiceRender
    local syncMoveServiceRender = self._world:GetService("SyncMoveRender")
    local cur_pos = boardServiceRender:GetRealEntityGridPos(e)
    --到达一个目标格子
    if cur_pos == dest_pos then
        syncMoveServiceRender:OnArriveAtPos(e, path_index, teamEntity)
        self:_ArriveAtPos(e, cur_pos)
    else
        syncMoveServiceRender:OnGridMoveToPos(e, path_index, speed, teamEntity)
        self:_GridMoveToPos(e, speed, cur_pos, dest_pos, teamEntity)
    end
end

---@param e Entity
function ChainMoveSystem_Render:_ArriveAtPos(e, posCur)
    local move_cmpt = e:ChainMove()
    local chain_path = move_cmpt:GetChainPath()
    local path_index = move_cmpt:GetPathIndex()
    local start_time = move_cmpt:GetStartTime()
    local speed = move_cmpt:GetSpeed()

    local teamEntity = e:Pet():GetOwnerTeamEntity()
    local teamLeader = teamEntity:Team():GetTeamLeaderEntity()

    --对于玩家要处理移动后的删格子等操作
    if teamLeader:GetID() == e:GetID() then
        self:_AfterPlayerMoveOneTile(e, path_index, chain_path)
    else
        self:_OnTeamMemberArrivePos(e,path_index,chain_path)
        
        ---如果不是玩家到达，，并且已经到达最后一个点了，需要隐藏
        if path_index == #chain_path then
            e:SetViewVisible(false)
        end
    end

    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    ---@type TimeService
    local timeService = self._world:GetService("Time")

    --这里取玩家是否死亡的表现数据，而不是逻辑数据，每个星灵都处理
    if
        teamEntity:HasTeamDeadMark() and
            teamEntity:TeamDeadMark():GetDeadGridPos() == boardServiceRender:GetRealEntityGridPos(e)
     then
        --移动结束处理
        move_cmpt:SetPathIndex(#chain_path)
        return
    end

    --机关显示隐藏处理
    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    if path_index <= #chain_path then
        trapServiceRender:ShowHideTrapByChainMove(posCur, false)
        --前一个格子没人
        if path_index > 1 and not self:_IsAnyPetAtChainPos(path_index - 1) then
            trapServiceRender:ShowHideTrapByChainMove(chain_path[path_index - 1], true)
        end
    end

    --最后一个pet离开起点
    if path_index <= #chain_path and path_index == 2 and self:_IsAllPetLeaveChainPos(1) then
        local playBuffSvc = self._world:GetService("PlayBuff")
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                playBuffSvc:PlayBuffView(TT, NTPlayerFirstMoveEnd:New(e, chain_path[1]))
            end
        )
    end

    --格子索引递增【pet到达格子的处理在上面！！下面path_index变成下个格子的了！！】
    path_index = path_index + 1

    --设置到达格子 时间
    move_cmpt:SetPathIndex(path_index)
    move_cmpt:AddPathArriveTime(path_index, timeService:GetCurrentTimeMs())

    --走完一个格子，检查是否需要转到普攻状态，如果不需要转普攻，就继续行走
    local hasNormalAttack = self:_CheckNormalAttack(e)
    if hasNormalAttack == true then
        --Log.fatal("Attack EntityID:",e:GetID()," Index:",path_index," Frame: ",GameGlobal:GetInstance():GetCurrentFrameCount()," Time:",timeService:GetCurrentTimeMs())
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        effectService:ShowChainMoveEffect(e, false)
        self._world:EventDispatcher():Dispatch(GameEventType.MoveFinish, 1, e:GetID())
    else
        --Log.fatal("Move EntityID:",e:GetID()," Index:",path_index," Frame: ",GameGlobal:GetInstance():GetCurrentFrameCount()," Time:",timeService:GetCurrentTimeMs())
        --走完一个格子如果没有普攻需要继续行走，否则会卡一帧
        self:UpdateChainMove(e)
    end
end
--2022/09/02 队员没有播NTPlayerEachMoveEnd
function ChainMoveSystem_Render:_OnTeamMemberArrivePos(e,path_index,chain_path)
    if path_index < 1 then
        return
    end
    local last_pos = chain_path[path_index]
    local ntPlayerEachMoveEnd = NTPlayerEachMoveEnd:New(e, last_pos, nil, nil, path_index)
    local playBuffSvc = self._world:GetService("PlayBuff")
    GameGlobal.TaskManager():CoreGameStartTask(
    function(TT)
        playBuffSvc:PlayBuffView(TT, ntPlayerEachMoveEnd)
    end
    )
end
function ChainMoveSystem_Render:_CheckNormalAttack(e)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    ---@type SkillPathNormalAttackData
    local pathNormalAttackData = self:_GetPetNormalAttackData(e)

    local position = boardServiceRender:GetRealEntityGridPos(e)
    local pathPointAttackData = pathNormalAttackData:GetPathPointAttackData(position)
    if pathPointAttackData == nil then
        Log.fatal("no pathPointAttackData:", e:GetID(), " pos ", position.x, " ", position.y)
        return false
    else
        local pathPointAttackCount = pathPointAttackData:GetPathPointAttackCount()
        --Log.fatal("pathPointAttackCount:",pathPointAttackCount ," entity id ",e:GetID()," pos ",e:GridLocation().Position.x," ",e:GridLocation().Position.y)
        if pathPointAttackCount > 0 then
            return true
        end
    end
end

---@param e Entity
function ChainMoveSystem_Render:_GetPetNormalAttackData(e)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type L2R_NormalAttackResult
    local normalAtkResCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)
    ---@type SkillPathNormalAttackData
    local pathNormalAttackData = normalAtkResCmpt:GetPetNormalAttackResult(e:GetID())
    return pathNormalAttackData
end

---@param e Entity
function ChainMoveSystem_Render:_GridMoveToPos(e, speed, curPos, destPos, teamEntity)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    effectService:ShowChainMoveEffect(e, true)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local normalSkillBeforeMove = utilDataSvc:GetEntityBuffValue(e,"NormalSkillBeforeMove")

    if normalSkillBeforeMove then
        e:SetAnimatorControllerBools({MoveSpecial = true})
    else
        e:SetAnimatorControllerBools({Move = true})
    end

    e:SetDirection(destPos - curPos)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local gridPos = boardServiceRender:GetRealEntityGridPos(e)
    e:AddGridMove(speed, destPos, gridPos)

    local move_cmpt = e:ChainMove()
    local chain_path = move_cmpt:GetChainPath()
    local path_index = move_cmpt:GetPathIndex()

    local leader = teamEntity:GetTeamLeaderPetEntity()
    if leader:GetID() == e:GetID() then
        self:_RemoveLinkageNum(path_index)
        self:_RemoveLinkLine(path_index)
    end

    --每次移动前的事件通知
    local chainPathPoint = chain_path[path_index]
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pieceType = utilData:FindPieceElement(chainPathPoint)
    ---@type PlayBuffService
    local playbufsvc = self._world:GetService("PlayBuff")
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            playbufsvc:PlayBuffView(TT, NTPlayerEachMoveStart:New(e, chainPathPoint, pieceType, path_index))
            if leader:GetID() == e:GetID() then
                playbufsvc:PlayBuffView(TT, NTTeamLeaderEachMoveStart:New(e, chainPathPoint, pieceType))
                playbufsvc:PlayBuffView(TT, NTTeamEachMoveStart:New(teamEntity, chainPathPoint, pieceType))
            end
        end
    )
end

---判断要移动的地方是不是领先前面的人了,如果是那么等着
function ChainMoveSystem_Render:_AfterFrontPet(pathIndex, e)
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    local petRoundTeam = renderBoardEntity:RenderRoundTeam():GetRoundTeam()

    local myIndex = 1
    for i, petEntityID in ipairs(petRoundTeam) do
        if e:GetID() == petEntityID then
            myIndex = i
            break
        end
    end
    ---@type TimeBaseService
    local timeService = self._world:GetService("Time")

    if myIndex ~= 1 then
        local PrePetEntityID = petRoundTeam[myIndex - 1]
        local petEntity = self._world:GetEntityByID(PrePetEntityID)

        --前一个人的
        ---@type ChainMoveComponent
        local preChainMoveComponent = petEntity:ChainMove()

        if petEntity:ChainMove() then
            ---@type ChainMoveComponent
            local chainMoveComponent = e:ChainMove()

            ---@type Entity
            local renderBoardEntity = self._world:GetRenderBoardEntity()
            ---@type L2R_NormalAttackResult
            local normalAtkCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)

            local attackCount = table.count(normalAtkCmpt:GetPlayNormalSkillSequence())
            if attackCount == 0 then
                return false
            end

            ---我不能超过我前面的人
            local index = petEntity:ChainMove():GetCurGridPathIndex()
            if index ~= 0 and index < pathIndex then
                ---第一次发现我前面有人的是有要加一个标志位
                if not chainMoveComponent:IsWait() then
                    chainMoveComponent:SetWaitState(true)
                --Log.fatal("Wait ID:",e:GetID()," Now:",timeService:GetCurrentTimeMs(),"MyWantPathIndex:",pathIndex," MyIndex:",myIndex," PrePetID:",petEntity:GetID(),"PreInPathIndex:",index)
                end
                return true
            else
                --自己可以移动的时间
                local canMoveTime = chainMoveComponent:GetCanMoveTime()
                if canMoveTime == 0 then
                    local targetPathIndex = pathIndex + 1

                    --前一个星灵  到达当前要移动目标的的时间
                    local prePetArriveTime = preChainMoveComponent:GetPathArriveTime(targetPathIndex)
                    --前一个星灵 还没有移动到目标格子
                    if not prePetArriveTime then
                        return true
                    end

                    local waitAttactTime = normalAtkCmpt:GetNormalSkillWaitTimeDic(myIndex, pathIndex)

                    if waitAttactTime < 0 then
                        waitAttactTime = 0
                    end

                    --转成毫秒
                    waitAttactTime = waitAttactTime * 1000

                    --出发延时
                    local startWaitTime = normalAtkCmpt:GetPathMoveStartWaitTime() * 1000

                    --自己可以移动的时间 =  前一个星灵到达下一个位置的时间 + 需要等待的时间
                    canMoveTime = prePetArriveTime + waitAttactTime + startWaitTime
                    chainMoveComponent:SetCanMoveTime(canMoveTime)
                end
                canMoveTime = chainMoveComponent:GetCanMoveTime()

                if timeService:GetCurrentTimeMs() > canMoveTime then
                    chainMoveComponent:SetWaitState(false)
                    chainMoveComponent:SetCanMoveTime(0)
                    return false
                else
                    return true
                end
            end
        end
    else
        return false
    end
end

function ChainMoveSystem_Render:_HasPetOnNextPathPoint(pathIndex)
    for i, ee in ipairs(self.group:GetEntities()) do
        if ee:ChainMove():GetPathIndex() == pathIndex + 1 then
            return true
        end
    end
end

function ChainMoveSystem_Render:_IsAllPetLeaveChainPos(chainIdx)
    for i, ee in ipairs(self.group:GetEntities()) do
        if ee:ChainMove():GetPathIndex() <= chainIdx then
            return false
        end
    end
    return true
end

function ChainMoveSystem_Render:_IsAnyPetAtChainPos(chainIdx)
    for i, ee in ipairs(self.group:GetEntities()) do
        if ee:ChainMove():GetPathIndex() == chainIdx then
            return true
        end
    end
    return false
end

function ChainMoveSystem_Render:_AfterPlayerMoveOneTile(e, pathIndex, chainPath)
    if pathIndex < 1 then
        return
    end
    local last_pos = chainPath[pathIndex]
    ---@type PieceServiceRender
    local pieceSvc = self._world:GetService("Piece")
    ---@type Entity
    local pieceEntity = pieceSvc:FindPieceEntity(last_pos)

    if self:_IsNeedHidePiece(pathIndex, chainPath) then
        pieceEntity:SetViewVisible(false)
    else
        self._world:GetService("Piece"):SetPieceAnimMoveDone(last_pos)
    end
    
    ---@type Entity
    local teamEntity = e:Pet():GetOwnerTeamEntity()
    local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()

    teamEntity:SetLocation(last_pos, teamLeaderEntity:GetRenderGridDirection())

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pieceType = utilData:FindPieceElement(last_pos)

    --通知移动一格结束
    local pieceEffectType = PieceEffectType.Normal
    if utilData:GetIsPrismPiece(last_pos) then
        pieceEffectType = PieceEffectType.Prism
    end
    local playBuffSvc = self._world:GetService("PlayBuff")
    local ntPlayerEachMoveEnd = NTPlayerEachMoveEnd:New(e, last_pos, pieceType, nil, pathIndex)
    ntPlayerEachMoveEnd:SetPieceEffectType(pieceEffectType)
    local ntPetChainMoveBegin = nil
    if pathIndex == 1 then
        ntPetChainMoveBegin = NTPetChainMoveBegin:New(e, last_pos, pieceType, nil, pathIndex)
        ntPetChainMoveBegin:SetPieceEffectType(pieceEffectType)
    end
    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            if ntPetChainMoveBegin then
                playBuffSvc:PlayBuffView(TT, ntPetChainMoveBegin)
            end
            playBuffSvc:PlayBuffView(TT, ntPlayerEachMoveEnd)
            if teamLeaderEntity:GetID() == e:GetID() then
                local ntTeamLeaderEachMoveEnd = NTTeamLeaderEachMoveEnd:New(e, last_pos, pieceType)
                ntTeamLeaderEachMoveEnd:SetPieceEffectType(pieceEffectType)
                playBuffSvc:PlayBuffView(TT, ntTeamLeaderEachMoveEnd)

                local ntTeamEachMoveEnd = NTTeamEachMoveEnd:New(teamEntity, last_pos, pieceType)
                ntTeamEachMoveEnd:SetPieceEffectType(pieceEffectType)
                playBuffSvc:PlayBuffView(TT, ntTeamEachMoveEnd)
            end
        end
    )

    ---到达一个格子，应用格子机关效果
    if pathIndex > 1 then
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type L2R_NormalAttackResult
        local normalAtkCmpt = renderBoardEntity:LogicResult():GetLogicResult(LogicStepType.NormalAttack)

        local triggerTraps = normalAtkCmpt:GetChainPathTriggerTrap(pathIndex)
        ---@type TrapServiceRender
        local trapServiceRender = self._world:GetService("TrapRender")
        --只有队长可以触发连线中的机关
        if triggerTraps then
            trapServiceRender:ChainMovePlayTrapTrigger(triggerTraps, e)
        end
    end
end

---@private
---@param targetEntitye Entity
---是否为chainPath的第一个位置
function ChainMoveSystem_Render:IsChainPathFstPos(targetEntity, pos)
    local cChainMove = targetEntity:ChainMove()
    local chainPath = cChainMove:GetChainPath()
    if chainPath and table.count(chainPath) > 0 then
        return pos == chainPath[1]
    end
    return false
end

function ChainMoveSystem_Render:_RemoveLinkageNum(index)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkageNumEntityList()
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    local remove_list = {}
    for _, linkageNumEntity in ipairs(allEntities) do
        ---@type LinkageNumComponent
        local linkageNumCmp = linkageNumEntity:LinkageNum()
        if linkageNumCmp:GetLinkageIndex() == index then
            linkageRenderService:DestroyLinkNum(linkageNumEntity)
            -----@type LinkageNumComponent
            --local linkageNumCmpt = linkageNumEntity:LinkageNum()
            --local entityConfigId = linkageNumCmpt:GetEntityConfigId()
            --entityPoolService:DestroyCacheEntity(linkageNumEntity, entityConfigId)
            --linkRendererDataCmpt:RemoveLinkageNumEntity(linkageNumEntity)
            return
        end
    end
end

function ChainMoveSystem_Render:_RemoveLinkLine(index)
    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")
    ---@type LinkageRenderService
    local linkageRenderService = self._world:GetService("LinkageRender")
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type LinkRendererDataComponent
    local linkRendererDataCmpt = reBoard:LinkRendererData()
    local allEntities = linkRendererDataCmpt:GetLinkLineEntityList()

    for _, linkLineEntity in ipairs(allEntities) do
        ---@type LinkLineIndexComponent
        local LinkLineIndex = linkLineEntity:LinkLineIndex()
        if LinkLineIndex:GetPathIndex() == index then
            linkageRenderService:DestroyLinkLine(linkLineEntity)
            return
        end
    end
end

function ChainMoveSystem_Render:RemoveCutChainPath()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderChainPathComponent
    local renderChainPathCmpt = renderBoardEntity:RenderChainPath()
    local cutRenderChainPath = renderChainPathCmpt:GetRenderCutChainPath()
    ---@type PieceServiceRender
    local pieceServiceRender = self._world:GetService("Piece")
    ---@type BoardServiceRender
    local sBoardRender = self._world:GetService("BoardRender")
    local ePreview = self._world:GetPreviewEntity()
    
        
    for index, pos in pairs(cutRenderChainPath) do
        self:_RemoveLinkageNum(index)
        self:_RemoveLinkLine(index)
        pieceServiceRender:SetPieceAnimNormal(pos)
        
    end

    if cutRenderChainPath then
        local indexArray = {}
        for index, pos in pairs(cutRenderChainPath) do--初始index大于1
            table.insert(indexArray,index)
        end
        table.sort(indexArray, function(a, b)
            return a > b
         end)--需要从后向前回退
        for _, tarIndex in ipairs(indexArray) do
            local pos = cutRenderChainPath[tarIndex]
            if ePreview then
                local cPreviewEnv = ePreview:PreviewEnv()
                if cPreviewEnv and cPreviewEnv:IsPrismPiece(pos) then
                    sBoardRender:UnapplyPrism(pos)
                end
            end
        end
    end
end

function ChainMoveSystem_Render:_IsNeedHidePiece(index, chainPath)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---非镂空刷新不隐藏
    if not utilDataSvc:IsPieceRefreshTypeDestroy() then
        return false
    end

    ---极光时刻不隐藏
    if utilDataSvc:GetStatIsRoundAuroraTime() then
        return false
    end

    ---连线终点不隐藏
    if index == #chainPath then
        return false
    end

    ---格子上有怪不隐藏
    local pos = chainPath[index]
    if utilDataSvc:GetMonsterAtPos(pos) then
        return false
    end

    return true
end
