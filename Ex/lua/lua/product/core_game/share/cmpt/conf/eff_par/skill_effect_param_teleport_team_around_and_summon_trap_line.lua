--[[------------------------------------------------------------------------------------------
    TeleportTeamAroundAndSummonTrapLine = 197, ---瞬移位置到队伍周围一圈，朝向目标。从旧坐标连线到新坐标中心召唤机关，如果没有空位位置可以往外面找格子
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamTeleportTeamAroundAndSummonTrapLine", SkillEffectParamBase)
---@class SkillEffectParamTeleportTeamAroundAndSummonTrapLine: SkillEffectParamBase
SkillEffectParamTeleportTeamAroundAndSummonTrapLine = SkillEffectParamTeleportTeamAroundAndSummonTrapLine

function SkillEffectParamTeleportTeamAroundAndSummonTrapLine:Constructor(t)
    self._trapID = t.trapID
    self._limitCount = t.limitCount --数量限制
    -- self._supplementCount = t.supplementCount --数量不够时一次补充数量

    self._squareRingStart = t.squareRingStart or 1 --瞬移后距离队伍的圈数
end

function SkillEffectParamTeleportTeamAroundAndSummonTrapLine:GetEffectType()
    return SkillEffectType.TeleportTeamAroundAndSummonTrapLine
end

function SkillEffectParamTeleportTeamAroundAndSummonTrapLine:GetTrapID()
    return self._trapID
end

function SkillEffectParamTeleportTeamAroundAndSummonTrapLine:GetLimitCount()
    return self._limitCount
end

function SkillEffectParamTeleportTeamAroundAndSummonTrapLine:GetSquareRingStart()
    return self._squareRingStart
end
