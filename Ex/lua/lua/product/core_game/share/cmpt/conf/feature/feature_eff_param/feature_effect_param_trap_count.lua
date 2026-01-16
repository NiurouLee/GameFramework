---机关数量显示模块参数
---@class FeatureEffectParamTrapCount: FeatureEffectParamBase
_class("FeatureEffectParamTrapCount", FeatureEffectParamBase)
FeatureEffectParamTrapCount = FeatureEffectParamTrapCount
---构造
function FeatureEffectParamTrapCount:Constructor(t)
    if not t then
        return
    end
    self:_RefreshData(t)
end
--读表数据
function FeatureEffectParamTrapCount:_RefreshData(t)
    if not t then
        return
    end
    --初始化和用光灵、关卡数据覆盖时都会调用，需要判断t.xxx是否存在
    if t.TargetTrapIDList then
        self._targetTrapIDList = t.TargetTrapIDList
    end
    if t.MaxCount then
        self._maxCount = t.MaxCount
    end
    if t.Icon then
        self._icon = t.Icon
    end
    if t.TitleStr then
        self._titleStr = t.TitleStr
    end
end
---模块类型
function FeatureEffectParamTrapCount:GetFeatureType()
    return FeatureType.TrapCount
end
function FeatureEffectParamTrapCount:GetTargetTrapIDList()
    return self._targetTrapIDList
end
function FeatureEffectParamTrapCount:GetMaxCount()
    return self._maxCount
end
function FeatureEffectParamTrapCount:GetIcon()
    return self._icon
end
function FeatureEffectParamTrapCount:GetTitleStr()
    return self._titleStr
end