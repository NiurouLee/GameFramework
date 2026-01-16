require("skill_damage_effect_param")
---@class SkillEffectParamAddBuffByPickupBuffLayer: SkillEffectParamBase
_class("SkillEffectParamAddBuffByPickupBuffLayer", SkillEffectParamBase)
SkillEffectParamAddBuffByPickupBuffLayer = SkillEffectParamAddBuffByPickupBuffLayer

function SkillEffectParamAddBuffByPickupBuffLayer:Constructor(t)
    self._trapIDList = t.trapIDList
    self._addBuffList = t.addBuffList or {} --与机关buff层数对应的buff
    self._checkBuffEffectType = t.checkBuffEffectType
end

--获取效果类型
function SkillEffectParamAddBuffByPickupBuffLayer:GetEffectType()
    return SkillEffectType.AddBuffByPickupBuffLayer
end

--获取机关ID列表
function SkillEffectParamAddBuffByPickupBuffLayer:GetTrapIDList()
    return self._trapIDList
end

--机关身上判断层数的buff
function SkillEffectParamAddBuffByPickupBuffLayer:GetCheckBuffEffectType()
    return self._checkBuffEffectType
end

--获取机关buff层数对应要加的buff
---@param layer number
function SkillEffectParamAddBuffByPickupBuffLayer:GetAddBuffIDByLayer(layer)
    local addBuffID = self._addBuffList[layer]
    if not addBuffID then
        if #self._addBuffList > 0 then
            return self._addBuffList[#self._addBuffList]
        else
            return 0
        end
    end
    return addBuffID
end
