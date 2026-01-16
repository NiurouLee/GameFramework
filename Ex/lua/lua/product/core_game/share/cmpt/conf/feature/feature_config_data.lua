--[[------------------------------------------------------------------------------------------
    FeatureConfigData : 模块配置数据
]] --------------------------------------------------------------------------------------------
_class("FeatureConfigData", Object)
---@class FeatureConfigData: Object
FeatureConfigData = FeatureConfigData
---构造
---@param effectParamParser FeatureEffectParamParser
function FeatureConfigData:Constructor(effectParamParser)
    self._effectParamParser = effectParamParser
end

---解析模块配置数据
---@param featureType number 模块类型
function FeatureConfigData:ParseFeatureConfig(featureType)
    local featureConfigGroup = Cfg.cfg_feature{FeatureType=featureType}
    if featureConfigGroup and #featureConfigGroup > 0 then
    else
        Log.fatal("ParseFeatureConfig feature not exist FeatureType=", featureType, " ", Log.traceback())
        return
    end
    local featureConfig = featureConfigGroup[1]
    self._featureType = featureType

    self._featureIndex = featureConfig.ID
    self._previewType = featureConfig.PreviewType
    self._previewParam = featureConfig.PreviewParam--
    self._layoutOrder = featureConfig.LayoutOrder or -1
    self._icon = featureConfig.Icon
    self._desc = featureConfig.Desc
    ---解析模块效果参数
    self._effectParam =
        self._effectParamParser:ParseFeatureEffectParam(featureType,featureConfig.EffectParam)
end

--[[
    获取模块类型
]]
function FeatureConfigData:GetFeatureType()
    return self._featureType
end

--[[
    获取模块图标
]]
function FeatureConfigData:GetFeatureIcon()
    return self._icon
end

---获取模块描述
function FeatureConfigData:GetFeatureDesc()
    return self._desc
end

---获取模块效果参数
function FeatureConfigData:GetFeatureEffectParam()
    return self._effectParam--这里是模块表中的基础配置
end

---获取预览类型
function FeatureConfigData:GetFeaturePreviewType()
    return self._previewType
end
---获取取预览参数
function FeatureConfigData:GetFeaturePreviewParam()
    return self._previewParam
end
---获取布局序号
function FeatureConfigData:GetFeaturePreviewParam()
    return self._layoutOrder
end