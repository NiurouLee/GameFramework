--[[------------------------------------------------------------------------------------------
    PopStarPieceRefreshSystem：消灭星星模式下的刷新格子
]]
--------------------------------------------------------------------------------------------

---@class PopStarPieceRefreshSystem:MainStateSystem
_class("PopStarPieceRefreshSystem", MainStateSystem)
PopStarPieceRefreshSystem = PopStarPieceRefreshSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function PopStarPieceRefreshSystem:_GetMainStateID()
    return GameStateID.PopStarPieceRefresh
end

---@param TT token 协程识别码，服务端是nil
function PopStarPieceRefreshSystem:_OnMainStateEnter(TT)
    ---逻辑上替换格子
    local result = self:_DoLogicFillPiece()

    ---表现上替换格子
    self:_DoRenderFillPiece(TT, result)

    --同步格子颜色
    self:_DoLogicSyncPieceType()

    ---切换主状态机
    self:_DoLogicSwitchState()
end

--region 逻辑接口
function PopStarPieceRefreshSystem:_DoLogicSwitchState()
    self._world:EventDispatcher():Dispatch(GameEventType.PopStarPieceRefreshFinish, 1)
end

---刷新格子
function PopStarPieceRefreshSystem:_DoLogicFillPiece()
    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local connectPieces = popStarSvc:GetPopConnectPieces()
    if not connectPieces then
        return
    end

    if #connectPieces == 0 then
        return
    end

    local result = popStarSvc:CalculatePopPieces(connectPieces)
    return result
end

--endregion

-------------------------表现接口----------------------------------

function PopStarPieceRefreshSystem:_DoRenderFillPiece(TT, result)
end
