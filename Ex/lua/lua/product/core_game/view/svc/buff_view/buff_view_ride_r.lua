--[[
    骑乘Buff表现
]]
---@class BuffViewRide : BuffViewBase
_class("BuffViewRide", BuffViewBase)
BuffViewRide = BuffViewRide

function BuffViewRide:IsNotifyMatch(notify)
    if notify then
        if notify:GetNotifyType() == NotifyType.MonsterTurnAfterAddBuffRound or
            notify:GetNotifyType() == NotifyType.BuffLoad or
            notify:GetNotifyType() == NotifyType.MonsterTurnAfterDelayedAddBuffRound
        then
            return true
        end
        ---@type BuffResultRide
        local buffResult = self:GetBuffResult()

        if notify:GetNotifyType() == NotifyType.NormalEachAttackEnd then
            ---@type NTNormalEachAttackEnd
            local n = notify

            return ((buffResult:GetNotifyPos() == n:GetAttackPos()) and
                (buffResult:GetTargetPos() == n:GetTargetPos()) and
                (buffResult:GetNotifyEntity() == n:GetAttackerEntity()))
        end
        if notify:GetNotifyType() == NotifyType.TrapEachAttackEnd then
            ---@type NTTrapEachAttackEnd
            local n = notify

            return ((buffResult:GetNotifyPos() == n:GetAttackPos()) and
                (buffResult:GetTargetPos() == n:GetTargetPos()) and
                (buffResult:GetNotifyEntity() == n:GetAttackerEntity()))
        end
        if notify:GetNotifyType() == NotifyType.ActiveSkillAttackEnd or
            notify:GetNotifyType() == NotifyType.TrapActiveSkillEnd or
            notify:GetNotifyType() == NotifyType.BuffCastSkillAttackEnd
        then
            return buffResult:GetNotifyEntity() == notify:GetNotifyEntity()
        end
        if notify:GetNotifyType() == NotifyType.SingleChainSkillAttackFinish then
            return buffResult:GetNotifyEntity() == notify:GetNotifyEntity() and
                buffResult:GetNotifyChainSkillIndex() == notify:GetChainSkillIndex()
        end
    end

    return false
end

function BuffViewRide:PlayView(TT)
    ---@type BuffResultRide
    local buffResult = self:GetBuffResult()
    if buffResult:HasPlayed() then
        return
    end
    buffResult:SetPlayed(true)
    local rideID = buffResult:GetRideEntityID()
    local mountID = buffResult:GetMountEntityID()
    ---@type Entity
    local rideEntity = self._world:GetEntityByID(rideID)

    ---@type DataGridLocationResult
    local gridLocRes = buffResult:GetDataGridLocationResult()

    ---@type RideServiceRender
    local rideSvc = self._world:GetService("RideRender")
    if mountID then
        rideSvc:ReplaceRideRender(rideID, mountID, gridLocRes)
        return
    end

    local fromTrap = false
    if rideEntity:HasRideRender() then
        ---@type RideRenderComponent
        local rideCmpt = rideEntity:RideRender()
        local oriMountID = rideCmpt:GetMountID()
        if oriMountID == mountID then
            return
        end
        ---@type Entity
        local oriMountEntity = self._world:GetEntityByID(oriMountID)
        if not oriMountEntity then
            Log.debug("BuffViewRide oriMountEntity is nil, id = ", oriMountID)
        end
        if oriMountEntity:HasTrapRender() then
            fromTrap = true
        end
        rideSvc:RemoveRideRender(rideID, oriMountID)
    end

    local pos = gridLocRes:GetGridLocResultBornPos()
    local offset = gridLocRes:GetGridLocResultBornOffset()
    rideSvc:SetNoRidePos(rideID, pos + offset, fromTrap)

    --待验证：不需要设置高度，在pos计算的时候，已经获取了GridLocation中的height
    -- local height = gridLocRes:GetGridLocResultBornHeight()
    -- rideEntity:SetLocationHeight(height)
end
