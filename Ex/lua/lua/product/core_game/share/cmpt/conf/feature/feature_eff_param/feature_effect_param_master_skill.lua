---空裔技能模块参数
---@class FeatureEffectParamMasterSkill: FeatureEffectParamBase
_class("FeatureEffectParamMasterSkill", FeatureEffectParamBase)
FeatureEffectParamMasterSkill = FeatureEffectParamMasterSkill
---构造
function FeatureEffectParamMasterSkill:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamMasterSkill:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.SkillID then
        self._skillID = t.SkillID--技能id
    end
    if t.UiType then
        self._uiType = t.UiType--改ui
    end
end
---模块类型
function FeatureEffectParamMasterSkill:GetFeatureType()
    return FeatureType.MasterSkill
end
---复制用
---@param param FeatureEffectParamMasterSkill
function FeatureEffectParamMasterSkill:CopyFrom(param)
    if param then
        for k,v in pairs(param) do
            self[k] = v
        end
    end
end
---复制
---@return FeatureEffectParamMasterSkill
function FeatureEffectParamMasterSkill:CloneSelf()
    local param = FeatureEffectParamMasterSkill:New()
    param:CopyFrom(self)
    return param
end
---替换部分参数
function FeatureEffectParamMasterSkill:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end
---技能id
function FeatureEffectParamMasterSkill:GetMasterSkillID()
    return self._skillID
end
function FeatureEffectParamMasterSkill:GetUiType()
    return self._uiType or FeatureMasterSkillUiType.Default
end