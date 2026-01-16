require("calc_base")

_class("SkillEffectCalc_LevelTrapUpLevel", SkillEffectCalc_Base)
---@class SkillEffectCalc_LevelTrapUpLevel : SkillEffectCalc_Base
SkillEffectCalc_LevelTrapUpLevel = SkillEffectCalc_LevelTrapUpLevel

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_LevelTrapUpLevel:DoSkillEffectCalculator(skillEffectCalcParam)
    
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    local results = {}
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end
    return results
end
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_LevelTrapUpLevel:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    local tarTrap = self._world:GetEntityByID(targetID)
    if not tarTrap then
        return
    end
    if not tarTrap:HasTrap() then
        return
    end
    ---@type SkillEffectParamLevelTrapUpLevel
    local param = skillEffectCalcParam:GetSkillEffectParam()
    if param then
        local centerPos = skillEffectCalcParam.skillRange[1]
        local checkTrapIDs = param:GetCheckTrapIDs()
        local checkTraps = {tarTrap}
        if #checkTraps > 0 then
            --升级
            local tarLevel = 1
            local desTrapLevel = 1
            local desTrap = checkTraps[1]
            if desTrap then
                local desTrapID = desTrap:Trap():GetTrapID()
                desTrapLevel = param:GetTrapModelLevel(desTrapID)
                -- ---@type AttributesComponent
                -- local attr = desTrap:Attributes()
                -- if attr then
                --     desTrapLevel = attr:GetAttribute("ModelLevel")
                -- end
            end
            tarLevel = desTrapLevel + 1
            local tarTrapID = 0
            local isTarTrapMaxLevel = false
            local modelLevelDic = param:GetModelLevels()
            if modelLevelDic then
                tarTrapID = modelLevelDic[tarLevel] or modelLevelDic[#modelLevelDic]
                if tarLevel >= #modelLevelDic then
                    isTarTrapMaxLevel = true
                end
            end
            if tarTrapID and tarTrapID > 0 then
                local summonList = {}
                local destroyList = {}
                local summonTrapResult = SkillSummonTrapEffectResult:New(
                    tarTrapID,
                    desTrap:GetGridPosition(),
                    param:IsTransferDisabled(),
                    param:GetSkillEffectDamageStageIndex()
                )
                table.insert(summonList,summonTrapResult)

                local desTrapEntityID = desTrap:GetID()
                local cTrap = desTrap:Trap()
                local desTrapID = cTrap:GetTrapID()
                local destroyTrapResult = SkillEffectDestroyTrapResult:New(
                    desTrapEntityID,
                    desTrapID
            )
                table.insert(destroyList,destroyTrapResult)
                return SkillEffectResultTrapUpLevel:New(
                    summonList,
                    destroyList,
                    isTarTrapMaxLevel
                )
            end
        else
        end
    end
end