--[[
    层数叠加
]]
---
_class("BuffViewAddLayerByDamageOfTeamHp", BuffViewBase)
---@class BuffViewAddLayerByDamageOfTeamHp:BuffViewBase
BuffViewAddLayerByDamageOfTeamHp = BuffViewAddLayerByDamageOfTeamHp
---
function BuffViewAddLayerByDamageOfTeamHp:PlayView(TT)
    ---@type BuffResultAddLayerByDamageOfTeamHp
    local res = self._buffResult
    local curLayer = res:GetLayer()
    local buffseq = res:GetBuffSeq()
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffseq)
    if not viewInstance then
        Log.error(
            "BuffViewAddLayerByDamageOfTeamHp not find viewInstance! entity=",
            self._entity:GetID(),
            " layer=",
            curLayer
        )
        return
    end

    --血条buff层数
    viewInstance:SetLayerCount(TT, curLayer)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end
