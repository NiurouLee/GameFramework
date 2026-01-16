--[[------------------------------------------------------------------------------------------
    SkillConfigHelper : 技能配置数据辅助，局内局外都会使用
]] --------------------------------------------------------------------------------------------

_class("SkillConfigHelper", Object)
---@class SkillConfigHelper: Object
SkillConfigHelper = SkillConfigHelper

function SkillConfigHelper:Constructor(hasViewParser)
    --解析过的技能配置列表
    self._skillConfigDic = {}
    --技能范围参数解析器
    self._scopeParamParser = SkillScopeParamParser:New()
    self._skillEffectParamParser = SkillEffectParamParser:New()

    ---服务端不需要这个解析器
    if hasViewParser ~= false then
        --技能表现参数解析器
        self._skillViewParamParser = SkillViewParamParser:New()
        self._skillPreviewParamParser = SkillPreviewParamParser:New()
    else
        self._skillViewParamParser = nil
    end
end

---清除读取的数据
function SkillConfigHelper:ClearSkillData()
    self._skillConfigDic = {}
    if self._skillViewParamParser ~= nil then
        self._skillViewParamParser:ClearSkillView()
    end
end

---提取技能数据
---@param skillID number 技能ID
---@param forceFetchNew boolean 传入true表示完全重新构造一个SkillConfigData
---@return SkillConfigData 技能配置数据体
function SkillConfigHelper:GetSkillData(skillID, forceFetchNew)
    if skillID == nil then
        --Log.error("SkillConfigHelper:GetSkillData() skillID is nil")
        return 
    end

    -- 如果需要重新构造，这里不从cache中获取
    if (not forceFetchNew) and self._skillConfigDic[skillID] ~= nil then
        return self._skillConfigDic[skillID]
    end

    ---没有缓存的话，解析一次
    ---@type SkillConfigData
    local skillConfigData =
        SkillConfigData:New(
        self._scopeParamParser,
        self._skillEffectParamParser,
        self._skillViewParamParser,
        self._skillPreviewParamParser
    )
    skillConfigData:ParseSkillConfig(skillID)

    -- 如果需要重新构造，新的SkillConfigData不进入cache
    if not forceFetchNew then
        self._skillConfigDic[skillID] = skillConfigData
    end

    return skillConfigData
end
