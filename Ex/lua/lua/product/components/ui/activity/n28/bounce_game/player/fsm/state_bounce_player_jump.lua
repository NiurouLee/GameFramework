---@class StateBouncePlayerJump : StateBouncePlayerBase
_class("StateBouncePlayerJump", StateBouncePlayerBase)
StateBouncePlayerJump = StateBouncePlayerJump

function StateBouncePlayerJump:OnEnter(TT, ...)
    self:Init()
    self:PlayAnim()
    self:LoadJumpEffect()
    if BounceDebug.ShowObjRect then
        self:ShowDebugRect()
    end
    self.viewBehavior = self.player:GetBehavior(BouncePlayerBeHaviorView:Name())
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N28BounceJump)
end

function StateBouncePlayerJump:OnExit(TT)
end

--jump cmd
function StateBouncePlayerJump:OnJump()
    local duration = self.bounceData.durationMs
    if self.playerData:ChecAirkAttackCD(duration, true) then
         --修改速度
         self.playerData.curSpeed = self.playerData.airJumpSpeed
        self.player:ChgPlayerState(StateBouncePlayer.JumpAttack)
    end
end

--attack cmd
function StateBouncePlayerJump:OnAttack()
     --chgspeed and chg to jump state
     if  self.playerData.curSpeed > self.playerData.accDownSpeed then
        self.playerData.curSpeed = self.playerData.accDownSpeed
    end
    self.player:ChgPlayerState(StateBouncePlayer.AccDown)
end

--战斗时间轴更新
function StateBouncePlayerJump:OnUpdate(deltaTimeMS)
     --checkSpeed
     if self.playerData.curSpeed <= 0 then
        --chgState
        self.player:ChgPlayerState(StateBouncePlayer.Down)
        return
    end

     --change view position
     self.player:HandleMove(deltaTimeMS)
end

function StateBouncePlayerJump:GetStateType()
    return StateBouncePlayer.Jump
end

function StateBouncePlayerJump:LoadJumpEffect()
    ---@type BouncePlayerBeHaviorView
    local viewBehavior = self:GetBehavior(BouncePlayerBeHaviorView:Name())
    if not viewBehavior then
        return
    end
    local playerGo = viewBehavior:GetGameObject()
    if not playerGo then
        return
    end
    local playerTran = playerGo:GetComponent("RectTransform")
    local eff = EffectManager.Acquire("eff_jump.prefab", playerTran.parent, playerTran.anchoredPosition, 350)
    return eff
end
