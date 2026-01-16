--[[
    SealedCurse: 诅咒：无法上场，首发于诅魍（2000551?）
]]
_class("BuffViewSetSealedCurse", BuffViewBase)
---@class BuffViewSetSealedCurse : BuffViewBase
BuffViewSetSealedCurse = BuffViewSetSealedCurse

function BuffViewSetSealedCurse:PlayView(TT)
    ---@type BuffResultSealedCurse
    local res = self._buffResult
    local buffseq = res:GetBuffSeq()
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffseq)
    if not viewInstance then
        Log.error(self._className, "no viewInstance! entity=", self._entity:GetID())
        return
    end

    if self._entity:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.BattlePetIconSealedCurse,
            self._entity:PetPstID():GetPstID(),
            res:IsCursed(),
            buffseq,
            viewInstance:RemainRoundCount(),
            (viewInstance:GetMaxRoundCount() == 0)
        )
    end
end

_class("BuffViewResetSealedCurse", BuffViewSetSealedCurse)
---@class BuffViewResetSealedCurse : BuffViewSetSealedCurse