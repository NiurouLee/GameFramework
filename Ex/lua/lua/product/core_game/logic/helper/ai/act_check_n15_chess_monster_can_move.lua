--[[-------------------------------------
    ActionCheckN15ChessMonsterCanMove 判断N15的敌方棋子是否能连线移动
--]] -------------------------------------
require "ai_node_new"
---@class ActionCheckN15ChessMonsterCanMove : AINewNode
_class("ActionCheckN15ChessMonsterCanMove", AINewNode)
ActionCheckN15ChessMonsterCanMove = ActionCheckN15ChessMonsterCanMove
----------------------------------------------------------------
function ActionCheckN15ChessMonsterCanMove:Constructor()
end
function ActionCheckN15ChessMonsterCanMove:OnUpdate()
    ---@type Entity
    local ownEntity =self.m_entityOwn
    ---@type BodyAreaComponent
    local bodyArea = ownEntity:BodyArea()
    if bodyArea:GetAreaCount() >1 then
        return AINewNodeStatus.Failure
    end
    local element = ownEntity:Element():GetPrimaryType()
    ---@type Vector2
    local myPos = ownEntity:GetGridPosition()
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    if board:GetPieceType(myPos) ~= element and board:GetPieceType(myPos) ~=PieceType.Any then
        return AINewNodeStatus.Failure
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local aroundPosList = utilScopeSvc:GetPosAroundSameTypePosList(myPos,element)
    if #aroundPosList == 0 then
        return AINewNodeStatus.Failure
    end
    return AINewNodeStatus.Success
end
