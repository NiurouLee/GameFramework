--[[
    TrapMoveAndDamage = 194, --N26Boss：子弹机关移动，移动中撞到玩家后爆炸
]]
---@class SkillEffectCalc_TrapMoveAndDamage: Object
_class("SkillEffectCalc_TrapMoveAndDamage", Object)
SkillEffectCalc_TrapMoveAndDamage = SkillEffectCalc_TrapMoveAndDamage

function SkillEffectCalc_TrapMoveAndDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TrapMoveAndDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)
    local casterPos = casterEntity:GetGridPosition()
    local casterDir = casterEntity:GetGridDirection()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type SkillEffectTrapMoveAndDamageParam
    local effectParam = skillEffectCalcParam.skillEffectParam
    local mobility = effectParam:GetMobility()

    ---若幻境强制结束，则一次性释放剩余回合所需要行动的步数
    ---@type MirageServiceLogic
    local mirageSvc = self._world:GetService("MirageLogic")
    ---@type MirageComponent
    local mirageCmpt = mirageSvc:GetMirageComponent()
    if mirageCmpt:IsMirageForceClose() then
        local count = mirageCmpt:GetRemainRoundCount()
        if count > 0 then
            mobility = mobility * count
        end
    end

    local isHitPlayer = false
    local isOut = false
    local newPos = Vector2.zero
    local movePath = {}
    for i = 1, mobility do
        newPos = casterPos + casterDir * i
        if newPos == teamPos then
            isHitPlayer = true
            table.insert(movePath, newPos)
            break
        elseif not utilDataSvc:IsValidPiecePos(newPos) then
            --移出版边
            isOut = true
            break
        end
        table.insert(movePath, newPos)
    end

    ---位移
    local walkResultList = self:DoWalk(casterEntity, movePath)

    ---计算伤害
    local damageResult = nil
    if isHitPlayer then
        damageResult = self:CalcDamageResult(skillEffectCalcParam)
    end

    local result = SkillEffectTrapMoveAndDamageResult:New(casterEntityID, walkResultList, damageResult, isOut)

    return { result }
end

function SkillEffectCalc_TrapMoveAndDamage:DoWalk(casterEntity, movePath)
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    ---@type MonsterWalkResult[]
    local posWalkResultList = {}

    if #movePath ~= 0 then
        for _, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MonsterWalkResult
            local walkRes = MonsterWalkResult:New()

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, pos)
            casterEntity:SetGridPosition(pos)
            casterEntity:SetGridDirection(pos - posSelf)

            walkRes:SetWalkPos(pos)
            table.insert(posWalkResultList, walkRes)
        end
    end
    return posWalkResultList
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TrapMoveAndDamage:CalcDamageResult(skillEffectCalcParam)
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterEntityID)

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    local damageResult = nil
    local nTotalDamage, listDamageInfo = self._skillEffectService:ComputeSkillDamage(
        casterEntity,
        teamPos,
        teamEntity,
        teamPos,
        skillEffectCalcParam:GetSkillID(),
        skillEffectCalcParam:GetSkillEffectParam(),
        SkillEffectType.TrapMoveAndDamage,
        1
    )

    damageResult = self._skillEffectService:NewSkillDamageEffectResult(
        teamPos,
        teamEntity:GetID(),
        nTotalDamage,
        listDamageInfo
    )

    return damageResult
end
