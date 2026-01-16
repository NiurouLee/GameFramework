--[[------------------------------------------------------------------------------------------
    BuffLogicService 处理Buff逻辑的公共服务对象 
]] --------------------------------------------------------------------------------------------

require("base_service")

local __AttrKey_ControlIncrease = "ControlIncrease"

_class("BuffLogicService", BaseService)
---@class BuffLogicService:BaseService
BuffLogicService = BuffLogicService

function BuffLogicService:Constructor(world)
    self._buffLogicHandler = {}
    ----@type MainWorld
    self._world = world
    self._buffSeqID = 1000
end

function BuffLogicService:CreateLogic(buffInstance, logicParam)
    local logicName = string.trim(logicParam.logic)
    local logicPrototype = Classes["BuffLogic" .. logicName]
    if not logicPrototype then
        local buffLogicName = "BuffLogic" .. logicParam.logic
        Log.exception(
            "BuffLogicService:CreateLogic() not find logic:",
            buffLogicName,
            " config Logic:",
            logicParam.logic
        )
        return
    end
    return logicPrototype:New(buffInstance, logicParam)
end

function BuffLogicService:CreateBuffInstance(buffID, entity, context, alterLayer, addLayerCount)
    self._buffSeqID = self._buffSeqID + 1
    local buffInstance = BuffInstance:New(self._buffSeqID, buffID, entity, self._world, context, alterLayer, addLayerCount)
    return buffInstance
end

function BuffLogicService:RemoveAllBuffInstance(entity)
    local buffCom = entity:BuffComponent()
    if buffCom then
        buffCom:ClearAllBuffInstances()
    end
end

--自动删除卸载的buffInstance
function BuffLogicService:AutoRemoveUnloadedBuff()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.Buff)
    for i, e in ipairs(group:GetEntities()) do
        e:BuffComponent():RemoveUnloadedBuffInstance()
    end
end

--创建buff逻辑对象
function BuffLogicService:CreateBuffLogic(buffInstance, logicConfig)
    if not logicConfig or not next(logicConfig) then
        return nil
    end
    ---@type BuffLogicBase
    local logic = {}
    for i, cfg in ipairs(logicConfig) do
        local sublogic = self:CreateLogic(buffInstance, cfg)
        logic[#logic + 1] = sublogic
    end
    return logic
end

--未知挂在哪些entity上
function BuffLogicService:AddBuffByTargetType(
    buffID,
    buffTargetType,
    buffTargetParam,
    context,
    buffSource,
    equipIntensifyParams,
    casterEntity)
    local es = self:CalcBuffTargetEntities(buffTargetType, buffTargetParam, casterEntity)
    local buffArray = {}
    for i, e in ipairs(es) do
        local buffInstance = self:AddBuff(buffID, e, context, buffSource, equipIntensifyParams)
        if buffInstance then
            buffArray[#buffArray + 1] = buffInstance
            ---@type BuffComponent
            local buffComponent = e:BuffComponent()
        end
    end
    return buffArray
end

--已知挂在某个entity上
---@param entity Entity
function BuffLogicService:AddBuff(buffID, entity, context, buffSource, equipIntensifyParams)
    if entity == nil then
        Log.fatal("[Buff] add buff failed, entity is nil. BuffID: ", buffID)
    end

    ---@type BuffComponent
    local buffComp = entity:BuffComponent()
    if not buffComp then
        return --实体有可能没有BuffComponent，比如机关
    end
    local buffCfg = Cfg.cfg_buff[buffID]
    if not buffCfg then
        Log.fatal("buffID has no config ", buffID)
        return
    end

    local buffEffectType = buffCfg.BuffEffectType

    if entity:HasTeam() or entity:HasPet() then
        if buffEffectType == BuffEffectType.Fear then
            Log.fatal("Fear buff target is team or pet")
            return
        end
    end

    local triggerSvc = self._world:GetService("Trigger")
    triggerSvc:Notify(NTBeforeEntityAddBuff:New(entity, buffID, buffEffectType))

    --免疫负面buff
    if buffCfg.IsDebuff then
        if entity:Attributes():GetAttribute("DebuffImmunity") ~= nil then
            self:PrintBuffLogicSvcLog("[Buff] buff target immunity debuff. BuffID: ", buffID)
            return nil
        end
    end

    --免疫指定buff
    local effs = buffComp:GetBuffValue("ImmuneBuffEffect")
    if effs and table.icontains(effs, buffEffectType) then
        self:PrintBuffLogicSvcLog("[Buff] buff immnue buff effect ", buffEffectType)
        return
    end

    if buffCfg.BuffType == BuffType.Control then
        --机关免控
        if entity:EntityType().Value == EntityType.Trap then
            self:PrintBuffLogicSvcLog("[buff] buff trap cannot add control buff=", buffID)
            return
        end
        --免控buff
        if buffComp:HasFlag(BuffFlags.ImmuneControl) then
            self:PrintBuffLogicSvcLog("[Buff] buff immnue control buff=", buffID)
            return
        end
    end

    local buffSeq = -1
    self._world:GetSyncLogger():Trace({key = "AddBuff", entityID = entity:GetID(), buffID = buffID})
    ---@type BuffInstance
    local buffInstance = self:HandleOverlap(buffID, entity, context, equipIntensifyParams)
    if buffInstance and not buffInstance:IsInit() then
        buffInstance:InitBuffHandler(equipIntensifyParams)
        buffComp:AddBuffInstance(buffInstance)
        buffComp:AddBuffSource(buffSource, buffInstance)
        buffSeq = buffInstance:BuffSeq()
    end

    --[[
        怪物精英化：受控加重

        特定buff加给具有受控加重效果的单位时，将添加额外的回合数
        逻辑判断：身上是否有加深计数，添加的buff是否无限回合，是否为控制buff
    ]]
    local controlIncreaseVal = entity:Attributes():GetAttribute(__AttrKey_ControlIncrease) or 0
    if
        ((controlIncreaseVal > 0) and (buffInstance and (buffInstance:GetMaxRoundCount() > 0)) and
            (table.icontains(BattleConst.ControlBuffEffectTypeArray, buffInstance:GetBuffEffectType())))
     then
        buffInstance:AddMaxRoundCount(controlIncreaseVal)
    end
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    if affixService:HasChangePetAddBuffMaxRound() then
        if entity:HasTeam() or entity:HasPet() then
            if buffCfg.CustomParams and buffCfg.CustomParams.effectFlags then
                local changeRound = affixService:GetChangePetAddBuffMaxRoundParam(buffCfg.CustomParams.effectFlags)
                if changeRound then
                    if (buffInstance and (buffInstance:GetMaxRoundCount() > 0)) then
                        buffInstance:AddMaxRoundCount(changeRound)
                    end
                end
            end
        end
    end

    self:PrintBuffLogicSvcLog("AddBuff() entityID=", entity:GetID(), " buffSeq=", buffSeq, " buffID=", buffID)
    return buffInstance
end

function BuffLogicService:HandleOverlap(buffID, entity, context, equipIntensifyParams)
    --处理叠加规则
    local buffComp = entity:BuffComponent()
    local buffCfg = Cfg.cfg_buff[buffID]
    local buffEffectType = buffCfg.BuffEffectType
    local replaceType = buffCfg.ReplaceType

    ---@type BuffInstance[]
    local existBuff = buffComp:GetBuffArrayByBuffEffect(buffEffectType)
    ---@type BuffInstance
    local buffInstance = nil
    if replaceType == BuffReplaceType.Exclusive then
        --互斥
        if 0 == #existBuff then
            ---@type BuffInstance
            buffInstance = self:CreateBuffInstance(buffID, entity, context)
        else
            self:PrintBuffLogicSvcLog("AddBuff() replaceType=Exclusive buffID=", buffID)
        end
    elseif replaceType == BuffReplaceType.CoExist then
        --共存
        buffInstance = self:CreateBuffInstance(buffID, entity, context)
    elseif replaceType == BuffReplaceType.RoundOverlap then
        if 0 == #existBuff then
            buffInstance = self:CreateBuffInstance(buffID, entity, context)
        else
            buffInstance = existBuff[1]
            buffInstance:AddMaxRoundCount(buffCfg.RoundCount)
        end
    elseif replaceType == BuffReplaceType.EffectOverlap then
        --叠加
        if 0 == #existBuff then
            buffInstance = self:CreateBuffInstance(buffID, entity, context)
        else
            buffInstance = existBuff[1]
            buffInstance:DoOverlap(buffID, context, equipIntensifyParams)
        end
    elseif replaceType == BuffReplaceType.Replace then
        --替换
        if 0 ~= #existBuff then
            buffInstance = existBuff[1]
            buffInstance:Unload()
        end

        buffInstance = self:CreateBuffInstance(buffID, entity, context)
    elseif replaceType == BuffReplaceType.LayerLimit then
        -- buff可能存在也可能不存在，配置有可能改也有可能没改
        ---@type ConfigService
        local sConfig = self._world:GetService("Config")
        local configData = sConfig:GetBuffConfigData(buffID) or {} --cfg即为cfg_buff的一条buff的配置
        local cfg = configData:GetData()
        local tmpCfg = {}
        ---TODO 优化一下写法 放两年了还todo呢
        tmpCfg["Load"] = {}
        tmpCfg["Load"].logic = table.cloneconf(cfg.LoadLogic) or {}
        tmpCfg["Active"] = {}
        tmpCfg["Active"].logic = table.cloneconf(cfg.ActiveLogic) or {}
        tmpCfg["Active"].trigger = table.cloneconf(cfg.ActiveTrigger)
        tmpCfg["Exec"] = {}
        tmpCfg["Exec"].logic = table.cloneconf(cfg.ExecLogic) or {}
        tmpCfg["Exec"].trigger = table.cloneconf(cfg.ExecTrigger)
        tmpCfg["Deactive"] = {}
        tmpCfg["Deactive"].logic = table.cloneconf(cfg.DeactiveLogic) or {}
        tmpCfg["Deactive"].trigger = table.cloneconf(cfg.DeactiveTrigger)
        tmpCfg["Unload"] = {}
        tmpCfg["Unload"].logic = table.cloneconf(cfg.UnloadLogic) or {}
        tmpCfg["Unload"].trigger = table.cloneconf(cfg.UnloadTrigger)
        self:DoEquipIntensify(buffID, tmpCfg, equipIntensifyParams)

        local alterLayer = {}
        local addLayerCount = {}

        local logic = tmpCfg.Load.logic
        local layerCheck, partialLayer
        if #logic == 0 then
            layerCheck = true
        else
            local utilData = self._world:GetService("UtilData")

            for index, l in ipairs(logic) do
                if l.logic == "AddLayer" then
                    local layerType = l.layerType or cfg.BuffEffectType
                    addLayerCount[layerType] = addLayerCount[layerType] or 0
                    local layer = utilData:GetBuffLayer(entity, layerType)
                    if (configData:GetMaxLayerCount() ~= 0) and (layer > 0) then
                        if (layer + addLayerCount[layerType] + l.layer) > configData:GetMaxLayerCount() then
                            if configData:GetMaxLayerCount() - layer - addLayerCount[layerType] > 0 then
                                -- 还有加的空间，只是加的不够多了
                                alterLayer[index] = configData:GetMaxLayerCount() - layer - addLayerCount[layerType]
                                addLayerCount[layerType] = addLayerCount[layerType] + alterLayer[index]
                            else
                                -- 根本加不了
                                alterLayer[index] = 0
                            end
                        else
                            addLayerCount[layerType] = addLayerCount[layerType] + l.layer
                        end
                    else
                        addLayerCount[layerType] = addLayerCount[layerType] + l.layer
                    end
                end
            end
        end

        --[[
            TODO: 如果这里的操作结果是加0层，是否应该添加是一个问题：
            AddLayer, layer=0; 是buff系统里的一种约定：表示“声明该单位具有这一效果，只是目前为0层不显示图标”
            目前没有处理这种情况，但数据记录是保留在buffInstance上，用来限制ClearLayer的最大数量的

            因原始问题中，未能添加层数的buff会造成表现错误（中毒层数为0但表现为中毒的紫色
            暂时处理为：如果完整计算之后发现没有实际添加任何层数，则本次加buff操作**无效**

            但受到整体上的限制，如果出现一个buff部分生效（如同时添加多个层数，但只有一个成功呢添加），则认为本次操作有效，以避免更深层或无法预期的问题
        ]]

        local isLayerChanged = false
        for _, v in pairs(addLayerCount) do
            if v > 0 then
                isLayerChanged = true
                break
            end
        end

        if isLayerChanged then
            buffInstance = self:CreateBuffInstance(buffID, entity, context, alterLayer, addLayerCount)
        end
    end

    return buffInstance
end

--人物结算buff阶段
function BuffLogicService:CalcPlayerBuffTurn(teamEntity)
    local svc = self._world:GetService("Trigger")
    --回合开始前触发
    svc:Notify(NTPlayerTurnStart:New(teamEntity))

    svc:Notify(NTEnemyTurnStart:New(teamEntity))

    --所有玩家回合开始的逻辑执行完之后，刷版会用到 --JinCe
    svc:Notify(NTPlayerTurnStartLast:New(teamEntity))

    --增加回合数
    local entityList = self._world:GetAllPlayerEntity(teamEntity)
    for i, e in ipairs(entityList) do
        if not e:HasPetDeadMark() then
            ---@type BuffComponent
            local buffCmpt = e:BuffComponent()
            local buffArray = buffCmpt:GetBuffArray()
            local buffCopy = table.shallowcopy(buffArray)
            for _, buffInstance in ipairs(buffCopy) do
                local buffEffectType = buffInstance:GetBuffEffectType()
                if table.icontains(_G.UnitTurnDelayStartEffectType, buffEffectType) then
                    Log.debug("CalcPlayerBuffTurn: buffEffectType: ", buffEffectType, ": lifecycle is delayed. ")
                else
                    buffInstance:AddRoundCount(NTPlayerTurnStart:New(teamEntity))
                end
            end
        end
    end

    svc:Notify(NTPlayerTurnBuffAddRoundEnd:New(teamEntity))
    svc:Notify(NTPlayerTurnBuffAddRoundEndAfter:New(teamEntity))
end

function BuffLogicService:CalcPlayerBuffDelayedTurn(teamEntity)
    --增加回合数
    local entityList = self._world:GetAllPlayerEntity(teamEntity)
    for i, e in ipairs(entityList) do
        if not e:HasPetDeadMark() then
            ---@type BuffComponent
            local buffCmpt = e:BuffComponent()
            local buffArray = buffCmpt:GetBuffArray()
            local buffCopy = table.shallowcopy(buffArray)
            for _, buffInstance in ipairs(buffCopy) do
                local buffEffectType = buffInstance:GetBuffEffectType()
                if table.icontains(_G.UnitTurnDelayStartEffectType, buffEffectType) then
                    Log.debug("CalcPlayerBuffDelayedTurn: buffEffectType: ", buffEffectType, ": delayed lifecycle processing. ")
                    buffInstance:AddRoundCount(NTPlayerTurnStart:New(teamEntity))
                end
            end
        end
    end
end

--棋子结算buff阶段
function BuffLogicService:CalcChessBuffTurn()
    --增加回合数
    local chessGroup = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for i, e in ipairs(chessGroup:GetEntities()) do
        if not e:HasDeadMark() and not e:BuffComponent():IsBuffFreeze() then
            ---@type BuffComponent
            local buffCmpt = e:BuffComponent()
            local buffArray = buffCmpt:GetBuffArray()
            local buffCopy = table.shallowcopy(buffArray)
            for _, buffInstance in ipairs(buffCopy) do
                buffInstance:AddRoundCount(NTPlayerTurnStart:New())
            end
        end
    end
end

--怪物结算buff阶段
function BuffLogicService:CalcMonsterBuffTurn(teamEntity)
    --回合开始
    self._world:GetService("Trigger"):Notify(NTMonsterTurnStart:New())
    --增加回合数
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)

    for i, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() and not e:BuffComponent():IsBuffFreeze() then
            ---@type BuffComponent
            local buffCmpt = e:BuffComponent()
            local buffArray = buffCmpt:GetBuffArray()
            ---@type BuffInstance[]
            local buffCopy = table.shallowcopy(buffArray)
            for _, buffInstance in ipairs(buffCopy) do
                local buffEffectType = buffInstance:GetBuffEffectType()
                if table.icontains(_G.UnitTurnDelayStartEffectType, buffEffectType) then
                    Log.debug("CalcMonsterBuffTurn: buffEffectType: ", buffEffectType, ": lifecycle is delayed. ")
                else
                    buffInstance:AddRoundCount(NTMonsterTurnStart:New())
                end
            end
        end
    end

    if teamEntity then
        --在怪物回合结算玩家身上的buff
        --buff的卸载条件 是MonsterTurnStart
        --满足回合计数 && 怪物回合卸载的 现在只有复仇刻印 2020.07.27
        local entityList = self._world:GetAllPlayerEntity(teamEntity)
        for i, e in ipairs(entityList) do
            ---@type BuffComponent
            local buffCmpt = e:BuffComponent()
            local buffArray = buffCmpt:GetBuffArray()
            local buffCopy = table.shallowcopy(buffArray)
            for _, buffInstance in ipairs(buffCopy) do
                local unloadNotifys = buffInstance:GetUnloadNotifyType()
                if #unloadNotifys > 0 and unloadNotifys[1] == NotifyType.MonsterTurnStart then
                    buffInstance:AddRoundCount(NTMonsterTurnStart:New())
                end
            end
        end
    end

    --计算buff回合后的怪物行动回合开始
    self._world:GetService("Trigger"):Notify(NTMonsterTurnAfterAddBuffRound:New())
end

function BuffLogicService:CalcMonsterBuffDelayedTurn()
    --增加回合数
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)

    for i, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() and not e:BuffComponent():IsBuffFreeze() then
            ---@type BuffComponent
            local buffCmpt = e:BuffComponent()
            local buffArray = buffCmpt:GetBuffArray()
            ---@type BuffInstance[]
            local buffCopy = table.shallowcopy(buffArray)
            for _, buffInstance in ipairs(buffCopy) do
                local buffEffectType = buffInstance:GetBuffEffectType()
                if table.icontains(_G.UnitTurnDelayStartEffectType, buffEffectType) then
                    Log.debug("CalcMonsterBuffDelayedTurn: buffEffectType: ", buffEffectType, ": delayed lifecycle processing. ")
                    buffInstance:AddRoundCount(NTMonsterTurnStart:New())
                end
            end
        end
    end

    --计算buff回合后的怪物行动回合开始
    self._world:GetService("Trigger"):Notify(NTMonsterTurnAfterDelayedAddBuffRound:New())
