require("pick_up_policy_base")

_class("PickUpPolicy_PetQingTong", PickUpPolicy_Base)
---@class PickUpPolicy_PetQingTong: PickUpPolicy_Base
PickUpPolicy_PetQingTong = PickUpPolicy_PetQingTong
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetQingTong:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position
    local pickPosList, atkPosList, targetIds = self:_CalPickPosPolicyPetQingTong(petEntity, activeSkillID, casterPos)
    if #pickPosList > 0 then
        ---@type AutoFightService
        local autoFightSvc = self._world:GetService("AutoFight")
        autoFightSvc:SetCastPetTrapSkillPetEntity(petEntity)
        --self._castPetTrapSkillPetEntity = petEntity
    end
    return pickPosList, atkPosList, targetIds
end

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetQingTong:_CalPickPosPolicyPetQingTong(petEntity, activeSkillID, casterPos)
    local env = self:_GetPickUpPolicyEnv()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标
    
    --此处特殊处理，将自身填充进目标，只为计数，不会作为目标ID使用
    local targetIDs = {}
    table.insert(targetIDs, petEntity:GetID())

    --获取技能中配置的点选参数
    local trapID = 0
    local pieceType = 0
    local canPickTrap = false
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local pickPosPolicyParam = skillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    if pickPosPolicyParam and pickPosPolicyParam.useType == AutoFightScopeUseType.PickPosPolicy then
        trapID = pickPosPolicyParam.trapID
        pieceType = pickPosPolicyParam.pieceType
        canPickTrap = pickPosPolicyParam.canPickTrap
    end

    --获取攻击目标
    ---@type Entity[]
    local targetEntityList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---@type Entity
        local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        ---@type Entity
        local enemyTeam = teamEntity:Team():GetEnemyTeamEntity()
        table.insert(targetEntityList, enemyTeam)
    else
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                table.insert(targetEntityList, monsterEntity)
            end
        end
    end

    --获取目标所占格子、周围一圈格子、周围两圈格子
    local targetPosList = {}
    local squareRing1PosList = {}
    local squareRing2PosList = {}
    for _, targetEntity in pairs(targetEntityList) do
        local targetPos = targetEntity:GridLocation():GetGridPos()
        local bodyArea = targetEntity:BodyArea():GetArea()
        for _, value in pairs(bodyArea) do
            local workPos = targetPos + value
            table.insert(targetPosList, workPos)
        end
        local ring1 = self:GetPosListAroundBodyArea(targetEntity, 1)
        table.appendArray(squareRing1PosList, ring1)
        local ring2 = self:GetPosListAroundBodyArea(targetEntity, 2)
        table.appendArray(squareRing2PosList, ring2)
    end

    --判定是否需要更换机关位置
    local needSummon, trapPos, matchPieceType = self:_IsNeedSummonTrap(petEntity, trapID, pieceType, targetPosList)
    if canPickTrap and not needSummon and trapPos then
        --不需要重新召唤，则返回机关位置作为点选对象
        table.insert(pickPosList, trapPos)
        return pickPosList, pickPosList, targetIDs
    end

    local squareRingListTab = {}
    table.insert(squareRingListTab, squareRing1PosList)
    table.insert(squareRingListTab, squareRing2PosList)

    --检查目标周围是否存在可召唤机关的非配置属性格子
    local pickPos = self:_CalcMatchPickPos(casterPos, squareRingListTab, trapID, pieceType)
    if pickPos then
        table.insert(pickPosList, pickPos)
        return pickPosList, pickPosList, targetIDs
    end

    --若机关格子存在，且机关脚下为配置属性格子，判断是否可攻击到目标，若能攻击目标，则返回机关格子
    if canPickTrap and needSummon and trapPos and matchPieceType then
        if self:_CanAttack(trapPos, targetPosList) then
            table.insert(pickPosList, trapPos)
            return pickPosList, pickPosList, targetIDs
        end
    end

    --检查目标周围是否存在可召唤机关的格子(去除格子属性限制)
    pickPos = self:_CalcMatchPickPos(casterPos, squareRingListTab, trapID)
    if pickPos then
        table.insert(pickPosList, pickPos)
        return pickPosList, pickPosList, targetIDs
    end

    --获取全棋盘
    ---@type Vector2[]
    local vec2BoardMax = {}
    local boardRingMax = boardService:GetCurBoardRingMax()
    for _, boardPos in ipairs(boardRingMax) do
        local vec2Pos = Vector2(boardPos[1], boardPos[2])
        table.insert(vec2BoardMax, vec2Pos)
    end
    --去除玩家位置
    table.removev(vec2BoardMax, casterPos)
    --排序
    HelperProxy:SortPosByCenterPosDistance(casterPos, vec2BoardMax)
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    for _, pickPos in pairs(vec2BoardMax) do
        if trapSvc:CanSummonTrapOnPos(pickPos, trapID) then
            table.insert(pickPosList, pickPos)
            return pickPosList, pickPosList, targetIDs
        end
    end

    return pickPosList, pickPosList, targetIDs
