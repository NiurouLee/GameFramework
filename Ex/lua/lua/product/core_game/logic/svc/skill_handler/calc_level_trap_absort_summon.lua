require("calc_base")

_class("SkillEffectCalc_LevelTrapAbsortSummon", SkillEffectCalc_Base)
---@class SkillEffectCalc_LevelTrapAbsortSummon : SkillEffectCalc_Base
SkillEffectCalc_LevelTrapAbsortSummon = SkillEffectCalc_LevelTrapAbsortSummon

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_LevelTrapAbsortSummon:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamLevelTrapAbsortSummon
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local checkTrapIDs = param:GetCheckTrapIDs()
    local range = skillEffectCalcParam.skillRange or {}
    local centerPos = skillEffectCalcParam:GetCenterPos()
    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local trapInRange = {}
    for _, pos in ipairs(range) do
        local array = utilSvc:GetTrapsAtPos(pos)
        for _, eTrap in ipairs(array) do
            if eTrap and not eTrap:HasDeadMark() then
                local isOwner = false
                if eTrap:HasSummoner() then
                    local summonEntityID = eTrap:Summoner():GetSummonerEntityID()
                    ---@type Entity
                    local summonEntity = eTrap:GetSummonerEntity()
                    --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
                    if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                        summonEntityID = summonEntity:GetSuperEntity():GetID()
                    end
                    if summonEntityID == casterEntityID then
                        isOwner = true
                    end
                else
                    isOwner = true
                end
                if isOwner and table.icontains(checkTrapIDs,eTrap:Trap():GetTrapID()) then
                    table.insert(trapInRange,eTrap)
                end
            end
        end
    end
    local tarLevel = 0
    if #trapInRange > 0 then
        for _,desTrap in ipairs(trapInRange) do
            local desTrapID = desTrap:Trap():GetTrapID()
            local desTrapLevel = param:GetTrapModelLevel(desTrapID)
            tarLevel = tarLevel + desTrapLevel
            -- ---@type AttributesComponent
            -- local attr = desTrap:Attributes()
            -- if attr then
            --     local desTrapLevel = attr:GetAttribute("ModelLevel") or 0
            --     tarLevel = tarLevel + desTrapLevel
            -- end
        end
    end
    if tarLevel == 0 then
        tarLevel = 1
    end
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
            centerPos,
            param:IsTransferDisabled(),
            param:GetSkillEffectDamageStageIndex()
        )
        table.insert(summonList,summonTrapResult)
        for _,desTrap in ipairs(trapInRange) do
            local desTrapEntityID = desTrap:GetID()
            local cTrap = desTrap:Trap()
            local desTrapID = cTrap:GetTrapID()
            local destroyTrapResult = SkillEffectDestroyTrapResult:New(
                desTrapEntityID,
                desTrapID
            )
            table.insert(destroyList,destroyTrapResult)
        end
        return SkillEffectResultLevelTrapAbsortSummon:New(
            summonList,
            destroyList,
            isTarTrapMaxLevel
        )
    end
end