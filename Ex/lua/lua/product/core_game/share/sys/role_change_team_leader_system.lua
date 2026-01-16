require("main_state_sys")

---@class RoleChangeTeamLeaderSystem : MainStateSystem
_class("RoleChangeTeamLeaderSystem", MainStateSystem)
RoleChangeTeamLeaderSystem = RoleChangeTeamLeaderSystem

---重载函数，返回主动技状态标识码
---@return GameStateID 状态标识
function RoleChangeTeamLeaderSystem:_GetMainStateID()
    return GameStateID.RoleChangeTeamLeader
end

---主动技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function RoleChangeTeamLeaderSystem:_OnMainStateEnter(TT)
    self:_DoRenderChangeTeamLeader(TT)

    self._world:EventDispatcher():Dispatch(GameEventType.RoleChangeTeamLeaderFinish, 1)
end

---FIXME: 这个要移到ClientRoleChangeTeamLeaderSystem内
function RoleChangeTeamLeaderSystem:_DoRenderChangeTeamLeader(TT)
end
