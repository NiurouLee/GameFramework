require("Vector2")
require("pick_up_policy_base")

---@class PickUpPolicyParam_LocalTeamSelectCornerGridsFor3x3Convert
---@field targetPieceType number
---@field targetCount number

_class("PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert", PickUpPolicy_Base)
---@class PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert: PickUpPolicy_Base
PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert = PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert

local relativeCandidates = {
    Vector2.New(-2,  2),
    Vector2.New( 2,  2),
    Vector2.New(-2, -2),
    Vector2.New( 2, -2)
}

local relativeBackupCandidates = {
    Vector2.New(-3,  3),
    Vector2.New( 3,  3),
    Vector2.New(-3, -3),
    Vector2.New( 3, -3)
}

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert:CalcAutoFightPickUpPolicy(calcParam)
    ---@type PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert
    local policyParam = calcParam.policyParam
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local teamPos = eLocalTeam:GetGridPosition()

    local targetPieceType = policyParam.targetPieceType
    local targetCount = policyParam.targetCount

    local pickUpValidList = self:BuildValidPickUpList(calcParam)

    local candidates = {}
    for _, v in ipairs(relativeCandidates) do
        local v2 = teamPos + v
        local isValidPickUp = table.Vector2Include(pickUpValidList, v2)
        local isQualified, convertGrids = self:_IsPosQualified(v2, teamPos, targetPieceType, targetCount)
        if isValidPickUp and isQualified then
            table.insert(candidates, {pos =v2, convertGrids = convertGrids})
        end
    end

    YIELD(calcParam.TT)

    if #candidates == 1 then
        return { teamPos, candidates[1].pos }, candidates[1].convertGrids, {}
    elseif #candidates > 0 then
        local luckyNum = math.random(1, #candidates)
        return { teamPos, candidates[luckyNum].pos }, candidates[luckyNum].convertGrids, {}
    end

    local backupCandidates = {}
    for _, v in ipairs(relativeBackupCandidates) do
        local v2 = teamPos + v
        local isValidPickUp = table.Vector2Include(pickUpValidList, v2)
        local isQualified, convertGrids = self:_IsPosQualified(v2, teamPos, targetPieceType, targetCount)
        if isValidPickUp then
            table.insert(backupCandidates, {pos =v2, convertGrids = convertGrids, sort = #backupCandidates})
        end
    end

    YIELD(calcParam.TT)

    table.sort(backupCandidates, function (a, b)
        if #(a.convertGrids) ~= #(b.convertGrids) then
            return #(a.convertGrids) > #(b.convertGrids)
        end

        return a.sort < b.sort
    end)

    if #(backupCandidates[1].convertGrids) == 0 then
        return {}, {}, {}
    end

    YIELD(calcParam.TT)

    local maxConvertCount = #(backupCandidates[1].convertGrids)
    local maxConvertBackup = {}
    for _, t in ipairs(backupCandidates) do
        local count = #(t.convertGrids)
        if count == maxConvertCount and count ~= 0 then
            table.insert(maxConvertBackup, t)
        else
            break
        end
    end

    if #maxConvertBackup == 1 then
        return { teamPos, maxConvertBackup[1].pos }, maxConvertBackup[1].convertGrids, {}
    elseif #maxConvertBackup > 0 then
        local luckyNum = math.random(1, #maxConvertBackup)
        return { teamPos, maxConvertBackup[luckyNum].pos }, maxConvertBackup[luckyNum].convertGrids, {}
    end

    --道理上这个是走不到的
    return {}, {}, {}
end

---@return boolean, Vector2[]
function PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert:_IsPosQualified(v2, teamPos, targetPieceType, targetCount)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local count = 0
    local convertGrids = {}

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)

    local rectInDoublePickCalc = SkillScopeCalculator_RectInDoublePick:New(scopeCalc)
    ---@type SkillScopeResult
    local scopeResult = rectInDoublePickCalc:CalcRange(
            SkillScopeType.RectInDoublePick,
            nil,
            {teamPos, v2}
    )

    local attackRange = scopeResult:GetAttackRange()

    for _, v in ipairs(attackRange) do
        local pieceType = utilData:GetPieceType(v)
        local isPieceTypeQualified = (pieceType) and (pieceType ~= targetPieceType) and (pieceType ~= PieceType.Any)
        local isPosBlockConvert = utilData:IsPosBlock(v, BlockFlag.ChangeElement)
        if isPieceTypeQualified and (not isPosBlockConvert) then
            count = count + 1
            table.insert(convertGrids, v)
        end
    end

    return count >= targetCount, convertGrids
end

---@param calcParam PickUpPolicy_CalcParam
---@return Vector2[]
function PickUpPolicy_LocalTeamSelectCornerGridsFor3x3Convert:BuildValidPickUpList(calcParam)
    local activeSkillID = calcParam.activeSkillID
    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local validScopeList = skillConfigData:GetPickUpValidScopeConfig()
    local invalidScopeList = skillConfigData:GetPickUpInvalidScopeConfig()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2[]
    local validGridList = utilScopeSvc:BuildScopeGridList(validScopeList, eLocalTeam) or {}
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(invalidScopeList, eLocalTeam) or {}

    local ret = {}
    for _, v in ipairs(validGridList) do
        if (not table.Vector2Include(ret, v)) and (not table.Vector2Include(invalidGridList, v)) then
            table.insert(ret, v)
        end
    end

    return ret
end
