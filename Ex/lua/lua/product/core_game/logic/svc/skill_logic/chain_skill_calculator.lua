--[[------------------------------------------------------------------------------------------
    ChainSkillCalculator :连锁技计算器
    根据当前连线队列计算连锁技效果
]] --------------------------------------------------------------------------------------------

---@class ChainSkillCalculator: Object
_class("ChainSkillCalculator", Object)
ChainSkillCalculator = ChainSkillCalculator

---@param world MainWorld
function ChainSkillCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillLogicService
    self._skillLogicService = self._world:GetService("SkillLogic")

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillScopeTargetSelector
    self._targetSelector = world:GetSkillScopeTargetSelector()

    ---逻辑效果执行器
    ---@type SkillEffectLogicExecutor
    self._skillEffectLogicExecutor = SkillEffectLogicExecutor:New(world)

    ----@type SkillEffectCalcRandDamageSameHalf
    self._calcRandDamageSameHalfCalc = SkillEffectCalcRandDamageSameHalf:New(world)
    ----@type SkillEffectCalc_SplashPreDamage
    self._calcSplashPreDamageCalc = SkillEffectCalc_SplashPreDamage:New(world)
    ---@type SkillEffectCalc_DamageCanRepeat
    self._damageCanRepeatCalculator = SkillEffectCalc_DamageCanRepeat:New(world)
    ----@type SkillEffectCalc_DamageOnTargetCount
    self._calcDamageOnTargetCountCalc = SkillEffectCalc_DamageOnTargetCount:New(world)
    ---@type SkillEffectCalc_DynamicCenterDamage
    self._dynamicCenterDamageCalc = SkillEffectCalc_DynamicCenterDamage:New(world)

    ---通用技能效果计算器
    ---@type GeneralEffectCalculator
    self._generalEffectCalculator = GeneralEffectCalculator:New(world)
end

