require("pick_up_policy_base")

---@class PickUpPolicy_PetDiNa: PickUpPolicy_Base
_class("PickUpPolicy_PetDiNa", PickUpPolicy_Base)
PickUpPolicy_PetDiNa = PickUpPolicy_PetDiNa

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetDiNa:CalcAutoFightPickUpPolicy(calcParam)
    ---@type Entity
    local petEntity = calcParam.petEntity
    local petPos = petEntity:GetGridPosition():Clone()
    local activeSkillID = calcParam.activeSkillID

    ---需要返回的三个数据
    local posList = {}
    local attackPosList = {} --攻击范围
    local targetIDList = {}  --攻击目标

    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillCfgData = configSvc:GetSkillConfigData(activeSkillID)
    local pickUpParam = skillCfgData:GetSkillPickParam()
    local depth = pickUpParam[1] or 0
    local pieceType = pickUpParam[2] or PieceType.Blue
    local canLinkMonster = (pickUpParam[3] or 0) == 1
    if depth == 0 then
        return posList, attackPosList, targetIDList
    end

    ---连线颜色排除转色目标颜色及万色格子
    local pieceTypeList = { PieceType.Blue, PieceType.Red, PieceType.Green, PieceType.Yellow }
    table.removev(pieceTypeList, pieceType)

    ---查找最近的目标
    local targetEntity = nil
    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---黑拳赛目标就是敌方队伍
        if petEntity:HasPet() then
            targetEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
        end
    else
        ---获取最近的怪物
        ---@type UtilScopeCalcServiceShare
        local utilScope = self._world:GetService("UtilScopeCalc")
        local monsterList, monsterPosList = utilScope:SelectNearestMonsterOnPos(petPos, 1)
        if monsterList and #monsterList > 0 then
            targetEntity = monsterList[1]
        end
    end
    if not targetEntity then
        return posList, attackPosList, targetIDList
    end
    table.insert(targetIDList, targetEntity:GetID())

    posList = self:FindPath_MonsterMoveGridByParam(petEntity, targetEntity, pieceTypeList, depth, canLinkMonster)
    attackPosList = posList

    return posList, attackPosList, targetIDList
end

