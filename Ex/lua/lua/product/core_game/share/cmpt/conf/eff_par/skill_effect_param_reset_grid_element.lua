--[[----------------------------------------------------------------
    2020-02-12 韩玉信添加
    SkillEffectParam_ResetGridElement : 重置所有格子
    2020-07-09 增加了子类SkillEffectParam_ResetSelectGridElement，有调整时考虑下
--]] ----------------------------------------------------------------
require("skill_effect_param_base")

_class("SkillEffectParam_ResetGridElement", SkillEffectParamBase)
---@class SkillEffectParam_ResetGridElement:SkillEffectParamBase
SkillEffectParam_ResetGridElement = SkillEffectParam_ResetGridElement

function SkillEffectParam_ResetGridElement:Constructor(t)
    --{element=2, percent=0.5} 火属性格子刷新频率percent
    self._element = t.element
    self._percent = t.percent
    self._convertGray = t.convertGray
    --默认刷机关，靳策添加
    if t.flushTrap == nil then
        self._flushTrap = true
    else
        self._flushTrap = t.flushTrap
    end
    --无视转色阻挡
    self._ignoreBlock = t.ignoreBlock
    local protectElementArray = t.protectElementType or {}
    self._protectElementType = {}
    for _, pieceType in ipairs(protectElementArray) do
        self._protectElementType[pieceType] = true
    end
    self._excludeTrapIDList = t.excludeTrapIDList or {}
    ---生成格子时是否排除掉范围内的颜色
    self._excludeRangColor = t.excludeRangeColor or false
    self._targetGridTypeList = t.targetGridTypeList or {1, 2, 3, 4}
    self._resetTrapId = t.resetTrapId
    self._targetElement = t.targetElement
    self._targetElementProb = t.targetElementProb
end

---@return number[]
function SkillEffectParam_ResetGridElement:GetResetTrapId()
    return self._resetTrapId
end

function SkillEffectParam_ResetGridElement:GetTargetElement()
    return self._targetElement
end

function SkillEffectParam_ResetGridElement:GetTargetElementProb()
    return self._targetElementProb
end

function SkillEffectParam_ResetGridElement:GetEffectType()
    return SkillEffectType.ResetGridElement
end

function SkillEffectParam_ResetGridElement:GetElement()
    return self._element
end

function SkillEffectParam_ResetGridElement:GetPercent()
    return self._percent
end
---@return boolean 是否可重置灰色格子
function SkillEffectParam_ResetGridElement:GetConvertGray()
    return self._convertGray
end

---@return boolean 是否可洗机关
function SkillEffectParam_ResetGridElement:GetCanFlushTrap()
    return self._flushTrap
end

function SkillEffectParam_ResetGridElement:GetProtectElementType()
    return self._protectElementType
end

function SkillEffectParam_ResetGridElement:GetExcludeTrapIDList()
    return self._excludeTrapIDList
end

function SkillEffectParam_ResetGridElement:GetExcludeRangeColor()
    return self._excludeRangColor
end

function SkillEffectParam_ResetGridElement:GetTargetGridTypeList()
    return self._targetGridTypeList
end

function SkillEffectParam_ResetGridElement:GetIgnoreBlock()
    return self._ignoreBlock
end