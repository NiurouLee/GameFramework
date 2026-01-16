--[[
    SummonTrap = 11, --召唤机关
]]
---@class SkillEffectCalc_SummonTrapByCasterPos: Object
_class("SkillEffectCalc_SummonTrapByCasterPos", Object)
SkillEffectCalc_SummonTrapByCasterPos = SkillEffectCalc_SummonTrapByCasterPos

function SkillEffectCalc_SummonTrapByCasterPos:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrapByCasterPos:DoSkillEffectCalculator(skillEffectCalcParam)
    local skillRange = skillEffectCalcParam.skillRange
    if not skillRange or table.count(skillRange) == 0 then
        return
    end
    local casterID = skillEffectCalcParam.casterEntityID
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SkillEffectParamSummonTrapByCasterPos
    local effectParam = skillEffectCalcParam.skillEffectParam

    local trapMaxCount = effectParam:GetMaxCount()

    local rangeAndCount = effectParam:GetRangeAndCount()

    local trapID = effectParam:GetTrapID()

    local bodyArea = casterEntity:BodyArea():GetArea()
    local casterBodyArea = {}
    for i, p in ipairs(bodyArea) do
        local newPos = Vector2(p.x+casterPos.x,p.y+casterPos.y)
        table.insert(casterBodyArea,newPos)
    end

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local resultList = {}
    for i, param in ipairs(rangeAndCount) do
        local range = table.clone(param.vectorRange)
        local inRangeCount = self:RangeInRangeCount(range,casterBodyArea)
        local maxCount = param.maxCount
        if param.casterInRange[inRangeCount] then
            maxCount = maxCount - param.casterInRange[inRangeCount]
        end
        local trapList = trapSvc:FindTrapByTrapIDAndRange(trapID,range)
        if maxCount > #trapList then
            self:SummonTrapInRange(range,trapID,maxCount-(#trapList),resultList)
        end
    end
    return resultList
end

function SkillEffectCalc_SummonTrapByCasterPos:SummonTrapInRange(range,trapID,count,resultList)
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    while #range>0 and count >0 do
        ---产生随机数
        local index = randomSvc:BoardLogicRand(1, #range)
        local pos = range[index]

        table.remove(range,index)
        if trapSvc:CanSummonTrapOnPos(pos,trapID) then
            ---@type SkillSummonTrapEffectResult
            local result = SkillSummonTrapEffectResult:New(trapID,Vector2(pos.x,pos.y))
            table.insert(resultList,result)
            count = count -1
        end
    end
end

---@return number
function SkillEffectCalc_SummonTrapByCasterPos:RangeInRangeCount(range1,range2)
    local count = 0
    for _, pos in ipairs(range1) do
        if table.Vector2Include(range2,pos) then
            count = count +1
        end
    end
    return count
end
