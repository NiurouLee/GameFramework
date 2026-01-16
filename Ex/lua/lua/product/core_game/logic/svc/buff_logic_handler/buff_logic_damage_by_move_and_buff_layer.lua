--[[
    触发后对目标造成伤害，走伤害公式
]]
_class("BuffLogicDamageByMoveAndBuffLayer", BuffLogicBase)
BuffLogicDamageByMoveAndBuffLayer = BuffLogicDamageByMoveAndBuffLayer

function BuffLogicDamageByMoveAndBuffLayer:Constructor(buffInstance, logicParam)
    self._damageParam = logicParam

    self._basePercent = logicParam.percent
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._monstBuffLayerAddSkillFinal = logicParam.monstBuffLayerAddSkillFinal or 0 --层数最大伤害加深
end

function BuffLogicDamageByMoveAndBuffLayer:DoLogic(notify)
    local context = self._buffInstance:Context()
    if not context then
        return
    end
    local petEntity = context.casterEntity
    if not petEntity then
        return
    end
    local defender = self._entity

    --获取移动的格子数量
    local moveGridCount = 1
    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        --怪物移动
        moveGridCount = 1
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd or notify:GetNotifyType() == NotifyType.TractionEnd then
        --击退 or 牵引
        local posStart = notify:GetPosStart()
        local posEnd = notify:GetPosEnd()
        moveGridCount = GameHelper.ComputeLogicStep(posStart, posEnd)
    elseif notify:GetNotifyType() == NotifyType.Teleport then
        --瞬移技能
        local posOld = notify:GetPosOld()
        local posNew = notify:GetPosNew()
        moveGridCount = GameHelper.ComputeLogicStep(posOld, posNew)
    end

    --没位移不计算
    if moveGridCount == 0 then
        return
    end

    ---重置第二属性标记，到这里有可能玩家还在使用第二属性
    ---@type ElementComponent
    local playerElementCmpt = petEntity:Element()
    if playerElementCmpt then
        playerElementCmpt:SetUseSecondaryType(false)
    end

    --获取buff挂载者身上的层数
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local curMarkLayer = svc:GetBuffLayer(defender, self._layerType)
    local newPercent = 0
    newPercent = self._basePercent * curMarkLayer * moveGridCount

    --重新赋值伤害系数
    self._damageParam.percent = newPercent

    if self._damageParam.useSnapAttack then
        self._damageParam.simpleDamage = self._buffInstance:GetSnapCasterAttack()
    end

    self._world:GetMatchLogger():BeginBuff(defender:GetID(), self._buffInstance:BuffID())

    --伤害增加
    local defenderHasMostBuffLayer = false
    if self._monstBuffLayerAddSkillFinal ~= 0 then
        defenderHasMostBuffLayer = self:_OnCheckTTDefenderHasMostBuffLayer()

        if defenderHasMostBuffLayer then
            self._buffLogicService:ChangeSkillFinalParam(
                petEntity,
                self:GetBuffSeq(),
                ModifySkillParamType.ActiveSkill,
                self._monstBuffLayerAddSkillFinal
            )
        end
    end

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local damageInfo = blsvc:DoBuffDamage(self._buffInstance:BuffID(), petEntity, defender, self._damageParam)

    --还原
    self._buffLogicService:RemoveSkillFinalParam(petEntity, self:GetBuffSeq(), ModifySkillParamType.ActiveSkill)

    self._world:GetMatchLogger():EndBuff(defender:GetID())

    local buffResult = BuffResultDamage:New(damageInfo)

    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        local walkPos = notify:GetWalkPos()
        buffResult:SetWalkPos(walkPos)
    end
    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        local walkPos = notify:GetPos()
        buffResult:SetWalkPos(walkPos)
    end

    return buffResult
end

function BuffLogicDamageByMoveAndBuffLayer:_OnCheckTTDefenderHasMostBuffLayer()
    local defenderEntity = self._entity
    if not defenderEntity then
        return false
    end
    ---@type BuffComponent
    local buffCmp = defenderEntity:BuffComponent()
    if not buffCmp then
        return false
    end
    local satisfied = false

    local buffEffectType = self._layerType
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")

    local monsterEntityList = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() then
            table.insert(monsterEntityList, e)
        end
    end

    --黑拳赛
    if defenderEntity:HasTeam() then
        table.insert(monsterEntityList, defenderEntity)
    end

    if table.count(monsterEntityList) == 0 then
        return false
    end

    --对比buff的层数
    local hasMostBuffLayerMonsterEntityList = {}
    local mostBuffLayer = 0
    for _, e in ipairs(monsterEntityList) do
        local curMarkLayer = svc:GetBuffLayer(e, buffEffectType)
        if curMarkLayer > mostBuffLayer then
            table.clear(hasMostBuffLayerMonsterEntityList)
            table.insert(hasMostBuffLayerMonsterEntityList, e)
            mostBuffLayer = curMarkLayer
        elseif curMarkLayer == mostBuffLayer and curMarkLayer ~= 0 then
            table.insert(hasMostBuffLayerMonsterEntityList, e)
        end
    end

    if table.count(hasMostBuffLayerMonsterEntityList) == 0 then
        return false
    end

    local hasMostBuffLayerMonsterEntity
    --buff层数都一样，对比血量最多的
    if table.count(hasMostBuffLayerMonsterEntityList) > 0 then
        local mostHp = 0
        for _, e in ipairs(hasMostBuffLayerMonsterEntityList) do
            local curhp = e:Attributes():GetCurrentHP()
            if curhp > mostHp then
                curhp = mostHp
                hasMostBuffLayerMonsterEntity = e
            end
        end
    end

    if not hasMostBuffLayerMonsterEntity then
        return false
    end

    satisfied = hasMostBuffLayerMonsterEntity:GetID() == defenderEntity:GetID()

    return satisfied
end
