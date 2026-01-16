---P5模块参数
---@class FeatureEffectParamPersonaSkill: FeatureEffectParamBase
_class("FeatureEffectParamPersonaSkill", FeatureEffectParamBase)
FeatureEffectParamPersonaSkill = FeatureEffectParamPersonaSkill
---构造
function FeatureEffectParamPersonaSkill:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamPersonaSkill:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.SkillID then
        self._skillID = t.SkillID--技能id
    end
end
---模块类型
function FeatureEffectParamPersonaSkill:GetFeatureType()
    return FeatureType.PersonaSkill
end
---复制用
---@param param FeatureEffectParamPersonaSkill
function FeatureEffectParamPersonaSkill:CopyFrom(param)
    if param then
        for k,v in pairs(param) do
            self[k] = v
        end
    end
end
---复制
---@return FeatureEffectParamPersonaSkill
function FeatureEffectParamPersonaSkill:CloneSelf()
    local param = FeatureEffectParamPersonaSkill:New()
    param:CopyFrom(self)
    return param
end
---替换部分参数
function FeatureEffectParamPersonaSkill:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end
---技能id
function FeatureEffectParamPersonaSkill:GetPersonaSkillID()
    return self._skillID
end
