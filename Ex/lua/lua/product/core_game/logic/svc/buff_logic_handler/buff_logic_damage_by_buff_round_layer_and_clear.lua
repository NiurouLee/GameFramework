--[[
    找到指定buff中指定回合数量的buff，用做计算伤害，算完清除掉这些buff。计算伤害前用全部该类型buff的数量计算增伤
]]
_class("BuffLogicDamageByBuffRoundLayerAndClear", BuffLogicBase)
---@class BuffLogicDamageByBuffRoundLayerAndClear:BuffLogicBase
BuffLogicDamageByBuffRoundLayerAndClear = BuffLogicDamageByBuffRoundLayerAndClear

function BuffLogicDamageByBuffRoundLayerAndClear:Constructor(buffInstance, logicParam)
    self._damageParam = logicParam

    self._basePercent = logicParam.percent
    self._layerType = logicParam.layerType
    self._removeBuffRound = logicParam.removeBuffRound or {} --卸载buff的回合
    self._damageBuffRound = logicParam.damageBuffRound or {}
    self._oneLayerAddSkillFinal = logicParam.oneLayerAddSkillFinal or 0 --伤害加深
end

function BuffLogicDamageByBuffRoundLayerAndClear:DoLogic(notify)
    local context = self._buffInstance:Context()
    if not context then
        return
    end
    local petEntity = context.casterEntity
    if not petEntity then
        return
    end
    local defender = self._entity

    --指定回合的参数
    local damageBuffList = {}
    local targetBuffList = {}
    local targetBuffSeq = {}
    ---@type BuffComponent
    local buffCmpt = defender:BuffComponent()
    local buffArray = buffCmpt:GetBuffArray()
    local buffCopy = table.shallowcopy(buffArray)
    for _, buffInstance in ipairs(buffCopy) do
        local buffRoundCount = buffInstance:GetBuffRoundCount()
        if not buffInstance:IsUnload() and buffInstance:GetBuffEffectType() == self._layerType then
            if table.intable(self._removeBuffRound, buffRoundCount) then
                table.insert(targetBuffList, buffInstance)
                table.insert(targetBuffSeq, buffInstance:BuffSeq())
            end
            if table.intable(self._damageBuffRound, buffRoundCount) then
                table.insert(damageBuffList, buffInstance)
            end
        end
    end
    local damageBuffCount = table.count(damageBuffList)

    if damageBuffCount == 0 then
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
    local buffLogicService = self._world:GetService("BuffLogic")
    --总层数
    local curMarkLayer = buffLogicService:GetBuffLayer(defender, self._layerType)

    local newPercent = self._basePercent * damageBuffCount

    --重新赋值伤害系数
    self._damageParam.percent = newPercent
    if self._damageParam.useSnapAttack then
        self._damageParam.simpleDamage = self._buffInstance:GetSnapCasterAttack()
    end

    self._world:GetMatchLogger():BeginBuff(defender:GetID(), self._buffInstance:BuffID())

    --伤害增加
    if self._oneLayerAddSkillFinal ~= 0 then
        local addSkillFinal = curMarkLayer * self._oneLayerAddSkillFinal

        self._buffLogicService:ChangeSkillFinalParam(
            petEntity,
            self:GetBuffSeq(),
            ModifySkillParamType.NormalSkill,
            addSkillFinal
        )
        ---方便测试
        self._buffLogicService:ChangeSkillFinalParam(
            petEntity,
            self:GetBuffSeq(),
            ModifySkillParamType.ActiveSkill,
            addSkillFinal
        )
    end

    local damageInfo =
        buffLogicService:DoBuffDamage(self._buffInstance:BuffID(), petEntity, defender, self._damageParam)

    --还原
    self._buffLogicService:RemoveSkillFinalParam(petEntity, self:GetBuffSeq(), ModifySkillParamType.NormalSkill)
    self._buffLogicService:RemoveSkillFinalParam(petEntity, self:GetBuffSeq(), ModifySkillParamType.ActiveSkill)

    self._world:GetMatchLogger():EndBuff(defender:GetID())

    for _, buffInstance in ipairs(targetBuffList) do
        buffInstance:Unload(NTBuffUnload:New())
    end

    local buffResult = BuffResultDamageByBuffRoundLayerAndClear:New(damageInfo, targetBuffSeq)

    return buffResult
end
