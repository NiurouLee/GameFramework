--[[------------------------------------------------------------------------------------------
    FeatureConfigHelper : 模块配置数据辅助
]] --------------------------------------------------------------------------------------------

_class("FeatureConfigHelper", Object)
---@class FeatureConfigHelper: Object
FeatureConfigHelper = FeatureConfigHelper
---构造
function FeatureConfigHelper:Constructor()
    self._featureConfigDic = {}
    self._featureEffectParamParser = FeatureEffectParamParser:New()
end

---清除读取的数据
function FeatureConfigHelper:ClearFeatureData()
    self._featureConfigDic = {}
end

---提取模块数据
---@param featureType number 模块类型
---@return FeatureConfigData 模块配置数据体
function FeatureConfigHelper:GetFeatureData(featureType)
    if featureType == nil then
        Log.error("FeatureConfigHelper:GetFeatureData() featureType is nil")
        return 
    end
    
    if self._featureConfigDic[featureType] ~= nil then
        return self._featureConfigDic[featureType]
    end

    ---没有缓存的话，解析一次
    ---@type FeatureConfigData
    local featureConfigData =
    FeatureConfigData:New(
        self._featureEffectParamParser
    )
    featureConfigData:ParseFeatureConfig(featureType)

    self._featureConfigDic[featureType] = featureConfigData

    return featureConfigData
end
---解析光灵、关卡配置的模块 其中参数在基础参数上替换
function FeatureConfigHelper:ParseCustomFeatureList(feature_list)
    local effectParamList = {}
    if not feature_list then
        return effectParamList
    end
    ---先取出索引
    local effectIndexList = {}
    for k, v in pairs(feature_list) do--原始配置数据 {[featureType]={}}
        effectIndexList[#effectIndexList + 1] = k
    end
    ---默认排序
    table.sort(effectIndexList)

    for _, featureType in ipairs(effectIndexList) do
        ---@type FeatureConfigData
        local baseData = self:GetFeatureData(featureType)
        if baseData then
            local baseParam = baseData:GetFeatureEffectParam()
            local effectParamObj
            if baseParam and baseParam.CloneSelf then
                effectParamObj = baseParam:CloneSelf()--new
                if effectParamObj then
                    local effectParamCfg = feature_list[featureType]
                    effectParamObj:ReplaceByCustomCfg(effectParamCfg)
                    effectParamList[#effectParamList + 1] = effectParamObj
                end
            end
        end
    end

    return effectParamList
end