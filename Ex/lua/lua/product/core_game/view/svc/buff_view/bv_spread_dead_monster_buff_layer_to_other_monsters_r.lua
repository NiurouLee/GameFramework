_class("BuffViewSpreadDeadMonsterBuffLayerToOtherMonsters", BuffViewBase)
---@class BuffViewSpreadDeadMonsterBuffLayerToOtherMonsters : BuffViewBase
BuffViewSpreadDeadMonsterBuffLayerToOtherMonsters = BuffViewSpreadDeadMonsterBuffLayerToOtherMonsters

---@param notify NTMonsterDeadStart|NTMonsterDeadEnd
function BuffViewSpreadDeadMonsterBuffLayerToOtherMonsters:IsNotifyMatch(notify)
    ---@type BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters
    local result = self._buffResult

    local notifyType = notify:GetNotifyType()
    if (notifyType == NotifyType.MonsterDeadStart) or (notifyType == NotifyType.MonsterDeadEnd) then
        return ((result:GetOwnerEntityID() == notify:GetNotifyEntity():GetID()) and
                (result:GetDefenderEntityID() == notify:GetDefenderEntity():GetID()))
    end
end

function BuffViewSpreadDeadMonsterBuffLayerToOtherMonsters:PlayView(TT, notify, trace)
    ---@type BuffResultSpreadDeadMonsterBuffLayerToOtherMonsters
    local result = self._buffResult

    for _, info in ipairs(result:GetSpreadResults()) do
        local targetID = info.targetID
        local eTarget = self._world:GetEntityByID(targetID)
        ---@type BuffViewComponent
        local buffView = eTarget:BuffView()
        local buffSeq = info.buffSeq
        local viewInstance = buffView:GetBuffViewInstance(buffSeq)
        if viewInstance then
            viewInstance:SetLayerCount(TT, info.finalLayer, nil, info.casterEntity, "SpreadDeadMonsterBuffLayerToOtherMonsters")
        end

        self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
        --星灵被动层数
        if eTarget:HasPetPstID() then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.SetAccumulateNum, eTarget:PetPstID():GetPstID(), info.layer)
        end
    end
end
