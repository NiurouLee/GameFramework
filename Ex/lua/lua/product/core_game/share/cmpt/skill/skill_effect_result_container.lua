_class("SkillEffectResultContainer", Object)
---@class SkillEffectResultContainer:Object
SkillEffectResultContainer = SkillEffectResultContainer

require("skill_effect_type")
---@class SkillEffectResultTypeOverride
SkillEffectResultTypeOverride = {
    [SkillEffectType.SummonMultipleTrap] = SkillEffectType.SummonTrap,
    [SkillEffectType.EnhanceOccupiedGrid] = SkillEffectType.SummonTrap
}
_enum("SkillEffectResultTypeOverride", SkillEffectResultTypeOverride)

function SkillEffectResultContainer:Constructor()
    --是不是最后一击
    self._isFinalAttack = false
    --触发最后一击的怪物ID
    self._finalAttackEntityID = nil

    --技能范围
    self._scopeResult = nil

    --技能结果列表
    self._effectResultDic = {}
    ---技能编号
    self.m_nSkillID = 0

    self._isNormalAttack = false
    ---用来标记是不是一个星灵在一个格子上的最后一次普通攻击
    self._isLastNormalAttackAtOneGrid = true
end

function SkillEffectResultContainer:Clear()
    --是不是最后一击
    self._isFinalAttack = false
    --触发最后一击的怪物ID
    self._finalAttackEntityID = nil

    --技能范围
    self._scopeResult = nil

    --技能结果列表
    self._effectResultDic = {}
    ---技能编号
    self.m_nSkillID = 0

    self._isNormalAttack = false
    ---用来标记是不是一个星灵在一个格子上的最后一次普通攻击
    self._isLastNormalAttackAtOneGrid = true
end

--增加一个技能范围
---@param result SkillScopeResult
function SkillEffectResultContainer:SetScopeResult(result)
    self._scopeResult = result
end

--根据索引获取范围
---@return SkillScopeResult
function SkillEffectResultContainer:GetScopeResult()
    return self._scopeResult
end

