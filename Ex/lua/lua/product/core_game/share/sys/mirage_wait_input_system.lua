--[[------------------------------------------------------------------------------------------
    MirageWaitInputSystem：等待玩家输入
]] --------------------------------------------------------------------------------------------

require "main_state_sys"

---@class MirageWaitInputSystem:MainStateSystem
_class("MirageWaitInputSystem", MainStateSystem)
MirageWaitInputSystem = MirageWaitInputSystem

---状态处理必须重写此方法
---@return GameStateID 状态标识
function MirageWaitInputSystem:_GetMainStateID()
    return GameStateID.MirageWaitInput
end

---@param TT token 协程识别码，服务端环境下是nil
function MirageWaitInputSystem:_OnMainStateEnter(TT)
    ---重置一些战斗状态
    self:_DoLogicRestBattleState()

    ---重置表现的战斗状态
    self:_DoRenderResetBattleState()

    ---重置格子动画
    self:_DoRenderPieceAnimation(TT)

    --逻辑表现棋盘数据同步
    self:_DoL2RBoardLogicData()

    --比对逻辑血量和表现血量
    self:_DoRenderCompareHPLog(TT)

    --对比格子类型数据
    self:_DoRenderComparePieceType(TT)
end

function MirageWaitInputSystem:_DoLogicRestBattleState()
    -- --计数（用于调试，客户端和服务器不一样）
    -- ---@type BattleStatComponent
    -- local battleStatCmpt = self._world:BattleStat()
    -- battleStatCmpt:IncWaitInputCount()
end

function MirageWaitInputSystem:_DoL2RBoardLogicData()
    -- --更新逻辑数据
    -- local t = self._world:GetService("BoardLogic"):CalcPieceEntities()
    -- self._world:GetBoardEntity():Board():SetPieceEntities(t)

    -- --多面棋盘更新
    -- ---@type ConfigService
    -- local configService = self._world:GetService("Config")
    -- ---@type LevelConfigData
    -- local levelConfigData = configService:GetLevelConfigData()
    -- local multiBoard = levelConfigData:GetMultiBoard()
    -- if multiBoard and table.count(multiBoard) > 0 then
    --     ---@type BoardMultiServiceLogic
    --     local boardMultiServiceLogic = self._world:GetService("BoardMultiLogic")
    --     ---@type BoardMultiComponent
    --     local boardMultiComponent = self._world:GetBoardEntity():BoardMulti()
    --     local entities = boardMultiServiceLogic:GetEntityGroup()
    --     for i, boardInfo in ipairs(multiBoard) do
    --         local boardIndex = boardInfo.index
    --         local pieceEntities = boardMultiServiceLogic:CalcPieceEntities(entities, boardIndex)
    --         boardMultiComponent:SetPieceEntities(boardIndex, pieceEntities)
    --     end
    --     boardMultiServiceLogic:SaveMonsterIDCmptOnOutsideRegion()
    -- end
    -- --离场怪处理 （符文刺客）
    -- ---@type BoardServiceLogic
    -- local boardSvc = self._world:GetService("BoardLogic")
    -- boardSvc:SaveMonsterIDCmptOffBoard()
    -- --更新表现数据
    -- ---@type L2RService
    -- local svc = self._world:GetService("L2R")
    -- svc:L2RBoardLogicData()
end

----------------------------------表现接口-----------------------------------
function MirageWaitInputSystem:_DoRenderResetBattleState(TT)
end

function MirageWaitInputSystem:_DoRenderPieceAnimation(TT)
end

function MirageWaitInputSystem:_DoRenderCompareHPLog(TT)
end

function MirageWaitInputSystem:_DoRenderComparePieceType(TT)
end
