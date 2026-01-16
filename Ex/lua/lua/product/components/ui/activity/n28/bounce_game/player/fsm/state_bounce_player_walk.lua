---@class StateBouncePlayerWalk : StateBouncePlayerBase
_class("StateBouncePlayerWalk", StateBouncePlayerBase)
StateBouncePlayerWalk = StateBouncePlayerWalk

function StateBouncePlayerWalk:OnEnter(TT, ...)
    self:Init()
    self:PlayAnim()
    if BounceDebug.ShowObjRect then
        self:ShowDebugRect()
    end
end

function StateBouncePlayerWalk:OnExit(TT)
end

--jump cmd
function StateBouncePlayerWalk:OnJump()
    --chgspeed and chg to jump state
    self.playerData.curSpeed = self.playerData.baseJumpSpeed
    self.player:ChgPlayerState(StateBouncePlayer.Jump)
end

--attack cmd
-- function StateBouncePlayerWalk:OnAttack()
--     local duration = self.bounceData.durationMs
--     if self.playerData:CheckAttackCD(duration, true) then
--         --直接攻击
--         self.player:ChgPlayerState(StateBouncePlayer.Attack)
--     end
-- end

function StateBouncePlayerWalk:GetStateType()
    return StateBouncePlayer.Walk
end
