require("pick_up_policy_base")

_class("PickUpPolicy_PetYeliyaMain", PickUpPolicy_Base)
---@class PickUpPolicy_PetYeliyaMain: PickUpPolicy_Base
PickUpPolicy_PetYeliyaMain = PickUpPolicy_PetYeliyaMain

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetYeliyaMain:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position
    --local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetYeliyaMain(petEntity, activeSkillID, casterPos)
    return pickPosList, atkPosList, targetIds, extraParam
end
function PickUpPolicy_PetYeliyaMain:_CalPickPosPolicy_PetYeliyaMain(petEntity, activeSkillID, casterPos)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local scopeParamList = skillConfigData._pickUpValidScopeList
    local checkDamageSkillID = 30018411
    local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()
    if policyParam then
        if policyParam.checkDamageSkillID then
            checkDamageSkillID = tonumber(policyParam.checkDamageSkillID)
        end
    end

    local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}

    local tmpPickList = {}
    --根据已点选数量 取不同范围
    if #scopeParamList > 0 then
        local totalScopeParam = scopeParamList[1]
        if totalScopeParam:GetScopeType() == SkillScopeType.ScopeByPickNum then
            local subScopeParamList = totalScopeParam:GetScopeParamData()
            if subScopeParamList then
                --第一个点 优先选范围内的强化格，没有强化格的时候选能打到最多目标的点
                local subParam = subScopeParamList[1]
                ---技能范围
                ---@type SkillPreviewScopeParam
                local validScopeParam =
                    SkillPreviewScopeParam:New(
                        {
                            TargetType = subParam.targetType,
                            ScopeType = subParam.scopeType,
                            ScopeCenterType = subParam.scopeCenterType,
                            TargetTypeParam = subParam.targetTypeParam
                        }
                    )
                validScopeParam:SetScopeParamData(subParam.scopeParam)

                local validGirdList = utilScopeSvc:BuildScopeGridList({ validScopeParam }, petEntity)
                local invalidGridList =
                utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)
                local invalidGridDict = {}
                for _, invalidPos in ipairs(invalidGridList) do
                    invalidGridDict[self:_Pos2Index(invalidPos)] = true
                end
                local validPosIdxList = {}
                local validPosList = {}
                for _, validPos in ipairs(validGirdList) do
                    local validPosIdx = self:_Pos2Index(validPos)
                    if not invalidGridDict[validPosIdx] then
                        validPosIdxList[validPosIdx] = true
                        validPosList[#validPosList + 1] = validPos
                    end
                end
                local firstPickPos
                local lastPickPos
                local lastPickSuperGrid = false
                local testPickPos = nil
                --第一个点 先找范围内强化格
                testPickPos = self:_YeliyaFindValidPosWithSuperGrid(petEntity,casterPos,validPosIdxList,tmpPickList)
                if testPickPos then
                    firstPickPos = testPickPos
                    lastPickPos = testPickPos
                    lastPickSuperGrid = true
                    table.insert(tmpPickList, firstPickPos)
                else
                    --没找到强化格，则找能攻击到敌人的点（取目标最多的位置）
                    testPickPos = self:_YeliyaFindValidPosWithMaxTargetCount(petEntity,casterPos,validPosIdxList,tmpPickList,checkDamageSkillID)
                    if testPickPos then
                        firstPickPos = testPickPos
                        lastPickPos = testPickPos
                        lastPickSuperGrid = false
                        table.insert(tmpPickList, firstPickPos)
                    else
                        --都没有就不放了
                        return {},{},{}
                    end
                end
                --后续点
              
                if firstPickPos then
                    if not lastPickSuperGrid then--第一个不是点的强化格，则没有后续点击了
                    else
                        --循环 点到强化格就继续找
                        local subPickFinish = false
                        local maxFindTimes = 30--限制一下循环
                        local findNextTimes = 0
                        subParam = subScopeParamList[2]
                        ---技能范围
                        local validScopeParam =
                            SkillPreviewScopeParam:New(
                                {
                                    TargetType = subParam.targetType,
                                    ScopeType = subParam.scopeType,
                                    ScopeCenterType = subParam.scopeCenterType,
                                    TargetTypeParam = subParam.targetTypeParam
                                }
                            )
                        validScopeParam:SetScopeParamData(subParam.scopeParam)
                        while not subPickFinish do
                            findNextTimes = findNextTimes + 1
                            if findNextTimes > maxFindTimes then
                                subPickFinish = true
                                break
                            end
                            if lastPickSuperGrid then
                                --后续点 优先强化格，没有则向最近的敌人靠近
                                local subScopeResult = utilScopeSvc:CalcSKillPreviewScopeResult(validScopeParam, lastPickPos, petEntity)
                                local validGirdList = subScopeResult:GetAttackRange()
                                --validGirdList = utilScopeSvc:BuildScopeGridListMultiPick({ validScopeParam }, petEntity, tmpPickList)
                                local validPosIdxList = {}
                                local validPosList = {}
                                for _, validPos in ipairs(validGirdList) do
                                    local validPosIdx = self:_Pos2Index(validPos)
                                    if not invalidGridDict[validPosIdx] then
                                        validPosIdxList[validPosIdx] = true
                                        validPosList[#validPosList + 1] = validPos
                                    end
                                end
                                local nextPickPos
                                testPickPos = self:_YeliyaFindValidPosWithSuperGrid(petEntity,lastPickPos,validPosIdxList,tmpPickList)
                                if testPickPos then
                                    nextPickPos = testPickPos
                                    lastPickPos = testPickPos
                                    lastPickSuperGrid = true
                                    table.insert(tmpPickList, nextPickPos)
                                else
                                    --没找到强化格，则找能攻击到敌人的点（取目标最多的位置）
                                    testPickPos = self:_YeliyaFindValidPosWithMaxTargetCount(petEntity,lastPickPos,validPosIdxList,tmpPickList,checkDamageSkillID)
                                    if testPickPos then
                                        nextPickPos = testPickPos
                                        lastPickPos = testPickPos
                                        lastPickSuperGrid = false
                                        table.insert(tmpPickList, nextPickPos)
                                    else
                                        --都没有 找离怪最近
                                        testPickPos = self:_YeliyaFindValidPosNearToMonster(petEntity,lastPickPos,validPosIdxList,validPosList, tmpPickList)
                                        if testPickPos then
                                            nextPickPos = testPickPos
                                            lastPickPos = testPickPos
                                            lastPickSuperGrid = false
                                            table.insert(tmpPickList, nextPickPos)
                                        end
                                    end
                                    --后续没有点到强化格就不继续了
                                    subPickFinish = true
                                end
                            end
                        end
                    end
                    if tmpPickList and #tmpPickList > 0 then
                        pickPosList = tmpPickList
                        --retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pickPosList)
                    end
                end
            end
        end
    end
    return pickPosList, retScopeResult, retTargetIds
end

function PickUpPolicy_PetYeliyaMain:_YeliyaFindValidPosWithSuperGrid(petEntity,centerPos,validPosIdxList,alreadyPickList)
    local pickPos = nil
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    local centerPosIndex = self:_Pos2Index(centerPos)
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(centerPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            if not table.icontains(alreadyPickList,pos) then
                local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                if not isBlockedLinkLine then
                    local traps = utilDataSvc:GetTrapsAtPos(pos)
                    if traps then
                        for index, e in ipairs(traps) do
                            if e:Trap():IsSuperGrid() then
                                pickPos = pos
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return pickPos
end
function PickUpPolicy_PetYeliyaMain:_YeliyaFindValidPosWithMaxTargetCount(petEntity,centerPos,validPosIdxList,alreadyPickList,checkDamageSkillID)
    local pickPos = nil

    checkDamageSkillID = 30018411
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    local centerPosIndex = self:_Pos2Index(centerPos)
    local maxTargetCount = 0
    local maxTargetPos = nil
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(centerPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            if not table.icontains(alreadyPickList,pos) then
                local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                if not isBlockedLinkLine then
                    local result, targetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, checkDamageSkillID, pos)
                    if targetIds then
                        local targetCount = #targetIds
                        if targetCount > maxTargetCount then
                            maxTargetCount = targetCount
                            maxTargetPos = pos
                        end
                    end
                end
            end
        end
    end
    if maxTargetPos then
        pickPos = maxTargetPos
    end
    return pickPos
end
function PickUpPolicy_PetYeliyaMain:_YeliyaFindValidPosNearToMonster(petEntity,centerPos,validPosIdxList,validPosList,alreadyPickList)
    local pickPos = nil

    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local validEnemyList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local enemyTeam = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
        table.insert(validEnemyList,enemyTeam)
    else
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                table.insert(validEnemyList,monsterEntity)
            end
        end
    end
    if validEnemyList and #validEnemyList > 0 then
        --先找个离中心点最近的怪
        local enemyPosList = {}
        for index, enemyEntity in ipairs(validEnemyList) do
            local enemyPos = enemyEntity:GetGridPosition()
            local tv2BodyArea = enemyEntity:BodyArea():GetArea()
            for _, v2Relative in ipairs(tv2BodyArea) do
                ---@type Vector2
                local v2 = enemyPos + v2Relative
                table.insert(enemyPosList,v2)
            end
        end
        local sortedEnemyPosList = HelperProxy:SortPosByCenterPosDistance(centerPos, enemyPosList)
        if sortedEnemyPosList and #sortedEnemyPosList > 0 then
            local nearestPos = sortedEnemyPosList[1]
            local sortedValidPosList = HelperProxy:SortPosByCenterPosDistance(nearestPos, validPosList)
            if sortedValidPosList then
                for index, pos in ipairs(sortedValidPosList) do
                    if not table.icontains(alreadyPickList,pos) then
                        local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                        if not isBlockedLinkLine then
                            pickPos = pos
                            break
                        end
                    end
                end
            end
        end
    end
    return pickPos
end