--[[
    ResetGridElement = 58, ---重置格子，洗版，默认附带洗机关效果
]]
---@class SkillEffectCalc_ResetGridElement: Object
_class("SkillEffectCalc_ResetGridElement", Object)
SkillEffectCalc_ResetGridElement = SkillEffectCalc_ResetGridElement

function SkillEffectCalc_ResetGridElement:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ResetGridElement:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_ResetGridElement
    local resetGridElementParam = skillEffectCalcParam.skillEffectParam
    local resetTrapId = resetGridElementParam:GetResetTrapId()
    local trapCount = self:CalcResetTrapCount(resetTrapId)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectResult_ResetGridElement
    local effectResult =
        self._skillEffectService:CalcSkill_ResetGridElement(
        skillEffectCalcParam.skillRange,
        casterEntity,
        resetGridElementParam
    )
    --没有需要重置的机关
    if not resetTrapId or trapCount <= 0 then
        return effectResult
    end
    --重新创建机关
    local targetElement = resetGridElementParam:GetTargetElement()
    local targetElementProb = resetGridElementParam:GetTargetElementProb()
    if targetElement and targetElementProb then
        local listPosHaveDown = {}
        local targetElementPosList = {}
        for k, v in ipairs(skillEffectCalcParam.skillRange) do
            if table.icontains(targetElement, effectResult:FindGridDataNew(v)) then
                targetElementPosList[#targetElementPosList + 1] = v
            end
        end
        local targetElementCount = math.floor(targetElementProb * trapCount + 0.5)
        targetElementCount = math.min(targetElementCount, #targetElementPosList)
        for i = 1, targetElementCount do
            local posSummon =
                self._skillEffectService:_FindSummonPos(
                SkillEffectEnum_SummonType.Trap,
                targetElementPosList,
                resetTrapId,
                listPosHaveDown
            )
            if posSummon then
                effectResult:AddSummonTrapData(posSummon, resetTrapId)
            end
        end
        for i = 1, trapCount - targetElementCount do
            local posSummon =
                self._skillEffectService:_FindSummonPos(
                SkillEffectEnum_SummonType.Trap,
                skillEffectCalcParam.skillRange,
                resetTrapId,
                listPosHaveDown
            )
            if posSummon then
                effectResult:AddSummonTrapData(posSummon, resetTrapId)
            end
        end
    else
        local listPosHaveDown = {}
        for i = 1, trapCount do
            local posSummon =
                self._skillEffectService:_FindSummonPos(
                SkillEffectEnum_SummonType.Trap,
                skillEffectCalcParam.skillRange,
                resetTrapId,
                listPosHaveDown
            )
            if posSummon then
                effectResult:AddSummonTrapData(posSummon, resetTrapId)
            end
        end
    end
    return effectResult
end

--计算场上需要重置的机关个数
function SkillEffectCalc_ResetGridElement:CalcResetTrapCount(resetTrapId)
    if not resetTrapId then
        return 0
    end
    local traps = self._world:GetGroup(self._world.BW_WEMatchers.Trap):GetEntities()
    local trapCount = 0
    if traps and #traps > 0 then
        for _, trap in ipairs(traps) do
            if not trap:HasDeadMark()then
                local trapID = trap:Trap():GetTrapID()
                if trapID == resetTrapId then
                    trapCount = trapCount + 1
                end
            end
        end
    end
    return trapCount
end