---@param casterEntity Entity 移动者
---@param targetEntity Entity 目标
---@param pieceTypeList PieceType[] 可移动的颜色格子
---@param moveType MovePathType 移动策略
function PickUpPolicy_PetDiNa:FindPath_MonsterMoveGridByParam(casterEntity, targetEntity, pieceTypeList, depth,
                                                              canLinkMonster)
    local movePath = {}
    --N25吸血鬼Boss移动环境
    self._diNaChainPaths = {}
    self._diNaChainIndexPaths = {}
    self._diNaMoveForward = false
    self._diNaConnectMap = {}
    self._HighConnectRateCutLen = 0
    self._maxlen = 0
    self._cutlen = 0

    --构建联通地图
    self:_BuildConnectMapByPieceTypeList(casterEntity, pieceTypeList)

    self._HighConnectRateCutLen = self:_CalcHighConnectRateCutLen(casterEntity)

    --计算所有联通路线
    self:_CalcAllMovePathByPieceTypeList(casterEntity, pieceTypeList, depth)

    --根据移动策略，找到最佳路线
    movePath = self:_FindPathNearToTarget4(targetEntity)

    if #movePath < 1 then
        --施法者所在格子填充进路径中
        local pos = casterEntity:GetGridPosition()
        movePath = { pos }
    end

    if canLinkMonster then
        local endPos = movePath[#movePath]
        local endPosIndex = Vector2.Pos2Index(endPos)
        local targetPos = targetEntity:GetGridPosition()
        local posIndex = Vector2.Pos2Index(targetPos)
        local aroundPosList = self:_GetPosIndexListByOffset(posIndex, Offset8)
        if table.icontains(aroundPosList, endPosIndex) then
            movePath[#movePath + 1] = targetPos
        end
    end

    if #movePath <= 1 then
        movePath = {}
    end

    --重置N25吸血鬼Boss移动环境
    self._diNaChainPaths = {}
    self._diNaChainIndexPaths = {}
    self._diNaMoveForward = false
    self._diNaConnectMap = {}
    self._HighConnectRateCutLen = 0
    self._maxlen = 0
    self._cutlen = 0

    return movePath
end

---@param entity Entity
---@param pieceTypeList PieceTypy[]
function PickUpPolicy_PetDiNa:_BuildConnectMapByPieceTypeList(entity, pieceTypeList)
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()

    local pos = entity:GetGridPosition()
    local posIndex = Vector2.Pos2Index(pos)

    --构建当前可移动范围
    local blockFlag = BlockFlag.LinkLine
    local blockCanMoveMap = boardCmpt:GetBlockFlagCanMoveMap(blockFlag)

    --构建需求颜色联通地图
    self:_ConnectMapByPieceTypeList(posIndex, pieceTypeList, boardCmpt, blockCanMoveMap)

    --清除可移动范围缓存
    boardCmpt:ClearBlockFlagCanMoveMap(blockFlag)
end

function PickUpPolicy_PetDiNa:_CanMatchPieceTypeList(type, typeList)
    if type == PieceType.None then
        return false
    end

    return table.icontains(typeList, type)
end

function PickUpPolicy_PetDiNa:_Offset2Index(i, j)
    local t = {
            [1] = { 6, 7, 8 },
            [2] = { 5, 0, 1 },
            [3] = { 4, 3, 2 }
    }
    return t[i + 2][j + 2]
end

---@param boardCmpt BoardComponent
function PickUpPolicy_PetDiNa:_ConnectMapByPieceTypeList(posIndex, pieceTypeList, boardCmpt, blockCanMoveMap)
    if self._diNaConnectMap[posIndex] then
        return
    end

    local ct = {}
    self._diNaConnectMap[posIndex] = ct

    for _, offset in ipairs(Offset8) do
        local offsetVec = Vector2(offset[1], offset[2])
        local surroundIndex = posIndex + Vector2.Pos2Index(offsetVec)
        if blockCanMoveMap[surroundIndex] then
            local surroundPiece = boardCmpt:GetPieceTypeByIndex(surroundIndex)
            if CanMatchPieceTypeList(surroundPiece, pieceTypeList) then
                ct[self:_Offset2Index(offsetVec.x, offsetVec.y)] = surroundIndex
                self:_ConnectMapByPieceTypeList(surroundIndex, pieceTypeList, boardCmpt, blockCanMoveMap)
            end
        end
    end
end

--计算所有连线情况
function PickUpPolicy_PetDiNa:_CalcAllMovePathByPieceTypeList(casterEntity, pieceTypeList, depth)
    local pos = casterEntity:GetGridPosition()
    local startPosIndex = Vector2.Pos2Index(pos)
    local chainPathIdx = { startPosIndex }

    self:_NextMoveByPieceTypeList(chainPathIdx, pieceTypeList, depth)
end

function PickUpPolicy_PetDiNa:_NextMoveByPieceTypeList(chainPathIdx, pieceTypeList, depth)
    if depth == 0 then
        return
    end

    local startPosIdx = chainPathIdx[#chainPathIdx]
    --不能联通则回退
    local ct = self._diNaConnectMap[startPosIdx]
    if not ct or table.count(ct) == 0 then
        return
    end

    for i = 1, 8 do
        --长度优化导致裁剪了部分路径，不尝试这部分了
        if startPosIdx ~= chainPathIdx[#chainPathIdx] then
            return
        end
        local posIdx = ct[i]
        if posIdx and not table.icontains(chainPathIdx, posIdx) then
            chainPathIdx[#chainPathIdx + 1] = posIdx
            local s = table.concat(chainPathIdx, " ")
            --Log.fatal("KZY: path+: ", s)
            self._diNaMoveForward = true
            self:_NextMoveByPieceTypeList(chainPathIdx, pieceTypeList, depth - 1)

            if self._diNaMoveForward and #chainPathIdx > 1 then
                self._diNaMoveForward = false
                --结果
                local chainPath = {}
                for n = 1, #chainPathIdx do
                    chainPath[#chainPath + 1] = Vector2.Index2Pos(chainPathIdx[n])
                end
                if table.icontains(self._diNaChainIndexPaths, chainPathIdx) then
                    return
                end
                self._diNaChainPaths[#self._diNaChainPaths + 1] = chainPath
                self._diNaChainIndexPaths[#self._diNaChainIndexPaths + 1] = table.cloneconf(chainPathIdx)
                local s = table.concat(chainPathIdx, " ")
                --Log.fatal("KZY: find sucess: 第", #self._diNaChainIndexPaths, "条路径: ", s)

                --计算裁剪路径
                self._maxlen = #chainPathIdx
                self._cutlen = self:_CalcChainPathComplexityLen(chainPathIdx)
            end

            --逐步撤回
            if startPosIdx == chainPathIdx[#chainPathIdx - 1] then
                local len = #chainPathIdx
                chainPathIdx[len] = nil
                local s = table.concat(chainPathIdx, " ")
                --Log.fatal("KZY: path-: ", s)
            end

            --无论如何回溯最后4步
            if self._maxlen - #chainPathIdx == 4 then
                for n = #chainPathIdx, self._cutlen, -1 do
                    local len = #chainPathIdx
                    chainPathIdx[len] = nil
                    local s = table.concat(chainPathIdx, " ")
                    --Log.fatal("KZY: path-: ", s)
                end
            end
        end
    end
end

---@param targetEntity Entity
function PickUpPolicy_PetDiNa:_FindPathNearToTarget4(targetEntity)
    --获取目标周围点
    local offsetList = Offset4

    local targetPos = targetEntity:GetGridPosition()
    local posIndex = Vector2.Pos2Index(targetPos)
    local highValuePosIdxList = self:_GetPosIndexListByOffset(posIndex, offsetList)

    local retPath = {}

    --寻找目标周围可攻击位置最多的路径
    local unionCount = 0
    local retIndex = 0
    for i, chainPathIdx in ipairs(self._diNaChainIndexPaths) do
        local targetInPath = table.union(chainPathIdx, highValuePosIdxList)
        if unionCount < #targetInPath then
            unionCount = #targetInPath
            retIndex = i
            if unionCount == #highValuePosIdxList then
                break
            end
        end
    end

    local disMin = MAX_INT_32
    local chainPathIndex = 0
    --local chainPosIndex = 0

    if retIndex > 0 then
        chainPathIndex = retIndex
    else
        --目标位置可攻击点均无法抵达，则寻找距离目标的最近路径
        for i, chainPath in ipairs(self._diNaChainPaths) do
            local chainPos = chainPath[#chainPath]
            local dis = Vector2.Distance(chainPos, targetPos)
            if dis < disMin then
                disMin = dis
                chainPathIndex = i
            end
        end
    end

    if chainPathIndex > 0 then
        retPath = self._diNaChainPaths[chainPathIndex]
    end

    return retPath
end

---@param posIndex Vector2
---@return number[]
function PickUpPolicy_PetDiNa:_GetPosIndexListByOffset(posIndex, offsetList)
    local posIndexList = {}
    for _, offset in ipairs(offsetList) do
        local offsetVec = Vector2(offset[1], offset[2])
        local index = posIndex + Vector2.Pos2Index(offsetVec)
        table.insert(posIndexList, index)
    end
    return posIndexList
end

---@param casterEntity Entity
function PickUpPolicy_PetDiNa:_CalcHighConnectRateCutLen(casterEntity)
    local connectMap = self._diNaConnectMap
    local playerPos = casterEntity:GetGridPosition()
    local playerPosIndex = Vector2.Pos2Index(playerPos)

    local touchIdx = {}
    local totalConnect = 0
    local totalPosNum = 0

    local search
    search = function(posIndex)
        touchIdx[posIndex] = true
        totalPosNum = totalPosNum + 1
        local ct = connectMap[posIndex]
        for i = 1, 8 do
            local nextIdx = ct[i]
            if nextIdx then
                totalConnect = totalConnect + 1
                if not touchIdx[nextIdx] then
                    search(nextIdx)
                end
            end
        end
    end

    search(playerPosIndex)
    local rate = totalConnect / totalPosNum
    local cutlen = 0
    local idx = BattleConst.AutoFightMoveEnhanced and 2 or 1
    if totalPosNum > BattleConst.AutoFightPathLengthCutPosNum and
        rate > BattleConst.AutoFightPathLengthCutConnectRate[idx] then
        cutlen = BattleConst.AutoFightPathLengthCut
    end
    Log.debug("[AutoFight] _CalcHighConnectRateCutLen() totalPosNum=", totalPosNum, " ConnectRate=", rate)
    return cutlen
end

function PickUpPolicy_PetDiNa:_CalcChainPathComplexityLen(chainPathIdx)
    if self._HighConnectRateCutLen > 0 then
        return self._HighConnectRateCutLen
    end
    local m = BattleConst.AutoFightMoveEnhanced and 2 or 1
    local cc = 1
    local len = #chainPathIdx
    for i, idx in ipairs(chainPathIdx) do
        cc = cc * table.count(self._diNaConnectMap[idx])
        if cc > BattleConst.AutoFightPathComplexity[m] then
            len = i - 1
            break
        end
    end
    return len
end