--增加一个技能效果
---@param result SkillEffectResultBase
function SkillEffectResultContainer:AddEffectResult(result, bReplace)
    if result == nil then
        Log.error("SkillEffectResultContainer:AddEffectResult result is nil")
        return
    end
    local effect_type = result:GetEffectType()
    if self._effectResultDic[effect_type] == nil then
        self._effectResultDic[effect_type] = {}
    end
    local results = self._effectResultDic[effect_type]
    if not results.array then
        results.array = {}
    end
    local bAddSuccess = false
    if bReplace then
        for k, v in ipairs(results.array) do
            if result:IsSame(v) then
                bAddSuccess = true
                results.array[k] = result
                break
            end
        end
    end
    if false == bAddSuccess then
        results.array[#results.array + 1] = result
    end

    if not results.pos then
        results.pos = {}
    end
    local posGrid = result:GetGridPos()
    if posGrid then
        results.pos[Vector2.Pos2Index(posGrid)] = result
    end

    if not results.target then
        results.target = {}
    end
    ---这个有个坑如果是多次伤害同一个目标的话 下面的数组只会存储最后一个
    if result:GetTargetID() then
        results.target[result:GetTargetID()] = result
    end

    --Log.debug("SkillEffectResultContainer:AddEffectResult() resultType=",result._className)
end

---@param type 技能效果类型
---@param index 数组索引
function SkillEffectResultContainer:GetEffectResultByArray(type, index)
    local res = self._effectResultDic[type]
    if res then
        if index == nil then
            index = 1
        end
        return res.array[index]
    end
end

---@param type 技能效果类型
---@param index 数组索引
function SkillEffectResultContainer:GetEffectResultByArrayAll(type)
    local res = self._effectResultDic[type]
    if res then
        return res.array
    end
end

---@param type 技能效果类型
---@param pos 格子坐标
function SkillEffectResultContainer:GetEffectResultByPos(type, pos)
    local res = self._effectResultDic[type]
    if nil == res then
        return nil
    end
    return res.pos[Vector2.Pos2Index(pos)]
end


---@param type 技能效果类型
---@param targetid 目标id
function SkillEffectResultContainer:GetEffectResultByTargetID(type, targetid)
    local res = self._effectResultDic[type]
    if res then
        return res.target[targetid]
    end
end

--根据类型获取全部结果
function SkillEffectResultContainer:GetEffectResultsAsPosDic(type)
    if not self._effectResultDic[type] then
        return
    end
    return self._effectResultDic[type].pos
end

function SkillEffectResultContainer:GetEffectResultsAsTargetIdDic(type)
    if not self._effectResultDic[type] then
        return
    end
    return self._effectResultDic[type].target
end

function SkillEffectResultContainer:GetEffectResultsAsArray(type, damageStageIndex)
    if not self._effectResultDic[type] then
        return
    end
    -- return self._effectResultDic[type].array
    local effectResultDic = self:_FilterByStage(self._effectResultDic[type].array, damageStageIndex)
    return effectResultDic
end

--用伤害阶段筛选
function SkillEffectResultContainer:_FilterByStage(damageResultArrayAllStage, damageStageIndex)
    if damageStageIndex then
        local effectResultDic = {}
        for _, damageResult in ipairs(damageResultArrayAllStage) do
            if damageResult:GetDamageStageIndex() == damageStageIndex then
                table.insert(effectResultDic, damageResult)
            end
        end
        return effectResultDic
    end
    return damageResultArrayAllStage
end

--获得技能阶段的数量
function SkillEffectResultContainer:GetEffectResultsStageCount(type)
    if not self._effectResultDic[type] then
        return
    end
    local stageCount = 0
    local effectResultDic = self._effectResultDic[type].array
    for _, effectResult in ipairs(effectResultDic) do
        local stageIndex = effectResult:GetDamageStageIndex()
        if stageIndex > stageCount then
            stageCount = stageIndex
        end
    end
    return stageCount
end

--获取整个结果dic
function SkillEffectResultContainer:GetEffectResultDict()
    return self._effectResultDic
end

function SkillEffectResultContainer:SetEffectResultDict(results)
    self._effectResultDic = results
end

function SkillEffectResultContainer:SetFinalAttack(isFinalAttack)
    -- Log.debug('IsFinalAttack=',isFinalAttack, Log.traceback())
    self._isFinalAttack = isFinalAttack
end

function SkillEffectResultContainer:SetFinalAttackEntityID(entityID)
    self._finalAttackEntityID = entityID
end

function SkillEffectResultContainer:GetFinalAttackEntityID()
    return self._finalAttackEntityID
end

function SkillEffectResultContainer:IsFinalAttack()
    return self._isFinalAttack
end

function SkillEffectResultContainer:IsFinalDamageResult(res)
    for i, r in ipairs(self._effectResultDic[SkillEffectType.Damage].array) do
        if r ~= res and not r:IsUsed() then
            return false
        end
    end
    return true
end

function SkillEffectResultContainer:SetSkillID(nSkillID)
    self.m_nSkillID = nSkillID
end

function SkillEffectResultContainer:GetSkillID()
    return self.m_nSkillID
end

function SkillEffectResultContainer:SetCurChainSkillIndex(idx)
    self._curChainSkillIndex = idx
end

function SkillEffectResultContainer:GetCurChainSkillIndex()
    return self._curChainSkillIndex
end

function SkillEffectResultContainer:SetNormalAttack(isNormalAttack)
    self._isNormalAttack = isNormalAttack
end

function SkillEffectResultContainer:IsNormalAttack()
    return self._isNormalAttack
end

function SkillEffectResultContainer:SetLastNormalAttackAtOnGrid(isLastNormalAttackAtOneGrid)
    self._isLastNormalAttackAtOneGrid = isLastNormalAttackAtOneGrid
end

function SkillEffectResultContainer:IsLastNormalAttackAtOnGrid()
    return self._isLastNormalAttackAtOneGrid
end

function SkillEffectResultContainer:GetEffectResultsByType(type)
    return self._effectResultDic[type]
end
function SkillEffectResultContainer:SetNormalAttackBeAttackOriPos(pos)
    self._normalAttackBeAttackOriPos = pos
end

function SkillEffectResultContainer:GetNormalAttackBeAttackOriPos()
    return self._normalAttackBeAttackOriPos
end