---为出战队伍里的每一个成员计算连锁技能伤害
---@param teamEntity Entity 主角Entity
---@param skillCastPos Vector2 连锁技的施法位置
function ChainSkillCalculator:DoCalculateChainSkill(teamEntity, skillCastPos)
    ---存放延迟击退的所有目标数据字典
    ---约定，每个人只会有一次击退，每次击退会打击N个目标
    ---key是petID，val是个Array，元素是SkillDelayHitBackEffectResult的
    local ntChainStart = NTChainSkillTurnStart:New(teamEntity)
    self._world:GetService("Trigger"):Notify(ntChainStart)

    ---@type LogicRoundTeamComponent
    local logicTeamCmpt = teamEntity:LogicRoundTeam()
    local petRoundTeam = logicTeamCmpt:GetPetRoundTeam()

    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()

    ---这个就是连线数
    local chainCount = self:_CalcChainPathRate(teamEntity)
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    local superGridNum = logicChainPathCmpt:GetSuperGridCountAtPathIndex(#chainPath)
    local poorGridNum = logicChainPathCmpt:GetPoorGridCountAtPathIndex(#chainPath)
    local chainPathPieceType = logicChainPathCmpt:GetLogicPieceType()

    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    local chainSkillCnt = 0

    local teamLeaderId = teamEntity:Team():GetTeamLeaderEntityID()
    ---计算每个出战的星灵的连锁技
    for petIndex = 1, #petRoundTeam do
        local skillHitbackResultDic = {}
        local petEntityID = petRoundTeam[petIndex]
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)
        if teamLeaderId ~= petEntityID or affixService:IsTeamLeaderCanAttack(teamEntity, chainPathPieceType) then
            local chainCountFix = petEntity:Attributes():GetAttribute("ChainSkillReleaseFix")
            local chainCountMul = petEntity:Attributes():GetAttribute("ChainSkillReleaseMul") or 0
            local finalChainRate = math.ceil((chainCount + chainCountFix) * (1 + chainCountMul))
            ---计算并应用 一个星灵的连锁技
            self:_CalcOnePetChainSkill(petEntity, skillCastPos, skillHitbackResultDic, finalChainRate, superGridNum, poorGridNum)

            ---检查施法者是否有连锁可以施放
            local ret = self:_RefreshPetChainSkillFlag(petEntity)
            if ret then
                chainSkillCnt = chainSkillCnt + 1
            end
        end
    end

    self._world:GetService("Trigger"):Notify(NTChainSkillTurnEnd:New(chainSkillCnt))
end

---计算连线率
---@param actorEntity Entity 身上挂有连线组件的星灵
---@return number 连线数
function ChainSkillCalculator:_CalcChainPathRate(teamEntity)
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainPath = logicChainPathCmpt:GetLogicChainPath()
    return logicChainPathCmpt:GetChainRateAtIndex(#chainPath)
end

---计算单个星灵连锁技
---@param petEntity Entity 施放连锁技的星灵
---@param skillHitbackResultDic Table 击退数据
---@param finalChainRate number 连线数
function ChainSkillCalculator:_CalcOnePetChainSkill(
    petEntity,
    castPos,
    skillHitbackResultDic,
    finalChainRate,
    superGridNum,
    poorGridNum)
    --region NTChainPathSelectTarget 连锁选目标之前
    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")
    local nt = NTChainPathSelectTarget:New()
    nt:SetNotifyEntity(petEntity)
    nt:SetChainCount(finalChainRate)
    sTrigger:Notify(nt)
    --endregion

    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = petEntity:SkillPetAttackData()
    ---@type SkillInfoComponent
    local skillInfoComponent = petEntity:SkillInfo()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local chainExtraFix = utilData:GetEntityBuffValue(petEntity, "ChangeExtraChainSkillReleaseFixForSkill")
    local chainSkillID, chainSkillStage = skillInfoComponent:GetChainSkillConfigID(finalChainRate, chainExtraFix)
    if chainSkillID <= 0 then
        --Log.error("_CalcOnePetChainSkill() failed! ChainSkillID=", chainSkillID)
        return --没有可施放的连锁技
    end
    petAttackDataCmpt:SetChainSkillID(chainSkillID)
    petAttackDataCmpt:SetCurChainSkillStage(chainSkillStage)
    petAttackDataCmpt:SetCurrentChainDamageRate(finalChainRate)
    petAttackDataCmpt:SetCurrentSuperGridNum(superGridNum)
    petAttackDataCmpt:SetCurrentPoorGridNum(poorGridNum)
    ---先清除原有的数据，再填充
    petAttackDataCmpt:ClearPetChainAttackData()

    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")
    ---此星灵连锁技可以施放几次
    ---@type BuffComponent
    local petBuffCmpt = petEntity:BuffComponent()
    local castChainSkillCount = petBuffCmpt:GetBuffValue("ChainSkillCount") or 1

    Log.debug(
        "CalcChainSkill CasterEntity:",
        petEntity:GetID(),
        "SkillID:",
        chainSkillID,
        " Count=",
        castChainSkillCount
    )

    ---连锁技可施放多次
    for idx = 1, castChainSkillCount do
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        local isFinalAttackBeforeSkill = battleService:IsFinalAttack()

        ---设置星灵攻击一定范围内的怪物 连锁技能增伤
        ---如果星灵有虚影连锁技能范围 与本体连锁技能范围 重叠增伤（小恶狗）  提前计算2次连锁技能范围  为目标添加标记 格子列表
        self:_CalcChainSkillScopeOverlap(petEntity, chainSkillID, castPos)
        self:_SaveChainSkillScope(petEntity, chainSkillID, castPos, finalChainRate)

        ---计算单次连锁技效果
        local targetIDList = self:_CalcSingleChainSkill(idx, petEntity, castPos, chainSkillID, skillHitbackResultDic)
        --Log.debug("_CalcOnePetChainSkill() targetIDList count=", #targetIDList)

        ---如果是第一次，需要处理全息投影的计算
        if idx == 1 then
            self:_ProjectionEntityCastSkill(petEntity, skillHitbackResultDic, idx)
        end

        ---指定其他实体在其他位置释放连锁技
        ---默认这个技能没有击退效果，不参与skillHitbackResultDic击退效果合并
        self:_AgentEntityCastSkill(idx, petEntity)

        ---计算并应用 一个星灵一次连锁技能的击退
        self:_CalcAndApplyChainSkillHitback(petEntity, castPos, skillHitbackResultDic, idx)

        --连锁技没有目标就没有表现，逻辑要保持一致
        if targetIDList and #targetIDList > 0 then
            ---每计算一次连锁技后，需要通知一次连锁技结束事件
            local nt = NTChainSkillAttackEnd:New(petEntity, targetIDList)
            nt:SetChainCount(finalChainRate)
            nt:SetChainSkillIndex(idx)
            nt:SetChainSkillId(chainSkillID)
            nt:SetChainSkillStage(chainSkillStage)
            sTrigger:Notify(nt)
            --所有逻辑通知和表现通知需一一对应
            if idx == 2 then
                sTrigger:Notify(NTSecondChainSkillAttackEnd:New(petEntity))
            end
        end
 
        sTrigger:Notify(NTSingleChainSkillAttackFinish:New(petEntity, idx))
        
        --- 以前是计算完3个连锁技统一计算击杀，计算最后一击。现在挪到每一个连锁技计算里去了
        -- ---每一次放完连锁技需要检查一次
        -- self:_HandleChainAttackDead(petEntity:GetID(), idx, chainSkillID)
        -- local isFinalAttack = battleService:IsFinalAttack()
        -- if (not isFinalAttackBeforeSkill) and isFinalAttack then
        --     local cRoutine = petEntity:SkillContext():GetResultContainer()
        --     cRoutine:SetFinalAttack(true)
        -- end

        ---@type SkillChainAttackData
        local attdt = petAttackDataCmpt:GetChainAttackData(idx)
        if attdt then
            local totalDmg = attdt:GetTotalDamage()
            ---连锁技数据埋点
            self._world:GetDataLogger():AddDataLog("OnChainSkillEnd", petEntity, chainSkillID, totalDmg)
        end
    end

    local ntEachPetChainSkillFinish = NTEachPetChainSkillFinish:New()
    ntEachPetChainSkillFinish:SetNotifyEntity(petEntity)
    ntEachPetChainSkillFinish:SetChainCount(finalChainRate)
    sTrigger:Notify(ntEachPetChainSkillFinish)
end

function ChainSkillCalculator:_SaveChainSkillScope(casterEntity, chainSkillID, castPos, finalChainRate)
    ---@type BuffComponent
    local petBuffCmpt = casterEntity:BuffComponent()
    local saveChainSkillID = petBuffCmpt:GetBuffValue("SavePetChainScope")
    if not saveChainSkillID then
        return
    end

    saveChainSkillID = chainSkillID

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, casterEntity)
    ---计算连锁技范围
    ---@type SkillScopeResult
    local scopeResultPet = self:CalcChainSkillScope(casterEntity, chainSkillID, castPos)

    ---计算范围内是否有目标，如果没有目标，不需要加连锁技攻击数据
    local targetListPet = self:_CalcTargetListInScopeResult(casterEntity, scopeResultPet)
    if #targetListPet <= 0 then
        return
    end

    -- local SavePetChainScope = {}
    -- --同一回合 极光时刻后的连线范围可能要小，使用大的范围
    -- local petChainScope = scopeResultPet:GetAttackRange()
    -- local curPos = casterEntity:GetGridPosition()

    -- for _, grid in pairs(petChainScope) do
    --     local posOffset = grid - curPos
    --     table.insert(SavePetChainScope, posOffset)
    -- end

    local levelRound = self._world:BattleStat():GetLevelTotalRoundCount()
    local levelRoundAndScopeRange = petBuffCmpt:GetBuffValue("LevelRoundAndScopeRange") or {}
    local lastChainSkillID = levelRoundAndScopeRange[levelRound] or 0
    if lastChainSkillID and lastChainSkillID > saveChainSkillID then
        saveChainSkillID = lastChainSkillID
    end
    levelRoundAndScopeRange[levelRound] = saveChainSkillID
    petBuffCmpt:SetBuffValue("SavePetChainScope", saveChainSkillID)
    petBuffCmpt:SetBuffValue("LevelRoundAndScopeRange", levelRoundAndScopeRange)

    local saveFinalChainRate = finalChainRate
    local levelRoundAndFinalChainRate = petBuffCmpt:GetBuffValue("LevelRoundAndFinalChainRate") or {}
    local lastFinalChainRate = levelRoundAndFinalChainRate[levelRound] or 0
    if lastFinalChainRate and lastFinalChainRate > saveFinalChainRate then
        saveFinalChainRate = lastFinalChainRate
    end
    levelRoundAndFinalChainRate[levelRound] = saveFinalChainRate
    petBuffCmpt:SetBuffValue("SaveFinalChainRate", saveFinalChainRate)
    petBuffCmpt:SetBuffValue("LevelRoundAndFinalChainRate", levelRoundAndFinalChainRate)
end

---如果星灵有虚影连锁技能范围 与本体连锁技能范围 重叠增伤（小恶狗）  提前计算2次连锁技能范围  为目标添加标记 格子列表
---@param casterEntity Entity 施法者
function ChainSkillCalculator:_CalcChainSkillScopeOverlap(casterEntity, chainSkillID, castPos)
    ---@type BuffComponent
    local petBuffCmpt = casterEntity:BuffComponent()
    local chainScopeOverlapChangeDamage = petBuffCmpt:GetBuffValue("ChainScopeOverlapChangeDamage")
    if not chainScopeOverlapChangeDamage then
        return
    end

    local scopeOverlapList = {}
    petBuffCmpt:SetBuffValue("ChainScopeOverlapPosList", scopeOverlapList)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, casterEntity)
    ---计算连锁技范围
    ---@type SkillScopeResult
    local scopeResultPet = self:CalcChainSkillScope(casterEntity, chainSkillID, castPos)

    ---计算范围内是否有目标，如果没有目标，不需要加连锁技攻击数据
    local targetListPet = self:_CalcTargetListInScopeResult(casterEntity, scopeResultPet)
    if #targetListPet <= 0 then
        return
    end

    ---虚影的范围
    ---@type Entity
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()

    local chainPathData = logicChainPathCmpt:GetLogicChainPath()
    ---全息投影的施法位置，是取连线的第一个点
    local castPosShadow = chainPathData[1]
    ---@type SkillScopeResult
    local scopeResultShadow = self:CalcChainSkillScope(casterEntity, chainSkillID, castPosShadow)
    local targetListShadow = self:_CalcTargetListInScopeResult(casterEntity, scopeResultPet)
    if #targetListShadow <= 0 then
        return
    end

    ---2次连锁 拥有相同的目标
    local hasSameTarget = false
    for _, targetEntityID in ipairs(targetListPet) do
        if table.intable(targetListShadow, targetEntityID) then
            hasSameTarget = true
            break
        end
    end

    if hasSameTarget == false then
        return
    end

    ---获取两次连锁 相同的范围
    local attackRangePet = scopeResultPet:GetAttackRange()
    local attackRangeShadow = scopeResultShadow:GetAttackRange()
    for _, pos in ipairs(attackRangePet) do
        if table.intable(attackRangeShadow, pos) then
            table.insert(scopeOverlapList, pos)
        end
    end

    petBuffCmpt:SetBuffValue("ChainScopeOverlapPosList", scopeOverlapList)
end

---计算单次连锁技，一个星灵可以有多次连锁技
---@param idx number 施放第几次技能索引
function ChainSkillCalculator:_CalcSingleChainSkill(idx, casterEntity, castPos, chainSkillID, skillHitbackResultDic)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, casterEntity)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardCmpt = boardEntity:Board()
    ---@type BuffLogicService
    local buffService = self._world:GetService("BuffLogic")
    if buffService:IsChainSkillUseChainScope(casterEntity) and not self._world:BattleStat():IsCastChainByDimensionDoor() then
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        ---@type LogicChainPathComponent
        local logicChainPathCmpt = teamEntity:LogicChainPath()
        local chainPath = logicChainPathCmpt:GetLogicChainPath()
        local chainPathPieceType = logicChainPathCmpt:GetLogicPieceType()
        boardCmpt:AddTmpPieceType(chainPath[1],PieceType.None)
        for i = 2, #chainPath do
            local pos = chainPath[i]
            boardCmpt:AddTmpPieceType(pos,chainPathPieceType)
        end
    end

    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")
    local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(casterEntity:GetID(), chainSkillID)
    local effectType191
    local effectType203
    for _, effect in ipairs(skillEffectArray) do
        if effect:GetEffectType() == SkillEffectType.DynamicCenterDamage then
            effectType191 = effect
        end
        if effect:GetEffectType() == SkillEffectType.DynamicScopeChainDamage then
            effectType203 = effect
        end
    end

    local scopeResult
    local targetList = {}

    ---191的中心范围是另算的
    if effectType191 then
        local calc191 = SkillEffectCalc_DynamicCenterDamage:New(self._world)
        targetList, scopeResult = calc191:SelectCenter(casterEntity, effectType191, castPos)
    elseif effectType203 then
        ---@type SkillEffectCalc_DynamicScopeChainDamage
        local calc203 = SkillEffectCalc_DynamicScopeChainDamage:New(self._world)
        scopeResult = calc203:CalcChainReplaceScope(casterEntity, effectType203)
        targetList = self:_CalcTargetListInScopeResult(casterEntity, scopeResult)
    else
        ---计算连锁技范围
        ---@type SkillScopeResult
        scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, castPos, casterEntity)
        boardCmpt:ClearTmpPieceType()
        ---计算范围内是否有目标，如果没有目标，不需要加连锁技攻击数据
        targetList = self:_CalcTargetListInScopeResult(casterEntity, scopeResult)
    end

    if #targetList <= 0 then
        return targetList
    end
    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")
    if idx == 2 then
        sTrigger:Notify(NTSecondChainSkillAttackStart:New(casterEntity))
    end

    ---添加一次连锁技数据
    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    petAttackDataCmpt:AddChainAttackData(idx)
    ---@type SkillChainAttackData
    local chainAttackData = petAttackDataCmpt:GetChainAttackData(idx)
    chainAttackData:SetScopeResult(scopeResult)
    petAttackDataCmpt:SetCurChainSkillIndex(idx)

    local scopeFilterParam = skillConfigData:GetScopeFilterParam()

    ---计算指定范围内目标的连锁技
    self:_CalcChainSkillInScopeResult(
        casterEntity,
        castPos,
        chainAttackData,
        targetList,
        skillHitbackResultDic,
        scopeFilterParam,
        idx
    )

    return targetList --给外面的buff通知用
