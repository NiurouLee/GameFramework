---消灭星星技能模块参数
---@class FeatureEffectParamPopStar: FeatureEffectParamBase
_class("FeatureEffectParamPopStar", FeatureEffectParamBase)
FeatureEffectParamPopStar = FeatureEffectParamPopStar
---构造
function FeatureEffectParamPopStar:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end

--读表数据
function FeatureEffectParamPopStar:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.SkillID then
        self._skillID = t.SkillID --技能id
    end
end

---模块类型
function FeatureEffectParamPopStar:GetFeatureType()
    return FeatureType.PopStar
end

---复制用
---@param param FeatureEffectParamPopStar
function FeatureEffectParamPopStar:CopyFrom(param)
    if param then
        for k, v in pairs(param) do
            self[k] = v
        end
    end
end

---复制
---@return FeatureEffectParamPopStar
function FeatureEffectParamPopStar:CloneSelf()
    local param = FeatureEffectParamPopStar:New()
    param:CopyFrom(self)
    return param
end

---替换部分参数
function FeatureEffectParamPopStar:ReplaceByCustomCfg(t)
    self:_RefreshData(t)
end

---技能id
function FeatureEffectParamPopStar:GetMasterSkillID()
    return self._skillID
end
