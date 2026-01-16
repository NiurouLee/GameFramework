--[[------------------------------------------------------------------------------------------
    SkillConfigData : 技能配置数据
]] --------------------------------------------------------------------------------------------
require("skill_scope_filter_param")

_class("SkillConfigData", Object)
---@class SkillConfigData: Object
SkillConfigData = SkillConfigData

---@param scopeParamParser SkillScopeParamParser
---@param effectParamParser SkillEffectParamParser
---@param viewParamParser SkillViewParamParser
---@param previewParamParser SkillPreviewParamParser
function SkillConfigData:Constructor(scopeParamParser, effectParamParser, viewParamParser, previewParamParser)
    self._skillName = ""
    self._skillDesc = ""

    self._subSkillIDList = {}

    self._triggerType = SkillTriggerType.None
    ---@type number
    self._triggerParam = nil
    self._triggerExtraParam = nil
    self._skillType = nil
    self._targetType = SkillTargetType.Monster
    self._targetTypeParam = nil
    self._scopeType = SkillScopeType.Cross
    self._scopeParamData = nil

    self._pickUpType = SkillPickUpType.None
    self._pickUpParam = nil
    ---效果
    self._skillEffectArray = {}

    --技能范围参数解析器
    self._scopeParamParser = scopeParamParser
    self._effectParamParser = effectParamParser

    ---预览参数
    self._previewType = SkillPreviewType.Scope

    ---表现数据
    self._viewParamParser = viewParamParser

    --表现
    self._skillPhaseArray={}
    ----点选有效范围类型
    ------@type SkillPreviewScopeParam[]
    self._pickUpValidScopeList = {}
    ----点选无效范围列表
    ---@type SkillPreviewScopeParam[]
    self._pickUpInvalidScopeList = {}
    ----预览配置
    ----@type SkillPreviewParamBase
    self._previewParamList = {}
    self._previewParamParser = previewParamParser
end

---解析技能配置数据
---@param skillID number 技能ID
function SkillConfigData:ParseSkillConfig(skillID)
    local skillConfig = BattleSkillCfg(skillID)
    if skillConfig == nil then
        Log.fatal("ParseSkillConfig skill not exist skillID=", skillID, " ", Log.traceback())
        return
    end

    self._skillID = skillConfig.ID
    self._skillIcon = skillConfig.Icon
    self._skillDesc = skillConfig.Desc
    self._skillName = skillConfig.Name
    self._skillType = skillConfig.Type
    self._subSkillIDList = skillConfig.SubSkillIDList or {}
    self._skillTag = skillConfig.Tag or {}
    self._triggerType = skillConfig.TriggerType
    self._triggerParam = skillConfig.TriggerParam
    self._triggerExtraParam = skillConfig.TriggerExtraParam
    self._targetType = skillConfig.TargetType
    self._targetTypeParam = skillConfig.TargetTypeParam
    self._scopeCenterType = skillConfig.ScopeCenterType
    self._scopeType = skillConfig.ScopeType
    self._scopeParamData = self._scopeParamParser:ParseScopeParam(skillConfig.ScopeType, skillConfig.ScopeParam)
    self._specialView = skillConfig.SpecialView or {}

    self._scopeFilterParam =
        SkillScopeFilterParam:New(
        {
            scopeCasterOccupiedFilter = skillConfig.ScopeCasterOccupiedFilter,
            obstructingTrapFilter = skillConfig.ScopeObstructingTrapFilter,
            monsterOccupiedPosFilter = skillConfig.ScopeMonsterOccupiedPosFilter,
            targetSelectionMode = skillConfig.TargetSelectionMode
        }
    )
    ---技能选取目标模式
    self._targetSelectionMode = skillConfig.TargetSelectionMode

    self._skillViewParams = skillConfig.ViewParams
    self._skillPhaseAdapter = skillConfig.ViewAdapter

    ---老预览--Begin---------------
    self._pickUpType = skillConfig.PickUpType
    self._pickUpParam = skillConfig.PickUpParam
    ---解析技能预览参数
    self._previewType = skillConfig.PreviewType
    self._previewParam = skillConfig.PreviewParam ---2020-04-21
    ---END------------------------

    ---新预览---Begin----------------
    self:ParsePreview(skillConfig)
    ---新预览---END----------------

    ---解析技能效果参数
    --Log.notice("parse skill config,skillID ", skillID)
    self._skillEffectArray =
        self._effectParamParser:ParseSkillEffectList(skillConfig.EffectTable,nil,self._skillType)

    self._sourceSkillEffectTable = skillConfig.EffectTable

    self._skillPhaseArray[1] = self:ParseViewID(skillConfig.ViewID)
    for skinId, viewID in pairs(self._specialView) do
        self._skillPhaseArray[skinId] = self:ParseViewID(viewID)
    end

    --解析自动战斗释放条件
    self:ParseAutoFightCondition(skillConfig.AutoFightCondition)
    self._autoFightPickPosPolicyParam = skillConfig.AutoFightPickPosPolicyParam
    self._autoFightSkillScopeTypeAndTargetType = skillConfig.AutoFightSkillScopeTypeAndTargetType
    --自动战斗点选方法
    self._autoFightPickPosPolicy = skillConfig.AutoFightPickPosPolicy or PickPosPolicy.MaxTargetCount
    --自动战斗释放顺序
    self._autoFightSkillOrder = skillConfig.AutoFightSkillOrder
    --自动战斗连锁技标签
    self._autoFightChainSkillTag = skillConfig.ChainSkillTag
    --下面这几个参数是用来动态构造技能参数的
    self._metaEffectTableArray = skillConfig.EffectTable
