require "skill_phase_param_base"

---@class PlaySkillParamBulletFlyToCaster:SkillPhaseParamBase
_class("PlaySkillParamBulletFlyToCaster", SkillPhaseParamBase)
PlaySkillParamBulletFlyToCaster = PlaySkillParamBulletFlyToCaster

function PlaySkillParamBulletFlyToCaster:Constructor(t)
    --1上，2下，3左，4右
    self.direction = t.direction
    --子弹出生特效
    self.bulletBornEftID = t.bulletBornEftID
    --出生时长
    self.bornDuration = t.bornDuration
    --子弹飞行特效
    self.bulletEftID = t.bulletEftID
    --飞行时长
    self.flyDuration = t.flyDuration
    --子弹起点距版边的距离
    self.distanceToEdge = t.distanceToEdge

    self.beHitAnim = t.beHitAnim
    self.beHitEft = t.beHitEft
    self.turnToTarget = t.turnToTarget
    self.deathClear = t.deathClear
end

function PlaySkillParamBulletFlyToCaster:GetPhaseType()
    return SkillViewPhaseType.BulletFlyToCasterFromEdge
end

function PlaySkillParamBulletFlyToCaster:GetCacheTable()
    local t = {}
    if self.bulletBornEftID and self.bulletBornEftID > 0 then
        table.insert(t, {Cfg.cfg_effect[self.bulletBornEftID].ResPath, 1})
    end
    if self.bulletEftID and self.bulletEftID > 0 then
        table.insert(t, {Cfg.cfg_effect[self.bulletEftID].ResPath, 1})
    end
    if self.beHitEft and self.beHitEft > 0 then
        table.insert(t, {Cfg.cfg_effect[self.beHitEft].ResPath, 1})
    end
    return t
end

function PlaySkillParamBulletFlyToCaster:GetDirection()
    return self.direction
end

function PlaySkillParamBulletFlyToCaster:GetBornEffect()
    return self.bulletBornEftID
end

function PlaySkillParamBulletFlyToCaster:GetBornDuration()
    return self.bornDuration
end

function PlaySkillParamBulletFlyToCaster:GetBulletEffect()
    return self.bulletEftID
end

function PlaySkillParamBulletFlyToCaster:GetBulletDuration()
    return self.flyDuration
end

function PlaySkillParamBulletFlyToCaster:GetDistanceToEdge()
    return self.distanceToEdge
end

function PlaySkillParamBulletFlyToCaster:GetBeHitEffect()
    return self.beHitEffect
end

function PlaySkillParamBulletFlyToCaster:GetBeHitAnim()
    return self.beHitAnim
end

function PlaySkillParamBulletFlyToCaster:GetTurnToTarget()
    return self.turnToTarget
end

function PlaySkillParamBulletFlyToCaster:GetDeathClear()
    return self.deathClear
end
