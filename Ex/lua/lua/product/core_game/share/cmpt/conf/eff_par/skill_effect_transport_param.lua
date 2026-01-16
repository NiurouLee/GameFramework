require("skill_effect_param_base")

---@class SkillEffectTransportParam : SkillEffectParamBase
_class("SkillEffectTransportParam", SkillEffectParamBase)
SkillEffectTransportParam = SkillEffectTransportParam

function SkillEffectTransportParam:Constructor(t)
    ---@type number
    self._times = t.times or 1 --传送次数

    --强制位移棋盘的参数
    self._isLoop = t.isLoop or 1 --是循环闭合的
    self._offsetPosX = t.offsetPosX or 0 --每次偏移的坐标
    self._offsetPosY = t.offsetPosY or 0
    self._offsetBodyAreaTimes = t.offsetBodyAreaTimes or 1 --默认只执行一次身形内的传送，作用是同时移动多行列
end

function SkillEffectTransportParam:GetEffectType()
    return SkillEffectType.Transport
end

function SkillEffectTransportParam:GetTimes()
    return self._times
end

function SkillEffectTransportParam:GetIsLoop()
    return self._isLoop
end

function SkillEffectTransportParam:GetOffsetPos()
    return Vector2(self._offsetPosX, self._offsetPosY)
end

function SkillEffectTransportParam:GetOffsetBodyAreaTimes()
    return self._offsetBodyAreaTimes
end
