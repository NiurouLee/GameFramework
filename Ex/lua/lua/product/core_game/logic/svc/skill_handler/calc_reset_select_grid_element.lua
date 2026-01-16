--[[
    ResetSelectGridElement = 76, --（扩展58）重置范围内某些符合选定规则的格子，比如龙女重置雷属性格子为其他格子
]]
---@class SkillEffectCalc_ResetSelectGridElement: Object
_class("SkillEffectCalc_ResetSelectGridElement", Object)
SkillEffectCalc_ResetSelectGridElement = SkillEffectCalc_ResetSelectGridElement

function SkillEffectCalc_ResetSelectGridElement:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ResetSelectGridElement:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local realRange = {}
    --按格子颜色筛选
    local conditionSrcElement = skillEffectCalcParam.skillEffectParam:GetSelectConditionSrcElement()
    if type(conditionSrcElement) == "table" then
        ---@type BoardServiceLogic
        local boardServiceLogic = self._world:GetService("BoardLogic")
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        for i = 1, #skillEffectCalcParam.skillRange do
            local pos = skillEffectCalcParam.skillRange[i]
            local elementType = utilData:FindPieceElement(pos)
            if
                not boardServiceLogic:IsPosBlock(pos, BlockFlag.ChangeElement) and
                    self:_CheckInTable(conditionSrcElement, elementType)
             then
                table.insert(realRange, pos)
            end
        end
    end
    return self._skillEffectService:CalcSkill_ResetGridElement(
        realRange,
        casterEntity,
        skillEffectCalcParam.skillEffectParam
    )
end

--辅助函数
function SkillEffectCalc_ResetSelectGridElement:_CheckInTable(tableName, element)
    for _, v in pairs(tableName) do
        if v == element then
            return true
        end
    end
    return false
end
