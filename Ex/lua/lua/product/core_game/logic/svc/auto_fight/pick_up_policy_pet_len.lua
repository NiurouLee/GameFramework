require("pick_up_policy_base")

_class("PickUpPolicy_PetLen", PickUpPolicy_Base)
---@class PickUpPolicy_PetLen: PickUpPolicy_Base
PickUpPolicy_PetLen = PickUpPolicy_PetLen

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetLen:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetLen(policyParam,petEntity)
    return pickPosList, atkPosList, targetIds, extraParam
end
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function PickUpPolicy_PetLen:_CalPickPosPolicy_PetLen(policyParam, petEntity)
    local pickPosList = {}
    local atkPosList = {}
    local targetIds = {}
    local extraParam = {}

    local greatestHPVal = 0
    ---@type Entity|nil
    local greatestHPValEntity
    local posIndexEntityIDDic = {}
    ---@type Entity[]
    local monsterGlobalEntityGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        monsterGlobalEntityGroup = {petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()}
    end
    --魔方
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()
    for _, e in ipairs(monsterGlobalEntityGroup) do
        local isSelectable = true
        if e:HasBuff() then
            isSelectable = not e:BuffComponent():HasBuffEffect(BuffEffectType.NotBeSelectedAsSkillTarget)
        end
        if (not e:HasDeadMark()) and isSelectable then
            local hp = e:Attributes():GetCurrentHP()
            local tv2BodyArea = e:BodyArea():GetArea()
            local v2GridPos = e:GetGridPosition()
            local eid = e:GetID()
            local hasValidBodyPos = false
            for _, v2Relative in ipairs(tv2BodyArea) do
                ---@type Vector2
                local v2 = v2GridPos + v2Relative
                if not table.intable(extraBoardPosRange, v2) then
                    local index = Vector2.Pos2Index(v2)
                    posIndexEntityIDDic[index] = eid
                    hasValidBodyPos = true
                end
            end
            
            if hasValidBodyPos then
                if hp > greatestHPVal then
                    greatestHPVal = hp
                    greatestHPValEntity = e
                end
            end
        end
    end

    if not greatestHPValEntity then
        Log.debug(self._className, "自动主动技释放：场上没怪")
        return pickPosList, atkPosList, targetIds, extraParam
    end

    local greatestHPValEntityID = greatestHPValEntity:GetID()
    Log.debug(self._className, "自动主动技释放：必然包含目标：", greatestHPValEntityID)
    --覆盖方式推算：在确保技能范围能够覆盖这个血量最高的目标的同时，尽可能推算出覆盖单位更多的范围
    local greatestHPValGridPos = greatestHPValEntity:GetGridPosition()
    if table.intable(extraBoardPosRange, greatestHPValGridPos) then--魔方boss gridPos不在bodyArea中
        --从bodyArea中重选一个位置
        local v2GridPos = greatestHPValGridPos
        local tv2BodyArea = greatestHPValEntity:BodyArea():GetArea()
        local validList = {}
        for _, v2Relative in ipairs(tv2BodyArea) do
            ---@type Vector2
            local v2 = v2GridPos + v2Relative
            if not table.intable(extraBoardPosRange, v2) then
                table.insert(validList,v2)
            end
        end
        --选一个左下角吧
        if #validList > 0 then
            table.sort(validList,
                function (a, b) 
                    if a.x ~= b.x then
                        return a.x < b.x
                    else
                        return a.y < b.y
                    end
                end
            )
            greatestHPValGridPos = validList[1]
        else--正常不会有else
            return pickPosList, atkPosList, targetIds, extraParam
        end
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local testResult = {}
    local resultIndex = 0
    -- 参数是两个为一组的范围偏移，如2, 2表示<x, y>到<x+2, y+2>的连线划定矩形内，-2, -2表示<x, y>到<x-2, y-2>，etc.
    for i = 1, #policyParam, 2 do
        local policyXOffset = policyParam[i]
        local policyYOffset = policyParam[i + 1]
        local gridPosX = greatestHPValGridPos.x
        local gridPosY = greatestHPValGridPos.y
        local gridPosOffsetX = gridPosX + policyXOffset
        local gridPosOffsetY = gridPosY + policyYOffset
        local pickPos2 = Vector2.New(gridPosOffsetX, gridPosOffsetY)
        -- 如果这个理论终点不是有效格子，就不往下算了
        if utilData:IsValidPiecePos(pickPos2) then
            if not self:_IsPosInExtraBoard(pickPos2,extraBoardPosRange) then
                resultIndex = resultIndex + 1
                local result = {
                    greatestHPValEntityCount = 0,
                    otherMonsterEntityCount = 0,
                    index = resultIndex,
                    x1 = gridPosX,
                    x2 = gridPosOffsetX,
                    y1 = gridPosY,
                    y2 = gridPosOffsetY,
                    targetIDs = {}
                }
                --这里这么取一下上下限，不然如果给出的下限比上限低，循环就没用了
                local minX = math.min(gridPosX, gridPosOffsetX)
                local maxX = math.max(gridPosX, gridPosOffsetX)
                local minY = math.min(gridPosY, gridPosOffsetY)
                local maxY = math.max(gridPosY, gridPosOffsetY)
                for x = minX, maxX do
                    for y = minY, maxY do
                        local v2 = Vector2.New(x, y)
                        ---@type number[]
                        local tMonsterList = utilData:FindEntityByPosAndType(v2, EnumTargetEntity.Monster)
                        if self._world:MatchType() == MatchType.MT_BlackFist then
                            local eTeam = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                            if eTeam:GetGridPosition() == v2 then
                                tMonsterList = {eTeam:GetID()}
                            end
                        end
                        for _, eid in ipairs(tMonsterList) do
                            -- targetIDs去重
                            if not table.icontains(result.targetIDs, eid) then
                                table.insert(result.targetIDs, eid)
                            end

                            if eid == greatestHPValEntityID then
                                result.greatestHPValEntityCount = result.greatestHPValEntityCount + 1
                            else
                                result.otherMonsterEntityCount = result.otherMonsterEntityCount + 1
                            end
                        end
                    end
                end
                table.insert(testResult, result)
            end
        end
    end

    table.sort(testResult, function (a, b)
        -- 排序规则：尽最大可能选中【绝对生命值最大的单位】的格子
        if a.greatestHPValEntityCount ~= b.greatestHPValEntityCount then
            return a.greatestHPValEntityCount > b.greatestHPValEntityCount
        else
            -- 在保证尽最大可能选中主要目标的基础上，圈到其他单位的数量越多越好
            if a.otherMonsterEntityCount ~= b.otherMonsterEntityCount then
                return a.otherMonsterEntityCount > b.otherMonsterEntityCount
            else
                return a.index < b.index
            end
        end
    end)

    local finalResult = testResult[1]
    local pickPosA = Vector2.New(finalResult.x1, finalResult.y1)
    local pickPosB = Vector2.New(finalResult.x2, finalResult.y2)

    -- 计算连线构成的矩形atkPosList
    local minX = math.min(pickPosA.x, pickPosB.x)
    local maxX = math.max(pickPosA.x, pickPosB.x)
    local minY = math.min(pickPosA.y, pickPosB.y)
    local maxY = math.max(pickPosA.y, pickPosB.y)
    for x = minX, maxX do
        for y = minY, maxY do
            local v2 = Vector2.New(x, y)
            if utilData:IsValidPiecePos(v2) then
                table.insert(atkPosList, v2)
            end
        end
    end

    return {pickPosA, pickPosB}, atkPosList, finalResult.targetIDs, extraParam
end