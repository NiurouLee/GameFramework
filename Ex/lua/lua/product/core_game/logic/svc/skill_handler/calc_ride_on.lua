--[[
    RideOn = 155, --骑乘到怪物或指定位置的机关上（优先骑乘怪物，若怪物瘫痪，则骑乘机关；若指定位置被占，则在怪物周围的一圈召唤机关，并骑乘）
]]
---@class SkillEffectCalc_RideOn : Object
_class("SkillEffectCalc_RideOn", Object)
SkillEffectCalc_RideOn = SkillEffectCalc_RideOn

function SkillEffectCalc_RideOn:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type RideServiceLogic
    self._rideSvc = self._world:GetService("RideLogic")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_RideOn:DoSkillEffectCalculator(skillEffectCalcParam)
    local fixedPos = nil
    if skillEffectCalcParam.skillRange._className and skillEffectCalcParam.skillRange._className == "Vector2" then
        fixedPos = skillEffectCalcParam.skillRange
    else
        fixedPos = skillEffectCalcParam.skillRange[1]
    end
    if not fixedPos then
        return
    end

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local curMountID = nil
    if casterEntity:HasRide() then
        ---@type RideComponent
        local rideCmpt = casterEntity:Ride()
        curMountID = rideCmpt:GetMountID()
    end

    ---@type SkillEffectRideOnParam
    local effectParam = skillEffectCalcParam.skillEffectParam
    local monsterClassID = effectParam:GetMonsterClassID()
    --查看怪物状态
    local monsterMountID, teleportPos = self:CalcMonsterState(monsterClassID, fixedPos)
    --已骑乘指定怪物，则直接返回
    if monsterMountID and curMountID == monsterMountID then
        return
    end

    --查看指定位置的机关
    local trapID = effectParam:GetTrapID()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local finalPos = fixedPos
    if teleportPos then
        finalPos = teleportPos
    end
    local trapMountID = utilDataSvc:GetTrapAtPosByTrapID(finalPos, trapID)

    --已骑乘最终位置的机关，则直接返回
    if trapMountID and curMountID == trapMountID then
        return
    end

    --最终位置无机关，则需要召唤机关
    local summonPosList = {}
    if not trapMountID then
        table.insert(summonPosList, finalPos)
    end

    local height = effectParam:GetTrapHeight()
    local centerOffset = Vector2.zero
    if monsterMountID then
        height = effectParam:GetMonsterHeight()
        centerOffset = effectParam:GetMonsterOffset()
    end
    local casterPos = casterEntity:GetGridPosition()
    local result = SkillEffectRideOnResult:New(curMountID, casterPos, monsterMountID, trapMountID, trapID, summonPosList, height, centerOffset)
    return result
end

---@param casterEntity Entity
---@param monsterClassID number
---@param fixedPos Vector2
function SkillEffectCalc_RideOn:CalcMonsterState(monsterClassID, fixedPos)
    --未配置monsterID，则直接返回nil
    if not monsterClassID then
        return nil
    end

    --查找怪物
    ---@type Entity
    local monsterEntity = nil
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() and monsterClassID == e:MonsterID():GetMonsterClassID() then
            monsterEntity = e
        end
    end

    --无配置的怪物，则直接返回nil
    if not monsterEntity then
        return nil
    end

    --检查怪物状态
    local needChangePos = false
    ---@type BuffComponent
    local buffCmpt = monsterEntity:BuffComponent()
    if buffCmpt then
        if not buffCmpt:HasBuffEffect(BuffEffectType.Palsy) then
            --未瘫痪，返回坐骑ID
            return monsterEntity:GetID()
        else
            --瘫痪，则检查位置是否占了指定位置
            local bodyArea = monsterEntity:BodyArea():GetArea()
            local pos = monsterEntity:GetGridPosition()
            for _, bodyPos in ipairs(bodyArea) do
                local curPos = pos + bodyPos
                if curPos == fixedPos then
                    needChangePos = true
                    break
                end
            end
        end
    end

    if not needChangePos then
        return nil, nil
    end

    --计算瞬移位置
    local centerPos = monsterEntity:GetGridPosition()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalc = utilScopeSvc:GetSkillScopeCalc()

    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    local maxLen = boardSvc:GetCurBoardMaxLen()
    for ringCount = 1, maxLen do
        ---@type SkillScopeResult
        local scopeRes = skillCalc:ComputeScopeRange(
            SkillScopeType.AroundBodyArea,
            { 0, ringCount },
            centerPos,
            bodyArea
        )

        local posList = scopeRes:GetAttackRange()
        for _, value in ipairs(posList) do
            if not utilScopeSvc:IsPosHaveMonsterOrPet(value) then
                return nil, value
            end
        end
    end
end
