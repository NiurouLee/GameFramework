--[[
   脱离 跟附身对应使用
]]
require("calc_base")

---@class SkillEffectCalcDetachMonster: SkillEffectCalc_Base
_class("SkillEffectCalcDetachMonster", SkillEffectCalc_Base)
SkillEffectCalcDetachMonster = SkillEffectCalcDetachMonster

function SkillEffectCalcDetachMonster:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcDetachMonster:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetID number
function SkillEffectCalcDetachMonster:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    ---@type SkillAbsorbPhantomParam
    local skillParam = skillEffectCalcParam:GetSkillEffectParam()
    local casterID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    ---@type AIComponentNew
    local aiComponent = casterEntity:AI()
    local attachMonsterID = aiComponent:GetRuntimeData("AttachMonsterID")
    ----@type Entity
    local attachMonsterEntity = self._world:GetEntityByID(attachMonsterID)
    local attachMonsterPos = attachMonsterEntity:GetGridPosition()
    casterEntity:SetGridPosition(attachMonsterPos)
    aiComponent:SetRuntimeData("AttachMonsterID", nil)
    aiComponent:SetRuntimeData("Target", nil)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()

    local round = battleStatCmpt:GetCurWaveTotalRoundCount()
    local curState = self._world:GameFSM():CurStateID()
    if curState == GameStateID.MonsterTurn then
        round = round + 1
    end
    aiComponent:SetRuntimeData("DetachBeginRunRound", round)

    return SkillEffectDetachMonsterResult:New(attachMonsterPos, attachMonsterID)
end
