--[[------------------------------------------------------------------------------------------
    SkillBuffEffectResult : 技能加buff结果
]] --------------------------------------------------------------------------------------------
require("skill_effect_result_base")
_class("SkillBuffEffectResult", SkillEffectResultBase)
---@class SkillBuffEffectResult: SkillEffectResultBase
SkillBuffEffectResult = SkillBuffEffectResult

function SkillBuffEffectResult:Constructor(entityID)
    self._effectType = SkillEffectType.AddBuff
    self._newBuffArray = {}
    self._stageIndex = 1
    self._entityID = entityID
end

function SkillBuffEffectResult:GetEffectType()
    return SkillEffectType.AddBuff
end

function SkillBuffEffectResult:GetAddBuffResult()
    return self._newBuffArray
end

function SkillBuffEffectResult:GetEntityID()
    return self._entityID
end

function SkillBuffEffectResult:AddBuffResult(buffseq)
    --Log.debug("AddBuffResult entityid=", self._entityID, "buffseq=", buffseq)
    self._newBuffArray[#self._newBuffArray + 1] = buffseq
end

function SkillBuffEffectResult:SetDamageStageIndex(stageIndex)
    self._stageIndex = stageIndex
end

function SkillBuffEffectResult:GetDamageStageIndex()
    return self._stageIndex
end

function SkillBuffEffectResult:SetBuffInitLayer(v)
    self._buffLayer = v
end

function SkillBuffEffectResult:GetBuffInitLayer()
    return self._buffLayer
end