end

--[[
    获取技能ID
]]
function SkillConfigData:GetID()
    return self._skillID
end

--[[
    获取技能图标
]]
function SkillConfigData:GetSkillIcon()
    return self._skillIcon
end

---获取技能表现参数
function SkillConfigData:GetSkillViewParams()
    return self._skillViewParams
end

---获取技能名称
function SkillConfigData:GetSkillName()
    return self._skillName
end

---获取技能描述
function SkillConfigData:GetSkillDesc()
    return self._skillDesc
end

---获取星灵技能描述
function SkillConfigData:GetPetSkillDes(forceParam)
    if forceParam and #forceParam > 0 then
        return StringTable.Get(self._skillDesc,table.unpack(forceParam))
    end
    if self._skillEffectArray == nil or #self._skillEffectArray <= 0 then
        return StringTable.Get(self._skillDesc)
    end
    --查找伤害效果参数
    ---@type SkillDamageEffectParam
    local damageEffectParam = nil
    for i = 1, #self._skillEffectArray do
        local skillEffect = self._skillEffectArray[i]
        if
            skillEffect:GetEffectType() == SkillEffectType.Damage or
                skillEffect:GetEffectType() == SkillEffectType.StampDamage
         then
            damageEffectParam = skillEffect
            break
        end
    end
    --不存在伤害效果
    if not damageEffectParam then
        return StringTable.Get(self._skillDesc)
    end
    local percent = damageEffectParam:GetDamagePercent()
    --伤害参数配置为空或者数量为0
    if percent == nil or table.count(percent) <= 0 then
        return StringTable.Get(self._skillDesc)
    end

    local des = nil
    local percentCount = table.count(percent)

    if percentCount == 1 then
        local value = math.floor(percent[1] * 100 + 0.5)
        des = StringTable.Get(self._skillDesc, tostring(value))
    elseif percentCount == 2 then
        local value1 = math.floor(percent[1] * 100 + 0.5)
        local value2 = math.floor(percent[2] * 100 + 0.5)
        des = StringTable.Get(self._skillDesc, tostring(value1), tostring(value2))
    else
        local value1 = math.floor(percent[1] * 100 + 0.5)
        local value2 = math.floor(percent[2] * 100 + 0.5)
        local value3 = math.floor(percent[3] * 100 + 0.5)
        des = StringTable.Get(self._skillDesc, tostring(value1), tostring(value2), tostring(value3))
    end

    return des
end

---获取技能类型
function SkillConfigData:GetSkillType()
    return self._skillType
end

---获取技能的目标类型
function SkillConfigData:GetSkillTargetType()
    return self._targetType
end

---获取技能的目标类型参数
function SkillConfigData:GetSkillTargetTypeParam()
    return self._targetTypeParam
end

--技能范围中心类型
function SkillConfigData:GetSkillScopeCenterType()
    return self._scopeCenterType
end

---获取技能的范围类型
function SkillConfigData:GetSkillScopeType()
    return self._scopeType
end

