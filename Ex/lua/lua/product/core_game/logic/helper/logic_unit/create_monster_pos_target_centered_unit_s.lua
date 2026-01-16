---用在围绕玩家或指定怪物找刷新位置的计算单元，负责给定范围，根据距离选择位置，维护已选择的位置等

_class("CreateMonsterPosTargetCenteredUnit", Object)
---@class CreateMonsterPosTargetCenteredUnit : Object
CreateMonsterPosTargetCenteredUnit = CreateMonsterPosTargetCenteredUnit

function CreateMonsterPosTargetCenteredUnit:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._gridList = {}
    self._gridByRing = {}
end

function CreateMonsterPosTargetCenteredUnit:InitGridList(v2CenterPos, filterBlockFlag)
    ---@type Entity
    local eBoard = self._world:GetBoardEntity()
    local cBoard = eBoard:Board()
    -- 这里用pairs是必须的，因为里面可能不是连续的东西，取到格子后会按规则重新排序
    for x, ys in pairs(cBoard._blockFlags) do
        for y, blockData in pairs(ys) do
            -- 中心点不算
            if ((x ~= v2CenterPos.x) or (y ~= v2CenterPos.y)) then
                local posBlockFlag = blockData:GetBlock()
                -- 只要该格子不*完全满足*筛选条件，就可以视为有效的点，以免筛掉一些部分有效的位置
                -- 例如：filterBlockFlag == BlockFlag.MonsterLand & BlockFlag.MonsterFly
                -- 如果一个位置的阻挡信息不包含MonsterFly，但包含MonsterLand，也视作有效位置
                if (posBlockFlag & filterBlockFlag) ~= filterBlockFlag then
                    table.insert(self._gridList, Vector2.New(x, y))
                end
            end
        end
    end

    for _, v2 in ipairs(self._gridList) do
        local ring = math.max(math.abs(v2.x - v2CenterPos.x), math.abs(v2.y - v2CenterPos.y))
        if not self._gridByRing[ring] then
            self._gridByRing[ring] = {}
        end
        table.insert(self._gridByRing[ring], v2)
    end
end

---@param blockFlag BlockFlag
function CreateMonsterPosTargetCenteredUnit:GetPosByBlockFlag(blockFlag, preferRadius, area)
    if #(self._gridList) == 0 then
        Log.info(self._className, "Not enough empty grid. ")
        return nil
    end

    local v2SelectedPos

    local preferPool = {}
    for i = 1, preferRadius do
        if self._gridByRing[i] then
            table.appendArray(preferPool, self._gridByRing[i])
        end
    end

    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")
    local theoryMaxRing = math.max(lsvcBoard:GetCurBoardMaxX(), lsvcBoard:GetCurBoardMaxY())

    ---@type UtilDataServiceShare
    local usvcUtilData = self._world:GetService("UtilData")
    ---@type RandomServiceLogic
    local lsvcRandom = self._world:GetService("RandomLogic")

    local currentRing = preferRadius
    while (not v2SelectedPos) do
        if #preferPool ~= 0 then
            local index = lsvcRandom:LogicRand(1, #preferPool)
            local v2 = table.remove(preferPool, index)
            local isPosSuitable = true
            for _, v2Relative in ipairs(area) do
                local v2Pos = v2 + v2Relative
                if not usvcUtilData:IsPosBlock(v2Pos, blockFlag) then
                    isPosSuitable = false
                    break
                end
            end

            if isPosSuitable then
                v2SelectedPos = v2
            end
        else
            -- 再往外找一圈
            for i = currentRing + 1, theoryMaxRing do
                if self._gridByRing[i] then
                    for k, v in ipairs(self._gridByRing[i]) do
                        preferPool[k] = v
                    end
                    currentRing = i
                    break
                end
            end
            --到这里还没找到那就是真的没位置了
            if currentRing == theoryMaxRing then
                break
            end
        end
    end

    return v2SelectedPos
end

function CreateMonsterPosTargetCenteredUnit:RemovePosFromCache(v2, body)
    body = body or {Vector2.zero}

    for _, v2Relative in ipairs(body) do
        local v2Pos = v2 + v2Relative
        local gridIndex = table.ikey(self._gridList, v2Pos)
        if gridIndex then
            table.remove(self._gridList, gridIndex)
        end

        for _, list in pairs(self._gridByRing) do
            local gridRingIndex = table.ikey(self._gridList, v2Pos)
            if gridRingIndex then
                table.remove(list, gridRingIndex)
            end
        end
    end
end
