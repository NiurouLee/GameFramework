require("pick_up_policy_base")

_class("PickUpPolicy_PetGiles", PickUpPolicy_Base)
---@class PickUpPolicy_PetGiles: PickUpPolicy_Base
PickUpPolicy_PetGiles = PickUpPolicy_PetGiles

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetGiles:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    --结果
    --local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetGiles(petEntity, activeSkillID, casterPos)
    return pickPosList, atkPosList, targetIds, extraParam
end
--贾尔斯：选择全场绝对血量最低的怪物攻击，在能攻击到的前提下优先选玩家所在的格子施放。
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function PickUpPolicy_PetGiles:_CalPickPosPolicy_PetGiles(petEntity, activeSkillID, casterPos)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local minHp = 1
    local targetEntity = nil
    for i, e in ipairs(group:GetEntities()) do
        if not e:HasDeadMark() then
            local hp = e:Attributes():GetCurrentHP()
            if not targetEntity or hp < minHp then
                minHp = hp
                targetEntity = e
            end
        end
    end

    if self._world:MatchType() == MatchType.MT_BlackFist then
        targetEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
    end

    if not targetEntity then
        return {}, {}, {}
    end

    -- local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}

    local pickPos = nil

    --先在身形的周围找是否有玩家坐标
    local targetGridPos = targetEntity:GridLocation():GetGridPos()
    local bodyArea = targetEntity:BodyArea():GetArea()
    local dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)}
    for _, value in ipairs(bodyArea) do
        local workPos = targetGridPos + value
        for _, dir in ipairs(dirs) do
            local targetPos = workPos + dir
            if targetPos == casterPos then
                pickPos = targetPos
                -- table.insert(pickPosList, workPos)
                break
            end
        end

        if pickPos then
            break
        end
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()
    --周围没有玩家，随便一个点
    if not pickPos then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        for _, dir in ipairs(dirs) do
            local targetPos = targetGridPos + dir
            if utilDataSvc:IsValidPiecePos(targetPos) then
                if not self:_IsPosInExtraBoard(targetPos,extraBoardPosRange) then
                    pickPos = targetPos
                    break
                end
            end
        end
    end

    retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pickPos)

    return {pickPos}, retScopeResult:GetAttackRange(), retTargetIds
end