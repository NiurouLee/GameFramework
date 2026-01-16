require("skill_damage_effect_param")
---@class SkillEffectAddBuffByPickupTargetParam: SkillEffectParamBase
_class("SkillEffectAddBuffByPickupTargetParam", SkillEffectParamBase)
SkillEffectAddBuffByPickupTargetParam = SkillEffectAddBuffByPickupTargetParam

function SkillEffectAddBuffByPickupTargetParam:Constructor(t)
    self._buffID = t.buffID --选空格子时附加的BuffID
    self._matchPieceType = t.matchPieceType
    self._trapIDBuffTab = t.trapIDBuffTab --机关及其对应的BuffID
    self._trapIDBuffMatchPieceTypeTab = t.trapIDBuffMatchPieceTypeTab --机关及其对应的BuffID
    self._trapIDList = {}
    if self._trapIDBuffTab then
        for key, value in pairs(self._trapIDBuffTab) do
            table.insert(self._trapIDList, key)
        end
    end
end

--获取效果类型
function SkillEffectAddBuffByPickupTargetParam:GetEffectType()
    return SkillEffectType.AddBuffByPickupTarget
end

--获取机关ID列表
function SkillEffectAddBuffByPickupTargetParam:GetTrapIDList()
    return self._trapIDList
end

--获取点击空格时的附加Buff ID
function SkillEffectAddBuffByPickupTargetParam:GetBuffID()
    return self._buffID
end

--获取机关ID对应的附加Buff ID
---@param trapID number
function SkillEffectAddBuffByPickupTargetParam:GetBuffIDByTrapID(trapID)
    return self._trapIDBuffTab[trapID]
end

--获取匹配格子属性的机关ID对应的附加Buff ID
---@param trapID number
function SkillEffectAddBuffByPickupTargetParam:GetMatchPieceTypeBuffIDByTrapID(trapID)
    return self._trapIDBuffMatchPieceTypeTab[trapID]
end

--获取匹配格子的属性
function SkillEffectAddBuffByPickupTargetParam:GetMatchPieceType()
    return self._matchPieceType
end