end

---计算范围内的目标
---@param scopeResult SkillScopeResult
function ChainSkillCalculator:_CalcTargetListInScopeResult(casterEntity, scopeResult)
    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    local chainSkillID = petAttackDataCmpt:GetChainSkillID()
    local attackRange = scopeResult:GetAttackRange()

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, casterEntity)

    local skillTargetType = skillConfigData:GetSkillTargetType()

    ---先选技能目标
    local targetEntityIDArray =
        self._targetSelector:DoSelectSkillTarget(casterEntity, skillTargetType, scopeResult, chainSkillID)

    return targetEntityIDArray
end

---@param chainAttackData SkillChainAttackData
function ChainSkillCalculator:_CalcChainSkillInScopeResult(
    casterEntity,
    castPos,
    chainAttackData,
    targetList,
    skillHitbackResultDic,
    scopeFilterParam,
    idx,
    bAgentChainSkillUseCfgID
    )
    ---添加一次连锁技数据
    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    local chainSkillID = petAttackDataCmpt:GetChainSkillID()
    if bAgentChainSkillUseCfgID then
        chainSkillID = chainAttackData:GetSkillID()
    end
    local chainSkillStage = petAttackDataCmpt:GetCurChainSkillStage()
    local scopeResult = chainAttackData:GetScopeResult()

    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local isFinalAttackBeforeSkill = battleService:IsFinalAttack()

    ---将目标加到范围结果里
    self:_AddTargetToScopeResult(targetList, scopeResult, scopeFilterParam)

    ---每计算一次连锁技前，就要通知一次连锁技事件
    self:_NotifyChainAttackStart(casterEntity, chainAttackData, castPos, chainSkillID, chainSkillStage)

    ---计算并应用技能结果
    self:_CalcChainSkillResult(chainSkillID, chainAttackData, casterEntity, skillHitbackResultDic)

    ---每计算一次连锁技后，需要通知一次连锁技伤害结束事件
    self:_NotifyChainDamageEnd(casterEntity, chainAttackData)

    --这里为了区分是3个连锁技中的那个造成了最后一击
    ---每一次放完连锁技需要检查一次
    self:_HandleChainAttackDead(casterEntity:GetID(), idx, chainSkillID)
    local isFinalAttack = battleService:IsFinalAttack()
    if (not isFinalAttackBeforeSkill) and isFinalAttack then
        chainAttackData:SetFinalAttack(true)
    end
end

---@param scopeResult SkillScopeResult
---@param scopeFilterParam SkillScopeFilterParam
function ChainSkillCalculator:_AddTargetToScopeResult(targetEntityIDArray, scopeResult, scopeFilterParam)
    local attackRange = scopeResult:GetAttackRange()
    local targetSelectionMode = scopeFilterParam:GetTargetSelectionMode()
    local isTargetSelected = {}
    for _, gridPos in ipairs(attackRange) do
        for _, targetEntityID in ipairs(targetEntityIDArray) do
            ----这里看似有问题 其实是可以实现单体只打了一次的
            if (targetSelectionMode ~= SkillTargetSelectionMode.Entity) or (not isTargetSelected[targetEntityID]) then
                ---@type Entity
                local targetEntity = self._world:GetEntityByID(targetEntityID)
                if targetEntity then
                    ---@type GridLocationComponent
                    local gridLocationCmpt = targetEntity:GridLocation()
                    ---@type BodyAreaComponent
                    local bodyAreaCmpt = targetEntity:BodyArea()
                    local bodyAreaList = bodyAreaCmpt:GetArea()

                    for i, bodyArea in ipairs(bodyAreaList) do
                        local curBodyPos =
                            Vector2(gridLocationCmpt.Position.x + bodyArea.x, gridLocationCmpt.Position.y + bodyArea.y)
                        if curBodyPos == gridPos then
                            scopeResult:AddTargetIDAndPos(targetEntityID, gridPos)
                            isTargetSelected[targetEntityID] = true
                        end
                    end
                end
            end
        end
    end
end

