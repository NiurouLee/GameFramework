require "play_skill_phase_base_r"
_class("PlaySkillPhaseMultiGridColumnAndRowCenterRandom", PlaySkillPhaseBase)
PlaySkillPhaseMultiGridColumnAndRowCenterRandom = PlaySkillPhaseMultiGridColumnAndRowCenterRandom

---@param casterEntity Entity
function PlaySkillPhaseMultiGridColumnAndRowCenterRandom:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseParamMultiGridColumnAndRowCenterRandom
    local effectID = phaseParam:GetEffectID()
    local hitAnimationName = phaseParam:GetHitAnimationName()
    local hitEffectID = phaseParam:GetHitEffectID()
    local intervalTime = phaseParam:GetEffectIntervalTime()

    local damageWaitTime = phaseParam:GetEffectDamageWaitTime()

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PieceServiceRender
    local pieceSerivce = world:GetService("Piece")
    ---
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local pickUpPosList = scopeResult:GetCenterPos()
    if pickUpPosList._className then
        pickUpPosList = {pickUpPosList}
    end
    local pickUpPosScopeList = scopeResult:GetAttackRange()

    local effectList = {}

    for k, v in pairs(pickUpPosList) do
        local pickUpPos = v
        local gridPosCenter
        local gridPosList

        local dir = 0
        --产生2个方向
        for i = 1, 2 do
            if dir == 0 then
                gridPosCenter, gridPosList = self:_GetGridPosRow(pickUpPos, pickUpPosScopeList)
            else
                gridPosCenter, gridPosList = self:_GetGridPosColumn(pickUpPos, pickUpPosScopeList)
            end

            local effectItem = {}
            --选中的点
            effectItem.pickUpPos = pickUpPos
            --特效产生的点
            effectItem.gridPosCenter = gridPosCenter
            --对应的行列的坐标
            effectItem.gridPosList = gridPosList
            --特效方向
            local gridDir = Vector2(dir, 0)
            effectItem.gridDir = gridDir
            table.insert(effectList, effectItem)

            dir = dir + 1
        end
    end
    ---@type RandomServiceRender
    local randomSvc = self._world:GetService("RandomRender")
    --对选好的全部 行列 随机
    local effectRandomList = {}
    local _index = 1
    while #effectList ~= 0 do
        local ran = randomSvc:RenderRand(0, #effectList)
        if effectList[ran] ~= nil then
            effectRandomList[_index] = effectList[ran]
            table.remove(effectList, ran)
            _index = _index + 1
        end
    end

    --播放特效
    for k, effectItem in pairs(effectRandomList) do
        local entityEffect = world:GetService("Effect"):CreateWorldPositionEffect(effectID, effectItem.gridPosCenter)
        --entityEffect:SetGridDirection(effectItem.gridDir)
        entityEffect:SetDirection(effectItem.gridDir)
        YIELD(TT, intervalTime)
    end

    YIELD(TT, damageWaitTime)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local isFinalAttack = skillEffectResultContainer:IsFinalAttack()

    ---当前施法索引
    local castIndex = 1
    local damageArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)

    if damageArray == nil then
        return
    end

    local damageTargetResultDic = {}
    for k, v in pairs(damageArray) do
        ---@type SkillDamageEffectResult
        local damageResult = v
        local damageTargetID = damageResult:GetTargetID()

        if not damageTargetResultDic[damageTargetID] then
            damageTargetResultDic[damageTargetID] = {}
        end
        table.insert(damageTargetResultDic[damageTargetID], damageResult)
    end

    ---收到攻击的怪物ID  不再播放受击动画  还播放受击特效
    local damageTargetEntityIDs = {}
    local hadPlayDamageResult = {}

    for effectKey, effectItem in pairs(effectRandomList) do
        -- ---攻击目标的总数
        -- local castCount = #damageArray
        for k, v in pairs(damageArray) do
            ---@type SkillDamageEffectResult
            local damageResult = v
            local damageTargetID = damageResult:GetTargetID()

            -- ---@type SkillDamageEffectResult
            -- local realDamageResult = damageTargetResultDic[damageTargetID][1]

            local damageTargetEntity = self._world:GetEntityByID(damageTargetID)
            ---单体伤害只有一个
            -- local damage = realDamageResult:GetDamageInfo(1)
            local damagePos = damageResult:GetGridPos()

            --如果这个伤害在 排好序的攻击范围内  并 不是已经播放过的 在选择点上的怪物
            if
                table.icontains(effectItem.gridPosList, damagePos) and
                    not table.icontains(hadPlayDamageResult, damageResult)
             then
                table.insert(hadPlayDamageResult, damageResult)

                ---@type SkillDamageEffectResult
                local realDamageResult = damageTargetResultDic[damageTargetID][1]
                local damage = realDamageResult:GetDamageInfo(1)
                damagePos = realDamageResult:GetGridPos()

                ---收到攻击的怪物ID  不再播放受击动画
                if not table.intable(damageTargetEntityIDs, damageTargetID) then
                    table.insert(damageTargetEntityIDs, damageTargetID)
                    hitAnimationName = phaseParam:GetHitAnimationName()
                else
                    hitAnimationName = nil
                end

                local curHitIsFinalAttack = false
                if isFinalAttack == true and castIndex == #effectRandomList then
                    curHitIsFinalAttack = true
                end

                ---调用统一处理被击的逻辑
                local beHitParam = HandleBeHitParam:New()
                    :SetHandleBeHitParam_CasterEntity(casterEntity)
                    :SetHandleBeHitParam_TargetEntity(damageTargetEntity)
                    :SetHandleBeHitParam_HitAnimName(hitAnimationName)
                    :SetHandleBeHitParam_HitEffectID(hitEffectID)
                    :SetHandleBeHitParam_DamageInfo(damage)
                    :SetHandleBeHitParam_DamagePos(damagePos)
                    :SetHandleBeHitParam_HitTurnTarget(TurnToTargetType.None)
                    :SetHandleBeHitParam_DeathClear(false)
                    :SetHandleBeHitParam_IsFinalHit(curHitIsFinalAttack)
                    :SetHandleBeHitParam_SkillID(skillID)

                self:SkillService():HandleBeHit(TT, beHitParam)

                table.removev(damageTargetResultDic[damageTargetID], realDamageResult)
                castIndex = castIndex + 1
                YIELD(TT, intervalTime)
            end
        end
    end
