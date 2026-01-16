require("skill_phase_param_base")

_class("SkillPhasePet1602091ChainParam", SkillPhaseParamBase)
---@class SkillPhasePet1602091ChainParam: SkillPhaseParamBase
SkillPhasePet1602091ChainParam = SkillPhasePet1602091ChainParam

function SkillPhasePet1602091ChainParam:GetPhaseType()
    return SkillViewPhaseType.Pet1602091Chain
end

function SkillPhasePet1602091ChainParam:Constructor(t)
    --动作名
    self._animatorTriggerName = t.animatorTriggerName
    --开始->原地跳跃最高点时间
    self._highJumpEffectDelay = t.highJumpEffectDelay
    --起跳时创建特效
    self._highJumpEffectID = t.highJumpEffectID
    --创建特效后->俯冲开始时间
    self._diveDelay = t.diveDelay
    --俯冲时弹道特效
    self._diveTrajectoryEffectID = t.diveTrajectoryEffectID
    --俯冲弹道开始->砸地特效+伤害表现延时
    self._diveEffectFlyTime = t.diveEffectFlyTime
    --砸地特效
    self._groundHitEffectID = t.groundHitEffectID
    --砸地特效开始->伤害跳字
    self._hitDelay = t.hitDelay
    --伤害跳字->角色从俯冲位置消失延时
    self._disappearDelay = t.disappearDelay
    self._disappearEffectID = t.disappearEffectID
    --队伍原始位置格子特效
    self._appearEffectDelay = t.appearEffectDelay
    self._appearEffectID = t.appearEffectID
    --恢复角色模型延时
    self._appearDelay = t.appearDelay
end

local sinsert = function (t, v)
    if not v then
        return
    end

    table.insert(t, v)
end

function SkillPhasePet1602091ChainParam:GetCacheTable()
    local t = {}
    sinsert(t, self:GetEffectResCacheInfo(self._highJumpEffectID))
    sinsert(t, self:GetEffectResCacheInfo(self._diveTrajectoryEffectID))
    sinsert(t, self:GetEffectResCacheInfo(self._groundHitEffectID))
    sinsert(t, self:GetEffectResCacheInfo(self._disappearEffectID))
    sinsert(t, self:GetEffectResCacheInfo(self._appearEffectID))
    return t
end

function SkillPhasePet1602091ChainParam:GetAnimatorTrigger()
    return self._animatorTriggerName
end

function SkillPhasePet1602091ChainParam:GetHighJumpEffectDelay()
    return self._highJumpEffectDelay
end

function SkillPhasePet1602091ChainParam:GetHighJumpEffectID()
    return self._highJumpEffectID
end

function SkillPhasePet1602091ChainParam:GetDiveDelay()
    return self._diveDelay
end

function SkillPhasePet1602091ChainParam:GetDiveTrajectoryEffectID()
    return self._diveTrajectoryEffectID
end

function SkillPhasePet1602091ChainParam:GetDiveEffectFlyTime()
    return self._diveEffectFlyTime
end

function SkillPhasePet1602091ChainParam:GetGroundHitEffectID()
    return self._groundHitEffectID
end

function SkillPhasePet1602091ChainParam:GetHitDelay()
    return self._hitDelay
end

function SkillPhasePet1602091ChainParam:GetDisappearDelay()
    return self._disappearDelay
end

function SkillPhasePet1602091ChainParam:GetDisappearEffectID()
    return self._disappearEffectID
end

function SkillPhasePet1602091ChainParam:GetAppearEffectDelay()
    return self._appearEffectDelay
end

function SkillPhasePet1602091ChainParam:GetAppearEffectID()
    return self._appearEffectID
end

function SkillPhasePet1602091ChainParam:GetAppearDelay()
    return self._appearDelay
end
