require("role_change_team_leader_system")

---@class ClientRoleChangeTeamLeaderSystem_Render : RoleChangeTeamLeaderSystem
_class("ClientRoleChangeTeamLeaderSystem_Render", RoleChangeTeamLeaderSystem)
ClientRoleChangeTeamLeaderSystem_Render = ClientRoleChangeTeamLeaderSystem_Render

---
function ClientRoleChangeTeamLeaderSystem_Render:_DoRenderChangeTeamLeader(TT)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamOrderBefore, teamOrderAfter = teamEntity:Team():GetChangeTeamLeaderCmdData()
    local request = BattleTeamOrderViewRequest:New(teamOrderBefore, teamOrderAfter, BattleTeamOrderViewType.Exchange_ChangeTeamLeader)
    local renderBattleService = self._world:GetService("RenderBattle")
    renderBattleService:RequestUIChangeTeamOrderView(request)
    
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local leftChangeTeamLeaderCount = utilDataSvc:GetEntityAttributeByName(teamEntity,"ChangeTeamLeaderCount")

    local newTeamLeaderPetPstID = teamOrderAfter[1]
    local oldTeamLeaderPetPstID = teamOrderBefore[1]
    self._world:EventDispatcher():Dispatch(
            GameEventType.UIChangeTeamLeader, -- 看上去是个UI事件，其实逻辑到表现的数据传递也是这个
            newTeamLeaderPetPstID,
            oldTeamLeaderPetPstID,
            leftChangeTeamLeaderCount,
            teamOrderBefore, teamOrderAfter
    )
    self._world:EventDispatcher():Dispatch(GameEventType.UIChangeTeamLeaderLeftCount, leftChangeTeamLeaderCount)
    
    local waitUIFinish = 0.5 ---等待UI播放结束，固定时长
    YIELD(TT,waitUIFinish * 1000)

    local ntTeamOrderChange = NTTeamOrderChange:New(teamEntity,teamOrderBefore,teamOrderAfter)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, ntTeamOrderChange)
end