---@param chainAttackData SkillChainAttackData
function ChainSkillCalculator:_NotifyChainAttackStart(
    casterEntity,
    chainAttackData,
    castPos,
    chainSkillId,
    chainSkillStage)
    local defenderList = {}
    local defendMonsterList = {}
    local attackPosList = {}

    ---@type SkillScopeResult
    local scopeResult = chainAttackData:GetScopeResult()
    ---@type SortedDictionary
    local dic = scopeResult:GetGridPosTargetIDDic()
    if dic == nil then
        return
    end

    for i = 1, dic:Size() do
        local pos, targetEntityID = dic:GetPairAt(i)
        defenderList[#defenderList + 1] = targetEntityID
        attackPosList[#attackPosList + 1] = pos

        local e = self._world:GetEntityByID(targetEntityID)
        if not e:HasTrapID() then --兼容黑拳赛
            table.insert(defendMonsterList, targetEntityID)
        end
    end

    if #defenderList <= 0 then
        return
    end

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")

    local notifyObj = NTChainSkillAttackStart:New(casterEntity, defenderList, castPos, attackPosList, defendMonsterList)
    notifyObj:SetChainSkillIndex(chainAttackData:GetChainSkillIndex())
    notifyObj:SetChainSkillId(chainSkillId)
    notifyObj:SetChainSkillStage(chainSkillStage)
    triggerSvc:Notify(notifyObj)

    local chainSkillAttackNotifyObj = NTChainSkillAttack:New(casterEntity, defenderList, castPos, attackPosList)
    triggerSvc:Notify(chainSkillAttackNotifyObj)
end

---通知连锁技伤害结束
---@param chainAttackData SkillChainAttackData
function ChainSkillCalculator:_NotifyChainDamageEnd(casterEntity, chainAttackData)
    local damageValue = 0
    local damageResArr = chainAttackData:GetEffectResultsAsArray(SkillEffectType.Damage)
    if damageResArr then
        for _, damageRes in ipairs(damageResArr) do
            damageValue = damageValue + damageRes:GetTotalDamage()
        end
    end

    self._world:GetService("Trigger"):Notify(NTChainSkillDamageEnd:New(casterEntity, damageValue))
end

---全息投影施法，也需要先选择目标，再施法
---@param casterEntity Entity 施法者
function ChainSkillCalculator:_ProjectionEntityCastSkill(casterEntity, skillHitbackResultDic, idx)
    ---@type BuffComponent
    local petBuffCmpt = casterEntity:BuffComponent()
    local buffInstance = petBuffCmpt:GetSingleBuffByBuffEffect(BuffEffectType.ShadowChainSKill)
    local buffInstancePro = petBuffCmpt:GetSingleBuffByBuffEffect(BuffEffectType.ShadowChainSKillPro)
    if buffInstance == nil and buffInstancePro == nil then
        return
    end

    if not buffInstance and buffInstancePro then
        buffInstance = buffInstancePro
    end

    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    local chainSkillID = petAttackDataCmpt:GetChainSkillID()

    ---@type ConfigService
    local configSvc = self._world:GetService("Config")

    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configSvc:GetSkillConfigData(chainSkillID, casterEntity)

    ---@type Entity
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()

    local chainPathData = logicChainPathCmpt:GetLogicChainPath()
    ---全息投影的施法位置，是取连线的第一个点
    local castPos = chainPathData[1]
    --如果虚影放的技能，需要重新计算子技能范围，取的是施法者当前的坐标，所以在计算前先设置施法者坐标到虚影位置。
    casterEntity:SetGridPosition(castPos)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type SkillScopeResult
    local scopeResult = self:CalcChainSkillScope(casterEntity, chainSkillID, castPos)
    local attackRange = scopeResult:GetAttackRange()
    local wholeRange = scopeResult:GetWholeGridRange()

    ---计算范围内是否有目标，如果没有目标，不需要加连锁技攻击数据
    local targetList = self:_CalcTargetListInScopeResult(casterEntity, scopeResult)
    if #targetList <= 0 then
        --还原施法者坐标
        casterEntity:SetGridPosition(teamEntity:GetGridPosition())
        return
    end

    local ShadowEntityID =petBuffCmpt:GetBuffValue("ShadowChainEntityID")
    local ShadowEntity = self._world:GetEntityByID(ShadowEntityID)
    petBuffCmpt:SetBuffValue("ShadowChainPos", castPos)
    ShadowEntity:SetGridPosition(castPos)

    self._world:EventDispatcher():Dispatch(GameEventType.DataBuffValue, casterEntity:GetID(), "ShadowChainPos", castPos)

    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    local damagePercent = petBuffCmpt:GetBuffValue("ShadowChainDamagePercent") or 1
    buffLogicSvc:ChangeSkillFinalParam(
        casterEntity,
        buffInstance:BuffSeq(),
        ModifySkillParamType.ChainSkill,
        damagePercent
    )

    --为每个攻击到的格子统计目标entity
    petAttackDataCmpt:AddChainShadowData(1)

    ---@type SkillChainAttackData
    local chainAttackData = petAttackDataCmpt:GetChainShadowData(1)
    chainAttackData:SetScopeResult(scopeResult)

    local scopeFilterParam = skillConfigData:GetScopeFilterParam()

    ---计算指定范围内目标的连锁技
    self:_CalcChainSkillInScopeResult(
        casterEntity,
        castPos,
        chainAttackData,
        targetList,
        skillHitbackResultDic,
        scopeFilterParam,
        idx
    )

    --还原施法者坐标
    casterEntity:SetGridPosition(teamEntity:GetGridPosition())

    buffLogicSvc:RemoveSkillFinalParam(
        casterEntity,
        buffInstance:BuffSeq(),
        ModifySkillParamType.ChainSkill,
        damagePercent,
        scopeFilterParam
    )
end

---指定实体目标，使用星灵属性，在其地点释放星灵连锁技
---@param casterEntity Entity 施法者
function ChainSkillCalculator:_AgentEntityCastSkill(idx, casterEntity)
    ---@type BuffComponent
    local petBuffCmpt = casterEntity:BuffComponent()
    local agentChainEntityID = petBuffCmpt:GetBuffValue("AgentChainEntityID")
    local agentChainEntity = self._world:GetEntityByID(agentChainEntityID)
    if not agentChainEntity then
        return
    end

    if agentChainEntity:HasDeadMark() then
        return
    end

    local chainCountMultiple = petBuffCmpt:GetBuffValue("AgentChainCountMultiple")
    local AgentChainSkillList = petBuffCmpt:GetBuffValue("AgentChainSkillList")
    local agentChainSkillUseCfgID = petBuffCmpt:GetBuffValue("AgentChainSkillUseCfgID") or 0

    --判断连线是否可以触发技能
    ---@type Entity
    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chain_path_data = logicChainPathCmpt:GetLogicChainPath()
    local chain_path_count = table.count(chain_path_data)
    --!!!注意，这里和星灵本体的连锁技触发数量不同，不计算ChainSkillReleaseFix连锁技修正
    local realChainCount = chain_path_count - 1
    if realChainCount == 0 then
        return
    end

    --机关技能不同于星灵
    local chainSkillID = 0
    for i = 1, #AgentChainSkillList do
        if realChainCount >= AgentChainSkillList[i].chainCount then
            chainSkillID = AgentChainSkillList[i].skill
            break
        end
    end

    if chainSkillID <= 0 then
        return
    end

    --计算连锁技范围 目标
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(chainSkillID, casterEntity)
    local castPos = agentChainEntity:GridLocation().Position
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = self:CalcChainSkillScope(casterEntity, chainSkillID, castPos)
    local attackRange = scopeResult:GetAttackRange()
    local wholeRange = scopeResult:GetWholeGridRange()

    local targetList = self:_CalcTargetListInScopeResult(casterEntity, scopeResult)
    --范围内没有目标也可以释放连锁技
    -- if #targetList <= 0 then
    --     return
    -- end

    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    --为每个攻击到的格子统计目标entity
    petAttackDataCmpt:AddChainAgentData(idx)

    ---@type SkillChainAttackData
    local chainAttackData = petAttackDataCmpt:GetChainAgentData(idx)
    chainAttackData:SetScopeResult(scopeResult)
    chainAttackData:SetSkillID(chainSkillID)

    local scopeFilterParam = skillConfigData:GetScopeFilterParam()

    local bAgentChainSkillUseCfgID = (agentChainSkillUseCfgID == 1)
    ---计算指定范围内目标的连锁技
    self:_CalcChainSkillInScopeResult(casterEntity, castPos, chainAttackData, targetList, {}, scopeFilterParam, idx,bAgentChainSkillUseCfgID)
end

---@param attdata SkillChainAttackData
---@param skillHitbackResultDic Dic key是施法者的entityID,value是击退效果数组
function ChainSkillCalculator:_CalcChainSkillResult(chainSkillID, attdata, petEntity, skillHitbackResultDic)
    local petEntityID = petEntity:GetID()
    ---@type SkillEffectCalcService
    local effectCalcService = self._world:GetService("SkillEffectCalc")
    ---@type SkillScopeResult
    local scopeResult = attdata:GetScopeResult()
    ---@type SortedDictionary
    local dic = scopeResult:GetGridPosTargetIDDic()
    if not dic then
        return
    end

    --和主动技流程一样设置SkillEffectResultContainer
    ---@type SkillEffectResultContainer
    local skillResult = petEntity:SkillContext():GetResultContainer()
    skillResult:Clear()
    skillResult:SetSkillID(chainSkillID)
    scopeResult:ClearTargetIDs()
    ---先选技能目标
    ---@type ConfigService
    local configService = self._configService
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, petEntity)
    local targetType = skillConfigData:GetSkillTargetType()
    local targetEntityIDArray =
        self._targetSelector:DoSelectSkillTarget(petEntity, targetType, scopeResult, chainSkillID)
    if targetEntityIDArray then
        for _, v in ipairs(targetEntityIDArray) do
            local targetEntity = self._world:GetEntityByID(v)
            local pos = nil
            if targetEntity:GridLocation() then
                pos = targetEntity:GridLocation().Position
            else
                pos = Vector2(0, 0) ---目前棋盘还没有grid location
            end
            scopeResult:AddTargetIDAndPos(v, pos)
        end
    end
    skillResult:SetScopeResult(scopeResult)
    --

    local attackPos = scopeResult:GetCenterPos()
    local attackRange = scopeResult:GetAttackRange()
    --计算技能效果
    local logger = self._world:GetMatchLogger()
    logger:BeginSkill(petEntityID, attackPos, chainSkillID, attackRange)
    local skillEffectResultArray =
        self:_CalcAndApplyChainSkillEffect(attdata, skillHitbackResultDic, petEntityID, chainSkillID, attackPos)
    logger:EndSkill(petEntityID)
end

---计算并应用连锁技的技能效果
---@param chainAttackData SkillChainAttackData
---@param skillHitbackResultDic Dic key是施法者的entityID,value是击退效果数组
function ChainSkillCalculator:_CalcAndApplyChainSkillEffect(
    chainAttackData,
    skillHitbackResultDic,
    petEntityID,
    chainSkillID,
    attackPos)
    ---@type SkillEffectCalcService
    local effectCalcService = self._world:GetService("SkillEffectCalc")
    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")

    local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(petEntityID, chainSkillID)
    for skillEffectIndex = 1, #skillEffectArray do
        ----@type SkillEffectParamBase
        local skillEffectParam = skillEffectArray[skillEffectIndex]

        if skillEffectParam:GetEffectType() == SkillEffectType.RandDamageSameHalf then
            --计算是否有子范围(没有取默认)
            ---@type SkillScopeResult
            local scopeResult =
                self:_CalcSkillEffectChildScope(chainAttackData, skillEffectParam, petEntityID, chainSkillID, attackPos)
            self:_CalcAndApplyChainSkillEffect_RandDamageSameHalf(
                chainAttackData,
                skillHitbackResultDic,
                petEntityID,
                chainSkillID,
                attackPos,
                skillEffectParam,
                scopeResult
            )
        elseif skillEffectParam:GetEffectType() == SkillEffectType.SplashPreDamage then
            --计算是否有子范围(没有取默认)
            ---@type SkillScopeResult
            local scopeResult =
                self:_CalcSkillEffectChildScope(chainAttackData, skillEffectParam, petEntityID, chainSkillID, attackPos)
            --对SkillEffectType.RandDamageSameHalf 随机分配伤害追加的溅射 对每个伤害结果位置计算范围
            self:_CalcAndApplyChainSkillEffect_SplashPreDamage(
                chainAttackData,
                skillHitbackResultDic,
                petEntityID,
                chainSkillID,
                attackPos,
                skillEffectParam,
                scopeResult
            )
        elseif skillEffectParam:GetEffectType() == SkillEffectType.DamageTargetCanRepeat then
            --计算是否有子范围(没有取默认)
            ---@type SkillScopeResult
            local scopeResult =
                self:_CalcSkillEffectChildScope(chainAttackData, skillEffectParam, petEntityID, chainSkillID, attackPos)
            local casterEntity = self._world:GetEntityByID(petEntityID)
            local results = self._damageCanRepeatCalculator:CalculateEffect(casterEntity, skillEffectParam, chainSkillID)
            --这个结构用在了_OnApplyChainSkillEffectResult内部，但实际上只有casterEntityID有用
            local skillEffectCalcParam = SkillEffectCalcParam:New(
                    petEntityID,
                    {},
                    skillEffectParam,
                    chainSkillID,
                    scopeResult:GetAttackRange(),
                    attackPos
            )
            for _, result in ipairs(results) do
                result:SetSkillEffectScopeResult(scopeResult)
                self:_OnApplyChainSkillEffectResult(skillEffectCalcParam, result, chainAttackData, skillHitbackResultDic)
            end
        elseif skillEffectParam:GetEffectType() == SkillEffectType.DamageOnTargetCount then
            --计算是否有子范围(没有取默认)
            ---@type SkillScopeResult
            local scopeResult =
                self:_CalcSkillEffectChildScope(chainAttackData, skillEffectParam, petEntityID, chainSkillID, attackPos)
            self:_CalcAndApplyChainSkillEffect_DamageOnTargetCount(
                chainAttackData,
                skillHitbackResultDic,
                petEntityID,
                chainSkillID,
                attackPos,
                skillEffectParam,
                scopeResult
            )
        elseif skillEffectParam:GetEffectType() == SkillEffectType.DynamicCenterDamage then
            local scopeResult = self:_CalcSkillEffectChildScope(chainAttackData, skillEffectParam, petEntityID, chainSkillID, attackPos)
            self:_CalcAndApplyChainSkillEffect_DynamicCenterDamage(
                    chainAttackData,
                    skillHitbackResultDic,
                    petEntityID,
                    chainSkillID,
                    attackPos,
                    skillEffectParam,
                    scopeResult
            )
        else
            local casterEntity = self._world:GetEntityByID(petEntityID)
            ---技能配置数据
            ---@type SkillConfigData
            local skillConfigData = self._configService:GetSkillConfigData(chainSkillID, casterEntity)
            local scopeFilterParam = skillConfigData:GetScopeFilterParam()
            ---@type SkillEffectType
            local skillEffectType = skillEffectParam:GetEffectType()
            local effectScopeFilterParam = skillEffectParam:GetScopeFilterParam()
            local finalScopeFilterParam =
                effectScopeFilterParam:IsDefault() and scopeFilterParam or effectScopeFilterParam
            local petEntity = self._world:GetEntityByID(petEntityID)

            --计算结果
            local resultArray =
                self._generalEffectCalculator:DoGeneralEffectCalc(petEntity, skillEffectParam, finalScopeFilterParam)

            --应用连锁技的技能结果
            for _, result in ipairs(resultArray) do
                ---@type SkillScopeResult
                local scopeResult = result:GetSkillEffectScopeResult()
                local targetIDs = scopeResult:GetTargetIDs()

                local skillEffectCalcParam =
                    SkillEffectCalcParam:New(
                    petEntityID,
                    targetIDs,
                    skillEffectParam,
                    chainSkillID,
                    scopeResult:GetAttackRange(),
                    attackPos
                )

                self:_OnApplyChainSkillEffectResult(
                    skillEffectCalcParam,
                    result,
                    chainAttackData,
                    skillHitbackResultDic
                )
            end
        end
    end

    --计算完整个技能过程后重置SkillContext
    effectCalcService:ResetSkillContext(petEntityID)
end
---特殊处理的技能效果 SkillEffectType.RandDamageSameHalf
---@param chainAttackData SkillChainAttackData
---@param skillHitbackResultDic Dic key是施法者的entityID,value是击退效果数组
function ChainSkillCalculator:_CalcAndApplyChainSkillEffect_RandDamageSameHalf(
    chainAttackData,
    skillHitbackResultDic,
    petEntityID,
    chainSkillID,
    attackPos,
    skillEffectParam,
    scopeResult)
    local targetIDs = scopeResult:GetTargetIDs()
    local skillEffectCalcParam =
        SkillEffectCalcParam:New(
        petEntityID,
        targetIDs,
        skillEffectParam,
        chainSkillID,
        scopeResult:GetAttackRange(),
        attackPos
    )
    --计算技能结果
    local skillResult = self._calcRandDamageSameHalfCalc:DoSkillEffectCalculator(skillEffectCalcParam)
    --这段代码来自SkillEffectCalcRandDamageSameHalf:DoSkillEffectCalculator
    --因为维克的需求把这个效果放到了主动技内，这段代码会让result被添加两次
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    for _, v in ipairs(skillResult) do
        skillEffectResultContainer:AddEffectResult(v)
    end
    for _, result in ipairs(skillResult) do
        --技能结果设置技能范围数据，表现要取
        result:SetSkillEffectScopeResult(scopeResult)

        --应用连锁技的技能结果
        self:_OnApplyChainSkillEffectResult(skillEffectCalcParam, result, chainAttackData, skillHitbackResultDic)
    end
end
---特殊处理的技能效果 SkillEffectType.SplashPreDamage
---@param chainAttackData SkillChainAttackData
---@param skillHitbackResultDic Dic key是施法者的entityID,value是击退效果数组
function ChainSkillCalculator:_CalcAndApplyChainSkillEffect_SplashPreDamage(
    chainAttackData,
    skillHitbackResultDic,
    petEntityID,
    chainSkillID,
    attackPos,
    skillEffectParam,
    scopeResult)
    local targetIDs = scopeResult:GetTargetIDs()
    local skillEffectCalcParam =
        SkillEffectCalcParam:New(
        petEntityID,
        targetIDs,
        skillEffectParam,
        chainSkillID,
        scopeResult:GetAttackRange(),
        attackPos
    )
    --计算技能结果
    local skillResult = self._calcSplashPreDamageCalc:DoSkillEffectCalculator(skillEffectCalcParam)

    for _, result in ipairs(skillResult) do
        --技能结果设置技能范围数据，表现要取
        result:SetSkillEffectScopeResult(scopeResult)

        --应用连锁技的技能结果
        self:_OnApplyChainSkillEffectResult(skillEffectCalcParam, result, chainAttackData, skillHitbackResultDic)
    end
end

---计算是否有子范围
---@param chainAttackData SkillChainAttackData
function ChainSkillCalculator:_CalcSkillEffectChildScope(
    chainAttackData,
    skillEffectParam,
    petEntityID,
    chainSkillID,
    attackPos)
    ---@type SkillScopeType
    local scopeType = skillEffectParam:GetSkillEffectScopeType()
    --没有配置子技能范围
    if not scopeType then
        ---@type SkillScopeResult
        local scopeResult = chainAttackData:GetScopeResult()
        return scopeResult
    end

    local attacker = self._world:GetEntityByID(petEntityID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillEffectScopeResult(skillEffectParam, attackPos, attacker)
    ---取出技能自己的目标类型
    ---@type SkillTargetType
    local skillEffectTargetType = skillEffectParam:GetSkillEffectTargetType()
    ---@type SkillScopeFilterParam
    local filterParam = skillEffectParam:GetScopeFilterParam()
    local skillEffectTargetTypeParam = skillEffectParam:GetSkillEffectTargetTypeParam()
    local targetSelectionMode = filterParam:GetTargetSelectionMode()
    ---只有计算技能的目标时传SkillID,计算技能效果的子范围不要穿SkillID
    local targetIDList =
        utilScopeSvc:SelectSkillTarget(attacker, skillEffectTargetType, scopeResult, nil, skillEffectTargetTypeParam)
    -- skillEffectCalcParam:SetTargetEntityIDs(targetIDList)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, casterEntity)
    local scopeFilterParam = skillConfigData:GetScopeFilterParam()

    ---将目标加到范围结果里
    self:_AddTargetToScopeResult(targetIDList, scopeResult, scopeFilterParam)

    return scopeResult
end

---应用连锁技的技能结果
---@param skillEffectCalcParam SkillEffectCalcParam
---@param skillResult SkillEffectResultBase
---@param chainAttackData SkillChainAttackData
function ChainSkillCalculator:_OnApplyChainSkillEffectResult(
    skillEffectCalcParam,
    skillResult,
    chainAttackData,
    skillHitbackResultDic)
    local petEntityID = skillEffectCalcParam.casterEntityID
    local petEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local chainIndex = chainAttackData:GetChainSkillIndex()
    local skillEffectType = skillResult:GetEffectType()

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    --连锁技的击退用的是 DelayHitBackEffectResult 后面转化成HitBackEffectResult 再加进EffectResult
    if skillEffectType ~= SkillEffectType.HitBack then
        chainAttackData:AddEffectResult(skillResult)
    end

    local skillEffectType = skillResult:GetEffectType()

    if (skillEffectType == SkillEffectType.Damage) or (skillEffectType == SkillEffectType.DamageTargetCanRepeat) then
        ---@type SkillDamageEffectResult
        local skillDamageEffectResult = skillResult
        local castDamage = skillDamageEffectResult:GetTotalDamage()
        local damageInfoArray = skillDamageEffectResult:GetDamageInfoArray()

        if not damageInfoArray or table.count(damageInfoArray) == 0 then
            return
        end

        --二次连锁修改最终伤害
        if chainIndex > 1 then
            local rate = petEntity:BuffComponent():GetBuffValue("DoubleChainRate") or 1
            skillDamageEffectResult:SetTotalDamage(castDamage * rate)
        end
        for _, v in ipairs(damageInfoArray) do
            local targetEntityId = v:GetTargetEntityID()
            if targetEntityId then
                if chainIndex > 1 then
                    local val = v:GetDamageValue()
                    local rate = petEntity:BuffComponent():GetBuffValue("DoubleChainRate") or 1
                    val = math.floor(val * rate) --防止出现小数，而飘字没有小数点
                    if val < 1 then
                        val = 1
                    end
                    v:SetDamageValue(val)
                end

                v:SetAttackerEntityID(petEntity:GetID())

                local targetEntity = self._world:GetEntityByID(targetEntityId)
                ---机关死亡处理
                trapServiceLogic:AddTrapDeadMark(targetEntity)
            end
        end
    elseif skillEffectType == SkillEffectType.SplashDamage then
        ---@type SkillEffectSplashDamageResult
        local splashResult = skillResult
        ---@type SkillDamageEffectResult[]
        local damageResults = splashResult:GetDamageResults()
        for _, damageResult in ipairs(damageResults) do
            local tDamageInfo = damageResult:GetDamageInfoArray()
            for __, damageInfo in ipairs(tDamageInfo) do
                damageInfo:SetAttackerEntityID(petEntity:GetID())
                local targetEntityId = damageInfo:GetTargetEntityID()
                local targetEntity = self._world:GetEntityByID(targetEntityId)
                if targetEntity then
                    trapServiceLogic:AddTrapDeadMark(targetEntity)
                end
            end
        end
    elseif skillEffectType == SkillEffectType.HitBack then
        ---@type SkillDelayHitBackEffectResult
        local delayHitbackEffectRes = skillResult
        local petHasAttack = table.iskey(skillHitbackResultDic, petEntityID)
        --施法星灵
        if petHasAttack == true then
            local hitbackResArray = skillHitbackResultDic[petEntityID]
            hitbackResArray[#hitbackResArray + 1] = delayHitbackEffectRes
        else
            local hitbackResArray = {}
            hitbackResArray[#hitbackResArray + 1] = delayHitbackEffectRes
            skillHitbackResultDic[petEntityID] = hitbackResArray
        end

        ---临时做法，给击退的炸弹，写一个已选标记，后续的星灵连锁技不应该再选
        local hitbackTargetID = delayHitbackEffectRes:GetTargetID()
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(hitbackTargetID)
        if targetEntity:HasTrap() then
            ---@type TrapComponent
            local trapCmpt = targetEntity:Trap()
            if trapCmpt:GetTrapType() == TrapType.BombByHitBack then
                trapCmpt:SetBombSelected(true)
            end
        end
    elseif skillEffectType == SkillEffectType.AddBlood then
        ----@type SkillEffectResult_AddBlood
        local skillAddBloodEffectResult = skillResult
        --二次连锁修改最终加血
        if chainIndex > 1 then
            local addblood = skillAddBloodEffectResult:GetAddValue()
            local rate = petEntity:BuffComponent():GetBuffValue("DoubleChainRate") or 1
            addblood = addblood * rate
            skillAddBloodEffectResult:SetAddValue(addblood)
        end

        --使用统一的结果应用
        self._skillEffectLogicExecutor:EachApplyAddBlood(petEntity, skillAddBloodEffectResult, SkillType.Chain)
    elseif skillEffectType == SkillEffectType.ChangeBuffLayer then
        ---@type BuffLogicService
        local buffLogicService = self._world:GetService("BuffLogic")
        ----@type SkillEffectResultChangeBuffLayer
        local result = skillResult
        local entityID = result:GetEntityID()
        local entity = self._world:GetEntityByID(entityID)
        local buffEffectType = result:GetTargetBuffEffectType()
        local layerCount = result:GetLayer()

        buffLogicService:SetBuffLayer(entity, buffEffectType, layerCount)

        if result:GetIsUnload() and layerCount == 0 then
            local targetBuff = entity:BuffComponent():GetSingleBuffByBuffEffect(buffEffectType)
            if targetBuff then
                targetBuff:Unload(NTBuffUnload:New())
            end
        end
    elseif skillEffectType == SkillEffectType.MoveTrap then
        ----@type SkillEffectResultMoveTrap
        local result = skillResult
        local entityID = result:GetEntityID()
        local entity = self._world:GetEntityByID(entityID)
        local posOld = result:GetPosOld()
        local posNew = result:GetPosNew()

        entity:SetGridLocation(posNew)

        ---@type BoardServiceLogic
        local sBoard = self._world:GetService("BoardLogic")
        sBoard:UpdateEntityBlockFlag(entity, posOld, posNew)
    elseif skillEffectType == SkillEffectType.EachTrapAddBlood then
        ----@type SkillEffectResultEachTrapAddBlood
        local skillAddBloodEffectResult = skillResult
        --使用统一的结果应用
        self._skillEffectLogicExecutor:EachApplyAddBlood(petEntity, skillAddBloodEffectResult, SkillType.Chain)
    elseif skillEffectType == SkillEffectType.DestroyTrap then
        ----@type SkillEffectDestroyTrapResult
        local skillDestroyTrapEffectResult = {}
        table.insert(skillDestroyTrapEffectResult,skillResult)
        --使用统一的结果应用
        self._skillEffectLogicExecutor:_ApplyDestroyTrap(petEntity,skillEffectCalcParam:GetSkillEffectParam(), skillDestroyTrapEffectResult)
    elseif skillEffectType == SkillEffectType.SummonTrap then
        ----@type SkillEffectDestroyTrapResult
        local t = {}
        table.insert(t,skillResult)
        --使用统一的结果应用
        self._skillEffectLogicExecutor:_ApplySummonTrap(petEntity,skillEffectCalcParam:GetSkillEffectParam(), t)
    elseif skillEffectType == SkillEffectType.LevelTrapUpLevel then
        local t = {}
        table.insert(t,skillResult)
        --使用统一的结果应用
        self._skillEffectLogicExecutor:_ApplyLevelTrapUpLevel(petEntity,skillEffectCalcParam:GetSkillEffectParam(), t)
    else
        self._skillEffectLogicExecutor:ApplySkillEffect(petEntity,skillEffectCalcParam:GetSkillEffectParam(),{skillResult})
        Log.error("_OnApplyChainSkillEffectResult unexcept skill effect: ",skillEffectType)
    end
end

function ChainSkillCalculator:_SetEffectResultScopeResult(skillEffectResultArray, scopeResult)
    if not skillEffectResultArray then
        return
    end
    for _, skillEffectResult in ipairs(skillEffectResultArray) do
        skillEffectResult:SetSkillEffectScopeResult(scopeResult)
    end
end

---@param skillCastPos Vector2 技能实际的施法位置
function ChainSkillCalculator:_CalcSkillDelayHitback(skillCastPos, skillHitbackResultDic)
    ---统计被击退的目标 按被击目标
    local hitbackVictimDic = {}
    for _, v in pairs(skillHitbackResultDic) do --不能改ipairs
        for _, arrayElement in ipairs(v) do
            ---@type SkillDelayHitBackEffectResult
            local delayHitbackEffectRes = arrayElement
            local victimEntityID = delayHitbackEffectRes:GetTargetID()
            ---@type Entity
            local victimEntity = self._world:GetEntityByID(victimEntityID)
            if victimEntity ~= nil and not victimEntity:HasDeadMark() then
                ---没有死亡的目标才会进入结算队列
                local hasVictim = table.iskey(hitbackVictimDic, victimEntityID)
                if hasVictim == true then
                    local hitbackArray = hitbackVictimDic[victimEntityID]
                    hitbackArray[#hitbackArray + 1] = delayHitbackEffectRes
                else
                    local hitbackArray = {}
                    hitbackArray[#hitbackArray + 1] = delayHitbackEffectRes
                    hitbackVictimDic[victimEntityID] = hitbackArray
                end
            end
        end
    end

    for targetID, targetHitBackResult in pairs(hitbackVictimDic) do --不能改ipairs
        --受击坐标与施法者最小的距离
        local minDistance = 99
        --计算几个击退里距离最短的
        for _, hitBackResult in ipairs(targetHitBackResult) do
            --被击者与施法者的距离
            local targetToCasterDistance = hitBackResult:GetAttackDistance()
            if hitBackResult:GetAttackDistance() < minDistance then
                minDistance = targetToCasterDistance
            end
        end

        --不是最短距离的排除出击退结果
        local tmpResult = {}
        for _, hitBackResult in ipairs(targetHitBackResult) do
            --被击者与施法者的距离
            local targetToCasterDistance = hitBackResult:GetAttackDistance()
            if targetToCasterDistance == minDistance then
                table.insert(tmpResult, hitBackResult)
            end
        end

        hitbackVictimDic[targetID] = tmpResult
    end

    local victimIDArray = table.keys(hitbackVictimDic)
    local hitbackResultDic = {}
    for _, victimEntityID in ipairs(victimIDArray) do
        local hitbackArray = hitbackVictimDic[victimEntityID]
        ---@type SkillHitBackEffectResult
        local hitbackRes = self:_CalcOneActorHitback(victimEntityID, hitbackArray)
        hitbackResultDic[victimEntityID] = hitbackRes
    end

    return hitbackResultDic
end

---@param victimEntityID 被击退者的ID
---@param hitbackArray 被击退者的击退数组
---@return SkillHitBackEffectResult
function ChainSkillCalculator:_CalcOneActorHitback(victimEntityID, hitbackArray)
    ---找出最大的击退距离
    local maxDistance = 0
    for _, v in ipairs(hitbackArray) do
        ---@type SkillDelayHitBackEffectResult
        local delayHitbackEffectRes = v
        local hitbackDis = delayHitbackEffectRes:GetHitbackDistance()
        if hitbackDis > maxDistance then
            maxDistance = hitbackDis
        end
    end

    ---最大击退距离有几个
    local maxPowerHitbackArray = {}
    for _, v in ipairs(hitbackArray) do
        ---@type SkillDelayHitBackEffectResult
        local delayHitbackEffectRes = v
        local hitbackDis = delayHitbackEffectRes:GetHitbackDistance()
        if hitbackDis == maxDistance then
            maxPowerHitbackArray[#maxPowerHitbackArray + 1] = delayHitbackEffectRes
        end
    end

    local hitbackCalcRes = nil
    ---@type SkillEffectCalcService
    local effectCalcService = self._world:GetService("SkillEffectCalc")
    ---@type SkillDelayHitBackEffectResult
    local delayHitbackResult = maxPowerHitbackArray[1]
    local casterEntityID = delayHitbackResult:GetCasterEntityID()
    ---@type Entity 提取攻击者数据
    local attacker = self._world:GetEntityByID(casterEntityID)
    local attackerBodyArea = attacker:BodyArea()

    local victimEntityID = delayHitbackResult:GetTargetID()
    local dirType = delayHitbackResult:GetHitbackDirType()
    local pullType = HitBackType.PushAway
    local hitbackDis = delayHitbackResult:GetHitbackDistance()
    --计算后的施法者坐标  如果本体击退和虚影击退叠加  这个坐标就既不是本体也不是虚影的坐标
    local skillCastPos = delayHitbackResult:GetCasterPos()

    local orderArray = {}
    if #maxPowerHitbackArray > 1 then
        for targetID, hitBackResult in ipairs(maxPowerHitbackArray) do
            ---处理叠加
            ---按照顺时针方向整理击退，并过滤掉非四方向的击退
            ---@type SkillDelayHitBackEffectResult
            local upRes = self:_FindHitbackByDir(hitBackResult:GetCasterPos(), HitBackDirectionType.Up, {hitBackResult})
            if upRes ~= nil then
                orderArray[#orderArray + 1] = upRes
            end
            local rightRes =
                self:_FindHitbackByDir(hitBackResult:GetCasterPos(), HitBackDirectionType.Right, {hitBackResult})
            if rightRes ~= nil then
                orderArray[#orderArray + 1] = rightRes
            end
            local downRes =
                self:_FindHitbackByDir(hitBackResult:GetCasterPos(), HitBackDirectionType.Down, {hitBackResult})
            if downRes ~= nil then
                orderArray[#orderArray + 1] = downRes
            end
            local leftRes =
                self:_FindHitbackByDir(hitBackResult:GetCasterPos(), HitBackDirectionType.Left, {hitBackResult})
            if leftRes ~= nil then
                orderArray[#orderArray + 1] = leftRes
            end
        end

        local orderArraySize = #orderArray
        if orderArraySize > 1 then
            ---取出前两个
            local firstDirType = orderArray[1]:GetHitbackDirType()
            local secondDirType = orderArray[2]:GetHitbackDirType()
            --重置击退方向
            dirType = HitBackDirectionTypeHelper.OverlapHitbackDir(firstDirType, secondDirType)

            local bodyArea = orderArray[1]:GetTargetBodyArea():GetArea()
            if #bodyArea > 1 then
                local dirEight = HitBackDirectionTypeHelper.ConvertDirTypeToVectorEight(dirType)
                local targetLocationCenter = orderArray[1]:GetTargetLocationCenter()
                local hitBackPos =
                    Vector2(
                    math.ceil(targetLocationCenter.x - dirEight.x / 2),
                    math.ceil(targetLocationCenter.y - dirEight.y / 2)
                )

                skillCastPos = hitBackPos - dirEight
            end
        elseif orderArraySize == 1 then
            dirType = orderArray[1]:GetHitbackDirType()
            skillCastPos = orderArray[1]:GetCasterPos()
        elseif orderArraySize == 0 then
            dirType = maxPowerHitbackArray[1]:GetHitbackDirType()
            skillCastPos = maxPowerHitbackArray[1]:GetCasterPos()
        end
    end

    local calcType = HitBackCalcType.Delay
    hitbackCalcRes =
        effectCalcService:CalcHitbackEffectResult(
        skillCastPos,
        Vector2.zero,
        attackerBodyArea,
        victimEntityID,
        dirType,
        pullType,
        hitbackDis,
        calcType,
        false,
        false,
        attacker
    )

    return hitbackCalcRes
end

---@param skillCastPos Vector2
---@param dirTypeParam HitBackDirectionType
function ChainSkillCalculator:_FindHitbackByDir(skillCastPos, dirTypeParam, maxPowerHitbackArray)
    for _, v in ipairs(maxPowerHitbackArray) do
        ---@type SkillDelayHitBackEffectResult
        local hitbackRes = v
        local curDir = hitbackRes:GetHitbackDirType()
        --提取被击者的受击方向
        local victimPos = hitbackRes:GetGridPos()
        local victimDir = Vector2.Normalize(victimPos - skillCastPos)
        local victimDirType = nil

        if curDir == dirTypeParam then
            return hitbackRes
        elseif curDir == HitBackDirectionType.EightDir then
            if victimDir.x == 0 then
                if victimDir.y > 0 then
                    victimDirType = HitBackDirectionType.Up
                elseif victimDir.y < 0 then
                    victimDirType = HitBackDirectionType.Down
                end
            elseif victimDir.y == 0 then
                if victimDir.x > 0 then
                    victimDirType = HitBackDirectionType.Right
                elseif victimDir.x < 0 then
                    victimDirType = HitBackDirectionType.Left
                end
            end

            if victimDirType ~= nil and victimDirType == dirTypeParam then
                hitbackRes:SetHitbackDirType(victimDirType)
                return hitbackRes
            end
        elseif curDir == HitBackDirectionType.LeftRight then
            if skillCastPos.x > victimPos.x then
                victimDirType = HitBackDirectionType.Left
            else
                victimDirType = HitBackDirectionType.Right
            end
            if victimDirType ~= nil and victimDirType == dirTypeParam then
                hitbackRes:SetHitbackDirType(victimDirType)
                return hitbackRes
            end
        elseif curDir == HitBackDirectionType.UpDown then
            if skillCastPos.y > victimPos.y then
                victimDirType = HitBackDirectionType.Down
            else
                victimDirType = HitBackDirectionType.Up
            end
            if victimDirType ~= nil and victimDirType == dirTypeParam then
                hitbackRes:SetHitbackDirType(victimDirType)
                return hitbackRes
            end
        end
    end

    return nil
end

---从连锁技攻击数据里，移除已经死亡的目标
---@param removeStartIndex number 移除开始的索引
---@param chainAttackDataList SkillChainAttackData[] 攻击数组
function ChainSkillCalculator:_RemoveDeadTargetFromChainAttackData(removeStartIndex, chainAttackDataList)
    for index = removeStartIndex, #chainAttackDataList do
        ---@type SkillChainAttackData
        local chainAttackData = chainAttackDataList[index]

        local deadTargetPosList = {}
        ---@type SkillScopeResult
        local scopeResult = chainAttackData:GetScopeResult()
        ---@type SortedDictionary
        local targetDic = scopeResult:GetGridPosTargetIDDic()
        if targetDic ~= nil then
            ---遍历所有目标
            for i = 1, targetDic:Size() do
                local pos, targetEntityID = targetDic:GetPairAt(i)
                ---@type Entity
                local defenderEntity = self._world:GetEntityByID(targetEntityID)
                if defenderEntity ~= nil and defenderEntity:HasAttributes() then
                    ---血量小于0，需要移除
                    local curHp = defenderEntity:Attributes():GetCurrentHP()
                    if curHp ~= nil then
                        if curHp <= 0 then
                            table.insert(deadTargetPosList, pos)
                        end
                    else
                        if defenderEntity:HasTrap() then
                            ---@type TrapComponent
                            local trapCmpt = defenderEntity:Trap()
                            if trapCmpt:GetTrapType() == TrapType.BombByHitBack then
                                local hasSelected = trapCmpt:IsBombSelected()
                                if hasSelected then
                                    ---已经被选的炸弹，不能作为后续连锁技的目标
                                    table.insert(deadTargetPosList, pos)
                                end
                            end
                        end
                    end
                else
                    ---找不到目标，需要移除
                    table.insert(deadTargetPosList, pos)
                end
            end
        end

        for _, v in ipairs(deadTargetPosList) do
            scopeResult:RemoveTargetIDByPos(v)
        end
    end
end

---刷新是否能施放连锁技
---@param petEntity Entity
function ChainSkillCalculator:_RefreshPetChainSkillFlag(petEntity)
    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = petEntity:SkillPetAttackData()
    petAttackDataCmpt:SetCastChainSkill(false)

    local chainAttackData = petAttackDataCmpt:GetChainAttackData()

    --recordXXXTimes 统计用 加释放次数 可能不止一次
    
    local recordChianAtkTimes = 0
    ---检查连锁技里还有没有攻击目标
    for _, attdata in ipairs(chainAttackData) do
        ---@type SkillScopeResult
        local scopeResult = attdata:GetScopeResult()
        ---@type SortedDictionary
        local targetDic = scopeResult:GetGridPosTargetIDDic()
        if targetDic ~= nil then
            local targetCount = targetDic:Size()
            if targetCount > 0 then
                recordChianAtkTimes = recordChianAtkTimes + 1
                petAttackDataCmpt:SetCastChainSkill(true)
            end
        end
    end

    local recordShadowChianAtkTimes = 0
    ---虚影 检查连锁技里还有没有攻击目标
    ---@type SkillChainAttackData
    local shadowChainAttackData = petAttackDataCmpt:GetChainShadowData()
    if shadowChainAttackData then
        for _, attdata in ipairs(shadowChainAttackData) do
            ---@type SkillScopeResult
            local scopeResult = attdata:GetScopeResult()
            ---@type SortedDictionary
            local targetDic = scopeResult:GetGridPosTargetIDDic()
            if targetDic ~= nil then
                local targetCount = targetDic:Size()
                if targetCount > 0 then
                    recordShadowChianAtkTimes = recordShadowChianAtkTimes + 1
                    petAttackDataCmpt:SetCastChainSkill(true)
                end
            end
        end
    end

    local agentShadowChianAtkTimes = 0
    ---代理 检查连锁技里还有没有攻击目标
    ---@type SkillChainAttackData
    local agentChainAttackData = petAttackDataCmpt:GetChainAgentData()
    if agentChainAttackData then
        for _, attdata in ipairs(agentChainAttackData) do
            ---@type SkillScopeResult
            local scopeResult = attdata:GetScopeResult()
            ---@type SortedDictionary
            local targetDic = scopeResult:GetGridPosTargetIDDic()
            if targetDic ~= nil then
                local targetCount = targetDic:Size()
                if targetCount > 0 then
                    agentShadowChianAtkTimes = agentShadowChianAtkTimes + 1
                    petAttackDataCmpt:SetCastChainSkill(true)
                end
            end
        end
    end

    local l_bCastChainSkill = petAttackDataCmpt:GetCastChainSkill()
    if l_bCastChainSkill then
        local l_battlestat = self._world:BattleStat()
        ---@type Entity
        if petEntity:HasPet() then
            local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
            local minTimes = 1
            local recordTimes = math.max(minTimes,recordChianAtkTimes,recordShadowChianAtkTimes,agentShadowChianAtkTimes)
            l_battlestat:AddChainSkillCount(teamEntity,recordTimes)
        end
    end
    return l_bCastChainSkill
end

function ChainSkillCalculator:_HandleChainAttackDead(casterEntityID, chainAttackIndex, chainSkillID)
    --检查所有怪的死亡状态
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        local result = sMonsterShowLogic:AddMonsterDeadMark(e)
        ---@type DeadMarkComponent
        local deadMarkCmpt = e:DeadMark()
        if result and deadMarkCmpt and not deadMarkCmpt:GetDeadCasterID() and not e:HasShowDeath() then
            deadMarkCmpt:SetDeadCasterID(casterEntityID)
            deadMarkCmpt:SetChainAttackIndex(chainAttackIndex)
            ---这里加个 日志 如果打印了 说明出现
            if not result then
                ---@type Entity
                local casterEntity = self._world:GetEntityByID(casterEntityID)
                if EDITOR then
                    Log.exception(
                        "MonsterHas DeadMark CasterID:",
                        casterEntity:PetPstID():GetTemplateID(),
                        ",SkillID:",
                        chainSkillID,
                        ",MonsterID:",
                        e:MonsterID():GetMonsterID(),
                        ",LevelID:",
                        self._world.BW_WorldInfo.level_id
                    )
                else
                    Log.fatal(
                        "MonsterHas DeadMark CasterID:",
                        casterEntity:PetPstID():GetTemplateID(),
                        ",SkillID:",
                        chainSkillID,
                        ",MonsterID:",
                        e:MonsterID():GetMonsterID(),
                        ",LevelID:",
                        self._world.BW_WorldInfo.level_id
                    )
                end
            end
        end
    end
    ----@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for _, e in ipairs(trapGroup:GetEntities()) do
        trapServiceLogic:AddTrapDeadMark(e)
        ---@type DeadMarkComponent
        local deadMarkCmpt = e:DeadMark()
        if deadMarkCmpt and not deadMarkCmpt:GetDeadCasterID() then
            deadMarkCmpt:SetDeadCasterID(casterEntityID)
            deadMarkCmpt:SetChainAttackIndex(chainAttackIndex)
        end
    end
    
    --每一次放完连锁技，处理一下逻辑死亡
    sMonsterShowLogic:DoAllMonsterDeadLogic()
end

---统一计算连锁技的击退效果
function ChainSkillCalculator:_CalcAndApplyChainSkillHitback(casterEntity, skillCastPos, skillHitbackResultDic, idx)
    local hitbackResultDic = self:_CalcSkillDelayHitback(skillCastPos, skillHitbackResultDic)

    ---@type SkillPetAttackDataComponent
    local petAttackDataCmpt = casterEntity:SkillPetAttackData()
    --本体
    local chainAttackData = petAttackDataCmpt:GetChainAttackData()
    --虚影
    local shadowChainAttackData = petAttackDataCmpt:GetChainShadowData()

    local attdata
    if chainAttackData[idx] then
        attdata = chainAttackData[idx]
    end
    if not attdata then
        attdata = shadowChainAttackData[idx]
    end

    if not attdata then
        return
    end

    ---逻辑 处理连锁技击退后的逻辑坐标  炸弹逻辑死亡
    ----@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")

    for victimEntityID, v in pairs(hitbackResultDic) do --不能改ipairs
        ---@type SkillHitBackEffectResult
        local hitbackResult = v
        local hitbackStartPos = hitbackResult:GetStartPos()
        local hitbackTargetPos = hitbackResult:GetGridPos()
        local victimEntity = self._world:GetEntityByID(victimEntityID)
        ---对于纯逻辑来说，直接设置击退的目标位置
        victimEntity:SetGridLocation(hitbackTargetPos)

        --在击退的方向触发炸弹
        if victimEntity:HasPetPstID() or victimEntity:HasTeam() or victimEntity:HasMonsterID() then
            local posDir = hitbackResult:GetHitDir()
            if posDir then
                hitbackTargetPos = hitbackTargetPos + posDir
            end
        end

        --触发炸弹
        local trapEntity = trapServiceLogic:TriggerBomb(hitbackTargetPos, victimEntity)
        if trapEntity then
            ---炸弹需要用另外的标记死亡
            ---@type TrapComponent
            local trapCmpt = trapEntity:Trap()
            trapEntity:Attributes():Modify("HP", 0)

            --执行统一的机关死亡流程
            trapServiceLogic:AddTrapDeadMark(trapEntity)
            --buff
            triggerService:Notify(NTTrapAction:New(nil, hitbackStartPos))
        end
        attdata:AddEffectResult(v)
    end
end

---特殊处理的技能效果 SkillEffectType.DamageOnTargetCount
---@param chainAttackData SkillChainAttackData
---@param skillHitbackResultDic Dic key是施法者的entityID,value是击退效果数组
function ChainSkillCalculator:_CalcAndApplyChainSkillEffect_DamageOnTargetCount(
    chainAttackData,
    skillHitbackResultDic,
    petEntityID,
    chainSkillID,
    attackPos,
    skillEffectParam,
    scopeResult)
    local targetIDs = scopeResult:GetTargetIDs()
    local skillEffectCalcParam =
        SkillEffectCalcParam:New(
        petEntityID,
        targetIDs,
        skillEffectParam,
        chainSkillID,
        scopeResult:GetAttackRange(),
        attackPos
    )
    --计算技能结果
    local skillResult = self._calcDamageOnTargetCountCalc:DoSkillEffectCalculator(skillEffectCalcParam)

    for _, result in ipairs(skillResult) do
        --技能结果设置技能范围数据，表现要取
        result:SetSkillEffectScopeResult(scopeResult)

        --应用连锁技的技能结果
        self:_OnApplyChainSkillEffectResult(skillEffectCalcParam, result, chainAttackData, skillHitbackResultDic)
    end
end

---@param scopeResult SkillScopeResult
function ChainSkillCalculator:_CalcAndApplyChainSkillEffect_DynamicCenterDamage(
        chainAttackData,
        skillHitbackResultDic,
        petEntityID,
        chainSkillID,
        attackPos,
        skillEffectParam,
        scopeResult)
    local targetIDs = scopeResult:GetTargetIDs()
    ---@type SkillEffectCalcParam
    local skillEffectCalcParam = SkillEffectCalcParam:New(
            petEntityID,
            targetIDs,
            skillEffectParam,
            chainSkillID,
            scopeResult:GetAttackRange(),
            attackPos
    )
    skillEffectCalcParam.centerPos = scopeResult:GetCenterPos()

    --计算技能结果
    local skillResult = self._dynamicCenterDamageCalc:DoSkillEffectCalculator(skillEffectCalcParam)

    for _, result in ipairs(skillResult) do
        --技能结果设置技能范围数据，表现要取
        result:SetSkillEffectScopeResult(scopeResult)

        --应用连锁技的技能结果
        self:_OnApplyChainSkillEffectResult(skillEffectCalcParam, result, chainAttackData, skillHitbackResultDic)
    end
end

function ChainSkillCalculator:CalcChainSkillScope(casterEntity, chainSkillID, castPos)
    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")
    local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(casterEntity:GetID(), chainSkillID)
    local effectType191
    local effectType203
    for _, effect in ipairs(skillEffectArray) do
        if effect:GetEffectType() == SkillEffectType.DynamicCenterDamage then
            effectType191 = effect
        end
        if effect:GetEffectType() == SkillEffectType.DynamicScopeChainDamage then
            effectType203 = effect
        end
    end

    local scopeResult
    local targetList = {}

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData 普通攻击的技能数据
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, casterEntity)

    ---191的中心范围是另算的
    if effectType191 then
        local calc191 = SkillEffectCalc_DynamicCenterDamage:New(self._world)
        targetList, scopeResult = calc191:SelectCenter(casterEntity, effectType191, castPos)
    elseif effectType203 then
        ---@type SkillEffectCalc_DynamicScopeChainDamage
        local calc203 = SkillEffectCalc_DynamicScopeChainDamage:New(self._world)
        scopeResult = calc203:CalcChainReplaceScope(casterEntity, effectType203)
    else
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---计算连锁技范围
        ---@type SkillScopeResult
        scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, castPos, casterEntity)
    end

    return scopeResult
end
