--[[------------------------------------------------------------------------------------------
    ChangeBuffLayer = 116, --修改buff层数
]] --------------------------------------------------------------------------------------------
require("skill_effect_result_base")
_class("SkillEffectResultChangeBuffLayer", SkillEffectResultBase)
---@class SkillEffectResultChangeBuffLayer: SkillEffectResultBase
SkillEffectResultChangeBuffLayer = SkillEffectResultChangeBuffLayer

function SkillEffectResultChangeBuffLayer:Constructor(entityID, targetBuffSeq, targetEffectType, layer, isUnload)
    self._stageIndex = 1
    self._entityID = entityID
    self._targetBuffSeq = targetBuffSeq
    self._targetEffectType = targetEffectType
    self._layer = layer
    self._isUnload = isUnload
end

function SkillEffectResultChangeBuffLayer:GetEffectType()
    return SkillEffectType.ChangeBuffLayer
end

function SkillEffectResultChangeBuffLayer:GetEntityID()
    return self._entityID
end

function SkillEffectResultChangeBuffLayer:GetTargetBuffSeq()
    return self._targetBuffSeq
end

function SkillEffectResultChangeBuffLayer:GetTargetBuffEffectType()
    return self._targetEffectType
end

function SkillEffectResultChangeBuffLayer:GetLayer()
    return self._layer
end

function SkillEffectResultChangeBuffLayer:GetIsUnload()
    return self._isUnload
end

-- function SkillEffectResultChangeBuffLayer:GetAddBuffResult()
--     return self._newBuffArray
-- end
-- function SkillEffectResultChangeBuffLayer:AddBuffResult(buffseq)
--     Log.debug("AddBuffResult entityid=", self._entityID, "buffseq=", buffseq)
--     self._newBuffArray[#self._newBuffArray + 1] = buffseq
-- end

function SkillEffectResultChangeBuffLayer:SetDamageStageIndex(stageIndex)
    self._stageIndex = stageIndex
end

function SkillEffectResultChangeBuffLayer:GetDamageStageIndex()
    return self._stageIndex
end
