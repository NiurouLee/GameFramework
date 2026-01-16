--[[
    层数叠加
]]
_class("BuffViewAddLayerByMonsterDead", BuffViewBase)
BuffViewAddLayerByMonsterDead = BuffViewAddLayerByMonsterDead

function BuffViewAddLayerByMonsterDead:PlayView(TT)
    ---@type BuffResultAddLayer
    local result = self:GetBuffResult()
    local curMarkLayer = result:GetLayer()
    local dontDisplay = result:GetDonotDisplay()
    --血条buff层数
    self._viewInstance:SetLayerCount(TT, curMarkLayer)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    if dontDisplay then
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
