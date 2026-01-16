--[[
    骑乘buff
]]
---@class BuffLogicRide:BuffLogicBase
_class("BuffLogicRide", BuffLogicBase)
BuffLogicRide = BuffLogicRide

function BuffLogicRide:Constructor(buffInstance, logicParam)
    --指定的机关ID
    self._trapID = logicParam.trapID
    self._trapHeight = logicParam.trapHeight
    --指定的怪物ID
    self._monsterClassID = logicParam.monsterClassID
    self._monsterHeight = logicParam.monsterHeight
    self._monsterOffset = Vector2.zero
    if logicParam.offset and #logicParam.offset == 2 then
        self._monsterOffset = Vector2(logicParam.offset[1], logicParam.offset[2])
    end
    --骑乘后是否改变身形，默认需要改变
    self._changeBodyArea = logicParam.changeBodyArea == nil and true or logicParam.changeBodyArea
    --骑乘后鼠标点击是否只能点击骑乘者
    self._onlyRiderCanClick = logicParam.onlyRiderCanClick == nil and true or logicParam.onlyRiderCanClick

    --范围
    self._targetType = logicParam.targetType
    self._targetTypeParam = logicParam._targetTypeParam
    self._scopeType = logicParam.scopeType
    self._scopeTypeParam = logicParam.scopeTypeParam
end

function BuffLogicRide:DoLogic(notify)
    ---@type Entity
    local entity = self._buffInstance:Entity()
    if not entity then
        return
    end

    --buff拥有者范围
    local pos = entity:GetGridPosition()
    local dir = entity:GetGridDirection()
    local bodyArea = entity:BodyArea():GetArea()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalc = utilScopeSvc:GetSkillScopeCalc()
    ---@type SkillScopeResult
    local skillScopeResult = skillCalc:ComputeScopeRange(self._scopeType, self._scopeTypeParam, pos,
        bodyArea, dir, self._targetType, pos, entity)

    local targetEntityIDList = utilScopeSvc:SelectSkillTarget(entity, self._targetType, skillScopeResult,
        nil, self._targetTypeParam)

    --检查怪物是否在目标内
    local entityID = self:IsMonsterInTargetList(targetEntityIDList)
    if entityID then
        --设置骑乘状态
        return self:CalcRide(notify, entity, entityID, true)
    end

    --检查机关是否在目标内，并获取距离最近的机关
    entityID = self:IsTrapInTargetList(pos, targetEntityIDList)
    if entityID then
        --设置骑乘机关
        return self:CalcRide(notify, entity, entityID, false)
    end

    --目标内没有合法被骑乘对象，则获取下落位置
    local targetPos = self:CalcTargetPos(entity)
    --若无需更改位置，则直接返回
    if not targetPos then
        return
    end

    return self:CalcRide(notify, entity, nil, false, targetPos)
end

function BuffLogicRide:IsMonsterInTargetList(targetEntityIDList)
    for _, entityID in ipairs(targetEntityIDList) do
        ---@type Entity
        local entity = self._world:GetEntityByID(entityID)

        --查找技能目标中是否存在指定怪物，且怪物不处于瘫痪状态
        if entity:HasMonsterID() and entity:MonsterID():GetMonsterClassID() == self._monsterClassID then
            local buffCmpt = entity:BuffComponent()
            if buffCmpt and not buffCmpt:HasBuffEffect(BuffEffectType.Palsy) then
                return entityID
            end
        end
    end
end

function BuffLogicRide:IsTrapInTargetList(casterPos, targetEntityIDList)
    local trapPosList = {}
    for _, trapID in ipairs(targetEntityIDList) do
        ---@type Entity
        local entity = self._world:GetEntityByID(trapID)

        --查找技能目标中是否存在指定的机关
        if entity:HasTrapID() and entity:TrapID():GetTrapID() == self._trapID then
            if not entity:HasDeadMark() then
                local trapPos = entity:GetGridPosition()
                table.insert(trapPosList, trapPos)
            end
        end
    end

    if #trapPosList == 0 then
        return
    end

    HelperProxy:SortPosByCenterPosDistance(casterPos, trapPosList)

    --根据位置找到机关ID
    local trapPos = trapPosList[1]
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es = boardCmpt:GetPieceEntities(
        trapPos,
        function(e)
            return e:HasTrapID() and e:TrapID():GetTrapID() == self._trapID
        end
    )
    if #es > 0 then
        ---@type Entity
        local trapEntity = es[1]
        return trapEntity:GetID()
    end
