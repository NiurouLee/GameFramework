require("base_ins_r")
---@class DataSelectDamageScopeGridRangeInstruction: BaseInstruction
_class("DataSelectDamageScopeGridRangeInstruction", BaseInstruction)
DataSelectDamageScopeGridRangeInstruction = DataSelectDamageScopeGridRangeInstruction

function DataSelectDamageScopeGridRangeInstruction:Constructor(paramList)
    if paramList["damageInfoIndex"] then
        self._damageInfoIndex = tonumber(paramList["damageInfoIndex"])
    end

    self._noPhaseEnd = paramList["noPhaseEnd"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectDamageScopeGridRangeInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --获取效果结果
    local resultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, self._damageInfoIndex)

    --效果不存在则结束phase
    if resultArray == nil or table.count(resultArray) <= 0 then
        return (not self._noPhaseEnd) and InstructionConst.PhaseEnd or nil
    end
    --获取效果的范围
    local gridList = {}
    local specialScopeResultList = {}
    for _, result in pairs(resultArray) do
        -- local scopeResult = result:GetSkillEffectScopeResult()
        -- if scopeResult then
        --     local array = scopeResult:GetAttackRange()
        --     for _, v in pairs(array) do
        --         if not self:_IsContainPos(gridList, v) then
        --             table.insert(gridList, v)
        --         end
        --     end
        -- end
        ---@type SkillDamageEffectResult
        local damageResult = result
        local damagePos = damageResult:GetGridPos()

        if not self:_IsContainPos(gridList, damagePos) then
            table.insert(gridList, damagePos)
        end
    end
    if table.count(gridList) <= 0 then
        return (not self._noPhaseEnd) and InstructionConst.PhaseEnd or nil
    end
    --设置效果作用的范围
    phaseContext:SetScopeGridList(gridList)
    --将范围计算中特殊排序后的结果，传给表现，避免再算一次
    phaseContext:SetSpecialScopeResultList(specialScopeResultList)
end

function DataSelectDamageScopeGridRangeInstruction:_IsContainPos(posArr, pos)
    for _, p in pairs(posArr) do
        if pos.x == p.x and pos.y == p.y then
            return true
        end
    end
    return false
end
