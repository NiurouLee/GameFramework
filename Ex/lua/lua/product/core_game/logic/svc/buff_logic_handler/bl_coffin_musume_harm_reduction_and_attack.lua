_class("BuffLogicCoffinMusumeHarmReductionAndAttack", BuffLogicBase)
---@class BuffLogicCoffinMusumeHarmReductionAndAttack: BuffLogicBase
BuffLogicCoffinMusumeHarmReductionAndAttack = BuffLogicCoffinMusumeHarmReductionAndAttack

function BuffLogicCoffinMusumeHarmReductionAndAttack:Constructor(buffInstance, logicParam)
    self._trapID = tonumber(logicParam.trapID)
    self._harmReduction = logicParam.harmReduction
    self._atkIncrease = logicParam.atkIncrease
    self._stage = logicParam.stage
    --self._mulVal = tonumber(logicParam.mulVal)
    self._uiText = logicParam.uiText --从逻辑传给UI，bon voyage
end

function BuffLogicCoffinMusumeHarmReductionAndAttack:DoLogic()
    local candleCount = 0
    local tLightCandleID = {}
    --蜡烛是不会死的，至少现在是
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, eTrap in ipairs(globalTrapEntities) do
        if not eTrap:Trap():GetTrapID() == self._trapID then
            goto CONTINUE
        end

        if not eTrap:HasBuff() then
            goto CONTINUE
        end

        if eTrap:BuffComponent():GetBuffValue(BattleConst.CandleLightKey) == 1 then
            candleCount = candleCount + 1
            table.insert(tLightCandleID, eTrap:GetID())
        end

        ::CONTINUE::
    end

    local harmReductionVal = self._harmReduction[candleCount + 1] --从0开始
    if not harmReductionVal then
        Log.exception("CoffinMusumeHarmReduction: 亮灯数量与减伤参数不匹配，亮灯数=", candleCount, "参数连续最大个数=", #self._harmReduction)
        return
    end
    local attackVal = self._atkIncrease[candleCount + 1] --从0开始
    if not attackVal then
        Log.exception("CoffinMusumeHarmReduction: 亮灯数量与攻击提升参数不匹配，亮灯数=", candleCount, "参数连续最大个数=", #self._atkIncrease)
        return
    end
    self._buffLogicService:RemoveFinalBeHitDamageParam(self._entity, self:GetBuffSeq())
    self._buffLogicService:ChangeFinalBeHitDamageParam(self._entity, self:GetBuffSeq(), harmReductionVal * (-0.01))

    self._buffLogicService:RemoveBaseAttack(self._entity, self:GetBuffSeq(), ModifyBaseAttackType.AttackPercentage)
    self._buffLogicService:ChangeBaseAttack(self._entity, self:GetBuffSeq(), ModifyBaseAttackType.AttackPercentage, attackVal * 0.01)

    --与HarmReduction一样的分组逻辑，但只用来表现
    --白线的UI顺序
    local lineList = {}

    local curStage = 1
    if candleCount > 0 and candleCount <= #self._stage then
        for i = 1, candleCount do
            if self._stage[i] > curStage then
                curStage = self._stage[i]
                --线的顺序= 已经打开的层数 + 已经有的线数量
                local lineIndex = i + #lineList
                table.insert(lineList, lineIndex)
            end
        end
    end

    return BuffResultCoffinMusumeHarmReductionAndAttack:New(tLightCandleID, self._uiText, harmReductionVal, attackVal, lineList)
end

function BuffLogicCoffinMusumeHarmReductionAndAttack:DoOverlap()
    return self:DoLogic()
end

_class("BuffLogicResetCoffinMusumeHarmReductionAndAttack", BuffLogicBase)
---@class BuffLogicResetCoffinMusumeHarmReductionAndAttack: BuffLogicBase
BuffLogicResetCoffinMusumeHarmReductionAndAttack = BuffLogicResetCoffinMusumeHarmReductionAndAttack

function BuffLogicResetCoffinMusumeHarmReductionAndAttack:DoLogic()
    self._buffLogicService:RemoveFinalBeHitDamageParam(self._entity, self:GetBuffSeq())
    self._buffLogicService:RemoveBaseAttack(self._entity, self:GetBuffSeq(), ModifyBaseAttackType.AttackPercentage)
end
