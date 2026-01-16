require "state_bounce_player_base"
---@class StateBouncePlayerAccDown : StateBouncePlayerBase
_class("StateBouncePlayerAccDown", StateBouncePlayerBase)
StateBouncePlayerAccDown = StateBouncePlayerAccDown

function StateBouncePlayerAccDown:OnEnter(TT, ...)
    self:Init()
    self:PlayAnim()
    if BounceDebug.ShowObjRect then
        self:ShowDebugRect()
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BoucneAccDown)
end

function StateBouncePlayerAccDown:OnExit(TT)
end

--战斗时间轴更新
function StateBouncePlayerAccDown:OnUpdate(deltaTimeMS)
    self.player:HandleMove(deltaTimeMS, true)
    if self.player.playerData.curSpeed > 0 then
        Log.error("[bounce] StateBouncePlayerAccDown curSpeed = " .. self.player.playerData.curSpeed)
    end
end

function StateBouncePlayerAccDown:GetStateType()
    return StateBouncePlayer.AccDown
end
