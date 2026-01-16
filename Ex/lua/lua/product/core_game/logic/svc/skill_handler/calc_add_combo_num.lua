--[[
    AddComboNum = 93, ---增加连线普攻combo数
]]
require("calc_base")

---@class SkillEffectCalc_AddComboNum: SkillEffectCalc_Base
_class("SkillEffectCalc_AddComboNum", SkillEffectCalc_Base)
SkillEffectCalc_AddComboNum = SkillEffectCalc_AddComboNum

function SkillEffectCalc_AddComboNum:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddComboNum:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillAddComboNumEffectParam
    local skillEffectParam = skillEffectCalcParam.skillEffectParam

    local battleSvc = self._world:GetService("Battle")
    ---计算完伤害，就可以累加一次combo数
    local curComboNum = battleSvc:GetLogicComboNum()
    curComboNum = curComboNum + 1
    battleSvc:SetLogicComboNum(curComboNum)
    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    --combo数就是普攻数
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    battleStatComponent:SetOneChainMaxNormalAttack(teamEntity,curComboNum)

    return SkillAddComboNumEffectResult:New()
end
