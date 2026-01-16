--[[
    MoveBoard = 140, --移动棋盘
]]
---@class SkillEffectCalc_MoveBoard: Object
_class("SkillEffectCalc_MoveBoard", Object)
SkillEffectCalc_MoveBoard = SkillEffectCalc_MoveBoard

function SkillEffectCalc_MoveBoard:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MoveBoard:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamMoveBoard
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type SkillEffectParamMoveBoard
    self._skillEffectParam =skillEffectParam
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local times = skillEffectParam:GetTimes()
    local direction = skillEffectParam:GetDirection()
    local destroyOutTrap = skillEffectParam:GetDestroyOutTrap()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local arr = board:GetBlockFlagArray()

    --用配置的技能范围重新算一遍排序
    local skillRange = {}
    for x, col in pairs(arr) do
        for y, block in pairs(col) do
            local grid = Vector2(x, y)

            if not boardServiceLogic:IsPosBlock(grid, BlockFlag.SkillSkip) then
                if direction.x ~= 0 then
                    if not skillRange[grid.x] then
                        skillRange[grid.x] = {}
                    end
                    table.insert(skillRange[grid.x], grid)
                elseif direction.y ~= 0 then
                    if not skillRange[grid.y] then
                        skillRange[grid.y] = {}
                    end
                    table.insert(skillRange[grid.y], grid)
                end
            end
        end
    end

    if direction == Vector2(0, 1) or direction == Vector2(1, 0) then
        skillRange = self:_SmallToLargeSort(skillRange)
    elseif direction == Vector2(0, -1) or direction == Vector2(-1, 0) then
        skillRange = self:_OnReinsert(skillRange)
    end

    self._fourAreaFixPos = Vector2(0, 0)

    if direction == Vector2(0, 1) then
        self._fourAreaFixPos = Vector2(1, 1)
    elseif direction == Vector2(0, -1) then
        self._fourAreaFixPos = Vector2(1, 0)
    elseif direction == Vector2(1, 0) then
        self._fourAreaFixPos = Vector2(1, 1)
    elseif direction == Vector2(-1, 0) then
        self._fourAreaFixPos = Vector2(0, 1)
    end

    local results = {}
    --次数
    for i = 1, times do
        --1次内的传送是一个结果，在一次播放
        local result = SkillEffectResultMoveBoard:New()
        for index, posList in pairs(skillRange) do
            -- --1.构建环境
            -- local envList = self:_CalcMoveBoardEnvList(posList)
            local isLast = (index == table.count(skillRange))
            --2.传送一步+触发机关
            self:_MoveBoardOneStepNew(result, posList, direction, destroyOutTrap, casterEntity, isLast)
        end
        results[#results + 1] = result
    end

    return results
end

function SkillEffectCalc_MoveBoard:_SmallToLargeSort(posDic)
    local sortDicFunc = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end
        table.sort(
            keyList,
            function(a, b)
                return a > b
            end
        )
        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end
    posDic = sortDicFunc(posDic)
    return posDic
end

function SkillEffectCalc_MoveBoard:_OnReinsert(posDic)
    local sortDicFunc = function(dic)
        local newDic = {}
        local keyList = {}
        for k, _ in pairs(dic) do
            table.insert(keyList, k)
        end

        for i = 1, #keyList do
            newDic[#newDic + 1] = dic[keyList[i]]
        end
        return newDic
    end
    posDic = sortDicFunc(posDic)
    return posDic
end

--传送一步
---@param result SkillEffectResultMoveBoard
function SkillEffectCalc_MoveBoard:_MoveBoardOneStepNew(result, posList, direction, destroyOutTrap, casterEntity, isLast)
    ---@type RandomServiceLogic
    local sRandom = self._world:GetService("RandomLogic")
    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    --收集可触发的机关信息
    local toTriggerTraps = {}
    local toDeadTraps = {}

    for i, pos in ipairs(posList) do
        local curPos = pos
        --目标位置
        local targetPos = pos + direction
        local nextPos = pos - direction

        local pieceType = boardCmpt:GetPieceType(pos)
        local nextPieceType = boardCmpt:GetPieceType(nextPos)
        -- local targetPieceType = boardCmpt:GetPieceType(targetPos)
        local targetPieceType = utilData:IsValidPiecePos(targetPos)

        local isPrism = boardCmpt:IsPrismPiece(pos)
        local prismEntityID = isPrism and boardCmpt:GetPrismEntityIDAtPos(pos) or nil

        local filter = function(e)
            if e:HasDeadMark() then
                return false
            end

            local moreAreaCanMove = true

            local bodyArea = e:BodyArea()
            if bodyArea then
                local area = bodyArea:GetArea()
                --处理多格怪物。 要求位移点是中心点  and  身形中没有占据最后一个点的
                if table.count(area) > 1 then
                    local gridPos = e:GetGridPosition()
                    --临时处理42830
                    if table.count(area) == 4 then
                        if (gridPos + self._fourAreaFixPos) ~= pos then
                            moreAreaCanMove = false
                        end
                    else
                        if gridPos ~= pos then
                            moreAreaCanMove = false
                        end
                    end
                end
            end

            local blockFlag = BlockFlag.None
            if e:HasBlockFlag() then
                blockFlag = e:BlockFlag():GetBlockFlag()
            end

            if blockFlag & BlockFlag.MoveBoard ~= 0 then
                moreAreaCanMove = false
            end

            return e ~= e:HasBlockFlag() and moreAreaCanMove
        end
        local es = boardCmpt:GetPieceEntities(pos, filter)

        if targetPieceType then
            --传送格子
            result:AddMoveBoardPiece(curPos, targetPos)

            for i, e in ipairs(es) do
                local canMove = true

                --其他，怪物，队伍都判断阻挡
                local blockFlag = BlockFlag.MonsterLand
                --多格需要判断所有身形都不阻挡
                local bodyArea = {}
                if e:HasBodyArea() then
                    bodyArea = e:BodyArea():GetArea()
                end
                local gridPos = e:GetGridPosition()
                local targetPosList = {}
                local bodyAreaPosList = {}
                if table.count(bodyArea) > 1 then
                    for _, area in ipairs(bodyArea) do
                        local workPos = gridPos + area
                        table.insert(bodyAreaPosList, workPos)
                        local areaPos = workPos + direction
                        table.insert(targetPosList, areaPos)
                    end
                elseif gridPos then
                    local areaPos = gridPos + direction
                    targetPosList = {areaPos}
                    bodyAreaPosList = {gridPos}
                end

                if #targetPosList == 0 then
                    canMove = false
                end

                for _, pos in ipairs(targetPosList) do
                    --下个位置   不是当前身形内的一个坐标  and （不在棋盘内  or 阻挡怪物移动）
                    if
                        not table.intable(bodyAreaPosList, pos) and
                            (not utilData:IsValidPiecePos(pos) or boardServiceLogic:IsPosBlock(pos, blockFlag))
                     then
                        canMove = false
                        break
                    end
                end

                --如果是机关，再特殊判断一下。判断自己有阻挡信息 and 前方阻挡 才不移动。否则可以无视阻挡移动
                if e:HasTrapID() and not canMove then
                    local curBlockFlag = e:BlockFlag():GetBlockFlag()
                    if curBlockFlag & BlockFlag.LinkLine == 0 then
                        canMove = true
                    end
                end

                if canMove then
                    --临时处理42830
                    if table.count(bodyArea) == 4 then
                        result:AddMoveBoardEntity(
                            e:GetID(),
                            curPos - self._fourAreaFixPos,
                            targetPos - self._fourAreaFixPos
                        )
                        e:SetGridPosition(targetPos - self._fourAreaFixPos)
                        boardServiceLogic:UpdateEntityBlockFlag(
                            e,
                            curPos - self._fourAreaFixPos,
                            targetPos - self._fourAreaFixPos
                        )
                    else
                        --传送entity结果
                        result:AddMoveBoardEntity(e:GetID(), curPos, targetPos)
                        --修改棋盘数据
                        e:SetGridPosition(targetPos)
                        boardServiceLogic:UpdateEntityBlockFlag(e, curPos, targetPos)
                    end

                    --队伍位置更新
                    if e:HasTeam() then
                        local pets = e:Team():GetTeamPetEntities()
                        for i, e in ipairs(pets) do
                            e:SetGridPosition(targetPos)
                        end
                    elseif e:HasTrapID() then
                        --检测下一个格子有不能移动的，是否有怪物或者是队伍。如果有，用于触发移动机关的触发技能
                        local targetEntity = nil

                        local blockEntitys =
                            boardCmpt:GetPieceEntities(
                            targetPos,
                            function(e)
                                return (e:HasTeam() or e:HasMonsterID()) and not e:HasDeadMark()
                            end
                        )

                        if #es > 0 then
                            targetEntity = es[1]
                        end

                        if targetEntity then
                            toTriggerTraps[#toTriggerTraps + 1] = {e, targetEntity}
                        end
                    end

                    --通知传送带传送一次
                    sTrigger:Notify(NTTransportEachMoveEnd:New(e, curPos, targetPos))
                else
                    --如果不能移动，从moveEntity移动到blockEntity
                end
            end

            ---@type Entity
            local teamEntity = self._world:Player():GetCurrentTeamEntity()
            local teamPos = teamEntity:GetGridPosition()

            --格子转色
            if teamPos == curPos then
                pieceType = sRandom:LogicRand(1, 4)
            end
            if teamPos == targetPos then
                pieceType = PieceType.None
            end

            result:AddConvertColor(targetPos, targetPieceType, pieceType)
            --转色生效
            -- if utilData:IsValidPiecePos(targetPos) then
            boardServiceLogic:SetPieceTypeLogic(pieceType, targetPos)
            -- end

            --棱镜
            if isPrism then
                if teamPos == targetPos then
                    --下个位置为空就删除棱镜
                    result:AddMoveBoardPrism(curPos, nil, prismEntityID)
                else
                    result:AddMoveBoardPrism(curPos, targetPos, prismEntityID)
                end
            end
        else
            --移除传送带范围的格子也需要添加移动结果
            result:AddMoveBoardPiece(curPos, targetPos)

            --删除棱镜
            if isPrism then
                result:AddMoveBoardPrism(curPos, nil, prismEntityID)
            end

            --在最后一格找到可以位移的   销毁传出格子的机关
            for i, entity in ipairs(es) do
                --能位移的机关
                if entity:HasTrapID() and destroyOutTrap == 1 then
                    result:AddMoveBoardEntity(entity:GetID(), curPos, targetPos)

                    --修改棋盘数据
                    entity:SetGridPosition(targetPos)
                    boardServiceLogic:RemoveEntityBlockFlag(entity, curPos)

                    table.insert(toDeadTraps, entity)
                else
                    --如果不能移动，从moveEntity移动到blockEntity
                    -- env.blockEntity[#env.blockEntity + 1] = entity
                end
            end
        end
    end

    --棱镜处理
    for i, v in ipairs(result:GetMoveBoardPrisms()) do
        local oldPos = v[1]
        boardCmpt:RemovePrismPiece(oldPos)
        local newPos = v[2]
        local prismEntityID = v[3]
        if newPos then
            boardCmpt:AddPrismPiece(newPos, prismEntityID)
        end
    end

    if isLast then
        for i, pos in ipairs(posList) do
            local curPieceType = boardCmpt:GetPieceType(pos)

            --划入第一个格子的坐标
            local envIndexZeroPos = pos - direction
            ---计算出要填充的列表
            local pieceFillTable = boardServiceLogic:SupplyPieceList({pos})
            ---连线最后一个点是角色将要站立的目标点
            local newPieceType = pieceFillTable[1].color

            if newPieceType ~= curPieceType then
                result:AddConvertColor(pos, curPieceType, newPieceType)
                --转色生效
                boardServiceLogic:SetPieceTypeLogic(newPieceType, pos)
            end

            result:AddMoveBoardPiece(envIndexZeroPos, pos)
            result:AddMoveBoardPieceCutIn(envIndexZeroPos, pos, newPieceType)

            --第一排划入的格子要有转色通知，从灰色转
            local convertInfoArray = {}
            --棋盘外的那个格子，从灰色转色成当前颜色
            local convertInfo = NTGridConvert_ConvertInfo:New(envIndexZeroPos, PieceType.None, newPieceType)
            table.insert(convertInfoArray, convertInfo)
            if #convertInfoArray > 0 then
                ---@type NTGridConvert
                local nt = NTGridConvert:New(casterEntity, convertInfoArray)
                sTrigger:Notify(nt)
                nt:SetSkillType(self._skillEffectParam:GetSkillType())
            end
        end
    end

    --触发机关
    for i, v in ipairs(toTriggerTraps) do
        self:_TriggerTraps(result, v[1], v[2])
    end

    --机关死亡
    for i, entity in ipairs(toDeadTraps) do
        self:_DestroyTrap(result, entity)
    end
end

--触发机关
---@param result SkillEffectResultMoveBoard
function SkillEffectCalc_MoveBoard:_TriggerTraps(result, trapEntity, triggerEntity)
    --机关不能触发机关
    if triggerEntity:HasTrapID() then
        return
    end

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    local triggerTraps, triggerResults = trapServiceLogic:CalcTrapTriggerSkill(trapEntity, triggerEntity)
    if triggerTraps then
        for i, trap in ipairs(triggerTraps) do
            local skillResult = triggerResults[i]
            result:AddTrapSkillResult(trap:GetID(), skillResult, triggerEntity:GetID())
        end
    end
end

function SkillEffectCalc_MoveBoard:_DestroyTrap(result, trapEntity)
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    ---@type TrapComponent
    local trapCmpt = trapEntity:Trap()
    trapEntity:Attributes():Modify("HP", 0)
    --关闭死亡技能
    local disableDieSkill = true
    trapServiceLogic:AddTrapDeadMark(trapEntity, disableDieSkill)

    result:AddTrapDestroyList(trapEntity:GetID())
end

--拿到前后offset个格子的env
function SkillEffectCalc_MoveBoard:_GetNeighboringEnv(envList, env)
    local total = #envList
    local envIdx = env.index
    local idx = envIdx - 1
    local neighboringEnv = envList[idx]
    return neighboringEnv
end