---获取技能的范围参数
function SkillConfigData:GetSkillScopeParam()
    return self._scopeParamData
end

---获取技能效果
function SkillConfigData:GetSkillEffect()
    return self._skillEffectArray
end

function SkillConfigData:GetSkillSourceEffectTable()
    return self._sourceSkillEffectTable
end

---获取技能表现[黑拳赛模式下同一个技能ID不同的皮肤对应不同表现]
function SkillConfigData:GetSkillPhaseArray(skinID)
    skinID = skinID or 1
    local ret =  self._skillPhaseArray[skinID]
    if not ret then
        ret = self._skillPhaseArray[1]
    end
    return ret
end

---提取预览类型
function SkillConfigData:GetSkillPreviewType()
    return self._previewType
end
---提取预览参数
function SkillConfigData:GetSkillPreviewParam()
    return self._previewParam
end

--提取手动选择类型
function SkillConfigData:GetSkillPickType()
    return self._pickUpType
end

function SkillConfigData:GetSkillPickParam()
    return self._pickUpParam
end

--提取触发类型
function SkillConfigData:GetSkillTriggerType()
    return self._triggerType
end

--提取触发参数
function SkillConfigData:GetSkillTriggerParam()
    return self._triggerParam
end
--提取触发额外参数
function SkillConfigData:GetSkillTriggerExtraParam()
    return self._triggerExtraParam
end


--技能表现数据提取
function SkillConfigData:GetSkillPhaseAdapter()
    return self._skillPhaseAdapter
end

---@return SkillScopeFilterParam
function SkillConfigData:GetScopeFilterParam()
    return self._scopeFilterParam
end

function SkillConfigData:ParseScopeParam(nScopeType, scopeParam)
    return self._scopeParamParser:ParseScopeParam(nScopeType, scopeParam)
end
---2020-04-15 韩玉信添加
---查找是否有某个特殊的效果
function SkillConfigData:IsHaveEffect_Common(pCallBack)
    local nEffectCount = table.count(self._skillEffectArray)
    for i = 1, nEffectCount do
        ---@type SkillEffectParam_Teleport  这里应该有个基类，因为现阶段基类是Object，为了方便先用 SkillEffectParam_Teleport来代替注释， 这里不是真的是这个类
        local effectData = self._skillEffectArray[i]
        if effectData then
            local nEffectType = effectData:GetEffectType()
            local bFind = pCallBack(self, nEffectType)
            if bFind then
                return true
            end
        end
    end
    return false
end
---判断技能效果内是否有击退效果
function SkillConfigData:_IsHaveEffect_HitBack(nEffectType)
    if SkillEffectType.HitBack == nEffectType then
        return true
    end
    return false
end
---判断技能效果内是否有转色效果
function SkillConfigData:_IsHaveEffect_Convert(nEffectType)
    if
        SkillEffectType.ConvertGridElement == nEffectType or SkillEffectType.ManualConvert == nEffectType or
            SkillEffectType.IslandConvert == nEffectType
     then
        return true
    end
    -- if SkillEffectType.ResetGridElement == nEffectType then
    --     return true
    -- end
    return false
end
---判断技能效果内是否有瞬移效果
function SkillConfigData:_IsHaveEffect_Teleport(nEffectType)
    if SkillEffectType.Teleport == nEffectType then
        return true
    end
    return false
end

function SkillConfigData:_IsHaveEffect_Damage(nEffectType)
    return nEffectType == SkillEffectType.Damage or nEffectType == SkillEffectType.DamageOnTargetCount or
        nEffectType == SkillEffectType.StampDamage
end
---判断技能效果内是否有击退效果
function SkillConfigData:IsHaveEffect_HitBack()
    return self:IsHaveEffect_Common(self._IsHaveEffect_HitBack)
end
---判断技能效果内是否有转色效果
function SkillConfigData:IsHaveEffect_Convert()
    return self:IsHaveEffect_Common(self._IsHaveEffect_Convert)
end
---判断技能效果内是否有瞬移效果
function SkillConfigData:IsHaveEffect_Teleport()
    return self:IsHaveEffect_Common(self._IsHaveEffect_Teleport)
end
---判断技能效果内是否有伤害
function SkillConfigData:IsHaveEffect_Damage()
    return self:IsHaveEffect_Common(self._IsHaveEffect_Damage)
end

