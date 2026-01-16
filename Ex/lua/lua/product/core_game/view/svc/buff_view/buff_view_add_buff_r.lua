--[[
    添加buff
]]
_class("BuffViewAddBuff", BuffViewBase)
BuffViewAddBuff = BuffViewAddBuff

function BuffViewAddBuff:PlayView(TT, notify, trace)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    local arr = self._buffResult:GetBuffArray()
    for i, v in ipairs(arr) do
        local eid, seq = v[1], v[2]
        Log.debug("BuffViewAddBuff entityid=", eid, "buffseq=", seq, "trace: ", trace)
        local entity = self._world:GetEntityByID(eid)
        if entity then
            local inst = entity:BuffView():GetBuffViewInstance(seq)
            if inst then
                playBuffSvc:PlayAddBuff(TT, inst)
                if self._buffResult:GetLight() == 1 then
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.ActivatePassive,
                        entity:PetPstID():GetPstID(),
                        true
                    )
                end
            end
        end
    end
    local cfg = self._viewInstance:BuffConfigData()
    local effectID = cfg:GetExecEffectID()
    if effectID then
        self._world:GetService("Effect"):CreateEffect(effectID, self._entity)
    end
end

function BuffViewAddBuff:IsNotifyMatch(notify)
    if notify.GetRandHalfDamageIndex and self._buffResult.GetRandHalfDamageIndex then
        local halfRandDamageIndex = notify:GetRandHalfDamageIndex()
        if halfRandDamageIndex then
            local buffHalfRandDamageIndex = self._buffResult:GetRandHalfDamageIndex()
            if buffHalfRandDamageIndex then
                if buffHalfRandDamageIndex ~= halfRandDamageIndex then
                    return false
                end
            end
        end
    end
    --如果传递了 攻击的坐标和 被击的坐标
    local attackPos = self._buffResult:GetAttackPos()
    local targetPos = self._buffResult:GetTargetPos()
    if notify.GetAttackPos and notify.GetTargetPos then
        if attackPos == notify:GetAttackPos() and targetPos == notify:GetTargetPos() then
            return true
        else
            return false
        end
    end

    if notify:GetNotifyType() == NotifyType.MonsterShow then
        local arr = self._buffResult:GetBuffArray()
        for i, v in ipairs(arr) do
            local eid, seq = v[1], v[2]
            if eid == notify:GetNotifyEntity():GetID() then
                return true
            end
        end
        return false
    end

    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        return self._buffResult:GetWalkPos() == notify:GetPos()
    end

    if notify:GetNotifyType() == NotifyType.NotifyLayerChange then
        ---@type NTNotifyLayerChange
        local n = notify
        if self._buffResult.__oldFinalLayer ~= n.__oldFinalLayer then
            return false
        end

        if n:GetNotifyEntity() and (self._buffResult:GetNotifyLayerChange_Entity() ~= n:GetNotifyEntity()) then
            return false
        end

        return true
    end

    return true
end

_class("BuffViewRemoveBuff", BuffViewBase)
---@class BuffViewRemoveBuff : BuffViewBase
BuffViewRemoveBuff = BuffViewRemoveBuff
function BuffViewRemoveBuff:IsNotifyMatch(notify)
    ---@type BuffResultRemoveBuff
    local result = self._buffResult
    if notify.GetRandHalfDamageIndex and self._buffResult.GetRandHalfDamageIndex then
        local halfRandDamageIndex = notify:GetRandHalfDamageIndex()
        if halfRandDamageIndex then
            local buffHalfRandDamageIndex = self._buffResult:GetRandHalfDamageIndex()
            if buffHalfRandDamageIndex then
                if buffHalfRandDamageIndex ~= halfRandDamageIndex then
                    return false
                end
            end
        end
    end

    if
        notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart
     then
        return self._buffResult:GetWalkPos() == notify:GetPos()
    end

    if notify and notify:GetNotifyType() == NotifyType.ChainSkillAttackEnd then
        local entityCheckPass = false
        local atkEntity = notify:GetNotifyEntity()
        if atkEntity then
            entityCheckPass = (result:GetNotifyEntityID() == atkEntity:GetID())
        end
        local skillIndexPass = result:GetNotifyChainSkillIndex() == notify:GetChainSkillIndex()
        local skillIdPass = result:GetNotifyChainSkillId() == notify:GetChainSkillId()
        return entityCheckPass and skillIndexPass and skillIdPass
    end

    return true
end
function BuffViewRemoveBuff:PlayView(TT, notify)
    ---@type PlayBuffService
    local playBuffSvc = self._world:GetService("PlayBuff")
    local arr = self._buffResult:GetBuffArray()
    for i, v in ipairs(arr) do
        local eid = v.eid
        local tSeqID = v.tSeqID

        local entity = self._world:GetEntityByID(eid)
        if entity then
            for _, seq in ipairs(tSeqID) do
                local inst = entity:BuffView():GetBuffViewInstance(seq)
                if inst then
                    playBuffSvc:PlayRemoveBuff(TT, inst, NTBuffUnload:New())

                    if self._buffResult:GetBlack() == 1 then
                        GameGlobal.EventDispatcher():Dispatch(
                            GameEventType.ActivatePassive,
                            entity:PetPstID():GetPstID(),
                            false
                        )
                    end
                end
            end
        end
    end
end
