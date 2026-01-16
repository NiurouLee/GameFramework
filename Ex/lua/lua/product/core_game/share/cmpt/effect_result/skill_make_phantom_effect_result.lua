--[[------------------------------------------------------------------------------------------
    制造幻象技能结果
]] --------------------------------------------------------------------------------------------


_class("SkillMakePhantomEffectResult", SkillEffectResultBase)
---@class SkillMakePhantomEffectResult: SkillEffectResultBase
SkillMakePhantomEffectResult = SkillMakePhantomEffectResult

function SkillMakePhantomEffectResult:Constructor(owner, hpPercent, targetID, pos, rot)
    self.owner = owner
    self.hpPercent = hpPercent
    self.pos = pos
    ---这是个方向Dir，Vector2类型
    self.rot = rot
    self.targetID = targetID
	self.targetEntityID= nil
end
function SkillMakePhantomEffectResult:GetEffectType()
    return SkillEffectType.MakePhantom
end

function SkillMakePhantomEffectResult:GetHPPercent()
    return self.hpPercent
end

function SkillMakePhantomEffectResult:GetBornPos()
    return self.pos
end

function SkillMakePhantomEffectResult:GetBornRot()
    return self.rot
end

function SkillMakePhantomEffectResult:GetOwnerID()
    return self.owner
end

function SkillMakePhantomEffectResult:GetTargetID()
    return self.targetID
end

function SkillMakePhantomEffectResult:SetTargetEntityID(entityID)
	self.targetEntityID = entityID
end

function SkillMakePhantomEffectResult:GetTargetEntityID()
	return self.targetEntityID
end

