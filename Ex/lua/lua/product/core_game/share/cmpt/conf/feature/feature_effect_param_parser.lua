--[[------------------------------------------------------------------------------------------
    FeatureEffectParamParser : 模块效果解析器
]] --------------------------------------------------------------------------------------------

_class("FeatureEffectParamParser", Object)
---@class FeatureEffectParamParser: Object
FeatureEffectParamParser = FeatureEffectParamParser
---构造
function FeatureEffectParamParser:Constructor()
    ---注册所有解析类型
    self._effectParamClassDict = {}
    self._effectParamClassDict[FeatureType.Sanity] = FeatureEffectParamSan
    self._effectParamClassDict[FeatureType.DayNight] = FeatureEffectParamDayNight
    self._effectParamClassDict[FeatureType.PersonaSkill] = FeatureEffectParamPersonaSkill
    self._effectParamClassDict[FeatureType.Card] = FeatureEffectParamCard
    self._effectParamClassDict[FeatureType.MasterSkill] = FeatureEffectParamMasterSkill
    self._effectParamClassDict[FeatureType.Scan] = FeatureEffectParamScan
    self._effectParamClassDict[FeatureType.MasterSkillRecover] = FeatureEffectParamMasterSkillRecover
    self._effectParamClassDict[FeatureType.MasterSkillTeleport] = FeatureEffectParamMasterSkillTeleport
    self._effectParamClassDict[FeatureType.TrapCount] = FeatureEffectParamTrapCount
    self._effectParamClassDict[FeatureType.PopStar] = FeatureEffectParamPopStar
end
---解析模块效果列表 光灵、关卡用 在基础配置上替换
-- function FeatureEffectParamParser:ParseFeatureList(feature_list)
--     local effectParamList = {}
--     if not feature_list then
--         return effectParamList
--     end
--     ---先取出索引
--     local effectIndexList = {}
--     for k, v in pairs(feature_list) do
--         effectIndexList[#effectIndexList + 1] = k
--     end

--     ---默认排序
--     table.sort(effectIndexList)

--     for _, featureType in ipairs(effectIndexList) do
--         local effectParam = feature_list[featureType]
--         local classType = self._effectParamClassDict[featureType]
--         if (classType == nil) then
--             Log.exception("ParseFeatureList cant find featureType ", featureType)
--             return effectParamList
--         end

--         ---创建对象
--         local paramDataObj = classType:New(effectParam)

--         effectParamList[#effectParamList + 1] = paramDataObj
--     end

--     return effectParamList
-- end
---解析模块效果参数
function FeatureEffectParamParser:ParseFeatureEffectParam(
    featureType,
    effectParam)
    local classType = self._effectParamClassDict[featureType]
    if (classType == nil) then
        Log.error("ParseFeatureEffectParam cant find featureType ", featureType)
    end

    ---创建对象
    local paramDataObj = classType:New(effectParam)
    return paramDataObj
end
