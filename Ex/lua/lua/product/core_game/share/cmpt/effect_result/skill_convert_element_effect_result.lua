--[[------------------------------------------------------------------------------------------
    SkillConvertGridElementEffectResult : 技能转色结果
]] --------------------------------------------------------------------------------------------
require("skill_effect_result_base")
_class("SkillConvertGridElementEffectResult", SkillEffectResultBase)
---@class SkillConvertGridElementEffectResult: SkillEffectResultBase
SkillConvertGridElementEffectResult = SkillConvertGridElementEffectResult

---@param targetElementType ElementType
function SkillConvertGridElementEffectResult:Constructor(gridArray, targetElementType, blockGridArray)
    ---转色的结果参数是需要跟范围相关的，目前只做了一个方环形的结果 ,后边加的时候，可以增加一个范围类型的定义
    ---根据不同的范围，做不同的解析
    self._gridArray = gridArray
    self._targetElementType = targetElementType
    self._blockGridArray = blockGridArray --阻挡转色的格子
    self._notifyBuff = true --转色是否通知buff,默认通知
end

function SkillConvertGridElementEffectResult:GetEffectType()
    return SkillEffectType.ConvertGridElement
end

function SkillConvertGridElementEffectResult:GetTargetGridArray()
    return self._gridArray
end

---@return ElementType
function SkillConvertGridElementEffectResult:GetTargetElementType()
    return self._targetElementType
end

function SkillConvertGridElementEffectResult:GetNewGridNumByType(pieceType)
    if self._targetElementType == pieceType then
        return #self._gridArray
    end
    return 0
end

function SkillConvertGridElementEffectResult:GetBlockGridArray()
    return self._blockGridArray
end

function SkillConvertGridElementEffectResult:SetForceConvert()
    self._forceConvert = true
end

function SkillConvertGridElementEffectResult:IsForceConvert()
    return self._forceConvert
end

function SkillConvertGridElementEffectResult:GetNotifyBuff()
    return self._notifyBuff
end

function SkillConvertGridElementEffectResult:SetNotifyBuff(notifyBuff)
    self._notifyBuff = notifyBuff
end
