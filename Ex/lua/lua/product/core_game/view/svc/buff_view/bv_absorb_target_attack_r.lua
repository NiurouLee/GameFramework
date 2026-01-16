--[[
    锁血破后释放一个技能在View里面
]]
_class("BuffViewAbsorbTargetAttack", BuffViewBase)
---@class BuffViewAbsorbTargetAttack:BuffViewBase
BuffViewAbsorbTargetAttack = BuffViewAbsorbTargetAttack

function BuffViewAbsorbTargetAttack:PlayView(TT)
	local param = 	self._viewInstance:BuffConfigData():GetViewParams()
	local materialAnim = param.MaterialAnim
	local ownerEntity = self:Entity()
	ownerEntity:PlayMaterialAnim(materialAnim)
end
