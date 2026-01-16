--[[
    血量血条护盾  加血溢出添加
]]
--添加护盾buff
_class("BuffLogicAddHPShieldHpSpilled", BuffLogicBase)
BuffLogicAddHPShieldHpSpilled = BuffLogicAddHPShieldHpSpilled

function BuffLogicAddHPShieldHpSpilled:Constructor(buffInstance, logicParam)
    self._addBuffID = logicParam.addBuffID
end

function BuffLogicAddHPShieldHpSpilled:DoLogic(notify)
    local hpSpilled = notify:GetHPSpilled()
    if not hpSpilled or hpSpilled <= 0 then
        return
    end

    --只有队伍有盾
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    local buffInstance = buffLogicSvc:AddBuff(self._addBuffID, teamEntity, {hpSpilled = hpSpilled})
    return BuffResultAddHPShieldHpSpilled:New(buffInstance:BuffSeq())
end

function BuffLogicAddHPShieldHpSpilled:DoOverlap(logicParam)
    return self:DoLogic()
end
