--[[
    ConvertOccupiedGridElement = 62, -- 对技能范围内的实体*脚下*的格子转色
]]
---@class SkillEffectCalc_ConvertOccupiedGridElement: SkillEffectCalc_Base
_class("SkillEffectCalc_ConvertOccupiedGridElement", SkillEffectCalc_Base)
SkillEffectCalc_ConvertOccupiedGridElement = SkillEffectCalc_ConvertOccupiedGridElement

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ConvertOccupiedGridElement:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ConvertOccupiedGridElement:_CalculateSingleTarget(skillEffectCalcParam, targetEntityId)
    ---@type SkillEffectConvertOccupiedGridElementParam
    local logicParam = skillEffectCalcParam.skillEffectParam

    local targetGridElement = logicParam:GetTargetGridElement()
    local priorityTarget = logicParam:GetPriorityTarget()

    ---@type Entity
    local victimEntity = self._world:GetEntityByID(targetEntityId)

    -- 技能没有找到目标时，仍然会尝试计算空结果用于表现
    -- 返回nil，表现阶段容错即可

    if not victimEntity then
        return
    end

    local gridArray = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local ePos = victimEntity:GridLocation().Position
    ---@type BodyAreaComponent
    local bodyAreaCmpt = victimEntity:BodyArea()
    local area = bodyAreaCmpt:GetArea()

    local nMaxConvertPerMonster = logicParam:GetMaxPosPerTarget() or #area

    local tPreselectPos = {}
    local priorityElementPosList = {}
    local lagElementPosList = {}

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    for i, p in ipairs(area) do
        local absolutePos = ePos + p
        if
            (not boardServiceLogic:IsPosBlock(absolutePos, BlockFlag.ChangeElement) and
                table.icontains(skillEffectCalcParam.skillRange, absolutePos) and
                boardServiceLogic:GetCanConvertGridElement(absolutePos))
         then
            table.insert(tPreselectPos, absolutePos)
            local elementType = utilData:FindPieceElement(absolutePos)

            --如果格子已经是目标颜色了 添加低优先列表， 如果不是目标颜色，添加高优先列表
            if targetGridElement == elementType then
                table.insert(lagElementPosList, absolutePos)
            else
                table.insert(priorityElementPosList, absolutePos)
            end
        end
    end

    local tConvertPosList = {}
    if nMaxConvertPerMonster >= #tPreselectPos then
        tConvertPosList = tPreselectPos
    else
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        while (nMaxConvertPerMonster > #tConvertPosList) do
            --优先转色非目标颜色
            if priorityTarget and priorityTarget == 1 then
                --如果优先列表里有数据
                if #priorityElementPosList > 0 then
                    local rand = randomSvc:LogicRand(1, #priorityElementPosList)
                    local v2Selected = table.remove(priorityElementPosList, rand)
                    table.insert(tConvertPosList, v2Selected)
                else
                    local rand = randomSvc:LogicRand(1, #lagElementPosList)
                    local v2Selected = table.remove(lagElementPosList, rand)
                    table.insert(tConvertPosList, v2Selected)
                end
            else
                --非优先转色
                local rand = randomSvc:LogicRand(1, #tPreselectPos)
                local v2Selected = table.remove(tPreselectPos, rand)
                table.insert(tConvertPosList, v2Selected)
            end
        end
    end

    local trapID = logicParam:GetTrapID()
    local trapResults = {}
    if trapID then
        for _, v2Pos in ipairs(tConvertPosList) do
            table.insert(trapResults, SkillSummonTrapEffectResult:New(trapID, v2Pos))
        end
    end

    local skillEffectConvertOccupiedGridElementResult =
        SkillEffectConvertOccupiedGridElementResult:New(tConvertPosList, targetGridElement, trapResults)
    return skillEffectConvertOccupiedGridElementResult
end