end

---@param entity Entity
---@return Vector2
function BuffLogicRide:CalcTargetPos(entity)
    --未骑乘，直接返回，不需要计算下落位置
    if not entity:HasRide() then
        return
    end

    ---@type RideComponent
    local rideCmpt = entity:Ride()
    local mountID = rideCmpt:GetMountID()
    ---@type Entity
    local mountEntity = self._world:GetEntityByID(mountID)
    if not mountEntity then
        return
    end

    --若被骑乘的是机关，则原地下落
    if mountEntity:HasTrap() then
        return mountEntity:GetGridPosition()
    end

    --若被骑乘的是怪物，则寻找怪物周围的合法位置且距离光灵最远的位置
    local pos = mountEntity:GetGridPosition()
    local bodyArea = mountEntity:BodyArea():GetArea()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local validPosList = {}

    --先查找十字范围
    local crossList = ComputeScopeRange.ComputeRange_CrossScope(pos, #bodyArea, 1)
    for _, value in ipairs(crossList) do
        if not utilData:IsPosBlock(value, BlockFlag.MonsterLand) then
            table.insert(validPosList, value)
        end
    end

    --再根据方形范围按圈数查找，只查周围两圈，如果没有就返回
    local ringCount = 1
    while #validPosList == 0 and ringCount < 3 do
        local ringList = ComputeScopeRange.ComputeRange_SquareRing(pos, #bodyArea, ringCount)
        for _, value in ipairs(ringList) do
            if not utilData:IsPosBlock(value, BlockFlag.MonsterLand) then
                table.insert(validPosList, value)
            end
        end
        ringCount = ringCount + 1
    end

    if #validPosList == 0 then
        return
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()
    HelperProxy:SortPosByCenterPosDistance(teamPos, validPosList)

    return validPosList[#validPosList]
end

---@param entity Entity
function BuffLogicRide:CalcRide(notify, entity, mountID, isMonster, targetPos)
    ---@type RideServiceLogic
    local rideSvc = self._world:GetService("RideLogic")

    local fromTrap = false
    if entity:HasRide() then
        ---@type RideComponent
        local rideCmpt = entity:Ride()
        local oriMountID = rideCmpt:GetMountID()
        ---@type Entity
        local oriMountEntity = self._world:GetEntityByID(oriMountID)
        if oriMountEntity:HasTrap() then
            fromTrap = true
        end
        rideSvc:RemoveRide(entity:GetID(), oriMountID)
    end
    rideSvc:ResetBodyArea(entity)

    if mountID then
        if isMonster then
            rideSvc:ReplaceRide(entity:GetID(), mountID, self._monsterHeight, self._monsterOffset, self._changeBodyArea,
                self._onlyRiderCanClick)
        else
            rideSvc:ReplaceRide(entity:GetID(), mountID, self._trapHeight)
        end
    else
        rideSvc:SetNoRidePos(entity:GetID(), targetPos, fromTrap)
    end

    --骑乘结果
    ---@type GridLocationComponent
    local gridLocCmpt = entity:GridLocation()
    ---@type DataGridLocationResult
    local gridLocRes = DataGridLocationResult:New()
    gridLocRes:SetGridLocResultBornPos(gridLocCmpt:GetGridPos())
    gridLocRes:SetGridLocResultBornDir(gridLocCmpt:GetGridDir())
    gridLocRes:SetGridLocResultBornHeight(gridLocCmpt:GetGridLocHeight())
    gridLocRes:SetGridLocResultBornOffset(gridLocCmpt:GetGridOffset())
    gridLocRes:SetGridLocResultDamageOffset(gridLocCmpt:GetDamageOffset())

    local buffResult = BuffResultRide:New(entity:GetID(), mountID, gridLocRes)
    if notify.GetNotifyEntity then
        buffResult:SetNotifyEntity(notify:GetNotifyEntity())
    end
    if notify.GetChainSkillIndex then
        buffResult:SetNotifyChainSkillIndex(notify:GetChainSkillIndex())
    end
    if notify.GetAttackPos and notify.GetTargetPos then
        buffResult:SetNotifyPos(notify:GetAttackPos())
        buffResult:SetTargetPos(notify:GetTargetPos())
    end
    return buffResult
end
