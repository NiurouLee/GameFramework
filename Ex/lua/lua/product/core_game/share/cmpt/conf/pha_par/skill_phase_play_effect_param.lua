--[[------------------------------------------------------------------------------------------
    SkillPhasePlayEffectParam : 播放特效阶段(现在比较简单，后续扩展)
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---技能播放特效的类型
---@class SkillPlayEffectType
SkillPlayEffectType = {
    Grid = 0, --默认是在某个格子位置上播放特效
    HealthShield = 1, --血条护盾罩子
    CasterTransform = 2 --和施法者的位置和方向关联
}
_enum("SkillPlayEffectType", SkillPlayEffectType)

---@class SkillPhasePlayEffectParam: Object
_class("SkillPhasePlayEffectParam", SkillPhaseParamBase)
SkillPhasePlayEffectParam = SkillPhasePlayEffectParam

function SkillPhasePlayEffectParam:Constructor(t)
    self._effectID = t.effectID
    self._position = t.position
    ---@type SkillPlayEffectType
    self._effectType = t.effectType or SkillPlayEffectType.Grid
    if t.rotation then
        local r = t.rotation
        self._quaternionDir = Quaternion.AngleAxis(r.angle, Vector3(r.axis.x, r.axis.y, r.axis.z)) --SkillPlayEffectType为CasterTransform时特效的旋转
    end
    if t.translation then
        local tran = t.translation
        self._translationQuaternion = Quaternion.AngleAxis(tran.angle, Vector3(tran.axis.x, tran.axis.y, tran.axis.z)) --SkillPlayEffectType为CasterTransform时特效的偏移四元数
        self._translationOffset = tran.offset --SkillPlayEffectType为CasterTransform时特效的偏移长度
    end
end

function SkillPhasePlayEffectParam:GetPhaseType()
    return SkillViewPhaseType.PlayEffect
end

function SkillPhasePlayEffectParam:GetEffectID()
    return self._effectID
end

function SkillPhasePlayEffectParam:GetEffectPosition()
    return self._position
end

---@return SkillPlayEffectType
function SkillPhasePlayEffectParam:GetPlayEffectType()
    return self._effectType
end
---@return Quaternion
function SkillPhasePlayEffectParam:GetQuaternionDir()
    return self._quaternionDir
end
---@return Quaternion
function SkillPhasePlayEffectParam:GetTranslationQuaternion()
    return self._translationQuaternion
end
---@return number
function SkillPhasePlayEffectParam:GetTranslationOffset()
    return self._translationOffset
end

function SkillPhasePlayEffectParam:GetCacheTable()
    local t = {}
    table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    return t
end
