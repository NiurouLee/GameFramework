--[[
        AddBuff = 5, --给目标加Buff
]]
_class("SkillEffectCalc_AddBuff", Object)
---@class SkillEffectCalc_AddBuff: Object
SkillEffectCalc_AddBuff = SkillEffectCalc_AddBuff

function SkillEffectCalc_AddBuff:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type MathService
    self._mathService = self._world:GetService("Math")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBuff:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = self:_CalculateSingleTarget(skillEffectCalcParam)
    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBuff:_CalculateSingleTarget(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local ctx = casterEntity:SkillContext()

    ---@type ConfigService
    local configService = self._configService

    ---@type SkillAddBuffEffectParam
    local addBuffParam = skillEffectCalcParam.skillEffectParam
    local attackRange = skillEffectCalcParam:GetSkillRange()
    local prob = addBuffParam:GetBuffProb()
    local probType = addBuffParam:GetBuffProbType()
    local buffID = addBuffParam:GetBuffID()
    local buffTargetType = addBuffParam:GetBuffTargetType()
    local remove = addBuffParam:GetRemove()
    local transmitAttack = addBuffParam:TransmitAttack()
    local getFinalAtk = addBuffParam:IsTransmitFinalAttack()

    local transmitDefence = addBuffParam:TransmitDefence()
    local getFinalDefense = addBuffParam:IsTransmitFinalDefense()

    local mustHaveSkillTarget = addBuffParam:MustHaveSkillTarget()
    --技能加buff时，空放也会导致加buff
    if mustHaveSkillTarget then
        local hasSkillTarget = false
        local targets = skillEffectCalcParam:GetTargetEntityIDs()
        for _, id in ipairs(targets) do
            if id ~= -1 then
                hasSkillTarget = true
            end
        end
        if not hasSkillTarget then
            return {}
        end
    end

    local skillID = skillEffectCalcParam:GetSkillID()
    if probType == SkillAddBuffPropType.Default then
        if prob < 1 then
            ---放大100倍
            prob = 100 * prob
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            ---产生随机数
            local random = randomSvc:LogicRand(1, 100)
            --buff概率
            if random > prob then
                return {}
            end
        end
    end

    local damageStageIndex = addBuffParam:GetSkillEffectDamageStageIndex()

    local results = {}
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type Entity[]
    local es, dmgs = self:CalcBuffTarget(skillEffectCalcParam)

    ---@type TriggerService
    local sTrigger = self._world:GetService("Trigger")
    for i, e in ipairs(es) do
        Log.debug("[CalcAddBuff] entityID:", e:GetID(), " BuffID:", buffID, "Prob:", prob, "remove=", remove)
        ---@type SkillBuffEffectResult
        local buffResult = SkillBuffEffectResult:New(e:GetID())
        buffResult:SetDamageStageIndex(damageStageIndex)
        if remove then
            local defenderBuffComp = e:BuffComponent()
            ---注意：若存在多个相同BuffID，只会返回并删除第一个
            local buff = defenderBuffComp:GetBuffById(buffID)
            if buff then
                buff:Unload(NTBuffUnload:New())
                buffResult:AddBuffResult(buff:BuffSeq())
            end
        else
            if (ctx:HasDamageInfoFor(e:GetID()) and (not ctx:IsEntityDamaged(e:GetID(), addBuffParam:CanAddToNonMissDamageTarget()))) then
                Log.debug("CalcAddBuff() skipped for damge == 0 !!")
            else
                buffID = self:CalcBuffID(e, casterEntity, buffTargetType, addBuffParam)
                local cfgNewBuff = Cfg.cfg_buff[buffID]
                if cfgNewBuff then
                    local count = self:CalcAddBuffCount(skillEffectCalcParam, e)
                    for i = 1, count do
                        local nt = NTEachAddBuffStart:New(skillID, casterEntity, e, attackRange)
                        sTrigger:Notify(nt)
                        local seqID
                        local buff =
                            buffLogicService:AddBuff(
                            buffID,
                            e,
                            {casterEntity = casterEntity, layer = addBuffParam:GetBuffInitLayer()}
                        )
                        if buff then
                            if transmitAttack then
                                local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

                                local actualAttack = casterEntity:Attributes():GetAttribute("Attack")
                                if getFinalAtk then
                                    actualAttack = casterEntity:Attributes():GetAttack()
                                end
                                e:BuffComponent():SetBuffValue("GuestAttack", actualAttack)
                            end
                            if transmitDefence then
                                local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
                                local actualDefense = casterEntity:Attributes():GetAttribute("Defense")
                                if getFinalDefense then
                                    actualDefense = casterEntity:Attributes():GetDefence()
                                end

                                e:BuffComponent():SetBuffValue("GuestDefence", actualDefense)
                            end
                            seqID = buff:BuffSeq()
                            buffResult:AddBuffResult(seqID)
                        end
                        sTrigger:Notify(NTEachAddBuffEnd:New(skillID, casterEntity, e, attackRange, buffID, seqID))
                    end
                end
            end
        end

        results[#results + 1] = buffResult
    end
    return results
end

---计算施加Buff的目标
---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddBuff:CalcBuffTarget(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type SkillAddBuffEffectParam
    local addBuffParam = skillEffectCalcParam.skillEffectParam
    local buffTargetType = addBuffParam:GetBuffTargetType()

    --黑拳赛替换目标类型
    buffTargetType = self._world:ReplaceBuffTarget(buffTargetType)

    ---@type Entity[]
    local es = {}
    local dmgs = nil
    if buffTargetType == BuffTargetType.Self or buffTargetType == BuffTargetType.SelectBuffByCasterLayer then
        local targetEntity = casterEntity
        local buffTargetParam = addBuffParam:GetBuffTargetParam()
        local checkSuper = false
        if buffTargetParam then
            if buffTargetParam.checkSuper and (buffTargetParam.checkSuper == 1) then
                checkSuper = true
            end
        end
        if checkSuper and targetEntity:HasSuperEntity() then
            targetEntity = targetEntity:GetSuperEntity()
        end
        es[#es + 1] = targetEntity
    elseif
        (buffTargetType == BuffTargetType.SkillTarget or buffTargetType == BuffTargetType.SkillTargetSelectBuffByLayer or
            buffTargetType == BuffTargetType.SkillTargetRandomBuff)
     then
        local targets = skillEffectCalcParam:GetTargetEntityIDs()
        for _, id in ipairs(targets) do
            local e = self._world:GetEntityByID(id)
            if e == nil then
                Log.warn("addbuff defender is nil entityid=", id)
            end
            --无敌、魔免不挂buff
            if e and buffLogicService:CheckCanAddBuff(casterEntity, e) then
                es[#es + 1] = e
            end
        end
    elseif buffTargetType == BuffTargetType.SkillScopeCenterPosMonster then
        local entityEnum = EnumTargetEntity.Monster
        if self._world:MatchType() == MatchType.MT_BlackFist then
            entityEnum = EnumTargetEntity.Pet
        end
        local centerPos = skillEffectCalcParam:GetCenterPos()
        -- 空放的时候这个是nil
        if centerPos then
            ---@type UtilDataServiceShare
            local utildata = self._world:GetService("UtilData")
            local entityIDFind = utildata:FindEntityByPosAndType(centerPos, entityEnum)
            local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
            for _, eid in ipairs(entityIDFind) do
                if table.icontains(targetIDs, eid) then
                    es[#es + 1] = self._world:GetEntityByID(eid)
                end
            end
        end
    elseif
        buffTargetType == BuffTargetType.EachPickUpScopeFarest or
            buffTargetType == BuffTargetType.EachPickUpScopeNearest
     then
        es = self:_CalcBuffEachPickUpScope(skillEffectCalcParam)
    elseif buffTargetType == BuffTargetType.Trap then --范围内的所有机关
        local buffTargetParam = addBuffParam:GetBuffTargetParam() --机关id列表，没有则不筛选
        local tarTrapIdList = {}
        if buffTargetParam then
            if buffTargetParam.trapIDs then
                tarTrapIdList = buffTargetParam.trapIDs
            end
        end
        local checkTrapId = false
        if tarTrapIdList and #tarTrapIdList > 0 then
            checkTrapId = true
        end
        local range = skillEffectCalcParam:GetSkillRange()
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        for _, pos in ipairs(range) do
            local listTrap = sUtilData:GetTrapsAtPos(pos)
            for i = 1, #listTrap do
                local targetEntity = listTrap[i]
                if targetEntity then
                    if checkTrapId then
                        local trapID = targetEntity:Trap():GetTrapID()
                        if table.icontains(tarTrapIdList, trapID) then
                            table.insert(es, targetEntity)
                        end
                    else
                        table.insert(es, targetEntity)
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.MyTrap then --范围内施法者召唤的机关
        local buffTargetParam = addBuffParam:GetBuffTargetParam() --机关id列表，没有则不筛选
        local tarTrapIdList = {}
        local checkSuper = false--召唤者如果有superEntity 是否判断superEntity是不是自己 默认不
        if buffTargetParam then
            if buffTargetParam.trapIDs then
                tarTrapIdList = buffTargetParam.trapIDs
            end
            if buffTargetParam.includeSuper and (buffTargetParam.includeSuper == 1) then
                checkSuper = true
            end
        end
        local checkTrapId = false
        if tarTrapIdList and #tarTrapIdList > 0 then
            checkTrapId = true
        end
        local range = skillEffectCalcParam:GetSkillRange()
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        for _, pos in ipairs(range) do
            local listTrap = sUtilData:GetTrapsAtPos(pos)
            for i = 1, #listTrap do
                local targetEntity = listTrap[i]
                local isOwner = false
                if targetEntity:HasSummoner() then
                    ---@type Entity
                    local summonerEntity = targetEntity:GetSummonerEntity()
                    if summonerEntity then
                        if summonerEntity == casterEntity then
                            isOwner = true
                        else
                            if checkSuper then
                                if summonerEntity:HasSuperEntity() then
                                    local superEntity = summonerEntity:GetSuperEntity()
                                    summonerEntity = superEntity
                                    if superEntity == casterEntity then
                                        isOwner = true
                                    end
                                end
                            end
                        end

                        --[[
                            修改前代码是只判断机关是不是施法者自己的
                            但N24加入的阿克希亚也可以召唤别人的机关，并需要被认为是施法者的
                            考虑到该判断原先的目的是防止吸收【被世界boss化的光灵】和【黑拳赛的对方光灵】所属机关
                            这里添加判断：当施法者是光灵时，自己队伍内的其他光灵召唤的机关，也视为施法者自己召唤的
                        ]]
                        if (not isOwner) and (summonerEntity:HasPet()) then
                            local cTeam = summonerEntity:Pet():GetOwnerTeamEntity():Team()
                            local petEntities = cTeam:GetTeamPetEntities()
                            for _, e in ipairs(petEntities) do
                                if e:GetID() == casterEntity:GetID() then
                                    isOwner = true
                                    break
                                end
                            end
                        end
                    end
                end
                if isOwner then
                    if checkTrapId then
                        local trapID = targetEntity:Trap():GetTrapID()
                        if table.icontains(tarTrapIdList, trapID) then
                            table.insert(es, targetEntity)
                        end
                    else
                        table.insert(es, targetEntity)
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.SkillTargetBodyAreaGridElementProp then
        local buffTargetParam = addBuffParam:GetBuffTargetParam()
        local targetIds = skillEffectCalcParam:GetTargetEntityIDs()
        local enemyEntities = {}
        for index, value in ipairs(targetIds) do
            local e = self._world:GetEntityByID(value)
            if e == nil then
                Log.warn("addbuff defender is nil entityid=", value)
            end
            table.insert(enemyEntities, e)
        end
        es = buffLogicService:CalTargets_BodyAreaGridElementProp(buffTargetParam, enemyEntities)
    elseif buffTargetType == BuffTargetType.SkillTargetBodyAreaGridFindElement then
        local buffTargetParam = addBuffParam:GetBuffTargetParam()
        local targetIds = skillEffectCalcParam:GetTargetEntityIDs()
        local enemyEntities = {}
        for index, value in ipairs(targetIds) do
            local e = self._world:GetEntityByID(value)
            if e == nil then
                Log.warn("addbuff defender is nil entityid=", value)
            end
            table.insert(enemyEntities, e)
        end
        es = buffLogicService:CalTargets_BodyAreaGridFindElement(buffTargetParam, enemyEntities)
    elseif buffTargetType == BuffTargetType.SkillTargetOtherMonster then
        local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for i, e in ipairs(monsterGroup:GetEntities()) do
            if not e:HasDeadMark() and not table.intable(targetIDs, e:GetID()) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.SkillTargetElement then
        local targetIds = skillEffectCalcParam:GetTargetEntityIDs()
        local buffTargetParam = addBuffParam:GetBuffTargetParam()
        for index, value in ipairs(targetIds) do
            local e = self._world:GetEntityByID(value)
            if e then
                ---@type ElementComponent
                local elementCmpt = e:Element()
                if elementCmpt then
                    local element = elementCmpt:GetPrimaryType()
                    if table.icontains(buffTargetParam, element) then
                        table.insert(es, e)
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.SkillTargetElementAndOwnerBuff then
        local targetIds = skillEffectCalcParam:GetTargetEntityIDs()
        local buffTargetParam = addBuffParam:GetBuffTargetParam()
        local elementParam = buffTargetParam.element
        local buffParam = buffTargetParam.buff

        for index, value in ipairs(targetIds) do
            local e = self._world:GetEntityByID(value)
            if e then
                ---@type ElementComponent
                local elementCmpt = e:Element()
                if elementCmpt then
                    local element = elementCmpt:GetPrimaryType()
                    if table.icontains(elementParam, element) then
                        ---@type BuffComponent
                        local buffCmp = e:BuffComponent()
                        for _, buffEffect in ipairs(buffParam) do
                            if buffCmp:HasBuffEffect(buffEffect) then
                                table.insert(es, e)
                                break
                            end
                        end
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.SkillScopeCenterPosMonsterOnTrap then
        local entityEnum = EnumTargetEntity.Monster
        if self._world:MatchType() == MatchType.MT_BlackFist then
            entityEnum = EnumTargetEntity.Pet
        end
        ---@type UtilDataServiceShare
        local utildata = self._world:GetService("UtilData")
        local centerPos = skillEffectCalcParam:GetCenterPos()
        -- 空放的时候这个是nil
        if centerPos then
            local buffTargetParam = addBuffParam:GetBuffTargetParam() --机关id列表
            local tarTrapIdList = {}
            if buffTargetParam then
                if buffTargetParam.trapIDs then
                    tarTrapIdList = buffTargetParam.trapIDs
                end
            end
            local findTrap = false
            local listTrap = utildata:GetTrapsAtPos(centerPos)
            for i = 1, #listTrap do
                local targetEntity = listTrap[i]
                if targetEntity:HasSummoner() and targetEntity:GetSummonerEntity() == casterEntity then
                    local trapID = targetEntity:Trap():GetTrapID()
                    if table.icontains(tarTrapIdList, trapID) then
                        findTrap = true
                        break
                    end
                end
            end
            if findTrap then
                local entityIDFind = utildata:FindEntityByPosAndType(centerPos, entityEnum)
                local targetIDs = skillEffectCalcParam:GetTargetEntityIDs()
                for _, eid in ipairs(entityIDFind) do
                    if table.icontains(targetIDs, eid) then
                        es[#es + 1] = self._world:GetEntityByID(eid)
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.OneGridMonsterInRange then
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        --技能范围内的单格怪
        for _, pos in ipairs(skillEffectCalcParam.skillRange) do
            local entity = sUtilData:GetMonsterAtPos(pos)--黑拳赛敌方队伍也会计入
            if entity then
                local bodyAreaCmpt = entity:BodyArea()
                if bodyAreaCmpt then
                    if bodyAreaCmpt:GetAreaCount() == 1 then
                        es[#es + 1] = entity
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.TrapTypeInRange then
        local buffTargetParam = addBuffParam:GetBuffTargetParam() --机关id列表
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        --技能范围内的单格怪
        for _, pos in ipairs(skillEffectCalcParam.skillRange) do
            local entities = sUtilData:GetTrapsAtPos(pos)
            for _, targetEntity in ipairs(entities) do
                local trapType = targetEntity:Trap():GetTrapType()
                if table.icontains(buffTargetParam, trapType) then
                    table.insert(es, targetEntity)
                end
            end
        end
    elseif buffTargetType == BuffTargetType.SelectMonsterIDInSkillRange then
        local buffTargetParam = addBuffParam:GetBuffTargetParam() --机关id列表
        ---@type UtilDataServiceShare
        local sUtilData = self._world:GetService("UtilData")
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        --技能范围内的单格怪
        for _, pos in ipairs(skillEffectCalcParam.skillRange) do
            local entities = sUtilData:GetAllMonstersAtPos(pos)
            for _, e in ipairs(entities) do
                ---@type MonsterIDComponent
                local monsterID = e:MonsterID():GetMonsterID()
                if table.icontains(buffTargetParam, monsterID) then
                    table.insert(es, e)
                end
            end
        end
    else
        es = buffLogicService:CalcBuffTargetEntities(buffTargetType, addBuffParam:GetBuffTargetParam(), casterEntity)
    end
    return es
end

---计算施加Buff的目标，每次拾取范围内的最近和最远的怪物 （四叶草）
---@param skillEffectCalcParam SkillEffectCalcParam
---@return Entity[]
function SkillEffectCalc_AddBuff:_CalcBuffEachPickUpScope(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type Entity[]
    local es = {}

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type SkillAddBuffEffectParam
    local addBuffParam = skillEffectCalcParam.skillEffectParam
    local buffTargetType = addBuffParam:GetBuffTargetType()
    local skillID = skillEffectCalcParam:GetSkillID()

    local casterPos = casterEntity:GridLocation().Position

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local targetSelector = self._world:GetSkillScopeTargetSelector()

    --按照目标格子相对施法者的方向 进行分组
    local sortGridList = utilScopeSvc:SortSkillRangeByDirectionAndDistance(casterPos, skillEffectCalcParam.skillRange)

    for _, gridPosList in pairs(sortGridList) do --不能改ipairs
        local skillScopeResult = SkillScopeResult:New(SkillScopeType.None, casterPos, gridPosList, gridPosList)

        local pickUpScopeTargetEntityID = {}
        if buffTargetType == BuffTargetType.EachPickUpScopeFarest then
            pickUpScopeTargetEntityID =
                targetSelector:DoSelectSkillTarget(
                casterEntity,
                SkillTargetType.FarestMonster,
                skillScopeResult,
                skillID
            )
        elseif buffTargetType == BuffTargetType.EachPickUpScopeNearest then
            pickUpScopeTargetEntityID =
                targetSelector:DoSelectSkillTarget(
                casterEntity,
                SkillTargetType.NearestMonster,
                skillScopeResult,
                skillID
            )
        end

        if #pickUpScopeTargetEntityID > 0 then
            local targets = skillEffectCalcParam:GetTargetEntityIDs()
            for _, id in ipairs(targets) do
                local e = self._world:GetEntityByID(id)

                --无敌、魔免不挂buff
                if e and id == pickUpScopeTargetEntityID[1] and buffLogicService:CheckCanAddBuff(casterEntity, e) then
                    es[#es + 1] = e
                end
            end
        end
    end
    return es
end

---@param addBuffParam SkillAddBuffEffectParam
---@return number
function SkillEffectCalc_AddBuff:CalcBuffID_SkillTargetRandomBuff(addBuffParam)
    local param = addBuffParam:GetBuffTargetParam()
    local randomBuffIDs = {}
    local totalWeight = 0
    for _, value in pairs(param.randomBuffIDs) do --不能改ipairs 不确定配置形式
        totalWeight = totalWeight + value[2]
        table.insert(
            randomBuffIDs,
            {
                ID = value[1],
                Weight = value[2]
            }
        )
    end

    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local random = randomSvc:LogicRand(1, totalWeight)

    local curWeight = 0
    for _, buffInfo in ipairs(randomBuffIDs) do
        curWeight = curWeight + buffInfo.Weight
        if random <= curWeight then
            return buffInfo.ID
        end
    end

    return 0
end

function SkillEffectCalc_AddBuff:CalcBuffID_SkillTargetSelectBuffByLayer(e, addBuffParam)
    local logicParam = addBuffParam:GetBuffTargetParam()
    local buffID = 0
    local newBuffIDs = {}
    for threshole, buffID in pairs(logicParam.newBuffIDs) do --不能改ipairs
        table.insert(
            newBuffIDs,
            {
                threshole = threshole,
                buffID = buffID
            }
        )
    end
    table.sort(
        newBuffIDs,
        function(a, b)
            return a.threshole < b.threshole
        end
    )

    local cBuff = e:BuffComponent()
    local layer = tonumber(cBuff:GetBuffValue(logicParam.determinativeLayerName)) or 0
    if layer then
        for _, newBuffInfo in ipairs(newBuffIDs) do
            if newBuffInfo.threshole <= layer then
                buffID = newBuffInfo.buffID
            end
        end
    end

    return buffID
end

function SkillEffectCalc_AddBuff:CalcBuffID_SelectBuffByCasterLayer(casterEntity, addBuffParam)
    local logicParam = addBuffParam:GetBuffTargetParam()
    local buffID = 0
    local newBuffIDs = {}
    for threshole, buffID in pairs(logicParam.newBuffIDs) do --不能改ipairs
        table.insert(
            newBuffIDs,
            {
                threshole = threshole,
                buffID = buffID
            }
        )
    end
    table.sort(
        newBuffIDs,
        function(a, b)
            return a.threshole < b.threshole
        end
    )

    local cBuff = casterEntity:BuffComponent()
    local layer = tonumber(cBuff:GetBuffValue(logicParam.determinativeLayerName)) or 0
    if layer then
        for _, newBuffInfo in ipairs(newBuffIDs) do
            if newBuffInfo.threshole <= layer then
                buffID = newBuffInfo.buffID
            end
        end
    end

    return buffID
end

---计算施加的BuffID
---@param targetEntity Entity
---@param addBuffParam SkillAddBuffEffectParam
function SkillEffectCalc_AddBuff:CalcBuffID(targetEntity, casterEntity, buffTargetType, addBuffParam)
    local buffID = addBuffParam:GetBuffID()
    if buffTargetType == BuffTargetType.SkillTargetSelectBuffByLayer then
        buffID = self:CalcBuffID_SkillTargetSelectBuffByLayer(targetEntity, addBuffParam)
    elseif buffTargetType == BuffTargetType.SelectBuffByCasterLayer then
        buffID = self:CalcBuffID_SelectBuffByCasterLayer(casterEntity, addBuffParam)
    elseif buffTargetType == BuffTargetType.SkillTargetRandomBuff then
        buffID = self:CalcBuffID_SkillTargetRandomBuff(targetEntity, addBuffParam)
    end
    return buffID
end
---计算施加Buff的数量
---@param skillEffectCalcParam SkillEffectCalcParam
---@param targetEntity Entity
function SkillEffectCalc_AddBuff:CalcAddBuffCount(skillEffectCalcParam, targetEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")

    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())

    ---@type SkillAddBuffEffectParam
    local addBuffParam = skillEffectCalcParam.skillEffectParam
    local addBuffType = addBuffParam:GetAddBuffType()
    local buffCountParam = addBuffParam:GetBuffCountParam()

    local count = buffLogicService:CalcAddTimesByParam(addBuffType, buffCountParam, casterEntity, targetEntity)

    return count
end
