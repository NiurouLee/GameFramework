---空裔技能模块参数
---@class FeatureEffectParamMasterSkillRecover: FeatureEffectParamBase
_class("FeatureEffectParamMasterSkillRecover", FeatureEffectParamBase)
FeatureEffectParamMasterSkillRecover = FeatureEffectParamMasterSkillRecover
---构造
function FeatureEffectParamMasterSkillRecover:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamMasterSkillRecover:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.SkillID then
        self._skillID = t.SkillID--技能id
    end
end
---模块类型
function FeatureEffectParamMasterSkillRecover:GetFeatureType()
    return FeatureType.MasterSkillRecover
end
---技能id
function FeatureEffectParamMasterSkillRecover:GetMasterSkillID()
    return self._skillID
end
