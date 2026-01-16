--[[------------------------------------------------------------------------------------------
    GeneralEffectCalculator :通用子技能效果计算器
    针对子技能效果的计算，流程是
    1.获取子技能效果范围。可以是技能公共范围，也可能是子技能效果范围
    2.获取目标列表。有可能需要计算效果自身的目标列表
    3.对目标列表做排序
    4.使用逐目标计算器，对每个目标计算子技能效果

    默认使用当前skillroutine里的范围和目标数据，如果每个效果有自定义的范围与目标，就会新计算一个范围和目标
]] --------------------------------------------------------------------------------------------

---@class GeneralEffectCalculator: Object
_class("GeneralEffectCalculator", Object)
GeneralEffectCalculator = GeneralEffectCalculator

---@param world MainWorld
function GeneralEffectCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ForEachTargetCalculator
    self._foreachTargetCalculator = ForEachTargetCalculator:New(world)

    ---@type SkillEffectTargetSorter
    self._skillEffectTargetSorter = SkillEffectTargetSorter:New(world)
end

---@param casterEntity Entity 施法者
---@param skillEffectParam SkillEffectParamBase 技能效果配置参数
---@param scopeFilterParam SkillScopeFilterParam 技能范围过滤参数
function GeneralEffectCalculator:DoGeneralEffectCalc(casterEntity, skillEffectParam, scopeFilterParam)
    ---获取范围
    ---这个返回的范围计算结果，可能是公共的范围，也可能是技能效果自己的范围
    ---@type SkillScopeResult
    local skillScopeResult = self:_CalcSkillEffectScopeResult(casterEntity, skillEffectParam)
    ---获取目标列表
    ---这个目标列表，可能是公共的目标ID，也可能是技能效果自己的目标对象
    local targetIDList = self:_CalcSkillEffectTargetList(casterEntity, skillScopeResult, skillEffectParam)

    ---有可能需要根据效果执行一次排序
    targetIDList =
        self._skillEffectTargetSorter:DoSortTargetList(casterEntity, targetIDList, skillEffectParam, skillScopeResult)

    ---使用逐目标计算器，针对当前技能效果，计算出技能结果（是个列表）
    local resultList =
        self._foreachTargetCalculator:DoTargetEffectCalculate(
        casterEntity,
        skillScopeResult,
        targetIDList,
        skillEffectParam,
        scopeFilterParam
    )

    ---重置技能范围
    ----每个技能结果都有自己的范围，这样在表现的时候，才知道该表现的范围是什么
    for _, v in ipairs(resultList) do
        ---@type SkillEffectResultBase
        local skillResult = v
        skillResult:SetSkillEffectScopeResult(skillScopeResult)
    end

    ---todo:每个技能效果也可以有自己的目标ID列表

    return resultList
end

---计算技能子效果的范围，扩展支持了技能子效果可以有自己定义的范围
---@param casterEntity Entity 施法者
---@param skillEffectParam SkillEffectParamBase 技能效果配置参数
---@return SkillScopeResult 返回的是一个范围，默认返回技能公共范围
function GeneralEffectCalculator:_CalcSkillEffectScopeResult(casterEntity, skillEffectParam)
    ---取出默认的范围数据
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---这里只要判断有新的范围类型，就会重新计算目标，以后可以再优化
    ---查看该技能效果是否有自己的范围和目标类型
    ---@type SkillScopeType
    local scopeType = skillEffectParam:GetSkillEffectScopeType()
    if scopeType ~= nil then
        ---默认取的是施法者的位置，对于点选大招来说，需要考虑施法者位置在什么地方
        local casterPos = casterEntity:GridLocation().Position
        scopeResult = utilScopeSvc:CalcSkillEffectScopeResult(skillEffectParam, casterPos, casterEntity)
    end

    return scopeResult
end

---计算技能子效果的目标列表
---@param casterEntity Entity 施法者
---@param scopeResult SkillScopeResult 范围
---@param skillEffectParam SkillEffectParamBase 子效果配置参数
---@return Array 目标EntityID数组
function GeneralEffectCalculator:_CalcSkillEffectTargetList(casterEntity, scopeResult, skillEffectParam)
    ---取出默认的范围数据
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()

    local targetEntityIDArray = scopeResult:GetTargetIDs()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillScopeFilterParam
    local filterParam = skillEffectParam:GetScopeFilterParam()
    local targetSelectionMode = filterParam:GetTargetSelectionMode()

    ---取出技能自己的目标类型
    ---@type SkillTargetType
    local skillEffectTargetType = skillEffectParam:GetSkillEffectTargetType()
    if skillEffectTargetType ~= nil then
        ---如果技能效果的目标类型不为空，需要重新计算一次技能目标
        local skillEffectTargetTypeParam = skillEffectParam:GetSkillEffectTargetTypeParam()
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---只有计算技能的目标时传SkillID,计算技能效果的子范围不要穿SkillID
        targetEntityIDArray =
            utilScopeSvc:SelectSkillTarget(
            casterEntity,
            skillEffectTargetType,
            scopeResult,
            nil,
            skillEffectTargetTypeParam
        )

        local fitterTargetIDs = {}
        for _, id in ipairs(targetEntityIDArray) do
            if not table.icontains(fitterTargetIDs, id) then
                table.insert(fitterTargetIDs, id)
            end
        end

        targetEntityIDArray = fitterTargetIDs
    end

    return targetEntityIDArray
end
