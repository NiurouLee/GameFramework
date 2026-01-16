--[[------------------------------------------------------------------------------------------
    SkillDamageEffectResult : 技能伤害结果
]]
--------------------------------------------------------------------------------------------
require("skill_effect_result_base")

_class("SkillDamageEffectResult", SkillEffectResultBase)
---@class SkillDamageEffectResult: SkillEffectResultBase
SkillDamageEffectResult = SkillDamageEffectResult

function SkillDamageEffectResult:Constructor(gridPos, targetid, damage, damageArray, damageStageIndex)
    self._attackGridDataDict = {}
    self._gridPos = gridPos
    self._targetID = targetid
    self._totalDamage = damage --总伤害
    self._multiDamageInfo = damageArray --每次伤害值
    self._damageStageIndex = damageStageIndex or 1 --伤害阶段索引
    self._used = false --记录伤害结果被使用过

    --扩展参数
    self._buffLayerCountForDamage = 0 --技能效果196专用
    self._isClearBuffLayer = false --技能效果196专用
    --215使用来计算
    self._damageIndex = nil
end

function SkillDamageEffectResult:GetEffectType()
    return SkillEffectType.Damage
end

function SkillDamageEffectResult:GetTargetID()
    return self._targetID
end

function SkillDamageEffectResult:GetTotalDamage()
    return self._totalDamage
end

function SkillDamageEffectResult:SetTotalDamage(val)
    self._totalDamage = math.floor(val)
    if self._totalDamage < 1 then
        self._totalDamage = 1
    end
end

function SkillDamageEffectResult:GetGridPos()
    return self._gridPos
end

---@return DamageInfo[]
function SkillDamageEffectResult:GetDamageInfoArray()
    return self._multiDamageInfo
end

function SkillDamageEffectResult:GetDamageInfo(index)
    if self._multiDamageInfo then
        return self._multiDamageInfo[index]
    end
    return nil
end

---@param damageInfo DamageInfo
function SkillDamageEffectResult:SetDamageInfo(index, damageInfo)
    self._multiDamageInfo[index] = damageInfo
    self._totalDamage = self._totalDamage + damageInfo:GetDamageValue()
end

function SkillDamageEffectResult:GetDamageStageIndex()
    return self._damageStageIndex
end

function SkillDamageEffectResult:SetUsed()
    self._used = true
end

function SkillDamageEffectResult:IsUsed()
    return self._used
end

---@param otherResult SkillEffectResultBase
function SkillDamageEffectResult:IsSame(otherResult)
    if self._targetID ~= otherResult._targetID then
        return false
    end
    if self._gridPos ~= otherResult._gridPos then
        return false
    end
    return true
end

---技能效果会修改技能预览计算好的技能范围
function SkillDamageEffectResult:SetSpecialScopeResultList(specialScopeResultList)
    self._specialScopeResultList = specialScopeResultList
end

function SkillDamageEffectResult:GetSpecialScopeResultList()
    return self._specialScopeResultList
end

function SkillDamageEffectResult:SetCasterID(casterID)
    self._casterID = casterID
end

function SkillDamageEffectResult:GetCasterID()
    return self._casterID
end

---技能效果196专用，伤害值与施法者的Buff层数相关，需要根据层数播放不同的特效
function SkillDamageEffectResult:SetBuffLayerCountForDamage(layerCount)
    self._buffLayerCountForDamage = layerCount
end

function SkillDamageEffectResult:GetBuffLayerCountForDamage()
    return self._buffLayerCountForDamage
end

function SkillDamageEffectResult:SetDamageIndex(index)
    self._damageIndex = index
end

function SkillDamageEffectResult:GetDamageIndex()
    return self._damageIndex
end

--region 普攻双击
--该伤害是普攻双击造成的
function SkillDamageEffectResult:SetNormalAttackDouble(normalAttackDouble)
    self._normalAttackDouble = normalAttackDouble
end

function SkillDamageEffectResult:GetNormalAttackDouble()
    return self._normalAttackDouble
end
--endregion 普攻双击
