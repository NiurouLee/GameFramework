require("base_ins_r")

---作用同DataSelectScopeGridRangeInstruction
---不同点是：使用结果数组中的Index去选取结果，而非DamageInfoIndex
---@class DataSelectScopeGridRangeByResultIndexInstruction: BaseInstruction
_class("DataSelectScopeGridRangeByResultIndexInstruction", BaseInstruction)
DataSelectScopeGridRangeByResultIndexInstruction = DataSelectScopeGridRangeByResultIndexInstruction

function DataSelectScopeGridRangeByResultIndexInstruction:Constructor(paramList)
    if paramList["effectType"] then
        self._effectType = tonumber(paramList["effectType"])
    end
    if paramList["index"] then
        self._index = tonumber(paramList["index"])
    end

    self._noPhaseEnd = paramList["noPhaseEnd"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectScopeGridRangeByResultIndexInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --获取效果结果
    local resultArray = nil
    if self._effectType then
        local result = skillEffectResultContainer:GetEffectResultByArray(self._effectType, self._index)
        if result then
            resultArray = {}
            table.insert(resultArray, result)
        end
    else
        resultArray = {}
        local resultDic = skillEffectResultContainer:GetEffectResultDict()
        for _, v in pairs(resultDic) do
            local arr = v.array
            for i = 1, #arr do
                table.insert(resultArray, arr[i])
            end
        end
    end
    --效果不存在则结束phase
    if resultArray == nil or table.count(resultArray) <= 0 then
        return (not self._noPhaseEnd) and InstructionConst.PhaseEnd or nil
    end
    --获取效果的范围
    local gridList = {}
    local specialScopeResultList = {}
    for _, result in pairs(resultArray) do
        local scopeResult = result:GetSkillEffectScopeResult()
        if scopeResult then
            local array = scopeResult:GetAttackRange()
            for _, v in pairs(array) do
                if not self:_IsContainPos(gridList, v) then
                    table.insert(gridList, v)
                end
            end
        end

        if result.GetSpecialScopeResultList then
            -- local specialScopeResult = scopeResult:GetSpecialScopeResult()
            --不再使用范围计算的范围结果。因为技能效果里会根据是否MISS重新计算范围，所以特殊范围存在了技能结果里
            local specialScopeResult = result:GetSpecialScopeResultList()
            if
                specialScopeResult and table.count(specialScopeResult) > 0 and
                not table.icontains(specialScopeResultList, specialScopeResult[1])
            then
                table.appendArray(specialScopeResultList, specialScopeResult)
            end
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

function DataSelectScopeGridRangeByResultIndexInstruction:_IsContainPos(posArr, pos)
    for _, p in pairs(posArr) do
        if pos.x == p.x and pos.y == p.y then
            return true
        end
    end
    return false
end
