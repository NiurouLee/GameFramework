_class("SkillEffectCalc_ButterflySummon", SkillEffectCalc_Base)
---@class SkillEffectCalc_ButterflySummon: SkillEffectCalc_Base
SkillEffectCalc_ButterflySummon = SkillEffectCalc_ButterflySummon

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ButterflySummon:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_ButterflySummon
    local effectParam = skillEffectCalcParam:GetSkillEffectParam()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()

    local casterPos = casterEntity:GetGridPosition()

    ---@type SkillEffectCalcService
    local effectCalcService = self._world:GetService("SkillEffectCalc")

    local summonPosArray = {}
    local resultArray = {}
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local wishSummonPos
        ---@type SkillDamageEffectResult
        local damageResult = skillEffectResultContainer:GetEffectResultByTargetID(SkillEffectType.Damage, targetID)
        local targetEntity = self._world:GetEntityByID(targetID)
        if damageResult and targetEntity then
            local targetPos = targetEntity:GetGridPosition()

            local dir = targetPos - casterPos
            if dir.x > 0 then
                dir.x = 1
            elseif dir.x < 0 then
                dir.x = -1
            end
            if dir.y > 0 then
                dir.y = 1
            elseif dir.y < 0 then
                dir.y = -1
            end

            wishSummonPos = targetPos - dir

            local summonValidPos = effectCalcService:_FindSummonPos(
                    SkillEffectEnum_SummonType.Monster,
                    {wishSummonPos},
                    effectParam:GetSummonID(),
                    summonPosArray,
                    nil,
                    true
            )
            if summonValidPos then
                local result = SkillEffectResult_SummonEverything:New(
                        SkillEffectEnum_SummonType.Monster,
                        effectParam:GetSummonID(),
                        casterPos,
                        summonValidPos
                )
                table.insert(resultArray, result)
                table.insert(summonPosArray, summonValidPos)
            end
        else
            local calcInfo = {
                up = {distance = -1,grids = {}},
                down = {distance = -1,grids = {}},
                left = {distance = -1,grids = {}},
                right = {distance = -1,grids = {}},
            }

            --每个方向取最远位置，每个位置召唤一个
            for _, v2 in ipairs(skillEffectCalcParam.skillRange) do
                self:_ChallengeFarthestPos(calcInfo, casterPos, v2)
            end

            local t = {}

            for _, v2 in ipairs(calcInfo.up.grids) do
                if not table.Vector2Include(t, v2) then
                    table.insert(t, v2)
                end
            end
            for _, v2 in ipairs(calcInfo.down.grids) do
                if not table.Vector2Include(t, v2) then
                    table.insert(t, v2)
                end
            end
            for _, v2 in ipairs(calcInfo.left.grids) do
                if not table.Vector2Include(t, v2) then
                    table.insert(t, v2)
                end
            end
            for _, v2 in ipairs(calcInfo.right.grids) do
                if not table.Vector2Include(t, v2) then
                    table.insert(t, v2)
                end
            end

            for _, v2 in ipairs(t) do
                local summonValidPos = effectCalcService:_FindSummonPos(
                        SkillEffectEnum_SummonType.Monster,
                        {v2},
                        effectParam:GetSummonID(),
                        summonPosArray,
                        nil,
                        true
                )
                if summonValidPos then
                    local result = SkillEffectResult_SummonEverything:New(
                            SkillEffectEnum_SummonType.Monster,
                            effectParam:GetSummonID(),
                            casterPos,
                            summonValidPos
                    )
                    table.insert(resultArray, result)
                    table.insert(summonPosArray, summonValidPos)
                end
            end
        end
    end

    return resultArray
end

---@param v2 Vector2
---@param centerPos Vector2
---@param dir Vector2
---@return boolean
local function isRangeDirMatch(v2, centerPos, dir)
    local sub = v2 - centerPos
    if sub.x > 0 then
        sub.x = 1
    elseif sub.x < 0 then
        sub.x = -1
    end

    if sub.y > 0 then
        sub.y = 1
    elseif sub.y < 0 then
        sub.y = -1
    end

    return sub == dir
end

function SkillEffectCalc_ButterflySummon:_ChallengeFarthestPos(info, centerPos, v2)
    local dirInfo
    if isRangeDirMatch(v2, centerPos, Vector2.up) then
        dirInfo = info.up
    elseif isRangeDirMatch(v2, centerPos, Vector2.down) then
        dirInfo = info.down
    elseif isRangeDirMatch(v2, centerPos, Vector2.left) then
        dirInfo = info.left
    elseif isRangeDirMatch(v2, centerPos, Vector2.right) then
        dirInfo = info.right
    end

    if not dirInfo then
        Log.fatal("SkillEffectCalc_ButterflySummon: unrecognized dir. pos=", v2, " centerPos=", centerPos)
        return
    end

    local dis = Vector2.Distance(centerPos, v2)
    if dirInfo.distance < dis then
        dirInfo.grids = {v2}
    elseif dirInfo.distance == dis then
        table.insert(dirInfo.grids, v2)
    end
end
