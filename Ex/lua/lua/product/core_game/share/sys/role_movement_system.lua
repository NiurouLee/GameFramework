--[[------------------------------------------------------------------------------------------
    主状态机流程 主要是表现角色移动以及普攻 
    0.对应的StateID是 RoleTurn
    1.客户端执行角色的移动和普攻表现，完成后，跳转到主状态机的下一个状态。
      服务端直接跳转到主状态机的下一个状态。
    2.此状态从WaitInput转过来
    3.在MovePathDownHandler里算完普攻逻辑数据后，通知主状态机跳转到本状态
    4.从表现上看，所有光灵到达连线的终点并普攻完成，此时本状态结束，跳转到下个状态
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class RoleMovementSystem:MainStateSystem
_class("RoleMovementSystem", MainStateSystem)
RoleMovementSystem = RoleMovementSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function RoleMovementSystem:_GetMainStateID()
    return GameStateID.RoleTurn
end

---@param TT token 协程识别码，服务端是nil
function RoleMovementSystem:_OnMainStateEnter(TT)
    local elementType = self:_DoLogicGetChainElementType()
    --通知自爆怪表现，死亡表现，刷新自爆怪格子
    --self:_DoLogicNotifyBuff()
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    self:_DoRenderNotifyBuff(TT, elementType, teamEntity)
    --self:_DoRenderMonsterDead(TT)
    --self:_DoRenderResetPieceAnim(TT)


    --头像出战显示
    self:_DoRenderPetHeadShow(TT)
    --移动表现，通过ChainMoveSystem执行具体的移动
    self:_DoRendererMove(TT, teamEntity)

    self:_DoRenderNotifyBuffNormalAttackEnd(TT)

    --秘境死亡
    local ntTeamOrderChange = self:_DoLogicPetDead(teamEntity)
    self:_DoRenderPetDead(TT, teamEntity, ntTeamOrderChange)
    self:_SendPrismNotify(TT)
    --状态切换
    self:_DoLogicGotoNextState()
end

function RoleMovementSystem:_DoLogicGetChainElementType()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    return logicChainPathCmpt:GetLogicPieceType()
end

function RoleMovementSystem:_DoLogicGotoNextState()
    self._world:EventDispatcher():Dispatch(GameEventType.RoleTurnFinish, 1)
end

----------------------------表现接口--------------------------------------
function RoleMovementSystem:_DoRenderPetHeadShow(TT)
end

function RoleMovementSystem:_DoRendererMove(TT, teamEntity)
end

function RoleMovementSystem:_DoRenderNotifyBuff(TT)
end

function RoleMovementSystem:_DoRenderNotifyBuffNormalAttackEnd(TT)
end

function RoleMovementSystem:_DoRenderResetPieceAnim(TT)
end

function RoleMovementSystem:_SendPrismNotify(TT)
end