--[[----------------------------------------------------------
    PickUpChessGridSystem_Render：战棋点选到格子
]] ------------------------------------------------------------
---@class PickUpChessGridSystem_Render:ReactiveSystem
_class("PickUpChessGridSystem_Render", ReactiveSystem)
PickUpChessGridSystem_Render = PickUpChessGridSystem_Render

---@param world World
function PickUpChessGridSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world World
function PickUpChessGridSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PickUpChessResult)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PickUpChessGridSystem_Render:Filter(entity)
    ---@type PickUpChessResultComponent
    local resCmpt = entity:PickUpChessResult()
    ---@type ChessPickUpTargetType
    local resType = resCmpt:GetChessPickUpResultType()
    if resType == ChessPickUpTargetType.Grid then
        return true
    end
    return false
end

---
function PickUpChessGridSystem_Render:ExecuteEntities(entities)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpChessResultComponent
    local resCmpt = renderBoardEntity:PickUpChessResult()
    local gridPos = resCmpt:GetCurChessPickUpPos()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()
    local walkRange = resCmpt:GetChessPetWalkRange()

    if stateId == GameStateID.WaitInput then
        ---清理怪物预览
        chessSvcRender:ClearChessMonsterPreview()
        chessSvcRender:ClearChessPetPreview()
    elseif stateId == GameStateID.PreviewChessPet then
        self:_PreviewChessPet(walkRange, gridPos)
    elseif stateId == GameStateID.PickUpChessPet then
        self:_PickUpChessPet(walkRange, gridPos)
    end
end

---
function PickUpChessGridSystem_Render:_PreviewChessPet(walkRange, gridPos)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")

    local inRange = self:_CheckPickWalkRange(walkRange, gridPos)
    if inRange then
        ---在移动范围内，切到等待输入状态
        self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 1)
        self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Move)

        --显示棋子虚影
        chessSvcRender:ShowChessPetPreviewGhost(gridPos)
        chessSvcRender:HideChessPetSkillTips()
    else
        ---不在范围内，结束预览，回到输入
        ---清理棋子光灵预览
        chessSvcRender:ClearAllChessUnitPreview()

        self._world:EventDispatcher():Dispatch(GameEventType.PreviewChessPetFinish, 3)
        self._world:EventDispatcher():Dispatch(
            GameEventType.ChessUIStateTransit,
            UIBattleWidgetChessState.FinishTurnOnly
        )
    end
end

---
function PickUpChessGridSystem_Render:_PickUpChessPet(walkRange, gridPos)
    ---@type ChessServiceRender
    local chessSvcRender = self._world:GetService("ChessRender")
    local inRange = self:_CheckPickWalkRange(walkRange, gridPos)
    if not inRange then
        ---不在范围内，结束预览，回到输入
        chessSvcRender:ClearAllChessUnitPreview()
        self._world:EventDispatcher():Dispatch(GameEventType.PickUpChessPetFinish, 5)
        self._world:EventDispatcher():Dispatch(
            GameEventType.ChessUIStateTransit,
            UIBattleWidgetChessState.FinishTurnOnly
        )
    else
        --显示棋子虚影
        chessSvcRender:ShowChessPetPreviewGhost(gridPos)
        chessSvcRender:HideChessPetSkillTips()
        --如果有选中的攻击目标 刷新攻击范围和选中范围
        chessSvcRender:RestartChessPetPreviewAttackRange()

        self._world:EventDispatcher():Dispatch(GameEventType.ChessUIStateTransit, UIBattleWidgetChessState.Move)
    end
end

function PickUpChessGridSystem_Render:_CheckPickWalkRange(walkRange, gridPos)
    for k, pos in ipairs(walkRange) do
        -- ---@type ComputeWalkPos
        -- local walkInfo = v
        -- local pos = walkInfo:GetPos()
        if pos == gridPos then
            return true
        end
    end

    return false
end