end

--x 变 y不变
function PlaySkillPhaseMultiGridColumnAndRowCenterRandom:_GetGridPosRow(pos, posList)
    local targetX = pos.x
    local targetY = pos.y

    local posXList = {}
    local rangeList = {}

    for k, grid in pairs(posList) do
        if pos.y == grid.y then
            table.insert(posXList, grid.x)
        end
    end

    if not table.icontains(posXList, targetX) then
        table.insert(posXList, targetX)
    end

    table.sort(
        posXList,
        function(pos1, pos2)
            return pos1 > pos2
        end
    )

    local xCenterIndex = math.fmod(#posXList, 2) == 1 and math.floor(#posXList / 2) + 1 or #posXList / 2

    targetX = posXList[xCenterIndex]

    for k, posX in pairs(posXList) do
        table.insert(rangeList, Vector2(posX, targetY))
    end

    local gridPos = Vector2(targetX, targetY)
    return gridPos, rangeList
end

function PlaySkillPhaseMultiGridColumnAndRowCenterRandom:_GetGridPosColumn(pos, posList)
    local targetX = pos.x
    local targetY = pos.y

    local posYList = {}
    local rangeList = {}

    for k, grid in pairs(posList) do
        if pos.x == grid.x then
            table.insert(posYList, grid.y)
        end
    end

    if not table.icontains(posYList, targetY) then
        table.insert(posYList, targetY)
    end

    table.sort(
        posYList,
        function(pos1, pos2)
            return pos1 > pos2
        end
    )

    local yCenterIndex = math.fmod(#posYList, 2) == 1 and math.floor(#posYList / 2) + 1 or #posYList / 2

    targetY = posYList[yCenterIndex]

    for k, posY in pairs(posYList) do
        table.insert(rangeList, Vector2(targetX, posY))
    end

    local gridPos = Vector2(targetX, targetY)
    return gridPos, rangeList
end
