_class("PlayCoffinMusumeCandleSetSelfLightInstruction", BaseInstruction)
---@class PlayCoffinMusumeCandleSetSelfLightInstruction : BaseInstruction
PlayCoffinMusumeCandleSetSelfLightInstruction = PlayCoffinMusumeCandleSetSelfLightInstruction

function PlayCoffinMusumeCandleSetSelfLightInstruction:Constructor(paramList)
    self._candleEffectID = tonumber(paramList.candleEffectID)
end

---@param TT TaskToken
---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCoffinMusumeCandleSetSelfLightInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_CoffinMusumeSetCandleLight
    local result = routineComponent:GetEffectResultByArray(SkillEffectType.CoffinMusumeSetCandleLight)

    if not result then
        return
    end

    local world = casterEntity:GetOwnerWorld()

    local e = world:GetEntityByID(result:GetEntityID())
    if e then
        local hasEffect = e:HasEffectHolder()
        local effectIDEntityDic = hasEffect and e:EffectHolder():GetEffectIDEntityDic()
        hasEffect = hasEffect and (effectIDEntityDic[self._candleEffectID]) and #(effectIDEntityDic[self._candleEffectID]) > 0

        if not hasEffect then
            ---@type EffectService
            local fxsvc = world:GetService("Effect")
            fxsvc:CreateEffect(self._candleEffectID, e)
        end
    end

    world:GetService("PlayBuff"):PlayBuffView(TT, NTCoffinMusumeSkillChangeLight:New({result:GetEntityID()}))
end
