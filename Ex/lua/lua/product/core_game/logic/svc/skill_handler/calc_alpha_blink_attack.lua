--[[
    AlphaBlinkAttack = 154, --阿尔法主动技2：阿尔法闪现攻击光灵然后瞬移后撤骑乘到机关上
]]
---@class SkillEffectCalc_AlphaBlinkAttack : Object
_class("SkillEffectCalc_AlphaBlinkAttack", Object)
SkillEffectCalc_AlphaBlinkAttack = SkillEffectCalc_AlphaBlinkAttack

function SkillEffectCalc_AlphaBlinkAttack:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type RideServiceLogic
    self._rideSvc = self._world:GetService("RideLogic")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AlphaBlinkAttack:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterPos = casterEntity:GetGridPosition()

    ---@type SkillEffectAlphaBlinkAttackParam
    local effectParam = skillEffectCalcParam.skillEffectParam
    local backOffset = effectParam:GetBackOffset()
    local trapID = effectParam:GetTrapID()
    local height = effectParam:GetTrapHeight()

    --计算机关召唤位置
    local attackPos, teleportPos = self:CalcPos(casterEntity, backOffset, trapID)
    if not attackPos or not teleportPos then
        return
    end

    --召唤
    local summonPosList = self:CalcSummonTrap(trapID, attackPos, teleportPos)

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local centerPos = teamEntity:GetGridPosition()
    local attackDir = centerPos - attackPos

    local result = SkillEffectAlphaBlinkAttackResult:New(casterPos, attackPos, attackDir, teleportPos, height, trapID, summonPosList)
    return result
end

---@param casterEntity Entity
---@param backOffset number
---@param trapID number
function SkillEffectCalc_AlphaBlinkAttack:CalcPos(casterEntity, backOffset, trapID)
    local casterPos = casterEntity:GetGridPosition()

    --计算闪现及最终瞬移位置
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local centerPos = teamEntity:GetGridPosition()
    local bodyArea = teamEntity:BodyArea():GetArea()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalc = utilScopeSvc:GetSkillScopeCalc()
    ---@type SkillScopeResult
    local scopeRes = skillCalc:ComputeScopeRange(
        SkillScopeType.CrossABackBNearCaster,
        { backOffset, trapID },
        centerPos,
        bodyArea,
        nil,
        nil,
        casterPos)
    local posList = scopeRes:GetAttackRange()
    if #posList < 2 then
        return
    end

    return posList[1], posList[2]
end

---@param trapID number
---@param attackPos Vector2
---@param teleportPos Vector2
---@return Vector2[]
function SkillEffectCalc_AlphaBlinkAttack:CalcSummonTrap(trapID, attackPos, teleportPos)
    local summonPosList = {}
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    if not utilScopeSvc:IsPosHasTrapByTrapID(attackPos, trapID) then
        table.insert(summonPosList, attackPos)
    end

    if not utilScopeSvc:IsPosHasTrapByTrapID(teleportPos, trapID) then
        table.insert(summonPosList, teleportPos)
    end

    return summonPosList
end
