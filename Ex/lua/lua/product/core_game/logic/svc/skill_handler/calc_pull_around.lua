--[[
    PullAround = 13, --拉到周围
]]
---@class SkillEffectCalc_PullAround: Object
_class("SkillEffectCalc_PullAround", Object)
SkillEffectCalc_PullAround = SkillEffectCalc_PullAround

function SkillEffectCalc_PullAround:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PullAround:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        table.insert(results, self:_CalculateSingleTarget(skillEffectCalcParam, targetID))
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_PullAround:_CalculateSingleTarget(skillEffectCalcParam, targetEntityID)
    ---@type SkillPullAroundEffectParam
    local skillPullAroundEffectParam = skillEffectCalcParam.skillEffectParam

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    ---拉到身边的技能效果目前只有boss需要 目标只有一个 体型为1 场景内没有会在拉取中阻挡的障碍物 其他情况需要扩展

    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local attackerPos = attacker:GridLocation().Position
    local attackerBodyArea = attacker:BodyArea()
    ---@type Entity
    local defender = self._world:GetEntityByID(targetEntityID)
    local defenderPos = defender:GridLocation().Position
    local defenderBodyArea = defender:BodyArea()

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    if not buffLogicService:CheckCanBePullAround(defender) then
        return
    end

    local utilCalcSvc = self._world:GetService("UtilCalc")
    local dir =
        utilCalcSvc:_CalcHitBackDir(
        HitBackDirectionType.EightDir,
        attackerPos,
        defenderPos,
        attackerBodyArea,
        defenderBodyArea
    )

    ---@type Vector2[]
    local atkBodyAreaVec = attackerBodyArea:GetArea()

    local targetPos = defenderPos:Clone()
    if dir.x < 0 then
        targetPos.x = BodyAreaHelper.GetBodyAreaLeft(atkBodyAreaVec) + attackerPos.x - 1
    elseif dir.x > 0 then
        targetPos.x = BodyAreaHelper.GetBodyAreaRight(atkBodyAreaVec) + attackerPos.x + 1
    end

    if dir.y < 0 then
        targetPos.y = BodyAreaHelper.GetBodyAreaDown(atkBodyAreaVec) + attackerPos.y - 1
    elseif dir.y > 0 then
        targetPos.y = BodyAreaHelper.GetBodyAreaUp(atkBodyAreaVec) + attackerPos.y + 1
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    if
        (not utilData:IsValidPiecePos(targetPos)) or
        boardServiceLogic:IsPosBlock(targetPos, BlockFlag.Skill | BlockFlag.SkillSkip)
     then
        targetPos = defenderPos
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    local pieceChangeTable = {}
    if defenderPos ~= targetPos then
        if utilData:FindPieceElement(defenderPos) == PieceType.None then
            ---返回结构 list{x = x, y = y, color = PieceType.None, connect = 0}
            local supplyRes = boardServiceLogic:SupplyPieceList({defenderPos})
            for i = 1, #supplyRes do
                local res = supplyRes[i]
                pieceChangeTable[Vector2(res.x, res.y)] = res.color
            end
        end
    end

    return SkillPullAroundEffectResult:New(targetEntityID, targetPos, pieceChangeTable)
end
