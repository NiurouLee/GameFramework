_class("PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert", PickUpPolicy_Base)
---@class PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert: PickUpPolicy_Base
PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert = PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert:CalcAutoFightPickUpPolicy(calcParam)
    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local teamPos = eLocalTeam:GetGridPosition()

    ---@type Entity[]
    local monsterGlobalEntityGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        monsterGlobalEntityGroup = {self._world:Player():GetRemoteTeamEntity()}
    end

    local policyParam = calcParam.policyParam
    local targetPieceType = policyParam.targetPieceType
    local targetCount = policyParam.targetCount

    local validPickUpGridList, validPosIndexBoolDict = self:_GetValidPickUpGridList(eLocalTeam, calcParam.activeSkillID)

    local yieldIndicator = 1

    local singleGridSelectInfo = {}
    for _, e in ipairs(monsterGlobalEntityGroup) do
        if yieldIndicator % 5 == 0 then
            YIELD(calcParam.TT)
        end
        local gridPos = e:GetGridPosition()
        local bodyArea = e:BodyArea():GetArea()
        if #bodyArea <= 1 then
            local gridPosIndex = Vector2.Pos2Index(gridPos)
            if validPosIndexBoolDict[gridPosIndex] then
                local info = self:_TryGetSelectInfo(gridPos, teamPos, targetPieceType)
                if info then
                    info.sortIndex = #singleGridSelectInfo
                    table.insert(singleGridSelectInfo, info)
                end
            end
        end
        yieldIndicator = yieldIndicator + 1
    end

    if #singleGridSelectInfo > 0 then
        local singleGridMonsterInfo = self:_TryGetBestCandidate(singleGridSelectInfo)
        if singleGridMonsterInfo then
            return {singleGridMonsterInfo.selectPos}, singleGridMonsterInfo.convertGrids, {}
        end
    end

    --以上逻辑基本是SP白兰的，去掉了需求不需要的多格怪，下面是新的逻辑

    --对玩家所在位置进行计算：位置无法点选则不释放
    if not validPosIndexBoolDict[Vector2.Pos2Index(teamPos)] then
        return {}, {}, {}
    end

    --玩家位置无法转色或转色数量少于规定值时不释放
    local teamPosInfo = self:_TryGetSelectInfo(teamPos, teamPos, targetPieceType)
    if (not teamPosInfo) or #teamPosInfo.dontConvertGrids >= targetCount then
        return {}, {}, {}
    end

    return {teamPos}, teamPosInfo.convertGrids, {}
end

function PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert:_GetValidPickUpGridList(petEntity, skillID)
    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = cfgsvc:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type Vector2[]
    local validGirdList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    local invalidGridDict = {}
    for _, invalidPos in ipairs(invalidGridList) do
        invalidGridDict[Vector2.Pos2Index(invalidPos)] = true
    end

    local validPosIdxList = {}
    local validPosList = {}
    for _, validPos in ipairs(validGirdList) do
        local validPosIdx = Vector2.Pos2Index(validPos)
        if not invalidGridDict[validPosIdx] then
            validPosIdxList[validPosIdx] = true
            table.insert(validPosList, validPos)
        end
    end

    return validPosList, validPosIdxList
end

function PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert:_TryGetSelectInfo(gridPos, teamPos, targetPieceType)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeCalculator_Cross
    local crossCalc = SkillScopeCalculator_Cross:New(scopeCalc)

    local gridPosIndex = Vector2.Pos2Index(gridPos)
    -- scopeParam=1: 需求是固定选择怪物周围十字的格子
    ---@type SkillScopeResult
    local crossScope = crossCalc:CalcRange(SkillScopeType.Cross, 1, gridPos, {Vector2.zero})

    local convertGrids = {}
    local dontConvertGrids = {}
    for _, grid in ipairs(crossScope:GetAttackRange() or {}) do
        if self:_CanGridConvert(grid, targetPieceType) and (not table.Vector2Include(convertGrids, grid)) then
            table.insert(convertGrids, grid)
        else
            if not table.Vector2Include(dontConvertGrids, grid) then
                table.insert(dontConvertGrids, grid)
            end
        end
    end

    if #convertGrids > 0 then
        return {
            selectPos = gridPos,
            convertGrids = convertGrids,
            distance = Vector2.Distance(gridPos, teamPos),
            dontConvertGrids = dontConvertGrids
        }
    end
end

function PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert:_CanGridConvert(v2, targetPieceType)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(v2) then
        return false
    end
    if utilData:IsPosBlock(v2, BlockFlag.ChangeElement) then
        return false
    end

    local pieceType = utilData:GetPieceType(v2)
    if pieceType == targetPieceType or pieceType == PieceType.Any then
        return false
    end

    return true
end

function PickUpPolicy_LocalTeamSelectCenterGridFor1xCrossConvert:_TryGetBestCandidate(candidates)
    local bestCandidate = {}

    local maxConvertCount = #(candidates[1].convertGrids)
    local minDistance = candidates[1].distance

    for i = 2, #candidates do
        local info = candidates[i]

        --优先可转色数量更多
        if #(info.convertGrids) > maxConvertCount then
            maxConvertCount = #(info.convertGrids)
            bestCandidate = {info}
        elseif #(info.convertGrids) == maxConvertCount then
            --转色数量相同时，取距离最近
            if info.distance < minDistance then
                minDistance = info.distance
                bestCandidate = {info}
            end
        end
    end

    local winner

    if #bestCandidate == 1 then
        winner = bestCandidate[1]
    elseif #bestCandidate > 1 then
        local index = math.random(1, #bestCandidate)
        winner = bestCandidate[index]
    end

    return winner
end
