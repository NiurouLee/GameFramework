--[[------------------------------------------------------------------------------------------
    SkillManualConvertGridElementEffectResult : 技能转色结果
]] --------------------------------------------------------------------------------------------

---@class SkillManualConvertGridElementEffectResult: SkillEffectResultBase
_class("SkillManualConvertGridElementEffectResult", SkillEffectResultBase)
SkillManualConvertGridElementEffectResult = SkillManualConvertGridElementEffectResult

---@param targetElementType ElementType
function SkillManualConvertGridElementEffectResult:Constructor(gridArray, targetElementType)
    ---转色的结果参数是需要跟范围相关的，目前只做了一个方环形的结果 ,后边加的时候，可以增加一个范围类型的定义
    ---根据不同的范围，做不同的解析
    self._gridArray = gridArray
    self._targetElementType = targetElementType
end

function SkillManualConvertGridElementEffectResult:GetEffectType()
    return SkillEffectType.ManualConvert
end


function SkillManualConvertGridElementEffectResult:GetTargetGridArray()
    return self._gridArray
end

---@return ElementType
function SkillManualConvertGridElementEffectResult:GetTargetElementType()
    return self._targetElementType
end
