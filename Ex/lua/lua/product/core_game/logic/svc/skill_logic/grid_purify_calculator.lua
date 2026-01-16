_class("GridPurifyCalculator", Object)
---@class GridPurifyCalculator
GridPurifyCalculator = GridPurifyCalculator

---@param world MainWorld
function GridPurifyCalculator:Constructor(world)
    self._world = world
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_GridPurify
function GridPurifyCalculator:Calculate(casterEntity, effectParam)
    ---@type SkillEffectResultContainer
    local container = casterEntity:SkillContext():GetResultContainer()

    ---@type SkillScopeResult
    local scopeResult = container:GetScopeResult()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---查看该技能效果是否有自己的范围和目标类型
    ---@type SkillScopeType
    local scopeType = effectParam:GetSkillEffectScopeType()
    if scopeType ~= nil then
        local casterPos = casterEntity:GetGridPosition()

        scopeResult = utilScopeSvc:CalcSkillEffectScopeResult(
            effectParam, casterPos, casterEntity
        )
    end

    ---@type UtilDataServiceShare
    local udsvc = self._world:GetService("UtilData")
    ---@type TrapServiceLogic
    local ltsvc = self._world:GetService("TrapLogic")

    local tv2Candidate = {}

    for _, v2GridPos in ipairs(scopeResult:GetAttackRange()) do
        table.insert(tv2Candidate, v2GridPos)
    end

    if #tv2Candidate == 0 then
        return
    end

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")

    local purifyRate = effectParam:GetPurifyRate()
    local purifyMax = math.ceil(#tv2Candidate * purifyRate)

    -- 这个table用来做召唤机关的判断，后面的逻辑会修改它
    local purifyRange = {}
    for purifyIndex = 1, purifyMax do
        if #tv2Candidate == 0 then
            break
        end

        local random = randomSvc:LogicRand(1, #tv2Candidate)
        local v2GridPos = table.remove(tv2Candidate, random)
        table.insert(purifyRange, v2GridPos)

        local array = udsvc:GetTrapsAtPos(v2GridPos)
        local trapIDArray = {}
        for _, eTrap in ipairs(array) do
            local cTrap = eTrap:Trap()
            if cTrap and (not eTrap:HasDeadMark()) and cTrap:CanBePurified() then
                ---@type TrapComponent
                local trapCmpt = eTrap:Trap()
                eTrap:Attributes():Modify("HP", 0)
                -- 如果真的是多格机关，只要在一个格子上判定死亡，就不再计入死亡列表
                -- 所以即使trapLogicService:AddTrapDeadMark(...)内部判断了，这里也同样要判断一次
                if not eTrap:HasDeadMark() then
                    ltsvc:AddTrapDeadMark(eTrap, true) -- 被净化的机关直接蒸发，不处理死亡技
                    table.insert(trapIDArray, eTrap:GetID())
                end
            end
        end

        container:AddEffectResult(SkillEffectResult_GridPurify:New(v2GridPos, trapIDArray))
    end

    if (not effectParam:GetTrapID()) then
        return
    end

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")

    local trapMax = effectParam:GetTrapMax() or #purifyRange
    for trapIndex = 1, trapMax do
        local v2GridPos
        while (#purifyRange > 0) do
            local random = randomSvc:LogicRand(1, #purifyRange)
            local v2 = table.remove(purifyRange, random)
            if trapSvc:CanSummonTrapOnPos(v2, effectParam:GetTrapID()) then
                v2GridPos = v2
                break
            end
        end

        -- 到这里还没有v2GridPos说明已经没有有效位置了
        if not v2GridPos then
            break
        end

        local eTrap = trapSvc:CreateTrap(effectParam:GetTrapID(), v2GridPos, Vector2.up, true, nil, casterEntity)
        if eTrap then
            local trapResult = SkillSummonTrapEffectResult:New(effectParam:GetTrapID(), v2GridPos)
            trapResult:SetTrapIDList({eTrap:GetID()})
            container:AddEffectResult(trapResult)
        end
    end
end
