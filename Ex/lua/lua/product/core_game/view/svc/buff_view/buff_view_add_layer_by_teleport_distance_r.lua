--[[
    层数叠加
]]
_class("BuffViewAddLayerByTeleportDistance", BuffViewBase)
BuffViewAddLayerByTeleportDistance = BuffViewAddLayerByTeleportDistance

function BuffViewAddLayerByTeleportDistance:PlayView(TT)
    ---@type BuffResultAddLayer
    local result = self._buffResult
    local curMarkLayer = result:GetLayer()
    --血条buff层数
    self._viewInstance:SetLayerCount(TT, curMarkLayer)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    if result:GetDonotDisplay() then
        return
    end

    --星灵被动层数
    if self._entity:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.SetAccumulateNum,
            self._entity:PetPstID():GetPstID(),
            curMarkLayer
        )
    end
end