end

--清瞳：检查是否需要重新召唤机关
function PickUpPolicy_PetQingTong:_IsNeedSummonTrap(petEntity, trapID, pieceType, targetPosList)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    --获取清瞳召唤的机关
    ---@type Entity[]
    local trapEntityList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:TrapID():GetTrapID() == trapID and e:HasSummoner() then
            local summonEntityID = e:Summoner():GetSummonerEntityID()
            ---@type Entity
            local summonEntity = e:GetSummonerEntity()
            --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
            if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                summonEntityID = summonEntity:GetSuperEntity():GetID()
            end
            if summonEntityID == petEntity:GetID() then
                table.insert(trapEntityList, e)
            end
        end
    end

    --场上没有机关，直接返回，需要重新召唤
    if #trapEntityList == 0 then
        return true, nil
    end

    ---@type Entity
    local trapEntity = trapEntityList[1]
    local trapPos = trapEntity:GetGridPosition()

    --机关被覆盖，直接返回，需要重新召唤
    if utilScopeSvc:IsPosHaveMonsterOrPet(trapPos) then
        return true, trapPos
    end

    --机关和阻挡连线的机关重合时，需要重新召唤
    if utilScopeSvc:IsPosBlock(trapPos, BlockFlag.LinkLine) then
        return true, trapPos
    end

    --格子颜色已是配置颜色，直接返回，需要重新召唤
    if pieceType == boardService:GetPieceType(trapPos) then
        return true, trapPos, true
    end

    --检查机关菱形十二格范围内，是否有怪物存在，若不存在，则返回，需要重新召唤
    if not self:_CanAttack(trapPos, targetPosList) then
        return true, trapPos
    end

    return false, trapPos
end

--清瞳：攻击目标的对应范围内是否存在非配置属性格子，若pieceType为nil，则不进行格子属性匹配
function PickUpPolicy_PetQingTong:_CalcMatchPickPos(casterPos, posListTab, trapID, pieceType)
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    for _, posList in ipairs(posListTab) do
        --去重
        posList = table.unique(posList)
        --排序
        HelperProxy:SortPosByCenterPosDistance(casterPos, posList)

        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        for _, pickPos in pairs(posList) do
            if trapSvc:CanSummonTrapOnPos(pickPos, trapID) then
                if not pieceType then
                    return pickPos
                end
                if pieceType and pieceType ~= boardService:GetPieceType(pickPos) then
                    return pickPos
                end
            end
        end
    end

    return nil
end
--是否可以攻击目标
function PickUpPolicy_PetQingTong:_CanAttack(trapPos, targetPosList)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.Rhombus, { 2 }, trapPos)
    local attackRange = scopeResult:GetAttackRange()
    local targetInRange = table.union(attackRange, targetPosList)
    if #targetInRange == 0 then
        return false
    end

    return true
end