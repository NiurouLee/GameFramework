--[[------------------------------------------------------------------------------------------
    ChessPetMoveAndAttackSystem：棋子光灵移动并攻击
]] --------------------------------------------------------------------------------------------
require "main_state_sys"

---@class ChessPetMoveAndAttackSystem:MainStateSystem
_class("ChessPetMoveAndAttackSystem", MainStateSystem)
ChessPetMoveAndAttackSystem = ChessPetMoveAndAttackSystem

---重载函数，返回主动技状态标识码
---@return GameStateID 状态标识
function ChessPetMoveAndAttackSystem:_GetMainStateID()
    return GameStateID.ChessPetMoveAndAttack
end

---主动技的施法流程比较长，未来应该可以合并一些阶段
---@param TT token 协程识别码，服务端是nil
function ChessPetMoveAndAttackSystem:_OnMainStateEnter(TT)
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type LogicChessPathComponent
    local logicChessPathComponent = boardEntity:LogicChessPath()
    local chessPath = logicChessPathComponent:GetLogicChessPath()
    local entityID = logicChessPathComponent:GetLogicChessPetEntityID()
    local pickUpPos = logicChessPathComponent:GetLogicPickUpPos()
    local chessPetEntity = self._world:GetEntityByID(entityID)

    ---@type L2RService
    local svc = self._world:GetService("L2R")

    ---移动逻辑
    self:_DoLogicChessPetMove()
    ---通知表现层
    svc:L2RChessPathData()
    ---移动表现
    self:_DoRenderChessPetMove(TT)

    --设置朝向
    self:_DoLogicSetChessPetDir(chessPetEntity, pickUpPos, chessPetEntity:GetGridPosition())
    self:_DoRenderSetChessPetDir(TT, chessPetEntity)

    --攻击逻辑
    self:_DoLogicChessPetAttack()
    ---通知表现层
    svc:L2RChessAttackData(chessPetEntity)
    --攻击表现
    local castSkillTaskID = self:_DoRenderChessPetAttack(TT)
    ---等待主动技施法结束
    self:_WaitTasksEnd(TT, {castSkillTaskID})

    ---攻击后的表现
    self:_DoRenderChessPetFinishAttack(TT)

    ---主状态机切换到ChessPetResult状态
    self._world:EventDispatcher():Dispatch(GameEventType.ChessPetMoveAndAttackFinish, 1)
end

---
function ChessPetMoveAndAttackSystem:_DoLogicChessPetMove()
    ---@type ChessServiceLogic
    local chessLogic = self._world:GetService("ChessLogic")
    chessLogic:DoChessPetPathMove()
end

function ChessPetMoveAndAttackSystem:_DoLogicChessPetAttack()
    ---@type ChessServiceLogic
    local chessLogic = self._world:GetService("ChessLogic")
    chessLogic:DoChessPetAttack()
end

---
function ChessPetMoveAndAttackSystem:_DoLogicSetChessPetDir(chessPetEntity, pickUpPos, targetMovePos)
    --set dir
    if pickUpPos then
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local dir = utilScopeSvc:GetChessEntityGridDirWithPickUpPos(chessPetEntity, pickUpPos, targetMovePos)

        chessPetEntity:SetGridDirection(dir)
    end
end

--------------------------------------表现接口-----------------------------------------
---
function ChessPetMoveAndAttackSystem:_DoRenderChessPetMove(TT)
end

---
function ChessPetMoveAndAttackSystem:_DoRenderChessPetAttack(TT)
end

---
function ChessPetMoveAndAttackSystem:_DoRenderSetChessPetDir(TT, chessPetEntity)
end

---
function ChessPetMoveAndAttackSystem:_DoRenderChessPetFinishAttack(TT)
end
