--[[
    SummonTrap = 11, --召唤机关
]]
---@class SkillEffectCalc_SummonTrap: Object
_class("SkillEffectCalc_SummonTrap", Object)
SkillEffectCalc_SummonTrap = SkillEffectCalc_SummonTrap

function SkillEffectCalc_SummonTrap:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    local skillRange = skillEffectCalcParam.skillRange
    if not skillRange or table.count(skillRange) == 0 then
        return
    end
    ---@type SkillSummonTrapEffectParam
    local skillSummonTrapEffectParam = skillEffectCalcParam.skillEffectParam
    if skillSummonTrapEffectParam:GetSummonType() == SummonTrapType.ByTargetUnderGrid then
        return self:SummonTrapByTargetUnderGrid(skillEffectCalcParam)
    end
    if skillSummonTrapEffectParam:GetSummonType() == SummonTrapType.Range then
        return self:SummonTrapByRange(skillEffectCalcParam)
    end
    if skillSummonTrapEffectParam:GetSummonType() == SummonTrapType.RandomRange then
        return self:SummonTrapByRandomRange(skillEffectCalcParam)
    end
    if not self:CheckCanSummon(skillEffectCalcParam) then
        return
    end

    if not self:CheckCanSummonByCountLimit(skillEffectCalcParam) then
        return
    end

    local centerPos = skillEffectCalcParam.skillRange[1]

    local trapIdList = skillSummonTrapEffectParam:GetTrapID()
    local block = skillSummonTrapEffectParam:GetBlock()
    if type(trapIdList) == "number" then
        trapIdList = { trapIdList }
    end

    local len = table.count(trapIdList)
    local index = 1
    if len > 1 then --列表有多个，随机一个
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        index = randomSvc:LogicRand(1, len)
    end
    local trapId = trapIdList[index]

    --检查是否只需要移动机关
    local moveTrap = skillSummonTrapEffectParam:GetMoveTrap()
    if moveTrap then
        local result = self:MoveTrap(trapId, centerPos, skillEffectCalcParam:GetCasterEntityID())
        if result then
            return result
        end
    end

    --检查是否需要使用点选方向
    local dir = nil
    local isUsePickUpDir = skillSummonTrapEffectParam:IsUsePickUpDir()
    if isUsePickUpDir then
        ---@type Entity
        local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpCmpt = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpCmpt then
            --dir = activeSkillPickUpCmpt:GetLastPickUpDirection()
            local firstPos = activeSkillPickUpCmpt:GetFirstValidPickUpGridPos()
            local secondPos = activeSkillPickUpCmpt:GetLastPickUpGridPos()
            dir = secondPos - firstPos
        end
    end

    local aiOrder = self:GetTrapAIOrder(skillEffectCalcParam)

    if trapId then
        --查看召唤位置上是否可以重复召唤相同ID的机关
        if not self:CheckCanSummonByOverlapFlag(skillEffectCalcParam, centerPos, trapId) then
            return
        end

        --不在怪物上召唤
        if skillSummonTrapEffectParam:IsBlockByMonster() then
            ---@type UtilDataServiceShare
            local sUtilData = self._world:GetService("UtilData")
            local entity = sUtilData:GetMonsterAtPos(centerPos) --黑拳赛敌方队伍也会计入
            if entity then
                ---@type BuffComponent
                local buffComponent = entity:BuffComponent()
                if buffComponent and buffComponent:HasBuffEffect(BuffEffectType.NotBeSelectedAsSkillTarget) then
                    --不可选中 则不阻挡
                else
                    return
                end
            end
        end

        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        if block == 0 or trapSvc:CanSummonTrapOnPos(centerPos, trapId) then
            return SkillSummonTrapEffectResult:New(
                trapId,
                centerPos,
                skillSummonTrapEffectParam:IsTransferDisabled(),
                skillSummonTrapEffectParam:GetSkillEffectDamageStageIndex(),
                dir,
                aiOrder
            )
        end
    end
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:CheckCanSummon(skillEffectCalcParam)
    ---@type SkillSummonTrapEffectParam
    local summonTrapParam = skillEffectCalcParam.skillEffectParam
    local absorbNum = summonTrapParam:GetAbsorbTrapNum()

    --不需要吸收机关个数，则直接返回true
    if absorbNum == 0 then
        return true
    end

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillEffectAbsorbTrapsAndDamageByPickupTargetResult
    local result = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.AbsorbTrapsAndDamageByPickupTarget)
    if result then
        local trapEntityIDs = result:GetTrapEntityIDs()
        if #trapEntityIDs >= absorbNum then
            return true
        end
    end

    return false
end

