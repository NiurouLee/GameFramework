--[[
    层数叠加
]]
_class("BuffViewAddLayerByScopeGridCount", BuffViewBase)
---@class BuffViewAddLayerByScopeGridCount:BuffViewBase
BuffViewAddLayerByScopeGridCount = BuffViewAddLayerByScopeGridCount

function BuffViewAddLayerByScopeGridCount:PlayView(TT)
    ---@type BuffResultAddLayer
    local result = self._buffResult
    local curMarkLayer = result:GetLayer()
    local buffSeq = result:GetBuffSeq()
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffSeq)
    --血条buff层数
    viewInstance:SetLayerCount(TT, curMarkLayer,result:GetTotalLayer())
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
