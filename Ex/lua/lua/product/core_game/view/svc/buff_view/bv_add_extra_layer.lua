_class("BuffViewAddExtraLayer", BuffViewBase)
---@class BuffViewAddExtraLayer : BuffViewBase
BuffViewAddExtraLayer = BuffViewAddExtraLayer

function BuffViewAddExtraLayer:IsNotifyMatch(notify)
    if notify:GetNotifyType() == NotifyType.NotifyLayerChange then
        ---@type NTNotifyLayerChange
        local n = notify
        if self._buffResult.__oldFinalLayer ~= n.__oldFinalLayer then
            return false
        end

        if (n:GetNotifyEntity()) and (self._buffResult:GetEntity() ~= n:GetNotifyEntity()) then
            return false
        end
    end

    return true
end

function BuffViewAddExtraLayer:PlayView(TT)
    ---@type BuffResultAddExtraLayer
    local result = self._buffResult

    local targetEntity = result:GetEntity()
    ---@type BuffViewComponent
    local buffView = targetEntity:BuffView()
    local buffSeq = result:GetTargetBuffSeq()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffSeq)
    if not viewInstance then
        return
    end

    local totalLayer = result:GetFinalLayer()

    viewInstance:SetLayerCount(TT, totalLayer)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    if targetEntity:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(
                GameEventType.SetAccumulateNum,
                targetEntity:PetPstID():GetPstID(),
                totalLayer
        )
    end
end
