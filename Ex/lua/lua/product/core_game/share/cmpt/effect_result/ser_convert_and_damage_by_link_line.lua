require("skill_effect_result_base")

_class("SkillEffectConvertAndDamageByLinkLineResult", SkillEffectResultBase)
---@class SkillEffectConvertAndDamageByLinkLineResult: SkillEffectResultBase
SkillEffectConvertAndDamageByLinkLineResult = SkillEffectConvertAndDamageByLinkLineResult

function SkillEffectConvertAndDamageByLinkLineResult:Constructor()
    ---连线路径
    ---@type Vector2[]
    self._chainPath = {}
    ---瞬移结果
    ---@type SkillEffectResult_Teleport
    self._teleportResult = nil
    ---转色结果
    ---@type SkillConvertGridElementEffectResult
    self._convertResult = nil
    ---伤害结果
    ---@type SkillDamageEffectResult
    self._damageResult = nil
end

function SkillEffectConvertAndDamageByLinkLineResult:GetEffectType()
    return SkillEffectType.ConvertAndDamageByLinkLine
end

function SkillEffectConvertAndDamageByLinkLineResult:SetChainPath(chainPath)
    self._chainPath = chainPath
end

function SkillEffectConvertAndDamageByLinkLineResult:SetTeleportResult(teleportRes)
    self._teleportResult = teleportRes
end

function SkillEffectConvertAndDamageByLinkLineResult:SetConvertResult(convertResult)
    self._convertResult = convertResult
end

function SkillEffectConvertAndDamageByLinkLineResult:SetDamageResult(damageResult)
    self._damageResult = damageResult
end

function SkillEffectConvertAndDamageByLinkLineResult:GetChainPath()
    return self._chainPath
end

function SkillEffectConvertAndDamageByLinkLineResult:GetTeleportResult()
    return self._teleportResult
end

function SkillEffectConvertAndDamageByLinkLineResult:GetConvertResult()
    return self._convertResult
end

function SkillEffectConvertAndDamageByLinkLineResult:GetDamageResult()
    return self._damageResult
end