--获取主动技定位标签
function SkillConfigData:GetSkillTag()
    return self._skillTag
end

function SkillConfigData:ParseViewID(viewID)
    local ret = nil
    if self._viewParamParser then
        ---解析技能表现过程参
        ret = self._viewParamParser:ParseSkillView(viewID, self:GetSkillViewParams())
    end
    if not ret then
        if EDITOR then
            Log.warn("no skill view, skillViewID = ", viewID)
        end
    end
    return ret
end

function SkillConfigData:GetSkillViewID(skinID)
    return self._skillViewID
end

function SkillConfigData:ParsePreview(skillConfig)
    if skillConfig.PickUpScopeType then
        ---点选有效范围
        self._pickUpValidScopeList = {}
        for _, v in ipairs(skillConfig.PickUpScopeType) do
            ---@type SkillPreviewScopeParam
            local pickUpScopeParam = SkillPreviewScopeParam:New(v)
            local scopeParamData = self._scopeParamParser:ParseScopeParam(v.ScopeType, v.ScopeParam)
            pickUpScopeParam:SetScopeParamData(scopeParamData)
            table.insert(self._pickUpValidScopeList, pickUpScopeParam)
        end
    end
    if skillConfig.PickUpInvalidScopeList then
        ---点选无效范围
        self._pickUpInvalidScopeList = {}
        for _, v in pairs(skillConfig.PickUpInvalidScopeList) do
            ---@type SkillPreviewScopeParam
            local pickUpInvalidScopeParam = SkillPreviewScopeParam:New(v)
            local pickUpScopeParamData = self._scopeParamParser:ParseScopeParam(v.ScopeType, v.ScopeParam)
            pickUpInvalidScopeParam:SetScopeParamData(pickUpScopeParamData)
            table.insert(self._pickUpInvalidScopeList, pickUpInvalidScopeParam)
        end
    end
    ---服务器没有这个Parser也不用执行这坨逻辑
    if self._previewParamParser then
        if skillConfig.PreviewList then
            self._previewParamList = self._previewParamParser:ParseSkillPreviewList(skillConfig.PreviewList)
        end
    end
end

--CasterHP<0.5 & CoverGrid>3 | ConnectGrid<15 & (AttackGrid>3 | AttackTarget>3 | TargetHP<0.1) | AlwaysTrue|AlwaysFalse
function SkillConfigData:ParseAutoFightCondition(condition)
    if not condition then
        return
    end

    self._autoFightCondition = {
        conds = {},
        callback = function(t)
            local code =
                string.gsub(
                condition,
                "%a+",
                function(s)
                    return t.conds[s]
                end
            )
            code = string.gsub(code, "&", " and ")
            code = string.gsub(code, "|", " or ")
            code = "return " .. code
            local f = load(code)
            if not f then
                Log.error("code:", code)
            end
            return f()
        end
    }
    for cond in string.gmatch(condition, "%a+") do
        self._autoFightCondition.conds[cond] = 0
    end
end

function SkillConfigData:GetAutoFightCondition()
    return self._autoFightCondition
end

function SkillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    return self._autoFightSkillScopeTypeAndTargetType
end

function SkillConfigData:GetAutoFightPickPosPolicy()
    return self._autoFightPickPosPolicy
end

function SkillConfigData:GetAutoFightSkillOrder()
    return self._autoFightSkillOrder
end

function SkillConfigData:GetAutoFightChainSkillTag()
    return self._autoFightChainSkillTag
end

function SkillConfigData:GetMetaEffectTableArray()
    return self._metaEffectTableArray
end

function SkillConfigData:GetSpecialView(key)
end

function SkillConfigData:GetPickUpValidScopeConfig()
    return self._pickUpValidScopeList
end

function SkillConfigData:GetPickUpInvalidScopeConfig()
    return self._pickUpInvalidScopeList
end

function SkillConfigData:GetTargetSelectionModeConfig()
    return self._targetSelectionMode
end

---获取技能效果
---@return SkillEffectParamBase
function SkillConfigData:GetSkillEffectByIndex(index)
    return self._skillEffectArray[index]
end


--获取子技能ID列表
function SkillConfigData:GetSubSkillIDList()
    return self._subSkillIDList
end

function SkillConfigData:GetAutoFightPickPosPolicyParam()
    return self._autoFightPickPosPolicyParam
end
