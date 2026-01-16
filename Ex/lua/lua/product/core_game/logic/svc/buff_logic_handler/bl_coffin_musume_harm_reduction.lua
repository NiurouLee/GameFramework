_class("BuffLogicCoffinMusumeHarmReduction", BuffLogicBase)
---@class BuffLogicCoffinMusumeHarmReduction: BuffLogicBase
BuffLogicCoffinMusumeHarmReduction = BuffLogicCoffinMusumeHarmReduction

function BuffLogicCoffinMusumeHarmReduction:Constructor(buffInstance, logicParam)
    self._trapID = tonumber(logicParam.trapID)
    self._harmReduction = logicParam.harmReduction
    self._stage = logicParam.stage
    --self._mulVal = tonumber(logicParam.mulVal)
    self._uiText = logicParam.uiText --从逻辑传给UI，bon voyage
end

function BuffLogicCoffinMusumeHarmReduction:DoLogic()
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

    self._buffLogicService:RemoveFinalBeHitDamageParam(self._entity, self:GetBuffSeq())

    local val = self._harmReduction[candleCount + 1] --从0开始
    if not val then
        Log.exception("CoffinMusumeHarmReduction: 亮灯数量与减伤参数不匹配，亮灯数=", candleCount, "参数连续最大个数=", #self._harmReduction)
        return
    end
    self._buffLogicService:ChangeFinalBeHitDamageParam(self._entity, self:GetBuffSeq(), val * (-0.01))

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

    return BuffResultCoffinMusumeHarmReduction:New(tLightCandleID, self._uiText, val, lineList)
end

function BuffLogicCoffinMusumeHarmReduction:DoOverlap()
    return self:DoLogic()
end

_class("BuffLogicResetCoffinMusumeHarmReduction", BuffLogicBase)
---@class BuffLogicResetCoffinMusumeHarmReduction: BuffLogicBase
BuffLogicResetCoffinMusumeHarmReduction = BuffLogicResetCoffinMusumeHarmReduction

function BuffLogicResetCoffinMusumeHarmReduction:DoLogic()
    self._buffLogicService:RemoveFinalBeHitDamageParam(self._entity, self:GetBuffSeq())
end
