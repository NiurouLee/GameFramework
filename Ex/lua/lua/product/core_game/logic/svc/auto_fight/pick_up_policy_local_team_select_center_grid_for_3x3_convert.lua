require("pick_up_policy_base")

---@class PickUpPolicyParam_LocalTeamSelectCenterGridFor3x3Convert
---@field targetPieceType number
---@field targetCount number

_class("PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert", PickUpPolicy_Base)
---@class PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert: PickUpPolicy_Base
PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert = PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert:CalcAutoFightPickUpPolicy(calcParam)
    ---@type PickUpPolicyParam_LocalTeamSelectCenterGridFor3x3Convert
    local policyParam = calcParam.policyParam
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local boardMax = math.max(utilData:GetCurBoardMaxX(), utilData:GetCurBoardMaxY())

    local targetPieceType = policyParam.targetPieceType
    local targetCount = policyParam.targetCount

    ---@type Entity
    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    local teamPos = eLocalTeam:GetGridPosition()

    local pickUpValidList = self:BuildValidPickUpList(calcParam)
    if table.Vector2Include(pickUpValidList, teamPos) then
        local isValid, grids = self:_IsPosQualified(teamPos, targetPieceType, targetCount)
        if isValid then
            return {teamPos}, grids, {}
        end
    end

    local yieldIndicator = 1
    for ring = 1, boardMax do
        if yieldIndicator % 5 == 0 then
            YIELD(calcParam.TT)
        end
        local range = ComputeScopeRange.ComputeRange_SquareRing(teamPos, #(eLocalTeam:BodyArea():GetArea()), ring, true)
        for _, v2 in ipairs(range) do
            local isValid, grids = self:_IsPosQualified(v2, targetPieceType, targetCount)
            if isValid then
                return {v2}, grids, {}
            end
            yieldIndicator = yieldIndicator + 1
        end
    end

    return {}, {}, {}
end

--    local activeSkillID = calcParam.activeSkillID

---@param calcParam PickUpPolicy_CalcParam
---@return Vector2[]
function PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert:BuildValidPickUpList(calcParam)
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

---@return boolean, Vector2[]
function PickUpPolicy_LocalTeamSelectCenterGridFor3x3Convert:_IsPosQualified(v2, targetPieceType, targetCount)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local count = 0
    local convertGrids = {}

    for x = v2.x - 1, v2.x + 1 do
        for y = v2.y - 1, v2.y + 1 do
            local v = Vector2.New(x, y)
            local pieceType = utilData:GetPieceType(v)
            local isPieceTypeQualified = (pieceType) and (pieceType ~= targetPieceType) and (pieceType ~= PieceType.Any)
            local isPosBlockConvert = utilData:IsPosBlock(v, BlockFlag.ChangeElement)
            if isPieceTypeQualified and (not isPosBlockConvert) then
                count = count + 1
                table.insert(convertGrids, v)
            end
        end
    end

    return count >= targetCount, convertGrids
end