--查看召唤位置上是否可以重复召唤相同ID的机关
---@param skillEffectCalcParam SkillEffectCalcParam
---@param centerPos Vector2
---@param trapId number
---@return boolean
function SkillEffectCalc_SummonTrap:CheckCanSummonByOverlapFlag(skillEffectCalcParam, centerPos, trapId)
    ---@type SkillSummonTrapEffectParam
    local summonTrapParam = skillEffectCalcParam:GetSkillEffectParam()

    if summonTrapParam:IsTrapOverlap() then
        return true
    end

    local boardCmpt = self._world:GetBoardEntity():Board()
    local repeatTraps = boardCmpt:GetPieceEntities(
        centerPos,
        function(e)
            local isOwner = false
            if e:HasSummoner() then
                local summoner = e:Summoner()
                if summoner:GetSummonerEntityID() == skillEffectCalcParam.casterEntityID then
                    isOwner = true
                else
                    if summonTrapParam:IsTrapOverlapCheckSuper() then
                        local summonEntity = e:GetSummonerEntity()
                        if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                            local summonEntityID = summonEntity:GetSuperEntity():GetID()
                            if summonEntityID == skillEffectCalcParam.casterEntityID then
                                isOwner = true
                            end
                        end
                    end
                end
            else
                isOwner = true
            end
            return isOwner and e:HasTrap() and e:Trap():GetTrapID() == trapId and not e:HasDeadMark()
        end
    )

    if #repeatTraps > 0 then
        return false
    end

    return true
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:CheckCanSummonByCountLimit(skillEffectCalcParam)
    local casterID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    if trapSvc:IsSummonCountLimit(casterEntity) then
        return false
    end

    return true
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:GetTrapAIOrder(skillEffectCalcParam)
    ---@type SkillSummonTrapEffectParam
    local skillParam = skillEffectCalcParam:GetSkillEffectParam()
    local aiOrder = skillParam:GetTrapAIOrder()
    if not aiOrder then
        return
    end

    local casterID = skillEffectCalcParam:GetCasterEntityID()
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local curCount = trapSvc:GetSummonTrapCount(casterEntity)

    return aiOrder + curCount
end

--若机关存在，则移动机关；若不存在，则返回nil
---@param trapID number
---@param movePos Vector2
---@param casterEntityID number
function SkillEffectCalc_SummonTrap:MoveTrap(trapID, movePos, casterEntityID)
    --检查场上是否已存在此ID的机关并且召唤者是施法者
    ---@type Entity[]
    local trapEntityList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:TrapID():GetTrapID() == trapID and e:HasSummoner() and
            e:Summoner():GetSummonerEntityID() == casterEntityID
        then
            table.insert(trapEntityList, e)
        end
    end

    --场上没有机关，直接返回，需要召唤
    if #trapEntityList == 0 then
        return
    end

    ---@type Entity
    local trapEntity = trapEntityList[1]
    local entityID = trapEntity:GetID()
    local posOld = trapEntity:GetGridPosition()
    local replaceTrapEntityID = nil
    local needMove = true
    if posOld ~= movePos then
        --位置不同，则需去获取被顶替的对象ID（因为位置相同，那么被顶替的是自己，不需要删除操作）
        needMove, replaceTrapEntityID = self:_GetReplaceTrapEntityID(trapID, movePos)
    end

    if not needMove then
        return
    end

    local resultArray = {}
    table.insert(resultArray, SkillEffectResultMoveTrap:New(entityID, posOld, movePos, replaceTrapEntityID))
    return resultArray
end

--获取被顶掉的机关EntityID
function SkillEffectCalc_SummonTrap:_GetReplaceTrapEntityID(trapID, movePos)
    --检查移动后的位置是否存在同层且优先级低的机关
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type TrapConfigData
    local trapConfigData = configSvc:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapID)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local samePosTraps = utilSvc:GetTrapsAtPos(movePos)
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    if #samePosTraps == 0 then
        return true, nil
    end
    local onlyViewTrap = trapSvc:IsViewTrapLevel(trapData.TrapLevel)
    for _, e in ipairs(samePosTraps) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        if trapCmpt:GetTrapLevel() == trapData.TrapLevel and not onlyViewTrap then
            if trapCmpt:GetReplaceLevel() <= trapData.ReplaceLevel then
                if not e:HasDeadMark() then
                    --同层机关，高优先级替换低或相等的
                    e:Attributes():Modify("HP", 0)
                    trapSvc:AddTrapDeadMark(e)
                    return true, e:GetID()
                    --同层只会有一个，处理完可以直接跳出循环
                end
            else
                return false, nil
            end
        end
    end

    return true, nil
end

