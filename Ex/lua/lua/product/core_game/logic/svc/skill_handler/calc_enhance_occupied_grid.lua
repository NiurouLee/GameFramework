---@class SkillEffectCalc_EnhanceOccupiedGrid : SkillEffectCalc_Base
_class("SkillEffectCalc_EnhanceOccupiedGrid", SkillEffectCalc_Base)
SkillEffectCalc_EnhanceOccupiedGrid = SkillEffectCalc_EnhanceOccupiedGrid

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EnhanceOccupiedGrid:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.appendArray(results, result)
        end
    end

    return results
end

---@param calcParam SkillEffectCalcParam
function SkillEffectCalc_EnhanceOccupiedGrid:_CalculateSingleTarget(calcParam, nTargetID)
    local eTarget = self._world:GetEntityByID(nTargetID)
    if not eTarget then
        return {}
    end

    local boardCmpt = self._world:GetBoardEntity():Board()
    local v2PosTarget = eTarget:GetGridPosition()
    local cBodyArea = eTarget:BodyArea()
    local tv2RelativeBody
    if not cBodyArea then
        tv2RelativeBody = {Vector2.zero}
    else
        tv2RelativeBody = cBodyArea:GetArea()
    end

    local tv2AbsBody = {}
    for _, v2Relative in ipairs(tv2RelativeBody) do
        table.insert(tv2AbsBody, v2Relative + v2PosTarget)
    end

    local rangeMap = self:GetRangeMap(calcParam.skillRange)
    ---@param e Entity
    local filter=function(e)
        return e:HasTrap() and e:Trap():GetTrapLevel()==0 
    end
    local tv2Candidates = {}
    for _, v2Abs in ipairs(tv2AbsBody) do
        if rangeMap[v2Abs.x] and rangeMap[v2Abs.x][v2Abs.y] then
            local es = boardCmpt:GetPieceEntities(v2Abs, filter) --策划说0层机关上不能召唤其他机关
            if #es==0 then
                table.insert(tv2Candidates, v2Abs)
            end
        end
    end

    ---@type SkillEffectParamEnhanceOccupiedGrid
    local effectParam = calcParam.skillEffectParam

    local limit = effectParam:GetMaxCountPerTarget()
    local tv2FinalPos = {}

    if #tv2Candidates <= limit then
        -- 如果候选位置数量不超过上限，就直接全选
        tv2FinalPos = tv2Candidates
    else
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        while ((#tv2Candidates > 0) and (limit > 0)) do
            local max = #tv2Candidates
            local rand = randomSvc:LogicRand(1, max)
            local v2Selected = table.remove(tv2Candidates, rand)
            table.insert(tv2FinalPos, v2Selected)
            limit = limit - 1
        end
    end

    local tResults = {}

    if #tv2FinalPos == 0 then
        return tResults
    end

    for _, v2 in ipairs(tv2FinalPos) do
        local result = SkillSummonTrapEffectResult:New(effectParam:GetTrapID(), v2)
        table.insert(tResults, result)
    end

    return tResults
end

function SkillEffectCalc_EnhanceOccupiedGrid:GetRangeMap(skillRange)
    local t = {}
    for _, v2 in ipairs(skillRange) do
        local x = v2.x
        local y = v2.y
        if not t[x] then
            t[x] = {}
        end
        t[x][y] = true
    end

    return t
end