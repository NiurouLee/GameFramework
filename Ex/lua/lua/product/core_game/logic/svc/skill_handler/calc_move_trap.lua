--[[
    MoveTrap = 118, --移动机关
]]
---@class SkillEffectCalc_MoveTrap: Object
_class("SkillEffectCalc_MoveTrap", Object)
SkillEffectCalc_MoveTrap = SkillEffectCalc_MoveTrap

function SkillEffectCalc_MoveTrap:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MoveTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamMoveTrap
    local effectParam = skillEffectCalcParam.skillEffectParam
    local trapID = effectParam:GetTrapID()
    if type(trapID) ~= "table" then
        trapID = {trapID}
    end

    local moveScopeType = effectParam:GetMoveScopeType()
    local moveScopeParam = effectParam:GetMoveScopeParam()

    local resultArray = {}

    --如果是虚影在计算这个技能效果，那么先从本体身上取到已经计算好的计算结果。

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    local range = skillEffectCalcParam.skillRange or {}

    local moveTrapEntity = {}
    for _, pos in ipairs(range) do
        local array = utilSvc:GetTrapsAtPos(pos)
        for _, eTrap in ipairs(array) do
            local cTrap = eTrap:Trap()
            if cTrap and not eTrap:HasDeadMark() and table.intable(trapID, cTrap:GetTrapID()) then
                table.insert(moveTrapEntity, eTrap)
            -- local entityID = eTrap:GetID()
            -- table.insert(resultArray, SkillEffectResultMoveTrap:New(entityID))
            end
        end
    end

    --按照远近顺序计算
    --这里采用施法者坐标计算，虚影放的连锁技使用虚影坐标
    local centerPos = skillEffectCalcParam:GetCenterPos()
    -- local gridPos = skillEffectCalcParam:GetGridPos()
    local function CmpDistancefunc(entity1, entity2)
        local pos1 = entity1:GetGridPosition()
        local pos2 = entity2:GetGridPosition()
        local dis1 = Vector2.Distance(pos1, centerPos)
        local dis2 = Vector2.Distance(pos2, centerPos)

        return dis1 < dis2
    end
    table.sort(moveTrapEntity, CmpDistancefunc)

    --1机关没死亡 and 2机关ID是目标 and 3 现有结果中不是自己占据的那个位置(result:EntityID ~= e:GetID() and pos  )

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    ---@type Vector2[]
    --已经选为结果的点
    local invalidGridList = {}
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    for _, entity in ipairs(moveTrapEntity) do
        ---@type SkillScopeResult
        local scopeResult =
            scopeCalculator:ComputeScopeRange(
            moveScopeType,
            invalidGridList,
            entity:GetGridPosition(),
            entity:BodyArea():GetArea(),
            nil,
            nil,
            entity:GetGridPosition(),
            entity
        )

        local entityID = entity:GetID()
        local posOld = entity:GetGridPosition()
        local posNew = entity:GetGridPosition()

        local attackRange = scopeResult:GetAttackRange()
        if attackRange and table.count(attackRange) > 0 then
            posNew = attackRange[1]
        end

        --无论是否移动都会有一个技能结果
        table.insert(resultArray, SkillEffectResultMoveTrap:New(entityID, posOld, posNew))

        table.insert(invalidGridList, posNew)
    end

    return resultArray

    -- --2只狗都计算到同一个范围内怎么处理

    -- for _, result in ipairs(resultArray) do
    -- end

    -- result:GetAttackRange()

    -- local limitCount = skillEffectParamSummon:GetLimitCount()

    -- local ignoreBlock = skillEffectParamSummon:IgnoreBlock()
    -- local blockFlag = BlockFlag.SummonTrap
    -- if ignoreBlock then
    --     blockFlag = 0
    -- end

    -- ---@type TrapServiceLogic
    -- local trapServiceLogic = self._world:GetService("TrapLogic")

    -- --1 召唤结果
    -- local summonPosList = {}
    -- for _, gridPos in ipairs(skillEffectCalcParam.skillRange) do
    --     if
    --         trapServiceLogic:CanSummonTrapOnPos(gridPos, trapID, blockFlag, false) and
    --             table.count(summonPosList) <= limitCount
    --      then
    --         table.insert(summonPosList, gridPos)
    --     end
    -- end

    -- local result = SkillEffectResultMoveTrap:New(trapID, summonPosList)

    -- --2 删除结果
    -- local destroyEntityID = {}
    -- ---@type BattleFlagsComponent
    -- local battleFlags = self._world:BattleFlags()
    -- local MoveTrapEntityID = battleFlags:GetMoveTrapEntityID(trapID)

    -- local meantimeCount = table.count(MoveTrapEntityID) + table.count(summonPosList)
    -- -- if meantimeCount > limitCount then

    -- local curIndex = 1
    -- while meantimeCount > limitCount do
    --     local curEntityID = MoveTrapEntityID[curIndex]
    --     meantimeCount = meantimeCount - 1
    --     curIndex = curIndex + 1
    --     table.insert(destroyEntityID, curEntityID)

    --     -- MoveTrapEntityID[1] = nil
    -- end

    -- result:SetDestroyEntityID(destroyEntityID)

    -- return result
end