---@param range Vector2[]
---@param stopSummonTrapType number[]
function SkillEffectCalc_SummonTrap:_RangeCanSummonTrap(trapID, range, stopSummonTrapType)
    ---@type TrapConfigData
    local trapConfigData = self._configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapID)
    local find = false
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local randomSvc = self._world:GetService("RandomLogic")

    while #range > 0 do
        local index = randomSvc:LogicRand(1, #range)
        local pos = range[index]
        table.remove(range, index)
        local bFind = self:IsPosCanSummonTrap(pos, trapID, stopSummonTrapType)
        if bFind then
            return pos
        end
    end
    return nil
end

function SkillEffectCalc_SummonTrap:IsPosCanSummonTrap(pos, trapID, stopSummonTrapType)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local samePosTraps = utilSvc:GetTrapsAtPos(pos)
    local isValidPos = utilSvc:IsValidPiecePos(pos)
    if not isValidPos then
        return false
    end
    if #samePosTraps == 0 then
        return true
    end
    for _, e in ipairs(samePosTraps) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        local type = trapCmpt:GetTrapType()
        local _trapID = trapCmpt:GetTrapID()
        if table.icontains(stopSummonTrapType, type) or _trapID == trapID then
            return false
        end
    end
    return true
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:SummonTrapByTargetUnderGrid(skillEffectCalcParam)
    local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
    ---@type SkillSummonTrapEffectParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    ---@type number[]
    local stopSummonTrapType = param:GetStopSummonTrapType()
    local trapID = param:GetTrapID()
    ----@type Vector2[]
    local gridList = {}
    if not targetIDs or targetIDs[1] == -1 then
        return
    end
    for i, id in ipairs(targetIDs) do
        ---@type Entity
        local entity = self._world:GetEntityByID(id)
        ---@type Vector2
        local localPos = entity:GetGridPosition()
        ---@type BodyAreaComponent
        local bodyAreaCpt = entity:BodyArea()
        ---@type Vector2[]
        local bodyArea = bodyAreaCpt:GetArea()
        local range = {}
        if #bodyArea > 0 then
            for i, v in ipairs(bodyArea) do
                local pos = Vector2(v.x + localPos.x, v.y + localPos.y)
                table.insert(range, pos)
            end
        else
            table.insert(range, localPos)
        end
        local canSummonPos = self:_RangeCanSummonTrap(trapID, range, stopSummonTrapType)
        if canSummonPos then
            table.insert(gridList, canSummonPos)
        end
    end
    local retList = {}
    for i, pos in ipairs(gridList) do
        local result = SkillSummonTrapEffectResult:New(
            trapID,
            pos,
            param:IsTransferDisabled(),
            param:GetSkillEffectDamageStageIndex())
        table.insert(retList, result)
    end
    return retList
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:SummonTrapByRange(skillEffectCalcParam)
    local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
    ---@type SkillSummonTrapEffectParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local range = skillEffectCalcParam:GetSkillRange()
    ---@type number[]
    local stopSummonTrapType = param:GetStopSummonTrapType()
    local trapID = param:GetTrapID()
    ----@type Vector2[]
    local gridList = {}
    if not targetIDs or targetIDs[1] == -1 then
        return
    end
    for _, pos in ipairs(range) do
        local canSummon = self:IsPosCanSummonTrap(pos, trapID, stopSummonTrapType)
        if canSummon then
            table.insert(gridList, pos)
        end
    end
    local retList = {}
    for _, pos in ipairs(gridList) do
        local result = SkillSummonTrapEffectResult:New(
            trapID,
            pos,
            param:IsTransferDisabled(),
            param:GetSkillEffectDamageStageIndex())
        table.insert(retList, result)
    end
    return retList
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SummonTrap:SummonTrapByRandomRange(skillEffectCalcParam)
    local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
    ---@type SkillSummonTrapEffectParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    local range = skillEffectCalcParam:GetSkillRange()
    ---@type number[]
    local stopSummonTrapType = param:GetStopSummonTrapType()
    local randomCount = param:GetRandomCount()
    local trapID = param:GetTrapID()
    ----@type Vector2[]
    local gridList = {}
    if not targetIDs or targetIDs[1] == -1 then
        return
    end
    local tmpRange = {}
    for index, pos in ipairs(range) do
        tmpRange[index] = pos
    end
    local randomSvc = self._world:GetService("RandomLogic")
    while #tmpRange > 0 and randomCount ~= 0 do
        local index = randomSvc:LogicRand(1, #tmpRange)
        local pos = tmpRange[index]
        table.remove(tmpRange, index)
        local bCan = self:IsPosCanSummonTrap(pos, trapID, stopSummonTrapType)
        if bCan then
            table.insert(gridList, pos)
            randomCount = randomCount - 1
        end
    end
    local retList = {}
    for _, pos in ipairs(gridList) do
        local result = SkillSummonTrapEffectResult:New(
            trapID,
            pos,
            param:IsTransferDisabled(),
            param:GetSkillEffectDamageStageIndex())
        table.insert(retList, result)
    end
    return retList
end
