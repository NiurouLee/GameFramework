--[[
    SummonOnFixPosLimit = 131, ---根据配置的X个固定点，依次召唤Y个机关；若场上机关大于上限Z，则销毁最先召唤的
]]
---@class SkillEffectCalc_SummonOnFixPosLimit: Object
_class("SkillEffectCalc_SummonOnFixPosLimit", Object)
SkillEffectCalc_SummonOnFixPosLimit = SkillEffectCalc_SummonOnFixPosLimit

function SkillEffectCalc_SummonOnFixPosLimit:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonOnFixPosLimit:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamSummonOnFixPosLimit
    local skillEffectParamSummon = skillEffectCalcParam.skillEffectParam
    local trapID = skillEffectParamSummon:GetTrapID()
    local limitCount = skillEffectParamSummon:GetLimitCount()
    local posList = skillEffectParamSummon:GetFixPosList()
    local summonCount = skillEffectParamSummon:GetSummonCount()

    local ignoreBlock = skillEffectParamSummon:IgnoreBlock()
    local blockFlag = BlockFlag.SummonTrap
    if ignoreBlock then
        blockFlag = 0
    end

    ---@type BattleFlagsComponent
    local battleFlags = self._world:BattleFlags()
    local summonIndex = battleFlags:GetSummonOnFixPosLimitIndex()

    --1 A个固定点，依次召唤B个干扰装置
    local index = 0
    local summonPosList = {}
    for i = 1, summonCount do
        index = math.fmod(summonIndex + i, #posList)
        if index == 0 then
            index = #posList
        end
        if table.count(summonPosList) <= limitCount then
            table.insert(summonPosList, posList[index])
        else
            --PrintLogBhv.
            Log.debug("")
        end
    end
    battleFlags:SetSummonOnFixPosLimitIndex(index)

    local result = SkillEffectResultSummonOnFixPosLimit:New(trapID, summonPosList)

    --2 超限，则删除之前的召唤机关
    local destroyEntityIDList = {}
    local entityIDList = battleFlags:GetSummonOnFixPosLimitEntityID(trapID)
    local meantimeCount = #summonPosList + #entityIDList

    local curIndex = 1
    while meantimeCount > limitCount do
        local curEntityID = entityIDList[curIndex]
        meantimeCount = meantimeCount - 1
        curIndex = curIndex + 1
        table.insert(destroyEntityIDList, curEntityID)
    end

    result:SetDestroyEntityIDList(destroyEntityIDList)

    return result
end
