_class("BuffViewAddCountDown", BuffViewBase)
---@class BuffViewAddCountDown:BuffViewBase
BuffViewAddCountDown = BuffViewAddCountDown

function BuffViewAddCountDown:PlayView(TT)
    ---@type BuffResultAddCountDown
    local buffResult = self._buffResult
    local curCountDown = buffResult:GetCountDown()
    local buffseq = buffResult:GetBuffSeq()

    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffseq)
    if not viewInstance then
        return
    end

    viewInstance:SetCountDown(curCountDown)

    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    -- if self._world:Player():IsLocalTeamEntity(self._entity) then
    --     local teamBuffList = self._entity:BuffView():GetBuffTeamStateShowList()
    --     self._world:EventDispatcher():Dispatch(GameEventType.ChangeTeamBuff, teamBuffList)
    -- end
end

function BuffViewAddCountDown:IsNotifyMatch(notify)
    ---@type BuffResultAddCountDown
    local buffResult = self._buffResult
    return true
end
