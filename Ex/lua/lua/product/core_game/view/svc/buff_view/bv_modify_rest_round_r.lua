--[[
    修改剩余回合
]]
---@class BuffViewModifyRestRound:BuffViewBase
_class("BuffViewModifyRestRound", BuffViewBase)
BuffViewModifyRestRound = BuffViewModifyRestRound

function BuffViewModifyRestRound:PlayView(TT)
    ---@type BuffResultModifyRestRound
    local result = self._buffResult
    local curWaveRestRound = result:GetCurWaveRound()
    local curWaveRestRoundDiff = result:GetCurWaveRoundDiff()--表现顺序与逻辑顺序不一致 用变化值好一点
    --self._world:EventDispatcher():Dispatch(GameEventType.UpdateRoundCount, curWaveRestRound)
    self._world:EventDispatcher():Dispatch(GameEventType.UpdateRoundCountByDiff, curWaveRestRoundDiff)
end
function BuffViewModifyRestRound:IsNotifyMatch(notify)
    if notify:GetNotifyType() == NotifyType.PlayerBeHit then
        local damageIndexMatch = true
        if self._buffResult.damageIndex and notify:GetDamageIndex() then
            damageIndexMatch = self._buffResult.damageIndex == notify:GetDamageIndex()
        end
        return self._buffResult.attackPos == notify:GetAttackPos() and
            self._buffResult.targetPos == notify:GetTargetPos() and
            self._buffResult.attackerEntity == notify:GetAttackerEntity() and
            self._buffResult.defenderEntity == notify:GetDefenderEntity() and
            damageIndexMatch
    elseif (notify:GetNotifyType() == NotifyType.MonsterDead) 
        or (notify:GetNotifyType() == NotifyType.MonsterDeadEnd) 
        or (notify:GetNotifyType() == NotifyType.MonsterDeadStart) 
    then
        ---@type Entity
         local entity = notify:GetNotifyEntity()
         return (self._buffResult.deadMonsterEntityID == entity:GetID())
    end
    return true
end