--[[------------------------------------------------------------------------------------------
    战棋模式下的拾取
    负责提取点选数据，并根据当前主状态机的状态和点选的目标类型，决定下一步的状态
]] --------------------------------------------------------------------------------------------

---@class ChessInputSystem_Render:UniqueReactiveSystem
_class("ChessInputSystem_Render", UniqueReactiveSystem)
ChessInputSystem_Render = ChessInputSystem_Render

function ChessInputSystem_Render:IsInterested(index, previousComponent, component)
    if component == nil then
        return false
    end
    if not ChessPickUpComponent:IsInstanceOfType(component) then
        return false
    end
    return true
end

function ChessInputSystem_Render:Filter(world)
    return true
end

---@param world MainWorld
function ChessInputSystem_Render:ExecuteWorld(world)
    self._world = world

    ---@type ChessPickUpComponent
    local chessPickUpCmpt = world:ChessPickUp()
    local clickRenderPos = chessPickUpCmpt:GetChessClickPos()

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local gridPos = boardServiceRender:BoardRenderPos2GridPos(clickRenderPos)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()

    if
        stateId == GameStateID.WaitInput or stateId == GameStateID.PreviewChessPet or
            stateId == GameStateID.PickUpChessPet
     then
        self:SetChessPickUpGrid(chessPickUpCmpt, gridPos, stateId)
    else
        Log.fatal("### invalid state. stateId=", stateId)
    end
end

---
function ChessInputSystem_Render:SetChessPickUpGrid(cPickUp, gridPos, stateId)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type GuideServiceRender
    local guideService = self._world:GetService("Guide")
    local isGuide, isValid = guideService:IsGuideAndPieceValid(gridPos.x, gridPos.y)
    if isGuide then
        if isValid then
            self._world:EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Piece)
        else
            return
        end
    end

    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()

    pickUpResCmpt:SetChessPickUpPos(gridPos)

    -- if utilData:IsValidPiecePos(gridPos) and not utilData:IsPosBlock(gridPos, BlockFlag.LinkLine)  then
    --     pickUpResCmpt:SetChessPickUpSafePos(gridPos)
    -- end

    ---取出上次点选的信息
    ---@type ChessPickUpTargetType
    local lastPickUpTargetType = pickUpResCmpt:GetChessPickUpResultType()
    local pickUpChessPetEntityID = pickUpResCmpt:GetPickUpChessPetEntityID()

    ---当前点选信息
    local selectMonster, curPickUpMonsterEntityID = self:CheckPickUpMonster(gridPos)
    local selectHookChess, curPickUpHookChessEntityID = self:CheckChessHookChess(gridPos, pickUpResCmpt)
    if selectMonster then
        self:_HandleChessInputPickMonster(gridPos, curPickUpMonsterEntityID)
    elseif not selectMonster and selectHookChess and pickUpChessPetEntityID then
        self:_HandleChessInputPickMonster(gridPos, curPickUpHookChessEntityID)
    else
        ---只要没有选中怪，就可以清除
        pickUpResCmpt:SetPickUpMonsterEntityID(nil)

        local selectChessPet, curPickUpChessPetEntityID = self:CheckPickUpChessPet(gridPos)
        if selectChessPet then
            self:_HandleChessInputPickChessPet(gridPos, curPickUpChessPetEntityID)
        else
            self:_HandleChessInputPickGrid(gridPos)
        end
    end
end

---
function ChessInputSystem_Render:CheckPickUpMonster(touchPosition)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(group:GetEntities()) do
        if not e:HasGhost() and not e:HasGuideGhost() and e:IsOnGridPosition(touchPosition) then
            return true, e:GetID()
        end
    end
    return false, nil
end

---检查点击是否在钩子怪的攻击范围内
function ChessInputSystem_Render:CheckChessHookChess(touchPosition, pickUpResCmpt)
    local attackRange = pickUpResCmpt:GetChessPetAttackRange()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for _, e in ipairs(group:GetEntities()) do
        if e:IsOnGridPosition(touchPosition) then
            if table.intable(attackRange, touchPosition) then
                return true, e:GetID()
            end
        end
    end
    return false, nil
end

---
function ChessInputSystem_Render:CheckPickUpChessPet(touchPosition)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for _, e in ipairs(group:GetEntities()) do
        if not e:HasDeadMark() and e:IsOnGridPosition(touchPosition) then
            return true, e:GetID()
        end
    end
    return false, nil
end

---@param gridPos Vector2 点选的位置
---@param pickEntityID number 当前被选中的棋子EntityID
---
function ChessInputSystem_Render:_HandleChessInputPickChessPet(gridPos, pickEntityID)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()

    local lastPickUpPetEntityID = pickUpResCmpt:GetPickUpChessPetEntityID()
    if pickEntityID ~= lastPickUpPetEntityID then
        pickUpResCmpt:SetChessPickUpTargetChanged(true)
        local stateID = self:_GetChessInputMainStateID()
        if stateID == GameStateID.PreviewChessPet or stateID == GameStateID.PickUpChessPet then
            ---选中一个棋子状态下，选中其他棋子
            ---什么都不做
        else
            pickUpResCmpt:SetChessPickUpTargetChanged(true)
            ---通知
            pickUpResCmpt:SetChessPickUpResultType(ChessPickUpTargetType.ChessPet)
            pickUpResCmpt:SetPickUpChessPetEntityID(pickEntityID)
            renderBoardEntity:ReplacePickUpChessResult()
        end
    else
        pickUpResCmpt:SetChessPickUpTargetChanged(false)
        ---通知
        pickUpResCmpt:SetChessPickUpResultType(ChessPickUpTargetType.ChessPet)
        pickUpResCmpt:SetPickUpChessPetEntityID(pickEntityID)
        renderBoardEntity:ReplacePickUpChessResult()
    end
end

---@param gridPos Vector2 点选的位置
---@param pickEntityID number 当前被选中的怪物EntityID
---
function ChessInputSystem_Render:_HandleChessInputPickMonster(gridPos, pickEntityID)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()

    local lastPickUpMonsterEntityID = pickUpResCmpt:GetPickUpMonsterEntityID()

    if lastPickUpMonsterEntityID == nil then
        pickUpResCmpt:SetChessPickUpTargetChanged(true)
    elseif pickEntityID ~= lastPickUpMonsterEntityID then
        pickUpResCmpt:SetChessPickUpTargetChanged(true)
    else
        pickUpResCmpt:SetChessPickUpTargetChanged(false)
    end

    pickUpResCmpt:SetChessPickUpResultType(ChessPickUpTargetType.Monster)
    pickUpResCmpt:SetPickUpMonsterEntityID(pickEntityID)
    renderBoardEntity:ReplacePickUpChessResult()
end

function ChessInputSystem_Render:_HandleChessInputPickGrid(gridPos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type PickUpChessResultComponent
    local pickUpResCmpt = renderBoardEntity:PickUpChessResult()

    ---取出上次点选的信息
    ---@type ChessPickUpTargetType
    local lastPickUpTargetType = pickUpResCmpt:GetChessPickUpResultType()
    pickUpResCmpt:SetChessPickUpResultType(ChessPickUpTargetType.Grid)
    renderBoardEntity:ReplacePickUpChessResult()

    Log.notice("ChessPickUp nothing : ", gridPos)
end

function ChessInputSystem_Render:_GetChessInputMainStateID()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local stateId = utilDataSvc:GetCurMainStateID()
    return stateId
end