end

--选择buff目标
---@param casterEntity Entity
function BuffLogicService:CalcBuffTargetEntities(buffTargetType, buffTargetParam, casterEntity)
    --黑拳赛替换目标类型
    buffTargetType = self._world:ReplaceBuffTarget(buffTargetType)

    --正在加入伙伴时，替换buff目标
    ---@type PartnerServiceLogic
    local partnerSvc = self._world:GetService("PartnerLogic")
    if partnerSvc then
        buffTargetType = partnerSvc:ReplaceBuffTarget(buffTargetType)
        if buffTargetType == BuffTargetType.None then
            return {}
        end
    end
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local enemyEntities = {}

    --死的不加buff
    for i, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() then
            table.insert(enemyEntities, e)
        end
    end

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if casterEntity then
        if casterEntity:HasTeam() then
            teamEntity = casterEntity
        elseif casterEntity:HasPet() then
            teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        end
    end

    --根据施法者队伍判断敌方队伍
    if self._world:MatchType() == MatchType.MT_BlackFist then
        table.insert(enemyEntities, teamEntity:Team():GetEnemyTeamEntity())
    end

    local es = {}
    if buffTargetType == BuffTargetType.Self then
        es[#es + 1] = casterEntity
        return es
    elseif buffTargetType == BuffTargetType.AllMonster then
        if type(buffTargetParam) == "table" and buffTargetParam[1] == 1 then
            local t = {}
            local caster = casterEntity
            if casterEntity:HasSuperEntity() then
                caster = casterEntity:GetSuperEntity()
            end
            for i = 1, #enemyEntities do
                if enemyEntities[i]:GetID() ~= caster:GetID() then
                    table.insert(t, enemyEntities[i])
                end
            end
            enemyEntities = t
        end
        return enemyEntities
    elseif buffTargetType == BuffTargetType.OneGridMonster then
        for i, e in ipairs(enemyEntities) do
            if e:BodyArea():GetAreaCount() == 1 then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.MultiGridMonster then
        -- 改PetElement逻辑时需要同时改NonLeaderPetElement
        for i, e in ipairs(enemyEntities) do
            if e:BodyArea():GetAreaCount() > 1 then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.PetElement then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            local element = e:Element():GetPrimaryType()
            if table.icontains(buffTargetParam, element) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.AddPartnerAllPartnerPetElement then
        local tmpTeamEntity = self._world:Player():GetAddPartnerTempTeam()
        if tmpTeamEntity then
            local teamMembers = tmpTeamEntity:Team():GetTeamPetEntities()
            for i, e in ipairs(teamMembers) do
                local element = e:Element():GetPrimaryType()
                if table.icontains(buffTargetParam, element) then
                    table.insert(es, e)
                end
            end
        end
    elseif buffTargetType == BuffTargetType.NonLeaderPetElement then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            local eTeam = teamEntity
            local eidTeamLeader = eTeam:Team():GetTeamLeaderEntityID()

            local element = e:Element():GetPrimaryType()
            if (e:GetID() ~= eidTeamLeader) and table.icontains(buffTargetParam, element) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.RandomMonster then
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local mes = {}
        table.appendArray(mes, enemyEntities)
        local x = buffTargetParam and buffTargetParam or 1
        for i = 1, x do
            if #mes == 0 then
                break
            end

            local index = randomSvc:LogicRand(1, #mes)
            es[#es + 1] = mes[index]
            mes[index] = nil
        end
    elseif buffTargetType == BuffTargetType.AllPet then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                es[#es + 1] = e
            end
        end
        return es
    elseif buffTargetType == BuffTargetType.AddPartnerAllPartnerPet then
        local tmpTeamEntity = self._world:Player():GetAddPartnerTempTeam()
        if tmpTeamEntity then
            local teamMembers = tmpTeamEntity:Team():GetTeamPetEntities()
            for i, e in ipairs(teamMembers) do
                if not e:HasPetDeadMark() then
                    es[#es + 1] = e
                end
            end
            return es
        end
    elseif buffTargetType == BuffTargetType.RemoteTeamAllPet then
        local remoteTeam = self._world:Player():GetRemoteTeamEntity()
        local teamMembers = remoteTeam:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                es[#es + 1] = e
            end
        end
        return es
    elseif buffTargetType == BuffTargetType.Team then
        local playerEntity = teamEntity
        return {playerEntity}
    elseif buffTargetType == BuffTargetType.AddPartnerTmpTeam then
        local tmpTeamEntity = self._world:Player():GetAddPartnerTempTeam()
        if tmpTeamEntity then
            local playerEntity = tmpTeamEntity
            return {playerEntity}
        end
    elseif buffTargetType == BuffTargetType.AroundMonster then
        local curPos = casterEntity:GetGridPosition()
        --多格
        local curBodyArea = casterEntity:BodyArea():GetArea()

        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---@type SkillScopeCalculator
        local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
        --获取怪物 周围一圈
        local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.SquareRing, {1, 0}, curPos, curBodyArea)
        local attackRange = scopeResult:GetAttackRange()

        for _, e in ipairs(enemyEntities) do
            local pos = e:GetGridPosition()
            local bodyArea = e:BodyArea():GetArea()
            --怪物可能多格
            for i, area in ipairs(bodyArea) do
                local curMonsterBodyPos = pos + area
                if table.intable(attackRange, curMonsterBodyPos) then
                    table.insert(es, e)
                    break
                end
            end
        end
    elseif buffTargetType == BuffTargetType.RegularBodyMonster then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        for i, e in ipairs(enemyEntities) do
            if monsterConfigData:IsRegularShape(e:MonsterID():GetMonsterID()) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.MonsterHaventDragonMark then
        for _, e in ipairs(enemyEntities) do
            local buffComp = e:BuffComponent()
            if not buffComp:CheckHaveBuffById(buffTargetParam) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.AllTrap then
        local g = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
        return g:GetEntities()
    elseif buffTargetType == BuffTargetType.AnyAlive then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        local petAlive = {}
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                petAlive[#petAlive + 1] = e
            end
        end
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local r = randomSvc:LogicRand(1, #petAlive)
        es[1] = petAlive[r]
    elseif buffTargetType == BuffTargetType.LowHPPet then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        local lowhp = 0
        local target = nil
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                local hp = e:Attributes():GetCurrentHP()
                local max_hp = e:Attributes():CalcMaxHp()
                if lowhp == 0 or (hp < max_hp and hp < lowhp) then
                    lowhp = hp
                    target = e
                end
            end
        end
        es[1] = target
    elseif buffTargetType == BuffTargetType.HPBTPet then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                local hp = e:Attributes():GetCurrentHP()
                local max_hp = e:Attributes():CalcMaxHp()
                if hp / max_hp >= buffTargetParam then
                    es[#es + 1] = e
                end
            end
        end
    elseif buffTargetType == BuffTargetType.PetJob then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                local petPstID = e:PetPstID():GetPstID()
                local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
                local petJob = petData:GetJob()
                if table.icontains(buffTargetParam, petJob) then
                    es[#es + 1] = e
                end
            end
        end
    elseif buffTargetType == BuffTargetType.AddPartnerTmpPetJob then
        local tmpTeamEntity = self._world:Player():GetAddPartnerTempTeam()
        if tmpTeamEntity then
            local teamMembers = tmpTeamEntity:Team():GetTeamPetEntities()
            for i, e in ipairs(teamMembers) do
                if not e:HasPetDeadMark() then
                    local petPstID = e:PetPstID():GetPstID()
                    local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
                    local petJob = petData:GetJob()
                    if table.icontains(buffTargetParam, petJob) then
                        es[#es + 1] = e
                    end
                end
            end
        end
    elseif buffTargetType == BuffTargetType.BodyAreaGridElementCount then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        for i, e in ipairs(enemyEntities) do
            local pos = e:GetGridPosition()
            local area = e:BodyArea():GetArea()

            for _, v in ipairs(area) do
                local posWork = pos + v
                local pieceElement = utilData:FindPieceElement(Vector2(posWork.x, posWork.y))
                if buffTargetParam == pieceElement then
                    es[#es + 1] = e
                    break
                end
            end
        end
    elseif buffTargetType == BuffTargetType.SpecificPet then
        local petID = buffTargetParam[1]
        local friendTeam = buffTargetParam[2] or 0
        local rootTeam = buffTargetParam[3] or 0 -- 妮娜 机关 释放技能 或 机关上的buff通过holder放技能，找机关的召唤者光灵队伍
        --正常关卡里用来怪物给光灵挂buff，黑拳赛里是对方给己方挂buff
        if self._world:MatchType() == MatchType.MT_BlackFist then
            if friendTeam == 0 then
                teamEntity = teamEntity:Team():GetEnemyTeamEntity()
            end
            if rootTeam == 1 then
                if casterEntity then
                    local superEntity = casterEntity
                    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
                        superEntity = casterEntity:SuperEntityComponent():GetSuperEntity()
                    end
                    if superEntity then
                        if superEntity:HasSummoner() then
                            local ownerPet = superEntity:GetSummonerEntity()
                            if ownerPet:HasPet() then
                                teamEntity = ownerPet:Pet():GetOwnerTeamEntity()
                            end
                        end
                    end
                end
            end
        end
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            local cPetPstID = e:PetPstID()
            if petID == cPetPstID:GetTemplateID() then
                table.insert(es, e)
                break
            end
        end
    elseif buffTargetType == BuffTargetType.MonsterExceptBoss then
        local ret = {}
        --死的不加buff
        for i, e in ipairs(monsterGroup:GetEntities()) do
            if not e:HasDeadMark() and not e:HasBoss() then
                table.insert(ret, e)
            end
        end
        return ret
    elseif buffTargetType == BuffTargetType.MonsterOnlyBoss then
        local ret = {}
        --死的不加buff
        for i, e in ipairs(monsterGroup:GetEntities()) do
            if not e:HasDeadMark() and e:HasBoss() then
                table.insert(ret, e)
            end
        end
        return ret
    elseif buffTargetType == BuffTargetType.AllTalePet then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            ---@type PetPstIDComponent
            local cPetPstID = e:PetPstID()
            if Cfg.cfg_tale_pet({ID = cPetPstID:GetTemplateID()}) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.AddPartnerTmpAllTalePet then
        local tmpTeamEntity = self._world:Player():GetAddPartnerTempTeam()
        if tmpTeamEntity then
            local teamMembers = tmpTeamEntity:Team():GetTeamPetEntities()
            for i, e in ipairs(teamMembers) do
                ---@type PetPstIDComponent
                local cPetPstID = e:PetPstID()
                if Cfg.cfg_tale_pet({ID = cPetPstID:GetTemplateID()}) then
                    table.insert(es, e)
                end
            end
        end
    elseif buffTargetType == BuffTargetType.AllNonTalePet then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            ---@type PetPstIDComponent
            local cPetPstID = e:PetPstID()
            if not Cfg.cfg_tale_pet({ID = cPetPstID:GetTemplateID()}) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.AddPartnerTmpAllNonTalePet then
        local tmpTeamEntity = self._world:Player():GetAddPartnerTempTeam()
        if tmpTeamEntity then
            local teamMembers = tmpTeamEntity:Team():GetTeamPetEntities()
            for i, e in ipairs(teamMembers) do
                ---@type PetPstIDComponent
                local cPetPstID = e:PetPstID()
                if not Cfg.cfg_tale_pet({ID = cPetPstID:GetTemplateID()}) then
                    table.insert(es, e)
                end
            end
        end
    elseif buffTargetType == BuffTargetType.HPPercentHighestMonster then
        --场上血量百分比最高的怪物，如果百分比相同，取当前血量最高，还相同就随机
        local hpPercentHighestMonsterList = {}
        local hpPercentHighest = 0
        for i, e in ipairs(enemyEntities) do
            local hp = e:Attributes():GetCurrentHP()
            local max_hp = e:Attributes():CalcMaxHp()
            local hpPercent = hp / max_hp
            if hpPercent >= hpPercentHighest then
                if hpPercent > hpPercentHighest then
                    table.clear(hpPercentHighestMonsterList)
                    hpPercentHighest = hpPercent
                end

                table.insert(hpPercentHighestMonsterList, e)
            end
        end

        local hpHighestMonsterList = {}
        local hptHighest = 0
        for i, e in ipairs(hpPercentHighestMonsterList) do
            local hp = e:Attributes():GetCurrentHP()
            if hp >= hptHighest then
                if hp > hptHighest then
                    table.clear(hpHighestMonsterList)
                    hptHighest = hp
                end
                table.insert(hpHighestMonsterList, e)
            end
        end

        if table.count(hpHighestMonsterList) <= 1 then
            es = hpHighestMonsterList
        else
            --可以支持配置取几个
            ---@type RandomServiceLogic
            local randomSvc = self._world:GetService("RandomLogic")
            local randomIndex = randomSvc:LogicRand(1, #hpHighestMonsterList)
            table.insert(es, hpHighestMonsterList[randomIndex])
        end
    elseif buffTargetType == BuffTargetType.PetCamp then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for _, e in ipairs(teamMembers) do
            local camp = e:MatchPet():GetMatchPet():GetPetCamp()
            if table.icontains(buffTargetParam, camp) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.MonsterAI then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        for i, e in ipairs(enemyEntities) do
            local monsterID = e:MonsterID()
            local monsterAIIDList = monsterConfigData:GetMonsterAIID(monsterID:GetMonsterID())
            if table.icontains(buffTargetParam, monsterAIIDList[1][1]) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.SelectMonsterID then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        for i, e in ipairs(enemyEntities) do
            ---@type MonsterIDComponent
            local monsterID = e:MonsterID()
            if table.icontains(buffTargetParam, monsterID:GetMonsterID()) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.MaxDamageDealerPetToSelf then
        local cDamageStatistics = casterEntity:DamageStatisticsComponent()
        if cDamageStatistics then
            local array = cDamageStatistics:GetDamageSourceArray()
            for i = #array, 1, -1 do
                local e = self._world:GetEntityByID(array[i].entityID)
                if not e:HasPetPstID() then
                    goto BUFF_TARGET_MAX_DAMAGE_DEALER_PET_TO_SELF_CONTINUE
                end

                table.insert(es, e)
                break

                ::BUFF_TARGET_MAX_DAMAGE_DEALER_PET_TO_SELF_CONTINUE::
            end
        end
    elseif buffTargetType == BuffTargetType.NonCasterPetElement then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            local element = e:Element():GetPrimaryType()
            if (e:GetID() ~= casterEntity:GetID()) and table.icontains(buffTargetParam, element) then
                table.insert(es, e)
            end
        end
    elseif buffTargetType == BuffTargetType.BodyAreaGridElementProp then
        es = self:CalTargets_BodyAreaGridElementProp(buffTargetParam, enemyEntities)
    elseif buffTargetType == BuffTargetType.BodyAreaGridFindElement then
        es = self:CalTargets_BodyAreaGridFindElement(buffTargetParam, enemyEntities)
    elseif buffTargetType == BuffTargetType.CasterTeamLeader then
        local caster = casterEntity
        if caster:HasSuperEntity() then
            caster = caster:GetSuperEntity()
        end
        local cPet = caster:Pet()
        if cPet then
            local eTeam = cPet:GetOwnerTeamEntity()
            local cTeam = eTeam:Team()
            local eTeamLeader = cTeam:GetTeamLeaderEntity()
            table.insert(es, eTeamLeader)
        end
    elseif buffTargetType == BuffTargetType.AllAliveMonster then
        local excludeSelf = type(buffTargetParam) == "table" and buffTargetParam.ExcludeSelf == 1
        local t = {}
        local caster = casterEntity
        if casterEntity:HasSuperEntity() then
            caster = casterEntity:GetSuperEntity()
        end
        for i = 1, #enemyEntities do
            if (enemyEntities[i]:Attributes():GetCurrentHP() > 0) then
                if (not excludeSelf) or (enemyEntities[i]:GetID() ~= caster:GetID()) then
                    table.insert(t, enemyEntities[i])
                end
            end
        end
        enemyEntities = t
        return enemyEntities
    elseif buffTargetType == BuffTargetType.AllPetAndFeatureHolder then
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                es[#es + 1] = e
            end
        end
        ---@type FeatureServiceLogic
	    local lsvcFeature = self._world:GetService("FeatureLogic")
        if lsvcFeature then
            --目前只需要处理合击技施法者
            local holder = lsvcFeature:GetFeatureSkillHolderEntity(FeatureType.PersonaSkill)
            if holder then
                es[#es + 1] = holder
            end
        end
        return es
    elseif buffTargetType == BuffTargetType.CurrentTeamLeader then
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        if teamEntity then
            local teamLeader = teamEntity:Team():GetTeamLeaderEntity()
            table.insert(es,teamLeader)
        end
    elseif buffTargetType == BuffTargetType.CurrentTeamTail then
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        if teamEntity then
            ---@type TeamComponent
            local cTeam = teamEntity:Team()
            local teamOrder = cTeam:GetTeamOrder()
            local finalIndex = #teamOrder
            local lastPetPstID = teamOrder[finalIndex]
            local lastPetEntity = cTeam:GetPetEntityByPetPstID(lastPetPstID)
            table.insert(es,lastPetEntity)
        end
    elseif buffTargetType == BuffTargetType.SpTrap then
        --local needTrapID = buffTargetParam[1]
        local listTrap = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
        for i = 1, #listTrap do
            ---@type Entity
            local targetEntity = listTrap[i]
            ---@type TrapIDComponent
            local trapIDCmpt = targetEntity:TrapID()
            local trapID =trapIDCmpt:GetTrapID()
            if table.icontains(buffTargetParam, trapID) then
                table.insert(es,targetEntity)
            end
        end
    elseif buffTargetType == BuffTargetType.PartOfAllMonster then--全场一半(可配)的怪物（随机、向上取整）
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local totalMonsterCount = #enemyEntities
        if totalMonsterCount > 1 then
            local partRate = 0.5
            if type(buffTargetParam) == "table" and buffTargetParam.CountRate then
                partRate = buffTargetParam.CountRate
            end
            local needCount = math.ceil(totalMonsterCount * partRate)
            randomSvc:Shuffle(enemyEntities)
            local randTargets = {}
            for i = 1, needCount do
                if i <= totalMonsterCount then
                    table.insert(randTargets,enemyEntities[i])
                end
            end
            return randTargets
        else
            return enemyEntities
        end
    elseif buffTargetType == BuffTargetType.RandCountMonsterWithBuff then--有指定buff的怪物（随机N1~N2个）
        if type(buffTargetParam) == "table" and buffTargetParam.MatchBuffList then
            local matchBuffList = buffTargetParam.MatchBuffList
            if matchBuffList then
                ---@type RandomServiceLogic
                local randomSvc = self._world:GetService("RandomLogic")
                local matchBuffTargets = {}
                for index, enemyEneity in ipairs(enemyEntities) do
                    ---@type BuffComponent
                    local buffCmp = enemyEneity:BuffComponent()
                    if buffCmp then
                        local findBuff = false
                        for _, buffEffect in ipairs(matchBuffList) do
                            if buffCmp:HasBuffEffect(buffEffect) then
                                findBuff = true
                                break
                            end
                        end
                        if findBuff then
                            table.insert(matchBuffTargets,enemyEneity)
                        end
                    end
                end
                local matchTargetCount = #matchBuffTargets
                if matchTargetCount == 0 then
                    return {}
                end
                local countMin = buffTargetParam.CountMin or 1
                local countMax = buffTargetParam.CountMax or 1
                local randCount = randomSvc:LogicRand(countMin,countMax)
                randomSvc:Shuffle(matchBuffTargets)
                local randTargets = {}
                for i = 1, randCount do
                    if i <= matchTargetCount then
                        table.insert(randTargets,matchBuffTargets[i])
                    else
                        break
                    end
                end
                return randTargets
            end
        end
        return {}
    elseif buffTargetType == BuffTargetType.MonsterAICheckScopeHasTargetTrap then
        local aiID = buffTargetParam[1]
        local skillID = buffTargetParam[2]
        local trapID = buffTargetParam[3]
        local hasTrap = buffTargetParam[4] or 0 --不配默认0判断没有

        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        for i, e in ipairs(enemyEntities) do
            local monsterID = e:MonsterID()
            local monsterAIIDList = monsterConfigData:GetMonsterAIID(monsterID:GetMonsterID())
            if aiID == monsterAIIDList[1][1] then
                local selfPos = e:GetGridPosition()
                local dir = e:GridLocation().Direction
                local selfBodyArea = e:BodyArea():GetArea()
                ---@type SkillScopeResult
                local skillResult = self:_CalculateSkillScope(skillID, selfPos, dir, selfBodyArea)
                local skillRange = skillResult:GetAttackRange()
                local scopeHasTrapCount = 0
                --检查范围内是否有指定机关
                ---@type TrapServiceLogic
                local trapServerLogic = self._world:GetService("TrapLogic")
                local tarpPosList = trapServerLogic:FindTrapPosByTrapID(trapID)
                for _, pos in ipairs(tarpPosList) do
                    if table.intable(skillRange, pos) then
                        scopeHasTrapCount = scopeHasTrapCount + 1
                    end
                end

                if hasTrap == 0 and scopeHasTrapCount == 0 then
                    table.insert(es, e)
                elseif hasTrap ~= 0 and scopeHasTrapCount > 0 then
                    table.insert(es, e)
                end
            end
        end        
    elseif buffTargetType == BuffTargetType.Host then
        if casterEntity:HasAI() then
            ---@type AIComponentNew
            local aiComponent = casterEntity:AI()
            local attachMonsterID = aiComponent:GetRuntimeData("AttachMonsterID")

            ---@type Entity
            local hostEntity = self._world:GetEntityByID(attachMonsterID)
            if hostEntity then
                table.insert(es, hostEntity)
            end
        end
    elseif buffTargetType == BuffTargetType.PetJobsAndElement then
        local jobTypeList = buffTargetParam.JobType
        local elementTypeList = buffTargetParam.ElementType
        ---@type Entity[]
        local teamMembers = teamEntity:Team():GetTeamPetEntities()
        ---@param e Entity
        for i, e in ipairs(teamMembers) do
            if not e:HasPetDeadMark() then
                local petPstID = e:PetPstID():GetPstID()
                local petElement = e:Element():GetPrimaryType()
                local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
                local petJob = petData:GetJob()
                if table.icontains(jobTypeList, petJob) and table.icontains(elementTypeList, petElement) then
                    es[#es + 1] = e
                end
            end
        end
    end
    return es
end

--给某个entity增加某种buff的layer数
---@return number, BuffInstance
function BuffLogicService:AddBuffLayer(entity, buffEffectType, layer, pos, casterEntity)
    pos = pos or entity:GetGridPosition()
    -- --如果死亡不能挂层数
    -- if entity:Attributes():GetAttribute("HP")<=0 then
    --     return 0
    -- end
    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if not bc then
        return 0
    end
    --可能有bug：如果存在两个buffinstance配的最大层数不一致就按第一个算了
    local buffinst = bc:GetSingleBuffByBuffEffect(buffEffectType)
    if not buffinst then
        return 0
    end
    local oldFinalVal = buffinst:GetLayerCount()
    local newLayer, changeLayer = buffinst:AddLayerCount(layer)
    local key = buffinst:GetBuffLayerName()

    local layerName = buffinst:GetBuffLayerName()
    local totalKey = string.format(BattleConst.AddBuffLayerTotalKeyFormatter, layerName)
    local count = bc:GetBuffValue(totalKey) or 0
    --Log.error(self._className, "entityID:", entity:GetID(), "count:", count, "layer:", layer, "new count:", count+layer, Log.traceback())
    count = count + layer
    bc:SetBuffValue(totalKey, count)
    local nt = NTNotifyLayerChange:New(key, layer, count, pos, entity, buffEffectType, casterEntity)
    nt.__oldFinalLayer = oldFinalVal
    nt:SetChangeLayer(changeLayer)
    self._world:GetService("Trigger"):Notify(nt)
    return newLayer, buffinst
end

function BuffLogicService:GetBuffTotalLayer(entity, layerName)
    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if bc then
        local totalKey = string.format(BattleConst.AddBuffLayerTotalKeyFormatter, layerName)
        local layer = bc:GetBuffValue(totalKey) or 0
        return layer
    end
    return 0
end

function BuffLogicService:GetBuffLayer(entity, buffEffectType)
    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if bc then
        local key = self:GetBuffLayerName(buffEffectType)
        local layer = bc:GetBuffValue(key) or 0
        local mul = bc:GetBuffValue(key .. "Mul")
        if mul and layer then
            layer = layer * mul
        end
        if layer < 0 then
            layer = 0
        end
        return layer
    end
    return 0
end

--清空某buff的layer
function BuffLogicService:ClearBuffLayer(entity, buffEffectType)
    local bc = entity:BuffComponent()
    if bc then
        local key = self:GetBuffLayerName(buffEffectType)
        local oldLayer = bc:GetBuffValue(key) or 0
        bc:SetBuffValue(key, 0)
        local totalKey = string.format(BattleConst.AddBuffLayerTotalKeyFormatter, key)
        local count = bc:GetBuffValue(totalKey) or 0
        local instance = bc:GetSingleBuffByBuffEffect(buffEffectType)
        local casterEntity = (instance and instance:Context()) and instance:Context().casterEntity or nil
        local nt = NTNotifyLayerChange:New(key, 0, count, entity:GetGridPosition(), entity, buffEffectType, casterEntity)
        nt:SetChangeLayer(-oldLayer)
        self._world:GetService("Trigger"):Notify(nt)
    end
end

--设置某buff的layer
---@param entity Entity
function BuffLogicService:SetBuffLayer(entity, buffEffectType, layer, silenced)
    local bc = entity:BuffComponent()
    if bc then
        if layer < 0 then
            layer = 0
        end
        local instance = bc:GetSingleBuffByBuffEffect(buffEffectType)
        if instance then
            local maxLayer = instance:GetMaxBuffLayerCount()
            if (maxLayer > 0) and (layer > maxLayer) then
                Log.info(self._className, "request layer ", layer, " exceeds its limit: ", maxLayer)
                layer = maxLayer
            end
        elseif layer ~= 0 then
            Log.error(self._className, "尝试给没有计层buff的单位设置层数：buffEffectType:", buffEffectType, " layer:", layer, "trace:\n", Log.traceback())
        end
        local key = self:GetBuffLayerName(buffEffectType)
        local old = bc:GetBuffValue(key) or 0
        bc:SetBuffValue(key, layer)
        local totalKey = string.format(BattleConst.AddBuffLayerTotalKeyFormatter, key)
        local count = bc:GetBuffValue(totalKey) or 0
        local casterEntity = (instance and instance:Context()) and instance:Context().casterEntity or nil
        if not silenced then
            local nt = NTNotifyLayerChange:New(key, layer, count, entity:GetGridPosition(), entity, buffEffectType, casterEntity)
            nt.__oldFinalLayer = old
            nt:SetChangeLayer(layer - old)
            self._world:GetService("Trigger"):Notify(nt)
        end
        return layer, instance
    end
end

---设置层数加成的倍数
function BuffLogicService:SetBuffLayerMul(entity, buffEffectType, mul)
    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if bc then
        local key = self:GetBuffLayerName(buffEffectType)
        bc:SetBuffValue(key .. "Mul", mul)
    end
end

--根据buffEffectType得到对应的layerName
function BuffLogicService:GetBuffLayerName(buffEffectType)
    return "Layer" .. buffEffectType
end

-- --检查被击者是否免疫普攻
-- ---@param defender Entity
-- function BuffLogicService:CheckAttackImmunity(defender)
--     return defender:Attributes():GetAttribute("BuffAtkImmunity")
-- end

-- --检查是否免疫技能
-- ---@param defender Entity
-- function BuffLogicService:CheckMonsterSkillImmunity(defender)
--     return defender:Attributes():GetAttribute("BuffMonsterSkillImmunity")
-- end

--检查被击者是否免疫属性伤害
---@param defender Entity
---@param attacker Entity
function BuffLogicService:CheckElementImmunity(attacker, defender)
    local elementList = defender:Attributes():GetAttribute("BuffElementImmunity")

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local element = utilSvc:GetEntityElementType(attacker)

    if elementList ~= nil then
        for _, el in ipairs(elementList) do
            if element == el then
                return true
            end
        end
    end
    return false
end

function BuffLogicService:CheckLayerShield(entity)
    ---@type BuffComponent
    local buffComponent = entity:BuffComponent()
    if not buffComponent then
        return false, 0
    end
    local buffinst = buffComponent:GetSingleBuffByBuffEffect(BuffEffectType.LayerShield)
    if not buffinst then
        return false, 0
    end
    local shieldLayer = buffinst:GetLayerCount()
    if not shieldLayer or shieldLayer == 0 then
        return false, 0
    end

    return true, shieldLayer
end

function BuffLogicService:ReduceLayerShield(entity, layerCount, reducedAmount)
    -- 这个通知就是扣盾的逻辑：所有层数盾buff必须监听这个通知并执行扣除层数逻辑RemoveLayerShield
    self:GetService("Trigger"):Notify(NTReduceShieldLayer:New(entity, layerCount - reducedAmount))
end

---检测是否有护盾 如果有则减少一层护盾(逻辑)
function BuffLogicService:CheckAndReduceShield(entity)
    local hasLayerShield, shieldLayer = self:CheckLayerShield(entity)
    if not hasLayerShield then
        return false
    end

    self:ReduceLayerShield(entity, shieldLayer, 1)
    return true
end

---检查是否有【破除无敌】
---@param entity Entity
function BuffLogicService:CheckBreakInvincible(entity)
    if not entity then
        return false
    end
    local buffCom = entity:BuffComponent()
    return buffCom and buffCom:HasFlag(BuffFlags.BreakInvincible)
end

--检查entity是否被控
---@param entity Entity
function BuffLogicService:CheckControlled(entity)
    local cBuff = entity:BuffComponent()
    if cBuff then
        local buff = cBuff:GetBuffArrayByBuffType(BuffType.Control)
        return buff and table.count(buff) > 0
    end
    return false
end

--检查是否可以挂buff
---@param caster Entity
---@param defender Entity
function BuffLogicService:CheckCanAddBuff(caster, defender)
    if not self:CheckBreakInvincible(caster) and self:CheckInvincible(defender) then --无敌
        return false
    elseif defender:Attributes():GetAttribute("BuffMonsterSkillImmunity") then --魔免
        if
            caster:HasPetPstID() or
                (caster:HasSuperEntity() and caster:GetSuperEntity():HasPetPstID() and
                    caster:EntityType():IsSkillHolder())
         then
            return false
        end
    end
    return true
end

--检查是否可以被拉取
---@param entity Entity
function BuffLogicService:CheckCanBePullAround(entity)
    if self:CheckInvincible(entity) then --无敌
        return false
    end
    if self:CheckImmuneTranslate(entity, "ImmunePullAround") then
        return false
    end
    return true
end

--endregion

--检查是否可以被技能伤害
function BuffLogicService:CheckCanBeDamage(attacker, defender, skillID, ignoreShield)
    --是否普攻
    ----@type SkillLogicService
    local skillLogicService = self:GetService("SkillLogic")
    local isNormalSkill = skillLogicService:CheckNormalSkill(skillID)
    local isSingleEntitySkill = skillLogicService:IsSelectEntitySkill(skillID)
    local isGridSkill = skillLogicService:IsSelectGridSkill(skillID)
    local isAttackerTeamMember = false
    if attacker:HasPet() then
        local teamEntity = attacker:Pet():GetOwnerTeamEntity()
        if teamEntity then
            isAttackerTeamMember = not teamEntity:Team():IsTeamLeaderByEntityId(attacker:GetID())
        end
    end
    local attrComp = defender:Attributes()
    if not attrComp then
        Log.error("CheckCanBeDamage() defender has no attrComp")
        return DamageType.Guard
    end

    ---@type BuffComponent
    local cDefBuff = defender:BuffComponent()

    local damageType = DamageType.Normal
    if skillID and skillID > 0 and self:CheckMissAndEvade(skillID, attacker, defender) then --闪避
        damageType = DamageType.Miss
    elseif (not self:CheckBreakInvincible(attacker)) and self:CheckInvincible(defender) then --无敌
        damageType = DamageType.Guard
    elseif (not ignoreShield) and self:CheckAndReduceShield(defender) then --护盾
        damageType = DamageType.Guard
    elseif isNormalSkill and attrComp:GetAttribute("BuffAtkImmunity") then --普攻免疫
        damageType = DamageType.Guard
    elseif not isNormalSkill and attrComp:GetAttribute("BuffMonsterSkillImmunity") then --怪对玩家的技能免疫
        if
            attacker:HasPetPstID() or
                (attacker:HasSuperEntity() and attacker:GetSuperEntity():HasPetPstID() and
                    attacker:EntityType():IsSkillHolder())
         then
            damageType = DamageType.Guard
        end
    elseif self:CheckElementImmunity(attacker, defender) then --怪对玩家的属性伤害免疫
        damageType = DamageType.Guard
    elseif isSingleEntitySkill and attrComp:GetAttribute("BuffSingleEntitySkillImmunity") then --无法被单体伤害击中
        damageType = DamageType.Miss
    elseif isNormalSkill and attrComp:GetAttribute("BuffNormalSkillImmunity") then --无法被普攻击中
        damageType = DamageType.Miss
    elseif isGridSkill and attrComp:GetAttribute("BuffGridSkillImmunity") then --无法被格子伤害击中
        damageType = DamageType.Miss
    elseif
        isNormalSkill and cDefBuff:GetBuffValue("MaxNormalAtkCount") and cDefBuff:GetBuffValue("CurrentNormalAtkCount")
     then -- 一次连线流程中只受到N次普攻伤害
        if cDefBuff:GetBuffValue("CurrentNormalAtkCount") >= cDefBuff:GetBuffValue("MaxNormalAtkCount") then
            damageType = DamageType.Guard
        end
    elseif isAttackerTeamMember and attrComp:GetAttribute("BuffGuardDamageFromTeamMember") then --怪对玩家队伍中的队员伤害免疫
        damageType = DamageType.Guard
    end
    return damageType
end

---获得层数护盾的层数
function BuffLogicService:GetLayerShield(entity)
    local layer = 0

    ---@type BuffComponent
    local buffComponent = entity:BuffComponent()
    if buffComponent then
        ---@type BuffInstance
        local buffInstanceLayerShield = buffComponent:GetSingleBuffByBuffEffect(BuffEffectType.LayerShield)
        if buffInstanceLayerShield then
            layer = buffInstanceLayerShield:GetLayerCount()
        end
    end

    return layer
end

---检测是否会攻击丢失，miss与闪避都会导致攻伤害丢失
---@param skillID number
---@param attacker Entity
---@param defender Entity
---@return boolean  true表示成功闪避
function BuffLogicService:CheckMissAndEvade(skillID, attacker, defender)
    ---@type BuffComponent
    local defenderBuff = defender:BuffComponent()
    if defenderBuff then
        if defenderBuff:HasBuffEffect(BuffEffectType.Benumb) then
            --被击者麻痹会导致伤害必中
            return false
        end
    end   

    ---闪避几率公式： 闪避总数 = 猎人失误率（Buff修正）+ 猎物闪避率（基准值+Buff修正）  2020-06-19  韩玉信
    ---其中基准数据出现负数，则会增加命中几率
    local nEvadeEffect = 0
    ---@type AttributesComponent
    local attrDefender = defender:Attributes()
    ---基准闪避率取值范围是[0,1]
    local nEvadeBase = (attrDefender and attrDefender:GetAttribute("Evade")) or 0
    nEvadeEffect = nEvadeBase

    local cBuffDef = defender:BuffComponent()
    if cBuffDef then
        ----@type SkillLogicService
        local skillLogicService = self:GetService("SkillLogic")
        local isNormalSkill = skillLogicService:CheckNormalSkill(skillID)
        if isNormalSkill then
            local normalSkillEvade = cBuffDef:GetBuffValue("NormalSkillEvade") or 0
            nEvadeEffect = nEvadeEffect + normalSkillEvade
        end
    end

    ---@type BuffComponent
    local buffAttacker = attacker:BuffComponent()
    if buffAttacker then
        ---攻击发起者失误率取值范围[0,1]
        local nMiss = 0
        ---Miss为负数则增加命中
        nMiss = buffAttacker:GetBuffValue("Miss") or 0

        ---Bug：MSG57064 致盲Buff导致杰诺抽卡不扣除队伍血量
        if not self:IsSameTeam(attacker, defender) then
            nEvadeEffect = nEvadeEffect + nMiss
        end
    end

    if nEvadeEffect <= 0 then
        return false
    end
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local random = randomSvc:LogicRand()
    if random <= nEvadeEffect then
        return true
    end
    return false
end

---检测攻击者与被击者是否同队
---@param attacker Entity
---@param defender Entity
function BuffLogicService:IsSameTeam(attacker, defender)
    --获取攻击者所在队伍ID
    local attackerTeamEntityID = nil
    if attacker:HasPet() then
        ---@type Entity
        local teamEntity = attacker:Pet():GetOwnerTeamEntity()
        attackerTeamEntityID = teamEntity:GetID()
    elseif attacker:HasTeam() then
        attackerTeamEntityID = attacker:GetID()
    end

    --获取被击者所在队伍ID
    local defenderTeamEntityID = nil
    if defender:HasPet() then
        ---@type Entity
        local teamEntity = defender:Pet():GetOwnerTeamEntity()
        defenderTeamEntityID = teamEntity:GetID()
    elseif defender:HasTeam() then
        defenderTeamEntityID = defender:GetID()
    end    

    if defenderTeamEntityID and attackerTeamEntityID and defenderTeamEntityID == attackerTeamEntityID then
        return true
    end

    return false
end

---@param entityWork Entity
function BuffLogicService:AutoRemoveBuffByHit(entityWork)
    local buffComponent = entityWork:BuffComponent()
    if nil == buffComponent then
        return
    end

    local listAutoRemoveByHit = buffComponent:GetAutoRemoveByHit()
    for i = 1, #listAutoRemoveByHit do
        local nBuffID = listAutoRemoveByHit[i]
        local pBuffInstance = buffComponent:FindBuffByBuffID(nBuffID)
        if pBuffInstance and pBuffInstance:GetWorkRountCount() > 0 then
            self:RemoveBuffEffect(pBuffInstance)
            buffComponent:RemoveBuff(pBuffInstance)
            buffComponent:DelAutoRemoveByHit(nBuffID)
        end
    end
end

---@return boolean 返回true表示锁回合数,回合数不会减少,但是累计的回合数会增加
function BuffLogicService:DoGuideLockRoundCount(teamEntity)
    if not teamEntity then
        return false
    end

    ---@type BuffComponent
    local buffCmpt = teamEntity:BuffComponent()
    if buffCmpt == nil then
        return false
    end
    ---@type BuffInstance
    local buffInstance = buffCmpt:GetSingleBuffByBuffEffect(BuffEffectType.GuideLockRoundCount)
    if buffInstance then
        local guideRoundCount = buffCmpt:GetBuffValue("GuideLockRoundCount")
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        if battleStatCmpt:GetLevelLeftRoundCount() <= guideRoundCount then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
function BuffLogicService:GetAttributeValue(entity, attributeName)
    local value = entity:Attributes():GetAttribute(attributeName)
    return value
end

---只可以用于怪物和宝宝
function BuffLogicService:GetEntityAttackValue(entity)
    local baseAttack = entity:Attributes():GetAttribute("Attack")
    local attackConstantFix = entity:Attributes():GetAttribute("AttackConstantFix") or 0
    local attackPercentage = entity:Attributes():GetAttribute("AttackPercentage") or 0
    return math.floor((baseAttack * (1 + attackPercentage)) + attackConstantFix)
end

---获取entity的防御力
---@param entity Entity
function BuffLogicService:GetEntityDefenceValue(entity)
    local defence = entity:Attributes():GetAttribute("Defense") or 1
    ---@type FormulaService
    local sFormula = self._world:GetService("Formula")
    local defencePercentage = sFormula:CalcDefencePercentage(entity)
    local defenceConstantFix = sFormula:CalcDefenceConstantFix(entity)
    return math.floor(defence * (1 + defencePercentage) + defenceConstantFix)
end

function BuffLogicService:GetEntityMaxHPValue(entity)
    ---@type AttributesComponent
    local attributeCmpt
    if entity:HasPetPstID() then
        local teamEntity = entity:Pet():GetOwnerTeamEntity()
        attributeCmpt = teamEntity:Attributes()
    else
        attributeCmpt = entity:Attributes()
    end
    local maxHP = attributeCmpt:CalcMaxHp()
    return maxHP
end

---@param entity Entity
---@return MultModifyValue
function BuffLogicService:_GetAttributeModifier(entity, attributeName)
    local cAttributes = entity:Attributes()
    if cAttributes then
        local modifier = cAttributes:GetAttributeModifier(attributeName)
        return modifier
    else
        self:PrintBuffLogicSvcLog("### no Attributes component on entity. EntityId=", entity:GetID())
    end
end

function BuffLogicService:_AddAttributeValue(entity, attributeName, modifierID, value)
    local modifier = self:_GetAttributeModifier(entity, attributeName)
    if modifier then
        modifier:AddModify(value, modifierID)
        self:PrintBuffLogicSvcLog(
            "_AddAttributeValue() entity=",
            entity:GetID(),
            " attributeName=",
            attributeName,
            " modifyValue=",
            value,
            " finalValue=",
            modifier:Value()
        )
    else
        self:PrintBuffLogicSvcLog("_AddAttributeValue() not find modifier! ", attributeName, modifierID, value)
    end
end

function BuffLogicService:_RemoveAttributeValue(entity, attributeName, modifierID)
    local modifier = self:_GetAttributeModifier(entity, attributeName)
    if modifier then
        modifier:RemoveModify(modifierID)
        self:PrintBuffLogicSvcLog(
            "_RemoveAttributeValue() entity=",
            entity:GetID(),
            " attributeName=",
            attributeName,
            " finalValue=",
            modifier:Value()
        )
    else
        self:PrintBuffLogicSvcLog("_RemoveAttributeValue() not find modifier! ", attributeName, modifierID)
    end
end

-----Begin 修改伤害计算相关Buff使用的方法-----------------------------------------------------

---增加攻击类使用
---修改基础伤害计算公式中攻击参数使用
---@param modifierID number 修改属性的唯一值用来取消修改使用
---@param modifyType  number 修改类型
function BuffLogicService:ChangeBaseAttack(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifyBaseAttackType.Attack then
        self:_AddAttributeValue(entity, "Attack", modifierID, value)
    elseif modifyType == ModifyBaseAttackType.AttackPercentage then
        self:_AddAttributeValue(entity, "AttackPercentage", modifierID, value)
    elseif modifyType == ModifyBaseAttackType.AttackConstantFix then
        self:_AddAttributeValue(entity, "AttackConstantFix", modifierID, value)
    end
end

---移除修改
function BuffLogicService:RemoveBaseAttack(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifyBaseAttackType.Attack then
        self:_RemoveAttributeValue(entity, "Attack", modifierID)
    elseif modifyType == ModifyBaseAttackType.AttackPercentage then
        self:_RemoveAttributeValue(entity, "AttackPercentage", modifierID)
    elseif modifyType == ModifyBaseAttackType.AttackConstantFix then
        self:_RemoveAttributeValue(entity, "AttackConstantFix", modifierID)
    end
end

---修改基础伤害计算公式中防御参数使用
---@param modifierID number 修改属性的唯一值用来取消修改使用
---@param modifyType number 修改类型是乘还是加
function BuffLogicService:ChangeBaseDefence(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifyBaseDefenceType.Defense then
        self:_AddAttributeValue(entity, "Defense", modifierID, value)
    elseif modifyType == ModifyBaseDefenceType.DefencePercentage then
        self:_AddAttributeValue(entity, "DefencePercentage", modifierID, value)
    elseif modifyType == ModifyBaseDefenceType.DefenceConstantFix then
        self:_AddAttributeValue(entity, "DefenceConstantFix", modifierID, value)
    end
end

---移除修改
function BuffLogicService:RemoveBaseDefence(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifyBaseDefenceType.Defense then
        self:_RemoveAttributeValue(entity, "Defense", modifierID)
    elseif modifyType == ModifyBaseDefenceType.DefencePercentage then
        self:_RemoveAttributeValue(entity, "DefencePercentage", modifierID)
    elseif modifyType == ModifyBaseDefenceType.DefenceConstantFix then
        self:_RemoveAttributeValue(entity, "DefenceConstantFix", modifierID)
    end
end

function BuffLogicService:GetBaseDefence(entity, modifierID, modifyType)
    -- -@type MultModifyValue
    local modifier = nil
    local modifyValue = 0
    if modifyType == ModifyBaseDefenceType.Defense then
        modifier = self:_GetAttributeModifier(entity, "Defense")
    elseif modifyType == ModifyBaseDefenceType.DefencePercentage then
        modifier = self:_GetAttributeModifier(entity, "DefencePercentage")
    elseif modifyType == ModifyBaseDefenceType.DefenceConstantFix then
        modifier = self:_GetAttributeModifier(entity, "DefenceConstantFix")
    end

    if modifier then
        --有值也可能不是当前modiferID添加的值  会返回nil
        modifyValue = modifier:GetModifyValue(modifierID) or 0
    end

    return modifyValue
end

---修改最大血量参数使用
---@param modifierID number 修改属性的唯一值用来取消修改使用
---@param modifyType number 修改类型是乘还是加
function BuffLogicService:ChangeBaseMaxHP(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifyBaseMaxHPType.MaxHPPercentage then
        self:_AddAttributeValue(entity, "MaxHPPercentage", modifierID, value)
    elseif modifyType == ModifyBaseMaxHPType.MaxHPConstantFix then
        self:_AddAttributeValue(entity, "MaxHPConstantFix", modifierID, value)
    end
end

---移除修改
function BuffLogicService:RemoveBaseMaxHP(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifyBaseMaxHPType.MaxHPPercentage then
        self:_RemoveAttributeValue(entity, "MaxHPPercentage", modifierID)
    elseif modifyType == ModifyBaseMaxHPType.MaxHPConstantFix then
        self:_RemoveAttributeValue(entity, "MaxHPConstantFix", modifierID)
    end
end


---提高技能伤害类使用
function BuffLogicService:ChangeSkillIncrease(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifySkillIncreaseParamType.NormalSkill then
        self:_AddAttributeValue(entity, "NormalSkillIncreaseParam", modifierID, value)
    elseif modifyType == ModifySkillIncreaseParamType.ChainSkill then
        self:_AddAttributeValue(entity, "ChainSkillIncreaseParam", modifierID, value)
    elseif modifyType == ModifySkillIncreaseParamType.ActiveSkill then
        self:_AddAttributeValue(entity, "ActiveSkillIncreaseParam", modifierID, value)
    elseif modifyType == ModifySkillIncreaseParamType.MonsterDamage then
        self:_AddAttributeValue(entity, "MonsterSkillIncreaseParam", modifierID, value)
    elseif modifyType == ModifySkillIncreaseParamType.TrapDamage then
        self:_AddAttributeValue(entity, "TrapSkillIncreaseParam", modifierID, value)
    end
end

function BuffLogicService:RemoveSkillIncrease(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifySkillIncreaseParamType.NormalSkill then
        self:_RemoveAttributeValue(entity, "NormalSkillIncreaseParam", modifierID)
    elseif modifyType == ModifySkillIncreaseParamType.ChainSkill then
        self:_RemoveAttributeValue(entity, "ChainSkillIncreaseParam", modifierID)
    elseif modifyType == ModifySkillIncreaseParamType.ActiveSkill then
        self:_RemoveAttributeValue(entity, "ActiveSkillIncreaseParam", modifierID)
    elseif modifyType == ModifySkillIncreaseParamType.MonsterDamage then
        self:_RemoveAttributeValue(entity, "MonsterSkillIncreaseParam", modifierID)
    elseif modifyType == ModifySkillIncreaseParamType.TrapDamage then
        self:_RemoveAttributeValue(entity, "TrapSkillIncreaseParam", modifierID)
    end
end

---增加伤害类使用
function BuffLogicService:ChangeSkillParam(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifySkillParamType.NormalSkill then
        self:_AddAttributeValue(entity, "NormalSkillParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.ChainSkill then
        self:_AddAttributeValue(entity, "ChainSkillParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.ActiveSkill then
        self:_AddAttributeValue(entity, "ActiveSkillParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.MonsterDamage then
        self:_AddAttributeValue(entity, "MonsterSkillParam", modifierID, value)
    end
end

function BuffLogicService:RemoveSkillParam(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifySkillParamType.NormalSkill then
        self:_RemoveAttributeValue(entity, "NormalSkillParam", modifierID)
    elseif modifyType == ModifySkillParamType.ChainSkill then
        self:_RemoveAttributeValue(entity, "ChainSkillParam", modifierID)
    elseif modifyType == ModifySkillParamType.ActiveSkill then
        self:_RemoveAttributeValue(entity, "ActiveSkillParam", modifierID)
    elseif modifyType == ModifySkillParamType.MonsterDamage then
        self:_RemoveAttributeValue(entity, "MonsterSkillParam", modifierID)
    end
end

---修改额外属性克制系数
function BuffLogicService:ChangeExElementParam(entity, modifierID, value)
    self:_AddAttributeValue(entity, "ExElementParam", modifierID, value)
end

function BuffLogicService:RemoveExElementParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "ExElementParam", modifierID)
end

function BuffLogicService:ChangeExBeHitElementParam(entity, modifierID, value)
    self:_AddAttributeValue(entity, "ExBeHitElementParam", modifierID, value)
end

function BuffLogicService:RemoveExBeHitElementParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "ExBeHitElementParam", modifierID)
end

---修改最终伤害的参数
function BuffLogicService:ChangeSkillFinalParam(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifySkillParamType.NormalSkill then
        self:_AddAttributeValue(entity, "NormalSkillFinalParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.ChainSkill then
        self:_AddAttributeValue(entity, "ChainSkillFinalParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.ActiveSkill then
        self:_AddAttributeValue(entity, "ActiveSkillFinalParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.MonsterDamage then
        self:_AddAttributeValue(entity, "MonsterSkillFinalParam", modifierID, value)
    elseif modifyType == ModifySkillParamType.SanSkill then -- 其实不一定非得是san技能，但实在是想不出怎么命名了
        self:_AddAttributeValue(entity, "SanSkillFinalParam", modifierID, value)
    end
end

function BuffLogicService:RemoveSkillFinalParam(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == ModifySkillParamType.NormalSkill then
        self:_RemoveAttributeValue(entity, "NormalSkillFinalParam", modifierID)
    elseif modifyType == ModifySkillParamType.ChainSkill then
        self:_RemoveAttributeValue(entity, "ChainSkillFinalParam", modifierID)
    elseif modifyType == ModifySkillParamType.ActiveSkill then
        self:_RemoveAttributeValue(entity, "ActiveSkillFinalParam", modifierID)
    elseif modifyType == ModifySkillParamType.MonsterDamage then
        self:_RemoveAttributeValue(entity, "MonsterSkillFinalParam", modifierID)
    elseif modifyType == ModifySkillParamType.SanSkill then
        self:_AddAttributeValue(entity, "SanSkillFinalParam", modifierID)
    end
end

function BuffLogicService:GetMonsterSkillAbsorbBaseValue(entity, absorbType)
    ---@type MultModifyValue
    local modifier = nil
    if absorbType == MonsterSkillAbsorbType.NormalSkill then
        modifier = self:_GetAttributeModifier(entity, "AbsorbNormal")
    elseif absorbType == MonsterSkillAbsorbType.ChainSkill then
        modifier = self:_GetAttributeModifier(entity, "AbsorbChain")
    elseif absorbType == MonsterSkillAbsorbType.ActiveSkill then
        modifier = self:_GetAttributeModifier(entity, "AbsorbActive")
    end
    if modifier then
        local baseModifyId = 1
        return modifier:GetModifyValue(baseModifyId) --BaseValue()--获取基础值，目前看是modifyId为1的是配置中读取的初始值 sjs_todo
    else
        self:PrintBuffLogicSvcLog("GetMonsterSkillAbsorbBaseValue() not find modifier! type ", absorbType)
    end
end

function BuffLogicService:ChangeMonsterSkillAbsorb(entity, modifierID, modifyType, value)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == MonsterSkillAbsorbType.NormalSkill then
        self:_AddAttributeValue(entity, "AbsorbNormal", modifierID, value)
    elseif modifyType == MonsterSkillAbsorbType.ChainSkill then
        self:_AddAttributeValue(entity, "AbsorbChain", modifierID, value)
    elseif modifyType == MonsterSkillAbsorbType.ActiveSkill then
        self:_AddAttributeValue(entity, "AbsorbActive", modifierID, value)
    end
end

function BuffLogicService:RemoveMonsterSkillAbsorb(entity, modifierID, modifyType)
    ---@type MultModifyValue
    local modifier = nil
    if modifyType == MonsterSkillAbsorbType.NormalSkill then
        self:_RemoveAttributeValue(entity, "AbsorbNormal", modifierID)
    elseif modifyType == MonsterSkillAbsorbType.ChainSkill then
        self:_RemoveAttributeValue(entity, "AbsorbChain", modifierID)
    elseif modifyType == MonsterSkillAbsorbType.ActiveSkill then
        self:_RemoveAttributeValue(entity, "AbsorbActive", modifierID)
    end
end

function BuffLogicService:ChangeChainSkillReleaseFix(entity, modifierID, value)
    self:_AddAttributeValue(entity, "ChainSkillReleaseFix", modifierID, value)
end

function BuffLogicService:RemoveChainSkillReleaseFix(entity, modifierID)
    self:_RemoveAttributeValue(entity, "ChainSkillReleaseFix", modifierID)
end

function BuffLogicService:ChangeChainSkillReleaseMul(entity, modifierID, value)
    self:_AddAttributeValue(entity, "ChainSkillReleaseMul", modifierID, value)
end

function BuffLogicService:RemoveChainSkillReleaseMul(entity, modifierID)
    self:_RemoveAttributeValue(entity, "ChainSkillReleaseMul", modifierID)
end

function BuffLogicService:ChangeDamagePercentAmpfily(entity, modifierID, value)
    self:_AddAttributeValue(entity, "DamagePercentAmpfily", modifierID, value)
end

function BuffLogicService:RemoveDamagePercentAmpfily(entity, modifierID)
    self:_RemoveAttributeValue(entity, "DamagePercentAmpfily", modifierID)
end

function BuffLogicService:ChangeTrueDamageFixParam(entity, modifierID, value)
    self:_AddAttributeValue(entity, "TrueDamageFixParam", modifierID, value)
end

function BuffLogicService:RemoveTrueDamageFixParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "TrueDamageFixParam", modifierID)
end

function BuffLogicService:ChangeDamageGlancingParam(entity, modifierID, percent, maxValue)
    self:_AddAttributeValue(entity, "GlancingRate", modifierID, percent)
    self:_AddAttributeValue(entity, "GlancingMaxValue", modifierID, maxValue)
end

function BuffLogicService:RemoveDamageGlancingParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "GlancingRate", modifierID)
    self:_RemoveAttributeValue(entity, "GlancingMaxValue", modifierID)
end

function BuffLogicService:ChangeAdditionalCritProb(entity, modifierID, val)
    self:_AddAttributeValue(entity, "AdditionalCritProb", modifierID, val)
end

function BuffLogicService:RemoveAdditionalCritProb(entity, modifierID, val)
    self:_RemoveAttributeValue(entity, "AdditionalCritProb", modifierID)
end

function BuffLogicService:ChangeAdditionalCritParam(entity, modifierID, val)
    self:_AddAttributeValue(entity, "AdditionalCritParam", modifierID, val)
end

function BuffLogicService:RemoveAdditionalCritParam(entity, modifierID, val)
    self:_RemoveAttributeValue(entity, "AdditionalCritParam", modifierID)
end

function BuffLogicService:ChangeControlIncrease(entity, modifierID, val)
    self:_AddAttributeValue(entity, __AttrKey_ControlIncrease, modifierID, val)
end

function BuffLogicService:RemoveControlIncrease(entity, modifierID)
    self:_RemoveAttributeValue(entity, __AttrKey_ControlIncrease, modifierID)
end

function BuffLogicService:ChangeFinalBeHitDamageParam(entity, modifierID, value)
    self:_AddAttributeValue(entity, "FinalBehitDamageParam", modifierID, value)
end

function BuffLogicService:RemoveFinalBeHitDamageParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "FinalBehitDamageParam", modifierID)
end

function BuffLogicService:ChangeFinalBehitByTeamLeaderDamageParam(entity, modifierID, value)
    self:_AddAttributeValue(entity, "FinalBehitByTeamLeaderDamageParam", modifierID, value)
end

function BuffLogicService:RemoveFinalBehitByTeamLeaderDamageParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "FinalBehitByTeamLeaderDamageParam", modifierID)
end

function BuffLogicService:ChangeFinalBehitByTeamMemberDamageParam(entity, modifierID, value)
    self:_AddAttributeValue(entity, "FinalBehitByTeamMemberDamageParam", modifierID, value)
end

function BuffLogicService:RemoveFinalBehitByTeamMemberDamageParam(entity, modifierID)
    self:_RemoveAttributeValue(entity, "FinalBehitByTeamMemberDamageParam", modifierID)
end

function BuffLogicService:_AddBuff2AllMonster(buffIDList, monsterList, buffSource, equipIntensifyParams)
    for _, monster in ipairs(monsterList) do
        for _, buffID in ipairs(buffIDList) do
            self:AddBuff(buffID, monster, nil, buffSource, equipIntensifyParams)
        end
    end
end

function BuffLogicService:ChangeSecondaryAttackParam(entity, modifierID, val)
    self:_AddAttributeValue(entity, "SecondaryAttackParam", modifierID, val)
end

function BuffLogicService:RemoveSecondaryAttackParam(entity, modifierID, val)
    self:_RemoveAttributeValue(entity, "SecondaryAttackParam", modifierID)
end

function BuffLogicService:BuildPetPassiveSkill(teamEntity)
    local petEntityList = teamEntity:Team():GetTeamPetEntities()
    ---@type ConfigService
    local configServer = self._world:GetService("Config")
    for _, petEntity in ipairs(petEntityList) do
        local passiveSkillID = petEntity:SkillInfo():GetPassiveSkillID()
        local equipIntensifyParams = petEntity:SkillInfo():GetEquipIntensifyParam()
        if passiveSkillID and passiveSkillID ~= 0 then
            local config = configServer:GetPetPassiveSkill(passiveSkillID)
            if config and config.BuffID then
                local buffSource = BuffSource:New(BuffSourceType.PassiveSkill, petEntity:PetPstID():GetPstID())
                for _, buffID in ipairs(config.BuffID) do
                    self:AddBuffByTargetType(
                        buffID,
                        config.BuffTargetType,
                        config.BuffTargetParam,
                        {casterEntity = petEntity},
                        buffSource,
                        equipIntensifyParams,
                        petEntity
                    )
                end
            end
        end
    end

    ---玩家带的光灵，有可能需要立即触发一些BUFF，可以放到这里
    for _, petEntity in ipairs(petEntityList) do
        ---大招就绪通知
        local ready = petEntity:Attributes():GetAttribute("Ready")
        if ready == 1 then
            local notify = NTPowerReady:New(petEntity)
            self._world:GetService("Trigger"):Notify(notify)
        end
    end
end
---设置星灵的强化buff--挂载强化buff时也应用了装备精炼里的强化
function BuffLogicService:BuildPetIntensifyBuff(teamEntity)
    local teamEntities = teamEntity:Team():GetTeamPetEntities()

    for _, petEntity in ipairs(teamEntities) do
        local buffList = petEntity:SkillInfo():GetIntensifyBuffList()
        local intensifyParams = {}
        local equipIntensifyParams = petEntity:SkillInfo():GetEquipIntensifyParam()--来自装备的强化参数
        local equipRefineIntensifyParams = petEntity:EquipRefine():GetEquipRefineIntensifyParam()--来自装备精炼的强化参数
        if equipIntensifyParams and type(equipIntensifyParams) == "table" then  
            local cloneEquipIntensifyParam = table.clone(equipIntensifyParams)
            if equipRefineIntensifyParams then 
                ---遍历装备强化参数列表
                local appendList = {}
                for _,equipRefineParam in ipairs(equipRefineIntensifyParams) do
                    local findInOldParam = false
                    for equipKey, equipParam in ipairs(cloneEquipIntensifyParam) do
                        if equipParam.BuffID == equipRefineParam.BuffID then
                            --相同BuffID的已经用装备精炼的配置替换过了
                            findInOldParam = true
                            break
                        end
                    end
                    if not findInOldParam then
                        table.insert(appendList,equipRefineParam)
                    end
                end
                table.appendArray(cloneEquipIntensifyParam,appendList)
                intensifyParams = cloneEquipIntensifyParam
            end
        else
            intensifyParams = equipRefineIntensifyParams
        end
        local buffSource = BuffSource:New(BuffSourceType.SkillIntensify, petEntity:PetPstID():GetPstID())
        if buffList and #buffList > 0 then
            for k, buffID in ipairs(buffList) do
                self:AddBuff(buffID, petEntity, nil, buffSource, intensifyParams)
            end
        end
    end
end

function BuffLogicService:BuildPetEquipRefineBuff(teamEntity)
    local petEntityList = teamEntity:Team():GetTeamPetEntities()

    for _, petEntity in ipairs(petEntityList) do
        local buffList = petEntity:EquipRefine():GetEquipRefineBuffList()
        if buffList then
            local buffSource = BuffSource:New(BuffSourceType.EquipRefine, petEntity:PetPstID():GetPstID())
            for _, buffID in ipairs(buffList) do
                self:AddBuff(buffID, petEntity, nil, buffSource)
            end
        end
    end

    ---玩家带的光灵，有可能需要立即触发一些BUFF，可以放到这里
    for _, petEntity in ipairs(petEntityList) do
        ---大招就绪通知
        local ready = petEntity:Attributes():GetAttribute("Ready")
        if ready == 1 then
            local notify = NTPowerReady:New(petEntity)
            self._world:GetService("Trigger"):Notify(notify)
        end
    end
end

function BuffLogicService:RefreshLockHPLogic()
    local gsmState = self._world:GameFSM():CurStateID()
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local round = battleStatCmpt:GetCurWaveTotalRoundCount()
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        if not monsterEntity:HasDeadMark() then
            ---@type BuffComponent
            local buffCmpt = monsterEntity:BuffComponent()
            if buffCmpt:IsHPNeedUnLock(round - 1, gsmState) then
                buffCmpt:RecordUnlockHPIndex(buffCmpt:GetHPLockIndex())
                buffCmpt:RecordLastUnlockHPRound(round)
                buffCmpt:ResetHPLockState()
                local isUnlockHP = buffCmpt:GetBuffValue("IsUnlockHP")
                self._world:GetService("Trigger"):Notify(NTBreakHPLock:New(monsterEntity, isUnlockHP))
            end
        end
    end
end

---@param targetEntity Entity
function BuffLogicService:CalcAddTimesByParam(addBuffType, buffCountParam, casterEntity, targetEntity, notify)
    local count = 1

    if addBuffType == SkillAddBuffType.ByCostHPPercent then
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        local hp, maxHP = battleService:GetCasterHP(casterEntity)
        if not buffCountParam.percent or not buffCountParam.maxCount then
            Log.exception("AddBuffParam buffCountParam Invalid skillID:", skillEffectCalcParam:GetSkillID())
            return count
        end
        local costHPPercent = (maxHP - hp) / maxHP * 100
        local addCount = math.modf(costHPPercent / buffCountParam.percent)
        if addCount > buffCountParam.maxCount then
            addCount = buffCountParam.maxCount
        end
        count = addCount + count
    elseif addBuffType == SkillAddBuffType.BySurroundingTargetCount then
        local scopeParam = buffCountParam
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)
        ---@type SkillScopeResult
        local scopeResult =
            scopeCalc:ComputeScopeRange(
            scopeParam.scopeType,
            scopeParam.scopeParam,
            casterEntity:GetGridPosition(),
            casterEntity:BodyArea():GetArea(),
            casterEntity:GetGridDirection(),
            scopeParam.scopeTargetType,
            casterEntity:GetGridPosition(),
            casterEntity
        )
        ---@type SkillScopeTargetSelector
        local targetSelector = self._world:GetSkillScopeTargetSelector()
        local targets = targetSelector:DoSelectSkillTarget(casterEntity, scopeParam.scopeTargetType, scopeResult)

        local tids = {}
        for _, tid in ipairs(targets) do
            if not table.icontains(tids, tid) then
                table.insert(tids, tid)
            end
        end

        count = #tids
    elseif addBuffType == SkillAddBuffType.MultipleTimes then
        local curBuffLayer = self:GetBuffLayer(targetEntity, buffCountParam.targetBuffEffect)
        if curBuffLayer == nil then
            count = 0
            return count
        end
        local newBuffLayer = math.floor(curBuffLayer * buffCountParam.multipleTimes)
        if newBuffLayer > buffCountParam.maxLayer then
            newBuffLayer = buffCountParam.maxLayer
        end

        count = newBuffLayer - curBuffLayer
    elseif addBuffType == SkillAddBuffType.LimitMaxCount then
        ---@type BuffComponent
        local cBuff = targetEntity:BuffComponent()
        if cBuff then
            local buff = cBuff:GetBuffArrayByBuffEffect(buffCountParam.targetBuffEffect)
            if buffCountParam.limitMaxCount <= table.count(buff) then
                count = 0
            end
        end
    elseif addBuffType == SkillAddBuffType.ByCasterTeamOrderDrop then
        local caster = casterEntity
        if caster:HasSuperEntity() then
            caster = caster:GetSuperEntity()
        end
        if not caster:HasPetPstID() then
            Log.exception("AddBuffTypeException: 施加者不是光灵不能使用addBuffType==7")
            goto CONTINUE
        end
        if (not notify) or (notify:GetNotifyType() ~= NotifyType.TeamOrderChange) then
            Log.exception("AddBuffTypeException: addBuffType==7要配合buff通知131使用")
            goto CONTINUE
        end
        local petPstID = caster:PetPstID():GetPstID()
        local oldIndex = table.ikey(notify:GetOldTeamOrder(), petPstID)
        local newIndex = table.ikey(notify:GetNewTeamOrder(), petPstID)
        local change = newIndex - oldIndex
        count = math.max(0, change)
        ::CONTINUE::
    end

    return count
end

---通过BuffID 获取装备强化
---@param equipIntensifyParams BuffIntensifyParam[]
function BuffLogicService:GetEquipIntensifyParam(equipIntensifyParams, buffID)
    if equipIntensifyParams then
        for _, v in ipairs(equipIntensifyParams) do
            if v.BuffID and v.BuffID == buffID then
                return v
            end
        end
    end
    return self._world:BattleStat():GetBuffIntensifyParam(buffID)
end

---出于复杂度的考虑 暂时只支持二层索引修改变量 层级太多的需要修改原始BuffLogic的配置
function BuffLogicService:_ExchangeBuffLogicParam(key, value, cfg)
    if cfg then
        local cfgLogic = cfg
        for cfgLogicKey, cfgLogicValue in pairs(cfgLogic) do
            if cfgLogicKey == key.param then
                cfg[cfgLogicKey] = value
                return true
            end
            if type(cfgLogicValue) == "table" then
                for cfgLogicValue_key, cfgLogicValue_value in pairs(cfgLogicValue) do
                    if type(cfgLogicValue_key) == "number" and key.paramIndex and key.paramIndex == cfgLogicValue_key then
                        if type(cfgLogicValue_value) == "table" then
                            for cfgLogicValue_value_key, v in pairs(cfgLogicValue_value) do
                                if cfgLogicValue_value_key == key.param then
                                    cfg[cfgLogicKey][cfgLogicValue_key][cfgLogicValue_value_key] = value
                                    --v = value
                                    return true
                                end
                            end
                        else
                            cfg[cfgLogicKey][cfgLogicValue_key] = value
                            --cfgLogicValue_value = value
                            return true
                        end
                    elseif cfgLogicValue_key == key.param then
                        cfg[cfgLogicKey][cfgLogicValue_key] = value
                        --cfgLogicValue_value = value
                        return true
                    end
                end
            end
        end
        return false
    else
        return false
    end
end

function BuffLogicService:_ExChangeBuffTriggerParam(value, triggerIndex, triggerParamIndex, cfgTrigger)
    if cfgTrigger and cfgTrigger[triggerIndex] and cfgTrigger[triggerIndex][triggerParamIndex] then
        cfgTrigger[triggerIndex][triggerParamIndex] = value
        return true
    else
        return false
    end
end

---根据装备强化数据修改buff配置
---只处理cfg_pet_equip中elementParam字段中field形式的：[1]={BuffID=4100591,[1]={field="LayerCount",value=2}}
---@param buffInstance BuffInstance
function BuffLogicService:UpdateBuffInstanceField(buffInstance, equipIntensifyParams)
    if not buffInstance then
        Log.fatal("### buffInstance nil")
        return
    end
    local buffId = buffInstance:BuffID()
    ---@type BuffIntensifyParam[]
    local equipIntensifyParam = self:GetEquipIntensifyParam(equipIntensifyParams, buffId)
    if not equipIntensifyParam then
        --Log.fatal("### equipIntensifyParam nil. buffId=", buffId)
        return
    end
    for _, v in ipairs(equipIntensifyParam) do
        if v.field then
            local field = v.field
            local value = v.value
            if field == "LayerCount" then
                buffInstance:SetMaxBuffLayerCount(value)
            else
                Log.fatal("### no such kind of field. need to extend. field=", field)
            end
        end
    end
end

---根据装备强化数据修改buff配置
function BuffLogicService:DoEquipIntensify(buffID, cfg, equipIntensifyParams)
    local ret = true
    ---@type BuffIntensifyParam[]
    local equipIntensifyParam = self:GetEquipIntensifyParam(equipIntensifyParams, buffID)
    if equipIntensifyParam then
        for _, v in ipairs(equipIntensifyParam) do
            if v.key then
                if v.key.LogicType then
                    if not v.key.LogicIndex then
                        v.key.LogicIndex = 1
                    end
                    if cfg[v.key.LogicType] and cfg[v.key.LogicType].logic then
                        ret = self:_ExchangeBuffLogicParam(v.key, v.value, cfg[v.key.LogicType].logic[v.key.LogicIndex])
                    else
                        break
                    end
                end
                if v.key.TriggerType then
                    if not v.key.TriggerIndex or not v.key.TriggerParamIndex then
                        break
                    end
                    if cfg[v.key.TriggerType] and cfg[v.key.TriggerType].trigger then
                        ret =
                            self:_ExChangeBuffTriggerParam(
                            v.value,
                            v.key.TriggerIndex,
                            v.key.TriggerParamIndex,
                            cfg[v.key.TriggerType].trigger
                        )
                    else
                        break
                    end
                end
            end
        end
    end

    if not ret then
        ---为了方便验证这里暂时就写成配错了就GG
        Log.exception("EquipIntensify Config failed BuffID:", buffID)
    end
end

---@param buffSource BuffSource
---@return Entity
function BuffLogicService:GetBuffSourceEntity(buffSource)
    if buffSource then
        local sourceType = buffSource:GetSourceType()
        local sourceID = buffSource:GetSourceID()
        if sourceType == BuffSourceType.SkillIntensify or BuffSourceType.PassiveSkill then
            local petEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.PetPstID)
            for i, petEntity in ipairs(petEntityList) do
                if petEntity:PetPstID() and petEntity:PetPstID():GetPstID() == sourceID then
                    return petEntity
                end
            end
        end
    end
    return nil
end

--检查是否可以被击退
---@param entity Entity
function BuffLogicService:CheckCanBeHitBack(entity)
    if self:CheckInvincible(entity) then --无敌
        return false
    end
    if self:CheckImmuneTranslate(entity, "ImmuneHitBack") then
        return false
    end
    if self:CheckControlImmunity(entity) then --免控
        return false
    end
    return true
end

--检查是否无敌
function BuffLogicService:CheckInvincible(entity)
    if not entity then
        return false
    end
    local buffCom = entity:BuffComponent()
    return buffCom and buffCom:HasFlag(BuffFlags.Invincible)
end

---@param entity Entity
---是否免疫translateType类型的位移
function BuffLogicService:CheckImmuneTranslate(entity, translateType)
    local cBuff = entity:BuffComponent()
    if not cBuff then
        return false
    end
    local val = cBuff:GetBuffValue(translateType) or false
    return val
end

--检查是否免控
---@param entity Entity
function BuffLogicService:CheckControlImmunity(entity)
    local buffCmp = entity:BuffComponent()
    return buffCmp and buffCmp:HasBuffEffect(BuffEffectType.ControlImmunized)
end
--检查是否 免疫 强制位移（及牵引的强制效果）
---@param entity Entity
function BuffLogicService:CheckForceMoveImmunity(entity)
    local buffCmp = entity:BuffComponent()
    return buffCmp and buffCmp:HasBuffEffect(BuffEffectType.ForceMoveImmunized)
end
--是否可被魔法攻击
function BuffLogicService:CheckCanBeMagicAttack(attacker, defender)
    local buffLogic = self._world:GetService("BuffLogic")
    local attrComp = defender:Attributes()
    if buffLogic:CheckElementImmunity(attacker, defender) then
        return false
    end
    if self:CheckInvincible(defender) then
        return false
    end

    --只对宝宝释放和宝宝的buff释放的技能免疫
    if attrComp:GetAttribute("BuffMonsterSkillImmunity") then
        if
            attacker:HasPetPstID() or
                (attacker:HasSuperEntity() and attacker:GetSuperEntity():HasPetPstID() and
                    attacker:EntityType():IsSkillHolder())
         then
            return false
        end
    end
    return true
end

---属性强化buff加血处理，仅适用于怪身上挂了属性强化buff，人打怪的情况
---@return number 属性强化标记
--- -1-属性强化buff无效；
--- 0-人克怪；1-怪克人；2-无克制关系；
function BuffLogicService:CheckElementReinforce(caster, defender)
    if (not caster) or (not defender) or not caster:HasPetPstID() or not defender:Attributes() then
        return -1
    end
    local isElementReinforce = defender:Attributes():GetAttribute("ElementReinforce")
    if not isElementReinforce then
        return -1
    end

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local t1 = utilSvc:GetEntityElementType(caster)
    local t2 = utilSvc:GetEntityElementType(defender)

    ---@type FormulaService
    local sFormula = self._world:GetService("Formula")
    return sFormula:GetRestrainFlag(t1, t2, caster, defender)
end

function BuffLogicService:CheckSealedCurse(e)
    if not e:HasPetPstID() then
        return false
    end

    local buffCom = e:BuffComponent()
    return buffCom and buffCom:HasFlag(BuffFlags.SealedCurse)
end

function BuffLogicService:PrintBuffLogicSvcLog(...)
    if self._world and self._world:IsDevelopEnv() then
        Log.debug(...)
    end
end

---@param e Entity
function BuffLogicService:ChangePetActiveSkillReady(e, ready,skillID)
    self:PrintBuffLogicSvcLog("BuffLogicService:ChangePetActiveSkillReady: eid=", e:GetID(), "ready=", ready)
    local r = ready
    if e:HasBuffFlag(BuffFlags.SealedCurse) then
        Log.debug("SealedCurse detected. Set ready to 0. ")
        r = 0
    elseif self:IsPetActiveSkillCanNotReadyByBuff(e) then
        r = 0
    end
    if not skillID then
        e:Attributes():Modify("Ready", r)
    else
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local isExtraSkill,extraSkillIndex = utilData:IsPetExtraActiveSkill(e,skillID)
        if isExtraSkill then
            if self:IsPetExtraActiveSkillCanNotReadyByBuff(e,skillID) then
                r = 0
            end
            local readyKey = "Ready" .. tostring(extraSkillIndex)
            e:Attributes():SetSimpleAttribute(readyKey, r)
        else
            e:Attributes():Modify("Ready", r)
        end
    end
    return r
end
function BuffLogicService:BuffSetPetActiveSkillCanNotReady(e, bSet, reason)
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    if buffCmpt then
        local setVal = bSet and 1 or 0
        buffCmpt:SetBuffValue("BuffSetCanNotReady", setVal)
        if bSet then
            if reason then
                local tipsKeyStr = "BuffSetCanNotReadyReason"
                buffCmpt:SetBuffValue(tipsKeyStr,reason)
            end
        else
            local tipsKeyStr = "BuffSetCanNotReadyReason"
            buffCmpt:SetBuffValue(tipsKeyStr,nil)
        end
    end
end
function BuffLogicService:IsPetActiveSkillCanNotReadyByBuff(e)
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    if buffCmpt then
        local setVal = buffCmpt:GetBuffValue("BuffSetCanNotReady")
        if setVal and setVal == 1 then
            local tipsKeyStr = "BuffSetCanNotReadyReason"
            local reason = buffCmpt:GetBuffValue(tipsKeyStr)
            return true,reason
        end
    end
    return false
end
function BuffLogicService:BuffSetPetExtraActiveSkillCanNotReady(e, skillID, bSet, reason)
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    if buffCmpt then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local isExtraSkill,extraSkillIndex = utilData:IsPetExtraActiveSkill(e,skillID)
        local subFix = skillID
        if isExtraSkill then
            subFix = extraSkillIndex
        end
        local keyStr = "BuffSetCanNotReady"..tostring(subFix)
        local setVal = bSet and 1 or 0
        buffCmpt:SetBuffValue(keyStr, setVal)
        if bSet then
            if reason then
                local tipsKeyStr = "BuffSetCanNotReadyReason"..tostring(subFix)
                buffCmpt:SetBuffValue(tipsKeyStr,reason)
            end
        else
            local tipsKeyStr = "BuffSetCanNotReadyReason"..tostring(subFix)
            buffCmpt:SetBuffValue(tipsKeyStr,nil)
        end
    end
end
function BuffLogicService:IsPetExtraActiveSkillCanNotReadyByBuff(e,skillID)
    ---@type BuffComponent
    
    local buffCmpt = e:BuffComponent()
    if buffCmpt then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local isExtraSkill,extraSkillIndex = utilData:IsPetExtraActiveSkill(e,skillID)
        local subFix = skillID
        if isExtraSkill then
            subFix = extraSkillIndex
        end
        local keyStr = "BuffSetCanNotReady"..tostring(subFix)
        local setVal = buffCmpt:GetBuffValue(keyStr)
        if setVal and setVal == 1 then
            local tipsKeyStr = "BuffSetCanNotReadyReason"..tostring(subFix)
            local reason = buffCmpt:GetBuffValue(tipsKeyStr)
            return true,reason
        end
    end
    return false
end

---判断目标是否能被宝宝的百分比伤害
---@param targetEntity Entity
function BuffLogicService:IsTargetCanBePercentDamage(targetEntity)
    ---@type AttributesComponent
    local attrCmpt = targetEntity:Attributes()
    local val = attrCmpt:GetAttribute("NoPercentDamage") or 0
    return val == 0
end

---判断目标是否能被斩杀
---@param targetEntity Entity
function BuffLogicService:IsTargetCanBeToDie(targetEntity)
    ---@type AttributesComponent
    local attrCmpt = targetEntity:Attributes()
    local val = attrCmpt:GetAttribute("NoDeadDamage") or 0
    return val == 0
end

---@param attacker Entity
---@param defender Entity
function BuffLogicService:_NotifyBuffDamageBegin(attacker, defender)
end

---@param attacker Entity
---@param defender Entity
---@param damageInfo DamageInfo
function BuffLogicService:_NotifyBuffDamageEnd(attacker, defender, damageInfo)
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")

    if defender:HasMonsterID() then
        local nt = NTMonsterBuffDamageEnd:New(attacker, defender)
        triggerSvc:Notify(nt)
    end
end

---@param buffID number
---@param attacker Entity
---@param defender Entity
---@return DamageInfo
function BuffLogicService:DoBuffDamage(buffID, attacker, defender, damageParam)
    self._world:GetMatchLogger():BeginBuff(attacker:GetID(), buffID)

    self:_NotifyBuffDamageBegin(attacker, defender)
    ---@type CalcDamageService
    local calcDamageSvc = self._world:GetService("CalcDamage")
    local damageInfo = calcDamageSvc:DoCalcDamage(attacker, defender, damageParam, true)
    self:_NotifyBuffDamageEnd(attacker, defender, damageInfo)
    self._world:GetMatchLogger():EndBuff(attacker:GetID())

    return damageInfo
end

function BuffLogicService:CalTargets_BodyAreaGridElementProp(buffTargetParam, enemyEntities)
    local es = {}
    if type(buffTargetParam) == "table" then
        local tarElements = buffTargetParam.tarElements or {}
        local maxProb = buffTargetParam.maxProb or 1
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        for i, e in ipairs(enemyEntities) do
            local pos = e:GetGridPosition()
            local area = e:BodyArea():GetArea()
            local totalPieceCount = e:BodyArea():GetAreaCount()
            if totalPieceCount == 0 then
                totalPieceCount = 1
            end
            local tarPieceCount = 0
            for _, v in ipairs(area) do
                local posWork = pos + v
                local pieceElement = utilData:FindPieceElement(Vector2(posWork.x, posWork.y))
                if table.icontains(tarElements, pieceElement) then
                    tarPieceCount = tarPieceCount + 1
                end
            end
            local pieceRandRate = tarPieceCount / totalPieceCount
            if pieceRandRate > 1 then
                pieceRandRate = 1
            end
            if maxProb < 1 then
                ---放大100倍
                local maxProbNum = 100 * maxProb
                local finalProb = pieceRandRate * maxProbNum
                ---产生随机数
                local random = randomSvc:LogicRand(1, 100)
                --buff概率
                if random > finalProb then
                else
                    table.insert(es, e)
                end
            else
                table.insert(es, e)
            end
        end
    end
    return es
end

function BuffLogicService:CalTargets_BodyAreaGridFindElement(buffTargetParam, enemyEntities)
    local es = {}
    if type(buffTargetParam) == "table" then
        local tarElements = buffTargetParam.tarElements or {}
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        for i, e in ipairs(enemyEntities) do
            local pos = e:GetGridPosition()
            local area = e:BodyArea():GetArea()
            local tarPieceCount = 0
            for _, v in ipairs(area) do
                local posWork = pos + v
                local pieceElement = utilData:FindPieceElement(Vector2(posWork.x, posWork.y))
                if table.icontains(tarElements, pieceElement) then
                    tarPieceCount = tarPieceCount + 1
                end
            end
            if tarPieceCount > 0 then
                table.insert(es, e)
            end
        end
    end
    return es
end

function BuffLogicService:CheckEntityLockHP(entity)
    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    local curRound = self._world:BattleStat():GetCurWaveTotalRoundCount()
    local isLock = buffCmpt:IsHPLock(curRound) or buffCmpt:IsHPLock(curRound - 1)
    local hasLockHPBuff = buffCmpt:GetBuffValue("LockHPByRound")
    if not hasLockHPBuff then
        hasLockHPBuff = buffCmpt:GetBuffValue("LockHPAlways")
    end

    return hasLockHPBuff, isLock
end

function BuffLogicService:GetLockHPInfo(entity, preDamage)
    ---@type BuffComponent
    local buffComponent = entity:BuffComponent()

    local curHp = entity:Attributes():GetCurrentHP()
    local maxHp = entity:Attributes():CalcMaxHp()
    curHp = curHp - (preDamage or 0)
    if curHp < 0 then
        curHp = 0
    end
    local leftHpPercent = curHp / maxHp * 100
    local lockHpPercent = 0
    local index = 0

    local lockHpList = buffComponent:GetBuffValue("LockHPList")
    for k, v in ipairs(lockHpList) do
        if v.hpPercent >= leftHpPercent and not buffComponent:HpIsHasLocked(v.hpPercent) then
            lockHpPercent = v.hpPercent
            index = k
        end
    end
    if buffComponent:GetBuffValue("LockHPAlways") and lockHpList and lockHpList[1] then
        local per = lockHpList[1].hpPercent
        if per >= leftHpPercent then
            lockHpPercent = per
            index = 1
        end
    end

    return lockHpPercent, index
end

--region 灰血条逻辑相关
local chargeGreyHPTag = "BuffLogicService:ChangeGreyHP: "
---
---@param e Entity
---@param val number
function BuffLogicService:ChangeGreyHP(e, val)
    local cBuff = e:BuffComponent()
    if not cBuff then
        Log.debug(chargeGreyHPTag, "target has no BuffComponent: ", e:GetID())
        return
    end
    if (not cBuff:IsGreyHPEnabled()) then
        Log.debug(chargeGreyHPTag, "target grey HP disabled: ", e:GetID())
        return
    end

    local currentVal = cBuff:GetGreyHPValue() or 0
    Log.debug(chargeGreyHPTag, e:GetID(), "current grey HP val: ", currentVal, "add val: ", val)
    currentVal = math.max(0, currentVal + val)
    cBuff:SetGreyHPValue(currentVal)
    ---添加战斗日志方便debug和测试
    local logger = self._world:GetMatchLogger()
    logger:BeginDamageLog(e:GetID())
    logger:AddDamageLog(
        e:GetID(),
        {
            key = "GreyHP",
            desc = "灰血积蓄值: [val]",
            val = val
        }
    )
    logger:EndDamageLog(e:GetID())
    return self:FixGreyHPVal(e)
end

function BuffLogicService:ClearGreyHP(e)
    ---@type BuffComponent
    local cBuff = e:BuffComponent()
    if not cBuff then
        return
    end
    if (not cBuff:IsGreyHPEnabled()) then
        return
    end

    cBuff:ClearGreyHPValue()
    return self:FixGreyHPVal(e)
end

local fixGreyHPValTag = "BuffLogicService:FixGreyHPVal: "
---
---@param e Entity
function BuffLogicService:FixGreyHPVal(e)
    local cBuff = e:BuffComponent()
    if not cBuff then
        Log.debug(fixGreyHPValTag, "target has no BuffComponent: ", e:GetID())
        return
    end

    local cAttributes = e:Attributes()
    local currentHP = cAttributes:GetCurrentHP()
    local maxHP = cAttributes:CalcMaxHp()

    local currentVal = cBuff:GetGreyHPValue()

    if not currentVal or currentVal <= 0 then
        Log.debug(fixGreyHPValTag, "entityID = ", e:GetID(), "no grey HP val. ")
        return
    end

    ---添加战斗日志方便debug和测试
    local logger = self._world:GetMatchLogger()
    logger:BeginDamageLog(e:GetID())

    if currentHP + currentVal > maxHP then
        local replaceVal = math.max(0, maxHP - currentHP)
        Log.debug(
            fixGreyHPValTag,
            "entityID = ",
            e:GetID(),
            " currentHP[",
            currentHP,
            "] +",
            " currentVal[",
            currentVal,
            "] > ",
            " maxHP[",
            maxHP,
            "]",
            "setting new grey HP val to ",
            replaceVal
        )

        logger:AddDamageLog(
            e:GetID(),
            {
                key = "GreyHP",
                desc = "灰血值修正: 当前生命值[currentHP] + 当前灰血值[currentVal] > 最大生命值[maxHP]，修正最终值[replaceVal]",
                currentHP = currentHP,
                currentVal = currentVal,
                maxHP = maxHP,
                replaceVal = replaceVal
            }
        )
        cBuff:SetGreyHPValue(replaceVal)
        currentVal = replaceVal
    else
        Log.debug(
            fixGreyHPValTag,
            "entityID = ",
            e:GetID(),
            " currentHP[",
            currentHP,
            "] +",
            " currentVal[",
            currentVal,
            "] > ",
            " maxHP[",
            maxHP,
            "]",
            "no need to fix. "
        )
        logger:AddDamageLog(
            e:GetID(),
            {
                key = "GreyHP",
                desc = "灰血值无需修正: 当前生命值[currentHP] + 当前灰血值[currentVal] <= 最大生命值[maxHP]",
                currentHP = currentHP,
                currentVal = currentVal,
                maxHP = maxHP
            }
        )
    end

    logger:AddDamageLog(
        e:GetID(),
        {
            key = "GreyHP",
            desc = "最终灰血值: [currentVal]",
            currentVal = currentVal
        }
    )
    logger:EndDamageLog(e:GetID())

    return currentVal
end

local recoverFromGreyHPTag = "BuffLogicService:RecoverFromGreyHP: "
---
---@param e Entity
---@param rate number
---@return DamageInfo
function BuffLogicService:GetRecoverFromGreyHPDamageInfo(e, rate)
    local cBuff = e:BuffComponent()
    if not cBuff then
        Log.debug(recoverFromGreyHPTag, "target has no BuffComponent: ", e:GetID())
        return
    end

    local cAttributes = e:Attributes()
    local currentHP = cAttributes:GetCurrentHP()
    local maxHP = cAttributes:CalcMaxHp()

    local currentLostHP = maxHP - currentHP

    local currentVal = cBuff:GetGreyHPValue()
    if (not currentVal) or (currentVal <= 0) then
        return
    end
    --恢复值不超过当前损失血量，向下取整，最小为1
    local recoverVal = math.max(1, math.floor(math.min(rate * currentVal, currentLostHP)))
    Log.debug(recoverFromGreyHPTag, "recover val: ", recoverVal, "entityID = ", e:GetID())

    local damageInfo = DamageInfo:New(recoverVal, DamageType.Recover)
    return damageInfo
end

--endregion

function BuffLogicService:GetRecoverByMaxHP(e, rate)
    local cBuff = e:BuffComponent()
    if not cBuff then
        return
    end

    ---@type AttributesComponent
    local cAttributes = e:Attributes()
    local currentHP = cAttributes:GetCurrentHP()
    local maxHP = cAttributes:CalcMaxHp()

    local recoverMaxHP = math.floor(math.min(maxHP * rate, maxHP))

    local recoverVal = math.max(1, recoverMaxHP - currentHP)

    local damageInfo = DamageInfo:New(recoverVal, DamageType.Recover)
    return damageInfo
end

function BuffLogicService:GetRecoverByMaxHPCount(e)
    ---@type BuffComponent
    local cBuff = e:BuffComponent()
    if not cBuff then
        return
    end

    return cBuff:GetRecoverByMaxHPCountValue()
end

function BuffLogicService:SetRecoverByMaxHPCount(e, val)
    ---@type BuffComponent
    local cBuff = e:BuffComponent()
    if not cBuff then
        return
    end

    cBuff:SetRecoverByMaxHPCountValue(val)
end

---@param entity Entity
function BuffLogicService:IsChainSkillUseChainScope(entity)
    if entity:HasBuff() then
        return entity:BuffComponent():GetBuffValue("ChainSkillUseChainScope")
                and entity:BuffComponent():GetBuffValue("ChainSkillUseChainScope")==1
    end
end
---@param entity Entity
---@param layerType BuffEffectType
---@param casterID number
function BuffLogicService:SetPoisonByAttackCasterID(entity, layerType, casterID)
    if layerType ~= BuffEffectType.PoisonByAttack then
        return
    end

    if not entity or not casterID then
        return
    end
    
    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if not buffCmpt then
        return
    end

    buffCmpt:SetPoisonByAttackCasterID(casterID)
end

---@param entity Entity
---@param layerType BuffEffectType
---@param casterID number
function BuffLogicService:ClearPoisonByAttackCasterID(entity, layerType)
    if layerType ~= BuffEffectType.PoisonByAttack then
        return
    end

    if not entity then
        return
    end

    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if not buffCmpt then
        return
    end

    buffCmpt:ClearPoisonByAttackCasterID()
end

function BuffLogicService:GetPoisonByAttackCasterID(entity)
    if not entity then
        return
    end

    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if not buffCmpt then
        return
    end

    return buffCmpt:GetPoisonByAttackCasterID()
end
--伙伴
--遍历当前队伍光灵，buff加给新队伍和新加入光灵
function BuffLogicService:ReBuildCurrentPetsPassiveSkillToPartner(teamEntity,partnerTepTeam)
    local petEntityList = teamEntity:Team():GetTeamPetEntities()
    ---@type ConfigService
    local configServer = self._world:GetService("Config")
    for _, petEntity in ipairs(petEntityList) do
        local passiveSkillID = petEntity:SkillInfo():GetPassiveSkillID()
        local equipIntensifyParams = petEntity:SkillInfo():GetEquipIntensifyParam()
        if passiveSkillID and passiveSkillID ~= 0 then
            local config = configServer:GetPetPassiveSkill(passiveSkillID)
            if config and config.BuffID then
                local buffSource = BuffSource:New(BuffSourceType.PassiveSkill, petEntity:PetPstID():GetPstID())
                for _, buffID in ipairs(config.BuffID) do
                    self:AddBuffByTargetType(
                        buffID,
                        config.BuffTargetType,
                        config.BuffTargetParam,
                        {casterEntity = petEntity},
                        buffSource,
                        equipIntensifyParams,
                        petEntity
                    )
                end
            end
        end
    end

    ---玩家带的光灵，有可能需要立即触发一些BUFF，可以放到这里
    -- for _, petEntity in ipairs(petEntityList) do
    --     ---大招就绪通知
    --     local ready = petEntity:Attributes():GetAttribute("Ready")
    --     if ready == 1 then
    --         local notify = NTPowerReady:New(petEntity)
    --         self._world:GetService("Trigger"):Notify(notify)
    --     end
    -- end
end
function BuffLogicService:BuildNewPartnerPassiveSkill(teamEntity,partnerTempTeam)
    local petEntityList = partnerTempTeam:Team():GetTeamPetEntities()--是新加入的光灵
    ---@type ConfigService
    local configServer = self._world:GetService("Config")
    for _, petEntity in ipairs(petEntityList) do
        local passiveSkillID = petEntity:SkillInfo():GetPassiveSkillID()
        local equipIntensifyParams = petEntity:SkillInfo():GetEquipIntensifyParam()
        if passiveSkillID and passiveSkillID ~= 0 then
            local config = configServer:GetPetPassiveSkill(passiveSkillID)
            if config and config.BuffID then
                local buffSource = BuffSource:New(BuffSourceType.PassiveSkill, petEntity:PetPstID():GetPstID())
                for _, buffID in ipairs(config.BuffID) do
                    self:AddBuffByTargetType(
                        buffID,
                        config.BuffTargetType,
                        config.BuffTargetParam,
                        {casterEntity = petEntity},
                        buffSource,
                        equipIntensifyParams,
                        petEntity
                    )
                end
            end
        end
    end

    for _, petEntity in ipairs(petEntityList) do
        ---大招就绪通知
        local ready = petEntity:Attributes():GetAttribute("Ready")
        if ready == 1 then
            local notify = NTPowerReady:New(petEntity)
            self._world:GetService("Trigger"):Notify(notify)
        end
    end
end


function BuffLogicService:ChangeDmgParamSingleTypeSkill(entity, modifierID, value)
    self:_AddAttributeValue(entity, "DmgParamSingleTypeSkill", modifierID, value)
end

function BuffLogicService:RemoveDmgParamSingleTypeSkill(entity, modifierID)
    self:_RemoveAttributeValue(entity, "DmgParamSingleTypeSkill", modifierID)
end

function BuffLogicService:CalcMinCostByExtraParam(petEntity,skillID)
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, petEntity) --第二个参数是必要的，MSG58001
    local defaultCost = skillConfigData:GetSkillTriggerParam()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local cost = utilData:CalcMinCostLegendPowerByExtraParam(petEntity,defaultCost,skillConfigData,0,false)
    return cost
end

--region CountDown
function BuffLogicService:GetCountDown(entity, buffEffectType)
    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if bc then
        local key = self:GetBuffLayerName(buffEffectType).."CountDown"
        local countDown = bc:GetBuffValue(key) 
        return countDown
    end
end

function BuffLogicService:SetCountDown(entity, buffEffectType, countDown)
    local bc = entity:BuffComponent()
    if bc then
        if countDown < 0 then
            countDown = 0
        end
        local buffInstance = bc:GetSingleBuffByBuffEffect(buffEffectType)
        local key = self:GetBuffLayerName(buffEffectType).."CountDown"
        bc:SetBuffValue(key, countDown)
        return countDown, buffInstance
    end
end

function BuffLogicService:AddCountDown(entity, buffEffectType, addCountDown)
    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if not bc then
        return 
    end
    ---@type BuffInstance
    local buffInstance = bc:GetSingleBuffByBuffEffect(buffEffectType)
    if not buffInstance then
        return 
    end
    local oldFinalVal = buffInstance:GetCountDown()
    local newCountDown, changeCountDown = buffInstance:AddCountDown(addCountDown)
    return newCountDown, buffInstance
end
--endregion CountDown

---@param entity Entity
---@param notifyType NotifyType
function BuffLogicService:IsPetNotifyTypeDisable(entity, notifyType)
    ---只针对光灵主动技，禁用某些通知类型
    if not entity:HasPet() then
        return false
    end
    
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local curActiveSkillID = activeSkillCmpt:GetActiveSkillID()
    local curCasterID = activeSkillCmpt:GetActiveSkillCasterEntityID()
    if curCasterID ~= entity:GetID() then
        return false
    end

    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if not bc then
        return false
    end

    local strValue = bc:GetBuffValue("ForbiddenNotifyType")
    local strArray = string.split(strValue, "|")
    local skillID = tonumber(strArray[1])
    local strTypeArray = string.split(strArray[2], ",")
    local typeList = {}
    for _, strType in ipairs(strTypeArray) do
        table.insert(typeList, tonumber(strType))
    end

    if skillID == curActiveSkillID then
        if table.icontains(typeList, notifyType) then
            return true
        end
    end
    return false
end

---@param entity Entity
---@param notifyType NotifyType
function BuffLogicService:IsPetNotTriggerAntiAttack(entity)
    ---只针对光灵主动技，禁用反制AI
    if not entity:HasPet() then
        return false
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local curActiveSkillID = activeSkillCmpt:GetActiveSkillID()
    local curCasterID = activeSkillCmpt:GetActiveSkillCasterEntityID()
    if curCasterID ~= entity:GetID() then
        return false
    end

    ---@type BuffComponent
    local bc = entity:BuffComponent()
    if not bc then
        return false
    end

    local strValue = bc:GetBuffValue("ForbiddenNotifyType")
    local strArray = string.split(strValue, "|")
    local skillID = tonumber(strArray[1])

    if skillID == curActiveSkillID then
        return true
    end
    return false
end

local BuffChangeAttrType={
    AttackPer
}

function BuffLogicService:ChangeADPAttr(entity, modifierID, value)
    self:_AddAttributeValue(entity, "ADPAttr", modifierID, value)
end

function BuffLogicService:GetPopStarStageBuffIDList()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()

    ---@type BuffComponent
    local buffComponent = teamEntity:BuffComponent()
    if not buffComponent then
        return
    end

    local buffIDList = {}
    ---@type BuffInstance[]
    local buffArray = buffComponent:GetBuffArrayByBuffType(BuffType.PopStarStage)
    if buffArray and #buffArray > 0 then
        for _, buffIns in ipairs(buffArray) do
            buffIDList[#buffIDList + 1] = buffIns:BuffID()
        end
    end

    return buffIDList
end
--region 诅咒血条逻辑相关
local chargeCurseHPTag = "BuffLogicService:ChangeCurseHP: "
---
---@param e Entity
---@param val number
function BuffLogicService:ChangeCurseHP(e, val)
    local cBuff = e:BuffComponent()
    if not cBuff then
        Log.debug(chargeCurseHPTag, "target has no BuffComponent: ", e:GetID())
        return
    end
    if (not cBuff:IsCurseHPEnabled()) then
        Log.debug(chargeCurseHPTag, "target curse HP disabled: ", e:GetID())
        return
    end

    local currentVal = cBuff:GetCurseHPValue() or 0
    Log.debug(chargeCurseHPTag, e:GetID(), "current curse HP val: ", currentVal, "add val: ", val)
    currentVal = currentVal + val
    if currentVal < 0 then
        currentVal = 0
    end
    cBuff:SetCurseHPValue(currentVal)
    ---添加战斗日志方便debug和测试
    local logger = self._world:GetMatchLogger()
    logger:BeginDamageLog(e:GetID())
    logger:AddDamageLog(
        e:GetID(),
        {
            key = "CurseHP",
            desc = "诅咒血条积蓄值: [val]",
            val = val
        }
    )
    logger:EndDamageLog(e:GetID())
    return self:FixCurseHPVal(e)
end

function BuffLogicService:ClearCurseHP(e)
    ---@type BuffComponent
    local cBuff = e:BuffComponent()
    if not cBuff then
        return
    end
    if (not cBuff:IsCurseHPEnabled()) then
        return
    end

    cBuff:ClearCurseHPValue()
    return self:FixCurseHPVal(e)
end

local fixCurseHPValTag = "BuffLogicService:FixCurseHPVal: "
---
---@param e Entity
function BuffLogicService:FixCurseHPVal(e)
    local cBuff = e:BuffComponent()
    if not cBuff then
        Log.debug(fixCurseHPValTag, "target has no BuffComponent: ", e:GetID())
        return
    end

    local cAttributes = e:Attributes()
    local maxHP = cAttributes:CalcMaxHp()

    local currentVal = cBuff:GetCurseHPValue()

    if not currentVal or currentVal < 0 then
        Log.debug(fixCurseHPValTag, "entityID = ", e:GetID(), "no curse HP val. ")
        return
    end

    ---添加战斗日志方便debug和测试
    local logger = self._world:GetMatchLogger()
    logger:BeginDamageLog(e:GetID())

    if currentVal > maxHP then
        local replaceVal = maxHP
        Log.debug(
            fixCurseHPValTag,
            "entityID = ",
            e:GetID(),
            " currentVal[",
            currentVal,
            "] > ",
            " maxHP[",
            maxHP,
            "]",
            "setting new curse HP val to ",
            replaceVal
        )

        logger:AddDamageLog(
            e:GetID(),
            {
                key = "CurseHP",
                desc = "诅咒血条值修正: 当前诅咒血条[currentVal] > 最大生命值[maxHP]，修正最终值[replaceVal]",
                currentVal = currentVal,
                maxHP = maxHP,
                replaceVal = replaceVal
            }
        )
        cBuff:SetCurseHPValue(replaceVal)
        currentVal = replaceVal
    else
        Log.debug(
            fixCurseHPValTag,
            "entityID = ",
            e:GetID(),
            " currentVal[",
            currentVal,
            "] > ",
            " maxHP[",
            maxHP,
            "]",
            "no need to fix. "
        )
        logger:AddDamageLog(
            e:GetID(),
            {
                key = "CurseHP",
                desc = "诅咒血条无需修正: 当前诅咒血条[currentVal] <= 最大生命值[maxHP]",
                currentVal = currentVal,
                maxHP = maxHP
            }
        )
    end

    logger:AddDamageLog(
        e:GetID(),
        {
            key = "CurseHP",
            desc = "最终诅咒血条: [currentVal]",
            currentVal = currentVal
        }
    )
    logger:EndDamageLog(e:GetID())

    return currentVal
end
---endregion